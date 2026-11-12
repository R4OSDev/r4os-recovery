// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Bounded canonical cache mechanics. No I/O, allocation, job state or GPU
//! admission. Compiler identity and semantic validators belong to providers.
const std = @import("std");
const native_endian = @import("builtin").cpu.arch.endian();
const Sha256 = std.crypto.hash.sha2.Sha256;
pub const Error = error{ InvalidArgument, InvalidLength, InvalidSchema, Overflow, Overlap, Capacity, UnknownFormat, VersionMismatch, IdentityMismatch, IntegrityMismatch, NonCanonical };

pub fn validSpan(address: usize, length: usize) bool {
    return address != 0 and length != 0 and length <= std.math.maxInt(usize) - address;
}
/// Readonly ranges may overlap. Invalid ranges conservatively overlap;
/// callers that need distinct error categories validate them first.
pub fn overlaps(a: usize, a_length: usize, b: usize, b_length: usize) bool {
    if (a_length == 0 or b_length == 0) return false;
    if (!validSpan(a, a_length) or !validSpan(b, b_length)) return true;
    return a < b + b_length and b < a + a_length;
}
const Span = struct {
    address: usize,
    length: usize,
    fn of(bytes: anytype) Span {
        return .{ .address = @intFromPtr(bytes.ptr), .length = bytes.len };
    }
    fn object(pointer: anytype) Span {
        return .{ .address = @intFromPtr(pointer), .length = @sizeOf(@typeInfo(@TypeOf(pointer)).pointer.child) };
    }
    fn valid(self: Span) bool {
        return validSpan(self.address, self.length);
    }
    fn intersects(self: Span, other: Span) bool {
        return overlaps(self.address, self.length, other.address, other.length);
    }
};

