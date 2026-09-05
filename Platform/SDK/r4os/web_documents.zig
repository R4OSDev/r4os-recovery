const std = @import("std");
const html = @import("html.zig");
const javascript = @import("javascript.zig");
const navigation = @import("web_navigation.zig");
const security = @import("web_security.zig");
const web_runtime = @import("web_runtime.zig");

/// Maximum number of concurrently active child-document owners in one
/// browser application. Together with the top-level document this yields at
/// most five independent WebRuntime generations. Child documents currently
/// have no visual layout and therefore create no web-font demands; a renderer
/// must add a generation-owned font registry before enabling those demands.
pub const max_subdocuments: usize = 4;
pub const max_document_owners: usize = max_subdocuments + 1;

pub const Error = html.Error || navigation.UrlError || web_runtime.Error || error{
    SubdocumentLimit,
    SubdocumentNotFound,
    StaleParent,
};

pub const Context = struct {
    parent_generation: u32,
    generation: u32,
    node: u16,
    url: navigation.Url,
    document: html.Document = undefined,
    runtime: web_runtime.WebRuntime = undefined,
    finalized: bool = false,
};

pub const Set = struct {
    allocator: std.mem.Allocator,
    program_allocator: web_runtime.ProgramAllocator,
    storage: *security.BrowserStorage,
    entries: [max_subdocuments]?*Context = [_]?*Context{null} ** max_subdocuments,
    next_generation: u32 = 0x4000_0000,
    pump_cursor: usize = 0,
    execution_stop: javascript.Stop = .{},
    execution_step_budget: usize = javascript.default_step_budget,
    environment: web_runtime.Environment = .{},
    monotonic_clock: web_runtime.MonotonicClock = .{},

    pub fn init(allocator: std.mem.Allocator, program_allocator: web_runtime.ProgramAllocator, storage: *security.BrowserStorage) Set {
        return .{
            .allocator = allocator,
            .program_allocator = program_allocator,
            .storage = storage,
        };
    }

    pub fn deinit(self: *Set) void {
        for (&self.entries) |*entry| self.destroySlot(entry);
    }

    pub fn setExecutionPolicy(self: *Set, stop: javascript.Stop, step_budget: usize) void {
        self.execution_stop = stop;
        self.execution_step_budget = step_budget;
    }

    pub fn setEnvironment(self: *Set, environment: web_runtime.Environment) void {
        self.environment = environment;
        for (self.entries) |entry| {
            const context = entry orelse continue;
            context.runtime.setEnvironment(environment);
        }
    }

    pub fn setMonotonicClock(self: *Set, clock: web_runtime.MonotonicClock) void {
        self.monotonic_clock = clock;
        for (self.entries) |entry| {
            const context = entry orelse continue;
            context.runtime.setMonotonicClock(clock);
        }
    }

    pub fn setViewport(self: *Set, width: u32, height: u32) void {
        self.environment.viewport_width = width;
        self.environment.viewport_height = height;
        for (self.entries) |entry| {
            const context = entry orelse continue;
            context.runtime.setViewport(width, height);
        }
    }

    pub fn create(
        self: *Set,
        parent_generation: u32,
        parent_origin: security.Origin,
        node: u16,
        url: navigation.Url,
        source: []const u8,
        content_type: []const u8,
        csp: []const u8,
        inherit_origin: bool,
        handler: web_runtime.ResourceHandler,
        frame_lookup: web_runtime.FrameLookup,
    ) Error!*Context {
        if (self.find(parent_generation, node)) |existing| self.destroy(existing);
        const slot = self.freeSlot() orelse return error.SubdocumentLimit;
        const context = self.allocator.create(Context) catch return error.ScriptAllocation;
        errdefer self.allocator.destroy(context);
        context.* = .{
            .parent_generation = parent_generation,
            .generation = self.allocateGeneration(),
            .node = node,
            .url = url,
        };
        _ = try context.document.parse(source, .{
            .content_type = content_type,
            .require_html_mime = true,
        });
        context.runtime.initialize(self.program_allocator);
        errdefer context.runtime.deinit();
        context.runtime.setEnvironment(self.environment);
        context.runtime.setMonotonicClock(self.monotonic_clock);
        context.runtime.setExecutionPolicy(self.execution_stop, self.execution_step_budget);
        context.runtime.setResourceHandler(handler);
        context.runtime.setFrameLookup(frame_lookup);
        try context.runtime.beginDocument(&context.document, self.storage, url.bytes(), csp, context.generation, 0);
        if (inherit_origin) {
            context.runtime.security_context.document_origin = parent_origin;
            context.runtime.security_context.secure_context = parent_origin.potentiallyTrustworthy();
        }
        self.entries[slot] = context;
        errdefer self.entries[slot] = null;
        _ = try context.runtime.executeDocumentScripts();
        return context;
    }

    pub fn find(self: *const Set, parent_generation: u32, node: u16) ?*Context {
        for (self.entries) |entry| {
            const context = entry orelse continue;
            if (context.parent_generation == parent_generation and context.node == node) return context;
        }
        return null;
    }

    pub fn findGeneration(self: *const Set, generation: u32) ?*Context {
        for (self.entries) |entry| {
            const context = entry orelse continue;
            if (context.generation == generation) return context;
        }
        return null;
    }

    pub fn sameOrigin(self: *const Set, parent_origin: *const security.Origin, parent_generation: u32, node: u16) bool {
        const context = self.find(parent_generation, node) orelse return false;
        return parent_origin.same(&context.runtime.security_context.document_origin);
    }

    pub fn retireParent(self: *Set, parent_generation: u32) void {
        for (&self.entries) |*entry| {
            const context = entry.* orelse continue;
            if (context.parent_generation != parent_generation) continue;
            self.retireParent(context.generation);
            self.destroySlot(entry);
        }
    }

    pub fn activeCount(self: *const Set) usize {
        var count: usize = 0;
        for (self.entries) |entry| if (entry != null) {
            count += 1;
        };
        return count;
    }

    pub fn pumpFair(self: *Set, now_ms: f64, maximum_jobs: usize) Error!usize {
        if (maximum_jobs == 0) return 0;
        var total: usize = 0;
        var visited: usize = 0;
        while (visited < self.entries.len and total < maximum_jobs) : (visited += 1) {
            const index = (self.pump_cursor + visited) % self.entries.len;
            const context = self.entries[index] orelse continue;
            const slice = @min(@as(usize, 8), maximum_jobs - total);
            total += try context.runtime.pump(now_ms, slice);
        }
        self.pump_cursor = (self.pump_cursor + 1) % self.entries.len;
        return total;
    }

    pub fn finalizeSettled(self: *Set, now_ms: f64) Error!usize {
        var finalized: usize = 0;
        for (self.entries) |entry| {
            const context = entry orelse continue;
            if (context.finalized or !context.runtime.resourcesSettled()) continue;
            context.runtime.markDomContentLoadedStart(now_ms);
            _ = try context.runtime.dispatchEvent(.document, "DOMContentLoaded", now_ms);
            context.runtime.markDomContentLoadedEnd(now_ms);
            context.runtime.markLoadStart(now_ms);
            _ = try context.runtime.dispatchEvent(.window, "load", now_ms);
            context.runtime.markLoadComplete(now_ms);
            context.finalized = true;
            finalized += 1;
        }
        return finalized;
    }

    fn freeSlot(self: *const Set) ?usize {
        for (self.entries, 0..) |entry, index| if (entry == null) return index;
        return null;
    }

    fn destroy(self: *Set, context: *Context) void {
        for (&self.entries) |*entry| {
            if (entry.* == context) {
                self.retireParent(context.generation);
                self.destroySlot(entry);
                return;
            }
        }
    }

    fn destroySlot(self: *Set, entry: *?*Context) void {
        const context = entry.* orelse return;
        context.runtime.abortDocument();
        context.runtime.deinit();
        self.allocator.destroy(context);
        entry.* = null;
    }

    fn allocateGeneration(self: *Set) u32 {
        const result = self.next_generation;
        self.next_generation +%= 1;
        if (self.next_generation < 0x4000_0000) self.next_generation = 0x4000_0000;
        return result;
    }
};

