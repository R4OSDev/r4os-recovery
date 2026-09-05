const r4os = @import("r4os");
const external = @import("external");

comptime {
    if (external.marker != 0x524D4150) @compileError("R4MF Zig-module mapping was not applied");
}

pub fn r4_app_main(app: *r4os.App) i32 {
    _ = app;
    return 0;
}
