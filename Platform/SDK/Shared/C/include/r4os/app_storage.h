#ifndef R4OS_APP_STORAGE_H
#define R4OS_APP_STORAGE_H

#include "app_contract.h"
#include "metadata2.h"

typedef struct R4Console { R4Sys *system; } R4Console;
typedef struct R4Files { R4Sys *system; } R4Files;
typedef struct R4Registry { R4Sys *system; } R4Registry;
/* SDK-local complete console policy; return value validates dispatch only.
 * Like the Zig facade it does not claim a transport completion code. */
int32_t R4SdkConsole(const R4Sys *,const uint8_t *,uintptr_t,int32_t operation);

typedef struct R4FileCopyResult {
    R4FileCopyProgress progress;
    int32_t raw_code;
    uint8_t ok;
} R4FileCopyResult;

typedef enum R4TransferState {
    R4_TRANSFER_BYTES = 0,
    R4_TRANSFER_END = 1,
    R4_TRANSFER_FAILED = 2
} R4TransferState;

typedef struct R4Transfer {
    R4TransferState state;
    int32_t raw_code;
    uint32_t bytes;
} R4Transfer;

typedef enum R4OperationState {
    R4_OPERATION_OK = 0,
    R4_OPERATION_MISSING = 1,
    R4_OPERATION_FAILED = 2
} R4OperationState;

typedef struct R4Operation {
    R4OperationState state;
    int32_t raw_code;
} R4Operation;

typedef enum R4FileInfoState {
    R4_FILE_INFO_VALUE = 0,
    R4_FILE_INFO_MISSING = 1,
    R4_FILE_INFO_FAILED = 2
} R4FileInfoState;

typedef struct R4FileInfoRead {
    R4FileInfoState state;
    int32_t raw_code;
    R4FileInfo value;
} R4FileInfoRead;

typedef enum R4DirectoryNextState {
    R4_DIRECTORY_ENTRY = 0,
    R4_DIRECTORY_END = 1,
    R4_DIRECTORY_FAILED = 2
} R4DirectoryNextState;

typedef struct R4DirectoryNext {
    R4DirectoryNextState state;
    int32_t raw_code;
    uint8_t is_directory;
    R4FilePath path;
    uint8_t has_info;
    R4FileInfo info;
} R4DirectoryNext;

typedef union R4DirectoryCursor {
    R4DirectoryBatchCursor first;
    R4DirectoryMetadataCursor2 next;
} R4DirectoryCursor;
typedef union R4DirectoryRows {
    R4DirectoryBatchEntry first[4];
    R4DirectoryMetadataEntry2 next[4];
} R4DirectoryRows;
typedef struct R4DirectoryIterator {
    R4Files files;
    const R4FilePath *directory;
    uint32_t index;
    uint8_t ended;
    uint8_t legacy_after_removal;
    R4DirectoryCursor cursor;
    R4DirectoryRows buffer;
    uint32_t buffer_index;
    uint32_t buffer_count;
    R4FileMetadata2 last_metadata;
    uint8_t last_metadata_valid;
} R4DirectoryIterator;

typedef struct R4StreamReader {
    R4Files files;
    const R4FilePath *path;
    uint64_t offset;
    uint8_t ended;
} R4StreamReader;

typedef struct R4StreamWriter {
    R4Files files;
    const R4FilePath *path;
    uint64_t offset;
    int32_t raw_code;
    uint8_t active;
} R4StreamWriter;

typedef struct R4RegistryValueView {
    R4RegistryValueInfo info;
    const uint8_t *bytes;
    uint32_t length;
} R4RegistryValueView;

typedef enum R4RegistryReadState {
    R4_REGISTRY_VALUE = 0,
    R4_REGISTRY_MISSING = 1,
    R4_REGISTRY_FAILED = 2
} R4RegistryReadState;

typedef struct R4RegistryRead {
    R4RegistryReadState state;
    int32_t raw_code;
    R4RegistryValueView value;
} R4RegistryRead;

typedef struct R4RegistryBatchBuilder {
    R4RegistryBatchOperation *operations;
    uint32_t operation_capacity;
    uint32_t operation_count;
    uint8_t *blob;
    uint32_t blob_capacity;
    uint32_t blob_len;
} R4RegistryBatchBuilder;

typedef struct R4RegistryBatchApply {
    int32_t raw_code;
    R4RegistryBatchResult result;
} R4RegistryBatchApply;

static inline R4Transfer r4_transfer_raw(int32_t raw) {
    R4Transfer result = {0}; result.raw_code = raw;
    if (raw < 0) result.state = R4_TRANSFER_FAILED;
    else if (raw == 0) result.state = R4_TRANSFER_END;
    else { result.state = R4_TRANSFER_BYTES; result.bytes = (uint32_t)raw; }
    return result;
}

static inline R4Operation r4_operation_presence(int32_t raw) {
    R4Operation result = {0}; result.raw_code = raw;
    result.state = raw < 0 ? R4_OPERATION_FAILED : (raw == 0 ? R4_OPERATION_MISSING : R4_OPERATION_OK);
    return result;
}

static inline R4Operation r4_operation_status(int32_t raw) {
    R4Operation result = {0}; result.raw_code = raw;
    result.state = raw < 0 ? R4_OPERATION_FAILED : R4_OPERATION_OK;
    return result;
}

static inline R4Console r4_app_console(R4App *app) { R4Console value = {app != 0 ? &app->system : 0}; return value; }
static inline R4Files r4_app_files(R4App *app) { R4Files value = {app != 0 ? &app->system : 0}; return value; }
static inline R4Registry r4_app_registry(R4App *app) { R4Registry value = {app != 0 ? &app->system : 0}; return value; }

