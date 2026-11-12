#ifndef R4OS_TEXT_METRICS_H
#define R4OS_TEXT_METRICS_H
#include "wire_helpers.h"
/* Single shared SDK owner. Source, state, complete storage and output records
 * are disjoint mapped ranges, immutable where borrowed for a valid view.
 * Provider code and all actual-call loans outlive synchronous return.
 * State fields are private; only progress/view/key grant cache authority. */
enum { R4_TEXT_METRICS_COMPLETE=1,R4_TEXT_METRICS_IN_CALL=2 };
enum { R4_TEXT_METRICS_INVALID_STATE=-101,R4_TEXT_METRICS_INVALID_STORAGE=-102,
       R4_TEXT_METRICS_BUSY=-103,R4_TEXT_METRICS_INCOMPLETE=-104,
       R4_TEXT_METRICS_INVALID_PROVIDER=-105,R4_TEXT_METRICS_STALE=-10 };
typedef struct R4SdkTextMetricsProvider { R4DrawFontPrefixMetrics2Fn measure; } R4SdkTextMetricsProvider;
typedef struct R4SdkTextMetricsKey {
    uint64_t source_address,text_revision,font_revision;uint32_t font_id,text_bytes;
} R4SdkTextMetricsKey;
typedef struct R4SdkTextMetricsProgress {
    R4SdkTextMetricsKey key;uint32_t required_count,count,flags;int32_t error_code;
} R4SdkTextMetricsProgress;
typedef struct R4SdkTextMetrics {
    R4FontAdvanceInfo2 native_info;R4SdkWireSpan source,storage;
    R4SdkTextMetricsProvider provider;uint64_t text_revision;
    uint32_t capacity,count,phase,busy;int32_t error_code;uint32_t reserved0;
} R4SdkTextMetrics;
int32_t R4SdkTextMetricsInit(R4SdkWireSpan,R4SdkWireSpan,uint32_t,R4SdkTextMetricsProvider,R4SdkTextMetrics *);
int32_t R4SdkTextMetricsPrepare(R4SdkTextMetrics *,uint64_t,uint32_t,R4SdkTextMetricsProgress *);
int32_t R4SdkTextMetricsGetProgress(const R4SdkTextMetrics *,R4SdkTextMetricsProgress *);
int32_t R4SdkTextMetricsGetKey(const R4SdkTextMetrics *,R4SdkTextMetricsKey *);
int32_t R4SdkTextMetricsGetView(const R4SdkTextMetrics *,R4SdkWireSpan *);
int32_t R4SdkTextMetricsHit(const R4SdkTextMetrics *,R4SdkTextMetricsKey,int32_t,uint32_t *);
int32_t R4SdkTextMetricsReset(R4SdkTextMetrics *);
/* Init captures nothing. Prepare invalidates former views and calls the
 * provider once, then projects whole scalar-prefix rows to grapheme rows in
 * place. required_count is SCALAR storage capacity, count is final GRAPHEMES.
 * native_info is private preprojection metadata, not a raw scalar-row view.
 * Capacity/encoding/failure never publish a usable partial cache. Full source
 * UTF8 bytes<=4096, no NUL; capacity<=4096 whole FontAdvance2 rows.
 * Source address/length + nonreused caller text revision + exact font ID/bank
 * revision bind the key. No content hash or globally unique allocation ID.
 * Text and rows remain immutable until actual end of every borrowed view;
 * text change needs discarded views and explicit reinitialization.
 * Prepared key/view/hit/progress do no provider call, text copy or full scan.
 * Hit is O(log n), exact original strict-half ties and x<=0 behavior. It is a
 * FROZEN observation, not a current-font/render-completion promise. A fresh
 * checked stamp detects a later font publication; use the Query2 adapter.
 * Reset discards only the logical SDK cache, no Kernel resource or physical
 * stop. Busy cannot end an active provider/storage/code loan prematurely. */
_Static_assert(sizeof(R4SdkTextMetricsProvider)==8u,"text metrics provider");
_Static_assert(sizeof(R4SdkTextMetricsKey)==32u,"text metrics key");
_Static_assert(sizeof(R4SdkTextMetricsProgress)==48u,"text metrics progress");
_Static_assert(sizeof(R4SdkTextMetrics)==112u,"text metrics state");
_Static_assert(offsetof(R4SdkTextMetrics,provider)==72u,"text metrics provider offset");
_Static_assert(offsetof(R4SdkTextMetrics,busy)==100u,"text metrics busy offset");
#endif
