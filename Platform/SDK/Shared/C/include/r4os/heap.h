#ifndef R4OS_HEAP_H
#define R4OS_HEAP_H
#include "r4sys.h"

/* One pooled heap per R4X image/instance. Kernel VM/task ownership remains
 * authoritative. These helpers are not a shared R4L-global allocator. */
typedef struct R4Heap {
    const R4XStartR4Sys *api;
    uint64_t instance;
    const R4App2Memory *memory2;
} R4Heap;
typedef struct R4HeapStats {
    uint64_t values[64];
    uint32_t count;
} R4HeapStats;

int32_t R4SdkHeapBind(const R4XStartR4Sys *, uint64_t);
void *R4SdkHeapAlloc(const R4XStartR4Sys *, uint64_t, uintptr_t, uintptr_t);
void *R4SdkHeapRealloc(const R4XStartR4Sys *, uint64_t, void *, uintptr_t, uintptr_t);
int32_t R4SdkHeapFree(const R4XStartR4Sys *, uint64_t, void *);
int32_t R4SdkHeapStats(const R4XStartR4Sys *, uint64_t, uint64_t *, uint32_t);
const char *R4SdkHeapStatName(uint32_t);
int32_t R4SdkHeapFinish(const R4XStartR4Sys *, uint64_t);

static inline int32_t r4_heap_init(const R4Sys *sys, R4Heap *out) {
    if (!out) return -1;
    *out = (R4Heap){0};
    if (sys && sys->generation2) {
        if (!sys->memory2 || !sys->generation2->raw) return -1;
        const uint64_t owner = sys->generation2->raw->instance_id;
        const int32_t rc = R4SdkHeapBind2(sys->memory2, owner);
        if (rc != 0) return rc;
        *out = (R4Heap){.api = NULL, .instance = owner, .memory2 = sys->memory2};
        return 0;
    }
    if (!sys || !sys->table || !sys->ctx) return -1;
    int32_t rc = R4SdkHeapBind(sys->table, sys->ctx->instance_id);
    if (rc != 0) return rc;
    *out = (R4Heap){.api = sys->table, .instance = sys->ctx->instance_id, .memory2 = NULL};
    return 0;
}
static inline void *r4_heap_alloc(const R4Heap *heap, uintptr_t size, uintptr_t alignment) {
    if (heap && heap->memory2) return R4SdkHeapAlloc2(heap->memory2, heap->instance, size, alignment);
    return heap && heap->api ? R4SdkHeapAlloc(heap->api,heap->instance,size,alignment) : 0;
}
static inline void *r4_heap_malloc(const R4Heap *heap, uintptr_t size) {
    return r4_heap_alloc(heap,size,_Alignof(max_align_t));
}
static inline void *r4_heap_calloc(const R4Heap *heap, uintptr_t count, uintptr_t size) {
    if (count && size > UINTPTR_MAX / count) return 0;
    uintptr_t bytes = count * size;
    uint8_t *p = (uint8_t *)r4_heap_malloc(heap,bytes);
    if (p) for (uintptr_t i=0; i<bytes; ++i) p[i]=0;
    return p;
}
/* NULL on growth failure preserves the original allocation. size=0 frees;
 * alignment changes may move the buffer, retaining min(old,new) bytes. */
static inline void *r4_heap_realloc(const R4Heap *heap, void *p, uintptr_t size, uintptr_t alignment) {
    if (heap && heap->memory2) return R4SdkHeapRealloc2(heap->memory2, heap->instance, p, size, alignment);
    return heap && heap->api ? R4SdkHeapRealloc(heap->api,heap->instance,p,size,alignment) : 0;
}
static inline int32_t r4_heap_free(const R4Heap *heap, void *p) {
    if (!p) return 0;
    if (heap && heap->memory2) return R4SdkHeapFree2(heap->memory2, heap->instance, p);
    return heap && heap->api ? R4SdkHeapFree(heap->api,heap->instance,p) : -1;
}
static inline int32_t r4_heap_stats(const R4Heap *heap, R4HeapStats *out) {
    if (!out || !heap || (!heap->api && !heap->memory2)) return -1;
    *out = (R4HeapStats){0};
    int32_t count = heap->memory2 ? R4SdkHeapStats2(heap->memory2,heap->instance,out->values,64) : R4SdkHeapStats(heap->api,heap->instance,out->values,64);
    if (count < 0) return count;
    out->count = (uint32_t)count;
    return 0;
}
static inline int r4_heap_stat(const R4HeapStats *stats, const char *name, uint64_t *out) {
    if (!stats || !name || !out) return 0;
    for (uint32_t i=0; i<stats->count; ++i) {
        const char *field = R4SdkHeapStatName(i);
        if (!field) return 0;
        uintptr_t n=0;
        while (field[n] && field[n]==name[n]) ++n;
        if (!field[n] && !name[n]) {*out=stats->values[i];return 1;}
    }
    return 0;
}
/* Irreversibly closes allocation admission. Join every allocator user first;
 * live allocations may still be freed before retrying. 0 = all exact region
 * and notification releases acknowledged; 1 = busy/live; 2 = VM release
 * pending. Failed/partial releases retain their value identities for retry.
 * Do not call automatically at root return while threads may still execute. */
static inline int32_t r4_heap_finish(const R4Heap *heap) {
    if (heap && heap->memory2) return R4SdkHeapFinish2(heap->memory2, heap->instance);
    return heap && heap->api ? R4SdkHeapFinish(heap->api,heap->instance) : -1;
}
#endif