static inline int r4_console_available(const R4Console *console) {
    return console != 0 && console->system != 0 && r4sys_available(console->system) &&
        R4SYS_SLOT(console->system, write) != 0 && R4SYS_SLOT(console->system, putc) != 0;
}

static inline int32_t r4_console_write(R4Console *console, const uint8_t *bytes, uint32_t length) {
    return r4_console_available(console) ? r4sys_write(console->system, bytes, length) : R4OS_ERR_NO_FN;
}

static inline int32_t r4_console_line(R4Console *console, const char *text) {
    return r4_console_available(console) ? r4sys_write_line(console->system, text) : R4OS_ERR_NO_FN;
}

static inline int32_t r4_console_put(R4Console *console, uint8_t byte) {
    return R4SdkConsole(console?console->system:0,&byte,1,2);
}
static inline int32_t r4_console_write_line(R4Console *console,const uint8_t *bytes,uint32_t length) {
    return R4SdkConsole(console?console->system:0,bytes,length,1);
}
static inline int32_t r4_console_write_all(R4Console *console,const uint8_t *bytes,uintptr_t length) {
    return R4SdkConsole(console?console->system:0,bytes,length,0);
}

static inline int r4_files_available(const R4Files *files) {
    return files != 0 && files->system != 0 && r4sys_available(files->system) &&
        R4SYS_SLOT(files->system, file_read) != 0 && R4SYS_SLOT(files->system, file_write) != 0 &&
        R4SYS_SLOT(files->system, file_read_at) != 0 && R4SYS_SLOT(files->system, file_append) != 0;
}

static inline R4Transfer r4_files_read(R4Files *files, const R4FilePath *path, uint8_t *out, uint32_t capacity) {
    if (files == 0 || path == 0 || files->system == 0 || !r4sys_available(files->system) || R4SYS_SLOT(files->system, file_read) == 0) return r4_transfer_raw(R4OS_ERR_NO_FN);
    return r4_transfer_raw(((R4SysFileReadFn)(uintptr_t)R4SYS_SLOT(files->system, file_read))(path->bytes, out, capacity));
}

static inline R4Transfer r4_files_read_at(R4Files *files, const R4FilePath *path, uint32_t offset, uint8_t *out, uint32_t capacity) {
    if (files == 0 || path == 0 || files->system == 0 || !r4sys_available(files->system) || R4SYS_SLOT(files->system, file_read_at) == 0) return r4_transfer_raw(R4OS_ERR_NO_FN);
    return r4_transfer_raw(((R4SysFileReadAtFn)(uintptr_t)R4SYS_SLOT(files->system, file_read_at))(path->bytes, offset, out, capacity));
}

static inline R4Transfer r4_files_write(R4Files *files, const R4FilePath *path, const uint8_t *bytes, uint32_t length) {
    if (files == 0 || path == 0 || files->system == 0 || !r4sys_available(files->system) || R4SYS_SLOT(files->system, file_write) == 0) return r4_transfer_raw(R4OS_ERR_NO_FN);
    int32_t raw = ((R4SysFileWriteFn)(uintptr_t)R4SYS_SLOT(files->system, file_write))(path->bytes, bytes, length);
    R4Transfer result = r4_transfer_raw(raw); if (raw == 0) { result.state = R4_TRANSFER_BYTES; result.bytes = 0; } return result;
}

static inline R4Transfer r4_files_append(R4Files *files, const R4FilePath *path, const uint8_t *bytes, uint32_t length) {
    if (files == 0 || path == 0 || files->system == 0 || !r4sys_available(files->system) || R4SYS_SLOT(files->system, file_append) == 0) return r4_transfer_raw(R4OS_ERR_NO_FN);
    int32_t raw = ((R4SysFileAppendFn)(uintptr_t)R4SYS_SLOT(files->system, file_append))(path->bytes, bytes, length);
    R4Transfer result = r4_transfer_raw(raw); if (raw == 0) { result.state = R4_TRANSFER_BYTES; result.bytes = 0; } return result;
}

/* Names are syntactically checked by FilePath; this query reports the actual
 * target provider and independent atomic staging rules. No name truncation. */
static inline int32_t r4_files_name_limits(R4Files *files, const R4FilePath *path, R4FileNameLimits *out) {
    if (!files || !path || !out) return R4OS_FILE_STREAM_ERROR_INVALID;
    return r4sys_file_name_limits(files->system, (const char *)path->bytes, out);
}

static inline int32_t r4_files_system_update_target_supported(const R4Files *files, const R4FilePath *path) {
    if (!files || !path || !path->absolute) return R4OS_ERROR_INVALID;
    return r4sys_system_update_target_supported(files->system, (const char *)path->bytes);
}

/* Wide values are the normal generation2 observation. The old FileInfo
 * projection is available only when every represented scalar fits exactly. */
