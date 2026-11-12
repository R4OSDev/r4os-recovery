#ifndef R4OS_WIRE_HELPERS_H
#define R4OS_WIRE_HELPERS_H
#include "abi.h"

/* Static SDK helpers; no R4L, I/O, mapping/pinning or hardware completion.
 * Borrowed storage stays live, stable and separate from state/metadata.
 * Wire cursors never produce native record pointers. */
enum { R4_WIRE_LITTLE=0, R4_WIRE_BIG=1 };
enum { R4_WIRE_TRUNCATED=-1, R4_WIRE_CAPACITY=-2,
       R4_WIRE_LENGTH_OVERFLOW=-3, R4_WIRE_INVALID_BUFFER=-4,
       R4_WIRE_INVALID_STATE=-5, R4_WIRE_INVALID_MARK=-6,
       R4_WIRE_INVALID_ORDER=-7, R4_WIRE_INVALID_WIDTH=-8,
       R4_WIRE_VALUE_OVERFLOW=-9 };
typedef struct R4SdkWireSpan { uintptr_t address,length; } R4SdkWireSpan;
typedef struct R4SdkWireReader { uintptr_t address,length,position; } R4SdkWireReader;
typedef struct R4SdkWireWriter { uintptr_t address,length,position; } R4SdkWireWriter;
typedef struct R4SdkWireMark {
    uintptr_t address,length,position;
    uint32_t kind,reserved;
} R4SdkWireMark;
int32_t R4SdkWireReaderInit(const uint8_t *,uintptr_t,R4SdkWireReader *);
int32_t R4SdkWireWriterInit(uint8_t *,uintptr_t,R4SdkWireWriter *);
int32_t R4SdkWireTake(R4SdkWireReader *,uintptr_t,R4SdkWireSpan *);
/* width_bytes is exactly1/2/4/8, order is explicit; failures leave state,
 * output values and output bytes unchanged. Integer writes reject overflow. */
int32_t R4SdkWireReadInteger(R4SdkWireReader *,uint32_t width_bytes,uint32_t order,uint64_t *);
int32_t R4SdkWirePut(R4SdkWireWriter *,const uint8_t *,uintptr_t);
int32_t R4SdkWireWriteInteger(R4SdkWireWriter *,uint32_t width_bytes,uint32_t order,uint64_t);
int32_t R4SdkWireReaderMark(const R4SdkWireReader *,R4SdkWireMark *);
int32_t R4SdkWireWriterMark(const R4SdkWireWriter *,R4SdkWireMark *);
int32_t R4SdkWireReaderRestore(R4SdkWireReader *,R4SdkWireMark);
int32_t R4SdkWireWriterRestore(R4SdkWireWriter *,R4SdkWireMark);
/* Mark restores position only. Same span/direction may share a mark while
 * that exact storage loan remains valid; no allocation identity is inferred.
 * Writer put uses memmove semantics for overlapping source/destination. */

enum { R4_CHECKSUM_LENGTH_OVERFLOW=-1, R4_CHECKSUM_INVALID_STATE=-2,
       R4_CHECKSUM_INVALID_BUFFER=-3 };
typedef struct R4SdkChecksum16 {
    uint32_t sum;
    uint8_t pending,odd;
    uint16_t reserved;
    uint64_t bytes;
} R4SdkChecksum16;
int32_t R4SdkChecksumInit(R4SdkChecksum16 *);
int32_t R4SdkChecksumAdd(R4SdkChecksum16 *,const uint8_t *,uintptr_t);
int32_t R4SdkChecksumFinish(const R4SdkChecksum16 *,uint16_t *);
/* Non-mutating finish: repeated snapshots and later add are allowed. Odd
 * byte parity survives add boundaries. Protocol supplies explicit pseudo-
 * header bytes first and owns UDP zero mapping/offload validation. */

