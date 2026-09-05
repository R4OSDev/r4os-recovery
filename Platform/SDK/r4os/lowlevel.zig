// Explizite Low-Level-Oberflaeche fuer ABI-nahe Programme, Diagnosen und
// Migration. Normale Anwendungen beginnen mit r4os.App und verwenden keine
// R4XStartContext-, Gruppentabellen- oder Entry-Assembly-Details.
pub const abi = @import("r4os_contract").abi;
pub const program = @import("program.zig");
pub const r4x = @import("r4x.zig");
pub const r4xstart = @import("r4xstart.zig");
pub const r4sys = @import("r4sys.zig");
pub const r4desk = @import("r4desk.zig");
pub const r4draw = @import("r4draw.zig");
pub const r4net = @import("r4net.zig");
pub const r4audio = @import("r4audio.zig");
pub const r4dev = @import("r4dev.zig");
