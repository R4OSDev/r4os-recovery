#include <assert.h>
#include <stdint.h>
#include <string.h>

#include <r4os/r4os.h>

static const uint8_t file_bytes[] = "hello";
static const uint8_t config_bytes[] =
    "\xEF\xBB\xBF" "R4S_FORMAT=1\r\nSCHEMA=TEST\r\nTITLE=Configured\r\nCOUNT=27\r\n";
static uint8_t written[64];
static uint32_t written_length;
static uint8_t stream_active;
static uint8_t stream_aborted;
static uint64_t registry_value;
static uint16_t registry_type;

static int32_t fake_write(const uint8_t *bytes, uint32_t length) {
    uint32_t count = length < sizeof(written) ? length : (uint32_t)sizeof(written);
    memcpy(written, bytes, count);
    written_length = count;
    return (int32_t)count;
}

static void fake_putc(uint8_t byte) {
    if (written_length < sizeof(written)) written[written_length++] = byte;
}

static int32_t fake_file_read(const uint8_t *path, uint8_t *out, uint32_t capacity) {
    const uint8_t *source = strstr((const char *)path, "CONFIG") != 0 ? config_bytes : file_bytes;
    uint32_t length = source == config_bytes ? (uint32_t)sizeof(config_bytes) - 1u : (uint32_t)sizeof(file_bytes) - 1u;
    uint32_t count = length < capacity ? length : capacity;
    memcpy(out, source, count);
    return (int32_t)count;
}

static int32_t fake_file_read_at(const uint8_t *path, uint32_t offset, uint8_t *out, uint32_t capacity) {
    (void)path;
    uint32_t length = (uint32_t)sizeof(file_bytes) - 1u;
    if (offset >= length) return 0;
    uint32_t count = length - offset < capacity ? length - offset : capacity;
    memcpy(out, file_bytes + offset, count);
    return (int32_t)count;
}

static int32_t fake_file_write(const uint8_t *path, const uint8_t *bytes, uint32_t length) {
    (void)path;
    return fake_write(bytes, length);
}

static int32_t fake_file_append(const uint8_t *path, const uint8_t *bytes, uint32_t length) {
    (void)path;
    uint32_t available = (uint32_t)sizeof(written) - written_length;
    uint32_t count = length < available ? length : available;
    memcpy(written + written_length, bytes, count);
    written_length += count;
    return (int32_t)count;
}

static int32_t fake_file_info(const uint8_t *path, R4FileInfo *info) {
    if (strstr((const char *)path, "MISSING") != 0) return 0;
    *info = (R4FileInfo){0}; info->exists = 1u; info->size = sizeof(file_bytes) - 1u; return 1;
}

static int32_t fake_file_delete(const uint8_t *path) {
    return strstr((const char *)path, "MISSING") != 0 ? 0 : 1;
}

static int32_t fake_file_rename(const uint8_t *source, const uint8_t *target) {
    (void)source;
    (void)target;
    return 1;
}

static int32_t fake_dir_create(const uint8_t *path) {
    (void)path;
    return 1;
}

static int32_t fake_dir_entry(const uint8_t *path, uint32_t index, uint8_t *out, uint32_t capacity) {
    (void)path;
    const char *entry = index == 2u ? "C:\\ONE.TXT" : "C:\\SUB";
    if (index > 3u) return -5;
    uint32_t length = (uint32_t)strlen(entry);
    if (length + 1u > capacity) return -4;
    memcpy(out, entry, length + 1u);
    return index == 3u ? 1 : 0;
}

static int32_t fake_stream_begin(const uint8_t *path, uint32_t flags) {
    (void)path;
    (void)flags;
    stream_active = 1u;
    stream_aborted = 0u;
    written_length = 0u;
    return R4OS_FILE_STREAM_RESULT_OK;
}

static int32_t fake_stream_write(const uint8_t *path, uint64_t offset, const uint8_t *bytes, uint32_t length, uint32_t flags) {
    (void)flags;
    if (!stream_active || offset != written_length) return R4OS_FILE_STREAM_ERROR_OFFSET_MISMATCH;
    return fake_file_append(path, bytes, length);
}

static int32_t fake_stream_finish(const uint8_t *path, uint64_t expected, uint32_t flags) {
    (void)path;
    (void)flags;
    if (!stream_active || expected != written_length) return R4OS_FILE_STREAM_ERROR_SIZE_MISMATCH;
    stream_active = 0u;
    return R4OS_FILE_STREAM_RESULT_OK;
}

static int32_t fake_stream_abort(const uint8_t *path) {
    (void)path;
    stream_active = 0u;
    stream_aborted = 1u;
    return R4OS_FILE_STREAM_RESULT_OK;
}

