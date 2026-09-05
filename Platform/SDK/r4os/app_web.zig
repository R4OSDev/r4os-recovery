const std = @import("std");
const abi = @import("r4os_contract").abi;
const app_network = @import("app_network.zig");
const http = @import("http.zig");
const r4dev = @import("r4dev.zig");
const time_contract = @import("time_contract.zig");
const web_crypto = @import("web_crypto.zig");

const tls_role = "security.tls";
const tls_op_client_begin: u32 = 27;
const tls_op_client_server_flight: u32 = 28;
const tls_op_client_finish: u32 = 29;
const tls_op_client_app_write: u32 = 30;
const tls_op_client_app_read: u32 = 31;
const tls_stream_state_len: usize = 140;
const tls_app_header_len: usize = 4 + tls_stream_state_len;
const tls_result_header_len: usize = 12;
const max_request_bytes: usize = 12 * 1024;
const max_url_bytes: usize = 1024;
const max_tls_flight_bytes: usize = 16 * 1024;
const max_tls_record_bytes: usize = 5 + 16 * 1024 + 8 + 16;
pub const tls_workspace_bytes: usize = 18 * 1024;
pub const tls_scratch_bytes: usize = tls_workspace_bytes * 3;
comptime {
    std.debug.assert(tls_workspace_bytes >= max_tls_record_bytes + tls_app_header_len);
}

pub const Timeout = time_contract.Timeout;

const RequestDeadline = struct {
    deadline_tick: u64 = 0,
    forever: bool = false,
    valid: bool = true,

    fn start(network: *const app_network.Network, timeout: Timeout) RequestDeadline {
        const wait_ticks = time_contract.timeoutToTicks(timeout, network.sys.monotonicHz()) catch
            return .{ .valid = false };
        return fromTicks(network.sys.ticks(), wait_ticks);
    }

    fn fromTicks(now: u64, wait_ticks: u64) RequestDeadline {
        if (wait_ticks == abi.io_wait_forever) return .{ .forever = true };
        return .{ .deadline_tick = now +| wait_ticks };
    }

    fn remaining(self: RequestDeadline, network: *const app_network.Network) Timeout {
        if (!self.valid) return time_contract.timeoutPoll();
        if (self.forever) return time_contract.timeoutForever();
        const now = network.sys.ticks();
        if (now >= self.deadline_tick) return time_contract.timeoutPoll();
        const duration = time_contract.durationFromTicks(self.deadline_tick - now, network.sys.monotonicHz()) catch
            return time_contract.timeoutPoll();
        return time_contract.timeoutFinite(duration);
    }

    fn expired(self: RequestDeadline, network: *const app_network.Network) bool {
        return !self.valid or (!self.forever and network.sys.ticks() >= self.deadline_tick);
    }
};

pub const Error = enum(u8) {
    invalid_url,
    unsupported_scheme,
    cancelled,
    dns_timeout,
    dns_not_found,
    dns_failed,
    connect_timeout,
    connect_failed,
    write_failed,
    read_failed,
    response_too_large,
    malformed_response,
    cors_preflight_failed,
    cors_rejected,
    policy_rejected,
    redirect_disallowed,
    redirect_without_location,
    redirect_limit,
    tls_unavailable,
    tls_entropy_required,
    tls_handshake_failed,
    tls_alert_handshake_failure,
    tls_alert_illegal_parameter,
    tls_alert_decode_error,
    tls_alert_protocol_version,
    tls_alert_insufficient_security,
    tls_alert_unexpected_message,
    tls_server_flight_malformed,
    tls_server_record_header_invalid,
    tls_server_message_framing_invalid,
    tls_server_hello_invalid,
    tls_server_certificate_list_invalid,
    tls_server_key_exchange_invalid,
    tls_server_hello_done_invalid,
    tls_server_message_unsupported,
    tls_server_flight_incomplete,
    tls_client_flight_buffer_invalid,
    tls_client_flight_header_invalid,
    tls_client_flight_lengths_invalid,
    tls_client_state_length_mismatch,
    tls_server_flight_length_mismatch,
    tls_client_flight_total_length_mismatch,
    tls_client_state_length_zero,
    tls_server_flight_length_zero,
    tls_client_flight_declared_too_large,
    tls_client_flight_has_trailing_input,
    tls_client_state_invalid,
    tls_certificate_rejected,
    tls_certificate_material_unavailable,
    tls_certificate_clock_invalid,
    tls_certificate_parse_failed,
    tls_certificate_hostname_rejected,
    tls_certificate_validity_rejected,
    tls_certificate_chain_rejected,
    tls_certificate_root_rejected,
    tls_server_signature_rejected,
    tls_server_flight_unsupported,
    tls_server_final_flight_invalid,
    tls_server_finished_rejected,
    tls_finished_state_invalid,
    tls_record_failed,
    scratch_too_small,
    request_too_large,
    read_timeout,
    read_reset,
    read_peer_closed,
    tls_close_notify,
    tls_alert_received,
    header_buffer_too_small,
    io_buffer_too_small,
    sink_failed,
    content_length_required,
    content_range_required,
    content_range_mismatch,
    range_header_conflict,
    unsupported_method,
};

pub const CookieProvider = *const fn (?*anyopaque, []const u8, []u8) []const u8;
pub const CookieSink = *const fn (?*anyopaque, []const u8, []const u8) void;
pub const TargetAuthorizer = *const fn (?*anyopaque, []const u8) bool;

pub const RedirectMode = enum(u8) {
    follow,
    error_mode,
    manual,
};

pub const FetchOptions = struct {
    timeout: Timeout = time_contract.timeoutFinite(time_contract.durationFromNanoseconds(10_000_000_000)),
    redirect_limit: u8 = http.max_redirects,
    redirect: RedirectMode = .follow,
    entropy: ?[32]u8 = null,
    stop: ?*const abi.R4StopFlag = null,
    progress: ?*const fn (?*anyopaque) callconv(.c) bool = null,
    progress_context: ?*anyopaque = null,
    cookie: []const u8 = "",
    origin: []const u8 = "",
    headers: []const u8 = "",
    method: http.Method = .get,
    content_type: []const u8 = "",
    body: []const u8 = "",
    cors: bool = false,
    credentials_include: bool = false,
    cookie_provider: ?CookieProvider = null,
    cookie_sink: ?CookieSink = null,
    cookie_context: ?*anyopaque = null,
    target_authorizer: ?TargetAuthorizer = null,
    target_authorization_context: ?*anyopaque = null,
};

pub const FetchResponse = struct {
    status: u16,
    body: []u8,
    headers: []const u8,
    content_type: ?[]const u8,
    content_security_policy: ?[]const u8,
    access_control_allow_origin: ?[]const u8,
    access_control_allow_credentials: bool,
    set_cookie: ?[]const u8,
    set_cookies: [http.max_set_cookie_headers]?[]const u8,
    set_cookie_count: usize,
    redirects: u8,
    manual_redirect: bool,
    secure: bool,
    final_url: FinalUrl,
};

pub const FinalUrl = struct {
    storage: [max_url_bytes + 1]u8 = .{0} ** (max_url_bytes + 1),
    len: usize = 0,

    pub fn bytes(self: *const FinalUrl) []const u8 {
        return self.storage[0..self.len];
    }
};

pub const FetchResult = union(enum) {
    response: FetchResponse,
    failure: Error,
};

pub const DownloadProgress = *const fn (?*anyopaque, u64, u64) bool;
pub const DownloadWrite = *const fn (?*anyopaque, u64, []const u8) bool;

/// A successful write returns only after the supplied bytes are durably owned
/// by the sink.  `offset` is absolute in the final object and makes resume
/// append-only and mechanically checkable by the caller.
pub const DownloadSink = struct {
    context: ?*anyopaque,
    write_fn: DownloadWrite,

    pub fn write(self: DownloadSink, offset: u64, bytes: []const u8) bool {
        return self.write_fn(self.context, offset, bytes);
    }
};

pub const DownloadOptions = struct {
    timeout: Timeout = time_contract.timeoutFinite(time_contract.durationFromNanoseconds(10_000_000_000)),
    redirect_limit: u8 = http.max_redirects,
    entropy: ?[32]u8 = null,
    stop: ?*const abi.R4StopFlag = null,
    progress: ?DownloadProgress = null,
    progress_context: ?*anyopaque = null,
    headers: []const u8 = "",
    method: http.Method = .get,
    resume_from: u64 = 0,
    expected_size: ?u64 = null,
    target_authorizer: ?TargetAuthorizer = null,
    target_authorization_context: ?*anyopaque = null,
};

pub const DownloadResponse = struct {
    status: u16,
    content_length: u64,
    total_size: u64,
    transferred: u64,
    resumed_from: u64,
    redirects: u8,
    secure: bool,
    final_url: FinalUrl,
};

pub const DownloadResult = union(enum) {
    response: DownloadResponse,
    range_not_satisfiable: u64,
    failure: Error,
};

const TlsSession = struct {
    stream_state: [tls_stream_state_len]u8,
};

const TlsSessionResult = union(enum) {
    session: TlsSession,
    failure: Error,
};

const TlsWriteResult = union(enum) {
    ok,
    failure: Error,
};

const TlsApplicationRead = union(enum) {
    bytes: []const u8,
    close_notify,
    failure: Error,
};

const DownloadAttemptResponse = struct {
    status: u16,
    content_length: u64,
    total_size: u64,
    transferred: u64,
};

const DownloadAttemptRedirect = struct {
    status: u16,
    location: []const u8,
};

const DownloadAttemptFailure = struct {
    cause: Error,
    transferred: u64,
    total_size: ?u64,
};

const DownloadAttempt = union(enum) {
    response: DownloadAttemptResponse,
    redirect: DownloadAttemptRedirect,
    range_not_satisfiable: u64,
    failure: DownloadAttemptFailure,
};

const DownloadHeadDecision = union(enum) {
    body: u64,
    response: DownloadAttemptResponse,
    redirect: DownloadAttemptRedirect,
    range_not_satisfiable: u64,
    failure: Error,
};

