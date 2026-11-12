#ifndef R4OS_AUDIO_WRITE_H
#define R4OS_AUDIO_WRITE_H
#include "gui_bridge.h"
#include "stream_transfer.h"
/* Borrow the real compiler-typed stream, or exact native callbacks and
 * caller-owned handles. All source/state/output/stream objects are separate,
 * mapped, exclusively owned through actual synchronous return. No close or
 * concurrent stream call during this loan. No pointer to state is retained.
 * legacy!=NULL, frame_bytes=0 derives the actual stream frame width. */
typedef struct R4SdkAudioWriterProvider {
 R4SdkAudioAudioStream *legacy;
 R4SysServiceCallFn call;
 R4SysMonotonicClockFn monotonic;
 uint32_t service_handle,stream_id,frame_bytes,reserved0;
} R4SdkAudioWriterProvider;
typedef struct R4SdkAudioWriteProgress {
 R4SdkTransferProgress io;
 uint64_t accepted_frames;
 uint32_t last_frames,frame_bytes,last_service_flags,service_flags_valid;
} R4SdkAudioWriteProgress;
typedef struct R4SdkAudioWriter {
 R4SdkTransfer io;
 R4SdkWireSpan source;
 R4SdkAudioWriterProvider provider;
 uint32_t last_service_flags,service_flags_valid;
} R4SdkAudioWriter;
enum {R4_AUDIO_WRITE_INVALID=-301,R4_AUDIO_WRITE_BUFFER=-302,
 R4_AUDIO_WRITE_FRAME=-303,R4_AUDIO_WRITE_STREAM_CLOSED=-304};
int32_t R4SdkAudioWriterInit(R4SdkWireSpan,R4SdkAudioWriterProvider,R4Timeout,R4SdkAudioWriter *);
int32_t R4SdkAudioWriterGetProgress(const R4SdkAudioWriter *,R4SdkAudioWriteProgress *);
int32_t R4SdkAudioWriterStep(R4SdkAudioWriter *,uint32_t,uint32_t,R4SdkAudioWriteProgress *);
int32_t R4SdkAudioWriterCancel(R4SdkAudioWriter *,R4SdkAudioWriteProgress *);
/* Step admits 1..64 RPCs, continuing only on acknowledged progress. Poll
 * admits one RPC; finite uses one absolute deadline and requested logical
 * tick rate. Busy yields immediately. Unknown effects/invalid replies are
 * terminal UNCERTAIN: retain the confirmed PCM prefix, never auto-replay.
 * Cancellation retains an active loan until actual return. Accepted PCM and
 * last observed AUDSVC flags are no hardware/DMA/audible completion receipt.
 * Backend presence flags: 1 backend,2 mixer,4 sessions,8 ready,16 no duration.
 * The admitted synchronous RPC may return after the deadline. */
_Static_assert(sizeof(R4SdkAudioWriterProvider)==40u,"audio provider");
_Static_assert(sizeof(R4SdkAudioWriteProgress)==56u,"audio progress");
_Static_assert(sizeof(R4SdkAudioWriter)==152u,"audio writer");
#endif
