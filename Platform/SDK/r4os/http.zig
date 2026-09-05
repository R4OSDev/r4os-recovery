const std = @import("std");

pub const max_header_bytes: usize = 16 * 1024;
pub const max_header_count: usize = 64;
pub const max_set_cookie_headers: usize = 16;
pub const max_redirects: u8 = 20;

pub const Scheme = enum(u8) {
    http,
    https,

    pub fn defaultPort(self: Scheme) u16 {
        return switch (self) {
            .http => 80,
            .https => 443,
        };
    }

    pub fn text(self: Scheme) []const u8 {
        return switch (self) {
            .http => "http",
            .https => "https",
        };
    }
};

pub const UrlError = enum(u8) {
    empty,
    unsupported_scheme,
    missing_host,
    userinfo_forbidden,
    ipv6_not_supported,
    bad_port,
    fragment_forbidden,
    output_too_small,
};

pub const ParsedUrl = struct {
    scheme: Scheme,
    host: []const u8,
    port: u16,
    path: []const u8,
    explicit_port: bool,
    query_only: bool,
};

pub const UrlResult = union(enum) {
    value: ParsedUrl,
    failure: UrlError,
};

pub fn parseUrl(raw_input: []const u8) UrlResult {
    const raw = trimAscii(raw_input);
    if (raw.len == 0) return .{ .failure = .empty };
    if (indexOfByte(raw, '#') != null) return .{ .failure = .fragment_forbidden };

    const scheme_end = indexOf(raw, "://") orelse return .{ .failure = .unsupported_scheme };
    const scheme = if (equalsIgnoreCase(raw[0..scheme_end], "http"))
        Scheme.http
    else if (equalsIgnoreCase(raw[0..scheme_end], "https"))
        Scheme.https
    else
        return .{ .failure = .unsupported_scheme };

    const authority_start = scheme_end + 3;
    if (authority_start >= raw.len) return .{ .failure = .missing_host };
    var authority_end = authority_start;
    while (authority_end < raw.len and raw[authority_end] != '/' and raw[authority_end] != '?') : (authority_end += 1) {}
    const authority = raw[authority_start..authority_end];
    if (authority.len == 0) return .{ .failure = .missing_host };
    if (indexOfByte(authority, '@') != null) return .{ .failure = .userinfo_forbidden };
    if (authority[0] == '[' or indexOfByte(authority, ']') != null) return .{ .failure = .ipv6_not_supported };

    var host = authority;
    var port = scheme.defaultPort();
    var explicit_port = false;
    if (lastIndexOfByte(authority, ':')) |colon| {
        host = authority[0..colon];
        const port_text = authority[colon + 1 ..];
        port = parsePort(port_text) orelse return .{ .failure = .bad_port };
        explicit_port = true;
    }
    if (host.len == 0) return .{ .failure = .missing_host };
    for (host) |ch| {
        if (!isHostByte(ch)) return .{ .failure = .missing_host };
    }

    const query_only = authority_end < raw.len and raw[authority_end] == '?';
    const path = if (authority_end == raw.len)
        "/"
    else
        raw[authority_end..];

    return .{ .value = .{
        .scheme = scheme,
        .host = host,
        .port = port,
        .path = path,
        .explicit_port = explicit_port,
        .query_only = query_only,
    } };
}

pub const RequestOptions = struct {
    user_agent: []const u8 = "Klickifax/0.62",
    accept: []const u8 = "text/html,application/xhtml+xml,text/plain;q=0.8,*/*;q=0.5",
    cookie: []const u8 = "",
    origin: []const u8 = "",
    headers: []const u8 = "",
    connection_close: bool = true,
    content_type: []const u8 = "",
    body: []const u8 = "",
};

pub const Method = enum(u8) {
    get,
    post,
    head,
    put,
    delete,
    patch,
    options,

    pub fn text(self: Method) []const u8 {
        return switch (self) {
            .get => "GET",
            .post => "POST",
            .head => "HEAD",
            .put => "PUT",
            .delete => "DELETE",
            .patch => "PATCH",
            .options => "OPTIONS",
        };
    }
};

pub const BuildResult = union(enum) {
    bytes: []u8,
    invalid_url: UrlError,
    output_too_small,
};

pub fn buildGetRequest(out: []u8, url: ParsedUrl, options: RequestOptions) BuildResult {
    return buildRequest(out, .get, url, options);
}

