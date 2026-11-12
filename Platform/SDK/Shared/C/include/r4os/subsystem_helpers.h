/* Compiler-generated SDK data helper boundary. Do not edit.
 * Private objects are native storage: use MaybeUninit in Rust. Never read
 * their bytes or assume padding initialized. Initialize all required fields
 * through the typed constructor before use. Borrowed strings/arrays/contexts
 * must outlive every referencing object. Stateful contexts/frames stay at
 * their exact address; inspect native status before release/reuse. Raw field
 * mutation requires preservation of the original owner's invariants.
 * Slot.status is transport status; bits retain native scalar return values,
 * including negative i32. PRESENT marks optional payloads, NATIVE_ERROR
 * exposes a resident error-name view. A returned view borrows its inputs or
 * exact native owner. Float values cross only through pointers. */
#ifndef R4SDKSUBSYSTEM_HELPERS_H
#define R4SDKSUBSYSTEM_HELPERS_H
#include "r4os/abi.h"
#define R4SDKSUBSYSTEM_PRESENT 1u
#define R4SDKSUBSYSTEM_NATIVE_ERROR 2u
#define R4SDKSUBSYSTEM_DEFAULT 4u
typedef struct R4SdkSubsystemSlot { void *ptr; uint64_t length,bits; int32_t status; uint32_t flags; } R4SdkSubsystemSlot;
R4SdkSubsystemSlot R4SdkSubsystemInvoke(uint64_t,uint32_t,const R4SdkSubsystemSlot *,uint32_t,void *);
R4SdkSubsystemSlot R4SdkSubsystemConstruct(uint64_t,uint32_t,const R4SdkSubsystemSlot *,uint32_t,void *);
R4SdkSubsystemSlot R4SdkSubsystemInspect(uint64_t,uint32_t,void *,void *);
R4SdkSubsystemSlot R4SdkSubsystemField(uint64_t,uint32_t,uint32_t,void *,const R4SdkSubsystemSlot *,void *);
/* subsystem_catalog.HostState; native size 1, alignment 1. */
typedef struct R4SdkSubsystemCatalogHostState { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemCatalogHostState;
#define R4SdkSubsystemCatalogHostState_TYPE 0u
/* subsystem_catalog.HostVerifier; native size 16, alignment 8. */
typedef struct R4SdkSubsystemCatalogHostVerifier { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemCatalogHostVerifier;
#define R4SdkSubsystemCatalogHostVerifier_TYPE 1u
/* subsystem_catalog.Entry; native size 128, alignment 8. */
typedef struct R4SdkSubsystemCatalogEntry { _Alignas(8) uint8_t opaque_bytes[128]; } R4SdkSubsystemCatalogEntry;
#define R4SdkSubsystemCatalogEntry_TYPE 4u
/* subsystem_catalog.Catalog; native size 24592, alignment 8. */
typedef struct R4SdkSubsystemCatalogCatalog { _Alignas(8) uint8_t opaque_bytes[24592]; } R4SdkSubsystemCatalogCatalog;
#define R4SdkSubsystemCatalogCatalog_TYPE 6u
/* [192]subsystem_catalog.Entry; native size 24576, alignment 8. */
typedef struct R4SdkSubsystemNativeValue8 { _Alignas(8) uint8_t opaque_bytes[24576]; } R4SdkSubsystemNativeValue8;
#define R4SdkSubsystemNativeValue8_TYPE 8u
/* subsystem_catalog.Association; native size 48, alignment 8. */
typedef struct R4SdkSubsystemCatalogAssociation { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemCatalogAssociation;
#define R4SdkSubsystemCatalogAssociation_TYPE 9u
/* subsystem_catalog.Policy; native size 32, alignment 8. */
typedef struct R4SdkSubsystemCatalogPolicy { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkSubsystemCatalogPolicy;
#define R4SdkSubsystemCatalogPolicy_TYPE 10u
/* []const subsystem_catalog.Association; native size 16, alignment 8. */
typedef struct R4SdkSubsystemNativeValue11 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemNativeValue11;
#define R4SdkSubsystemNativeValue11_TYPE 11u
/* subsystem_catalog.Input; native size 48, alignment 8. */
typedef struct R4SdkSubsystemCatalogInput { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemCatalogInput;
#define R4SdkSubsystemCatalogInput_TYPE 12u
/* subsystem_catalog.Evidence; native size 1, alignment 1. */
typedef struct R4SdkSubsystemCatalogEvidence { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemCatalogEvidence;
#define R4SdkSubsystemCatalogEvidence_TYPE 13u
/* subsystem_catalog.Candidate; native size 88, alignment 8. */
typedef struct R4SdkSubsystemCatalogCandidate { _Alignas(8) uint8_t opaque_bytes[88]; } R4SdkSubsystemCatalogCandidate;
#define R4SdkSubsystemCatalogCandidate_TYPE 14u
/* subsystem_catalog.ResolutionState; native size 1, alignment 1. */
typedef struct R4SdkSubsystemCatalogResolutionState { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemCatalogResolutionState;
#define R4SdkSubsystemCatalogResolutionState_TYPE 15u
/* subsystem_catalog.Resolution; native size 11280, alignment 8. */
typedef struct R4SdkSubsystemCatalogResolution { _Alignas(8) uint8_t opaque_bytes[11280]; } R4SdkSubsystemCatalogResolution;
#define R4SdkSubsystemCatalogResolution_TYPE 16u
/* [128]subsystem_catalog.Candidate; native size 11264, alignment 8. */
typedef struct R4SdkSubsystemNativeValue17 { _Alignas(8) uint8_t opaque_bytes[11264]; } R4SdkSubsystemNativeValue17;
#define R4SdkSubsystemNativeValue17_TYPE 17u
/* *const subsystem_catalog.Catalog; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue18 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue18;
#define R4SdkSubsystemNativeValue18_TYPE 18u
/* *subsystem_catalog.Resolution; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue19 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue19;
#define R4SdkSubsystemNativeValue19_TYPE 19u
/* error{InvalidAssociation,InvalidInput,StaleAssociation,TooManyCandidates}!void; native size 2, alignment 2. */
typedef struct R4SdkSubsystemNativeValue20 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkSubsystemNativeValue20;
#define R4SdkSubsystemNativeValue20_TYPE 20u
/* subsystem_launch.Option; native size 32, alignment 8. */
typedef struct R4SdkSubsystemLaunchOption { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkSubsystemLaunchOption;
#define R4SdkSubsystemLaunchOption_TYPE 21u
/* subsystem_launch.Request; native size 40, alignment 8. */
typedef struct R4SdkSubsystemLaunchRequest { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkSubsystemLaunchRequest;
#define R4SdkSubsystemLaunchRequest_TYPE 22u
/* []const subsystem_launch.Option; native size 16, alignment 8. */
typedef struct R4SdkSubsystemNativeValue23 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemNativeValue23;
#define R4SdkSubsystemNativeValue23_TYPE 23u
/* error{BufferTooSmall,DuplicateGuest,InvalidGuestPath,InvalidKey,InvalidMagic,InvalidValue,MalformedRecord,MissingGuest,TooManyOptions}![]const u8; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNativeValue25 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNativeValue25;
#define R4SdkSubsystemNativeValue25_TYPE 25u
/* error{BufferTooSmall,DuplicateGuest,InvalidGuestPath,InvalidKey,InvalidMagic,InvalidValue,MalformedRecord,MissingGuest,TooManyOptions}!subsystem_launch.Request; native size 48, alignment 8. */
typedef struct R4SdkSubsystemNativeValue26 { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemNativeValue26;
#define R4SdkSubsystemNativeValue26_TYPE 26u
/* subsystem_launch.OptionIterator; native size 16, alignment 8. */
typedef struct R4SdkSubsystemLaunchOptionIterator { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemLaunchOptionIterator;
#define R4SdkSubsystemLaunchOptionIterator_TYPE 27u
/* subsystem_host.PixelFormat; native size 1, alignment 1. */
typedef struct R4SdkSubsystemVideoPixelFormat { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemVideoPixelFormat;
#define R4SdkSubsystemVideoPixelFormat_TYPE 28u
/* subsystem_host.Indexed8; native size 32, alignment 8. */
typedef struct R4SdkSubsystemVideoIndexed8 { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkSubsystemVideoIndexed8;
#define R4SdkSubsystemVideoIndexed8_TYPE 29u
/* []u32; native size 16, alignment 8. */
typedef struct R4SdkSubsystemNativeValue30 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemNativeValue30;
#define R4SdkSubsystemNativeValue30_TYPE 30u
/* subsystem_host.PixelStorage; native size 40, alignment 8. */
typedef struct R4SdkSubsystemVideoPixelStorage { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkSubsystemVideoPixelStorage;
#define R4SdkSubsystemVideoPixelStorage_TYPE 31u
/* subsystem_host.Surface; native size 48, alignment 8. */
typedef struct R4SdkSubsystemVideoSurface { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemVideoSurface;
#define R4SdkSubsystemVideoSurface_TYPE 32u
/* subsystem_host.Rect; native size 16, alignment 4. */
typedef struct R4SdkSubsystemVideoRect { _Alignas(4) uint8_t opaque_bytes[16]; } R4SdkSubsystemVideoRect;
#define R4SdkSubsystemVideoRect_TYPE 33u
/* subsystem_host.Point; native size 8, alignment 4. */
typedef struct R4SdkSubsystemVideoPoint { _Alignas(4) uint8_t opaque_bytes[8]; } R4SdkSubsystemVideoPoint;
#define R4SdkSubsystemVideoPoint_TYPE 34u
/* subsystem_host.Size; native size 8, alignment 4. */
typedef struct R4SdkSubsystemVideoSize { _Alignas(4) uint8_t opaque_bytes[8]; } R4SdkSubsystemVideoSize;
#define R4SdkSubsystemVideoSize_TYPE 35u
/* subsystem_host.Viewport; native size 28, alignment 4. */
typedef struct R4SdkSubsystemVideoViewport { _Alignas(4) uint8_t opaque_bytes[28]; } R4SdkSubsystemVideoViewport;
#define R4SdkSubsystemVideoViewport_TYPE 36u
/* error{BufferTooSmall,InvalidSize,Overflow,PaletteTooSmall,ScratchTooSmall,UnsupportedDrawContract,WindowUnavailable}!subsystem_host.Viewport; native size 32, alignment 4. */
typedef struct R4SdkSubsystemNativeValue37 { _Alignas(4) uint8_t opaque_bytes[32]; } R4SdkSubsystemNativeValue37;
#define R4SdkSubsystemNativeValue37_TYPE 37u
/* subsystem_host.PresentMode; native size 1, alignment 1. */
typedef struct R4SdkSubsystemVideoPresentMode { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemVideoPresentMode;
#define R4SdkSubsystemVideoPresentMode_TYPE 38u
/* subsystem_host.PresentInfo; native size 48, alignment 8. */
typedef struct R4SdkSubsystemVideoPresentInfo { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemVideoPresentInfo;
#define R4SdkSubsystemVideoPresentInfo_TYPE 39u
/* subsystem_host.PresentResult; native size 56, alignment 8. */
typedef struct R4SdkSubsystemVideoPresentResult { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkSubsystemVideoPresentResult;
#define R4SdkSubsystemVideoPresentResult_TYPE 40u
/* @typeInfo(subsystem_host.PresentResult).@"union".tag_type.?; native size 1, alignment 1. */
typedef struct R4SdkSubsystemNative__typeInfo_subsystem_host_PresentResult____union__tag_type__ { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemNative__typeInfo_subsystem_host_PresentResult____union__tag_type__;
#define R4SdkSubsystemNative__typeInfo_subsystem_host_PresentResult____union__tag_type___TYPE 41u
/* subsystem_host.PresentStats; native size 176, alignment 8. */
typedef struct R4SdkSubsystemVideoPresentStats { _Alignas(8) uint8_t opaque_bytes[176]; } R4SdkSubsystemVideoPresentStats;
#define R4SdkSubsystemVideoPresentStats_TYPE 42u
/* subsystem_host.IndexedBatch; native size 112, alignment 8. */
typedef struct R4SdkSubsystemVideoIndexedBatch { _Alignas(8) uint8_t opaque_bytes[112]; } R4SdkSubsystemVideoIndexedBatch;
#define R4SdkSubsystemVideoIndexedBatch_TYPE 43u
/* subsystem_host.Xrgb32Batch; native size 112, alignment 8. */
typedef struct R4SdkSubsystemVideoXrgb32Batch { _Alignas(8) uint8_t opaque_bytes[112]; } R4SdkSubsystemVideoXrgb32Batch;
#define R4SdkSubsystemVideoXrgb32Batch_TYPE 45u
/* subsystem_host.SharedRasterBatch; native size 176, alignment 8. */
typedef struct R4SdkSubsystemVideoSharedRasterBatch { _Alignas(8) uint8_t opaque_bytes[176]; } R4SdkSubsystemVideoSharedRasterBatch;
#define R4SdkSubsystemVideoSharedRasterBatch_TYPE 46u
/* subsystem_host.Backend; native size 136, alignment 8. */
typedef struct R4SdkSubsystemVideoBackend { _Alignas(8) uint8_t opaque_bytes[136]; } R4SdkSubsystemVideoBackend;
#define R4SdkSubsystemVideoBackend_TYPE 48u
/* subsystem_host.FrameOverlay; native size 16, alignment 8. */
typedef struct R4SdkSubsystemVideoFrameOverlay { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemVideoFrameOverlay;
#define R4SdkSubsystemVideoFrameOverlay_TYPE 49u
/* subsystem_host.Presenter; native size 520, alignment 8. */
typedef struct R4SdkSubsystemVideoPresenter { _Alignas(8) uint8_t opaque_bytes[520]; } R4SdkSubsystemVideoPresenter;
#define R4SdkSubsystemVideoPresenter_TYPE 50u
/* subsystem_host.Damage; native size 144, alignment 8. */
typedef struct R4SdkSubsystemVideoDamage { _Alignas(8) uint8_t opaque_bytes[144]; } R4SdkSubsystemVideoDamage;
#define R4SdkSubsystemVideoDamage_TYPE 51u
/* subsystem_host.DamageKind; native size 1, alignment 1. */
typedef struct R4SdkSubsystemVideoDamageKind { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemVideoDamageKind;
#define R4SdkSubsystemVideoDamageKind_TYPE 52u
/* [8]subsystem_host.Rect; native size 128, alignment 4. */
typedef struct R4SdkSubsystemNativeValue53 { _Alignas(4) uint8_t opaque_bytes[128]; } R4SdkSubsystemNativeValue53;
#define R4SdkSubsystemNativeValue53_TYPE 53u
/* ?subsystem_host.Viewport; native size 32, alignment 4. */
typedef struct R4SdkSubsystemNativeValue54 { _Alignas(4) uint8_t opaque_bytes[32]; } R4SdkSubsystemNativeValue54;
#define R4SdkSubsystemNativeValue54_TYPE 54u
/* ?subsystem_host.Rect; native size 20, alignment 4. */
typedef struct R4SdkSubsystemNativeValue57 { _Alignas(4) uint8_t opaque_bytes[20]; } R4SdkSubsystemNativeValue57;
#define R4SdkSubsystemNativeValue57_TYPE 57u
/* subsystem_host.MouseAction; native size 1, alignment 1. */
typedef struct R4SdkSubsystemVideoMouseAction { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemVideoMouseAction;
#define R4SdkSubsystemVideoMouseAction_TYPE 58u
/* subsystem_host.KeyTextMode; native size 1, alignment 1. */
typedef struct R4SdkSubsystemVideoKeyTextMode { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemVideoKeyTextMode;
#define R4SdkSubsystemVideoKeyTextMode_TYPE 59u
/* subsystem_host.PointerMode; native size 1, alignment 1. */
typedef struct R4SdkSubsystemVideoPointerMode { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemVideoPointerMode;
#define R4SdkSubsystemVideoPointerMode_TYPE 60u
/* subsystem_host.InputPolicy; native size 2, alignment 1. */
typedef struct R4SdkSubsystemVideoInputPolicy { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkSubsystemVideoInputPolicy;
#define R4SdkSubsystemVideoInputPolicy_TYPE 61u
/* subsystem_host.InputStamp; native size 16, alignment 8. */
typedef struct R4SdkSubsystemVideoInputStamp { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemVideoInputStamp;
#define R4SdkSubsystemVideoInputStamp_TYPE 62u
/* subsystem_host.InputFilterReason; native size 1, alignment 1. */
typedef struct R4SdkSubsystemVideoInputFilterReason { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemVideoInputFilterReason;
#define R4SdkSubsystemVideoInputFilterReason_TYPE 63u
/* subsystem_host.InputTranslationStats; native size 208, alignment 8. */
typedef struct R4SdkSubsystemVideoInputTranslationStats { _Alignas(8) uint8_t opaque_bytes[208]; } R4SdkSubsystemVideoInputTranslationStats;
#define R4SdkSubsystemVideoInputTranslationStats_TYPE 64u
/* subsystem_host.HostStats; native size 48, alignment 8. */
typedef struct R4SdkSubsystemVideoHostStats { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemVideoHostStats;
#define R4SdkSubsystemVideoHostStats_TYPE 65u
/* subsystem_host.KeyEvent; native size 24, alignment 8. */
typedef struct R4SdkSubsystemVideoKeyEvent { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemVideoKeyEvent;
#define R4SdkSubsystemVideoKeyEvent_TYPE 66u
/* subsystem_host.PhysicalKeyEvent; native size 32, alignment 8. */
typedef struct R4SdkSubsystemVideoPhysicalKeyEvent { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkSubsystemVideoPhysicalKeyEvent;
#define R4SdkSubsystemVideoPhysicalKeyEvent_TYPE 67u
/* subsystem_host.TextEvent; native size 24, alignment 8. */
typedef struct R4SdkSubsystemVideoTextEvent { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemVideoTextEvent;
#define R4SdkSubsystemVideoTextEvent_TYPE 68u
/* subsystem_host.MouseEvent; native size 48, alignment 8. */
typedef struct R4SdkSubsystemVideoMouseEvent { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemVideoMouseEvent;
#define R4SdkSubsystemVideoMouseEvent_TYPE 69u
/* ?subsystem_host.Point; native size 12, alignment 4. */
typedef struct R4SdkSubsystemNativeValue70 { _Alignas(4) uint8_t opaque_bytes[12]; } R4SdkSubsystemNativeValue70;
#define R4SdkSubsystemNativeValue70_TYPE 70u
/* subsystem_host.ResizeEvent; native size 56, alignment 8. */
typedef struct R4SdkSubsystemVideoResizeEvent { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkSubsystemVideoResizeEvent;
#define R4SdkSubsystemVideoResizeEvent_TYPE 71u
/* subsystem_host.FocusEvent; native size 24, alignment 8. */
typedef struct R4SdkSubsystemVideoFocusEvent { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemVideoFocusEvent;
#define R4SdkSubsystemVideoFocusEvent_TYPE 72u
/* subsystem_host.CloseEvent; native size 16, alignment 8. */
typedef struct R4SdkSubsystemVideoCloseEvent { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemVideoCloseEvent;
#define R4SdkSubsystemVideoCloseEvent_TYPE 73u
/* subsystem_host.InputEvent; native size 64, alignment 8. */
typedef struct R4SdkSubsystemVideoInputEvent { _Alignas(8) uint8_t opaque_bytes[64]; } R4SdkSubsystemVideoInputEvent;
#define R4SdkSubsystemVideoInputEvent_TYPE 74u
/* @typeInfo(subsystem_host.InputEvent).@"union".tag_type.?; native size 1, alignment 1. */
typedef struct R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type__ { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type__;
#define R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type___TYPE 75u
/* subsystem_host.InputTranslator; native size 520, alignment 8. */
typedef struct R4SdkSubsystemVideoInputTranslator { _Alignas(8) uint8_t opaque_bytes[520]; } R4SdkSubsystemVideoInputTranslator;
#define R4SdkSubsystemVideoInputTranslator_TYPE 76u
/* ?subsystem_host.TextEvent; native size 32, alignment 8. */
typedef struct R4SdkSubsystemNativeValue77 { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkSubsystemNativeValue77;
#define R4SdkSubsystemNativeValue77_TYPE 77u
/* [256]bool; native size 256, alignment 1. */
typedef struct R4SdkSubsystemNativeValue78 { _Alignas(1) uint8_t opaque_bytes[256]; } R4SdkSubsystemNativeValue78;
#define R4SdkSubsystemNativeValue78_TYPE 78u
/* ?u16; native size 4, alignment 2. */
typedef struct R4SdkSubsystemNativeValue79 { _Alignas(2) uint8_t opaque_bytes[4]; } R4SdkSubsystemNativeValue79;
#define R4SdkSubsystemNativeValue79_TYPE 79u
/* subsystem_host.Host; native size 1192, alignment 8. */
typedef struct R4SdkSubsystemVideoHost { _Alignas(8) uint8_t opaque_bytes[1192]; } R4SdkSubsystemVideoHost;
#define R4SdkSubsystemVideoHost_TYPE 80u
/* r4desk.Context; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNative_r4desk_Context { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNative_r4desk_Context;
#define R4SdkSubsystemNative_r4desk_Context_TYPE 81u
/* r4draw.Context; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNative_r4draw_Context { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNative_r4draw_Context;
#define R4SdkSubsystemNative_r4draw_Context_TYPE 82u
/* ?subsystem_host.FrameOverlay; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNativeValue83 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNativeValue83;
#define R4SdkSubsystemNativeValue83_TYPE 83u
/* subsystem_audio_transport.Completion; native size 232, alignment 8. */
typedef struct R4SdkSubsystemNative_subsystem_audio_transport_Completion { _Alignas(8) uint8_t opaque_bytes[232]; } R4SdkSubsystemNative_subsystem_audio_transport_Completion;
#define R4SdkSubsystemNative_subsystem_audio_transport_Completion_TYPE 84u
/* subsystem_audio_transport.Operation; native size 1, alignment 1. */
typedef struct R4SdkSubsystemNative_subsystem_audio_transport_Operation { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemNative_subsystem_audio_transport_Operation;
#define R4SdkSubsystemNative_subsystem_audio_transport_Operation_TYPE 85u
/* ?abi_generated.AudioServiceStreamProgressState; native size 208, alignment 8. */
typedef struct R4SdkSubsystemNativeValue86 { _Alignas(8) uint8_t opaque_bytes[208]; } R4SdkSubsystemNativeValue86;
#define R4SdkSubsystemNativeValue86_TYPE 86u
/* subsystem_audio_transport.Finish; native size 456, alignment 8. */
typedef struct R4SdkSubsystemNative_subsystem_audio_transport_Finish { _Alignas(8) uint8_t opaque_bytes[456]; } R4SdkSubsystemNative_subsystem_audio_transport_Finish;
#define R4SdkSubsystemNative_subsystem_audio_transport_Finish_TYPE 88u
/* ?subsystem_audio_transport.Completion; native size 240, alignment 8. */
typedef struct R4SdkSubsystemNativeValue89 { _Alignas(8) uint8_t opaque_bytes[240]; } R4SdkSubsystemNativeValue89;
#define R4SdkSubsystemNativeValue89_TYPE 89u
/* subsystem_runtime.LifecycleState; native size 1, alignment 1. */
typedef struct R4SdkSubsystemRuntimeLifecycleState { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemRuntimeLifecycleState;
#define R4SdkSubsystemRuntimeLifecycleState_TYPE 90u
/* subsystem_runtime.LifecycleCommand; native size 1, alignment 1. */
typedef struct R4SdkSubsystemRuntimeLifecycleCommand { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemRuntimeLifecycleCommand;
#define R4SdkSubsystemRuntimeLifecycleCommand_TYPE 91u
/* subsystem_runtime.StepStatus; native size 1, alignment 1. */
typedef struct R4SdkSubsystemRuntimeStepStatus { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemRuntimeStepStatus;
#define R4SdkSubsystemRuntimeStepStatus_TYPE 92u
/* subsystem_runtime.StepResult; native size 24, alignment 8. */
typedef struct R4SdkSubsystemRuntimeStepResult { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemRuntimeStepResult;
#define R4SdkSubsystemRuntimeStepResult_TYPE 93u
/* subsystem_runtime.HostPollResult; native size 8, alignment 4. */
typedef struct R4SdkSubsystemRuntimeHostPollResult { _Alignas(4) uint8_t opaque_bytes[8]; } R4SdkSubsystemRuntimeHostPollResult;
#define R4SdkSubsystemRuntimeHostPollResult_TYPE 94u
/* @typeInfo(subsystem_runtime.HostPollResult).@"union".tag_type.?; native size 1, alignment 1. */
typedef struct R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type__ { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type__;
#define R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type___TYPE 95u
/* subsystem_runtime.AudioFeedback; native size 96, alignment 8. */
typedef struct R4SdkSubsystemRuntimeAudioFeedback { _Alignas(8) uint8_t opaque_bytes[96]; } R4SdkSubsystemRuntimeAudioFeedback;
#define R4SdkSubsystemRuntimeAudioFeedback_TYPE 96u
/* subsystem_runtime.AudioState; native size 1, alignment 1. */
typedef struct R4SdkSubsystemRuntimeAudioState { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemRuntimeAudioState;
#define R4SdkSubsystemRuntimeAudioState_TYPE 97u
/* subsystem_runtime.GuestDriver; native size 40, alignment 8. */
typedef struct R4SdkSubsystemRuntimeGuestDriver { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkSubsystemRuntimeGuestDriver;
#define R4SdkSubsystemRuntimeGuestDriver_TYPE 99u
/* ?*const fn (*anyopaque, subsystem_runtime.AudioFeedback) bool; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue100 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue100;
#define R4SdkSubsystemNativeValue100_TYPE 100u
/* subsystem_runtime.HostDriver; native size 40, alignment 8. */
typedef struct R4SdkSubsystemRuntimeHostDriver { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkSubsystemRuntimeHostDriver;
#define R4SdkSubsystemRuntimeHostDriver_TYPE 101u
/* ?*const fn (*anyopaque, u64) i32; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue102 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue102;
#define R4SdkSubsystemNativeValue102_TYPE 102u
/* ?*const fn (*anyopaque) bool; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue103 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue103;
#define R4SdkSubsystemNativeValue103_TYPE 103u
/* subsystem_runtime.GuestClock; native size 32, alignment 8. */
typedef struct R4SdkSubsystemRuntimeGuestClock { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkSubsystemRuntimeGuestClock;
#define R4SdkSubsystemRuntimeGuestClock_TYPE 104u
/* subsystem_runtime.Pacer; native size 16, alignment 8. */
typedef struct R4SdkSubsystemRuntimePacer { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemRuntimePacer;
#define R4SdkSubsystemRuntimePacer_TYPE 105u
/* subsystem_runtime.AudioConfig; native size 40, alignment 8. */
typedef struct R4SdkSubsystemRuntimeAudioConfig { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkSubsystemRuntimeAudioConfig;
#define R4SdkSubsystemRuntimeAudioConfig_TYPE 106u
/* subsystem_runtime.AudioSink; native size 64, alignment 8. */
typedef struct R4SdkSubsystemRuntimeAudioSink { _Alignas(8) uint8_t opaque_bytes[64]; } R4SdkSubsystemRuntimeAudioSink;
#define R4SdkSubsystemRuntimeAudioSink_TYPE 107u
/* ?*const fn (*anyopaque) ?subsystem_audio_transport.Completion; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue108 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue108;
#define R4SdkSubsystemNativeValue108_TYPE 108u
/* ?*const fn (*anyopaque) subsystem_audio_transport.Finish; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue109 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue109;
#define R4SdkSubsystemNativeValue109_TYPE 109u
/* ?*const fn (*anyopaque) i32; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue110 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue110;
#define R4SdkSubsystemNativeValue110_TYPE 110u
/* subsystem_runtime.R4AudioSink; native size 88, alignment 8. */
typedef struct R4SdkSubsystemRuntimeR4AudioSink { _Alignas(8) uint8_t opaque_bytes[88]; } R4SdkSubsystemRuntimeR4AudioSink;
#define R4SdkSubsystemRuntimeR4AudioSink_TYPE 111u
/* app_audio.Audio; native size 48, alignment 8. */
typedef struct R4SdkSubsystemNative_app_audio_Audio { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemNative_app_audio_Audio;
#define R4SdkSubsystemNative_app_audio_Audio_TYPE 112u
/* subsystem_runtime.AudioStats; native size 392, alignment 8. */
typedef struct R4SdkSubsystemRuntimeAudioStats { _Alignas(8) uint8_t opaque_bytes[392]; } R4SdkSubsystemRuntimeAudioStats;
#define R4SdkSubsystemRuntimeAudioStats_TYPE 114u
/* subsystem_runtime.PcmQueue; native size 40, alignment 8. */
typedef struct R4SdkSubsystemRuntimePcmQueue { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkSubsystemRuntimePcmQueue;
#define R4SdkSubsystemRuntimePcmQueue_TYPE 115u
/* subsystem_runtime.AudioOptions; native size 144, alignment 8. */
typedef struct R4SdkSubsystemRuntimeAudioOptions { _Alignas(8) uint8_t opaque_bytes[144]; } R4SdkSubsystemRuntimeAudioOptions;
#define R4SdkSubsystemRuntimeAudioOptions_TYPE 116u
/* ?subsystem_runtime.AudioSink; native size 72, alignment 8. */
typedef struct R4SdkSubsystemNativeValue117 { _Alignas(8) uint8_t opaque_bytes[72]; } R4SdkSubsystemNativeValue117;
#define R4SdkSubsystemNativeValue117_TYPE 117u
/* subsystem_runtime.AudioPump; native size 856, alignment 8. */
typedef struct R4SdkSubsystemRuntimeAudioPump { _Alignas(8) uint8_t opaque_bytes[856]; } R4SdkSubsystemRuntimeAudioPump;
#define R4SdkSubsystemRuntimeAudioPump_TYPE 118u
/* ?subsystem_audio_transport.Operation; native size 2, alignment 1. */
typedef struct R4SdkSubsystemNativeValue119 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkSubsystemNativeValue119;
#define R4SdkSubsystemNativeValue119_TYPE 119u
/* subsystem_runtime.AudioPump.DiscardReason; native size 1, alignment 1. */
typedef struct R4SdkSubsystemRuntimeAudioPump_DiscardReason { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemRuntimeAudioPump_DiscardReason;
#define R4SdkSubsystemRuntimeAudioPump_DiscardReason_TYPE 120u
/* subsystem_runtime.Config; native size 24, alignment 8. */
typedef struct R4SdkSubsystemRuntimeConfig { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemRuntimeConfig;
#define R4SdkSubsystemRuntimeConfig_TYPE 121u
/* subsystem_runtime.RuntimeStats; native size 232, alignment 8. */
typedef struct R4SdkSubsystemRuntimeRuntimeStats { _Alignas(8) uint8_t opaque_bytes[232]; } R4SdkSubsystemRuntimeRuntimeStats;
#define R4SdkSubsystemRuntimeRuntimeStats_TYPE 122u
/* subsystem_runtime.CycleResult; native size 16, alignment 8. */
typedef struct R4SdkSubsystemRuntimeCycleResult { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemRuntimeCycleResult;
#define R4SdkSubsystemRuntimeCycleResult_TYPE 123u
/* @typeInfo(subsystem_runtime.CycleResult).@"union".tag_type.?; native size 1, alignment 1. */
typedef struct R4SdkSubsystemNative__typeInfo_subsystem_runtime_CycleResult____union__tag_type__ { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemNative__typeInfo_subsystem_runtime_CycleResult____union__tag_type__;
#define R4SdkSubsystemNative__typeInfo_subsystem_runtime_CycleResult____union__tag_type___TYPE 124u
/* subsystem_runtime.CycleResult__struct_; native size 8, alignment 4. */
typedef struct R4SdkSubsystemNativeValue125 { _Alignas(4) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue125;
#define R4SdkSubsystemNativeValue125_TYPE 125u
/* subsystem_runtime.Runtime; native size 1248, alignment 8. */
typedef struct R4SdkSubsystemRuntimeRuntime { _Alignas(8) uint8_t opaque_bytes[1248]; } R4SdkSubsystemRuntimeRuntime;
#define R4SdkSubsystemRuntimeRuntime_TYPE 126u
/* subsystem_persistence.FileKind; native size 1, alignment 1. */
typedef struct R4SdkSubsystemPersistenceFileKind { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemPersistenceFileKind;
#define R4SdkSubsystemPersistenceFileKind_TYPE 127u
/* *const [32]u8; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue128 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue128;
#define R4SdkSubsystemNativeValue128_TYPE 128u
/* *[64]u8; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue130 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue130;
#define R4SdkSubsystemNativeValue130_TYPE 130u
/* [64]u8; native size 64, alignment 1. */
typedef struct R4SdkSubsystemNativeValue131 { _Alignas(1) uint8_t opaque_bytes[64]; } R4SdkSubsystemNativeValue131;
#define R4SdkSubsystemNativeValue131_TYPE 131u
/* subsystem_persistence.ReadResult; native size 1, alignment 1. */
typedef struct R4SdkSubsystemPersistenceReadResult { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemPersistenceReadResult;
#define R4SdkSubsystemPersistenceReadResult_TYPE 132u
/* subsystem_persistence.Backend; native size 64, alignment 8. */
typedef struct R4SdkSubsystemPersistenceBackend { _Alignas(8) uint8_t opaque_bytes[64]; } R4SdkSubsystemPersistenceBackend;
#define R4SdkSubsystemPersistenceBackend_TYPE 133u
/* ?*const fn (*anyopaque) error{Busy,Full,Io,Unsupported}!void; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue134 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue134;
#define R4SdkSubsystemNativeValue134_TYPE 134u
/* subsystem_persistence.Configuration; native size 88, alignment 8. */
typedef struct R4SdkSubsystemPersistenceConfiguration { _Alignas(8) uint8_t opaque_bytes[88]; } R4SdkSubsystemPersistenceConfiguration;
#define R4SdkSubsystemPersistenceConfiguration_TYPE 135u
/* ?*const fn (?*anyopaque, []const u8) bool; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue136 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue136;
#define R4SdkSubsystemNativeValue136_TYPE 136u
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).FailureStage; native size 1, alignment 1. */
typedef struct R4SdkSubsystemFailureStage { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemFailureStage;
#define R4SdkSubsystemFailureStage_TYPE 137u
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).RecoveryTestState; native size 48, alignment 8. */
typedef struct R4SdkSubsystemRecoveryTestState { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemRecoveryTestState;
#define R4SdkSubsystemRecoveryTestState_TYPE 138u
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).Store; native size 1176, alignment 8. */
typedef struct R4SdkSubsystemStore { _Alignas(8) uint8_t opaque_bytes[1176]; } R4SdkSubsystemStore;
#define R4SdkSubsystemStore_TYPE 139u
/* app_storage.Files; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNative_app_storage_Files { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNative_app_storage_Files;
#define R4SdkSubsystemNative_app_storage_Files_TYPE 140u
/* ?app_storage.OwnedStageWriter; native size 1096, alignment 8. */
typedef struct R4SdkSubsystemNativeValue141 { _Alignas(8) uint8_t opaque_bytes[1096]; } R4SdkSubsystemNativeValue141;
#define R4SdkSubsystemNativeValue141_TYPE 141u
/* app_storage.OwnedStageWriter; native size 1088, alignment 8. */
typedef struct R4SdkSubsystemNative_app_storage_OwnedStageWriter { _Alignas(8) uint8_t opaque_bytes[1088]; } R4SdkSubsystemNative_app_storage_OwnedStageWriter;
#define R4SdkSubsystemNative_app_storage_OwnedStageWriter_TYPE 142u
/* *const subsystem_persistence.Configuration; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue143 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue143;
#define R4SdkSubsystemNativeValue143_TYPE 143u
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncStats; native size 64, alignment 8. */
typedef struct R4SdkSubsystemAsyncStats { _Alignas(8) uint8_t opaque_bytes[64]; } R4SdkSubsystemAsyncStats;
#define R4SdkSubsystemAsyncStats_TYPE 144u
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncStore; native size 1344, alignment 8. */
typedef struct R4SdkSubsystemAsyncStore { _Alignas(8) uint8_t opaque_bytes[1344]; } R4SdkSubsystemAsyncStore;
#define R4SdkSubsystemAsyncStore_TYPE 145u
/* ?subsystem_persistence.R4osStore(subsystem_persistence.Configuration).ActiveWrite; native size 48, alignment 8. */
typedef struct R4SdkSubsystemNativeValue147 { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemNativeValue147;
#define R4SdkSubsystemNativeValue147_TYPE 147u
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).ActiveWrite; native size 40, alignment 8. */
typedef struct R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite;
#define R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite_TYPE 148u
/* *subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncWriteJob; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue149 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue149;
#define R4SdkSubsystemNativeValue149_TYPE 149u
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncWriteJob; native size 72, alignment 8. */
typedef struct R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob { _Alignas(8) uint8_t opaque_bytes[72]; } R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob;
#define R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_TYPE 150u
/* *subsystem_persistence.R4osStore(subsystem_persistence.Configuration).Store; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue151 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue151;
#define R4SdkSubsystemNativeValue151_TYPE 151u
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncWriteResult; native size 1, alignment 1. */
typedef struct R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult;
#define R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult_TYPE 152u
/* [3]?*subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncWriteJob; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNativeValue154 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNativeValue154;
#define R4SdkSubsystemNativeValue154_TYPE 154u
/* ?*subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncWriteJob; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue155 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue155;
#define R4SdkSubsystemNativeValue155_TYPE 155u
/* ?error{Busy,Full,Io,Unsupported}; native size 2, alignment 2. */
typedef struct R4SdkSubsystemNativeValue156 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkSubsystemNativeValue156;
#define R4SdkSubsystemNativeValue156_TYPE 156u
/* @typeInfo(@typeInfo(@TypeOf(subsystem_persistence.R4osStore(subsystem_persistence.Configuration).dataPathConfigured)).@"fn".return_type.?).error_union.error_set!path.AbsoluteFilePath; native size 1030, alignment 2. */
typedef struct R4SdkSubsystemNativeValue157 { _Alignas(2) uint8_t opaque_bytes[1030]; } R4SdkSubsystemNativeValue157;
#define R4SdkSubsystemNativeValue157_TYPE 157u
/* path.AbsoluteFilePath; native size 1028, alignment 2. */
typedef struct R4SdkSubsystemNative_path_AbsoluteFilePath { _Alignas(2) uint8_t opaque_bytes[1028]; } R4SdkSubsystemNative_path_AbsoluteFilePath;
#define R4SdkSubsystemNative_path_AbsoluteFilePath_TYPE 158u
/* subsystem_callback_bridge.Kind; native size 1, alignment 1. */
typedef struct R4SdkSubsystemCallbackKind { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkSubsystemCallbackKind;
#define R4SdkSubsystemCallbackKind_TYPE 162u
/* subsystem_callback_bridge.Table; native size 24, alignment 8. */
typedef struct R4SdkSubsystemCallbackTable { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemCallbackTable;
#define R4SdkSubsystemCallbackTable_TYPE 163u
/* *const subsystem_callback_bridge.Table; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue165 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue165;
#define R4SdkSubsystemNativeValue165_TYPE 165u
/* error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_catalog.HostVerifier; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNativeValue166 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNativeValue166;
#define R4SdkSubsystemNativeValue166_TYPE 166u
/* error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_host.Backend; native size 144, alignment 8. */
typedef struct R4SdkSubsystemNativeValue167 { _Alignas(8) uint8_t opaque_bytes[144]; } R4SdkSubsystemNativeValue167;
#define R4SdkSubsystemNativeValue167_TYPE 167u
/* error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_host.FrameOverlay; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNativeValue168 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNativeValue168;
#define R4SdkSubsystemNativeValue168_TYPE 168u
/* error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_runtime.GuestDriver; native size 48, alignment 8. */
typedef struct R4SdkSubsystemNativeValue169 { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemNativeValue169;
#define R4SdkSubsystemNativeValue169_TYPE 169u
/* error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_runtime.HostDriver; native size 48, alignment 8. */
typedef struct R4SdkSubsystemNativeValue170 { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemNativeValue170;
#define R4SdkSubsystemNativeValue170_TYPE 170u
/* error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_runtime.AudioSink; native size 72, alignment 8. */
typedef struct R4SdkSubsystemNativeValue171 { _Alignas(8) uint8_t opaque_bytes[72]; } R4SdkSubsystemNativeValue171;
#define R4SdkSubsystemNativeValue171_TYPE 171u
/* error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_persistence.Backend; native size 72, alignment 8. */
typedef struct R4SdkSubsystemNativeValue172 { _Alignas(8) uint8_t opaque_bytes[72]; } R4SdkSubsystemNativeValue172;
#define R4SdkSubsystemNativeValue172_TYPE 172u
/* error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_persistence.Configuration; native size 96, alignment 8. */
typedef struct R4SdkSubsystemNativeValue173 { _Alignas(8) uint8_t opaque_bytes[96]; } R4SdkSubsystemNativeValue173;
#define R4SdkSubsystemNativeValue173_TYPE 173u
/* subsystem_helper_adapters.Context; native size 152, alignment 8. */
typedef struct R4SdkSubsystemContext { _Alignas(8) uint8_t opaque_bytes[152]; } R4SdkSubsystemContext;
#define R4SdkSubsystemContext_TYPE 174u
/* program.Bundle; native size 56, alignment 8. */
typedef struct R4SdkSubsystemNative_program_Bundle { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkSubsystemNative_program_Bundle;
#define R4SdkSubsystemNative_program_Bundle_TYPE 175u
/* r4sys.Context; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNative_r4sys_Context { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNative_r4sys_Context;
#define R4SdkSubsystemNative_r4sys_Context_TYPE 176u
/* r4audio.Context; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNative_r4audio_Context { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNative_r4audio_Context;
#define R4SdkSubsystemNative_r4audio_Context_TYPE 177u
/* program.Context; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNative_program_Context { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNative_program_Context;
#define R4SdkSubsystemNative_program_Context_TYPE 178u
/* *subsystem_helper_adapters.Context; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue179 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue179;
#define R4SdkSubsystemNativeValue179_TYPE 179u
/* *const abi_generated.R4XStartContext; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue180 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue180;
#define R4SdkSubsystemNativeValue180_TYPE 180u
/* *subsystem_host.Host; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue182 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue182;
#define R4SdkSubsystemNativeValue182_TYPE 182u
/* *const subsystem_helper_adapters.Context; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue183 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue183;
#define R4SdkSubsystemNativeValue183_TYPE 183u
/* error{BufferTooSmall,InvalidSize,Overflow,PaletteTooSmall,ScratchTooSmall,UnsupportedDrawContract,WindowUnavailable}!void; native size 2, alignment 2. */
typedef struct R4SdkSubsystemNativeValue184 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkSubsystemNativeValue184;
#define R4SdkSubsystemNativeValue184_TYPE 184u
/* *subsystem_runtime.R4AudioSink; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue185 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue185;
#define R4SdkSubsystemNativeValue185_TYPE 185u
/* *subsystem_runtime.Runtime; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue186 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue186;
#define R4SdkSubsystemNativeValue186_TYPE 186u
/* []const u32; native size 16, alignment 8. */
typedef struct R4SdkSubsystemNativeValue187 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemNativeValue187;
#define R4SdkSubsystemNativeValue187_TYPE 187u
/* error{Busy,Full,Io,Unsupported}!void; native size 2, alignment 2. */
typedef struct R4SdkSubsystemNativeValue188 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkSubsystemNativeValue188;
#define R4SdkSubsystemNativeValue188_TYPE 188u
/* *subsystem_catalog.Catalog; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue190 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue190;
#define R4SdkSubsystemNativeValue190_TYPE 190u
/* error{HostCheckFailed,InvalidInventory,MissingHost,TooManySubsystems}!void; native size 2, alignment 2. */
typedef struct R4SdkSubsystemNativeValue191 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkSubsystemNativeValue191;
#define R4SdkSubsystemNativeValue191_TYPE 191u
/* *const subsystem_catalog.Resolution; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue193 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue193;
#define R4SdkSubsystemNativeValue193_TYPE 193u
/* []const subsystem_catalog.Candidate; native size 16, alignment 8. */
typedef struct R4SdkSubsystemNativeValue194 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemNativeValue194;
#define R4SdkSubsystemNativeValue194_TYPE 194u
/* ?subsystem_catalog.Candidate; native size 96, alignment 8. */
typedef struct R4SdkSubsystemNativeValue195 { _Alignas(8) uint8_t opaque_bytes[96]; } R4SdkSubsystemNativeValue195;
#define R4SdkSubsystemNativeValue195_TYPE 195u
/* error{BufferTooSmall,DuplicateGuest,InvalidGuestPath,InvalidKey,InvalidMagic,InvalidValue,MalformedRecord,MissingGuest,TooManyOptions}!?[]const u8; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNativeValue196 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNativeValue196;
#define R4SdkSubsystemNativeValue196_TYPE 196u
/* *subsystem_launch.OptionIterator; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue197 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue197;
#define R4SdkSubsystemNativeValue197_TYPE 197u
/* error{BufferTooSmall,DuplicateGuest,InvalidGuestPath,InvalidKey,InvalidMagic,InvalidValue,MalformedRecord,MissingGuest,TooManyOptions}!?subsystem_launch.Option; native size 48, alignment 8. */
typedef struct R4SdkSubsystemNativeValue198 { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemNativeValue198;
#define R4SdkSubsystemNativeValue198_TYPE 198u
/* ?subsystem_launch.Option; native size 40, alignment 8. */
typedef struct R4SdkSubsystemNativeValue199 { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkSubsystemNativeValue199;
#define R4SdkSubsystemNativeValue199_TYPE 199u
/* error{BufferTooSmall,InvalidSize,Overflow,PaletteTooSmall,ScratchTooSmall,UnsupportedDrawContract,WindowUnavailable}!subsystem_host.Surface; native size 56, alignment 8. */
typedef struct R4SdkSubsystemNativeValue200 { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkSubsystemNativeValue200;
#define R4SdkSubsystemNativeValue200_TYPE 200u
/* *subsystem_host.Surface; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue201 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue201;
#define R4SdkSubsystemNativeValue201_TYPE 201u
/* ?[]u8; native size 16, alignment 8. */
typedef struct R4SdkSubsystemNativeValue202 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemNativeValue202;
#define R4SdkSubsystemNativeValue202_TYPE 202u
/* ?[]u32; native size 16, alignment 8. */
typedef struct R4SdkSubsystemNativeValue203 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemNativeValue203;
#define R4SdkSubsystemNativeValue203_TYPE 203u
/* *const r4draw.Context; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue204 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue204;
#define R4SdkSubsystemNativeValue204_TYPE 204u
/* error{BufferTooSmall,InvalidSize,Overflow,PaletteTooSmall,ScratchTooSmall,UnsupportedDrawContract,WindowUnavailable}!subsystem_host.Presenter; native size 528, alignment 8. */
typedef struct R4SdkSubsystemNativeValue205 { _Alignas(8) uint8_t opaque_bytes[528]; } R4SdkSubsystemNativeValue205;
#define R4SdkSubsystemNativeValue205_TYPE 205u
/* *subsystem_host.Presenter; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue206 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue206;
#define R4SdkSubsystemNativeValue206_TYPE 206u
/* *const subsystem_host.Presenter; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue207 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue207;
#define R4SdkSubsystemNativeValue207_TYPE 207u
/* *subsystem_host.InputTranslator; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue208 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue208;
#define R4SdkSubsystemNativeValue208_TYPE 208u
/* *const subsystem_host.InputTranslator; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue209 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue209;
#define R4SdkSubsystemNativeValue209_TYPE 209u
/* ?subsystem_host.InputEvent; native size 72, alignment 8. */
typedef struct R4SdkSubsystemNativeValue210 { _Alignas(8) uint8_t opaque_bytes[72]; } R4SdkSubsystemNativeValue210;
#define R4SdkSubsystemNativeValue210_TYPE 210u
/* ?subsystem_host.Size; native size 12, alignment 4. */
typedef struct R4SdkSubsystemNativeValue212 { _Alignas(4) uint8_t opaque_bytes[12]; } R4SdkSubsystemNativeValue212;
#define R4SdkSubsystemNativeValue212_TYPE 212u
/* error{BufferTooSmall,InvalidSize,Overflow,PaletteTooSmall,ScratchTooSmall,UnsupportedDrawContract,WindowUnavailable}!subsystem_host.Host; native size 1200, alignment 8. */
typedef struct R4SdkSubsystemNativeValue213 { _Alignas(8) uint8_t opaque_bytes[1200]; } R4SdkSubsystemNativeValue213;
#define R4SdkSubsystemNativeValue213_TYPE 213u
/* ?i32; native size 8, alignment 4. */
typedef struct R4SdkSubsystemNativeValue215 { _Alignas(4) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue215;
#define R4SdkSubsystemNativeValue215_TYPE 215u
/* ?bool; native size 2, alignment 1. */
typedef struct R4SdkSubsystemNativeValue216 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkSubsystemNativeValue216;
#define R4SdkSubsystemNativeValue216_TYPE 216u
/* error{AudioQueueTooSmall,AudioScratchTooSmall,InvalidAudioConfiguration,InvalidConfiguration,Overflow,UnknownFrequency}!subsystem_runtime.GuestClock; native size 40, alignment 8. */
typedef struct R4SdkSubsystemNativeValue217 { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkSubsystemNativeValue217;
#define R4SdkSubsystemNativeValue217_TYPE 217u
/* *subsystem_runtime.GuestClock; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue218 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue218;
#define R4SdkSubsystemNativeValue218_TYPE 218u
/* *const subsystem_runtime.GuestClock; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue219 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue219;
#define R4SdkSubsystemNativeValue219_TYPE 219u
/* error{AudioQueueTooSmall,AudioScratchTooSmall,InvalidAudioConfiguration,InvalidConfiguration,Overflow,UnknownFrequency}!subsystem_runtime.Pacer; native size 24, alignment 8. */
typedef struct R4SdkSubsystemNativeValue220 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkSubsystemNativeValue220;
#define R4SdkSubsystemNativeValue220_TYPE 220u
/* *subsystem_runtime.Pacer; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue221 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue221;
#define R4SdkSubsystemNativeValue221_TYPE 221u
/* *const subsystem_runtime.Pacer; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue222 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue222;
#define R4SdkSubsystemNativeValue222_TYPE 222u
/* error{AudioQueueTooSmall,AudioScratchTooSmall,InvalidAudioConfiguration,InvalidConfiguration,Overflow,UnknownFrequency}!usize; native size 16, alignment 8. */
typedef struct R4SdkSubsystemNativeValue223 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemNativeValue223;
#define R4SdkSubsystemNativeValue223_TYPE 223u
/* error{AudioQueueTooSmall,AudioScratchTooSmall,InvalidAudioConfiguration,InvalidConfiguration,Overflow,UnknownFrequency}!subsystem_runtime.PcmQueue; native size 48, alignment 8. */
typedef struct R4SdkSubsystemNativeValue224 { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkSubsystemNativeValue224;
#define R4SdkSubsystemNativeValue224_TYPE 224u
/* *const subsystem_runtime.PcmQueue; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue225 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue225;
#define R4SdkSubsystemNativeValue225_TYPE 225u
/* *subsystem_runtime.PcmQueue; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue226 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue226;
#define R4SdkSubsystemNativeValue226_TYPE 226u
/* ?subsystem_runtime.AudioOptions; native size 152, alignment 8. */
typedef struct R4SdkSubsystemNativeValue227 { _Alignas(8) uint8_t opaque_bytes[152]; } R4SdkSubsystemNativeValue227;
#define R4SdkSubsystemNativeValue227_TYPE 227u
/* error{AudioQueueTooSmall,AudioScratchTooSmall,InvalidAudioConfiguration,InvalidConfiguration,Overflow,UnknownFrequency}!subsystem_runtime.Runtime; native size 1256, alignment 8. */
typedef struct R4SdkSubsystemNativeValue228 { _Alignas(8) uint8_t opaque_bytes[1256]; } R4SdkSubsystemNativeValue228;
#define R4SdkSubsystemNativeValue228_TYPE 228u
/* *const r4sys.Context; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue229 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue229;
#define R4SdkSubsystemNativeValue229_TYPE 229u
/* *const subsystem_persistence.R4osStore(subsystem_persistence.Configuration).Store; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue230 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue230;
#define R4SdkSubsystemNativeValue230_TYPE 230u
/* error{Busy,Full,Io,Unsupported}!subsystem_persistence.R4osStore(subsystem_persistence.Configuration).RecoveryTestState; native size 56, alignment 8. */
typedef struct R4SdkSubsystemNativeValue231 { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkSubsystemNativeValue231;
#define R4SdkSubsystemNativeValue231_TYPE 231u
/* *subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncStore; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue232 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue232;
#define R4SdkSubsystemNativeValue232_TYPE 232u
/* *const subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncStore; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue233 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue233;
#define R4SdkSubsystemNativeValue233_TYPE 233u
/* error{ComponentTooLong,EmbeddedNul,Empty,ExpectedAbsolute,ExpectedRelative,InvalidCharacter,RootTraversal,TooLong}!path.AbsoluteFilePath; native size 1030, alignment 2. */
typedef struct R4SdkSubsystemNativeValue234 { _Alignas(2) uint8_t opaque_bytes[1030]; } R4SdkSubsystemNativeValue234;
#define R4SdkSubsystemNativeValue234_TYPE 234u
/* *const path.AbsoluteFilePath; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue235 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue235;
#define R4SdkSubsystemNativeValue235_TYPE 235u
/* path.PathZ; native size 16, alignment 8. */
typedef struct R4SdkSubsystemNative_path_PathZ { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemNative_path_PathZ;
#define R4SdkSubsystemNative_path_PathZ_TYPE 236u
/* *const program.Bundle; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue237 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue237;
#define R4SdkSubsystemNativeValue237_TYPE 237u
/* *const r4audio.Context; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue238 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue238;
#define R4SdkSubsystemNativeValue238_TYPE 238u
/* *abi_generated.AudioOutputInfo; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue240 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue240;
#define R4SdkSubsystemNativeValue240_TYPE 240u
/* []abi_generated.AudioOutputInfo; native size 16, alignment 8. */
typedef struct R4SdkSubsystemNativeValue242 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkSubsystemNativeValue242;
#define R4SdkSubsystemNativeValue242_TYPE 242u
/* *abi_generated.AudioOutputCatalog; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue243 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue243;
#define R4SdkSubsystemNativeValue243_TYPE 243u
/* *const [64]u8; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue245 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue245;
#define R4SdkSubsystemNativeValue245_TYPE 245u
/* *abi_generated.AudioStreamProgress; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue246 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue246;
#define R4SdkSubsystemNativeValue246_TYPE 246u
/* *const abi_generated.AudioStreamExpectation; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue248 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue248;
#define R4SdkSubsystemNativeValue248_TYPE 248u
/* *abi.AudioServiceStatus; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue250 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue250;
#define R4SdkSubsystemNativeValue250_TYPE 250u
/* *abi_generated.AudioServiceMasterState; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue252 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue252;
#define R4SdkSubsystemNativeValue252_TYPE 252u
/* *const abi_generated.AudioServiceMasterRequest; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue254 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue254;
#define R4SdkSubsystemNativeValue254_TYPE 254u
/* *abi.AudioServiceStreamResult; native size 8, alignment 8. */
typedef struct R4SdkSubsystemNativeValue256 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkSubsystemNativeValue256;
#define R4SdkSubsystemNativeValue256_TYPE 256u
#define R4SdkSubsystem_ABI_FINGERPRINT UINT64_C(14514733300798266635)
int32_t R4SdkSubsystemVerifyAbi(uint64_t);
#define R4SdkSubsystemCatalog_max_entries (192)
#define R4SdkSubsystemCatalog_max_candidates (128)
#define R4SdkSubsystemCatalog_max_associations (64)
#define R4SdkSubsystemCatalog_max_probe_bytes (262144)
#define R4SdkSubsystemCatalog_max_render_bytes (65536)
static const uint8_t R4SdkSubsystemLaunch_CONST_magic[] = {82,52,83,85,66,83,89,83,49,0};
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunch_constant_magic(void) { return (R4SdkSubsystemSlot){.ptr=(void *)R4SdkSubsystemLaunch_CONST_magic,.length=9,.flags=1u}; }
static const uint8_t R4SdkSubsystemLaunch_CONST_guest_key[] = {71,85,69,83,84,0};
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunch_constant_guest_key(void) { return (R4SdkSubsystemSlot){.ptr=(void *)R4SdkSubsystemLaunch_CONST_guest_key,.length=5,.flags=1u}; }
static const uint8_t R4SdkSubsystemLaunch_CONST_command_key[] = {67,0};
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunch_constant_command_key(void) { return (R4SdkSubsystemSlot){.ptr=(void *)R4SdkSubsystemLaunch_CONST_command_key,.length=1,.flags=1u}; }
static const uint8_t R4SdkSubsystemLaunch_CONST_environment_key[] = {69,0};
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunch_constant_environment_key(void) { return (R4SdkSubsystemSlot){.ptr=(void *)R4SdkSubsystemLaunch_CONST_environment_key,.length=1,.flags=1u}; }
static const uint8_t R4SdkSubsystemLaunch_CONST_trace_key[] = {84,0};
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunch_constant_trace_key(void) { return (R4SdkSubsystemSlot){.ptr=(void *)R4SdkSubsystemLaunch_CONST_trace_key,.length=1,.flags=1u}; }
static const uint8_t R4SdkSubsystemLaunch_CONST_trace_mode_key[] = {77,0};
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunch_constant_trace_mode_key(void) { return (R4SdkSubsystemSlot){.ptr=(void *)R4SdkSubsystemLaunch_CONST_trace_mode_key,.length=1,.flags=1u}; }
static const uint8_t R4SdkSubsystemLaunch_CONST_trace_phases_key[] = {80,0};
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunch_constant_trace_phases_key(void) { return (R4SdkSubsystemSlot){.ptr=(void *)R4SdkSubsystemLaunch_CONST_trace_phases_key,.length=1,.flags=1u}; }
static const uint8_t R4SdkSubsystemLaunch_CONST_trace_mode_gui[] = {71,0};
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunch_constant_trace_mode_gui(void) { return (R4SdkSubsystemSlot){.ptr=(void *)R4SdkSubsystemLaunch_CONST_trace_mode_gui,.length=1,.flags=1u}; }
static const uint8_t R4SdkSubsystemLaunch_CONST_trace_mode_headless[] = {72,0};
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunch_constant_trace_mode_headless(void) { return (R4SdkSubsystemSlot){.ptr=(void *)R4SdkSubsystemLaunch_CONST_trace_mode_headless,.length=1,.flags=1u}; }
#define R4SdkSubsystemLaunch_max_options (8)
#define R4SdkSubsystemLaunch_max_args_bytes (127)
#define R4SdkSubsystemVideo_tile_max_width (128)
#define R4SdkSubsystemVideo_tile_max_height (128)
#define R4SdkSubsystemVideo_tile_max_pixels (16384)
#define R4SdkSubsystemVideo_palette_entries (256)
#define R4SdkSubsystemVideo_letterbox_rgb (0)
#define R4SdkSubsystemVideo_integer_preference_percent (85)
#define R4SdkSubsystemVideo_max_damage_chain (32)
#define R4SdkSubsystemVideo_max_damage_regions (8)
#define R4SdkSubsystemRuntime_default_slice_budget (262144)
#define R4SdkSubsystemRuntime_default_max_input_events (64)
#define R4SdkSubsystemRuntime_default_max_wait_ticks (18446744073709551615)
#define R4SdkSubsystemRuntime_default_idle_retry_ticks (1)
#define R4SdkSubsystemRuntime_default_active_yield_nanoseconds (8000000)
#define R4SdkSubsystemRuntime_default_sample_rate (48000)
#define R4SdkSubsystemRuntime_default_channels (2)
#define R4SdkSubsystemRuntime_default_quantum_frames (480)
#define R4SdkSubsystemRuntime_default_target_quanta (2)
#define R4SdkSubsystemRuntime_default_max_catchup_quanta (2)
#define R4SdkSubsystemRuntime_default_busy_retry_nanoseconds (10000000)
#define R4SdkSubsystemRuntime_audio_error_timeout (-9601)
#define R4SdkSubsystemRuntime_audio_error_unavailable (-9602)
#define R4SdkSubsystemRuntime_runtime_error_guest_audio (-9610)
#define R4SdkSubsystemRuntime_runtime_error_guest_reset (-9611)
#define R4SdkSubsystemRuntime_runtime_error_host_poll (-9612)
#define R4SdkSubsystemRuntime_runtime_error_host_present (-9613)
#define R4SdkSubsystemRuntime_host_present_unchanged (0)
#define R4SdkSubsystemRuntime_host_presented (1)
#define R4SdkSubsystemRuntime_host_present_hidden (2)
#define R4SdkSubsystemRuntime_host_present_dropped (3)
#define R4SdkSubsystemPersistence_digest_bytes (32)
#define R4SdkSubsystemPersistence_digest_hex_bytes (64)
#include "r4os/update_helpers.h"
#define R4SdkSubsystemCatalogHostState_present 0u
#define R4SdkSubsystemCatalogHostState_missing 1u
#define R4SdkSubsystemCatalogHostState_failed 2u
#define R4SdkSubsystemCatalogEvidence_user_association 0u
#define R4SdkSubsystemCatalogEvidence_confirmed_probe 1u
#define R4SdkSubsystemCatalogEvidence_default_association 2u
#define R4SdkSubsystemCatalogEvidence_extension 3u
#define R4SdkSubsystemCatalogResolutionState_unknown 0u
#define R4SdkSubsystemCatalogResolutionState_selected 1u
#define R4SdkSubsystemCatalogResolutionState_ambiguous 2u
#define R4SdkSubsystemVideoPixelFormat_indexed8 0u
#define R4SdkSubsystemVideoPixelFormat_xrgb32 1u
#define R4SdkSubsystemVideoPresentMode_full 0u
#define R4SdkSubsystemVideoPresentMode_damage 1u
#define R4SdkSubsystemVideoPresentMode_replace 2u
#define R4SdkSubsystemNative__typeInfo_subsystem_host_PresentResult____union__tag_type___unchanged 0u
#define R4SdkSubsystemNative__typeInfo_subsystem_host_PresentResult____union__tag_type___hidden 1u
#define R4SdkSubsystemNative__typeInfo_subsystem_host_PresentResult____union__tag_type___presented 2u
#define R4SdkSubsystemNative__typeInfo_subsystem_host_PresentResult____union__tag_type___failure 3u
#define R4SdkSubsystemVideoDamageKind_none 0u
#define R4SdkSubsystemVideoDamageKind_full 1u
#define R4SdkSubsystemVideoDamageKind_rect 2u
#define R4SdkSubsystemVideoMouseAction_down 0u
#define R4SdkSubsystemVideoMouseAction_up 1u
#define R4SdkSubsystemVideoMouseAction_move 2u
#define R4SdkSubsystemVideoKeyTextMode_key_and_text 0u
#define R4SdkSubsystemVideoKeyTextMode_text_only 1u
#define R4SdkSubsystemVideoPointerMode_mapped 0u
#define R4SdkSubsystemVideoPointerMode_ignored 1u
#define R4SdkSubsystemVideoInputFilterReason_none 0u
#define R4SdkSubsystemVideoInputFilterReason_pointer_ignored 1u
#define R4SdkSubsystemVideoInputFilterReason_duplicate_focus 2u
#define R4SdkSubsystemVideoInputFilterReason_duplicate_physical_down 3u
#define R4SdkSubsystemVideoInputFilterReason_unexpected_physical_up 4u
#define R4SdkSubsystemVideoInputFilterReason_invalid_physical_key 5u
#define R4SdkSubsystemVideoInputFilterReason_missing_geometry 6u
#define R4SdkSubsystemVideoInputFilterReason_unsupported_raw 7u
#define R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type___close 0u
#define R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type___resize 1u
#define R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type___focus 2u
#define R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type___key_down 3u
#define R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type___physical_key_down 4u
#define R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type___physical_key_up 5u
#define R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type___text 6u
#define R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type___mouse 7u
#define R4SdkSubsystemNative_subsystem_audio_transport_Operation_open 0u
#define R4SdkSubsystemNative_subsystem_audio_transport_Operation_write 1u
#define R4SdkSubsystemNative_subsystem_audio_transport_Operation_volume 2u
#define R4SdkSubsystemNative_subsystem_audio_transport_Operation_close 3u
#define R4SdkSubsystemNative_subsystem_audio_transport_Operation_fence 4u
#define R4SdkSubsystemNative_subsystem_audio_transport_Operation_progress 5u
#define R4SdkSubsystemRuntimeLifecycleState_ready 0u
#define R4SdkSubsystemRuntimeLifecycleState_running 1u
#define R4SdkSubsystemRuntimeLifecycleState_paused 2u
#define R4SdkSubsystemRuntimeLifecycleState_completed 3u
#define R4SdkSubsystemRuntimeLifecycleState_failed 4u
#define R4SdkSubsystemRuntimeLifecycleState_closed 5u
#define R4SdkSubsystemRuntimeLifecycleCommand_none 0u
#define R4SdkSubsystemRuntimeLifecycleCommand_pause 1u
#define R4SdkSubsystemRuntimeLifecycleCommand_resume_running 2u
#define R4SdkSubsystemRuntimeLifecycleCommand_toggle_pause 3u
#define R4SdkSubsystemRuntimeLifecycleCommand_reset 4u
#define R4SdkSubsystemRuntimeLifecycleCommand_mute 5u
#define R4SdkSubsystemRuntimeLifecycleCommand_unmute 6u
#define R4SdkSubsystemRuntimeLifecycleCommand_toggle_mute 7u
#define R4SdkSubsystemRuntimeLifecycleCommand_close 8u
#define R4SdkSubsystemRuntimeStepStatus_progress 0u
#define R4SdkSubsystemRuntimeStepStatus_waiting 1u
#define R4SdkSubsystemRuntimeStepStatus_completed 2u
#define R4SdkSubsystemRuntimeStepStatus_failed 3u
#define R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type___idle 0u
#define R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type___ignored 1u
#define R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type___handled 2u
#define R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type___present 3u
#define R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type___command 4u
#define R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type___failure 5u
#define R4SdkSubsystemRuntimeAudioState_disabled 0u
#define R4SdkSubsystemRuntimeAudioState_ready 1u
#define R4SdkSubsystemRuntimeAudioState_active 2u
#define R4SdkSubsystemRuntimeAudioState_degraded 3u
#define R4SdkSubsystemRuntimeAudioState_closed 4u
#define R4SdkSubsystemRuntimeAudioPump_DiscardReason_other 0u
#define R4SdkSubsystemRuntimeAudioPump_DiscardReason_pause 1u
#define R4SdkSubsystemRuntimeAudioPump_DiscardReason_mute 2u
#define R4SdkSubsystemNative__typeInfo_subsystem_runtime_CycleResult____union__tag_type___wait 0u
#define R4SdkSubsystemNative__typeInfo_subsystem_runtime_CycleResult____union__tag_type___finished 1u
#define R4SdkSubsystemPersistenceFileKind_sram 0u
#define R4SdkSubsystemPersistenceFileKind_rtc 1u
#define R4SdkSubsystemPersistenceFileKind_sram_delta 2u
#define R4SdkSubsystemPersistenceReadResult_ok 0u
#define R4SdkSubsystemPersistenceReadResult_missing 1u
#define R4SdkSubsystemPersistenceReadResult_wrong_size 2u
#define R4SdkSubsystemPersistenceReadResult_io 3u
#define R4SdkSubsystemFailureStage_none 0u
#define R4SdkSubsystemFailureStage_async_unavailable 1u
#define R4SdkSubsystemFailureStage_async_allocate 2u
#define R4SdkSubsystemFailureStage_async_start 3u
#define R4SdkSubsystemFailureStage_async_join 4u
#define R4SdkSubsystemFailureStage_save_root 5u
#define R4SdkSubsystemFailureStage_lock_begin 6u
#define R4SdkSubsystemFailureStage_lock_write 7u
#define R4SdkSubsystemFailureStage_lock_finish 8u
#define R4SdkSubsystemFailureStage_lock_abort 9u
#define R4SdkSubsystemFailureStage_atomic_cleanup 10u
#define R4SdkSubsystemFailureStage_atomic_begin 11u
#define R4SdkSubsystemFailureStage_atomic_begin_create 12u
#define R4SdkSubsystemFailureStage_atomic_begin_write 13u
#define R4SdkSubsystemFailureStage_atomic_begin_finish 14u
#define R4SdkSubsystemFailureStage_atomic_begin_abort 15u
#define R4SdkSubsystemFailureStage_atomic_release 16u
#define R4SdkSubsystemFailureStage_atomic_recover 17u
#define R4SdkSubsystemFailureStage_atomic_stage 18u
#define R4SdkSubsystemFailureStage_atomic_stage_begin 19u
#define R4SdkSubsystemFailureStage_atomic_stage_write 20u
#define R4SdkSubsystemFailureStage_atomic_stage_finish 21u
#define R4SdkSubsystemFailureStage_atomic_stage_verify 22u
#define R4SdkSubsystemFailureStage_atomic_publish 23u
#define R4SdkSubsystemFailureStage_sram_info 24u
#define R4SdkSubsystemFailureStage_sram_read 25u
#define R4SdkSubsystemFailureStage_rtc_info 26u
#define R4SdkSubsystemFailureStage_rtc_read 27u
#define R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult_pending 0u
#define R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult_ok 1u
#define R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult_busy 2u
#define R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult_io 3u
#define R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult_full 4u
#define R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult_unsupported 5u
#define R4SdkSubsystemCallbackKind_verify_host 0u
#define R4SdkSubsystemCallbackKind_video_begin_full 1u
#define R4SdkSubsystemCallbackKind_video_begin_damage 2u
#define R4SdkSubsystemCallbackKind_video_begin_replace 3u
#define R4SdkSubsystemCallbackKind_video_clear 4u
#define R4SdkSubsystemCallbackKind_video_raster 5u
#define R4SdkSubsystemCallbackKind_video_indexed8 6u
#define R4SdkSubsystemCallbackKind_video_xrgb32 7u
#define R4SdkSubsystemCallbackKind_video_shared_create 8u
#define R4SdkSubsystemCallbackKind_video_shared_destroy 9u
#define R4SdkSubsystemCallbackKind_video_shared_map 10u
#define R4SdkSubsystemCallbackKind_video_shared_publish 11u
#define R4SdkSubsystemCallbackKind_video_shared_submit 12u
#define R4SdkSubsystemCallbackKind_video_commit_full 13u
#define R4SdkSubsystemCallbackKind_video_commit_damage 14u
#define R4SdkSubsystemCallbackKind_video_cancel 15u
#define R4SdkSubsystemCallbackKind_video_overlay 16u
#define R4SdkSubsystemCallbackKind_guest_step 17u
#define R4SdkSubsystemCallbackKind_guest_reset 18u
#define R4SdkSubsystemCallbackKind_guest_audio 19u
#define R4SdkSubsystemCallbackKind_guest_feedback 20u
#define R4SdkSubsystemCallbackKind_host_poll 21u
#define R4SdkSubsystemCallbackKind_host_present 22u
#define R4SdkSubsystemCallbackKind_host_wait 23u
#define R4SdkSubsystemCallbackKind_host_close 24u
#define R4SdkSubsystemCallbackKind_audio_open 25u
#define R4SdkSubsystemCallbackKind_audio_write 26u
#define R4SdkSubsystemCallbackKind_audio_volume 27u
#define R4SdkSubsystemCallbackKind_audio_close 28u
#define R4SdkSubsystemCallbackKind_save_acquire 29u
#define R4SdkSubsystemCallbackKind_save_release 30u
#define R4SdkSubsystemCallbackKind_save_read 31u
#define R4SdkSubsystemCallbackKind_save_write 32u
#define R4SdkSubsystemCallbackKind_save_poll 33u
#define R4SdkSubsystemCallbackKind_save_drain 34u
#define R4SdkSubsystemCallbackKind_save_pending 35u
#define R4SdkSubsystemCallbackKind_validate_rtc 36u
#define R4SdkSubsystemCallbackKind_validate_delta 37u
#define R4SdkSubsystemCallbackKind_audio_poll 38u
#define R4SdkSubsystemCallbackKind_audio_finish 39u
/* subsystem_catalog.assumeHostPresent -> subsystem_catalog.HostState */
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalog_assumeHostPresent(uint32_t reserved, R4SdkSubsystemSlot p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = p0;
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,0u,a,2u,0);
}
/* subsystem_catalog.resolve -> error{InvalidAssociation,InvalidInput,StaleAssociation,TooManyCandidates}!void */
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalog_resolve(uint32_t reserved, const R4SdkSubsystemCatalogCatalog * p0, const R4SdkSubsystemCatalogInput * p1, const R4SdkSubsystemCatalogPolicy * p2, R4SdkSubsystemCatalogResolution * p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,1u,a,4u,0);
}
/* subsystem_launch.encode -> error{BufferTooSmall,DuplicateGuest,InvalidGuestPath,InvalidKey,InvalidMagic,InvalidValue,MalformedRecord,MissingGuest,TooManyOptions}![]const u8 */
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunch_encode(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const R4SdkSubsystemLaunchOption * p1, uintptr_t n1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,2u,a,3u,0);
}
/* subsystem_launch.parse -> error{BufferTooSmall,DuplicateGuest,InvalidGuestPath,InvalidKey,InvalidMagic,InvalidValue,MalformedRecord,MissingGuest,TooManyOptions}!subsystem_launch.Request */
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunch_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkSubsystemLaunchRequest *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,3u,a,1u,output);
}
/* subsystem_host.calculateViewport -> error{BufferTooSmall,InvalidSize,Overflow,PaletteTooSmall,ScratchTooSmall,UnsupportedDrawContract,WindowUnavailable}!subsystem_host.Viewport */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideo_calculateViewport(uint32_t reserved, int32_t p0, int32_t p1, uint32_t p2, uint32_t p3, R4SdkSubsystemVideoViewport *output) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,4u,a,4u,output);
}
/* subsystem_persistence.digestHex -> []const u8 */
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistence_digestHex(uint32_t reserved, const R4SdkDataNative_Value158 * p0, R4SdkSubsystemNativeValue131 * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,5u,a,2u,0);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).dataPath -> @typeInfo(@typeInfo(@TypeOf(subsystem_persistence.R4osStore(subsystem_persistence.Configuration).dataPathConfigured)).@"fn".return_type.?).error_union.error_set!path.AbsoluteFilePath */
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__dataPath(uint32_t reserved, const R4SdkSubsystemPersistenceConfiguration * p0, const R4SdkDataNative_Value158 * p1, uint32_t p2, R4SdkSubsystemNative_path_AbsoluteFilePath *output) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,6u,a,3u,output);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).wallSeconds -> ?i64 */
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__wallSeconds(uint32_t reserved, const R4TimeState * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,7u,a,1u,0);
}
/* subsystem_helper_adapters.hostVerifier -> error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_catalog.HostVerifier */
static inline R4SdkSubsystemSlot R4SdkSubsystem_hostVerifier(uint32_t reserved, const R4SdkSubsystemCallbackTable * p0, R4SdkSubsystemCatalogHostVerifier *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,8u,a,1u,output);
}
/* subsystem_helper_adapters.videoBackend -> error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_host.Backend */
static inline R4SdkSubsystemSlot R4SdkSubsystem_videoBackend(uint32_t reserved, const R4SdkSubsystemCallbackTable * p0, uint8_t p1, uint8_t p2, uint8_t p3, R4SdkSubsystemVideoBackend *output) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,9u,a,4u,output);
}
/* subsystem_helper_adapters.overlay -> error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_host.FrameOverlay */
static inline R4SdkSubsystemSlot R4SdkSubsystem_overlay(uint32_t reserved, const R4SdkSubsystemCallbackTable * p0, R4SdkSubsystemVideoFrameOverlay *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,10u,a,1u,output);
}
/* subsystem_helper_adapters.guestDriver -> error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_runtime.GuestDriver */
static inline R4SdkSubsystemSlot R4SdkSubsystem_guestDriver(uint32_t reserved, const R4SdkSubsystemCallbackTable * p0, R4SdkSubsystemRuntimeGuestDriver *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,11u,a,1u,output);
}
/* subsystem_helper_adapters.hostDriver -> error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_runtime.HostDriver */
static inline R4SdkSubsystemSlot R4SdkSubsystem_hostDriver(uint32_t reserved, const R4SdkSubsystemCallbackTable * p0, R4SdkSubsystemRuntimeHostDriver *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,12u,a,1u,output);
}
/* subsystem_helper_adapters.audioSink -> error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_runtime.AudioSink */
static inline R4SdkSubsystemSlot R4SdkSubsystem_audioSink(uint32_t reserved, const R4SdkSubsystemCallbackTable * p0, R4SdkSubsystemRuntimeAudioSink *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,13u,a,1u,output);
}
/* subsystem_helper_adapters.persistenceBackend -> error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_persistence.Backend */
static inline R4SdkSubsystemSlot R4SdkSubsystem_persistenceBackend(uint32_t reserved, const R4SdkSubsystemCallbackTable * p0, R4SdkSubsystemPersistenceBackend *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,14u,a,1u,output);
}
/* subsystem_helper_adapters.persistenceConfiguration -> error{InvalidConfiguration,MissingCallback,Unavailable}!subsystem_persistence.Configuration */
static inline R4SdkSubsystemSlot R4SdkSubsystem_persistenceConfiguration(uint32_t reserved, const R4SdkSubsystemCallbackTable * p0, const uint8_t * p1, uintptr_t n1, const R4SdkDataNative_Value31 * p2, uintptr_t n2, uint64_t p3, uint64_t p4, uint8_t * p5, uintptr_t n5, R4SdkSubsystemPersistenceConfiguration *output) {
 (void)reserved; R4SdkSubsystemSlot a[6]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,15u,a,6u,output);
}
/* subsystem_helper_adapters.open -> bool */
static inline R4SdkSubsystemSlot R4SdkSubsystem_open(uint32_t reserved, R4SdkSubsystemContext * p0, const R4XStartContext * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,16u,a,2u,0);
}
/* subsystem_helper_adapters.guiHost -> error{BufferTooSmall,InvalidSize,Overflow,PaletteTooSmall,ScratchTooSmall,UnsupportedDrawContract,WindowUnavailable}!void */
static inline R4SdkSubsystemSlot R4SdkSubsystem_guiHost(uint32_t reserved, R4SdkSubsystemVideoHost * p0, const R4SdkSubsystemContext * p1, const R4SdkSubsystemVideoSurface * p2, uint32_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,17u,a,4u,0);
}
/* subsystem_helper_adapters.drawBackend -> subsystem_host.Backend */
static inline R4SdkSubsystemSlot R4SdkSubsystem_drawBackend(uint32_t reserved, const R4SdkSubsystemContext * p0, R4SdkSubsystemVideoBackend *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,18u,a,1u,output);
}
/* subsystem_helper_adapters.platformAudio -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystem_platformAudio(uint32_t reserved, R4SdkSubsystemRuntimeR4AudioSink * p0, const R4SdkSubsystemContext * p1, uint64_t p2, uint64_t p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,19u,a,4u,0);
}
/* subsystem_helper_adapters.platformFiles -> app_storage.Files */
static inline R4SdkSubsystemSlot R4SdkSubsystem_platformFiles(uint32_t reserved, const R4SdkSubsystemContext * p0, R4SdkSubsystemNative_app_storage_Files *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,20u,a,1u,output);
}
/* subsystem_helper_adapters.run -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystem_run(uint32_t reserved, R4SdkSubsystemRuntimeRuntime * p0, const R4SdkSubsystemContext * p1, const R4SdkSubsystemRuntimeGuestDriver * p2, const R4SdkSubsystemRuntimeHostDriver * p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,21u,a,4u,0);
}
/* subsystem_catalog.Entry.supportsFormat -> bool */
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_supportsFormat(uint32_t reserved, const R4SdkSubsystemCatalogEntry * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,22u,a,2u,0);
}
/* subsystem_catalog.Entry.mapsExtension -> bool */
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_mapsExtension(uint32_t reserved, const R4SdkSubsystemCatalogEntry * p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,23u,a,3u,0);
}
/* subsystem_catalog.Catalog.loadInstalled -> error{HostCheckFailed,InvalidInventory,MissingHost,TooManySubsystems}!void */
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCatalog_loadInstalled(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateInventoryInventory * p1, R4SdkSubsystemCatalogCatalog * p2, const R4SdkSubsystemCatalogHostVerifier * p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,24u,a,4u,0);
}
/* subsystem_catalog.Catalog.render -> ?[]const u8 */
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCatalog_render(uint32_t reserved, const R4SdkSubsystemCatalogCatalog * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,25u,a,2u,0);
}
/* subsystem_catalog.Resolution.slice -> []const subsystem_catalog.Candidate */
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolution_slice(uint32_t reserved, const R4SdkSubsystemCatalogResolution * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,26u,a,1u,0);
}
/* subsystem_catalog.Resolution.selected -> ?subsystem_catalog.Candidate */
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolution_selected(uint32_t reserved, const R4SdkSubsystemCatalogResolution * p0, R4SdkSubsystemCatalogCandidate *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,27u,a,1u,output);
}
/* subsystem_launch.Request.options -> subsystem_launch.OptionIterator */
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchRequest_options(uint32_t reserved, const R4SdkSubsystemLaunchRequest * p0, R4SdkSubsystemLaunchOptionIterator *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,28u,a,1u,output);
}
/* subsystem_launch.Request.option -> error{BufferTooSmall,DuplicateGuest,InvalidGuestPath,InvalidKey,InvalidMagic,InvalidValue,MalformedRecord,MissingGuest,TooManyOptions}!?[]const u8 */
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchRequest_option(uint32_t reserved, const R4SdkSubsystemLaunchRequest * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,29u,a,2u,0);
}
/* subsystem_launch.OptionIterator.next -> error{BufferTooSmall,DuplicateGuest,InvalidGuestPath,InvalidKey,InvalidMagic,InvalidValue,MalformedRecord,MissingGuest,TooManyOptions}!?subsystem_launch.Option */
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOptionIterator_next(uint32_t reserved, R4SdkSubsystemLaunchOptionIterator * p0, R4SdkSubsystemLaunchOption *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,30u,a,1u,output);
}
/* subsystem_host.Surface.initIndexed8 -> error{BufferTooSmall,InvalidSize,Overflow,PaletteTooSmall,ScratchTooSmall,UnsupportedDrawContract,WindowUnavailable}!subsystem_host.Surface */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_initIndexed8(uint32_t reserved, uint8_t * p0, uintptr_t n0, uint32_t * p1, uintptr_t n1, uint32_t p2, uint32_t p3, R4SdkSubsystemVideoSurface *output) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,31u,a,4u,output);
}
/* subsystem_host.Surface.initXrgb32 -> error{BufferTooSmall,InvalidSize,Overflow,PaletteTooSmall,ScratchTooSmall,UnsupportedDrawContract,WindowUnavailable}!subsystem_host.Surface */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_initXrgb32(uint32_t reserved, uint32_t * p0, uintptr_t n0, uint32_t p1, uint32_t p2, R4SdkSubsystemVideoSurface *output) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,32u,a,3u,output);
}
/* subsystem_host.Surface.format -> subsystem_host.PixelFormat */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_format(uint32_t reserved, const R4SdkSubsystemVideoSurface * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,33u,a,1u,0);
}
/* subsystem_host.Surface.pixelCount -> usize */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_pixelCount(uint32_t reserved, const R4SdkSubsystemVideoSurface * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,34u,a,1u,0);
}
/* subsystem_host.Surface.indexedPixels -> ?[]u8 */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_indexedPixels(uint32_t reserved, R4SdkSubsystemVideoSurface * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,35u,a,1u,0);
}
/* subsystem_host.Surface.xrgb32Pixels -> ?[]u32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_xrgb32Pixels(uint32_t reserved, R4SdkSubsystemVideoSurface * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,36u,a,1u,0);
}
/* subsystem_host.Surface.palette -> ?[]u32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_palette(uint32_t reserved, R4SdkSubsystemVideoSurface * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,37u,a,1u,0);
}
/* subsystem_host.Rect.full -> subsystem_host.Rect */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_full(uint32_t reserved, uint32_t p0, uint32_t p1, R4SdkSubsystemVideoRect *output) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,38u,a,2u,output);
}
/* subsystem_host.Rect.isEmpty -> bool */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_isEmpty(uint32_t reserved, const R4SdkSubsystemVideoRect * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,39u,a,1u,0);
}
/* subsystem_host.Viewport.isInteger -> bool */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_isInteger(uint32_t reserved, const R4SdkSubsystemVideoViewport * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,40u,a,1u,0);
}
/* subsystem_host.Viewport.mapClientPoint -> ?subsystem_host.Point */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_mapClientPoint(uint32_t reserved, const R4SdkSubsystemVideoViewport * p0, int32_t p1, int32_t p2, R4SdkSubsystemVideoPoint *output) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,41u,a,3u,output);
}
/* subsystem_host.Backend.fromDraw -> subsystem_host.Backend */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_fromDraw(uint32_t reserved, const R4SdkSubsystemNative_r4draw_Context * p0, R4SdkSubsystemVideoBackend *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,42u,a,1u,output);
}
/* subsystem_host.Presenter.init -> error{BufferTooSmall,InvalidSize,Overflow,PaletteTooSmall,ScratchTooSmall,UnsupportedDrawContract,WindowUnavailable}!subsystem_host.Presenter */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_init(uint32_t reserved, const R4SdkSubsystemVideoSurface * p0, uint32_t * p1, uintptr_t n1, R4SdkSubsystemVideoPresenter *output) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,43u,a,2u,output);
}
/* subsystem_host.Presenter.setSurface -> error{BufferTooSmall,InvalidSize,Overflow,PaletteTooSmall,ScratchTooSmall,UnsupportedDrawContract,WindowUnavailable}!void */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_setSurface(uint32_t reserved, R4SdkSubsystemVideoPresenter * p0, const R4SdkSubsystemVideoSurface * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,44u,a,2u,0);
}
/* subsystem_host.Presenter.invalidateAll -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_invalidateAll(uint32_t reserved, R4SdkSubsystemVideoPresenter * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,45u,a,1u,0);
}
/* subsystem_host.Presenter.invalidate -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_invalidate(uint32_t reserved, R4SdkSubsystemVideoPresenter * p0, const R4SdkSubsystemVideoRect * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,46u,a,2u,0);
}
/* subsystem_host.Presenter.invalidateClient -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_invalidateClient(uint32_t reserved, R4SdkSubsystemVideoPresenter * p0, const R4SdkSubsystemVideoRect * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,47u,a,2u,0);
}
/* subsystem_host.Presenter.setPaletteEntry -> bool */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_setPaletteEntry(uint32_t reserved, R4SdkSubsystemVideoPresenter * p0, uint8_t p1, uint32_t p2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,48u,a,3u,0);
}
/* subsystem_host.Presenter.currentViewport -> ?subsystem_host.Viewport */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_currentViewport(uint32_t reserved, const R4SdkSubsystemVideoPresenter * p0, R4SdkSubsystemVideoViewport *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,49u,a,1u,output);
}
/* subsystem_host.Presenter.presentTo -> subsystem_host.PresentResult */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_presentTo(uint32_t reserved, R4SdkSubsystemVideoPresenter * p0, const R4SdkSubsystemVideoBackend * p1, int32_t p2, int32_t p3, R4SdkSubsystemVideoPresentResult *output) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,50u,a,4u,output);
}
/* subsystem_host.Presenter.presentToWithOverlay -> subsystem_host.PresentResult */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_presentToWithOverlay(uint32_t reserved, R4SdkSubsystemVideoPresenter * p0, const R4SdkSubsystemVideoBackend * p1, int32_t p2, int32_t p3, R4SdkSubsystemSlot p4, R4SdkSubsystemVideoPresentResult *output) {
 (void)reserved; R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = p4;
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,51u,a,5u,output);
}
/* subsystem_host.Presenter.deinit -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_deinit(uint32_t reserved, R4SdkSubsystemVideoPresenter * p0, const R4SdkSubsystemVideoBackend * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,52u,a,2u,0);
}
/* subsystem_host.InputEvent.stamp -> subsystem_host.InputStamp */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_stamp(uint32_t reserved, const R4SdkSubsystemVideoInputEvent * p0, R4SdkSubsystemVideoInputStamp *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,53u,a,1u,output);
}
/* subsystem_host.InputTranslator.init -> subsystem_host.InputTranslator */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_init(uint32_t reserved, const R4SdkSubsystemVideoInputPolicy * p0, R4SdkSubsystemVideoInputTranslator *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,54u,a,1u,output);
}
/* subsystem_host.InputTranslator.setPolicy -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_setPolicy(uint32_t reserved, R4SdkSubsystemVideoInputTranslator * p0, const R4SdkSubsystemVideoInputPolicy * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,55u,a,2u,0);
}
/* subsystem_host.InputTranslator.requiresViewport -> bool */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_requiresViewport(uint32_t reserved, const R4SdkSubsystemVideoInputTranslator * p0, uint32_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,56u,a,2u,0);
}
/* subsystem_host.InputTranslator.takePending -> ?subsystem_host.InputEvent */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_takePending(uint32_t reserved, R4SdkSubsystemVideoInputTranslator * p0, R4SdkSubsystemVideoInputEvent *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,57u,a,1u,output);
}
/* subsystem_host.InputTranslator.translate -> ?subsystem_host.InputEvent */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_translate(uint32_t reserved, R4SdkSubsystemVideoInputTranslator * p0, const R4GuiEvent * p1, R4SdkSubsystemSlot p2, R4SdkSubsystemSlot p3, R4SdkSubsystemVideoInputEvent *output) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = p2;
 a[3] = p3;
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,58u,a,4u,output);
}
/* subsystem_host.Host.init -> error{BufferTooSmall,InvalidSize,Overflow,PaletteTooSmall,ScratchTooSmall,UnsupportedDrawContract,WindowUnavailable}!subsystem_host.Host */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_init(uint32_t reserved, const R4SdkSubsystemNative_r4desk_Context * p0, const R4SdkSubsystemNative_r4draw_Context * p1, const R4SdkSubsystemVideoSurface * p2, uint32_t * p3, uintptr_t n3, R4SdkSubsystemVideoHost *output) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,59u,a,4u,output);
}
/* subsystem_host.Host.setTitle -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_setTitle(uint32_t reserved, R4SdkSubsystemVideoHost * p0, const uint8_t * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,60u,a,2u,0);
}
/* subsystem_host.Host.setMinimumSize -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_setMinimumSize(uint32_t reserved, R4SdkSubsystemVideoHost * p0, int32_t p1, int32_t p2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,61u,a,3u,0);
}
/* subsystem_host.Host.setInputPolicy -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_setInputPolicy(uint32_t reserved, R4SdkSubsystemVideoHost * p0, const R4SdkSubsystemVideoInputPolicy * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,62u,a,2u,0);
}
/* subsystem_host.Host.present -> subsystem_host.PresentResult */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_present(uint32_t reserved, R4SdkSubsystemVideoHost * p0, R4SdkSubsystemVideoPresentResult *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,63u,a,1u,output);
}
/* subsystem_host.Host.pollInput -> ?subsystem_host.InputEvent */
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_pollInput(uint32_t reserved, R4SdkSubsystemVideoHost * p0, R4SdkSubsystemVideoInputEvent *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,64u,a,1u,output);
}
/* subsystem_runtime.StepResult.progress -> subsystem_runtime.StepResult */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_progress(uint32_t reserved, uint8_t p0, R4SdkSubsystemRuntimeStepResult *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,65u,a,1u,output);
}
/* subsystem_runtime.StepResult.waitUntil -> subsystem_runtime.StepResult */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_waitUntil(uint32_t reserved, uint64_t p0, uint8_t p1, R4SdkSubsystemRuntimeStepResult *output) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,66u,a,2u,output);
}
/* subsystem_runtime.StepResult.complete -> subsystem_runtime.StepResult */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_complete(uint32_t reserved, int32_t p0, uint8_t p1, R4SdkSubsystemRuntimeStepResult *output) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,67u,a,2u,output);
}
/* subsystem_runtime.StepResult.fail -> subsystem_runtime.StepResult */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_fail(uint32_t reserved, int32_t p0, R4SdkSubsystemRuntimeStepResult *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,68u,a,1u,output);
}
/* subsystem_runtime.StepResult.withOperations -> subsystem_runtime.StepResult */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_withOperations(uint32_t reserved, const R4SdkSubsystemRuntimeStepResult * p0, uint32_t p1, R4SdkSubsystemRuntimeStepResult *output) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,69u,a,2u,output);
}
/* subsystem_runtime.GuestDriver.step -> subsystem_runtime.StepResult */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_step(uint32_t reserved, const R4SdkSubsystemRuntimeGuestDriver * p0, uint32_t p1, uint64_t p2, R4SdkSubsystemRuntimeStepResult *output) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,70u,a,3u,output);
}
/* subsystem_runtime.GuestDriver.reset -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_reset(uint32_t reserved, const R4SdkSubsystemRuntimeGuestDriver * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,71u,a,1u,0);
}
/* subsystem_runtime.GuestDriver.renderAudio -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_renderAudio(uint32_t reserved, const R4SdkSubsystemRuntimeGuestDriver * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,72u,a,2u,0);
}
/* subsystem_runtime.GuestDriver.audioFeedback -> bool */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_audioFeedback(uint32_t reserved, const R4SdkSubsystemRuntimeGuestDriver * p0, const R4SdkSubsystemRuntimeAudioFeedback * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,73u,a,2u,0);
}
/* subsystem_runtime.HostDriver.poll -> subsystem_runtime.HostPollResult */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_poll(uint32_t reserved, const R4SdkSubsystemRuntimeHostDriver * p0, R4SdkSubsystemRuntimeHostPollResult *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,74u,a,1u,output);
}
/* subsystem_runtime.HostDriver.present -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_present(uint32_t reserved, const R4SdkSubsystemRuntimeHostDriver * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,75u,a,1u,0);
}
/* subsystem_runtime.HostDriver.wait -> ?i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_wait(uint32_t reserved, const R4SdkSubsystemRuntimeHostDriver * p0, uint64_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,76u,a,2u,0);
}
/* subsystem_runtime.HostDriver.shouldClose -> ?bool */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_shouldClose(uint32_t reserved, const R4SdkSubsystemRuntimeHostDriver * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,77u,a,1u,0);
}
/* subsystem_runtime.GuestClock.init -> error{AudioQueueTooSmall,AudioScratchTooSmall,InvalidAudioConfiguration,InvalidConfiguration,Overflow,UnknownFrequency}!subsystem_runtime.GuestClock */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_init(uint32_t reserved, uint32_t p0, uint64_t p1, R4SdkSubsystemRuntimeGuestClock *output) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,78u,a,2u,output);
}
/* subsystem_runtime.GuestClock.sync -> u64 */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_sync(uint32_t reserved, R4SdkSubsystemRuntimeGuestClock * p0, uint64_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,79u,a,2u,0);
}
/* subsystem_runtime.GuestClock.pause -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_pause(uint32_t reserved, R4SdkSubsystemRuntimeGuestClock * p0, uint64_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,80u,a,2u,0);
}
/* subsystem_runtime.GuestClock.resumeAt -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_resumeAt(uint32_t reserved, R4SdkSubsystemRuntimeGuestClock * p0, uint64_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,81u,a,2u,0);
}
/* subsystem_runtime.GuestClock.reset -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_reset(uint32_t reserved, R4SdkSubsystemRuntimeGuestClock * p0, uint64_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,82u,a,2u,0);
}
/* subsystem_runtime.GuestClock.ticksUntil -> u64 */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_ticksUntil(uint32_t reserved, const R4SdkSubsystemRuntimeGuestClock * p0, uint64_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,83u,a,2u,0);
}
/* subsystem_runtime.Pacer.initHz -> error{AudioQueueTooSmall,AudioScratchTooSmall,InvalidAudioConfiguration,InvalidConfiguration,Overflow,UnknownFrequency}!subsystem_runtime.Pacer */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePacer_initHz(uint32_t reserved, uint32_t p0, R4SdkSubsystemRuntimePacer *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,84u,a,1u,output);
}
/* subsystem_runtime.Pacer.reset -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePacer_reset(uint32_t reserved, R4SdkSubsystemRuntimePacer * p0, uint64_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,85u,a,2u,0);
}
/* subsystem_runtime.Pacer.take -> bool */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePacer_take(uint32_t reserved, R4SdkSubsystemRuntimePacer * p0, uint64_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,86u,a,2u,0);
}
/* subsystem_runtime.Pacer.deadline -> u64 */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePacer_deadline(uint32_t reserved, const R4SdkSubsystemRuntimePacer * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,87u,a,1u,0);
}
/* subsystem_runtime.AudioConfig.frameBytes -> error{AudioQueueTooSmall,AudioScratchTooSmall,InvalidAudioConfiguration,InvalidConfiguration,Overflow,UnknownFrequency}!usize */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_frameBytes(uint32_t reserved, const R4SdkSubsystemRuntimeAudioConfig * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,88u,a,1u,0);
}
/* subsystem_runtime.AudioConfig.quantumBytes -> error{AudioQueueTooSmall,AudioScratchTooSmall,InvalidAudioConfiguration,InvalidConfiguration,Overflow,UnknownFrequency}!usize */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_quantumBytes(uint32_t reserved, const R4SdkSubsystemRuntimeAudioConfig * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,89u,a,1u,0);
}
/* subsystem_runtime.AudioConfig.targetBytes -> error{AudioQueueTooSmall,AudioScratchTooSmall,InvalidAudioConfiguration,InvalidConfiguration,Overflow,UnknownFrequency}!usize */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_targetBytes(uint32_t reserved, const R4SdkSubsystemRuntimeAudioConfig * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,90u,a,1u,0);
}
/* subsystem_runtime.R4AudioSink.init -> subsystem_runtime.R4AudioSink */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_init(uint32_t reserved, const R4SdkSubsystemNative_app_audio_Audio * p0, R4SdkSubsystemRuntimeR4AudioSink *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,91u,a,1u,output);
}
/* subsystem_runtime.R4AudioSink.initWithTimeout -> subsystem_runtime.R4AudioSink */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_initWithTimeout(uint32_t reserved, const R4SdkSubsystemNative_app_audio_Audio * p0, uint64_t p1, R4SdkSubsystemRuntimeR4AudioSink *output) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,92u,a,2u,output);
}
/* subsystem_runtime.R4AudioSink.initWithTimeouts -> subsystem_runtime.R4AudioSink */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_initWithTimeouts(uint32_t reserved, const R4SdkSubsystemNative_app_audio_Audio * p0, uint64_t p1, uint64_t p2, R4SdkSubsystemRuntimeR4AudioSink *output) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,93u,a,3u,output);
}
/* subsystem_runtime.R4AudioSink.sink -> subsystem_runtime.AudioSink */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_sink(uint32_t reserved, R4SdkSubsystemRuntimeR4AudioSink * p0, R4SdkSubsystemRuntimeAudioSink *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,94u,a,1u,output);
}
/* subsystem_runtime.PcmQueue.init -> error{AudioQueueTooSmall,AudioScratchTooSmall,InvalidAudioConfiguration,InvalidConfiguration,Overflow,UnknownFrequency}!subsystem_runtime.PcmQueue */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_init(uint32_t reserved, uint8_t * p0, uintptr_t n0, uint64_t p1, R4SdkSubsystemRuntimePcmQueue *output) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,95u,a,2u,output);
}
/* subsystem_runtime.PcmQueue.available -> usize */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_available(uint32_t reserved, const R4SdkSubsystemRuntimePcmQueue * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,96u,a,1u,0);
}
/* subsystem_runtime.PcmQueue.free -> usize */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_free(uint32_t reserved, const R4SdkSubsystemRuntimePcmQueue * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,97u,a,1u,0);
}
/* subsystem_runtime.PcmQueue.clear -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_clear(uint32_t reserved, R4SdkSubsystemRuntimePcmQueue * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,98u,a,1u,0);
}
/* subsystem_runtime.PcmQueue.write -> usize */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_write(uint32_t reserved, R4SdkSubsystemRuntimePcmQueue * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,99u,a,2u,0);
}
/* subsystem_runtime.PcmQueue.peek -> usize */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_peek(uint32_t reserved, const R4SdkSubsystemRuntimePcmQueue * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,100u,a,2u,0);
}
/* subsystem_runtime.PcmQueue.discard -> usize */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_discard(uint32_t reserved, R4SdkSubsystemRuntimePcmQueue * p0, uint64_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,101u,a,2u,0);
}
/* subsystem_runtime.PcmQueue.read -> usize */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_read(uint32_t reserved, R4SdkSubsystemRuntimePcmQueue * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,102u,a,2u,0);
}
/* subsystem_runtime.Runtime.init -> error{AudioQueueTooSmall,AudioScratchTooSmall,InvalidAudioConfiguration,InvalidConfiguration,Overflow,UnknownFrequency}!subsystem_runtime.Runtime */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_init(uint32_t reserved, const R4SdkSubsystemRuntimeConfig * p0, uint32_t p1, uint64_t p2, R4SdkSubsystemSlot p3, R4SdkSubsystemRuntimeRuntime *output) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = p3;
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,103u,a,4u,output);
}
/* subsystem_runtime.Runtime.start -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_start(uint32_t reserved, R4SdkSubsystemRuntimeRuntime * p0, uint64_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,104u,a,2u,0);
}
/* subsystem_runtime.Runtime.request -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_request(uint32_t reserved, R4SdkSubsystemRuntimeRuntime * p0, uint32_t p1, uint64_t p2, const R4SdkSubsystemRuntimeGuestDriver * p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,105u,a,4u,0);
}
/* subsystem_runtime.Runtime.cycle -> subsystem_runtime.CycleResult */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_cycle(uint32_t reserved, R4SdkSubsystemRuntimeRuntime * p0, uint64_t p1, const R4SdkSubsystemRuntimeGuestDriver * p2, const R4SdkSubsystemRuntimeHostDriver * p3, R4SdkSubsystemRuntimeCycleResult *output) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,106u,a,4u,output);
}
/* subsystem_runtime.Runtime.run -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_run(uint32_t reserved, R4SdkSubsystemRuntimeRuntime * p0, const R4SdkSubsystemNative_r4sys_Context * p1, const R4SdkSubsystemRuntimeGuestDriver * p2, const R4SdkSubsystemRuntimeHostDriver * p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,107u,a,4u,0);
}
/* subsystem_runtime.Runtime.shutdown -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_shutdown(uint32_t reserved, R4SdkSubsystemRuntimeRuntime * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,108u,a,1u,0);
}
/* subsystem_persistence.Backend.acquire -> error{Busy,Full,Io,Unsupported}!void */
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_acquire(uint32_t reserved, const R4SdkSubsystemPersistenceBackend * p0, const R4SdkDataNative_Value158 * p1, uint64_t p2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,109u,a,3u,0);
}
/* subsystem_persistence.Backend.release -> error{Busy,Full,Io,Unsupported}!void */
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_release(uint32_t reserved, const R4SdkSubsystemPersistenceBackend * p0, const R4SdkDataNative_Value158 * p1, uint64_t p2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,110u,a,3u,0);
}
/* subsystem_persistence.Backend.readExact -> subsystem_persistence.ReadResult */
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_readExact(uint32_t reserved, const R4SdkSubsystemPersistenceBackend * p0, const R4SdkDataNative_Value158 * p1, uint32_t p2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,111u,a,4u,0);
}
/* subsystem_persistence.Backend.writeAtomic -> error{Busy,Full,Io,Unsupported}!void */
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_writeAtomic(uint32_t reserved, const R4SdkSubsystemPersistenceBackend * p0, const R4SdkDataNative_Value158 * p1, uint32_t p2, const uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,112u,a,4u,0);
}
/* subsystem_persistence.Backend.drain -> error{Busy,Full,Io,Unsupported}!void */
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_drain(uint32_t reserved, const R4SdkSubsystemPersistenceBackend * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,113u,a,1u,0);
}
/* subsystem_persistence.Backend.pending -> bool */
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_pending(uint32_t reserved, const R4SdkSubsystemPersistenceBackend * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,114u,a,1u,0);
}
/* subsystem_persistence.Backend.poll -> error{Busy,Full,Io,Unsupported}!void */
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_poll(uint32_t reserved, const R4SdkSubsystemPersistenceBackend * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,115u,a,1u,0);
}
/* subsystem_persistence.Configuration.valid -> bool */
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_valid(uint32_t reserved, const R4SdkSubsystemPersistenceConfiguration * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,116u,a,1u,0);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).Store.init -> subsystem_persistence.R4osStore(subsystem_persistence.Configuration).Store */
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_init(uint32_t reserved, const R4SdkSubsystemNative_app_storage_Files * p0, const R4SdkSubsystemPersistenceConfiguration * p1, R4SdkSubsystemStore *output) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,117u,a,2u,output);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).Store.backend -> subsystem_persistence.Backend */
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_backend(uint32_t reserved, R4SdkSubsystemStore * p0, R4SdkSubsystemPersistenceBackend *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,118u,a,1u,output);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).Store.failureStageName -> []const u8 */
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_failureStageName(uint32_t reserved, const R4SdkSubsystemStore * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,119u,a,1u,0);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).Store.failureCode -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_failureCode(uint32_t reserved, const R4SdkSubsystemStore * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,120u,a,1u,0);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).Store.removeTestFiles -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_removeTestFiles(uint32_t reserved, R4SdkSubsystemStore * p0, const R4SdkDataNative_Value158 * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,121u,a,2u,0);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).Store.prepareInterruptedPublishForTest -> error{Busy,Full,Io,Unsupported}!void */
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_prepareInterruptedPublishForTest(uint32_t reserved, R4SdkSubsystemStore * p0, const R4SdkDataNative_Value158 * p1, uint32_t p2, const uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,122u,a,4u,0);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).Store.recoveryTestStateForTest -> error{Busy,Full,Io,Unsupported}!subsystem_persistence.R4osStore(subsystem_persistence.Configuration).RecoveryTestState */
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_recoveryTestStateForTest(uint32_t reserved, R4SdkSubsystemStore * p0, const R4SdkDataNative_Value158 * p1, uint32_t p2, R4SdkSubsystemRecoveryTestState *output) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,123u,a,3u,output);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncStore.init -> subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncStore */
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_init(uint32_t reserved, const R4SdkSubsystemNative_app_storage_Files * p0, const R4SdkDataAllocator * p1, const R4SdkSubsystemPersistenceConfiguration * p2, R4SdkSubsystemAsyncStore *output) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,124u,a,3u,output);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncStore.backend -> subsystem_persistence.Backend */
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_backend(uint32_t reserved, R4SdkSubsystemAsyncStore * p0, R4SdkSubsystemPersistenceBackend *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,125u,a,1u,output);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncStore.failureStageName -> []const u8 */
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_failureStageName(uint32_t reserved, const R4SdkSubsystemAsyncStore * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,126u,a,1u,0);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncStore.failureCode -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_failureCode(uint32_t reserved, const R4SdkSubsystemAsyncStore * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,127u,a,1u,0);
}
/* subsystem_persistence.R4osStore(subsystem_persistence.Configuration).AsyncStore.removeTestFiles -> void */
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_removeTestFiles(uint32_t reserved, R4SdkSubsystemAsyncStore * p0, const R4SdkDataNative_Value158 * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,128u,a,2u,0);
}
/* path.AbsoluteFilePath.parse -> error{ComponentTooLong,EmbeddedNul,Empty,ExpectedAbsolute,ExpectedRelative,InvalidCharacter,RootTraversal,TooLong}!path.AbsoluteFilePath */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_AbsoluteFilePath_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkSubsystemNative_path_AbsoluteFilePath *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,129u,a,1u,output);
}
/* path.AbsoluteFilePath.bytes -> []const u8 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_AbsoluteFilePath_bytes(uint32_t reserved, const R4SdkSubsystemNative_path_AbsoluteFilePath * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,130u,a,1u,0);
}
/* path.AbsoluteFilePath.asZ -> path.PathZ */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_AbsoluteFilePath_asZ(uint32_t reserved, const R4SdkSubsystemNative_path_AbsoluteFilePath * p0, R4SdkSubsystemNative_path_PathZ *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,131u,a,1u,output);
}
/* subsystem_callback_bridge.Table.has -> bool */
static inline R4SdkSubsystemSlot R4SdkSubsystemCallbackTable_has(uint32_t reserved, const R4SdkSubsystemCallbackTable * p0, uint32_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,132u,a,2u,0);
}
/* r4audio.Context.init -> r4audio.Context */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_init(uint32_t reserved, const R4SdkSubsystemNative_program_Bundle * p0, R4SdkSubsystemNative_r4audio_Context *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,133u,a,1u,output);
}
/* r4audio.Context.fromProgram -> r4audio.Context */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_fromProgram(uint32_t reserved, const R4SdkSubsystemNative_program_Context * p0, R4SdkSubsystemNative_r4audio_Context *output) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,134u,a,1u,output);
}
/* r4audio.Context.audioOpenStream -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioOpenStream(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint16_t p2, uint32_t p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,135u,a,4u,0);
}
/* r4audio.Context.audioOutputInfo -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioOutputInfo(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, R4AudioOutputInfo * p2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,136u,a,3u,0);
}
/* r4audio.Context.audioOutputCatalog -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioOutputCatalog(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, R4AudioOutputInfo * p1, uintptr_t n1, R4AudioOutputCatalog * p2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,137u,a,3u,0);
}
/* r4audio.Context.audioSelectOutput -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioSelectOutput(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, const R4SdkSubsystemNativeValue131 * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,138u,a,2u,0);
}
/* r4audio.Context.audioWrite -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioWrite(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,139u,a,3u,0);
}
/* r4audio.Context.audioClose -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioClose(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,140u,a,2u,0);
}
/* r4audio.Context.audioStreamProgress -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioStreamProgress(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint64_t p2, R4AudioStreamProgress * p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,141u,a,4u,0);
}
/* r4audio.Context.audioSetStreamExpectation -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioSetStreamExpectation(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, const R4AudioStreamExpectation * p2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,142u,a,3u,0);
}
/* r4audio.Context.audioCloseStreamProgress -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioCloseStreamProgress(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint64_t p2, R4AudioStreamProgress * p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,143u,a,4u,0);
}
/* r4audio.Context.audioSetVolume -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioSetVolume(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint32_t p2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,144u,a,3u,0);
}
/* r4audio.Context.audioServiceStatus -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioServiceStatus(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, R4AudioServiceStatus * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,145u,a,2u,0);
}
/* r4audio.Context.audioServiceSetMasterVolume -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioServiceSetMasterVolume(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, R4AudioServiceStatus * p2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,146u,a,3u,0);
}
/* r4audio.Context.audioServiceMasterState -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioServiceMasterState(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, R4AudioServiceMasterState * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,147u,a,2u,0);
}
/* r4audio.Context.audioServiceSetMasterState -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioServiceSetMasterState(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, const R4AudioServiceMasterRequest * p1, R4AudioServiceMasterState * p2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,148u,a,3u,0);
}
/* r4audio.Context.audioServiceOpenStream -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioServiceOpenStream(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint16_t p2, uint32_t p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,149u,a,4u,0);
}
/* r4audio.Context.audioServiceOpenStreamResult -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioServiceOpenStreamResult(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint16_t p2, uint32_t p3, uint32_t p4, R4AudioServiceStreamResult * p5) {
 (void)reserved; R4SdkSubsystemSlot a[6]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.ptr=(void *)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,150u,a,6u,0);
}
/* r4audio.Context.audioServiceWrite -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioServiceWrite(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,151u,a,3u,0);
}
/* r4audio.Context.audioServiceClose -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioServiceClose(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,152u,a,2u,0);
}
/* r4audio.Context.audioServiceSetVolume -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_audioServiceSetVolume(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint32_t p2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,153u,a,3u,0);
}
/* r4audio.Context.sidAcquire -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_sidAcquire(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,154u,a,1u,0);
}
/* r4audio.Context.sidWriteRegister -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_sidWriteRegister(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint8_t p2, uint8_t p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,155u,a,4u,0);
}
/* r4audio.Context.sidRelease -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_sidRelease(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,156u,a,2u,0);
}
/* r4audio.Context.sidLoadData -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_sidLoadData(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint16_t p2, const uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,157u,a,4u,0);
}
/* r4audio.Context.sidInit -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_sidInit(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint16_t p2, uint16_t p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,158u,a,4u,0);
}
/* r4audio.Context.sidPlayFrame -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_sidPlayFrame(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint16_t p2, uint16_t p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,159u,a,4u,0);
}
/* r4audio.Context.sidStop -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_sidStop(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,160u,a,2u,0);
}
/* r4audio.Context.sidModelName -> [*:0]const u8 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_sidModelName(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,161u,a,1u,0);
}
/* r4audio.Context.midiOpenSynth -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_midiOpenSynth(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, const uint8_t * p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,162u,a,2u,0);
}
/* r4audio.Context.midiSend -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_midiSend(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint8_t p2, uint8_t p3, uint8_t p4, uint8_t p5) {
 (void)reserved; R4SdkSubsystemSlot a[6]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,163u,a,6u,0);
}
/* r4audio.Context.midiRender -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_midiRender(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1, uint16_t p2) {
 (void)reserved; R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,164u,a,3u,0);
}
/* r4audio.Context.midiClose -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_midiClose(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint32_t p1) {
 (void)reserved; R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,165u,a,2u,0);
}
/* r4audio.Context.opl3WriteRegister -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_opl3WriteRegister(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0, uint8_t p1, uint8_t p2, uint8_t p3) {
 (void)reserved; R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,166u,a,4u,0);
}
/* r4audio.Context.opl3Reset -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_opl3Reset(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,167u,a,1u,0);
}
/* r4audio.Context.opl3RenderBlock -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_opl3RenderBlock(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,168u,a,1u,0);
}
/* r4audio.Context.opl3Stop -> i32 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_opl3Stop(uint32_t reserved, const R4SdkSubsystemNative_r4audio_Context * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,169u,a,1u,0);
}
/* path.PathZ.bytes -> []const u8 */
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_PathZ_bytes(uint32_t reserved, const R4SdkSubsystemNative_path_PathZ * p0) {
 (void)reserved; R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemInvoke(R4SdkSubsystem_ABI_FINGERPRINT,170u,a,1u,0);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogHostState_create(R4SdkSubsystemCatalogHostState *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,0u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogHostState_inspectNative(const R4SdkSubsystemCatalogHostState *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,0u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogHostVerifier_create(R4SdkSubsystemCatalogHostVerifier *output, uintptr_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,1u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogHostVerifier_from_fields(R4SdkSubsystemCatalogHostVerifier *output, R4SdkSubsystemSlot p0, uintptr_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = p0;
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,1u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogHostVerifier_get_context(const R4SdkSubsystemCatalogHostVerifier *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,1u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogHostVerifier_set_context(R4SdkSubsystemCatalogHostVerifier *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,1u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogHostVerifier_get_check(const R4SdkSubsystemCatalogHostVerifier *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,1u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogHostVerifier_set_check(R4SdkSubsystemCatalogHostVerifier *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,1u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogHostVerifier_inspectNative(const R4SdkSubsystemCatalogHostVerifier *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,1u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_create(R4SdkSubsystemCatalogEntry *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, const R4SdkDataNative_Value31 * p5, uintptr_t n5, const R4SdkDataNative_Value31 * p6, uintptr_t n6, const R4SdkDataNative_Value31 * p7, uintptr_t n7) {
 R4SdkSubsystemSlot a[8]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.ptr=(void *)p7,.length=n7,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,4u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_from_fields(R4SdkSubsystemCatalogEntry *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, const R4SdkDataNative_Value31 * p5, uintptr_t n5, const R4SdkDataNative_Value31 * p6, uintptr_t n6, const R4SdkDataNative_Value31 * p7, uintptr_t n7) {
 R4SdkSubsystemSlot a[8]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.ptr=(void *)p7,.length=n7,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,4u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_get_subsystem_id(const R4SdkSubsystemCatalogEntry *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_set_subsystem_id(R4SdkSubsystemCatalogEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_get_host_path(const R4SdkSubsystemCatalogEntry *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_set_host_path(R4SdkSubsystemCatalogEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_get_display_name(const R4SdkSubsystemCatalogEntry *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_set_display_name(R4SdkSubsystemCatalogEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_get_module_name(const R4SdkSubsystemCatalogEntry *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_set_module_name(R4SdkSubsystemCatalogEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_get_module_version(const R4SdkSubsystemCatalogEntry *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_set_module_version(R4SdkSubsystemCatalogEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_get_guest_formats(const R4SdkSubsystemCatalogEntry *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_set_guest_formats(R4SdkSubsystemCatalogEntry *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_get_guest_extensions(const R4SdkSubsystemCatalogEntry *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_set_guest_extensions(R4SdkSubsystemCatalogEntry *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_get_guest_features(const R4SdkSubsystemCatalogEntry *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_set_guest_features(R4SdkSubsystemCatalogEntry *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,4u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEntry_inspectNative(const R4SdkSubsystemCatalogEntry *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,4u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCatalog_create(R4SdkSubsystemCatalogCatalog *output) {
 R4SdkSubsystemSlot a[3]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,6u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCatalog_from_fields(R4SdkSubsystemCatalogCatalog *output, uint32_t p0, const R4SdkSubsystemNativeValue8 * p1, uint64_t p2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,6u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCatalog_get_profile(const R4SdkSubsystemCatalogCatalog *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,6u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCatalog_set_profile(R4SdkSubsystemCatalogCatalog *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,6u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCatalog_get_entries(const R4SdkSubsystemCatalogCatalog *self, R4SdkSubsystemNativeValue8 *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,6u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCatalog_set_entries(R4SdkSubsystemCatalogCatalog *self, const R4SdkSubsystemNativeValue8 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,6u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCatalog_get_count(const R4SdkSubsystemCatalogCatalog *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,6u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCatalog_set_count(R4SdkSubsystemCatalogCatalog *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,6u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCatalog_inspectNative(const R4SdkSubsystemCatalogCatalog *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,6u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue8_create(R4SdkSubsystemNativeValue8 *output, const R4SdkSubsystemNativeValue8 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,8u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue8_inspectNative(const R4SdkSubsystemNativeValue8 *self, R4SdkSubsystemNativeValue8 *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,8u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogAssociation_create(R4SdkSubsystemCatalogAssociation *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,9u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogAssociation_from_fields(R4SdkSubsystemCatalogAssociation *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,9u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogAssociation_get_extension(const R4SdkSubsystemCatalogAssociation *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,9u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogAssociation_set_extension(R4SdkSubsystemCatalogAssociation *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,9u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogAssociation_get_subsystem_id(const R4SdkSubsystemCatalogAssociation *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,9u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogAssociation_set_subsystem_id(R4SdkSubsystemCatalogAssociation *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,9u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogAssociation_get_format_id(const R4SdkSubsystemCatalogAssociation *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,9u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogAssociation_set_format_id(R4SdkSubsystemCatalogAssociation *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,9u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogAssociation_inspectNative(const R4SdkSubsystemCatalogAssociation *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,9u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogPolicy_create(R4SdkSubsystemCatalogPolicy *output) {
 R4SdkSubsystemSlot a[2]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,10u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogPolicy_from_fields(R4SdkSubsystemCatalogPolicy *output, const R4SdkSubsystemCatalogAssociation * p0, uintptr_t n0, const R4SdkSubsystemCatalogAssociation * p1, uintptr_t n1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,10u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogPolicy_get_user_associations(const R4SdkSubsystemCatalogPolicy *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,10u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogPolicy_set_user_associations(R4SdkSubsystemCatalogPolicy *self, const R4SdkSubsystemCatalogAssociation * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,10u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogPolicy_get_default_associations(const R4SdkSubsystemCatalogPolicy *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,10u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogPolicy_set_default_associations(R4SdkSubsystemCatalogPolicy *self, const R4SdkSubsystemCatalogAssociation * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,10u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogPolicy_inspectNative(const R4SdkSubsystemCatalogPolicy *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,10u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue11_create(R4SdkSubsystemNativeValue11 *output, const R4SdkSubsystemCatalogAssociation * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,11u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue11_inspectNative(const R4SdkSubsystemNativeValue11 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,11u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogInput_create(R4SdkSubsystemCatalogInput *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, uint64_t p2, uint8_t p3) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,12u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogInput_from_fields(R4SdkSubsystemCatalogInput *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, uint64_t p2, uint8_t p3) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,12u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogInput_get_path(const R4SdkSubsystemCatalogInput *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,12u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogInput_set_path(R4SdkSubsystemCatalogInput *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,12u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogInput_get_probe_prefix(const R4SdkSubsystemCatalogInput *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,12u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogInput_set_probe_prefix(R4SdkSubsystemCatalogInput *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,12u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogInput_get_file_size(const R4SdkSubsystemCatalogInput *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,12u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogInput_set_file_size(R4SdkSubsystemCatalogInput *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,12u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogInput_get_probe_window_complete(const R4SdkSubsystemCatalogInput *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,12u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogInput_set_probe_window_complete(R4SdkSubsystemCatalogInput *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,12u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogInput_inspectNative(const R4SdkSubsystemCatalogInput *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,12u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEvidence_create(R4SdkSubsystemCatalogEvidence *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,13u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogEvidence_inspectNative(const R4SdkSubsystemCatalogEvidence *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,13u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_create(R4SdkSubsystemCatalogCandidate *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, uint32_t p5) {
 R4SdkSubsystemSlot a[7]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,14u,a,7u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_from_fields(R4SdkSubsystemCatalogCandidate *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, uint32_t p5, uint8_t p6) {
 R4SdkSubsystemSlot a[7]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,14u,a,7u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_get_subsystem_id(const R4SdkSubsystemCatalogCandidate *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_set_subsystem_id(R4SdkSubsystemCatalogCandidate *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_get_format_id(const R4SdkSubsystemCatalogCandidate *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_set_format_id(R4SdkSubsystemCatalogCandidate *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_get_host_path(const R4SdkSubsystemCatalogCandidate *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_set_host_path(R4SdkSubsystemCatalogCandidate *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_get_display_name(const R4SdkSubsystemCatalogCandidate *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_set_display_name(R4SdkSubsystemCatalogCandidate *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_get_module_version(const R4SdkSubsystemCatalogCandidate *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_set_module_version(R4SdkSubsystemCatalogCandidate *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_get_evidence(const R4SdkSubsystemCatalogCandidate *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_set_evidence(R4SdkSubsystemCatalogCandidate *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_get_host_validation_required(const R4SdkSubsystemCatalogCandidate *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_set_host_validation_required(R4SdkSubsystemCatalogCandidate *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,14u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogCandidate_inspectNative(const R4SdkSubsystemCatalogCandidate *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,14u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolutionState_create(R4SdkSubsystemCatalogResolutionState *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,15u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolutionState_inspectNative(const R4SdkSubsystemCatalogResolutionState *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,15u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolution_create(R4SdkSubsystemCatalogResolution *output) {
 R4SdkSubsystemSlot a[3]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,16u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolution_from_fields(R4SdkSubsystemCatalogResolution *output, uint32_t p0, const R4SdkSubsystemNativeValue17 * p1, uint64_t p2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,16u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolution_get_state(const R4SdkSubsystemCatalogResolution *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,16u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolution_set_state(R4SdkSubsystemCatalogResolution *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,16u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolution_get_candidates(const R4SdkSubsystemCatalogResolution *self, R4SdkSubsystemNativeValue17 *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,16u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolution_set_candidates(R4SdkSubsystemCatalogResolution *self, const R4SdkSubsystemNativeValue17 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,16u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolution_get_count(const R4SdkSubsystemCatalogResolution *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,16u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolution_set_count(R4SdkSubsystemCatalogResolution *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,16u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCatalogResolution_inspectNative(const R4SdkSubsystemCatalogResolution *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,16u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue17_create(R4SdkSubsystemNativeValue17 *output, const R4SdkSubsystemNativeValue17 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,17u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue17_inspectNative(const R4SdkSubsystemNativeValue17 *self, R4SdkSubsystemNativeValue17 *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,17u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue18_create(R4SdkSubsystemNativeValue18 *output, const R4SdkSubsystemCatalogCatalog * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,18u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue18_inspectNative(const R4SdkSubsystemNativeValue18 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,18u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue19_create(R4SdkSubsystemNativeValue19 *output, R4SdkSubsystemCatalogResolution * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,19u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue19_inspectNative(const R4SdkSubsystemNativeValue19 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,19u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue20_inspectNative(const R4SdkSubsystemNativeValue20 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,20u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOption_create(R4SdkSubsystemLaunchOption *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,21u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOption_from_fields(R4SdkSubsystemLaunchOption *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,21u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOption_get_key(const R4SdkSubsystemLaunchOption *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,21u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOption_set_key(R4SdkSubsystemLaunchOption *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,21u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOption_get_value(const R4SdkSubsystemLaunchOption *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,21u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOption_set_value(R4SdkSubsystemLaunchOption *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,21u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOption_inspectNative(const R4SdkSubsystemLaunchOption *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,21u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchRequest_create(R4SdkSubsystemLaunchRequest *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, uint64_t p2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,22u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchRequest_from_fields(R4SdkSubsystemLaunchRequest *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, uint64_t p2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,22u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchRequest_get_encoded(const R4SdkSubsystemLaunchRequest *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,22u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchRequest_set_encoded(R4SdkSubsystemLaunchRequest *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,22u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchRequest_get_guest_path(const R4SdkSubsystemLaunchRequest *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,22u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchRequest_set_guest_path(R4SdkSubsystemLaunchRequest *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,22u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchRequest_get_option_count(const R4SdkSubsystemLaunchRequest *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,22u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchRequest_set_option_count(R4SdkSubsystemLaunchRequest *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,22u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchRequest_inspectNative(const R4SdkSubsystemLaunchRequest *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,22u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue23_create(R4SdkSubsystemNativeValue23 *output, const R4SdkSubsystemLaunchOption * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,23u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue23_inspectNative(const R4SdkSubsystemNativeValue23 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,23u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue25_inspectNative(const R4SdkSubsystemNativeValue25 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,25u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue26_inspectNative(const R4SdkSubsystemNativeValue26 *self, R4SdkSubsystemLaunchRequest *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,26u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOptionIterator_create(R4SdkSubsystemLaunchOptionIterator *output, const uint8_t * p0, uintptr_t n0) {
 R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,27u,a,1u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOptionIterator_from_fields(R4SdkSubsystemLaunchOptionIterator *output, const uint8_t * p0, uintptr_t n0) {
 R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,27u,a,1u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOptionIterator_get_remaining(const R4SdkSubsystemLaunchOptionIterator *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,27u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOptionIterator_set_remaining(R4SdkSubsystemLaunchOptionIterator *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,27u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemLaunchOptionIterator_inspectNative(const R4SdkSubsystemLaunchOptionIterator *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,27u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPixelFormat_create(R4SdkSubsystemVideoPixelFormat *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,28u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPixelFormat_inspectNative(const R4SdkSubsystemVideoPixelFormat *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,28u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexed8_create(R4SdkSubsystemVideoIndexed8 *output, uint8_t * p0, uintptr_t n0, uint32_t * p1, uintptr_t n1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,29u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexed8_from_fields(R4SdkSubsystemVideoIndexed8 *output, uint8_t * p0, uintptr_t n0, uint32_t * p1, uintptr_t n1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,29u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexed8_get_pixels(const R4SdkSubsystemVideoIndexed8 *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,29u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexed8_set_pixels(R4SdkSubsystemVideoIndexed8 *self, uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,29u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexed8_get_palette(const R4SdkSubsystemVideoIndexed8 *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,29u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexed8_set_palette(R4SdkSubsystemVideoIndexed8 *self, uint32_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,29u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexed8_inspectNative(const R4SdkSubsystemVideoIndexed8 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,29u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue30_create(R4SdkSubsystemNativeValue30 *output, uint32_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,30u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue30_inspectNative(const R4SdkSubsystemNativeValue30 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,30u,(void *)self,0); }
#define R4SdkSubsystemVideoPixelStorage_TAG_indexed8 0u
#define R4SdkSubsystemVideoPixelStorage_TAG_xrgb32 1u
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPixelStorage_get_indexed8(const R4SdkSubsystemVideoPixelStorage *self, R4SdkSubsystemVideoIndexed8 *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,31u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPixelStorage_set_indexed8(R4SdkSubsystemVideoPixelStorage *self, const R4SdkSubsystemVideoIndexed8 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,31u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPixelStorage_get_xrgb32(const R4SdkSubsystemVideoPixelStorage *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,31u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPixelStorage_set_xrgb32(R4SdkSubsystemVideoPixelStorage *self, uint32_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,31u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPixelStorage_inspectNative(const R4SdkSubsystemVideoPixelStorage *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,31u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_create(R4SdkSubsystemVideoSurface *output, uint32_t p0, uint32_t p1, const R4SdkSubsystemVideoPixelStorage * p2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,32u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_from_fields(R4SdkSubsystemVideoSurface *output, uint32_t p0, uint32_t p1, const R4SdkSubsystemVideoPixelStorage * p2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,32u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_get_width(const R4SdkSubsystemVideoSurface *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,32u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_set_width(R4SdkSubsystemVideoSurface *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,32u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_get_height(const R4SdkSubsystemVideoSurface *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,32u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_set_height(R4SdkSubsystemVideoSurface *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,32u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_get_storage(const R4SdkSubsystemVideoSurface *self, R4SdkSubsystemVideoPixelStorage *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,32u,2u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_set_storage(R4SdkSubsystemVideoSurface *self, const R4SdkSubsystemVideoPixelStorage * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,32u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSurface_inspectNative(const R4SdkSubsystemVideoSurface *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,32u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_create(R4SdkSubsystemVideoRect *output, uint32_t p0, uint32_t p1, uint32_t p2, uint32_t p3) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,33u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_from_fields(R4SdkSubsystemVideoRect *output, uint32_t p0, uint32_t p1, uint32_t p2, uint32_t p3) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,33u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_get_x(const R4SdkSubsystemVideoRect *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,33u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_set_x(R4SdkSubsystemVideoRect *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,33u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_get_y(const R4SdkSubsystemVideoRect *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,33u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_set_y(R4SdkSubsystemVideoRect *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,33u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_get_w(const R4SdkSubsystemVideoRect *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,33u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_set_w(R4SdkSubsystemVideoRect *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,33u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_get_h(const R4SdkSubsystemVideoRect *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,33u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_set_h(R4SdkSubsystemVideoRect *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,33u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoRect_inspectNative(const R4SdkSubsystemVideoRect *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,33u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPoint_create(R4SdkSubsystemVideoPoint *output, uint32_t p0, uint32_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,34u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPoint_from_fields(R4SdkSubsystemVideoPoint *output, uint32_t p0, uint32_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,34u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPoint_get_x(const R4SdkSubsystemVideoPoint *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,34u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPoint_set_x(R4SdkSubsystemVideoPoint *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,34u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPoint_get_y(const R4SdkSubsystemVideoPoint *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,34u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPoint_set_y(R4SdkSubsystemVideoPoint *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,34u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPoint_inspectNative(const R4SdkSubsystemVideoPoint *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,34u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSize_create(R4SdkSubsystemVideoSize *output, uint32_t p0, uint32_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,35u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSize_from_fields(R4SdkSubsystemVideoSize *output, uint32_t p0, uint32_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,35u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSize_get_w(const R4SdkSubsystemVideoSize *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,35u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSize_set_w(R4SdkSubsystemVideoSize *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,35u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSize_get_h(const R4SdkSubsystemVideoSize *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,35u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSize_set_h(R4SdkSubsystemVideoSize *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,35u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSize_inspectNative(const R4SdkSubsystemVideoSize *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,35u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_create(R4SdkSubsystemVideoViewport *output, int32_t p0, int32_t p1, uint32_t p2, uint32_t p3, uint32_t p4, uint32_t p5, uint32_t p6) {
 R4SdkSubsystemSlot a[7]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,36u,a,7u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_from_fields(R4SdkSubsystemVideoViewport *output, int32_t p0, int32_t p1, uint32_t p2, uint32_t p3, uint32_t p4, uint32_t p5, uint32_t p6) {
 R4SdkSubsystemSlot a[7]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,36u,a,7u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_get_x(const R4SdkSubsystemVideoViewport *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_set_x(R4SdkSubsystemVideoViewport *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_get_y(const R4SdkSubsystemVideoViewport *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_set_y(R4SdkSubsystemVideoViewport *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_get_w(const R4SdkSubsystemVideoViewport *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_set_w(R4SdkSubsystemVideoViewport *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_get_h(const R4SdkSubsystemVideoViewport *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_set_h(R4SdkSubsystemVideoViewport *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_get_guest_w(const R4SdkSubsystemVideoViewport *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_set_guest_w(R4SdkSubsystemVideoViewport *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_get_guest_h(const R4SdkSubsystemVideoViewport *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_set_guest_h(R4SdkSubsystemVideoViewport *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_get_integer_scale(const R4SdkSubsystemVideoViewport *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_set_integer_scale(R4SdkSubsystemVideoViewport *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,36u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoViewport_inspectNative(const R4SdkSubsystemVideoViewport *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,36u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue37_inspectNative(const R4SdkSubsystemNativeValue37 *self, R4SdkSubsystemVideoViewport *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,37u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentMode_create(R4SdkSubsystemVideoPresentMode *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,38u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentMode_inspectNative(const R4SdkSubsystemVideoPresentMode *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,38u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_create(R4SdkSubsystemVideoPresentInfo *output, uint32_t p0, const R4SdkSubsystemVideoViewport * p1, uint32_t p2, uint32_t p3, uint64_t p4) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,39u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_from_fields(R4SdkSubsystemVideoPresentInfo *output, uint32_t p0, const R4SdkSubsystemVideoViewport * p1, uint32_t p2, uint32_t p3, uint64_t p4) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,39u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_get_mode(const R4SdkSubsystemVideoPresentInfo *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,39u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_set_mode(R4SdkSubsystemVideoPresentInfo *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,39u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_get_viewport(const R4SdkSubsystemVideoPresentInfo *self, R4SdkSubsystemVideoViewport *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,39u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_set_viewport(R4SdkSubsystemVideoPresentInfo *self, const R4SdkSubsystemVideoViewport * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,39u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_get_damage_regions(const R4SdkSubsystemVideoPresentInfo *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,39u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_set_damage_regions(R4SdkSubsystemVideoPresentInfo *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,39u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_get_raster_blocks(const R4SdkSubsystemVideoPresentInfo *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,39u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_set_raster_blocks(R4SdkSubsystemVideoPresentInfo *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,39u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_get_sampled_pixels(const R4SdkSubsystemVideoPresentInfo *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,39u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_set_sampled_pixels(R4SdkSubsystemVideoPresentInfo *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,39u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentInfo_inspectNative(const R4SdkSubsystemVideoPresentInfo *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,39u,(void *)self,0); }
#define R4SdkSubsystemVideoPresentResult_TAG_unchanged 0u
#define R4SdkSubsystemVideoPresentResult_TAG_hidden 1u
#define R4SdkSubsystemVideoPresentResult_TAG_presented 2u
#define R4SdkSubsystemVideoPresentResult_TAG_failure 3u
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentResult_get_unchanged(const R4SdkSubsystemVideoPresentResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,40u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentResult_set_unchanged(R4SdkSubsystemVideoPresentResult *self) { R4SdkSubsystemSlot a[1]={0};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,40u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentResult_get_hidden(const R4SdkSubsystemVideoPresentResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,40u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentResult_set_hidden(R4SdkSubsystemVideoPresentResult *self) { R4SdkSubsystemSlot a[1]={0};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,40u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentResult_get_presented(const R4SdkSubsystemVideoPresentResult *self, R4SdkSubsystemVideoPresentInfo *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,40u,2u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentResult_set_presented(R4SdkSubsystemVideoPresentResult *self, const R4SdkSubsystemVideoPresentInfo * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,40u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentResult_get_failure(const R4SdkSubsystemVideoPresentResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,40u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentResult_set_failure(R4SdkSubsystemVideoPresentResult *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,40u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentResult_inspectNative(const R4SdkSubsystemVideoPresentResult *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,40u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative__typeInfo_subsystem_host_PresentResult____union__tag_type___create(R4SdkSubsystemNative__typeInfo_subsystem_host_PresentResult____union__tag_type__ *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,41u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative__typeInfo_subsystem_host_PresentResult____union__tag_type___inspectNative(const R4SdkSubsystemNative__typeInfo_subsystem_host_PresentResult____union__tag_type__ *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,41u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_create(R4SdkSubsystemVideoPresentStats *output) {
 R4SdkSubsystemSlot a[22]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[8].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[9].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[10].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[11].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[12].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[13].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[14].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[15].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[16].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[17].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[18].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[19].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[20].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[21].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,42u,a,22u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_from_fields(R4SdkSubsystemVideoPresentStats *output, uint64_t p0, uint64_t p1, uint64_t p2, uint64_t p3, uint64_t p4, uint64_t p5, uint64_t p6, uint64_t p7, uint64_t p8, uint64_t p9, uint64_t p10, uint64_t p11, uint64_t p12, uint64_t p13, uint64_t p14, uint64_t p15, uint64_t p16, uint64_t p17, uint64_t p18, uint64_t p19, uint64_t p20, uint64_t p21) {
 R4SdkSubsystemSlot a[22]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[8] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[9] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[10] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[11] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[12] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[13] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[14] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p14,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[15] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p15,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[16] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p16,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[17] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p17,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[18] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p18,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[19] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p19,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[20] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p20,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[21] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p21,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,42u,a,22u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_published_frames(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_published_frames(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_skipped_frames(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_skipped_frames(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_full_frames(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_full_frames(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_damage_frames(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_damage_frames(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_compacted_frames(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_compacted_frames(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_damage_regions(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_damage_regions(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_indexed8_frames(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_indexed8_frames(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_indexed8_blocks(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_indexed8_blocks(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_indexed8_resource_bytes(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,8u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_indexed8_resource_bytes(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,8u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_replacement_frames(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,9u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_replacement_frames(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,9u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_xrgb32_nearest_frames(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,10u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_xrgb32_nearest_frames(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,10u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_xrgb32_nearest_blocks(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,11u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_xrgb32_nearest_blocks(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,11u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_xrgb32_nearest_resource_bytes(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,12u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_xrgb32_nearest_resource_bytes(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,12u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_shared_raster_frames(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,13u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_shared_raster_frames(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,13u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_shared_raster_blocks(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,14u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_shared_raster_blocks(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,14u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_shared_raster_descriptor_bytes(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,15u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_shared_raster_descriptor_bytes(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,15u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_shared_raster_published_bytes(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,16u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_shared_raster_published_bytes(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,16u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_shared_raster_fallback_frames(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,17u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_shared_raster_fallback_frames(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,17u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_shared_raster_backpressure_fallbacks(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,18u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_shared_raster_backpressure_fallbacks(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,18u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_xrgb_fallback_frames(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,19u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_xrgb_fallback_frames(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,19u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_raster_blocks(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,20u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_raster_blocks(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,20u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_get_sampled_pixels(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,21u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_set_sampled_pixels(R4SdkSubsystemVideoPresentStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,42u,21u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresentStats_inspectNative(const R4SdkSubsystemVideoPresentStats *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,42u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexedBatch_create(R4SdkSubsystemVideoIndexedBatch *output, const R4GuiFrameCommand * p0, const uint8_t * p1, uintptr_t n1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,43u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexedBatch_from_fields(R4SdkSubsystemVideoIndexedBatch *output, const R4GuiFrameCommand * p0, const uint8_t * p1, uintptr_t n1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,43u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexedBatch_get_command(const R4SdkSubsystemVideoIndexedBatch *self, R4GuiFrameCommand *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,43u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexedBatch_set_command(R4SdkSubsystemVideoIndexedBatch *self, const R4GuiFrameCommand * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,43u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexedBatch_get_resource(const R4SdkSubsystemVideoIndexedBatch *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,43u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexedBatch_set_resource(R4SdkSubsystemVideoIndexedBatch *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,43u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoIndexedBatch_inspectNative(const R4SdkSubsystemVideoIndexedBatch *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,43u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoXrgb32Batch_create(R4SdkSubsystemVideoXrgb32Batch *output, const R4GuiFrameCommand * p0, const uint8_t * p1, uintptr_t n1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,45u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoXrgb32Batch_from_fields(R4SdkSubsystemVideoXrgb32Batch *output, const R4GuiFrameCommand * p0, const uint8_t * p1, uintptr_t n1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,45u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoXrgb32Batch_get_command(const R4SdkSubsystemVideoXrgb32Batch *self, R4GuiFrameCommand *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,45u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoXrgb32Batch_set_command(R4SdkSubsystemVideoXrgb32Batch *self, const R4GuiFrameCommand * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,45u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoXrgb32Batch_get_resource(const R4SdkSubsystemVideoXrgb32Batch *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,45u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoXrgb32Batch_set_resource(R4SdkSubsystemVideoXrgb32Batch *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,45u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoXrgb32Batch_inspectNative(const R4SdkSubsystemVideoXrgb32Batch *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,45u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSharedRasterBatch_create(R4SdkSubsystemVideoSharedRasterBatch *output, const R4GuiFrameCommand * p0, const R4GuiSharedRasterResource * p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,46u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSharedRasterBatch_from_fields(R4SdkSubsystemVideoSharedRasterBatch *output, const R4GuiFrameCommand * p0, const R4GuiSharedRasterResource * p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,46u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSharedRasterBatch_get_command(const R4SdkSubsystemVideoSharedRasterBatch *self, R4GuiFrameCommand *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,46u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSharedRasterBatch_set_command(R4SdkSubsystemVideoSharedRasterBatch *self, const R4GuiFrameCommand * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,46u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSharedRasterBatch_get_resource(const R4SdkSubsystemVideoSharedRasterBatch *self, R4GuiSharedRasterResource *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,46u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSharedRasterBatch_set_resource(R4SdkSubsystemVideoSharedRasterBatch *self, const R4GuiSharedRasterResource * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,46u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoSharedRasterBatch_inspectNative(const R4SdkSubsystemVideoSharedRasterBatch *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,46u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_create(R4SdkSubsystemVideoBackend *output, void * p0, uintptr_t p1, uintptr_t p2, uintptr_t p4, uintptr_t p5, uintptr_t p6, uintptr_t p13, uintptr_t p14, uintptr_t p15) {
 R4SdkSubsystemSlot a[20]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[8].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[9].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[10].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[11].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[12].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[13] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p13,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[14] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p14,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[15] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p15,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[16].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[17].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[18].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[19].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,48u,a,20u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_from_fields(R4SdkSubsystemVideoBackend *output, void * p0, uintptr_t p1, uintptr_t p2, uintptr_t p3, uintptr_t p4, uintptr_t p5, uintptr_t p6, uintptr_t p7, uintptr_t p8, uintptr_t p9, uintptr_t p10, uintptr_t p11, uintptr_t p12, uintptr_t p13, uintptr_t p14, uintptr_t p15, uint8_t p16, uint8_t p17, uint8_t p18, uint8_t p19) {
 R4SdkSubsystemSlot a[20]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[8] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p8,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[9] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p9,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[10] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p10,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[11] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p11,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[12] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p12,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[13] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p13,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[14] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p14,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[15] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p15,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[16] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p16,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[17] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p17,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[18] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p18,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[19] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p19,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,48u,a,20u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_context(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_context(R4SdkSubsystemVideoBackend *self, void * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_begin_full_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_begin_full_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_begin_damage_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_begin_damage_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_begin_replace_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_begin_replace_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_clear_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_clear_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_raster_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_raster_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_indexed8_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_indexed8_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_xrgb32_nearest_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_xrgb32_nearest_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_shared_raster_create_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,8u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_shared_raster_create_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,8u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_shared_raster_destroy_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,9u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_shared_raster_destroy_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,9u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_shared_raster_map_write_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,10u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_shared_raster_map_write_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,10u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_shared_raster_publish_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,11u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_shared_raster_publish_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,11u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_shared_raster_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,12u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_shared_raster_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,12u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_commit_full_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,13u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_commit_full_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,13u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_commit_damage_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,14u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_commit_damage_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,14u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_cancel_fn(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,15u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_cancel_fn(R4SdkSubsystemVideoBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,15u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_available(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,16u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_available(R4SdkSubsystemVideoBackend *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,16u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_supports_indexed8(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,17u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_supports_indexed8(R4SdkSubsystemVideoBackend *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,17u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_supports_xrgb32_nearest(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,18u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_supports_xrgb32_nearest(R4SdkSubsystemVideoBackend *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,18u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_get_supports_shared_raster(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,19u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_set_supports_shared_raster(R4SdkSubsystemVideoBackend *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,48u,19u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoBackend_inspectNative(const R4SdkSubsystemVideoBackend *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,48u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFrameOverlay_create(R4SdkSubsystemVideoFrameOverlay *output, void * p0, uintptr_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,49u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFrameOverlay_from_fields(R4SdkSubsystemVideoFrameOverlay *output, void * p0, uintptr_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,49u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFrameOverlay_get_context(const R4SdkSubsystemVideoFrameOverlay *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,49u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFrameOverlay_set_context(R4SdkSubsystemVideoFrameOverlay *self, void * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,49u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFrameOverlay_get_append_fn(const R4SdkSubsystemVideoFrameOverlay *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,49u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFrameOverlay_set_append_fn(R4SdkSubsystemVideoFrameOverlay *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,49u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFrameOverlay_inspectNative(const R4SdkSubsystemVideoFrameOverlay *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,49u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_create(R4SdkSubsystemVideoPresenter *output, const R4SdkSubsystemVideoSurface * p0, uint32_t * p1, uintptr_t n1) {
 R4SdkSubsystemSlot a[11]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[8].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[9].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[10].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,50u,a,11u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_from_fields(R4SdkSubsystemVideoPresenter *output, const R4SdkSubsystemVideoSurface * p0, uint32_t * p1, uintptr_t n1, const R4SdkSubsystemVideoDamage * p2, R4SdkSubsystemSlot p3, uint8_t p4, uint32_t p5, const R4SdkSubsystemVideoPresentStats * p6, const R4GuiSharedRasterHandle * p7, const R4GuiSharedRasterCreateInfo * p8, uint64_t p9, R4SdkSubsystemSlot p10) {
 R4SdkSubsystemSlot a[11]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = p3;
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.ptr=(void *)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.ptr=(void *)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[8] = (R4SdkSubsystemSlot){.ptr=(void *)p8,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[9] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[10] = p10;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,50u,a,11u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_get_surface(const R4SdkSubsystemVideoPresenter *self, R4SdkSubsystemVideoSurface *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_set_surface(R4SdkSubsystemVideoPresenter *self, const R4SdkSubsystemVideoSurface * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_get_scratch(const R4SdkSubsystemVideoPresenter *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_set_scratch(R4SdkSubsystemVideoPresenter *self, uint32_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_get_damage(const R4SdkSubsystemVideoPresenter *self, R4SdkSubsystemVideoDamage *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,2u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_set_damage(R4SdkSubsystemVideoPresenter *self, const R4SdkSubsystemVideoDamage * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_get_last_viewport(const R4SdkSubsystemVideoPresenter *self, R4SdkSubsystemVideoViewport *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,3u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_set_last_viewport(R4SdkSubsystemVideoPresenter *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_get_has_frame(const R4SdkSubsystemVideoPresenter *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_set_has_frame(R4SdkSubsystemVideoPresenter *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_get_damage_chain(const R4SdkSubsystemVideoPresenter *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_set_damage_chain(R4SdkSubsystemVideoPresenter *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_get_stats(const R4SdkSubsystemVideoPresenter *self, R4SdkSubsystemVideoPresentStats *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,6u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_set_stats(R4SdkSubsystemVideoPresenter *self, const R4SdkSubsystemVideoPresentStats * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_get_shared_handle(const R4SdkSubsystemVideoPresenter *self, R4GuiSharedRasterHandle *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,7u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_set_shared_handle(R4SdkSubsystemVideoPresenter *self, const R4GuiSharedRasterHandle * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_get_shared_info(const R4SdkSubsystemVideoPresenter *self, R4GuiSharedRasterCreateInfo *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,8u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_set_shared_info(R4SdkSubsystemVideoPresenter *self, const R4GuiSharedRasterCreateInfo * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,8u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_get_shared_generation(const R4SdkSubsystemVideoPresenter *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,9u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_set_shared_generation(R4SdkSubsystemVideoPresenter *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,9u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_get_client_damage(const R4SdkSubsystemVideoPresenter *self, R4SdkSubsystemVideoRect *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,10u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_set_client_damage(R4SdkSubsystemVideoPresenter *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,50u,10u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPresenter_inspectNative(const R4SdkSubsystemVideoPresenter *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,50u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoDamage_create(R4SdkSubsystemVideoDamage *output) {
 R4SdkSubsystemSlot a[3]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,51u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoDamage_from_fields(R4SdkSubsystemVideoDamage *output, uint32_t p0, const R4SdkSubsystemNativeValue53 * p1, uint64_t p2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,51u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoDamage_get_kind(const R4SdkSubsystemVideoDamage *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,51u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoDamage_set_kind(R4SdkSubsystemVideoDamage *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,51u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoDamage_get_regions(const R4SdkSubsystemVideoDamage *self, R4SdkSubsystemNativeValue53 *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,51u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoDamage_set_regions(R4SdkSubsystemVideoDamage *self, const R4SdkSubsystemNativeValue53 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,51u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoDamage_get_count(const R4SdkSubsystemVideoDamage *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,51u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoDamage_set_count(R4SdkSubsystemVideoDamage *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,51u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoDamage_inspectNative(const R4SdkSubsystemVideoDamage *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,51u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoDamageKind_create(R4SdkSubsystemVideoDamageKind *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,52u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoDamageKind_inspectNative(const R4SdkSubsystemVideoDamageKind *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,52u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue53_create(R4SdkSubsystemNativeValue53 *output, const R4SdkSubsystemNativeValue53 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,53u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue53_inspectNative(const R4SdkSubsystemNativeValue53 *self, R4SdkSubsystemNativeValue53 *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,53u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue54_create(R4SdkSubsystemNativeValue54 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,54u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue54_inspectNative(const R4SdkSubsystemNativeValue54 *self, R4SdkSubsystemVideoViewport *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,54u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue57_create(R4SdkSubsystemNativeValue57 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,57u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue57_inspectNative(const R4SdkSubsystemNativeValue57 *self, R4SdkSubsystemVideoRect *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,57u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseAction_create(R4SdkSubsystemVideoMouseAction *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,58u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseAction_inspectNative(const R4SdkSubsystemVideoMouseAction *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,58u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyTextMode_create(R4SdkSubsystemVideoKeyTextMode *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,59u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyTextMode_inspectNative(const R4SdkSubsystemVideoKeyTextMode *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,59u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPointerMode_create(R4SdkSubsystemVideoPointerMode *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,60u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPointerMode_inspectNative(const R4SdkSubsystemVideoPointerMode *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,60u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputPolicy_create(R4SdkSubsystemVideoInputPolicy *output) {
 R4SdkSubsystemSlot a[2]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,61u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputPolicy_from_fields(R4SdkSubsystemVideoInputPolicy *output, uint32_t p0, uint32_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,61u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputPolicy_get_key_text_mode(const R4SdkSubsystemVideoInputPolicy *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,61u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputPolicy_set_key_text_mode(R4SdkSubsystemVideoInputPolicy *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,61u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputPolicy_get_pointer_mode(const R4SdkSubsystemVideoInputPolicy *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,61u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputPolicy_set_pointer_mode(R4SdkSubsystemVideoInputPolicy *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,61u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputPolicy_inspectNative(const R4SdkSubsystemVideoInputPolicy *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,61u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputStamp_create(R4SdkSubsystemVideoInputStamp *output, uint64_t p0, uint64_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,62u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputStamp_from_fields(R4SdkSubsystemVideoInputStamp *output, uint64_t p0, uint64_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,62u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputStamp_get_sequence(const R4SdkSubsystemVideoInputStamp *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,62u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputStamp_set_sequence(R4SdkSubsystemVideoInputStamp *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,62u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputStamp_get_tick(const R4SdkSubsystemVideoInputStamp *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,62u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputStamp_set_tick(R4SdkSubsystemVideoInputStamp *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,62u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputStamp_inspectNative(const R4SdkSubsystemVideoInputStamp *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,62u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputFilterReason_create(R4SdkSubsystemVideoInputFilterReason *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,63u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputFilterReason_inspectNative(const R4SdkSubsystemVideoInputFilterReason *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,63u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_create(R4SdkSubsystemVideoInputTranslationStats *output) {
 R4SdkSubsystemSlot a[26]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[8].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[9].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[10].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[11].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[12].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[13].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[14].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[15].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[16].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[17].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[18].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[19].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[20].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[21].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[22].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[23].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[24].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[25].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,64u,a,26u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_from_fields(R4SdkSubsystemVideoInputTranslationStats *output, uint64_t p0, uint64_t p1, uint64_t p2, uint64_t p3, uint64_t p4, uint64_t p5, uint64_t p6, uint64_t p7, uint64_t p8, uint64_t p9, uint64_t p10, uint64_t p11, uint64_t p12, uint64_t p13, uint64_t p14, uint64_t p15, uint64_t p16, uint64_t p17, uint64_t p18, uint64_t p19, uint64_t p20, uint64_t p21, uint64_t p22, uint64_t p23, uint64_t p24, uint32_t p25) {
 R4SdkSubsystemSlot a[26]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[8] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[9] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[10] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[11] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[12] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[13] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[14] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p14,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[15] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p15,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[16] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p16,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[17] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p17,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[18] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p18,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[19] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p19,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[20] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p20,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[21] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p21,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[22] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p22,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[23] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p23,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[24] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p24,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[25] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p25,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,64u,a,26u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_raw_events(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_raw_events(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_logical_events(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_logical_events(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_pending_text_created(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_pending_text_created(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_pending_text_emitted(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_pending_text_emitted(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_mouse_events(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_mouse_events(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_mouse_moves(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_mouse_moves(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_mouse_mappings(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_mouse_mappings(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_physical_key_downs(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_physical_key_downs(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_physical_key_ups(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,8u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_physical_key_ups(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,8u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_physical_key_repeats(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,9u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_physical_key_repeats(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,9u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_synthesized_physical_key_ups(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,10u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_synthesized_physical_key_ups(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,10u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_filtered_events(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,11u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_filtered_events(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,11u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_pointer_ignored(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,12u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_pointer_ignored(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,12u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_duplicate_focus(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,13u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_duplicate_focus(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,13u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_duplicate_physical_down(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,14u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_duplicate_physical_down(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,14u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_unexpected_physical_up(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,15u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_unexpected_physical_up(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,15u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_invalid_physical_key(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,16u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_invalid_physical_key(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,16u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_missing_geometry(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,17u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_missing_geometry(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,17u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_unsupported_raw(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,18u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_unsupported_raw(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,18u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_last_raw_sequence(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,19u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_last_raw_sequence(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,19u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_last_raw_tick(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,20u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_last_raw_tick(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,20u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_last_logical_sequence(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,21u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_last_logical_sequence(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,21u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_last_logical_tick(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,22u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_last_logical_tick(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,22u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_last_filtered_sequence(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,23u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_last_filtered_sequence(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,23u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_last_filtered_tick(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,24u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_last_filtered_tick(R4SdkSubsystemVideoInputTranslationStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,24u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_get_last_filter_reason(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,25u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_set_last_filter_reason(R4SdkSubsystemVideoInputTranslationStats *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,64u,25u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslationStats_inspectNative(const R4SdkSubsystemVideoInputTranslationStats *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,64u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_create(R4SdkSubsystemVideoHostStats *output) {
 R4SdkSubsystemSlot a[6]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,65u,a,6u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_from_fields(R4SdkSubsystemVideoHostStats *output, uint64_t p0, uint64_t p1, uint64_t p2, uint64_t p3, uint64_t p4, uint64_t p5) {
 R4SdkSubsystemSlot a[6]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,65u,a,6u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_get_window_info_calls(const R4SdkSubsystemVideoHostStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,65u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_set_window_info_calls(R4SdkSubsystemVideoHostStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,65u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_get_present_window_info_calls(const R4SdkSubsystemVideoHostStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,65u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_set_present_window_info_calls(R4SdkSubsystemVideoHostStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,65u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_get_input_window_info_calls(const R4SdkSubsystemVideoHostStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,65u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_set_input_window_info_calls(R4SdkSubsystemVideoHostStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,65u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_get_viewport_calculations(const R4SdkSubsystemVideoHostStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,65u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_set_viewport_calculations(R4SdkSubsystemVideoHostStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,65u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_get_present_viewport_calculations(const R4SdkSubsystemVideoHostStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,65u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_set_present_viewport_calculations(R4SdkSubsystemVideoHostStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,65u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_get_input_viewport_calculations(const R4SdkSubsystemVideoHostStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,65u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_set_input_viewport_calculations(R4SdkSubsystemVideoHostStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,65u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHostStats_inspectNative(const R4SdkSubsystemVideoHostStats *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,65u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyEvent_create(R4SdkSubsystemVideoKeyEvent *output, uint32_t p0, uint32_t p1, uint64_t p2) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,66u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyEvent_from_fields(R4SdkSubsystemVideoKeyEvent *output, uint32_t p0, uint32_t p1, uint64_t p2, uint64_t p3) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,66u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyEvent_get_code(const R4SdkSubsystemVideoKeyEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,66u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyEvent_set_code(R4SdkSubsystemVideoKeyEvent *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,66u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyEvent_get_modifiers(const R4SdkSubsystemVideoKeyEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,66u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyEvent_set_modifiers(R4SdkSubsystemVideoKeyEvent *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,66u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyEvent_get_tick(const R4SdkSubsystemVideoKeyEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,66u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyEvent_set_tick(R4SdkSubsystemVideoKeyEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,66u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyEvent_get_sequence(const R4SdkSubsystemVideoKeyEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,66u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyEvent_set_sequence(R4SdkSubsystemVideoKeyEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,66u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoKeyEvent_inspectNative(const R4SdkSubsystemVideoKeyEvent *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,66u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_create(R4SdkSubsystemVideoPhysicalKeyEvent *output, uint32_t p0, uint32_t p1, uint32_t p2, uint64_t p3) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,67u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_from_fields(R4SdkSubsystemVideoPhysicalKeyEvent *output, uint32_t p0, uint32_t p1, uint32_t p2, uint64_t p3, uint64_t p4) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,67u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_get_key(const R4SdkSubsystemVideoPhysicalKeyEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,67u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_set_key(R4SdkSubsystemVideoPhysicalKeyEvent *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,67u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_get_modifiers(const R4SdkSubsystemVideoPhysicalKeyEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,67u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_set_modifiers(R4SdkSubsystemVideoPhysicalKeyEvent *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,67u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_get_flags(const R4SdkSubsystemVideoPhysicalKeyEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,67u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_set_flags(R4SdkSubsystemVideoPhysicalKeyEvent *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,67u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_get_tick(const R4SdkSubsystemVideoPhysicalKeyEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,67u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_set_tick(R4SdkSubsystemVideoPhysicalKeyEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,67u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_get_sequence(const R4SdkSubsystemVideoPhysicalKeyEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,67u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_set_sequence(R4SdkSubsystemVideoPhysicalKeyEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,67u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoPhysicalKeyEvent_inspectNative(const R4SdkSubsystemVideoPhysicalKeyEvent *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,67u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoTextEvent_create(R4SdkSubsystemVideoTextEvent *output, uint32_t p0, uint32_t p1, uint64_t p2) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,68u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoTextEvent_from_fields(R4SdkSubsystemVideoTextEvent *output, uint32_t p0, uint32_t p1, uint64_t p2, uint64_t p3) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,68u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoTextEvent_get_codepoint(const R4SdkSubsystemVideoTextEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,68u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoTextEvent_set_codepoint(R4SdkSubsystemVideoTextEvent *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,68u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoTextEvent_get_modifiers(const R4SdkSubsystemVideoTextEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,68u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoTextEvent_set_modifiers(R4SdkSubsystemVideoTextEvent *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,68u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoTextEvent_get_tick(const R4SdkSubsystemVideoTextEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,68u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoTextEvent_set_tick(R4SdkSubsystemVideoTextEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,68u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoTextEvent_get_sequence(const R4SdkSubsystemVideoTextEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,68u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoTextEvent_set_sequence(R4SdkSubsystemVideoTextEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,68u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoTextEvent_inspectNative(const R4SdkSubsystemVideoTextEvent *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,68u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_create(R4SdkSubsystemVideoMouseEvent *output, uint32_t p0, int32_t p1, int32_t p2, R4SdkSubsystemSlot p3, uint32_t p4, uint32_t p5, uint64_t p6) {
 R4SdkSubsystemSlot a[8]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = p3;
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,69u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_from_fields(R4SdkSubsystemVideoMouseEvent *output, uint32_t p0, int32_t p1, int32_t p2, R4SdkSubsystemSlot p3, uint32_t p4, uint32_t p5, uint64_t p6, uint64_t p7) {
 R4SdkSubsystemSlot a[8]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = p3;
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,69u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_get_action(const R4SdkSubsystemVideoMouseEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_set_action(R4SdkSubsystemVideoMouseEvent *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_get_client_x(const R4SdkSubsystemVideoMouseEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_set_client_x(R4SdkSubsystemVideoMouseEvent *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_get_client_y(const R4SdkSubsystemVideoMouseEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_set_client_y(R4SdkSubsystemVideoMouseEvent *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_get_guest(const R4SdkSubsystemVideoMouseEvent *self, R4SdkSubsystemVideoPoint *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,3u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_set_guest(R4SdkSubsystemVideoMouseEvent *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_get_buttons(const R4SdkSubsystemVideoMouseEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_set_buttons(R4SdkSubsystemVideoMouseEvent *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_get_modifiers(const R4SdkSubsystemVideoMouseEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_set_modifiers(R4SdkSubsystemVideoMouseEvent *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_get_tick(const R4SdkSubsystemVideoMouseEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_set_tick(R4SdkSubsystemVideoMouseEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_get_sequence(const R4SdkSubsystemVideoMouseEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_set_sequence(R4SdkSubsystemVideoMouseEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,69u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoMouseEvent_inspectNative(const R4SdkSubsystemVideoMouseEvent *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,69u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue70_create(R4SdkSubsystemNativeValue70 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,70u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue70_inspectNative(const R4SdkSubsystemNativeValue70 *self, R4SdkSubsystemVideoPoint *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,70u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoResizeEvent_create(R4SdkSubsystemVideoResizeEvent *output, const R4SdkSubsystemVideoSize * p0, const R4SdkSubsystemVideoViewport * p1, uint64_t p2) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,71u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoResizeEvent_from_fields(R4SdkSubsystemVideoResizeEvent *output, const R4SdkSubsystemVideoSize * p0, const R4SdkSubsystemVideoViewport * p1, uint64_t p2, uint64_t p3) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,71u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoResizeEvent_get_client(const R4SdkSubsystemVideoResizeEvent *self, R4SdkSubsystemVideoSize *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,71u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoResizeEvent_set_client(R4SdkSubsystemVideoResizeEvent *self, const R4SdkSubsystemVideoSize * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,71u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoResizeEvent_get_viewport(const R4SdkSubsystemVideoResizeEvent *self, R4SdkSubsystemVideoViewport *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,71u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoResizeEvent_set_viewport(R4SdkSubsystemVideoResizeEvent *self, const R4SdkSubsystemVideoViewport * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,71u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoResizeEvent_get_tick(const R4SdkSubsystemVideoResizeEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,71u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoResizeEvent_set_tick(R4SdkSubsystemVideoResizeEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,71u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoResizeEvent_get_sequence(const R4SdkSubsystemVideoResizeEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,71u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoResizeEvent_set_sequence(R4SdkSubsystemVideoResizeEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,71u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoResizeEvent_inspectNative(const R4SdkSubsystemVideoResizeEvent *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,71u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFocusEvent_create(R4SdkSubsystemVideoFocusEvent *output, uint8_t p0, uint64_t p1) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,72u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFocusEvent_from_fields(R4SdkSubsystemVideoFocusEvent *output, uint8_t p0, uint64_t p1, uint64_t p2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,72u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFocusEvent_get_focused(const R4SdkSubsystemVideoFocusEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,72u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFocusEvent_set_focused(R4SdkSubsystemVideoFocusEvent *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,72u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFocusEvent_get_tick(const R4SdkSubsystemVideoFocusEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,72u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFocusEvent_set_tick(R4SdkSubsystemVideoFocusEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,72u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFocusEvent_get_sequence(const R4SdkSubsystemVideoFocusEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,72u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFocusEvent_set_sequence(R4SdkSubsystemVideoFocusEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,72u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoFocusEvent_inspectNative(const R4SdkSubsystemVideoFocusEvent *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,72u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoCloseEvent_create(R4SdkSubsystemVideoCloseEvent *output, uint64_t p0) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,73u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoCloseEvent_from_fields(R4SdkSubsystemVideoCloseEvent *output, uint64_t p0, uint64_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,73u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoCloseEvent_get_tick(const R4SdkSubsystemVideoCloseEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,73u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoCloseEvent_set_tick(R4SdkSubsystemVideoCloseEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,73u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoCloseEvent_get_sequence(const R4SdkSubsystemVideoCloseEvent *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,73u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoCloseEvent_set_sequence(R4SdkSubsystemVideoCloseEvent *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,73u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoCloseEvent_inspectNative(const R4SdkSubsystemVideoCloseEvent *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,73u,(void *)self,0); }
#define R4SdkSubsystemVideoInputEvent_TAG_close 0u
#define R4SdkSubsystemVideoInputEvent_TAG_resize 1u
#define R4SdkSubsystemVideoInputEvent_TAG_focus 2u
#define R4SdkSubsystemVideoInputEvent_TAG_key_down 3u
#define R4SdkSubsystemVideoInputEvent_TAG_physical_key_down 4u
#define R4SdkSubsystemVideoInputEvent_TAG_physical_key_up 5u
#define R4SdkSubsystemVideoInputEvent_TAG_text 6u
#define R4SdkSubsystemVideoInputEvent_TAG_mouse 7u
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_get_close(const R4SdkSubsystemVideoInputEvent *self, R4SdkSubsystemVideoCloseEvent *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_set_close(R4SdkSubsystemVideoInputEvent *self, const R4SdkSubsystemVideoCloseEvent * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_get_resize(const R4SdkSubsystemVideoInputEvent *self, R4SdkSubsystemVideoResizeEvent *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_set_resize(R4SdkSubsystemVideoInputEvent *self, const R4SdkSubsystemVideoResizeEvent * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_get_focus(const R4SdkSubsystemVideoInputEvent *self, R4SdkSubsystemVideoFocusEvent *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,2u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_set_focus(R4SdkSubsystemVideoInputEvent *self, const R4SdkSubsystemVideoFocusEvent * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_get_key_down(const R4SdkSubsystemVideoInputEvent *self, R4SdkSubsystemVideoKeyEvent *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,3u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_set_key_down(R4SdkSubsystemVideoInputEvent *self, const R4SdkSubsystemVideoKeyEvent * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_get_physical_key_down(const R4SdkSubsystemVideoInputEvent *self, R4SdkSubsystemVideoPhysicalKeyEvent *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,4u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_set_physical_key_down(R4SdkSubsystemVideoInputEvent *self, const R4SdkSubsystemVideoPhysicalKeyEvent * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_get_physical_key_up(const R4SdkSubsystemVideoInputEvent *self, R4SdkSubsystemVideoPhysicalKeyEvent *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,5u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_set_physical_key_up(R4SdkSubsystemVideoInputEvent *self, const R4SdkSubsystemVideoPhysicalKeyEvent * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_get_text(const R4SdkSubsystemVideoInputEvent *self, R4SdkSubsystemVideoTextEvent *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,6u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_set_text(R4SdkSubsystemVideoInputEvent *self, const R4SdkSubsystemVideoTextEvent * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_get_mouse(const R4SdkSubsystemVideoInputEvent *self, R4SdkSubsystemVideoMouseEvent *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,7u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_set_mouse(R4SdkSubsystemVideoInputEvent *self, const R4SdkSubsystemVideoMouseEvent * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,74u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputEvent_inspectNative(const R4SdkSubsystemVideoInputEvent *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,74u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type___create(R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type__ *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,75u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type___inspectNative(const R4SdkSubsystemNative__typeInfo_subsystem_host_InputEvent____union__tag_type__ *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,75u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_create(R4SdkSubsystemVideoInputTranslator *output) {
 R4SdkSubsystemSlot a[8]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,76u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_from_fields(R4SdkSubsystemVideoInputTranslator *output, const R4SdkSubsystemVideoInputPolicy * p0, uint8_t p1, R4SdkSubsystemSlot p2, const R4SdkSubsystemNativeValue78 * p3, R4SdkSubsystemSlot p4, uint64_t p5, uint64_t p6, const R4SdkSubsystemVideoInputTranslationStats * p7) {
 R4SdkSubsystemSlot a[8]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = p2;
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = p4;
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.ptr=(void *)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,76u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_get_policy(const R4SdkSubsystemVideoInputTranslator *self, R4SdkSubsystemVideoInputPolicy *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_set_policy(R4SdkSubsystemVideoInputTranslator *self, const R4SdkSubsystemVideoInputPolicy * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_get_focused(const R4SdkSubsystemVideoInputTranslator *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_set_focused(R4SdkSubsystemVideoInputTranslator *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_get_pending_text(const R4SdkSubsystemVideoInputTranslator *self, R4SdkSubsystemVideoTextEvent *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,2u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_set_pending_text(R4SdkSubsystemVideoInputTranslator *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_get_held_physical_keys(const R4SdkSubsystemVideoInputTranslator *self, R4SdkSubsystemNativeValue78 *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,3u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_set_held_physical_keys(R4SdkSubsystemVideoInputTranslator *self, const R4SdkSubsystemNativeValue78 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_get_pending_release_cursor(const R4SdkSubsystemVideoInputTranslator *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_set_pending_release_cursor(R4SdkSubsystemVideoInputTranslator *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_get_pending_release_tick(const R4SdkSubsystemVideoInputTranslator *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_set_pending_release_tick(R4SdkSubsystemVideoInputTranslator *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_get_next_sequence(const R4SdkSubsystemVideoInputTranslator *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_set_next_sequence(R4SdkSubsystemVideoInputTranslator *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_get_stats(const R4SdkSubsystemVideoInputTranslator *self, R4SdkSubsystemVideoInputTranslationStats *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,7u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_set_stats(R4SdkSubsystemVideoInputTranslator *self, const R4SdkSubsystemVideoInputTranslationStats * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,76u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoInputTranslator_inspectNative(const R4SdkSubsystemVideoInputTranslator *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,76u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue77_create(R4SdkSubsystemNativeValue77 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,77u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue77_inspectNative(const R4SdkSubsystemNativeValue77 *self, R4SdkSubsystemVideoTextEvent *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,77u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue78_create(R4SdkSubsystemNativeValue78 *output, const R4SdkSubsystemNativeValue78 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,78u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue78_inspectNative(const R4SdkSubsystemNativeValue78 *self, R4SdkSubsystemNativeValue78 *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,78u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue79_create(R4SdkSubsystemNativeValue79 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,79u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue79_inspectNative(const R4SdkSubsystemNativeValue79 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,79u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_create(R4SdkSubsystemVideoHost *output, const R4SdkSubsystemNative_r4desk_Context * p0, const R4SdkSubsystemNative_r4draw_Context * p1, const R4SdkSubsystemVideoPresenter * p2) {
 R4SdkSubsystemSlot a[7]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,80u,a,7u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_from_fields(R4SdkSubsystemVideoHost *output, const R4SdkSubsystemNative_r4desk_Context * p0, const R4SdkSubsystemNative_r4draw_Context * p1, const R4SdkSubsystemVideoPresenter * p2, const R4SdkSubsystemVideoInputTranslator * p3, R4SdkSubsystemSlot p4, const R4SdkSubsystemVideoHostStats * p5, R4SdkSubsystemSlot p6) {
 R4SdkSubsystemSlot a[7]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = p4;
 a[5] = (R4SdkSubsystemSlot){.ptr=(void *)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = p6;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,80u,a,7u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_get_desk(const R4SdkSubsystemVideoHost *self, R4SdkSubsystemNative_r4desk_Context *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_set_desk(R4SdkSubsystemVideoHost *self, const R4SdkSubsystemNative_r4desk_Context * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_get_draw(const R4SdkSubsystemVideoHost *self, R4SdkSubsystemNative_r4draw_Context *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_set_draw(R4SdkSubsystemVideoHost *self, const R4SdkSubsystemNative_r4draw_Context * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_get_video(const R4SdkSubsystemVideoHost *self, R4SdkSubsystemVideoPresenter *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,2u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_set_video(R4SdkSubsystemVideoHost *self, const R4SdkSubsystemVideoPresenter * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_get_input(const R4SdkSubsystemVideoHost *self, R4SdkSubsystemVideoInputTranslator *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,3u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_set_input(R4SdkSubsystemVideoHost *self, const R4SdkSubsystemVideoInputTranslator * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_get_input_viewport(const R4SdkSubsystemVideoHost *self, R4SdkSubsystemVideoViewport *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,4u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_set_input_viewport(R4SdkSubsystemVideoHost *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_get_stats(const R4SdkSubsystemVideoHost *self, R4SdkSubsystemVideoHostStats *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,5u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_set_stats(R4SdkSubsystemVideoHost *self, const R4SdkSubsystemVideoHostStats * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_get_overlay(const R4SdkSubsystemVideoHost *self, R4SdkSubsystemVideoFrameOverlay *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,6u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_set_overlay(R4SdkSubsystemVideoHost *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,80u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemVideoHost_inspectNative(const R4SdkSubsystemVideoHost *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,80u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue83_create(R4SdkSubsystemNativeValue83 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,83u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue83_inspectNative(const R4SdkSubsystemNativeValue83 *self, R4SdkSubsystemVideoFrameOverlay *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,83u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_create(R4SdkSubsystemNative_subsystem_audio_transport_Completion *output, uint32_t p0, uint32_t p1, uint64_t p2, int32_t p3) {
 R4SdkSubsystemSlot a[6]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,84u,a,6u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_from_fields(R4SdkSubsystemNative_subsystem_audio_transport_Completion *output, uint32_t p0, uint32_t p1, uint64_t p2, int32_t p3, uint16_t p4, R4SdkSubsystemSlot p5) {
 R4SdkSubsystemSlot a[6]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = p5;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,84u,a,6u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_get_operation(const R4SdkSubsystemNative_subsystem_audio_transport_Completion *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,84u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_set_operation(R4SdkSubsystemNative_subsystem_audio_transport_Completion *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,84u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_get_request_id(const R4SdkSubsystemNative_subsystem_audio_transport_Completion *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,84u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_set_request_id(R4SdkSubsystemNative_subsystem_audio_transport_Completion *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,84u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_get_generation(const R4SdkSubsystemNative_subsystem_audio_transport_Completion *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,84u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_set_generation(R4SdkSubsystemNative_subsystem_audio_transport_Completion *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,84u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_get_result(const R4SdkSubsystemNative_subsystem_audio_transport_Completion *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,84u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_set_result(R4SdkSubsystemNative_subsystem_audio_transport_Completion *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,84u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_get_requests(const R4SdkSubsystemNative_subsystem_audio_transport_Completion *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,84u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_set_requests(R4SdkSubsystemNative_subsystem_audio_transport_Completion *self, uint16_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,84u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_get_progress(const R4SdkSubsystemNative_subsystem_audio_transport_Completion *self, R4AudioServiceStreamProgressState *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,84u,5u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_set_progress(R4SdkSubsystemNative_subsystem_audio_transport_Completion *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,84u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Completion_inspectNative(const R4SdkSubsystemNative_subsystem_audio_transport_Completion *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,84u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Operation_create(R4SdkSubsystemNative_subsystem_audio_transport_Operation *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,85u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Operation_inspectNative(const R4SdkSubsystemNative_subsystem_audio_transport_Operation *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,85u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue86_create(R4SdkSubsystemNativeValue86 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,86u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue86_inspectNative(const R4SdkSubsystemNativeValue86 *self, R4AudioServiceStreamProgressState *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,86u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Finish_create(R4SdkSubsystemNative_subsystem_audio_transport_Finish *output) {
 R4SdkSubsystemSlot a[4]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,88u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Finish_from_fields(R4SdkSubsystemNative_subsystem_audio_transport_Finish *output, R4SdkSubsystemSlot p0, int32_t p1, uint32_t p2, R4SdkSubsystemSlot p3) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = p0;
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = p3;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,88u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Finish_get_completion(const R4SdkSubsystemNative_subsystem_audio_transport_Finish *self, R4SdkSubsystemNative_subsystem_audio_transport_Completion *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,88u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Finish_set_completion(R4SdkSubsystemNative_subsystem_audio_transport_Finish *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,88u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Finish_get_error_code(const R4SdkSubsystemNative_subsystem_audio_transport_Finish *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,88u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Finish_set_error_code(R4SdkSubsystemNative_subsystem_audio_transport_Finish *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,88u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Finish_get_control_requests(const R4SdkSubsystemNative_subsystem_audio_transport_Finish *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,88u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Finish_set_control_requests(R4SdkSubsystemNative_subsystem_audio_transport_Finish *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,88u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Finish_get_progress(const R4SdkSubsystemNative_subsystem_audio_transport_Finish *self, R4AudioServiceStreamProgressState *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,88u,3u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Finish_set_progress(R4SdkSubsystemNative_subsystem_audio_transport_Finish *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,88u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_subsystem_audio_transport_Finish_inspectNative(const R4SdkSubsystemNative_subsystem_audio_transport_Finish *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,88u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue89_create(R4SdkSubsystemNativeValue89 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,89u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue89_inspectNative(const R4SdkSubsystemNativeValue89 *self, R4SdkSubsystemNative_subsystem_audio_transport_Completion *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,89u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeLifecycleState_create(R4SdkSubsystemRuntimeLifecycleState *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,90u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeLifecycleState_inspectNative(const R4SdkSubsystemRuntimeLifecycleState *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,90u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeLifecycleCommand_create(R4SdkSubsystemRuntimeLifecycleCommand *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,91u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeLifecycleCommand_inspectNative(const R4SdkSubsystemRuntimeLifecycleCommand *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,91u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepStatus_create(R4SdkSubsystemRuntimeStepStatus *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,92u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepStatus_inspectNative(const R4SdkSubsystemRuntimeStepStatus *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,92u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_create(R4SdkSubsystemRuntimeStepResult *output) {
 R4SdkSubsystemSlot a[5]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,93u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_from_fields(R4SdkSubsystemRuntimeStepResult *output, uint32_t p0, uint8_t p1, uint64_t p2, int32_t p3, uint32_t p4) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,93u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_get_status(const R4SdkSubsystemRuntimeStepResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,93u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_set_status(R4SdkSubsystemRuntimeStepResult *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,93u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_get_frame_ready(const R4SdkSubsystemRuntimeStepResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,93u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_set_frame_ready(R4SdkSubsystemRuntimeStepResult *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,93u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_get_wake_guest_ns(const R4SdkSubsystemRuntimeStepResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,93u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_set_wake_guest_ns(R4SdkSubsystemRuntimeStepResult *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,93u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_get_exit_code(const R4SdkSubsystemRuntimeStepResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,93u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_set_exit_code(R4SdkSubsystemRuntimeStepResult *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,93u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_get_operations(const R4SdkSubsystemRuntimeStepResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,93u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_set_operations(R4SdkSubsystemRuntimeStepResult *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,93u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeStepResult_inspectNative(const R4SdkSubsystemRuntimeStepResult *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,93u,(void *)self,0); }
#define R4SdkSubsystemRuntimeHostPollResult_TAG_idle 0u
#define R4SdkSubsystemRuntimeHostPollResult_TAG_ignored 1u
#define R4SdkSubsystemRuntimeHostPollResult_TAG_handled 2u
#define R4SdkSubsystemRuntimeHostPollResult_TAG_present 3u
#define R4SdkSubsystemRuntimeHostPollResult_TAG_command 4u
#define R4SdkSubsystemRuntimeHostPollResult_TAG_failure 5u
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_get_idle(const R4SdkSubsystemRuntimeHostPollResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,94u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_set_idle(R4SdkSubsystemRuntimeHostPollResult *self) { R4SdkSubsystemSlot a[1]={0};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,94u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_get_ignored(const R4SdkSubsystemRuntimeHostPollResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,94u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_set_ignored(R4SdkSubsystemRuntimeHostPollResult *self) { R4SdkSubsystemSlot a[1]={0};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,94u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_get_handled(const R4SdkSubsystemRuntimeHostPollResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,94u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_set_handled(R4SdkSubsystemRuntimeHostPollResult *self) { R4SdkSubsystemSlot a[1]={0};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,94u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_get_present(const R4SdkSubsystemRuntimeHostPollResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,94u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_set_present(R4SdkSubsystemRuntimeHostPollResult *self) { R4SdkSubsystemSlot a[1]={0};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,94u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_get_command(const R4SdkSubsystemRuntimeHostPollResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,94u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_set_command(R4SdkSubsystemRuntimeHostPollResult *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,94u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_get_failure(const R4SdkSubsystemRuntimeHostPollResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,94u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_set_failure(R4SdkSubsystemRuntimeHostPollResult *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,94u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostPollResult_inspectNative(const R4SdkSubsystemRuntimeHostPollResult *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,94u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type___create(R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type__ *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,95u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type___inspectNative(const R4SdkSubsystemNative__typeInfo_subsystem_runtime_HostPollResult____union__tag_type__ *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,95u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_create(R4SdkSubsystemRuntimeAudioFeedback *output, uint32_t p0, uint8_t p1) {
 R4SdkSubsystemSlot a[12]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[8].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[9].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[10].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[11].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,96u,a,12u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_from_fields(R4SdkSubsystemRuntimeAudioFeedback *output, uint32_t p0, uint8_t p1, uint64_t p2, uint64_t p3, uint64_t p4, R4SdkSubsystemSlot p5, uint64_t p6, uint64_t p7, uint64_t p8, uint64_t p9, uint64_t p10, uint64_t p11) {
 R4SdkSubsystemSlot a[12]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = p5;
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[8] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[9] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[10] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[11] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,96u,a,12u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_get_state(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_set_state(R4SdkSubsystemRuntimeAudioFeedback *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_get_muted(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_set_muted(R4SdkSubsystemRuntimeAudioFeedback *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_get_accepted_bytes(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_set_accepted_bytes(R4SdkSubsystemRuntimeAudioFeedback *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_get_suppressed_bytes(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_set_suppressed_bytes(R4SdkSubsystemRuntimeAudioFeedback *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_get_discarded_bytes(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_set_discarded_bytes(R4SdkSubsystemRuntimeAudioFeedback *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_get_playback_frames(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_set_playback_frames(R4SdkSubsystemRuntimeAudioFeedback *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_get_backend_frames(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_set_backend_frames(R4SdkSubsystemRuntimeAudioFeedback *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_get_dma_frames(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_set_dma_frames(R4SdkSubsystemRuntimeAudioFeedback *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_get_unconfirmed_frames(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,8u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_set_unconfirmed_frames(R4SdkSubsystemRuntimeAudioFeedback *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,8u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_get_queued_frames(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,9u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_set_queued_frames(R4SdkSubsystemRuntimeAudioFeedback *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,9u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_get_queue_age_ns(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,10u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_set_queue_age_ns(R4SdkSubsystemRuntimeAudioFeedback *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,10u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_get_source_starvations(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,11u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_set_source_starvations(R4SdkSubsystemRuntimeAudioFeedback *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,96u,11u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioFeedback_inspectNative(const R4SdkSubsystemRuntimeAudioFeedback *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,96u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioState_create(R4SdkSubsystemRuntimeAudioState *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,97u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioState_inspectNative(const R4SdkSubsystemRuntimeAudioState *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,97u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_create(R4SdkSubsystemRuntimeGuestDriver *output, void * p0, uintptr_t p1, uintptr_t p2, uintptr_t p3) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,99u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_from_fields(R4SdkSubsystemRuntimeGuestDriver *output, void * p0, uintptr_t p1, uintptr_t p2, uintptr_t p3, R4SdkSubsystemSlot p4) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = p4;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,99u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_get_context(const R4SdkSubsystemRuntimeGuestDriver *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,99u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_set_context(R4SdkSubsystemRuntimeGuestDriver *self, void * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,99u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_get_step_fn(const R4SdkSubsystemRuntimeGuestDriver *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,99u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_set_step_fn(R4SdkSubsystemRuntimeGuestDriver *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,99u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_get_reset_fn(const R4SdkSubsystemRuntimeGuestDriver *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,99u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_set_reset_fn(R4SdkSubsystemRuntimeGuestDriver *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,99u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_get_render_audio_fn(const R4SdkSubsystemRuntimeGuestDriver *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,99u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_set_render_audio_fn(R4SdkSubsystemRuntimeGuestDriver *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,99u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_get_audio_feedback_fn(const R4SdkSubsystemRuntimeGuestDriver *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,99u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_set_audio_feedback_fn(R4SdkSubsystemRuntimeGuestDriver *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,99u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestDriver_inspectNative(const R4SdkSubsystemRuntimeGuestDriver *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,99u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue100_create(R4SdkSubsystemNativeValue100 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,100u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue100_inspectNative(const R4SdkSubsystemNativeValue100 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,100u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_create(R4SdkSubsystemRuntimeHostDriver *output, void * p0, uintptr_t p1, uintptr_t p2) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,101u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_from_fields(R4SdkSubsystemRuntimeHostDriver *output, void * p0, uintptr_t p1, uintptr_t p2, R4SdkSubsystemSlot p3, R4SdkSubsystemSlot p4) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = p3;
 a[4] = p4;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,101u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_get_context(const R4SdkSubsystemRuntimeHostDriver *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,101u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_set_context(R4SdkSubsystemRuntimeHostDriver *self, void * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,101u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_get_poll_fn(const R4SdkSubsystemRuntimeHostDriver *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,101u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_set_poll_fn(R4SdkSubsystemRuntimeHostDriver *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,101u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_get_present_fn(const R4SdkSubsystemRuntimeHostDriver *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,101u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_set_present_fn(R4SdkSubsystemRuntimeHostDriver *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,101u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_get_wait_fn(const R4SdkSubsystemRuntimeHostDriver *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,101u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_set_wait_fn(R4SdkSubsystemRuntimeHostDriver *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,101u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_get_should_close_fn(const R4SdkSubsystemRuntimeHostDriver *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,101u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_set_should_close_fn(R4SdkSubsystemRuntimeHostDriver *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,101u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeHostDriver_inspectNative(const R4SdkSubsystemRuntimeHostDriver *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,101u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue102_create(R4SdkSubsystemNativeValue102 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,102u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue102_inspectNative(const R4SdkSubsystemNativeValue102 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,102u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue103_create(R4SdkSubsystemNativeValue103 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,103u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue103_inspectNative(const R4SdkSubsystemNativeValue103 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,103u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_create(R4SdkSubsystemRuntimeGuestClock *output, uint32_t p0) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,104u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_from_fields(R4SdkSubsystemRuntimeGuestClock *output, uint32_t p0, uint64_t p1, uint64_t p2, uint64_t p3, uint8_t p4) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,104u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_get_monotonic_hz(const R4SdkSubsystemRuntimeGuestClock *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,104u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_set_monotonic_hz(R4SdkSubsystemRuntimeGuestClock *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,104u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_get_last_host_tick(const R4SdkSubsystemRuntimeGuestClock *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,104u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_set_last_host_tick(R4SdkSubsystemRuntimeGuestClock *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,104u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_get_guest_ns(const R4SdkSubsystemRuntimeGuestClock *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,104u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_set_guest_ns(R4SdkSubsystemRuntimeGuestClock *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,104u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_get_remainder(const R4SdkSubsystemRuntimeGuestClock *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,104u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_set_remainder(R4SdkSubsystemRuntimeGuestClock *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,104u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_get_paused(const R4SdkSubsystemRuntimeGuestClock *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,104u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_set_paused(R4SdkSubsystemRuntimeGuestClock *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,104u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeGuestClock_inspectNative(const R4SdkSubsystemRuntimeGuestClock *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,104u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePacer_create(R4SdkSubsystemRuntimePacer *output, uint64_t p0) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,105u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePacer_from_fields(R4SdkSubsystemRuntimePacer *output, uint64_t p0, uint64_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,105u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePacer_get_interval_ns(const R4SdkSubsystemRuntimePacer *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,105u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePacer_set_interval_ns(R4SdkSubsystemRuntimePacer *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,105u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePacer_get_next_ns(const R4SdkSubsystemRuntimePacer *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,105u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePacer_set_next_ns(R4SdkSubsystemRuntimePacer *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,105u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePacer_inspectNative(const R4SdkSubsystemRuntimePacer *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,105u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_create(R4SdkSubsystemRuntimeAudioConfig *output) {
 R4SdkSubsystemSlot a[10]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[8].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[9].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,106u,a,10u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_from_fields(R4SdkSubsystemRuntimeAudioConfig *output, uint32_t p0, uint16_t p1, uint32_t p2, uint32_t p3, uint16_t p4, uint16_t p5, uint64_t p6, uint8_t p7, uint32_t p8, uint32_t p9) {
 R4SdkSubsystemSlot a[10]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[8] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[9] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,106u,a,10u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_get_sample_rate(const R4SdkSubsystemRuntimeAudioConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_set_sample_rate(R4SdkSubsystemRuntimeAudioConfig *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_get_channels(const R4SdkSubsystemRuntimeAudioConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_set_channels(R4SdkSubsystemRuntimeAudioConfig *self, uint16_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_get_volume(const R4SdkSubsystemRuntimeAudioConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_set_volume(R4SdkSubsystemRuntimeAudioConfig *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_get_quantum_frames(const R4SdkSubsystemRuntimeAudioConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_set_quantum_frames(R4SdkSubsystemRuntimeAudioConfig *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_get_target_quanta(const R4SdkSubsystemRuntimeAudioConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_set_target_quanta(R4SdkSubsystemRuntimeAudioConfig *self, uint16_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_get_max_catchup_quanta(const R4SdkSubsystemRuntimeAudioConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_set_max_catchup_quanta(R4SdkSubsystemRuntimeAudioConfig *self, uint16_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_get_busy_retry_nanoseconds(const R4SdkSubsystemRuntimeAudioConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_set_busy_retry_nanoseconds(R4SdkSubsystemRuntimeAudioConfig *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_get_continuous(const R4SdkSubsystemRuntimeAudioConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_set_continuous(R4SdkSubsystemRuntimeAudioConfig *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_get_low_water_frames(const R4SdkSubsystemRuntimeAudioConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,8u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_set_low_water_frames(R4SdkSubsystemRuntimeAudioConfig *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,8u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_get_high_water_frames(const R4SdkSubsystemRuntimeAudioConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,9u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_set_high_water_frames(R4SdkSubsystemRuntimeAudioConfig *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,106u,9u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioConfig_inspectNative(const R4SdkSubsystemRuntimeAudioConfig *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,106u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_create(R4SdkSubsystemRuntimeAudioSink *output, void * p0, uintptr_t p1, uintptr_t p2, uintptr_t p3, uintptr_t p4) {
 R4SdkSubsystemSlot a[8]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,107u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_from_fields(R4SdkSubsystemRuntimeAudioSink *output, void * p0, uintptr_t p1, uintptr_t p2, uintptr_t p3, uintptr_t p4, R4SdkSubsystemSlot p5, R4SdkSubsystemSlot p6, R4SdkSubsystemSlot p7) {
 R4SdkSubsystemSlot a[8]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = p5;
 a[6] = p6;
 a[7] = p7;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,107u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_get_context(const R4SdkSubsystemRuntimeAudioSink *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_set_context(R4SdkSubsystemRuntimeAudioSink *self, void * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_get_open_fn(const R4SdkSubsystemRuntimeAudioSink *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_set_open_fn(R4SdkSubsystemRuntimeAudioSink *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_get_write_fn(const R4SdkSubsystemRuntimeAudioSink *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_set_write_fn(R4SdkSubsystemRuntimeAudioSink *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_get_volume_fn(const R4SdkSubsystemRuntimeAudioSink *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_set_volume_fn(R4SdkSubsystemRuntimeAudioSink *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_get_close_fn(const R4SdkSubsystemRuntimeAudioSink *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_set_close_fn(R4SdkSubsystemRuntimeAudioSink *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_get_poll_fn(const R4SdkSubsystemRuntimeAudioSink *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_set_poll_fn(R4SdkSubsystemRuntimeAudioSink *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_get_finish_fn(const R4SdkSubsystemRuntimeAudioSink *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_set_finish_fn(R4SdkSubsystemRuntimeAudioSink *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_get_progress_fn(const R4SdkSubsystemRuntimeAudioSink *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_set_progress_fn(R4SdkSubsystemRuntimeAudioSink *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,107u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioSink_inspectNative(const R4SdkSubsystemRuntimeAudioSink *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,107u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue108_create(R4SdkSubsystemNativeValue108 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,108u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue108_inspectNative(const R4SdkSubsystemNativeValue108 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,108u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue109_create(R4SdkSubsystemNativeValue109 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,109u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue109_inspectNative(const R4SdkSubsystemNativeValue109 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,109u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue110_create(R4SdkSubsystemNativeValue110 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,110u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue110_inspectNative(const R4SdkSubsystemNativeValue110 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,110u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_create(R4SdkSubsystemRuntimeR4AudioSink *output, const R4SdkSubsystemNative_app_audio_Audio * p0) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,111u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_from_fields(R4SdkSubsystemRuntimeR4AudioSink *output, const R4SdkSubsystemNative_app_audio_Audio * p0, R4SdkSubsystemSlot p1, const R4Timeout * p2, const R4Timeout * p3) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = p1;
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,111u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_get_audio(const R4SdkSubsystemRuntimeR4AudioSink *self, R4SdkSubsystemNative_app_audio_Audio *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,111u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_set_audio(R4SdkSubsystemRuntimeR4AudioSink *self, const R4SdkSubsystemNative_app_audio_Audio * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,111u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_get_transport_owner(const R4SdkSubsystemRuntimeR4AudioSink *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,111u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_set_transport_owner(R4SdkSubsystemRuntimeR4AudioSink *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,111u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_get_timeout(const R4SdkSubsystemRuntimeR4AudioSink *self, R4Timeout *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,111u,2u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_set_timeout(R4SdkSubsystemRuntimeR4AudioSink *self, const R4Timeout * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,111u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_get_close_timeout(const R4SdkSubsystemRuntimeR4AudioSink *self, R4Timeout *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,111u,3u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_set_close_timeout(R4SdkSubsystemRuntimeR4AudioSink *self, const R4Timeout * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,111u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeR4AudioSink_inspectNative(const R4SdkSubsystemRuntimeR4AudioSink *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,111u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_create(R4SdkSubsystemRuntimeAudioStats *output) {
 R4SdkSubsystemSlot a[48]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[8].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[9].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[10].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[11].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[12].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[13].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[14].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[15].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[16].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[17].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[18].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[19].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[20].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[21].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[22].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[23].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[24].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[25].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[26].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[27].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[28].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[29].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[30].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[31].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[32].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[33].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[34].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[35].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[36].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[37].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[38].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[39].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[40].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[41].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[42].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[43].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[44].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[45].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[46].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[47].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,114u,a,48u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_from_fields(R4SdkSubsystemRuntimeAudioStats *output, R4SdkSubsystemSlot p0, uint64_t p1, uint64_t p2, uint64_t p3, uint64_t p4, uint64_t p5, uint64_t p6, uint64_t p7, uint64_t p8, uint64_t p9, uint64_t p10, uint64_t p11, uint64_t p12, uint64_t p13, uint64_t p14, uint64_t p15, uint64_t p16, uint64_t p17, uint64_t p18, uint64_t p19, uint64_t p20, uint64_t p21, uint64_t p22, uint64_t p23, uint64_t p24, uint64_t p25, uint64_t p26, uint64_t p27, uint64_t p28, uint64_t p29, uint64_t p30, uint64_t p31, uint64_t p32, uint64_t p33, uint64_t p34, uint64_t p35, uint64_t p36, uint64_t p37, uint64_t p38, uint64_t p39, uint64_t p40, uint64_t p41, uint64_t p42, uint64_t p43, uint64_t p44, uint64_t p45, uint64_t p46, uint16_t p47) {
 R4SdkSubsystemSlot a[48]={0};
 a[0] = p0;
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[8] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[9] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[10] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[11] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[12] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[13] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[14] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p14,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[15] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p15,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[16] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p16,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[17] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p17,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[18] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p18,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[19] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p19,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[20] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p20,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[21] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p21,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[22] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p22,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[23] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p23,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[24] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p24,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[25] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p25,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[26] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p26,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[27] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p27,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[28] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p28,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[29] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p29,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[30] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p30,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[31] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p31,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[32] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p32,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[33] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p33,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[34] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p34,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[35] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p35,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[36] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p36,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[37] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p37,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[38] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p38,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[39] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p39,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[40] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p40,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[41] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p41,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[42] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p42,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[43] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p43,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[44] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p44,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[45] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p45,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[46] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p46,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[47] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p47,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,114u,a,48u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_playback_frames(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_playback_frames(R4SdkSubsystemRuntimeAudioStats *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_backend_frames(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_backend_frames(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_dma_frames(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_dma_frames(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_unconfirmed_frames(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_unconfirmed_frames(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_queued_frames(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_queued_frames(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_queue_age_ns(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_queue_age_ns(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_source_starvations(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_source_starvations(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_progress_queries(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_progress_queries(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_retired_playback_frames(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,8u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_retired_playback_frames(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,8u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_retired_unconfirmed_frames(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,9u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_retired_unconfirmed_frames(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,9u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_backend_generation(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,10u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_backend_generation(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,10u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_output_generation(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,11u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_output_generation(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,11u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_reset_generation(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,12u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_reset_generation(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,12u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_stream_generation(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,13u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_stream_generation(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,13u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_progress_observed_ns(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,14u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_progress_observed_ns(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,14u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_generated_bytes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,15u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_generated_bytes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,15u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_submitted_bytes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,16u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_submitted_bytes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,16u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_discarded_bytes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,17u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_discarded_bytes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,17u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_retired_submitted_bytes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,18u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_retired_submitted_bytes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,18u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_retired_discarded_bytes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,19u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_retired_discarded_bytes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,19u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_async_submissions(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,20u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_async_submissions(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,20u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_async_completions(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,21u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_async_completions(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,21u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_async_pending_cycles(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,22u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_async_pending_cycles(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,22u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_partial_writes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,23u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_partial_writes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,23u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_silence_bytes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,24u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_silence_bytes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,24u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_muted_bytes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,25u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_muted_bytes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,25u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_underflows(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,26u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_underflows(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,26u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_open_retries(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,27u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_open_retries(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,27u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_writes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,28u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_writes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,28u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_busy_writes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,29u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_busy_writes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,29u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_write_failures(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,30u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_write_failures(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,30u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_late_resyncs(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,31u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_late_resyncs(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,31u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_suppressed_bytes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,32u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_suppressed_bytes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,32u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_idle_quanta(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,33u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_idle_quanta(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,33u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_lazy_opens(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,34u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_lazy_opens(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,34u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_idle_closes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,35u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_idle_closes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,35u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_active_cycles(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,36u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_active_cycles(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,36u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_silent_cycles(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,37u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_silent_cycles(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,37u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_paused_cycles(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,38u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_paused_cycles(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,38u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_muted_cycles(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,39u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_muted_cycles(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,39u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_active_quanta(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,40u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_active_quanta(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,40u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_silent_quanta(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,41u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_silent_quanta(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,41u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_paused_bytes(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,42u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_paused_bytes(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,42u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_service_operations(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,43u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_service_operations(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,43u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_open_operations(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,44u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_open_operations(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,44u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_write_operations(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,45u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_write_operations(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,45u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_close_operations(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,46u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_close_operations(R4SdkSubsystemRuntimeAudioStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,46u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_get_maximum_service_operations_per_cycle(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,47u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_set_maximum_service_operations_per_cycle(R4SdkSubsystemRuntimeAudioStats *self, uint16_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,114u,47u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioStats_inspectNative(const R4SdkSubsystemRuntimeAudioStats *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,114u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_create(R4SdkSubsystemRuntimePcmQueue *output, uint8_t * p0, uintptr_t n0) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,115u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_from_fields(R4SdkSubsystemRuntimePcmQueue *output, uint8_t * p0, uintptr_t n0, uint64_t p1, uint64_t p2, uint64_t p3) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,115u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_get_storage(const R4SdkSubsystemRuntimePcmQueue *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,115u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_set_storage(R4SdkSubsystemRuntimePcmQueue *self, uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,115u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_get_frame_bytes(const R4SdkSubsystemRuntimePcmQueue *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,115u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_set_frame_bytes(R4SdkSubsystemRuntimePcmQueue *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,115u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_get_read_pos(const R4SdkSubsystemRuntimePcmQueue *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,115u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_set_read_pos(R4SdkSubsystemRuntimePcmQueue *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,115u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_get_len(const R4SdkSubsystemRuntimePcmQueue *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,115u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_set_len(R4SdkSubsystemRuntimePcmQueue *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,115u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimePcmQueue_inspectNative(const R4SdkSubsystemRuntimePcmQueue *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,115u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioOptions_create(R4SdkSubsystemRuntimeAudioOptions *output, uint8_t * p1, uintptr_t n1, uint8_t * p2, uintptr_t n2) {
 R4SdkSubsystemSlot a[4]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,116u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioOptions_from_fields(R4SdkSubsystemRuntimeAudioOptions *output, const R4SdkSubsystemRuntimeAudioConfig * p0, uint8_t * p1, uintptr_t n1, uint8_t * p2, uintptr_t n2, R4SdkSubsystemSlot p3) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = p3;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,116u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioOptions_get_config(const R4SdkSubsystemRuntimeAudioOptions *self, R4SdkSubsystemRuntimeAudioConfig *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,116u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioOptions_set_config(R4SdkSubsystemRuntimeAudioOptions *self, const R4SdkSubsystemRuntimeAudioConfig * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,116u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioOptions_get_queue_storage(const R4SdkSubsystemRuntimeAudioOptions *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,116u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioOptions_set_queue_storage(R4SdkSubsystemRuntimeAudioOptions *self, uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,116u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioOptions_get_scratch(const R4SdkSubsystemRuntimeAudioOptions *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,116u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioOptions_set_scratch(R4SdkSubsystemRuntimeAudioOptions *self, uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,116u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioOptions_get_sink(const R4SdkSubsystemRuntimeAudioOptions *self, R4SdkSubsystemRuntimeAudioSink *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,116u,3u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioOptions_set_sink(R4SdkSubsystemRuntimeAudioOptions *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,116u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioOptions_inspectNative(const R4SdkSubsystemRuntimeAudioOptions *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,116u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue117_create(R4SdkSubsystemNativeValue117 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,117u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue117_inspectNative(const R4SdkSubsystemNativeValue117 *self, R4SdkSubsystemRuntimeAudioSink *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,117u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_create(R4SdkSubsystemRuntimeAudioPump *output) {
 R4SdkSubsystemSlot a[33]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[8].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[9].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[10].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[11].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[12].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[13].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[14].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[15].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[16].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[17].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[18].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[19].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[20].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[21].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[22].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[23].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[24].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[25].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[26].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[27].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[28].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[29].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[30].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[31].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[32].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,118u,a,33u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_from_fields(R4SdkSubsystemRuntimeAudioPump *output, const R4SdkSubsystemRuntimeAudioConfig * p0, const R4SdkSubsystemRuntimePcmQueue * p1, uint8_t * p2, uintptr_t n2, R4SdkSubsystemSlot p3, uint32_t p4, int32_t p5, uint8_t p6, uint64_t p7, uint64_t p8, uint32_t p9, uint64_t p10, uint64_t p11, uint16_t p12, uint16_t p13, uint8_t p14, uint8_t p15, R4SdkSubsystemSlot p16, uint64_t p17, uint8_t p18, uint8_t p19, uint32_t p20, uint8_t p21, uint64_t p22, int32_t p23, uint64_t p24, uint16_t p25, const R4SdkSubsystemRuntimeAudioStats * p26, const R4AudioServiceStreamProgressState * p27, uint8_t p28, uint8_t p29, uint64_t p30, uint8_t p31, uint8_t p32) {
 R4SdkSubsystemSlot a[33]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = p3;
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[8] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[9] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[10] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[11] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[12] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[13] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[14] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p14,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[15] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p15,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[16] = p16;
 a[17] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p17,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[18] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p18,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[19] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p19,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[20] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p20,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[21] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p21,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[22] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p22,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[23] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p23,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[24] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p24,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[25] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p25,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[26] = (R4SdkSubsystemSlot){.ptr=(void *)p26,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[27] = (R4SdkSubsystemSlot){.ptr=(void *)p27,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[28] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p28,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[29] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p29,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[30] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p30,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[31] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p31,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[32] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p32,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,118u,a,33u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_config(const R4SdkSubsystemRuntimeAudioPump *self, R4SdkSubsystemRuntimeAudioConfig *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_config(R4SdkSubsystemRuntimeAudioPump *self, const R4SdkSubsystemRuntimeAudioConfig * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_queue(const R4SdkSubsystemRuntimeAudioPump *self, R4SdkSubsystemRuntimePcmQueue *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_queue(R4SdkSubsystemRuntimeAudioPump *self, const R4SdkSubsystemRuntimePcmQueue * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_scratch(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_scratch(R4SdkSubsystemRuntimeAudioPump *self, uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_sink(const R4SdkSubsystemRuntimeAudioPump *self, R4SdkSubsystemRuntimeAudioSink *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,3u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_sink(R4SdkSubsystemRuntimeAudioPump *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_state(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_state(R4SdkSubsystemRuntimeAudioPump *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_last_error(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_last_error(R4SdkSubsystemRuntimeAudioPump *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_muted(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_muted(R4SdkSubsystemRuntimeAudioPump *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_next_deadline_tick(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_next_deadline_tick(R4SdkSubsystemRuntimeAudioPump *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_quantum_ticks(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,8u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_quantum_ticks(R4SdkSubsystemRuntimeAudioPump *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,8u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_monotonic_hz(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,9u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_monotonic_hz(R4SdkSubsystemRuntimeAudioPump *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,9u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_busy_retry_ticks(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,10u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_busy_retry_ticks(R4SdkSubsystemRuntimeAudioPump *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,10u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_open_retry_ticks(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,11u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_open_retry_ticks(R4SdkSubsystemRuntimeAudioPump *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,11u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_open_retry_attempts(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,12u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_open_retry_attempts(R4SdkSubsystemRuntimeAudioPump *self, uint16_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,12u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_resync_prefill_quanta(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,13u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_resync_prefill_quanta(R4SdkSubsystemRuntimeAudioPump *self, uint16_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,13u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_sink_open(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,14u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_sink_open(R4SdkSubsystemRuntimeAudioPump *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,14u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_close_pending(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,15u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_close_pending(R4SdkSubsystemRuntimeAudioPump *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,15u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_pending_operation(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,16u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_pending_operation(R4SdkSubsystemRuntimeAudioPump *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,16u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_pending_bytes(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,17u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_pending_bytes(R4SdkSubsystemRuntimeAudioPump *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,17u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_pending_idle_close(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,18u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_pending_idle_close(R4SdkSubsystemRuntimeAudioPump *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,18u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_discard_after_pending(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,19u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_discard_after_pending(R4SdkSubsystemRuntimeAudioPump *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,19u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_pending_discard_reason(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,20u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_pending_discard_reason(R4SdkSubsystemRuntimeAudioPump *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,20u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_retire_pending_feedback(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,21u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_retire_pending_feedback(R4SdkSubsystemRuntimeAudioPump *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,21u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_sink_generation(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,22u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_sink_generation(R4SdkSubsystemRuntimeAudioPump *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,22u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_close_error(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,23u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_close_error(R4SdkSubsystemRuntimeAudioPump *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,23u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_close_retry_tick(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,24u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_close_retry_tick(R4SdkSubsystemRuntimeAudioPump *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,24u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_service_operations_cycle(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,25u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_service_operations_cycle(R4SdkSubsystemRuntimeAudioPump *self, uint16_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,25u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_stats(const R4SdkSubsystemRuntimeAudioPump *self, R4SdkSubsystemRuntimeAudioStats *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,26u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_stats(R4SdkSubsystemRuntimeAudioPump *self, const R4SdkSubsystemRuntimeAudioStats * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,26u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_progress_record(const R4SdkSubsystemRuntimeAudioPump *self, R4AudioServiceStreamProgressState *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,27u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_progress_record(R4SdkSubsystemRuntimeAudioPump *self, const R4AudioServiceStreamProgressState * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,27u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_progress_seen(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,28u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_progress_seen(R4SdkSubsystemRuntimeAudioPump *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,28u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_progress_ready(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,29u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_progress_ready(R4SdkSubsystemRuntimeAudioPump *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,29u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_progress_due_tick(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,30u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_progress_due_tick(R4SdkSubsystemRuntimeAudioPump *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,30u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_feedback_retire_current(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,31u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_feedback_retire_current(R4SdkSubsystemRuntimeAudioPump *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,31u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_get_progress_record_retired(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,32u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_set_progress_record_retired(R4SdkSubsystemRuntimeAudioPump *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,118u,32u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_inspectNative(const R4SdkSubsystemRuntimeAudioPump *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,118u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue119_create(R4SdkSubsystemNativeValue119 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,119u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue119_inspectNative(const R4SdkSubsystemNativeValue119 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,119u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_DiscardReason_create(R4SdkSubsystemRuntimeAudioPump_DiscardReason *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,120u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeAudioPump_DiscardReason_inspectNative(const R4SdkSubsystemRuntimeAudioPump_DiscardReason *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,120u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeConfig_create(R4SdkSubsystemRuntimeConfig *output) {
 R4SdkSubsystemSlot a[4]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,121u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeConfig_from_fields(R4SdkSubsystemRuntimeConfig *output, uint32_t p0, uint16_t p1, uint64_t p2, uint64_t p3) {
 R4SdkSubsystemSlot a[4]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,121u,a,4u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeConfig_get_slice_budget(const R4SdkSubsystemRuntimeConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,121u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeConfig_set_slice_budget(R4SdkSubsystemRuntimeConfig *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,121u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeConfig_get_max_input_events(const R4SdkSubsystemRuntimeConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,121u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeConfig_set_max_input_events(R4SdkSubsystemRuntimeConfig *self, uint16_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,121u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeConfig_get_max_wait_ticks(const R4SdkSubsystemRuntimeConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,121u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeConfig_set_max_wait_ticks(R4SdkSubsystemRuntimeConfig *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,121u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeConfig_get_idle_retry_ticks(const R4SdkSubsystemRuntimeConfig *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,121u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeConfig_set_idle_retry_ticks(R4SdkSubsystemRuntimeConfig *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,121u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeConfig_inspectNative(const R4SdkSubsystemRuntimeConfig *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,121u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_create(R4SdkSubsystemRuntimeRuntimeStats *output) {
 R4SdkSubsystemSlot a[29]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[8].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[9].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[10].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[11].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[12].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[13].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[14].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[15].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[16].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[17].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[18].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[19].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[20].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[21].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[22].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[23].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[24].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[25].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[26].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[27].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[28].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,122u,a,29u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_from_fields(R4SdkSubsystemRuntimeRuntimeStats *output, uint64_t p0, uint64_t p1, uint64_t p2, uint64_t p3, uint64_t p4, uint64_t p5, uint64_t p6, uint64_t p7, uint64_t p8, uint64_t p9, uint64_t p10, uint64_t p11, uint64_t p12, uint64_t p13, uint64_t p14, uint64_t p15, uint64_t p16, uint64_t p17, uint64_t p18, uint64_t p19, uint64_t p20, uint64_t p21, uint64_t p22, uint64_t p23, uint64_t p24, uint64_t p25, uint64_t p26, uint64_t p27, uint64_t p28) {
 R4SdkSubsystemSlot a[29]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[8] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[9] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[10] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[11] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[12] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[13] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[14] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p14,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[15] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p15,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[16] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p16,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[17] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p17,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[18] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p18,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[19] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p19,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[20] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p20,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[21] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p21,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[22] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p22,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[23] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p23,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[24] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p24,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[25] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p25,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[26] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p26,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[27] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p27,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[28] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p28,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,122u,a,29u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_cycles(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_cycles(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_slices(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_slices(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_requested_operations(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_requested_operations(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_executed_operations(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_executed_operations(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_host_polls(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_host_polls(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_close_checks(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_close_checks(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_poll_budget_exhaustions(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_poll_budget_exhaustions(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_input_events(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_input_events(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_ignored_input_events(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,8u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_ignored_input_events(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,8u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_active_cycles(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,9u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_active_cycles(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,9u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_waiting_cycles(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,10u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_waiting_cycles(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,10u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_paused_cycles(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,11u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_paused_cycles(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,11u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_present_attempts(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,12u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_present_attempts(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,12u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_presents(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,13u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_presents(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,13u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_skipped_presents(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,14u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_skipped_presents(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,14u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_unchanged_presents(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,15u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_unchanged_presents(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,15u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_hidden_presents(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,16u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_hidden_presents(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,16u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_dropped_presents(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,17u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_dropped_presents(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,17u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_pauses(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,18u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_pauses(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,18u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_resumes(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,19u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_resumes(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,19u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_resets(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,20u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_resets(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,20u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_active_continues(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,21u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_active_continues(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,21u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_yields(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,22u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_yields(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,22u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_sleeps(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,23u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_sleeps(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,23u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_event_waits(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,24u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_event_waits(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,24u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_event_wakes(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,25u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_event_wakes(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,25u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_event_timeouts(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,26u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_event_timeouts(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,26u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_event_wait_failures(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,27u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_event_wait_failures(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,27u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_get_zero_progress_waits(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,28u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_set_zero_progress_waits(R4SdkSubsystemRuntimeRuntimeStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,122u,28u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntimeStats_inspectNative(const R4SdkSubsystemRuntimeRuntimeStats *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,122u,(void *)self,0); }
#define R4SdkSubsystemRuntimeCycleResult_TAG_wait 0u
#define R4SdkSubsystemRuntimeCycleResult_TAG_finished 1u
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeCycleResult_get_wait(const R4SdkSubsystemRuntimeCycleResult *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,123u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeCycleResult_set_wait(R4SdkSubsystemRuntimeCycleResult *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,123u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeCycleResult_get_finished(const R4SdkSubsystemRuntimeCycleResult *self, R4SdkSubsystemNativeValue125 *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,123u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeCycleResult_set_finished(R4SdkSubsystemRuntimeCycleResult *self, const R4SdkSubsystemNativeValue125 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,123u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeCycleResult_inspectNative(const R4SdkSubsystemRuntimeCycleResult *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,123u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative__typeInfo_subsystem_runtime_CycleResult____union__tag_type___create(R4SdkSubsystemNative__typeInfo_subsystem_runtime_CycleResult____union__tag_type__ *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,124u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative__typeInfo_subsystem_runtime_CycleResult____union__tag_type___inspectNative(const R4SdkSubsystemNative__typeInfo_subsystem_runtime_CycleResult____union__tag_type__ *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,124u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue125_create(R4SdkSubsystemNativeValue125 *output, uint32_t p0, int32_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,125u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue125_from_fields(R4SdkSubsystemNativeValue125 *output, uint32_t p0, int32_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,125u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue125_get_state(const R4SdkSubsystemNativeValue125 *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,125u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue125_set_state(R4SdkSubsystemNativeValue125 *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,125u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue125_get_exit_code(const R4SdkSubsystemNativeValue125 *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,125u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue125_set_exit_code(R4SdkSubsystemNativeValue125 *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,125u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue125_inspectNative(const R4SdkSubsystemNativeValue125 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,125u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_create(R4SdkSubsystemRuntimeRuntime *output, const R4SdkSubsystemRuntimeConfig * p0, const R4SdkSubsystemRuntimeGuestClock * p1, uint64_t p11) {
 R4SdkSubsystemSlot a[26]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[8].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[9].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[10].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[11] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[12].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[13].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[14].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[15].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[16].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[17].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[18].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[19].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[20].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[21].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[22].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[23].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[24].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[25].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,126u,a,26u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_from_fields(R4SdkSubsystemRuntimeRuntime *output, const R4SdkSubsystemRuntimeConfig * p0, const R4SdkSubsystemRuntimeGuestClock * p1, const R4SdkSubsystemRuntimeAudioPump * p2, uint32_t p3, int32_t p4, uint64_t p5, uint8_t p6, uint8_t p7, uint8_t p8, uint8_t p9, uint8_t p10, uint64_t p11, uint64_t p12, uint8_t p13, uint8_t p14, uint64_t p15, uint64_t p16, uint64_t p17, uint32_t p18, uint8_t p19, uint8_t p20, R4SdkSubsystemSlot p21, uint64_t p22, uint64_t p23, uint64_t p24, const R4SdkSubsystemRuntimeRuntimeStats * p25) {
 R4SdkSubsystemSlot a[26]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[8] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[9] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[10] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[11] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[12] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[13] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[14] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p14,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[15] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p15,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[16] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p16,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[17] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p17,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[18] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p18,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[19] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p19,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[20] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p20,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[21] = p21;
 a[22] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p22,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[23] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p23,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[24] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p24,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[25] = (R4SdkSubsystemSlot){.ptr=(void *)p25,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,126u,a,26u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_config(const R4SdkSubsystemRuntimeRuntime *self, R4SdkSubsystemRuntimeConfig *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_config(R4SdkSubsystemRuntimeRuntime *self, const R4SdkSubsystemRuntimeConfig * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_clock(const R4SdkSubsystemRuntimeRuntime *self, R4SdkSubsystemRuntimeGuestClock *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_clock(R4SdkSubsystemRuntimeRuntime *self, const R4SdkSubsystemRuntimeGuestClock * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_audio(const R4SdkSubsystemRuntimeRuntime *self, R4SdkSubsystemRuntimeAudioPump *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,2u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_audio(R4SdkSubsystemRuntimeRuntime *self, const R4SdkSubsystemRuntimeAudioPump * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_state(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_state(R4SdkSubsystemRuntimeRuntime *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_exit_code(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_exit_code(R4SdkSubsystemRuntimeRuntime *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_guest_wake_ns(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_guest_wake_ns(R4SdkSubsystemRuntimeRuntime *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_guest_waiting(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_guest_waiting(R4SdkSubsystemRuntimeRuntime *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_present_pending(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_present_pending(R4SdkSubsystemRuntimeRuntime *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_guest_idle_polling(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,8u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_guest_idle_polling(R4SdkSubsystemRuntimeRuntime *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,8u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_host_backlog_pending(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,9u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_host_backlog_pending(R4SdkSubsystemRuntimeRuntime *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,9u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_post_present_poll_pending(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,10u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_post_present_poll_pending(R4SdkSubsystemRuntimeRuntime *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,10u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_active_yield_ticks(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,11u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_active_yield_ticks(R4SdkSubsystemRuntimeRuntime *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,11u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_next_yield_tick(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,12u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_next_yield_tick(R4SdkSubsystemRuntimeRuntime *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,12u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_started(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,13u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_started(R4SdkSubsystemRuntimeRuntime *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,13u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_resources_closed(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,14u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_resources_closed(R4SdkSubsystemRuntimeRuntime *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,14u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_audio_feedback_submitted_bytes(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,15u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_audio_feedback_submitted_bytes(R4SdkSubsystemRuntimeRuntime *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,15u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_audio_feedback_suppressed_bytes(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,16u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_audio_feedback_suppressed_bytes(R4SdkSubsystemRuntimeRuntime *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,16u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_audio_feedback_discarded_bytes(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,17u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_audio_feedback_discarded_bytes(R4SdkSubsystemRuntimeRuntime *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,17u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_audio_feedback_state(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,18u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_audio_feedback_state(R4SdkSubsystemRuntimeRuntime *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,18u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_audio_feedback_muted(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,19u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_audio_feedback_muted(R4SdkSubsystemRuntimeRuntime *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,19u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_audio_feedback_initialized(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,20u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_audio_feedback_initialized(R4SdkSubsystemRuntimeRuntime *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,20u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_audio_feedback_playback_frames(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,21u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_audio_feedback_playback_frames(R4SdkSubsystemRuntimeRuntime *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,21u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_audio_feedback_unconfirmed_frames(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,22u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_audio_feedback_unconfirmed_frames(R4SdkSubsystemRuntimeRuntime *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,22u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_audio_feedback_playback_base(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,23u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_audio_feedback_playback_base(R4SdkSubsystemRuntimeRuntime *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,23u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_audio_feedback_unconfirmed_base(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,24u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_audio_feedback_unconfirmed_base(R4SdkSubsystemRuntimeRuntime *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,24u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_get_stats(const R4SdkSubsystemRuntimeRuntime *self, R4SdkSubsystemRuntimeRuntimeStats *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,25u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_set_stats(R4SdkSubsystemRuntimeRuntime *self, const R4SdkSubsystemRuntimeRuntimeStats * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,126u,25u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRuntimeRuntime_inspectNative(const R4SdkSubsystemRuntimeRuntime *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,126u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceFileKind_create(R4SdkSubsystemPersistenceFileKind *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,127u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceFileKind_inspectNative(const R4SdkSubsystemPersistenceFileKind *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,127u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue128_create(R4SdkSubsystemNativeValue128 *output, const R4SdkDataNative_Value158 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,128u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue128_inspectNative(const R4SdkSubsystemNativeValue128 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,128u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue130_create(R4SdkSubsystemNativeValue130 *output, R4SdkSubsystemNativeValue131 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,130u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue130_inspectNative(const R4SdkSubsystemNativeValue130 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,130u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue131_create(R4SdkSubsystemNativeValue131 *output, const R4SdkSubsystemNativeValue131 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,131u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue131_inspectNative(const R4SdkSubsystemNativeValue131 *self, R4SdkSubsystemNativeValue131 *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,131u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceReadResult_create(R4SdkSubsystemPersistenceReadResult *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,132u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceReadResult_inspectNative(const R4SdkSubsystemPersistenceReadResult *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,132u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_create(R4SdkSubsystemPersistenceBackend *output, void * p0, uintptr_t p1, uintptr_t p2, uintptr_t p3, uintptr_t p4) {
 R4SdkSubsystemSlot a[8]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,133u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_from_fields(R4SdkSubsystemPersistenceBackend *output, void * p0, uintptr_t p1, uintptr_t p2, uintptr_t p3, uintptr_t p4, R4SdkSubsystemSlot p5, R4SdkSubsystemSlot p6, R4SdkSubsystemSlot p7) {
 R4SdkSubsystemSlot a[8]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = p5;
 a[6] = p6;
 a[7] = p7;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,133u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_get_context(const R4SdkSubsystemPersistenceBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_set_context(R4SdkSubsystemPersistenceBackend *self, void * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_get_acquire_fn(const R4SdkSubsystemPersistenceBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_set_acquire_fn(R4SdkSubsystemPersistenceBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_get_release_fn(const R4SdkSubsystemPersistenceBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_set_release_fn(R4SdkSubsystemPersistenceBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_get_read_exact_fn(const R4SdkSubsystemPersistenceBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_set_read_exact_fn(R4SdkSubsystemPersistenceBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_get_write_atomic_fn(const R4SdkSubsystemPersistenceBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_set_write_atomic_fn(R4SdkSubsystemPersistenceBackend *self, uintptr_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_get_poll_fn(const R4SdkSubsystemPersistenceBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_set_poll_fn(R4SdkSubsystemPersistenceBackend *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_get_drain_fn(const R4SdkSubsystemPersistenceBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_set_drain_fn(R4SdkSubsystemPersistenceBackend *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_get_pending_fn(const R4SdkSubsystemPersistenceBackend *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_set_pending_fn(R4SdkSubsystemPersistenceBackend *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,133u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceBackend_inspectNative(const R4SdkSubsystemPersistenceBackend *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,133u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue134_create(R4SdkSubsystemNativeValue134 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,134u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue134_inspectNative(const R4SdkSubsystemNativeValue134 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,134u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_create(R4SdkSubsystemPersistenceConfiguration *output, const uint8_t * p0, uintptr_t n0, const R4SdkDataNative_Value31 * p1, uintptr_t n1) {
 R4SdkSubsystemSlot a[8]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,135u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_from_fields(R4SdkSubsystemPersistenceConfiguration *output, const uint8_t * p0, uintptr_t n0, const R4SdkDataNative_Value31 * p1, uintptr_t n1, uint64_t p2, uint64_t p3, uint8_t * p4, uintptr_t n4, R4SdkSubsystemSlot p5, R4SdkSubsystemSlot p6, R4SdkSubsystemSlot p7) {
 R4SdkSubsystemSlot a[8]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = p5;
 a[6] = p6;
 a[7] = p7;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,135u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_get_save_root(const R4SdkSubsystemPersistenceConfiguration *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_set_save_root(R4SdkSubsystemPersistenceConfiguration *self, const uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_get_root_directories(const R4SdkSubsystemPersistenceConfiguration *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_set_root_directories(R4SdkSubsystemPersistenceConfiguration *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_get_rtc_record_bytes(const R4SdkSubsystemPersistenceConfiguration *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_set_rtc_record_bytes(R4SdkSubsystemPersistenceConfiguration *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_get_delta_record_bytes(const R4SdkSubsystemPersistenceConfiguration *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_set_delta_record_bytes(R4SdkSubsystemPersistenceConfiguration *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_get_record_scratch(const R4SdkSubsystemPersistenceConfiguration *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_set_record_scratch(R4SdkSubsystemPersistenceConfiguration *self, uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_get_context(const R4SdkSubsystemPersistenceConfiguration *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_set_context(R4SdkSubsystemPersistenceConfiguration *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_get_validate_rtc(const R4SdkSubsystemPersistenceConfiguration *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_set_validate_rtc(R4SdkSubsystemPersistenceConfiguration *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_get_validate_delta(const R4SdkSubsystemPersistenceConfiguration *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_set_validate_delta(R4SdkSubsystemPersistenceConfiguration *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,135u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceConfiguration_inspectNative(const R4SdkSubsystemPersistenceConfiguration *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,135u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue136_create(R4SdkSubsystemNativeValue136 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,136u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue136_inspectNative(const R4SdkSubsystemNativeValue136 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,136u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemFailureStage_create(R4SdkSubsystemFailureStage *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,137u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemFailureStage_inspectNative(const R4SdkSubsystemFailureStage *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,137u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRecoveryTestState_create(R4SdkSubsystemRecoveryTestState *output, R4SdkSubsystemSlot p0, R4SdkSubsystemSlot p1, R4SdkSubsystemSlot p2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = p0;
 a[1] = p1;
 a[2] = p2;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,138u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRecoveryTestState_from_fields(R4SdkSubsystemRecoveryTestState *output, R4SdkSubsystemSlot p0, R4SdkSubsystemSlot p1, R4SdkSubsystemSlot p2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = p0;
 a[1] = p1;
 a[2] = p2;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,138u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemRecoveryTestState_get_target_size(const R4SdkSubsystemRecoveryTestState *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,138u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRecoveryTestState_set_target_size(R4SdkSubsystemRecoveryTestState *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,138u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRecoveryTestState_get_stage_size(const R4SdkSubsystemRecoveryTestState *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,138u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRecoveryTestState_set_stage_size(R4SdkSubsystemRecoveryTestState *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,138u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRecoveryTestState_get_backup_size(const R4SdkSubsystemRecoveryTestState *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,138u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRecoveryTestState_set_backup_size(R4SdkSubsystemRecoveryTestState *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,138u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemRecoveryTestState_inspectNative(const R4SdkSubsystemRecoveryTestState *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,138u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_create(R4SdkSubsystemStore *output, const R4SdkSubsystemNative_app_storage_Files * p0) {
 R4SdkSubsystemSlot a[7]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,139u,a,7u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_from_fields(R4SdkSubsystemStore *output, const R4SdkSubsystemNative_app_storage_Files * p0, R4SdkSubsystemSlot p1, uint64_t p2, const R4SdkDataNative_Value158 * p3, uint32_t p4, int32_t p5, const R4SdkSubsystemPersistenceConfiguration * p6) {
 R4SdkSubsystemSlot a[7]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = p1;
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.ptr=(void *)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,139u,a,7u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_get_files(const R4SdkSubsystemStore *self, R4SdkSubsystemNative_app_storage_Files *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_set_files(R4SdkSubsystemStore *self, const R4SdkSubsystemNative_app_storage_Files * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_get_lock_writer(const R4SdkSubsystemStore *self, R4SdkSubsystemNative_app_storage_OwnedStageWriter *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_set_lock_writer(R4SdkSubsystemStore *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_get_lock_generation(const R4SdkSubsystemStore *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_set_lock_generation(R4SdkSubsystemStore *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_get_lock_digest(const R4SdkSubsystemStore *self, R4SdkDataNative_Value158 *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,3u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_set_lock_digest(R4SdkSubsystemStore *self, const R4SdkDataNative_Value158 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_get_failure_stage(const R4SdkSubsystemStore *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_set_failure_stage(R4SdkSubsystemStore *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_get_failure_code(const R4SdkSubsystemStore *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_set_failure_code(R4SdkSubsystemStore *self, int32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_get_configuration(const R4SdkSubsystemStore *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_set_configuration(R4SdkSubsystemStore *self, const R4SdkSubsystemPersistenceConfiguration * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,139u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemStore_inspectNative(const R4SdkSubsystemStore *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,139u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue141_create(R4SdkSubsystemNativeValue141 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,141u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue141_inspectNative(const R4SdkSubsystemNativeValue141 *self, R4SdkSubsystemNative_app_storage_OwnedStageWriter *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,141u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue143_create(R4SdkSubsystemNativeValue143 *output, const R4SdkSubsystemPersistenceConfiguration * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,143u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue143_inspectNative(const R4SdkSubsystemNativeValue143 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,143u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_create(R4SdkSubsystemAsyncStats *output) {
 R4SdkSubsystemSlot a[8]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[7].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,144u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_from_fields(R4SdkSubsystemAsyncStats *output, uint64_t p0, uint64_t p1, uint64_t p2, uint64_t p3, uint64_t p4, uint8_t p5, uint64_t p6, uint64_t p7) {
 R4SdkSubsystemSlot a[8]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[6] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[7] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,144u,a,8u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_get_enqueued(const R4SdkSubsystemAsyncStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_set_enqueued(R4SdkSubsystemAsyncStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_get_started(const R4SdkSubsystemAsyncStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_set_started(R4SdkSubsystemAsyncStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_get_completed(const R4SdkSubsystemAsyncStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_set_completed(R4SdkSubsystemAsyncStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_get_coalesced(const R4SdkSubsystemAsyncStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_set_coalesced(R4SdkSubsystemAsyncStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_get_errors(const R4SdkSubsystemAsyncStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_set_errors(R4SdkSubsystemAsyncStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_get_maximum_queued(const R4SdkSubsystemAsyncStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_set_maximum_queued(R4SdkSubsystemAsyncStats *self, uint8_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_get_snapshot_bytes(const R4SdkSubsystemAsyncStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,6u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_set_snapshot_bytes(R4SdkSubsystemAsyncStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_get_written_bytes(const R4SdkSubsystemAsyncStats *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,7u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_set_written_bytes(R4SdkSubsystemAsyncStats *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,144u,7u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStats_inspectNative(const R4SdkSubsystemAsyncStats *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,144u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_create(R4SdkSubsystemAsyncStore *output, const R4SdkDataAllocator * p0, const R4SdkSubsystemStore * p1) {
 R4SdkSubsystemSlot a[7]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[3].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[4].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[6].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,145u,a,7u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_from_fields(R4SdkSubsystemAsyncStore *output, const R4SdkDataAllocator * p0, const R4SdkSubsystemStore * p1, R4SdkSubsystemSlot p2, const R4SdkSubsystemNativeValue154 * p3, uint64_t p4, R4SdkSubsystemSlot p5, const R4SdkSubsystemAsyncStats * p6) {
 R4SdkSubsystemSlot a[7]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = p2;
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = p5;
 a[6] = (R4SdkSubsystemSlot){.ptr=(void *)p6,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,145u,a,7u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_get_allocator(const R4SdkSubsystemAsyncStore *self, R4SdkDataAllocator *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_set_allocator(R4SdkSubsystemAsyncStore *self, const R4SdkDataAllocator * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_get_store(const R4SdkSubsystemAsyncStore *self, R4SdkSubsystemStore *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_set_store(R4SdkSubsystemAsyncStore *self, const R4SdkSubsystemStore * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_get_active(const R4SdkSubsystemAsyncStore *self, R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,2u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_set_active(R4SdkSubsystemAsyncStore *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_get_pending(const R4SdkSubsystemAsyncStore *self, R4SdkSubsystemNativeValue154 *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,3u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_set_pending(R4SdkSubsystemAsyncStore *self, const R4SdkSubsystemNativeValue154 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_get_next_sequence(const R4SdkSubsystemAsyncStore *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_set_next_sequence(R4SdkSubsystemAsyncStore *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_get_latched_failure(const R4SdkSubsystemAsyncStore *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_set_latched_failure(R4SdkSubsystemAsyncStore *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_get_stats(const R4SdkSubsystemAsyncStore *self, R4SdkSubsystemAsyncStats *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,6u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_set_stats(R4SdkSubsystemAsyncStore *self, const R4SdkSubsystemAsyncStats * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,145u,6u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemAsyncStore_inspectNative(const R4SdkSubsystemAsyncStore *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,145u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue147_create(R4SdkSubsystemNativeValue147 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,147u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue147_inspectNative(const R4SdkSubsystemNativeValue147 *self, R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,147u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite_create(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite *output, R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob * p0, const R4ProgramJoinHandle * p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,148u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite_from_fields(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite *output, R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob * p0, const R4ProgramJoinHandle * p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,148u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite_get_job(const R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,148u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite_set_job(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite *self, R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,148u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite_get_handle(const R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite *self, R4ProgramJoinHandle *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,148u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite_set_handle(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite *self, const R4ProgramJoinHandle * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,148u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite_inspectNative(const R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__ActiveWrite *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,148u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue149_create(R4SdkSubsystemNativeValue149 *output, R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,149u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue149_inspectNative(const R4SdkSubsystemNativeValue149 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,149u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_create(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *output, R4SdkSubsystemStore * p0, const R4SdkDataNative_Value158 * p1, uint32_t p2, uint8_t * p3, uintptr_t n3, uint64_t p4) {
 R4SdkSubsystemSlot a[6]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,150u,a,6u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_from_fields(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *output, R4SdkSubsystemStore * p0, const R4SdkDataNative_Value158 * p1, uint32_t p2, uint8_t * p3, uintptr_t n3, uint64_t p4, uint32_t p5) {
 R4SdkSubsystemSlot a[6]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[5] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,150u,a,6u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_get_store(const R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,150u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_set_store(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self, R4SdkSubsystemStore * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,150u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_get_digest(const R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self, R4SdkDataNative_Value158 *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,150u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_set_digest(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self, const R4SdkDataNative_Value158 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,150u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_get_kind(const R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,150u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_set_kind(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,150u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_get_bytes(const R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,150u,3u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_set_bytes(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self, uint8_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,150u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_get_sequence(const R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,150u,4u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_set_sequence(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,150u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_get_result(const R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,150u,5u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_set_result(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,150u,5u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob_inspectNative(const R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteJob *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,150u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue151_create(R4SdkSubsystemNativeValue151 *output, R4SdkSubsystemStore * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,151u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue151_inspectNative(const R4SdkSubsystemNativeValue151 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,151u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult_create(R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,152u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult_inspectNative(const R4SdkSubsystemPersistenceR4osStore_subsystem_persistence_Configuration__AsyncWriteResult *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,152u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue154_create(R4SdkSubsystemNativeValue154 *output, const R4SdkSubsystemNativeValue154 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,154u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue154_inspectNative(const R4SdkSubsystemNativeValue154 *self, R4SdkSubsystemNativeValue154 *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,154u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue155_create(R4SdkSubsystemNativeValue155 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,155u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue155_inspectNative(const R4SdkSubsystemNativeValue155 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,155u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue156_create(R4SdkSubsystemNativeValue156 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,156u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue156_inspectNative(const R4SdkSubsystemNativeValue156 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,156u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue157_inspectNative(const R4SdkSubsystemNativeValue157 *self, R4SdkSubsystemNative_path_AbsoluteFilePath *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,157u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_AbsoluteFilePath_create(R4SdkSubsystemNative_path_AbsoluteFilePath *output) {
 R4SdkSubsystemSlot a[2]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,158u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_AbsoluteFilePath_from_fields(R4SdkSubsystemNative_path_AbsoluteFilePath *output, const R4SdkUpdateNativeValue154 * p0, uint16_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,158u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_AbsoluteFilePath_get_storage(const R4SdkSubsystemNative_path_AbsoluteFilePath *self, R4SdkUpdateNativeValue154 *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,158u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_AbsoluteFilePath_set_storage(R4SdkSubsystemNative_path_AbsoluteFilePath *self, const R4SdkUpdateNativeValue154 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,158u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_AbsoluteFilePath_get_len(const R4SdkSubsystemNative_path_AbsoluteFilePath *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,158u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_AbsoluteFilePath_set_len(R4SdkSubsystemNative_path_AbsoluteFilePath *self, uint16_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,158u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_AbsoluteFilePath_inspectNative(const R4SdkSubsystemNative_path_AbsoluteFilePath *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,158u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCallbackKind_create(R4SdkSubsystemCallbackKind *output, uint32_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,162u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCallbackKind_inspectNative(const R4SdkSubsystemCallbackKind *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,162u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCallbackTable_create(R4SdkSubsystemCallbackTable *output) {
 R4SdkSubsystemSlot a[3]={0};
 a[0].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[1].flags=R4SDKSUBSYSTEM_DEFAULT;
 a[2].flags=R4SDKSUBSYSTEM_DEFAULT;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,163u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCallbackTable_from_fields(R4SdkSubsystemCallbackTable *output, R4SdkSubsystemSlot p0, uint64_t p1, R4SdkSubsystemSlot p2) {
 R4SdkSubsystemSlot a[3]={0};
 a[0] = p0;
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = p2;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,163u,a,3u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemCallbackTable_get_user(const R4SdkSubsystemCallbackTable *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,163u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCallbackTable_set_user(R4SdkSubsystemCallbackTable *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,163u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCallbackTable_get_mask(const R4SdkSubsystemCallbackTable *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,163u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCallbackTable_set_mask(R4SdkSubsystemCallbackTable *self, uint64_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,163u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCallbackTable_get_invoke(const R4SdkSubsystemCallbackTable *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,163u,2u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCallbackTable_set_invoke(R4SdkSubsystemCallbackTable *self, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,163u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemCallbackTable_inspectNative(const R4SdkSubsystemCallbackTable *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,163u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue165_create(R4SdkSubsystemNativeValue165 *output, const R4SdkSubsystemCallbackTable * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,165u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue165_inspectNative(const R4SdkSubsystemNativeValue165 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,165u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue166_inspectNative(const R4SdkSubsystemNativeValue166 *self, R4SdkSubsystemCatalogHostVerifier *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,166u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue167_inspectNative(const R4SdkSubsystemNativeValue167 *self, R4SdkSubsystemVideoBackend *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,167u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue168_inspectNative(const R4SdkSubsystemNativeValue168 *self, R4SdkSubsystemVideoFrameOverlay *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,168u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue169_inspectNative(const R4SdkSubsystemNativeValue169 *self, R4SdkSubsystemRuntimeGuestDriver *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,169u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue170_inspectNative(const R4SdkSubsystemNativeValue170 *self, R4SdkSubsystemRuntimeHostDriver *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,170u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue171_inspectNative(const R4SdkSubsystemNativeValue171 *self, R4SdkSubsystemRuntimeAudioSink *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,171u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue172_inspectNative(const R4SdkSubsystemNativeValue172 *self, R4SdkSubsystemPersistenceBackend *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,172u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue173_inspectNative(const R4SdkSubsystemNativeValue173 *self, R4SdkSubsystemPersistenceConfiguration *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,173u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_create(R4SdkSubsystemContext *output, const R4SdkSubsystemNative_program_Bundle * p0, const R4SdkSubsystemNative_r4sys_Context * p1, const R4SdkSubsystemNative_r4desk_Context * p2, const R4SdkSubsystemNative_r4draw_Context * p3, const R4SdkSubsystemNative_r4audio_Context * p4) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,174u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_from_fields(R4SdkSubsystemContext *output, const R4SdkSubsystemNative_program_Bundle * p0, const R4SdkSubsystemNative_r4sys_Context * p1, const R4SdkSubsystemNative_r4desk_Context * p2, const R4SdkSubsystemNative_r4draw_Context * p3, const R4SdkSubsystemNative_r4audio_Context * p4) {
 R4SdkSubsystemSlot a[5]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.ptr=(void *)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[2] = (R4SdkSubsystemSlot){.ptr=(void *)p2,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[3] = (R4SdkSubsystemSlot){.ptr=(void *)p3,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[4] = (R4SdkSubsystemSlot){.ptr=(void *)p4,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,174u,a,5u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_get_bundle(const R4SdkSubsystemContext *self, R4SdkSubsystemNative_program_Bundle *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,174u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_set_bundle(R4SdkSubsystemContext *self, const R4SdkSubsystemNative_program_Bundle * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,174u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_get_sys(const R4SdkSubsystemContext *self, R4SdkSubsystemNative_r4sys_Context *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,174u,1u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_set_sys(R4SdkSubsystemContext *self, const R4SdkSubsystemNative_r4sys_Context * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,174u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_get_desk(const R4SdkSubsystemContext *self, R4SdkSubsystemNative_r4desk_Context *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,174u,2u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_set_desk(R4SdkSubsystemContext *self, const R4SdkSubsystemNative_r4desk_Context * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,174u,2u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_get_draw(const R4SdkSubsystemContext *self, R4SdkSubsystemNative_r4draw_Context *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,174u,3u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_set_draw(R4SdkSubsystemContext *self, const R4SdkSubsystemNative_r4draw_Context * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,174u,3u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_get_audio(const R4SdkSubsystemContext *self, R4SdkSubsystemNative_r4audio_Context *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,174u,4u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_set_audio(R4SdkSubsystemContext *self, const R4SdkSubsystemNative_r4audio_Context * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,174u,4u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemContext_inspectNative(const R4SdkSubsystemContext *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,174u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_create(R4SdkSubsystemNative_r4audio_Context *output, const R4SdkSubsystemNative_program_Context * p0) {
 R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,177u,a,1u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_from_fields(R4SdkSubsystemNative_r4audio_Context *output, const R4SdkSubsystemNative_program_Context * p0) {
 R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,177u,a,1u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_get_base(const R4SdkSubsystemNative_r4audio_Context *self, R4SdkSubsystemNative_program_Context *output) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,177u,0u,(void *)self,0,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_set_base(R4SdkSubsystemNative_r4audio_Context *self, const R4SdkSubsystemNative_program_Context * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,177u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_r4audio_Context_inspectNative(const R4SdkSubsystemNative_r4audio_Context *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,177u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue179_create(R4SdkSubsystemNativeValue179 *output, R4SdkSubsystemContext * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,179u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue179_inspectNative(const R4SdkSubsystemNativeValue179 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,179u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue180_create(R4SdkSubsystemNativeValue180 *output, const R4XStartContext * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,180u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue180_inspectNative(const R4SdkSubsystemNativeValue180 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,180u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue182_create(R4SdkSubsystemNativeValue182 *output, R4SdkSubsystemVideoHost * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,182u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue182_inspectNative(const R4SdkSubsystemNativeValue182 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,182u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue183_create(R4SdkSubsystemNativeValue183 *output, const R4SdkSubsystemContext * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,183u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue183_inspectNative(const R4SdkSubsystemNativeValue183 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,183u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue184_inspectNative(const R4SdkSubsystemNativeValue184 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,184u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue185_create(R4SdkSubsystemNativeValue185 *output, R4SdkSubsystemRuntimeR4AudioSink * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,185u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue185_inspectNative(const R4SdkSubsystemNativeValue185 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,185u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue186_create(R4SdkSubsystemNativeValue186 *output, R4SdkSubsystemRuntimeRuntime * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,186u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue186_inspectNative(const R4SdkSubsystemNativeValue186 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,186u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue187_create(R4SdkSubsystemNativeValue187 *output, const uint32_t * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,187u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue187_inspectNative(const R4SdkSubsystemNativeValue187 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,187u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue188_inspectNative(const R4SdkSubsystemNativeValue188 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,188u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue190_create(R4SdkSubsystemNativeValue190 *output, R4SdkSubsystemCatalogCatalog * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,190u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue190_inspectNative(const R4SdkSubsystemNativeValue190 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,190u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue191_inspectNative(const R4SdkSubsystemNativeValue191 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,191u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue193_create(R4SdkSubsystemNativeValue193 *output, const R4SdkSubsystemCatalogResolution * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,193u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue193_inspectNative(const R4SdkSubsystemNativeValue193 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,193u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue194_create(R4SdkSubsystemNativeValue194 *output, const R4SdkSubsystemCatalogCandidate * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,194u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue194_inspectNative(const R4SdkSubsystemNativeValue194 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,194u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue195_create(R4SdkSubsystemNativeValue195 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,195u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue195_inspectNative(const R4SdkSubsystemNativeValue195 *self, R4SdkSubsystemCatalogCandidate *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,195u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue196_inspectNative(const R4SdkSubsystemNativeValue196 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,196u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue197_create(R4SdkSubsystemNativeValue197 *output, R4SdkSubsystemLaunchOptionIterator * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,197u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue197_inspectNative(const R4SdkSubsystemNativeValue197 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,197u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue198_inspectNative(const R4SdkSubsystemNativeValue198 *self, R4SdkSubsystemLaunchOption *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,198u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue199_create(R4SdkSubsystemNativeValue199 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,199u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue199_inspectNative(const R4SdkSubsystemNativeValue199 *self, R4SdkSubsystemLaunchOption *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,199u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue200_inspectNative(const R4SdkSubsystemNativeValue200 *self, R4SdkSubsystemVideoSurface *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,200u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue201_create(R4SdkSubsystemNativeValue201 *output, R4SdkSubsystemVideoSurface * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,201u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue201_inspectNative(const R4SdkSubsystemNativeValue201 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,201u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue202_create(R4SdkSubsystemNativeValue202 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,202u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue202_inspectNative(const R4SdkSubsystemNativeValue202 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,202u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue203_create(R4SdkSubsystemNativeValue203 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,203u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue203_inspectNative(const R4SdkSubsystemNativeValue203 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,203u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue204_create(R4SdkSubsystemNativeValue204 *output, const R4SdkSubsystemNative_r4draw_Context * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,204u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue204_inspectNative(const R4SdkSubsystemNativeValue204 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,204u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue205_inspectNative(const R4SdkSubsystemNativeValue205 *self, R4SdkSubsystemVideoPresenter *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,205u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue206_create(R4SdkSubsystemNativeValue206 *output, R4SdkSubsystemVideoPresenter * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,206u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue206_inspectNative(const R4SdkSubsystemNativeValue206 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,206u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue207_create(R4SdkSubsystemNativeValue207 *output, const R4SdkSubsystemVideoPresenter * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,207u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue207_inspectNative(const R4SdkSubsystemNativeValue207 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,207u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue208_create(R4SdkSubsystemNativeValue208 *output, R4SdkSubsystemVideoInputTranslator * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,208u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue208_inspectNative(const R4SdkSubsystemNativeValue208 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,208u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue209_create(R4SdkSubsystemNativeValue209 *output, const R4SdkSubsystemVideoInputTranslator * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,209u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue209_inspectNative(const R4SdkSubsystemNativeValue209 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,209u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue210_create(R4SdkSubsystemNativeValue210 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,210u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue210_inspectNative(const R4SdkSubsystemNativeValue210 *self, R4SdkSubsystemVideoInputEvent *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,210u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue212_create(R4SdkSubsystemNativeValue212 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,212u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue212_inspectNative(const R4SdkSubsystemNativeValue212 *self, R4SdkSubsystemVideoSize *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,212u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue213_inspectNative(const R4SdkSubsystemNativeValue213 *self, R4SdkSubsystemVideoHost *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,213u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue215_create(R4SdkSubsystemNativeValue215 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,215u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue215_inspectNative(const R4SdkSubsystemNativeValue215 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,215u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue216_create(R4SdkSubsystemNativeValue216 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,216u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue216_inspectNative(const R4SdkSubsystemNativeValue216 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,216u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue217_inspectNative(const R4SdkSubsystemNativeValue217 *self, R4SdkSubsystemRuntimeGuestClock *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,217u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue218_create(R4SdkSubsystemNativeValue218 *output, R4SdkSubsystemRuntimeGuestClock * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,218u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue218_inspectNative(const R4SdkSubsystemNativeValue218 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,218u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue219_create(R4SdkSubsystemNativeValue219 *output, const R4SdkSubsystemRuntimeGuestClock * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,219u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue219_inspectNative(const R4SdkSubsystemNativeValue219 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,219u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue220_inspectNative(const R4SdkSubsystemNativeValue220 *self, R4SdkSubsystemRuntimePacer *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,220u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue221_create(R4SdkSubsystemNativeValue221 *output, R4SdkSubsystemRuntimePacer * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,221u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue221_inspectNative(const R4SdkSubsystemNativeValue221 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,221u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue222_create(R4SdkSubsystemNativeValue222 *output, const R4SdkSubsystemRuntimePacer * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,222u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue222_inspectNative(const R4SdkSubsystemNativeValue222 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,222u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue223_inspectNative(const R4SdkSubsystemNativeValue223 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,223u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue224_inspectNative(const R4SdkSubsystemNativeValue224 *self, R4SdkSubsystemRuntimePcmQueue *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,224u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue225_create(R4SdkSubsystemNativeValue225 *output, const R4SdkSubsystemRuntimePcmQueue * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,225u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue225_inspectNative(const R4SdkSubsystemNativeValue225 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,225u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue226_create(R4SdkSubsystemNativeValue226 *output, R4SdkSubsystemRuntimePcmQueue * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,226u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue226_inspectNative(const R4SdkSubsystemNativeValue226 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,226u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue227_create(R4SdkSubsystemNativeValue227 *output, R4SdkSubsystemSlot p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = p0;
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,227u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue227_inspectNative(const R4SdkSubsystemNativeValue227 *self, R4SdkSubsystemRuntimeAudioOptions *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,227u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue228_inspectNative(const R4SdkSubsystemNativeValue228 *self, R4SdkSubsystemRuntimeRuntime *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,228u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue229_create(R4SdkSubsystemNativeValue229 *output, const R4SdkSubsystemNative_r4sys_Context * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,229u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue229_inspectNative(const R4SdkSubsystemNativeValue229 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,229u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue230_create(R4SdkSubsystemNativeValue230 *output, const R4SdkSubsystemStore * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,230u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue230_inspectNative(const R4SdkSubsystemNativeValue230 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,230u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue231_inspectNative(const R4SdkSubsystemNativeValue231 *self, R4SdkSubsystemRecoveryTestState *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,231u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue232_create(R4SdkSubsystemNativeValue232 *output, R4SdkSubsystemAsyncStore * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,232u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue232_inspectNative(const R4SdkSubsystemNativeValue232 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,232u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue233_create(R4SdkSubsystemNativeValue233 *output, const R4SdkSubsystemAsyncStore * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,233u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue233_inspectNative(const R4SdkSubsystemNativeValue233 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,233u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue234_inspectNative(const R4SdkSubsystemNativeValue234 *self, R4SdkSubsystemNative_path_AbsoluteFilePath *output) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,234u,(void *)self,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue235_create(R4SdkSubsystemNativeValue235 *output, const R4SdkSubsystemNative_path_AbsoluteFilePath * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,235u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue235_inspectNative(const R4SdkSubsystemNativeValue235 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,235u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_PathZ_create(R4SdkSubsystemNative_path_PathZ *output, const uint8_t * p0, uint16_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,236u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_PathZ_from_fields(R4SdkSubsystemNative_path_PathZ *output, const uint8_t * p0, uint16_t p1) {
 R4SdkSubsystemSlot a[2]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 a[1] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,236u,a,2u,output);
}
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_PathZ_get_ptr(const R4SdkSubsystemNative_path_PathZ *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,236u,0u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_PathZ_set_ptr(R4SdkSubsystemNative_path_PathZ *self, const uint8_t * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,236u,0u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_PathZ_get_len(const R4SdkSubsystemNative_path_PathZ *self) { return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,236u,1u,(void *)self,0,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_PathZ_set_len(R4SdkSubsystemNative_path_PathZ *self, uint16_t p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemField(R4SdkSubsystem_ABI_FINGERPRINT,236u,1u,self,a,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNative_path_PathZ_inspectNative(const R4SdkSubsystemNative_path_PathZ *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,236u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue237_create(R4SdkSubsystemNativeValue237 *output, const R4SdkSubsystemNative_program_Bundle * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,237u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue237_inspectNative(const R4SdkSubsystemNativeValue237 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,237u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue238_create(R4SdkSubsystemNativeValue238 *output, const R4SdkSubsystemNative_r4audio_Context * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,238u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue238_inspectNative(const R4SdkSubsystemNativeValue238 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,238u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue240_create(R4SdkSubsystemNativeValue240 *output, R4AudioOutputInfo * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,240u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue240_inspectNative(const R4SdkSubsystemNativeValue240 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,240u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue242_create(R4SdkSubsystemNativeValue242 *output, R4AudioOutputInfo * p0, uintptr_t n0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,242u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue242_inspectNative(const R4SdkSubsystemNativeValue242 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,242u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue243_create(R4SdkSubsystemNativeValue243 *output, R4AudioOutputCatalog * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,243u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue243_inspectNative(const R4SdkSubsystemNativeValue243 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,243u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue245_create(R4SdkSubsystemNativeValue245 *output, const R4SdkSubsystemNativeValue131 * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,245u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue245_inspectNative(const R4SdkSubsystemNativeValue245 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,245u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue246_create(R4SdkSubsystemNativeValue246 *output, R4AudioStreamProgress * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,246u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue246_inspectNative(const R4SdkSubsystemNativeValue246 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,246u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue248_create(R4SdkSubsystemNativeValue248 *output, const R4AudioStreamExpectation * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,248u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue248_inspectNative(const R4SdkSubsystemNativeValue248 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,248u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue250_create(R4SdkSubsystemNativeValue250 *output, R4AudioServiceStatus * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,250u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue250_inspectNative(const R4SdkSubsystemNativeValue250 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,250u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue252_create(R4SdkSubsystemNativeValue252 *output, R4AudioServiceMasterState * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,252u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue252_inspectNative(const R4SdkSubsystemNativeValue252 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,252u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue254_create(R4SdkSubsystemNativeValue254 *output, const R4AudioServiceMasterRequest * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,254u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue254_inspectNative(const R4SdkSubsystemNativeValue254 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,254u,(void *)self,0); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue256_create(R4SdkSubsystemNativeValue256 *output, R4AudioServiceStreamResult * p0) { R4SdkSubsystemSlot a[1]={0};
 a[0] = (R4SdkSubsystemSlot){.ptr=(void *)p0,.flags=R4SDKSUBSYSTEM_PRESENT};
 return R4SdkSubsystemConstruct(R4SdkSubsystem_ABI_FINGERPRINT,256u,a,1u,output); }
static inline R4SdkSubsystemSlot R4SdkSubsystemNativeValue256_inspectNative(const R4SdkSubsystemNativeValue256 *self) { return R4SdkSubsystemInspect(R4SdkSubsystem_ABI_FINGERPRINT,256u,(void *)self,0); }
#endif