fn testingProgramCreate(_: *anyopaque) ?*javascript.Program {
    return std.testing.allocator.create(javascript.Program) catch null;
}

fn testingProgramDestroy(_: *anyopaque, program: *javascript.Program) void {
    std.testing.allocator.destroy(program);
}

fn testingMemoryAllocate(_: *anyopaque, length: usize, alignment: usize) ?[*]u8 {
    return std.testing.allocator.rawAlloc(length, .fromByteUnits(alignment), @returnAddress());
}

fn testingMemoryFree(_: *anyopaque, memory: [*]u8, length: usize, alignment: usize) void {
    std.testing.allocator.rawFree(memory[0..length], .fromByteUnits(alignment), @returnAddress());
}

test "subdocuments own separate realms generations and origin decisions" {
    var storage: security.BrowserStorage = undefined;
    storage.reset();
    var marker: u8 = 0;
    const program_allocator: web_runtime.ProgramAllocator = .{
        .context = &marker,
        .create = testingProgramCreate,
        .destroy = testingProgramDestroy,
        .allocate = testingMemoryAllocate,
        .free = testingMemoryFree,
    };
    var documents = Set.init(std.testing.allocator, program_allocator, &storage);
    defer documents.deinit();
    const parent_origin = try security.Origin.parse("https://parent.example/index", 1);
    const same = try documents.create(
        7,
        parent_origin,
        10,
        try navigation.parse("https://parent.example/frame"),
        "<body><script>var realmName='same'</script></body>",
        "text/html",
        "",
        false,
        .{},
        .{},
    );
    const cross = try documents.create(
        7,
        parent_origin,
        11,
        try navigation.parse("https://other.example/frame"),
        "<body><script>var realmName='cross'</script></body>",
        "text/html",
        "",
        false,
        .{},
        .{},
    );
    try std.testing.expect(same.generation != cross.generation);
    try std.testing.expectEqualStrings("same", same.runtime.runtime.valueString(same.runtime.runtime.global("realmName").?));
    try std.testing.expectEqualStrings("cross", cross.runtime.runtime.valueString(cross.runtime.runtime.global("realmName").?));
    try std.testing.expect(documents.sameOrigin(&parent_origin, 7, 10));
    try std.testing.expect(!documents.sameOrigin(&parent_origin, 7, 11));
    try std.testing.expectEqual(@as(usize, 2), try documents.finalizeSettled(4));
    try std.testing.expectEqual(@as(usize, 2), documents.activeCount());
    documents.retireParent(7);
    try std.testing.expectEqual(@as(usize, 0), documents.activeCount());
}