pub fn buildRequest(out: []u8, method: Method, url: ParsedUrl, options: RequestOptions) BuildResult {
    var pos: usize = 0;
    if (!append(out, &pos, method.text()) or
        !appendByte(out, &pos, ' ') or
        (url.query_only and !appendByte(out, &pos, '/')) or
        !append(out, &pos, url.path) or
        !append(out, &pos, " HTTP/1.1\r\nHost: ") or
        !append(out, &pos, url.host))
    {
        return .output_too_small;
    }
    if (url.explicit_port or url.port != url.scheme.defaultPort()) {
        if (!appendByte(out, &pos, ':') or !appendUnsigned(out, &pos, url.port)) return .output_too_small;
    }
    if (!append(out, &pos, "\r\nUser-Agent: ") or !appendHeaderValue(out, &pos, options.user_agent) or !append(out, &pos, "\r\n")) return .output_too_small;
    if (!containsSerializedHeader(options.headers, "accept") and (!append(out, &pos, "Accept: ") or !appendHeaderValue(out, &pos, options.accept) or !append(out, &pos, "\r\n"))) return .output_too_small;
    if (!append(out, &pos, "Accept-Encoding: identity\r\n")) return .output_too_small;
    if (options.cookie.len > 0 and
        (!append(out, &pos, "Cookie: ") or !appendHeaderValue(out, &pos, options.cookie) or !append(out, &pos, "\r\n")))
    {
        return .output_too_small;
    }
    if (options.origin.len > 0 and
        (!append(out, &pos, "Origin: ") or !appendHeaderValue(out, &pos, options.origin) or !append(out, &pos, "\r\n")))
    {
        return .output_too_small;
    }
    if (options.headers.len > 0 and !appendSerializedHeaders(out, &pos, options.headers)) return .output_too_small;
    if (options.body.len > 0) {
        if (!containsSerializedHeader(options.headers, "content-type")) {
            const content_type = if (options.content_type.len > 0) options.content_type else "application/x-www-form-urlencoded";
            if (!append(out, &pos, "Content-Type: ") or !appendHeaderValue(out, &pos, content_type) or !append(out, &pos, "\r\n")) return .output_too_small;
        }
        if (!append(out, &pos, "Content-Length: ") or !appendUnsigned(out, &pos, options.body.len) or !append(out, &pos, "\r\n")) return .output_too_small;
    }
    if (options.connection_close and !append(out, &pos, "Connection: close\r\n")) return .output_too_small;
    if (!append(out, &pos, "\r\n")) return .output_too_small;
    if (options.body.len > 0 and !append(out, &pos, options.body)) return .output_too_small;
    return .{ .bytes = out[0..pos] };
}

fn appendSerializedHeaders(out: []u8, pos: *usize, serialized: []const u8) bool {
    var cursor: usize = 0;
    while (cursor < serialized.len) {
        const relative_end = std.mem.indexOfScalar(u8, serialized[cursor..], '\n') orelse return false;
        const line = serialized[cursor .. cursor + relative_end];
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse return false;
        if (colon == 0 or !append(out, pos, line[0..colon]) or !append(out, pos, ": ") or !appendHeaderValue(out, pos, line[colon + 1 ..]) or !append(out, pos, "\r\n")) return false;
        cursor += relative_end + 1;
    }
    return true;
}

fn containsSerializedHeader(serialized: []const u8, wanted: []const u8) bool {
    var cursor: usize = 0;
    while (cursor < serialized.len) {
        const relative_end = std.mem.indexOfScalar(u8, serialized[cursor..], '\n') orelse return false;
        const line = serialized[cursor .. cursor + relative_end];
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse return false;
        if (equalsIgnoreCase(line[0..colon], wanted)) return true;
        cursor += relative_end + 1;
    }
    return false;
}

pub const Transfer = enum(u8) {
    none,
    content_length,
    chunked,
    close_delimited,
};

pub const ContentRange = struct {
    satisfied: bool,
    start: u64,
    end: u64,
    total: u64,
};

pub const ResponseError = enum(u8) {
    malformed_status,
    unsupported_version,
    header_too_large,
    too_many_headers,
    malformed_header,
    invalid_content_length,
    conflicting_length,
    unsupported_transfer_encoding,
    malformed_chunk,
    body_too_large,
    redirect_without_location,
    redirect_loop,
    transport_closed_early,
    content_length_required,
    unexpected_body,
};

pub const Response = struct {
    status: u16,
    transfer: Transfer,
    body: []u8,
    headers: []const u8,
    location: ?[]const u8,
    content_type: ?[]const u8,
    content_security_policy: ?[]const u8,
    access_control_allow_origin: ?[]const u8,
    access_control_allow_credentials: bool,
    set_cookie: ?[]const u8,
    set_cookies: [max_set_cookie_headers]?[]const u8,
    set_cookie_count: usize,
    content_range: ?ContentRange,
    consumed: usize,

    pub fn isRedirect(self: Response) bool {
        return self.status == 301 or self.status == 302 or self.status == 303 or self.status == 307 or self.status == 308;
    }
};

pub const DecodeResult = union(enum) {
    complete: Response,
    need_more,
    aborted,
    failure: ResponseError,
};

const ParsedHead = struct {
    status: u16,
    body_start: usize,
    transfer: Transfer,
    content_length: usize,
    headers: []const u8,
    location: ?[]const u8,
    content_type: ?[]const u8,
    content_security_policy: ?[]const u8,
    access_control_allow_origin: ?[]const u8,
    access_control_allow_credentials: bool,
    set_cookie: ?[]const u8,
    set_cookies: [max_set_cookie_headers]?[]const u8,
    set_cookie_count: usize,
    content_range: ?ContentRange,
};

