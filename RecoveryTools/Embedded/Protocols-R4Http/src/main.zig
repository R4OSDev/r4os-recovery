const r4os = @import("r4os");

pub const op_capabilities: u32 = 1;
pub const op_build_get: u32 = 2;
pub const op_decode_response: u32 = 3;
pub const op_resolve_redirect: u32 = 4;
pub const op_selftest: u32 = 5;

pub const result_ok: i32 = 0;
pub const result_need_more: i32 = 1;
pub const result_aborted: i32 = 2;
pub const result_bad_buffer: i32 = -2;
pub const result_unknown_op: i32 = -4;
pub const result_output_small: i32 = -5;
pub const result_malformed: i32 = -6;
pub const result_unsupported: i32 = -7;
pub const result_body_too_large: i32 = -8;

var protocol_api: ?*const r4os.r4dev.ProtocolApi2 = null;

comptime {
    if (!@import("builtin").is_test) asm (r4os.technical2.protocolEntriesAsm("r4http_init", "r4http_shutdown", "r4http_query", "r4http_dispatch"));
}

export fn r4http_init(api: *const r4os.r4dev.ProtocolApi2) callconv(.c) i32 {
    var ctx = r4os.r4dev.ProtocolContext2.init(api);
    if (!ctx.requires(.{ "register_role", "set_status" })) return -3;
    protocol_api = api;
    ctx.logInfo("R4HTTP.R4P init");
    if (ctx.registerRole("application.http", .data, 0) != 0) return -4;
    if (ctx.setStatus(.active, "HTTP/1.1 client parser active") != 0) return -5;
    return 0;
}

export fn r4http_shutdown() callconv(.c) i32 {
    protocol_api = null;
    return 0;
}

export fn r4http_query(out: *r4os.abi.ProtocolStatus) callconv(.c) i32 {
    out.* = .{
        .state = @intFromEnum(r4os.abi.ProtocolState.active),
        .flags = 0,
        .last_error = 0,
        .reserved = 0,
        .note = note("R4HTTP ready"),
    };
    return 0;
}

export fn r4http_dispatch(op: u32, in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) callconv(.c) i32 {
    return switch (op) {
        op_capabilities => writeOut(out_buffer, "role=application.http;version=HTTP/1.1;request=GET|HEAD;body=content-length|chunked|close;stream=content-length|content-range|resume;redirect=relative;cancel=bounded"),
        op_build_get => buildGet(in_buffer, out_buffer),
        op_decode_response => decodeResponse(in_buffer, out_buffer),
        op_resolve_redirect => resolveRedirect(in_buffer, out_buffer),
        op_selftest => selftest(out_buffer),
        else => result_unknown_op,
    };
}

fn buildGet(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return result_bad_buffer;
    const url = switch (r4os.http.parseUrl(input)) {
        .value => |value| value,
        .failure => |err| return if (err == .unsupported_scheme) result_unsupported else result_malformed,
    };
    const out = outputBytes(out_buffer) orelse return result_bad_buffer;
    return switch (r4os.http.buildGetRequest(out, url, .{})) {
        .bytes => |bytes| finish(out_buffer, bytes.len),
        .invalid_url => result_malformed,
        .output_too_small => result_output_small,
    };
}

fn decodeResponse(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return result_bad_buffer;
    const out = outputBytes(out_buffer) orelse return result_bad_buffer;
    const header_len: usize = 12;
    if (out.len < header_len) return result_output_small;
    return switch (r4os.http.decodeResponse(input, out[header_len..], true, false)) {
        .complete => |response| blk: {
            @memcpy(out[0..4], "R4HR");
            writeBe16(out[4..6], response.status);
            out[6] = @intFromEnum(response.transfer);
            out[7] = if (response.isRedirect()) 1 else 0;
            writeBe32(out[8..12], @intCast(response.body.len));
            break :blk finish(out_buffer, header_len + response.body.len);
        },
        .need_more => result_need_more,
        .aborted => result_aborted,
        .failure => |err| if (err == .body_too_large) result_body_too_large else result_malformed,
    };
}

fn resolveRedirect(in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const input = inputBytes(in_buffer) orelse return result_bad_buffer;
    const separator = findByte(input, '\n') orelse return result_malformed;
    const base = switch (r4os.http.parseUrl(trimCr(input[0..separator]))) {
        .value => |value| value,
        .failure => return result_malformed,
    };
    const out = outputBytes(out_buffer) orelse return result_bad_buffer;
    return switch (r4os.http.resolveRedirect(base, trimCr(input[separator + 1 ..]), out)) {
        .url => |url| finish(out_buffer, url.len),
        .invalid => result_malformed,
        .output_too_small => result_output_small,
    };
}

