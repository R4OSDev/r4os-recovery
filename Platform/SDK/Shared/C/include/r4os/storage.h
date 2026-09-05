#ifndef R4OS_STORAGE_H
#define R4OS_STORAGE_H
#include "r4sys.h"

/* Physical storage identities and claims belong to R4SYS. No driver access. */
typedef struct R4Storage { R4Sys *system; } R4Storage;
#define R4_STORAGE_HAS(s, name) ((s) && (s)->system && (s)->system->table && \
    (s)->system->table->size >= offsetof(R4XStartR4Sys, name) + sizeof(uintptr_t) && \
    (s)->system->table->name != 0)
#define R4_STORAGE_CALL(s, name, type, ...) (R4_STORAGE_HAS(s, name) ? \
    ((type)(uintptr_t)(s)->system->table->name)(__VA_ARGS__) : R4OS_STORAGE_ERROR_UNSUPPORTED)

static inline int r4_storage_available(const R4Storage *s) {
    return R4_STORAGE_HAS(s, storage_inventory) && R4_STORAGE_HAS(s, storage_claim_begin) &&
        R4_STORAGE_HAS(s, storage_use_begin) && R4_STORAGE_HAS(s, storage_use_end);
}

static inline int32_t r4_storage_inventory(R4Storage *s, R4StorageInventory *out) {
    if (!out) return R4OS_STORAGE_ERROR_INVALID;
    R4StorageInventory value = {0}; value.version = 1; value.size = sizeof(value); *out = value;
    return R4_STORAGE_CALL(s, storage_inventory, R4SysStorageInventoryFn, out);
}

static inline int32_t r4_storage_device(R4Storage *s, uint64_t generation, uint32_t slot, R4StorageDeviceInfo *out) {
    if (!out) return R4OS_STORAGE_ERROR_INVALID;
    R4StorageDeviceInfo value = {0}; value.version = 1; value.size = sizeof(value); *out = value;
    return R4_STORAGE_CALL(s, storage_device, R4SysStorageDeviceFn, generation, slot, out);
}

static inline int32_t r4_storage_partition(R4Storage *s, uint64_t generation, const R4StorageDeviceRef *device, uint32_t slot, R4StoragePartitionInfo *out) {
    if (!out) return R4OS_STORAGE_ERROR_INVALID;
    R4StoragePartitionInfo value = {0}; value.version = 1; value.size = sizeof(value); *out = value;
    return R4_STORAGE_CALL(s, storage_partition, R4SysStoragePartitionFn, generation, device, slot, out);
}

static inline int32_t r4_storage_volume(R4Storage *s, uint64_t generation, uint32_t slot, R4StorageVolumeInfo *out) {
    if (!out) return R4OS_STORAGE_ERROR_INVALID;
    R4StorageVolumeInfo value = {0}; value.version = 1; value.size = sizeof(value); *out = value;
    return R4_STORAGE_CALL(s, storage_volume, R4SysStorageVolumeFn, generation, slot, out);
}

static inline R4StorageTarget r4_storage_whole_device(const R4StorageDeviceInfo *disk) {
    R4StorageTarget target = {0}; target.version = 1; target.size = sizeof(target);
    if (disk) { target.device = disk->reference; target.layout_generation = disk->layout_generation;
        target.sector_count = disk->sector_count; target.kind = R4OS_STORAGE_TARGET_DEVICE; }
    return target;
}
static inline int32_t r4_storage_claim_begin(R4Storage *s, const R4StorageTarget *target, uint64_t *claim) {
    if (!target || !claim) return R4OS_STORAGE_ERROR_INVALID;
    *claim = 0; return R4_STORAGE_CALL(s, storage_claim_begin, R4SysStorageClaimBeginFn, target, claim);
}
/* BUSY retains the handle; a completed I/O/remount failure consumes it. */
static inline int32_t r4_storage_claim_end(R4Storage *s, uint64_t *claim, int keep_unmounted) {
    if (!claim) return R4OS_STORAGE_ERROR_INVALID;
    int32_t result = R4_STORAGE_CALL(s, storage_claim_end, R4SysStorageClaimEndFn, *claim,
        keep_unmounted ? R4OS_STORAGE_CLAIM_END_KEEP_UNMOUNTED : 0);
    if (result == R4OS_STORAGE_RESULT_OK || result == R4OS_STORAGE_ERROR_IO || result == R4OS_STORAGE_ERROR_REMOUNT) *claim = 0;
    return result;
}

