// CheckNtfsFixtures0603: proves the shared NTFS structure core against real
// Windows-formatted fixture volumes.
//
// Bootstraps the MFT from the boot sector, loads the volume $UpCase table,
// walks the complete $I30 directory tree (root entries plus INDX sub-node
// blocks with fixups), reads every file through runlists (sparse runs,
// initialized_size clipping, $ATTRIBUTE_LIST-extended attributes) and
// compares SHA256 per file against the manifest that was recorded while the
// volume was mounted by Windows.
//
// Usage:
//   zig run --dep ntfs_format -Mroot=CheckNtfsFixtures0603.zig \
//       -Mntfs_format=Code/System/SDK/r4os/ntfs_format.zig \
//       -- <image.img> <manifest-flat.txt> <expected_cluster_bytes>

const std = @import("std");
const ntfs = @import("ntfs_format");

const MAX_IMAGE_BYTES: usize = 64 * 1024 * 1024;
const MAX_FILE_BYTES: usize = 16 * 1024 * 1024;
const MAX_MFT_RUNS: usize = 128;
const MAX_ATTR_RUNS: usize = 512;

const FILETIME_UNIX_EPOCH: u64 = 116444736000000000;

var failures: usize = 0;

fn fail(comptime format: []const u8, args: anytype) void {
    failures += 1;
    std.debug.print("FAIL: " ++ format ++ "\n", args);
}

const ManifestEntry = struct {
    path: []const u8,
    size: u64,
    sha256: []const u8,
    compressed: bool,
    found: bool = false,
};

const Volume = struct {
    allocator: std.mem.Allocator,
    image: []const u8,
    part_offset: usize,
    boot: ntfs.BootSector,
    record_size: usize,
    mft_runs: [MAX_MFT_RUNS]ntfs.Run = undefined,
    mft_run_count: usize = 0,
    upcase: []const u8 = &[_]u8{},

    fn clusterBytes(self: *const Volume) usize {
        return self.boot.cluster_bytes;
    }

    fn lcnOffset(self: *const Volume, lcn: u64) ?usize {
        const offset = self.part_offset + @as(usize, @intCast(lcn)) * self.clusterBytes();
        if (offset >= self.image.len) return null;
        return offset;
    }

    /// Byte offset of MFT record `number` through the bootstrapped MFT runs.
    fn mftRecordOffset(self: *const Volume, number: u64) ?usize {
        var byte_index = @as(u64, number) * self.record_size;
        var run_index: usize = 0;
        while (run_index < self.mft_run_count) : (run_index += 1) {
            const run = self.mft_runs[run_index];
            const run_bytes = run.length_clusters * self.clusterBytes();
            if (byte_index < run_bytes) {
                const lcn = run.lcn orelse return null;
                const base = self.lcnOffset(lcn) orelse return null;
                const offset = base + @as(usize, @intCast(byte_index));
                if (offset + self.record_size > self.image.len) return null;
                return offset;
            }
            byte_index -= run_bytes;
        }
        return null;
    }

    /// Copies record `number` into `buf`, removes fixups and parses the
    /// header.  Returns null for free/invalid records.
    fn loadRecord(self: *const Volume, number: u64, buf: []u8) ?ntfs.FileRecordHeader {
        const offset = self.mftRecordOffset(number) orelse return null;
        const record = buf[0..self.record_size];
        @memcpy(record, self.image[offset .. offset + self.record_size]);
        if (ntfs.applyFixups(record) != .ok) return null;
        const header = ntfs.FileRecordHeader.parse(record) orelse return null;
        if (header.record_number != number) return null;
        return header;
    }
};

const AttrRuns = struct {
    runs: [MAX_ATTR_RUNS]ntfs.Run = undefined,
    count: usize = 0,
    data_size: u64 = 0,
    initialized_size: u64 = 0,
    flags: u16 = 0,
    resident: bool = false,
    resident_copy: [4096]u8 = undefined,
    resident_len: usize = 0,

    fn appendMapping(self: *AttrRuns, mapping: []const u8) bool {
        var iterator = ntfs.RunlistIterator.init(mapping);
        while (iterator.next()) |run| {
            if (self.count >= self.runs.len) return false;
            self.runs[self.count] = run;
            self.count += 1;
        }
        return !iterator.hadError();
    }
};

