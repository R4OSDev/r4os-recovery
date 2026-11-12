const std = @import("std");
const abi = @import("r4os_contract").abi;
const app_network = @import("app_network.zig");
const http = @import("http.zig");
const family = @import("network_family.zig");
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
const socket_close_timeout = time_contract.timeoutFinite(time_contract.durationFromNanoseconds(250_000_000));
pub const tls_workspace_bytes: usize = 18 * 1024;
pub const tls_scratch_bytes: usize = tls_workspace_bytes * 3;
comptime {
    std.debug.assert(tls_workspace_bytes >= max_tls_record_bytes + tls_app_header_len);
}

pub const Timeout = time_contract.Timeout;

const Socket = struct {
    const Open = union(enum) { socket: Socket, timed_out, failed };
    const Typed = struct {
        client: family.Client,
        identity: abi.NetworkSocketResult,
    };

    network: app_network.Network,
    connection: union(enum) { start1: app_network.TcpSocket, start2: Typed },

    fn open(network: app_network.Network, remote: app_network.SocketAddress, timeout: Timeout) Open {
        const actual = network.sys.base.generation2 orelse return switch (network.connectTcp(remote, timeout)) {
            .socket => |socket| .{ .socket = .{ .network = network, .connection = .{ .start1 = socket } } },
            .timed_out => .timed_out,
            else => .failed,
        };
        const sample = family.common.sample(network.sys) catch return .failed;
        var budget = time_contract.checked.DeadlineBudget.init(sample, timeout) catch return .failed;
        const limit = family.fromBudget(budget) catch return .failed;
        var client: family.Client = undefined;
        if (family.Client.connect(actual, .tcp, &client) != 0) return .failed;
        var keep = false;
        defer if (!keep) {
            _ = client.close();
        };
        client.timeout_ticks = remainingTicks(network, &budget) orelse return .timed_out;
        var info: abi.NetworkProviderInfo = .{};
        if (client.info(&info) != 0 or info.capabilities & (abi.network_cap_ipv4 | abi.network_cap_tcp) != (abi.network_cap_ipv4 | abi.network_cap_tcp)) return .failed;
        client.timeout_ticks = remainingTicks(network, &budget) orelse return .timed_out;
        var result: abi.NetworkSocketResult = .{};
        const rc = client.socket(abi.network_op_connect, .{
            .provider = info.provider,
            .endpoint = family.common.v4Endpoint(remote.address.octets, remote.port),
            .deadline = limit,
        }, "", &.{}, &result);
        if (rc == abi.network_error_timeout or rc == abi.service_api_result_timeout) return .timed_out;
        if (rc != 0 or result.state != abi.network_state_ready) return .failed;
        keep = true;
        return .{ .socket = .{ .network = network, .connection = .{ .start2 = .{ .client = client, .identity = result } } } };
    }

    fn remainingTicks(network: app_network.Network, budget: *time_contract.checked.DeadlineBudget) ?u64 {
        const sample = family.common.sample(network.sys) catch return null;
        const left = budget.remaining(sample) catch return null;
        return switch (left.kind) {
            0 => if (budget.kind == 0) 0 else null,
            1 => time_contract.checked.durationToTicks(.{ .nanoseconds = left.value }, sample.identity.tick_hz) catch null,
            2 => abi.io_wait_forever,
            else => null,
        };
    }

    fn read(self: *Socket, out: []u8, timeout: Timeout) app_network.SocketIo {
        return switch (self.connection) {
            .start1 => |*socket| socket.read(out, timeout),
            .start2 => |*socket| self.call(socket, abi.network_op_read, "", out[0..@min(out.len, 4008)], timeout),
        };
    }

    fn write(self: *Socket, data: []const u8, timeout: Timeout) app_network.SocketIo {
        return switch (self.connection) {
            .start1 => |*socket| socket.write(data, timeout),
            .start2 => |*socket| self.call(socket, abi.network_op_write, data[0..@min(data.len, 3968)], &.{}, timeout),
        };
    }

    fn dispose(self: *Socket, legacy_timeout: Timeout) void {
        switch (self.connection) {
            .start1 => |*socket| _ = socket.close(legacy_timeout),
            .start2 => |*socket| {
                // The transport budget may already be exhausted. Give the
                // exact socket a close attempt, then release its IPC endpoint.
                defer _ = socket.client.close();
                _ = self.call(socket, abi.network_op_close, "", &.{}, socket_close_timeout);
            },
        }
    }

    fn call(self: *const Socket, socket: *Typed, op: u16, data: []const u8, out: []u8, timeout: Timeout) app_network.SocketIo {
        if (socket.identity.socket == 0) return .{ .failure = abi.err_closed };
        const sample = family.common.sample(self.network.sys) catch return .{ .failure = abi.network_error_clock_changed };
        var budget = time_contract.checked.DeadlineBudget.init(sample, timeout) catch return .{ .failure = abi.network_error_clock_changed };
        const limit = family.fromBudget(budget) catch return .{ .failure = abi.network_error_clock_changed };
        socket.client.timeout_ticks = remainingTicks(self.network, &budget) orelse return .timed_out;
        var result: abi.NetworkSocketResult = .{};
        const rc = socket.client.socket(op, .{
            .provider = socket.identity.provider,
            .socket = socket.identity.socket,
            .generation = socket.identity.generation,
            .bytes = @intCast(if (op == abi.network_op_read) out.len else data.len),
            .deadline = limit,
        }, data, out, &result);
        // An RPC timeout can have consumed bytes. Only a provider timeout
        // carries a known zero prefix for a safe later read attempt.
        if (rc != 0) return switch (rc) {
            abi.network_error_timeout => .timed_out,
            abi.network_error_reset => .reset,
            abi.network_error_would_block => .would_block,
            else => .{ .failure = rc },
        };
        if (op == abi.network_op_close and result.state == abi.network_state_local_closed) {
            socket.identity = .{};
        }
        if (result.bytes != 0) return .{ .bytes = result.bytes };
        return switch (result.state) {
            abi.network_state_ready => .{ .bytes = 0 },
            abi.network_state_would_block => .would_block,
            abi.network_state_eof => .peer_closed,
            abi.network_state_reset => .reset,
            abi.network_state_local_closed => .closed,
            abi.network_state_timeout => .timed_out,
            else => .{ .failure = abi.network_error_invalid },
        };
    }
};