static inline int32_t r4_files_metadata(const R4Files *files, const R4FilePath *path, R4FileMetadata2 *out) {
    if (!files || !files->system || !path || !out) return R4OS_FILE_METADATA2_ERROR_INVALID;
    if (!files->system->generation2) return R4OS_FILE_METADATA2_ERROR_UNSUPPORTED;
    return R4SdkFileMetadata2(files->system->generation2, path->bytes, out);
}
static inline int32_t r4_metadata_file_info(const R4FileMetadata2 *metadata, const uint8_t *path, R4FileInfo *out) {
    if (!metadata || !path || !out || metadata->version != 1 || metadata->size < sizeof(*metadata)) return R4OS_FILE_METADATA2_ERROR_INVALID;
    if (!(metadata->flags & R4OS_FILE_METADATA2_FLAG_EXISTS)) return R4OS_FILE_METADATA2_ERROR_INVALID;
    if ((metadata->flags & R4OS_FILE_METADATA2_FLAG_BACKEND_NODE_VALID) && metadata->backend_node > UINT32_MAX) return R4OS_FILE_METADATA2_ERROR_UNSUPPORTED;
    if (metadata->attributes > UINT8_MAX || metadata->drive_letter > UINT8_MAX) return R4OS_FILE_METADATA2_ERROR_UNSUPPORTED;
    R4FileInfo value = {0};
    value.exists = (metadata->flags & R4OS_FILE_METADATA2_FLAG_EXISTS) != 0;
    value.is_dir = (metadata->flags & R4OS_FILE_METADATA2_FLAG_DIRECTORY) != 0;
    if (!value.is_dir && !(metadata->flags & R4OS_FILE_METADATA2_FLAG_BYTE_SIZE_VALID)) return R4OS_FILE_METADATA2_ERROR_UNSUPPORTED;
    value.size = (metadata->flags & R4OS_FILE_METADATA2_FLAG_BYTE_SIZE_VALID) ? metadata->byte_size : 0;
    value.first_cluster = (metadata->flags & R4OS_FILE_METADATA2_FLAG_BACKEND_NODE_VALID) ? (uint32_t)metadata->backend_node : 0;
    value.attr = (uint8_t)metadata->attributes; value.drive = (uint8_t)metadata->drive_letter;
    if (metadata->flags & R4OS_FILE_METADATA2_FLAG_DOS_TIME_VALID) {
        value.created_time = metadata->created_time; value.created_date = metadata->created_date;
        value.access_date = metadata->access_date;
        value.modified_time = metadata->modified_time; value.modified_date = metadata->modified_date;
    }
    const uint8_t *name = path;
    for (const uint8_t *p = path; *p; ++p) if (*p == '\\' || *p == '/') name = p + 1;
    size_t length = 0;
    while (name[length]) { if (length + 1 >= sizeof(value.name)) return R4OS_FILE_METADATA2_ERROR_UNSUPPORTED; ++length; }
    for (size_t i = 0; i < length; ++i) value.name[i] = name[i];
    *out = value; return 0;
}
static inline R4FileInfoRead r4_files_info(R4Files *files, const R4FilePath *path) {
    R4FileInfoRead result = {0};
    if (files && files->system && files->system->generation2) {
        R4FileMetadata2 metadata;
        const int32_t rc = r4_files_metadata(files, path, &metadata);
        if (rc == 0) { result.state = R4_FILE_INFO_MISSING; return result; }
        result.raw_code = rc == 1 ? r4_metadata_file_info(&metadata, path->bytes, &result.value) : rc;
        result.state = result.raw_code == 0 ? R4_FILE_INFO_VALUE : R4_FILE_INFO_FAILED;
        return result;
    }
    if (files == 0 || path == 0 || files->system == 0 || !r4sys_available(files->system) || R4SYS_SLOT(files->system, file_info) == 0) {
        result.state = R4_FILE_INFO_FAILED; result.raw_code = R4OS_ERR_NO_FN; return result;
    }
    int32_t raw = ((R4SysFileInfoFn)(uintptr_t)R4SYS_SLOT(files->system, file_info))(path->bytes, &result.value);
    result.raw_code = raw;
    if (raw < 0) result.state = R4_FILE_INFO_FAILED;
    else if (raw == 0 || result.value.exists == 0u) result.state = R4_FILE_INFO_MISSING;
    else result.state = R4_FILE_INFO_VALUE;
    return result;
}

static inline R4Operation r4_files_delete(R4Files *files, const R4FilePath *path) {
    if (files == 0 || path == 0 || files->system == 0 || !r4sys_available(files->system) || R4SYS_SLOT(files->system, file_delete) == 0) return r4_operation_status(R4OS_ERR_NO_FN);
    return r4_operation_presence(((R4SysFileDeleteFn)(uintptr_t)R4SYS_SLOT(files->system, file_delete))(path->bytes));
}

static inline R4FileCopyResult r4_files_copy(R4Files *files, const R4FilePath *source, const R4FilePath *target, uint8_t *buffer, uint32_t capacity) {
    R4FileCopyResult result = {0};
    result.progress.version = 1u;
    result.progress.size = sizeof(R4FileCopyProgress);
    result.raw_code = r4sys_file_copy_buffered(files == 0 ? 0 : files->system, source == 0 ? 0 : (const char *)source->bytes, target == 0 ? 0 : (const char *)target->bytes, buffer, capacity, &result.progress);
    result.ok = result.raw_code == R4OS_FILE_STREAM_RESULT_OK;
    return result;
}

static inline R4Operation r4_files_create_directory(R4Files *files, const R4FilePath *path) {
    if (files == 0 || path == 0 || files->system == 0 || !r4sys_available(files->system) || R4SYS_SLOT(files->system, dir_create) == 0) return r4_operation_status(R4OS_ERR_NO_FN);
    return r4_operation_presence(((R4SysDirCreateFn)(uintptr_t)R4SYS_SLOT(files->system, dir_create))(path->bytes));
}

static inline R4Operation r4_files_delete_directory(R4Files *files, const R4FilePath *path) {
    if (files == 0 || path == 0 || files->system == 0 || !r4sys_available(files->system) || R4SYS_SLOT(files->system, dir_delete) == 0) return r4_operation_status(R4OS_ERR_NO_FN);
    return r4_operation_presence(((R4SysDirDeleteFn)(uintptr_t)R4SYS_SLOT(files->system, dir_delete))(path->bytes));
}

