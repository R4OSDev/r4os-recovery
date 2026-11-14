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
#ifndef R4SDKDRIVER_HELPERS_H
#define R4SDKDRIVER_HELPERS_H
#include "r4os/abi.h"
#include "r4os/generation2.h"
#define R4SDKDRIVER_PRESENT 1u
#define R4SDKDRIVER_NATIVE_ERROR 2u
#define R4SDKDRIVER_DEFAULT 4u
typedef struct R4SdkDriverSlot { void *ptr; uint64_t length,bits; int32_t status; uint32_t flags; } R4SdkDriverSlot;
R4SdkDriverSlot R4SdkDriverInvoke(uint64_t,uint32_t,const R4SdkDriverSlot *,uint32_t,void *);
R4SdkDriverSlot R4SdkDriverConstruct(uint64_t,uint32_t,const R4SdkDriverSlot *,uint32_t,void *);
R4SdkDriverSlot R4SdkDriverInspect(uint64_t,uint32_t,void *,void *);
R4SdkDriverSlot R4SdkDriverField(uint64_t,uint32_t,uint32_t,void *,const R4SdkDriverSlot *,void *);
/* driver.SharedDmaBuffer; native size 40, alignment 8. */
typedef struct R4SdkDriverSharedDmaBuffer { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkDriverSharedDmaBuffer;
#define R4SdkDriverSharedDmaBuffer_TYPE 0u
/* driver2.Context; native size 8, alignment 8. */
typedef struct R4SdkDriver2Context { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriver2Context;
#define R4SdkDriver2Context_TYPE 2u
/* *const technical2_generated.DriverApi2; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue3 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue3;
#define R4SdkDriverNativeValue3_TYPE 3u
/* driver_serial.Context; native size 40, alignment 8. */
typedef struct R4SdkDriverSerialContext { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkDriverSerialContext;
#define R4SdkDriverSerialContext_TYPE 5u
/* driver_memory.Context; native size 256, alignment 8. */
typedef struct R4SdkDriverMemoryContext { _Alignas(8) uint8_t opaque_bytes[256]; } R4SdkDriverMemoryContext;
#define R4SdkDriverMemoryContext_TYPE 7u
/* driver_entropy.Context; native size 32, alignment 8. */
typedef struct R4SdkDriverEntropyContext { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkDriverEntropyContext;
#define R4SdkDriverEntropyContext_TYPE 9u
/* driver_resources.Context; native size 72, alignment 8. */
typedef struct R4SdkDriverResourcesContext { _Alignas(8) uint8_t opaque_bytes[72]; } R4SdkDriverResourcesContext;
#define R4SdkDriverResourcesContext_TYPE 11u
/* driver_resources.Platform; native size 32, alignment 8. */
typedef struct R4SdkDriverResourcesPlatform { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkDriverResourcesPlatform;
#define R4SdkDriverResourcesPlatform_TYPE 13u
/* driver_queue.Context; native size 168, alignment 8. */
typedef struct R4SdkDriverQueueContext { _Alignas(8) uint8_t opaque_bytes[168]; } R4SdkDriverQueueContext;
#define R4SdkDriverQueueContext_TYPE 15u
/* driver_outputs.Context; native size 176, alignment 8. */
typedef struct R4SdkDriverOutputsContext { _Alignas(8) uint8_t opaque_bytes[176]; } R4SdkDriverOutputsContext;
#define R4SdkDriverOutputsContext_TYPE 17u
/* driver_display.Context; native size 152, alignment 8. */
typedef struct R4SdkDriverDisplayContext { _Alignas(8) uint8_t opaque_bytes[152]; } R4SdkDriverDisplayContext;
#define R4SdkDriverDisplayContext_TYPE 19u
/* driver_heap.Context; native size 32, alignment 8. */
typedef struct R4SdkDriverHeapContext { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkDriverHeapContext;
#define R4SdkDriverHeapContext_TYPE 21u
/* driver_threads.Context; native size 88, alignment 8. */
typedef struct R4SdkDriverThreadsContext { _Alignas(8) uint8_t opaque_bytes[88]; } R4SdkDriverThreadsContext;
#define R4SdkDriverThreadsContext_TYPE 23u
/* driver_semaphores.Context; native size 64, alignment 8. */
typedef struct R4SdkDriverSemaphoresContext { _Alignas(8) uint8_t opaque_bytes[64]; } R4SdkDriverSemaphoresContext;
#define R4SdkDriverSemaphoresContext_TYPE 25u
/* driver_cpu_power.Context; native size 184, alignment 8. */
typedef struct R4SdkDriverCpuPowerContext { _Alignas(8) uint8_t opaque_bytes[184]; } R4SdkDriverCpuPowerContext;
#define R4SdkDriverCpuPowerContext_TYPE 27u
/* *const driver2.Context; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue29 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue29;
#define R4SdkDriverNativeValue29_TYPE 29u
/* ?*driver.SharedDmaBuffer; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue30 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue30;
#define R4SdkDriverNativeValue30_TYPE 30u
/* *driver.SharedDmaBuffer; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue31 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue31;
#define R4SdkDriverNativeValue31_TYPE 31u
/* *const driver.SharedDmaBuffer; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue32 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue32;
#define R4SdkDriverNativeValue32_TYPE 32u
/* *const technical2_generated.AudioBackend2; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue35 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue35;
#define R4SdkDriverNativeValue35_TYPE 35u
/* *const abi.SynthEngine; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue37 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue37;
#define R4SdkDriverNativeValue37_TYPE 37u
/* *const abi.DriverWorkRequest; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue39 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue39;
#define R4SdkDriverNativeValue39_TYPE 39u
/* *u32; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue41 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue41;
#define R4SdkDriverNativeValue41_TYPE 41u
/* ?driver_outputs.Context; native size 184, alignment 8. */
typedef struct R4SdkDriverNativeValue42 { _Alignas(8) uint8_t opaque_bytes[184]; } R4SdkDriverNativeValue42;
#define R4SdkDriverNativeValue42_TYPE 42u
/* ?driver_display.Context; native size 160, alignment 8. */
typedef struct R4SdkDriverNativeValue43 { _Alignas(8) uint8_t opaque_bytes[160]; } R4SdkDriverNativeValue43;
#define R4SdkDriverNativeValue43_TYPE 43u
/* ?driver_queue.Context; native size 176, alignment 8. */
typedef struct R4SdkDriverNativeValue44 { _Alignas(8) uint8_t opaque_bytes[176]; } R4SdkDriverNativeValue44;
#define R4SdkDriverNativeValue44_TYPE 44u
/* *const abi.DisplayBlitBackend; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue45 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue45;
#define R4SdkDriverNativeValue45_TYPE 45u
/* *const abi.UsbHostController; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue47 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue47;
#define R4SdkDriverNativeValue47_TYPE 47u
/* *const abi.DmaMapping; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue49 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue49;
#define R4SdkDriverNativeValue49_TYPE 49u
/* *abi.IrqStats; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue51 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue51;
#define R4SdkDriverNativeValue51_TYPE 51u
/* *abi.DriverWorkSummary; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue53 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue53;
#define R4SdkDriverNativeValue53_TYPE 53u
/* *abi_generated.MonotonicClockInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue55 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue55;
#define R4SdkDriverNativeValue55_TYPE 55u
/* ?driver_heap.Context; native size 40, alignment 8. */
typedef struct R4SdkDriverNativeValue57 { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkDriverNativeValue57;
#define R4SdkDriverNativeValue57_TYPE 57u
/* ?driver_resources.Context; native size 80, alignment 8. */
typedef struct R4SdkDriverNativeValue58 { _Alignas(8) uint8_t opaque_bytes[80]; } R4SdkDriverNativeValue58;
#define R4SdkDriverNativeValue58_TYPE 58u
/* ?driver_threads.Context; native size 96, alignment 8. */
typedef struct R4SdkDriverNativeValue59 { _Alignas(8) uint8_t opaque_bytes[96]; } R4SdkDriverNativeValue59;
#define R4SdkDriverNativeValue59_TYPE 59u
/* ?driver_semaphores.Context; native size 72, alignment 8. */
typedef struct R4SdkDriverNativeValue60 { _Alignas(8) uint8_t opaque_bytes[72]; } R4SdkDriverNativeValue60;
#define R4SdkDriverNativeValue60_TYPE 60u
/* ?driver_serial.Context; native size 48, alignment 8. */
typedef struct R4SdkDriverNativeValue61 { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkDriverNativeValue61;
#define R4SdkDriverNativeValue61_TYPE 61u
/* ?driver_memory.Context; native size 264, alignment 8. */
typedef struct R4SdkDriverNativeValue62 { _Alignas(8) uint8_t opaque_bytes[264]; } R4SdkDriverNativeValue62;
#define R4SdkDriverNativeValue62_TYPE 62u
/* *const abi.NetBackend; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue63 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue63;
#define R4SdkDriverNativeValue63_TYPE 63u
/* *abi.NetBackendNegotiation; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue66 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue66;
#define R4SdkDriverNativeValue66_TYPE 66u
/* *const abi.NetPacket; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue68 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue68;
#define R4SdkDriverNativeValue68_TYPE 68u
/* *abi.PciDeviceInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue70 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue70;
#define R4SdkDriverNativeValue70_TYPE 70u
/* *abi.DmaBuffer; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue72 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue72;
#define R4SdkDriverNativeValue72_TYPE 72u
/* *abi.DriverCompletionStatus; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue73 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue73;
#define R4SdkDriverNativeValue73_TYPE 73u
/* *i32; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue75 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue75;
#define R4SdkDriverNativeValue75_TYPE 75u
/* *const abi.DmaPinnedBuffer; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue76 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue76;
#define R4SdkDriverNativeValue76_TYPE 76u
/* *const abi.DmaConstraints; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue78 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue78;
#define R4SdkDriverNativeValue78_TYPE 78u
/* *abi.DmaMapping; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue80 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue80;
#define R4SdkDriverNativeValue80_TYPE 80u
/* *abi.MmioRegion; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue81 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue81;
#define R4SdkDriverNativeValue81_TYPE 81u
/* *abi.DmaPinnedBuffer; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue83 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue83;
#define R4SdkDriverNativeValue83_TYPE 83u
/* *const abi.StorageBackend; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue84 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue84;
#define R4SdkDriverNativeValue84_TYPE 84u
/* *const driver_serial.Context; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue86 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue86;
#define R4SdkDriverNativeValue86_TYPE 86u
/* *const abi_generated.SerialBackend; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue87 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue87;
#define R4SdkDriverNativeValue87_TYPE 87u
/* *u64; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue89 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue89;
#define R4SdkDriverNativeValue89_TYPE 89u
/* *const driver_memory.Context; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue90 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue90;
#define R4SdkDriverNativeValue90_TYPE 90u
/* *const abi_generated.GfxTelemetryState; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue91 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue91;
#define R4SdkDriverNativeValue91_TYPE 91u
/* *abi_generated.GfxTelemetryDemand; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue93 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue93;
#define R4SdkDriverNativeValue93_TYPE 93u
/* *const abi_generated.GfxDeviceBudgetRequest; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue95 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue95;
#define R4SdkDriverNativeValue95_TYPE 95u
/* *abi_generated.GfxDeviceBudgetState; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue97 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue97;
#define R4SdkDriverNativeValue97_TYPE 97u
/* *const abi_generated.GfxNativeProvider; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue99 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue99;
#define R4SdkDriverNativeValue99_TYPE 99u
/* *abi_generated.GfxBufferHandle; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue101 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue101;
#define R4SdkDriverNativeValue101_TYPE 101u
/* *const abi_generated.GfxBufferHandle; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue103 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue103;
#define R4SdkDriverNativeValue103_TYPE 103u
/* *abi_generated.GfxVirtualJob; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue104 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue104;
#define R4SdkDriverNativeValue104_TYPE 104u
/* *const abi_generated.GfxVirtualCompletion; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue106 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue106;
#define R4SdkDriverNativeValue106_TYPE 106u
/* *abi_generated.GfxNativeJob; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue108 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue108;
#define R4SdkDriverNativeValue108_TYPE 108u
/* *const abi_generated.GfxBufferDescriptor; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue110 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue110;
#define R4SdkDriverNativeValue110_TYPE 110u
/* *abi_generated.GfxBufferReference; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue112 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue112;
#define R4SdkDriverNativeValue112_TYPE 112u
/* *abi_generated.GfxBufferDescriptor; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue114 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue114;
#define R4SdkDriverNativeValue114_TYPE 114u
/* *abi_generated.GfxBufferMap; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue115 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue115;
#define R4SdkDriverNativeValue115_TYPE 115u
/* *const abi_generated.GfxDeviceRequest; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue117 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue117;
#define R4SdkDriverNativeValue117_TYPE 117u
/* *abi_generated.GfxDeviceLease; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue119 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue119;
#define R4SdkDriverNativeValue119_TYPE 119u
/* *const abi_generated.GfxDeviceLease; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue121 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue121;
#define R4SdkDriverNativeValue121_TYPE 121u
/* *abi_generated.GfxDmaSegment; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue122 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue122;
#define R4SdkDriverNativeValue122_TYPE 122u
/* *const abi_generated.GfxMmioRequest; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue124 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue124;
#define R4SdkDriverNativeValue124_TYPE 124u
/* *abi_generated.GfxMmioWindow; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue126 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue126;
#define R4SdkDriverNativeValue126_TYPE 126u
/* *abi_generated.GfxBufferStats; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue128 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue128;
#define R4SdkDriverNativeValue128_TYPE 128u
/* *abi_generated.GfxOwnedBufferReservation; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue130 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue130;
#define R4SdkDriverNativeValue130_TYPE 130u
/* *const abi_generated.GfxOwnedBufferReservation; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue132 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue132;
#define R4SdkDriverNativeValue132_TYPE 132u
/* *abi_generated.GfxOwnedBufferRelease; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue133 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue133;
#define R4SdkDriverNativeValue133_TYPE 133u
/* *const abi_generated.GfxOwnedBufferRelease; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue135 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue135;
#define R4SdkDriverNativeValue135_TYPE 135u
/* *const driver_entropy.Context; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue136 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue136;
#define R4SdkDriverNativeValue136_TYPE 136u
/* *const abi_generated.EntropyBackend; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue137 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue137;
#define R4SdkDriverNativeValue137_TYPE 137u
/* *const driver_resources.Context; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue139 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue139;
#define R4SdkDriverNativeValue139_TYPE 139u
/* ?driver_entropy.Context; native size 40, alignment 8. */
typedef struct R4SdkDriverNativeValue140 { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkDriverNativeValue140;
#define R4SdkDriverNativeValue140_TYPE 140u
/* ?driver_cpu_power.Context; native size 192, alignment 8. */
typedef struct R4SdkDriverNativeValue141 { _Alignas(8) uint8_t opaque_bytes[192]; } R4SdkDriverNativeValue141;
#define R4SdkDriverNativeValue141_TYPE 141u
/* ?driver_resources.Platform; native size 40, alignment 8. */
typedef struct R4SdkDriverNativeValue142 { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkDriverNativeValue142;
#define R4SdkDriverNativeValue142_TYPE 142u
/* [4]u8; native size 4, alignment 1. */
typedef struct R4SdkDriverNativeValue143 { _Alignas(1) uint8_t opaque_bytes[4]; } R4SdkDriverNativeValue143;
#define R4SdkDriverNativeValue143_TYPE 143u
/* *abi_generated.DriverFirmwareTableInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue144 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue144;
#define R4SdkDriverNativeValue144_TYPE 144u
/* *abi_generated.DriverResourceInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue146 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue146;
#define R4SdkDriverNativeValue146_TYPE 146u
/* *const driver_resources.Platform; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue148 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue148;
#define R4SdkDriverNativeValue148_TYPE 148u
/* *const driver_queue.Context; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue150 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue150;
#define R4SdkDriverNativeValue150_TYPE 150u
/* *const abi_generated.GfxBackendBinding; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue151 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue151;
#define R4SdkDriverNativeValue151_TYPE 151u
/* *abi_generated.GfxQueueOwnerInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue153 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue153;
#define R4SdkDriverNativeValue153_TYPE 153u
/* *const abi_generated.GfxFence; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue155 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue155;
#define R4SdkDriverNativeValue155_TYPE 155u
/* *abi_generated.GfxRenderColorList; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue157 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue157;
#define R4SdkDriverNativeValue157_TYPE 157u
/* *abi_generated.GfxRenderGridList; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue159 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue159;
#define R4SdkDriverNativeValue159_TYPE 159u
/* *abi_generated.GfxRenderList; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue161 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue161;
#define R4SdkDriverNativeValue161_TYPE 161u
/* *const abi_generated.GfxBackendRegistration; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue163 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue163;
#define R4SdkDriverNativeValue163_TYPE 163u
/* *const abi_generated.GfxBackendProfile; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue165 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue165;
#define R4SdkDriverNativeValue165_TYPE 165u
/* *abi_generated.GfxBackendBinding; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue167 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue167;
#define R4SdkDriverNativeValue167_TYPE 167u
/* *const abi_generated.GfxBackendProperties; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue168 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue168;
#define R4SdkDriverNativeValue168_TYPE 168u
/* *abi_generated.GfxNativeJobInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue170 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue170;
#define R4SdkDriverNativeValue170_TYPE 170u
/* *abi_generated.GfxNativeBinding; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue172 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue172;
#define R4SdkDriverNativeValue172_TYPE 172u
/* *abi_generated.GfxDriverJob; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue174 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue174;
#define R4SdkDriverNativeValue174_TYPE 174u
/* *const driver_outputs.Context; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue176 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue176;
#define R4SdkDriverNativeValue176_TYPE 176u
/* *const abi_generated.GfxOutputPower; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue177 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue177;
#define R4SdkDriverNativeValue177_TYPE 177u
/* *const abi_generated.GfxOutputId; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue179 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue179;
#define R4SdkDriverNativeValue179_TYPE 179u
/* *abi_generated.GfxPowerRequest; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue181 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue181;
#define R4SdkDriverNativeValue181_TYPE 181u
/* *const abi_generated.GfxOutputBrightness; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue183 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue183;
#define R4SdkDriverNativeValue183_TYPE 183u
/* *abi_generated.GfxBrightnessRequest; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue185 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue185;
#define R4SdkDriverNativeValue185_TYPE 185u
/* *const abi_generated.GfxOutputRefresh; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue187 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue187;
#define R4SdkDriverNativeValue187_TYPE 187u
/* *const abi_generated.GfxOutputTarget; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue189 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue189;
#define R4SdkDriverNativeValue189_TYPE 189u
/* *abi_generated.GfxRefreshRequest; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue191 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue191;
#define R4SdkDriverNativeValue191_TYPE 191u
/* *abi_generated.GfxDriverModeColor; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue193 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue193;
#define R4SdkDriverNativeValue193_TYPE 193u
/* *const abi_generated.GfxOutputColorState; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue195 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue195;
#define R4SdkDriverNativeValue195_TYPE 195u
/* *const abi_generated.GfxAtomicState; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue197 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue197;
#define R4SdkDriverNativeValue197_TYPE 197u
/* *abi_generated.GfxModeStatus; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue199 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue199;
#define R4SdkDriverNativeValue199_TYPE 199u
/* *const abi_generated.GfxAudioRoute; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue201 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue201;
#define R4SdkDriverNativeValue201_TYPE 201u
/* *abi_generated.GfxAudioRoute; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue203 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue203;
#define R4SdkDriverNativeValue203_TYPE 203u
/* *abi_generated.GfxDriverModeJob; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue204 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue204;
#define R4SdkDriverNativeValue204_TYPE 204u
/* *const abi_generated.GfxDriverModeCompletion; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue206 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue206;
#define R4SdkDriverNativeValue206_TYPE 206u
/* *abi_generated.GfxReceiverSource; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue208 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue208;
#define R4SdkDriverNativeValue208_TYPE 208u
/* *const abi_generated.GfxReceiverUpdate; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue210 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue210;
#define R4SdkDriverNativeValue210_TYPE 210u
/* *const abi_generated.GfxReceiverSource; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue212 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue212;
#define R4SdkDriverNativeValue212_TYPE 212u
/* *const abi_generated.GfxOutputPublication; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue213 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue213;
#define R4SdkDriverNativeValue213_TYPE 213u
/* *abi_generated.GfxOutputId; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue215 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue215;
#define R4SdkDriverNativeValue215_TYPE 215u
/* *const driver_display.Context; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue216 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue216;
#define R4SdkDriverNativeValue216_TYPE 216u
/* *abi_generated.GfxNativeState; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue217 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue217;
#define R4SdkDriverNativeValue217_TYPE 217u
/* *const abi_generated.GfxNativeRegistration; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue219 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue219;
#define R4SdkDriverNativeValue219_TYPE 219u
/* *const abi_generated.GfxAdditionalOutput; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue221 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue221;
#define R4SdkDriverNativeValue221_TYPE 221u
/* *abi_generated.GfxOutputTarget; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue223 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue223;
#define R4SdkDriverNativeValue223_TYPE 223u
/* *const abi_generated.DisplayCursorInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue224 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue224;
#define R4SdkDriverNativeValue224_TYPE 224u
/* *abi_generated.GfxDriverCursorJob; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue226 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue226;
#define R4SdkDriverNativeValue226_TYPE 226u
/* *const abi_generated.GfxDriverCursorCompletion; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue228 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue228;
#define R4SdkDriverNativeValue228_TYPE 228u
/* *const abi_generated.DisplayPresentationInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue230 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue230;
#define R4SdkDriverNativeValue230_TYPE 230u
/* *const abi_generated.DisplayPresentationStats; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue232 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue232;
#define R4SdkDriverNativeValue232_TYPE 232u
/* *const abi_generated.GfxBootHoldRequest; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue234 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue234;
#define R4SdkDriverNativeValue234_TYPE 234u
/* *abi_generated.GfxNativeBootInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue236 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue236;
#define R4SdkDriverNativeValue236_TYPE 236u
/* *const driver_heap.Context; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue238 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue238;
#define R4SdkDriverNativeValue238_TYPE 238u
/* *abi_generated.DriverHeapAllocation; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue239 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue239;
#define R4SdkDriverNativeValue239_TYPE 239u
/* *abi_generated.DriverHeapStats; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue241 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue241;
#define R4SdkDriverNativeValue241_TYPE 241u
/* *const driver_threads.Context; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue243 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue243;
#define R4SdkDriverNativeValue243_TYPE 243u
/* *abi_generated.DriverThreadStatus; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue244 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue244;
#define R4SdkDriverNativeValue244_TYPE 244u
/* *abi_generated.DriverThreadStats; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue246 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue246;
#define R4SdkDriverNativeValue246_TYPE 246u
/* *abi_generated.DriverThreadRequest; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue248 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue248;
#define R4SdkDriverNativeValue248_TYPE 248u
/* *const driver_semaphores.Context; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue250 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue250;
#define R4SdkDriverNativeValue250_TYPE 250u
/* *abi_generated.DriverSemaphoreStatus; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue251 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue251;
#define R4SdkDriverNativeValue251_TYPE 251u
/* *abi_generated.DriverSemaphoreStats; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue253 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue253;
#define R4SdkDriverNativeValue253_TYPE 253u
/* *const driver_cpu_power.Context; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue255 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue255;
#define R4SdkDriverNativeValue255_TYPE 255u
/* *const abi_generated.CpuIdleDescriptor; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue256 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue256;
#define R4SdkDriverNativeValue256_TYPE 256u
/* *const abi_generated.CpuIdlePolicy; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue258 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue258;
#define R4SdkDriverNativeValue258_TYPE 258u
/* *const abi_generated.CpuFirmwareBackend; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue260 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue260;
#define R4SdkDriverNativeValue260_TYPE 260u
/* *const abi_generated.CpuPerformanceRequest; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue262 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue262;
#define R4SdkDriverNativeValue262_TYPE 262u
/* *abi_generated.CpuFirmwareInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue264 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue264;
#define R4SdkDriverNativeValue264_TYPE 264u
/* *abi_generated.CpuCapabilitiesInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue266 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue266;
#define R4SdkDriverNativeValue266_TYPE 266u
/* *abi_generated.CpuFeatureInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue268 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue268;
#define R4SdkDriverNativeValue268_TYPE 268u
/* *const abi_generated.CpuPerformanceBackend; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue270 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue270;
#define R4SdkDriverNativeValue270_TYPE 270u
/* *abi_generated.CpuRegisterWriteInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue272 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue272;
#define R4SdkDriverNativeValue272_TYPE 272u
/* *const abi_generated.CpuCppcBackend; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue274 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue274;
#define R4SdkDriverNativeValue274_TYPE 274u
/* *const abi_generated.CpuPerformanceHint; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue276 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue276;
#define R4SdkDriverNativeValue276_TYPE 276u
/* *const abi_generated.CpuPowerBackend; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue278 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue278;
#define R4SdkDriverNativeValue278_TYPE 278u
/* *abi_generated.CpuTopologyInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue280 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue280;
#define R4SdkDriverNativeValue280_TYPE 280u
/* *abi_generated.CpuRegisterInfo; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue282 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue282;
#define R4SdkDriverNativeValue282_TYPE 282u
/* *abi_generated.CpuPowerCounters; native size 8, alignment 8. */
typedef struct R4SdkDriverNativeValue284 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDriverNativeValue284;
#define R4SdkDriverNativeValue284_TYPE 284u
#define R4SdkDriver_ABI_FINGERPRINT UINT64_C(8156702727755291414)
int32_t R4SdkDriverVerifyAbi(uint64_t);
#define R4SdkDriver_r4d_shutdown_entry_offset (5)
#include "r4os/update_helpers.h"
/* driver.SharedDmaBuffer.create -> ?*driver.SharedDmaBuffer */
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_create(uint32_t reserved, const R4SdkDriver2Context * p0, uint32_t p1, uint64_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,0u,a,3u,0);
}
/* driver.SharedDmaBuffer.data -> []u8 */
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_data(uint32_t reserved, const R4SdkDriverSharedDmaBuffer * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,1u,a,1u,0);
}
/* driver.SharedDmaBuffer.retain -> void */
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_retain(uint32_t reserved, R4SdkDriverSharedDmaBuffer * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,2u,a,1u,0);
}
/* driver.SharedDmaBuffer.release -> void */
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_release(uint32_t reserved, R4SdkDriverSharedDmaBuffer * p0, const R4SdkDriver2Context * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,3u,a,2u,0);
}
/* driver2.Context.init -> driver2.Context */
static inline R4SdkDriverSlot R4SdkDriver2Context_init(uint32_t reserved, const R4DriverApi2 * p0, R4SdkDriver2Context *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,4u,a,1u,output);
}
/* driver2.Context.apiCompatible -> bool */
static inline R4SdkDriverSlot R4SdkDriver2Context_apiCompatible(uint32_t reserved, const R4SdkDriver2Context * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,5u,a,1u,0);
}
/* driver2.Context.registerAudioOutputBackend -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_registerAudioOutputBackend(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1, const R4AudioBackend2 * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,6u,a,3u,0);
}
/* driver2.Context.registerSynthEngineEx -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_registerSynthEngineEx(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1, const R4SynthEngine * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,7u,a,3u,0);
}
/* driver2.Context.unregisterAudioBackend -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_unregisterAudioBackend(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,8u,a,2u,0);
}
/* driver2.Context.registerAudioOutputEpoch -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_registerAudioOutputEpoch(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1, uintptr_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,9u,a,3u,0);
}
/* driver2.Context.workSubmitRequest -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_workSubmitRequest(uint32_t reserved, const R4SdkDriver2Context * p0, const R4DriverWorkRequest * p1, uint32_t * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,10u,a,3u,0);
}
/* driver2.Context.graphicsOutputs -> ?driver_outputs.Context */
static inline R4SdkDriverSlot R4SdkDriver2Context_graphicsOutputs(uint32_t reserved, const R4SdkDriver2Context * p0, R4SdkDriverOutputsContext *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,11u,a,1u,output);
}
/* driver2.Context.graphicsDisplay -> ?driver_display.Context */
static inline R4SdkDriverSlot R4SdkDriver2Context_graphicsDisplay(uint32_t reserved, const R4SdkDriver2Context * p0, R4SdkDriverDisplayContext *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,12u,a,1u,output);
}
/* driver2.Context.graphicsQueue -> ?driver_queue.Context */
static inline R4SdkDriverSlot R4SdkDriver2Context_graphicsQueue(uint32_t reserved, const R4SdkDriver2Context * p0, R4SdkDriverQueueContext *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,13u,a,1u,output);
}
/* driver2.Context.registerDisplayBlitBackend -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_registerDisplayBlitBackend(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1, const R4DisplayBlitBackend * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,14u,a,3u,0);
}
/* driver2.Context.unregisterDisplayBlitBackend -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_unregisterDisplayBlitBackend(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,15u,a,2u,0);
}
/* driver2.Context.registerUsbHostController -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_registerUsbHostController(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1, const R4UsbHostController * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,16u,a,3u,0);
}
/* driver2.Context.syncDmaForDevice -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_syncDmaForDevice(uint32_t reserved, const R4SdkDriver2Context * p0, const R4DmaMapping * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,17u,a,2u,0);
}
/* driver2.Context.syncDmaForCpu -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_syncDmaForCpu(uint32_t reserved, const R4SdkDriver2Context * p0, const R4DmaMapping * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,18u,a,2u,0);
}
/* driver2.Context.syncDmaRangeForDevice -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_syncDmaRangeForDevice(uint32_t reserved, const R4SdkDriver2Context * p0, const R4DmaMapping * p1, uint32_t p2, uint32_t p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,19u,a,4u,0);
}
/* driver2.Context.syncDmaRangeForCpu -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_syncDmaRangeForCpu(uint32_t reserved, const R4SdkDriver2Context * p0, const R4DmaMapping * p1, uint32_t p2, uint32_t p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,20u,a,4u,0);
}
/* driver2.Context.irqStats -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_irqStats(uint32_t reserved, const R4SdkDriver2Context * p0, uint8_t p1, R4IrqStats * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,21u,a,3u,0);
}
/* driver2.Context.workSummary -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_workSummary(uint32_t reserved, const R4SdkDriver2Context * p0, R4DriverWorkSummary * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,22u,a,2u,0);
}
/* driver2.Context.workSubmitOwned -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_workSubmitOwned(uint32_t reserved, const R4SdkDriver2Context * p0, uintptr_t p1, uint64_t p2, uint32_t * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,23u,a,4u,0);
}
/* driver2.Context.monotonicClock -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_monotonicClock(uint32_t reserved, const R4SdkDriver2Context * p0, R4MonotonicClockInfo * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,24u,a,2u,0);
}
/* driver2.Context.heap -> ?driver_heap.Context */
static inline R4SdkDriverSlot R4SdkDriver2Context_heap(uint32_t reserved, const R4SdkDriver2Context * p0, R4SdkDriverHeapContext *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,25u,a,1u,output);
}
/* driver2.Context.resources -> ?driver_resources.Context */
static inline R4SdkDriverSlot R4SdkDriver2Context_resources(uint32_t reserved, const R4SdkDriver2Context * p0, R4SdkDriverResourcesContext *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,26u,a,1u,output);
}
/* driver2.Context.threads -> ?driver_threads.Context */
static inline R4SdkDriverSlot R4SdkDriver2Context_threads(uint32_t reserved, const R4SdkDriver2Context * p0, R4SdkDriverThreadsContext *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,27u,a,1u,output);
}
/* driver2.Context.semaphores -> ?driver_semaphores.Context */
static inline R4SdkDriverSlot R4SdkDriver2Context_semaphores(uint32_t reserved, const R4SdkDriver2Context * p0, R4SdkDriverSemaphoresContext *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,28u,a,1u,output);
}
/* driver2.Context.activateUsbHostController -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_activateUsbHostController(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1, uint32_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,29u,a,3u,0);
}
/* driver2.Context.unregisterUsbHostController -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_unregisterUsbHostController(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,30u,a,2u,0);
}
/* driver2.Context.serial -> ?driver_serial.Context */
static inline R4SdkDriverSlot R4SdkDriver2Context_serial(uint32_t reserved, const R4SdkDriver2Context * p0, R4SdkDriverSerialContext *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,31u,a,1u,output);
}
/* driver2.Context.memory -> ?driver_memory.Context */
static inline R4SdkDriverSlot R4SdkDriver2Context_memory(uint32_t reserved, const R4SdkDriver2Context * p0, R4SdkDriverMemoryContext *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,32u,a,1u,output);
}
/* driver2.Context.getOption -> [*:0]const u8 */
static inline R4SdkDriverSlot R4SdkDriver2Context_getOption(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1, const uint8_t * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,33u,a,3u,0);
}
/* driver2.Context.registerNetBackend -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_registerNetBackend(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1, const R4NetBackend * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,34u,a,3u,0);
}
/* driver2.Context.netReceiveFrame -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_netReceiveFrame(uint32_t reserved, const R4SdkDriver2Context * p0, int32_t p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,35u,a,3u,0);
}
/* driver2.Context.netScheduleRx -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_netScheduleRx(uint32_t reserved, const R4SdkDriver2Context * p0, int32_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,36u,a,2u,0);
}
/* driver2.Context.netBackendQuery -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_netBackendQuery(uint32_t reserved, const R4SdkDriver2Context * p0, int32_t p1, R4NetBackendNegotiation * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,37u,a,3u,0);
}
/* driver2.Context.netReceivePacket -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_netReceivePacket(uint32_t reserved, const R4SdkDriver2Context * p0, int32_t p1, const R4NetPacket * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,38u,a,3u,0);
}
/* driver2.Context.pciDeviceCount -> u32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_pciDeviceCount(uint32_t reserved, const R4SdkDriver2Context * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,39u,a,1u,0);
}
/* driver2.Context.pciDeviceAt -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_pciDeviceAt(uint32_t reserved, const R4SdkDriver2Context * p0, uint32_t p1, R4PciDeviceInfo * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,40u,a,3u,0);
}
/* driver2.Context.pciReadBar -> u32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_pciReadBar(uint32_t reserved, const R4SdkDriver2Context * p0, const R4PciDeviceInfo * p1, uint8_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,41u,a,3u,0);
}
/* driver2.Context.createSharedDmaBuffer -> ?*driver.SharedDmaBuffer */
static inline R4SdkDriverSlot R4SdkDriver2Context_createSharedDmaBuffer(uint32_t reserved, const R4SdkDriver2Context * p0, uint32_t p1, uint64_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,42u,a,3u,0);
}
/* driver2.Context.releaseSharedDmaBuffer -> void */
static inline R4SdkDriverSlot R4SdkDriver2Context_releaseSharedDmaBuffer(uint32_t reserved, const R4SdkDriver2Context * p0, R4SdkDriverSharedDmaBuffer * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,43u,a,2u,0);
}
/* driver2.Context.allocDmaRegion -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_allocDmaRegion(uint32_t reserved, const R4SdkDriver2Context * p0, uint32_t p1, uint32_t p2, R4DmaBuffer * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,44u,a,4u,0);
}
/* driver2.Context.allocDmaRegionConstrained -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_allocDmaRegionConstrained(uint32_t reserved, const R4SdkDriver2Context * p0, uint32_t p1, uint32_t p2, uint64_t p3, R4DmaBuffer * p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.ptr=(void *)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,45u,a,5u,0);
}
/* driver2.Context.completionRelease -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_completionRelease(uint32_t reserved, const R4SdkDriver2Context * p0, uint32_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,46u,a,2u,0);
}
/* driver2.Context.completionStatus -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_completionStatus(uint32_t reserved, const R4SdkDriver2Context * p0, uint32_t p1, R4DriverCompletionStatus * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,47u,a,3u,0);
}
/* driver2.Context.completionWait -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_completionWait(uint32_t reserved, const R4SdkDriver2Context * p0, uint32_t p1, uint64_t p2, int32_t * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,48u,a,4u,0);
}
/* driver2.Context.freeDmaRegion -> void */
static inline R4SdkDriverSlot R4SdkDriver2Context_freeDmaRegion(uint32_t reserved, const R4SdkDriver2Context * p0, R4DmaBuffer * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,49u,a,2u,0);
}
/* driver2.Context.irqRegister -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_irqRegister(uint32_t reserved, const R4SdkDriver2Context * p0, uint8_t p1, uintptr_t p2, uint64_t p3, uint32_t p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,50u,a,5u,0);
}
/* driver2.Context.irqUnregister -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_irqUnregister(uint32_t reserved, const R4SdkDriver2Context * p0, uint8_t p1, uintptr_t p2, uint64_t p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)(uintptr_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,51u,a,4u,0);
}
/* driver2.Context.logError -> void */
static inline R4SdkDriverSlot R4SdkDriver2Context_logError(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,52u,a,2u,0);
}
/* driver2.Context.logInfo -> void */
static inline R4SdkDriverSlot R4SdkDriver2Context_logInfo(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,53u,a,2u,0);
}
/* driver2.Context.logWarn -> void */
static inline R4SdkDriverSlot R4SdkDriver2Context_logWarn(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,54u,a,2u,0);
}
/* driver2.Context.mapDmaPinned -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_mapDmaPinned(uint32_t reserved, const R4SdkDriver2Context * p0, const R4DmaPinnedBuffer * p1, const R4DmaConstraints * p2, uint32_t p3, R4DmaMapping * p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.ptr=(void *)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,55u,a,5u,0);
}
/* driver2.Context.pciDisableMsi -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_pciDisableMsi(uint32_t reserved, const R4SdkDriver2Context * p0, const R4PciDeviceInfo * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,56u,a,2u,0);
}
/* driver2.Context.pciEnableBusMaster -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_pciEnableBusMaster(uint32_t reserved, const R4SdkDriver2Context * p0, const R4PciDeviceInfo * p1, uint32_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,57u,a,3u,0);
}
/* driver2.Context.pciEnableMsi -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_pciEnableMsi(uint32_t reserved, const R4SdkDriver2Context * p0, const R4PciDeviceInfo * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,58u,a,2u,0);
}
/* driver2.Context.pciFindByClass -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_pciFindByClass(uint32_t reserved, const R4SdkDriver2Context * p0, uint8_t p1, uint8_t p2, uint32_t p3, R4PciDeviceInfo * p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.ptr=(void *)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,59u,a,5u,0);
}
/* driver2.Context.pciMapBar -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_pciMapBar(uint32_t reserved, const R4SdkDriver2Context * p0, const R4PciDeviceInfo * p1, uint8_t p2, uint32_t p3, uint32_t p4, R4MmioRegion * p5) {
 (void)reserved; R4SdkDriverSlot a[6]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDRIVER_PRESENT};
 a[5] = (R4SdkDriverSlot){.ptr=(void *)p5,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,60u,a,6u,0);
}
/* driver2.Context.pciReadConfig32 -> u32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_pciReadConfig32(uint32_t reserved, const R4SdkDriver2Context * p0, const R4PciDeviceInfo * p1, uint16_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,61u,a,3u,0);
}
/* driver2.Context.pciWriteConfig32 -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_pciWriteConfig32(uint32_t reserved, const R4SdkDriver2Context * p0, const R4PciDeviceInfo * p1, uint16_t p2, uint32_t p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,62u,a,4u,0);
}
/* driver2.Context.pinDmaBuffer -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_pinDmaBuffer(uint32_t reserved, const R4SdkDriver2Context * p0, uint8_t * p1, uintptr_t n1, R4DmaPinnedBuffer * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,63u,a,3u,0);
}
/* driver2.Context.pinDmaConstBuffer -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_pinDmaConstBuffer(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1, uintptr_t n1, R4DmaPinnedBuffer * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,64u,a,3u,0);
}
/* driver2.Context.portInb -> u8 */
static inline R4SdkDriverSlot R4SdkDriver2Context_portInb(uint32_t reserved, const R4SdkDriver2Context * p0, uint16_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,65u,a,2u,0);
}
/* driver2.Context.portInw -> u16 */
static inline R4SdkDriverSlot R4SdkDriver2Context_portInw(uint32_t reserved, const R4SdkDriver2Context * p0, uint16_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,66u,a,2u,0);
}
/* driver2.Context.portInl -> u32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_portInl(uint32_t reserved, const R4SdkDriver2Context * p0, uint16_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,67u,a,2u,0);
}
/* driver2.Context.portOutb -> void */
static inline R4SdkDriverSlot R4SdkDriver2Context_portOutb(uint32_t reserved, const R4SdkDriver2Context * p0, uint16_t p1, uint8_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,68u,a,3u,0);
}
/* driver2.Context.portOutw -> void */
static inline R4SdkDriverSlot R4SdkDriver2Context_portOutw(uint32_t reserved, const R4SdkDriver2Context * p0, uint16_t p1, uint16_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,69u,a,3u,0);
}
/* driver2.Context.portOutl -> void */
static inline R4SdkDriverSlot R4SdkDriver2Context_portOutl(uint32_t reserved, const R4SdkDriver2Context * p0, uint16_t p1, uint32_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,70u,a,3u,0);
}
/* driver2.Context.registerStorageBackend -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_registerStorageBackend(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1, const R4StorageBackend * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,71u,a,3u,0);
}
/* driver2.Context.unregisterStorageBackend -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_unregisterStorageBackend(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,72u,a,2u,0);
}
/* driver2.Context.storageBackendRecoveryBegin -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_storageBackendRecoveryBegin(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,73u,a,2u,0);
}
/* driver2.Context.storageBackendRecoveryFinish -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_storageBackendRecoveryFinish(uint32_t reserved, const R4SdkDriver2Context * p0, const uint8_t * p1, uint8_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,74u,a,3u,0);
}
/* driver2.Context.tickCount -> u64 */
static inline R4SdkDriverSlot R4SdkDriver2Context_tickCount(uint32_t reserved, const R4SdkDriver2Context * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,75u,a,1u,0);
}
/* driver2.Context.timerFrequency -> u32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_timerFrequency(uint32_t reserved, const R4SdkDriver2Context * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,76u,a,1u,0);
}
/* driver2.Context.unmapDma -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_unmapDma(uint32_t reserved, const R4SdkDriver2Context * p0, R4DmaMapping * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,77u,a,2u,0);
}
/* driver2.Context.unpinDmaBuffer -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_unpinDmaBuffer(uint32_t reserved, const R4SdkDriver2Context * p0, R4DmaPinnedBuffer * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,78u,a,2u,0);
}
/* driver2.Context.waitTicks -> void */
static inline R4SdkDriverSlot R4SdkDriver2Context_waitTicks(uint32_t reserved, const R4SdkDriver2Context * p0, uint64_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,79u,a,2u,0);
}
/* driver2.Context.workCancel -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_workCancel(uint32_t reserved, const R4SdkDriver2Context * p0, uint32_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,80u,a,2u,0);
}
/* driver2.Context.workSubmit -> i32 */
static inline R4SdkDriverSlot R4SdkDriver2Context_workSubmit(uint32_t reserved, const R4SdkDriver2Context * p0, uintptr_t p1, uint64_t p2, uint32_t p3, uint32_t * p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.ptr=(void *)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,81u,a,5u,0);
}
/* driver_serial.Context.register -> i32 */
static inline R4SdkDriverSlot R4SdkDriverSerialContext_register(uint32_t reserved, const R4SdkDriverSerialContext * p0, const R4SerialBackend * p1, uint64_t * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,82u,a,3u,0);
}
/* driver_serial.Context.unregister -> i32 */
static inline R4SdkDriverSlot R4SdkDriverSerialContext_unregister(uint32_t reserved, const R4SdkDriverSerialContext * p0, uint64_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,83u,a,2u,0);
}
/* driver_serial.Context.notify -> i32 */
static inline R4SdkDriverSlot R4SdkDriverSerialContext_notify(uint32_t reserved, const R4SdkDriverSerialContext * p0, uint64_t p1, uint32_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,84u,a,3u,0);
}
/* driver_serial.Context.admission -> i32 */
static inline R4SdkDriverSlot R4SdkDriverSerialContext_admission(uint32_t reserved, const R4SdkDriverSerialContext * p0, uint64_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,85u,a,2u,0);
}
/* driver_memory.Context.reservedSpan -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_reservedSpan(uint32_t reserved, const R4SdkDriverMemoryContext * p0, uint64_t p1, uint64_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,86u,a,3u,0);
}
/* driver_memory.Context.unmanagedSpan -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_unmanagedSpan(uint32_t reserved, const R4SdkDriverMemoryContext * p0, uint64_t p1, uint64_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,87u,a,3u,0);
}
/* driver_memory.Context.deviceLost -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_deviceLost(uint32_t reserved, const R4SdkDriverMemoryContext * p0, uint32_t p1, uint64_t p2, uint8_t p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,88u,a,4u,0);
}
/* driver_memory.Context.telemetryExchange -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_telemetryExchange(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxTelemetryState * p1, R4GfxTelemetryDemand * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,89u,a,3u,0);
}
/* driver_memory.Context.memoryBudget -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_memoryBudget(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxDeviceBudgetRequest * p1, R4GfxDeviceBudgetState * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,90u,a,3u,0);
}
/* driver_memory.Context.virtualRegister -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_virtualRegister(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxNativeProvider * p1, R4GfxBufferHandle * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,91u,a,3u,0);
}
/* driver_memory.Context.virtualUnregister -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_virtualUnregister(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,92u,a,2u,0);
}
/* driver_memory.Context.virtualTake -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_virtualTake(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1, R4GfxVirtualJob * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,93u,a,3u,0);
}
/* driver_memory.Context.virtualComplete -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_virtualComplete(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1, const R4GfxVirtualCompletion * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,94u,a,3u,0);
}
/* driver_memory.Context.nativeRegister -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_nativeRegister(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxNativeProvider * p1, R4GfxBufferHandle * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,95u,a,3u,0);
}
/* driver_memory.Context.nativeUnregister -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_nativeUnregister(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,96u,a,2u,0);
}
/* driver_memory.Context.nativeTake -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_nativeTake(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1, R4GfxNativeJob * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,97u,a,3u,0);
}
/* driver_memory.Context.nativeComplete -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_nativeComplete(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1, const R4GfxBufferHandle * p2, int32_t p3, const R4GfxBufferHandle * p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.ptr=(void *)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,98u,a,5u,0);
}
/* driver_memory.Context.bufferCreate -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_bufferCreate(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferDescriptor * p1, R4GfxBufferReference * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,99u,a,3u,0);
}
/* driver_memory.Context.bufferDescribe -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_bufferDescribe(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1, R4GfxBufferDescriptor * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,100u,a,3u,0);
}
/* driver_memory.Context.bufferImport -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_bufferImport(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1, R4GfxBufferReference * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,101u,a,3u,0);
}
/* driver_memory.Context.bufferRelease -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_bufferRelease(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,102u,a,2u,0);
}
/* driver_memory.Context.bufferMap -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_bufferMap(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1, uint32_t p2, uint64_t p3, uint64_t p4, R4GfxBufferMap * p5) {
 (void)reserved; R4SdkDriverSlot a[6]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDRIVER_PRESENT};
 a[5] = (R4SdkDriverSlot){.ptr=(void *)p5,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,103u,a,6u,0);
}
/* driver_memory.Context.bufferUnmap -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_bufferUnmap(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,104u,a,2u,0);
}
/* driver_memory.Context.deviceAcquire -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_deviceAcquire(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1, const R4GfxDeviceRequest * p2, R4GfxDeviceLease * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,105u,a,4u,0);
}
/* driver_memory.Context.deviceSegment -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_deviceSegment(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxDeviceLease * p1, uint64_t p2, R4GfxDmaSegment * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,106u,a,4u,0);
}
/* driver_memory.Context.deviceRelease -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_deviceRelease(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxDeviceLease * p1, uint32_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,107u,a,3u,0);
}
/* driver_memory.Context.mmioMap -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_mmioMap(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxMmioRequest * p1, R4GfxMmioWindow * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,108u,a,3u,0);
}
/* driver_memory.Context.mmioUnmap -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_mmioUnmap(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferHandle * p1, uint32_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,109u,a,3u,0);
}
/* driver_memory.Context.collect -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_collect(uint32_t reserved, const R4SdkDriverMemoryContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,110u,a,1u,0);
}
/* driver_memory.Context.bufferStats -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_bufferStats(uint32_t reserved, const R4SdkDriverMemoryContext * p0, R4GfxBufferStats * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,111u,a,2u,0);
}
/* driver_memory.Context.bufferReserve -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_bufferReserve(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxBufferDescriptor * p1, uint64_t p2, R4GfxOwnedBufferReservation * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,112u,a,4u,0);
}
/* driver_memory.Context.bufferCommit -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_bufferCommit(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxOwnedBufferReservation * p1, R4GfxBufferReference * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,113u,a,3u,0);
}
/* driver_memory.Context.bufferAbort -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_bufferAbort(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxOwnedBufferReservation * p1, uint32_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,114u,a,3u,0);
}
/* driver_memory.Context.bufferTakeRelease -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_bufferTakeRelease(uint32_t reserved, const R4SdkDriverMemoryContext * p0, uint32_t p1, uint64_t p2, R4GfxOwnedBufferRelease * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,115u,a,4u,0);
}
/* driver_memory.Context.bufferFinishRelease -> i32 */
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_bufferFinishRelease(uint32_t reserved, const R4SdkDriverMemoryContext * p0, const R4GfxOwnedBufferRelease * p1, uint32_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,116u,a,3u,0);
}
/* driver_entropy.Context.register -> i32 */
static inline R4SdkDriverSlot R4SdkDriverEntropyContext_register(uint32_t reserved, const R4SdkDriverEntropyContext * p0, const R4EntropyBackend * p1, uint64_t * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,117u,a,3u,0);
}
/* driver_entropy.Context.unregister -> i32 */
static inline R4SdkDriverSlot R4SdkDriverEntropyContext_unregister(uint32_t reserved, const R4SdkDriverEntropyContext * p0, uint64_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,118u,a,2u,0);
}
/* driver_resources.Context.entropy -> ?driver_entropy.Context */
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_entropy(uint32_t reserved, const R4SdkDriverResourcesContext * p0, R4SdkDriverEntropyContext *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,119u,a,1u,output);
}
/* driver_resources.Context.cpuPower -> ?driver_cpu_power.Context */
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_cpuPower(uint32_t reserved, const R4SdkDriverResourcesContext * p0, R4SdkDriverCpuPowerContext *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,120u,a,1u,output);
}
/* driver_resources.Context.platform -> ?driver_resources.Platform */
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_platform(uint32_t reserved, const R4SdkDriverResourcesContext * p0, R4SdkDriverResourcesPlatform *output) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,121u,a,1u,output);
}
/* driver_resources.Context.supportsAcpi -> bool */
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_supportsAcpi(uint32_t reserved, const R4SdkDriverResourcesContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,122u,a,1u,0);
}
/* driver_resources.Context.acpiStat -> i32 */
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_acpiStat(uint32_t reserved, const R4SdkDriverResourcesContext * p0, const R4SdkDriverNativeValue143 * p1, uint32_t p2, R4DriverFirmwareTableInfo * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,123u,a,4u,0);
}
/* driver_resources.Context.acpiReadAt -> i32 */
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_acpiReadAt(uint32_t reserved, const R4SdkDriverResourcesContext * p0, uint64_t p1, uint64_t p2, uint8_t * p3, uintptr_t n3, uint64_t p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,124u,a,5u,0);
}
/* driver_resources.Context.stat -> i32 */
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_stat(uint32_t reserved, const R4SdkDriverResourcesContext * p0, const uint8_t * p1, uintptr_t n1, R4DriverResourceInfo * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,125u,a,3u,0);
}
/* driver_resources.Context.readAt -> i32 */
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_readAt(uint32_t reserved, const R4SdkDriverResourcesContext * p0, uint64_t p1, uint64_t p2, uint8_t * p3, uintptr_t n3, uint64_t p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,126u,a,5u,0);
}
/* driver_resources.Context.nowNs -> u64 */
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_nowNs(uint32_t reserved, const R4SdkDriverResourcesContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,127u,a,1u,0);
}
/* driver_resources.Platform.rsdp -> u64 */
static inline R4SdkDriverSlot R4SdkDriverResourcesPlatform_rsdp(uint32_t reserved, const R4SdkDriverResourcesPlatform * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,128u,a,1u,0);
}
/* driver_resources.Platform.physicalView -> ?[*]u8 */
static inline R4SdkDriverSlot R4SdkDriverResourcesPlatform_physicalView(uint32_t reserved, const R4SdkDriverResourcesPlatform * p0, uint64_t p1, uint64_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,129u,a,3u,0);
}
/* driver_resources.Platform.input -> i32 */
static inline R4SdkDriverSlot R4SdkDriverResourcesPlatform_input(uint32_t reserved, const R4SdkDriverResourcesPlatform * p0, uint32_t p1, uint32_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,130u,a,3u,0);
}
/* driver_queue.Context.queueOwnerInfo -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_queueOwnerInfo(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxBackendBinding * p1, uint64_t p2, R4GfxQueueOwnerInfo * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,131u,a,4u,0);
}
/* driver_queue.Context.supportsScanout -> bool */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_supportsScanout(uint32_t reserved, const R4SdkDriverQueueContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,132u,a,1u,0);
}
/* driver_queue.Context.retainScanout -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_retainScanout(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxFence * p1, R4GfxBufferReference * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,133u,a,3u,0);
}
/* driver_queue.Context.beginScanout -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_beginScanout(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxFence * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,134u,a,2u,0);
}
/* driver_queue.Context.scanoutRetireRequested -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_scanoutRetireRequested(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxFence * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,135u,a,2u,0);
}
/* driver_queue.Context.supportsRenderList -> bool */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_supportsRenderList(uint32_t reserved, const R4SdkDriverQueueContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,136u,a,1u,0);
}
/* driver_queue.Context.supportsRenderGridList -> bool */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_supportsRenderGridList(uint32_t reserved, const R4SdkDriverQueueContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,137u,a,1u,0);
}
/* driver_queue.Context.supportsRenderColorList -> bool */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_supportsRenderColorList(uint32_t reserved, const R4SdkDriverQueueContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,138u,a,1u,0);
}
/* driver_queue.Context.readRenderColorList -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_readRenderColorList(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxFence * p1, R4GfxRenderColorList * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,139u,a,3u,0);
}
/* driver_queue.Context.readRenderGridList -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_readRenderGridList(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxFence * p1, R4GfxRenderGridList * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,140u,a,3u,0);
}
/* driver_queue.Context.readRenderList -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_readRenderList(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxFence * p1, R4GfxRenderList * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,141u,a,3u,0);
}
/* driver_queue.Context.updateOperations -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_updateOperations(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxBackendBinding * p1, uint64_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,142u,a,3u,0);
}
/* driver_queue.Context.registerProfile -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_registerProfile(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxBackendRegistration * p1, const R4GfxBackendProfile * p2, R4GfxBackendBinding * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,143u,a,4u,0);
}
/* driver_queue.Context.publishProperties -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_publishProperties(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxBackendBinding * p1, const R4GfxBackendProperties * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,144u,a,3u,0);
}
/* driver_queue.Context.nativeInfo -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_nativeInfo(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxFence * p1, R4GfxNativeJobInfo * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,145u,a,3u,0);
}
/* driver_queue.Context.nativeData -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_nativeData(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxFence * p1, uint32_t p2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,146u,a,4u,0);
}
/* driver_queue.Context.nativeBinding -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_nativeBinding(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxFence * p1, uint32_t p2, R4GfxNativeBinding * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,147u,a,4u,0);
}
/* driver_queue.Context.register -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_register(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxBackendRegistration * p1, R4GfxBackendBinding * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,148u,a,3u,0);
}
/* driver_queue.Context.unregister -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_unregister(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxBackendBinding * p1, uint32_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,149u,a,3u,0);
}
/* driver_queue.Context.take -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_take(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxBackendBinding * p1, R4GfxDriverJob * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,150u,a,3u,0);
}
/* driver_queue.Context.complete -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_complete(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxFence * p1, uint32_t p2, uint32_t p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,151u,a,4u,0);
}
/* driver_queue.Context.reset -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_reset(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxBackendBinding * p1, uint32_t p2, R4GfxBackendBinding * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,152u,a,4u,0);
}
/* driver_queue.Context.segment -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_segment(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxFence * p1, uint32_t p2, uint64_t p3, uint64_t p4, R4GfxDmaSegment * p5) {
 (void)reserved; R4SdkDriverSlot a[6]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDRIVER_PRESENT};
 a[5] = (R4SdkDriverSlot){.ptr=(void *)p5,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,153u,a,6u,0);
}
/* driver_queue.Context.retainResource -> i32 */
static inline R4SdkDriverSlot R4SdkDriverQueueContext_retainResource(uint32_t reserved, const R4SdkDriverQueueContext * p0, const R4GfxFence * p1, uint32_t p2, R4GfxBufferReference * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,154u,a,4u,0);
}
/* driver_outputs.Context.supportsPower -> bool */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_supportsPower(uint32_t reserved, const R4SdkDriverOutputsContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,155u,a,1u,0);
}
/* driver_outputs.Context.publishPower -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_publishPower(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxOutputPower * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,156u,a,2u,0);
}
/* driver_outputs.Context.readPower -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_readPower(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxOutputId * p1, R4GfxPowerRequest * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,157u,a,3u,0);
}
/* driver_outputs.Context.supportsBrightness -> bool */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_supportsBrightness(uint32_t reserved, const R4SdkDriverOutputsContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,158u,a,1u,0);
}
/* driver_outputs.Context.publishBrightness -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_publishBrightness(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxOutputBrightness * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,159u,a,2u,0);
}
/* driver_outputs.Context.readBrightness -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_readBrightness(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxOutputId * p1, R4GfxBrightnessRequest * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,160u,a,3u,0);
}
/* driver_outputs.Context.supportsRefresh -> bool */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_supportsRefresh(uint32_t reserved, const R4SdkDriverOutputsContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,161u,a,1u,0);
}
/* driver_outputs.Context.publishRefresh -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_publishRefresh(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxOutputRefresh * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,162u,a,2u,0);
}
/* driver_outputs.Context.readRefresh -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_readRefresh(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxOutputTarget * p1, R4GfxRefreshRequest * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,163u,a,3u,0);
}
/* driver_outputs.Context.supportsModeColor -> bool */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_supportsModeColor(uint32_t reserved, const R4SdkDriverOutputsContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,164u,a,1u,0);
}
/* driver_outputs.Context.readModeColor -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_readModeColor(uint32_t reserved, const R4SdkDriverOutputsContext * p0, uint64_t p1, uint64_t p2, R4GfxDriverModeColor * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,165u,a,4u,0);
}
/* driver_outputs.Context.supportsColor -> bool */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_supportsColor(uint32_t reserved, const R4SdkDriverOutputsContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,166u,a,1u,0);
}
/* driver_outputs.Context.publishColor -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_publishColor(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxOutputColorState * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,167u,a,2u,0);
}
/* driver_outputs.Context.supportsHotplug -> bool */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_supportsHotplug(uint32_t reserved, const R4SdkDriverOutputsContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,168u,a,1u,0);
}
/* driver_outputs.Context.pauseOutput -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_pauseOutput(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxOutputId * p1, uint8_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,169u,a,3u,0);
}
/* driver_outputs.Context.restoreMode -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_restoreMode(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxAtomicState * p1, R4GfxModeStatus * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,170u,a,3u,0);
}
/* driver_outputs.Context.modeStatus -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_modeStatus(uint32_t reserved, const R4SdkDriverOutputsContext * p0, uint64_t p1, R4GfxModeStatus * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,171u,a,3u,0);
}
/* driver_outputs.Context.supportsAudio -> bool */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_supportsAudio(uint32_t reserved, const R4SdkDriverOutputsContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,172u,a,1u,0);
}
/* driver_outputs.Context.publishAudio -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_publishAudio(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxAudioRoute * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,173u,a,2u,0);
}
/* driver_outputs.Context.queryAudio -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_queryAudio(uint32_t reserved, const R4SdkDriverOutputsContext * p0, uint32_t p1, uint32_t p2, uint32_t p3, R4GfxAudioRoute * p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.ptr=(void *)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,174u,a,5u,0);
}
/* driver_outputs.Context.supportsModes -> bool */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_supportsModes(uint32_t reserved, const R4SdkDriverOutputsContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,175u,a,1u,0);
}
/* driver_outputs.Context.enableModes -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_enableModes(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxBackendBinding * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,176u,a,2u,0);
}
/* driver_outputs.Context.takeMode -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_takeMode(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxBackendBinding * p1, R4GfxDriverModeJob * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,177u,a,3u,0);
}
/* driver_outputs.Context.completeMode -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_completeMode(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxDriverModeCompletion * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,178u,a,2u,0);
}
/* driver_outputs.Context.supportsReceivers -> bool */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_supportsReceivers(uint32_t reserved, const R4SdkDriverOutputsContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,179u,a,1u,0);
}
/* driver_outputs.Context.registerSource -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_registerSource(uint32_t reserved, const R4SdkDriverOutputsContext * p0, uint32_t p1, R4GfxReceiverSource * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,180u,a,3u,0);
}
/* driver_outputs.Context.replaceReceivers -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_replaceReceivers(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxReceiverUpdate * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,181u,a,2u,0);
}
/* driver_outputs.Context.closeSource -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_closeSource(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxReceiverSource * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,182u,a,2u,0);
}
/* driver_outputs.Context.publish -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_publish(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxOutputPublication * p1, R4GfxOutputId * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,183u,a,3u,0);
}
/* driver_outputs.Context.withdraw -> i32 */
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_withdraw(uint32_t reserved, const R4SdkDriverOutputsContext * p0, const R4GfxOutputId * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,184u,a,2u,0);
}
/* driver_display.Context.supportsHeadlessResume -> bool */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_supportsHeadlessResume(uint32_t reserved, const R4SdkDriverDisplayContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,185u,a,1u,0);
}
/* driver_display.Context.resumeHeadless -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_resumeHeadless(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4GfxBackendBinding * p1, uint64_t p2, R4GfxNativeState * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,186u,a,4u,0);
}
/* driver_display.Context.supportsTerminalRelease -> bool */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_supportsTerminalRelease(uint32_t reserved, const R4SdkDriverDisplayContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,187u,a,1u,0);
}
/* driver_display.Context.releaseTerminal -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_releaseTerminal(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4GfxBackendBinding * p1, uint64_t p2, R4GfxNativeState * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,188u,a,4u,0);
}
/* driver_display.Context.supportsReset -> bool */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_supportsReset(uint32_t reserved, const R4SdkDriverDisplayContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,189u,a,1u,0);
}
/* driver_display.Context.deviceReset -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_deviceReset(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4GfxBackendBinding * p1, uint64_t p2, uint8_t p3, R4GfxNativeState * p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.ptr=(void *)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,190u,a,5u,0);
}
/* driver_display.Context.prepareReset -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_prepareReset(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4GfxNativeRegistration * p1, uint64_t p2, uint64_t p3, R4GfxNativeState * p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.ptr=(void *)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,191u,a,5u,0);
}
/* driver_display.Context.supportsOutputs -> bool */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_supportsOutputs(uint32_t reserved, const R4SdkDriverDisplayContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,192u,a,1u,0);
}
/* driver_display.Context.outputRegister -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_outputRegister(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4GfxAdditionalOutput * p1, R4GfxOutputTarget * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,193u,a,3u,0);
}
/* driver_display.Context.outputTransition -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_outputTransition(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4GfxOutputTarget * p1, uint32_t p2, uint8_t p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,194u,a,4u,0);
}
/* driver_display.Context.supportsCursor -> bool */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_supportsCursor(uint32_t reserved, const R4SdkDriverDisplayContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,195u,a,1u,0);
}
/* driver_display.Context.cursorConfigure -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_cursorConfigure(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4DisplayCursorInfo * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,196u,a,2u,0);
}
/* driver_display.Context.cursorTake -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_cursorTake(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4GfxBackendBinding * p1, R4GfxDriverCursorJob * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,197u,a,3u,0);
}
/* driver_display.Context.cursorComplete -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_cursorComplete(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4GfxDriverCursorCompletion * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,198u,a,2u,0);
}
/* driver_display.Context.supportsPresentationStats -> bool */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_supportsPresentationStats(uint32_t reserved, const R4SdkDriverDisplayContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,199u,a,1u,0);
}
/* driver_display.Context.supportsPresentationInfo -> bool */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_supportsPresentationInfo(uint32_t reserved, const R4SdkDriverDisplayContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,200u,a,1u,0);
}
/* driver_display.Context.presentationInfo -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_presentationInfo(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4DisplayPresentationInfo * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,201u,a,2u,0);
}
/* driver_display.Context.presentationStats -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_presentationStats(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4DisplayPresentationStats * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,202u,a,2u,0);
}
/* driver_display.Context.bootHold -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_bootHold(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4GfxBootHoldRequest * p1, R4GfxNativeState * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,203u,a,3u,0);
}
/* driver_display.Context.bootFinish -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_bootFinish(uint32_t reserved, const R4SdkDriverDisplayContext * p0, uint64_t p1, uint32_t p2, R4GfxNativeState * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,204u,a,4u,0);
}
/* driver_display.Context.schedule -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_schedule(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4GfxBackendBinding * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,205u,a,2u,0);
}
/* driver_display.Context.bootInfo -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_bootInfo(uint32_t reserved, const R4SdkDriverDisplayContext * p0, R4GfxNativeBootInfo * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,206u,a,2u,0);
}
/* driver_display.Context.prepare -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_prepare(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4GfxNativeRegistration * p1, R4GfxNativeState * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,207u,a,3u,0);
}
/* driver_display.Context.prepareHeld -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_prepareHeld(uint32_t reserved, const R4SdkDriverDisplayContext * p0, const R4GfxNativeRegistration * p1, uint64_t p2, R4GfxNativeState * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,208u,a,4u,0);
}
/* driver_display.Context.transition -> i32 */
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_transition(uint32_t reserved, const R4SdkDriverDisplayContext * p0, uint64_t p1, uint32_t p2, R4GfxNativeState * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,209u,a,4u,0);
}
/* driver_heap.Context.allocate -> i32 */
static inline R4SdkDriverSlot R4SdkDriverHeapContext_allocate(uint32_t reserved, const R4SdkDriverHeapContext * p0, uint64_t p1, uint32_t p2, R4DriverHeapAllocation * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,210u,a,4u,0);
}
/* driver_heap.Context.release -> i32 */
static inline R4SdkDriverSlot R4SdkDriverHeapContext_release(uint32_t reserved, const R4SdkDriverHeapContext * p0, uint64_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,211u,a,2u,0);
}
/* driver_heap.Context.stats -> i32 */
static inline R4SdkDriverSlot R4SdkDriverHeapContext_stats(uint32_t reserved, const R4SdkDriverHeapContext * p0, R4DriverHeapStats * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,212u,a,2u,0);
}
/* driver_threads.Context.start -> i32 */
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_start(uint32_t reserved, const R4SdkDriverThreadsContext * p0, uintptr_t p1, uint64_t p2, uint32_t p3, uint64_t * p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.ptr=(void *)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,213u,a,5u,0);
}
/* driver_threads.Context.stop -> i32 */
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_stop(uint32_t reserved, const R4SdkDriverThreadsContext * p0, uint64_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,214u,a,2u,0);
}
/* driver_threads.Context.join -> i32 */
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_join(uint32_t reserved, const R4SdkDriverThreadsContext * p0, uint64_t p1, uint64_t p2, int32_t * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,215u,a,4u,0);
}
/* driver_threads.Context.release -> i32 */
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_release(uint32_t reserved, const R4SdkDriverThreadsContext * p0, uint64_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,216u,a,2u,0);
}
/* driver_threads.Context.status -> i32 */
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_status(uint32_t reserved, const R4SdkDriverThreadsContext * p0, uint64_t p1, R4DriverThreadStatus * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,217u,a,3u,0);
}
/* driver_threads.Context.current -> u64 */
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_current(uint32_t reserved, const R4SdkDriverThreadsContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,218u,a,1u,0);
}
/* driver_threads.Context.sleepTicks -> i32 */
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_sleepTicks(uint32_t reserved, const R4SdkDriverThreadsContext * p0, uint64_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,219u,a,2u,0);
}
/* driver_threads.Context.stats -> i32 */
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_stats(uint32_t reserved, const R4SdkDriverThreadsContext * p0, R4DriverThreadStats * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,220u,a,2u,0);
}
/* driver_threads.Context.canAbort -> bool */
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_canAbort(uint32_t reserved, const R4SdkDriverThreadsContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,221u,a,1u,0);
}
/* driver_threads.Context.hasCurrentRequest -> bool */
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_hasCurrentRequest(uint32_t reserved, const R4SdkDriverThreadsContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,222u,a,1u,0);
}
/* driver_threads.Context.currentRequest -> i32 */
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_currentRequest(uint32_t reserved, const R4SdkDriverThreadsContext * p0, R4DriverThreadRequest * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,223u,a,2u,0);
}
/* driver_threads.Context.abortCurrent -> i32 */
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_abortCurrent(uint32_t reserved, const R4SdkDriverThreadsContext * p0, int32_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,224u,a,2u,0);
}
/* driver_semaphores.Context.create -> i32 */
static inline R4SdkDriverSlot R4SdkDriverSemaphoresContext_create(uint32_t reserved, const R4SdkDriverSemaphoresContext * p0, uint32_t p1, uint32_t p2, uint64_t * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,225u,a,4u,0);
}
/* driver_semaphores.Context.acquire -> i32 */
static inline R4SdkDriverSlot R4SdkDriverSemaphoresContext_acquire(uint32_t reserved, const R4SdkDriverSemaphoresContext * p0, uint64_t p1, uint64_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,226u,a,3u,0);
}
/* driver_semaphores.Context.release -> i32 */
static inline R4SdkDriverSlot R4SdkDriverSemaphoresContext_release(uint32_t reserved, const R4SdkDriverSemaphoresContext * p0, uint64_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,227u,a,2u,0);
}
/* driver_semaphores.Context.destroy -> i32 */
static inline R4SdkDriverSlot R4SdkDriverSemaphoresContext_destroy(uint32_t reserved, const R4SdkDriverSemaphoresContext * p0, uint64_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,228u,a,2u,0);
}
/* driver_semaphores.Context.status -> i32 */
static inline R4SdkDriverSlot R4SdkDriverSemaphoresContext_status(uint32_t reserved, const R4SdkDriverSemaphoresContext * p0, uint64_t p1, R4DriverSemaphoreStatus * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,229u,a,3u,0);
}
/* driver_semaphores.Context.stats -> i32 */
static inline R4SdkDriverSlot R4SdkDriverSemaphoresContext_stats(uint32_t reserved, const R4SdkDriverSemaphoresContext * p0, R4DriverSemaphoreStats * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,230u,a,2u,0);
}
/* driver_semaphores.Context.contextFlags -> u32 */
static inline R4SdkDriverSlot R4SdkDriverSemaphoresContext_contextFlags(uint32_t reserved, const R4SdkDriverSemaphoresContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,231u,a,1u,0);
}
/* driver_cpu_power.Context.idlePublish -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_idlePublish(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, const R4CpuIdleDescriptor * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,232u,a,2u,0);
}
/* driver_cpu_power.Context.idlePolicy -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_idlePolicy(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, const R4CpuIdlePolicy * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,233u,a,2u,0);
}
/* driver_cpu_power.Context.firmwareRegister -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_firmwareRegister(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint32_t p1, const R4CpuFirmwareBackend * p2, uint64_t * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,234u,a,4u,0);
}
/* driver_cpu_power.Context.firmwareUnregister -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_firmwareUnregister(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint32_t p1, uint64_t p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,235u,a,3u,0);
}
/* driver_cpu_power.Context.firmwareExecute -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_firmwareExecute(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, const R4CpuPerformanceRequest * p1, R4CpuFirmwareInfo * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,236u,a,3u,0);
}
/* driver_cpu_power.Context.firmwareControl -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_firmwareControl(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint32_t p1, uint32_t p2, uint64_t p3, uint64_t p4, uint64_t p5, uint64_t * p6) {
 (void)reserved; R4SdkDriverSlot a[7]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDRIVER_PRESENT};
 a[5] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKDRIVER_PRESENT};
 a[6] = (R4SdkDriverSlot){.ptr=(void *)p6,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,237u,a,7u,0);
}
/* driver_cpu_power.Context.firmwareCpuInfo -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_firmwareCpuInfo(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint32_t p1, R4CpuCapabilitiesInfo * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,238u,a,3u,0);
}
/* driver_cpu_power.Context.feature -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_feature(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint32_t p1, uint64_t p2, uint32_t p3, R4CpuFeatureInfo * p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.ptr=(void *)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,239u,a,5u,0);
}
/* driver_cpu_power.Context.registerPerformance -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_registerPerformance(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint64_t p1, const R4CpuPerformanceBackend * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,240u,a,3u,0);
}
/* driver_cpu_power.Context.controlAcquire -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_controlAcquire(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint32_t p1, uint64_t p2, uint64_t * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,241u,a,4u,0);
}
/* driver_cpu_power.Context.controlRelease -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_controlRelease(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint32_t p1, uint64_t p2, uint64_t p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,242u,a,4u,0);
}
/* driver_cpu_power.Context.registerCompareWrite -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_registerCompareWrite(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint32_t p1, uint64_t p2, uint64_t p3, uint32_t p4, uint64_t p5, uint64_t p6, R4CpuRegisterWriteInfo * p7) {
 (void)reserved; R4SdkDriverSlot a[8]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDRIVER_PRESENT};
 a[5] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKDRIVER_PRESENT};
 a[6] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKDRIVER_PRESENT};
 a[7] = (R4SdkDriverSlot){.ptr=(void *)p7,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,243u,a,8u,0);
}
/* driver_cpu_power.Context.registerCppc -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_registerCppc(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint64_t p1, const R4CpuCppcBackend * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,244u,a,3u,0);
}
/* driver_cpu_power.Context.rankPublish -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_rankPublish(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, const R4CpuPerformanceHint * p1, uint64_t * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,245u,a,3u,0);
}
/* driver_cpu_power.Context.register -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_register(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, const R4CpuPowerBackend * p1, uint64_t * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,246u,a,3u,0);
}
/* driver_cpu_power.Context.unregister -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_unregister(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint64_t p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,247u,a,2u,0);
}
/* driver_cpu_power.Context.currentCpu -> u32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_currentCpu(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0) {
 (void)reserved; R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,248u,a,1u,0);
}
/* driver_cpu_power.Context.capabilities -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_capabilities(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint32_t p1, R4CpuCapabilitiesInfo * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,249u,a,3u,0);
}
/* driver_cpu_power.Context.topology -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_topology(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint32_t p1, R4CpuTopologyInfo * p2) {
 (void)reserved; R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.ptr=(void *)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,250u,a,3u,0);
}
/* driver_cpu_power.Context.registerRead -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_registerRead(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint32_t p1, uint64_t p2, uint32_t p3, R4CpuRegisterInfo * p4) {
 (void)reserved; R4SdkDriverSlot a[5]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDRIVER_PRESENT};
 a[4] = (R4SdkDriverSlot){.ptr=(void *)p4,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,251u,a,5u,0);
}
/* driver_cpu_power.Context.clock -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_clock(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, R4MonotonicClockInfo * p1) {
 (void)reserved; R4SdkDriverSlot a[2]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.ptr=(void *)p1,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,252u,a,2u,0);
}
/* driver_cpu_power.Context.countersRead -> i32 */
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_countersRead(uint32_t reserved, const R4SdkDriverCpuPowerContext * p0, uint32_t p1, uint64_t p2, R4CpuPowerCounters * p3) {
 (void)reserved; R4SdkDriverSlot a[4]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 a[3] = (R4SdkDriverSlot){.ptr=(void *)p3,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverInvoke(R4SdkDriver_ABI_FINGERPRINT,253u,a,4u,0);
}
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_constructNative(R4SdkDriverSharedDmaBuffer *output, const R4DmaBuffer * p0, uint32_t p2) {
 R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1].flags=R4SDKDRIVER_DEFAULT;
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,0u,a,3u,output);
}
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_from_fields(R4SdkDriverSharedDmaBuffer *output, const R4DmaBuffer * p0, uint32_t p1, uint32_t p2) {
 R4SdkDriverSlot a[3]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 a[1] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDRIVER_PRESENT};
 a[2] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,0u,a,3u,output);
}
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_get_region(const R4SdkDriverSharedDmaBuffer *self, R4DmaBuffer *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,0u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_set_region(R4SdkDriverSharedDmaBuffer *self, const R4DmaBuffer * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,0u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_get_references(const R4SdkDriverSharedDmaBuffer *self) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,0u,1u,(void *)self,0,0); }
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_set_references(R4SdkDriverSharedDmaBuffer *self, uint32_t p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,0u,1u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_get_payload_bytes(const R4SdkDriverSharedDmaBuffer *self) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,0u,2u,(void *)self,0,0); }
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_set_payload_bytes(R4SdkDriverSharedDmaBuffer *self, uint32_t p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,0u,2u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverSharedDmaBuffer_inspectNative(const R4SdkDriverSharedDmaBuffer *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,0u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriver2Context_create(R4SdkDriver2Context *output, const R4DriverApi2 * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,2u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriver2Context_from_fields(R4SdkDriver2Context *output, const R4DriverApi2 * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,2u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriver2Context_get_api(const R4SdkDriver2Context *self) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,2u,0u,(void *)self,0,0); }
static inline R4SdkDriverSlot R4SdkDriver2Context_set_api(R4SdkDriver2Context *self, const R4DriverApi2 * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,2u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriver2Context_inspectNative(const R4SdkDriver2Context *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,2u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue3_create(R4SdkDriverNativeValue3 *output, const R4DriverApi2 * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,3u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue3_inspectNative(const R4SdkDriverNativeValue3 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,3u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverSerialContext_create(R4SdkDriverSerialContext *output, const R4DriverSerialApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,5u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverSerialContext_from_fields(R4SdkDriverSerialContext *output, const R4DriverSerialApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,5u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverSerialContext_get_table(const R4SdkDriverSerialContext *self, R4DriverSerialApi *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,5u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverSerialContext_set_table(R4SdkDriverSerialContext *self, const R4DriverSerialApi * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,5u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverSerialContext_inspectNative(const R4SdkDriverSerialContext *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,5u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_create(R4SdkDriverMemoryContext *output, const R4GfxDriverMemoryApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,7u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_from_fields(R4SdkDriverMemoryContext *output, const R4GfxDriverMemoryApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,7u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_get_table(const R4SdkDriverMemoryContext *self, R4GfxDriverMemoryApi *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,7u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_set_table(R4SdkDriverMemoryContext *self, const R4GfxDriverMemoryApi * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,7u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverMemoryContext_inspectNative(const R4SdkDriverMemoryContext *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,7u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverEntropyContext_create(R4SdkDriverEntropyContext *output, const R4DriverEntropyApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,9u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverEntropyContext_from_fields(R4SdkDriverEntropyContext *output, const R4DriverEntropyApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,9u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverEntropyContext_get_table(const R4SdkDriverEntropyContext *self, R4DriverEntropyApi *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,9u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverEntropyContext_set_table(R4SdkDriverEntropyContext *self, const R4DriverEntropyApi * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,9u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverEntropyContext_inspectNative(const R4SdkDriverEntropyContext *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,9u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_create(R4SdkDriverResourcesContext *output, const R4DriverResourceApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,11u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_from_fields(R4SdkDriverResourcesContext *output, const R4DriverResourceApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,11u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_get_table(const R4SdkDriverResourcesContext *self, R4DriverResourceApi *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,11u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_set_table(R4SdkDriverResourcesContext *self, const R4DriverResourceApi * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,11u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverResourcesContext_inspectNative(const R4SdkDriverResourcesContext *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,11u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverResourcesPlatform_create(R4SdkDriverResourcesPlatform *output, const R4DriverPlatformApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,13u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverResourcesPlatform_from_fields(R4SdkDriverResourcesPlatform *output, const R4DriverPlatformApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,13u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverResourcesPlatform_get_table(const R4SdkDriverResourcesPlatform *self, R4DriverPlatformApi *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,13u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverResourcesPlatform_set_table(R4SdkDriverResourcesPlatform *self, const R4DriverPlatformApi * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,13u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverResourcesPlatform_inspectNative(const R4SdkDriverResourcesPlatform *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,13u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverQueueContext_create(R4SdkDriverQueueContext *output, const R4GfxDriverQueueApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,15u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverQueueContext_from_fields(R4SdkDriverQueueContext *output, const R4GfxDriverQueueApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,15u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverQueueContext_get_table(const R4SdkDriverQueueContext *self, R4GfxDriverQueueApi *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,15u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverQueueContext_set_table(R4SdkDriverQueueContext *self, const R4GfxDriverQueueApi * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,15u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverQueueContext_inspectNative(const R4SdkDriverQueueContext *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,15u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_create(R4SdkDriverOutputsContext *output, const R4GfxDriverOutputApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,17u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_from_fields(R4SdkDriverOutputsContext *output, const R4GfxDriverOutputApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,17u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_get_table(const R4SdkDriverOutputsContext *self, R4GfxDriverOutputApi *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,17u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_set_table(R4SdkDriverOutputsContext *self, const R4GfxDriverOutputApi * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,17u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverOutputsContext_inspectNative(const R4SdkDriverOutputsContext *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,17u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_create(R4SdkDriverDisplayContext *output, const R4GfxDriverDisplayApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,19u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_from_fields(R4SdkDriverDisplayContext *output, const R4GfxDriverDisplayApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,19u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_get_table(const R4SdkDriverDisplayContext *self, R4GfxDriverDisplayApi *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,19u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_set_table(R4SdkDriverDisplayContext *self, const R4GfxDriverDisplayApi * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,19u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverDisplayContext_inspectNative(const R4SdkDriverDisplayContext *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,19u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverHeapContext_create(R4SdkDriverHeapContext *output, const R4DriverHeapApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,21u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverHeapContext_from_fields(R4SdkDriverHeapContext *output, const R4DriverHeapApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,21u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverHeapContext_get_table(const R4SdkDriverHeapContext *self, R4DriverHeapApi *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,21u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverHeapContext_set_table(R4SdkDriverHeapContext *self, const R4DriverHeapApi * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,21u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverHeapContext_inspectNative(const R4SdkDriverHeapContext *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,21u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_create(R4SdkDriverThreadsContext *output, const R4DriverThreadApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,23u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_from_fields(R4SdkDriverThreadsContext *output, const R4DriverThreadApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,23u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_get_table(const R4SdkDriverThreadsContext *self, R4DriverThreadApi *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,23u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_set_table(R4SdkDriverThreadsContext *self, const R4DriverThreadApi * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,23u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverThreadsContext_inspectNative(const R4SdkDriverThreadsContext *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,23u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverSemaphoresContext_constructNative(R4SdkDriverSemaphoresContext *output, const R4DriverSemaphoreApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,25u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverSemaphoresContext_from_fields(R4SdkDriverSemaphoresContext *output, const R4DriverSemaphoreApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,25u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverSemaphoresContext_get_table(const R4SdkDriverSemaphoresContext *self, R4DriverSemaphoreApi *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,25u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverSemaphoresContext_set_table(R4SdkDriverSemaphoresContext *self, const R4DriverSemaphoreApi * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,25u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverSemaphoresContext_inspectNative(const R4SdkDriverSemaphoresContext *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,25u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_create(R4SdkDriverCpuPowerContext *output, const R4DriverCpuPowerApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,27u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_from_fields(R4SdkDriverCpuPowerContext *output, const R4DriverCpuPowerApi * p0) {
 R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,27u,a,1u,output);
}
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_get_table(const R4SdkDriverCpuPowerContext *self, R4DriverCpuPowerApi *output) { return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,27u,0u,(void *)self,0,output); }
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_set_table(R4SdkDriverCpuPowerContext *self, const R4DriverCpuPowerApi * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverField(R4SdkDriver_ABI_FINGERPRINT,27u,0u,self,a,0); }
static inline R4SdkDriverSlot R4SdkDriverCpuPowerContext_inspectNative(const R4SdkDriverCpuPowerContext *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,27u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue29_create(R4SdkDriverNativeValue29 *output, const R4SdkDriver2Context * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,29u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue29_inspectNative(const R4SdkDriverNativeValue29 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,29u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue30_create(R4SdkDriverNativeValue30 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,30u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue30_inspectNative(const R4SdkDriverNativeValue30 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,30u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue31_create(R4SdkDriverNativeValue31 *output, R4SdkDriverSharedDmaBuffer * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,31u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue31_inspectNative(const R4SdkDriverNativeValue31 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,31u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue32_create(R4SdkDriverNativeValue32 *output, const R4SdkDriverSharedDmaBuffer * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,32u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue32_inspectNative(const R4SdkDriverNativeValue32 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,32u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue35_create(R4SdkDriverNativeValue35 *output, const R4AudioBackend2 * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,35u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue35_inspectNative(const R4SdkDriverNativeValue35 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,35u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue37_create(R4SdkDriverNativeValue37 *output, const R4SynthEngine * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,37u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue37_inspectNative(const R4SdkDriverNativeValue37 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,37u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue39_create(R4SdkDriverNativeValue39 *output, const R4DriverWorkRequest * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,39u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue39_inspectNative(const R4SdkDriverNativeValue39 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,39u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue41_create(R4SdkDriverNativeValue41 *output, uint32_t * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,41u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue41_inspectNative(const R4SdkDriverNativeValue41 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,41u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue42_create(R4SdkDriverNativeValue42 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,42u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue42_inspectNative(const R4SdkDriverNativeValue42 *self, R4SdkDriverOutputsContext *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,42u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue43_create(R4SdkDriverNativeValue43 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,43u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue43_inspectNative(const R4SdkDriverNativeValue43 *self, R4SdkDriverDisplayContext *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,43u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue44_create(R4SdkDriverNativeValue44 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,44u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue44_inspectNative(const R4SdkDriverNativeValue44 *self, R4SdkDriverQueueContext *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,44u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue45_create(R4SdkDriverNativeValue45 *output, const R4DisplayBlitBackend * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,45u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue45_inspectNative(const R4SdkDriverNativeValue45 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,45u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue47_create(R4SdkDriverNativeValue47 *output, const R4UsbHostController * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,47u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue47_inspectNative(const R4SdkDriverNativeValue47 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,47u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue49_create(R4SdkDriverNativeValue49 *output, const R4DmaMapping * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,49u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue49_inspectNative(const R4SdkDriverNativeValue49 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,49u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue51_create(R4SdkDriverNativeValue51 *output, R4IrqStats * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,51u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue51_inspectNative(const R4SdkDriverNativeValue51 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,51u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue53_create(R4SdkDriverNativeValue53 *output, R4DriverWorkSummary * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,53u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue53_inspectNative(const R4SdkDriverNativeValue53 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,53u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue55_create(R4SdkDriverNativeValue55 *output, R4MonotonicClockInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,55u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue55_inspectNative(const R4SdkDriverNativeValue55 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,55u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue57_create(R4SdkDriverNativeValue57 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,57u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue57_inspectNative(const R4SdkDriverNativeValue57 *self, R4SdkDriverHeapContext *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,57u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue58_create(R4SdkDriverNativeValue58 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,58u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue58_inspectNative(const R4SdkDriverNativeValue58 *self, R4SdkDriverResourcesContext *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,58u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue59_create(R4SdkDriverNativeValue59 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,59u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue59_inspectNative(const R4SdkDriverNativeValue59 *self, R4SdkDriverThreadsContext *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,59u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue60_create(R4SdkDriverNativeValue60 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,60u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue60_inspectNative(const R4SdkDriverNativeValue60 *self, R4SdkDriverSemaphoresContext *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,60u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue61_create(R4SdkDriverNativeValue61 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,61u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue61_inspectNative(const R4SdkDriverNativeValue61 *self, R4SdkDriverSerialContext *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,61u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue62_create(R4SdkDriverNativeValue62 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,62u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue62_inspectNative(const R4SdkDriverNativeValue62 *self, R4SdkDriverMemoryContext *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,62u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue63_create(R4SdkDriverNativeValue63 *output, const R4NetBackend * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,63u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue63_inspectNative(const R4SdkDriverNativeValue63 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,63u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue66_create(R4SdkDriverNativeValue66 *output, R4NetBackendNegotiation * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,66u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue66_inspectNative(const R4SdkDriverNativeValue66 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,66u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue68_create(R4SdkDriverNativeValue68 *output, const R4NetPacket * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,68u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue68_inspectNative(const R4SdkDriverNativeValue68 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,68u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue70_create(R4SdkDriverNativeValue70 *output, R4PciDeviceInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,70u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue70_inspectNative(const R4SdkDriverNativeValue70 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,70u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue72_create(R4SdkDriverNativeValue72 *output, R4DmaBuffer * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,72u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue72_inspectNative(const R4SdkDriverNativeValue72 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,72u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue73_create(R4SdkDriverNativeValue73 *output, R4DriverCompletionStatus * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,73u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue73_inspectNative(const R4SdkDriverNativeValue73 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,73u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue75_create(R4SdkDriverNativeValue75 *output, int32_t * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,75u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue75_inspectNative(const R4SdkDriverNativeValue75 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,75u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue76_create(R4SdkDriverNativeValue76 *output, const R4DmaPinnedBuffer * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,76u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue76_inspectNative(const R4SdkDriverNativeValue76 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,76u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue78_create(R4SdkDriverNativeValue78 *output, const R4DmaConstraints * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,78u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue78_inspectNative(const R4SdkDriverNativeValue78 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,78u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue80_create(R4SdkDriverNativeValue80 *output, R4DmaMapping * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,80u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue80_inspectNative(const R4SdkDriverNativeValue80 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,80u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue81_create(R4SdkDriverNativeValue81 *output, R4MmioRegion * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,81u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue81_inspectNative(const R4SdkDriverNativeValue81 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,81u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue83_create(R4SdkDriverNativeValue83 *output, R4DmaPinnedBuffer * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,83u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue83_inspectNative(const R4SdkDriverNativeValue83 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,83u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue84_create(R4SdkDriverNativeValue84 *output, const R4StorageBackend * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,84u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue84_inspectNative(const R4SdkDriverNativeValue84 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,84u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue86_create(R4SdkDriverNativeValue86 *output, const R4SdkDriverSerialContext * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,86u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue86_inspectNative(const R4SdkDriverNativeValue86 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,86u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue87_create(R4SdkDriverNativeValue87 *output, const R4SerialBackend * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,87u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue87_inspectNative(const R4SdkDriverNativeValue87 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,87u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue89_create(R4SdkDriverNativeValue89 *output, uint64_t * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,89u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue89_inspectNative(const R4SdkDriverNativeValue89 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,89u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue90_create(R4SdkDriverNativeValue90 *output, const R4SdkDriverMemoryContext * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,90u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue90_inspectNative(const R4SdkDriverNativeValue90 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,90u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue91_create(R4SdkDriverNativeValue91 *output, const R4GfxTelemetryState * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,91u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue91_inspectNative(const R4SdkDriverNativeValue91 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,91u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue93_create(R4SdkDriverNativeValue93 *output, R4GfxTelemetryDemand * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,93u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue93_inspectNative(const R4SdkDriverNativeValue93 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,93u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue95_create(R4SdkDriverNativeValue95 *output, const R4GfxDeviceBudgetRequest * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,95u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue95_inspectNative(const R4SdkDriverNativeValue95 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,95u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue97_create(R4SdkDriverNativeValue97 *output, R4GfxDeviceBudgetState * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,97u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue97_inspectNative(const R4SdkDriverNativeValue97 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,97u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue99_create(R4SdkDriverNativeValue99 *output, const R4GfxNativeProvider * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,99u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue99_inspectNative(const R4SdkDriverNativeValue99 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,99u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue101_create(R4SdkDriverNativeValue101 *output, R4GfxBufferHandle * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,101u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue101_inspectNative(const R4SdkDriverNativeValue101 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,101u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue103_create(R4SdkDriverNativeValue103 *output, const R4GfxBufferHandle * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,103u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue103_inspectNative(const R4SdkDriverNativeValue103 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,103u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue104_create(R4SdkDriverNativeValue104 *output, R4GfxVirtualJob * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,104u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue104_inspectNative(const R4SdkDriverNativeValue104 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,104u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue106_create(R4SdkDriverNativeValue106 *output, const R4GfxVirtualCompletion * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,106u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue106_inspectNative(const R4SdkDriverNativeValue106 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,106u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue108_create(R4SdkDriverNativeValue108 *output, R4GfxNativeJob * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,108u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue108_inspectNative(const R4SdkDriverNativeValue108 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,108u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue110_create(R4SdkDriverNativeValue110 *output, const R4GfxBufferDescriptor * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,110u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue110_inspectNative(const R4SdkDriverNativeValue110 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,110u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue112_create(R4SdkDriverNativeValue112 *output, R4GfxBufferReference * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,112u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue112_inspectNative(const R4SdkDriverNativeValue112 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,112u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue114_create(R4SdkDriverNativeValue114 *output, R4GfxBufferDescriptor * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,114u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue114_inspectNative(const R4SdkDriverNativeValue114 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,114u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue115_create(R4SdkDriverNativeValue115 *output, R4GfxBufferMap * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,115u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue115_inspectNative(const R4SdkDriverNativeValue115 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,115u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue117_create(R4SdkDriverNativeValue117 *output, const R4GfxDeviceRequest * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,117u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue117_inspectNative(const R4SdkDriverNativeValue117 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,117u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue119_create(R4SdkDriverNativeValue119 *output, R4GfxDeviceLease * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,119u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue119_inspectNative(const R4SdkDriverNativeValue119 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,119u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue121_create(R4SdkDriverNativeValue121 *output, const R4GfxDeviceLease * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,121u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue121_inspectNative(const R4SdkDriverNativeValue121 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,121u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue122_create(R4SdkDriverNativeValue122 *output, R4GfxDmaSegment * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,122u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue122_inspectNative(const R4SdkDriverNativeValue122 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,122u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue124_create(R4SdkDriverNativeValue124 *output, const R4GfxMmioRequest * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,124u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue124_inspectNative(const R4SdkDriverNativeValue124 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,124u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue126_create(R4SdkDriverNativeValue126 *output, R4GfxMmioWindow * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,126u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue126_inspectNative(const R4SdkDriverNativeValue126 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,126u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue128_create(R4SdkDriverNativeValue128 *output, R4GfxBufferStats * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,128u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue128_inspectNative(const R4SdkDriverNativeValue128 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,128u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue130_create(R4SdkDriverNativeValue130 *output, R4GfxOwnedBufferReservation * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,130u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue130_inspectNative(const R4SdkDriverNativeValue130 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,130u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue132_create(R4SdkDriverNativeValue132 *output, const R4GfxOwnedBufferReservation * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,132u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue132_inspectNative(const R4SdkDriverNativeValue132 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,132u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue133_create(R4SdkDriverNativeValue133 *output, R4GfxOwnedBufferRelease * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,133u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue133_inspectNative(const R4SdkDriverNativeValue133 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,133u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue135_create(R4SdkDriverNativeValue135 *output, const R4GfxOwnedBufferRelease * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,135u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue135_inspectNative(const R4SdkDriverNativeValue135 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,135u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue136_create(R4SdkDriverNativeValue136 *output, const R4SdkDriverEntropyContext * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,136u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue136_inspectNative(const R4SdkDriverNativeValue136 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,136u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue137_create(R4SdkDriverNativeValue137 *output, const R4EntropyBackend * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,137u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue137_inspectNative(const R4SdkDriverNativeValue137 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,137u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue139_create(R4SdkDriverNativeValue139 *output, const R4SdkDriverResourcesContext * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,139u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue139_inspectNative(const R4SdkDriverNativeValue139 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,139u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue140_create(R4SdkDriverNativeValue140 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,140u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue140_inspectNative(const R4SdkDriverNativeValue140 *self, R4SdkDriverEntropyContext *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,140u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue141_create(R4SdkDriverNativeValue141 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,141u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue141_inspectNative(const R4SdkDriverNativeValue141 *self, R4SdkDriverCpuPowerContext *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,141u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue142_create(R4SdkDriverNativeValue142 *output, R4SdkDriverSlot p0) { R4SdkDriverSlot a[1]={0};
 a[0] = p0;
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,142u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue142_inspectNative(const R4SdkDriverNativeValue142 *self, R4SdkDriverResourcesPlatform *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,142u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue143_create(R4SdkDriverNativeValue143 *output, const R4SdkDriverNativeValue143 * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,143u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue143_inspectNative(const R4SdkDriverNativeValue143 *self, R4SdkDriverNativeValue143 *output) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,143u,(void *)self,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue144_create(R4SdkDriverNativeValue144 *output, R4DriverFirmwareTableInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,144u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue144_inspectNative(const R4SdkDriverNativeValue144 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,144u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue146_create(R4SdkDriverNativeValue146 *output, R4DriverResourceInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,146u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue146_inspectNative(const R4SdkDriverNativeValue146 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,146u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue148_create(R4SdkDriverNativeValue148 *output, const R4SdkDriverResourcesPlatform * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,148u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue148_inspectNative(const R4SdkDriverNativeValue148 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,148u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue150_create(R4SdkDriverNativeValue150 *output, const R4SdkDriverQueueContext * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,150u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue150_inspectNative(const R4SdkDriverNativeValue150 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,150u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue151_create(R4SdkDriverNativeValue151 *output, const R4GfxBackendBinding * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,151u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue151_inspectNative(const R4SdkDriverNativeValue151 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,151u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue153_create(R4SdkDriverNativeValue153 *output, R4GfxQueueOwnerInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,153u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue153_inspectNative(const R4SdkDriverNativeValue153 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,153u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue155_create(R4SdkDriverNativeValue155 *output, const R4GfxFence * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,155u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue155_inspectNative(const R4SdkDriverNativeValue155 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,155u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue157_create(R4SdkDriverNativeValue157 *output, R4GfxRenderColorList * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,157u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue157_inspectNative(const R4SdkDriverNativeValue157 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,157u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue159_create(R4SdkDriverNativeValue159 *output, R4GfxRenderGridList * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,159u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue159_inspectNative(const R4SdkDriverNativeValue159 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,159u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue161_create(R4SdkDriverNativeValue161 *output, R4GfxRenderList * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,161u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue161_inspectNative(const R4SdkDriverNativeValue161 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,161u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue163_create(R4SdkDriverNativeValue163 *output, const R4GfxBackendRegistration * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,163u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue163_inspectNative(const R4SdkDriverNativeValue163 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,163u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue165_create(R4SdkDriverNativeValue165 *output, const R4GfxBackendProfile * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,165u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue165_inspectNative(const R4SdkDriverNativeValue165 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,165u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue167_create(R4SdkDriverNativeValue167 *output, R4GfxBackendBinding * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,167u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue167_inspectNative(const R4SdkDriverNativeValue167 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,167u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue168_create(R4SdkDriverNativeValue168 *output, const R4GfxBackendProperties * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,168u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue168_inspectNative(const R4SdkDriverNativeValue168 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,168u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue170_create(R4SdkDriverNativeValue170 *output, R4GfxNativeJobInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,170u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue170_inspectNative(const R4SdkDriverNativeValue170 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,170u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue172_create(R4SdkDriverNativeValue172 *output, R4GfxNativeBinding * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,172u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue172_inspectNative(const R4SdkDriverNativeValue172 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,172u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue174_create(R4SdkDriverNativeValue174 *output, R4GfxDriverJob * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,174u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue174_inspectNative(const R4SdkDriverNativeValue174 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,174u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue176_create(R4SdkDriverNativeValue176 *output, const R4SdkDriverOutputsContext * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,176u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue176_inspectNative(const R4SdkDriverNativeValue176 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,176u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue177_create(R4SdkDriverNativeValue177 *output, const R4GfxOutputPower * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,177u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue177_inspectNative(const R4SdkDriverNativeValue177 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,177u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue179_create(R4SdkDriverNativeValue179 *output, const R4GfxOutputId * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,179u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue179_inspectNative(const R4SdkDriverNativeValue179 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,179u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue181_create(R4SdkDriverNativeValue181 *output, R4GfxPowerRequest * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,181u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue181_inspectNative(const R4SdkDriverNativeValue181 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,181u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue183_create(R4SdkDriverNativeValue183 *output, const R4GfxOutputBrightness * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,183u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue183_inspectNative(const R4SdkDriverNativeValue183 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,183u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue185_create(R4SdkDriverNativeValue185 *output, R4GfxBrightnessRequest * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,185u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue185_inspectNative(const R4SdkDriverNativeValue185 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,185u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue187_create(R4SdkDriverNativeValue187 *output, const R4GfxOutputRefresh * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,187u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue187_inspectNative(const R4SdkDriverNativeValue187 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,187u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue189_create(R4SdkDriverNativeValue189 *output, const R4GfxOutputTarget * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,189u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue189_inspectNative(const R4SdkDriverNativeValue189 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,189u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue191_create(R4SdkDriverNativeValue191 *output, R4GfxRefreshRequest * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,191u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue191_inspectNative(const R4SdkDriverNativeValue191 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,191u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue193_create(R4SdkDriverNativeValue193 *output, R4GfxDriverModeColor * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,193u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue193_inspectNative(const R4SdkDriverNativeValue193 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,193u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue195_create(R4SdkDriverNativeValue195 *output, const R4GfxOutputColorState * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,195u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue195_inspectNative(const R4SdkDriverNativeValue195 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,195u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue197_create(R4SdkDriverNativeValue197 *output, const R4GfxAtomicState * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,197u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue197_inspectNative(const R4SdkDriverNativeValue197 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,197u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue199_create(R4SdkDriverNativeValue199 *output, R4GfxModeStatus * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,199u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue199_inspectNative(const R4SdkDriverNativeValue199 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,199u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue201_create(R4SdkDriverNativeValue201 *output, const R4GfxAudioRoute * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,201u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue201_inspectNative(const R4SdkDriverNativeValue201 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,201u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue203_create(R4SdkDriverNativeValue203 *output, R4GfxAudioRoute * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,203u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue203_inspectNative(const R4SdkDriverNativeValue203 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,203u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue204_create(R4SdkDriverNativeValue204 *output, R4GfxDriverModeJob * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,204u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue204_inspectNative(const R4SdkDriverNativeValue204 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,204u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue206_create(R4SdkDriverNativeValue206 *output, const R4GfxDriverModeCompletion * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,206u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue206_inspectNative(const R4SdkDriverNativeValue206 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,206u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue208_create(R4SdkDriverNativeValue208 *output, R4GfxReceiverSource * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,208u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue208_inspectNative(const R4SdkDriverNativeValue208 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,208u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue210_create(R4SdkDriverNativeValue210 *output, const R4GfxReceiverUpdate * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,210u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue210_inspectNative(const R4SdkDriverNativeValue210 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,210u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue212_create(R4SdkDriverNativeValue212 *output, const R4GfxReceiverSource * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,212u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue212_inspectNative(const R4SdkDriverNativeValue212 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,212u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue213_create(R4SdkDriverNativeValue213 *output, const R4GfxOutputPublication * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,213u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue213_inspectNative(const R4SdkDriverNativeValue213 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,213u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue215_create(R4SdkDriverNativeValue215 *output, R4GfxOutputId * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,215u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue215_inspectNative(const R4SdkDriverNativeValue215 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,215u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue216_create(R4SdkDriverNativeValue216 *output, const R4SdkDriverDisplayContext * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,216u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue216_inspectNative(const R4SdkDriverNativeValue216 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,216u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue217_create(R4SdkDriverNativeValue217 *output, R4GfxNativeState * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,217u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue217_inspectNative(const R4SdkDriverNativeValue217 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,217u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue219_create(R4SdkDriverNativeValue219 *output, const R4GfxNativeRegistration * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,219u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue219_inspectNative(const R4SdkDriverNativeValue219 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,219u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue221_create(R4SdkDriverNativeValue221 *output, const R4GfxAdditionalOutput * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,221u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue221_inspectNative(const R4SdkDriverNativeValue221 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,221u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue223_create(R4SdkDriverNativeValue223 *output, R4GfxOutputTarget * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,223u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue223_inspectNative(const R4SdkDriverNativeValue223 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,223u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue224_create(R4SdkDriverNativeValue224 *output, const R4DisplayCursorInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,224u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue224_inspectNative(const R4SdkDriverNativeValue224 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,224u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue226_create(R4SdkDriverNativeValue226 *output, R4GfxDriverCursorJob * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,226u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue226_inspectNative(const R4SdkDriverNativeValue226 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,226u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue228_create(R4SdkDriverNativeValue228 *output, const R4GfxDriverCursorCompletion * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,228u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue228_inspectNative(const R4SdkDriverNativeValue228 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,228u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue230_create(R4SdkDriverNativeValue230 *output, const R4DisplayPresentationInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,230u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue230_inspectNative(const R4SdkDriverNativeValue230 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,230u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue232_create(R4SdkDriverNativeValue232 *output, const R4DisplayPresentationStats * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,232u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue232_inspectNative(const R4SdkDriverNativeValue232 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,232u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue234_create(R4SdkDriverNativeValue234 *output, const R4GfxBootHoldRequest * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,234u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue234_inspectNative(const R4SdkDriverNativeValue234 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,234u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue236_create(R4SdkDriverNativeValue236 *output, R4GfxNativeBootInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,236u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue236_inspectNative(const R4SdkDriverNativeValue236 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,236u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue238_create(R4SdkDriverNativeValue238 *output, const R4SdkDriverHeapContext * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,238u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue238_inspectNative(const R4SdkDriverNativeValue238 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,238u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue239_create(R4SdkDriverNativeValue239 *output, R4DriverHeapAllocation * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,239u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue239_inspectNative(const R4SdkDriverNativeValue239 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,239u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue241_create(R4SdkDriverNativeValue241 *output, R4DriverHeapStats * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,241u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue241_inspectNative(const R4SdkDriverNativeValue241 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,241u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue243_create(R4SdkDriverNativeValue243 *output, const R4SdkDriverThreadsContext * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,243u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue243_inspectNative(const R4SdkDriverNativeValue243 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,243u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue244_create(R4SdkDriverNativeValue244 *output, R4DriverThreadStatus * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,244u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue244_inspectNative(const R4SdkDriverNativeValue244 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,244u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue246_create(R4SdkDriverNativeValue246 *output, R4DriverThreadStats * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,246u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue246_inspectNative(const R4SdkDriverNativeValue246 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,246u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue248_create(R4SdkDriverNativeValue248 *output, R4DriverThreadRequest * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,248u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue248_inspectNative(const R4SdkDriverNativeValue248 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,248u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue250_create(R4SdkDriverNativeValue250 *output, const R4SdkDriverSemaphoresContext * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,250u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue250_inspectNative(const R4SdkDriverNativeValue250 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,250u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue251_create(R4SdkDriverNativeValue251 *output, R4DriverSemaphoreStatus * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,251u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue251_inspectNative(const R4SdkDriverNativeValue251 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,251u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue253_create(R4SdkDriverNativeValue253 *output, R4DriverSemaphoreStats * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,253u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue253_inspectNative(const R4SdkDriverNativeValue253 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,253u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue255_create(R4SdkDriverNativeValue255 *output, const R4SdkDriverCpuPowerContext * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,255u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue255_inspectNative(const R4SdkDriverNativeValue255 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,255u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue256_create(R4SdkDriverNativeValue256 *output, const R4CpuIdleDescriptor * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,256u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue256_inspectNative(const R4SdkDriverNativeValue256 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,256u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue258_create(R4SdkDriverNativeValue258 *output, const R4CpuIdlePolicy * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,258u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue258_inspectNative(const R4SdkDriverNativeValue258 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,258u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue260_create(R4SdkDriverNativeValue260 *output, const R4CpuFirmwareBackend * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,260u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue260_inspectNative(const R4SdkDriverNativeValue260 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,260u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue262_create(R4SdkDriverNativeValue262 *output, const R4CpuPerformanceRequest * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,262u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue262_inspectNative(const R4SdkDriverNativeValue262 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,262u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue264_create(R4SdkDriverNativeValue264 *output, R4CpuFirmwareInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,264u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue264_inspectNative(const R4SdkDriverNativeValue264 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,264u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue266_create(R4SdkDriverNativeValue266 *output, R4CpuCapabilitiesInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,266u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue266_inspectNative(const R4SdkDriverNativeValue266 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,266u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue268_create(R4SdkDriverNativeValue268 *output, R4CpuFeatureInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,268u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue268_inspectNative(const R4SdkDriverNativeValue268 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,268u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue270_create(R4SdkDriverNativeValue270 *output, const R4CpuPerformanceBackend * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,270u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue270_inspectNative(const R4SdkDriverNativeValue270 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,270u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue272_create(R4SdkDriverNativeValue272 *output, R4CpuRegisterWriteInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,272u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue272_inspectNative(const R4SdkDriverNativeValue272 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,272u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue274_create(R4SdkDriverNativeValue274 *output, const R4CpuCppcBackend * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,274u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue274_inspectNative(const R4SdkDriverNativeValue274 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,274u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue276_create(R4SdkDriverNativeValue276 *output, const R4CpuPerformanceHint * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,276u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue276_inspectNative(const R4SdkDriverNativeValue276 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,276u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue278_create(R4SdkDriverNativeValue278 *output, const R4CpuPowerBackend * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,278u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue278_inspectNative(const R4SdkDriverNativeValue278 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,278u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue280_create(R4SdkDriverNativeValue280 *output, R4CpuTopologyInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,280u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue280_inspectNative(const R4SdkDriverNativeValue280 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,280u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue282_create(R4SdkDriverNativeValue282 *output, R4CpuRegisterInfo * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,282u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue282_inspectNative(const R4SdkDriverNativeValue282 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,282u,(void *)self,0); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue284_create(R4SdkDriverNativeValue284 *output, R4CpuPowerCounters * p0) { R4SdkDriverSlot a[1]={0};
 a[0] = (R4SdkDriverSlot){.ptr=(void *)p0,.flags=R4SDKDRIVER_PRESENT};
 return R4SdkDriverConstruct(R4SdkDriver_ABI_FINGERPRINT,284u,a,1u,output); }
static inline R4SdkDriverSlot R4SdkDriverNativeValue284_inspectNative(const R4SdkDriverNativeValue284 *self) { return R4SdkDriverInspect(R4SdkDriver_ABI_FINGERPRINT,284u,(void *)self,0); }
#endif