pub fn decodeResponse(input: []const u8, body_out: []u8, eof: bool, stop_requested: bool) DecodeResult {
    if (stop_requested) return .aborted;
    const head = parseHead(input) orelse {
        if (input.len > max_header_bytes) return .{ .failure = .header_too_large };
        return if (eof) .{ .failure = .transport_closed_early } else .need_more;
    };
    if (head.status == 204 or head.status == 304 or (head.status >= 100 and head.status < 200)) {
        return .{ .complete = .{
            .status = head.status,
            .transfer = .none,
            .body = body_out[0..0],
            .headers = head.headers,
            .location = head.location,
            .content_type = head.content_type,
            .content_security_policy = head.content_security_policy,
            .access_control_allow_origin = head.access_control_allow_origin,
            .access_control_allow_credentials = head.access_control_allow_credentials,
            .set_cookie = head.set_cookie,
            .set_cookies = head.set_cookies,
            .set_cookie_count = head.set_cookie_count,
            .content_range = head.content_range,
            .consumed = head.body_start,
        } };
    }

    return switch (head.transfer) {
        .none => .{ .complete = .{
            .status = head.status,
            .transfer = .none,
            .body = body_out[0..0],
            .headers = head.headers,
            .location = head.location,
            .content_type = head.content_type,
            .content_security_policy = head.content_security_policy,
            .access_control_allow_origin = head.access_control_allow_origin,
            .access_control_allow_credentials = head.access_control_allow_credentials,
            .set_cookie = head.set_cookie,
            .set_cookies = head.set_cookies,
            .set_cookie_count = head.set_cookie_count,
            .content_range = head.content_range,
            .consumed = head.body_start,
        } },
        .content_length => decodeContentLength(input, body_out, head),
        .chunked => decodeChunked(input, body_out, head),
        .close_delimited => decodeCloseDelimited(input, body_out, head, eof),
    };
}

fn parseHead(input: []const u8) ?ParsedHead {
    const end = indexOf(input, "\r\n\r\n") orelse return null;
    const body_start = end + 4;
    if (body_start > max_header_bytes) return null;
    const status_end = indexOf(input[0..end], "\r\n") orelse return null;
    const status_line = input[0..status_end];
    if (!startsWith(status_line, "HTTP/1.1 ") and !startsWith(status_line, "HTTP/1.0 ")) return null;
    if (status_line.len < 12 or !isDigit(status_line[9]) or !isDigit(status_line[10]) or !isDigit(status_line[11])) return null;
    const status = @as(u16, status_line[9] - '0') * 100 + @as(u16, status_line[10] - '0') * 10 + @as(u16, status_line[11] - '0');

    var cursor = status_end + 2;
    var count: usize = 0;
    var content_length: ?usize = null;
    var chunked = false;
    var location: ?[]const u8 = null;
    var content_type: ?[]const u8 = null;
    var content_security_policy: ?[]const u8 = null;
    var access_control_allow_origin: ?[]const u8 = null;
    var access_control_allow_credentials = false;
    var set_cookie: ?[]const u8 = null;
    var set_cookies = [_]?[]const u8{null} ** max_set_cookie_headers;
    var set_cookie_count: usize = 0;
    var content_range: ?ContentRange = null;
    while (cursor < end) {
        count += 1;
        if (count > max_header_count) return null;
        const relative_end = indexOf(input[cursor..body_start], "\r\n") orelse return null;
        const line_end = cursor + relative_end;
        const line = input[cursor..line_end];
        const colon = indexOfByte(line, ':') orelse return null;
        const name = line[0..colon];
        const value = trimAscii(line[colon + 1 ..]);
        if (name.len == 0 or !isHeaderName(name) or hasForbiddenHeaderByte(value)) return null;
        if (equalsIgnoreCase(name, "Content-Length")) {
            const parsed = parseDecimal(value) orelse return null;
            if (content_length != null and content_length.? != parsed) return null;
            content_length = parsed;
        } else if (equalsIgnoreCase(name, "Transfer-Encoding")) {
            if (!equalsIgnoreCase(value, "chunked")) return null;
            chunked = true;
        } else if (equalsIgnoreCase(name, "Location")) {
            location = value;
        } else if (equalsIgnoreCase(name, "Content-Type")) {
            content_type = value;
        } else if (equalsIgnoreCase(name, "Content-Security-Policy")) {
            content_security_policy = value;
        } else if (equalsIgnoreCase(name, "Access-Control-Allow-Origin")) {
            access_control_allow_origin = value;
        } else if (equalsIgnoreCase(name, "Access-Control-Allow-Credentials")) {
            access_control_allow_credentials = equalsIgnoreCase(value, "true");
        } else if (equalsIgnoreCase(name, "Set-Cookie")) {
            if (set_cookie == null) set_cookie = value;
            if (set_cookie_count < set_cookies.len) {
                set_cookies[set_cookie_count] = value;
                set_cookie_count += 1;
            }
        } else if (equalsIgnoreCase(name, "Content-Range")) {
            if (content_range != null) return null;
            content_range = parseContentRange(value) orelse return null;
        }
        cursor = line_end + 2;
    }
    if (chunked and content_length != null) return null;
    return .{
        .status = status,
        .body_start = body_start,
        .transfer = if (chunked) .chunked else if (content_length != null) .content_length else .close_delimited,
        .content_length = content_length orelse 0,
        .headers = input[status_end + 2 .. end],
        .location = location,
        .content_type = content_type,
        .content_security_policy = content_security_policy,
        .access_control_allow_origin = access_control_allow_origin,
        .access_control_allow_credentials = access_control_allow_credentials,
        .set_cookie = set_cookie,
        .set_cookies = set_cookies,
        .set_cookie_count = set_cookie_count,
        .content_range = content_range,
    };
}

