const std = @import("std");
const html = @import("html.zig");

pub const max_resources: usize = 64;
pub const no_request: u32 = 0;

pub const Error = error{
    ResourceLimit,
    InvalidResource,
    InvalidTransition,
    StaleGeneration,
};

pub const Kind = enum(u8) {
    script,
    stylesheet,
    image,
    subdocument,
    font,
};

pub const ScriptMode = enum(u8) {
    none,
    parser_blocking,
    defer_mode,
    async_mode,
    dynamic,
};

pub const State = enum(u8) {
    discovered,
    queued,
    fetching,
    ready,
    running,
    complete,
    failed,
    aborted,

    pub fn terminal(self: State) bool {
        return self == .complete or self == .failed or self == .aborted;
    }
};

pub const Entry = struct {
    id: u32 = 0,
    generation: u32 = 0,
    sequence: u16 = 0,
    node: u16 = html.none,
    kind: Kind = .script,
    script_mode: ScriptMode = .none,
    request_required: bool = false,
    state: State = .discovered,
    request_id: u32 = no_request,
};

pub const Scheduler = struct {
    generation: u32 = 0,
    entries: [max_resources]Entry = [_]Entry{.{}} ** max_resources,
    count: usize = 0,
    next_id: u32 = 1,
    parsing_complete: bool = false,
    ready_cursor: usize = 0,

    pub fn init(generation: u32) Scheduler {
        return .{ .generation = generation };
    }

    pub fn reset(self: *Scheduler, generation: u32) void {
        self.* = init(generation);
    }

    pub fn discover(self: *Scheduler, node: u16, kind: Kind, script_mode: ScriptMode, request_required: bool) Error!usize {
        if (self.count >= self.entries.len) return error.ResourceLimit;
        if (kind == .script and script_mode == .none) return error.InvalidResource;
        if (kind != .script and script_mode != .none) return error.InvalidResource;
        const index = self.count;
        self.entries[index] = .{
            .id = self.next_id,
            .generation = self.generation,
            .sequence = @intCast(index),
            .node = node,
            .kind = kind,
            .script_mode = script_mode,
            .request_required = request_required,
        };
        self.next_id +%= 1;
        if (self.next_id == 0) self.next_id = 1;
        self.count += 1;
        return index;
    }

    pub fn queue(self: *Scheduler, index: usize, request_id: u32) Error!void {
        const entry = try self.active(index);
        if (entry.state != .discovered or request_id == no_request) return error.InvalidTransition;
        entry.request_id = request_id;
        entry.state = .queued;
    }

    pub fn beginFetch(self: *Scheduler, request_id: u32, generation: u32) Error!usize {
        const index = try self.requestIndex(request_id, generation);
        if (self.entries[index].state != .queued) return error.InvalidTransition;
        self.entries[index].state = .fetching;
        return index;
    }

    pub fn completeFetch(self: *Scheduler, request_id: u32, generation: u32) Error!usize {
        const index = try self.requestIndex(request_id, generation);
        if (self.entries[index].state != .fetching) return error.InvalidTransition;
        self.entries[index].state = .ready;
        return index;
    }

    pub fn failFetch(self: *Scheduler, request_id: u32, generation: u32) Error!usize {
        const index = try self.requestIndex(request_id, generation);
        if (self.entries[index].state != .queued and self.entries[index].state != .fetching) return error.InvalidTransition;
        self.entries[index].state = .failed;
        return index;
    }

    pub fn markReady(self: *Scheduler, index: usize) Error!void {
        const entry = try self.active(index);
        if (entry.request_required or entry.request_id != no_request or entry.state != .discovered) return error.InvalidTransition;
        entry.state = .ready;
    }

    pub fn reject(self: *Scheduler, index: usize) Error!void {
        const entry = try self.active(index);
        if (entry.state.terminal() or entry.state == .running) return error.InvalidTransition;
        entry.state = .failed;
    }

    pub fn finishParsing(self: *Scheduler) void {
        self.parsing_complete = true;
    }

    pub fn takeRunnable(self: *Scheduler) ?usize {
        if (self.takeReadyMode(.async_mode)) |index| return index;
        if (self.takeReadyMode(.dynamic)) |index| return index;

        var parser_pending = false;
        for (self.entries[0..self.count], 0..) |entry, index| {
            if (entry.kind != .script or entry.script_mode != .parser_blocking or entry.state.terminal()) continue;
            parser_pending = true;
            if (entry.state == .ready) {
                self.entries[index].state = .running;
                return index;
            }
            break;
        }

        if (self.parsing_complete and !parser_pending) {
            for (self.entries[0..self.count], 0..) |entry, index| {
                if (entry.kind != .script or entry.script_mode != .defer_mode or entry.state.terminal()) continue;
                if (entry.state == .ready) {
                    self.entries[index].state = .running;
                    return index;
                }
                break;
            }
        }

        if (self.takeReadyResource()) |index| return index;
        return null;
    }

    pub fn finish(self: *Scheduler, index: usize, success: bool) Error!void {
        const entry = try self.active(index);
        if (entry.state != .running) return error.InvalidTransition;
        entry.state = if (success) .complete else .failed;
    }

    pub fn abort(self: *Scheduler, generation: u32) void {
        for (self.entries[0..self.count]) |*entry| {
            if (entry.generation == generation and !entry.state.terminal()) entry.state = .aborted;
        }
    }

    pub fn settled(self: *const Scheduler) bool {
        for (self.entries[0..self.count]) |entry| if (!entry.state.terminal()) return false;
        return true;
    }

    pub fn pendingRequestSlot(self: *const Scheduler) ?usize {
        for (self.entries[0..self.count], 0..) |entry, index| {
            if (entry.state == .discovered and entry.request_id == no_request and entry.request_required) return index;
        }
        return null;
    }

    pub fn containsNode(self: *const Scheduler, node: u16) bool {
        for (self.entries[0..self.count]) |entry| if (entry.node == node) return true;
        return false;
    }

    fn active(self: *Scheduler, index: usize) Error!*Entry {
        if (index >= self.count) return error.InvalidResource;
        if (self.entries[index].generation != self.generation) return error.StaleGeneration;
        return &self.entries[index];
    }

    fn requestIndex(self: *Scheduler, request_id: u32, generation: u32) Error!usize {
        if (generation != self.generation) return error.StaleGeneration;
        for (self.entries[0..self.count], 0..) |entry, index| {
            if (entry.request_id == request_id and entry.generation == generation) return index;
        }
        return error.InvalidResource;
    }

    fn takeReadyMode(self: *Scheduler, mode: ScriptMode) ?usize {
        for (self.entries[0..self.count], 0..) |entry, index| {
            if (entry.kind == .script and entry.script_mode == mode and entry.state == .ready) {
                self.entries[index].state = .running;
                return index;
            }
        }
        return null;
    }

    fn takeReadyResource(self: *Scheduler) ?usize {
        if (self.count == 0) return null;
        var checked: usize = 0;
        while (checked < self.count) : (checked += 1) {
            const index = (self.ready_cursor + checked) % self.count;
            const entry = self.entries[index];
            if (entry.kind == .script or entry.state != .ready) continue;
            if (entry.kind == .stylesheet) {
                var earlier: usize = 0;
                var blocked = false;
                while (earlier < index) : (earlier += 1) {
                    if (self.entries[earlier].kind == .stylesheet and !self.entries[earlier].state.terminal()) {
                        blocked = true;
                        break;
                    }
                }
                if (blocked) continue;
            }
            self.entries[index].state = .running;
            self.ready_cursor = (index + 1) % self.count;
            return index;
        }
        return null;
    }
};

