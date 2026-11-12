const provider = @import("provider");
const r4os = @import("r4os");
const r4std = @import("r4std");

const module_name: [:0]const u8 = "R4STD";
const export_names = [_][:0]const u8{ "TEXT_V1", "SETTINGS_V1", "DATE_V1", "TIME_V1", "CONFIG_V1" };

var imports: [export_names.len]r4os.abi.R4XStartImport = undefined;
var context: r4os.abi.R4XStartContext = undefined;
var ready = false;

pub fn ensure() !void {
    if (ready) return;
    const tables = [_]usize{
        @intFromPtr(&provider.r4std_text_v1),
        @intFromPtr(&provider.r4std_settings_v1),
        @intFromPtr(&provider.r4std_date_v1),
        @intFromPtr(&provider.r4std_time_v1),
        @intFromPtr(&provider.r4std_config_v1),
    };
    for (&imports, export_names, tables) |*item, export_name, table| {
        item.* = .{
            .group_id = 0,
            .min_version = 1,
            .resolved_version = 1,
            .module_name = @intFromPtr(module_name.ptr),
            .symbol_name = @intFromPtr(export_name.ptr),
            .table = table,
        };
    }
    context = .{
        .flags = r4os.abi.r4xstart_flag_imports_valid,
        .imports = @intFromPtr(&imports),
        .import_count = imports.len,
    };
    r4std.resetForTesting();
    if (!r4std.init(&context)) return error.R4StdTestRuntimeUnavailable;
    ready = true;
}