fn decodeContentLength(input: []const u8, out: []u8, head: ParsedHead) DecodeResult {
    if (head.content_length > out.len) return .{ .failure = .body_too_large };
    if (input.len < head.body_start + head.content_length) return .need_more;
    if (head.content_length > 0) @memcpy(out[0..head.content_length], input[head.body_start .. head.body_start + head.content_length]);
    return .{ .complete = .{
        .status = head.status,
        .transfer = .content_length,
        .body = out[0..head.content_length],
        .headers = head.headers,
        .location = head.location,
        .content_type = head.content_type,
        .content_security_policy = head.content_security_policy,
        .access_control_allow_origin = head.access_control_allow_origin,
        .access_control_allow_credentials = head.access_control_allow_credentials,
        .set_cookie = head.set_cookie,
        .set_cookies = head.set_cookies,
        .set_cookie_count = head.set_cookie_count,
        .content_range = head.content_range,
        .consumed = head.body_start + head.content_length,
    } };
}

fn decodeCloseDelimited(input: []const u8, out: []u8, head: ParsedHead, eof: bool) DecodeResult {
    const available = input.len - head.body_start;
    if (available > out.len) return .{ .failure = .body_too_large };
    if (!eof) return .need_more;
    if (available > 0) @memcpy(out[0..available], input[head.body_start..]);
    return .{ .complete = .{
        .status = head.status,
        .transfer = .close_delimited,
        .body = out[0..available],
        .headers = head.headers,
        .location = head.location,
        .content_type = head.content_type,
        .content_security_policy = head.content_security_policy,
        .access_control_allow_origin = head.access_control_allow_origin,
        .access_control_allow_credentials = head.access_control_allow_credentials,
        .set_cookie = head.set_cookie,
        .set_cookies = head.set_cookies,
        .set_cookie_count = head.set_cookie_count,
        .content_range = head.content_range,
        .consumed = input.len,
    } };
}

fn decodeChunked(input: []const u8, out: []u8, head: ParsedHead) DecodeResult {
    var cursor = head.body_start;
    var written: usize = 0;
    while (true) {
        const line_rel = indexOf(input[cursor..], "\r\n") orelse return .need_more;
        const line_end = cursor + line_rel;
        var size_text = input[cursor..line_end];
        if (indexOfByte(size_text, ';')) |semi| size_text = size_text[0..semi];
        const chunk_size = parseHex(trimAscii(size_text)) orelse return .{ .failure = .malformed_chunk };
        cursor = line_end + 2;
        if (chunk_size == 0) {
            if (input.len < cursor + 2) return .need_more;
            if (input[cursor] == '\r' and input[cursor + 1] == '\n') {
                cursor += 2;
            } else {
                const trailers_end = indexOf(input[cursor..], "\r\n\r\n") orelse return .need_more;
                cursor += trailers_end + 4;
            }
            return .{ .complete = .{
                .status = head.status,
                .transfer = .chunked,
                .body = out[0..written],
                .headers = head.headers,
                .location = head.location,
                .content_type = head.content_type,
                .content_security_policy = head.content_security_policy,
                .access_control_allow_origin = head.access_control_allow_origin,
                .access_control_allow_credentials = head.access_control_allow_credentials,
                .set_cookie = head.set_cookie,
                .set_cookies = head.set_cookies,
                .set_cookie_count = head.set_cookie_count,
                .content_range = head.content_range,
                .consumed = cursor,
            } };
        }
        if (chunk_size > out.len - written) return .{ .failure = .body_too_large };
        if (input.len < cursor + chunk_size + 2) return .need_more;
        if (input[cursor + chunk_size] != '\r' or input[cursor + chunk_size + 1] != '\n') return .{ .failure = .malformed_chunk };
        @memcpy(out[written .. written + chunk_size], input[cursor .. cursor + chunk_size]);
        written += chunk_size;
        cursor += chunk_size + 2;
    }
}

pub const StreamResponse = struct {
    status: u16,
    transfer: Transfer,
    content_length: u64,
    location: ?[]const u8,
    content_type: ?[]const u8,
    content_range: ?ContentRange,

    pub fn isRedirect(self: StreamResponse) bool {
        return self.status == 301 or self.status == 302 or self.status == 303 or self.status == 307 or self.status == 308;
    }
};

pub const StreamChunk = struct {
    bytes: []const u8,
    complete: bool,
};

pub const StreamDecodeResult = union(enum) {
    chunk: StreamChunk,
    complete,
    need_more,
    aborted,
    failure: ResponseError,
};