pub fn classifyScript(document: *const html.Document, node: u16, dynamically_inserted: bool) ScriptMode {
    if (dynamically_inserted) return .dynamic;
    const script_type = document.attribute(node, "type") orelse "";
    const module = std.ascii.eqlIgnoreCase(script_type, "module");
    const external = document.attribute(node, "src") != null;
    if ((external or module) and document.attribute(node, "async") != null) return .async_mode;
    if (module) return .defer_mode;
    if (external and document.attribute(node, "defer") != null) return .defer_mode;
    return .parser_blocking;
}

pub fn resourceKind(document: *const html.Document, node: u16) ?Kind {
    if (node >= document.node_count or document.nodes[node].kind != .element) return null;
    const name = document.nodeName(node);
    if (std.ascii.eqlIgnoreCase(name, "script")) return .script;
    if (std.ascii.eqlIgnoreCase(name, "img") and hasPotentialImageSource(document, node)) return .image;
    if (std.ascii.eqlIgnoreCase(name, "iframe") and (document.attribute(node, "src") != null or document.attribute(node, "srcdoc") != null)) return .subdocument;
    if (std.ascii.eqlIgnoreCase(name, "link") and document.attribute(node, "href") != null) {
        const relation = document.attribute(node, "rel") orelse "";
        if (containsTokenIgnoreCase(relation, "stylesheet") and
            !containsTokenIgnoreCase(relation, "alternate") and
            document.attribute(node, "disabled") == null and
            stylesheetAppliesToScreen(document.attribute(node, "media") orelse "")) return .stylesheet;
    }
    return null;
}

