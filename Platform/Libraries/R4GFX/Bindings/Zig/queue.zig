// Caller-owned producer helper. No hidden thread, allocation or frame queue;
// policy/capacity are explicit and the platform owns every accepted BO lease.
const r4os = @import("r4os");
const a = r4os.abi;
pub const Copy = struct {
    source: a.GfxBufferHandle,
    target: a.GfxBufferHandle,
    bytes: u64,
    deadline_ns: u64,
    source_offset: u64 = 0,
    target_offset: u64 = 0,
    frame_key: u64 = 0,
    dependencies: []const a.GfxFence = &.{},
};
pub const Queue = struct {
    context: r4os.gfx_queue.Context,
    handle: a.GfxQueueHandle = .{},

    pub fn open(self: *Queue, config: a.GfxQueueConfig) i32 {
        if (self.handle.timeline != 0) return a.gfx_queue_error_busy;
        return self.context.open(&config, &self.handle);
    }
    pub fn close(self: *Queue) i32 {
        if (self.handle.timeline == 0) return a.gfx_queue_ok;
        const rc = self.context.close(&self.handle);
        // Reset may have retired the last queue record after its final fence
        // was released. That exact nonwrapping handle then owns nothing.
        if (rc == a.gfx_queue_ok or rc == a.gfx_queue_error_stale) {
            self.handle = .{};
            return a.gfx_queue_ok;
        }
        return rc;
    }
    pub fn copy(self: *const Queue, request: Copy, output: *a.GfxFenceStatus) i32 {
        if (request.dependencies.len > a.gfx_queue_max_dependencies) return a.gfx_queue_error_invalid;
        var input = a.GfxSubmission{
            .operation = a.gfx_queue_operation_copy,
            .source = request.source,
            .target = request.target,
            .source_offset = request.source_offset,
            .target_offset = request.target_offset,
            .byte_length = request.bytes,
            .deadline_ns = request.deadline_ns,
            .frame_key = request.frame_key,
            .dependency_count = @intCast(request.dependencies.len),
        };
        @memcpy(input.dependencies[0..request.dependencies.len], request.dependencies);
        return self.context.submit(&self.handle, &input, output);
    }
    pub fn barrier(self: *const Queue, deadline_ns: u64, frame_key: u64, dependencies: []const a.GfxFence, output: *a.GfxFenceStatus) i32 {
        if (dependencies.len > a.gfx_queue_max_dependencies) return a.gfx_queue_error_invalid;
        var input = a.GfxSubmission{ .operation = a.gfx_queue_operation_barrier, .deadline_ns = deadline_ns, .frame_key = frame_key, .dependency_count = @intCast(dependencies.len) };
        @memcpy(input.dependencies[0..dependencies.len], dependencies);
        return self.context.submit(&self.handle, &input, output);
    }
};
