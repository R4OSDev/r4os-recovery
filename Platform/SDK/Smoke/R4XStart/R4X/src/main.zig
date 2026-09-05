const r4os = @import("r4os");

comptime {
    asm (r4os.r4x.entryAsm("sdk_smoke_main"));
}

export fn sdk_smoke_main(raw: *const r4os.abi.R4XStartContext) callconv(.c) i32 {
    const ctx = r4os.r4x.Context.init(raw);
    if (!ctx.valid()) return 51;

    const sys = ctx.r4sys() orelse return 52;
    sys.println("SDK R4XStart smoke");
    sys.println("R4XStart context: OK");
    sys.print("ARGS: ");
    const args = ctx.args();
    if (args.len == 0) {
        sys.println("<none>");
    } else {
        sys.println(args);
    }
    sys.println("R4SYS/R4L import: OK");
    return 0;
}
