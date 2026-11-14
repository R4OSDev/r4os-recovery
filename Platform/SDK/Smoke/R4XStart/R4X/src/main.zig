const r4os = @import("r4os");
pub export fn R4XStart2(raw: *const r4os.platform2.abi.R4XStartContext2) callconv(.c) i32 {
    const app = switch (r4os.App2.init(raw, .console)) { .value => |value| value, .failure => |failure| return failure.raw_code };
    const sys = app.system();
    sys.println("SDK R4XStart smoke");
    sys.println("R4XStart context: OK");
    sys.print("ARGS: ");
    const args = app.args();
    sys.println(if (args.len == 0) "<none>" else args);
    sys.println("R4SYS/R4L import: OK");
    return 0;
}
