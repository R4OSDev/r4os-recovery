#include <r4os/r4os.h>
#include <string.h>

static R4XStartImport make_import(uint32_t group, const void *table) {
    R4XStartImport item = {0}; item.group_id = group; item.min_version = item.resolved_version = 2; item.flags = R4XSTART_IMPORT_FLAG_GROUP_INTERFACE; item.table = (uint64_t)(uintptr_t)table; return item;
}
static R4XStartContext2 make_context(R4XStartImport *imports, uint32_t count, const char *args) {
    R4XStartContext2 ctx = {0};
    ctx.magic = R4OS2_START_MAGIC; ctx.abi_major = 2u; ctx.abi_minor = R4XSTART_ABI_MINOR; ctx.size = sizeof(R4XStartContext2);
    ctx.app_class = R4XSTART_APP_CLASS_CONSOLE; ctx.flags = R4XSTART_FLAG_IMPORTS_VALID; ctx.imports = (uint64_t)(uintptr_t)imports; ctx.import_count = count;
    ctx.args = (uint64_t)(uintptr_t)args; ctx.args_len = args != 0 ? strlen(args) : 0u; return ctx;
}

static int declared_start(void) {
    R4XStartR4Sys2 sys = {R4OS2_R4SYS_MAGIC, R4OS2_R4SYS_VERSION, sizeof(R4XStartR4Sys2), 0};
    R4XStartR4Desk2 desk = {R4OS2_R4DESK_MAGIC, R4OS2_R4DESK_VERSION, sizeof(R4XStartR4Desk2), 0};
    R4XStartR4Draw2 draw = {R4OS2_R4DRAW_MAGIC, R4OS2_R4DRAW_VERSION, sizeof(R4XStartR4Draw2), 0};
    R4XStartR4Net2 net = {R4OS2_R4NET_MAGIC, R4OS2_R4NET_VERSION, sizeof(R4XStartR4Net2), 0};
    R4XStartR4Audio2 audio = {R4OS2_R4AUDIO_MAGIC, R4OS2_R4AUDIO_VERSION, sizeof(R4XStartR4Audio2), 0};
    R4XStartR4Dev2 dev = {R4OS2_R4DEV_MAGIC, R4OS2_R4DEV_VERSION, sizeof(R4XStartR4Dev2), 0};
    R4XStartImport entries[8] = {0};
    R4StartupImport declared[8] = {0};
#define BIND(i, t, n, g) do { \
    entries[i] = make_import(g, &t); entries[i].min_version = entries[i].resolved_version = 2; \
    entries[i].module_name = (uintptr_t)n; entries[i].symbol_name = (uintptr_t)"Query2"; \
    declared[i] = (R4StartupImport){n,"Query2",2,0,g,t.magic,t.abi_version,t.size}; \
} while (0)
    BIND(0, sys, "R4SYS", R4L_GROUP_R4SYS);
    BIND(1, desk, "R4DESK", R4L_GROUP_R4DESK);
    BIND(2, draw, "R4DRAW", R4L_GROUP_R4DRAW);
    BIND(3, net, "R4NET", R4L_GROUP_R4NET);
    BIND(4, audio, "R4AUDIO", R4L_GROUP_R4AUDIO);
    BIND(5, dev, "R4DEV", R4L_GROUP_R4DEV);
