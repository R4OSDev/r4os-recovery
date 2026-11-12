//! A cooperative CPU-rendered output loop for a compositor, not a GUI window.
//! The caller owns the device, two image resources and a fill pipeline.
const std = @import("std");
const gfx = @import("r4gfx");

pub const Output = struct {
    chain: gfx.R4GfxSwapchain,
    pending: ?gfx.R4GfxSwapchainFrame = null,
    last_receipt: ?gfx.R4GfxSwapchainFrameStatus = null,

    pub fn open(api: *const gfx.DeviceV1Client, device: *const gfx.R4GfxDevice,
        head: u32, generation: u64, images: *const [2]gfx.R4GfxResource, out: *Output) i32
    {
        var chain: gfx.R4GfxSwapchain = undefined;
        const result = api.swapchain_open(device, &.{ .version = 1,
            .size = @sizeOf(gfx.R4GfxSwapchainDesc), .head_id = head,
            .display_generation = generation, .policy = gfx.present_policy_fifo,
            .flags = 0, .count = 2, .images = @intFromPtr(images) }, &chain);
        if (result == gfx.status_ok) out.* = .{ .chain = chain };
        return result;
    }

    /// Call only when damage exists. A busy receipt is retried from the event
    /// loop, never spun on. No shader creation or allocation occurs here.
    pub fn frame(self: *Output, api: *const gfx.DeviceV1Client, device: *const gfx.R4GfxDevice,
        fill: gfx.R4GfxResource, width: u32, height: u32, deadline_ns: u64) i32
    {
        const retired = self.retire(api, device);
        if (retired != gfx.status_ok) return retired;
        var acquired: gfx.R4GfxSwapchainFrame = undefined;
        const rc = api.swapchain_acquire(device, &self.chain, 0, &acquired);
        if (rc != gfx.status_ok) return rc;
        self.pending = acquired;
        var draw = std.mem.zeroes(gfx.R4GfxDraw);
        draw.target = acquired.image;
        draw.pipeline = fill;
        draw.color = 0x284060;
        draw.target_rect = .{ .x = 0, .y = 0, .width = width, .height = height };
        var stats: gfx.R4GfxRenderStats = undefined;
        const rendered = api.render(device, &.{ .commands = @intFromPtr(&draw), .command_count = 1,
            .flags = 0, .pixel_budget = @as(u64, width) * height }, &stats);
        if (rendered != gfx.status_ok) {
            _ = self.retire(api, device);
            return rendered;
        }
        // render() is synchronous CPU work. Native asynchronous work would
        // pass its real render_job; zero must never hide unfinished GPU work.
        const submitted = api.swapchain_present(device, &self.chain, &.{ .version = 1,
            .size = @sizeOf(gfx.R4GfxSwapchainPresent), .frame = acquired,
            .render_job = std.mem.zeroes(gfx.R4GfxJob), .deadline_ns = deadline_ns,
            .intent = 0, .blockers = 0 });
        if (submitted != gfx.status_ok) _ = self.retire(api, device);
        return submitted;
    }

    pub fn retire(self: *Output, api: *const gfx.DeviceV1Client, device: *const gfx.R4GfxDevice) i32 {
        const pending = self.pending orelse return gfx.status_ok;
        var status: gfx.R4GfxSwapchainStatus = undefined;
        const polled = api.swapchain_poll(device, &self.chain, &status);
        if (polled != gfx.status_ok) return polled;
        self.last_receipt = switch (pending.slot) {
            1 => status.frame0, 2 => status.frame1, 3 => status.frame2,
            else => return gfx.status_invalid,
        };
        const released = api.swapchain_release(device, &self.chain, &pending);
        if (released == gfx.status_ok) self.pending = null;
        return released;
    }

    /// On busy/lost, retain this owner, images and device storage for recovery.
    /// Only successful close permits releasing the caller's image references.
    pub fn close(self: *Output, api: *const gfx.DeviceV1Client, device: *const gfx.R4GfxDevice) i32 {
        const retired = self.retire(api, device);
        if (retired != gfx.status_ok) return retired;
        return api.swapchain_close(device, &self.chain);
    }
};