pub const RequestDeadline = struct {
    deadline_tick: u64 = 0,
    forever: bool = false,
    valid: bool = true,

    pub fn start(network: *const app_network.Network, timeout: Timeout) RequestDeadline {
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

pub const TransportStats = struct {
    dns_resolutions: u64 = 0,
    connections: u64 = 0,
    tls_handshakes: u64 = 0,
    reused_connections: u64 = 0,
    preflights: u64 = 0,
    payload_copied_bytes: u64 = 0,
};

pub const FetchOptions = struct {
    sessions: ?*SessionPool = null,
    network_partition: []const u8 = "",
    absolute_deadline: ?RequestDeadline = null,
    stats: ?*TransportStats = null,
    timeout: Timeout = time_contract.timeoutFinite(time_contract.durationFromNanoseconds(10_000_000_000)),
    redirect_limit: u8 = http.max_redirects,
    redirect: RedirectMode = .follow,
    entropy: ?[32]u8 = null,
    stop: ?*const abi.R4StopFlag = null,
    progress: ?*const fn (?*anyopaque) callconv(.c) bool = null,
    progress_context: ?*anyopaque = null,
    cookie: []const u8 = "",
    initial_cookie: ?[]const u8 = null,
    origin: []const u8 = "",
    headers: []const u8 = "",
    // Cache validators are transport metadata, not author request headers.
    conditional_headers: []const u8 = "",
    cache_headers: []const u8 = "",
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

pub const RegistrationEndpoint = struct {
    address: app_network.Ipv4Address,
    hostname: []const u8,
    port: u16,
    tls: bool,
};

pub const RegistrationResult = union(enum) {
    accepted,
    invalid_secret,
    invalid_reply,
    failure: Error,
};

pub const DownloadProgress = *const fn (?*anyopaque, u64, u64) bool;
pub const DownloadWrite = *const fn (?*anyopaque, u64, []const u8) bool;
/// Borrowed only for the synchronous observation; retain neither slice nor
/// callback argument. Rejection happens before any bytes reach the sink.
pub const DownloadHeadObservation = struct {
    response: http.StreamResponse,
    headers: []const u8,
    requested_offset: u64,
};
pub const DownloadHeadObserver = *const fn (?*anyopaque, DownloadHeadObservation) bool;

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
    // Legacy callers retain one read retry. An outer transaction can set0
    // and enforce one shared budget across HTTP and transport failures.
    max_retries: u8 = 1,
    head_observer: ?DownloadHeadObserver = null,
    head_context: ?*anyopaque = null,

    pub fn observeHead(self: *const DownloadOptions, observation: DownloadHeadObservation) bool {
        return if (self.head_observer) |observe| observe(self.head_context, observation) else true;
    }
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

const TlsProtected = union(enum) { bytes: []const u8, failure: Error };

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
                if (!self.options.observeHead(.{ .response = response, .headers = self.decoder.header_buffer[0..self.decoder.header_len], .requested_offset = self.resume_from }))
                    return self.failed(if (downloadStopped(self.options)) .cancelled else .policy_rejected);
                if (downloadStopped(self.options)) return self.failed(.cancelled);
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

/// Explicitly owned by one transport worker (or one synchronous caller).
/// Close only after its operations have joined; never share it concurrently.
pub const SessionPool = struct {
    const Entry = struct {
        key: [2048]u8 = undefined,
        key_len: usize = 0,
        socket: ?app_network.TcpSocket = null,
        tls: ?TlsSession = null,
        leased: bool = false,
        expires: u64 = 0,
        used: u64 = 0,
    };
    const Preflight = struct {
        key: [16 * 1024]u8 = undefined,
        key_len: usize = 0,
        expires: u64 = 0,
        used: u64 = 0,
    };
    entries: [2]Entry = .{Entry{}} ** 2,
    preflights: [4]Preflight = .{Preflight{}} ** 4,
    serial: u64 = 0,

    pub fn deinit(self: *SessionPool) void {
        for (&self.entries) |*entry| {
            std.debug.assert(!entry.leased);
            closeEntry(entry);
        }
        for (&self.preflights) |*entry| entry.key_len = 0;
    }
    fn closeEntry(entry: *Entry) void {
        if (entry.socket) |*socket| _ = socket.close(socket_close_timeout);
        entry.* = .{};
    }
    fn acquire(self: *SessionPool, key: []const u8, now: u64) ?*Entry {
        var replacement: ?*Entry = null;
        for (&self.entries) |*entry| {
            if (entry.leased) continue;
            if (entry.socket != null and (entry.expires <= now or !entry.socket.?.valid())) closeEntry(entry);
            if (entry.socket != null and std.mem.eql(u8, entry.key[0..entry.key_len], key)) {
                entry.leased = true;
                return entry;
            }
            if (replacement == null or entry.used < replacement.?.used) replacement = entry;
        }
        const entry = replacement orelse return null;
        closeEntry(entry);
        @memcpy(entry.key[0..key.len], key);
        entry.key_len = key.len;
        entry.leased = true;
        return entry;
    }
    fn release(self: *SessionPool, entry: *Entry, reusable: bool, now: u64, hz: u64) void {
        if (!reusable or entry.socket == null or !entry.socket.?.valid()) {
            closeEntry(entry);
            return;
        }
        self.serial +|= 1;
        entry.used = self.serial;
        entry.expires = now +| (hz *| 30);
        entry.leased = false;
    }
    fn preflightHit(self: *SessionPool, key: []const u8, now: u64) bool {
        for (&self.preflights) |*entry| {
            if (entry.expires <= now) entry.key_len = 0;
            if (entry.key_len == 0 or !std.mem.eql(u8, entry.key[0..entry.key_len], key)) continue;
            self.serial +|= 1;
            entry.used = self.serial;
            return true;
        }
        return false;
    }
    fn rememberPreflight(self: *SessionPool, key: []const u8, response: http.Response, now: u64, hz: u64) void {
        const value = responseHeader(response.headers, "Access-Control-Max-Age") orelse "5";
        const seconds = @min(std.fmt.parseInt(u64, value, 10) catch 5, 600);
        var replacement = &self.preflights[0];
        for (&self.preflights) |*entry| {
            if (std.mem.eql(u8, entry.key[0..entry.key_len], key)) {
                replacement = entry;
                break;
            }
            if (entry.key_len == 0 or entry.used < replacement.used) replacement = entry;
        }
        if (seconds == 0) {
            replacement.key_len = 0;
            return;
        }
        @memcpy(replacement.key[0..key.len], key);
        replacement.key_len = key.len;
        replacement.expires = now +| (seconds *| hz);
        self.serial +|= 1;
        replacement.used = self.serial;
    }
};

fn sessionKey(url: http.ParsedUrl, options: FetchOptions, output: []u8) ?[]const u8 {
    var host: [253]u8 = undefined;
    if (url.host.len > host.len) return null;
    for (url.host, 0..) |byte, i| host[i] = std.ascii.toLower(byte);
    return std.fmt.bufPrint(output, "{s}://{s}:{d}\norigin={s}\npartition={s}\ncredentials={d}", .{
        url.scheme.text(), host[0..url.host.len], url.port, options.origin, options.network_partition, @intFromBool(options.credentials_include),
    }) catch null;
}
fn preflightKey(url: []const u8, options: FetchOptions, preflight_headers: []const u8, output: []u8) ?[]const u8 {
    return std.fmt.bufPrint(output, "{s}\n{s}\n{s}\ncredentials={d}\n{s}", .{
        options.network_partition, options.origin, url, @intFromBool(options.credentials_include), preflight_headers,
    }) catch null;
}

pub const WebTransport = struct {
    network: app_network.Network,
    dev: r4dev.Context,

    pub fn available(self: *const WebTransport) bool {
        return self.network.available() and self.dev.hasFn("protocol_dispatch");
    }

    /// Registration is a raw TCP exchange. The public profile completes
    /// certificate and IP-SAN verification before any secret bytes are sent.
    pub fn registerServer(self: *WebTransport, endpoint: RegistrationEndpoint, secret: []const u8, scratch: []u8, timeout: Timeout) RegistrationResult {
        if (secret.len == 0 or secret.len > 256) return .invalid_secret;
        for (secret) |byte| if (byte < 0x21 or byte > 0x7e) {
            return .invalid_secret;
        };
        const parsed_ip = app_network.Ipv4Address.parseCanonical(endpoint.hostname) orelse return .{ .failure = .invalid_url };
        if (!std.mem.eql(u8, &parsed_ip.octets, &endpoint.address.octets) or endpoint.port == 0) return .{ .failure = .invalid_url };
        if (endpoint.tls and scratch.len < tls_scratch_bytes) return .{ .failure = .scratch_too_small };
        defer std.crypto.secureZero(u8, scratch);

        const options = FetchOptions{
            .timeout = timeout,
            .progress = if (self.network.sys.base.generation2 != null) ownerRunning else null,
            .progress_context = &self.network.sys,
        };
        if (shouldStop(options)) return .{ .failure = .cancelled };
        const deadline = RequestDeadline.start(&self.network, timeout);
        var socket = switch (Socket.open(self.network, .{ .address = endpoint.address, .port = endpoint.port }, deadline.remaining(&self.network))) {
            .socket => |value| value,
            .timed_out => return .{ .failure = .connect_timeout },
            else => return .{ .failure = .connect_failed },
        };
        defer socket.dispose(deadline.remaining(&self.network));

        var received: usize = 0;
        var reply: [2]u8 = undefined;
        if (endpoint.tls) {
            var url_buffer: [64]u8 = undefined;
            const raw_url = std.fmt.bufPrint(&url_buffer, "https://{s}:{d}/", .{ endpoint.hostname, endpoint.port }) catch return .{ .failure = .invalid_url };
            const url = switch (http.parseUrl(raw_url)) {
                .value => |value| value,
                .failure => return .{ .failure = .invalid_url },
            };
            var session = switch (self.openTlsSession(&socket, url, scratch, options, deadline)) {
                .session => |value| value,
                .failure => |failure| return .{ .failure = failure },
            };
            switch (self.writeTlsApplication(&socket, &session, secret, scratch, options, deadline)) {
                .ok => {},
                .failure => |failure| return .{ .failure = failure },
            }
            while (received < reply.len) {
                switch (self.readTlsApplication(&socket, &session, scratch, options, deadline)) {
                    .bytes => |plain| {
                        if (plain.len == 0) continue;
                        if (plain.len > reply.len - received) return .invalid_reply;
                        @memcpy(reply[received .. received + plain.len], plain);
                        received += plain.len;
                    },
                    .close_notify => return .invalid_reply,
                    .failure => |failure| return .{ .failure = failure },
                }
            }
        } else {
            if (!writeAll(&socket, secret, options, deadline)) return .{ .failure = .write_failed };
            while (received < reply.len) {
                switch (readSocketBounded(&socket, reply[received..], options, deadline)) {
                    .bytes => |count| received += count,
                    .cancelled => return .{ .failure = .cancelled },
                    .timed_out => return .{ .failure = .read_timeout },
                    .reset => return .{ .failure = .read_reset },
                    .peer_closed, .closed => return .invalid_reply,
                    .failed => return .{ .failure = .read_failed },
                }
            }
        }
        return if (std.mem.eql(u8, &reply, "OK")) .accepted else .invalid_reply;
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
                deadline = options.absolute_deadline orelse RequestDeadline.start(&self.network, options.timeout);
                deadline_started = true;
            }
            if (deadline.expired(&self.network)) return .{ .failure = .read_timeout };
            if (options.cors and isCrossOrigin(options.origin, parsed)) {
                var preflight_headers_buffer: [max_request_bytes]u8 = undefined;
                const preflight_headers = corsPreflightHeaders(method, request_headers, preflight_headers_buffer[0..]) orelse return .{ .failure = .cors_preflight_failed };
                var key_buffer: [16 * 1024]u8 = undefined;
                const cache_key = if (preflight_headers.len != 0) preflightKey(current, options, preflight_headers, &key_buffer) else null;
                const cached = if (options.sessions) |pool| if (cache_key) |key| pool.preflightHit(key, self.network.sys.ticks()) else false else false;
                if (preflight_headers.len > 0 and !cached) {
                    if (options.stats) |stats| stats.preflights +|= 1;
                    var preflight_reused = false;
                    var preflight_once = self.fetchOnce(current, parsed, raw_response, body_out, scratch, options, deadline, .options, preflight_headers, "", "", false, false, &preflight_reused);
                    if (preflight_once == .failure and preflight_reused and (shouldRetryReadFailure(.get, preflight_once.failure, 0) or preflight_once.failure == .write_failed)) {
                        preflight_once = self.fetchOnce(current, parsed, raw_response, body_out, scratch, options, deadline, .options, preflight_headers, "", "", false, false, &preflight_reused);
                    }
                    const preflight = switch (preflight_once) {
                        .response => |value| value,
                        .failure => return .{ .failure = .cors_preflight_failed },
                    };
                    if (!acceptsPreflight(preflight.http_response, options.origin, method, request_headers, options.credentials_include)) return .{ .failure = .cors_preflight_failed };
                    if (options.sessions) |pool| if (cache_key) |key| pool.rememberPreflight(key, preflight.http_response, self.network.sys.ticks(), self.network.sys.monotonicHz());
                }
            }
            var conditional_buffer: [max_request_bytes]u8 = undefined;
            const validators = if (redirects == 0) options.conditional_headers else "";
            const transport_headers = if (validators.len != 0 or options.cache_headers.len != 0)
                std.fmt.bufPrint(&conditional_buffer, "{s}{s}{s}", .{ request_headers, options.cache_headers, validators }) catch return .{ .failure = .request_too_large }
            else
                request_headers;
            var reused = false;
            const once = self.fetchOnce(current, parsed, raw_response, body_out, scratch, options, deadline, method, transport_headers, content_type, body, redirects == 0, true, &reused);
            const response = switch (once) {
                .response => |value| value,
                .failure => |err| {
                    if (shouldRetryReadFailure(method, err, read_retries) or shouldRetryReusedWrite(method, err, read_retries, reused)) {
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
                    if (options.method == .get and shouldRetryDownload(failure.cause, read_retries, options.max_retries)) {
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
        reusable: bool = false,
    };

    const ResponseReceiver = struct {
        decoder: http.ResponseDecoder,
        received: usize = 0,
        informational: u8 = 0,

        fn next(self: *ResponseReceiver, raw: []u8, body: []u8, eof: bool, stop: bool) http.DecodeResult {
            while (true) {
                const result = self.decoder.decode(raw[0..self.received], body, eof, stop);
                if (result == .complete and result.complete.status < 200) {
                    if (result.complete.status == 101 or self.informational == 8) return .{ .failure = .malformed_status };
                    self.informational += 1;
                    const consumed = result.complete.consumed;
                    const remaining = self.received - consumed;
                    std.mem.copyForwards(u8, raw[0..remaining], raw[consumed..self.received]);
                    self.received = remaining;
                    self.decoder = http.ResponseDecoder.init(self.decoder.method);
                    continue;
                }
                return result;
            }
        }
        fn complete(self: *const ResponseReceiver, raw: []const u8, response: http.Response, eof: bool) OnceResult {
            return .{ .response = .{ .http_response = response, .reusable = !eof and http.responseAllowsReuse(raw[0..self.received], response) } };
        }
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
        was_reused: *bool,
    ) OnceResult {
        was_reused.* = false;
        var key_buffer: [2048]u8 = undefined;
        const key = sessionKey(url, options, &key_buffer);
        const may_pool = self.network.sys.base.generation2 == null and options.sessions != null and key != null and
            !http.serializedHeadersContain(headers, "Connection") and !http.serializedHeadersContain(headers, "Upgrade");
        const leased = if (may_pool) options.sessions.?.acquire(key.?, self.network.sys.ticks()) else null;
        var temporary: SessionPool.Entry = .{};
        const connection = leased orelse &temporary;
        var reusable = false;
        defer if (leased) |entry| {
            options.sessions.?.release(entry, reusable and !shouldStop(options), self.network.sys.ticks(), self.network.sys.monotonicHz());
        } else SessionPool.closeEntry(connection);
        var opened: ?Socket = null;
        defer if (opened) |*socket| switch (socket.connection) {
            .start1 => |legacy| connection.socket = legacy,
            .start2 => socket.dispose(socket_close_timeout),
        };
        if (connection.socket) |legacy| {
            opened = .{ .network = self.network, .connection = .{ .start1 = legacy } };
            was_reused.* = true;
            if (options.stats) |stats| stats.reused_connections +|= 1;
        } else {
            if (options.stats) |stats| stats.dns_resolutions +|= 1;
            var resolver = self.network.resolver();
            const address = switch (resolver.resolveA(url.host, null, deadline.remaining(&self.network))) {
                .address => |value| value,
                .timed_out => return .{ .failure = .dns_timeout },
                .not_found => return .{ .failure = .dns_not_found },
                else => return .{ .failure = .dns_failed },
            };
            opened = switch (Socket.open(self.network, .{ .address = address, .port = url.port }, deadline.remaining(&self.network))) {
                .socket => |value| value,
                .timed_out => return .{ .failure = .connect_timeout },
                else => return .{ .failure = .connect_failed },
            };
            if (options.stats) |stats| stats.connections +|= 1;
        }
        const socket = &opened.?;

        var cookie_buffer: [1024]u8 = undefined;
        const cookie = if (!allow_cookies)
            ""
        else if (allow_legacy_cookie and options.initial_cookie != null)
            options.initial_cookie.?
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
            .connection_close = leased == null,
        })) {
            .bytes => |value| value,
            else => return .{ .failure = .request_too_large },
        };
        var effective_options = options;
        effective_options.method = method;
        const result = if (url.scheme == .http)
            self.fetchPlain(socket, request, raw_response, body_out, effective_options, deadline)
        else
            self.fetchTls(socket, url, &connection.tls, request, raw_response, body_out, scratch, effective_options, deadline);
        reusable = result == .response and result.response.reusable;
        return result;
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
        var socket = switch (Socket.open(self.network, .{ .address = address, .port = url.port }, deadline.remaining(&self.network))) {
            .socket => |value| value,
            .timed_out => return downloadFailure(.connect_timeout),
            else => return downloadFailure(.connect_failed),
        };
        defer socket.dispose(deadline.remaining(&self.network));

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

    fn fetchPlain(self: *WebTransport, socket: *Socket, request: []const u8, raw_response: []u8, body_out: []u8, options: FetchOptions, deadline: RequestDeadline) OnceResult {
        _ = self;
        if (!writeAll(socket, request, options, deadline)) return .{ .failure = if (shouldStop(options)) .cancelled else .write_failed };
        var receiver = ResponseReceiver{ .decoder = http.ResponseDecoder.init(options.method) };
        defer {
            if (options.stats) |stats| stats.payload_copied_bytes +|= receiver.decoder.copied_bytes;
        }
        while (true) {
            if (shouldStop(options)) return .{ .failure = .cancelled };
            const decoded = receiver.next(raw_response, body_out, false, false);
            switch (decoded) {
                .complete => |response| return receiver.complete(raw_response, response, false),
                .failure => return .{ .failure = .malformed_response },
                .aborted => return .{ .failure = .cancelled },
                .need_more => {},
            }
            if (receiver.received == raw_response.len) return .{ .failure = .response_too_large };
            switch (readSocketBounded(socket, raw_response[receiver.received..], options, deadline)) {
                .bytes => |count| {
                    if (count == 0) continue;
                    receiver.received += count;
                },
                .peer_closed, .closed => {
                    return switch (receiver.next(raw_response, body_out, true, false)) {
                        .complete => |response| receiver.complete(raw_response, response, true),
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

    fn fetchTls(self: *WebTransport, socket: *Socket, url: http.ParsedUrl, cached_session: *?TlsSession, request: []const u8, raw_response: []u8, body_out: []u8, scratch: []u8, options: FetchOptions, deadline: RequestDeadline) OnceResult {
        if (cached_session.* == null) cached_session.* = switch (self.openTlsSession(socket, url, scratch, options, deadline)) {
            .session => |value| value,
            .failure => |failure| return .{ .failure = failure },
        };
        const session = &cached_session.*.?;
        switch (self.writeTlsApplication(socket, session, request, scratch, options, deadline)) {
            .ok => {},
            .failure => |failure| return .{ .failure = failure },
        }

        var receiver = ResponseReceiver{ .decoder = http.ResponseDecoder.init(options.method) };
        defer {
            if (options.stats) |stats| stats.payload_copied_bytes +|= receiver.decoder.copied_bytes;
        }
        while (true) {
            switch (receiver.next(raw_response, body_out, false, shouldStop(options))) {
                .complete => |response| return receiver.complete(raw_response, response, false),
                .aborted => return .{ .failure = .cancelled },
                .failure => return .{ .failure = .malformed_response },
                .need_more => {},
            }
            switch (self.readTlsApplication(socket, session, scratch, options, deadline)) {
                .bytes => |plain| {
                    if (plain.len > raw_response.len - receiver.received) return .{ .failure = .response_too_large };
                    @memcpy(raw_response[receiver.received .. receiver.received + plain.len], plain);
                    receiver.received += plain.len;
                },
                .close_notify => {
                    return switch (receiver.next(raw_response, body_out, true, false)) {
                        .complete => |response| receiver.complete(raw_response, response, true),
                        else => .{ .failure = .tls_close_notify },
                    };
                },
                .failure => |failure| {
                    if (failure == .read_peer_closed) {
                        return switch (receiver.next(raw_response, body_out, true, false)) {
                            .complete => |response| receiver.complete(raw_response, response, true),
                            else => .{ .failure = failure },
                        };
                    }
                    return .{ .failure = failure };
                },
            }
        }
    }

    fn openTlsSession(self: *WebTransport, socket: anytype, url: http.ParsedUrl, scratch: []u8, options: FetchOptions, deadline: RequestDeadline) TlsSessionResult {
        if (options.stats) |stats| stats.tls_handshakes +|= 1;
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

    fn writeTlsApplication(self: *WebTransport, socket: anytype, session: *TlsSession, bytes: []const u8, scratch: []u8, options: FetchOptions, deadline: RequestDeadline) TlsWriteResult {
        const wire = switch (self.protectTlsApplication(session, bytes, scratch)) {
            .bytes => |value| value,
            .failure => |failure| return .{ .failure = failure },
        };
        if (!writeAll(socket, wire, options, deadline)) return .{ .failure = if (shouldStop(options)) .cancelled else .write_failed };
        return .ok;
    }

    fn protectTlsApplication(self: *WebTransport, session: *TlsSession, bytes: []const u8, scratch: []u8) TlsProtected {
        const first = scratch[0..tls_workspace_bytes];
        const third = scratch[tls_workspace_bytes * 2 .. tls_workspace_bytes * 3];
        if (tls_app_header_len + bytes.len > third.len) return .{ .failure = .scratch_too_small };
        @memcpy(third[0..4], "R4CW");
        @memcpy(third[4..tls_app_header_len], session.stream_state[0..]);
        @memcpy(third[tls_app_header_len .. tls_app_header_len + bytes.len], bytes);
        const protected = self.protocolCall(tls_op_client_app_write, third[0 .. tls_app_header_len + bytes.len], first) orelse return .{ .failure = .tls_record_failed };
        if (protected.len <= tls_app_header_len or !startsWith(protected, "R4CX")) return .{ .failure = .tls_record_failed };
        @memcpy(session.stream_state[0..], protected[4..tls_app_header_len]);
        return .{ .bytes = protected[tls_app_header_len..] };
    }

    fn readTlsApplication(self: *WebTransport, socket: anytype, session: *TlsSession, scratch: []u8, options: FetchOptions, deadline: RequestDeadline) TlsApplicationRead {
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

pub const PostStreamAction = enum(u8) { accept, pause, cancel, fail };
pub const PostStreamWrite = *const fn (?*anyopaque, u64, []const u8) PostStreamAction;
/// Positive: bytes produced in `output`; zero: EOF; -1: pause; -2: cancel;
/// every other negative value: source failure. A paused read consumes nothing.
pub const PostStreamRead = *const fn (?*anyopaque, u64, []u8) i64;
pub const PostStreamSink = struct { context: ?*anyopaque = null, write: PostStreamWrite };
pub const PostStreamOptions = struct {
    request: FetchOptions = .{ .method = .post, .redirect = .manual },
    request_body_limit: u64 = 64 * 1024 * 1024,
    response_limits: http.PayloadStreamLimits = .{},
    /// Null selects chunked request framing for a reader. A slice always has
    /// its exact length. Reader and request.body are mutually exclusive.
    request_length: ?u64 = null,
    reader: ?PostStreamRead = null,
    reader_context: ?*anyopaque = null,
};
pub const PostStreamBuffers = struct {
    headers: []u8,
    io: []u8,
    upload: []u8,
    tls: []u8,
};
pub const PostStreamState = enum(u8) { ready, paused, cleanup_pending, complete, cancelled, failed };
pub const PostStreamReport = struct {
    state: PostStreamState = .ready,
    failure: ?Error = null,
    framing_failure: ?http.ResponseError = null,
    status: ?u16 = null,
    response_total: ?u64 = null,
    request_body_confirmed: u64 = 0,
    /// TCP-accepted application wire bytes, including TLS record overhead;
    /// excludes handshake traffic. This is not server execution evidence.
    application_wire_confirmed: u64 = 0,
    response_received: u64 = 0,
    response_delivered: u64 = 0,
    request_effect_unknown: bool = false,
    http_complete: bool = false,
    tcp_eof: bool = false,
    tls_close_notify: bool = false,
    close_ack: bool = false,
};

/// Caller-owned POST/PUT transport. Keep this context, options, callback storage
/// and all four buffers stable until canRelease(). Pausing accepts zero bytes
/// and retains the same chunk for the next run(). No upload or TLS record is
/// automatically replayed. Redirects are manual or errors, never followed.
pub const PostStream = struct {
    transport: *WebTransport,
    options: PostStreamOptions,
    buffers: PostStreamBuffers,
    sink: PostStreamSink,
    deadline: RequestDeadline,
    decoder: http.PayloadStreamDecoder,
    socket: ?app_network.TcpSocket = null,
    tls: ?TlsSession = null,
    url: [max_url_bytes]u8 = undefined,
    url_len: usize = 0,
    parsed_url: ?http.ParsedUrl = null,
    headers: [max_request_bytes]u8 = undefined,
    headers_len: usize = 0,
    request_head: [max_request_bytes]u8 = undefined,
    request_head_len: usize = 0,
    remaining_input: []const u8 = "",
    pending: []const u8 = "",
    result: PostStreamReport = .{},
    length: ?u64 = null,
    preflight: bool = false,
    stopped: bool = false,
    busy: bool = false,
    phase: enum { connect, send_head, send_body, receive, preflight_close, terminal } = .connect,

    /// Initialize in its final stable address; this does not send a request.
    pub fn init(self: *PostStream, transport: *WebTransport, raw_url: []const u8, buffers: PostStreamBuffers, sink: PostStreamSink, options: PostStreamOptions) PostStreamReport {
        self.* = .{ .transport = transport, .options = options, .buffers = buffers, .sink = sink, .deadline = .{ .valid = false }, .decoder = .init(buffers.headers, options.request.method, options.response_limits) };
        if (shouldStop(options.request)) return self.finish(.cancelled);
        if (!targetAuthorized(options.request, raw_url)) return self.finish(.policy_rejected);
        if (raw_url.len == 0 or raw_url.len > self.url.len) return self.finish(.invalid_url);
        const url = switch (http.parseUrl(raw_url)) {
            .value => |v| v,
            else => return self.finish(.invalid_url),
        };
        if (options.request.method != .post and options.request.method != .put) return self.finish(.unsupported_method);
        if (options.request.redirect == .follow) return self.finish(.redirect_disallowed);
        if (buffers.headers.len < http.max_header_bytes) return self.finish(.header_buffer_too_small);
        if (buffers.io.len == 0 or buffers.upload.len == 0) return self.finish(.io_buffer_too_small);
        if (buffers.tls.len < tls_scratch_bytes) return self.finish(.scratch_too_small);
        const limits = options.response_limits;
        if (limits.header_bytes < 4 or limits.header_bytes > http.max_header_bytes or limits.line_bytes < 2 or limits.line_bytes > 1024 or
            limits.trailer_bytes < 2 or limits.trailer_bytes > http.max_header_bytes or limits.trailer_count > http.max_header_count or limits.informational_count > 8) return self.finish(.policy_rejected);
        inline for (.{ "content-length", "transfer-encoding", "expect", "connection" }) |reserved| {
            if (http.serializedHeadersContain(options.request.headers, reserved)) return self.finish(.policy_rejected);
        }
        if (options.reader != null and options.request.body.len != 0) return self.finish(.policy_rejected);
        self.length = if (options.reader != null) options.request_length else options.request.body.len;
        if (options.reader == null and options.request_length != null and options.request_length.? != options.request.body.len) return self.finish(.policy_rejected);
        if (self.length) |length| if (length > options.request_body_limit) return self.finish(.request_too_large);
        @memcpy(self.url[0..raw_url.len], raw_url);
        self.url_len = raw_url.len;
        self.parsed_url = http.parseUrl(self.url[0..self.url_len]).value;
        const headers = if (options.request.content_type.len != 0 and !http.serializedHeadersContain(options.request.headers, "content-type"))
            std.fmt.bufPrint(&self.headers, "{s}Content-Type: {s}\n", .{ options.request.headers, options.request.content_type }) catch return self.finish(.request_too_large)
        else blk: {
            if (options.request.headers.len > self.headers.len) return self.finish(.request_too_large);
            @memcpy(self.headers[0..options.request.headers.len], options.request.headers);
            break :blk self.headers[0..options.request.headers.len];
        };
        self.headers_len = headers.len;
        if (options.request.cors and isCrossOrigin(options.request.origin, url)) {
            var preflight_headers: [max_request_bytes]u8 = undefined;
            const generated = corsPreflightHeaders(options.request.method, headers, &preflight_headers) orelse return self.finish(.cors_preflight_failed);
            if (generated.len != 0) {
                const head = switch (http.buildRequest(&self.request_head, .options, url, .{ .headers = generated, .origin = options.request.origin })) {
                    .bytes => |v| v,
                    else => return self.finish(.request_too_large),
                };
                self.request_head_len = head.len;
                self.preflight = true;
                self.decoder = .init(buffers.headers, .options, options.response_limits);
            }
        }
        if (!self.preflight and !self.preparePost()) return self.result;
        self.deadline = options.request.absolute_deadline orelse RequestDeadline.start(&transport.network, options.request.timeout);
        if (!self.deadline.valid) return self.finish(.read_timeout);
        return self.result;
    }

    pub fn report(self: *const PostStream) PostStreamReport {
        return self.result;
    }

    /// Final response metadata borrows buffers.headers, until reinitialization.
    pub fn response(self: *const PostStream) ?http.Response {
        return if (self.preflight) null else self.decoder.response();
    }

    pub fn canRelease(self: *const PostStream) bool {
        return if (self.socket) |socket| !socket.valid() else true;
    }

    /// Explicit bounded disposal. Unknown/failed Close retains the real socket
    /// and responsibility in this context. No ACK is inferred from FIN/EOF.
    pub fn close(self: *PostStream, timeout: Timeout) bool {
        if (self.busy) return false;
        if (self.phase != .preflight_close and self.phase != .terminal) {
            self.phase = .terminal;
            self.result.state = .cancelled;
            self.result.failure = .cancelled;
        }
        return self.closeOwned(timeout);
    }

    pub fn cancel(self: *PostStream) void {
        self.stopped = true;
    }

    pub fn run(self: *PostStream) PostStreamReport {
        if (self.busy or self.phase == .terminal) return self.result;
        self.busy = true;
        defer self.busy = false;
        self.result.state = .ready;
        while (true) {
            if (self.stopped or shouldStop(self.options.request)) return self.finish(.cancelled);
            if (self.deadline.expired(&self.transport.network)) return self.finish(.read_timeout);
            const url = self.parsed_url.?;
            switch (self.phase) {
                .connect => {
                    var resolver = self.transport.network.resolver();
                    const address = switch (resolver.resolveA(url.host, null, self.deadline.remaining(&self.transport.network))) {
                        .address => |v| v,
                        .timed_out => return self.finish(.dns_timeout),
                        .not_found => return self.finish(.dns_not_found),
                        else => return self.finish(.dns_failed),
                    };
                    self.socket = switch (self.transport.network.connectTcp(.{ .address = address, .port = url.port }, self.deadline.remaining(&self.transport.network))) {
                        .socket => |v| v,
                        .timed_out => return self.finish(.connect_timeout),
                        else => return self.finish(.connect_failed),
                    };
                    self.result.close_ack = false;
                    if (url.scheme == .https) {
                        var tls_options = self.options.request;
                        if (self.preflight) tls_options.entropy = null;
                        self.tls = switch (self.transport.openTlsSession(&self.socket.?, url, self.buffers.tls, tls_options, self.deadline)) {
                            .session => |v| v,
                            .failure => |err| return self.finish(err),
                        };
                    }
                    self.phase = .send_head;
                },
                .send_head => {
                    if (!self.send(self.request_head[0..self.request_head_len], false)) return self.result;
                    self.phase = if (self.preflight) .receive else .send_body;
                },
                .send_body => {
                    const offset = self.result.request_body_confirmed;
                    if (self.length) |length| if (offset == length) {
                        self.phase = .receive;
                        continue;
                    };
                    const capacity = @min(self.buffers.upload.len, @as(usize, 8 * 1024));
                    const available: usize = if (self.length) |length| @intCast(@min(capacity, length - offset)) else capacity;
                    const bytes = if (self.options.reader) |reader| blk: {
                        const n = reader(self.options.reader_context, offset, self.buffers.upload[0..available]);
                        if (n == -1) {
                            self.result.state = .paused;
                            return self.result;
                        }
                        if (n == -2) return self.finish(.cancelled);
                        if (n < 0 or n > available) return self.finish(.read_failed);
                        if (n == 0) {
                            if (self.length != null) return self.finish(.read_failed);
                            if (!self.send("0\r\n\r\n", false)) return self.result;
                            self.phase = .receive;
                            continue;
                        }
                        break :blk self.buffers.upload[0..@intCast(n)];
                    } else self.options.request.body[@intCast(offset)..][0..available];
                    if (bytes.len > self.options.request_body_limit - offset) return self.finish(.request_too_large);
                    if (self.length == null) {
                        var line: [24]u8 = undefined;
                        const prefix = std.fmt.bufPrint(&line, "{x}\r\n", .{bytes.len}) catch unreachable;
                        if (!self.send(prefix, false)) return self.result;
                    }
                    if (!self.send(bytes, true)) return self.result;
                    if (self.length == null and !self.send("\r\n", false)) return self.result;
                },
                .receive => {
                    if (self.pending.len != 0) {
                        const action = self.sink.write(self.sink.context, self.result.response_delivered, self.pending);
                        // Acceptance happens inside the callback, before any
                        // stop intent it may publish. Never erase that prefix.
                        if (action == .accept) {
                            self.result.response_delivered += self.pending.len;
                            self.pending = "";
                        }
                        if (self.stopped or shouldStop(self.options.request)) return self.finish(.cancelled);
                        switch (action) {
                            .pause => {
                                self.result.state = .paused;
                                return self.result;
                            },
                            .cancel => return self.finish(.cancelled),
                            .fail => return self.finish(.sink_failed),
                            .accept => {},
                        }
                        continue;
                    }
                    const eof = self.result.tcp_eof or self.result.tls_close_notify;
                    const step = self.decoder.push(self.remaining_input, eof, false);
                    self.remaining_input = self.remaining_input[step.consumed..];
                    if (!self.preflight) self.result.response_received = self.decoder.receivedBytes();
                    switch (step.state) {
                        .head => {
                            const head = self.decoder.response().?;
                            if (self.preflight) {
                                if (!acceptsPreflight(head, self.options.request.origin, self.options.request.method, self.headers[0..self.headers_len], self.options.request.credentials_include)) return self.finish(.cors_preflight_failed);
                            } else {
                                self.result.status = head.status;
                                self.result.response_total = self.decoder.totalBytes();
                                if (self.options.request.cors and isCrossOrigin(self.options.request.origin, url) and !acceptsCorsResponse(head, self.options.request.origin, self.options.request.credentials_include)) return self.finish(.cors_rejected);
                                if (head.isRedirect() and self.options.request.redirect == .error_mode) return self.finish(.redirect_disallowed);
                                if (self.options.request.cookie_sink) |sink| {
                                    for (head.set_cookies[0..head.set_cookie_count]) |cookie| if (cookie) |value| sink(self.options.request.cookie_context, self.url[0..self.url_len], value);
                                }
                            }
                        },
                        .chunk => if (!self.preflight) {
                            self.pending = step.bytes;
                        },
                        .complete => {
                            if (self.preflight) {
                                self.phase = .preflight_close;
                                continue;
                            }
                            self.result.http_complete = true;
                            self.result.state = .complete;
                            self.phase = .terminal;
                            _ = self.closeOwned(self.deadline.remaining(&self.transport.network));
                            return self.result;
                        },
                        .failure => {
                            self.result.framing_failure = step.failure;
                            return self.finish(if (step.failure == .body_too_large) .response_too_large else .malformed_response);
                        },
                        .aborted => return self.finish(.cancelled),
                        .need_more => {
                            if (self.remaining_input.len != 0) return self.finish(.malformed_response);
                            if (self.tls) |*session| {
                                switch (self.transport.readTlsApplication(&self.socket.?, session, self.buffers.tls, self.options.request, self.deadline)) {
                                    .bytes => |bytes| self.remaining_input = bytes,
                                    .close_notify => self.result.tls_close_notify = true,
                                    .failure => |err| {
                                        if (err == .read_peer_closed) self.result.tcp_eof = true;
                                        // A bare TCP EOF never authenticates a TLS body end.
                                        return self.finish(if (err == .read_failed and self.deadline.expired(&self.transport.network)) .read_timeout else err);
                                    },
                                }
                            } else switch (readSocketBounded(&self.socket.?, self.buffers.io, self.options.request, self.deadline)) {
                                .bytes => |n| self.remaining_input = self.buffers.io[0..n],
                                .peer_closed, .closed => self.result.tcp_eof = true,
                                .cancelled => return self.finish(.cancelled),
                                .timed_out => return self.finish(.read_timeout),
                                .reset => return self.finish(.read_reset),
                                .failed => return self.finish(if (self.deadline.expired(&self.transport.network)) .read_timeout else .read_failed),
                            }
                        },
                    }
                },
                .preflight_close => {
                    if (!self.closeOwned(self.deadline.remaining(&self.transport.network))) {
                        self.result.state = .cleanup_pending;
                        return self.result;
                    }
                    self.socket = null;
                    self.tls = null;
                    self.preflight = false;
                    self.result = .{};
                    self.decoder = .init(self.buffers.headers, self.options.request.method, self.options.response_limits);
                    if (!self.preparePost()) return self.result;
                    self.phase = .connect;
                },
                .terminal => return self.result,
            }
        }
    }

    fn preparePost(self: *PostStream) bool {
        var cookie_buffer: [1024]u8 = undefined;
        const options = self.options.request;
        const cookie = if (options.initial_cookie) |v| v else if (options.cookie_provider) |provider|
            provider(options.cookie_context, self.url[0..self.url_len], &cookie_buffer)
        else
            options.cookie;
        const head = switch (http.buildStreamRequestHead(&self.request_head, options.method, self.parsed_url.?, .{ .cookie = cookie, .origin = options.origin, .headers = self.headers[0..self.headers_len] }, if (self.length) |length| .{ .content_length = length } else .chunked)) {
            .bytes => |v| v,
            else => {
                _ = self.finish(.request_too_large);
                return false;
            },
        };
        self.request_head_len = head.len;
        return true;
    }

    fn send(self: *PostStream, plain: []const u8, body: bool) bool {
        // A record is protected once. On a partial/unknown write it is never
        // protected or submitted again; only earlier confirmed prefixes count.
        const wire = if (self.tls) |*session| switch (self.transport.protectTlsApplication(session, plain, self.buffers.tls)) {
            .bytes => |v| v,
            .failure => |err| {
                _ = self.finish(err);
                return false;
            },
        } else plain;
        var pos: usize = 0;
        while (pos < wire.len) {
            if (self.stopped or shouldStop(self.options.request)) {
                if (!self.preflight and self.tls != null and pos != 0) self.result.request_effect_unknown = true;
                _ = self.finish(.cancelled);
                return false;
            }
            if (self.deadline.expired(&self.transport.network)) {
                if (!self.preflight and self.tls != null and pos != 0) self.result.request_effect_unknown = true;
                _ = self.finish(.read_timeout);
                return false;
            }
            const end = @min(wire.len, pos + abi.net_service_tcp_write_max);
            switch (self.socket.?.write(wire[pos..end], self.deadline.remaining(&self.transport.network))) {
                .bytes => |n| {
                    if (n == 0) {
                        self.transport.network.sys.sleepTicks(1);
                        continue;
                    }
                    if (!self.preflight) {
                        self.result.application_wire_confirmed += n;
                        if (body and self.tls == null) self.result.request_body_confirmed += n;
                    }
                    pos += n;
                },
                .would_block => self.transport.network.sys.sleepTicks(1),
                .failure => {
                    if (!self.preflight) self.result.request_effect_unknown = true;
                    _ = self.finish(if (self.stopped or shouldStop(self.options.request)) .cancelled else if (self.deadline.expired(&self.transport.network)) .read_timeout else .write_failed);
                    return false;
                },
                else => {
                    if (!self.preflight and self.tls != null and pos != 0) self.result.request_effect_unknown = true;
                    _ = self.finish(.write_failed);
                    return false;
                },
            }
        }
        if (body and self.tls != null and !self.preflight) self.result.request_body_confirmed += plain.len;
        return true;
    }

    fn closeOwned(self: *PostStream, timeout: Timeout) bool {
        if (self.socket) |*socket| {
            if (!socket.valid()) return true;
            _ = socket.close(timeout);
            if (socket.valid()) return false;
            self.result.close_ack = true;
        }
        return true;
    }

    fn finish(self: *PostStream, failure: Error) PostStreamReport {
        self.result.failure = failure;
        self.result.state = if (failure == .cancelled) .cancelled else .failed;
        self.phase = .terminal;
        if (self.socket != null) _ = self.closeOwned(if (self.deadline.valid) self.deadline.remaining(&self.transport.network) else time_contract.timeoutPoll());
        return self.result;
    }
};

test "HTTP81 actual POST owner retains paused bytes counts acceptance and handles cancel sink error" {
    const State = struct {
        action: PostStreamAction = .pause,
        stop: ?*abi.R4StopFlag = null,
        calls: usize = 0,
        output: [8]u8 = undefined,
        fn write(raw: ?*anyopaque, offset: u64, bytes: []const u8) PostStreamAction {
            const self: *@This() = @ptrCast(@alignCast(raw.?));
            self.calls += 1;
            if (self.action == .accept) @memcpy(self.output[@intCast(offset)..][0..bytes.len], bytes);
            if (self.stop) |flag| @atomicStore(u32, &flag.value, 1, .release);
            return self.action;
        }
    };
    var transport: WebTransport = undefined; // No network branch is reached.
    var header: [http.max_header_bytes]u8 = undefined;
    var io: [64]u8 = undefined;
    var upload: [64]u8 = undefined;
    var scratch: [tls_scratch_bytes]u8 = undefined;
    var sink = State{};
    var stream = PostStream{ .transport = &transport, .options = .{}, .buffers = .{ .headers = &header, .io = &io, .upload = &upload, .tls = &scratch }, .sink = .{ .context = &sink, .write = State.write }, .deadline = .{ .forever = true }, .decoder = .init(&header, .post, .{}), .phase = .receive, .remaining_input = "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n8\r\nabcdefgh\r\n0\r\n\r\n" };
    const url = "http://stream.example/events";
    @memcpy(stream.url[0..url.len], url);
    stream.url_len = url.len;
    stream.parsed_url = http.parseUrl(url).value;
    const paused = stream.run();
    try std.testing.expectEqual(PostStreamState.paused, paused.state);
    try std.testing.expectEqual(@as(u64, 8), paused.response_received);
    try std.testing.expectEqual(@as(u64, 0), paused.response_delivered);
    try std.testing.expect(paused.response_total == null and !paused.http_complete and !paused.close_ack);
    sink.action = .accept;
    const complete = stream.run();
    try std.testing.expectEqual(PostStreamState.complete, complete.state);
    try std.testing.expectEqual(@as(u64, 8), complete.response_delivered);
    try std.testing.expectEqualStrings("abcdefgh", &sink.output);
    try std.testing.expect(complete.http_complete and !complete.close_ack and stream.canRelease());
    try std.testing.expectEqual(@as(usize, 2), sink.calls);

    // Reuse the actual retained context path, without manufacturing an ACK.
    stream.phase = .receive;
    stream.result = .{};
    stream.pending = "x";
    sink.action = .fail;
    try std.testing.expectEqual(Error.sink_failed, stream.run().failure.?);
    try std.testing.expectEqual(@as(u64, 0), stream.report().response_delivered);
    stream.phase = .receive;
    stream.result = .{};
    stream.cancel();
    try std.testing.expectEqual(PostStreamState.cancelled, stream.run().state);
    var stop = abi.R4StopFlag{ .value = 0 };
    stream.phase = .receive;
    stream.result = .{};
    stream.stopped = false;
    stream.options.request.stop = &stop;
    stream.pending = "x";
    sink.action = .accept;
    sink.stop = &stop;
    const accepted_then_stopped = stream.run();
    try std.testing.expectEqual(PostStreamState.cancelled, accepted_then_stopped.state);
    try std.testing.expectEqual(@as(u64, 1), accepted_then_stopped.response_delivered);
    const rejected = stream.init(&transport, url, stream.buffers, stream.sink, .{ .request = .{ .method = .post, .redirect = .manual, .body = "exceeds" }, .request_body_limit = 2 });
    try std.testing.expectEqual(Error.request_too_large, rejected.failure.?);
    try std.testing.expect(stream.canRelease() and !rejected.close_ack);
}

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

fn shouldRetryDownload(failure: Error, attempts: u8, max_retries: u8) bool {
    if (attempts >= max_retries) return false;
    return failure == .read_timeout or failure == .read_reset or failure == .read_peer_closed or failure == .read_failed or failure == .tls_close_notify;
}

fn shouldRetryReusedWrite(method: http.Method, failure: Error, attempts: u8, reused: bool) bool {
    return reused and attempts == 0 and failure == .write_failed and (method == .get or method == .head);
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
        if (!headerTokenContains(allow_headers, line[0..colon], credentials_include or std.ascii.eqlIgnoreCase(line[0..colon], "authorization"))) return false;
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
    try std.testing.expect(shouldRetryReusedWrite(.get, .write_failed, 0, true));
    try std.testing.expect(!shouldRetryReusedWrite(.get, .write_failed, 1, true));
    try std.testing.expect(!shouldRetryReusedWrite(.get, .write_failed, 0, false));
    try std.testing.expect(!shouldRetryReusedWrite(.post, .write_failed, 0, true));
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
    try std.testing.expect(shouldRetryDownload(.read_peer_closed, 0, 1));
    try std.testing.expect(!shouldRetryDownload(.read_peer_closed, 1, 1));
    try std.testing.expect(!shouldRetryDownload(.read_peer_closed, 0, 0));
    try std.testing.expect(shouldRetryDownload(.read_timeout, 2, 3));
    try std.testing.expect(!shouldRetryDownload(.read_timeout, 3, 3));
    try std.testing.expect(!shouldRetryDownload(.tls_certificate_rejected, 0, 3));

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

test "stream download observes headers once before writes and stops before rejected or cancelled bodies" {
    const State = struct {
        allow: bool = true,
        observed: u32 = 0,
        writes: u32 = 0,
        expected_offset: u64 = 0,
        stop: ?*abi.R4StopFlag = null,

        fn observe(context: ?*anyopaque, head: DownloadHeadObservation) bool {
            const self: *@This() = @ptrCast(@alignCast(context.?));
            self.observed += 1;
            if (self.stop) |stop| @atomicStore(u32, &stop.value, 1, .release);
            return self.allow and head.requested_offset == self.expected_offset and head.response.status == 200 and
                std.mem.indexOf(u8, head.headers, "ETag: \"expected\"") != null;
        }
        fn write(context: ?*anyopaque, _: u64, _: []const u8) bool {
            const self: *@This() = @ptrCast(@alignCast(context.?));
            if (self.observed != 1) return false;
            self.writes += 1;
            return true;
        }
    };
    const raw = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nETag: \"expected\"\r\n\r\na";
    var header: [512]u8 = undefined;
    var state = State{ .allow = false };
    var pump = DownloadPump{ .decoder = .init(&header, .get), .sink = .{ .context = &state, .write_fn = State.write }, .options = .{ .head_observer = State.observe, .head_context = &state }, .resume_from = 0, .expected_size = 2 };
    const rejected = pump.feed(raw, false, .read_peer_closed).?;
    try std.testing.expect(rejected == .failure and rejected.failure.cause == .policy_rejected and rejected.failure.transferred == 0);
    try std.testing.expectEqual(@as(u32, 0), state.writes);
    state = .{};
    pump = .{ .decoder = .init(&header, .get), .sink = .{ .context = &state, .write_fn = State.write }, .options = .{ .head_observer = State.observe, .head_context = &state }, .resume_from = 0, .expected_size = 2 };
    try std.testing.expect(pump.feed(raw, false, .read_peer_closed) == null);
    const complete = pump.feed("b", false, .read_peer_closed).?;
    try std.testing.expect(complete == .response and complete.response.transferred == 2);
    try std.testing.expectEqual(@as(u32, 1), state.observed);
    try std.testing.expectEqual(@as(u32, 2), state.writes);
    var stop: abi.R4StopFlag = .{};
    state = .{ .stop = &stop };
    pump = .{ .decoder = .init(&header, .get), .sink = .{ .context = &state, .write_fn = State.write }, .options = .{ .stop = &stop, .head_observer = State.observe, .head_context = &state }, .resume_from = 0, .expected_size = 2 };
    const cancelled = pump.feed(raw, false, .read_peer_closed).?;
    try std.testing.expect(cancelled == .failure and cancelled.failure.cause == .cancelled and cancelled.failure.transferred == 0);
    try std.testing.expectEqual(@as(u32, 0), state.writes);
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

fn writeAll(socket: anytype, bytes: []const u8, options: FetchOptions, deadline: RequestDeadline) bool {
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

fn readSocketBounded(socket: anytype, out: []u8, options: FetchOptions, deadline: RequestDeadline) BoundedSocketRead {
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

fn readTlsRecord(socket: anytype, out: []u8, options: FetchOptions, deadline: RequestDeadline) TlsRecordReadResult {
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

fn readTlsHandshakeFlight(socket: anytype, out: []u8, record_storage: []u8, options: FetchOptions, deadline: RequestDeadline) TlsHandshakeFlightResult {
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

fn readTlsFlight(socket: anytype, out: []u8, options: FetchOptions, deadline: RequestDeadline) ?[]u8 {
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

fn ownerRunning(raw: ?*anyopaque) callconv(.c) bool {
    const sys: *const @import("r4sys.zig").Context = @ptrCast(@alignCast(raw orelse return false));
    return !sys.programShouldClose();
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

test "buffered web receiver consumes informational headers before the final chunked response" {
    const wire = "HTTP/1.1 103 Early Hints\r\nLink: </asset>\r\n\r\nHTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nabc\r\n0\r\n\r\n";
    var raw: [512]u8 = undefined;
    var body: [32]u8 = undefined;
    const split = wire.len - 8;
    @memcpy(raw[0..split], wire[0..split]);
    var receiver = WebTransport.ResponseReceiver{ .decoder = .{}, .received = split };
    try std.testing.expect(receiver.next(&raw, &body, false, false) == .need_more);
    @memcpy(raw[receiver.received .. receiver.received + wire.len - split], wire[split..]);
    receiver.received += wire.len - split;
    const response = receiver.next(&raw, &body, false, false).complete;
    try std.testing.expectEqual(@as(u16, 200), response.status);
    try std.testing.expectEqualStrings("abc", response.body);
    try std.testing.expectEqual(@as(u64, 3), receiver.decoder.copied_bytes);
    try std.testing.expect(receiver.complete(&raw, response, false).response.reusable);
    try std.testing.expect(!receiver.complete(&raw, response, true).response.reusable);
}

test "preflight cache expires and isolates URL origin partition credentials and header names" {
    const pool = try std.testing.allocator.create(SessionPool);
    defer std.testing.allocator.destroy(pool);
    pool.* = .{};
    defer pool.deinit();
    var key_buffer: [16 * 1024]u8 = undefined;
    var other_buffer: [16 * 1024]u8 = undefined;
    var body: [1]u8 = undefined;
    const url = "https://asset.example/value";
    const options: FetchOptions = .{ .origin = "https://app.example", .network_partition = "document-a" };
    const headers = "access-control-request-method:GET\naccess-control-request-headers:x-one\n";
    const key = preflightKey(url, options, headers, &key_buffer).?;
    const wire = "HTTP/1.1 204 No Content\r\nAccess-Control-Allow-Origin: https://app.example\r\nAccess-Control-Allow-Headers: *\r\nAccess-Control-Max-Age: 3\r\n\r\n";
    const response = http.decodeResponse(wire, &body, false, false).complete;
    try std.testing.expect(acceptsPreflight(response, options.origin, .get, "x-one:value\n", false));
    try std.testing.expect(!acceptsPreflight(response, options.origin, .get, "authorization:value\n", false));
    pool.rememberPreflight(key, response, 1000, 1000);
    try std.testing.expect(pool.preflightHit(key, 3999));
    var variant = options;
    variant.credentials_include = true;
    try std.testing.expect(!pool.preflightHit(preflightKey(url, variant, headers, &other_buffer).?, 1001));
    variant = options;
    variant.origin = "https://other.example";
    try std.testing.expect(!pool.preflightHit(preflightKey(url, variant, headers, &other_buffer).?, 1001));
    variant = options;
    variant.network_partition = "document-b";
    try std.testing.expect(!pool.preflightHit(preflightKey(url, variant, headers, &other_buffer).?, 1001));
    try std.testing.expect(!pool.preflightHit(preflightKey("https://asset.example/other", options, headers, &other_buffer).?, 1001));
    try std.testing.expect(!pool.preflightHit(preflightKey(url, options, "access-control-request-method:GET\naccess-control-request-headers:x-two\n", &other_buffer).?, 1001));
    try std.testing.expect(!pool.preflightHit(key, 4000));
    const tls_url = http.parseUrl(url).value;
    const connection_key = sessionKey(tls_url, options, &key_buffer).?;
    try std.testing.expect(!std.mem.eql(u8, connection_key, sessionKey(http.parseUrl("http://asset.example/value").value, options, &other_buffer).?));
    try std.testing.expect(!std.mem.eql(u8, connection_key, sessionKey(http.parseUrl("https://asset.example:8443/value").value, options, &other_buffer).?));
    try std.testing.expect(!std.mem.eql(u8, connection_key, sessionKey(tls_url, variant, &other_buffer).?));
}