static inline R4Operation r4_files_rename(R4Files *files, const R4FilePath *source, const R4FilePath *target) {
    if (files == 0 || source == 0 || target == 0 || files->system == 0 || !r4sys_available(files->system) || R4SYS_SLOT(files->system, file_rename) == 0) return r4_operation_status(R4OS_ERR_NO_FN);
    return r4_operation_presence(((R4SysFileRenameFn)(uintptr_t)R4SYS_SLOT(files->system, file_rename))(source->bytes, target->bytes));
}

static inline int32_t r4_files_replace_atomic(R4Files *files, const R4FilePath *target, const R4FilePath *stage, const R4FilePath *backup, uint32_t flags) {
    if (!files || !target || !stage || !backup ||
        (flags & ~(R4SYS_FILE_REPLACE_ATOMIC_CONSUME_STAGE | R4SYS_FILE_REPLACE_ATOMIC_REQUIRE_TARGET_ABSENT | R4SYS_FILE_REPLACE_ATOMIC_REQUIRE_OWNED_STAGE)) ||
        ((flags & (R4SYS_FILE_REPLACE_ATOMIC_REQUIRE_TARGET_ABSENT | R4SYS_FILE_REPLACE_ATOMIC_REQUIRE_OWNED_STAGE)) && !(flags & R4SYS_FILE_REPLACE_ATOMIC_CONSUME_STAGE)) ||
        ((flags & R4SYS_FILE_REPLACE_ATOMIC_REQUIRE_OWNED_STAGE) &&
         (flags & (R4SYS_FILE_REPLACE_ATOMIC_CONSUME_STAGE | R4SYS_FILE_REPLACE_ATOMIC_REQUIRE_TARGET_ABSENT)) !=
         (R4SYS_FILE_REPLACE_ATOMIC_CONSUME_STAGE | R4SYS_FILE_REPLACE_ATOMIC_REQUIRE_TARGET_ABSENT))) return R4SYS_FILE_REPLACE_ATOMIC_ERROR_INVALID;
    return r4sys_file_replace_atomic_flags(files->system, (const char *)target->bytes, (const char *)stage->bytes, (const char *)backup->bytes, flags);
}

static inline int32_t r4_files_directory_changes_begin(R4Files *files, const R4FilePath *path, R4DirectoryChangeCursor *cursor) {
    if (!files || !files->system || !r4sys_available(files->system) || !path || !cursor) return R4OS_ERROR_INVALID;
    if (!R4SYS_HAS(files->system, directory_change_begin) || !R4SYS_SLOT(files->system, directory_change_begin)) return R4OS_ERR_NO_FN;
    *cursor = (R4DirectoryChangeCursor){.version=1, .size=sizeof(*cursor)};
    return ((R4SysDirectoryChangeBeginFn)(uintptr_t)R4SYS_SLOT(files->system, directory_change_begin))(path->bytes, cursor);
}
static inline int32_t r4_files_directory_changes_poll(R4Files *files, R4DirectoryChangeCursor *cursor) {
    if (!files || !files->system || !r4sys_available(files->system) || !cursor) return R4OS_ERROR_INVALID;
    if (!R4SYS_HAS(files->system, directory_change_poll) || !R4SYS_SLOT(files->system, directory_change_poll)) return R4OS_ERR_NO_FN;
    return ((R4SysDirectoryChangePollFn)(uintptr_t)R4SYS_SLOT(files->system, directory_change_poll))(cursor);
}

/* Capacity0 validates an initialized descriptor without advancing it. */
static inline int32_t r4_files_directory_batch(R4Files *files, const R4FilePath *path,
        R4DirectoryBatchCursor *cursor, R4DirectoryBatchEntry *out, uint32_t capacity) {
    if (!files || !files->system || !r4sys_available(files->system) || !path || !cursor) return R4OS_ERROR_INVALID;
    if (!R4SYS_HAS(files->system, directory_batch) || !R4SYS_SLOT(files->system, directory_batch)) return R4OS_ERR_NO_FN;
    return ((R4SysDirectoryBatchFn)(uintptr_t)R4SYS_SLOT(files->system, directory_batch))(path->bytes, cursor, out, capacity);
}

static inline R4DirectoryIterator r4_files_iterate(R4Files files, const R4FilePath *directory) {
    R4DirectoryIterator result = {0};
    result.files = files; result.directory = directory; result.index = 2u;
    if (files.system && files.system->generation2) R4SdkDirectoryMetadata2Init(&result.cursor.next);
    else { result.cursor.first.version = 1u; result.cursor.first.size = sizeof(result.cursor.first); }
    return result;
}