pub fn hasPotentialImageSource(document: *const html.Document, node: u16) bool {
    if (node >= document.node_count or document.nodes[node].kind != .element or
        !std.ascii.eqlIgnoreCase(document.nodeName(node), "img")) return false;
    if (document.attribute(node, "src") != null or document.attribute(node, "srcset") != null) return true;
    const parent = document.nodes[node].parent;
    if (parent == html.none or parent >= document.node_count or
        !std.ascii.eqlIgnoreCase(document.nodeName(parent), "picture")) return false;
    var child = document.nodes[parent].first_child;
    while (child != html.none and child != node) {
        if (document.nodes[child].kind == .element and std.ascii.eqlIgnoreCase(document.nodeName(child), "source") and
            document.attribute(child, "srcset") != null) return true;
        child = document.nodes[child].next_sibling;
    }
    return false;
}

fn stylesheetAppliesToScreen(media: []const u8) bool {
    if (std.mem.trim(u8, media, " \t\r\n").len == 0) return true;
    var queries = std.mem.splitScalar(u8, media, ',');
    while (queries.next()) |raw_query| {
        var query = std.mem.trim(u8, raw_query, " \t\r\n");
        if (query.len == 0) continue;
        var negated = false;
        if (takeLeadingToken(&query, "not")) negated = true else _ = takeLeadingToken(&query, "only");
        if (query.len > 0 and query[0] == '(') {
            if (!negated) return true;
            continue;
        }
        const type_end = std.mem.indexOfAny(u8, query, " \t\r\n(") orelse query.len;
        const media_type = query[0..type_end];
        const applies = std.ascii.eqlIgnoreCase(media_type, "screen") or std.ascii.eqlIgnoreCase(media_type, "all");
        if (applies != negated) return true;
        if (std.ascii.eqlIgnoreCase(media_type, "print") and negated) return true;
    }
    return false;
}

fn takeLeadingToken(value: *[]const u8, wanted: []const u8) bool {
    const token_end = std.mem.indexOfAny(u8, value.*, " \t\r\n") orelse value.len;
    if (!std.ascii.eqlIgnoreCase(value.*[0..token_end], wanted)) return false;
    value.* = std.mem.trim(u8, value.*[token_end..], " \t\r\n");
    return true;
}

fn containsTokenIgnoreCase(value: []const u8, wanted: []const u8) bool {
    var start: usize = 0;
    while (start < value.len) {
        while (start < value.len and std.ascii.isWhitespace(value[start])) start += 1;
        var end = start;
        while (end < value.len and !std.ascii.isWhitespace(value[end])) end += 1;
        if (std.ascii.eqlIgnoreCase(value[start..end], wanted)) return true;
        start = end;
    }
    return false;
}

