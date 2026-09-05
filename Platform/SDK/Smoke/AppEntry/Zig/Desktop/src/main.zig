const r4os = @import("r4os");

pub fn r4_app_main(app: *r4os.App) i32 {
    if (app.profile != .desktop or app.desktop() == null or app.drawing() == null) return 72;
    app.system().println("APPZDESK app entry: OK");
    return 0;
}
