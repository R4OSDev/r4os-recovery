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
#ifndef R4SDKDATA_HELPERS_H
#define R4SDKDATA_HELPERS_H
#include "r4os/abi.h"
#include "r4os/generation2.h"
#define R4SDKDATA_PRESENT 1u
#define R4SDKDATA_NATIVE_ERROR 2u
#define R4SDKDATA_DEFAULT 4u
typedef struct R4SdkDataSlot { void *ptr; uint64_t length,bits; int32_t status; uint32_t flags; } R4SdkDataSlot;
R4SdkDataSlot R4SdkDataInvoke(uint64_t,uint32_t,const R4SdkDataSlot *,uint32_t,void *);
R4SdkDataSlot R4SdkDataConstruct(uint64_t,uint32_t,const R4SdkDataSlot *,uint32_t,void *);
R4SdkDataSlot R4SdkDataInspect(uint64_t,uint32_t,void *,void *);
R4SdkDataSlot R4SdkDataField(uint64_t,uint32_t,uint32_t,void *,const R4SdkDataSlot *,void *);
/* json.Token; native size 4, alignment 4. */
typedef struct R4SdkDataJsonToken { _Alignas(4) uint8_t opaque_bytes[4]; } R4SdkDataJsonToken;
#define R4SdkDataJsonToken_TYPE 0u
/* ?error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}; native size 2, alignment 2. */
typedef struct R4SdkDataNative_Value1 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value1;
#define R4SdkDataNative_Value1_TYPE 1u
/* json.Cursor; native size 56, alignment 8. */
typedef struct R4SdkDataJsonCursor { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkDataJsonCursor;
#define R4SdkDataJsonCursor_TYPE 2u
/* ?[*]const u8; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value3 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value3;
#define R4SdkDataNative_Value3_TYPE 3u
/* [*]const u8; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value4 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value4;
#define R4SdkDataNative_Value4_TYPE 4u
/* ?[*]u8; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value5 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value5;
#define R4SdkDataNative_Value5_TYPE 5u
/* [*]u8; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value6 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value6;
#define R4SdkDataNative_Value6_TYPE 6u
/* json.Request; native size 56, alignment 8. */
typedef struct R4SdkDataJsonRequest { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkDataJsonRequest;
#define R4SdkDataJsonRequest_TYPE 7u
/* ?*json.Cursor; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value8 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value8;
#define R4SdkDataNative_Value8_TYPE 8u
/* *json.Cursor; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value9 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value9;
#define R4SdkDataNative_Value9_TYPE 9u
/* json.Document; native size 64, alignment 8. */
typedef struct R4SdkDataJsonDocument { _Alignas(8) uint8_t opaque_bytes[64]; } R4SdkDataJsonDocument;
#define R4SdkDataJsonDocument_TYPE 10u
/* *const r4dev.Context; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value11 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value11;
#define R4SdkDataNative_Value11_TYPE 11u
/* r4dev.Context; native size 24, alignment 8. */
typedef struct R4SdkDataNative_r4dev_Context { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_r4dev_Context;
#define R4SdkDataNative_r4dev_Context_TYPE 12u
/* error{BadRequest,Bounds,Checksum,DuplicatePath,Inflate,InvalidArchive,Limit,OutputTooSmall,Stale,Unavailable,UnsafePath,Unsupported}!void; native size 2, alignment 2. */
typedef struct R4SdkDataNative_Value13 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value13;
#define R4SdkDataNative_Value13_TYPE 13u
/* zip.Info; native size 40, alignment 8. */
typedef struct R4SdkDataZipInfo { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkDataZipInfo;
#define R4SdkDataZipInfo_TYPE 14u
/* zip.Entry; native size 72, alignment 8. */
typedef struct R4SdkDataZipEntry { _Alignas(8) uint8_t opaque_bytes[72]; } R4SdkDataZipEntry;
#define R4SdkDataZipEntry_TYPE 15u
/* zip.Progress; native size 16, alignment 8. */
typedef struct R4SdkDataZipProgress { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataZipProgress;
#define R4SdkDataZipProgress_TYPE 16u
/* zip.Request; native size 80, alignment 8. */
typedef struct R4SdkDataZipRequest { _Alignas(8) uint8_t opaque_bytes[80]; } R4SdkDataZipRequest;
#define R4SdkDataZipRequest_TYPE 17u
/* ?[*]zip.Entry; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value18 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value18;
#define R4SdkDataNative_Value18_TYPE 18u
/* [*]zip.Entry; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value19 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value19;
#define R4SdkDataNative_Value19_TYPE 19u
/* ?*const zip.Entry; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value20 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value20;
#define R4SdkDataNative_Value20_TYPE 20u
/* *const zip.Entry; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value21 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value21;
#define R4SdkDataNative_Value21_TYPE 21u
/* ?[*]align(16) u8; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value22 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value22;
#define R4SdkDataNative_Value22_TYPE 22u
/* [*]align(16) u8; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value23 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value23;
#define R4SdkDataNative_Value23_TYPE 23u
/* zip.Work; native size 16384, alignment 16. */
typedef struct R4SdkDataZipWork { _Alignas(16) uint8_t opaque_bytes[16384]; } R4SdkDataZipWork;
#define R4SdkDataZipWork_TYPE 24u
/* [16384]u8; native size 16384, alignment 1. */
typedef struct R4SdkDataNative_Value25 { _Alignas(1) uint8_t opaque_bytes[16384]; } R4SdkDataNative_Value25;
#define R4SdkDataNative_Value25_TYPE 25u
/* zip.Context; native size 8, alignment 8. */
typedef struct R4SdkDataZipContext { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataZipContext;
#define R4SdkDataZipContext_TYPE 26u
/* ico.Directory; native size 2, alignment 2. */
typedef struct R4SdkDataIcoDirectory { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkDataIcoDirectory;
#define R4SdkDataIcoDirectory_TYPE 27u
/* ico.Entry; native size 20, alignment 4. */
typedef struct R4SdkDataIcoEntry { _Alignas(4) uint8_t opaque_bytes[20]; } R4SdkDataIcoEntry;
#define R4SdkDataIcoEntry_TYPE 28u
/* ico.BitmapImage; native size 56, alignment 8. */
typedef struct R4SdkDataIcoBitmapImage { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkDataIcoBitmapImage;
#define R4SdkDataIcoBitmapImage_TYPE 29u
/* ico.Pixel; native size 8, alignment 4. */
typedef struct R4SdkDataIcoPixel { _Alignas(4) uint8_t opaque_bytes[8]; } R4SdkDataIcoPixel;
#define R4SdkDataIcoPixel_TYPE 30u
/* []const u8; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value31 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value31;
#define R4SdkDataNative_Value31_TYPE 31u
/* error{BadDirectory,BadImage,NotIcon,Truncated,UnsupportedBpp,UnsupportedCompression}!ico.Directory; native size 4, alignment 2. */
typedef struct R4SdkDataNative_Value32 { _Alignas(2) uint8_t opaque_bytes[4]; } R4SdkDataNative_Value32;
#define R4SdkDataNative_Value32_TYPE 32u
/* error{BadDirectory,BadImage,NotIcon,Truncated,UnsupportedBpp,UnsupportedCompression}!ico.Entry; native size 24, alignment 4. */
typedef struct R4SdkDataNative_Value33 { _Alignas(4) uint8_t opaque_bytes[24]; } R4SdkDataNative_Value33;
#define R4SdkDataNative_Value33_TYPE 33u
/* error{BadDirectory,BadImage,NotIcon,Truncated,UnsupportedBpp,UnsupportedCompression}!ico.BitmapImage; native size 64, alignment 8. */
typedef struct R4SdkDataNative_Value34 { _Alignas(8) uint8_t opaque_bytes[64]; } R4SdkDataNative_Value34;
#define R4SdkDataNative_Value34_TYPE 34u
/* ?ico.Pixel; native size 12, alignment 4. */
typedef struct R4SdkDataNative_Value35 { _Alignas(4) uint8_t opaque_bytes[12]; } R4SdkDataNative_Value35;
#define R4SdkDataNative_Value35_TYPE 35u
/* []u32; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value36 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value36;
#define R4SdkDataNative_Value36_TYPE 36u
/* []u8; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value37 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value37;
#define R4SdkDataNative_Value37_TYPE 37u
/* raster.Image; native size 24, alignment 8. */
typedef struct R4SdkDataRasterImage { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataRasterImage;
#define R4SdkDataRasterImage_TYPE 38u
/* error{InvalidSize,TooLarge}!raster.Image; native size 32, alignment 8. */
typedef struct R4SdkDataNative_Value39 { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkDataNative_Value39;
#define R4SdkDataNative_Value39_TYPE 39u
/* error{InvalidSize,TooLarge}!usize; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value40 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value40;
#define R4SdkDataNative_Value40_TYPE 40u
/* secure_random.Provider; native size 32, alignment 8. */
typedef struct R4SdkDataRandomProvider { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkDataRandomProvider;
#define R4SdkDataRandomProvider_TYPE 41u
/* ?*const fn (*abi_generated.EntropySourceInfo) callconv(.c) i32; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value42 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value42;
#define R4SdkDataNative_Value42_TYPE 42u
/* ?*const fn ([*]u8, u32) callconv(.c) i32; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value43 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value43;
#define R4SdkDataNative_Value43_TYPE 43u
/* ?*const fn (*abi_generated.CpuAccelerationInfo) callconv(.c) i32; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value44 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value44;
#define R4SdkDataNative_Value44_TYPE 44u
/* ?*const fn (u32, u32, ?*const *const fn (u64, u32) callconv(.c) i32, u64, *abi_generated.CpuAccelerationWork) callconv(.c) i32; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value45 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value45;
#define R4SdkDataNative_Value45_TYPE 45u
/* *const program.Context; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value46 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value46;
#define R4SdkDataNative_Value46_TYPE 46u
/* program.Context; native size 24, alignment 8. */
typedef struct R4SdkDataNative_program_Context { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_program_Context;
#define R4SdkDataNative_program_Context_TYPE 47u
/* *const technical2_generated.ProtocolApi2; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value48 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value48;
#define R4SdkDataNative_Value48_TYPE 48u
/* *abi_generated.EntropySourceInfo; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value50 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value50;
#define R4SdkDataNative_Value50_TYPE 50u
/* *const abi_generated.CpuAccelerationWork; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value52 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value52;
#define R4SdkDataNative_Value52_TYPE 52u
/* cpu_memory.Policy; native size 1, alignment 1. */
typedef struct R4SdkDataMemoryPolicy { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataMemoryPolicy;
#define R4SdkDataMemoryPolicy_TYPE 54u
/* error{EntropyUnavailable,OutputTooSmall,UnsupportedAlgorithm}![]const u8; native size 24, alignment 8. */
typedef struct R4SdkDataNative_Value55 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_Value55;
#define R4SdkDataNative_Value55_TYPE 55u
/* web_encoding.Encoding; native size 1, alignment 1. */
typedef struct R4SdkDataEncodingEncoding { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataEncodingEncoding;
#define R4SdkDataEncodingEncoding_TYPE 56u
/* error{InputTooLarge,InvalidSequence,OutputTooSmall,UnknownEncoding}!web_encoding.Encoding; native size 4, alignment 2. */
typedef struct R4SdkDataNative_Value57 { _Alignas(2) uint8_t opaque_bytes[4]; } R4SdkDataNative_Value57;
#define R4SdkDataNative_Value57_TYPE 57u
/* web_encoding.EncodeIntoResult; native size 16, alignment 8. */
typedef struct R4SdkDataEncodingEncodeIntoResult { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataEncodingEncodeIntoResult;
#define R4SdkDataEncodingEncodeIntoResult_TYPE 58u
/* web_encoding.Decoder; native size 24, alignment 8. */
typedef struct R4SdkDataEncodingDecoder { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataEncodingDecoder;
#define R4SdkDataEncodingDecoder_TYPE 59u
/* [4]u8; native size 4, alignment 1. */
typedef struct R4SdkDataNative_Value60 { _Alignas(1) uint8_t opaque_bytes[4]; } R4SdkDataNative_Value60;
#define R4SdkDataNative_Value60_TYPE 60u
/* web_url.Parts; native size 144, alignment 8. */
typedef struct R4SdkDataUrlParts { _Alignas(8) uint8_t opaque_bytes[144]; } R4SdkDataUrlParts;
#define R4SdkDataUrlParts_TYPE 61u
/* error{InvalidUrl,PairLimit,TooLong}!web_url.Parts; native size 152, alignment 8. */
typedef struct R4SdkDataNative_Value62 { _Alignas(8) uint8_t opaque_bytes[152]; } R4SdkDataNative_Value62;
#define R4SdkDataNative_Value62_TYPE 62u
/* error{InvalidUrl,PairLimit,TooLong}![]u8; native size 24, alignment 8. */
typedef struct R4SdkDataNative_Value63 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_Value63;
#define R4SdkDataNative_Value63_TYPE 63u
/* *usize; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value64 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value64;
#define R4SdkDataNative_Value64_TYPE 64u
/* error{InvalidUrl,PairLimit,TooLong}!void; native size 2, alignment 2. */
typedef struct R4SdkDataNative_Value65 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value65;
#define R4SdkDataNative_Value65_TYPE 65u
/* web_url.Component; native size 1, alignment 1. */
typedef struct R4SdkDataUrlComponent { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataUrlComponent;
#define R4SdkDataUrlComponent_TYPE 66u
/* error{InvalidUrl,PairLimit,TooLong}![]const u8; native size 24, alignment 8. */
typedef struct R4SdkDataNative_Value67 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_Value67;
#define R4SdkDataNative_Value67_TYPE 67u
/* web_url.Pair; native size 8, alignment 2. */
typedef struct R4SdkDataUrlPair { _Alignas(2) uint8_t opaque_bytes[8]; } R4SdkDataUrlPair;
#define R4SdkDataUrlPair_TYPE 68u
/* web_url.SliceRef; native size 4, alignment 2. */
typedef struct R4SdkDataUrlSliceRef { _Alignas(2) uint8_t opaque_bytes[4]; } R4SdkDataUrlSliceRef;
#define R4SdkDataUrlSliceRef_TYPE 69u
/* web_url.SearchParams; native size 2064, alignment 8. */
typedef struct R4SdkDataUrlSearchParams { _Alignas(8) uint8_t opaque_bytes[2064]; } R4SdkDataUrlSearchParams;
#define R4SdkDataUrlSearchParams_TYPE 70u
/* [1534]u8; native size 1534, alignment 1. */
typedef struct R4SdkDataNative_Value71 { _Alignas(1) uint8_t opaque_bytes[1534]; } R4SdkDataNative_Value71;
#define R4SdkDataNative_Value71_TYPE 71u
/* [64]web_url.Pair; native size 512, alignment 2. */
typedef struct R4SdkDataNative_Value72 { _Alignas(2) uint8_t opaque_bytes[512]; } R4SdkDataNative_Value72;
#define R4SdkDataNative_Value72_TYPE 72u
/* r4cp.ModuleKind; native size 1, alignment 1. */
typedef struct R4SdkDataProjectModuleKind { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataProjectModuleKind;
#define R4SdkDataProjectModuleKind_TYPE 73u
/* r4cp.Language; native size 1, alignment 1. */
typedef struct R4SdkDataProjectLanguage { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataProjectLanguage;
#define R4SdkDataProjectLanguage_TYPE 74u
/* r4cp.ProfileClass; native size 1, alignment 1. */
typedef struct R4SdkDataProjectProfileClass { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataProjectProfileClass;
#define R4SdkDataProjectProfileClass_TYPE 75u
/* r4cp.Token; native size 32, alignment 8. */
typedef struct R4SdkDataProjectToken { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkDataProjectToken;
#define R4SdkDataProjectToken_TYPE 76u
/* r4cp.RenderResult; native size 24, alignment 8. */
typedef struct R4SdkDataProjectRenderResult { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataProjectRenderResult;
#define R4SdkDataProjectRenderResult_TYPE 77u
/* r4cp.ProjectTemplateValues; native size 112, alignment 8. */
typedef struct R4SdkDataProjectProjectTemplateValues { _Alignas(8) uint8_t opaque_bytes[112]; } R4SdkDataProjectProjectTemplateValues;
#define R4SdkDataProjectProjectTemplateValues_TYPE 78u
/* r4cp.Item; native size 32, alignment 8. */
typedef struct R4SdkDataProjectItem { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkDataProjectItem;
#define R4SdkDataProjectItem_TYPE 79u
/* r4cp.Project; native size 2064, alignment 8. */
typedef struct R4SdkDataProjectProject { _Alignas(8) uint8_t opaque_bytes[2064]; } R4SdkDataProjectProject;
#define R4SdkDataProjectProject_TYPE 80u
/* [12]r4cp.Item; native size 384, alignment 8. */
typedef struct R4SdkDataNative_Value81 { _Alignas(8) uint8_t opaque_bytes[384]; } R4SdkDataNative_Value81;
#define R4SdkDataNative_Value81_TYPE 81u
/* [16]r4cp.Item; native size 512, alignment 8. */
typedef struct R4SdkDataNative_Value82 { _Alignas(8) uint8_t opaque_bytes[512]; } R4SdkDataNative_Value82;
#define R4SdkDataNative_Value82_TYPE 82u
/* [8]r4cp.Item; native size 256, alignment 8. */
typedef struct R4SdkDataNative_Value83 { _Alignas(8) uint8_t opaque_bytes[256]; } R4SdkDataNative_Value83;
#define R4SdkDataNative_Value83_TYPE 83u
/* error{HostPathRejected,IncompatibleBuildProfile,InvalidArtifactPath,InvalidImport,InvalidKey,InvalidLanguage,InvalidLine,InvalidModuleKind,InvalidSectionHeader,InvalidSourcePath,InvalidTargetPath,KeyOutsideSection,MissingArtifact,MissingBuildProfile,MissingLanguage,MissingModuleKind,MissingProjectName,MissingR4XStart,MissingSource,MissingTargetPath,TooManyContracts,TooManyExports,TooManyImports,TooManyMetadata,TooManySources,UnknownImportGroup,UnsupportedBuildProfile}!r4cp.Project; native size 2072, alignment 8. */
typedef struct R4SdkDataNative_Value84 { _Alignas(8) uint8_t opaque_bytes[2072]; } R4SdkDataNative_Value84;
#define R4SdkDataNative_Value84_TYPE 84u
/* []const r4cp.Token; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value85 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value85;
#define R4SdkDataNative_Value85_TYPE 85u
/* r4cp_convert.ConvertError; native size 1, alignment 1. */
typedef struct R4SdkDataProjectConvertConvertError { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataProjectConvertConvertError;
#define R4SdkDataProjectConvertConvertError_TYPE 86u
/* r4cp_convert.Result; native size 24, alignment 8. */
typedef struct R4SdkDataProjectConvertResult { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataProjectConvertResult;
#define R4SdkDataProjectConvertResult_TYPE 87u
/* ?r4cp_convert.ConvertError; native size 2, alignment 1. */
typedef struct R4SdkDataNative_Value88 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value88;
#define R4SdkDataNative_Value88_TYPE 88u
/* ?u32; native size 8, alignment 4. */
typedef struct R4SdkDataNative_Value89 { _Alignas(4) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value89;
#define R4SdkDataNative_Value89_TYPE 89u
/* module_manifest.Kind; native size 1, alignment 1. */
typedef struct R4SdkDataManifestKind { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataManifestKind;
#define R4SdkDataManifestKind_TYPE 90u
/* module_manifest.Language; native size 1, alignment 1. */
typedef struct R4SdkDataManifestLanguage { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataManifestLanguage;
#define R4SdkDataManifestLanguage_TYPE 91u
/* module_manifest.AppClass; native size 1, alignment 1. */
typedef struct R4SdkDataManifestAppClass { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataManifestAppClass;
#define R4SdkDataManifestAppClass_TYPE 92u
/* module_manifest.EntryMode; native size 1, alignment 1. */
typedef struct R4SdkDataManifestEntryMode { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataManifestEntryMode;
#define R4SdkDataManifestEntryMode_TYPE 93u
/* module_manifest.ImageScope; native size 1, alignment 1. */
typedef struct R4SdkDataManifestImageScope { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataManifestImageScope;
#define R4SdkDataManifestImageScope_TYPE 94u
/* module_manifest.Optimization; native size 1, alignment 1. */
typedef struct R4SdkDataManifestOptimization { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataManifestOptimization;
#define R4SdkDataManifestOptimization_TYPE 95u
/* module_manifest.ModuleRole; native size 0, alignment 1. */
typedef struct R4SdkDataManifestModuleRole { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataManifestModuleRole;
#define R4SdkDataManifestModuleRole_TYPE 96u
/* module_manifest.GuestExtensionEntry; native size 32, alignment 8. */
typedef struct R4SdkDataManifestGuestExtensionEntry { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkDataManifestGuestExtensionEntry;
#define R4SdkDataManifestGuestExtensionEntry_TYPE 97u
/* module_manifest.GuestFeatureEntry; native size 32, alignment 8. */
typedef struct R4SdkDataManifestGuestFeatureEntry { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkDataManifestGuestFeatureEntry;
#define R4SdkDataManifestGuestFeatureEntry_TYPE 98u
/* module_manifest.ModuleVersion; native size 24, alignment 8. */
typedef struct R4SdkDataManifestModuleVersion { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataManifestModuleVersion;
#define R4SdkDataManifestModuleVersion_TYPE 99u
/* module_manifest.ResourceEntry; native size 32, alignment 8. */
typedef struct R4SdkDataManifestResourceEntry { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkDataManifestResourceEntry;
#define R4SdkDataManifestResourceEntry_TYPE 100u
/* module_manifest.ExportEntry; native size 40, alignment 8. */
typedef struct R4SdkDataManifestExportEntry { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkDataManifestExportEntry;
#define R4SdkDataManifestExportEntry_TYPE 101u
/* module_manifest.CDefineEntry; native size 32, alignment 8. */
typedef struct R4SdkDataManifestCDefineEntry { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkDataManifestCDefineEntry;
#define R4SdkDataManifestCDefineEntry_TYPE 102u
/* module_manifest.Manifest; native size 536, alignment 8. */
typedef struct R4SdkDataManifestManifest { _Alignas(8) uint8_t opaque_bytes[536]; } R4SdkDataManifestManifest;
#define R4SdkDataManifestManifest_TYPE 103u
/* ?module_manifest.Language; native size 2, alignment 1. */
typedef struct R4SdkDataNative_Value104 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value104;
#define R4SdkDataNative_Value104_TYPE 104u
/* []const []const u8; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value105 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value105;
#define R4SdkDataNative_Value105_TYPE 105u
/* ?module_manifest.EntryMode; native size 2, alignment 1. */
typedef struct R4SdkDataNative_Value106 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value106;
#define R4SdkDataNative_Value106_TYPE 106u
/* ?module_manifest.AppClass; native size 2, alignment 1. */
typedef struct R4SdkDataNative_Value107 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value107;
#define R4SdkDataNative_Value107_TYPE 107u
/* ?module_manifest.ModuleRole; native size 1, alignment 1. */
typedef struct R4SdkDataNative_Value108 { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataNative_Value108;
#define R4SdkDataNative_Value108_TYPE 108u
/* ?[]const u8; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value109 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value109;
#define R4SdkDataNative_Value109_TYPE 109u
/* []const module_manifest.GuestExtensionEntry; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value110 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value110;
#define R4SdkDataNative_Value110_TYPE 110u
/* []const module_manifest.GuestFeatureEntry; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value111 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value111;
#define R4SdkDataNative_Value111_TYPE 111u
/* ?module_manifest.ImageScope; native size 2, alignment 1. */
typedef struct R4SdkDataNative_Value112 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value112;
#define R4SdkDataNative_Value112_TYPE 112u
/* ?module_manifest.Optimization; native size 2, alignment 1. */
typedef struct R4SdkDataNative_Value113 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value113;
#define R4SdkDataNative_Value113_TYPE 113u
/* []const module_manifest.CDefineEntry; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value114 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value114;
#define R4SdkDataNative_Value114_TYPE 114u
/* []const module_manifest.ExportEntry; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value115 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value115;
#define R4SdkDataNative_Value115_TYPE 115u
/* []const module_manifest.ResourceEntry; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value116 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value116;
#define R4SdkDataNative_Value116_TYPE 116u
/* module_manifest.Plan; native size 176, alignment 8. */
typedef struct R4SdkDataManifestPlan { _Alignas(8) uint8_t opaque_bytes[176]; } R4SdkDataManifestPlan;
#define R4SdkDataManifestPlan_TYPE 117u
/* module_manifest.RenderResult; native size 24, alignment 8. */
typedef struct R4SdkDataManifestRenderResult { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataManifestRenderResult;
#define R4SdkDataManifestRenderResult_TYPE 118u
/* mem.Allocator; native size 16, alignment 8. */
typedef struct R4SdkDataAllocator { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataAllocator;
#define R4SdkDataAllocator_TYPE 119u
/* @typeInfo(@typeInfo(@TypeOf(module_manifest.parse)).@"fn".return_type.?).error_union.error_set!module_manifest.Manifest; native size 544, alignment 8. */
typedef struct R4SdkDataNative_Value120 { _Alignas(8) uint8_t opaque_bytes[544]; } R4SdkDataNative_Value120;
#define R4SdkDataNative_Value120_TYPE 120u
/* @typeInfo(@typeInfo(@TypeOf(module_manifest.moduleVersionMeta)).@"fn".return_type.?).error_union.error_set![]const u8; native size 24, alignment 8. */
typedef struct R4SdkDataNative_Value121 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_Value121;
#define R4SdkDataNative_Value121_TYPE 121u
/* @typeInfo(@typeInfo(@TypeOf(module_manifest.r4xManifestMetadata)).@"fn".return_type.?).error_union.error_set![]const []const u8; native size 24, alignment 8. */
typedef struct R4SdkDataNative_Value122 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_Value122;
#define R4SdkDataNative_Value122_TYPE 122u
/* @typeInfo(@typeInfo(@TypeOf(module_manifest.sdkBuildProfile)).@"fn".return_type.?).error_union.error_set![]const u8; native size 24, alignment 8. */
typedef struct R4SdkDataNative_Value123 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_Value123;
#define R4SdkDataNative_Value123_TYPE 123u
/* @typeInfo(@typeInfo(@TypeOf(module_manifest.moduleExports)).@"fn".return_type.?).error_union.error_set![]const []const u8; native size 24, alignment 8. */
typedef struct R4SdkDataNative_Value124 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_Value124;
#define R4SdkDataNative_Value124_TYPE 124u
/* @typeInfo(@typeInfo(@TypeOf(module_manifest.derivePlan)).@"fn".return_type.?).error_union.error_set!module_manifest.Plan; native size 184, alignment 8. */
typedef struct R4SdkDataNative_Value125 { _Alignas(8) uint8_t opaque_bytes[184]; } R4SdkDataNative_Value125;
#define R4SdkDataNative_Value125_TYPE 125u
/* version_info.SemanticVersion; native size 12, alignment 4. */
typedef struct R4SdkDataVersionSemanticVersion { _Alignas(4) uint8_t opaque_bytes[12]; } R4SdkDataVersionSemanticVersion;
#define R4SdkDataVersionSemanticVersion_TYPE 126u
/* ?version_info.SemanticVersion; native size 16, alignment 4. */
typedef struct R4SdkDataNative_Value127 { _Alignas(4) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value127;
#define R4SdkDataNative_Value127_TYPE 127u
/* r4u_manifest.ComponentKind; native size 1, alignment 1. */
typedef struct R4SdkDataUpdateMetadataComponentKind { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataUpdateMetadataComponentKind;
#define R4SdkDataUpdateMetadataComponentKind_TYPE 129u
/* r4u_manifest.InstallMode; native size 1, alignment 1. */
typedef struct R4SdkDataUpdateMetadataInstallMode { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataUpdateMetadataInstallMode;
#define R4SdkDataUpdateMetadataInstallMode_TYPE 130u
/* r4u_manifest.Priority; native size 1, alignment 1. */
typedef struct R4SdkDataUpdateMetadataPriority { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataUpdateMetadataPriority;
#define R4SdkDataUpdateMetadataPriority_TYPE 131u
/* r4u_manifest.RequirementState; native size 1, alignment 1. */
typedef struct R4SdkDataUpdateMetadataRequirementState { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataUpdateMetadataRequirementState;
#define R4SdkDataUpdateMetadataRequirementState_TYPE 132u
/* r4u_manifest.DerivedClass; native size 2, alignment 1. */
typedef struct R4SdkDataUpdateMetadataDerivedClass { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataUpdateMetadataDerivedClass;
#define R4SdkDataUpdateMetadataDerivedClass_TYPE 133u
/* *r4u_manifest.DerivedClass; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value134 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value134;
#define R4SdkDataNative_Value134_TYPE 134u
/* ?r4u_manifest.ComponentKind; native size 2, alignment 1. */
typedef struct R4SdkDataNative_Value135 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value135;
#define R4SdkDataNative_Value135_TYPE 135u
/* ?i8; native size 2, alignment 1. */
typedef struct R4SdkDataNative_Value136 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value136;
#define R4SdkDataNative_Value136_TYPE 136u
/* r4u_artifact.Identity; native size 96, alignment 8. */
typedef struct R4SdkDataArtifactIdentity { _Alignas(8) uint8_t opaque_bytes[96]; } R4SdkDataArtifactIdentity;
#define R4SdkDataArtifactIdentity_TYPE 137u
/* [49]u8; native size 49, alignment 1. */
typedef struct R4SdkDataNative_Value138 { _Alignas(1) uint8_t opaque_bytes[49]; } R4SdkDataNative_Value138;
#define R4SdkDataNative_Value138_TYPE 138u
/* [25]u8; native size 25, alignment 1. */
typedef struct R4SdkDataNative_Value139 { _Alignas(1) uint8_t opaque_bytes[25]; } R4SdkDataNative_Value139;
#define R4SdkDataNative_Value139_TYPE 139u
/* r4u_artifact.SliceReader; native size 16, alignment 8. */
typedef struct R4SdkDataArtifactSliceReader { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataArtifactSliceReader;
#define R4SdkDataArtifactSliceReader_TYPE 140u
/* data_helper_adapters.Context; native size 240, alignment 8. */
typedef struct R4SdkDataContext { _Alignas(8) uint8_t opaque_bytes[240]; } R4SdkDataContext;
#define R4SdkDataContext_TYPE 141u
/* *json.Document; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value142 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value142;
#define R4SdkDataNative_Value142_TYPE 142u
/* *const data_helper_adapters.Context; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value143 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value143;
#define R4SdkDataNative_Value143_TYPE 143u
/* *crypto_sha256.Sha256((function 'noWork')); native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value144 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value144;
#define R4SdkDataNative_Value144_TYPE 144u
/* crypto_sha256.Sha256((function 'noWork')); native size 128, alignment 16. */
typedef struct R4SdkDataSha256 { _Alignas(16) uint8_t opaque_bytes[128]; } R4SdkDataSha256;
#define R4SdkDataSha256_TYPE 145u
/* crypto.sha2.Sha2x32(.{ 1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225 },256); native size 112, alignment 16. */
typedef struct R4SdkDataNative_crypto_sha2_Sha2x32____1779033703__3144134277__1013904242__2773480762__1359893119__2600822924__528734635__1541459225___256_ { _Alignas(16) uint8_t opaque_bytes[112]; } R4SdkDataNative_crypto_sha2_Sha2x32____1779033703__3144134277__1013904242__2773480762__1359893119__2600822924__528734635__1541459225___256_;
#define R4SdkDataNative_crypto_sha2_Sha2x32____1779033703__3144134277__1013904242__2773480762__1359893119__2600822924__528734635__1541459225___256__TYPE 146u
/* heap.FixedBufferAllocator; native size 24, alignment 8. */
typedef struct R4SdkDataArena { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataArena;
#define R4SdkDataArena_TYPE 147u
/* *heap.FixedBufferAllocator; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value148 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value148;
#define R4SdkDataNative_Value148_TYPE 148u
/* *const heap.FixedBufferAllocator; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value149 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value149;
#define R4SdkDataNative_Value149_TYPE 149u
/* ?r4u_artifact.Identity; native size 104, alignment 8. */
typedef struct R4SdkDataNative_Value150 { _Alignas(8) uint8_t opaque_bytes[104]; } R4SdkDataNative_Value150;
#define R4SdkDataNative_Value150_TYPE 150u
/* data_helper_adapters.Reader; native size 16, alignment 8. */
typedef struct R4SdkDataReader { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataReader;
#define R4SdkDataReader_TYPE 151u
/* ?*anyopaque; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value152 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value152;
#define R4SdkDataNative_Value152_TYPE 152u
/* *data_helper_adapters.Context; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value153 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value153;
#define R4SdkDataNative_Value153_TYPE 153u
/* *const abi.R4XStartContext2; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value154 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value154;
#define R4SdkDataNative_Value154_TYPE 154u
/* crypto.sha2.Sha2x32(.{ 1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225 },256).Options; native size 0, alignment 1. */
typedef struct R4SdkDataNative_crypto_sha2_Sha2x32____1779033703__3144134277__1013904242__2773480762__1359893119__2600822924__528734635__1541459225___256__Options { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkDataNative_crypto_sha2_Sha2x32____1779033703__3144134277__1013904242__2773480762__1359893119__2600822924__528734635__1541459225___256__Options;
#define R4SdkDataNative_crypto_sha2_Sha2x32____1779033703__3144134277__1013904242__2773480762__1359893119__2600822924__528734635__1541459225___256__Options_TYPE 156u
/* *[32]u8; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value157 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value157;
#define R4SdkDataNative_Value157_TYPE 157u
/* [32]u8; native size 32, alignment 1. */
typedef struct R4SdkDataNative_Value158 { _Alignas(1) uint8_t opaque_bytes[32]; } R4SdkDataNative_Value158;
#define R4SdkDataNative_Value158_TYPE 158u
/* *const json.Document; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value159 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value159;
#define R4SdkDataNative_Value159_TYPE 159u
/* error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}!void; native size 2, alignment 2. */
typedef struct R4SdkDataNative_Value160 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value160;
#define R4SdkDataNative_Value160_TYPE 160u
/* error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}![]u8; native size 24, alignment 8. */
typedef struct R4SdkDataNative_Value161 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_Value161;
#define R4SdkDataNative_Value161_TYPE 161u
/* error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}!u64; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value162 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value162;
#define R4SdkDataNative_Value162_TYPE 162u
/* error{BadRequest,Bounds,Checksum,DuplicatePath,Inflate,InvalidArchive,Limit,OutputTooSmall,Stale,Unavailable,UnsafePath,Unsupported}![]const u8; native size 24, alignment 8. */
typedef struct R4SdkDataNative_Value163 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_Value163;
#define R4SdkDataNative_Value163_TYPE 163u
/* []zip.Entry; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value164 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value164;
#define R4SdkDataNative_Value164_TYPE 164u
/* error{BadRequest,Bounds,Checksum,DuplicatePath,Inflate,InvalidArchive,Limit,OutputTooSmall,Stale,Unavailable,UnsafePath,Unsupported}!zip.Info; native size 48, alignment 8. */
typedef struct R4SdkDataNative_Value165 { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkDataNative_Value165;
#define R4SdkDataNative_Value165_TYPE 165u
/* *zip.Work; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value166 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value166;
#define R4SdkDataNative_Value166_TYPE 166u
/* error{BadRequest,Bounds,Checksum,DuplicatePath,Inflate,InvalidArchive,Limit,OutputTooSmall,Stale,Unavailable,UnsafePath,Unsupported}!zip.Progress; native size 24, alignment 8. */
typedef struct R4SdkDataNative_Value167 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_Value167;
#define R4SdkDataNative_Value167_TYPE 167u
/* []const u32; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value168 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value168;
#define R4SdkDataNative_Value168_TYPE 168u
/* ?[]u32; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value169 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value169;
#define R4SdkDataNative_Value169_TYPE 169u
/* *raster.Image; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value170 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value170;
#define R4SdkDataNative_Value170_TYPE 170u
/* error{InvalidSize,TooLarge}!void; native size 2, alignment 2. */
typedef struct R4SdkDataNative_Value171 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value171;
#define R4SdkDataNative_Value171_TYPE 171u
/* *const abi_generated.CpuAccelerationInfo; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value172 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value172;
#define R4SdkDataNative_Value172_TYPE 172u
/* *const web_encoding.Decoder; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value174 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value174;
#define R4SdkDataNative_Value174_TYPE 174u
/* *web_encoding.Decoder; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value175 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value175;
#define R4SdkDataNative_Value175_TYPE 175u
/* error{InputTooLarge,InvalidSequence,OutputTooSmall,UnknownEncoding}![]const u8; native size 24, alignment 8. */
typedef struct R4SdkDataNative_Value176 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkDataNative_Value176;
#define R4SdkDataNative_Value176_TYPE 176u
/* error{InvalidUrl,PairLimit,TooLong}!web_url.SearchParams; native size 2072, alignment 8. */
typedef struct R4SdkDataNative_Value177 { _Alignas(8) uint8_t opaque_bytes[2072]; } R4SdkDataNative_Value177;
#define R4SdkDataNative_Value177_TYPE 177u
/* *web_url.SearchParams; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value178 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value178;
#define R4SdkDataNative_Value178_TYPE 178u
/* *const web_url.SearchParams; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value179 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value179;
#define R4SdkDataNative_Value179_TYPE 179u
/* *const r4cp.Project; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value180 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value180;
#define R4SdkDataNative_Value180_TYPE 180u
/* []const r4cp.Item; native size 16, alignment 8. */
typedef struct R4SdkDataNative_Value181 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkDataNative_Value181;
#define R4SdkDataNative_Value181_TYPE 181u
/* ?r4cp.ProfileClass; native size 2, alignment 1. */
typedef struct R4SdkDataNative_Value182 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value182;
#define R4SdkDataNative_Value182_TYPE 182u
/* ?r4u_manifest.InstallMode; native size 2, alignment 1. */
typedef struct R4SdkDataNative_Value183 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value183;
#define R4SdkDataNative_Value183_TYPE 183u
/* ?r4u_manifest.Priority; native size 2, alignment 1. */
typedef struct R4SdkDataNative_Value184 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value184;
#define R4SdkDataNative_Value184_TYPE 184u
/* ?r4u_manifest.RequirementState; native size 2, alignment 1. */
typedef struct R4SdkDataNative_Value185 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkDataNative_Value185;
#define R4SdkDataNative_Value185_TYPE 185u
/* *const r4u_artifact.Identity; native size 8, alignment 8. */
typedef struct R4SdkDataNative_Value186 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkDataNative_Value186;
#define R4SdkDataNative_Value186_TYPE 186u
#define R4SdkData_ABI_FINGERPRINT UINT64_C(18045244107517554407)
int32_t R4SdkDataVerifyAbi(uint64_t);
static const uint8_t R4SdkDataJson_CONST_role[] = {102,111,114,109,97,116,46,106,115,111,110,0};
static inline R4SdkDataSlot R4SdkDataJson_constant_role(void) { return (R4SdkDataSlot){.ptr=(void *)R4SdkDataJson_CONST_role,.length=11,.flags=1u}; }
#define R4SdkDataJson_op_open (1)
#define R4SdkDataJson_op_next (2)
#define R4SdkDataJson_op_select (3)
#define R4SdkDataJson_op_value (4)
#define R4SdkDataJson_op_enter (5)
#define R4SdkDataJson_op_next_element (6)
#define R4SdkDataJson_op_set (7)
#define R4SdkDataJson_op_remove (8)
#define R4SdkDataJson_op_insert (9)
static const uint8_t R4SdkDataZip_CONST_role[] = {102,111,114,109,97,116,46,122,105,112,0};
static inline R4SdkDataSlot R4SdkDataZip_constant_role(void) { return (R4SdkDataSlot){.ptr=(void *)R4SdkDataZip_CONST_role,.length=10,.flags=1u}; }
#define R4SdkDataZip_contract_version (1)
#define R4SdkDataZip_max_entries (4096)
#define R4SdkDataZip_max_path (255)
#define R4SdkDataZip_work_bytes (16384)
#define R4SdkDataZip_work_alignment (16)
#define R4SdkDataZip_max_step_bytes (4194304)
#define R4SdkDataZip_min_step_bytes (258)
#define R4SdkDataZip_op_inspect (1)
#define R4SdkDataZip_op_begin (2)
#define R4SdkDataZip_op_step (3)
#define R4SdkDataZip_op_begin_stream (4)
#define R4SdkDataZip_op_step_stream (5)
#define R4SdkDataZip_stream_history_bytes (32768)
#define R4SdkDataZip_stream_buffer_bytes (163840)
static const uint8_t R4SdkDataIco_CONST_textfile_icon_path[] = {67,58,92,82,52,79,83,92,77,101,100,105,97,92,73,99,111,110,115,92,84,101,120,116,102,105,108,101,46,105,99,111,0};
static inline R4SdkDataSlot R4SdkDataIco_constant_textfile_icon_path(void) { return (R4SdkDataSlot){.ptr=(void *)R4SdkDataIco_CONST_textfile_icon_path,.length=32,.flags=1u}; }
#define R4SdkDataRaster_max_width (128)
#define R4SdkDataRaster_max_height (128)
#define R4SdkDataRaster_max_pixels (16384)
#define R4SdkDataRaster_default_background (16777215)
#define R4SdkDataCrypto_max_random_bytes (65536)
#define R4SdkDataEncoding_max_input_bytes (131072)
#define R4SdkDataEncoding_max_output_bytes (393219)
#define R4SdkDataUrl_max_query_bytes (767)
#define R4SdkDataUrl_max_pairs (64)
#define R4SdkDataProject_max_sources (12)
#define R4SdkDataProject_max_imports (12)
#define R4SdkDataProject_max_exports (12)
#define R4SdkDataProject_max_metadata (16)
#define R4SdkDataProject_max_contracts (8)
#define R4SdkDataManifest_manifest_version (2)
#define R4SdkDataManifest_max_manifest_bytes (131072)
#define R4SdkDataManifest_plan_contract_version (1)
#define R4SdkDataManifest_subsystem_id_max_bytes (63)
#define R4SdkDataManifest_subsystem_display_name_max_bytes (96)
#define R4SdkDataManifest_guest_format_id_max_bytes (63)
#define R4SdkDataManifest_guest_feature_max_bytes (63)
#define R4SdkDataManifest_guest_extension_max_bytes (16)
#define R4SdkDataManifest_max_guest_formats (16)
#define R4SdkDataManifest_max_guest_extensions (32)
#define R4SdkDataManifest_max_guest_features (32)
#define R4SdkDataManifest_max_resource_entries (64)
static const uint8_t R4SdkDataVersion_CONST_release_field[] = {82,69,76,69,65,83,69,95,86,69,82,83,73,79,78,61,0};
static inline R4SdkDataSlot R4SdkDataVersion_constant_release_field(void) { return (R4SdkDataSlot){.ptr=(void *)R4SdkDataVersion_CONST_release_field,.length=16,.flags=1u}; }
static const uint8_t R4SdkDataVersion_CONST_release_file_path[] = {47,82,52,79,83,47,67,79,78,70,73,71,47,86,69,82,83,73,79,78,46,82,52,83,0};
static inline R4SdkDataSlot R4SdkDataVersion_constant_release_file_path(void) { return (R4SdkDataSlot){.ptr=(void *)R4SdkDataVersion_CONST_release_file_path,.length=24,.flags=1u}; }
static const uint8_t R4SdkDataVersion_CONST_inventory_file_path[] = {47,82,52,79,83,47,67,79,78,70,73,71,47,77,79,68,85,76,69,83,46,74,83,79,78,0};
static inline R4SdkDataSlot R4SdkDataVersion_constant_inventory_file_path(void) { return (R4SdkDataSlot){.ptr=(void *)R4SdkDataVersion_CONST_inventory_file_path,.length=25,.flags=1u}; }
#define R4SdkDataUpdateMetadata_manifest_version (2)
static const uint8_t R4SdkDataUpdateMetadata_CONST_header_magic[] = {82,52,85,50,0};
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_constant_header_magic(void) { return (R4SdkDataSlot){.ptr=(void *)R4SdkDataUpdateMetadata_CONST_header_magic,.length=4,.flags=1u}; }
#define R4SdkDataUpdateMetadata_header_version (2)
#define R4SdkDataUpdateMetadata_header_size (64)
#define R4SdkDataUpdateMetadata_max_package_payloads (32)
#define R4SdkDataUpdateMetadata_manifest_max_bytes (32768)
#define R4SdkDataUpdateMetadata_title_max_bytes (96)
#define R4SdkDataUpdateMetadata_description_max_bytes (2048)
#define R4SdkDataUpdateMetadata_package_name_max_bytes (48)
#define R4SdkDataUpdateMetadata_component_name_max_bytes (48)
#define R4SdkDataUpdateMetadata_version_max_bytes (24)
#define R4SdkDataArtifact_name_capacity (49)
#define R4SdkDataArtifact_version_capacity (25)
#define R4SdkDataSha256_block_length (64)
#define R4SdkDataSha256_digest_length (32)
#define R4SdkDataJsonToken_end 0u
#define R4SdkDataJsonToken_object_begin 1u
#define R4SdkDataJsonToken_object_end 2u
#define R4SdkDataJsonToken_array_begin 3u
#define R4SdkDataJsonToken_array_end 4u
#define R4SdkDataJsonToken_key 5u
#define R4SdkDataJsonToken_string 6u
#define R4SdkDataJsonToken_number 7u
#define R4SdkDataJsonToken_true_value 8u
#define R4SdkDataJsonToken_false_value 9u
#define R4SdkDataJsonToken_null_value 10u
#define R4SdkDataJsonToken_none 255u
#define R4SdkDataEncodingEncoding_utf8 0u
#define R4SdkDataEncodingEncoding_windows_1252 1u
#define R4SdkDataUrlComponent_protocol 0u
#define R4SdkDataUrlComponent_username 1u
#define R4SdkDataUrlComponent_password 2u
#define R4SdkDataUrlComponent_host 3u
#define R4SdkDataUrlComponent_hostname 4u
#define R4SdkDataUrlComponent_port 5u
#define R4SdkDataUrlComponent_pathname 6u
#define R4SdkDataUrlComponent_search 7u
#define R4SdkDataUrlComponent_hash 8u
#define R4SdkDataProjectModuleKind_r4x 0u
#define R4SdkDataProjectModuleKind_r4d 1u
#define R4SdkDataProjectModuleKind_r4p 2u
#define R4SdkDataProjectModuleKind_r4l 3u
#define R4SdkDataProjectLanguage_zig 0u
#define R4SdkDataProjectLanguage_c 1u
#define R4SdkDataProjectProfileClass_internal 0u
#define R4SdkDataProjectProfileClass_external_compatible 1u
#define R4SdkDataProjectConvertConvertError_unsupported_module_kind 0u
#define R4SdkDataProjectConvertConvertError_unsupported_profile 1u
#define R4SdkDataProjectConvertConvertError_invalid_app_class 2u
#define R4SdkDataProjectConvertConvertError_output_too_small 3u
#define R4SdkDataManifestKind_r4x 0u
#define R4SdkDataManifestKind_r4d 1u
#define R4SdkDataManifestKind_r4p 2u
#define R4SdkDataManifestKind_r4l 3u
#define R4SdkDataManifestLanguage_zig 0u
#define R4SdkDataManifestLanguage_c 1u
#define R4SdkDataManifestLanguage_rust 2u
#define R4SdkDataManifestAppClass_console 0u
#define R4SdkDataManifestAppClass_gui 1u
#define R4SdkDataManifestAppClass_service 2u
#define R4SdkDataManifestEntryMode_app 0u
#define R4SdkDataManifestEntryMode_lowlevel 1u
#define R4SdkDataManifestImageScope_slim 0u
#define R4SdkDataManifestImageScope_full 1u
#define R4SdkDataManifestImageScope_test 2u
#define R4SdkDataManifestImageScope_none 3u
#define R4SdkDataManifestOptimization_size 0u
#define R4SdkDataManifestOptimization_speed 1u
#define R4SdkDataManifestModuleRole_subsystem 0u
#define R4SdkDataUpdateMetadataComponentKind_kernel 0u
#define R4SdkDataUpdateMetadataComponentKind_r4x 1u
#define R4SdkDataUpdateMetadataComponentKind_r4l 2u
#define R4SdkDataUpdateMetadataComponentKind_r4d 3u
#define R4SdkDataUpdateMetadataComponentKind_r4p 4u
#define R4SdkDataUpdateMetadataInstallMode_live 0u
#define R4SdkDataUpdateMetadataInstallMode_restart 1u
#define R4SdkDataUpdateMetadataPriority_normal 0u
#define R4SdkDataUpdateMetadataPriority_foundation 1u
#define R4SdkDataUpdateMetadataRequirementState_installed 0u
#define R4SdkDataUpdateMetadataRequirementState_active 1u
/* json.mapStatus -> ?error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken} */
static inline R4SdkDataSlot R4SdkDataJson_mapStatus(uint32_t reserved, int32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,0u,a,1u,0);
}
/* zip.status -> i32 */
static inline R4SdkDataSlot R4SdkDataZip_status(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,1u,a,1u,0);
}
/* zip.check -> error{BadRequest,Bounds,Checksum,DuplicatePath,Inflate,InvalidArchive,Limit,OutputTooSmall,Stale,Unavailable,UnsafePath,Unsupported}!void */
static inline R4SdkDataSlot R4SdkDataZip_check(uint32_t reserved, int32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,2u,a,1u,0);
}
/* ico.parseDirectory -> error{BadDirectory,BadImage,NotIcon,Truncated,UnsupportedBpp,UnsupportedCompression}!ico.Directory */
static inline R4SdkDataSlot R4SdkDataIco_parseDirectory(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkDataIcoDirectory *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,3u,a,1u,output);
}
/* ico.entryAt -> error{BadDirectory,BadImage,NotIcon,Truncated,UnsupportedBpp,UnsupportedCompression}!ico.Entry */
static inline R4SdkDataSlot R4SdkDataIco_entryAt(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint64_t p1, R4SdkDataIcoEntry *output) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,4u,a,2u,output);
}
/* ico.isTextFileName -> bool */
static inline R4SdkDataSlot R4SdkDataIco_isTextFileName(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,5u,a,1u,0);
}
/* ico.chooseBest -> error{BadDirectory,BadImage,NotIcon,Truncated,UnsupportedBpp,UnsupportedCompression}!ico.Entry */
static inline R4SdkDataSlot R4SdkDataIco_chooseBest(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint16_t p1, R4SdkDataIcoEntry *output) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,6u,a,2u,output);
}
/* ico.parseBmpImage -> error{BadDirectory,BadImage,NotIcon,Truncated,UnsupportedBpp,UnsupportedCompression}!ico.BitmapImage */
static inline R4SdkDataSlot R4SdkDataIco_parseBmpImage(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const R4SdkDataIcoEntry * p1, R4SdkDataIcoBitmapImage *output) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,7u,a,2u,output);
}
/* ico.pixelAt -> ?ico.Pixel */
static inline R4SdkDataSlot R4SdkDataIco_pixelAt(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const R4SdkDataIcoBitmapImage * p1, uint32_t p2, uint32_t p3, R4SdkDataIcoPixel *output) {
 (void)reserved; R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,8u,a,4u,output);
}
/* ico.copyScaledPixels -> bool */
static inline R4SdkDataSlot R4SdkDataIco_copyScaledPixels(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const R4SdkDataIcoBitmapImage * p1, uint32_t * p2, uintptr_t n2, uint8_t * p3, uintptr_t n3, uint32_t p4, uint32_t p5, uint64_t p6) {
 (void)reserved; R4SdkDataSlot a[7]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,9u,a,7u,0);
}
/* raster.init -> error{InvalidSize,TooLarge}!raster.Image */
static inline R4SdkDataSlot R4SdkDataRaster_init(uint32_t reserved, uint32_t * p0, uintptr_t n0, uint32_t p1, uint32_t p2, uint32_t p3, R4SdkDataRasterImage *output) {
 (void)reserved; R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,10u,a,4u,output);
}
/* raster.requiredPixels -> error{InvalidSize,TooLarge}!usize */
static inline R4SdkDataSlot R4SdkDataRaster_requiredPixels(uint32_t reserved, uint32_t p0, uint32_t p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,11u,a,2u,0);
}
/* raster.normalizeColor -> u32 */
static inline R4SdkDataSlot R4SdkDataRaster_normalizeColor(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,12u,a,1u,0);
}
/* raster.rgb -> u32 */
static inline R4SdkDataSlot R4SdkDataRaster_rgb(uint32_t reserved, uint8_t p0, uint8_t p1, uint8_t p2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,13u,a,3u,0);
}
/* raster.red -> u8 */
static inline R4SdkDataSlot R4SdkDataRaster_red(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,14u,a,1u,0);
}
/* raster.green -> u8 */
static inline R4SdkDataSlot R4SdkDataRaster_green(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,15u,a,1u,0);
}
/* raster.blue -> u8 */
static inline R4SdkDataSlot R4SdkDataRaster_blue(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,16u,a,1u,0);
}
/* secure_random.bindProgram -> void */
static inline R4SdkDataSlot R4SdkDataRandom_bindProgram(uint32_t reserved, const R4SdkDataNative_program_Context * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,17u,a,1u,0);
}
/* secure_random.bindProtocol -> void */
static inline R4SdkDataSlot R4SdkDataRandom_bindProtocol(uint32_t reserved, const R4ProtocolApi2 * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,18u,a,1u,0);
}
/* secure_random.available -> bool */
static inline R4SdkDataSlot R4SdkDataRandom_available(uint32_t reserved) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,19u,a,0u,0);
}
/* secure_random.fill -> bool */
static inline R4SdkDataSlot R4SdkDataRandom_fill(uint32_t reserved, uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,20u,a,1u,0);
}
/* secure_random.sourceInfo -> i32 */
static inline R4SdkDataSlot R4SdkDataRandom_sourceInfo(uint32_t reserved, R4EntropySourceInfo * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,21u,a,1u,0);
}
/* cpu_acceleration.protocolWork -> ?*const fn (u32, u32, ?*const *const fn (u64, u32) callconv(.c) i32, u64, *abi_generated.CpuAccelerationWork) callconv(.c) i32 */
static inline R4SdkDataSlot R4SdkDataCpu_protocolWork(uint32_t reserved, const R4ProtocolApi2 * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,22u,a,1u,0);
}
/* cpu_acceleration.protocolInfo -> ?*const fn (*abi_generated.CpuAccelerationInfo) callconv(.c) i32 */
static inline R4SdkDataSlot R4SdkDataCpu_protocolInfo(uint32_t reserved, const R4ProtocolApi2 * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,23u,a,1u,0);
}
/* cpu_acceleration.accepted -> bool */
static inline R4SdkDataSlot R4SdkDataCpu_accepted(uint32_t reserved, const R4CpuAccelerationWork * p0, uint32_t p1, uint32_t p2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,24u,a,3u,0);
}
/* web_crypto.secureEntropyAvailable -> bool */
static inline R4SdkDataSlot R4SdkDataCrypto_secureEntropyAvailable(uint32_t reserved) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,25u,a,0u,0);
}
/* web_crypto.fillSecureRandom -> bool */
static inline R4SdkDataSlot R4SdkDataCrypto_fillSecureRandom(uint32_t reserved, uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,26u,a,1u,0);
}
/* web_crypto.digest -> error{EntropyUnavailable,OutputTooSmall,UnsupportedAlgorithm}![]const u8 */
static inline R4SdkDataSlot R4SdkDataCrypto_digest(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,27u,a,3u,0);
}
/* web_encoding.parseLabel -> error{InputTooLarge,InvalidSequence,OutputTooSmall,UnknownEncoding}!web_encoding.Encoding */
static inline R4SdkDataSlot R4SdkDataEncoding_parseLabel(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,28u,a,1u,0);
}
/* web_encoding.encodeInto -> web_encoding.EncodeIntoResult */
static inline R4SdkDataSlot R4SdkDataEncoding_encodeInto(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint8_t * p1, uintptr_t n1, R4SdkDataEncodingEncodeIntoResult *output) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,29u,a,2u,output);
}
/* web_url.parts -> error{InvalidUrl,PairLimit,TooLong}!web_url.Parts */
static inline R4SdkDataSlot R4SdkDataUrl_parts(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkDataUrlParts *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,30u,a,1u,output);
}
/* web_url.resolveReference -> error{InvalidUrl,PairLimit,TooLong}![]u8 */
static inline R4SdkDataSlot R4SdkDataUrl_resolveReference(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,31u,a,4u,0);
}
/* web_url.appendNormalizedPath -> error{InvalidUrl,PairLimit,TooLong}!void */
static inline R4SdkDataSlot R4SdkDataUrl_appendNormalizedPath(uint32_t reserved, uint8_t * p0, uintptr_t n0, uint64_t * p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,32u,a,3u,0);
}
/* web_url.replaceComponent -> error{InvalidUrl,PairLimit,TooLong}![]const u8 */
static inline R4SdkDataSlot R4SdkDataUrl_replaceComponent(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint32_t p1, const uint8_t * p2, uintptr_t n2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,33u,a,4u,0);
}
/* r4cp.parse -> error{HostPathRejected,IncompatibleBuildProfile,InvalidArtifactPath,InvalidImport,InvalidKey,InvalidLanguage,InvalidLine,InvalidModuleKind,InvalidSectionHeader,InvalidSourcePath,InvalidTargetPath,KeyOutsideSection,MissingArtifact,MissingBuildProfile,MissingLanguage,MissingModuleKind,MissingProjectName,MissingR4XStart,MissingSource,MissingTargetPath,TooManyContracts,TooManyExports,TooManyImports,TooManyMetadata,TooManySources,UnknownImportGroup,UnsupportedBuildProfile}!r4cp.Project */
static inline R4SdkDataSlot R4SdkDataProject_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkDataProjectProject *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,34u,a,1u,output);
}
/* r4cp.errorMessage -> []const u8 */
static inline R4SdkDataSlot R4SdkDataProject_errorMessage(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,35u,a,1u,0);
}
/* r4cp.renderTemplate -> r4cp.RenderResult */
static inline R4SdkDataSlot R4SdkDataProject_renderTemplate(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const R4SdkDataProjectToken * p1, uintptr_t n1, uint8_t * p2, uintptr_t n2, R4SdkDataProjectRenderResult *output) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,36u,a,3u,output);
}
/* r4cp.renderProjectTemplate -> r4cp.RenderResult */
static inline R4SdkDataSlot R4SdkDataProject_renderProjectTemplate(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const R4SdkDataProjectProjectTemplateValues * p1, uint8_t * p2, uintptr_t n2, R4SdkDataProjectRenderResult *output) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,37u,a,3u,output);
}
/* r4cp.trim -> []const u8 */
static inline R4SdkDataSlot R4SdkDataProject_trim(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,38u,a,1u,0);
}
/* r4cp_convert.render -> r4cp_convert.Result */
static inline R4SdkDataSlot R4SdkDataProjectConvert_render(uint32_t reserved, const R4SdkDataProjectProject * p0, uint8_t * p1, uintptr_t n1, R4SdkDataProjectConvertResult *output) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,39u,a,2u,output);
}
/* r4cp_convert.errorMessage -> []const u8 */
static inline R4SdkDataSlot R4SdkDataProjectConvert_errorMessage(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,40u,a,1u,0);
}
/* module_manifest.platformApiGroupId -> ?u32 */
static inline R4SdkDataSlot R4SdkDataManifest_platformApiGroupId(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,41u,a,1u,0);
}
/* module_manifest.parse -> @typeInfo(@typeInfo(@TypeOf(module_manifest.parse)).@"fn".return_type.?).error_union.error_set!module_manifest.Manifest */
static inline R4SdkDataSlot R4SdkDataManifest_parse(uint32_t reserved, const R4SdkDataAllocator * p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, R4SdkDataManifestManifest *output) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,42u,a,3u,output);
}
/* module_manifest.importIsOptional -> bool */
static inline R4SdkDataSlot R4SdkDataManifest_importIsOptional(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,43u,a,1u,0);
}
/* module_manifest.moduleVersionMeta -> @typeInfo(@typeInfo(@TypeOf(module_manifest.moduleVersionMeta)).@"fn".return_type.?).error_union.error_set![]const u8 */
static inline R4SdkDataSlot R4SdkDataManifest_moduleVersionMeta(uint32_t reserved, const R4SdkDataAllocator * p0, const R4SdkDataManifestManifest * p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,44u,a,2u,0);
}
/* module_manifest.r4xManifestMetadata -> @typeInfo(@typeInfo(@TypeOf(module_manifest.r4xManifestMetadata)).@"fn".return_type.?).error_union.error_set![]const []const u8 */
static inline R4SdkDataSlot R4SdkDataManifest_r4xManifestMetadata(uint32_t reserved, const R4SdkDataAllocator * p0, const R4SdkDataManifestManifest * p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,45u,a,2u,0);
}
/* module_manifest.sdkBuildProfile -> @typeInfo(@typeInfo(@TypeOf(module_manifest.sdkBuildProfile)).@"fn".return_type.?).error_union.error_set![]const u8 */
static inline R4SdkDataSlot R4SdkDataManifest_sdkBuildProfile(uint32_t reserved, const R4SdkDataManifestManifest * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,46u,a,1u,0);
}
/* module_manifest.moduleExports -> @typeInfo(@typeInfo(@TypeOf(module_manifest.moduleExports)).@"fn".return_type.?).error_union.error_set![]const []const u8 */
static inline R4SdkDataSlot R4SdkDataManifest_moduleExports(uint32_t reserved, const R4SdkDataAllocator * p0, const R4SdkDataManifestManifest * p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,47u,a,2u,0);
}
/* module_manifest.derivePlan -> @typeInfo(@typeInfo(@TypeOf(module_manifest.derivePlan)).@"fn".return_type.?).error_union.error_set!module_manifest.Plan */
static inline R4SdkDataSlot R4SdkDataManifest_derivePlan(uint32_t reserved, const R4SdkDataAllocator * p0, const R4SdkDataManifestManifest * p1, R4SdkDataManifestPlan *output) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,48u,a,2u,output);
}
/* module_manifest.buildProfileName -> []const u8 */
static inline R4SdkDataSlot R4SdkDataManifest_buildProfileName(uint32_t reserved, uint32_t p0, uint32_t p1, uint32_t p2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,49u,a,3u,0);
}
/* module_manifest.appProfileName -> []const u8 */
static inline R4SdkDataSlot R4SdkDataManifest_appProfileName(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,50u,a,1u,0);
}
/* module_manifest.renderContractPlan -> module_manifest.RenderResult */
static inline R4SdkDataSlot R4SdkDataManifest_renderContractPlan(uint32_t reserved, const R4SdkDataManifestManifest * p0, uint8_t * p1, uintptr_t n1, R4SdkDataManifestRenderResult *output) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,51u,a,2u,output);
}
/* version_info.stripBom -> []const u8 */
static inline R4SdkDataSlot R4SdkDataVersion_stripBom(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,52u,a,1u,0);
}
/* version_info.parseReleaseVersion -> ?[]const u8 */
static inline R4SdkDataSlot R4SdkDataVersion_parseReleaseVersion(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,53u,a,1u,0);
}
/* version_info.parseInstalledKernelVersion -> ?[]const u8 */
static inline R4SdkDataSlot R4SdkDataVersion_parseInstalledKernelVersion(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,54u,a,1u,0);
}
/* version_info.parseSemanticVersion -> ?version_info.SemanticVersion */
static inline R4SdkDataSlot R4SdkDataVersion_parseSemanticVersion(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkDataVersionSemanticVersion *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,55u,a,1u,output);
}
/* version_info.fromKernelVersion -> version_info.SemanticVersion */
static inline R4SdkDataSlot R4SdkDataVersion_fromKernelVersion(uint32_t reserved, const R4KernelVersion * p0, R4SdkDataVersionSemanticVersion *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,56u,a,1u,output);
}
/* version_info.formatKernelVersion -> ?[]const u8 */
static inline R4SdkDataSlot R4SdkDataVersion_formatKernelVersion(uint32_t reserved, const R4KernelVersion * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,57u,a,2u,0);
}
/* version_info.formatSemanticVersion -> ?[]const u8 */
static inline R4SdkDataSlot R4SdkDataVersion_formatSemanticVersion(uint32_t reserved, const R4SdkDataVersionSemanticVersion * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,58u,a,2u,0);
}
/* version_info.restartRequired -> bool */
static inline R4SdkDataSlot R4SdkDataVersion_restartRequired(uint32_t reserved, const R4KernelVersion * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,59u,a,2u,0);
}
/* r4u_manifest.kernelSupportsCompanions -> bool */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_kernelSupportsCompanions(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,60u,a,1u,0);
}
/* r4u_manifest.companionRecoveryRequirement -> bool */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_companionRecoveryRequirement(uint32_t reserved, uint32_t p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, uint32_t p4) {
 (void)reserved; R4SdkDataSlot a[5]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,61u,a,5u,0);
}
/* r4u_manifest.kernelSupportsCompanionSet -> bool */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_kernelSupportsCompanionSet(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint8_t p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,62u,a,2u,0);
}
/* r4u_manifest.companionSetRecoveryRequirement -> bool */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_companionSetRecoveryRequirement(uint32_t reserved, uint32_t p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, uint32_t p4, uint8_t p5) {
 (void)reserved; R4SdkDataSlot a[6]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,63u,a,6u,0);
}
/* r4u_manifest.includeCompanion -> void */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_includeCompanion(uint32_t reserved, R4SdkDataUpdateMetadataDerivedClass * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,64u,a,2u,0);
}
/* r4u_manifest.componentKindForPayload -> ?r4u_manifest.ComponentKind */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_componentKindForPayload(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,65u,a,2u,0);
}
/* r4u_manifest.installModeFor -> r4u_manifest.InstallMode */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_installModeFor(uint32_t reserved, uint32_t p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,66u,a,2u,0);
}
/* r4u_manifest.priorityFor -> r4u_manifest.Priority */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_priorityFor(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,67u,a,1u,0);
}
/* r4u_manifest.includeComponent -> void */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_includeComponent(uint32_t reserved, R4SdkDataUpdateMetadataDerivedClass * p0, uint32_t p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,68u,a,3u,0);
}
/* r4u_manifest.validSemanticVersion -> bool */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_validSemanticVersion(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,69u,a,1u,0);
}
/* r4u_manifest.compareVersions -> ?i8 */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_compareVersions(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,70u,a,2u,0);
}
/* r4u_manifest.validToken -> bool */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_validToken(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint64_t p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,71u,a,2u,0);
}
/* r4u_manifest.validDisplayText -> bool */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_validDisplayText(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint64_t p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,72u,a,2u,0);
}
/* r4u_manifest.canonicalInventoryTarget -> ?[]const u8 */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_canonicalInventoryTarget(uint32_t reserved, uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,73u,a,2u,0);
}
/* r4u_manifest.targetEquals -> bool */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_targetEquals(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,74u,a,2u,0);
}
/* r4u_manifest.isManagedStateTarget -> bool */
static inline R4SdkDataSlot R4SdkDataUpdateMetadata_isManagedStateTarget(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,75u,a,1u,0);
}
/* data_helper_adapters.json -> void */
static inline R4SdkDataSlot R4SdkData_json(uint32_t reserved, R4SdkDataJsonDocument * p0, const R4SdkDataContext * p1, const uint8_t * p2, uintptr_t n2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,76u,a,4u,0);
}
/* data_helper_adapters.zip -> zip.Context */
static inline R4SdkDataSlot R4SdkData_zip(uint32_t reserved, const R4SdkDataContext * p0, R4SdkDataZipContext *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,77u,a,1u,output);
}
/* data_helper_adapters.entropyProvider -> secure_random.Provider */
static inline R4SdkDataSlot R4SdkData_entropyProvider(uint32_t reserved, const R4SdkDataContext * p0, R4SdkDataRandomProvider *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,78u,a,1u,output);
}
/* data_helper_adapters.hashUpdate -> void */
static inline R4SdkDataSlot R4SdkData_hashUpdate(uint32_t reserved, R4SdkDataSha256 * p0, const R4SdkDataContext * p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,79u,a,3u,0);
}
/* data_helper_adapters.hashInit -> void */
static inline R4SdkDataSlot R4SdkData_hashInit(uint32_t reserved, R4SdkDataSha256 * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,80u,a,1u,0);
}
/* data_helper_adapters.arena -> void */
static inline R4SdkDataSlot R4SdkData_arena(uint32_t reserved, R4SdkDataArena * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,81u,a,2u,0);
}
/* data_helper_adapters.allocator -> mem.Allocator */
static inline R4SdkDataSlot R4SdkData_allocator(uint32_t reserved, R4SdkDataArena * p0, R4SdkDataAllocator *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,82u,a,1u,output);
}
/* data_helper_adapters.reset -> void */
static inline R4SdkDataSlot R4SdkData_reset(uint32_t reserved, R4SdkDataArena * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,83u,a,1u,0);
}
/* data_helper_adapters.used -> usize */
static inline R4SdkDataSlot R4SdkData_used(uint32_t reserved, const R4SdkDataArena * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,84u,a,1u,0);
}
/* data_helper_adapters.inspectBytes -> ?r4u_artifact.Identity */
static inline R4SdkDataSlot R4SdkData_inspectBytes(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkDataArtifactIdentity *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,85u,a,1u,output);
}
/* data_helper_adapters.inspectReader -> ?r4u_artifact.Identity */
static inline R4SdkDataSlot R4SdkData_inspectReader(uint32_t reserved, const R4SdkDataReader * p0, uint64_t p1, R4SdkDataArtifactIdentity *output) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,86u,a,2u,output);
}
/* data_helper_adapters.audioStreamReplyValid -> bool */
static inline R4SdkDataSlot R4SdkData_audioStreamReplyValid(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint16_t p1, uint32_t p2, uint32_t p3, uint64_t p4) {
 (void)reserved; R4SdkDataSlot a[5]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,87u,a,5u,0);
}
/* data_helper_adapters.open2 -> bool */
static inline R4SdkDataSlot R4SdkData_open2(uint32_t reserved, R4SdkDataContext * p0, const R4XStartContext2 * p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,88u,a,2u,0);
}
/* crypto_sha256.Sha256((function 'noWork')).init -> crypto_sha256.Sha256((function 'noWork')) */
static inline R4SdkDataSlot R4SdkDataSha256_init(uint32_t reserved, const R4SdkDataNative_crypto_sha2_Sha2x32____1779033703__3144134277__1013904242__2773480762__1359893119__2600822924__528734635__1541459225___256__Options * p0, R4SdkDataSha256 *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,89u,a,1u,output);
}
/* crypto_sha256.Sha256((function 'noWork')).hash -> void */
static inline R4SdkDataSlot R4SdkDataSha256_hash(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkDataNative_Value158 * p1, const R4SdkDataNative_crypto_sha2_Sha2x32____1779033703__3144134277__1013904242__2773480762__1359893119__2600822924__528734635__1541459225___256__Options * p2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,90u,a,3u,0);
}
/* crypto_sha256.Sha256((function 'noWork')).update -> void */
static inline R4SdkDataSlot R4SdkDataSha256_update(uint32_t reserved, R4SdkDataSha256 * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,91u,a,2u,0);
}
/* crypto_sha256.Sha256((function 'noWork')).updateWithExecutor -> void */
static inline R4SdkDataSlot R4SdkDataSha256_updateWithExecutor(uint32_t reserved, R4SdkDataSha256 * p0, const uint8_t * p1, uintptr_t n1, R4SdkDataSlot p2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = p2;
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,92u,a,3u,0);
}
/* crypto_sha256.Sha256((function 'noWork')).final -> void */
static inline R4SdkDataSlot R4SdkDataSha256_final(uint32_t reserved, R4SdkDataSha256 * p0, R4SdkDataNative_Value158 * p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,93u,a,2u,0);
}
/* crypto_sha256.Sha256((function 'noWork')).finalResult -> [32]u8 */
static inline R4SdkDataSlot R4SdkDataSha256_finalResult(uint32_t reserved, R4SdkDataSha256 * p0, R4SdkDataNative_Value158 *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,94u,a,1u,output);
}
/* crypto_sha256.Sha256((function 'noWork')).peek -> [32]u8 */
static inline R4SdkDataSlot R4SdkDataSha256_peek(uint32_t reserved, const R4SdkDataSha256 * p0, R4SdkDataNative_Value158 *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,95u,a,1u,output);
}
/* json.Document.init -> json.Document */
static inline R4SdkDataSlot R4SdkDataJsonDocument_init(uint32_t reserved, const R4SdkDataNative_r4dev_Context * p0, const uint8_t * p1, uintptr_t n1, uint8_t * p2, uintptr_t n2, R4SdkDataJsonDocument *output) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,96u,a,3u,output);
}
/* json.Document.token -> json.Token */
static inline R4SdkDataSlot R4SdkDataJsonDocument_token(uint32_t reserved, const R4SdkDataJsonDocument * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,97u,a,1u,0);
}
/* json.Document.tokenBytes -> ?[]const u8 */
static inline R4SdkDataSlot R4SdkDataJsonDocument_tokenBytes(uint32_t reserved, const R4SdkDataJsonDocument * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,98u,a,1u,0);
}
/* json.Document.next -> error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}!void */
static inline R4SdkDataSlot R4SdkDataJsonDocument_next(uint32_t reserved, R4SdkDataJsonDocument * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,99u,a,1u,0);
}
/* json.Document.select -> error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}!void */
static inline R4SdkDataSlot R4SdkDataJsonDocument_select(uint32_t reserved, R4SdkDataJsonDocument * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,100u,a,2u,0);
}
/* json.Document.value -> error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}![]u8 */
static inline R4SdkDataSlot R4SdkDataJsonDocument_value(uint32_t reserved, R4SdkDataJsonDocument * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,101u,a,2u,0);
}
/* json.Document.readString -> error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}![]u8 */
static inline R4SdkDataSlot R4SdkDataJsonDocument_readString(uint32_t reserved, R4SdkDataJsonDocument * p0, const uint8_t * p1, uintptr_t n1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,102u,a,3u,0);
}
/* json.Document.readU64 -> error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}!u64 */
static inline R4SdkDataSlot R4SdkDataJsonDocument_readU64(uint32_t reserved, R4SdkDataJsonDocument * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,103u,a,2u,0);
}
/* json.Document.enter -> error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}!void */
static inline R4SdkDataSlot R4SdkDataJsonDocument_enter(uint32_t reserved, R4SdkDataJsonDocument * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,104u,a,1u,0);
}
/* json.Document.nextElement -> error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}!void */
static inline R4SdkDataSlot R4SdkDataJsonDocument_nextElement(uint32_t reserved, R4SdkDataJsonDocument * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,105u,a,1u,0);
}
/* json.Document.set -> error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}![]u8 */
static inline R4SdkDataSlot R4SdkDataJsonDocument_set(uint32_t reserved, R4SdkDataJsonDocument * p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,106u,a,4u,0);
}
/* json.Document.remove -> error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}![]u8 */
static inline R4SdkDataSlot R4SdkDataJsonDocument_remove(uint32_t reserved, R4SdkDataJsonDocument * p0, const uint8_t * p1, uintptr_t n1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,107u,a,3u,0);
}
/* json.Document.insert -> error{BadDocument,BadPath,BadRequest,DepthExceeded,NotFound,OutputTooSmall,Unavailable,UnknownOperation,WrongToken}![]u8 */
static inline R4SdkDataSlot R4SdkDataJsonDocument_insert(uint32_t reserved, R4SdkDataJsonDocument * p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,108u,a,4u,0);
}
/* zip.Entry.name -> error{BadRequest,Bounds,Checksum,DuplicatePath,Inflate,InvalidArchive,Limit,OutputTooSmall,Stale,Unavailable,UnsafePath,Unsupported}![]const u8 */
static inline R4SdkDataSlot R4SdkDataZipEntry_name(uint32_t reserved, const R4SdkDataZipEntry * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,109u,a,2u,0);
}
/* zip.Context.inspect -> error{BadRequest,Bounds,Checksum,DuplicatePath,Inflate,InvalidArchive,Limit,OutputTooSmall,Stale,Unavailable,UnsafePath,Unsupported}!zip.Info */
static inline R4SdkDataSlot R4SdkDataZipContext_inspect(uint32_t reserved, const R4SdkDataZipContext * p0, const uint8_t * p1, uintptr_t n1, R4SdkDataZipEntry * p2, uintptr_t n2, R4SdkDataZipInfo *output) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,110u,a,3u,output);
}
/* zip.Context.begin -> error{BadRequest,Bounds,Checksum,DuplicatePath,Inflate,InvalidArchive,Limit,OutputTooSmall,Stale,Unavailable,UnsafePath,Unsupported}!zip.Progress */
static inline R4SdkDataSlot R4SdkDataZipContext_begin(uint32_t reserved, const R4SdkDataZipContext * p0, const uint8_t * p1, uintptr_t n1, const R4SdkDataZipEntry * p2, uint8_t * p3, uintptr_t n3, R4SdkDataZipWork * p4, R4SdkDataZipProgress *output) {
 (void)reserved; R4SdkDataSlot a[5]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.ptr=(void *)p4,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,111u,a,5u,output);
}
/* zip.Context.step -> error{BadRequest,Bounds,Checksum,DuplicatePath,Inflate,InvalidArchive,Limit,OutputTooSmall,Stale,Unavailable,UnsafePath,Unsupported}!zip.Progress */
static inline R4SdkDataSlot R4SdkDataZipContext_step(uint32_t reserved, const R4SdkDataZipContext * p0, R4SdkDataZipWork * p1, uint32_t p2, R4SdkDataZipProgress *output) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,112u,a,3u,output);
}
/* zip.Context.beginStream -> error{BadRequest,Bounds,Checksum,DuplicatePath,Inflate,InvalidArchive,Limit,OutputTooSmall,Stale,Unavailable,UnsafePath,Unsupported}!zip.Progress */
static inline R4SdkDataSlot R4SdkDataZipContext_beginStream(uint32_t reserved, const R4SdkDataZipContext * p0, const uint8_t * p1, uintptr_t n1, const R4SdkDataZipEntry * p2, uint8_t * p3, uintptr_t n3, R4SdkDataZipWork * p4, R4SdkDataZipProgress *output) {
 (void)reserved; R4SdkDataSlot a[5]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.ptr=(void *)p4,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,113u,a,5u,output);
}
/* zip.Context.streamStep -> error{BadRequest,Bounds,Checksum,DuplicatePath,Inflate,InvalidArchive,Limit,OutputTooSmall,Stale,Unavailable,UnsafePath,Unsupported}!zip.Progress */
static inline R4SdkDataSlot R4SdkDataZipContext_streamStep(uint32_t reserved, const R4SdkDataZipContext * p0, R4SdkDataZipWork * p1, uint32_t p2, R4SdkDataZipProgress *output) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,114u,a,3u,output);
}
/* raster.Image.pixelCount -> usize */
static inline R4SdkDataSlot R4SdkDataRasterImage_pixelCount(uint32_t reserved, const R4SdkDataRasterImage * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,115u,a,1u,0);
}
/* raster.Image.pixels -> []u32 */
static inline R4SdkDataSlot R4SdkDataRasterImage_pixels(uint32_t reserved, const R4SdkDataRasterImage * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,116u,a,1u,0);
}
/* raster.Image.pixelsConst -> []const u32 */
static inline R4SdkDataSlot R4SdkDataRasterImage_pixelsConst(uint32_t reserved, const R4SdkDataRasterImage * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,117u,a,1u,0);
}
/* raster.Image.row -> ?[]u32 */
static inline R4SdkDataSlot R4SdkDataRasterImage_row(uint32_t reserved, const R4SdkDataRasterImage * p0, uint32_t p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,118u,a,2u,0);
}
/* raster.Image.setPixel -> bool */
static inline R4SdkDataSlot R4SdkDataRasterImage_setPixel(uint32_t reserved, const R4SdkDataRasterImage * p0, uint32_t p1, uint32_t p2, uint32_t p3) {
 (void)reserved; R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,119u,a,4u,0);
}
/* raster.Image.pixelAt -> ?u32 */
static inline R4SdkDataSlot R4SdkDataRasterImage_pixelAt(uint32_t reserved, const R4SdkDataRasterImage * p0, uint32_t p1, uint32_t p2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,120u,a,3u,0);
}
/* raster.Image.fill -> void */
static inline R4SdkDataSlot R4SdkDataRasterImage_fill(uint32_t reserved, const R4SdkDataRasterImage * p0, uint32_t p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,121u,a,2u,0);
}
/* raster.Image.resize -> error{InvalidSize,TooLarge}!void */
static inline R4SdkDataSlot R4SdkDataRasterImage_resize(uint32_t reserved, R4SdkDataRasterImage * p0, uint32_t p1, uint32_t p2, uint32_t p3) {
 (void)reserved; R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,122u,a,4u,0);
}
/* secure_random.Provider.bind -> void */
static inline R4SdkDataSlot R4SdkDataRandomProvider_bind(uint32_t reserved, const R4SdkDataRandomProvider * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,123u,a,1u,0);
}
/* secure_random.Provider.available -> bool */
static inline R4SdkDataSlot R4SdkDataRandomProvider_available(uint32_t reserved, const R4SdkDataRandomProvider * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,124u,a,1u,0);
}
/* secure_random.Provider.fill -> bool */
static inline R4SdkDataSlot R4SdkDataRandomProvider_fill(uint32_t reserved, const R4SdkDataRandomProvider * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,125u,a,2u,0);
}
/* cpu_memory.Policy.fromInfo -> cpu_memory.Policy */
static inline R4SdkDataSlot R4SdkDataMemoryPolicy_fromInfo(uint32_t reserved, const R4CpuAccelerationInfo * p0, R4SdkDataMemoryPolicy *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,126u,a,1u,output);
}
/* cpu_memory.Policy.move -> void */
static inline R4SdkDataSlot R4SdkDataMemoryPolicy_move(uint32_t reserved, const R4SdkDataMemoryPolicy * p0, uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,127u,a,3u,0);
}
/* web_encoding.Encoding.name -> []const u8 */
static inline R4SdkDataSlot R4SdkDataEncodingEncoding_name(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,128u,a,1u,0);
}
/* web_encoding.Decoder.init -> web_encoding.Decoder */
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_init(uint32_t reserved, uint32_t p0, uint8_t p1, uint8_t p2, R4SdkDataEncodingDecoder *output) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,129u,a,3u,output);
}
/* web_encoding.Decoder.packState -> u64 */
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_packState(uint32_t reserved, const R4SdkDataEncodingDecoder * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,130u,a,1u,0);
}
/* web_encoding.Decoder.fromPackedState -> web_encoding.Decoder */
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_fromPackedState(uint32_t reserved, uint64_t p0, R4SdkDataEncodingDecoder *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,131u,a,1u,output);
}
/* web_encoding.Decoder.decode -> error{InputTooLarge,InvalidSequence,OutputTooSmall,UnknownEncoding}![]const u8 */
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_decode(uint32_t reserved, R4SdkDataEncodingDecoder * p0, const uint8_t * p1, uintptr_t n1, uint8_t * p2, uintptr_t n2, uint8_t p3) {
 (void)reserved; R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,132u,a,4u,0);
}
/* web_url.SearchParams.init -> error{InvalidUrl,PairLimit,TooLong}!web_url.SearchParams */
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_init(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkDataUrlSearchParams *output) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,133u,a,1u,output);
}
/* web_url.SearchParams.replace -> error{InvalidUrl,PairLimit,TooLong}!void */
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_replace(uint32_t reserved, R4SdkDataUrlSearchParams * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,134u,a,2u,0);
}
/* web_url.SearchParams.name -> []const u8 */
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_name(uint32_t reserved, const R4SdkDataUrlSearchParams * p0, uint64_t p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,135u,a,2u,0);
}
/* web_url.SearchParams.value -> []const u8 */
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_value(uint32_t reserved, const R4SdkDataUrlSearchParams * p0, uint64_t p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,136u,a,2u,0);
}
/* web_url.SearchParams.append -> error{InvalidUrl,PairLimit,TooLong}!void */
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_append(uint32_t reserved, R4SdkDataUrlSearchParams * p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,137u,a,3u,0);
}
/* web_url.SearchParams.get -> ?[]const u8 */
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_get(uint32_t reserved, const R4SdkDataUrlSearchParams * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,138u,a,2u,0);
}
/* web_url.SearchParams.has -> bool */
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_has(uint32_t reserved, const R4SdkDataUrlSearchParams * p0, const uint8_t * p1, uintptr_t n1, R4SdkDataSlot p2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = p2;
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,139u,a,3u,0);
}
/* web_url.SearchParams.delete -> void */
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_delete(uint32_t reserved, R4SdkDataUrlSearchParams * p0, const uint8_t * p1, uintptr_t n1, R4SdkDataSlot p2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = p2;
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,140u,a,3u,0);
}
/* web_url.SearchParams.set -> error{InvalidUrl,PairLimit,TooLong}!void */
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_set(uint32_t reserved, R4SdkDataUrlSearchParams * p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,141u,a,3u,0);
}
/* web_url.SearchParams.sort -> void */
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_sort(uint32_t reserved, R4SdkDataUrlSearchParams * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,142u,a,1u,0);
}
/* web_url.SearchParams.serialize -> error{InvalidUrl,PairLimit,TooLong}![]const u8 */
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_serialize(uint32_t reserved, const R4SdkDataUrlSearchParams * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,143u,a,2u,0);
}
/* r4cp.Project.sources -> []const r4cp.Item */
static inline R4SdkDataSlot R4SdkDataProjectProject_sources(uint32_t reserved, const R4SdkDataProjectProject * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,144u,a,1u,0);
}
/* r4cp.Project.imports -> []const r4cp.Item */
static inline R4SdkDataSlot R4SdkDataProjectProject_imports(uint32_t reserved, const R4SdkDataProjectProject * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,145u,a,1u,0);
}
/* r4cp.Project.exports -> []const r4cp.Item */
static inline R4SdkDataSlot R4SdkDataProjectProject_exports(uint32_t reserved, const R4SdkDataProjectProject * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,146u,a,1u,0);
}
/* r4cp.Project.metadata -> []const r4cp.Item */
static inline R4SdkDataSlot R4SdkDataProjectProject_metadata(uint32_t reserved, const R4SdkDataProjectProject * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,147u,a,1u,0);
}
/* r4cp.Project.contracts -> []const r4cp.Item */
static inline R4SdkDataSlot R4SdkDataProjectProject_contracts(uint32_t reserved, const R4SdkDataProjectProject * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,148u,a,1u,0);
}
/* r4cp.Project.hasR4XStart -> bool */
static inline R4SdkDataSlot R4SdkDataProjectProject_hasR4XStart(uint32_t reserved, const R4SdkDataProjectProject * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,149u,a,1u,0);
}
/* r4cp.Project.profileClass -> ?r4cp.ProfileClass */
static inline R4SdkDataSlot R4SdkDataProjectProject_profileClass(uint32_t reserved, const R4SdkDataProjectProject * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,150u,a,1u,0);
}
/* r4cp_convert.Result.ok -> bool */
static inline R4SdkDataSlot R4SdkDataProjectConvertResult_ok(uint32_t reserved, const R4SdkDataProjectConvertResult * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,151u,a,1u,0);
}
/* module_manifest.Kind.text -> []const u8 */
static inline R4SdkDataSlot R4SdkDataManifestKind_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,152u,a,1u,0);
}
/* module_manifest.Language.text -> []const u8 */
static inline R4SdkDataSlot R4SdkDataManifestLanguage_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,153u,a,1u,0);
}
/* module_manifest.AppClass.text -> []const u8 */
static inline R4SdkDataSlot R4SdkDataManifestAppClass_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,154u,a,1u,0);
}
/* module_manifest.EntryMode.text -> []const u8 */
static inline R4SdkDataSlot R4SdkDataManifestEntryMode_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,155u,a,1u,0);
}
/* module_manifest.ImageScope.text -> []const u8 */
static inline R4SdkDataSlot R4SdkDataManifestImageScope_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,156u,a,1u,0);
}
/* module_manifest.Optimization.text -> []const u8 */
static inline R4SdkDataSlot R4SdkDataManifestOptimization_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,157u,a,1u,0);
}
/* module_manifest.ModuleRole.text -> []const u8 */
static inline R4SdkDataSlot R4SdkDataManifestModuleRole_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,158u,a,1u,0);
}
/* version_info.SemanticVersion.eql -> bool */
static inline R4SdkDataSlot R4SdkDataVersionSemanticVersion_eql(uint32_t reserved, const R4SdkDataVersionSemanticVersion * p0, const R4SdkDataVersionSemanticVersion * p1) {
 (void)reserved; R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,159u,a,2u,0);
}
/* r4u_manifest.ComponentKind.text -> []const u8 */
static inline R4SdkDataSlot R4SdkDataUpdateMetadataComponentKind_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,160u,a,1u,0);
}
/* r4u_manifest.ComponentKind.parse -> ?r4u_manifest.ComponentKind */
static inline R4SdkDataSlot R4SdkDataUpdateMetadataComponentKind_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,161u,a,1u,0);
}
/* r4u_manifest.InstallMode.text -> []const u8 */
static inline R4SdkDataSlot R4SdkDataUpdateMetadataInstallMode_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,162u,a,1u,0);
}
/* r4u_manifest.InstallMode.parse -> ?r4u_manifest.InstallMode */
static inline R4SdkDataSlot R4SdkDataUpdateMetadataInstallMode_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,163u,a,1u,0);
}
/* r4u_manifest.Priority.text -> []const u8 */
static inline R4SdkDataSlot R4SdkDataUpdateMetadataPriority_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,164u,a,1u,0);
}
/* r4u_manifest.Priority.parse -> ?r4u_manifest.Priority */
static inline R4SdkDataSlot R4SdkDataUpdateMetadataPriority_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,165u,a,1u,0);
}
/* r4u_manifest.RequirementState.text -> []const u8 */
static inline R4SdkDataSlot R4SdkDataUpdateMetadataRequirementState_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,166u,a,1u,0);
}
/* r4u_manifest.RequirementState.parse -> ?r4u_manifest.RequirementState */
static inline R4SdkDataSlot R4SdkDataUpdateMetadataRequirementState_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,167u,a,1u,0);
}
/* r4u_artifact.Identity.nameText -> []const u8 */
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_nameText(uint32_t reserved, const R4SdkDataArtifactIdentity * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,168u,a,1u,0);
}
/* r4u_artifact.Identity.versionText -> []const u8 */
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_versionText(uint32_t reserved, const R4SdkDataArtifactIdentity * p0) {
 (void)reserved; R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,169u,a,1u,0);
}
/* r4u_artifact.SliceReader.readAt -> bool */
static inline R4SdkDataSlot R4SdkDataArtifactSliceReader_readAt(uint32_t reserved, const R4SdkDataArtifactSliceReader * p0, uint64_t p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,170u,a,3u,0);
}
/* data_helper_adapters.Reader.readAt -> bool */
static inline R4SdkDataSlot R4SdkDataReader_readAt(uint32_t reserved, const R4SdkDataReader * p0, uint64_t p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,171u,a,3u,0);
}
static inline R4SdkDataSlot R4SdkDataJsonToken_create(R4SdkDataJsonToken *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,0u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataJsonToken_inspectNative(const R4SdkDataJsonToken *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,0u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value1_create(R4SdkDataNative_Value1 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,1u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value1_inspectNative(const R4SdkDataNative_Value1 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,1u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_create(R4SdkDataJsonCursor *output) {
 R4SdkDataSlot a[10]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2].flags=R4SDKDATA_DEFAULT;
 a[3].flags=R4SDKDATA_DEFAULT;
 a[4].flags=R4SDKDATA_DEFAULT;
 a[5].flags=R4SDKDATA_DEFAULT;
 a[6].flags=R4SDKDATA_DEFAULT;
 a[7].flags=R4SDKDATA_DEFAULT;
 a[8].flags=R4SDKDATA_DEFAULT;
 a[9].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,2u,a,10u,output);
}
static inline R4SdkDataSlot R4SdkDataJsonCursor_from_fields(R4SdkDataJsonCursor *output, R4SdkDataSlot p0, uint32_t p1, uint32_t p2, uint32_t p3, R4SdkDataSlot p4, uint32_t p5, uint32_t p6, uint32_t p7, uint32_t p8, uint32_t p9) {
 R4SdkDataSlot a[10]={0};
 a[0] = p0;
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 a[4] = p4;
 a[5] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKDATA_PRESENT};
 a[7] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKDATA_PRESENT};
 a[8] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKDATA_PRESENT};
 a[9] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,2u,a,10u,output);
}
static inline R4SdkDataSlot R4SdkDataJsonCursor_get_doc(const R4SdkDataJsonCursor *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_set_doc(R4SdkDataJsonCursor *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_get_doc_len(const R4SdkDataJsonCursor *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_set_doc_len(R4SdkDataJsonCursor *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_get_pos(const R4SdkDataJsonCursor *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_set_pos(R4SdkDataJsonCursor *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_get_depth(const R4SdkDataJsonCursor *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_set_depth(R4SdkDataJsonCursor *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_get_depth_stack(const R4SdkDataJsonCursor *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_set_depth_stack(R4SdkDataJsonCursor *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_get_depth_capacity(const R4SdkDataJsonCursor *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,5u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_set_depth_capacity(R4SdkDataJsonCursor *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_get_token(const R4SdkDataJsonCursor *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_set_token(R4SdkDataJsonCursor *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_get_token_start(const R4SdkDataJsonCursor *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,7u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_set_token_start(R4SdkDataJsonCursor *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,7u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_get_token_end(const R4SdkDataJsonCursor *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,8u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_set_token_end(R4SdkDataJsonCursor *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,8u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_get_reserved(const R4SdkDataJsonCursor *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,9u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_set_reserved(R4SdkDataJsonCursor *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,2u,9u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonCursor_inspectNative(const R4SdkDataJsonCursor *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,2u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value3_create(R4SdkDataNative_Value3 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,3u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value3_inspectNative(const R4SdkDataNative_Value3 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,3u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value4_create(R4SdkDataNative_Value4 *output, const uint8_t * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,4u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value4_inspectNative(const R4SdkDataNative_Value4 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,4u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value5_create(R4SdkDataNative_Value5 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,5u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value5_inspectNative(const R4SdkDataNative_Value5 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,5u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value6_create(R4SdkDataNative_Value6 *output, uint8_t * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,6u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value6_inspectNative(const R4SdkDataNative_Value6 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,6u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_create(R4SdkDataJsonRequest *output) {
 R4SdkDataSlot a[7]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2].flags=R4SDKDATA_DEFAULT;
 a[3].flags=R4SDKDATA_DEFAULT;
 a[4].flags=R4SDKDATA_DEFAULT;
 a[5].flags=R4SDKDATA_DEFAULT;
 a[6].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,7u,a,7u,output);
}
static inline R4SdkDataSlot R4SdkDataJsonRequest_from_fields(R4SdkDataJsonRequest *output, R4SdkDataSlot p0, R4SdkDataSlot p1, uint32_t p2, R4SdkDataSlot p3, uint32_t p4, R4SdkDataSlot p5, uint32_t p6) {
 R4SdkDataSlot a[7]={0};
 a[0] = p0;
 a[1] = p1;
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = p3;
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 a[5] = p5;
 a[6] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,7u,a,7u,output);
}
static inline R4SdkDataSlot R4SdkDataJsonRequest_get_cursor(const R4SdkDataJsonRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_set_cursor(R4SdkDataJsonRequest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_get_doc(const R4SdkDataJsonRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_set_doc(R4SdkDataJsonRequest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_get_doc_len(const R4SdkDataJsonRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_set_doc_len(R4SdkDataJsonRequest *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_get_path(const R4SdkDataJsonRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_set_path(R4SdkDataJsonRequest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_get_path_len(const R4SdkDataJsonRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_set_path_len(R4SdkDataJsonRequest *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_get_value(const R4SdkDataJsonRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,5u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_set_value(R4SdkDataJsonRequest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_get_value_len(const R4SdkDataJsonRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_set_value_len(R4SdkDataJsonRequest *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,7u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonRequest_inspectNative(const R4SdkDataJsonRequest *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,7u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value8_create(R4SdkDataNative_Value8 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,8u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value8_inspectNative(const R4SdkDataNative_Value8 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,8u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value9_create(R4SdkDataNative_Value9 *output, R4SdkDataJsonCursor * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,9u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value9_inspectNative(const R4SdkDataNative_Value9 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,9u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataJsonDocument_create(R4SdkDataJsonDocument *output, const R4SdkDataNative_r4dev_Context * p0, const R4SdkDataJsonCursor * p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,10u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataJsonDocument_from_fields(R4SdkDataJsonDocument *output, const R4SdkDataNative_r4dev_Context * p0, const R4SdkDataJsonCursor * p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,10u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataJsonDocument_get_dev(const R4SdkDataJsonDocument *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,10u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataJsonDocument_set_dev(R4SdkDataJsonDocument *self, const R4SdkDataNative_r4dev_Context * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,10u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonDocument_get_cursor(const R4SdkDataJsonDocument *self, R4SdkDataJsonCursor *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,10u,1u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataJsonDocument_set_cursor(R4SdkDataJsonDocument *self, const R4SdkDataJsonCursor * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,10u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataJsonDocument_inspectNative(const R4SdkDataJsonDocument *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,10u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value11_create(R4SdkDataNative_Value11 *output, const R4SdkDataNative_r4dev_Context * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,11u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value11_inspectNative(const R4SdkDataNative_Value11 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,11u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value13_inspectNative(const R4SdkDataNative_Value13 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,13u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_create(R4SdkDataZipInfo *output) {
 R4SdkDataSlot a[7]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2].flags=R4SDKDATA_DEFAULT;
 a[3].flags=R4SDKDATA_DEFAULT;
 a[4].flags=R4SDKDATA_DEFAULT;
 a[5].flags=R4SDKDATA_DEFAULT;
 a[6].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,14u,a,7u,output);
}
static inline R4SdkDataSlot R4SdkDataZipInfo_from_fields(R4SdkDataZipInfo *output, uint32_t p0, uint32_t p1, uint32_t p2, uint32_t p3, uint64_t p4, uint64_t p5, uint64_t p6) {
 R4SdkDataSlot a[7]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,14u,a,7u,output);
}
static inline R4SdkDataSlot R4SdkDataZipInfo_get_version(const R4SdkDataZipInfo *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_set_version(R4SdkDataZipInfo *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_get_size(const R4SdkDataZipInfo *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_set_size(R4SdkDataZipInfo *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_get_entries(const R4SdkDataZipInfo *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_set_entries(R4SdkDataZipInfo *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_get_files(const R4SdkDataZipInfo *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_set_files(R4SdkDataZipInfo *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_get_total_bytes(const R4SdkDataZipInfo *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_set_total_bytes(R4SdkDataZipInfo *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_get_central_offset(const R4SdkDataZipInfo *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,5u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_set_central_offset(R4SdkDataZipInfo *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_get_central_bytes(const R4SdkDataZipInfo *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_set_central_bytes(R4SdkDataZipInfo *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,14u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipInfo_inspectNative(const R4SdkDataZipInfo *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,14u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_create(R4SdkDataZipEntry *output) {
 R4SdkDataSlot a[12]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2].flags=R4SDKDATA_DEFAULT;
 a[3].flags=R4SDKDATA_DEFAULT;
 a[4].flags=R4SDKDATA_DEFAULT;
 a[5].flags=R4SDKDATA_DEFAULT;
 a[6].flags=R4SDKDATA_DEFAULT;
 a[7].flags=R4SDKDATA_DEFAULT;
 a[8].flags=R4SDKDATA_DEFAULT;
 a[9].flags=R4SDKDATA_DEFAULT;
 a[10].flags=R4SDKDATA_DEFAULT;
 a[11].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,15u,a,12u,output);
}
static inline R4SdkDataSlot R4SdkDataZipEntry_from_fields(R4SdkDataZipEntry *output, uint64_t p0, uint64_t p1, uint64_t p2, uint64_t p3, uint64_t p4, uint64_t p5, uint64_t p6, uint32_t p7, uint32_t p8, uint16_t p9, uint16_t p10, uint32_t p11) {
 R4SdkDataSlot a[12]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKDATA_PRESENT};
 a[7] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKDATA_PRESENT};
 a[8] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKDATA_PRESENT};
 a[9] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKDATA_PRESENT};
 a[10] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKDATA_PRESENT};
 a[11] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,15u,a,12u,output);
}
static inline R4SdkDataSlot R4SdkDataZipEntry_get_central_offset(const R4SdkDataZipEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_set_central_offset(R4SdkDataZipEntry *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_get_local_offset(const R4SdkDataZipEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_set_local_offset(R4SdkDataZipEntry *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_get_data_offset(const R4SdkDataZipEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_set_data_offset(R4SdkDataZipEntry *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_get_end_offset(const R4SdkDataZipEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_set_end_offset(R4SdkDataZipEntry *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_get_compressed_bytes(const R4SdkDataZipEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_set_compressed_bytes(R4SdkDataZipEntry *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_get_bytes(const R4SdkDataZipEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,5u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_set_bytes(R4SdkDataZipEntry *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_get_name_offset(const R4SdkDataZipEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_set_name_offset(R4SdkDataZipEntry *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_get_name_bytes(const R4SdkDataZipEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,7u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_set_name_bytes(R4SdkDataZipEntry *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,7u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_get_crc32(const R4SdkDataZipEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,8u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_set_crc32(R4SdkDataZipEntry *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,8u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_get_method(const R4SdkDataZipEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,9u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_set_method(R4SdkDataZipEntry *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,9u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_get_flags(const R4SdkDataZipEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,10u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_set_flags(R4SdkDataZipEntry *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,10u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_get_directory(const R4SdkDataZipEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,11u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_set_directory(R4SdkDataZipEntry *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,15u,11u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipEntry_inspectNative(const R4SdkDataZipEntry *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,15u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataZipProgress_create(R4SdkDataZipProgress *output) {
 R4SdkDataSlot a[3]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,16u,a,3u,output);
}
static inline R4SdkDataSlot R4SdkDataZipProgress_from_fields(R4SdkDataZipProgress *output, uint64_t p0, uint32_t p1, uint32_t p2) {
 R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,16u,a,3u,output);
}
static inline R4SdkDataSlot R4SdkDataZipProgress_get_written(const R4SdkDataZipProgress *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,16u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipProgress_set_written(R4SdkDataZipProgress *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,16u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipProgress_get_done(const R4SdkDataZipProgress *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,16u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipProgress_set_done(R4SdkDataZipProgress *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,16u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipProgress_get_reserved(const R4SdkDataZipProgress *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,16u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipProgress_set_reserved(R4SdkDataZipProgress *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,16u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipProgress_inspectNative(const R4SdkDataZipProgress *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,16u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_create(R4SdkDataZipRequest *output) {
 R4SdkDataSlot a[13]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2].flags=R4SDKDATA_DEFAULT;
 a[3].flags=R4SDKDATA_DEFAULT;
 a[4].flags=R4SDKDATA_DEFAULT;
 a[5].flags=R4SDKDATA_DEFAULT;
 a[6].flags=R4SDKDATA_DEFAULT;
 a[7].flags=R4SDKDATA_DEFAULT;
 a[8].flags=R4SDKDATA_DEFAULT;
 a[9].flags=R4SDKDATA_DEFAULT;
 a[10].flags=R4SDKDATA_DEFAULT;
 a[11].flags=R4SDKDATA_DEFAULT;
 a[12].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,17u,a,13u,output);
}
static inline R4SdkDataSlot R4SdkDataZipRequest_from_fields(R4SdkDataZipRequest *output, uint32_t p0, uint32_t p1, R4SdkDataSlot p2, uint64_t p3, R4SdkDataSlot p4, uint32_t p5, uint32_t p6, R4SdkDataSlot p7, R4SdkDataSlot p8, uint32_t p9, uint32_t p10, R4SdkDataSlot p11, uint64_t p12) {
 R4SdkDataSlot a[13]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = p2;
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 a[4] = p4;
 a[5] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKDATA_PRESENT};
 a[7] = p7;
 a[8] = p8;
 a[9] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKDATA_PRESENT};
 a[10] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKDATA_PRESENT};
 a[11] = p11;
 a[12] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,17u,a,13u,output);
}
static inline R4SdkDataSlot R4SdkDataZipRequest_get_version(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_version(R4SdkDataZipRequest *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_get_size(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_size(R4SdkDataZipRequest *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_get_archive(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_archive(R4SdkDataZipRequest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_get_archive_bytes(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_archive_bytes(R4SdkDataZipRequest *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_get_entries(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_entries(R4SdkDataZipRequest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_get_entry_capacity(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,5u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_entry_capacity(R4SdkDataZipRequest *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_get_step_bytes(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_step_bytes(R4SdkDataZipRequest *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_get_entry(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,7u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_entry(R4SdkDataZipRequest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,7u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_get_work(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,8u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_work(R4SdkDataZipRequest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,8u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_get_work_len(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,9u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_work_len(R4SdkDataZipRequest *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,9u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_get_reserved(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,10u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_reserved(R4SdkDataZipRequest *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,10u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_get_output(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,11u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_output(R4SdkDataZipRequest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,11u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_get_output_bytes(const R4SdkDataZipRequest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,12u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_set_output_bytes(R4SdkDataZipRequest *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,17u,12u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipRequest_inspectNative(const R4SdkDataZipRequest *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,17u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value18_create(R4SdkDataNative_Value18 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,18u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value18_inspectNative(const R4SdkDataNative_Value18 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,18u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value19_create(R4SdkDataNative_Value19 *output, R4SdkDataZipEntry * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,19u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value19_inspectNative(const R4SdkDataNative_Value19 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,19u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value20_create(R4SdkDataNative_Value20 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,20u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value20_inspectNative(const R4SdkDataNative_Value20 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,20u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value21_create(R4SdkDataNative_Value21 *output, const R4SdkDataZipEntry * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,21u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value21_inspectNative(const R4SdkDataNative_Value21 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,21u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value22_create(R4SdkDataNative_Value22 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,22u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value22_inspectNative(const R4SdkDataNative_Value22 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,22u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value23_create(R4SdkDataNative_Value23 *output, uint8_t * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,23u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value23_inspectNative(const R4SdkDataNative_Value23 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,23u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataZipWork_create(R4SdkDataZipWork *output) {
 R4SdkDataSlot a[1]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,24u,a,1u,output);
}
static inline R4SdkDataSlot R4SdkDataZipWork_from_fields(R4SdkDataZipWork *output, const R4SdkDataNative_Value25 * p0) {
 R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,24u,a,1u,output);
}
static inline R4SdkDataSlot R4SdkDataZipWork_get_data(const R4SdkDataZipWork *self, R4SdkDataNative_Value25 *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,24u,0u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataZipWork_set_data(R4SdkDataZipWork *self, const R4SdkDataNative_Value25 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,24u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipWork_inspectNative(const R4SdkDataZipWork *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,24u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value25_create(R4SdkDataNative_Value25 *output, const R4SdkDataNative_Value25 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,25u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value25_inspectNative(const R4SdkDataNative_Value25 *self, R4SdkDataNative_Value25 *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,25u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataZipContext_create(R4SdkDataZipContext *output, const R4SdkDataNative_r4dev_Context * p0) {
 R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,26u,a,1u,output);
}
static inline R4SdkDataSlot R4SdkDataZipContext_from_fields(R4SdkDataZipContext *output, const R4SdkDataNative_r4dev_Context * p0) {
 R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,26u,a,1u,output);
}
static inline R4SdkDataSlot R4SdkDataZipContext_get_dev(const R4SdkDataZipContext *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,26u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataZipContext_set_dev(R4SdkDataZipContext *self, const R4SdkDataNative_r4dev_Context * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,26u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataZipContext_inspectNative(const R4SdkDataZipContext *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,26u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataIcoDirectory_create(R4SdkDataIcoDirectory *output, uint16_t p0) {
 R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,27u,a,1u,output);
}
static inline R4SdkDataSlot R4SdkDataIcoDirectory_from_fields(R4SdkDataIcoDirectory *output, uint16_t p0) {
 R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,27u,a,1u,output);
}
static inline R4SdkDataSlot R4SdkDataIcoDirectory_get_count(const R4SdkDataIcoDirectory *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,27u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoDirectory_set_count(R4SdkDataIcoDirectory *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,27u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoDirectory_inspectNative(const R4SdkDataIcoDirectory *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,27u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_create(R4SdkDataIcoEntry *output, uint16_t p0, uint16_t p1, uint8_t p2, uint16_t p3, uint16_t p4, uint32_t p5, uint32_t p6) {
 R4SdkDataSlot a[7]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,28u,a,7u,output);
}
static inline R4SdkDataSlot R4SdkDataIcoEntry_from_fields(R4SdkDataIcoEntry *output, uint16_t p0, uint16_t p1, uint8_t p2, uint16_t p3, uint16_t p4, uint32_t p5, uint32_t p6) {
 R4SdkDataSlot a[7]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,28u,a,7u,output);
}
static inline R4SdkDataSlot R4SdkDataIcoEntry_get_width(const R4SdkDataIcoEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_set_width(R4SdkDataIcoEntry *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_get_height(const R4SdkDataIcoEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_set_height(R4SdkDataIcoEntry *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_get_color_count(const R4SdkDataIcoEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_set_color_count(R4SdkDataIcoEntry *self, uint8_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_get_planes(const R4SdkDataIcoEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_set_planes(R4SdkDataIcoEntry *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_get_bit_count(const R4SdkDataIcoEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_set_bit_count(R4SdkDataIcoEntry *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_get_bytes_in_res(const R4SdkDataIcoEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,5u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_set_bytes_in_res(R4SdkDataIcoEntry *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_get_image_offset(const R4SdkDataIcoEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_set_image_offset(R4SdkDataIcoEntry *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,28u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoEntry_inspectNative(const R4SdkDataIcoEntry *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,28u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_create(R4SdkDataIcoBitmapImage *output, uint32_t p0, uint32_t p1, uint16_t p2, uint64_t p3, uint64_t p4) {
 R4SdkDataSlot a[9]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 a[5].flags=R4SDKDATA_DEFAULT;
 a[6].flags=R4SDKDATA_DEFAULT;
 a[7].flags=R4SDKDATA_DEFAULT;
 a[8].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,29u,a,9u,output);
}
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_from_fields(R4SdkDataIcoBitmapImage *output, uint32_t p0, uint32_t p1, uint16_t p2, uint64_t p3, uint64_t p4, uint64_t p5, uint32_t p6, uint64_t p7, uint64_t p8) {
 R4SdkDataSlot a[9]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKDATA_PRESENT};
 a[7] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKDATA_PRESENT};
 a[8] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,29u,a,9u,output);
}
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_get_width(const R4SdkDataIcoBitmapImage *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_set_width(R4SdkDataIcoBitmapImage *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_get_height(const R4SdkDataIcoBitmapImage *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_set_height(R4SdkDataIcoBitmapImage *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_get_bpp(const R4SdkDataIcoBitmapImage *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_set_bpp(R4SdkDataIcoBitmapImage *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_get_pixel_offset(const R4SdkDataIcoBitmapImage *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_set_pixel_offset(R4SdkDataIcoBitmapImage *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_get_stride(const R4SdkDataIcoBitmapImage *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_set_stride(R4SdkDataIcoBitmapImage *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_get_palette_offset(const R4SdkDataIcoBitmapImage *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,5u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_set_palette_offset(R4SdkDataIcoBitmapImage *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_get_palette_count(const R4SdkDataIcoBitmapImage *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_set_palette_count(R4SdkDataIcoBitmapImage *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_get_mask_offset(const R4SdkDataIcoBitmapImage *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,7u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_set_mask_offset(R4SdkDataIcoBitmapImage *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,7u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_get_mask_stride(const R4SdkDataIcoBitmapImage *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,8u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_set_mask_stride(R4SdkDataIcoBitmapImage *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,29u,8u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoBitmapImage_inspectNative(const R4SdkDataIcoBitmapImage *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,29u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataIcoPixel_create(R4SdkDataIcoPixel *output, uint32_t p0, uint8_t p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,30u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataIcoPixel_from_fields(R4SdkDataIcoPixel *output, uint32_t p0, uint8_t p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,30u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataIcoPixel_get_rgb(const R4SdkDataIcoPixel *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,30u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoPixel_set_rgb(R4SdkDataIcoPixel *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,30u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoPixel_get_alpha(const R4SdkDataIcoPixel *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,30u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataIcoPixel_set_alpha(R4SdkDataIcoPixel *self, uint8_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,30u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataIcoPixel_inspectNative(const R4SdkDataIcoPixel *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,30u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value31_create(R4SdkDataNative_Value31 *output, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,31u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value31_inspectNative(const R4SdkDataNative_Value31 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,31u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value32_inspectNative(const R4SdkDataNative_Value32 *self, R4SdkDataIcoDirectory *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,32u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value33_inspectNative(const R4SdkDataNative_Value33 *self, R4SdkDataIcoEntry *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,33u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value34_inspectNative(const R4SdkDataNative_Value34 *self, R4SdkDataIcoBitmapImage *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,34u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value35_create(R4SdkDataNative_Value35 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,35u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value35_inspectNative(const R4SdkDataNative_Value35 *self, R4SdkDataIcoPixel *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,35u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value36_create(R4SdkDataNative_Value36 *output, uint32_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,36u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value36_inspectNative(const R4SdkDataNative_Value36 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,36u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value37_create(R4SdkDataNative_Value37 *output, uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,37u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value37_inspectNative(const R4SdkDataNative_Value37 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,37u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataRasterImage_create(R4SdkDataRasterImage *output, uint32_t * p2, uintptr_t n2) {
 R4SdkDataSlot a[3]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,38u,a,3u,output);
}
static inline R4SdkDataSlot R4SdkDataRasterImage_from_fields(R4SdkDataRasterImage *output, uint32_t p0, uint32_t p1, uint32_t * p2, uintptr_t n2) {
 R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,38u,a,3u,output);
}
static inline R4SdkDataSlot R4SdkDataRasterImage_get_width(const R4SdkDataRasterImage *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,38u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataRasterImage_set_width(R4SdkDataRasterImage *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,38u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataRasterImage_get_height(const R4SdkDataRasterImage *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,38u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataRasterImage_set_height(R4SdkDataRasterImage *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,38u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataRasterImage_get_storage(const R4SdkDataRasterImage *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,38u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataRasterImage_set_storage(R4SdkDataRasterImage *self, uint32_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,38u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataRasterImage_inspectNative(const R4SdkDataRasterImage *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,38u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value39_inspectNative(const R4SdkDataNative_Value39 *self, R4SdkDataRasterImage *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,39u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value40_inspectNative(const R4SdkDataNative_Value40 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,40u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataRandomProvider_create(R4SdkDataRandomProvider *output) {
 R4SdkDataSlot a[4]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2].flags=R4SDKDATA_DEFAULT;
 a[3].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,41u,a,4u,output);
}
static inline R4SdkDataSlot R4SdkDataRandomProvider_from_fields(R4SdkDataRandomProvider *output, R4SdkDataSlot p0, R4SdkDataSlot p1, R4SdkDataSlot p2, R4SdkDataSlot p3) {
 R4SdkDataSlot a[4]={0};
 a[0] = p0;
 a[1] = p1;
 a[2] = p2;
 a[3] = p3;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,41u,a,4u,output);
}
static inline R4SdkDataSlot R4SdkDataRandomProvider_get_info(const R4SdkDataRandomProvider *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,41u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataRandomProvider_set_info(R4SdkDataRandomProvider *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,41u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataRandomProvider_get_device(const R4SdkDataRandomProvider *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,41u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataRandomProvider_set_device(R4SdkDataRandomProvider *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,41u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataRandomProvider_get_hardware_info(const R4SdkDataRandomProvider *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,41u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataRandomProvider_set_hardware_info(R4SdkDataRandomProvider *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,41u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataRandomProvider_get_hardware(const R4SdkDataRandomProvider *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,41u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataRandomProvider_set_hardware(R4SdkDataRandomProvider *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,41u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataRandomProvider_inspectNative(const R4SdkDataRandomProvider *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,41u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value42_create(R4SdkDataNative_Value42 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,42u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value42_inspectNative(const R4SdkDataNative_Value42 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,42u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value43_create(R4SdkDataNative_Value43 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,43u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value43_inspectNative(const R4SdkDataNative_Value43 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,43u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value44_create(R4SdkDataNative_Value44 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,44u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value44_inspectNative(const R4SdkDataNative_Value44 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,44u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value45_create(R4SdkDataNative_Value45 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,45u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value45_inspectNative(const R4SdkDataNative_Value45 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,45u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value46_create(R4SdkDataNative_Value46 *output, const R4SdkDataNative_program_Context * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,46u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value46_inspectNative(const R4SdkDataNative_Value46 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,46u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value48_create(R4SdkDataNative_Value48 *output, const R4ProtocolApi2 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,48u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value48_inspectNative(const R4SdkDataNative_Value48 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,48u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value50_create(R4SdkDataNative_Value50 *output, R4EntropySourceInfo * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,50u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value50_inspectNative(const R4SdkDataNative_Value50 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,50u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value52_create(R4SdkDataNative_Value52 *output, const R4CpuAccelerationWork * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,52u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value52_inspectNative(const R4SdkDataNative_Value52 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,52u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataMemoryPolicy_create(R4SdkDataMemoryPolicy *output) {
 R4SdkDataSlot a[1]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,54u,a,1u,output);
}
static inline R4SdkDataSlot R4SdkDataMemoryPolicy_from_fields(R4SdkDataMemoryPolicy *output, uint8_t p0) {
 R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,54u,a,1u,output);
}
static inline R4SdkDataSlot R4SdkDataMemoryPolicy_get_erms(const R4SdkDataMemoryPolicy *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,54u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataMemoryPolicy_set_erms(R4SdkDataMemoryPolicy *self, uint8_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,54u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataMemoryPolicy_inspectNative(const R4SdkDataMemoryPolicy *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,54u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value55_inspectNative(const R4SdkDataNative_Value55 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,55u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataEncodingEncoding_create(R4SdkDataEncodingEncoding *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,56u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataEncodingEncoding_inspectNative(const R4SdkDataEncodingEncoding *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,56u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value57_inspectNative(const R4SdkDataNative_Value57 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,57u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataEncodingEncodeIntoResult_create(R4SdkDataEncodingEncodeIntoResult *output, uint64_t p0, uint64_t p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,58u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataEncodingEncodeIntoResult_from_fields(R4SdkDataEncodingEncodeIntoResult *output, uint64_t p0, uint64_t p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,58u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataEncodingEncodeIntoResult_get_read(const R4SdkDataEncodingEncodeIntoResult *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,58u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataEncodingEncodeIntoResult_set_read(R4SdkDataEncodingEncodeIntoResult *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,58u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataEncodingEncodeIntoResult_get_written(const R4SdkDataEncodingEncodeIntoResult *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,58u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataEncodingEncodeIntoResult_set_written(R4SdkDataEncodingEncodeIntoResult *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,58u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataEncodingEncodeIntoResult_inspectNative(const R4SdkDataEncodingEncodeIntoResult *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,58u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_create(R4SdkDataEncodingDecoder *output, uint32_t p0) {
 R4SdkDataSlot a[7]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2].flags=R4SDKDATA_DEFAULT;
 a[3].flags=R4SDKDATA_DEFAULT;
 a[4].flags=R4SDKDATA_DEFAULT;
 a[5].flags=R4SDKDATA_DEFAULT;
 a[6].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,59u,a,7u,output);
}
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_from_fields(R4SdkDataEncodingDecoder *output, uint32_t p0, uint8_t p1, uint8_t p2, uint8_t p3, uint8_t p4, const R4SdkDataNative_Value60 * p5, uint64_t p6) {
 R4SdkDataSlot a[7]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.ptr=(void *)p5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,59u,a,7u,output);
}
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_get_encoding(const R4SdkDataEncodingDecoder *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_set_encoding(R4SdkDataEncodingDecoder *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_get_fatal(const R4SdkDataEncodingDecoder *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_set_fatal(R4SdkDataEncodingDecoder *self, uint8_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_get_ignore_bom(const R4SdkDataEncodingDecoder *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_set_ignore_bom(R4SdkDataEncodingDecoder *self, uint8_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_get_streaming(const R4SdkDataEncodingDecoder *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_set_streaming(R4SdkDataEncodingDecoder *self, uint8_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_get_bom_seen(const R4SdkDataEncodingDecoder *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_set_bom_seen(R4SdkDataEncodingDecoder *self, uint8_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_get_pending(const R4SdkDataEncodingDecoder *self, R4SdkDataNative_Value60 *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,5u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_set_pending(R4SdkDataEncodingDecoder *self, const R4SdkDataNative_Value60 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_get_pending_len(const R4SdkDataEncodingDecoder *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_set_pending_len(R4SdkDataEncodingDecoder *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,59u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataEncodingDecoder_inspectNative(const R4SdkDataEncodingDecoder *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,59u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value60_create(R4SdkDataNative_Value60 *output, const R4SdkDataNative_Value60 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,60u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value60_inspectNative(const R4SdkDataNative_Value60 *self, R4SdkDataNative_Value60 *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,60u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataUrlParts_create(R4SdkDataUrlParts *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, const uint8_t * p5, uintptr_t n5, const uint8_t * p6, uintptr_t n6, const uint8_t * p7, uintptr_t n7, const uint8_t * p8, uintptr_t n8) {
 R4SdkDataSlot a[9]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKDATA_PRESENT};
 a[7] = (R4SdkDataSlot){.ptr=(void *)p7,.length=n7,.flags=R4SDKDATA_PRESENT};
 a[8] = (R4SdkDataSlot){.ptr=(void *)p8,.length=n8,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,61u,a,9u,output);
}
static inline R4SdkDataSlot R4SdkDataUrlParts_from_fields(R4SdkDataUrlParts *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, const uint8_t * p5, uintptr_t n5, const uint8_t * p6, uintptr_t n6, const uint8_t * p7, uintptr_t n7, const uint8_t * p8, uintptr_t n8) {
 R4SdkDataSlot a[9]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKDATA_PRESENT};
 a[7] = (R4SdkDataSlot){.ptr=(void *)p7,.length=n7,.flags=R4SDKDATA_PRESENT};
 a[8] = (R4SdkDataSlot){.ptr=(void *)p8,.length=n8,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,61u,a,9u,output);
}
static inline R4SdkDataSlot R4SdkDataUrlParts_get_protocol(const R4SdkDataUrlParts *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_set_protocol(R4SdkDataUrlParts *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_get_username(const R4SdkDataUrlParts *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_set_username(R4SdkDataUrlParts *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_get_password(const R4SdkDataUrlParts *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_set_password(R4SdkDataUrlParts *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_get_host(const R4SdkDataUrlParts *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_set_host(R4SdkDataUrlParts *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_get_hostname(const R4SdkDataUrlParts *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_set_hostname(R4SdkDataUrlParts *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_get_port(const R4SdkDataUrlParts *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,5u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_set_port(R4SdkDataUrlParts *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_get_pathname(const R4SdkDataUrlParts *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_set_pathname(R4SdkDataUrlParts *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_get_search(const R4SdkDataUrlParts *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,7u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_set_search(R4SdkDataUrlParts *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,7u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_get_hash(const R4SdkDataUrlParts *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,8u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_set_hash(R4SdkDataUrlParts *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,61u,8u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlParts_inspectNative(const R4SdkDataUrlParts *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,61u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value62_inspectNative(const R4SdkDataNative_Value62 *self, R4SdkDataUrlParts *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,62u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value63_inspectNative(const R4SdkDataNative_Value63 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,63u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value64_create(R4SdkDataNative_Value64 *output, uint64_t * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,64u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value64_inspectNative(const R4SdkDataNative_Value64 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,64u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value65_inspectNative(const R4SdkDataNative_Value65 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,65u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataUrlComponent_create(R4SdkDataUrlComponent *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,66u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataUrlComponent_inspectNative(const R4SdkDataUrlComponent *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,66u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value67_inspectNative(const R4SdkDataNative_Value67 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,67u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataUrlPair_create(R4SdkDataUrlPair *output) {
 R4SdkDataSlot a[2]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,68u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataUrlPair_from_fields(R4SdkDataUrlPair *output, const R4SdkDataUrlSliceRef * p0, const R4SdkDataUrlSliceRef * p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,68u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataUrlPair_get_name(const R4SdkDataUrlPair *self, R4SdkDataUrlSliceRef *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,68u,0u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataUrlPair_set_name(R4SdkDataUrlPair *self, const R4SdkDataUrlSliceRef * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,68u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlPair_get_value(const R4SdkDataUrlPair *self, R4SdkDataUrlSliceRef *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,68u,1u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataUrlPair_set_value(R4SdkDataUrlPair *self, const R4SdkDataUrlSliceRef * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,68u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlPair_inspectNative(const R4SdkDataUrlPair *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,68u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataUrlSliceRef_create(R4SdkDataUrlSliceRef *output) {
 R4SdkDataSlot a[2]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,69u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataUrlSliceRef_from_fields(R4SdkDataUrlSliceRef *output, uint16_t p0, uint16_t p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,69u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataUrlSliceRef_get_offset(const R4SdkDataUrlSliceRef *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,69u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlSliceRef_set_offset(R4SdkDataUrlSliceRef *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,69u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlSliceRef_get_len(const R4SdkDataUrlSliceRef *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,69u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlSliceRef_set_len(R4SdkDataUrlSliceRef *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,69u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlSliceRef_inspectNative(const R4SdkDataUrlSliceRef *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,69u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_create(R4SdkDataUrlSearchParams *output) {
 R4SdkDataSlot a[4]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2].flags=R4SDKDATA_DEFAULT;
 a[3].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,70u,a,4u,output);
}
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_from_fields(R4SdkDataUrlSearchParams *output, const R4SdkDataNative_Value71 * p0, uint64_t p1, const R4SdkDataNative_Value72 * p2, uint64_t p3) {
 R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,70u,a,4u,output);
}
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_get_storage(const R4SdkDataUrlSearchParams *self, R4SdkDataNative_Value71 *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,70u,0u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_set_storage(R4SdkDataUrlSearchParams *self, const R4SdkDataNative_Value71 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,70u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_get_storage_len(const R4SdkDataUrlSearchParams *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,70u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_set_storage_len(R4SdkDataUrlSearchParams *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,70u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_get_pairs(const R4SdkDataUrlSearchParams *self, R4SdkDataNative_Value72 *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,70u,2u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_set_pairs(R4SdkDataUrlSearchParams *self, const R4SdkDataNative_Value72 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,70u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_get_count(const R4SdkDataUrlSearchParams *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,70u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_set_count(R4SdkDataUrlSearchParams *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,70u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUrlSearchParams_inspectNative(const R4SdkDataUrlSearchParams *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,70u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value71_create(R4SdkDataNative_Value71 *output, const R4SdkDataNative_Value71 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,71u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value71_inspectNative(const R4SdkDataNative_Value71 *self, R4SdkDataNative_Value71 *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,71u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value72_create(R4SdkDataNative_Value72 *output, const R4SdkDataNative_Value72 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,72u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value72_inspectNative(const R4SdkDataNative_Value72 *self, R4SdkDataNative_Value72 *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,72u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataProjectModuleKind_create(R4SdkDataProjectModuleKind *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,73u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataProjectModuleKind_inspectNative(const R4SdkDataProjectModuleKind *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,73u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataProjectLanguage_create(R4SdkDataProjectLanguage *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,74u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataProjectLanguage_inspectNative(const R4SdkDataProjectLanguage *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,74u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataProjectProfileClass_create(R4SdkDataProjectProfileClass *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,75u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataProjectProfileClass_inspectNative(const R4SdkDataProjectProfileClass *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,75u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataProjectToken_create(R4SdkDataProjectToken *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,76u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataProjectToken_from_fields(R4SdkDataProjectToken *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,76u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataProjectToken_get_name(const R4SdkDataProjectToken *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,76u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectToken_set_name(R4SdkDataProjectToken *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,76u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectToken_get_value(const R4SdkDataProjectToken *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,76u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectToken_set_value(R4SdkDataProjectToken *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,76u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectToken_inspectNative(const R4SdkDataProjectToken *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,76u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataProjectRenderResult_create(R4SdkDataProjectRenderResult *output, const uint8_t * p0, uintptr_t n0, uint8_t p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,77u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataProjectRenderResult_from_fields(R4SdkDataProjectRenderResult *output, const uint8_t * p0, uintptr_t n0, uint8_t p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,77u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataProjectRenderResult_get_bytes(const R4SdkDataProjectRenderResult *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,77u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectRenderResult_set_bytes(R4SdkDataProjectRenderResult *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,77u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectRenderResult_get_ok(const R4SdkDataProjectRenderResult *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,77u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectRenderResult_set_ok(R4SdkDataProjectRenderResult *self, uint8_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,77u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectRenderResult_inspectNative(const R4SdkDataProjectRenderResult *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,77u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_create(R4SdkDataProjectProjectTemplateValues *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, const uint8_t * p5, uintptr_t n5, const uint8_t * p6, uintptr_t n6) {
 R4SdkDataSlot a[7]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,78u,a,7u,output);
}
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_from_fields(R4SdkDataProjectProjectTemplateValues *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, const uint8_t * p5, uintptr_t n5, const uint8_t * p6, uintptr_t n6) {
 R4SdkDataSlot a[7]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,78u,a,7u,output);
}
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_get_project_name(const R4SdkDataProjectProjectTemplateValues *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_set_project_name(R4SdkDataProjectProjectTemplateValues *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_get_module_kind(const R4SdkDataProjectProjectTemplateValues *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_set_module_kind(R4SdkDataProjectProjectTemplateValues *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_get_language(const R4SdkDataProjectProjectTemplateValues *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_set_language(R4SdkDataProjectProjectTemplateValues *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_get_build_profile(const R4SdkDataProjectProjectTemplateValues *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_set_build_profile(R4SdkDataProjectProjectTemplateValues *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_get_app_class(const R4SdkDataProjectProjectTemplateValues *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_set_app_class(R4SdkDataProjectProjectTemplateValues *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_get_artifact(const R4SdkDataProjectProjectTemplateValues *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,5u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_set_artifact(R4SdkDataProjectProjectTemplateValues *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_get_target_path(const R4SdkDataProjectProjectTemplateValues *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_set_target_path(R4SdkDataProjectProjectTemplateValues *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,78u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProjectTemplateValues_inspectNative(const R4SdkDataProjectProjectTemplateValues *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,78u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataProjectItem_create(R4SdkDataProjectItem *output) {
 R4SdkDataSlot a[2]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,79u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataProjectItem_from_fields(R4SdkDataProjectItem *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,79u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataProjectItem_get_key(const R4SdkDataProjectItem *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,79u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectItem_set_key(R4SdkDataProjectItem *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,79u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectItem_get_value(const R4SdkDataProjectItem *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,79u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectItem_set_value(R4SdkDataProjectItem *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,79u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectItem_inspectNative(const R4SdkDataProjectItem *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,79u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_create(R4SdkDataProjectProject *output) {
 R4SdkDataSlot a[18]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2].flags=R4SDKDATA_DEFAULT;
 a[3].flags=R4SDKDATA_DEFAULT;
 a[4].flags=R4SDKDATA_DEFAULT;
 a[5].flags=R4SDKDATA_DEFAULT;
 a[6].flags=R4SDKDATA_DEFAULT;
 a[7].flags=R4SDKDATA_DEFAULT;
 a[8].flags=R4SDKDATA_DEFAULT;
 a[9].flags=R4SDKDATA_DEFAULT;
 a[10].flags=R4SDKDATA_DEFAULT;
 a[11].flags=R4SDKDATA_DEFAULT;
 a[12].flags=R4SDKDATA_DEFAULT;
 a[13].flags=R4SDKDATA_DEFAULT;
 a[14].flags=R4SDKDATA_DEFAULT;
 a[15].flags=R4SDKDATA_DEFAULT;
 a[16].flags=R4SDKDATA_DEFAULT;
 a[17].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,80u,a,18u,output);
}
static inline R4SdkDataSlot R4SdkDataProjectProject_from_fields(R4SdkDataProjectProject *output, const uint8_t * p0, uintptr_t n0, uint32_t p1, uint32_t p2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, const uint8_t * p5, uintptr_t n5, const uint8_t * p6, uintptr_t n6, const uint8_t * p7, uintptr_t n7, const R4SdkDataNative_Value81 * p8, uint64_t p9, const R4SdkDataNative_Value81 * p10, uint64_t p11, const R4SdkDataNative_Value81 * p12, uint64_t p13, const R4SdkDataNative_Value82 * p14, uint64_t p15, const R4SdkDataNative_Value83 * p16, uint64_t p17) {
 R4SdkDataSlot a[18]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKDATA_PRESENT};
 a[7] = (R4SdkDataSlot){.ptr=(void *)p7,.length=n7,.flags=R4SDKDATA_PRESENT};
 a[8] = (R4SdkDataSlot){.ptr=(void *)p8,.flags=R4SDKDATA_PRESENT};
 a[9] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKDATA_PRESENT};
 a[10] = (R4SdkDataSlot){.ptr=(void *)p10,.flags=R4SDKDATA_PRESENT};
 a[11] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKDATA_PRESENT};
 a[12] = (R4SdkDataSlot){.ptr=(void *)p12,.flags=R4SDKDATA_PRESENT};
 a[13] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKDATA_PRESENT};
 a[14] = (R4SdkDataSlot){.ptr=(void *)p14,.flags=R4SDKDATA_PRESENT};
 a[15] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p15,.flags=R4SDKDATA_PRESENT};
 a[16] = (R4SdkDataSlot){.ptr=(void *)p16,.flags=R4SDKDATA_PRESENT};
 a[17] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p17,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,80u,a,18u,output);
}
static inline R4SdkDataSlot R4SdkDataProjectProject_get_name(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_name(R4SdkDataProjectProject *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_module_kind(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_module_kind(R4SdkDataProjectProject *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_language(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_language(R4SdkDataProjectProject *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_build_profile(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_build_profile(R4SdkDataProjectProject *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_app_class(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_app_class(R4SdkDataProjectProject *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_artifact(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,5u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_artifact(R4SdkDataProjectProject *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_target_path(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_target_path(R4SdkDataProjectProject *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_test_profile(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,7u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_test_profile(R4SdkDataProjectProject *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,7u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_source_items(const R4SdkDataProjectProject *self, R4SdkDataNative_Value81 *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,8u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_source_items(R4SdkDataProjectProject *self, const R4SdkDataNative_Value81 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,8u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_source_count(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,9u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_source_count(R4SdkDataProjectProject *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,9u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_import_items(const R4SdkDataProjectProject *self, R4SdkDataNative_Value81 *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,10u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_import_items(R4SdkDataProjectProject *self, const R4SdkDataNative_Value81 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,10u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_import_count(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,11u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_import_count(R4SdkDataProjectProject *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,11u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_export_items(const R4SdkDataProjectProject *self, R4SdkDataNative_Value81 *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,12u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_export_items(R4SdkDataProjectProject *self, const R4SdkDataNative_Value81 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,12u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_export_count(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,13u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_export_count(R4SdkDataProjectProject *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,13u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_metadata_items(const R4SdkDataProjectProject *self, R4SdkDataNative_Value82 *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,14u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_metadata_items(R4SdkDataProjectProject *self, const R4SdkDataNative_Value82 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,14u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_metadata_count(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,15u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_metadata_count(R4SdkDataProjectProject *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,15u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_contract_items(const R4SdkDataProjectProject *self, R4SdkDataNative_Value83 *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,16u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_contract_items(R4SdkDataProjectProject *self, const R4SdkDataNative_Value83 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,16u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_get_contract_count(const R4SdkDataProjectProject *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,17u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_set_contract_count(R4SdkDataProjectProject *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,80u,17u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectProject_inspectNative(const R4SdkDataProjectProject *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,80u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value81_create(R4SdkDataNative_Value81 *output, const R4SdkDataNative_Value81 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,81u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value81_inspectNative(const R4SdkDataNative_Value81 *self, R4SdkDataNative_Value81 *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,81u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value82_create(R4SdkDataNative_Value82 *output, const R4SdkDataNative_Value82 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,82u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value82_inspectNative(const R4SdkDataNative_Value82 *self, R4SdkDataNative_Value82 *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,82u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value83_create(R4SdkDataNative_Value83 *output, const R4SdkDataNative_Value83 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,83u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value83_inspectNative(const R4SdkDataNative_Value83 *self, R4SdkDataNative_Value83 *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,83u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value84_inspectNative(const R4SdkDataNative_Value84 *self, R4SdkDataProjectProject *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,84u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value85_create(R4SdkDataNative_Value85 *output, const R4SdkDataProjectToken * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,85u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value85_inspectNative(const R4SdkDataNative_Value85 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,85u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataProjectConvertConvertError_create(R4SdkDataProjectConvertConvertError *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,86u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataProjectConvertConvertError_inspectNative(const R4SdkDataProjectConvertConvertError *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,86u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataProjectConvertResult_create(R4SdkDataProjectConvertResult *output, const uint8_t * p0, uintptr_t n0, R4SdkDataSlot p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = p1;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,87u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataProjectConvertResult_from_fields(R4SdkDataProjectConvertResult *output, const uint8_t * p0, uintptr_t n0, R4SdkDataSlot p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = p1;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,87u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataProjectConvertResult_get_bytes(const R4SdkDataProjectConvertResult *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,87u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectConvertResult_set_bytes(R4SdkDataProjectConvertResult *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,87u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectConvertResult_get_err(const R4SdkDataProjectConvertResult *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,87u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataProjectConvertResult_set_err(R4SdkDataProjectConvertResult *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,87u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataProjectConvertResult_inspectNative(const R4SdkDataProjectConvertResult *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,87u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value88_create(R4SdkDataNative_Value88 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,88u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value88_inspectNative(const R4SdkDataNative_Value88 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,88u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value89_create(R4SdkDataNative_Value89 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,89u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value89_inspectNative(const R4SdkDataNative_Value89 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,89u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestKind_create(R4SdkDataManifestKind *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,90u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataManifestKind_inspectNative(const R4SdkDataManifestKind *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,90u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestLanguage_create(R4SdkDataManifestLanguage *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,91u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataManifestLanguage_inspectNative(const R4SdkDataManifestLanguage *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,91u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestAppClass_create(R4SdkDataManifestAppClass *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,92u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataManifestAppClass_inspectNative(const R4SdkDataManifestAppClass *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,92u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestEntryMode_create(R4SdkDataManifestEntryMode *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,93u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataManifestEntryMode_inspectNative(const R4SdkDataManifestEntryMode *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,93u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestImageScope_create(R4SdkDataManifestImageScope *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,94u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataManifestImageScope_inspectNative(const R4SdkDataManifestImageScope *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,94u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestOptimization_create(R4SdkDataManifestOptimization *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,95u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataManifestOptimization_inspectNative(const R4SdkDataManifestOptimization *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,95u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestModuleRole_create(R4SdkDataManifestModuleRole *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,96u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataManifestModuleRole_inspectNative(const R4SdkDataManifestModuleRole *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,96u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestGuestExtensionEntry_create(R4SdkDataManifestGuestExtensionEntry *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,97u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestGuestExtensionEntry_from_fields(R4SdkDataManifestGuestExtensionEntry *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,97u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestGuestExtensionEntry_get_format_id(const R4SdkDataManifestGuestExtensionEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,97u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestGuestExtensionEntry_set_format_id(R4SdkDataManifestGuestExtensionEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,97u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestGuestExtensionEntry_get_extension(const R4SdkDataManifestGuestExtensionEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,97u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestGuestExtensionEntry_set_extension(R4SdkDataManifestGuestExtensionEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,97u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestGuestExtensionEntry_inspectNative(const R4SdkDataManifestGuestExtensionEntry *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,97u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestGuestFeatureEntry_create(R4SdkDataManifestGuestFeatureEntry *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,98u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestGuestFeatureEntry_from_fields(R4SdkDataManifestGuestFeatureEntry *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,98u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestGuestFeatureEntry_get_format_id(const R4SdkDataManifestGuestFeatureEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,98u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestGuestFeatureEntry_set_format_id(R4SdkDataManifestGuestFeatureEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,98u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestGuestFeatureEntry_get_feature(const R4SdkDataManifestGuestFeatureEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,98u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestGuestFeatureEntry_set_feature(R4SdkDataManifestGuestFeatureEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,98u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestGuestFeatureEntry_inspectNative(const R4SdkDataManifestGuestFeatureEntry *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,98u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestModuleVersion_create(R4SdkDataManifestModuleVersion *output, uint16_t p0, uint16_t p1, uint16_t p2, const uint8_t * p3, uintptr_t n3) {
 R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,99u,a,4u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestModuleVersion_from_fields(R4SdkDataManifestModuleVersion *output, uint16_t p0, uint16_t p1, uint16_t p2, const uint8_t * p3, uintptr_t n3) {
 R4SdkDataSlot a[4]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,99u,a,4u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestModuleVersion_get_major(const R4SdkDataManifestModuleVersion *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,99u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestModuleVersion_set_major(R4SdkDataManifestModuleVersion *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,99u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestModuleVersion_get_minor(const R4SdkDataManifestModuleVersion *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,99u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestModuleVersion_set_minor(R4SdkDataManifestModuleVersion *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,99u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestModuleVersion_get_patch(const R4SdkDataManifestModuleVersion *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,99u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestModuleVersion_set_patch(R4SdkDataManifestModuleVersion *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,99u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestModuleVersion_get_text(const R4SdkDataManifestModuleVersion *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,99u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestModuleVersion_set_text(R4SdkDataManifestModuleVersion *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,99u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestModuleVersion_inspectNative(const R4SdkDataManifestModuleVersion *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,99u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestResourceEntry_create(R4SdkDataManifestResourceEntry *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,100u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestResourceEntry_from_fields(R4SdkDataManifestResourceEntry *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,100u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestResourceEntry_get_name(const R4SdkDataManifestResourceEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,100u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestResourceEntry_set_name(R4SdkDataManifestResourceEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,100u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestResourceEntry_get_path(const R4SdkDataManifestResourceEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,100u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestResourceEntry_set_path(R4SdkDataManifestResourceEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,100u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestResourceEntry_inspectNative(const R4SdkDataManifestResourceEntry *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,100u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestExportEntry_create(R4SdkDataManifestExportEntry *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, uint16_t p2) {
 R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,101u,a,3u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestExportEntry_from_fields(R4SdkDataManifestExportEntry *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, uint16_t p2) {
 R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,101u,a,3u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestExportEntry_get_name(const R4SdkDataManifestExportEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,101u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestExportEntry_set_name(R4SdkDataManifestExportEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,101u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestExportEntry_get_symbol(const R4SdkDataManifestExportEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,101u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestExportEntry_set_symbol(R4SdkDataManifestExportEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,101u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestExportEntry_get_revision(const R4SdkDataManifestExportEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,101u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestExportEntry_set_revision(R4SdkDataManifestExportEntry *self, uint16_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,101u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestExportEntry_inspectNative(const R4SdkDataManifestExportEntry *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,101u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestCDefineEntry_create(R4SdkDataManifestCDefineEntry *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,102u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestCDefineEntry_from_fields(R4SdkDataManifestCDefineEntry *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,102u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestCDefineEntry_get_name(const R4SdkDataManifestCDefineEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,102u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestCDefineEntry_set_name(R4SdkDataManifestCDefineEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,102u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestCDefineEntry_get_value(const R4SdkDataManifestCDefineEntry *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,102u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestCDefineEntry_set_value(R4SdkDataManifestCDefineEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,102u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestCDefineEntry_inspectNative(const R4SdkDataManifestCDefineEntry *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,102u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_create(R4SdkDataManifestManifest *output, uint8_t p0, const uint8_t * p1, uintptr_t n1, uint32_t p2, const uint8_t * p3, uintptr_t n3, const R4SdkDataManifestModuleVersion * p4, const uint8_t * p15, uintptr_t n15) {
 R4SdkDataSlot a[41]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.ptr=(void *)p4,.flags=R4SDKDATA_PRESENT};
 a[5].flags=R4SDKDATA_DEFAULT;
 a[6].flags=R4SDKDATA_DEFAULT;
 a[7].flags=R4SDKDATA_DEFAULT;
 a[8].flags=R4SDKDATA_DEFAULT;
 a[9].flags=R4SDKDATA_DEFAULT;
 a[10].flags=R4SDKDATA_DEFAULT;
 a[11].flags=R4SDKDATA_DEFAULT;
 a[12].flags=R4SDKDATA_DEFAULT;
 a[13].flags=R4SDKDATA_DEFAULT;
 a[14].flags=R4SDKDATA_DEFAULT;
 a[15] = (R4SdkDataSlot){.ptr=(void *)p15,.length=n15,.flags=R4SDKDATA_PRESENT};
 a[16].flags=R4SDKDATA_DEFAULT;
 a[17].flags=R4SDKDATA_DEFAULT;
 a[18].flags=R4SDKDATA_DEFAULT;
 a[19].flags=R4SDKDATA_DEFAULT;
 a[20].flags=R4SDKDATA_DEFAULT;
 a[21].flags=R4SDKDATA_DEFAULT;
 a[22].flags=R4SDKDATA_DEFAULT;
 a[23].flags=R4SDKDATA_DEFAULT;
 a[24].flags=R4SDKDATA_DEFAULT;
 a[25].flags=R4SDKDATA_DEFAULT;
 a[26].flags=R4SDKDATA_DEFAULT;
 a[27].flags=R4SDKDATA_DEFAULT;
 a[28].flags=R4SDKDATA_DEFAULT;
 a[29].flags=R4SDKDATA_DEFAULT;
 a[30].flags=R4SDKDATA_DEFAULT;
 a[31].flags=R4SDKDATA_DEFAULT;
 a[32].flags=R4SDKDATA_DEFAULT;
 a[33].flags=R4SDKDATA_DEFAULT;
 a[34].flags=R4SDKDATA_DEFAULT;
 a[35].flags=R4SDKDATA_DEFAULT;
 a[36].flags=R4SDKDATA_DEFAULT;
 a[37].flags=R4SDKDATA_DEFAULT;
 a[38].flags=R4SDKDATA_DEFAULT;
 a[39].flags=R4SDKDATA_DEFAULT;
 a[40].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,103u,a,41u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestManifest_from_fields(R4SdkDataManifestManifest *output, uint8_t p0, const uint8_t * p1, uintptr_t n1, uint32_t p2, const uint8_t * p3, uintptr_t n3, const R4SdkDataManifestModuleVersion * p4, R4SdkDataSlot p5, const R4SdkDataNative_Value31 * p6, uintptr_t n6, R4SdkDataSlot p7, R4SdkDataSlot p8, R4SdkDataSlot p9, R4SdkDataSlot p10, R4SdkDataSlot p11, const R4SdkDataNative_Value31 * p12, uintptr_t n12, const R4SdkDataManifestGuestExtensionEntry * p13, uintptr_t n13, const R4SdkDataManifestGuestFeatureEntry * p14, uintptr_t n14, const uint8_t * p15, uintptr_t n15, R4SdkDataSlot p16, R4SdkDataSlot p17, R4SdkDataSlot p18, const R4SdkDataNative_Value31 * p19, uintptr_t n19, const R4SdkDataNative_Value31 * p20, uintptr_t n20, const R4SdkDataNative_Value31 * p21, uintptr_t n21, const R4SdkDataManifestCDefineEntry * p22, uintptr_t n22, const R4SdkDataNative_Value31 * p23, uintptr_t n23, const R4SdkDataNative_Value31 * p24, uintptr_t n24, const R4SdkDataManifestExportEntry * p25, uintptr_t n25, R4SdkDataSlot p26, R4SdkDataSlot p27, R4SdkDataSlot p28, R4SdkDataSlot p29, R4SdkDataSlot p30, R4SdkDataSlot p31, R4SdkDataSlot p32, R4SdkDataSlot p33, R4SdkDataSlot p34, const R4SdkDataNative_Value31 * p35, uintptr_t n35, const R4SdkDataNative_Value31 * p36, uintptr_t n36, R4SdkDataSlot p37, const R4SdkDataManifestResourceEntry * p38, uintptr_t n38, R4SdkDataSlot p39, uint8_t p40) {
 R4SdkDataSlot a[41]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.ptr=(void *)p4,.flags=R4SDKDATA_PRESENT};
 a[5] = p5;
 a[6] = (R4SdkDataSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKDATA_PRESENT};
 a[7] = p7;
 a[8] = p8;
 a[9] = p9;
 a[10] = p10;
 a[11] = p11;
 a[12] = (R4SdkDataSlot){.ptr=(void *)p12,.length=n12,.flags=R4SDKDATA_PRESENT};
 a[13] = (R4SdkDataSlot){.ptr=(void *)p13,.length=n13,.flags=R4SDKDATA_PRESENT};
 a[14] = (R4SdkDataSlot){.ptr=(void *)p14,.length=n14,.flags=R4SDKDATA_PRESENT};
 a[15] = (R4SdkDataSlot){.ptr=(void *)p15,.length=n15,.flags=R4SDKDATA_PRESENT};
 a[16] = p16;
 a[17] = p17;
 a[18] = p18;
 a[19] = (R4SdkDataSlot){.ptr=(void *)p19,.length=n19,.flags=R4SDKDATA_PRESENT};
 a[20] = (R4SdkDataSlot){.ptr=(void *)p20,.length=n20,.flags=R4SDKDATA_PRESENT};
 a[21] = (R4SdkDataSlot){.ptr=(void *)p21,.length=n21,.flags=R4SDKDATA_PRESENT};
 a[22] = (R4SdkDataSlot){.ptr=(void *)p22,.length=n22,.flags=R4SDKDATA_PRESENT};
 a[23] = (R4SdkDataSlot){.ptr=(void *)p23,.length=n23,.flags=R4SDKDATA_PRESENT};
 a[24] = (R4SdkDataSlot){.ptr=(void *)p24,.length=n24,.flags=R4SDKDATA_PRESENT};
 a[25] = (R4SdkDataSlot){.ptr=(void *)p25,.length=n25,.flags=R4SDKDATA_PRESENT};
 a[26] = p26;
 a[27] = p27;
 a[28] = p28;
 a[29] = p29;
 a[30] = p30;
 a[31] = p31;
 a[32] = p32;
 a[33] = p33;
 a[34] = p34;
 a[35] = (R4SdkDataSlot){.ptr=(void *)p35,.length=n35,.flags=R4SDKDATA_PRESENT};
 a[36] = (R4SdkDataSlot){.ptr=(void *)p36,.length=n36,.flags=R4SDKDATA_PRESENT};
 a[37] = p37;
 a[38] = (R4SdkDataSlot){.ptr=(void *)p38,.length=n38,.flags=R4SDKDATA_PRESENT};
 a[39] = p39;
 a[40] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p40,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,103u,a,41u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_version(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_version(R4SdkDataManifestManifest *self, uint8_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_path(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_path(R4SdkDataManifestManifest *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_kind(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_kind(R4SdkDataManifestManifest *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_name(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_name(R4SdkDataManifestManifest *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_module_version(const R4SdkDataManifestManifest *self, R4SdkDataManifestModuleVersion *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,4u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_module_version(R4SdkDataManifestManifest *self, const R4SdkDataManifestModuleVersion * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_language(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,5u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_language(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_sources(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_sources(R4SdkDataManifestManifest *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_entry_mode(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,7u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_entry_mode(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,7u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_app_class(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,8u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_app_class(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,8u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_module_role(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,9u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_module_role(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,9u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_subsystem_id(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,10u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_subsystem_id(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,10u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_subsystem_display_name(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,11u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_subsystem_display_name(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,11u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_guest_formats(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,12u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_guest_formats(R4SdkDataManifestManifest *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,12u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_guest_extensions(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,13u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_guest_extensions(R4SdkDataManifestManifest *self, const R4SdkDataManifestGuestExtensionEntry * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,13u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_guest_features(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,14u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_guest_features(R4SdkDataManifestManifest *self, const R4SdkDataManifestGuestFeatureEntry * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,14u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_target(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,15u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_target(R4SdkDataManifestManifest *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,15u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_image_scope(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,16u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_image_scope(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,16u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_optimization(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,17u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_optimization(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,17u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_package(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,18u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_package(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,18u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_zig_modules(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,19u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_zig_modules(R4SdkDataManifestManifest *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,19u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_native_archives(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,20u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_native_archives(R4SdkDataManifestManifest *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,20u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_c_includes(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,21u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_c_includes(R4SdkDataManifestManifest *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,21u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_c_defines(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,22u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_c_defines(R4SdkDataManifestManifest *self, const R4SdkDataManifestCDefineEntry * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,22u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_c_flags(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,23u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_c_flags(R4SdkDataManifestManifest *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,23u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_imports(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,24u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_imports(R4SdkDataManifestManifest *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,24u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_exports(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,25u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_exports(R4SdkDataManifestManifest *self, const R4SdkDataManifestExportEntry * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,25u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_contract(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,26u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_contract(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,26u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_contract_baseline(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,27u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_contract_baseline(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,27u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_implementation_zig(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,28u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_implementation_zig(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,28u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_binding_zig(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,29u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_binding_zig(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,29u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_binding_c(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,30u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_binding_c(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,30u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_binding_rust(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,31u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_binding_rust(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,31u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_conformance_zig(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,32u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_conformance_zig(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,32u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_conformance_c(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,33u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_conformance_c(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,33u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_api_reference(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,34u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_api_reference(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,34u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_metadata(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,35u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_metadata(R4SdkDataManifestManifest *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,35u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_icons(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,36u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_icons(R4SdkDataManifestManifest *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,36u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_help(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,37u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_help(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,37u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_resources(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,38u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_resources(R4SdkDataManifestManifest *self, const R4SdkDataManifestResourceEntry * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,38u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_sdk_profile(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,39u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_sdk_profile(R4SdkDataManifestManifest *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,39u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_get_platform_generation(const R4SdkDataManifestManifest *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,40u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_set_platform_generation(R4SdkDataManifestManifest *self, uint8_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,103u,40u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestManifest_inspectNative(const R4SdkDataManifestManifest *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,103u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value104_create(R4SdkDataNative_Value104 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,104u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value104_inspectNative(const R4SdkDataNative_Value104 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,104u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value105_create(R4SdkDataNative_Value105 *output, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,105u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value105_inspectNative(const R4SdkDataNative_Value105 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,105u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value106_create(R4SdkDataNative_Value106 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,106u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value106_inspectNative(const R4SdkDataNative_Value106 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,106u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value107_create(R4SdkDataNative_Value107 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,107u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value107_inspectNative(const R4SdkDataNative_Value107 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,107u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value108_create(R4SdkDataNative_Value108 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,108u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value108_inspectNative(const R4SdkDataNative_Value108 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,108u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value109_create(R4SdkDataNative_Value109 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,109u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value109_inspectNative(const R4SdkDataNative_Value109 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,109u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value110_create(R4SdkDataNative_Value110 *output, const R4SdkDataManifestGuestExtensionEntry * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,110u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value110_inspectNative(const R4SdkDataNative_Value110 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,110u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value111_create(R4SdkDataNative_Value111 *output, const R4SdkDataManifestGuestFeatureEntry * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,111u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value111_inspectNative(const R4SdkDataNative_Value111 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,111u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value112_create(R4SdkDataNative_Value112 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,112u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value112_inspectNative(const R4SdkDataNative_Value112 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,112u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value113_create(R4SdkDataNative_Value113 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,113u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value113_inspectNative(const R4SdkDataNative_Value113 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,113u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value114_create(R4SdkDataNative_Value114 *output, const R4SdkDataManifestCDefineEntry * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,114u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value114_inspectNative(const R4SdkDataNative_Value114 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,114u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value115_create(R4SdkDataNative_Value115 *output, const R4SdkDataManifestExportEntry * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,115u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value115_inspectNative(const R4SdkDataNative_Value115 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,115u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value116_create(R4SdkDataNative_Value116 *output, const R4SdkDataManifestResourceEntry * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,116u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value116_inspectNative(const R4SdkDataNative_Value116 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,116u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_create(R4SdkDataManifestPlan *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, const uint8_t * p5, uintptr_t n5, const R4SdkDataNative_Value31 * p9, uintptr_t n9, const R4SdkDataNative_Value31 * p10, uintptr_t n10) {
 R4SdkDataSlot a[11]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKDATA_PRESENT};
 a[6].flags=R4SDKDATA_DEFAULT;
 a[7].flags=R4SDKDATA_DEFAULT;
 a[8].flags=R4SDKDATA_DEFAULT;
 a[9] = (R4SdkDataSlot){.ptr=(void *)p9,.length=n9,.flags=R4SDKDATA_PRESENT};
 a[10] = (R4SdkDataSlot){.ptr=(void *)p10,.length=n10,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,117u,a,11u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestPlan_from_fields(R4SdkDataManifestPlan *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, const uint8_t * p5, uintptr_t n5, const uint8_t * p6, uintptr_t n6, const uint8_t * p7, uintptr_t n7, const uint8_t * p8, uintptr_t n8, const R4SdkDataNative_Value31 * p9, uintptr_t n9, const R4SdkDataNative_Value31 * p10, uintptr_t n10) {
 R4SdkDataSlot a[11]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKDATA_PRESENT};
 a[5] = (R4SdkDataSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKDATA_PRESENT};
 a[6] = (R4SdkDataSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKDATA_PRESENT};
 a[7] = (R4SdkDataSlot){.ptr=(void *)p7,.length=n7,.flags=R4SDKDATA_PRESENT};
 a[8] = (R4SdkDataSlot){.ptr=(void *)p8,.length=n8,.flags=R4SDKDATA_PRESENT};
 a[9] = (R4SdkDataSlot){.ptr=(void *)p9,.length=n9,.flags=R4SDKDATA_PRESENT};
 a[10] = (R4SdkDataSlot){.ptr=(void *)p10,.length=n10,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,117u,a,11u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestPlan_get_source_project(const R4SdkDataManifestPlan *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_set_source_project(R4SdkDataManifestPlan *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_get_artifact(const R4SdkDataManifestPlan *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_set_artifact(R4SdkDataManifestPlan *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_get_build_profile(const R4SdkDataManifestPlan *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_set_build_profile(R4SdkDataManifestPlan *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_get_app_profile(const R4SdkDataManifestPlan *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,3u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_set_app_profile(R4SdkDataManifestPlan *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_get_app_class(const R4SdkDataManifestPlan *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_set_app_class(R4SdkDataManifestPlan *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_get_optimization(const R4SdkDataManifestPlan *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,5u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_set_optimization(R4SdkDataManifestPlan *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,5u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_get_export_contract(const R4SdkDataManifestPlan *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,6u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_set_export_contract(R4SdkDataManifestPlan *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,6u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_get_module_contract(const R4SdkDataManifestPlan *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,7u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_set_module_contract(R4SdkDataManifestPlan *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,7u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_get_r4x_start_abi(const R4SdkDataManifestPlan *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,8u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_set_r4x_start_abi(R4SdkDataManifestPlan *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,8u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_get_imports(const R4SdkDataManifestPlan *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,9u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_set_imports(R4SdkDataManifestPlan *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,9u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_get_metadata(const R4SdkDataManifestPlan *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,10u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_set_metadata(R4SdkDataManifestPlan *self, const R4SdkDataNative_Value31 * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,117u,10u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestPlan_inspectNative(const R4SdkDataManifestPlan *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,117u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataManifestRenderResult_create(R4SdkDataManifestRenderResult *output, const uint8_t * p0, uintptr_t n0, uint8_t p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,118u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestRenderResult_from_fields(R4SdkDataManifestRenderResult *output, const uint8_t * p0, uintptr_t n0, uint8_t p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,118u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataManifestRenderResult_get_bytes(const R4SdkDataManifestRenderResult *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,118u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestRenderResult_set_bytes(R4SdkDataManifestRenderResult *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,118u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestRenderResult_get_ok(const R4SdkDataManifestRenderResult *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,118u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataManifestRenderResult_set_ok(R4SdkDataManifestRenderResult *self, uint8_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,118u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataManifestRenderResult_inspectNative(const R4SdkDataManifestRenderResult *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,118u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value120_inspectNative(const R4SdkDataNative_Value120 *self, R4SdkDataManifestManifest *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,120u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value121_inspectNative(const R4SdkDataNative_Value121 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,121u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value122_inspectNative(const R4SdkDataNative_Value122 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,122u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value123_inspectNative(const R4SdkDataNative_Value123 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,123u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value124_inspectNative(const R4SdkDataNative_Value124 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,124u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value125_inspectNative(const R4SdkDataNative_Value125 *self, R4SdkDataManifestPlan *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,125u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataVersionSemanticVersion_create(R4SdkDataVersionSemanticVersion *output, uint32_t p0, uint32_t p1, uint32_t p2) {
 R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,126u,a,3u,output);
}
static inline R4SdkDataSlot R4SdkDataVersionSemanticVersion_from_fields(R4SdkDataVersionSemanticVersion *output, uint32_t p0, uint32_t p1, uint32_t p2) {
 R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,126u,a,3u,output);
}
static inline R4SdkDataSlot R4SdkDataVersionSemanticVersion_get_major(const R4SdkDataVersionSemanticVersion *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,126u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataVersionSemanticVersion_set_major(R4SdkDataVersionSemanticVersion *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,126u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataVersionSemanticVersion_get_minor(const R4SdkDataVersionSemanticVersion *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,126u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataVersionSemanticVersion_set_minor(R4SdkDataVersionSemanticVersion *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,126u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataVersionSemanticVersion_get_patch(const R4SdkDataVersionSemanticVersion *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,126u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataVersionSemanticVersion_set_patch(R4SdkDataVersionSemanticVersion *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,126u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataVersionSemanticVersion_inspectNative(const R4SdkDataVersionSemanticVersion *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,126u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value127_create(R4SdkDataNative_Value127 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,127u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value127_inspectNative(const R4SdkDataNative_Value127 *self, R4SdkDataVersionSemanticVersion *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,127u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataComponentKind_create(R4SdkDataUpdateMetadataComponentKind *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,129u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataComponentKind_inspectNative(const R4SdkDataUpdateMetadataComponentKind *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,129u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataInstallMode_create(R4SdkDataUpdateMetadataInstallMode *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,130u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataInstallMode_inspectNative(const R4SdkDataUpdateMetadataInstallMode *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,130u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataPriority_create(R4SdkDataUpdateMetadataPriority *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,131u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataPriority_inspectNative(const R4SdkDataUpdateMetadataPriority *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,131u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataRequirementState_create(R4SdkDataUpdateMetadataRequirementState *output, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,132u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataRequirementState_inspectNative(const R4SdkDataUpdateMetadataRequirementState *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,132u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataDerivedClass_create(R4SdkDataUpdateMetadataDerivedClass *output) {
 R4SdkDataSlot a[2]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,133u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataUpdateMetadataDerivedClass_from_fields(R4SdkDataUpdateMetadataDerivedClass *output, uint32_t p0, uint32_t p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,133u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataUpdateMetadataDerivedClass_get_activation(const R4SdkDataUpdateMetadataDerivedClass *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,133u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataDerivedClass_set_activation(R4SdkDataUpdateMetadataDerivedClass *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,133u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataDerivedClass_get_priority(const R4SdkDataUpdateMetadataDerivedClass *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,133u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataDerivedClass_set_priority(R4SdkDataUpdateMetadataDerivedClass *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,133u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataUpdateMetadataDerivedClass_inspectNative(const R4SdkDataUpdateMetadataDerivedClass *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,133u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value134_create(R4SdkDataNative_Value134 *output, R4SdkDataUpdateMetadataDerivedClass * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,134u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value134_inspectNative(const R4SdkDataNative_Value134 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,134u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value135_create(R4SdkDataNative_Value135 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,135u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value135_inspectNative(const R4SdkDataNative_Value135 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,135u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value136_create(R4SdkDataNative_Value136 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,136u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value136_inspectNative(const R4SdkDataNative_Value136 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,136u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_create(R4SdkDataArtifactIdentity *output, uint32_t p0) {
 R4SdkDataSlot a[5]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2].flags=R4SDKDATA_DEFAULT;
 a[3].flags=R4SDKDATA_DEFAULT;
 a[4].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,137u,a,5u,output);
}
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_from_fields(R4SdkDataArtifactIdentity *output, uint32_t p0, const R4SdkDataNative_Value138 * p1, uint64_t p2, const R4SdkDataNative_Value139 * p3, uint64_t p4) {
 R4SdkDataSlot a[5]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.ptr=(void *)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 a[3] = (R4SdkDataSlot){.ptr=(void *)p3,.flags=R4SDKDATA_PRESENT};
 a[4] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,137u,a,5u,output);
}
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_get_kind(const R4SdkDataArtifactIdentity *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,137u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_set_kind(R4SdkDataArtifactIdentity *self, uint32_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,137u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_get_name(const R4SdkDataArtifactIdentity *self, R4SdkDataNative_Value138 *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,137u,1u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_set_name(R4SdkDataArtifactIdentity *self, const R4SdkDataNative_Value138 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,137u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_get_name_len(const R4SdkDataArtifactIdentity *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,137u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_set_name_len(R4SdkDataArtifactIdentity *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,137u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_get_version(const R4SdkDataArtifactIdentity *self, R4SdkDataNative_Value139 *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,137u,3u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_set_version(R4SdkDataArtifactIdentity *self, const R4SdkDataNative_Value139 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,137u,3u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_get_version_len(const R4SdkDataArtifactIdentity *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,137u,4u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_set_version_len(R4SdkDataArtifactIdentity *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,137u,4u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataArtifactIdentity_inspectNative(const R4SdkDataArtifactIdentity *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,137u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value138_create(R4SdkDataNative_Value138 *output, const R4SdkDataNative_Value138 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,138u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value138_inspectNative(const R4SdkDataNative_Value138 *self, R4SdkDataNative_Value138 *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,138u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value139_create(R4SdkDataNative_Value139 *output, const R4SdkDataNative_Value139 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,139u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value139_inspectNative(const R4SdkDataNative_Value139 *self, R4SdkDataNative_Value139 *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,139u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataArtifactSliceReader_create(R4SdkDataArtifactSliceReader *output, const uint8_t * p0, uintptr_t n0) {
 R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,140u,a,1u,output);
}
static inline R4SdkDataSlot R4SdkDataArtifactSliceReader_from_fields(R4SdkDataArtifactSliceReader *output, const uint8_t * p0, uintptr_t n0) {
 R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,140u,a,1u,output);
}
static inline R4SdkDataSlot R4SdkDataArtifactSliceReader_get_bytes(const R4SdkDataArtifactSliceReader *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,140u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataArtifactSliceReader_set_bytes(R4SdkDataArtifactSliceReader *self, const uint8_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,140u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataArtifactSliceReader_inspectNative(const R4SdkDataArtifactSliceReader *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,140u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value142_create(R4SdkDataNative_Value142 *output, R4SdkDataJsonDocument * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,142u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value142_inspectNative(const R4SdkDataNative_Value142 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,142u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value143_create(R4SdkDataNative_Value143 *output, const R4SdkDataContext * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,143u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value143_inspectNative(const R4SdkDataNative_Value143 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,143u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value144_create(R4SdkDataNative_Value144 *output, R4SdkDataSha256 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,144u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value144_inspectNative(const R4SdkDataNative_Value144 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,144u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataSha256_create(R4SdkDataSha256 *output, const R4SdkDataNative_crypto_sha2_Sha2x32____1779033703__3144134277__1013904242__2773480762__1359893119__2600822924__528734635__1541459225___256_ * p0) {
 R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1].flags=R4SDKDATA_DEFAULT;
 a[2].flags=R4SDKDATA_DEFAULT;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,145u,a,3u,output);
}
static inline R4SdkDataSlot R4SdkDataSha256_from_fields(R4SdkDataSha256 *output, const R4SdkDataNative_crypto_sha2_Sha2x32____1779033703__3144134277__1013904242__2773480762__1359893119__2600822924__528734635__1541459225___256_ * p0, uint64_t p1, uint64_t p2) {
 R4SdkDataSlot a[3]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 a[1] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKDATA_PRESENT};
 a[2] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,145u,a,3u,output);
}
static inline R4SdkDataSlot R4SdkDataSha256_get_inner(const R4SdkDataSha256 *self, R4SdkDataNative_crypto_sha2_Sha2x32____1779033703__3144134277__1013904242__2773480762__1359893119__2600822924__528734635__1541459225___256_ *output) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,145u,0u,(void *)self,0,output); }
static inline R4SdkDataSlot R4SdkDataSha256_set_inner(R4SdkDataSha256 *self, const R4SdkDataNative_crypto_sha2_Sha2x32____1779033703__3144134277__1013904242__2773480762__1359893119__2600822924__528734635__1541459225___256_ * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,145u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataSha256_get_accepted_blocks(const R4SdkDataSha256 *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,145u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataSha256_set_accepted_blocks(R4SdkDataSha256 *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,145u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataSha256_get_refused_windows(const R4SdkDataSha256 *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,145u,2u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataSha256_set_refused_windows(R4SdkDataSha256 *self, uint64_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,145u,2u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataSha256_inspectNative(const R4SdkDataSha256 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,145u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value148_create(R4SdkDataNative_Value148 *output, R4SdkDataArena * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,148u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value148_inspectNative(const R4SdkDataNative_Value148 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,148u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value149_create(R4SdkDataNative_Value149 *output, const R4SdkDataArena * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,149u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value149_inspectNative(const R4SdkDataNative_Value149 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,149u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value150_create(R4SdkDataNative_Value150 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,150u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value150_inspectNative(const R4SdkDataNative_Value150 *self, R4SdkDataArtifactIdentity *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,150u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataReader_create(R4SdkDataReader *output, uintptr_t p1) {
 R4SdkDataSlot a[2]={0};
 a[0].flags=R4SDKDATA_DEFAULT;
 a[1] = (R4SdkDataSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,151u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataReader_from_fields(R4SdkDataReader *output, R4SdkDataSlot p0, uintptr_t p1) {
 R4SdkDataSlot a[2]={0};
 a[0] = p0;
 a[1] = (R4SdkDataSlot){.ptr=(void *)(uintptr_t)p1,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,151u,a,2u,output);
}
static inline R4SdkDataSlot R4SdkDataReader_get_user(const R4SdkDataReader *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,151u,0u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataReader_set_user(R4SdkDataReader *self, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,151u,0u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataReader_get_callback(const R4SdkDataReader *self) { return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,151u,1u,(void *)self,0,0); }
static inline R4SdkDataSlot R4SdkDataReader_set_callback(R4SdkDataReader *self, uintptr_t p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,151u,1u,self,a,0); }
static inline R4SdkDataSlot R4SdkDataReader_inspectNative(const R4SdkDataReader *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,151u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value152_create(R4SdkDataNative_Value152 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,152u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value152_inspectNative(const R4SdkDataNative_Value152 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,152u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value153_create(R4SdkDataNative_Value153 *output, R4SdkDataContext * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,153u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value153_inspectNative(const R4SdkDataNative_Value153 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,153u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value154_create(R4SdkDataNative_Value154 *output, const R4XStartContext2 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,154u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value154_inspectNative(const R4SdkDataNative_Value154 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,154u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value157_create(R4SdkDataNative_Value157 *output, R4SdkDataNative_Value158 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,157u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value157_inspectNative(const R4SdkDataNative_Value157 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,157u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value158_create(R4SdkDataNative_Value158 *output, const R4SdkDataNative_Value158 * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,158u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value158_inspectNative(const R4SdkDataNative_Value158 *self, R4SdkDataNative_Value158 *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,158u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value159_create(R4SdkDataNative_Value159 *output, const R4SdkDataJsonDocument * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,159u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value159_inspectNative(const R4SdkDataNative_Value159 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,159u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value160_inspectNative(const R4SdkDataNative_Value160 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,160u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value161_inspectNative(const R4SdkDataNative_Value161 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,161u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value162_inspectNative(const R4SdkDataNative_Value162 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,162u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value163_inspectNative(const R4SdkDataNative_Value163 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,163u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value164_create(R4SdkDataNative_Value164 *output, R4SdkDataZipEntry * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,164u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value164_inspectNative(const R4SdkDataNative_Value164 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,164u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value165_inspectNative(const R4SdkDataNative_Value165 *self, R4SdkDataZipInfo *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,165u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value166_create(R4SdkDataNative_Value166 *output, R4SdkDataZipWork * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,166u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value166_inspectNative(const R4SdkDataNative_Value166 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,166u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value167_inspectNative(const R4SdkDataNative_Value167 *self, R4SdkDataZipProgress *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,167u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value168_create(R4SdkDataNative_Value168 *output, const uint32_t * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,168u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value168_inspectNative(const R4SdkDataNative_Value168 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,168u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value169_create(R4SdkDataNative_Value169 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,169u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value169_inspectNative(const R4SdkDataNative_Value169 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,169u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value170_create(R4SdkDataNative_Value170 *output, R4SdkDataRasterImage * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,170u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value170_inspectNative(const R4SdkDataNative_Value170 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,170u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value171_inspectNative(const R4SdkDataNative_Value171 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,171u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value172_create(R4SdkDataNative_Value172 *output, const R4CpuAccelerationInfo * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,172u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value172_inspectNative(const R4SdkDataNative_Value172 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,172u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value174_create(R4SdkDataNative_Value174 *output, const R4SdkDataEncodingDecoder * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,174u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value174_inspectNative(const R4SdkDataNative_Value174 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,174u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value175_create(R4SdkDataNative_Value175 *output, R4SdkDataEncodingDecoder * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,175u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value175_inspectNative(const R4SdkDataNative_Value175 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,175u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value176_inspectNative(const R4SdkDataNative_Value176 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,176u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value177_inspectNative(const R4SdkDataNative_Value177 *self, R4SdkDataUrlSearchParams *output) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,177u,(void *)self,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value178_create(R4SdkDataNative_Value178 *output, R4SdkDataUrlSearchParams * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,178u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value178_inspectNative(const R4SdkDataNative_Value178 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,178u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value179_create(R4SdkDataNative_Value179 *output, const R4SdkDataUrlSearchParams * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,179u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value179_inspectNative(const R4SdkDataNative_Value179 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,179u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value180_create(R4SdkDataNative_Value180 *output, const R4SdkDataProjectProject * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,180u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value180_inspectNative(const R4SdkDataNative_Value180 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,180u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value181_create(R4SdkDataNative_Value181 *output, const R4SdkDataProjectItem * p0, uintptr_t n0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,181u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value181_inspectNative(const R4SdkDataNative_Value181 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,181u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value182_create(R4SdkDataNative_Value182 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,182u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value182_inspectNative(const R4SdkDataNative_Value182 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,182u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value183_create(R4SdkDataNative_Value183 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,183u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value183_inspectNative(const R4SdkDataNative_Value183 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,183u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value184_create(R4SdkDataNative_Value184 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,184u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value184_inspectNative(const R4SdkDataNative_Value184 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,184u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value185_create(R4SdkDataNative_Value185 *output, R4SdkDataSlot p0) { R4SdkDataSlot a[1]={0};
 a[0] = p0;
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,185u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value185_inspectNative(const R4SdkDataNative_Value185 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,185u,(void *)self,0); }
static inline R4SdkDataSlot R4SdkDataNative_Value186_create(R4SdkDataNative_Value186 *output, const R4SdkDataArtifactIdentity * p0) { R4SdkDataSlot a[1]={0};
 a[0] = (R4SdkDataSlot){.ptr=(void *)p0,.flags=R4SDKDATA_PRESENT};
 return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,186u,a,1u,output); }
static inline R4SdkDataSlot R4SdkDataNative_Value186_inspectNative(const R4SdkDataNative_Value186 *self) { return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,186u,(void *)self,0); }
#endif