pub const ScalarSchemaCodec = struct {
    pub const max_record_bytes = 64 * 1024;
    pub const max_fields = 256;
    pub const zero: u8 = 1;
    /// Portable descriptor; offsets and widths are bytes, never pointers.
    /// Fields are sorted by wire_offset. Only width4/8 and flag ZERO exist.
    pub const Field = extern struct {
        native_offset: u32,
        wire_offset: u32,
        width: u8,
        flags: u8 = 0,
        reserved: u16 = 0,
    };
    pub const Schema = struct {
        native_bytes: u32,
        wire_bytes: u32,
        fields: []const Field,
        fn descriptorSpan(self: Schema) Span {
            return .{ .address = @intFromPtr(self.fields.ptr), .length = self.fields.len * @sizeOf(Field) };
        }
        pub fn validate(self: Schema) Error!void {
            if (self.native_bytes == 0 or self.native_bytes > max_record_bytes or self.wire_bytes == 0 or self.wire_bytes > max_record_bytes or
                self.fields.len == 0 or self.fields.len > max_fields) return error.InvalidSchema;
            if (!self.descriptorSpan().valid()) return error.InvalidSchema;
            var wire_end: u64 = 0;
            for (self.fields, 0..) |field, i| {
                if ((field.width != 4 and field.width != 8) or field.flags & ~zero != 0 or field.reserved != 0 or
                    @as(u64, field.native_offset) + field.width > self.native_bytes or
                    @as(u64, field.wire_offset) + field.width > self.wire_bytes or field.wire_offset < wire_end) return error.InvalidSchema;
                for (self.fields[0..i]) |previous| {
                    if (@as(u64, field.native_offset) < @as(u64, previous.native_offset) + previous.width and
                        @as(u64, previous.native_offset) < @as(u64, field.native_offset) + field.width) return error.InvalidSchema;
                }
                wire_end = @as(u64, field.wire_offset) + field.width;
            }
        }
        fn wireValue(source: []const u8, field: Field) u64 {
            const bytes = source[field.wire_offset..];
            return if (field.width == 4) std.mem.readInt(u32, bytes[0..4], .little) else std.mem.readInt(u64, bytes[0..8], .little);
        }
        fn canonical(self: Schema, source: []const u8) Error!void {
            if (source.len != self.wire_bytes) return error.InvalidLength;
            var position: usize = 0;
            for (self.fields) |field| {
                for (source[position..field.wire_offset]) |byte| if (byte != 0) return error.NonCanonical;
                if (field.flags & zero != 0 and wireValue(source, field) != 0) return error.NonCanonical;
                position = field.wire_offset + @as(usize, field.width);
            }
            for (source[position..]) |byte| if (byte != 0) return error.NonCanonical;
        }
        fn writeUnchecked(self: Schema, source: []const u8, output: []u8) void {
            @memset(output[0..self.wire_bytes], 0);
            for (self.fields) |field| {
                if (field.flags & zero != 0) continue;
                const input = source[field.native_offset..];
                const target = output[field.wire_offset..];
                if (field.width == 4) std.mem.writeInt(u32, target[0..4], std.mem.readInt(u32, input[0..4], native_endian), .little) else std.mem.writeInt(u64, target[0..8], std.mem.readInt(u64, input[0..8], native_endian), .little);
            }
        }
        fn readUnchecked(self: Schema, source: []const u8, output: []u8) void {
            @memset(output[0..self.native_bytes], 0);
            for (self.fields) |field| {
                const target = output[field.native_offset..];
                const value = wireValue(source, field);
                if (field.width == 4) std.mem.writeInt(u32, target[0..4], @intCast(value), native_endian) else std.mem.writeInt(u64, target[0..8], value, native_endian);
            }
        }
        pub fn encode(self: Schema, source: []const u8, output: []u8) Error!void {
            try self.validate();
            if (source.len < self.native_bytes) return error.InvalidLength;
            if (output.len < self.wire_bytes) return error.Capacity;
            if (!Span.of(source).valid() or !Span.of(output).valid()) return error.InvalidArgument;
            const target = Span.of(output[0..self.wire_bytes]);
            if (target.intersects(Span.of(source[0..self.native_bytes])) or target.intersects(self.descriptorSpan())) return error.Overlap;
            self.writeUnchecked(source, output);
        }
        pub fn decode(self: Schema, source: []const u8, output: []u8) Error!void {
            try self.validate();
            if (output.len < self.native_bytes) return error.Capacity;
            if (!Span.of(source).valid() or !Span.of(output).valid()) return error.InvalidArgument;
            const target = Span.of(output[0..self.native_bytes]);
            if (target.intersects(Span.of(source)) or target.intersects(self.descriptorSpan())) return error.Overlap;
            try self.canonical(source);
            self.readUnchecked(source, output);
        }
    };
    fn count(comptime T: type) usize {
        return switch (@typeInfo(T)) {
            .int => |info| if (info.bits == 32 or info.bits == 64) 1 else @compileError("Canonical cache fields require32/64bit integers"),
            .@"struct" => |info| blk: {
                if (info.layout != .@"extern") @compileError("Canonical cache records require explicit extern layout");
                var result: usize = 0;
                for (info.fields) |field| result += count(field.type);
                break :blk result;
            },
            else => @compileError("Canonical cache fields reject pointers, arrays, floats and implicit layout"),
        };
    }
    fn selected(comptime path: []const u8, comptime names: []const []const u8) bool {
        for (names) |name| if (std.mem.eql(u8, path, name)) return true;
        return false;
    }
    fn fill(comptime T: type, comptime offset: usize, comptime path: []const u8, comptime names: []const []const u8, fields: []Field, at: *usize) void {
        switch (@typeInfo(T)) {
            .int => {
                fields[at.*] = .{ .native_offset = offset, .wire_offset = offset, .width = @sizeOf(T), .flags = if (selected(path, names)) zero else 0 };
                at.* += 1;
            },
            .@"struct" => inline for (std.meta.fields(T)) |field| {
                const name = if (path.len == 0) field.name else path ++ "." ++ field.name;
                fill(field.type, offset + @offsetOf(T, field.name), name, names, fields, at);
            },
            else => unreachable,
        }
    }
    fn pathExists(comptime T: type, comptime path: []const u8, comptime name: []const u8) bool {
        return switch (@typeInfo(T)) {
            .int => std.mem.eql(u8, path, name),
            .@"struct" => blk: {
                for (std.meta.fields(T)) |field| {
                    if (pathExists(field.type, if (path.len == 0) field.name else path ++ "." ++ field.name, name)) break :blk true;
                }
                break :blk false;
            },
            else => false,
        };
    }
    /// Derive the already explicit extern contract layout. Padding is always
    /// canonical zero, not read from native memory. Names may be dotted paths.
    pub fn Record(comptime T: type, comptime zero_fields: []const []const u8) type {
        @setEvalBranchQuota(200000);
        if (@sizeOf(T) > max_record_bytes or count(T) == 0 or count(T) > max_fields) @compileError("Canonical cache record exceeds bounded schema");
        for (zero_fields, 0..) |name, i| {
            if (!pathExists(T, "", name)) @compileError("Unknown canonical transient field " ++ name);
            for (zero_fields[0..i]) |previous| if (std.mem.eql(u8, previous, name)) @compileError("Duplicate canonical transient field " ++ name);
        }
        return struct {
            const definitions = blk: {
                @setEvalBranchQuota(200000);
                var fields: [count(T)]Field = undefined;
                var at: usize = 0;
                fill(T, 0, "", zero_fields, &fields, &at);
                break :blk fields;
            };
            pub const schema: Schema = .{ .native_bytes = @sizeOf(T), .wire_bytes = @sizeOf(T), .fields = &definitions };
            pub fn encode(value: *const T, output: []u8) Error!void {
                return schema.encode(std.mem.asBytes(value), output);
            }
            pub fn decode(source: []const u8) Error!T {
                var value: T = undefined;
                try schema.decode(source, std.mem.asBytes(&value));
                return value;
            }
        };
    }
};

