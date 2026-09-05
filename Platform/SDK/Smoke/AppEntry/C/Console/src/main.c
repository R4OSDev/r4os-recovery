#include <r4os/r4os.h>

static void parity_u64(R4Sys *sys, uint64_t value) {
    char buffer[20];
    uint32_t count = 0;
    do { buffer[count++] = (char)('0' + (value % 10u)); value /= 10u; } while (value != 0u);
    while (count != 0u) r4sys_putc(sys, (uint8_t)buffer[--count]);
}

static void parity_i32(R4Sys *sys, int32_t value) {
    if (value < 0) {
        r4sys_putc(sys, '-');
        parity_u64(sys, (uint64_t)(-(int64_t)value));
    } else {
        parity_u64(sys, (uint32_t)value);
    }
}

static void parity_text(R4Sys *sys, const char *text) {
    r4sys_write(sys, (const uint8_t *)text, r4os_cstr_len(text));
}

int32_t r4_app_main(R4App *app) {
    if (app->profile != R4_APP_PROFILE_CONSOLE || !r4_app_has_group(app, R4L_GROUP_R4SYS) || r4_app_has_group(app, R4L_GROUP_R4DESK)) return 81;
    R4Files files = r4_app_files(app);
    R4FilePath missing_path, payload_path;
    static const char missing_text[] = "C:\\__R4OS_05835_PARITY_MISSING__.BIN";
    static const char payload_text[] = "C:\\R4OS\\CONFIG\\VERSION.R4S";
    if (r4_file_path((const uint8_t *)missing_text, sizeof(missing_text) - 1u, &missing_path) != R4_PATH_OK) return 82;
    if (r4_file_path((const uint8_t *)payload_text, sizeof(payload_text) - 1u, &payload_path) != R4_PATH_OK) return 83;

    uint8_t missing_buffer[8];
    uint8_t buffer[128];
    for (uint32_t index = 0; index < sizeof(missing_buffer); ++index) missing_buffer[index] = 0xA5u;
    for (uint32_t index = 0; index < sizeof(buffer); ++index) buffer[index] = 0xA5u;
    R4Transfer missing = r4_files_read(&files, &missing_path, missing_buffer, sizeof(missing_buffer));
    R4Transfer read = r4_files_read(&files, &payload_path, buffer, 64u);
    if (read.state != R4_TRANSFER_BYTES || read.bytes == 0u) return 84;
    uint64_t payload = UINT64_C(14695981039346656037);
    for (uint32_t index = 0; index < read.bytes; ++index) { payload ^= buffer[index]; payload *= UINT64_C(1099511628211); }

    R4Resources resources = r4_app_resources(app);
    R4VmRegion region;
    if (r4_resources_reserve_vm(&resources, 4096u, 4096u, R4OS_VM_REGION_FLAGS_DEFAULT, &region) != R4OS_VM_OK) return 85;
    uint32_t handle_before = r4_vm_region_valid(&region) ? 1u : 0u;
    int32_t close_raw = r4_vm_region_release(&region);
    uint32_t handle_after = r4_vm_region_valid(&region) ? 1u : 0u;

    parity_text(&app->system, "APPPARITY lang=c domain=");
    parity_u64(&app->system, R4_ERROR_DOMAIN_FILESYSTEM);
    parity_text(&app->system, " raw=");
    parity_i32(&app->system, missing.raw_code);
    parity_text(&app->system, " payload=");
    parity_u64(&app->system, payload);
    parity_text(&app->system, " bytes=");
    parity_u64(&app->system, read.bytes);
    parity_text(&app->system, " mutated=");
    parity_u64(&app->system, buffer[0] != 0xA5u ? 1u : 0u);
    parity_text(&app->system, " tail=");
    parity_u64(&app->system, buffer[64] == 0xA5u ? 1u : 0u);
    parity_text(&app->system, " handle_before=");
    parity_u64(&app->system, handle_before);
    parity_text(&app->system, " close=");
    parity_i32(&app->system, close_raw);
    parity_text(&app->system, " handle_after=");
    parity_u64(&app->system, handle_after);
    parity_text(&app->system, "\r\n");
    if (buffer[64] != 0xA5u || handle_before != 1u || close_raw != 0 || handle_after != 0u) return 86;
    return r4sys_write_line(&app->system, "APPCCON app entry: OK");
}