/// Collects the complete attribute (all extents) of `attr_type`/`name` for
/// the base record, following $ATTRIBUTE_LIST when present.
fn collectAttribute(volume: *const Volume, record_number: u64, attr_type: ntfs.AttrType, name_utf16: []const u8, out: *AttrRuns) bool {
    var record_buf: [4096]u8 = undefined;
    const header = volume.loadRecord(record_number, record_buf[0..]) orelse return false;
    const record = record_buf[0..volume.record_size];

    if (ntfs.findAttribute(record, header, .attribute_list, &[_]u8{})) |list_attr| {
        var list_storage: [64 * 1024]u8 = undefined;
        var list_bytes: []const u8 = undefined;
        if (!list_attr.non_resident) {
            list_bytes = list_attr.value;
        } else {
            var list_runs = AttrRuns{};
            list_runs.data_size = list_attr.data_size;
            list_runs.initialized_size = list_attr.initialized_size;
            if (!list_runs.appendMapping(list_attr.mapping_pairs)) return false;
            const len = readRunsInto(volume, &list_runs, list_storage[0..]) orelse return false;
            list_bytes = list_storage[0..len];
        }

        var found_any = false;
        var iterator = ntfs.AttributeListIterator.init(list_bytes);
        while (iterator.next()) |entry| {
            if (entry.attr_type != @intFromEnum(attr_type)) continue;
            if (!std.mem.eql(u8, entry.name, name_utf16)) continue;
            var part_buf: [4096]u8 = undefined;
            const part_header = volume.loadRecord(entry.mft_reference.record, part_buf[0..]) orelse return false;
            const part_record = part_buf[0..volume.record_size];
            var part_iter = ntfs.AttributeIterator.init(part_record, part_header);
            while (part_iter.next()) |attribute| {
                if (attribute.attr_type != @intFromEnum(attr_type)) continue;
                if (!std.mem.eql(u8, attribute.name, name_utf16)) continue;
                if (attribute.non_resident and attribute.lowest_vcn != entry.lowest_vcn) continue;
                if (!captureAttribute(attribute, out, entry.lowest_vcn == 0)) return false;
                found_any = true;
            }
        }
        if (found_any) return true;
    }

    const attribute = ntfs.findAttribute(record, header, attr_type, name_utf16) orelse return false;
    return captureAttribute(attribute, out, true);
}

fn captureAttribute(attribute: ntfs.Attribute, out: *AttrRuns, is_first_extent: bool) bool {
    if (!attribute.non_resident) {
        if (attribute.value.len > out.resident_copy.len) return false;
        out.resident = true;
        @memcpy(out.resident_copy[0..attribute.value.len], attribute.value);
        out.resident_len = attribute.value.len;
        out.data_size = attribute.value.len;
        out.initialized_size = attribute.value.len;
        out.flags = attribute.flags;
        return true;
    }
    if (is_first_extent) {
        out.data_size = attribute.data_size;
        out.initialized_size = attribute.initialized_size;
        out.flags = attribute.flags;
    }
    return out.appendMapping(attribute.mapping_pairs);
}