const DownloadPump = struct {
    decoder: http.StreamDecoder,
    sink: DownloadSink,
    options: DownloadOptions,
    resume_from: u64,
    expected_size: ?u64,
    transferred: u64 = 0,
    total_size: ?u64 = null,
    head_accepted: bool = false,

    fn feed(self: *DownloadPump, input: []const u8, eof: bool, eof_failure: Error) ?DownloadAttempt {
        const step = self.decoder.push(input, eof, downloadStopped(self.options));
        if (!self.head_accepted) {
            if (self.decoder.response()) |response| {
                switch (validateDownloadHead(response, self.options.method, self.resume_from, self.expected_size)) {
                    .body => |total| {
                        self.total_size = total;
                        self.head_accepted = true;
                    },
                    .response => |value| return .{ .response = value },
                    .redirect => |value| return .{ .redirect = value },
                    .range_not_satisfiable => |total| return .{ .range_not_satisfiable = total },
                    .failure => |failure| return self.failed(failure),
                }
            }
        }
        switch (step) {
            .chunk => |chunk| {
                if (!self.sink.write(self.resume_from + self.transferred, chunk.bytes)) return self.failed(.sink_failed);
                self.transferred += chunk.bytes.len;
                const total = self.total_size orelse return self.failed(.malformed_response);
                if (self.options.progress) |progress| {
                    if (!progress(self.options.progress_context, self.resume_from + self.transferred, total)) return self.failed(.cancelled);
                }
                if (chunk.complete) return .{ .response = self.completedResponse() };
            },
            .complete => return .{ .response = self.completedResponse() },
            .need_more => {},
            .aborted => return self.failed(.cancelled),
            .failure => |failure| {
                const cause: Error = if (failure == .transport_closed_early)
                    eof_failure
                else if (failure == .content_length_required)
                    .content_length_required
                else
                    .malformed_response;
                return self.failed(cause);
            },
        }
        return null;
    }

    fn completedResponse(self: *const DownloadPump) DownloadAttemptResponse {
        const response = self.decoder.response().?;
        return .{
            .status = response.status,
            .content_length = response.content_length,
            .total_size = self.total_size orelse response.content_length,
            .transferred = self.transferred,
        };
    }

    fn failed(self: *const DownloadPump, cause: Error) DownloadAttempt {
        return .{ .failure = .{
            .cause = cause,
            .transferred = self.transferred,
            .total_size = self.total_size,
        } };
    }
};