pub const StreamDecoder = struct {
    header_buffer: []u8,
    method: Method,
    header_len: usize = 0,
    head: ?ParsedHead = null,
    received: u64 = 0,
    done: bool = false,

    pub fn init(header_buffer: []u8, method: Method) StreamDecoder {
        return .{ .header_buffer = header_buffer, .method = method };
    }

    pub fn response(self: *const StreamDecoder) ?StreamResponse {
        const head = self.head orelse return null;
        return .{
            .status = head.status,
            .transfer = head.transfer,
            .content_length = head.content_length,
            .location = head.location,
            .content_type = head.content_type,
            .content_range = head.content_range,
        };
    }

    pub fn receivedBytes(self: *const StreamDecoder) u64 {
        return self.received;
    }

    pub fn push(self: *StreamDecoder, input: []const u8, eof: bool, stop_requested: bool) StreamDecodeResult {
        if (stop_requested) return .aborted;
        if (self.done) return if (input.len == 0) .complete else .{ .failure = .unexpected_body };
        var body = input;
        if (self.head == null) {
            var consumed: usize = 0;
            while (consumed < input.len) : (consumed += 1) {
                if (self.header_len >= self.header_buffer.len or self.header_len >= max_header_bytes) {
                    return .{ .failure = .header_too_large };
                }
                self.header_buffer[self.header_len] = input[consumed];
                self.header_len += 1;
                if (self.header_len >= 4 and std.mem.eql(u8, self.header_buffer[self.header_len - 4 .. self.header_len], "\r\n\r\n")) {
                    self.head = parseHead(self.header_buffer[0..self.header_len]) orelse return .{ .failure = .malformed_header };
                    body = input[consumed + 1 ..];
                    break;
                }
            }
            if (self.head == null) return if (eof) .{ .failure = .transport_closed_early } else .need_more;
        }

        const head = self.head.?;
        const no_body = self.method == .head or head.status == 204 or head.status == 304 or (head.status >= 100 and head.status < 200);
        if (no_body) {
            if (body.len != 0) return .{ .failure = .unexpected_body };
            self.done = true;
            return .complete;
        }
        if (head.transfer != .content_length) return .{ .failure = .content_length_required };
        const expected: u64 = head.content_length;
        if (self.received > expected or body.len > expected - self.received) return .{ .failure = .conflicting_length };
        self.received += body.len;
        const complete = self.received == expected;
        if (complete) self.done = true;
        if (body.len != 0) return .{ .chunk = .{ .bytes = body, .complete = complete } };
        if (complete) return .complete;
        return if (eof) .{ .failure = .transport_closed_early } else .need_more;
    }
};

pub fn serializedHeadersContain(serialized: []const u8, wanted: []const u8) bool {
    return containsSerializedHeader(serialized, wanted);
}

pub const RedirectResult = union(enum) {
    url: []u8,
    invalid: UrlError,
    output_too_small,
};

pub fn resolveRedirect(base: ParsedUrl, location_input: []const u8, out: []u8) RedirectResult {
    const location = trimAscii(location_input);
    if (location.len == 0) return .{ .invalid = .missing_host };
    if (indexOfByte(location, '#') != null) return .{ .invalid = .fragment_forbidden };
    if (indexOf(location, "://") != null) {
        const parsed = parseUrl(location);
        return switch (parsed) {
            .value => if (copyInto(out, location)) |bytes| .{ .url = bytes } else .output_too_small,
            .failure => |err| .{ .invalid = err },
        };
    }

    var pos: usize = 0;
    if (!append(out, &pos, base.scheme.text()) or !append(out, &pos, "://") or !append(out, &pos, base.host)) return .output_too_small;
    if (base.explicit_port or base.port != base.scheme.defaultPort()) {
        if (!appendByte(out, &pos, ':') or !appendUnsigned(out, &pos, base.port)) return .output_too_small;
    }
    if (startsWith(location, "//")) {
        pos = 0;
        if (!append(out, &pos, base.scheme.text()) or !appendByte(out, &pos, ':') or !append(out, &pos, location)) return .output_too_small;
    } else if (location[0] == '/') {
        if (!append(out, &pos, location)) return .output_too_small;
    } else if (location[0] == '?') {
        const query = indexOfByte(base.path, '?') orelse base.path.len;
        if ((base.query_only and !appendByte(out, &pos, '/')) or
            !append(out, &pos, base.path[0..query]) or
            !append(out, &pos, location))
        {
            return .output_too_small;
        }
    } else {
        const query = indexOfByte(base.path, '?') orelse base.path.len;
        const path_only = base.path[0..query];
        const slash = lastIndexOfByte(path_only, '/') orelse 0;
        if (!append(out, &pos, path_only[0 .. slash + 1]) or !append(out, &pos, location)) return .output_too_small;
    }
    return .{ .url = out[0..pos] };
}

fn parsePort(value: []const u8) ?u16 {
    const parsed = parseDecimal(value) orelse return null;
    if (parsed == 0 or parsed > std.math.maxInt(u16)) return null;
    return @intCast(parsed);
}

fn parseContentRange(value: []const u8) ?ContentRange {
    if (value.len < 9 or !equalsIgnoreCase(value[0..5], "bytes") or value[5] != ' ') return null;
    const range = value[6..];
    const slash = indexOfByte(range, '/') orelse return null;
    if (slash == 0 or slash + 1 >= range.len) return null;
    const total = parseDecimalU64(range[slash + 1 ..]) orelse return null;
    if (total == 0) return null;
    const interval = range[0..slash];
    if (interval.len == 1 and interval[0] == '*') {
        return .{ .satisfied = false, .start = 0, .end = 0, .total = total };
    }
    const dash = indexOfByte(interval, '-') orelse return null;
    if (dash == 0 or dash + 1 >= interval.len) return null;
    const start = parseDecimalU64(interval[0..dash]) orelse return null;
    const end = parseDecimalU64(interval[dash + 1 ..]) orelse return null;
    if (start > end or end >= total) return null;
    return .{ .satisfied = true, .start = start, .end = end, .total = total };
}

fn parseDecimal(value: []const u8) ?usize {
    if (value.len == 0) return null;
    var result: usize = 0;
    for (value) |ch| {
        if (!isDigit(ch)) return null;
        result = std.math.mul(usize, result, 10) catch return null;
        result = std.math.add(usize, result, ch - '0') catch return null;
    }
    return result;
}