/// Materializes the attribute content into `out` (sparse runs as zeros,
/// bytes past initialized_size as zeros).  Returns the logical length.
fn readRunsInto(volume: *const Volume, attr: *const AttrRuns, out: []u8) ?usize {
    const total: usize = @intCast(attr.data_size);
    if (total > out.len) return null;
    if (attr.resident) {
        @memcpy(out[0..attr.resident_len], attr.resident_copy[0..attr.resident_len]);
        return attr.resident_len;
    }
    @memset(out[0..total], 0);
    const cluster = volume.clusterBytes();
    var position: usize = 0;
    var run_index: usize = 0;
    while (run_index < attr.count and position < total) : (run_index += 1) {
        const run = attr.runs[run_index];
        var run_bytes = @as(usize, @intCast(run.length_clusters)) * cluster;
        if (position + run_bytes > total) run_bytes = total - position;
        if (run.lcn) |lcn| {
            const src = volume.lcnOffset(lcn) orelse return null;
            if (src + run_bytes > volume.image.len) return null;
            var copy_bytes = run_bytes;
            if (position >= attr.initialized_size) {
                copy_bytes = 0;
            } else if (position + copy_bytes > attr.initialized_size) {
                copy_bytes = @intCast(attr.initialized_size - position);
            }
            @memcpy(out[position .. position + copy_bytes], volume.image[src .. src + copy_bytes]);
        }
        position += run_bytes;
    }
    return total;
}

fn readWholeAttribute(volume: *const Volume, record_number: u64, attr_type: ntfs.AttrType, name_utf16: []const u8, allocator: std.mem.Allocator) ?[]u8 {
    var attr = AttrRuns{};
    if (!collectAttribute(volume, record_number, attr_type, name_utf16, &attr)) return null;
    if (attr.data_size > MAX_FILE_BYTES) return null;
    const buffer = allocator.alloc(u8, @intCast(attr.data_size)) catch return null;
    const len = readRunsInto(volume, &attr, buffer) orelse {
        allocator.free(buffer);
        return null;
    };
    return buffer[0..len];
}

// ---------------------------------------------------------------------------
// Directory walk
// ---------------------------------------------------------------------------

const WalkContext = struct {
    volume: *const Volume,
    allocator: std.mem.Allocator,
    manifest: []ManifestEntry,
    files_seen: usize = 0,
    dirs_seen: usize = 0,
    compressed_seen: usize = 0,
    hashed_ok: usize = 0,
    ads_record: ?u64 = null,
    linktgt_record: ?u64 = null,
    hello_record: ?u64 = null,
};

fn utf16ToUtf8(utf16: []const u8, out: []u8) ?usize {
    var len: usize = 0;
    var i: usize = 0;
    while (i + 1 < utf16.len + 1 and i < utf16.len) : (i += 2) {
        const unit = std.mem.readInt(u16, utf16[i..][0..2], .little);
        if (unit >= 0xD800 and unit <= 0xDFFF) return null;
        if (unit < 0x80) {
            if (len + 1 > out.len) return null;
            out[len] = @intCast(unit);
            len += 1;
        } else if (unit < 0x800) {
            if (len + 2 > out.len) return null;
            out[len] = @intCast(0xC0 | (unit >> 6));
            out[len + 1] = @intCast(0x80 | (unit & 0x3F));
            len += 2;
        } else {
            if (len + 3 > out.len) return null;
            out[len] = @intCast(0xE0 | (unit >> 12));
            out[len + 1] = @intCast(0x80 | ((unit >> 6) & 0x3F));
            out[len + 2] = @intCast(0x80 | (unit & 0x3F));
            len += 3;
        }
    }
    return len;
}

fn skipAtRoot(name: []const u8) bool {
    if (name.len == 0) return true;
    if (name[0] == '$') return true;
    if (name[0] == '.') return true;
    if (std.mem.eql(u8, name, "System Volume Information")) return true;
    return false;
}

