const r4os = @import("r4os");
const app_source = @import("r4_app_source");
const options = @import("r4_app_options");

comptime {
    asm (r4os.lowlevel.r4x.entryAsm("R4XStart"));
}

export fn R4XStart(raw: *const r4os.lowlevel.abi.R4XStartContext) callconv(.c) i32 {
    const profile: r4os.AppProfile = @enumFromInt(options.profile);
    const initialized = r4os.App.init(raw, profile);
    var app = switch (initialized) {
        .value => |value| value,
        .failure => |failure| return failure.raw_code,
    };
    return app_source.r4_app_main(&app);
}
