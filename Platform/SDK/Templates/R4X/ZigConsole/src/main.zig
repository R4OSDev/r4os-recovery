const r4os = @import("r4os");

pub fn r4_app_main(app: *r4os.App) i32 {
    const console = app.console() orelse return r4os.abi.err_no_fn;
    console.line("Hello from R4OS");
    return 0;
}
