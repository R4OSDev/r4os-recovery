const std = @import("std");
const abi = @import("r4os_contract").abi;
const web = @import("app_web.zig");
const resources = @import("app_resources.zig");
const time = @import("time_contract.zig");

pub const capacity = 2;

/// One transport worker; request and response storage must remain at stable
/// addresses through collect(). The owner services callbacks while waiting.
/// Runtime/DOM/cache access is never performed by the transport thread.
pub const Job = struct {
    transport: web.WebTransport,
    sessions: web.SessionPool = .{},
    stats: web.TransportStats = .{},
    handle: ?resources.JoinHandle = null,
    stop: abi.R4StopFlag = .{},
    done: u32 = 0,
    invocation_pending: u32 = 0,
    invocation_context: ?*anyopaque = null,
    invocation_fn: ?*const fn (*anyopaque) void = null,
    url: []const u8 = "",
    raw: []u8 = &.{},
    body: []u8 = &.{},
    scratch: []u8 = &.{},
    owner_options: web.FetchOptions = .{},
    result: web.FetchResult = .{ .failure = .cancelled },

    pub fn start(self: *Job, url: []const u8, raw: []u8, body: []u8, scratch: []u8, options: web.FetchOptions) bool {
        std.debug.assert(self.handle == null and self.invocation_pending == 0);
        self.url = url;
        self.raw = raw;
        self.body = body;
        self.scratch = scratch;
        self.owner_options = options;
        self.owner_options.absolute_deadline = options.absolute_deadline orelse web.RequestDeadline.start(&self.transport.network, options.timeout);
        @atomicStore(u32, &self.stop.value, 0, .release);
        @atomicStore(u32, &self.done, 0, .release);
        const owner: resources.Resources = .{ .sys = self.transport.network.sys };
        // The transport contains bounded HTTP/TLS workspaces, not a JS realm.
        switch (owner.createThread(entry, @intFromPtr(self), 1024 * 1024)) {
            .handle => |handle| self.handle = handle,
            .failure => return false,
        }
        return true;
    }

    pub fn cancel(self: *Job) void {
        @atomicStore(u32, &self.stop.value, 1, .release);
    }

    pub fn service(self: *Job) bool {
        if (self.handle == null) return false;
        if (self.owner_options.stop) |flag| if (@atomicLoad(u32, &flag.value, .acquire) != 0) self.cancel();
        if (@atomicLoad(u32, &self.invocation_pending, .acquire) == 0) return false;
        self.invocation_fn.?(self.invocation_context.?);
        @atomicStore(u32, &self.invocation_pending, 0, .release);
        return true;
    }

    /// Nonblocking join. Only after this returns true may buffers be reused.
    pub fn collect(self: *Job) bool {
        _ = self.service();
        const handle = if (self.handle) |*handle| handle else return false;
        if (@atomicLoad(u32, &self.done, .acquire) == 0) return false;
        switch (handle.join(time.timeoutPoll())) {
            .exited => {},
            .failure => if (handle.valid()) return false,
            .timed_out => return false,
        }
        self.handle = null;
        if (@atomicLoad(u32, &self.stop.value, .acquire) != 0) self.sessions.deinit();
        return true;
    }

    pub fn deinit(self: *Job) void {
        self.cancel();
        while (self.handle != null) {
            if (self.collect()) break;
            self.transport.network.sys.sleepTicks(1);
        }
        self.sessions.deinit();
    }

    fn invoke(self: *Job, comptime T: type, context: *T, callback: *const fn (*T) void) void {
        const Invocation = struct {
            context: *T,
            callback: *const fn (*T) void,
            fn run(raw: *anyopaque) void {
                const call: *@This() = @ptrCast(@alignCast(raw));
                call.callback(call.context);
            }
        };
        var call: Invocation = .{ .context = context, .callback = callback };
        self.invocation_context = &call;
        self.invocation_fn = Invocation.run;
        @atomicStore(u32, &self.invocation_pending, 1, .release);
        // Cancellation still drains already published invocations before join.
        while (@atomicLoad(u32, &self.invocation_pending, .acquire) != 0) self.transport.network.sys.sleepTicks(1);
    }

    fn entry(argument: u64) callconv(.c) i32 {
        const self: *Job = @ptrFromInt(argument);
        var options = self.owner_options;
        options.stop = &self.stop;
        options.sessions = &self.sessions;
        options.stats = &self.stats;
        // Progress and GUI event pumping belong to the caller's owner loop.
        options.progress = null;
        options.progress_context = null;
        options.cookie_context = self;
        options.cookie_provider = if (self.owner_options.cookie_provider != null) provideCookie else null;
        options.cookie_sink = if (self.owner_options.cookie_sink != null) acceptCookie else null;
        options.target_authorization_context = self;
        options.target_authorizer = if (self.owner_options.target_authorizer != null) authorizeTarget else null;
        self.result = self.transport.fetch(self.url, self.raw, self.body, self.scratch, options);
        @atomicStore(u32, &self.done, 1, .release);
        return 0;
    }

    fn provideCookie(raw: ?*anyopaque, url: []const u8, out: []u8) []const u8 {
        const self: *Job = @ptrCast(@alignCast(raw.?));
        const Call = struct {
            job: *Job,
            url: []const u8,
            out: []u8,
            value: []const u8 = "",
            fn run(call: *@This()) void {
                if (@atomicLoad(u32, &call.job.stop.value, .acquire) != 0) return;
                const options = call.job.owner_options;
                call.value = options.cookie_provider.?(options.cookie_context, call.url, call.out);
            }
        };
        var call: Call = .{ .job = self, .url = url, .out = out };
        self.invoke(Call, &call, Call.run);
        return call.value;
    }

    fn acceptCookie(raw: ?*anyopaque, url: []const u8, header: []const u8) void {
        const self: *Job = @ptrCast(@alignCast(raw.?));
        const Call = struct {
            job: *Job,
            url: []const u8,
            header: []const u8,
            fn run(call: *@This()) void {
                if (@atomicLoad(u32, &call.job.stop.value, .acquire) != 0) return;
                const options = call.job.owner_options;
                options.cookie_sink.?(options.cookie_context, call.url, call.header);
            }
        };
        var call: Call = .{ .job = self, .url = url, .header = header };
        self.invoke(Call, &call, Call.run);
    }

    fn authorizeTarget(raw: ?*anyopaque, url: []const u8) bool {
        const self: *Job = @ptrCast(@alignCast(raw.?));
        const Call = struct {
            job: *Job,
            url: []const u8,
            value: bool = false,
            fn run(call: *@This()) void {
                if (@atomicLoad(u32, &call.job.stop.value, .acquire) != 0) return;
                const options = call.job.owner_options;
                call.value = options.target_authorizer.?(options.target_authorization_context, call.url);
            }
        };
        var call: Call = .{ .job = self, .url = url };
        self.invoke(Call, &call, Call.run);
        return call.value;
    }
};