static inline R4DirectoryNext r4_directory_next2(R4DirectoryIterator *iterator) {
    R4DirectoryNext result = {0};
    const R4OS2Context *context = iterator->files.system->generation2;
    iterator->last_metadata_valid = 0;
    int32_t raw;
    if (iterator->legacy_after_removal) { raw = R4OS_FILE_METADATA2_ERROR_RESTART; goto fail; }
    while (iterator->buffer_index == iterator->buffer_count) {
        raw = R4SdkDirectoryMetadata2Batch(context, iterator->directory->bytes, &iterator->cursor.next, iterator->buffer.next, 4);
        if (raw == -5) { iterator->ended = 1; result.state = R4_DIRECTORY_END; result.raw_code = raw; return result; }
        if (raw < 0) goto fail;
        if (raw > 4) { raw = R4OS_FILE_METADATA2_ERROR_INVALID; goto fail; }
        if (raw != 0) { iterator->buffer_index = 0; iterator->buffer_count = (uint32_t)raw; break; }
        if (r4sys_program_should_close(iterator->files.system)) { raw = R4OS_ERR_CLOSED; goto fail; }
        r4sys_sleep_ticks(iterator->files.system, 0);
    }
    if (r4sys_program_should_close(iterator->files.system)) { raw = R4OS_ERR_CLOSED; goto fail; }
    raw = R4SdkDirectoryMetadata2Batch(context, NULL, &iterator->cursor.next, NULL, 0);
    if (raw != 0) { if (raw > 0) raw = R4OS_FILE_METADATA2_ERROR_INVALID; goto fail; }
    const R4DirectoryMetadataEntry2 *record = &iterator->buffer.next[iterator->buffer_index];
    if (record->info.version != 1 || record->info.size < sizeof(record->info) || !(record->info.flags & R4OS_FILE_METADATA2_FLAG_EXISTS)) { raw = R4OS_FILE_METADATA2_ERROR_INVALID; goto fail; }
    size_t length = 0;
    while (length < sizeof(result.path.bytes) && record->path[length]) ++length;
    if (length == sizeof(result.path.bytes)) { raw = R4OS_FILE_METADATA2_ERROR_PATH_BOUNDS; goto fail; }
    for (size_t i = 0; i < length; ++i) result.path.bytes[i] = record->path[i];
    result.path.length = (uint16_t)length; result.path.absolute = 1;
    result.is_directory = (record->info.flags & R4OS_FILE_METADATA2_FLAG_DIRECTORY) != 0;
    result.has_info = r4_metadata_file_info(&record->info, record->path, &result.info) == 0;
    iterator->last_metadata = record->info; iterator->last_metadata_valid = 1;
    ++iterator->buffer_index;
    result.state = R4_DIRECTORY_ENTRY;
    return result;
fail:
    iterator->buffer_index = iterator->buffer_count = 0;
    result.state = R4_DIRECTORY_FAILED; result.raw_code = raw;
    return result;
}

static inline R4DirectoryNext r4_directory_next(R4DirectoryIterator *iterator) {
    R4DirectoryNext result = {0};
    if (iterator == 0 || iterator->ended) { result.state = R4_DIRECTORY_END; return result; }
    if (!iterator->directory || !iterator->files.system || !r4sys_available(iterator->files.system)) {
        result.state = R4_DIRECTORY_FAILED; result.raw_code = R4OS_ERR_NO_FN; return result;
    }
    if (iterator->files.system->generation2) return r4_directory_next2(iterator);
    int32_t raw;
    if (iterator->legacy_after_removal || iterator->index < 2u) {
        raw = R4SYS_SLOT(iterator->files.system, dir_entry) ? ((R4SysDirEntryFn)(uintptr_t)R4SYS_SLOT(iterator->files.system, dir_entry))(iterator->directory->bytes, iterator->index, result.path.bytes, (uint32_t)sizeof(result.path.bytes)) : R4OS_ERR_NO_FN;
    } else {
        while (iterator->buffer_index == iterator->buffer_count) {
            raw = r4_files_directory_batch(&iterator->files, iterator->directory, &iterator->cursor.first, iterator->buffer.first, 4u);
            if (raw < 0) goto complete;
            if (raw > 4) { raw = R4OS_ERROR_INVALID; goto complete; }
            if (raw != 0) { iterator->buffer_index = 0; iterator->buffer_count = (uint32_t)raw; break; }
            if (r4sys_program_should_close(iterator->files.system)) { raw = -10; goto complete; }
            r4sys_sleep_ticks(iterator->files.system, 0);
        }
        if (r4sys_program_should_close(iterator->files.system)) { raw = -10; goto complete; }
        raw = r4_files_directory_batch(&iterator->files, iterator->directory, &iterator->cursor.first, 0, 0);
        if (raw < 0) goto complete;
        const R4DirectoryBatchEntry *record = &iterator->buffer.first[iterator->buffer_index];
        uint32_t length = 0;
        while (length < sizeof(result.path.bytes) && record->path[length] != 0) ++length;
        if (length == sizeof(result.path.bytes)) { raw = R4OS_ERROR_INVALID; goto complete; }
        for (uint32_t i = 0; i < length; ++i) result.path.bytes[i] = record->path[i];
        result.info = record->info; result.has_info = 1u;
        ++iterator->buffer_index;
        raw = record->info.is_dir ? 1 : 0;
    }
complete:
    result.raw_code = raw;
    if (raw == R4SYS_DIR_ENTRY_RESULT_END) { iterator->ended = 1u; result.state = R4_DIRECTORY_END; return result; }
    if (raw < 0) { result.state = R4_DIRECTORY_FAILED; return result; }
    ++iterator->index; result.state = R4_DIRECTORY_ENTRY; result.is_directory = raw == 1;
    while (result.path.length < sizeof(result.path.bytes) && result.path.bytes[result.path.length] != 0) ++result.path.length;
    result.path.absolute = 1u; return result;
}

static inline void r4_directory_revisit_after_removal(R4DirectoryIterator *iterator) {
    if (iterator == 0) return;
    if (iterator->files.system && iterator->files.system->generation2) {
        iterator->last_metadata_valid = 0;
        iterator->buffer_index = iterator->buffer_count = 0;
        iterator->legacy_after_removal = 1;
        iterator->ended = 0;
        return; /* Caller must discard the old traversal and start a fresh one. */
    }
    iterator->legacy_after_removal = 1u;
    iterator->cursor.first = (R4DirectoryBatchCursor){0};
    iterator->buffer_index = 0; iterator->buffer_count = 0;
    iterator->cursor.first.version = 1u; iterator->cursor.first.size = sizeof(iterator->cursor.first);
    if (iterator->index > 2u) --iterator->index;
    iterator->ended = 0u;
}

static inline R4StreamReader r4_files_stream_reader(R4Files files, const R4FilePath *path) {
    R4StreamReader result = {files, path, 0u, 0u}; return result;
}