fn parseDecimalU64(value: []const u8) ?u64 {
    if (value.len == 0) return null;
    var result: u64 = 0;
    for (value) |ch| {
        if (!isDigit(ch)) return null;
        result = std.math.mul(u64, result, 10) catch return null;
        result = std.math.add(u64, result, ch - '0') catch return null;
    }
    return result;
}

fn parseHex(value: []const u8) ?usize {
    if (value.len == 0) return null;
    var result: usize = 0;
    for (value) |ch| {
        const digit: usize = if (ch >= '0' and ch <= '9')
            ch - '0'
        else if (ch >= 'a' and ch <= 'f')
            ch - 'a' + 10
        else if (ch >= 'A' and ch <= 'F')
            ch - 'A' + 10
        else
            return null;
        result = std.math.mul(usize, result, 16) catch return null;
        result = std.math.add(usize, result, digit) catch return null;
    }
    return result;
}

fn appendHeaderValue(out: []u8, pos: *usize, value: []const u8) bool {
    if (hasForbiddenHeaderByte(value)) return false;
    return append(out, pos, value);
}

fn hasForbiddenHeaderByte(value: []const u8) bool {
    for (value) |ch| {
        if (ch == '\r' or ch == '\n' or ch == 0) return true;
    }
    return false;
}

fn isHeaderName(value: []const u8) bool {
    for (value) |ch| {
        if (!isTokenByte(ch)) return false;
    }
    return value.len != 0;
}

fn isTokenByte(ch: u8) bool {
    if ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or isDigit(ch)) return true;
    return switch (ch) {
        '!', '#', '$', '%', '&', '\'', '*', '+', '-', '.', '^', '_', '`', '|', '~' => true,
        else => false,
    };
}

fn isHostByte(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or isDigit(ch) or ch == '.' or ch == '-';
}

fn isDigit(ch: u8) bool {
    return ch >= '0' and ch <= '9';
}

fn trimAscii(value: []const u8) []const u8 {
    var start: usize = 0;
    var end = value.len;
    while (start < end and (value[start] == ' ' or value[start] == '\t' or value[start] == '\r' or value[start] == '\n')) : (start += 1) {}
    while (end > start and (value[end - 1] == ' ' or value[end - 1] == '\t' or value[end - 1] == '\r' or value[end - 1] == '\n')) : (end -= 1) {}
    return value[start..end];
}

fn append(out: []u8, pos: *usize, value: []const u8) bool {
    if (value.len > out.len -| pos.*) return false;
    if (value.len > 0) @memcpy(out[pos.* .. pos.* + value.len], value);
    pos.* += value.len;
    return true;
}

fn appendByte(out: []u8, pos: *usize, value: u8) bool {
    if (pos.* >= out.len) return false;
    out[pos.*] = value;
    pos.* += 1;
    return true;
}

fn appendUnsigned(out: []u8, pos: *usize, value: anytype) bool {
    var buffer: [20]u8 = undefined;
    const text = std.fmt.bufPrint(buffer[0..], "{d}", .{value}) catch return false;
    return append(out, pos, text);
}

fn copyInto(out: []u8, value: []const u8) ?[]u8 {
    if (value.len > out.len) return null;
    if (value.len > 0) @memcpy(out[0..value.len], value);
    return out[0..value.len];
}

fn indexOf(value: []const u8, needle: []const u8) ?usize {
    return std.mem.indexOf(u8, value, needle);
}

fn indexOfByte(value: []const u8, needle: u8) ?usize {
    return std.mem.indexOfScalar(u8, value, needle);
}

fn lastIndexOfByte(value: []const u8, needle: u8) ?usize {
    return std.mem.lastIndexOfScalar(u8, value, needle);
}

fn startsWith(value: []const u8, prefix: []const u8) bool {
    return std.mem.startsWith(u8, value, prefix);
}

fn equalsIgnoreCase(a: []const u8, b: []const u8) bool {
    return std.ascii.eqlIgnoreCase(a, b);
}

test "URL parser separates HTTP and HTTPS authority" {
    const https = switch (parseUrl("https://Example.COM:8443/search?q=r4os")) {
        .value => |value| value,
        else => return error.TestUnexpectedResult,
    };
    try std.testing.expectEqual(Scheme.https, https.scheme);
    try std.testing.expectEqual(@as(u16, 8443), https.port);
    try std.testing.expectEqualStrings("Example.COM", https.host);
    try std.testing.expectEqualStrings("/search?q=r4os", https.path);
    try std.testing.expect(switch (parseUrl("ftp://example.com/")) {
        .failure => |err| err == .unsupported_scheme,
        else => false,
    });
}