fn selftest(out_buffer: *r4os.abi.ProtocolBuffer) i32 {
    const url = switch (r4os.http.parseUrl("https://example.test/start")) {
        .value => |value| value,
        else => return result_malformed,
    };
    var request: [512]u8 = undefined;
    const request_bytes = switch (r4os.http.buildGetRequest(request[0..], url, .{})) {
        .bytes => |bytes| bytes,
        else => return result_output_small,
    };
    if (!contains(request_bytes, "GET /start HTTP/1.1\r\n") or !contains(request_bytes, "Accept-Encoding: identity\r\n")) return result_malformed;

    const response = "HTTP/1.1 302 Found\r\nLocation: /next\r\nTransfer-Encoding: chunked\r\n\r\n4\r\ntest\r\n0\r\n\r\n";
    var body: [16]u8 = undefined;
    if (r4os.http.decodeResponse(response[0 .. response.len - 2], body[0..], false, false) != .need_more) return result_malformed;
    if (r4os.http.decodeResponse(response, body[0..], true, true) != .aborted) return result_malformed;
    const decoded = switch (r4os.http.decodeResponse(response, body[0..], true, false)) {
        .complete => |value| value,
        else => return result_malformed,
    };
    if (!decoded.isRedirect() or decoded.location == null or !equals(decoded.body, "test")) return result_malformed;
    var redirect: [128]u8 = undefined;
    const target = switch (r4os.http.resolveRedirect(url, decoded.location.?, redirect[0..])) {
        .url => |value| value,
        else => return result_malformed,
    };
    if (!equals(target, "https://example.test/next")) return result_malformed;
    const ranged = "HTTP/1.1 206 Partial Content\r\nContent-Length: 4\r\nContent-Range: bytes 6-9/10\r\n\r\ntest";
    var stream_header: [r4os.http.max_header_bytes]u8 = undefined;
    var stream = r4os.http.StreamDecoder.init(stream_header[0..], .get);
    const stream_chunk = switch (stream.push(ranged, false, false)) {
        .chunk => |value| value,
        else => return result_malformed,
    };
    const content_range = stream.response().?.content_range orelse return result_malformed;
    if (!stream_chunk.complete or !equals(stream_chunk.bytes, "test") or !content_range.satisfied or content_range.start != 6 or content_range.end != 9 or content_range.total != 10) return result_malformed;
    return writeOut(out_buffer, "R4HTTP selftest: OK request=GET|HEAD length=ok chunked=ok range=ok stream=ok redirect=ok cancel=ok");
}

fn inputBytes(buffer: *const r4os.abi.ProtocolBuffer) ?[]const u8 {
    if (buffer.data == null or buffer.len > buffer.capacity) return null;
    const ptr: [*]const u8 = @ptrCast(buffer.data.?);
    return ptr[0..buffer.len];
}

fn outputBytes(buffer: *r4os.abi.ProtocolBuffer) ?[]u8 {
    if (buffer.data == null) return null;
    const ptr: [*]u8 = @ptrCast(buffer.data.?);
    return ptr[0..buffer.capacity];
}

fn finish(buffer: *r4os.abi.ProtocolBuffer, len: usize) i32 {
    if (len > buffer.capacity) return result_output_small;
    buffer.len = @intCast(len);
    return result_ok;
}

fn writeOut(buffer: *r4os.abi.ProtocolBuffer, text: []const u8) i32 {
    const out = outputBytes(buffer) orelse return result_bad_buffer;
    if (text.len > out.len) return result_output_small;
    if (text.len > 0) @memcpy(out[0..text.len], text);
    return finish(buffer, text.len);
}

fn writeBe16(out: []u8, value: u16) void {
    out[0] = @intCast(value >> 8);
    out[1] = @intCast(value);
}

fn writeBe32(out: []u8, value: u32) void {
    out[0] = @intCast(value >> 24);
    out[1] = @intCast(value >> 16);
    out[2] = @intCast(value >> 8);
    out[3] = @intCast(value);
}

fn trimCr(value: []const u8) []const u8 {
    return if (value.len > 0 and value[value.len - 1] == '\r') value[0 .. value.len - 1] else value;
}

fn findByte(value: []const u8, needle: u8) ?usize {
    for (value, 0..) |ch, index| {
        if (ch == needle) return index;
    }
    return null;
}

fn contains(value: []const u8, needle: []const u8) bool {
    return stdMemIndexOf(value, needle) != null;
}

fn stdMemIndexOf(value: []const u8, needle: []const u8) ?usize {
    if (needle.len == 0) return 0;
    if (needle.len > value.len) return null;
    var index: usize = 0;
    while (index + needle.len <= value.len) : (index += 1) {
        if (equals(value[index .. index + needle.len], needle)) return index;
    }
    return null;
}

fn equals(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |left, right| {
        if (left != right) return false;
    }
    return true;
}

fn note(comptime text: []const u8) [64]u8 {
    var out: [64]u8 = .{0} ** 64;
    const count = @min(text.len, out.len - 1);
    @memcpy(out[0..count], text[0..count]);
    return out;
}