pub const WebTransport = struct {
    network: app_network.Network,
    dev: r4dev.Context,

    pub fn available(self: *const WebTransport) bool {
        return self.network.available() and self.dev.hasFn("protocol_dispatch");
    }

    pub fn fetch(self: *WebTransport, raw_url: []const u8, raw_response: []u8, body_out: []u8, scratch: []u8, options: FetchOptions) FetchResult {
        if (scratch.len < tls_scratch_bytes) return .{ .failure = .scratch_too_small };
        if (raw_url.len == 0 or raw_url.len > max_url_bytes) return .{ .failure = .invalid_url };
        var deadline: RequestDeadline = undefined;
        var deadline_started = false;
        var url_a: [max_url_bytes]u8 = undefined;
        var url_b: [max_url_bytes]u8 = undefined;
        @memcpy(url_a[0..raw_url.len], raw_url);
        var current = url_a[0..raw_url.len];
        var use_a = true;
        var redirects: u8 = 0;
        var read_retries: u8 = 0;
        var method = options.method;
        var content_type = options.content_type;
        var body = options.body;
        var request_headers = options.headers;
        var redirect_headers: [max_request_bytes]u8 = undefined;

        while (true) {
            if (shouldStop(options)) return .{ .failure = .cancelled };
            if (!targetAuthorized(options, current)) return .{ .failure = .policy_rejected };
            const parsed = switch (http.parseUrl(current)) {
                .value => |value| value,
                .failure => |err| return .{ .failure = if (err == .unsupported_scheme) .unsupported_scheme else .invalid_url },
            };
            // Pure cancellation/policy/URL rejection must not dereference a
            // transport clock or open a network context. Start the one shared
            // request deadline only after the first approved URL.
            if (!deadline_started) {
                deadline = RequestDeadline.start(&self.network, options.timeout);
                deadline_started = true;
            }
            if (deadline.expired(&self.network)) return .{ .failure = .read_timeout };
            if (options.cors and isCrossOrigin(options.origin, parsed)) {
                var preflight_headers_buffer: [max_request_bytes]u8 = undefined;
                const preflight_headers = corsPreflightHeaders(method, request_headers, preflight_headers_buffer[0..]) orelse return .{ .failure = .cors_preflight_failed };
                if (preflight_headers.len > 0) {
                    const preflight_once = self.fetchOnce(current, parsed, raw_response, body_out, scratch, options, deadline, .options, preflight_headers, "", "", false, false);
                    const preflight = switch (preflight_once) {
                        .response => |value| value,
                        .failure => return .{ .failure = .cors_preflight_failed },
                    };
                    if (!acceptsPreflight(preflight.http_response, options.origin, method, request_headers, options.credentials_include)) return .{ .failure = .cors_preflight_failed };
                }
            }
            const once = self.fetchOnce(current, parsed, raw_response, body_out, scratch, options, deadline, method, request_headers, content_type, body, redirects == 0, true);
            const response = switch (once) {
                .response => |value| value,
                .failure => |err| {
                    if (shouldRetryReadFailure(method, err, read_retries)) {
                        read_retries += 1;
                        continue;
                    }
                    return .{ .failure = err };
                },
            };
            if (options.cookie_sink) |sink| {
                var cookie_index: usize = 0;
                while (cookie_index < response.http_response.set_cookie_count and cookie_index < response.http_response.set_cookies.len) : (cookie_index += 1) {
                    const header = response.http_response.set_cookies[cookie_index] orelse continue;
                    sink(options.cookie_context, current, header);
                }
            }
            if (options.cors and isCrossOrigin(options.origin, parsed) and !acceptsCorsResponse(response.http_response, options.origin, options.credentials_include)) return .{ .failure = .cors_rejected };
            if (!response.http_response.isRedirect()) {
                return responseResult(response, current, parsed, redirects, false);
            }
            switch (options.redirect) {
                .error_mode => return .{ .failure = .redirect_disallowed },
                .manual => return responseResult(response, current, parsed, redirects, true),
                .follow => {},
            }
            const location = response.http_response.location orelse return .{ .failure = .redirect_without_location };
            if (redirects >= options.redirect_limit) return .{ .failure = .redirect_limit };
            const target_buffer = if (use_a) url_b[0..] else url_a[0..];
            const target = switch (http.resolveRedirect(parsed, location, target_buffer)) {
                .url => |value| value,
                else => return .{ .failure = .invalid_url },
            };
            const target_parsed = switch (http.parseUrl(target)) {
                .value => |value| value,
                else => return .{ .failure = .invalid_url },
            };
            const rewrite_body = (response.http_response.status == 303 and method != .get and method != .head) or
                ((response.http_response.status == 301 or response.http_response.status == 302) and method == .post);
            const strip_sensitive = !sameOrigin(parsed, target_parsed);
            if (rewrite_body or strip_sensitive) {
                request_headers = filterRedirectHeaders(request_headers, redirect_headers[0..], rewrite_body, strip_sensitive) orelse return .{ .failure = .request_too_large };
            }
            current = target;
            use_a = !use_a;
            redirects += 1;
            read_retries = 0;
            if (rewrite_body) {
                method = .get;
                content_type = "";
                body = "";
            }
        }
    }

    pub fn download(
        self: *WebTransport,
        raw_url: []const u8,
        header_buffer: []u8,
        io_buffer: []u8,
        scratch: []u8,
        sink: DownloadSink,
        options: DownloadOptions,
    ) DownloadResult {
        if (scratch.len < tls_scratch_bytes) return .{ .failure = .scratch_too_small };
        if (header_buffer.len < http.max_header_bytes) return .{ .failure = .header_buffer_too_small };
        if (io_buffer.len == 0) return .{ .failure = .io_buffer_too_small };
        if (raw_url.len == 0 or raw_url.len > max_url_bytes) return .{ .failure = .invalid_url };
        if (options.method != .get and options.method != .head) return .{ .failure = .unsupported_method };
        if (options.method == .head and options.resume_from != 0) return .{ .failure = .content_range_mismatch };
        if (http.serializedHeadersContain(options.headers, "Range")) return .{ .failure = .range_header_conflict };
        var deadline: RequestDeadline = undefined;
        var deadline_started = false;

        var url_a: [max_url_bytes]u8 = undefined;
        var url_b: [max_url_bytes]u8 = undefined;
        @memcpy(url_a[0..raw_url.len], raw_url);
        var current = url_a[0..raw_url.len];
        var use_a = true;
        var redirects: u8 = 0;
        var read_retries: u8 = 0;
        var resume_offset = options.resume_from;
        var transferred: u64 = 0;
        var expected_size = options.expected_size;
        var request_headers = options.headers;
        var stripped_headers: [max_request_bytes]u8 = undefined;
        var sensitive_stripped = false;

        while (true) {
            if (downloadStopped(options)) return .{ .failure = .cancelled };
            if (!downloadTargetAuthorized(options, current)) return .{ .failure = .policy_rejected };
            const parsed = switch (http.parseUrl(current)) {
                .value => |value| value,
                .failure => |failure| return .{ .failure = if (failure == .unsupported_scheme) .unsupported_scheme else .invalid_url },
            };
            if (!deadline_started) {
                deadline = RequestDeadline.start(&self.network, options.timeout);
                deadline_started = true;
            }
            if (deadline.expired(&self.network)) return .{ .failure = .read_timeout };
            var ranged_headers: [max_request_bytes]u8 = undefined;
            const headers = appendRangeHeader(request_headers, resume_offset, ranged_headers[0..]) orelse return .{ .failure = .request_too_large };
            const attempt = self.downloadOnce(parsed, headers, header_buffer, io_buffer, scratch, sink, resume_offset, expected_size, options, deadline);
            switch (attempt) {
                .response => |response| {
                    transferred += response.transferred;
                    var final_url = FinalUrl{};
                    @memcpy(final_url.storage[0..current.len], current);
                    final_url.len = current.len;
                    return .{ .response = .{
                        .status = response.status,
                        .content_length = response.content_length,
                        .total_size = response.total_size,
                        .transferred = transferred,
                        .resumed_from = options.resume_from,
                        .redirects = redirects,
                        .secure = parsed.scheme == .https,
                        .final_url = final_url,
                    } };
                },
                .range_not_satisfiable => |total| return .{ .range_not_satisfiable = total },
                .redirect => |redirect| {
                    if (redirects >= options.redirect_limit) return .{ .failure = .redirect_limit };
                    const target_buffer = if (use_a) url_b[0..] else url_a[0..];
                    const target = switch (http.resolveRedirect(parsed, redirect.location, target_buffer)) {
                        .url => |value| value,
                        else => return .{ .failure = .invalid_url },
                    };
                    const target_parsed = switch (http.parseUrl(target)) {
                        .value => |value| value,
                        else => return .{ .failure = .invalid_url },
                    };
                    if (!sameOrigin(parsed, target_parsed) and !sensitive_stripped) {
                        request_headers = filterRedirectHeaders(request_headers, stripped_headers[0..], false, true) orelse return .{ .failure = .request_too_large };
                        sensitive_stripped = true;
                    }
                    current = target;
                    use_a = !use_a;
                    redirects += 1;
                },
                .failure => |failure| {
                    transferred += failure.transferred;
                    resume_offset += failure.transferred;
                    if (failure.total_size) |total| expected_size = total;
                    if (options.method == .get and shouldRetryDownload(failure.cause, read_retries)) {
                        read_retries += 1;
                        continue;
                    }
                    return .{ .failure = failure.cause };
                },
            }
        }
    }

    fn responseResult(response: OnceResponse, current: []const u8, parsed: http.ParsedUrl, redirects: u8, manual_redirect: bool) FetchResult {
        var final_url = FinalUrl{};
        @memcpy(final_url.storage[0..current.len], current);
        final_url.len = current.len;
        return .{ .response = .{
            .status = response.http_response.status,
            .body = response.http_response.body,
            .headers = response.http_response.headers,
            .content_type = response.http_response.content_type,
            .content_security_policy = response.http_response.content_security_policy,
            .access_control_allow_origin = response.http_response.access_control_allow_origin,
            .access_control_allow_credentials = response.http_response.access_control_allow_credentials,
            .set_cookie = response.http_response.set_cookie,
            .set_cookies = response.http_response.set_cookies,
            .set_cookie_count = response.http_response.set_cookie_count,
            .redirects = redirects,
            .manual_redirect = manual_redirect,
            .secure = parsed.scheme == .https,
            .final_url = final_url,
        } };
    }

    const OnceResponse = struct {
        http_response: http.Response,
    };

    const OnceResult = union(enum) {
        response: OnceResponse,
        failure: Error,
    };

    fn fetchOnce(
        self: *WebTransport,
        raw_url: []const u8,
        url: http.ParsedUrl,
        raw_response: []u8,
        body_out: []u8,
        scratch: []u8,
        options: FetchOptions,
        deadline: RequestDeadline,
        method: http.Method,
        headers: []const u8,
        content_type: []const u8,
        body: []const u8,
        allow_legacy_cookie: bool,
        allow_cookies: bool,
    ) OnceResult {
        var resolver = self.network.resolver();
        const address = switch (resolver.resolveA(url.host, null, deadline.remaining(&self.network))) {
            .address => |value| value,
            .timed_out => return .{ .failure = .dns_timeout },
            .not_found => return .{ .failure = .dns_not_found },
            else => return .{ .failure = .dns_failed },
        };
        var socket = switch (self.network.connectTcp(.{ .address = address, .port = url.port }, deadline.remaining(&self.network))) {
            .socket => |value| value,
            .timed_out => return .{ .failure = .connect_timeout },
            else => return .{ .failure = .connect_failed },
        };
        defer _ = socket.close(deadline.remaining(&self.network));

        var cookie_buffer: [1024]u8 = undefined;
        const cookie = if (!allow_cookies)
            ""
        else if (options.cookie_provider) |provider|
            provider(options.cookie_context, raw_url, cookie_buffer[0..])
        else if (allow_legacy_cookie)
            options.cookie
        else
            "";
        var request_buffer: [max_request_bytes]u8 = undefined;
        const request = switch (http.buildRequest(request_buffer[0..], method, url, .{
            .cookie = cookie,
            .origin = options.origin,
            .headers = headers,
            .content_type = content_type,
            .body = body,
        })) {
            .bytes => |value| value,
            else => return .{ .failure = .request_too_large },
        };
        return if (url.scheme == .http)
            self.fetchPlain(&socket, request, raw_response, body_out, options, deadline)
        else
            self.fetchTls(&socket, url, request, raw_response, body_out, scratch, options, deadline);
    }

    fn downloadOnce(
        self: *WebTransport,
        url: http.ParsedUrl,
        headers: []const u8,
        header_buffer: []u8,
        io_buffer: []u8,
        scratch: []u8,
        sink: DownloadSink,
        resume_from: u64,
        expected_size: ?u64,
        options: DownloadOptions,
        deadline: RequestDeadline,
    ) DownloadAttempt {
        var resolver = self.network.resolver();
        const address = switch (resolver.resolveA(url.host, null, deadline.remaining(&self.network))) {
            .address => |value| value,
            .timed_out => return downloadFailure(.dns_timeout),
            .not_found => return downloadFailure(.dns_not_found),
            else => return downloadFailure(.dns_failed),
        };
        var socket = switch (self.network.connectTcp(.{ .address = address, .port = url.port }, deadline.remaining(&self.network))) {
            .socket => |value| value,
            .timed_out => return downloadFailure(.connect_timeout),
            else => return downloadFailure(.connect_failed),
        };
        defer _ = socket.close(deadline.remaining(&self.network));

        var request_buffer: [max_request_bytes]u8 = undefined;
        const request = switch (http.buildRequest(request_buffer[0..], options.method, url, .{ .headers = headers })) {
            .bytes => |value| value,
            else => return downloadFailure(.request_too_large),
        };
        const fetch_options = downloadFetchOptions(options);
        var pump = DownloadPump{
            .decoder = http.StreamDecoder.init(header_buffer, options.method),
            .sink = sink,
            .options = options,
            .resume_from = resume_from,
            .expected_size = expected_size,
        };

        if (url.scheme == .http) {
            if (!writeAll(&socket, request, fetch_options, deadline)) return pump.failed(if (downloadStopped(options)) .cancelled else .write_failed);
            while (true) {
                switch (readSocketBounded(&socket, io_buffer, fetch_options, deadline)) {
                    .bytes => |count| {
                        if (count == 0) continue;
                        if (pump.feed(io_buffer[0..count], false, .read_peer_closed)) |terminal| return terminal;
                    },
                    .peer_closed, .closed => return pump.feed("", true, .read_peer_closed) orelse pump.failed(.read_peer_closed),
                    .cancelled => return pump.failed(.cancelled),
                    .timed_out => return pump.failed(.read_timeout),
                    .reset => return pump.failed(.read_reset),
                    .failed => return pump.failed(.read_failed),
                }
            }
        }

        var session = switch (self.openTlsSession(&socket, url, scratch, fetch_options, deadline)) {
            .session => |value| value,
            .failure => |failure| return pump.failed(failure),
        };
        switch (self.writeTlsApplication(&socket, &session, request, scratch, fetch_options, deadline)) {
            .ok => {},
            .failure => |failure| return pump.failed(failure),
        }
        while (true) {
            switch (self.readTlsApplication(&socket, &session, scratch, fetch_options, deadline)) {
                .bytes => |plain| {
                    if (plain.len == 0) continue;
                    if (pump.feed(plain, false, .tls_close_notify)) |terminal| return terminal;
                },
                .close_notify => return pump.feed("", true, .tls_close_notify) orelse pump.failed(.tls_close_notify),
                .failure => |failure| {
                    if (failure == .read_peer_closed) return pump.feed("", true, failure) orelse pump.failed(failure);
                    return pump.failed(failure);
                },
            }
        }
    }

    fn fetchPlain(self: *WebTransport, socket: *app_network.TcpSocket, request: []const u8, raw_response: []u8, body_out: []u8, options: FetchOptions, deadline: RequestDeadline) OnceResult {
        _ = self;
        if (!writeAll(socket, request, options, deadline)) return .{ .failure = if (shouldStop(options)) .cancelled else .write_failed };
        var received: usize = 0;
        while (true) {
            if (shouldStop(options)) return .{ .failure = .cancelled };
            const decoded = http.decodeResponse(raw_response[0..received], body_out, false, false);
            switch (decoded) {
                .complete => |response| return .{ .response = .{ .http_response = response } },
                .failure => return .{ .failure = .malformed_response },
                .aborted => return .{ .failure = .cancelled },
                .need_more => {},
            }
            if (received == raw_response.len) return .{ .failure = .response_too_large };
            switch (readSocketBounded(socket, raw_response[received..], options, deadline)) {
                .bytes => |count| {
                    if (count == 0) continue;
                    received += count;
                },
                .peer_closed, .closed => {
                    return switch (http.decodeResponse(raw_response[0..received], body_out, true, false)) {
                        .complete => |response| .{ .response = .{ .http_response = response } },
                        else => .{ .failure = .read_peer_closed },
                    };
                },
                .cancelled => return .{ .failure = .cancelled },
                .timed_out => return .{ .failure = .read_timeout },
                .reset => return .{ .failure = .read_reset },
                .failed => return .{ .failure = .read_failed },
            }
        }
    }

    fn fetchTls(self: *WebTransport, socket: *app_network.TcpSocket, url: http.ParsedUrl, request: []const u8, raw_response: []u8, body_out: []u8, scratch: []u8, options: FetchOptions, deadline: RequestDeadline) OnceResult {
        var session = switch (self.openTlsSession(socket, url, scratch, options, deadline)) {
            .session => |value| value,
            .failure => |failure| return .{ .failure = failure },
        };
        switch (self.writeTlsApplication(socket, &session, request, scratch, options, deadline)) {
            .ok => {},
            .failure => |failure| return .{ .failure = failure },
        }

        var received: usize = 0;
        while (true) {
            switch (http.decodeResponse(raw_response[0..received], body_out, false, shouldStop(options))) {
                .complete => |response| return .{ .response = .{ .http_response = response } },
                .aborted => return .{ .failure = .cancelled },
                .failure => return .{ .failure = .malformed_response },
                .need_more => {},
            }
            switch (self.readTlsApplication(socket, &session, scratch, options, deadline)) {
                .bytes => |plain| {
                    if (plain.len > raw_response.len - received) return .{ .failure = .response_too_large };
                    @memcpy(raw_response[received .. received + plain.len], plain);
                    received += plain.len;
                },
                .close_notify => {
                    return switch (http.decodeResponse(raw_response[0..received], body_out, true, false)) {
                        .complete => |response| .{ .response = .{ .http_response = response } },
                        else => .{ .failure = .tls_close_notify },
                    };
                },
                .failure => |failure| {
                    if (failure == .read_peer_closed) {
                        return switch (http.decodeResponse(raw_response[0..received], body_out, true, false)) {
                            .complete => |response| .{ .response = .{ .http_response = response } },
                            else => .{ .failure = failure },
                        };
                    }
                    return .{ .failure = failure };
                },
            }
        }
    }

    fn openTlsSession(self: *WebTransport, socket: *app_network.TcpSocket, url: http.ParsedUrl, scratch: []u8, options: FetchOptions, deadline: RequestDeadline) TlsSessionResult {
        var generated_entropy: [32]u8 = undefined;
        const entropy = options.entropy orelse blk: {
            if (!fillSecureEntropy(&generated_entropy)) return .{ .failure = .tls_entropy_required };
            break :blk generated_entropy;
        };
        const first = scratch[0..tls_workspace_bytes];
        const second = scratch[tls_workspace_bytes .. tls_workspace_bytes * 2];
        const third = scratch[tls_workspace_bytes * 2 .. tls_workspace_bytes * 3];
        var begin_input: [4 + 32 + 8 + 2 + 253]u8 = undefined;
        var begin_len: usize = 0;
        @memcpy(begin_input[0..4], "R4CB");
        begin_len = 4;
        @memcpy(begin_input[begin_len .. begin_len + entropy.len], entropy[0..]);
        begin_len += entropy.len;
        writeBe64(begin_input[begin_len .. begin_len + 8], packedUtc(self.network.sys.timeState()));
        begin_len += 8;
        writeBe16(begin_input[begin_len .. begin_len + 2], @intCast(url.host.len));
        begin_len += 2;
        @memcpy(begin_input[begin_len .. begin_len + url.host.len], url.host);
        begin_len += url.host.len;
        const begin_result = self.protocolCall(tls_op_client_begin, begin_input[0..begin_len], first) orelse return .{ .failure = .tls_unavailable };
        if (begin_result.len < tls_result_header_len or !startsWith(begin_result, "R4CH")) return .{ .failure = .tls_handshake_failed };
        const begin_state_len = readBe32(begin_result[4..8]);
        const hello_len = readBe32(begin_result[8..12]);
        if (begin_result.len != tls_result_header_len + begin_state_len + hello_len) return .{ .failure = .tls_handshake_failed };
        const begin_state = begin_result[tls_result_header_len .. tls_result_header_len + begin_state_len];
        const hello = begin_result[tls_result_header_len + begin_state_len ..];
        if (!writeAll(socket, hello, options, deadline)) return .{ .failure = if (shouldStop(options)) .cancelled else .write_failed };

        switch (readTlsHandshakeFlight(socket, second, third, options, deadline)) {
            .flight_complete => {},
            .alert => |description| return .{ .failure = tlsAlertError(description) },
            .malformed => return .{ .failure = .tls_server_flight_malformed },
            .read_failed => return .{ .failure = .tls_handshake_failed },
        }
        const flight_parts = TlsFlightParts{
            .state_ptr = begin_state.ptr,
            .state_len = begin_state_len,
            .flight_ptr = second.ptr,
            .flight_len = 0,
            .derive_tls_record_len = true,
        };
        const flight_input_len = serializeTlsFlight(third, "R4CF", &flight_parts) orelse return .{ .failure = .scratch_too_small };
        const client_flight_call = self.protocolCallWithStatus(tls_op_client_server_flight, third[0..flight_input_len], first);
        const client_flight_result = client_flight_call.bytes orelse return .{ .failure = switch (client_flight_call.status) {
            -6 => .tls_server_flight_malformed,
            -8 => .tls_server_signature_rejected,
            -10 => .tls_certificate_rejected,
            -41 => .tls_certificate_material_unavailable,
            -42 => .tls_certificate_clock_invalid,
            -43 => .tls_certificate_parse_failed,
            -44 => .tls_certificate_hostname_rejected,
            -45 => .tls_certificate_validity_rejected,
            -46 => .tls_certificate_chain_rejected,
            -47 => .tls_certificate_root_rejected,
            -7 => .tls_server_flight_unsupported,
            -21 => .tls_client_flight_buffer_invalid,
            -22 => .tls_client_flight_header_invalid,
            -23 => .tls_client_state_length_zero,
            -25 => .tls_server_flight_length_zero,
            -26 => .tls_client_flight_declared_too_large,
            -27 => .tls_client_flight_has_trailing_input,
            -24 => .tls_client_state_invalid,
            -31 => .tls_server_record_header_invalid,
            -32 => .tls_server_message_framing_invalid,
            -33 => .tls_server_hello_invalid,
            -34 => .tls_server_certificate_list_invalid,
            -35 => .tls_server_key_exchange_invalid,
            -36 => .tls_server_hello_done_invalid,
            -37 => .tls_server_message_unsupported,
            -38 => .tls_server_flight_incomplete,
            else => .tls_handshake_failed,
        } };
        if (client_flight_result.len < tls_result_header_len or !startsWith(client_flight_result, "R4CQ")) return .{ .failure = .tls_certificate_rejected };
        const ready_len = readBe32(client_flight_result[4..8]);
        const client_wire_len = readBe32(client_flight_result[8..12]);
        if (client_flight_result.len != tls_result_header_len + ready_len + client_wire_len) return .{ .failure = .tls_handshake_failed };
        const ready = client_flight_result[tls_result_header_len .. tls_result_header_len + ready_len];
        const client_wire = client_flight_result[tls_result_header_len + ready_len ..];
        if (!writeAll(socket, client_wire, options, deadline)) return .{ .failure = if (shouldStop(options)) .cancelled else .write_failed };

        const server_final = readTlsFlight(socket, second, options, deadline) orelse return .{ .failure = .tls_server_final_flight_invalid };
        const finish_parts = TlsFlightParts{
            .state_ptr = ready.ptr,
            .state_len = ready_len,
            .flight_ptr = second.ptr,
            .flight_len = server_final.len,
        };
        const finish_input_len = serializeTlsFlight(third, "R4CE", &finish_parts) orelse return .{ .failure = .scratch_too_small };
        const finish_call = self.protocolCallWithStatus(tls_op_client_finish, third[0..finish_input_len], first);
        const finish = finish_call.bytes orelse return .{ .failure = switch (finish_call.status) {
            -6 => .tls_server_final_flight_invalid,
            -8 => .tls_server_finished_rejected,
            else => .tls_handshake_failed,
        } };
        if (finish.len != 4 + tls_stream_state_len or !startsWith(finish, "R4CT")) return .{ .failure = .tls_finished_state_invalid };
        var session: TlsSession = undefined;
        @memcpy(session.stream_state[0..], finish[4..]);
        return .{ .session = session };
    }

    fn writeTlsApplication(self: *WebTransport, socket: *app_network.TcpSocket, session: *TlsSession, bytes: []const u8, scratch: []u8, options: FetchOptions, deadline: RequestDeadline) TlsWriteResult {
        const first = scratch[0..tls_workspace_bytes];
        const third = scratch[tls_workspace_bytes * 2 .. tls_workspace_bytes * 3];
        if (tls_app_header_len + bytes.len > third.len) return .{ .failure = .scratch_too_small };
        @memcpy(third[0..4], "R4CW");
        @memcpy(third[4..tls_app_header_len], session.stream_state[0..]);
        @memcpy(third[tls_app_header_len .. tls_app_header_len + bytes.len], bytes);
        const protected = self.protocolCall(tls_op_client_app_write, third[0 .. tls_app_header_len + bytes.len], first) orelse return .{ .failure = .tls_record_failed };
        if (protected.len <= tls_app_header_len or !startsWith(protected, "R4CX")) return .{ .failure = .tls_record_failed };
        @memcpy(session.stream_state[0..], protected[4..tls_app_header_len]);
        if (!writeAll(socket, protected[tls_app_header_len..], options, deadline)) return .{ .failure = if (shouldStop(options)) .cancelled else .write_failed };
        return .ok;
    }

    fn readTlsApplication(self: *WebTransport, socket: *app_network.TcpSocket, session: *TlsSession, scratch: []u8, options: FetchOptions, deadline: RequestDeadline) TlsApplicationRead {
        const first = scratch[0..tls_workspace_bytes];
        const second = scratch[tls_workspace_bytes .. tls_workspace_bytes * 2];
        const third = scratch[tls_workspace_bytes * 2 .. tls_workspace_bytes * 3];
        const record = switch (readTlsRecord(socket, second, options, deadline)) {
            .record => |value| value,
            .cancelled => return .{ .failure = .cancelled },
            .timed_out => return .{ .failure = .read_timeout },
            .reset => return .{ .failure = .read_reset },
            .peer_closed, .closed => return .{ .failure = .read_peer_closed },
            .failed, .buffer_too_small => return .{ .failure = .read_failed },
        };
        if (record.len + tls_app_header_len > third.len) return .{ .failure = .scratch_too_small };
        @memcpy(third[0..4], "R4CR");
        @memcpy(third[4..tls_app_header_len], session.stream_state[0..]);
        @memcpy(third[tls_app_header_len .. tls_app_header_len + record.len], record);
        const opened = self.protocolCall(tls_op_client_app_read, third[0 .. tls_app_header_len + record.len], first) orelse return .{ .failure = .tls_record_failed };
        if (opened.len < tls_app_header_len or !startsWith(opened, "R4CY")) return .{ .failure = .tls_record_failed };
        @memcpy(session.stream_state[0..], opened[4..tls_app_header_len]);
        const plain = opened[tls_app_header_len..];
        if (record[0] != 21) return .{ .bytes = plain };
        if (plain.len != 2) return .{ .failure = .tls_record_failed };
        if (plain[0] == 1 and plain[1] == 0) return .close_notify;
        return .{ .failure = .tls_alert_received };
    }

    fn protocolCall(self: *const WebTransport, op: u32, input: []const u8, output: []u8) ?[]u8 {
        return self.protocolCallWithStatus(op, input, output).bytes;
    }

    const ProtocolCallResult = struct {
        bytes: ?[]u8,
        status: i32,
    };

    fn protocolCallWithStatus(self: *const WebTransport, op: u32, input: []const u8, output: []u8) ProtocolCallResult {
        var in_buffer = abi.ProtocolBuffer{ .data = @ptrCast(@constCast(input.ptr)), .len = @intCast(input.len), .capacity = @intCast(input.len) };
        var out_buffer = abi.ProtocolBuffer{ .data = output.ptr, .len = 0, .capacity = @intCast(output.len) };
        const rc = self.dev.protocolDispatch(tls_role, op, &in_buffer, &out_buffer);
        if (rc != 0 or out_buffer.len > out_buffer.capacity) return .{ .bytes = null, .status = rc };
        return .{ .bytes = output[0..out_buffer.len], .status = rc };
    }
};