enum { R4_NATIVE_INPUT=0, R4_NATIVE_OUTPUT=1, R4_NATIVE_INOUT=2 };
enum { R4_NATIVE_EXACT=0, R4_NATIVE_PREFIX=1 };
enum { R4_NATIVE_NULL_BUFFER=-1, R4_NATIVE_TOO_SHORT=-2,
       R4_NATIVE_LENGTH_MISMATCH=-3, R4_NATIVE_MISALIGNED=-4,
       R4_NATIVE_UNSUPPORTED_VERSION=-5, R4_NATIVE_HEADER_SIZE=-6,
       R4_NATIVE_DIRECTION=-7, R4_NATIVE_FLAGS=-8,
       R4_NATIVE_POLICY=-9, R4_NATIVE_LENGTH_OVERFLOW=-10 };
typedef struct R4SdkNativePolicy {
    uintptr_t required_bytes,alignment;
    uint32_t version_offset,size_offset,expected_version,size_mode,direction,allowed_flags;
} R4SdkNativePolicy;
#define R4SDK_NATIVE_RECORD(T,dir,mode) ((R4SdkNativePolicy){sizeof(T),_Alignof(T),UINT32_MAX,UINT32_MAX,0u,(mode),(dir),0u})
/* version/size are native u32 fields, never network or packed wire headers. */
#define R4SDK_NATIVE_VERSIONED(T,ver,dir,mode) ((R4SdkNativePolicy){sizeof(T),_Alignof(T),offsetof(T,version),offsetof(T,size),(ver),(mode),(dir),0u})
int32_t R4SdkNativeAdmit(const R4ProtocolBuffer *,R4SdkNativePolicy,uint32_t access,uintptr_t *);
int32_t R4SdkNativePublish(R4ProtocolBuffer *,R4SdkNativePolicy,uint32_t written_bytes);
/* Admission validates declared bytes/alignment/version/direction/flags only.
 * Caller guarantees readable initialized native representation for input,
 * and header offsets designate actual initialized native u32 record fields,
 * never padding or unknown representation bytes. Caller also guarantees
 * exclusive valid output capacity and dispatch-limited storage lifetime.
 * Output admission never reads payload; publish reads only written_bytes
 * after caller initialized them and updates len only on success. Metadata
 * stays unchanged on failure. Flags are not direction or offload authority. */

enum { R4_BLOCK_EXACT=0, R4_BLOCK_AT_LEAST=1 };
enum { R4_BLOCK_ZERO_COUNT=-1, R4_BLOCK_UNKNOWN_GEOMETRY=-2,
       R4_BLOCK_UNSUPPORTED_SHAPE=-3, R4_BLOCK_OUT_OF_RANGE=-4,
       R4_BLOCK_LENGTH_MISMATCH=-5, R4_BLOCK_OVERFLOW=-6,
       R4_BLOCK_INVALID_BUFFER=-7 };
typedef struct R4SdkBlockLimits {
    uint64_t capacity_blocks,max_blocks,max_bytes;
    uint32_t lba_bits,buffer_mode;
} R4SdkBlockLimits;
typedef struct R4SdkBlockShape { uint64_t byte_count,last_lba; } R4SdkBlockShape;
int32_t R4SdkBlockTransfer(uint64_t lba,uint64_t count,uint64_t block_bytes,uint64_t buffer_bytes,R4SdkBlockLimits,R4SdkBlockShape *);
/* Positive known capacity/block size and explicit maxima; LBA bits are not
 * DMA address bits. Flush/unknown discovery/device policy stays in backend.
 * A shape never acknowledges I/O, mapping, DMA, pinning or device stop. */
_Static_assert(sizeof(R4SdkWireSpan)==16u,"wire span");
_Static_assert(sizeof(R4SdkWireReader)==24u,"wire reader");
_Static_assert(sizeof(R4SdkWireWriter)==24u,"wire writer");
_Static_assert(sizeof(R4SdkWireMark)==32u,"wire mark");
_Static_assert(sizeof(R4SdkChecksum16)==16u,"checksum state");
_Static_assert(sizeof(R4SdkNativePolicy)==40u,"native policy");
_Static_assert(sizeof(R4SdkBlockLimits)==32u,"block limits");
_Static_assert(sizeof(R4SdkBlockShape)==16u,"block shape");
#endif