static int32_t fake_registry_get(const uint8_t *key, const uint8_t *name, R4RegistryValueInfo *info, uint8_t *out, uint32_t capacity) {
    (void)key;
    if (strcmp((const char *)name, "MISSING") == 0) return R4OS_REGISTRY_API_RESULT_VALUE_NOT_FOUND;
    *info = (R4RegistryValueInfo){0};
    if (strcmp((const char *)name, "TEXT") == 0) {
        if (capacity < 2u) return R4OS_REGISTRY_API_RESULT_BUFFER_TOO_SMALL;
        info->value_type = R4OS_REGISTRY_VALUE_TYPE_STRING; info->data_len = 2u; memcpy(out, "OK", 2u); return 2;
    }
    if (strcmp((const char *)name, "WIDE") == 0) {
        if (capacity < 8u) return R4OS_REGISTRY_API_RESULT_BUFFER_TOO_SMALL;
        info->value_type = R4OS_REGISTRY_VALUE_TYPE_U64; info->data_len = 8u; for (uint32_t i = 0; i < 8u; ++i) out[i] = (uint8_t)(0x0102030405060708ull >> (i * 8u)); return 8;
    }
    if (strcmp((const char *)name, "ENABLED") == 0) {
        if (capacity < 1u) return R4OS_REGISTRY_API_RESULT_BUFFER_TOO_SMALL;
        info->value_type = R4OS_REGISTRY_VALUE_TYPE_BOOL; info->data_len = 1u; out[0] = 1u; return 1;
    }
    if (capacity < 4u) return R4OS_REGISTRY_API_RESULT_BUFFER_TOO_SMALL;
    info->value_type = R4OS_REGISTRY_VALUE_TYPE_U32; info->data_len = 4u;
    out[0] = 0x78u; out[1] = 0x56u; out[2] = 0x34u; out[3] = 0x12u; return 4;
}

static int32_t fake_registry_set(const uint8_t *key, const uint8_t *name, uint16_t type, const uint8_t *bytes, uint32_t length) {
    (void)key;
    (void)name;
    registry_type = type; registry_value = 0u;
    if (length > 8u) return R4OS_REGISTRY_API_RESULT_INVALID;
    for (uint32_t i = 0; i < length; ++i) registry_value |= (uint64_t)bytes[i] << (i * 8u);
    return R4OS_REGISTRY_API_RESULT_OK;
}

static int32_t fake_registry_delete(const uint8_t *key, const uint8_t *name) {
    (void)key; return strcmp((const char *)name, "MISSING") == 0 ? R4OS_REGISTRY_API_RESULT_VALUE_NOT_FOUND : R4OS_REGISTRY_API_RESULT_OK;
}

static R4XStartR4Sys make_table(int full) {
    R4XStartR4Sys table = {0};
    table.write = (uint64_t)(uintptr_t)&fake_write;
    table.putc = (uint64_t)(uintptr_t)&fake_putc;
    if (!full) return table;
    table.file_read = (uint64_t)(uintptr_t)&fake_file_read;
    table.file_write = (uint64_t)(uintptr_t)&fake_file_write;
    table.file_read_at = (uint64_t)(uintptr_t)&fake_file_read_at;
    table.file_append = (uint64_t)(uintptr_t)&fake_file_append;
    table.file_info = (uint64_t)(uintptr_t)&fake_file_info;
    table.file_delete = (uint64_t)(uintptr_t)&fake_file_delete;
    table.file_rename = (uint64_t)(uintptr_t)&fake_file_rename;
    table.dir_create = (uint64_t)(uintptr_t)&fake_dir_create;
    table.dir_delete = (uint64_t)(uintptr_t)&fake_file_delete;
    table.dir_entry = (uint64_t)(uintptr_t)&fake_dir_entry;
    table.file_stream_begin = (uint64_t)(uintptr_t)&fake_stream_begin;
    table.file_stream_write = (uint64_t)(uintptr_t)&fake_stream_write;
    table.file_stream_finish = (uint64_t)(uintptr_t)&fake_stream_finish;
    table.file_stream_abort = (uint64_t)(uintptr_t)&fake_stream_abort;
    table.registry_get_value = (uint64_t)(uintptr_t)&fake_registry_get;
    table.registry_set_value = (uint64_t)(uintptr_t)&fake_registry_set;
    table.registry_delete_value = (uint64_t)(uintptr_t)&fake_registry_delete;
    return table;
}