fn sameOrigin(left: http.ParsedUrl, right: http.ParsedUrl) bool {
    return left.scheme == right.scheme and left.port == right.port and std.ascii.eqlIgnoreCase(left.host, right.host);
}

fn appendRangeHeader(headers: []const u8, resume_from: u64, out: []u8) ?[]const u8 {
    if (resume_from == 0) return headers;
    var written: usize = 0;
    if (!appendText(out, &written, headers)) return null;
    if (headers.len != 0 and headers[headers.len - 1] != '\n') return null;
    if (!appendText(out, &written, "Range: bytes=")) return null;
    const count = std.fmt.bufPrint(out[written..], "{d}", .{resume_from}) catch return null;
    written += count.len;
    if (!appendText(out, &written, "-\n")) return null;
    return out[0..written];
}

fn validateDownloadHead(response: http.StreamResponse, method: http.Method, resume_from: u64, expected_size: ?u64) DownloadHeadDecision {
    if (response.isRedirect()) {
        return .{ .redirect = .{
            .status = response.status,
            .location = response.location orelse return .{ .failure = .redirect_without_location },
        } };
    }
    if (response.status == 416) {
        const range = response.content_range orelse return .{ .failure = .content_range_required };
        if (range.satisfied) return .{ .failure = .content_range_mismatch };
        if (expected_size) |expected| if (expected != range.total) return .{ .failure = .content_range_mismatch };
        return .{ .range_not_satisfiable = range.total };
    }
    if (method == .head) {
        if (expected_size) |expected| if (response.status == 200 and expected != response.content_length) return .{ .failure = .content_range_mismatch };
        return .{ .response = .{
            .status = response.status,
            .content_length = response.content_length,
            .total_size = response.content_length,
            .transferred = 0,
        } };
    }
    if (response.status != 200 and response.status != 206) {
        return .{ .response = .{
            .status = response.status,
            .content_length = response.content_length,
            .total_size = response.content_length,
            .transferred = 0,
        } };
    }
    if (response.transfer != .content_length) return .{ .failure = .content_length_required };
    if (resume_from == 0) {
        if (response.status != 200 or response.content_range != null) return .{ .failure = .content_range_mismatch };
        if (expected_size) |expected| if (expected != response.content_length) return .{ .failure = .content_range_mismatch };
        return .{ .body = response.content_length };
    }
    if (response.status != 206) return .{ .failure = .content_range_required };
    const range = response.content_range orelse return .{ .failure = .content_range_required };
    if (!range.satisfied or range.start != resume_from or range.end - range.start + 1 != response.content_length) return .{ .failure = .content_range_mismatch };
    if (expected_size) |expected| if (expected != range.total) return .{ .failure = .content_range_mismatch };
    return .{ .body = range.total };
}