fn walkDirectory(ctx: *WalkContext, record_number: u64, prefix: []const u8, depth: usize) void {
    if (depth > 16) {
        fail("directory depth over 16 at {s}", .{prefix});
        return;
    }
    const volume = ctx.volume;
    var record_buf: [4096]u8 = undefined;
    const header = volume.loadRecord(record_number, record_buf[0..]) orelse {
        fail("cannot load directory record {d} ({s})", .{ record_number, prefix });
        return;
    };
    const record = record_buf[0..volume.record_size];
    const root_attr = ntfs.findAttribute(record, header, .index_root, &ntfs.I30_NAME_UTF16) orelse {
        fail("directory record {d} has no $I30 INDEX_ROOT ({s})", .{ record_number, prefix });
        return;
    };
    const index_root = ntfs.IndexRoot.parse(root_attr.value) orelse {
        fail("INDEX_ROOT parse failed for record {d}", .{record_number});
        return;
    };
    if (index_root.collation_rule != ntfs.COLLATION_FILE_NAME) {
        fail("unexpected collation {d} in record {d}", .{ index_root.collation_rule, record_number });
        return;
    }

    var blocks: ?[]u8 = null;
    defer if (blocks) |b| ctx.allocator.free(b);
    if (index_root.header.hasSubNodes()) {
        blocks = readWholeAttribute(volume, record_number, .index_allocation, &ntfs.I30_NAME_UTF16, ctx.allocator);
        if (blocks == null) {
            fail("INDEX_ALLOCATION read failed for record {d} ({s})", .{ record_number, prefix });
            return;
        }
    }

    walkIndexEntries(ctx, index_root.entries, blocks, index_root.index_block_bytes, record_number, prefix, depth);
}

fn walkIndexBlock(ctx: *WalkContext, blocks: ?[]u8, block_bytes: u32, vcn: u64, record_number: u64, prefix: []const u8, depth: usize) void {
    const all = blocks orelse {
        fail("sub-node VCN {d} without INDEX_ALLOCATION in record {d}", .{ vcn, record_number });
        return;
    };
    const cluster = ctx.volume.clusterBytes();
    if (cluster > block_bytes) {
        fail("cluster {d} larger than index block {d} is unsupported here", .{ cluster, block_bytes });
        return;
    }
    const start = @as(usize, @intCast(vcn)) * cluster;
    if (start + block_bytes > all.len) {
        fail("index block VCN {d} outside allocation in record {d}", .{ vcn, record_number });
        return;
    }
    const block = all[start .. start + block_bytes];
    if (ntfs.applyFixups(block) != .ok) {
        // A block may already be fixed up from an earlier visit in this walk.
        if (std.mem.readInt(u32, block[0..4], .little) != ntfs.INDX_MAGIC) {
            fail("index block fixup failed at VCN {d} record {d}", .{ vcn, record_number });
            return;
        }
    }
    const parsed = ntfs.IndexBlock.parse(block) orelse {
        fail("index block parse failed at VCN {d} record {d}", .{ vcn, record_number });
        return;
    };
    if (parsed.vcn != vcn) {
        fail("index block self VCN {d} != {d} in record {d}", .{ parsed.vcn, vcn, record_number });
        return;
    }
    walkIndexEntries(ctx, parsed.entries, blocks, block_bytes, record_number, prefix, depth);
}

fn walkIndexEntries(ctx: *WalkContext, entries: []const u8, blocks: ?[]u8, block_bytes: u32, record_number: u64, prefix: []const u8, depth: usize) void {
    var iterator = ntfs.IndexEntryIterator.init(entries);
    var previous_key: ?[]const u8 = null;
    while (iterator.next()) |entry| {
        if (entry.hasSubNode()) {
            walkIndexBlock(ctx, blocks, block_bytes, entry.sub_node_vcn.?, record_number, prefix, depth);
        }
        if (entry.isEnd()) break;
        const file_name = entry.fileName() orelse {
            fail("index entry without $FILE_NAME key in record {d}", .{record_number});
            continue;
        };
        if (previous_key) |prev| {
            if (ntfs.compareFileNames(ctx.volume.upcase, prev, file_name.name) != .lt) {
                fail("index entries not strictly ascending in record {d} ({s})", .{ record_number, prefix });
            }
        }
        previous_key = file_name.name;
        if (file_name.namespace == ntfs.NAMESPACE_DOS) continue;
        processEntry(ctx, entry, file_name, prefix, depth);
    }
}

