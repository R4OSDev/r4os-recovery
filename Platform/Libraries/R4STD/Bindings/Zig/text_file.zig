const r4os = @import("r4os");
const abi = r4os.abi;
const gui = r4os.gui;

pub const LoadResult = struct {
    ok: bool = false,
    truncated: bool = false,
    bytes_read: u32 = 0,
    error_code: i32 = 0,
};

pub const SaveResult = struct {
    ok: bool = false,
    bytes_written: i32 = 0,
};

pub fn loadIntoTextArea(sys: anytype, path: [*:0]const u8, editor: anytype, view: gui.TextAreaView) LoadResult {
    editor.clear();

    var read_buffer: [512]u8 = .{0} ** 512;
    var offset: u32 = 0;
    while (editor.available() > 0) {
        const want = @min(read_buffer.len, editor.available());
        const read = sys.fileReadAt(path, offset, read_buffer[0..want]);
        if (read < 0) {
            editor.clear();
            return .{ .error_code = read };
        }
        if (read == 0) break;

        const len: usize = @intCast(read);
        _ = editor.insertSlice(read_buffer[0..len], view);
        offset += @intCast(len);
        if (len < want) break;
    }

    var truncated = false;
    if (sys.fileInfo(path)) |info| {
        truncated = info.size > offset;
    }

    editor.focused = true;
    editor.ensureCursorVisible(view);
    return .{
        .ok = true,
        .truncated = truncated,
        .bytes_read = offset,
        .error_code = abi.service_api_result_ok,
    };
}

pub fn saveFromTextArea(sys: anytype, path: [*:0]const u8, editor: anytype) SaveResult {
    const value = editor.value();
    const written = sys.fileWrite(path, value);
    return .{
        .ok = written >= 0 and @as(usize, @intCast(written)) == value.len,
        .bytes_written = written,
    };
}