fn downloadFailure(cause: Error) DownloadAttempt {
    return .{ .failure = .{ .cause = cause, .transferred = 0, .total_size = null } };
}

fn downloadFetchOptions(options: DownloadOptions) FetchOptions {
    return .{
        .timeout = options.timeout,
        .entropy = options.entropy,
        .stop = options.stop,
    };
}

fn downloadStopped(options: DownloadOptions) bool {
    return if (options.stop) |stop| isStopped(stop) else false;
}

fn downloadTargetAuthorized(options: DownloadOptions, url: []const u8) bool {
    return if (options.target_authorizer) |authorize|
        authorize(options.target_authorization_context, url)
    else
        true;
}

fn shouldRetryDownload(failure: Error, attempts: u8) bool {
    if (attempts != 0) return false;
    return failure == .read_timeout or failure == .read_reset or failure == .read_peer_closed or failure == .read_failed or failure == .tls_close_notify;
}

fn shouldRetryReadFailure(method: http.Method, failure: Error, attempts: u8) bool {
    if (attempts != 0 or (method != .get and method != .head)) return false;
    return switch (failure) {
        .read_failed, .read_timeout, .read_reset, .read_peer_closed, .tls_close_notify => true,
        else => false,
    };
}

fn filterRedirectHeaders(input: []const u8, output: []u8, strip_body: bool, strip_sensitive: bool) ?[]const u8 {
    var written: usize = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse return null;
        const name = line[0..colon];
        const is_body = std.ascii.eqlIgnoreCase(name, "content-encoding") or
            std.ascii.eqlIgnoreCase(name, "content-language") or
            std.ascii.eqlIgnoreCase(name, "content-location") or
            std.ascii.eqlIgnoreCase(name, "content-type");
        const is_sensitive = std.ascii.eqlIgnoreCase(name, "authorization") or
            std.ascii.eqlIgnoreCase(name, "proxy-authorization");
        if ((strip_body and is_body) or (strip_sensitive and is_sensitive)) continue;
        if (line.len + 1 > output.len -| written) return null;
        std.mem.copyForwards(u8, output[written .. written + line.len], line);
        written += line.len;
        output[written] = '\n';
        written += 1;
    }
    return output[0..written];
}

fn isCrossOrigin(serialized_origin: []const u8, target: http.ParsedUrl) bool {
    const source = switch (http.parseUrl(serialized_origin)) {
        .value => |value| value,
        else => return true,
    };
    return !sameOrigin(source, target);
}

fn corsPreflightHeaders(method: http.Method, headers: []const u8, output: []u8) ?[]const u8 {
    var names: [2048]u8 = undefined;
    var names_len: usize = 0;
    var needs_preflight = method != .get and method != .head and method != .post;
    var lines = std.mem.splitScalar(u8, headers, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse return null;
        const name = line[0..colon];
        const value = line[colon + 1 ..];
        if (corsSafelistedRequestHeader(name, value)) continue;
        needs_preflight = true;
        if (names_len > 0) {
            if (names_len >= names.len) return null;
            names[names_len] = ',';
            names_len += 1;
        }
        if (name.len > names.len -| names_len) return null;
        @memcpy(names[names_len .. names_len + name.len], name);
        names_len += name.len;
    }
    if (!needs_preflight) return output[0..0];
    var written: usize = 0;
    if (!appendText(output, &written, "access-control-request-method:") or !appendText(output, &written, method.text()) or !appendText(output, &written, "\n")) return null;
    if (names_len > 0) {
        if (!appendText(output, &written, "access-control-request-headers:") or !appendText(output, &written, names[0..names_len]) or !appendText(output, &written, "\n")) return null;
    }
    return output[0..written];
}

fn corsSafelistedRequestHeader(name: []const u8, value: []const u8) bool {
    if (std.ascii.eqlIgnoreCase(name, "accept") or std.ascii.eqlIgnoreCase(name, "accept-language") or std.ascii.eqlIgnoreCase(name, "content-language")) return value.len <= 128;
    if (std.ascii.eqlIgnoreCase(name, "range")) return value.len <= 128 and std.ascii.startsWithIgnoreCase(value, "bytes=") and std.mem.indexOfScalar(u8, value, ',') == null;
    if (!std.ascii.eqlIgnoreCase(name, "content-type") or value.len > 128) return false;
    const semicolon = std.mem.indexOfScalar(u8, value, ';') orelse value.len;
    const essence = std.mem.trim(u8, value[0..semicolon], " \t");
    return std.ascii.eqlIgnoreCase(essence, "application/x-www-form-urlencoded") or
        std.ascii.eqlIgnoreCase(essence, "multipart/form-data") or
        std.ascii.eqlIgnoreCase(essence, "text/plain");
}

