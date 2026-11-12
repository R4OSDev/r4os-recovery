const std = @import("std");
const s = @import("swapchain_state.zig");
const t = std.testing;
const output: s.Output = .{ .generation = 1, .width = 1920, .height = 1080, .policies = 7, .visibility = true };
pub fn check() !void {
    var chain: s.Chain = .{};
    try t.expectError(error.Unsupported, chain.configure(.{ .require_vsync = true }, output));
    try chain.configure(.{}, output);
    const first = try chain.acquire(10, 9);
    const second = try chain.acquire(11, 0);
    try t.expectError(error.Busy, chain.acquire(12, 0));
    // FIFO is Present order, independently of Acquire order. Waiting for
    // the oldest render cannot let a later ready frame pass it.
    try chain.present(second, 12, .composition, true);
    try chain.present(first, 13, .composition, false);
    try t.expect(chain.candidate() == null);
    try chain.rendered(second, 15, true);
    try t.expectEqualDeep(second, chain.candidate().?);
    try chain.submitted(second, 16);
    try chain.retired(second, 20, true);
    try t.expectEqual(@as(u64, 0), (try chain.frame(second)).times.visible_ns);
    try t.expectError(error.Busy, chain.release(second));
    try t.expect(chain.candidate() == null);
    try chain.visible(second, 22);
    try chain.release(second);
    try t.expectEqualDeep(first, chain.candidate().?);
    try chain.submitted(first, 23);
    chain.change(.lost);
    try t.expectError(error.Busy, chain.release(first));
    try chain.retired(first, 24, false);
    try t.expectEqual(s.Result.lost, (try chain.frame(first)).result);
    try chain.release(first);
    try t.expectError(error.Lost, chain.acquire(25, 0));
    try chain.configure(.{ .count = 3, .policy = .latest_ready }, output);
    try t.expectError(error.Stale, chain.release(first));
    const old = try chain.acquire(30, 0);
    const middle = try chain.acquire(31, 0);
    const newest = try chain.acquire(32, 0);
    try chain.present(old, 33, .copy, true);
    try chain.present(middle, 34, .copy, false);
    try chain.present(newest, 35, .copy, false);
    try t.expectEqualDeep(newest, chain.candidate().?);
    // Rejected consumer admission does not mutate older frames.
    try t.expectEqual(s.Result.pending, (try chain.frame(middle)).result);
    try chain.submitted(newest, 36);
    try t.expectEqual(s.Result.discarded, (try chain.frame(old)).result);
    try t.expectError(error.Busy, chain.release(old));
    try chain.rendered(old, 37, true);
    try chain.release(old);
    try chain.release(middle);
    // Hide cancels logical publication while preserving the in-flight reader.
    var hidden = output; hidden.occluded = true;
    try chain.refresh(hidden);
    try t.expectError(error.Occluded, chain.acquire(38, 0));
    try t.expectError(error.Busy, chain.release(newest));
    try chain.retired(newest, 39, true);
    try chain.release(newest);
    try chain.refresh(output);
    var direct = output; direct.direct = true; direct.synchronized = true;
    direct.phase_ns = 100; direct.interval_ns = 16;
    try chain.configure(.{ .require_vsync = true }, direct);
    const front = try chain.acquire(101, 100);
    try chain.present(front, 102, .direct, true);
    try chain.rendered(front, 105, true);
    try chain.submitted(front, 106);
    try t.expectEqual(@as(u64, 116), (try chain.frame(front)).times.selected_ns);
    try t.expectEqual(@as(u64, 0), (try chain.frame(front)).times.visible_ns);
    try chain.visible(front, 118);
    try t.expectError(error.Busy, chain.release(front));
    const back = try chain.acquire(119, 0);
    try chain.present(back, 120, .composition, false);
    try chain.submitted(back, 121);
    try chain.retired(back, 122, true);
    try chain.visible(back, 133);
    // Composition is visible before the old direct buffer is released.
    try t.expectError(error.Busy, chain.release(front));
    try chain.retired(front, 134, true);
    try chain.release(front);
    try chain.release(back);
    var resized = direct; resized.generation += 1; resized.width = 1280;
    try chain.refresh(resized);
    try t.expectError(error.Suboptimal, chain.acquire(140, 0));
    try chain.configure(.{}, resized);
    const final = try chain.acquire(141, 0);
    try chain.release(final); // Abandoned acquisition never reached a consumer.
    // A software copy has no observed visible time, even with FIFO ordering.
    var software = output; software.visibility = false;
    try chain.configure(.{}, software);
    const cpu = try chain.acquire(150, 0);
    try chain.present(cpu, 151, .copy, false);
    try chain.submitted(cpu, 152);
    try chain.retired(cpu, 155, true);
    try t.expectEqual(s.Result.copied, (try chain.frame(cpu)).result);
    try t.expectEqual(@as(u64, 0), (try chain.frame(cpu)).times.visible_ns);
    try chain.release(cpu);
    // A confirmed adaptive transition removes the old fixed-period render
    // deadline, without inventing scanout visibility or releasing images.
    try chain.configure(.{ .require_vsync = true }, direct);
    const adaptive_front = try chain.acquire(201, 0);
    try chain.present(adaptive_front, 202, .composition, false);
    try chain.submitted(adaptive_front, 203);
    chain.next_start_ns = 300;
    var adaptive = direct; adaptive.adaptive = true; adaptive.phase_ns = 0; adaptive.interval_ns = 0;
    try chain.refresh(adaptive);
    const adaptive_back = try chain.acquire(204, 0);
    try t.expect((try chain.frame(adaptive_front)).consumer_held and (try chain.frame(adaptive_front)).times.visible_ns == 0);
    try chain.present(adaptive_back, 205, .composition, false);
    try t.expect(chain.candidate() == null);
    try chain.retired(adaptive_front, 206, true);
    try chain.visible(adaptive_front, 207);
    try chain.release(adaptive_front);
    try chain.submitted(adaptive_back, 208);
    try t.expect((try chain.frame(adaptive_back)).times.selected_ns == 0 and chain.next_start_ns == 0);
    try chain.retired(adaptive_back, 209, true);
    try chain.visible(adaptive_back, 210);
    try chain.release(adaptive_back);
    try chain.refresh(direct);
    try t.expect(!chain.output.adaptive and chain.output.interval_ns == 16);
}