test "GET request prevents header injection and requests identity transfer" {
    const url = switch (parseUrl("http://example.com/a")) {
        .value => |value| value,
        else => return error.TestUnexpectedResult,
    };
    var out: [512]u8 = undefined;
    const request = switch (buildGetRequest(out[0..], url, .{})) {
        .bytes => |bytes| bytes,
        else => return error.TestUnexpectedResult,
    };
    try std.testing.expect(std.mem.indexOf(u8, request, "Host: example.com\r\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, request, "Accept-Encoding: identity\r\n") != null);
    try std.testing.expect(switch (buildGetRequest(out[0..], url, .{ .user_agent = "bad\r\nInjected: yes" })) {
        .output_too_small => true,
        else => false,
    });
}

test "POST request emits an urlencoded entity" {
    const url = switch (parseUrl("https://consent.example/save")) {
        .value => |value| value,
        else => return error.TestUnexpectedResult,
    };
    var out: [512]u8 = undefined;
    const request = switch (buildRequest(out[0..], .post, url, .{
        .origin = "https://example.com",
        .body = "choice=reject&continue=%2Fsearch",
    })) {
        .bytes => |bytes| bytes,
        else => return error.TestUnexpectedResult,
    };
    try std.testing.expect(std.mem.startsWith(u8, request, "POST /save HTTP/1.1\r\n"));
    try std.testing.expect(std.mem.indexOf(u8, request, "Content-Type: application/x-www-form-urlencoded\r\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, request, "Content-Length: 32\r\n") != null);
    try std.testing.expect(std.mem.endsWith(u8, request, "\r\n\r\nchoice=reject&continue=%2Fsearch"));
}

test "request methods and validated custom headers reach the wire once" {
    const parsed = switch (parseUrl("https://example.com/api")) {
        .value => |value| value,
        else => return error.InvalidUrl,
    };
    var output: [2048]u8 = undefined;
    const request = switch (buildRequest(output[0..], .put, parsed, .{
        .headers = "accept:application/json\ncontent-type:application/json\nx-request:r4\n",
        .body = "{\"ok\":true}",
    })) {
        .bytes => |bytes| bytes,
        else => return error.OutputTooSmall,
    };
    try std.testing.expect(std.mem.startsWith(u8, request, "PUT /api HTTP/1.1\r\n"));
    try std.testing.expectEqual(@as(usize, 1), std.mem.count(u8, request, "accept: application/json\r\n"));
    try std.testing.expectEqual(@as(usize, 0), std.mem.count(u8, request, "Accept: text/html"));
    try std.testing.expectEqual(@as(usize, 1), std.mem.count(u8, request, "content-type: application/json\r\n"));
    try std.testing.expect(std.mem.indexOf(u8, request, "x-request: r4\r\nContent-Length: 11\r\n") != null);
    try std.testing.expect(std.mem.endsWith(u8, request, "\r\n\r\n{\"ok\":true}"));
}

test "query-only URL keeps slash in request and redirect" {
    const url = switch (parseUrl("https://example.com?q=1")) {
        .value => |value| value,
        else => return error.TestUnexpectedResult,
    };
    try std.testing.expect(url.query_only);
    try std.testing.expectEqualStrings("?q=1", url.path);

    var request_buffer: [512]u8 = undefined;
    const request = switch (buildGetRequest(request_buffer[0..], url, .{})) {
        .bytes => |bytes| bytes,
        else => return error.TestUnexpectedResult,
    };
    try std.testing.expect(std.mem.startsWith(u8, request, "GET /?q=1 HTTP/1.1\r\n"));

    var redirect_buffer: [128]u8 = undefined;
    const redirected = switch (resolveRedirect(url, "?q=2", redirect_buffer[0..])) {
        .url => |value| value,
        else => return error.TestUnexpectedResult,
    };
    try std.testing.expectEqualStrings("https://example.com/?q=2", redirected);
}

test "content length waits for complete payload and exposes content type" {
    const response = "HTTP/1.1 200 OK\r\nContent-Length: 5\r\nContent-Type: text/html; charset=utf-8\r\n" ++
        "Content-Security-Policy: default-src 'self'\r\nAccess-Control-Allow-Origin: https://app.example\r\n" ++
        "Access-Control-Allow-Credentials: true\r\nSet-Cookie: sid=abc; Secure\r\n" ++
        "Set-Cookie: theme=classic; Path=/\r\n\r\nhello";
    var out: [16]u8 = undefined;
    try std.testing.expect(switch (decodeResponse(response[0 .. response.len - 1], out[0..], false, false)) {
        .need_more => true,
        else => false,
    });
    const complete = switch (decodeResponse(response, out[0..], false, false)) {
        .complete => |value| value,
        else => return error.TestUnexpectedResult,
    };
    try std.testing.expectEqual(@as(u16, 200), complete.status);
    try std.testing.expectEqualStrings("hello", complete.body);
    try std.testing.expectEqualStrings("text/html; charset=utf-8", complete.content_type.?);
    try std.testing.expect(std.mem.indexOf(u8, complete.headers, "Content-Type: text/html; charset=utf-8") != null);
    try std.testing.expectEqualStrings("default-src 'self'", complete.content_security_policy.?);
    try std.testing.expectEqualStrings("https://app.example", complete.access_control_allow_origin.?);
    try std.testing.expect(complete.access_control_allow_credentials);
    try std.testing.expectEqualStrings("sid=abc; Secure", complete.set_cookie.?);
    try std.testing.expectEqual(@as(usize, 2), complete.set_cookie_count);
    try std.testing.expectEqualStrings("sid=abc; Secure", complete.set_cookies[0].?);
    try std.testing.expectEqualStrings("theme=classic; Path=/", complete.set_cookies[1].?);
}

test "chunked body supports extensions and trailers" {
    const response = "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n4;fixture=yes\r\nWiki\r\n5\r\npedia\r\n0\r\nX-End: yes\r\n\r\n";
    var out: [32]u8 = undefined;
    const complete = switch (decodeResponse(response, out[0..], false, false)) {
        .complete => |value| value,
        else => return error.TestUnexpectedResult,
    };
    try std.testing.expectEqual(Transfer.chunked, complete.transfer);
    try std.testing.expectEqualStrings("Wikipedia", complete.body);
}

test "redirect resolution and cancellation stay explicit" {
    const base = switch (parseUrl("https://example.com/a/b/index.html")) {
        .value => |value| value,
        else => return error.TestUnexpectedResult,
    };
    var url_buffer: [128]u8 = undefined;
    const redirected = switch (resolveRedirect(base, "../next?q=1", url_buffer[0..])) {
        .url => |value| value,
        else => return error.TestUnexpectedResult,
    };
    try std.testing.expectEqualStrings("https://example.com/a/b/../next?q=1", redirected);
    var body: [8]u8 = undefined;
    try std.testing.expect(switch (decodeResponse("", body[0..], false, true)) {
        .aborted => true,
        else => false,
    });
}

test "smuggling ambiguity and body overflow fail closed" {
    const ambiguous = "HTTP/1.1 200 OK\r\nContent-Length: 4\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n";
    var out: [3]u8 = undefined;
    try std.testing.expect(switch (decodeResponse(ambiguous, out[0..], true, false)) {
        .failure => true,
        else => false,
    });
    const too_large = "HTTP/1.1 200 OK\r\nContent-Length: 4\r\n\r\ntest";
    try std.testing.expect(switch (decodeResponse(too_large, out[0..], true, false)) {
        .failure => |err| err == .body_too_large,
        else => false,
    });
}

test "stream decoder transfers a multi-megabyte body with bounded caller memory" {
    const total: u64 = 11 * 1024 * 1024;
    const header = "HTTP/1.1 200 OK\r\nContent-Length: 11534336\r\nContent-Type: application/octet-stream\r\n\r\n";
    var header_buffer: [max_header_bytes]u8 = undefined;
    var decoder = StreamDecoder.init(header_buffer[0..], .get);
    try std.testing.expect(decoder.push(header[0..7], false, false) == .need_more);
    try std.testing.expect(decoder.push(header[7..31], false, false) == .need_more);
    try std.testing.expect(decoder.push(header[31..], false, false) == .need_more);
    try std.testing.expectEqual(total, decoder.response().?.content_length);

    var chunk_buffer: [4093]u8 = undefined;
    var offset: u64 = 0;
    while (offset < total) {
        const take: usize = @intCast(@min(@as(u64, chunk_buffer.len), total - offset));
        for (chunk_buffer[0..take], 0..) |*byte, index| byte.* = @truncate(offset + index);
        const chunk = switch (decoder.push(chunk_buffer[0..take], false, false)) {
            .chunk => |value| value,
            else => return error.TestUnexpectedResult,
        };
        try std.testing.expectEqualSlices(u8, chunk_buffer[0..take], chunk.bytes);
        offset += take;
        try std.testing.expectEqual(offset == total, chunk.complete);
    }
    try std.testing.expectEqual(total, decoder.receivedBytes());
    try std.testing.expect(decoder.push("", true, false) == .complete);
}

test "stream decoder exposes ranges and fails closed on truncation and abort" {
    const partial = "HTTP/1.1 206 Partial Content\r\nContent-Length: 4\r\nContent-Range: bytes 6-9/10\r\n\r\ntest";
    var header_buffer: [max_header_bytes]u8 = undefined;
    var decoder = StreamDecoder.init(header_buffer[0..], .get);
    const chunk = switch (decoder.push(partial, false, false)) {
        .chunk => |value| value,
        else => return error.TestUnexpectedResult,
    };
    try std.testing.expect(chunk.complete);
    try std.testing.expectEqualStrings("test", chunk.bytes);
    const range = decoder.response().?.content_range.?;
    try std.testing.expect(range.satisfied);
    try std.testing.expectEqual(@as(u64, 6), range.start);
    try std.testing.expectEqual(@as(u64, 9), range.end);
    try std.testing.expectEqual(@as(u64, 10), range.total);

    const truncated = "HTTP/1.1 200 OK\r\nContent-Length: 8\r\n\r\nshort";
    var truncated_header: [max_header_bytes]u8 = undefined;
    var truncated_decoder = StreamDecoder.init(truncated_header[0..], .get);
    try std.testing.expect(switch (truncated_decoder.push(truncated, false, false)) {
        .chunk => |value| !value.complete,
        else => false,
    });
    try std.testing.expect(switch (truncated_decoder.push("", true, false)) {
        .failure => |failure| failure == .transport_closed_early,
        else => false,
    });

    var aborted_header: [max_header_bytes]u8 = undefined;
    var aborted = StreamDecoder.init(aborted_header[0..], .get);
    try std.testing.expect(aborted.push("", false, true) == .aborted);

    const bad_range = "HTTP/1.1 206 Partial Content\r\nContent-Length: 4\r\nContent-Range: bytes 9-6/10\r\n\r\ntest";
    var bad_header: [max_header_bytes]u8 = undefined;
    var bad = StreamDecoder.init(bad_header[0..], .get);
    try std.testing.expect(switch (bad.push(bad_range, false, false)) {
        .failure => |failure| failure == .malformed_header,
        else => false,
    });
}