int main(void) {
    R4XStartR4Sys table = make_table(1);
    R4App app = {0};
    app.system.table = &table;
    R4Files files = r4_app_files(&app);
    R4FilePath path = {0};
    assert(r4_file_path((const uint8_t *)"C:/TEMP/FILE.TXT", 16u, &path) == R4_PATH_OK);

    uint8_t buffer[128] = {0};
    R4Transfer transfer = r4_files_read(&files, &path, buffer, sizeof(buffer));
    assert(transfer.state == R4_TRANSFER_BYTES && transfer.bytes == 5u);
    assert(r4_files_write(&files, &path, (const uint8_t *)"A", 1u).state == R4_TRANSFER_BYTES);
    assert(r4_files_append(&files, &path, (const uint8_t *)"B", 1u).state == R4_TRANSFER_BYTES);
    assert(written_length == 2u && memcmp(written, "AB", 2u) == 0);
    assert(r4_files_info(&files, &path).state == R4_FILE_INFO_VALUE);

    R4FilePath directory = {0};
    assert(r4_file_path((const uint8_t *)"C:\\", 3u, &directory) == R4_PATH_OK);
    R4DirectoryIterator iterator = r4_files_iterate(files, &directory);
    assert(r4_directory_next(&iterator).state == R4_DIRECTORY_ENTRY);
    assert(r4_directory_next(&iterator).is_directory == 1u);
    assert(r4_directory_next(&iterator).state == R4_DIRECTORY_END);
    assert(r4_directory_next(&iterator).state == R4_DIRECTORY_END);

    R4StreamReader reader = r4_files_stream_reader(files, &path);
    assert(r4_stream_reader_read(&reader, buffer, 2u).bytes == 2u);
    assert(r4_stream_reader_read(&reader, buffer, sizeof(buffer)).bytes == 3u);
    assert(r4_stream_reader_read(&reader, buffer, sizeof(buffer)).state == R4_TRANSFER_END);

    R4StreamWriter writer = {0};
    assert(r4_files_stream_writer(files, &path, R4OS_FILE_STREAM_OPEN_REPLACE, &writer).state == R4_OPERATION_OK);
    assert(r4_stream_writer_write(&writer, (const uint8_t *)"stream", 6u).state == R4_OPERATION_OK);
    assert(r4_stream_writer_finish(&writer).state == R4_OPERATION_OK);
    assert(r4_files_stream_writer(files, &path, R4OS_FILE_STREAM_OPEN_REPLACE, &writer).state == R4_OPERATION_OK);
    assert(r4_stream_writer_abort(&writer).state == R4_OPERATION_OK && stream_aborted);

    R4Registry registry = r4_app_registry(&app);
    R4RegistryPath key = {0};
    assert(r4_registry_path((const uint8_t *)"HKCU/Software/Test", 18u, &key) == R4_PATH_OK);
    R4RegistryRead value = r4_registry_get(&registry, &key, "COUNT", buffer, sizeof(buffer));
    uint32_t decoded = 0u;
    assert(value.state == R4_REGISTRY_VALUE && r4_registry_value_u32(&value.value, &decoded));
    assert(decoded == 0x12345678u);
    assert(r4_registry_set_u32(&registry, &key, "COUNT", 99u).state == R4_OPERATION_OK);
    assert(registry_type == R4OS_REGISTRY_VALUE_TYPE_U32 && registry_value == 99u);
    value = r4_registry_get(&registry, &key, "WIDE", buffer, sizeof(buffer));
    uint64_t wide = 0u; assert(r4_registry_value_u64(&value.value, &wide) && wide == 0x0102030405060708ull);
    value = r4_registry_get(&registry, &key, "ENABLED", buffer, sizeof(buffer));
    int enabled = 0; assert(r4_registry_value_bool(&value.value, &enabled) && enabled);
    value = r4_registry_get(&registry, &key, "TEXT", buffer, sizeof(buffer));
    R4TextView text = {0}; assert(r4_registry_value_string(&value.value, &text) && text.len == 2u);
    assert(r4_registry_set_u64(&registry, &key, "WIDE", wide).state == R4_OPERATION_OK);
    assert(registry_type == R4OS_REGISTRY_VALUE_TYPE_U64 && registry_value == wide);
    assert(r4_registry_set_bool(&registry, &key, "ENABLED", 1).state == R4_OPERATION_OK);
    assert(registry_type == R4OS_REGISTRY_VALUE_TYPE_BOOL && registry_value == 1u);
    assert(r4_registry_delete(&registry, &key, "COUNT").state == R4_OPERATION_OK);
    assert(r4_registry_delete(&registry, &key, "MISSING").state == R4_OPERATION_MISSING);

    R4XStartR4Sys partial = make_table(0);
    app.system.table = &partial;
    files = r4_app_files(&app);
    registry = r4_app_registry(&app);
    assert(!r4_files_available(&files));
    assert(r4_files_read(&files, &path, buffer, sizeof(buffer)).raw_code == R4OS_ERR_NO_FN);
    assert(!r4_registry_available(&registry));

    uint8_t long_path[R4OS_FILE_PATH_MAX_BYTES + 2u];
    memset(long_path, 'A', sizeof(long_path));
    assert(r4_file_path(long_path, sizeof(long_path), &path) == R4_PATH_TOO_LONG);
    return 0;
}