static inline R4Transfer r4_stream_reader_read(R4StreamReader *reader, uint8_t *out, uint32_t capacity) {
    if (reader == 0 || reader->ended) { R4Transfer end = {R4_TRANSFER_END, 0, 0}; return end; }
    if (reader->offset > UINT32_MAX) return r4_transfer_raw(R4OS_FILE_STREAM_ERROR_TOO_LARGE);
    R4Transfer result = r4_files_read_at(&reader->files, reader->path, (uint32_t)reader->offset, out, capacity);
    if (result.state == R4_TRANSFER_BYTES) reader->offset += result.bytes;
    else if (result.state == R4_TRANSFER_END) reader->ended = 1u;
    return result;
}

static inline R4Operation r4_files_stream_writer(R4Files files, const R4FilePath *path, uint32_t flags, R4StreamWriter *out_writer) {
    if (out_writer == 0 || path == 0 || files.system == 0 || !r4sys_available(files.system) || R4SYS_SLOT(files.system, file_stream_begin) == 0) return r4_operation_status(R4OS_ERR_NO_FN);
    *out_writer = (R4StreamWriter){files, path, 0u, 0, 0u};
    int32_t raw = ((R4SysFileStreamBeginFn)(uintptr_t)R4SYS_SLOT(files.system, file_stream_begin))(path->bytes, flags);
    out_writer->raw_code = raw; out_writer->active = raw == R4OS_FILE_STREAM_RESULT_OK; return r4_operation_status(raw);
}

static inline R4Operation r4_stream_writer_write(R4StreamWriter *writer, const uint8_t *bytes, uint32_t length) {
    if (writer == 0 || !writer->active || R4SYS_SLOT(writer->files.system, file_stream_write) == 0) return r4_operation_status(R4OS_ERR_NO_FN);
    int32_t raw = ((R4SysFileStreamWriteFn)(uintptr_t)R4SYS_SLOT(writer->files.system, file_stream_write))(writer->path->bytes, writer->offset, bytes, length, 0u);
    writer->raw_code = raw; if (raw < 0 || (uint32_t)raw != length) { writer->active = 0u; return r4_operation_status(raw < 0 ? raw : R4OS_FILE_STREAM_ERROR_IO); }
    writer->offset += length; return r4_operation_status(R4OS_FILE_STREAM_RESULT_OK);
}

static inline R4Operation r4_stream_writer_finish_flags(R4StreamWriter *writer, uint32_t flags) {
    if (writer == 0 || !writer->active || R4SYS_SLOT(writer->files.system, file_stream_finish) == 0) return r4_operation_status(R4OS_ERR_NO_FN);
    int32_t raw = ((R4SysFileStreamFinishFn)(uintptr_t)R4SYS_SLOT(writer->files.system, file_stream_finish))(writer->path->bytes, writer->offset, flags);
    writer->raw_code = raw; writer->active = 0u; return r4_operation_status(raw);
}

static inline R4Operation r4_stream_writer_finish(R4StreamWriter *writer) {
    return r4_stream_writer_finish_flags(writer, 0u);
}

static inline R4Operation r4_stream_writer_abort(R4StreamWriter *writer) {
    if (writer == 0 || writer->files.system == 0 || !r4sys_available(writer->files.system) || R4SYS_SLOT(writer->files.system, file_stream_abort) == 0) return r4_operation_status(R4OS_ERR_NO_FN);
    int32_t raw = ((R4SysFileStreamAbortFn)(uintptr_t)R4SYS_SLOT(writer->files.system, file_stream_abort))(writer->path->bytes);
    writer->raw_code = raw; writer->active = 0u; return r4_operation_status(raw);
}

static inline int r4_registry_available(const R4Registry *registry) {
    return registry != 0 && registry->system != 0 && r4sys_available(registry->system) &&
        R4SYS_SLOT(registry->system, registry_get_value) != 0 && R4SYS_SLOT(registry->system, registry_set_value) != 0;
}

static inline int r4_registry_snapshot_available(const R4Registry *registry) {
    return registry != 0 && r4sys_supports_registry_snapshot(registry->system);
}

static inline int32_t r4_registry_snapshot_begin(
    R4Registry *registry,
    const R4RegistryPath *key,
    uint32_t kind,
    R4RegistrySnapshotCursor *cursor)
{
    if (registry == 0 || key == 0 || cursor == 0) return R4OS_REGISTRY_API_RESULT_INVALID;
    return r4sys_registry_snapshot_begin(registry->system, key->bytes, kind, cursor);
}

static inline int32_t r4_registry_snapshot_page(
    R4Registry *registry,
    R4RegistrySnapshotCursor *cursor,
    R4RegistrySnapshotEntry *entries,
    uint32_t entry_capacity,
    uint8_t *data,
    uint32_t data_capacity,
    R4RegistrySnapshotPageInfo *out_page)
{
    if (registry == 0) return R4OS_REGISTRY_API_RESULT_INVALID;
    return r4sys_registry_snapshot_page(registry->system, cursor, entries, entry_capacity, data, data_capacity, out_page);
}

static inline void r4_registry_batch_builder_init(
    R4RegistryBatchBuilder *builder,
    R4RegistryBatchOperation *operations,
    uint32_t operation_capacity,
    uint8_t *blob,
    uint32_t blob_capacity)
{
    if (builder == 0) return;
    *builder = (R4RegistryBatchBuilder){operations, operation_capacity, 0u, blob, blob_capacity, 0u};
}

static inline void r4_registry_batch_builder_reset(R4RegistryBatchBuilder *builder) {
    if (builder == 0) return;
    builder->operation_count = 0u;
    builder->blob_len = 0u;
}