/// Rule owns magic[8], format_revision, compiler_revision, max_payload_bytes,
/// transient_fields, compilerIdentity(), valid_key() and valid_metadata().
/// The actual vendor validators/identity remain external pure synchronous
/// admission code. Every caller pointer and descriptor loan lasts to return.
pub fn CanonicalCacheEnvelope(comptime Key: type, comptime Metadata: type, comptime Rule: type) type {
    const KeyRecord = ScalarSchemaCodec.Record(Key, &.{});
    const MetadataRecord = ScalarSchemaCodec.Record(Metadata, Rule.transient_fields);
    return struct {
        pub const key_offset = 64;
        pub const metadata_offset = key_offset + @sizeOf(Key);
        pub const digest_offset = metadata_offset + @sizeOf(Metadata);
        pub const payload_offset = digest_offset + 32;
        fn descriptorsOverlap(output: Span) bool {
            return output.intersects(KeyRecord.schema.descriptorSpan()) or output.intersects(MetadataRecord.schema.descriptorSpan());
        }
        pub fn requiredBytes(payload_bytes: usize) Error!usize {
            if (payload_bytes == 0 or payload_bytes > Rule.max_payload_bytes) return error.InvalidLength;
            return std.math.add(usize, payload_offset, payload_bytes) catch error.Overflow;
        }
        fn digest(prefix: []const u8, payload: []const u8) [32]u8 {
            var hasher: Sha256 = .init(.{});
            hasher.update(prefix);
            hasher.update(payload);
            return hasher.finalResult();
        }
        pub fn encode(key: *const Key, metadata: *const Metadata, payload: [*]const u8, payload_bytes: u64, output: [*]u8, capacity: u64, written: *u64) Error!usize {
            const count_bytes = std.math.cast(usize, payload_bytes) orelse return error.Overflow;
            const output_bytes = std.math.cast(usize, capacity) orelse return error.Overflow;
            if (!Rule.valid_key(key) or !Rule.valid_metadata(key, metadata, count_bytes) or
                !validSpan(@intFromPtr(payload), count_bytes) or !validSpan(@intFromPtr(output), output_bytes)) return error.InvalidArgument;
            try KeyRecord.schema.validate();
            try MetadataRecord.schema.validate();
            const total = try requiredBytes(count_bytes);
            if (output_bytes < total) return error.Capacity;
            const target = Span{ .address = @intFromPtr(output), .length = total };
            const publish = Span.object(written);
            const sources = [_]Span{ Span.object(key), Span.object(metadata), .{ .address = @intFromPtr(payload), .length = count_bytes } };
            if (!publish.valid()) return error.InvalidArgument;
            if (target.intersects(publish) or descriptorsOverlap(target) or descriptorsOverlap(publish)) return error.Overlap;
            for (sources) |source| {
                if (!source.valid()) return error.InvalidArgument;
                if (target.intersects(source) or publish.intersects(source)) return error.Overlap;
            }
            // No fallible work after this point. Native padding/transient fields
            // are never persisted, and written publishes only the complete blob.
            const bytes = output[0..total];
            @memset(bytes[0..payload_offset], 0);
            @memcpy(bytes[0..8], &Rule.magic);
            std.mem.writeInt(u32, bytes[8..12], Rule.format_revision, .little);
            std.mem.writeInt(u32, bytes[12..16], Rule.compiler_revision, .little);
            std.mem.writeInt(u64, bytes[16..24], total, .little);
            std.mem.writeInt(u32, bytes[24..28], @sizeOf(Key), .little);
            std.mem.writeInt(u32, bytes[28..32], @sizeOf(Metadata), .little);
            @memcpy(bytes[32..64], &Rule.compilerIdentity());
            KeyRecord.schema.writeUnchecked(std.mem.asBytes(key), bytes[key_offset..metadata_offset]);
            MetadataRecord.schema.writeUnchecked(std.mem.asBytes(metadata), bytes[metadata_offset..digest_offset]);
            @memcpy(bytes[digest_offset..payload_offset], &digest(bytes[0..digest_offset], payload[0..count_bytes]));
            @memcpy(bytes[payload_offset..], payload[0..count_bytes]);
            written.* = total;
            return total;
        }
        pub fn decode(expected_key: *const Key, input: [*]const u8, length: u64, metadata_output: *Metadata, payload_output: [*]u8, capacity: u64) Error!usize {
            const input_bytes = std.math.cast(usize, length) orelse return error.Overflow;
            const output_bytes = std.math.cast(usize, capacity) orelse return error.Overflow;
            if (!Rule.valid_key(expected_key) or !validSpan(@intFromPtr(input), input_bytes) or !validSpan(@intFromPtr(payload_output), output_bytes)) return error.InvalidArgument;
            if (input_bytes < payload_offset or input_bytes - payload_offset > Rule.max_payload_bytes) return error.InvalidLength;
            try KeyRecord.schema.validate();
            try MetadataRecord.schema.validate();
            const bytes = input[0..input_bytes];
            if (!std.mem.eql(u8, bytes[0..8], &Rule.magic)) return error.UnknownFormat;
            if (std.mem.readInt(u32, bytes[8..12], .little) != Rule.format_revision or std.mem.readInt(u32, bytes[12..16], .little) != Rule.compiler_revision) return error.VersionMismatch;
            if (std.mem.readInt(u64, bytes[16..24], .little) != length or std.mem.readInt(u32, bytes[24..28], .little) != @sizeOf(Key) or
                std.mem.readInt(u32, bytes[28..32], .little) != @sizeOf(Metadata)) return error.InvalidLength;
            if (!std.mem.eql(u8, bytes[32..64], &Rule.compilerIdentity())) return error.IdentityMismatch;
            const stored_key = try KeyRecord.decode(bytes[key_offset..metadata_offset]);
            const stored_metadata = try MetadataRecord.decode(bytes[metadata_offset..digest_offset]);
            const payload_bytes = input_bytes - payload_offset;
            if (!std.meta.eql(stored_key, expected_key.*) or !Rule.valid_metadata(expected_key, &stored_metadata, payload_bytes)) return error.InvalidLength;
            if (!std.mem.eql(u8, bytes[digest_offset..payload_offset], &digest(bytes[0..digest_offset], bytes[payload_offset..]))) return error.IntegrityMismatch;
            if (output_bytes < payload_bytes) return error.Capacity;
            const target = Span{ .address = @intFromPtr(payload_output), .length = payload_bytes };
            const metadata = Span.object(metadata_output);
            const source = Span.of(bytes);
            const key_source = Span.object(expected_key);
            if (!metadata.valid() or !key_source.valid()) return error.InvalidArgument;
            if (target.intersects(source) or target.intersects(key_source) or metadata.intersects(source) or metadata.intersects(key_source) or
                metadata.intersects(target) or descriptorsOverlap(target) or descriptorsOverlap(metadata)) return error.Overlap;
            @memcpy(payload_output[0..payload_bytes], bytes[payload_offset..]);
            metadata_output.* = stored_metadata;
            return payload_bytes;
        }
    };
}
