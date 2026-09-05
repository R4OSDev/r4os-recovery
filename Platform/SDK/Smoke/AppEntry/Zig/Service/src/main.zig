const r4os = @import("r4os");

pub fn r4_app_main(app: *r4os.App) i32 {
    if (app.profile != .service or !app.hasGroup(.r4sys) or app.desktop() != null) return 73;
    app.system().println("APPZSVC app entry: OK");
    return 0;
}