#undef BIND
    for (uint32_t i = 6; i < 8; ++i) {
        entries[i].module_name = (uintptr_t)"LIB"; entries[i].symbol_name = (uintptr_t)"API_V1"; entries[i].min_version = 1;
        declared[i] = (R4StartupImport){"LIB","API_V1",1,i == 7,0,0,0,0};
    }
    entries[6].table = 1; entries[6].resolved_version = 1;
    R4StartupInfo info = {R4_APP_PROFILE_DESKTOP, R4XSTART_APP_CLASS_GUI, R4_APP_PROFILE_DESKTOP_REQUIRED_GROUPS, 8, declared};
    R4XStartContext2 ctx = make_context(entries, 8, "host"); ctx.app_class = R4XSTART_APP_CLASS_GUI; ctx.instance_id = 42;
    R4App app;
    /* Valid host with no application window, but all six API views. */
    if (!r4_status_succeeded(r4_app_init_declared(&ctx, &info, &app))) return 101;
    if (app.context != &ctx || app.network.table != &net || app.audio.table != &audio || app.devices.table != &dev) return 102;
    if (r4xstart_find_import_named(&ctx,"lib","api_v1") != &entries[6]) return 103;
    entries[7].resolved_version = 1;
    if (r4xstart_validate_declared(&ctx,&info) != -14) return 104;
    entries[7].resolved_version = 0; entries[6].table = 0;
    if (r4xstart_validate_declared(&ctx,&info) != -14) return 105;
    entries[6].table = 1; dev.size -= 8;
    if (r4xstart_validate_declared(&ctx,&info) != -15) return 106;
    dev.size += 8; entries[0].table += 1;
    if (r4xstart_validate_declared(&ctx,&info) != -14) return 107;
    entries[0].table -= 1; ctx.import_count -= 1;
    if (r4xstart_validate_declared(&ctx,&info) != -13) return 108;
    ctx.import_count += 1; ctx.args = UINT64_MAX;
    if (r4xstart_validate_declared(&ctx,&info) != -13) return 109;
    ctx.args = 0; ctx.args_len = 0; ctx.app_class = R4XSTART_APP_CLASS_CONSOLE;
    if (r4xstart_validate_declared(&ctx,&info) != -12) return 110;
    return 0;
}

int main(void) {
    R4XStartR4Sys2 first_sys = {R4OS2_R4SYS_MAGIC, R4OS2_R4SYS_VERSION, sizeof(R4XStartR4Sys2), 0};
    R4XStartR4Sys2 second_sys = {R4OS2_R4SYS_MAGIC, R4OS2_R4SYS_VERSION, sizeof(R4XStartR4Sys2), 0};
    R4XStartR4Desk2 desk = {R4OS2_R4DESK_MAGIC, R4OS2_R4DESK_VERSION, sizeof(R4XStartR4Desk2), 0};
    R4XStartR4Draw2 draw = {R4OS2_R4DRAW_MAGIC, R4OS2_R4DRAW_VERSION, sizeof(R4XStartR4Draw2), 0};
    R4XStartImport console_imports[] = {make_import(R4L_GROUP_R4SYS, &first_sys)};
    R4XStartImport desktop_imports[] = {make_import(R4L_GROUP_R4SYS, &second_sys), make_import(R4L_GROUP_R4DESK, &desk), make_import(R4L_GROUP_R4DRAW, &draw)};
    R4XStartContext2 console_ctx = make_context(console_imports, 1u, "console");
    R4XStartContext2 desktop_ctx = make_context(desktop_imports, 3u, "desktop"); desktop_ctx.app_class = R4XSTART_APP_CLASS_GUI;
    R4App console, desktop;
    if (!r4_status_succeeded(r4_app_init(&console_ctx, R4_APP_PROFILE_CONSOLE, &console))) return 1;
    if (!r4_app_has_group(&console, R4L_GROUP_R4SYS) || r4_app_has_group(&console, R4L_GROUP_R4DESK)) return 2;
    if (r4_status_succeeded(r4_app_init(&console_ctx, R4_APP_PROFILE_DESKTOP, &desktop))) return 3;
    if (!r4_status_succeeded(r4_app_init(&desktop_ctx, R4_APP_PROFILE_DESKTOP, &desktop))) return 4;
    if (!r4_app_has_group(&desktop, R4L_GROUP_R4DESK) || !r4_app_has_group(&desktop, R4L_GROUP_R4DRAW)) return 5;
    if (console.system.table == desktop.system.table) return 6;
    uint64_t len = 0; const uint8_t *args = r4_app_args(&console, &len);
    if (args == 0 || len != 7u || memcmp(args, "console", 7u) != 0) return 7;
    if (R4_APP_PROFILE_DESKTOP_REQUIRED_GROUPS != ((1u << R4L_GROUP_R4SYS) | (1u << R4L_GROUP_R4DESK) | (1u << R4L_GROUP_R4DRAW))) return 8;
    if (r4_status_succeeded(r4_app_init(&console_ctx, (R4AppProfile)99, &desktop))) return 9;
    return declared_start();
}
