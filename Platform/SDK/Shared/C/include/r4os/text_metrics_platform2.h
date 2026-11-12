#ifndef R4OS_TEXT_METRICS_PLATFORM2_H
#define R4OS_TEXT_METRICS_PLATFORM2_H
/* Inline Query2 bindings remain outside facades.h: no unbacked externs. */
#include "platform2.h"
#include "text_metrics.h"
static inline int32_t R4SdkTextMetricsProvider2(const R4OS2Context *context,R4SdkTextMetricsProvider *out){
 if(!out)return R4_TEXT_METRICS_INVALID_STATE;
 uint64_t address=0;int32_t rc=R4OS2ContextFunction(context,3,offsetof(R4XStartR4Draw2,font_prefix_metrics2),&address);
 if(rc)return rc;
 out->measure=(R4DrawFontPrefixMetrics2Fn)(uintptr_t)address;return 0;
}
static inline int32_t R4SdkTextMetricsValidateFont2(const R4OS2Context *context,R4SdkTextMetrics *cache){
 R4SdkTextMetricsKey key;int32_t rc=R4SdkTextMetricsGetKey(cache,&key);if(rc)return rc;
 R4SdkTextMetricsProvider provider;rc=R4SdkTextMetricsProvider2(context,&provider);
 if(rc){int32_t reset=R4SdkTextMetricsReset(cache);return reset?reset:rc;}
 R4FontAdvanceInfo2 info={0};rc=provider.measure(key.font_id,0,0,0,0,&info);
 if(!rc&&(info.version!=R4OS_FONT_METRICS2_VERSION||info.size!=sizeof(info)||info.font_id!=key.font_id||!info.font_revision||info.text_bytes||info.count||info.required_count||info.flags!=R4OS_FONT_METRICS2_FLAG_COMPLETE||info.reserved0))rc=R4_TEXT_METRICS_INVALID_PROVIDER;
 if(!rc&&info.font_revision!=key.font_revision)rc=R4_TEXT_METRICS_STALE;
 if(rc){int32_t reset=R4SdkTextMetricsReset(cache);if(reset)return reset;}
 return rc;
}
#endif