test "subdocuments srcdoc inherits its parent origin without sharing a realm" {
    var storage: security.BrowserStorage = undefined;
    storage.reset();
    var marker: u8 = 0;
    const program_allocator: web_runtime.ProgramAllocator = .{
        .context = &marker,
        .create = testingProgramCreate,
        .destroy = testingProgramDestroy,
        .allocate = testingMemoryAllocate,
        .free = testingMemoryFree,
    };
    var documents = Set.init(std.testing.allocator, program_allocator, &storage);
    defer documents.deinit();
    const parent_origin = try security.Origin.parse("https://parent.example/index", 1);
    const child = try documents.create(
        9,
        parent_origin,
        12,
        try navigation.parse("https://parent.example/index"),
        "<script>var inherited=true</script>",
        "text/html",
        "",
        true,
        .{},
        .{},
    );
    try std.testing.expect(parent_origin.same(&child.runtime.security_context.document_origin));
    try std.testing.expect(child.runtime.runtime.global("inherited") != null);
}

test "subdocument owner bound exposes four reusable child slots" {
    var documents = Set{
        .allocator = std.testing.allocator,
        .program_allocator = undefined,
        .storage = @ptrFromInt(0x1000),
    };
    for (&documents.entries, 0..) |*entry, index| {
        entry.* = @ptrFromInt(0x2000 + index * 0x1000);
    }
    try std.testing.expectEqual(@as(usize, 4), max_subdocuments);
    try std.testing.expectEqual(@as(usize, 5), max_document_owners);
    try std.testing.expectEqual(max_subdocuments, documents.activeCount());
    try std.testing.expect(documents.freeSlot() == null);

    documents.entries[2] = null;
    try std.testing.expectEqual(max_subdocuments - 1, documents.activeCount());
    try std.testing.expectEqual(@as(usize, 2), documents.freeSlot().?);

    const first_generation = documents.allocateGeneration();
    const second_generation = documents.allocateGeneration();
    try std.testing.expect(first_generation != second_generation);
    try std.testing.expect(first_generation >= 0x4000_0000 and second_generation >= 0x4000_0000);
}