fn acceptsPreflight(response: http.Response, origin: []const u8, method: http.Method, request_headers: []const u8, credentials_include: bool) bool {
    if (response.status < 200 or response.status > 299) return false;
    const allow_origin = responseHeader(response.headers, "access-control-allow-origin") orelse return false;
    if (!std.mem.eql(u8, allow_origin, origin) and !(std.mem.eql(u8, allow_origin, "*") and !credentials_include)) return false;
    if (credentials_include and !std.ascii.eqlIgnoreCase(responseHeader(response.headers, "access-control-allow-credentials") orelse "", "true")) return false;
    if (method != .get and method != .head and method != .post) {
        if (!headerTokenContains(responseHeader(response.headers, "access-control-allow-methods") orelse "", method.text(), credentials_include)) return false;
    }
    const allow_headers = responseHeader(response.headers, "access-control-allow-headers") orelse "";
    var lines = std.mem.splitScalar(u8, request_headers, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse return false;
        if (corsSafelistedRequestHeader(line[0..colon], line[colon + 1 ..])) continue;
        if (!headerTokenContains(allow_headers, line[0..colon], credentials_include)) return false;
    }
    return true;
}

fn acceptsCorsResponse(response: http.Response, origin: []const u8, credentials_include: bool) bool {
    const allow_origin = responseHeader(response.headers, "access-control-allow-origin") orelse return false;
    if (!std.mem.eql(u8, allow_origin, origin) and !(std.mem.eql(u8, allow_origin, "*") and !credentials_include)) return false;
    return !credentials_include or std.ascii.eqlIgnoreCase(responseHeader(response.headers, "access-control-allow-credentials") orelse "", "true");
}

fn targetAuthorized(options: FetchOptions, url: []const u8) bool {
    const authorize = options.target_authorizer orelse return true;
    return authorize(options.target_authorization_context, url);
}

fn responseHeader(headers: []const u8, wanted: []const u8) ?[]const u8 {
    var lines = std.mem.splitSequence(u8, headers, "\r\n");
    while (lines.next()) |line| {
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
        if (!std.ascii.eqlIgnoreCase(std.mem.trim(u8, line[0..colon], " \t"), wanted)) continue;
        return std.mem.trim(u8, line[colon + 1 ..], " \t");
    }
    return null;
}

fn headerTokenContains(value: []const u8, wanted: []const u8, credentials_include: bool) bool {
    var tokens = std.mem.splitScalar(u8, value, ',');
    while (tokens.next()) |raw_token| {
        const token = std.mem.trim(u8, raw_token, " \t");
        if (std.mem.eql(u8, token, "*") and !credentials_include) return true;
        if (std.ascii.eqlIgnoreCase(token, wanted)) return true;
    }
    return false;
}

fn appendText(output: []u8, written: *usize, value: []const u8) bool {
    if (value.len > output.len -| written.*) return false;
    @memcpy(output[written.* .. written.* + value.len], value);
    written.* += value.len;
    return true;
}

test "redirect filtering removes body and cross-origin credentials" {
    var output: [256]u8 = undefined;
    const filtered = filterRedirectHeaders(
        "authorization:secret\ncontent-type:application/json\nx-request:r4\n",
        output[0..],
        true,
        true,
    ).?;
    try std.testing.expectEqualStrings("x-request:r4\n", filtered);
    const same_origin = filterRedirectHeaders("authorization:secret\nx-request:r4\n", output[0..], false, false).?;
    try std.testing.expectEqualStrings("authorization:secret\nx-request:r4\n", same_origin);
}

test "transport target authorizer observes and rejects redirect path targets" {
    const Trace = struct {
        calls: usize = 0,
        initial_seen: bool = false,
        blocked_seen: bool = false,
        final_seen: bool = false,

        fn authorize(raw_context: ?*anyopaque, url: []const u8) bool {
            const self: *@This() = @ptrCast(@alignCast(raw_context orelse return false));
            self.calls += 1;
            if (std.mem.eql(u8, url, "https://allowed.example/start")) self.initial_seen = true;
            if (std.mem.eql(u8, url, "http://blocked.example/hop")) self.blocked_seen = true;
            if (std.mem.eql(u8, url, "https://allowed.example/final")) self.final_seen = true;
            return !std.mem.eql(u8, url, "http://blocked.example/hop");
        }
    };

    var trace = Trace{};
    const options: FetchOptions = .{
        .target_authorizer = Trace.authorize,
        .target_authorization_context = &trace,
    };
    try std.testing.expect(targetAuthorized(options, "https://allowed.example/start"));
    try std.testing.expect(!targetAuthorized(options, "http://blocked.example/hop"));
    try std.testing.expect(targetAuthorized(options, "https://allowed.example/final"));
    try std.testing.expectEqual(@as(usize, 3), trace.calls);
    try std.testing.expect(trace.initial_seen and trace.blocked_seen and trace.final_seen);

    var transport: WebTransport = undefined;
    var raw_response: [1]u8 = undefined;
    var body: [1]u8 = undefined;
    var scratch: [tls_scratch_bytes]u8 = undefined;
    const result = transport.fetch(
        "http://blocked.example/hop",
        raw_response[0..],
        body[0..],
        scratch[0..],
        options,
    );
    switch (result) {
        .failure => |err| try std.testing.expectEqual(Error.policy_rejected, err),
        .response => return error.TestUnexpectedResult,
    }
    var download_header: [http.max_header_bytes]u8 = undefined;
    const NeverSink = struct {
        fn write(_: ?*anyopaque, _: u64, _: []const u8) bool {
            unreachable;
        }
    };
    const rejected_download = transport.download("http://blocked.example/hop", &download_header, &body, &scratch, .{ .context = null, .write_fn = NeverSink.write }, .{
        .target_authorizer = Trace.authorize,
        .target_authorization_context = &trace,
    });
    try std.testing.expect(switch (rejected_download) {
        .failure => |err| err == .policy_rejected,
        else => false,
    });
}

test "read retry is single and restricted to idempotent retrieval" {
    try std.testing.expect(shouldRetryReadFailure(.get, .read_failed, 0));
    try std.testing.expect(shouldRetryReadFailure(.head, .read_failed, 0));
    try std.testing.expect(shouldRetryReadFailure(.get, .read_timeout, 0));
    try std.testing.expect(shouldRetryReadFailure(.get, .read_reset, 0));
    try std.testing.expect(shouldRetryReadFailure(.get, .read_peer_closed, 0));
    try std.testing.expect(shouldRetryReadFailure(.get, .tls_close_notify, 0));
    try std.testing.expect(!shouldRetryReadFailure(.get, .read_failed, 1));
    try std.testing.expect(!shouldRetryReadFailure(.post, .read_failed, 0));
    try std.testing.expect(!shouldRetryReadFailure(.post, .read_reset, 0));
    try std.testing.expect(!shouldRetryReadFailure(.get, .write_failed, 0));
}