fn processEntry(ctx: *WalkContext, entry: ntfs.IndexEntry, file_name: ntfs.FileName, prefix: []const u8, depth: usize) void {
    var name_buf: [512]u8 = undefined;
    const name_len = utf16ToUtf8(file_name.name, name_buf[0..]) orelse {
        fail("name UTF-16 decode failed under {s}", .{prefix});
        return;
    };
    const name = name_buf[0..name_len];
    if (depth == 0 and skipAtRoot(name)) return;

    var path_buf: [1024]u8 = undefined;
    var path_len: usize = 0;
    if (prefix.len > 0) {
        @memcpy(path_buf[0..prefix.len], prefix);
        path_len = prefix.len;
        path_buf[path_len] = '/';
        path_len += 1;
    }
    @memcpy(path_buf[path_len .. path_len + name.len], name);
    path_len += name.len;
    const path = path_buf[0..path_len];

    const reference = ntfs.FileReference.parse(entry.file_reference);
    if ((file_name.flags & ntfs.FILE_ATTR_DIRECTORY_DUP) != 0) {
        ctx.dirs_seen += 1;
        const owned_prefix = ctx.allocator.dupe(u8, path) catch {
            fail("out of memory for path {s}", .{path});
            return;
        };
        defer ctx.allocator.free(owned_prefix);
        walkDirectory(ctx, reference.record, owned_prefix, depth + 1);
        return;
    }

    ctx.files_seen += 1;
    if (std.mem.eql(u8, name, "ADSHOST.TXT")) ctx.ads_record = reference.record;
    if (std.mem.eql(u8, name, "LINKTGT.BIN")) ctx.linktgt_record = reference.record;
    if (std.mem.eql(u8, name, "HELLO.TXT")) ctx.hello_record = reference.record;
    verifyFile(ctx, reference, path);
}

fn manifestLookup(ctx: *WalkContext, path: []const u8) ?*ManifestEntry {
    for (ctx.manifest) |*entry| {
        if (std.mem.eql(u8, entry.path, path)) return entry;
    }
    return null;
}

