//! A hosted, event-driven window using the ordinary transactional R4DRAW path.
const r = @import("r4os");

pub fn r4_app_main(app: *r.App2) i32 {
    var timers: [0]r.Timer = .{};
    var window = r.Window.init(app.system(), app.desktop() orelse return -1, app.drawing() orelse return -1, &timers) orelse return -1;
    _ = window.setTitle("Canvas example");
    _ = window.setMinimumSize(400, 220);
    var dirty = true;
    while (true) {
        if (dirty) {
            var paint = switch (window.beginPaint()) {
                .paint => |value| value,
                .failure => return -1,
            };
            defer paint.discard();
            var commands: [12]r.abi.GuiFrameCommand = undefined;
            var resources: [2048]u8 = undefined;
            var builder: r.app_gui.FrameCanvas = undefined;
            const canvas = paint.bufferedCanvas(&builder, &commands, &resources);
            var text: [64]u8 = undefined;
            // Width and height are the complete current client dimensions.
            if (canvas.clear(0x19151e) < 0 or
                canvas.label(.{ .rect = .{ .x = 20, .y = 16, .w = canvas.w - 40, .h = 20 }, .text = "Native linear / radial gradients", .fg = 0xffffff, .bg = 0x19151e }, &text) < 0) return -1;
            const stops = [_]r.gui_shapes.GradientStop{
                .{ .position = 0, .argb = 0xff261639 }, .{ .position = 0.55, .argb = 0xff7944c4 }, .{ .position = 1, .argb = 0xffd199ed },
            };
            const width: u32 = @intCast(@max(9, @divTrunc(canvas.w - 52, 2)));
            const height: u32 = @intCast(@max(9, canvas.h - 68));
            for ([_]r.gui_shapes.GradientKind{ .linear, .radial }, 0..) |kind, index| {
                var payload: [256]u8 = undefined;
                const shape = r.gui_shapes.RoundedRect{ .x = 4, .y = 4, .w = @floatFromInt(width - 8), .h = @floatFromInt(height - 8), .radii = .{ .top_left_x = 14, .top_left_y = 14, .top_right_x = 14, .top_right_y = 14, .bottom_left_x = 14, .bottom_left_y = 14, .bottom_right_x = 14, .bottom_right_y = 14 }, .borders = .{ .top = 1, .left = 1, .right = 1, .bottom = 1 }, .border_argb = 0xffba8ae2, .shadow = .{ .argb = 0x80000000, .offset_y = 2, .blur = 3 } };
                const x: i32 = 20 + @as(i32, @intCast(index)) * (@as(i32, @intCast(width)) + 12);
                const shadow = r.gui_shapes.roundedRect(&payload, shape) catch return -2;
                const shadow_command = r.gui_shapes.command(r.abi.gui_frame_command_kind_shadow, x, 48, width, height, 0, shadow.len) catch return -2;
                if (canvas.frameCommand(shadow_command, shadow) < 0) return -2;
                const resource = r.gui_shapes.gradientRoundedRect(&payload, shape, .{ .kind = kind, .start = .{ .x = 0, .y = 0 }, .end = .{ .x = @floatFromInt(width), .y = @floatFromInt(height) }, .stops = &stops }) catch return -2;
                const command = r.gui_shapes.command(r.abi.gui_frame_command_kind_gradient_rounded_rect, x, 48, width, height, 0, resource.len) catch return -2;
                if (canvas.frameCommand(command, resource) < 0) return -2;
            }
            if (paint.present() < 0) return -1;
            dirty = false;
        }
        switch (window.waitMessage(.{ .kind = r.abi.timeout_kind_forever })) {
            .message => |message| switch (message) {
                .close => return 0,
                .resize => dirty = true,
                else => {},
            },
            .timed_out => {},
            .failure => return -1,
        }
    }
}