test "resource scheduler preserves parser defer async and fair non-script order" {
    var scheduler = Scheduler.init(7);
    const parser_one = try scheduler.discover(1, .script, .parser_blocking, false);
    const parser_two = try scheduler.discover(2, .script, .parser_blocking, true);
    const deferred = try scheduler.discover(3, .script, .defer_mode, true);
    const asynchronous = try scheduler.discover(4, .script, .async_mode, true);
    const image = try scheduler.discover(5, .image, .none, true);
    try scheduler.markReady(parser_one);
    try scheduler.queue(parser_two, 10);
    _ = try scheduler.beginFetch(10, 7);
    try scheduler.queue(deferred, 11);
    _ = try scheduler.beginFetch(11, 7);
    try scheduler.queue(asynchronous, 12);
    _ = try scheduler.beginFetch(12, 7);
    try scheduler.queue(image, 13);
    _ = try scheduler.beginFetch(13, 7);
    scheduler.finishParsing();

    _ = try scheduler.completeFetch(11, 7);
    _ = try scheduler.completeFetch(12, 7);
    _ = try scheduler.completeFetch(13, 7);
    try std.testing.expectEqual(asynchronous, scheduler.takeRunnable().?);
    try scheduler.finish(asynchronous, true);
    try std.testing.expectEqual(parser_one, scheduler.takeRunnable().?);
    try scheduler.finish(parser_one, true);
    try std.testing.expectEqual(image, scheduler.takeRunnable().?);
    try scheduler.finish(image, true);
    try std.testing.expect(scheduler.takeRunnable() == null);

    _ = try scheduler.completeFetch(10, 7);
    try std.testing.expectEqual(parser_two, scheduler.takeRunnable().?);
    try scheduler.finish(parser_two, true);
    try std.testing.expectEqual(deferred, scheduler.takeRunnable().?);
    try scheduler.finish(deferred, true);
    try std.testing.expect(scheduler.settled());
}

test "resource scheduler rejects stale completions and aborts one generation" {
    var scheduler = Scheduler.init(4);
    const script = try scheduler.discover(1, .script, .async_mode, true);
    try scheduler.queue(script, 20);
    _ = try scheduler.beginFetch(20, 4);
    try std.testing.expectError(error.StaleGeneration, scheduler.completeFetch(20, 3));
    scheduler.abort(4);
    try std.testing.expectEqual(State.aborted, scheduler.entries[script].state);
    try std.testing.expect(scheduler.settled());
    scheduler.reset(5);
    try std.testing.expectEqual(@as(usize, 0), scheduler.count);
    try std.testing.expectError(error.StaleGeneration, scheduler.completeFetch(20, 4));
}

test "resource discovery classifies document elements and script scheduling" {
    var document: html.Document = undefined;
    _ = try document.parse(
        "<script src=a.js></script><script defer src=b.js></script><script async src=c.js></script>" ++
            "<script type=module src=m.js></script><link rel='alternate stylesheet' href=a.css>" ++
            "<link rel=stylesheet media=print href=print.css><link rel=stylesheet media='screen and (min-width: 1px)' href=screen.css>" ++
            "<img src=a.bmp><img srcset='small.png 1x, large.png 2x'>" ++
            "<picture><source type='image/png' srcset='wide.png 2x'><img alt=responsive></picture>" ++
            "<iframe src=/frame></iframe>",
        .{ .content_type = "text/html" },
    );
    var modes: [4]ScriptMode = undefined;
    var mode_count: usize = 0;
    var styles: usize = 0;
    var images: usize = 0;
    var frames: usize = 0;
    for (0..document.node_count) |raw_index| {
        const index: u16 = @intCast(raw_index);
        const kind = resourceKind(&document, index) orelse continue;
        switch (kind) {
            .script => {
                modes[mode_count] = classifyScript(&document, index, false);
                mode_count += 1;
            },
            .stylesheet => styles += 1,
            .image => images += 1,
            .subdocument => frames += 1,
            .font => {},
        }
    }
    try std.testing.expectEqualSlices(ScriptMode, &.{ .parser_blocking, .defer_mode, .async_mode, .defer_mode }, modes[0..mode_count]);
    try std.testing.expectEqual(@as(usize, 1), styles);
    try std.testing.expectEqual(@as(usize, 3), images);
    try std.testing.expectEqual(@as(usize, 1), frames);
}
