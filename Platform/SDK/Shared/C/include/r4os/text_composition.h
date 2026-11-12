#ifndef R4OS_TEXT_COMPOSITION_H
#define R4OS_TEXT_COMPOSITION_H
#include "wire_helpers.h"
/* One editor-thread owner. Fields are private. A new storage incarnation
 * requires a nonzero never-reused owner_generation within this full window.
 * Do not copy/reinitialize live state. No document/event/provider pointers
 * survive a call. Preedit view borrows initialized state bytes only until
 * the next mutation. Acquire current focus/provider outside GUI/text locks;
 * apply pure transitions on the editor owner. No wait/callback/implicit Drop.
 * Ranges are whole pinned R4STD graphemes in strict UTF8/noNUL. Document<=64KB,
 * event/surrounding<=1024bytes; Capacity is whole-or-error. Only valid Commit
 * changes document/length/revision. Scope loss cancels only old local state.
 * The ABI transports scalars and pointers to copied input records. Inputs
 * are borrowed through actual return, stable and disjoint from mutable
 * state/document/output/length/revision. No input record pointer is retained.
 * All mapped state/document/output/length/revision/event ranges are disjoint.
 * Event text may alias document (it is staged before commit). Surrounding
 * output is disjoint from document; it cannot silently edit source bytes. */
typedef struct R4SdkComposition {
 uint64_t stamp;R4CompositionId id;R4Utf8ByteRange replacement,selection;
 R4CompositionCaret caret;R4CompositionProvider provider;
 uint64_t revision,sequence,next_generation,owner_generation;
 uint32_t phase,preedit_bytes;uint8_t data[1024];
} R4SdkComposition;
int32_t R4SdkCompositionInit(uint64_t,R4SdkComposition *);
int32_t R4SdkCompositionBegin(R4SdkComposition *,const R4CompositionFocus *,const R4CompositionProvider *,uint64_t,const R4SdkWireSpan *,const R4Utf8ByteRange *,const R4CompositionCaret *,R4CompositionId *);
int32_t R4SdkCompositionRefresh(R4SdkComposition *,const R4CompositionFocus *,const R4CompositionProvider *,uint64_t);
int32_t R4SdkCompositionApply(R4SdkComposition *,const R4CompositionFocus *,const R4CompositionProvider *,const R4CompositionEvent *,const R4SdkWireSpan *,const R4SdkWireSpan *,uint64_t *,uint64_t *);
int32_t R4SdkCompositionCancel(R4SdkComposition *,const R4CompositionId *);
int32_t R4SdkCompositionPreedit(const R4SdkComposition *,R4SdkWireSpan *);
int32_t R4SdkCompositionCaret(R4SdkComposition *,const R4CompositionFocus *,const R4CompositionProvider *,uint64_t,R4CompositionCaret *);
int32_t R4SdkCompositionSetCaret(R4SdkComposition *,const R4CompositionFocus *,const R4CompositionProvider *,uint64_t,const R4CompositionCaret *);
int32_t R4SdkCompositionSurrounding(R4SdkComposition *,const R4CompositionFocus *,const R4CompositionProvider *,uint64_t,const R4SdkWireSpan *,const R4Utf8ByteRange *,const R4SdkWireSpan *,uint64_t *);
_Static_assert(sizeof(R4SdkComposition)==1288u,"composition owner");
_Static_assert(_Alignof(R4SdkComposition)==8u,"composition owner alignment");
_Static_assert(offsetof(R4SdkComposition,data)==264u,"composition initialized text");
#endif
