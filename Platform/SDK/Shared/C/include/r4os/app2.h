#ifndef R4OS_APP2_H
#define R4OS_APP2_H
#include <r4os/platform2.h>
#include <r4os/app_memory.h>
#include <r4os/app_contract.h>
#include <r4os/inventory_platform2.h>
#include <r4os/device_snapshot_platform2.h>
#include <r4os/text_metrics_platform2.h>
#include <r4os/file_picker_platform2.h>
#include <r4os/clipboard_offer_platform2.h>
#include <r4os/text_composition_platform2.h>

/* SDK-private callback input to the existing module heap. This is not a
 * platform table or another allocator. Bind2 copies it into module storage. */
typedef struct {
    const char *module_name, *symbol_name;
    uint32_t minimum, optional, group_id, reserved;
} R4App2Import;
typedef struct {
    uint32_t profile, app_class, required_groups, import_count;
    const R4App2Import *imports;
} R4App2StartupInfo;
typedef struct {
    R4OS2Context context;
    R4App2Memory memory;
    uint32_t profile;
} R4App2;
static inline int32_t r4_app2_facade(const R4App2 *app, R4App *out) {
    return app ? r4_app_init2(&app->context, &app->memory, out) : R4OS_ERROR_INVALID;
}
static inline int32_t r4_app2_system(const R4App2 *app, R4Sys *out) {
    return app ? r4sys_init2(&app->context, &app->memory, out) : R4OS_ERROR_INVALID;
}
static inline int32_t r4_app2_inventory_provider(const R4App2 *app, uint32_t mode, R4SdkInventoryProvider *out) {
    return app ? R4SdkInventoryProvider2(&app->context, mode, out) : R4OS_ERROR_INVALID;
}
static inline int32_t r4_app2_device_snapshot_provider(const R4App2 *app, R4SdkDeviceSnapshotProvider *out) {
    return app ? R4SdkDeviceSnapshotProvider2(&app->context, out) : R4OS_ERROR_INVALID;
}
static inline int32_t r4_app2_clock(const R4App2 *app, R4SdkTransferPlatformClock *out) {
    return app ? R4SdkTransferClock2(&app->context, out) : R4OS_ERROR_INVALID;
}
static inline int32_t r4_app2_text_metrics_provider(const R4App2 *app, R4SdkTextMetricsProvider *out) {
    return app ? R4SdkTextMetricsProvider2(&app->context, out) : R4OS_ERROR_INVALID;
}
static inline int32_t r4_app2_file_picker_provider(const R4App2 *app, R4SdkFilePickerProvider *out) {
    return app ? R4SdkFilePickerProvider2(&app->context, out) : R4OS_ERROR_INVALID;
}
static inline int32_t r4_app2_clipboard_offers(const R4App2 *app, R4SdkClipboardOffers *out) {
    return app ? R4SdkClipboardOffersConnect(&app->context, out) : R4OS_ERROR_INVALID;
}
static inline int32_t r4_app2_composition_client(const R4App2 *app, uint64_t timeout, R4SdkCompositionClient *out) {
    return app ? R4SdkCompositionConnect2(&app->context, timeout, out) : R4OS_ERROR_INVALID;
}
_Static_assert(sizeof(R4App2Memory) == 128, "SDK heap input2");
_Static_assert(sizeof(R4App2Import) == 32 && sizeof(R4App2StartupInfo) == 24, "SDK startup2 facts");

int32_t R4SdkApp2Init(const R4XStartContext2 *, const R4App2StartupInfo *, R4App2Memory *);
/* Explicit helper scope for a raw entry; no global allocator is installed. */
int32_t R4SdkApp2InitRaw(const R4XStartContext2 *, R4App2Memory *);

static inline int32_t r4_app2_init(const R4XStartContext2 *raw, const R4App2StartupInfo *info, R4App2 *out) {
    if (!out) return -12;
    R4App2 candidate;
    int32_t rc = R4SdkApp2Init(raw, info, &candidate.memory);
    if (rc < 0) return rc;
    if (R4OS2ContextInit(raw, &candidate.context) != R4OS2_CONTEXT_OK) return -12;
    candidate.profile = info->profile;
    *out = candidate;
    return 0;
}
static inline int32_t r4_app2_function(const R4App2 *app, uint32_t group, uint32_t offset, uint64_t *out) {
    if (!app) return R4OS_ERR_NO_GROUP;
    return R4OS2ContextFunction(&app->context, group, offset, out);
}
static inline int32_t r4_app2_write(const R4App2 *app, const uint8_t *data, uint32_t length) {
    uint64_t address;
    int32_t rc = r4_app2_function(app, 1, offsetof(R4XStartR4Sys2, write), &address);
    return rc < 0 ? rc : ((int32_t (*)(const uint8_t *, uint32_t))(uintptr_t)address)(data, length);
}
static inline const uint8_t *r4_app2_args(const R4App2 *app, uint64_t *length) {
    return app ? R4OS2ContextArgs(&app->context, length) : NULL;
}
static inline uint32_t r4_app2_should_close(const R4App2 *app) {
    return app ? R4OS2ContextShouldClose(&app->context) : 1;
}
static inline uint32_t r4_app2_yield(const R4App2 *app) {
    return app ? R4OS2ContextYield(&app->context) : 0;
}
static inline int32_t r4_app2_heap_bind(const R4App2 *app) {
    return app ? R4SdkHeapBind2(&app->memory, app->context.raw->instance_id) : -1;
}
/* All heap users and callbacks must be quiescent before Finish2. Busy/pending
 * retain the exact ownership and must not be translated into success. */
static inline void *r4_app2_alloc(const R4App2 *app, size_t size, size_t alignment) {
    if (r4_app2_heap_bind(app) != 0) return NULL;
    return R4SdkHeapAlloc2(&app->memory, app->context.raw->instance_id, size, alignment);
}
static inline int32_t r4_app2_free(const R4App2 *app, void *pointer) {
    return app ? R4SdkHeapFree2(&app->memory, app->context.raw->instance_id, pointer) : -1;
}
#endif