test "stream download pump resumes once with exact range and durable offsets" {
    const Fixture = struct {
        bytes: [10]u8 = .{0} ** 10,
        next: u64 = 0,

        fn write(context: ?*anyopaque, offset: u64, value: []const u8) bool {
            const self: *@This() = @ptrCast(@alignCast(context.?));
            if (offset != self.next or value.len > self.bytes.len - self.next) return false;
            @memcpy(self.bytes[@intCast(self.next)..@intCast(self.next + value.len)], value);
            self.next += value.len;
            return true;
        }
    };
    var fixture = Fixture{};
    const sink = DownloadSink{ .context = &fixture, .write_fn = Fixture.write };

    var first_header: [http.max_header_bytes]u8 = undefined;
    var first = DownloadPump{
        .decoder = http.StreamDecoder.init(first_header[0..], .get),
        .sink = sink,
        .options = .{ .expected_size = 10 },
        .resume_from = 0,
        .expected_size = 10,
    };
    try std.testing.expect(first.feed("HTTP/1.1 200 OK\r\nContent-Length: 10\r\n\r\nab", false, .read_peer_closed) == null);
    const interrupted = first.feed("", true, .read_peer_closed) orelse return error.TestUnexpectedResult;
    switch (interrupted) {
        .failure => |failure| {
            try std.testing.expectEqual(Error.read_peer_closed, failure.cause);
            try std.testing.expectEqual(@as(u64, 2), failure.transferred);
            try std.testing.expectEqual(@as(?u64, 10), failure.total_size);
        },
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expect(shouldRetryDownload(.read_peer_closed, 0));
    try std.testing.expect(!shouldRetryDownload(.read_peer_closed, 1));

    var range_buffer: [128]u8 = undefined;
    try std.testing.expectEqualStrings("x-test: yes\nRange: bytes=2-\n", appendRangeHeader("x-test: yes\n", 2, range_buffer[0..]).?);
    var second_header: [http.max_header_bytes]u8 = undefined;
    var second = DownloadPump{
        .decoder = http.StreamDecoder.init(second_header[0..], .get),
        .sink = sink,
        .options = .{ .resume_from = 2, .expected_size = 10 },
        .resume_from = 2,
        .expected_size = 10,
    };
    try std.testing.expect(second.feed("HTTP/1.1 206 Partial Content\r\nContent-Length: 8\r\nContent-Range: bytes 2-9/10\r\n\r\ncde", false, .read_peer_closed) == null);
    const completed = second.feed("fghij", false, .read_peer_closed) orelse return error.TestUnexpectedResult;
    switch (completed) {
        .response => |response| {
            try std.testing.expectEqual(@as(u16, 206), response.status);
            try std.testing.expectEqual(@as(u64, 8), response.transferred);
            try std.testing.expectEqual(@as(u64, 10), response.total_size);
        },
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expectEqualStrings("abcdefghij", fixture.bytes[0..]);

    const wrong = validateDownloadHead(.{
        .status = 206,
        .transfer = .content_length,
        .content_length = 8,
        .location = null,
        .content_type = null,
        .content_range = .{ .satisfied = true, .start = 3, .end = 9, .total = 10 },
    }, .get, 2, 10);
    try std.testing.expect(switch (wrong) {
        .failure => |failure| failure == .content_range_mismatch,
        else => false,
    });
    const unsatisfied = validateDownloadHead(.{
        .status = 416,
        .transfer = .content_length,
        .content_length = 0,
        .location = null,
        .content_type = null,
        .content_range = .{ .satisfied = false, .start = 0, .end = 0, .total = 10 },
    }, .get, 10, 10);
    try std.testing.expect(switch (unsatisfied) {
        .range_not_satisfiable => |total| total == 10,
        else => false,
    });
}

test "multi-megabyte R4U fixture streams byte-exact through bounded sink" {
    const total: u64 = 11 * 1024 * 1024;
    const Fixture = struct {
        next: u64 = 0,

        fn expected(offset: u64) u8 {
            return switch (offset) {
                0 => 'R',
                1 => '4',
                2 => 'U',
                3 => '2',
                else => @truncate(offset),
            };
        }

        fn write(context: ?*anyopaque, offset: u64, value: []const u8) bool {
            const self: *@This() = @ptrCast(@alignCast(context.?));
            if (offset != self.next) return false;
            for (value, 0..) |byte, index| {
                if (byte != expected(offset + index)) return false;
            }
            self.next += value.len;
            return true;
        }
    };
    var fixture = Fixture{};
    var header: [http.max_header_bytes]u8 = undefined;
    var pump = DownloadPump{
        .decoder = http.StreamDecoder.init(header[0..], .get),
        .sink = .{ .context = &fixture, .write_fn = Fixture.write },
        .options = .{ .expected_size = total },
        .resume_from = 0,
        .expected_size = total,
    };
    try std.testing.expect(pump.feed("HTTP/1.1 200 OK\r\nContent-Length: 11534336\r\n\r\n", false, .read_peer_closed) == null);
    var bytes: [4093]u8 = undefined;
    var offset: u64 = 0;
    while (offset < total) {
        const take: usize = @intCast(@min(@as(u64, bytes.len), total - offset));
        for (bytes[0..take], 0..) |*byte, index| byte.* = Fixture.expected(offset + index);
        const terminal = pump.feed(bytes[0..take], false, .read_peer_closed);
        offset += take;
        if (offset == total) {
            const completed = terminal orelse return error.TestUnexpectedResult;
            try std.testing.expect(switch (completed) {
                .response => |response| response.transferred == total and response.total_size == total,
                else => false,
            });
        } else {
            try std.testing.expect(terminal == null);
        }
    }
    try std.testing.expectEqual(total, fixture.next);
}

test "stream download exposes explicit abort and compiles the public entrypoint" {
    const Fixture = struct {
        bytes: usize = 0,

        fn write(context: ?*anyopaque, _: u64, value: []const u8) bool {
            const self: *@This() = @ptrCast(@alignCast(context.?));
            self.bytes += value.len;
            return true;
        }

        fn stop(_: ?*anyopaque, _: u64, _: u64) bool {
            return false;
        }
    };
    var fixture = Fixture{};
    const sink = DownloadSink{ .context = &fixture, .write_fn = Fixture.write };
    var header: [http.max_header_bytes]u8 = undefined;
    var pump = DownloadPump{
        .decoder = http.StreamDecoder.init(header[0..], .get),
        .sink = sink,
        .options = .{ .progress = Fixture.stop },
        .resume_from = 0,
        .expected_size = null,
    };
    const aborted = pump.feed("HTTP/1.1 200 OK\r\nContent-Length: 4\r\n\r\ntest", false, .read_peer_closed) orelse return error.TestUnexpectedResult;
    try std.testing.expect(switch (aborted) {
        .failure => |failure| failure.cause == .cancelled and failure.transferred == 4,
        else => false,
    });

    var transport: WebTransport = undefined;
    var none: [0]u8 = .{};
    const result = transport.download("https://example.test/file", none[0..], none[0..], none[0..], sink, .{});
    try std.testing.expect(switch (result) {
        .failure => |failure| failure == .scratch_too_small,
        else => false,
    });
}

test "CORS preflight derives and validates non-safelisted requests" {
    var generated: [512]u8 = undefined;
    const headers = corsPreflightHeaders(.put, "content-type:application/json\nx-request:r4\n", generated[0..]).?;
    try std.testing.expectEqualStrings("access-control-request-method:PUT\naccess-control-request-headers:content-type,x-request\n", headers);
    var body: [1]u8 = undefined;
    const raw = "HTTP/1.1 204 No Content\r\nAccess-Control-Allow-Origin: https://app.example\r\nAccess-Control-Allow-Methods: PUT\r\nAccess-Control-Allow-Headers: content-type, x-request\r\n\r\n";
    const response = switch (http.decodeResponse(raw, body[0..], false, false)) {
        .complete => |value| value,
        else => return error.TestUnexpectedResult,
    };
    try std.testing.expect(acceptsPreflight(response, "https://app.example", .put, "content-type:application/json\nx-request:r4\n", false));
    try std.testing.expect(!acceptsPreflight(response, "https://other.example", .put, "content-type:application/json\nx-request:r4\n", false));
    try std.testing.expect(acceptsCorsResponse(response, "https://app.example", false));
    try std.testing.expect(!acceptsCorsResponse(response, "https://other.example", false));
}

test "TLS handshake records reassemble without losing split messages" {
    const first = [_]u8{ 22, 3, 3, 0, 7, 2, 0, 0, 1, 0, 11, 0 };
    const second = [_]u8{ 22, 3, 3, 0, 7, 0, 1, 0, 14, 0, 0, 0 };
    var flight: [64]u8 = .{0} ** 64;
    try std.testing.expect(appendTlsHandshakeRecord(flight[0..], first[0..]));
    var payload_len = readBe16(flight[3..5]);
    try std.testing.expect(!tlsHandshakeFlightComplete(flight[5 .. 5 + payload_len]));
    try std.testing.expect(appendTlsHandshakeRecord(flight[0..], second[0..]));
    payload_len = readBe16(flight[3..5]);
    try std.testing.expect(tlsHandshakeFlightComplete(flight[5 .. 5 + payload_len]));
    try std.testing.expectEqual(@as(usize, 14), payload_len);
    try std.testing.expectEqual(@as(usize, 14), readBe16(flight[3..5]));
}

test "TLS two-part flight serialization keeps its adjacent length header" {
    var state: [300]u8 = undefined;
    var flight: [420]u8 = undefined;
    for (&state, 0..) |*byte, index| byte.* = @truncate(index + 1);
    for (&flight, 0..) |*byte, index| byte.* = @truncate(0x80 + index);
    var out: [800]u8 = .{0xCC} ** 800;

    const parts = TlsFlightParts{
        .state_ptr = state[0..].ptr,
        .state_len = state.len,
        .flight_ptr = flight[0..].ptr,
        .flight_len = flight.len,
    };
    const encoded_len = serializeTlsFlight(out[0..], "R4CF", &parts) orelse return error.TestUnexpectedResult;
    const encoded = out[0..encoded_len];
    try std.testing.expectEqualStrings("R4CF", encoded[0..4]);
    try std.testing.expectEqual(state.len, readBe32(encoded[4..8]));
    try std.testing.expectEqual(flight.len, readBe32(encoded[8..12]));
    try std.testing.expectEqualSlices(u8, state[0..], encoded[12 .. 12 + state.len]);
    try std.testing.expectEqualSlices(u8, flight[0..], encoded[12 + state.len ..]);
    try std.testing.expectEqual(@as(u8, 0xCC), out[encoded.len]);
    try std.testing.expect(tlsFlightEnvelopeValid(encoded, "R4CF"));

    encoded[11] +%= 1;
    try std.testing.expect(!tlsFlightEnvelopeValid(encoded, "R4CF"));
}

/// Fills a TLS seed without introducing a private kernel random path.
/// R4OS targets AVX2-class x86_64 machines, but RDRAND remains optional and
/// is checked through CPUID before the instruction is executed.
pub fn fillSecureEntropy(out: *[32]u8) bool {
    return web_crypto.fillSecureRandom(out[0..]);
}

fn writeAll(socket: *app_network.TcpSocket, bytes: []const u8, options: FetchOptions, deadline: RequestDeadline) bool {
    var pos: usize = 0;
    while (pos < bytes.len) {
        if (shouldStop(options)) return false;
        if (deadline.expired(&socket.network)) return false;
        const end = @min(bytes.len, pos + abi.net_service_tcp_write_max);
        switch (socket.write(bytes[pos..end], deadline.remaining(&socket.network))) {
            .bytes => |count| {
                if (count == 0) continue;
                pos += count;
            },
            .would_block => continue,
            else => return false,
        }
    }
    return true;
}

const TlsRecordReadResult = union(enum) {
    record: []u8,
    cancelled,
    timed_out,
    reset,
    peer_closed,
    closed,
    failed,
    buffer_too_small,
};

const BoundedSocketRead = union(enum) {
    bytes: usize,
    cancelled,
    timed_out,
    reset,
    peer_closed,
    closed,
    failed,
};

fn readSocketBounded(socket: *app_network.TcpSocket, out: []u8, options: FetchOptions, deadline: RequestDeadline) BoundedSocketRead {
    while (true) {
        if (shouldStop(options)) return .cancelled;
        if (deadline.expired(&socket.network)) return .timed_out;
        switch (socket.read(out, deadline.remaining(&socket.network))) {
            .bytes => |count| if (count != 0) return .{ .bytes = count },
            .would_block, .timed_out => {},
            .reset => return .reset,
            .peer_closed => return .peer_closed,
            .closed => return .closed,
            .failure => return .failed,
        }
        if (deadline.expired(&socket.network)) return .timed_out;
        socket.network.sys.sleepTicks(1);
    }
}

fn readTlsRecord(socket: *app_network.TcpSocket, out: []u8, options: FetchOptions, deadline: RequestDeadline) TlsRecordReadResult {
    var received: usize = 0;
    var expected: ?usize = null;
    while (expected == null or received < expected.?) {
        if (shouldStop(options)) return .cancelled;
        if (received == out.len) return .buffer_too_small;
        const read_end = if (expected) |record_len| record_len else @min(out.len, @as(usize, 5));
        switch (readSocketBounded(socket, out[received..read_end], options, deadline)) {
            .bytes => |count| {
                if (count == 0) continue;
                received += count;
                if (expected == null and received >= 5) expected = 5 + readBe16(out[3..5]);
                if (expected != null and expected.? > out.len) return .buffer_too_small;
            },
            .cancelled => return .cancelled,
            .timed_out => return .timed_out,
            .reset => return .reset,
            .peer_closed => return .peer_closed,
            .closed => return .closed,
            .failed => return .failed,
        }
    }
    return .{ .record = out[0..expected.?] };
}

test "request deadline remains absolute across partial transport progress" {
    const finite = RequestDeadline.fromTicks(100, 30);
    try std.testing.expectEqual(@as(u64, 130), finite.deadline_tick);
    try std.testing.expect(!finite.forever);

    const poll = RequestDeadline.fromTicks(100, 0);
    try std.testing.expectEqual(@as(u64, 100), poll.deadline_tick);

    const forever = RequestDeadline.fromTicks(100, abi.io_wait_forever);
    try std.testing.expect(forever.forever);
}

const TlsHandshakeFlightResult = union(enum) {
    flight_complete,
    alert: u8,
    malformed,
    read_failed,
};

fn readTlsHandshakeFlight(socket: *app_network.TcpSocket, out: []u8, record_storage: []u8, options: FetchOptions, deadline: RequestDeadline) TlsHandshakeFlightResult {
    if (out.len < 5 or record_storage.len < 5) return .malformed;
    out[0] = 0;
    out[1] = 0;
    out[2] = 0;
    out[3] = 0;
    out[4] = 0;
    while (true) {
        const record = switch (readTlsRecord(socket, record_storage, options, deadline)) {
            .record => |value| value,
            else => return .read_failed,
        };
        if (record[0] == 21) {
            if (record.len != 7 or record[5] < 1 or record[5] > 2) return .malformed;
            return .{ .alert = record[6] };
        }
        if (!appendTlsHandshakeRecord(out, record)) return .malformed;
        const assembled_len = (@as(usize, out[3]) << 8) | @as(usize, out[4]);
        if (assembled_len < 4) continue;
        if (out[5] != 2) return .malformed;
        const server_hello_len = 4 + (@as(usize, out[6]) << 16) + (@as(usize, out[7]) << 8) + @as(usize, out[8]);
        if (server_hello_len > out.len - 5) return .malformed;
        if (assembled_len < server_hello_len) continue;
        if (tlsHandshakeFlightComplete(out.ptr[5 .. 5 + assembled_len])) {
            return .flight_complete;
        }
    }
}

fn tlsAlertError(description: u8) Error {
    return switch (description) {
        10 => .tls_alert_unexpected_message,
        40 => .tls_alert_handshake_failure,
        47 => .tls_alert_illegal_parameter,
        50 => .tls_alert_decode_error,
        70 => .tls_alert_protocol_version,
        71 => .tls_alert_insufficient_security,
        else => .tls_handshake_failed,
    };
}

fn appendTlsHandshakeRecord(out: []u8, record: []const u8) bool {
    if (record.len < 5 or record[0] != 22 or record[1] != 3) return false;
    const fragment_len = (@as(usize, record[3]) << 8) | @as(usize, record[4]);
    const previous_payload_len = (@as(usize, out[3]) << 8) | @as(usize, out[4]);
    if (record.len != 5 + fragment_len or fragment_len > out.len -| 5 -| previous_payload_len) return false;
    if (previous_payload_len == 0) {
        out[0] = 22;
        out[1] = record[1];
        out[2] = record[2];
    }
    const low_sum = @as(u16, out[4]) + @as(u16, record[4]);
    out[4] = @truncate(low_sum);
    out[3] +%= record[3];
    if (low_sum > 0xFF) out[3] +%= 1;
    const next_payload_len = (@as(usize, out[3]) << 8) | @as(usize, out[4]);
    std.mem.copyForwards(u8, out.ptr[5 + previous_payload_len .. 5 + next_payload_len], record.ptr[5 .. 5 + fragment_len]);
    return true;
}

/// Serializes the two-part TLS protocol payload from stable scalar lengths.
/// The module ABI can spill later slice arguments while a large copy runs, so
/// the header and the later flight are materialized before copying the state.
const TlsFlightParts = struct {
    state_ptr: [*]const u8,
    state_len: usize,
    flight_ptr: [*]const u8,
    flight_len: usize,
    derive_tls_record_len: bool = false,
};

fn serializeTlsFlight(out: []u8, magic: *const [4]u8, parts: *const TlsFlightParts) ?usize {
    const state_len = parts.state_len;
    const flight_len = if (parts.derive_tls_record_len)
        5 + ((@as(usize, parts.flight_ptr[3]) << 8) | @as(usize, parts.flight_ptr[4]))
    else
        parts.flight_len;
    if (state_len == 0 or flight_len == 0 or state_len > std.math.maxInt(u32) or flight_len > std.math.maxInt(u32)) return null;
    const total = tls_result_header_len + state_len + flight_len;
    if (total > out.len) return null;
    out[0] = magic[0];
    out[1] = magic[1];
    out[2] = magic[2];
    out[3] = magic[3];
    writeBe32(out[4..8], @intCast(state_len));
    if (parts.derive_tls_record_len) {
        out[8] = 0;
        out[9] = 0;
        const record_low_sum = @as(u16, parts.flight_ptr[4]) + 5;
        out[10] = parts.flight_ptr[3] +% @as(u8, @intFromBool(record_low_sum > 0xFF));
        out[11] = @truncate(record_low_sum);
    } else {
        writeBe32(out[8..12], @intCast(flight_len));
    }

    const flight_offset = tls_result_header_len + state_len;
    @memcpy(out[flight_offset..total], parts.flight_ptr[0..flight_len]);
    const declared_state_len = readBe32(out[4..8]);
    @memcpy(out[tls_result_header_len .. tls_result_header_len + declared_state_len], parts.state_ptr[0..declared_state_len]);
    return tls_result_header_len + declared_state_len + readBe32(out[8..12]);
}

fn tlsFlightEnvelopeValid(encoded: []const u8, magic: []const u8) bool {
    if (magic.len != 4 or encoded.len < tls_result_header_len or !startsWith(encoded, magic)) return false;
    const state_len = readBe32(encoded[4..8]);
    const flight_len = readBe32(encoded[8..12]);
    if (state_len == 0 or flight_len == 0 or state_len > encoded.len - tls_result_header_len) return false;
    return flight_len == encoded.len - tls_result_header_len - state_len;
}

fn tlsHandshakeFlightComplete(fragment: []const u8) bool {
    var pos: usize = 0;
    while (pos < fragment.len) {
        if (fragment.len - pos < 4) return false;
        const body_len = (@as(usize, fragment[pos + 1]) << 16) |
            (@as(usize, fragment[pos + 2]) << 8) |
            @as(usize, fragment[pos + 3]);
        const full_len = 4 + body_len;
        if (full_len > fragment.len - pos) return false;
        if (fragment[pos] == 14) return body_len == 0 and pos + full_len == fragment.len;
        pos += full_len;
    }
    return false;
}

fn readTlsFlight(socket: *app_network.TcpSocket, out: []u8, options: FetchOptions, deadline: RequestDeadline) ?[]u8 {
    var used: usize = 0;
    var saw_change_cipher_spec = false;
    var record_count: usize = 0;
    while (record_count < 8) : (record_count += 1) {
        const record = switch (readTlsRecord(socket, out[used..], options, deadline)) {
            .record => |value| value,
            else => return null,
        };
        if (record.len < 5) return null;
        if (!saw_change_cipher_spec) {
            if (record[0] == 22) {
                used += record.len;
                continue;
            }
            if (record.len != 6 or record[0] != 20 or record[1] != 3 or record[2] != 3 or record[3] != 0 or record[4] != 1 or record[5] != 1) return null;
            saw_change_cipher_spec = true;
            used += record.len;
            continue;
        }
        if (record[0] != 22) return null;
        used += record.len;
        return out[0..used];
    }
    return null;
}

fn isStopped(stop: ?*const abi.R4StopFlag) bool {
    const flag = stop orelse return false;
    return @atomicLoad(u32, &flag.value, .acquire) != 0;
}

fn shouldStop(options: FetchOptions) bool {
    if (isStopped(options.stop)) return true;
    if (options.progress) |progress| return !progress(options.progress_context);
    return false;
}

fn packedUtc(state: abi.TimeState) u64 {
    return @as(u64, state.year) * 10_000_000_000 +
        @as(u64, state.month) * 100_000_000 +
        @as(u64, state.day) * 1_000_000 +
        @as(u64, state.hour) * 10_000 +
        @as(u64, state.minute) * 100 +
        state.second;
}

fn startsWith(value: []const u8, prefix: []const u8) bool {
    return std.mem.startsWith(u8, value, prefix);
}

fn writeBe16(out: []u8, value: u16) void {
    out[0] = @intCast(value >> 8);
    out[1] = @intCast(value);
}

fn writeBe32(out: []u8, value: u32) void {
    const native: [4]u8 = @bitCast(value);
    out[0] = native[3];
    out[1] = native[2];
    out[2] = native[1];
    out[3] = native[0];
}

fn writeBe64(out: []u8, value: u64) void {
    const native: [8]u8 = @bitCast(value);
    out[0] = native[7];
    out[1] = native[6];
    out[2] = native[5];
    out[3] = native[4];
    out[4] = native[3];
    out[5] = native[2];
    out[6] = native[1];
    out[7] = native[0];
}

fn readBe16(input: []const u8) usize {
    return (@as(usize, input[0]) << 8) | input[1];
}

fn readBe24(input: []const u8) usize {
    return (@as(usize, input[0]) << 16) | (@as(usize, input[1]) << 8) | input[2];
}

fn readBe32(input: []const u8) usize {
    return (@as(usize, input[0]) << 24) | (@as(usize, input[1]) << 16) | (@as(usize, input[2]) << 8) | input[3];
}