static inline int32_t r4_storage_read(R4Storage *s, const R4StorageTarget *target, uint64_t relative_lba, uint8_t *buffer, uint32_t bytes) {
    if (!buffer || !target || !bytes || bytes % 512 || bytes / 512 > R4OS_STORAGE_RAW_MAX_SECTORS) return R4OS_STORAGE_ERROR_INVALID;
    return R4_STORAGE_CALL(s, storage_read, R4SysStorageReadFn, target, relative_lba, bytes / 512, buffer, bytes);
}

static inline int32_t r4_storage_claim_read(R4Storage *s, uint64_t claim, uint64_t relative_lba, uint8_t *buffer, uint32_t bytes) {
    if (!buffer || !claim || !bytes || bytes % 512 || bytes / 512 > R4OS_STORAGE_RAW_MAX_SECTORS) return R4OS_STORAGE_ERROR_INVALID;
    return R4_STORAGE_CALL(s, storage_claim_read, R4SysStorageClaimReadFn, claim, relative_lba, bytes / 512, buffer, bytes);
}

static inline int32_t r4_storage_claim_write(R4Storage *s, uint64_t claim, uint64_t relative_lba, const uint8_t *buffer, uint32_t bytes) {
    if (!buffer || !claim || !bytes || bytes % 512 || bytes / 512 > R4OS_STORAGE_RAW_MAX_SECTORS) return R4OS_STORAGE_ERROR_INVALID;
    return R4_STORAGE_CALL(s, storage_claim_write, R4SysStorageClaimWriteFn, claim, relative_lba, bytes / 512, buffer, bytes);
}

static inline int32_t r4_storage_claim_flush(R4Storage *s, uint64_t claim) {
    return R4_STORAGE_CALL(s, storage_claim_flush, R4SysStorageClaimFlushFn, claim);
}
static inline int32_t r4_storage_rescan(R4Storage *s, const R4StorageDeviceRef *device) {
    if (!device) return R4OS_STORAGE_ERROR_INVALID;
    return R4_STORAGE_CALL(s, storage_rescan, R4SysStorageRescanFn, device);
}
static inline int32_t r4_storage_mount(R4Storage *s, const R4StorageTarget *target, uint8_t letter, R4StorageVolumeRef *out) {
    if (!target || !out) return R4OS_STORAGE_ERROR_INVALID;
    R4StorageVolumeRef empty = {0}; *out = empty;
    return R4_STORAGE_CALL(s, storage_mount, R4SysStorageMountFn, target, letter, out);
}
static inline int32_t r4_storage_unmount(R4Storage *s, const R4StorageVolumeRef *volume) {
    if (!volume) return R4OS_STORAGE_ERROR_INVALID;
    return R4_STORAGE_CALL(s, storage_unmount, R4SysStorageUnmountFn, volume);
}
static inline int32_t r4_storage_use_begin(R4Storage *s, const uint8_t *path, uint64_t *use) {
    if (!path || !use) return R4OS_STORAGE_ERROR_INVALID;
    *use = 0; return R4_STORAGE_CALL(s, storage_use_begin, R4SysStorageUseBeginFn, path, use);
}
static inline int32_t r4_storage_use_end(R4Storage *s, uint64_t *use) {
    if (!use) return R4OS_STORAGE_ERROR_INVALID;
    if (!*use) return R4OS_STORAGE_RESULT_OK;
    int32_t result = R4_STORAGE_CALL(s, storage_use_end, R4SysStorageUseEndFn, *use);
    if (result == R4OS_STORAGE_RESULT_OK) *use = 0;
    return result;
}
static inline int32_t r4_storage_transfer_use_begin(R4Storage *s, const uint8_t *path, uint64_t *use) {
    if (!path || !use) return R4OS_STORAGE_ERROR_INVALID;
    if (!R4_STORAGE_HAS(s, storage_use_begin) && !R4_STORAGE_HAS(s, storage_claim_begin)) { *use = 0; return R4OS_STORAGE_RESULT_OK; }
    return r4_storage_use_begin(s, path, use);
}
#undef R4_STORAGE_CALL
#undef R4_STORAGE_HAS
#endif