static inline int32_t r4_registry_batch_builder_append(
    R4RegistryBatchBuilder *builder,
    const R4RegistryPath *key,
    const char *name,
    uint16_t operation,
    uint16_t value_type,
    const uint8_t *data,
    uint32_t data_len)
{
    if (builder == 0 || builder->operations == 0 || builder->blob == 0 || key == 0 || name == 0 ||
        (data == 0 && data_len != 0u) || builder->operation_count >= builder->operation_capacity ||
        builder->operation_count >= R4OS_REGISTRY_BATCH_OPERATION_MAX)
    {
        return R4OS_REGISTRY_API_RESULT_INVALID;
    }
    uint32_t name_len = r4os_cstr_len(name);
    if (name_len > 63u) return R4OS_REGISTRY_API_RESULT_INVALID;
    for (uint32_t i = 0; i < name_len; ++i) {
        uint8_t ch = (uint8_t)name[i];
        if (ch < 0x20u || ch == 0x7fu || ch == '\\' || ch == '/' || ch == '=') return R4OS_REGISTRY_API_RESULT_INVALID;
    }
    uint64_t needed = (uint64_t)key->length + name_len + data_len;
    if (needed > builder->blob_capacity || builder->blob_len > builder->blob_capacity - (uint32_t)needed ||
        builder->blob_len + (uint32_t)needed > R4OS_REGISTRY_BATCH_BLOB_MAX)
    {
        return R4OS_REGISTRY_API_RESULT_BUFFER_TOO_SMALL;
    }
    uint32_t key_offset = builder->blob_len;
    __builtin_memcpy(builder->blob + builder->blob_len, key->bytes, key->length);
    builder->blob_len += key->length;
    uint32_t name_offset = builder->blob_len;
    __builtin_memcpy(builder->blob + builder->blob_len, name, name_len);
    builder->blob_len += name_len;
    uint32_t data_offset = builder->blob_len;
    if (data_len != 0u) __builtin_memcpy(builder->blob + builder->blob_len, data, data_len);
    builder->blob_len += data_len;
    R4RegistryBatchOperation *entry = &builder->operations[builder->operation_count++];
    *entry = (R4RegistryBatchOperation){operation, value_type, key_offset, key->length, name_offset, name_len, data_offset, data_len, 0u};
    return R4OS_REGISTRY_API_RESULT_OK;
}

static inline int32_t r4_registry_batch_builder_set(
    R4RegistryBatchBuilder *builder,
    const R4RegistryPath *key,
    const char *name,
    uint16_t value_type,
    const uint8_t *data,
    uint32_t data_len)
{
    return r4_registry_batch_builder_append(builder, key, name, R4OS_REGISTRY_BATCH_OPERATION_SET, value_type, data, data_len);
}

static inline int32_t r4_registry_batch_builder_set_u32(R4RegistryBatchBuilder *builder, const R4RegistryPath *key, const char *name, uint32_t value) {
    uint8_t data[4] = {(uint8_t)value, (uint8_t)(value >> 8), (uint8_t)(value >> 16), (uint8_t)(value >> 24)};
    return r4_registry_batch_builder_set(builder, key, name, R4OS_REGISTRY_VALUE_TYPE_U32, data, 4u);
}

static inline int32_t r4_registry_batch_builder_delete(R4RegistryBatchBuilder *builder, const R4RegistryPath *key, const char *name) {
    return r4_registry_batch_builder_append(builder, key, name, R4OS_REGISTRY_BATCH_OPERATION_DELETE, 0u, 0, 0u);
}

static inline int r4_registry_batch_available(const R4Registry *registry) {
    return registry != 0 && r4sys_supports_registry_batch(registry->system);
}

static inline R4RegistryBatchApply r4_registry_batch_apply(R4Registry *registry, const R4RegistryBatchBuilder *builder) {
    R4RegistryBatchApply applied = {0};
    applied.result.version = R4OS_REGISTRY_BATCH_VERSION;
    applied.result.size = (uint32_t)sizeof(R4RegistryBatchResult);
    if (registry == 0 || builder == 0) {
        applied.raw_code = R4OS_REGISTRY_API_RESULT_INVALID;
        return applied;
    }
    applied.raw_code = r4sys_registry_batch_mutate(
        registry->system,
        builder->operations,
        builder->operation_count,
        builder->blob,
        builder->blob_len,
        &applied.result);
    return applied;
}

static inline int r4_registry_batch_committed(const R4RegistryBatchApply *applied) {
    return applied != 0 && applied->raw_code == R4OS_REGISTRY_API_RESULT_OK &&
        applied->result.status == R4OS_REGISTRY_BATCH_STATUS_COMMITTED;
}

static inline R4RegistryRead r4_registry_get(R4Registry *registry, const R4RegistryPath *key, const char *name, uint8_t *out, uint32_t capacity) {
    R4RegistryRead result = {0};
    if (registry == 0 || key == 0 || name == 0 || registry->system == 0 || !r4sys_available(registry->system) || R4SYS_SLOT(registry->system, registry_get_value) == 0) {
        result.state = R4_REGISTRY_FAILED; result.raw_code = R4OS_ERR_NO_FN; return result;
    }
    int32_t raw = ((R4SysRegistryGetValueFn)(uintptr_t)R4SYS_SLOT(registry->system, registry_get_value))(key->bytes, (const uint8_t *)name, &result.value.info, out, capacity);
    result.raw_code = raw;
    if (raw == R4OS_REGISTRY_API_RESULT_VALUE_NOT_FOUND || raw == R4OS_REGISTRY_API_RESULT_KEY_NOT_FOUND) result.state = R4_REGISTRY_MISSING;
    else if (raw < 0) result.state = R4_REGISTRY_FAILED;
    else if ((uint32_t)raw > capacity) { result.state = R4_REGISTRY_FAILED; result.raw_code = R4OS_REGISTRY_API_RESULT_BUFFER_TOO_SMALL; }
    else { result.state = R4_REGISTRY_VALUE; result.value.bytes = out; result.value.length = (uint32_t)raw; }
    return result;
}

