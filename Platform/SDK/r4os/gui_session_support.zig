//! Stable SDK-owned contexts. Allocation and lifetime belong to the caller.
const a = @import("r4os_contract").abi;
const program = @import("program.zig");
const sys = @import("r4sys.zig");
const desk = @import("r4desk.zig");
const draw = @import("r4draw.zig");
const app = @import("app_gui.zig");
const gui = @import("gui.zig");
const mode = @import("window_mode.zig");
pub const Session = struct {
    bundle: program.Bundle,
    context2: ?@import("platform2.zig").Context = null,
    memory2: @import("allocator_source.zig").Memory = undefined,
    instance_id: u32,
    program: program.Context,
    sys: sys.Context,
    desk: desk.Context,
    draw: draw.Context,
    window: ?app.Window = null,
    paint: ?app.PaintContext = null,
    frame: gui.FrameCanvas = undefined,
    canvas: gui.Canvas = undefined,
    timers: []app.Timer,
    role: u32,
    owner: a.ProgramProcessHandle = .{},
    endpoint: u32 = 0,
    epoch: u64 = 0,
    claimed: bool = false,
    mode: ?mode.Client = null,
};
pub const EventKind = enum(u32) { close = 1, resize = 2, key = 3, mouse_down = 4, mouse_up = 5, mouse_move = 6, command = 7, clipboard = 8, timer = 9, unknown = 10, focus_gained = 11, focus_lost = 12, font_changed = 13, wheel = 14, relative = 15, pointer_capture = 16, input_reset = 17 };
pub const Event = extern struct {
    kind: u32 = 0,
    window_id: i32 = -1,
    width: i32 = 0,
    height: i32 = 0,
    x: i32 = 0,
    y: i32 = 0,
    codepoint: u32 = 0,
    modifiers: u32 = 0,
    buttons: u32 = 0,
    id: u32 = 0,
    revision: u32 = 0,
    reserved: u32 = 0,
    tick: u64 = 0,
    raw: a.GuiEvent = .{},
};
