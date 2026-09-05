#include <r4os/r4os.h>
#include <string.h>

static R4XStartImport make_import(uint32_t group, const void *table) {
    R4XStartImport item = {0}; item.group_id = group; item.flags = R4XSTART_IMPORT_FLAG_GROUP_INTERFACE; item.table = (uint64_t)(uintptr_t)table; return item;
}
static R4XStartContext make_context(R4XStartImport *imports, uint32_t count, const char *args) {
    R4XStartContext ctx = {0};
    ctx.magic = R4XSTART_MAGIC; ctx.abi_major = R4XSTART_ABI_MAJOR; ctx.abi_minor = R4XSTART_ABI_MINOR; ctx.size = R4XSTART_CONTEXT_SIZE;
    ctx.flags = R4XSTART_FLAG_IMPORTS_VALID; ctx.imports = (uint64_t)(uintptr_t)imports; ctx.import_count = count;
    ctx.args = (uint64_t)(uintptr_t)args; ctx.args_len = args != 0 ? strlen(args) : 0u; return ctx;
}

int main(void) {
    R4XStartR4Sys first_sys = {R4XSTART_R4SYS_MAGIC, R4XSTART_R4SYS_VERSION, R4XSTART_R4SYS_SIZE, 0};
    R4XStartR4Sys second_sys = {R4XSTART_R4SYS_MAGIC, R4XSTART_R4SYS_VERSION, R4XSTART_R4SYS_SIZE, 0};
    R4XStartR4Desk desk = {R4XSTART_R4DESK_MAGIC, R4XSTART_R4DESK_VERSION, R4XSTART_R4DESK_SIZE, 0};
    R4XStartR4Draw draw = {R4XSTART_R4DRAW_MAGIC, R4XSTART_R4DRAW_VERSION, R4XSTART_R4DRAW_SIZE, 0};
    R4XStartImport console_imports[] = {make_import(R4L_GROUP_R4SYS, &first_sys)};
    R4XStartImport desktop_imports[] = {make_import(R4L_GROUP_R4SYS, &second_sys), make_import(R4L_GROUP_R4DESK, &desk), make_import(R4L_GROUP_R4DRAW, &draw)};
    R4XStartContext console_ctx = make_context(console_imports, 1u, "console");
    R4XStartContext desktop_ctx = make_context(desktop_imports, 3u, "desktop");
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
    return 0;
}
