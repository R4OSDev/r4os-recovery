const std = @import("std");
const runtime = @import("web_runtime.zig");
const jobs = @import("app_web_jobs.zig");
const web = @import("app_web.zig");
const navigation = @import("web_navigation.zig");
const security = @import("web_security.zig");

/// Called only by the owner, including callbacks marshalled from a worker.
/// Looking up a generation instead of retaining a Runtime pointer also handles
/// subdocuments destroyed while their transport is still being cancelled.
pub const Owner = struct {
    context: ?*anyopaque,
    find: *const fn (?*anyopaque, u32) ?*runtime.WebRuntime,
};

/// Frozen request and independent response buffers for one of two transports.
/// The owner may wrap options/completion with its response cache transaction.
pub const RequestJob = struct {
    job: jobs.Job,
    owner: Owner,
    allocator: std.mem.Allocator,
    memory: []u8 = &.{},
    active: bool = false,
    generation: u32 = 0,
    ids: [runtime.max_requests]u32 = undefined,
    count: usize = 0,
    kind: runtime.RequestKind = .fetch,
    mode: security.RequestMode = .cors,
    credentials: security.CredentialsMode = .same_origin,
    cache_mode: runtime.RequestCacheMode = .normal,
    origin: security.Origin = .{},
    origin_text: [security.max_origin_host_bytes + 24]u8 = undefined,
    partition: [512]u8 = undefined,
    url: navigation.Url = .{},
    options: web.FetchOptions = .{},

    pub fn prepare(self: *RequestJob, source: *runtime.WebRuntime, request: *runtime.PendingRequest, raw_capacity: usize, body_capacity: usize) !void {
        std.debug.assert(!self.active and self.job.handle == null and self.memory.len == 0);
        const request_bytes = request.requestHeaders().len + request.bodyBytes().len;
        self.memory = try self.allocator.alloc(u8, raw_capacity + body_capacity + web.tls_scratch_bytes + request_bytes);
        self.active = true;
        self.generation = request.generation;
        self.count = source.joinResourceRequests(request, &self.ids);
        self.kind = request.kind;
        self.mode = request.mode;
        self.credentials = request.credentials;
        self.cache_mode = request.cache_mode;
        self.origin = source.security_context.document_origin;
        self.url = request.url;
        self.job.raw = self.memory[0..raw_capacity];
        self.job.body = self.memory[raw_capacity..][0..body_capacity];
        self.job.scratch = self.memory[raw_capacity + body_capacity ..][0..web.tls_scratch_bytes];
        const headers = self.memory[raw_capacity + body_capacity + web.tls_scratch_bytes ..][0..request.requestHeaders().len];
        const body = self.memory[self.memory.len - request.bodyBytes().len ..];
        @memcpy(headers, request.requestHeaders());
        @memcpy(body, request.bodyBytes());
        @atomicStore(u32, &self.job.stop.value, 0, .release);
        const partition = std.fmt.bufPrint(&self.partition, "opaque={d};mode={s};credentials={s}", .{
            self.origin.opaque_id, @tagName(request.mode), @tagName(request.credentials),
        }) catch unreachable;
        self.options = .{
            .stop = &self.job.stop,
            .origin = self.origin.serialize(&self.origin_text) orelse "null",
            .network_partition = partition,
            .method = request.method,
            .redirect = switch (request.redirect) {
                .follow => .follow,
                .error_mode => .error_mode,
                .manual => .manual,
            },
            .headers = headers,
            .body = body,
            .cors = request.mode == .cors,
            .credentials_include = request.credentials == .include,
            .cookie_provider = cookieProvider,
            .cookie_sink = cookieSink,
            .cookie_context = self,
            .target_authorizer = authorize,
            .target_authorization_context = self,
        };
        self.options.absolute_deadline = web.RequestDeadline.start(&self.job.transport.network, self.options.timeout);
    }

    pub fn start(self: *RequestJob, options: web.FetchOptions) bool {
        return self.job.start(self.url.bytes(), self.job.raw, self.job.body, self.job.scratch, options);
    }

    pub fn activeRuntime(self: *RequestJob) ?*runtime.WebRuntime {
        const owner = self.owner.find(self.owner.context, self.generation) orelse return null;
        for (self.ids[0..self.count]) |id| if (owner.requestInFlight(id, self.generation)) return owner;
        return null;
    }

    pub fn poll(self: *RequestJob) bool {
        if (!self.active) return false;
        if (self.activeRuntime() == null or self.job.transport.network.sys.programShouldClose()) self.job.cancel();
        return self.job.collect();
    }

    pub fn release(self: *RequestJob) void {
        std.debug.assert(self.job.handle == null);
        self.allocator.free(self.memory);
        self.memory = &.{};
        self.active = false;
    }

    pub fn deinit(self: *RequestJob) void {
        self.job.deinit();
        self.release();
    }

    pub fn fail(self: *RequestJob, message: []const u8, policy: bool) void {
        for (self.ids[0..self.count]) |id| {
            const owner = self.owner.find(self.owner.context, self.generation) orelse break;
            if (!owner.requestInFlight(id, self.generation)) continue;
            if (policy) owner.failRequestPolicy(id, self.generation, message) catch {} else owner.failRequest(id, self.generation, message) catch {};
        }
    }

    /// Response publication is owner-only; every consumer keeps its own ID.
    pub fn complete(self: *RequestJob, response: web.FetchResponse, identity: u64) void {
        for (self.ids[0..self.count]) |id| {
            const owner = self.owner.find(self.owner.context, self.generation) orelse break;
            if (!owner.requestInFlight(id, self.generation)) continue;
            owner.completeRequest(id, self.generation, .{
                .status = response.status,
                .secure = response.secure,
                .content_type = response.content_type orelse "",
                .content_security_policy = response.content_security_policy orelse "",
                .headers = response.headers,
                .redirected = response.redirects > 0,
                .final_url = response.final_url.bytes(),
                .access_control_allow_origin = response.access_control_allow_origin orelse "",
                .access_control_allow_credentials = response.access_control_allow_credentials,
                .set_cookies = response.set_cookies,
                .set_cookie_count = response.set_cookie_count,
                .manual_redirect = response.manual_redirect,
                .cookies_processed = true,
                .response_identity = identity,
            }, response.body) catch |err| {
                if (owner.requestInFlight(id, self.generation)) owner.failRequest(id, self.generation, @errorName(err)) catch {};
            };
        }
    }

    fn authorize(raw: ?*anyopaque, url: []const u8) bool {
        const self: *RequestJob = @ptrCast(@alignCast(raw.?));
        const owner = self.activeRuntime() orelse return false;
        return owner.authorizeRequestTarget(self.generation, self.kind, self.mode, url);
    }

    fn cookieProvider(raw: ?*anyopaque, url: []const u8, out: []u8) []const u8 {
        const self: *RequestJob = @ptrCast(@alignCast(raw.?));
        const owner = self.activeRuntime() orelse return "";
        const storage = owner.storage orelse return "";
        const origin = security.Origin.parse(url, self.generation) catch return "";
        if (self.credentials == .omit or (self.credentials == .same_origin and !self.origin.same(&origin))) return "";
        return storage.cookies.writeRequestHeader(&origin, urlPath(url), self.origin.same(&origin), out);
    }

    fn cookieSink(raw: ?*anyopaque, url: []const u8, header: []const u8) void {
        const self: *RequestJob = @ptrCast(@alignCast(raw.?));
        const owner = self.activeRuntime() orelse return;
        const storage = owner.storage orelse return;
        const origin = security.Origin.parse(url, self.generation) catch return;
        if (self.credentials == .omit or (self.credentials == .same_origin and !self.origin.same(&origin))) return;
        storage.cookies.setFromHeader(&origin, urlPath(url), header) catch {};
    }
};

fn urlPath(url: []const u8) []const u8 {
    const scheme = std.mem.indexOf(u8, url, "://") orelse return "/";
    const start = std.mem.indexOfScalarPos(u8, url, scheme + 3, '/') orelse return "/";
    return url[start .. std.mem.indexOfAnyPos(u8, url, start, "?#") orelse url.len];
}
