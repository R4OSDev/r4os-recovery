#include <stdint.h>
#include <stdio.h>
#include "clc7b7.h"
#include "clc9b7.h"
#include "class/clc56f.h"
#define BIT(field) (1U << (0 ? field))
#define INCR(method,count) (0x20000000U|((count)<<16)|((method)/4))
#define ADDRESS(index) (0x1000000U+(index)*0x20000U)
#define EMIT(N) static int emit_##N(FILE*f){ \
 uint32_t w[61]={0}; \
 w[0]=INCR(NVC56F_SET_OBJECT,1);w[1]=N##_VIDEO_ENCODER|(NVC56F_SET_OBJECT_ENGINE_SW<<(0?NVC56F_SET_OBJECT_ENGINE)); \
 w[2]=INCR(N##_SET_APPLICATION_ID,2);w[3]=N##_SET_APPLICATION_ID_ID_NVENC_H264;w[4]=500000000; \
 w[5]=INCR(N##_SET_IN_REF_PIC0_LUMA,16);w[6]=ADDRESS(9); \
 w[22]=INCR(N##_SET_IN_REF_PIC0_CHROMA,16);w[23]=ADDRESS(9); \
 w[39]=INCR(N##_SET_CONTROL_PARAMS,14); \
 w[40]=N##_SET_CONTROL_PARAMS_CODEC_TYPE_H264|BIT(N##_SET_CONTROL_PARAMS_FORCE_OUT_PIC)|BIT(N##_SET_CONTROL_PARAMS_FORCE_OUT_COL)|BIT(N##_SET_CONTROL_PARAMS_SLICE_STAT_ON)|BIT(N##_SET_CONTROL_PARAMS_GPTIMER_ON)|BIT(N##_SET_CONTROL_PARAMS_DUMP_CYCLE_COUNT); \
 w[41]=0x12345678;w[44]=ADDRESS(0);w[46]=ADDRESS(1);w[47]=ADDRESS(3);w[48]=ADDRESS(2); \
 w[50]=ADDRESS(11);w[51]=ADDRESS(8);w[52]=ADDRESS(6);w[53]=ADDRESS(4); \
 w[54]=INCR(N##_SET_IN_CUR_PIC_CHROMA_U,4);w[55]=w[56]=ADDRESS(4);w[58]=ADDRESS(6); \
 w[59]=INCR(N##_EXECUTE,1); \
 return fwrite(w,1,sizeof w,f)==sizeof w; }
_Static_assert(NVC7B7_SET_WATCHDOG_TIMER==NVC7B7_SET_APPLICATION_ID+4,"C7 watchdog follows application");
_Static_assert(NVC9B7_SET_WATCHDOG_TIMER==NVC9B7_SET_APPLICATION_ID+4,"C9 watchdog follows application");
_Static_assert(NVC7B7_SET_IN_MEPRED_DATA==0x738&&NVC7B7_SET_OUT_MEPRED_DATA==0x73c,"C7 omitted optional methods");
_Static_assert(NVC9B7_SET_IN_MEPRED_DATA==0x738&&NVC9B7_SET_OUT_MEPRED_DATA==0x73c,"C9 omitted optional methods");
EMIT(NVC7B7)
EMIT(NVC9B7)
int main(int argc,char**argv){
 if(argc!=2)return 1;FILE*f=fopen(argv[1],"wb");if(!f)return 2;
 int ok=emit_NVC7B7(f)&&emit_NVC9B7(f);if(fclose(f))return 3;return ok?0:4;
}