fn verifyFile(ctx: *WalkContext, reference: ntfs.FileReference, path: []const u8) void {
    const manifest_entry = manifestLookup(ctx, path) orelse {
        fail("walker found {s} which is not in the manifest", .{path});
        return;
    };
    if (manifest_entry.found) {
        fail("duplicate walk hit for {s}", .{path});
        return;
    }
    manifest_entry.found = true;

    var attr = AttrRuns{};
    if (!collectAttribute(ctx.volume, reference.record, .data, &[_]u8{}, &attr)) {
        fail("no unnamed $DATA for {s}", .{path});
        return;
    }
    if (attr.data_size != manifest_entry.size) {
        fail("size mismatch for {s}: ntfs={d} manifest={d}", .{ path, attr.data_size, manifest_entry.size });
        return;
    }
    const is_compressed = (attr.flags & ntfs.ATTR_FLAG_COMPRESSED) != 0;
    if (is_compressed != manifest_entry.compressed) {
        fail("compression flag mismatch for {s}: ntfs={} manifest={}", .{ path, is_compressed, manifest_entry.compressed });
        return;
    }
    if (is_compressed) {
        // LZNT1 decode is the 0.60.10 read-completeness step; structure and
        // size are verified here, content is not.
        ctx.compressed_seen += 1;
        return;
    }
    if (attr.data_size > MAX_FILE_BYTES) {
        fail("{s} exceeds checker limit", .{path});
        return;
    }
    const buffer = ctx.allocator.alloc(u8, @intCast(attr.data_size)) catch {
        fail("out of memory reading {s}", .{path});
        return;
    };
    defer ctx.allocator.free(buffer);
    const len = readRunsInto(ctx.volume, &attr, buffer) orelse {
        fail("data read failed for {s}", .{path});
        return;
    };

    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(buffer[0..len], &digest, .{});
    const hex = std.fmt.bytesToHex(digest, .upper);
    if (!std.ascii.eqlIgnoreCase(hex[0..], manifest_entry.sha256)) {
        fail("sha256 mismatch for {s}", .{path});
        return;
    }
    ctx.hashed_ok += 1;
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

fn expectedFiletime(unix_seconds: u64) u64 {
    return FILETIME_UNIX_EPOCH + unix_seconds * 10_000_000;
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len != 4) {
        std.debug.print("Usage: CheckNtfsFixtures0603 <image.img> <manifest-flat.txt> <expected_cluster_bytes>\n", .{});
        std.process.exit(2);
    }

    const image = try cwd.readFileAlloc(io, args[1], allocator, .limited(MAX_IMAGE_BYTES));
    defer allocator.free(image);
    const manifest_text = try cwd.readFileAlloc(io, args[2], allocator, .limited(4 * 1024 * 1024));
    defer allocator.free(manifest_text);
    const expected_cluster = try std.fmt.parseInt(u32, args[3], 10);

    // Manifest lines: path|size|sha256|compressed(0/1)
    var manifest_list: std.ArrayList(ManifestEntry) = .empty;
    defer manifest_list.deinit(allocator);
    var line_iter = std.mem.splitScalar(u8, manifest_text, '\n');
    while (line_iter.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r\xEF\xBB\xBF");
        if (line.len == 0) continue;
        var field_iter = std.mem.splitScalar(u8, line, '|');
        const path = field_iter.next() orelse continue;
        const size_text = field_iter.next() orelse continue;
        const sha = field_iter.next() orelse continue;
        const compressed_text = field_iter.next() orelse continue;
        try manifest_list.append(allocator, .{
            .path = path,
            .size = try std.fmt.parseInt(u64, size_text, 10),
            .sha256 = sha,
            .compressed = std.mem.eql(u8, compressed_text, "1"),
        });
    }

    // MBR partition 1 -> NTFS boot sector.
    if (image.len < 512) {
        std.debug.print("image too small\n", .{});
        std.process.exit(1);
    }
    const part_lba = std.mem.readInt(u32, image[446 + 8 ..][0..4], .little);
    const part_offset = @as(usize, part_lba) * 512;
    var boot: ntfs.BootSector = undefined;
    const boot_result = ntfs.BootSector.parse(image[part_offset..], &boot);
    if (boot_result != .ok) {
        std.debug.print("boot sector parse failed: {s}\n", .{@tagName(boot_result)});
        std.process.exit(1);
    }
    if (boot.cluster_bytes != expected_cluster) {
        fail("cluster bytes {d} != expected {d}", .{ boot.cluster_bytes, expected_cluster });
    }

    var volume = Volume{
        .allocator = allocator,
        .image = image,
        .part_offset = part_offset,
        .boot = boot,
        .record_size = boot.file_record_bytes,
    };

    // Bootstrap the MFT runlist from record 0 read directly at mft_lcn.
    {
        const mft_offset = volume.lcnOffset(boot.mft_lcn) orelse {
            std.debug.print("MFT LCN outside image\n", .{});
            std.process.exit(1);
        };
        var record_buf: [4096]u8 = undefined;
        const record = record_buf[0..volume.record_size];
        @memcpy(record, image[mft_offset .. mft_offset + volume.record_size]);
        if (ntfs.applyFixups(record) != .ok) {
            std.debug.print("MFT record 0 fixups failed\n", .{});
            std.process.exit(1);
        }
        const header = ntfs.FileRecordHeader.parse(record) orelse {
            std.debug.print("MFT record 0 parse failed\n", .{});
            std.process.exit(1);
        };
        const data_attr = ntfs.findAttribute(record, header, .data, &[_]u8{}) orelse {
            std.debug.print("MFT record 0 without $DATA\n", .{});
            std.process.exit(1);
        };
        var iterator = ntfs.RunlistIterator.init(data_attr.mapping_pairs);
        while (iterator.next()) |run| {
            if (volume.mft_run_count >= MAX_MFT_RUNS) break;
            volume.mft_runs[volume.mft_run_count] = run;
            volume.mft_run_count += 1;
        }
        if (iterator.hadError() or volume.mft_run_count == 0) {
            std.debug.print("MFT runlist decode failed\n", .{});
            std.process.exit(1);
        }
    }

    // Load the volume upcase table (128 KB).
    const upcase = readWholeAttribute(&volume, ntfs.MFT_RECORD_UPCASE, .data, &[_]u8{}, allocator) orelse {
        std.debug.print("$UpCase read failed\n", .{});
        std.process.exit(1);
    };
    defer allocator.free(upcase);
    if (upcase.len != ntfs.UPCASE_BYTES) fail("$UpCase size {d} != {d}", .{ upcase.len, ntfs.UPCASE_BYTES });
    volume.upcase = upcase;

    // $Volume version must be 3.1 and clean.
    {
        var record_buf: [4096]u8 = undefined;
        if (volume.loadRecord(ntfs.MFT_RECORD_VOLUME, record_buf[0..])) |header| {
            const record = record_buf[0..volume.record_size];
            if (ntfs.findAttribute(record, header, .volume_information, &[_]u8{})) |attr| {
                if (ntfs.VolumeInformation.parse(attr.value)) |info| {
                    if (info.major != 3 or info.minor != 1) fail("volume version {d}.{d} != 3.1", .{ info.major, info.minor });
                    if ((info.flags & ntfs.VOLUME_FLAG_DIRTY) != 0) fail("fixture volume is dirty", .{});
                } else fail("$VOLUME_INFORMATION parse failed", .{});
            } else fail("$VOLUME_INFORMATION missing", .{});
        } else fail("$Volume record load failed", .{});
    }

    var ctx = WalkContext{
        .volume = &volume,
        .allocator = allocator,
        .manifest = manifest_list.items,
    };
    walkDirectory(&ctx, ntfs.MFT_RECORD_ROOT, "", 0);

    for (ctx.manifest) |entry| {
        if (!entry.found) fail("manifest entry not reached by walker: {s}", .{entry.path});
    }
    if (ctx.files_seen != ctx.manifest.len) {
        fail("walker saw {d} files, manifest has {d}", .{ ctx.files_seen, ctx.manifest.len });
    }

    // Feature spot checks on the full-featured volume.
    if (ctx.ads_record) |ads_record| {
        var name_buf: [16]u8 = undefined;
        const name_len = ntfs.asciiToUtf16("SECOND", name_buf[0..]) orelse 0;
        const ads = readWholeAttribute(&volume, ads_record, .data, name_buf[0..name_len], allocator);
        if (ads) |bytes| {
            defer allocator.free(bytes);
            if (!std.mem.eql(u8, bytes, "alternate stream payload")) fail("ADS content mismatch", .{});
        } else fail("named $DATA stream SECOND not found", .{});
    }
    if (ctx.linktgt_record) |link_record| {
        var record_buf: [4096]u8 = undefined;
        if (volume.loadRecord(link_record, record_buf[0..])) |header| {
            if (header.link_count != 2) fail("hard link count {d} != 2", .{header.link_count});
        } else fail("hard link record load failed", .{});
    }
    if (ctx.hello_record) |hello_record| {
        var record_buf: [4096]u8 = undefined;
        if (volume.loadRecord(hello_record, record_buf[0..])) |header| {
            const record = record_buf[0..volume.record_size];
            if (ntfs.findAttribute(record, header, .standard_information, &[_]u8{})) |attr| {
                if (ntfs.StandardInformation.parse(attr.value)) |si| {
                    if (si.creation_time != expectedFiletime(1577934246)) fail("HELLO.TXT creation FILETIME mismatch: {d}", .{si.creation_time});
                    if (si.data_change_time != expectedFiletime(1620284890)) fail("HELLO.TXT write FILETIME mismatch: {d}", .{si.data_change_time});
                } else fail("HELLO.TXT $STANDARD_INFORMATION parse failed", .{});
            } else fail("HELLO.TXT without $STANDARD_INFORMATION", .{});
        }
    }

    if (failures != 0) {
        std.debug.print("NTFSFIXTURE result: FAILED ({d} failure(s))\n", .{failures});
        std.process.exit(1);
    }
    std.debug.print(
        "NTFSFIXTURE result: OK files={d} dirs={d} hashed={d} compressed={d} cluster={d} record={d}\n",
        .{ ctx.files_seen, ctx.dirs_seen, ctx.hashed_ok, ctx.compressed_seen, boot.cluster_bytes, volume.record_size },
    );
}