static inline R4Operation r4_registry_set(R4Registry *registry, const R4RegistryPath *key, const char *name, uint16_t type, const uint8_t *bytes, uint32_t length) {
    if (registry == 0 || key == 0 || name == 0 || registry->system == 0 || !r4sys_available(registry->system) || R4SYS_SLOT(registry->system, registry_set_value) == 0) return r4_operation_status(R4OS_ERR_NO_FN);
    return r4_operation_status(((R4SysRegistrySetValueFn)(uintptr_t)R4SYS_SLOT(registry->system, registry_set_value))(key->bytes, (const uint8_t *)name, type, bytes, length));
}

static inline R4Operation r4_registry_set_u32(R4Registry *registry, const R4RegistryPath *key, const char *name, uint32_t value) {
    uint8_t bytes[4] = {(uint8_t)value, (uint8_t)(value >> 8), (uint8_t)(value >> 16), (uint8_t)(value >> 24)};
    return r4_registry_set(registry, key, name, R4OS_REGISTRY_VALUE_TYPE_U32, bytes, 4u);
}

static inline R4Operation r4_registry_set_string(R4Registry *registry, const R4RegistryPath *key, const char *name, const char *value) {
    if (value == 0) return r4_operation_status(R4OS_REGISTRY_API_RESULT_INVALID);
    return r4_registry_set(registry, key, name, R4OS_REGISTRY_VALUE_TYPE_STRING, (const uint8_t *)value, r4os_cstr_len(value));
}

static inline R4Operation r4_registry_set_u64(R4Registry *registry, const R4RegistryPath *key, const char *name, uint64_t value) {
    uint8_t bytes[8]; for (uint32_t i = 0; i < 8u; ++i) bytes[i] = (uint8_t)(value >> (i * 8u));
    return r4_registry_set(registry, key, name, R4OS_REGISTRY_VALUE_TYPE_U64, bytes, 8u);
}

static inline R4Operation r4_registry_set_bool(R4Registry *registry, const R4RegistryPath *key, const char *name, int value) {
    uint8_t byte = value ? 1u : 0u;
    return r4_registry_set(registry, key, name, R4OS_REGISTRY_VALUE_TYPE_BOOL, &byte, 1u);
}

static inline R4Operation r4_registry_set_binary(R4Registry *registry, const R4RegistryPath *key, const char *name, const uint8_t *bytes, uint32_t length) {
    return r4_registry_set(registry, key, name, R4OS_REGISTRY_VALUE_TYPE_BINARY, bytes, length);
}

static inline R4Operation r4_registry_delete(R4Registry *registry, const R4RegistryPath *key, const char *name) {
    if (registry == 0 || key == 0 || name == 0 || registry->system == 0 || !r4sys_available(registry->system) || R4SYS_SLOT(registry->system, registry_delete_value) == 0) return r4_operation_status(R4OS_ERR_NO_FN);
    int32_t raw = ((R4SysRegistryDeleteValueFn)(uintptr_t)R4SYS_SLOT(registry->system, registry_delete_value))(key->bytes, (const uint8_t *)name);
    if (raw == R4OS_REGISTRY_API_RESULT_VALUE_NOT_FOUND || raw == R4OS_REGISTRY_API_RESULT_KEY_NOT_FOUND) { R4Operation missing = {R4_OPERATION_MISSING, raw}; return missing; }
    return r4_operation_status(raw);
}

static inline int r4_registry_value_u32(const R4RegistryValueView *view, uint32_t *out) {
    if (view == 0 || out == 0 || view->info.value_type != R4OS_REGISTRY_VALUE_TYPE_U32 || view->length != 4u) return 0;
    *out = (uint32_t)view->bytes[0] | ((uint32_t)view->bytes[1] << 8) | ((uint32_t)view->bytes[2] << 16) | ((uint32_t)view->bytes[3] << 24); return 1;
}

static inline int r4_registry_value_u64(const R4RegistryValueView *view, uint64_t *out) {
    if (view == 0 || out == 0 || view->info.value_type != R4OS_REGISTRY_VALUE_TYPE_U64 || view->length != 8u) return 0;
    uint64_t value = 0u; for (uint32_t i = 0; i < 8u; ++i) value |= (uint64_t)view->bytes[i] << (i * 8u); *out = value; return 1;
}

static inline int r4_registry_value_bool(const R4RegistryValueView *view, int *out) {
    if (view == 0 || out == 0 || view->info.value_type != R4OS_REGISTRY_VALUE_TYPE_BOOL || view->length != 1u || view->bytes[0] > 1u) return 0;
    *out = view->bytes[0] != 0u; return 1;
}

static inline int r4_registry_value_string(const R4RegistryValueView *view, R4TextView *out) {
    if (view == 0 || out == 0 || view->info.value_type != R4OS_REGISTRY_VALUE_TYPE_STRING) return 0;
    out->ptr = view->bytes; out->len = view->length; return 1;
}

static inline int r4_registry_value_binary(const R4RegistryValueView *view, const uint8_t **out_bytes, uint32_t *out_length) {
    if (view == 0 || out_bytes == 0 || out_length == 0 || view->info.value_type != R4OS_REGISTRY_VALUE_TYPE_BINARY) return 0;
    *out_bytes = view->bytes; *out_length = view->length; return 1;
}

#endif
