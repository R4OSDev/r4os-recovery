//! Temporary reverse view for the deliberately retained pre-cutover provider.
//! Live functions exist only in the current canonical schema. The four inert
//! holes below cannot supply a callback and disappear with the legacy view.
const std = @import("std");

pub fn project(a: std.mem.Allocator, io: std.Io, current: anytype) !@TypeOf(current.*) {
    const Contract = @TypeOf(current.*);
    const Slot = @typeInfo(@TypeOf(current.groups[0].slots)).pointer.child;
    const Field = @typeInfo(@TypeOf(current.r4x_start.context.fields)).pointer.child;
    const Compatibility = struct {
        groups: []struct { name: []const u8, source_version: u32, current_version: u32, source_magic: u32, tombstones: []Slot },
    };
    const bytes = try std.Io.Dir.cwd().readFileAlloc(io, "API/LegacyProjection.json", a, .limited(64 * 1024));
    const compat = (try std.json.parseFromSlice(Compatibility, a, bytes, .{})).value;
    const raw = try std.json.Stringify.valueAlloc(a, current.*, .{});
    const renamed = try std.mem.replaceOwned(u8, a, raw, "R4XStartContext2", "R4XStartContext");
    var legacy = (try std.json.parseFromSlice(Contract, a, renamed, .{})).value;
    legacy.schema_version = 11;
    legacy.baseline_id = "standalone-contract-0.64.11";
    for (legacy.groups) |*group| {
        for (compat.groups) |origin| {
            if (!std.mem.eql(u8, group.name, origin.name)) continue;
            if (group.abi_version < origin.current_version) return error.LegacyProjectionRevision;
            group.abi_version = try std.math.add(u32, origin.source_version, group.abi_version - origin.current_version);
            group.magic = origin.source_magic;
            group.table_type = group.table_type[0 .. group.table_type.len - 1];
            group.fn_namespace = group.fn_namespace[0 .. group.fn_namespace.len - 1];
            group.query_import = try std.fmt.allocPrint(a, "{s}:Query:1", .{group.name});
            const slots = try a.alloc(Slot, group.slots.len + origin.tombstones.len);
            var next: usize = 0;
            for (slots, 0..) |*slot, number| {
                var hole = false;
                for (origin.tombstones) |retired| {
                    if (retired.number != number) continue;
                    if (retired.state != .tombstone or retired.signature != null or retired.required) return error.LegacyProjectionLiveSlot;
                    slot.* = retired;
                    hole = true;
                    break;
                }
                if (!hole) {
                    slot.* = group.slots[next];
                    next += 1;
                }
                slot.number = @intCast(number);
                slot.offset = 16 + slot.number * 8;
            }
            if (next != group.slots.len) return error.LegacyProjectionSlots;
            group.slots = slots;
            group.size = 16 + @as(u32, @intCast(slots.len)) * 8;
            break;
        }
    }
    const start = &legacy.r4x_start;
    start.magic = 0x53583452;
    start.abi_major = 1;
    start.abi_minor = 1;
    start.entry.symbol = "R4XStart";
    start.entry.version = 1;
    start.context.name = "R4XStartContext";
    start.context.size = 128;
    const start_fields = try a.alloc(Field, start.context.fields.len + 1);
    var index: usize = 0;
    for (start.context.fields) |field| {
        if (std.mem.eql(u8, field.name, "reserved2")) {
            var hole = field;
            hole.name = "reserved_runtime";
            hole.description = "reserved runtime";
            hole.offset = 112;
            start_fields[index] = hole;
            index += 1;
        }
        var value = field;
        if (std.mem.eql(u8, field.name, "magic")) value.default_value = "1398289490";
        if (std.mem.eql(u8, field.name, "abi_major") or std.mem.eql(u8, field.name, "abi_minor")) value.default_value = "1";
        if (std.mem.eql(u8, field.name, "size")) value.default_value = "128";
        if (std.mem.eql(u8, field.name, "reserved2")) value.offset = 120;
        start_fields[index] = value;
        index += 1;
    }
    if (index != start_fields.len) return error.LegacyProjectionStart;
    start.context.fields = start_fields;
    for (start.metadata) |*item| {
        if (std.mem.eql(u8, item.key, "r4x.start")) item.value = "r4xstart";
        if (std.mem.eql(u8, item.key, "r4x.entry")) item.value = "R4XStart";
        if (std.mem.eql(u8, item.key, "r4x.context")) item.value = "R4XStartContext";
    }
    for (legacy.artifact_metadata.r4x_required_metadata) |*item| {
        for (start.metadata) |value| if (std.mem.eql(u8, item.key, value.key)) {
            item.value = value.value;
        };
    }
    for (legacy.abi_roots) |*item| {
        if (std.mem.eql(u8, item.name, "R4XStart2")) item.name = "R4XStart";
        if (std.mem.eql(u8, item.name, "R4LQuery2")) item.name = "R4LQuery";
    }
    const query = &legacy.r4l_query;
    query.magic = 0x314c3452;
    query.abi_version = 1;
    query.entry_symbol = "Query";
    query.entry_version = 1;
    query.layout.name = "R4LQuery";
    query.layout.size = 32;
    const query_fields = try a.alloc(Field, query.layout.fields.len + 1);
    index = 0;
    for (query.layout.fields) |field| {
        if (std.mem.eql(u8, field.name, "reserved")) {
            var hole = field;
            hole.name = "kernel_bridge";
            hole.description = "kernel bridge";
            hole.offset = 16;
            query_fields[index] = hole;
            index += 1;
        }
        var value = field;
        if (std.mem.eql(u8, field.name, "reserved")) value.offset = 24;
        query_fields[index] = value;
        index += 1;
    }
    if (index != query_fields.len) return error.LegacyProjectionQuery;
    query.layout.fields = query_fields;
    return legacy;
}
