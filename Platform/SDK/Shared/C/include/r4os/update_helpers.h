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
#ifndef R4SDKUPDATE_HELPERS_H
#define R4SDKUPDATE_HELPERS_H
#include "r4os/abi.h"
#include "r4os/generation2.h"
#define R4SDKUPDATE_PRESENT 1u
#define R4SDKUPDATE_NATIVE_ERROR 2u
#define R4SDKUPDATE_DEFAULT 4u
typedef struct R4SdkUpdateSlot { void *ptr; uint64_t length,bits; int32_t status; uint32_t flags; } R4SdkUpdateSlot;
R4SdkUpdateSlot R4SdkUpdateInvoke(uint64_t,uint32_t,const R4SdkUpdateSlot *,uint32_t,void *);
R4SdkUpdateSlot R4SdkUpdateConstruct(uint64_t,uint32_t,const R4SdkUpdateSlot *,uint32_t,void *);
R4SdkUpdateSlot R4SdkUpdateInspect(uint64_t,uint32_t,void *,void *);
R4SdkUpdateSlot R4SdkUpdateField(uint64_t,uint32_t,uint32_t,void *,const R4SdkUpdateSlot *,void *);
/* ntfs_builder.WithFormat(ntfs_format).Meta; native size 272, alignment 8. */
typedef struct R4SdkUpdateNtfsMetadata { _Alignas(8) uint8_t opaque_bytes[272]; } R4SdkUpdateNtfsMetadata;
#define R4SdkUpdateNtfsMetadata_TYPE 0u
/* storage_tools.io.Phase; native size 1, alignment 1. */
typedef struct R4SdkUpdateBlockPhase { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateBlockPhase;
#define R4SdkUpdateBlockPhase_TYPE 2u
/* storage_tools.io.Progress; native size 40, alignment 8. */
typedef struct R4SdkUpdateBlockProgress { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkUpdateBlockProgress;
#define R4SdkUpdateBlockProgress_TYPE 3u
/* ?u64; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue4 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue4;
#define R4SdkUpdateNativeValue4_TYPE 4u
/* ?error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue5 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue5;
#define R4SdkUpdateNativeValue5_TYPE 5u
/* storage_tools.io.Device; native size 72, alignment 8. */
typedef struct R4SdkUpdateBlockDevice { _Alignas(8) uint8_t opaque_bytes[72]; } R4SdkUpdateBlockDevice;
#define R4SdkUpdateBlockDevice_TYPE 6u
/* ?*storage_tools.io.Progress; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue7 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue7;
#define R4SdkUpdateNativeValue7_TYPE 7u
/* *storage_tools.io.Progress; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue8 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue8;
#define R4SdkUpdateNativeValue8_TYPE 8u
/* ?*const fn (?*anyopaque, storage_tools.io.Phase, u64) bool; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue10 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue10;
#define R4SdkUpdateNativeValue10_TYPE 10u
/* storage_tools.io.Region; native size 88, alignment 8. */
typedef struct R4SdkUpdateBlockRegion { _Alignas(8) uint8_t opaque_bytes[88]; } R4SdkUpdateBlockRegion;
#define R4SdkUpdateBlockRegion_TYPE 11u
/* storage_tools.io.Memory; native size 16, alignment 8. */
typedef struct R4SdkUpdateBlockMemory { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateBlockMemory;
#define R4SdkUpdateBlockMemory_TYPE 12u
/* storage_tools.byte_source.Source; native size 32, alignment 8. */
typedef struct R4SdkUpdateByteSource { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkUpdateByteSource;
#define R4SdkUpdateByteSource_TYPE 14u
/* storage_tools.sparse_image.Image; native size 65608, alignment 8. */
typedef struct R4SdkUpdateStoragesparse_image_Image { _Alignas(8) uint8_t opaque_bytes[65608]; } R4SdkUpdateStoragesparse_image_Image;
#define R4SdkUpdateStoragesparse_image_Image_TYPE 15u
/* []?[]const u8; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue17 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue17;
#define R4SdkUpdateNativeValue17_TYPE 17u
/* [65536]u8; native size 65536, alignment 1. */
typedef struct R4SdkUpdateNativeValue19 { _Alignas(1) uint8_t opaque_bytes[65536]; } R4SdkUpdateNativeValue19;
#define R4SdkUpdateNativeValue19_TYPE 19u
/* update_host_file.File; native size 65536, alignment 64. */
typedef struct R4SdkUpdateHostFile { _Alignas(64) uint8_t opaque_bytes[65536]; } R4SdkUpdateHostFile;
#define R4SdkUpdateHostFile_TYPE 20u
/* *update_host_file.File; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue21 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue21;
#define R4SdkUpdateNativeValue21_TYPE 21u
/* anyerror!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue22 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue22;
#define R4SdkUpdateNativeValue22_TYPE 22u
/* anyerror!storage_tools.io.Device; native size 80, alignment 8. */
typedef struct R4SdkUpdateNativeValue23 { _Alignas(8) uint8_t opaque_bytes[80]; } R4SdkUpdateNativeValue23;
#define R4SdkUpdateNativeValue23_TYPE 23u
/* storage_tools.partition.Kind; native size 1, alignment 1. */
typedef struct R4SdkUpdatePartitionKind { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdatePartitionKind;
#define R4SdkUpdatePartitionKind_TYPE 24u
/* storage_tools.partition.Range; native size 16, alignment 8. */
typedef struct R4SdkUpdatePartitionRange { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdatePartitionRange;
#define R4SdkUpdatePartitionRange_TYPE 25u
/* storage_tools.partition.Entry; native size 152, alignment 8. */
typedef struct R4SdkUpdatePartitionEntry { _Alignas(8) uint8_t opaque_bytes[152]; } R4SdkUpdatePartitionEntry;
#define R4SdkUpdatePartitionEntry_TYPE 26u
/* [16]u8; native size 16, alignment 1. */
typedef struct R4SdkUpdateNativeValue27 { _Alignas(1) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue27;
#define R4SdkUpdateNativeValue27_TYPE 27u
/* [36]u16; native size 72, alignment 2. */
typedef struct R4SdkUpdateNativeValue28 { _Alignas(2) uint8_t opaque_bytes[72]; } R4SdkUpdateNativeValue28;
#define R4SdkUpdateNativeValue28_TYPE 28u
/* storage_tools.partition.Plan; native size 20096, alignment 8. */
typedef struct R4SdkUpdatePartitionPlan { _Alignas(8) uint8_t opaque_bytes[20096]; } R4SdkUpdatePartitionPlan;
#define R4SdkUpdatePartitionPlan_TYPE 29u
/* [446]u8; native size 446, alignment 1. */
typedef struct R4SdkUpdateNativeValue30 { _Alignas(1) uint8_t opaque_bytes[446]; } R4SdkUpdateNativeValue30;
#define R4SdkUpdateNativeValue30_TYPE 30u
/* [128]storage_tools.partition.Entry; native size 19456, alignment 8. */
typedef struct R4SdkUpdateNativeValue31 { _Alignas(8) uint8_t opaque_bytes[19456]; } R4SdkUpdateNativeValue31;
#define R4SdkUpdateNativeValue31_TYPE 31u
/* storage_tools.partition.Source; native size 120, alignment 8. */
typedef struct R4SdkUpdatePartitionSource { _Alignas(8) uint8_t opaque_bytes[120]; } R4SdkUpdatePartitionSource;
#define R4SdkUpdatePartitionSource_TYPE 32u
/* [5]storage_tools.partition.Range; native size 80, alignment 8. */
typedef struct R4SdkUpdateNativeValue33 { _Alignas(8) uint8_t opaque_bytes[80]; } R4SdkUpdateNativeValue33;
#define R4SdkUpdateNativeValue33_TYPE 33u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.clean)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue35 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue35;
#define R4SdkUpdateNativeValue35_TYPE 35u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.asciiName)).@"fn".return_type.?).error_union.error_set![36]u16; native size 74, alignment 2. */
typedef struct R4SdkUpdateNativeValue36 { _Alignas(2) uint8_t opaque_bytes[74]; } R4SdkUpdateNativeValue36;
#define R4SdkUpdateNativeValue36_TYPE 36u
/* ?[16]u8; native size 17, alignment 1. */
typedef struct R4SdkUpdateNativeValue37 { _Alignas(1) uint8_t opaque_bytes[17]; } R4SdkUpdateNativeValue37;
#define R4SdkUpdateNativeValue37_TYPE 37u
/* [36]u8; native size 36, alignment 1. */
typedef struct R4SdkUpdateNativeValue38 { _Alignas(1) uint8_t opaque_bytes[36]; } R4SdkUpdateNativeValue38;
#define R4SdkUpdateNativeValue38_TYPE 38u
/* storage_tools.fat32.Geometry; native size 24, alignment 4. */
typedef struct R4SdkUpdateFat32Geometry { _Alignas(4) uint8_t opaque_bytes[24]; } R4SdkUpdateFat32Geometry;
#define R4SdkUpdateFat32Geometry_TYPE 39u
/* storage_tools.fat32.Plan; native size 40, alignment 4. */
typedef struct R4SdkUpdateFat32Plan { _Alignas(4) uint8_t opaque_bytes[40]; } R4SdkUpdateFat32Plan;
#define R4SdkUpdateFat32Plan_TYPE 40u
/* [11]u8; native size 11, alignment 1. */
typedef struct R4SdkUpdateNativeValue41 { _Alignas(1) uint8_t opaque_bytes[11]; } R4SdkUpdateNativeValue41;
#define R4SdkUpdateNativeValue41_TYPE 41u
/* [512]u8; native size 512, alignment 1. */
typedef struct R4SdkUpdateNativeValue42 { _Alignas(1) uint8_t opaque_bytes[512]; } R4SdkUpdateNativeValue42;
#define R4SdkUpdateNativeValue42_TYPE 42u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32.volumeLabel)).@"fn".return_type.?).error_union.error_set![11]u8; native size 14, alignment 2. */
typedef struct R4SdkUpdateNativeValue43 { _Alignas(2) uint8_t opaque_bytes[14]; } R4SdkUpdateNativeValue43;
#define R4SdkUpdateNativeValue43_TYPE 43u
/* storage_tools.fat32_image.File; native size 32, alignment 8. */
typedef struct R4SdkUpdateStoragefat32_image_File { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkUpdateStoragefat32_image_File;
#define R4SdkUpdateStoragefat32_image_File_TYPE 44u
/* storage_tools.fat32_image.Stats; native size 28, alignment 4. */
typedef struct R4SdkUpdateStoragefat32_image_Stats { _Alignas(4) uint8_t opaque_bytes[28]; } R4SdkUpdateStoragefat32_image_Stats;
#define R4SdkUpdateStoragefat32_image_Stats_TYPE 45u
/* storage_tools.fat32_image.Streamed; native size 88, alignment 8. */
typedef struct R4SdkUpdateStoragefat32_image_Streamed { _Alignas(8) uint8_t opaque_bytes[88]; } R4SdkUpdateStoragefat32_image_Streamed;
#define R4SdkUpdateStoragefat32_image_Streamed_TYPE 46u
/* array_list.Aligned(storage_tools.fat32_image.Streamed.Segment,null); native size 24, alignment 8. */
typedef struct R4SdkUpdateNative_array_list_Aligned_storage_tools_fat32_image_Streamed_Segment_null_ { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateNative_array_list_Aligned_storage_tools_fat32_image_Streamed_Segment_null_;
#define R4SdkUpdateNative_array_list_Aligned_storage_tools_fat32_image_Streamed_Segment_null__TYPE 47u
/* storage_tools.fat32_image.Prepared; native size 64, alignment 8. */
typedef struct R4SdkUpdateStoragefat32_image_Prepared { _Alignas(8) uint8_t opaque_bytes[64]; } R4SdkUpdateStoragefat32_image_Prepared;
#define R4SdkUpdateStoragefat32_image_Prepared_TYPE 48u
/* []const storage_tools.fat32_image.File; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue49 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue49;
#define R4SdkUpdateNativeValue49_TYPE 49u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_image.prepare)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_image.Prepared; native size 72, alignment 8. */
typedef struct R4SdkUpdateNativeValue50 { _Alignas(8) uint8_t opaque_bytes[72]; } R4SdkUpdateNativeValue50;
#define R4SdkUpdateNativeValue50_TYPE 50u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_image.buildInto)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_image.Stats; native size 32, alignment 4. */
typedef struct R4SdkUpdateNativeValue51 { _Alignas(4) uint8_t opaque_bytes[32]; } R4SdkUpdateNativeValue51;
#define R4SdkUpdateNativeValue51_TYPE 51u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_image.prepareStreamed)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_image.Streamed; native size 96, alignment 8. */
typedef struct R4SdkUpdateNativeValue52 { _Alignas(8) uint8_t opaque_bytes[96]; } R4SdkUpdateNativeValue52;
#define R4SdkUpdateNativeValue52_TYPE 52u
/* storage_tools.fat32_view.View; native size 56, alignment 8. */
typedef struct R4SdkUpdateStoragefat32_view_View { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkUpdateStoragefat32_view_View;
#define R4SdkUpdateStoragefat32_view_View_TYPE 53u
/* storage_tools.fat32_update.Change; native size 32, alignment 8. */
typedef struct R4SdkUpdateStoragefat32_update_Change { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkUpdateStoragefat32_update_Change;
#define R4SdkUpdateStoragefat32_update_Change_TYPE 54u
/* storage_tools.fat32_update.Backing; native size 128, alignment 8. */
typedef struct R4SdkUpdateStoragefat32_update_Backing { _Alignas(8) uint8_t opaque_bytes[128]; } R4SdkUpdateStoragefat32_update_Backing;
#define R4SdkUpdateStoragefat32_update_Backing_TYPE 55u
/* []?[*]u8; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue56 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue56;
#define R4SdkUpdateNativeValue56_TYPE 56u
/* array_list.Aligned([]u8,null); native size 24, alignment 8. */
typedef struct R4SdkUpdateNative_array_list_Aligned___u8_null_ { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateNative_array_list_Aligned___u8_null_;
#define R4SdkUpdateNative_array_list_Aligned___u8_null__TYPE 58u
/* *storage_tools.fat32_update.Backing; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue59 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue59;
#define R4SdkUpdateNativeValue59_TYPE 59u
/* []const storage_tools.fat32_update.Change; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue60 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue60;
#define R4SdkUpdateNativeValue60_TYPE 60u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.prepareBacking)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_update.Prepared; native size 128, alignment 8. */
typedef struct R4SdkUpdateNativeValue61 { _Alignas(8) uint8_t opaque_bytes[128]; } R4SdkUpdateNativeValue61;
#define R4SdkUpdateNativeValue61_TYPE 61u
/* storage_tools.fat32_update.Prepared; native size 120, alignment 8. */
typedef struct R4SdkUpdateStoragefat32_update_Prepared { _Alignas(8) uint8_t opaque_bytes[120]; } R4SdkUpdateStoragefat32_update_Prepared;
#define R4SdkUpdateStoragefat32_update_Prepared_TYPE 62u
/* []storage_tools.fat32_update.Write; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue63 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue63;
#define R4SdkUpdateNativeValue63_TYPE 63u
/* storage_tools.fat32_update.Write; native size 24, alignment 8. */
typedef struct R4SdkUpdateStoragefat32_update_Write { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateStoragefat32_update_Write;
#define R4SdkUpdateStoragefat32_update_Write_TYPE 64u
/* []storage_tools.fat32_update.SourceRange; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue65 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue65;
#define R4SdkUpdateNativeValue65_TYPE 65u
/* storage_tools.fat32_update.SourceRange; native size 8, alignment 4. */
typedef struct R4SdkUpdateStoragefat32_update_SourceRange { _Alignas(4) uint8_t opaque_bytes[8]; } R4SdkUpdateStoragefat32_update_SourceRange;
#define R4SdkUpdateStoragefat32_update_SourceRange_TYPE 66u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.verifyTree)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue68 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue68;
#define R4SdkUpdateNativeValue68_TYPE 68u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.verifyTreeBacking)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue69 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue69;
#define R4SdkUpdateNativeValue69_TYPE 69u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.prepare)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_update.Prepared; native size 128, alignment 8. */
typedef struct R4SdkUpdateNativeValue70 { _Alignas(8) uint8_t opaque_bytes[128]; } R4SdkUpdateNativeValue70;
#define R4SdkUpdateNativeValue70_TYPE 70u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.prepareDelta)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_update.Prepared; native size 128, alignment 8. */
typedef struct R4SdkUpdateNativeValue71 { _Alignas(8) uint8_t opaque_bytes[128]; } R4SdkUpdateNativeValue71;
#define R4SdkUpdateNativeValue71_TYPE 71u
/* ntfs_format.AttrType; native size 4, alignment 4. */
typedef struct R4SdkUpdateNtfsFormatAttrType { _Alignas(4) uint8_t opaque_bytes[4]; } R4SdkUpdateNtfsFormatAttrType;
#define R4SdkUpdateNtfsFormatAttrType_TYPE 72u
/* ntfs_format.FileReference; native size 16, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatFileReference { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNtfsFormatFileReference;
#define R4SdkUpdateNtfsFormatFileReference_TYPE 73u
/* ntfs_format.BootSector; native size 48, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatBootSector { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkUpdateNtfsFormatBootSector;
#define R4SdkUpdateNtfsFormatBootSector_TYPE 74u
/* ntfs_format.FixupError; native size 1, alignment 1. */
typedef struct R4SdkUpdateNtfsFormatFixupError { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateNtfsFormatFixupError;
#define R4SdkUpdateNtfsFormatFixupError_TYPE 75u
/* ntfs_format.FileRecordHeader; native size 56, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatFileRecordHeader { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkUpdateNtfsFormatFileRecordHeader;
#define R4SdkUpdateNtfsFormatFileRecordHeader_TYPE 76u
/* ntfs_format.Attribute; native size 104, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatAttribute { _Alignas(8) uint8_t opaque_bytes[104]; } R4SdkUpdateNtfsFormatAttribute;
#define R4SdkUpdateNtfsFormatAttribute_TYPE 77u
/* ntfs_format.AttributeIterator; native size 24, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatAttributeIterator { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateNtfsFormatAttributeIterator;
#define R4SdkUpdateNtfsFormatAttributeIterator_TYPE 78u
/* ?ntfs_format.Attribute; native size 112, alignment 8. */
typedef struct R4SdkUpdateNativeValue79 { _Alignas(8) uint8_t opaque_bytes[112]; } R4SdkUpdateNativeValue79;
#define R4SdkUpdateNativeValue79_TYPE 79u
/* ntfs_format.Run; native size 24, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatRun { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateNtfsFormatRun;
#define R4SdkUpdateNtfsFormatRun_TYPE 80u
/* ntfs_format.RunlistIterator; native size 40, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatRunlistIterator { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkUpdateNtfsFormatRunlistIterator;
#define R4SdkUpdateNtfsFormatRunlistIterator_TYPE 81u
/* ?i64; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue82 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue82;
#define R4SdkUpdateNativeValue82_TYPE 82u
/* ?usize; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue83 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue83;
#define R4SdkUpdateNativeValue83_TYPE 83u
/* ntfs_format.StandardInformation; native size 40, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatStandardInformation { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkUpdateNtfsFormatStandardInformation;
#define R4SdkUpdateNtfsFormatStandardInformation_TYPE 84u
/* ntfs_format.FileName; native size 88, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatFileName { _Alignas(8) uint8_t opaque_bytes[88]; } R4SdkUpdateNtfsFormatFileName;
#define R4SdkUpdateNtfsFormatFileName_TYPE 85u
/* ntfs_format.AttributeListEntry; native size 48, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatAttributeListEntry { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkUpdateNtfsFormatAttributeListEntry;
#define R4SdkUpdateNtfsFormatAttributeListEntry_TYPE 86u
/* ntfs_format.AttributeListIterator; native size 24, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatAttributeListIterator { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateNtfsFormatAttributeListIterator;
#define R4SdkUpdateNtfsFormatAttributeListIterator_TYPE 87u
/* ntfs_format.IndexRoot; native size 48, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatIndexRoot { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkUpdateNtfsFormatIndexRoot;
#define R4SdkUpdateNtfsFormatIndexRoot_TYPE 88u
/* ntfs_format.IndexHeader; native size 16, alignment 4. */
typedef struct R4SdkUpdateNtfsFormatIndexHeader { _Alignas(4) uint8_t opaque_bytes[16]; } R4SdkUpdateNtfsFormatIndexHeader;
#define R4SdkUpdateNtfsFormatIndexHeader_TYPE 89u
/* ntfs_format.IndexBlock; native size 32, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatIndexBlock { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkUpdateNtfsFormatIndexBlock;
#define R4SdkUpdateNtfsFormatIndexBlock_TYPE 90u
/* ntfs_format.IndexEntry; native size 48, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatIndexEntry { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkUpdateNtfsFormatIndexEntry;
#define R4SdkUpdateNtfsFormatIndexEntry_TYPE 91u
/* ntfs_format.IndexEntryIterator; native size 32, alignment 8. */
typedef struct R4SdkUpdateNtfsFormatIndexEntryIterator { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkUpdateNtfsFormatIndexEntryIterator;
#define R4SdkUpdateNtfsFormatIndexEntryIterator_TYPE 92u
/* math.Order; native size 1, alignment 1. */
typedef struct R4SdkUpdateNative_math_Order { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateNative_math_Order;
#define R4SdkUpdateNative_math_Order_TYPE 93u
/* ntfs_format.VolumeInformation; native size 4, alignment 2. */
typedef struct R4SdkUpdateNtfsFormatVolumeInformation { _Alignas(2) uint8_t opaque_bytes[4]; } R4SdkUpdateNtfsFormatVolumeInformation;
#define R4SdkUpdateNtfsFormatVolumeInformation_TYPE 94u
/* storage_tools.ntfs_plan.Plan; native size 616, alignment 8. */
typedef struct R4SdkUpdateNtfsPlan { _Alignas(8) uint8_t opaque_bytes[616]; } R4SdkUpdateNtfsPlan;
#define R4SdkUpdateNtfsPlan_TYPE 95u
/* array_list.Aligned(storage_tools.ntfs_plan.Segment,null); native size 24, alignment 8. */
typedef struct R4SdkUpdateNative_array_list_Aligned_storage_tools_ntfs_plan_Segment_null_ { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateNative_array_list_Aligned_storage_tools_ntfs_plan_Segment_null_;
#define R4SdkUpdateNative_array_list_Aligned_storage_tools_ntfs_plan_Segment_null__TYPE 96u
/* ntfs_builder.WithFormat(ntfs_format).Builder; native size 384, alignment 8. */
typedef struct R4SdkUpdateNtfsBuilder { _Alignas(8) uint8_t opaque_bytes[384]; } R4SdkUpdateNtfsBuilder;
#define R4SdkUpdateNtfsBuilder_TYPE 97u
/* array_list.Aligned(ntfs_builder.WithFormat(ntfs_format).Node,null); native size 24, alignment 8. */
typedef struct R4SdkUpdateNative_array_list_Aligned_ntfs_builder_WithFormat_ntfs_format__Node_null_ { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateNative_array_list_Aligned_ntfs_builder_WithFormat_ntfs_format__Node_null_;
#define R4SdkUpdateNative_array_list_Aligned_ntfs_builder_WithFormat_ntfs_format__Node_null__TYPE 98u
/* storage_tools.ntfs_plan.Segment; native size 32, alignment 8. */
typedef struct R4SdkUpdateNtfsSegment { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkUpdateNtfsSegment;
#define R4SdkUpdateNtfsSegment_TYPE 99u
/* storage_tools.ntfs_resize.ShrinkLimits; native size 40, alignment 8. */
typedef struct R4SdkUpdateStoragentfs_resize_ShrinkLimits { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkUpdateStoragentfs_resize_ShrinkLimits;
#define R4SdkUpdateStoragentfs_resize_ShrinkLimits_TYPE 100u
/* storage_tools.ntfs_resize.Plan; native size 29648, alignment 8. */
typedef struct R4SdkUpdateStoragentfs_resize_Plan { _Alignas(8) uint8_t opaque_bytes[29648]; } R4SdkUpdateStoragentfs_resize_Plan;
#define R4SdkUpdateStoragentfs_resize_Plan_TYPE 101u
/* storage_tools.ntfs_resize.Map; native size 1560, alignment 8. */
typedef struct R4SdkUpdateStoragentfs_resize_Map { _Alignas(8) uint8_t opaque_bytes[1560]; } R4SdkUpdateStoragentfs_resize_Map;
#define R4SdkUpdateStoragentfs_resize_Map_TYPE 102u
/* [64]ntfs_format.Run; native size 1536, alignment 8. */
typedef struct R4SdkUpdateNativeValue103 { _Alignas(8) uint8_t opaque_bytes[1536]; } R4SdkUpdateNativeValue103;
#define R4SdkUpdateNativeValue103_TYPE 103u
/* ?[32]u8; native size 33, alignment 1. */
typedef struct R4SdkUpdateNativeValue104 { _Alignas(1) uint8_t opaque_bytes[33]; } R4SdkUpdateNativeValue104;
#define R4SdkUpdateNativeValue104_TYPE 104u
/* [152]storage_tools.ntfs_resize.Source; native size 7296, alignment 8. */
typedef struct R4SdkUpdateNativeValue105 { _Alignas(8) uint8_t opaque_bytes[7296]; } R4SdkUpdateNativeValue105;
#define R4SdkUpdateNativeValue105_TYPE 105u
/* storage_tools.ntfs_resize.Source; native size 48, alignment 8. */
typedef struct R4SdkUpdateStoragentfs_resize_Source { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkUpdateStoragentfs_resize_Source;
#define R4SdkUpdateStoragentfs_resize_Source_TYPE 106u
/* [4]storage_tools.ntfs_resize.Patch; native size 16448, alignment 8. */
typedef struct R4SdkUpdateNativeValue107 { _Alignas(8) uint8_t opaque_bytes[16448]; } R4SdkUpdateNativeValue107;
#define R4SdkUpdateNativeValue107_TYPE 107u
/* storage_tools.ntfs_resize.Patch; native size 4112, alignment 8. */
typedef struct R4SdkUpdateStoragentfs_resize_Patch { _Alignas(8) uint8_t opaque_bytes[4112]; } R4SdkUpdateStoragentfs_resize_Patch;
#define R4SdkUpdateStoragentfs_resize_Patch_TYPE 108u
/* [4096]u8; native size 4096, alignment 1. */
typedef struct R4SdkUpdateNativeValue109 { _Alignas(1) uint8_t opaque_bytes[4096]; } R4SdkUpdateNativeValue109;
#define R4SdkUpdateNativeValue109_TYPE 109u
/* [1024]u8; native size 1024, alignment 1. */
typedef struct R4SdkUpdateNativeValue110 { _Alignas(1) uint8_t opaque_bytes[1024]; } R4SdkUpdateNativeValue110;
#define R4SdkUpdateNativeValue110_TYPE 110u
/* storage_tools.gpt_repair.Status; native size 1, alignment 1. */
typedef struct R4SdkUpdateStoragegpt_repair_Status { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateStoragegpt_repair_Status;
#define R4SdkUpdateStoragegpt_repair_Status_TYPE 111u
/* storage_tools.gpt_repair.Report; native size 34560, alignment 8. */
typedef struct R4SdkUpdateStoragegpt_repair_Report { _Alignas(8) uint8_t opaque_bytes[34560]; } R4SdkUpdateStoragegpt_repair_Report;
#define R4SdkUpdateStoragegpt_repair_Report_TYPE 112u
/* storage_tools.installation.Role; native size 1, alignment 1. */
typedef struct R4SdkUpdateStorageinstallation_Role { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateStorageinstallation_Role;
#define R4SdkUpdateStorageinstallation_Role_TYPE 113u
/* storage_tools.installation.Medium; native size 1, alignment 1. */
typedef struct R4SdkUpdateStorageinstallation_Medium { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateStorageinstallation_Medium;
#define R4SdkUpdateStorageinstallation_Medium_TYPE 114u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.sourceRanges)).@"fn".return_type.?).error_union.error_set![5]storage_tools.partition.Range; native size 88, alignment 8. */
typedef struct R4SdkUpdateNativeValue115 { _Alignas(8) uint8_t opaque_bytes[88]; } R4SdkUpdateNativeValue115;
#define R4SdkUpdateNativeValue115_TYPE 115u
/* storage_tools.installation.Identifiers; native size 112, alignment 1. */
typedef struct R4SdkUpdateStorageinstallation_Identifiers { _Alignas(1) uint8_t opaque_bytes[112]; } R4SdkUpdateStorageinstallation_Identifiers;
#define R4SdkUpdateStorageinstallation_Identifiers_TYPE 116u
/* [5][16]u8; native size 80, alignment 1. */
typedef struct R4SdkUpdateNativeValue117 { _Alignas(1) uint8_t opaque_bytes[80]; } R4SdkUpdateNativeValue117;
#define R4SdkUpdateNativeValue117_TYPE 117u
/* storage_tools.installation.Layout; native size 200, alignment 8. */
typedef struct R4SdkUpdateStorageinstallation_Layout { _Alignas(8) uint8_t opaque_bytes[200]; } R4SdkUpdateStorageinstallation_Layout;
#define R4SdkUpdateStorageinstallation_Layout_TYPE 118u
/* *const storage_tools.partition.Plan; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue119 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue119;
#define R4SdkUpdateNativeValue119_TYPE 119u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.limine.verifyBios)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue120 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue120;
#define R4SdkUpdateNativeValue120_TYPE 120u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.limine.installBios)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue121 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue121;
#define R4SdkUpdateNativeValue121_TYPE 121u
/* storage_tools_guest.Target; native size 88, alignment 8. */
typedef struct R4SdkUpdateGuestTarget { _Alignas(8) uint8_t opaque_bytes[88]; } R4SdkUpdateGuestTarget;
#define R4SdkUpdateGuestTarget_TYPE 122u
/* storage.Context; native size 8, alignment 8. */
typedef struct R4SdkUpdateNative_storage_Context { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNative_storage_Context;
#define R4SdkUpdateNative_storage_Context_TYPE 123u
/* system_update_inventory.ModuleRole; native size 0, alignment 1. */
typedef struct R4SdkUpdateInventoryModuleRole { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateInventoryModuleRole;
#define R4SdkUpdateInventoryModuleRole_TYPE 138u
/* system_update_inventory.Profile; native size 1, alignment 1. */
typedef struct R4SdkUpdateInventoryProfile { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateInventoryProfile;
#define R4SdkUpdateInventoryProfile_TYPE 139u
/* system_update_inventory.Entry; native size 1392, alignment 8. */
typedef struct R4SdkUpdateInventoryEntry { _Alignas(8) uint8_t opaque_bytes[1392]; } R4SdkUpdateInventoryEntry;
#define R4SdkUpdateInventoryEntry_TYPE 140u
/* ?system_update_inventory.ModuleRole; native size 1, alignment 1. */
typedef struct R4SdkUpdateNativeValue141 { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateNativeValue141;
#define R4SdkUpdateNativeValue141_TYPE 141u
/* [16][]const u8; native size 256, alignment 8. */
typedef struct R4SdkUpdateNativeValue142 { _Alignas(8) uint8_t opaque_bytes[256]; } R4SdkUpdateNativeValue142;
#define R4SdkUpdateNativeValue142_TYPE 142u
/* [32][]const u8; native size 512, alignment 8. */
typedef struct R4SdkUpdateNativeValue143 { _Alignas(8) uint8_t opaque_bytes[512]; } R4SdkUpdateNativeValue143;
#define R4SdkUpdateNativeValue143_TYPE 143u
/* system_update_inventory.Inventory; native size 267280, alignment 8. */
typedef struct R4SdkUpdateInventoryInventory { _Alignas(8) uint8_t opaque_bytes[267280]; } R4SdkUpdateInventoryInventory;
#define R4SdkUpdateInventoryInventory_TYPE 144u
/* [192]system_update_inventory.Entry; native size 267264, alignment 8. */
typedef struct R4SdkUpdateNativeValue145 { _Alignas(8) uint8_t opaque_bytes[267264]; } R4SdkUpdateNativeValue145;
#define R4SdkUpdateNativeValue145_TYPE 145u
/* system_update_recovery.JournalPhase; native size 1, alignment 1. */
typedef struct R4SdkUpdateRecoveryJournalPhase { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateRecoveryJournalPhase;
#define R4SdkUpdateRecoveryJournalPhase_TYPE 146u
/* system_update_recovery.PathState; native size 1, alignment 1. */
typedef struct R4SdkUpdateRecoveryPathState { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateRecoveryPathState;
#define R4SdkUpdateRecoveryPathState_TYPE 147u
/* system_update_recovery.PresenceState; native size 1, alignment 1. */
typedef struct R4SdkUpdateRecoveryPresenceState { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateRecoveryPresenceState;
#define R4SdkUpdateRecoveryPresenceState_TYPE 148u
/* system_update_recovery.MutationStatus; native size 1, alignment 1. */
typedef struct R4SdkUpdateRecoveryMutationStatus { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateRecoveryMutationStatus;
#define R4SdkUpdateRecoveryMutationStatus_TYPE 149u
/* system_update_recovery.ReplayStatus; native size 1, alignment 1. */
typedef struct R4SdkUpdateRecoveryReplayStatus { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateRecoveryReplayStatus;
#define R4SdkUpdateRecoveryReplayStatus_TYPE 150u
/* system_update_recovery.SlotSelection; native size 2, alignment 1. */
typedef struct R4SdkUpdateRecoverySlotSelection { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkUpdateRecoverySlotSelection;
#define R4SdkUpdateRecoverySlotSelection_TYPE 151u
/* @typeInfo(system_update_recovery.SlotSelection).@"union".tag_type.?; native size 1, alignment 1. */
typedef struct R4SdkUpdateNative__typeInfo_system_update_recovery_SlotSelection____union__tag_type__ { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateNative__typeInfo_system_update_recovery_SlotSelection____union__tag_type__;
#define R4SdkUpdateNative__typeInfo_system_update_recovery_SlotSelection____union__tag_type___TYPE 152u
/* system_update_recovery.JournalPayload; native size 4176, alignment 8. */
typedef struct R4SdkUpdateRecoveryJournalPayload { _Alignas(8) uint8_t opaque_bytes[4176]; } R4SdkUpdateRecoveryJournalPayload;
#define R4SdkUpdateRecoveryJournalPayload_TYPE 153u
/* [1024:0]u8; native size 1025, alignment 1. */
typedef struct R4SdkUpdateNativeValue154 { _Alignas(1) uint8_t opaque_bytes[1025]; } R4SdkUpdateNativeValue154;
#define R4SdkUpdateNativeValue154_TYPE 154u
/* system_update_recovery.JournalComponentKind; native size 1, alignment 1. */
typedef struct R4SdkUpdateRecoveryJournalComponentKind { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateRecoveryJournalComponentKind;
#define R4SdkUpdateRecoveryJournalComponentKind_TYPE 155u
/* system_update_recovery.JournalComponent; native size 1144, alignment 8. */
typedef struct R4SdkUpdateRecoveryJournalComponent { _Alignas(8) uint8_t opaque_bytes[1144]; } R4SdkUpdateRecoveryJournalComponent;
#define R4SdkUpdateRecoveryJournalComponent_TYPE 156u
/* [49:0]u8; native size 50, alignment 1. */
typedef struct R4SdkUpdateNativeValue157 { _Alignas(1) uint8_t opaque_bytes[50]; } R4SdkUpdateNativeValue157;
#define R4SdkUpdateNativeValue157_TYPE 157u
/* [32:0]u8; native size 33, alignment 1. */
typedef struct R4SdkUpdateNativeValue158 { _Alignas(1) uint8_t opaque_bytes[33]; } R4SdkUpdateNativeValue158;
#define R4SdkUpdateNativeValue158_TYPE 158u
/* system_update_recovery.TransactionJournal; native size 179816, alignment 8. */
typedef struct R4SdkUpdateRecoveryTransactionJournal { _Alignas(8) uint8_t opaque_bytes[179816]; } R4SdkUpdateRecoveryTransactionJournal;
#define R4SdkUpdateRecoveryTransactionJournal_TYPE 159u
/* [32]system_update_recovery.JournalComponent; native size 36608, alignment 8. */
typedef struct R4SdkUpdateNativeValue160 { _Alignas(8) uint8_t opaque_bytes[36608]; } R4SdkUpdateNativeValue160;
#define R4SdkUpdateNativeValue160_TYPE 160u
/* [34]system_update_recovery.JournalPayload; native size 141984, alignment 8. */
typedef struct R4SdkUpdateNativeValue161 { _Alignas(8) uint8_t opaque_bytes[141984]; } R4SdkUpdateNativeValue161;
#define R4SdkUpdateNativeValue161_TYPE 161u
/* [2]bool; native size 2, alignment 1. */
typedef struct R4SdkUpdateNativeValue162 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue162;
#define R4SdkUpdateNativeValue162_TYPE 162u
/* [2]u64; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue163 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue163;
#define R4SdkUpdateNativeValue163_TYPE 163u
/* *const system_update_recovery.TransactionJournal; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue164 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue164;
#define R4SdkUpdateNativeValue164_TYPE 164u
/* *system_update_recovery.TransactionJournal; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue165 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue165;
#define R4SdkUpdateNativeValue165_TYPE 165u
/* system_update_batch.Phase; native size 1, alignment 1. */
typedef struct R4SdkUpdateBatchPhase { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateBatchPhase;
#define R4SdkUpdateBatchPhase_TYPE 166u
/* system_update_batch.PackageEntry; native size 1184, alignment 8. */
typedef struct R4SdkUpdateBatchPackageEntry { _Alignas(8) uint8_t opaque_bytes[1184]; } R4SdkUpdateBatchPackageEntry;
#define R4SdkUpdateBatchPackageEntry_TYPE 167u
/* system_update_batch.BatchJournal; native size 19112, alignment 8. */
typedef struct R4SdkUpdateBatchBatchJournal { _Alignas(8) uint8_t opaque_bytes[19112]; } R4SdkUpdateBatchBatchJournal;
#define R4SdkUpdateBatchBatchJournal_TYPE 170u
/* [65]u8; native size 65, alignment 1. */
typedef struct R4SdkUpdateNativeValue171 { _Alignas(1) uint8_t opaque_bytes[65]; } R4SdkUpdateNativeValue171;
#define R4SdkUpdateNativeValue171_TYPE 171u
/* [16]system_update_batch.PackageEntry; native size 18944, alignment 8. */
typedef struct R4SdkUpdateNativeValue172 { _Alignas(8) uint8_t opaque_bytes[18944]; } R4SdkUpdateNativeValue172;
#define R4SdkUpdateNativeValue172_TYPE 172u
/* system_update_batch.SlotSelection; native size 2, alignment 1. */
typedef struct R4SdkUpdateBatchSlotSelection { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkUpdateBatchSlotSelection;
#define R4SdkUpdateBatchSlotSelection_TYPE 173u
/* @typeInfo(system_update_batch.SlotSelection).@"union".tag_type.?; native size 1, alignment 1. */
typedef struct R4SdkUpdateNative__typeInfo_system_update_batch_SlotSelection____union__tag_type__ { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateNative__typeInfo_system_update_batch_SlotSelection____union__tag_type__;
#define R4SdkUpdateNative__typeInfo_system_update_batch_SlotSelection____union__tag_type___TYPE 174u
/* *const system_update_batch.BatchJournal; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue175 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue175;
#define R4SdkUpdateNativeValue175_TYPE 175u
/* *system_update_batch.BatchJournal; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue176 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue176;
#define R4SdkUpdateNativeValue176_TYPE 176u
/* system_update_batch.PlanComponent; native size 56, alignment 8. */
typedef struct R4SdkUpdateBatchPlanComponent { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkUpdateBatchPlanComponent;
#define R4SdkUpdateBatchPlanComponent_TYPE 177u
/* system_update_batch.PlanRequirement; native size 56, alignment 8. */
typedef struct R4SdkUpdateBatchPlanRequirement { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkUpdateBatchPlanRequirement;
#define R4SdkUpdateBatchPlanRequirement_TYPE 178u
/* system_update_batch.PlanPackage; native size 1, alignment 1. */
typedef struct R4SdkUpdateBatchPlanPackage { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateBatchPlanPackage;
#define R4SdkUpdateBatchPlanPackage_TYPE 179u
/* []const system_update_batch.PlanPackage; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue180 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue180;
#define R4SdkUpdateNativeValue180_TYPE 180u
/* []const system_update_batch.PlanComponent; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue181 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue181;
#define R4SdkUpdateNativeValue181_TYPE 181u
/* []const system_update_batch.PlanRequirement; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue182 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue182;
#define R4SdkUpdateNativeValue182_TYPE 182u
/* error{DependencyCycle,DuplicateComponent,InvalidReference,TooManyPackages,UnresolvedRequirement}![]const u8; native size 24, alignment 8. */
typedef struct R4SdkUpdateNativeValue183 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateNativeValue183;
#define R4SdkUpdateNativeValue183_TYPE 183u
/* update_catalog.Component; native size 56, alignment 8. */
typedef struct R4SdkUpdateCatalogComponent { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkUpdateCatalogComponent;
#define R4SdkUpdateCatalogComponent_TYPE 184u
/* update_catalog.Requirement; native size 56, alignment 8. */
typedef struct R4SdkUpdateCatalogRequirement { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkUpdateCatalogRequirement;
#define R4SdkUpdateCatalogRequirement_TYPE 185u
/* update_catalog.Package; native size 136, alignment 8. */
typedef struct R4SdkUpdateCatalogPackage { _Alignas(8) uint8_t opaque_bytes[136]; } R4SdkUpdateCatalogPackage;
#define R4SdkUpdateCatalogPackage_TYPE 186u
/* update_catalog.CatalogRelease; native size 58968, alignment 8. */
typedef struct R4SdkUpdateCatalogCatalogRelease { _Alignas(8) uint8_t opaque_bytes[58968]; } R4SdkUpdateCatalogCatalogRelease;
#define R4SdkUpdateCatalogCatalogRelease_TYPE 187u
/* [192]update_catalog.Component; native size 10752, alignment 8. */
typedef struct R4SdkUpdateNativeValue188 { _Alignas(8) uint8_t opaque_bytes[10752]; } R4SdkUpdateNativeValue188;
#define R4SdkUpdateNativeValue188_TYPE 188u
/* [64]update_catalog.Package; native size 8704, alignment 8. */
typedef struct R4SdkUpdateNativeValue189 { _Alignas(8) uint8_t opaque_bytes[8704]; } R4SdkUpdateNativeValue189;
#define R4SdkUpdateNativeValue189_TYPE 189u
/* [512]update_catalog.Requirement; native size 28672, alignment 8. */
typedef struct R4SdkUpdateNativeValue190 { _Alignas(8) uint8_t opaque_bytes[28672]; } R4SdkUpdateNativeValue190;
#define R4SdkUpdateNativeValue190_TYPE 190u
/* update_catalog.PackageDelta; native size 6, alignment 2. */
typedef struct R4SdkUpdateCatalogPackageDelta { _Alignas(2) uint8_t opaque_bytes[6]; } R4SdkUpdateCatalogPackageDelta;
#define R4SdkUpdateCatalogPackageDelta_TYPE 191u
/* update_catalog.Plan; native size 160, alignment 8. */
typedef struct R4SdkUpdateCatalogPlan { _Alignas(8) uint8_t opaque_bytes[160]; } R4SdkUpdateCatalogPlan;
#define R4SdkUpdateCatalogPlan_TYPE 192u
/* [64]u16; native size 128, alignment 2. */
typedef struct R4SdkUpdateNativeValue193 { _Alignas(2) uint8_t opaque_bytes[128]; } R4SdkUpdateNativeValue193;
#define R4SdkUpdateNativeValue193_TYPE 193u
/* *const update_catalog.CatalogRelease; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue194 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue194;
#define R4SdkUpdateNativeValue194_TYPE 194u
/* *const system_update_inventory.Inventory; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue195 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue195;
#define R4SdkUpdateNativeValue195_TYPE 195u
/* error{DependencyOrder,InvalidCatalog,InvalidInventory,TooManyPackages,UnmetRequirement}!update_catalog.Plan; native size 168, alignment 8. */
typedef struct R4SdkUpdateNativeValue196 { _Alignas(8) uint8_t opaque_bytes[168]; } R4SdkUpdateNativeValue196;
#define R4SdkUpdateNativeValue196_TYPE 196u
/* *const update_catalog.Package; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue197 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue197;
#define R4SdkUpdateNativeValue197_TYPE 197u
/* error{DependencyOrder,InvalidCatalog,InvalidInventory,TooManyPackages,UnmetRequirement}!update_catalog.PackageDelta; native size 8, alignment 2. */
typedef struct R4SdkUpdateNativeValue198 { _Alignas(2) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue198;
#define R4SdkUpdateNativeValue198_TYPE 198u
/* ?*const system_update_inventory.Entry; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue199 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue199;
#define R4SdkUpdateNativeValue199_TYPE 199u
/* *const system_update_inventory.Entry; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue200 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue200;
#define R4SdkUpdateNativeValue200_TYPE 200u
/* update_callback_bridge.Kind; native size 1, alignment 1. */
typedef struct R4SdkUpdateCallbackKind { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateCallbackKind;
#define R4SdkUpdateCallbackKind_TYPE 201u
/* update_callback_bridge.Table; native size 24, alignment 8. */
typedef struct R4SdkUpdateCallbackTable { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateCallbackTable;
#define R4SdkUpdateCallbackTable_TYPE 202u
/* ?*const fn (?*anyopaque, u32, [*]const native_value_bridge.Slot, u32, ?*anyopaque) callconv(.c) native_value_bridge.Slot; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue203 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue203;
#define R4SdkUpdateNativeValue203_TYPE 203u
/* update_helper_adapters.Replay; native size 8, alignment 8. */
typedef struct R4SdkUpdateReplay { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateReplay;
#define R4SdkUpdateReplay_TYPE 204u
/* *const update_callback_bridge.Table; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue205 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue205;
#define R4SdkUpdateNativeValue205_TYPE 205u
/* error{MissingCallback}!system_update_recovery.ReplayStatus; native size 4, alignment 2. */
typedef struct R4SdkUpdateNativeValue206 { _Alignas(2) uint8_t opaque_bytes[4]; } R4SdkUpdateNativeValue206;
#define R4SdkUpdateNativeValue206_TYPE 206u
/* error{Copy,MissingCallback,Referenced,Remove,Verification}!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue207 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue207;
#define R4SdkUpdateNativeValue207_TYPE 207u
/* error{MissingCallback}!storage_tools.io.Device; native size 80, alignment 8. */
typedef struct R4SdkUpdateNativeValue208 { _Alignas(8) uint8_t opaque_bytes[80]; } R4SdkUpdateNativeValue208;
#define R4SdkUpdateNativeValue208_TYPE 208u
/* error{MissingCallback}!storage_tools.byte_source.Source; native size 40, alignment 8. */
typedef struct R4SdkUpdateNativeValue209 { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkUpdateNativeValue209;
#define R4SdkUpdateNativeValue209_TYPE 209u
/* *storage_tools_guest.Target; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue210 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue210;
#define R4SdkUpdateNativeValue210_TYPE 210u
/* @typeInfo(@typeInfo(@TypeOf(update_helper_adapters.gptRead)).@"fn".return_type.?).error_union.error_set!*storage_tools.gpt_repair.Report; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue213 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue213;
#define R4SdkUpdateNativeValue213_TYPE 213u
/* *storage_tools.gpt_repair.Report; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue214 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue214;
#define R4SdkUpdateNativeValue214_TYPE 214u
/* *const storage_tools.gpt_repair.Report; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue215 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue215;
#define R4SdkUpdateNativeValue215_TYPE 215u
/* @typeInfo(@typeInfo(@TypeOf(update_helper_adapters.gptRepairable)).@"fn".return_type.?).error_union.error_set!usize; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue216 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue216;
#define R4SdkUpdateNativeValue216_TYPE 216u
/* @typeInfo(@typeInfo(@TypeOf(update_helper_adapters.gptRepair)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue217 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue217;
#define R4SdkUpdateNativeValue217_TYPE 217u
/* *update_catalog.CatalogRelease; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue219 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue219;
#define R4SdkUpdateNativeValue219_TYPE 219u
/* error{BadJson,BadSchema,DuplicateField,DuplicateRelease,InvalidValue,LimitExceeded,NoEligibleRelease,UnknownField}!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue220 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue220;
#define R4SdkUpdateNativeValue220_TYPE 220u
/* error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue221 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue221;
#define R4SdkUpdateNativeValue221_TYPE 221u
/* *storage_tools.io.Region; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue222 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue222;
#define R4SdkUpdateNativeValue222_TYPE 222u
/* error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}!storage_tools.io.Device; native size 80, alignment 8. */
typedef struct R4SdkUpdateNativeValue223 { _Alignas(8) uint8_t opaque_bytes[80]; } R4SdkUpdateNativeValue223;
#define R4SdkUpdateNativeValue223_TYPE 223u
/* *storage_tools.io.Memory; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue224 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue224;
#define R4SdkUpdateNativeValue224_TYPE 224u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.byte_source.Source.read)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue225 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue225;
#define R4SdkUpdateNativeValue225_TYPE 225u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.byte_source.Source.range)).@"fn".return_type.?).error_union.error_set!storage_tools.byte_source.Source; native size 40, alignment 8. */
typedef struct R4SdkUpdateNativeValue226 { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkUpdateNativeValue226;
#define R4SdkUpdateNativeValue226_TYPE 226u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.sparse_image.Image.init)).@"fn".return_type.?).error_union.error_set!*storage_tools.sparse_image.Image; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue227 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue227;
#define R4SdkUpdateNativeValue227_TYPE 227u
/* *storage_tools.sparse_image.Image; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue228 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue228;
#define R4SdkUpdateNativeValue228_TYPE 228u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.sparse_image.Image.append)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue229 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue229;
#define R4SdkUpdateNativeValue229_TYPE 229u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.sparse_image.Image.finish)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue230 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue230;
#define R4SdkUpdateNativeValue230_TYPE 230u
/* *const storage_tools.sparse_image.Image; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue231 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue231;
#define R4SdkUpdateNativeValue231_TYPE 231u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.read)).@"fn".return_type.?).error_union.error_set!storage_tools.partition.Plan; native size 20104, alignment 8. */
typedef struct R4SdkUpdateNativeValue232 { _Alignas(8) uint8_t opaque_bytes[20104]; } R4SdkUpdateNativeValue232;
#define R4SdkUpdateNativeValue232_TYPE 232u
/* *storage_tools.partition.Plan; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue233 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue233;
#define R4SdkUpdateNativeValue233_TYPE 233u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.initializeGpt)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue234 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue234;
#define R4SdkUpdateNativeValue234_TYPE 234u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.initializeMbr)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue235 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue235;
#define R4SdkUpdateNativeValue235_TYPE 235u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.convertEmpty)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue236 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue236;
#define R4SdkUpdateNativeValue236_TYPE 236u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.validate)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue237 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue237;
#define R4SdkUpdateNativeValue237_TYPE 237u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.add)).@"fn".return_type.?).error_union.error_set!u32; native size 8, alignment 4. */
typedef struct R4SdkUpdateNativeValue238 { _Alignas(4) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue238;
#define R4SdkUpdateNativeValue238_TYPE 238u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.remove)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue239 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue239;
#define R4SdkUpdateNativeValue239_TYPE 239u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.get)).@"fn".return_type.?).error_union.error_set!*storage_tools.partition.Entry; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue240 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue240;
#define R4SdkUpdateNativeValue240_TYPE 240u
/* *storage_tools.partition.Entry; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue241 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue241;
#define R4SdkUpdateNativeValue241_TYPE 241u
/* []storage_tools.partition.Range; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue242 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue242;
#define R4SdkUpdateNativeValue242_TYPE 242u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.freeRanges)).@"fn".return_type.?).error_union.error_set!usize; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue243 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue243;
#define R4SdkUpdateNativeValue243_TYPE 243u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.firstFit)).@"fn".return_type.?).error_union.error_set!u64; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue244 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue244;
#define R4SdkUpdateNativeValue244_TYPE 244u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.extend)).@"fn".return_type.?).error_union.error_set!u64; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue245 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue245;
#define R4SdkUpdateNativeValue245_TYPE 245u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.shrink)).@"fn".return_type.?).error_union.error_set!u64; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue246 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue246;
#define R4SdkUpdateNativeValue246_TYPE 246u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.revalidate)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue247 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue247;
#define R4SdkUpdateNativeValue247_TYPE 247u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.commit)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue248 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue248;
#define R4SdkUpdateNativeValue248_TYPE 248u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32.Geometry.init)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32.Geometry; native size 28, alignment 4. */
typedef struct R4SdkUpdateNativeValue249 { _Alignas(4) uint8_t opaque_bytes[28]; } R4SdkUpdateNativeValue249;
#define R4SdkUpdateNativeValue249_TYPE 249u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32.Plan.prepare)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32.Plan; native size 44, alignment 4. */
typedef struct R4SdkUpdateNativeValue250 { _Alignas(4) uint8_t opaque_bytes[44]; } R4SdkUpdateNativeValue250;
#define R4SdkUpdateNativeValue250_TYPE 250u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32.Plan.execute)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue251 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue251;
#define R4SdkUpdateNativeValue251_TYPE 251u
/* *storage_tools.fat32_image.Streamed; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue252 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue252;
#define R4SdkUpdateNativeValue252_TYPE 252u
/* *const storage_tools.fat32_image.Streamed; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue253 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue253;
#define R4SdkUpdateNativeValue253_TYPE 253u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_image.Streamed.execute)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue254 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue254;
#define R4SdkUpdateNativeValue254_TYPE 254u
/* *storage_tools.fat32_image.Prepared; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue255 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue255;
#define R4SdkUpdateNativeValue255_TYPE 255u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_image.Prepared.execute)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue256 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue256;
#define R4SdkUpdateNativeValue256_TYPE 256u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_view.View.init)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_view.View; native size 64, alignment 8. */
typedef struct R4SdkUpdateNativeValue257 { _Alignas(8) uint8_t opaque_bytes[64]; } R4SdkUpdateNativeValue257;
#define R4SdkUpdateNativeValue257_TYPE 257u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_view.View.initSource)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_view.View; native size 64, alignment 8. */
typedef struct R4SdkUpdateNativeValue258 { _Alignas(8) uint8_t opaque_bytes[64]; } R4SdkUpdateNativeValue258;
#define R4SdkUpdateNativeValue258_TYPE 258u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_view.View.readFile)).@"fn".return_type.?).error_union.error_set![]u8; native size 24, alignment 8. */
typedef struct R4SdkUpdateNativeValue259 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateNativeValue259;
#define R4SdkUpdateNativeValue259_TYPE 259u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_view.View.matches)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue260 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue260;
#define R4SdkUpdateNativeValue260_TYPE 260u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.Backing.init)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_update.Backing; native size 136, alignment 8. */
typedef struct R4SdkUpdateNativeValue261 { _Alignas(8) uint8_t opaque_bytes[136]; } R4SdkUpdateNativeValue261;
#define R4SdkUpdateNativeValue261_TYPE 261u
/* *const storage_tools.fat32_update.Backing; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue262 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue262;
#define R4SdkUpdateNativeValue262_TYPE 262u
/* *storage_tools.fat32_update.Prepared; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue263 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue263;
#define R4SdkUpdateNativeValue263_TYPE 263u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.Prepared.checkSource)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue264 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue264;
#define R4SdkUpdateNativeValue264_TYPE 264u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.Prepared.execute)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue265 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue265;
#define R4SdkUpdateNativeValue265_TYPE 265u
/* *ntfs_format.BootSector; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue266 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue266;
#define R4SdkUpdateNativeValue266_TYPE 266u
/* ntfs_format.BootSector.ParseError; native size 1, alignment 1. */
typedef struct R4SdkUpdateNtfsFormatBootSector_ParseError { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateNtfsFormatBootSector_ParseError;
#define R4SdkUpdateNtfsFormatBootSector_ParseError_TYPE 267u
/* ?ntfs_format.FileRecordHeader; native size 64, alignment 8. */
typedef struct R4SdkUpdateNativeValue268 { _Alignas(8) uint8_t opaque_bytes[64]; } R4SdkUpdateNativeValue268;
#define R4SdkUpdateNativeValue268_TYPE 268u
/* *ntfs_format.AttributeIterator; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue269 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue269;
#define R4SdkUpdateNativeValue269_TYPE 269u
/* *ntfs_format.RunlistIterator; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue270 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue270;
#define R4SdkUpdateNativeValue270_TYPE 270u
/* ?ntfs_format.Run; native size 32, alignment 8. */
typedef struct R4SdkUpdateNativeValue271 { _Alignas(8) uint8_t opaque_bytes[32]; } R4SdkUpdateNativeValue271;
#define R4SdkUpdateNativeValue271_TYPE 271u
/* ?ntfs_format.StandardInformation; native size 48, alignment 8. */
typedef struct R4SdkUpdateNativeValue272 { _Alignas(8) uint8_t opaque_bytes[48]; } R4SdkUpdateNativeValue272;
#define R4SdkUpdateNativeValue272_TYPE 272u
/* ?ntfs_format.FileName; native size 96, alignment 8. */
typedef struct R4SdkUpdateNativeValue273 { _Alignas(8) uint8_t opaque_bytes[96]; } R4SdkUpdateNativeValue273;
#define R4SdkUpdateNativeValue273_TYPE 273u
/* *ntfs_format.AttributeListIterator; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue274 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue274;
#define R4SdkUpdateNativeValue274_TYPE 274u
/* ?ntfs_format.AttributeListEntry; native size 56, alignment 8. */
typedef struct R4SdkUpdateNativeValue275 { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkUpdateNativeValue275;
#define R4SdkUpdateNativeValue275_TYPE 275u
/* ?ntfs_format.IndexRoot; native size 56, alignment 8. */
typedef struct R4SdkUpdateNativeValue276 { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkUpdateNativeValue276;
#define R4SdkUpdateNativeValue276_TYPE 276u
/* ?ntfs_format.IndexHeader; native size 20, alignment 4. */
typedef struct R4SdkUpdateNativeValue277 { _Alignas(4) uint8_t opaque_bytes[20]; } R4SdkUpdateNativeValue277;
#define R4SdkUpdateNativeValue277_TYPE 277u
/* ?ntfs_format.IndexBlock; native size 40, alignment 8. */
typedef struct R4SdkUpdateNativeValue278 { _Alignas(8) uint8_t opaque_bytes[40]; } R4SdkUpdateNativeValue278;
#define R4SdkUpdateNativeValue278_TYPE 278u
/* *ntfs_format.IndexEntryIterator; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue279 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue279;
#define R4SdkUpdateNativeValue279_TYPE 279u
/* ?ntfs_format.IndexEntry; native size 56, alignment 8. */
typedef struct R4SdkUpdateNativeValue280 { _Alignas(8) uint8_t opaque_bytes[56]; } R4SdkUpdateNativeValue280;
#define R4SdkUpdateNativeValue280_TYPE 280u
/* ?math.Order; native size 2, alignment 1. */
typedef struct R4SdkUpdateNativeValue281 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue281;
#define R4SdkUpdateNativeValue281_TYPE 281u
/* math.CompareOperator; native size 1, alignment 1. */
typedef struct R4SdkUpdateNative_math_CompareOperator { _Alignas(1) uint8_t opaque_bytes[1]; } R4SdkUpdateNative_math_CompareOperator;
#define R4SdkUpdateNative_math_CompareOperator_TYPE 282u
/* ?ntfs_format.VolumeInformation; native size 6, alignment 2. */
typedef struct R4SdkUpdateNativeValue283 { _Alignas(2) uint8_t opaque_bytes[6]; } R4SdkUpdateNativeValue283;
#define R4SdkUpdateNativeValue283_TYPE 283u
/* *storage_tools.ntfs_plan.Plan; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue284 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue284;
#define R4SdkUpdateNativeValue284_TYPE 284u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_plan.Plan.addBorrowed)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue285 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue285;
#define R4SdkUpdateNativeValue285_TYPE 285u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_plan.Plan.addOwned)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue286 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue286;
#define R4SdkUpdateNativeValue286_TYPE 286u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_plan.Plan.addCopy)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue287 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue287;
#define R4SdkUpdateNativeValue287_TYPE 287u
/* *const storage_tools.ntfs_plan.Plan; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue288 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue288;
#define R4SdkUpdateNativeValue288_TYPE 288u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_plan.Plan.validate)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue289 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue289;
#define R4SdkUpdateNativeValue289_TYPE 289u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_plan.Plan.execute)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue290 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue290;
#define R4SdkUpdateNativeValue290_TYPE 290u
/* @typeInfo(@typeInfo(@TypeOf(ntfs_builder.WithFormat(ntfs_format).Builder.init)).@"fn".return_type.?).error_union.error_set!ntfs_builder.WithFormat(ntfs_format).Builder; native size 392, alignment 8. */
typedef struct R4SdkUpdateNativeValue291 { _Alignas(8) uint8_t opaque_bytes[392]; } R4SdkUpdateNativeValue291;
#define R4SdkUpdateNativeValue291_TYPE 291u
/* *ntfs_builder.WithFormat(ntfs_format).Builder; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue292 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue292;
#define R4SdkUpdateNativeValue292_TYPE 292u
/* @typeInfo(@typeInfo(@TypeOf(ntfs_builder.WithFormat(ntfs_format).Builder.addDirectory)).@"fn".return_type.?).error_union.error_set!u32; native size 8, alignment 4. */
typedef struct R4SdkUpdateNativeValue293 { _Alignas(4) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue293;
#define R4SdkUpdateNativeValue293_TYPE 293u
/* @typeInfo(@typeInfo(@TypeOf(ntfs_builder.WithFormat(ntfs_format).Builder.ensureDirectory)).@"fn".return_type.?).error_union.error_set!u32; native size 8, alignment 4. */
typedef struct R4SdkUpdateNativeValue294 { _Alignas(4) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue294;
#define R4SdkUpdateNativeValue294_TYPE 294u
/* @typeInfo(@typeInfo(@TypeOf(ntfs_builder.WithFormat(ntfs_format).Builder.addFile)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue295 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue295;
#define R4SdkUpdateNativeValue295_TYPE 295u
/* @typeInfo(@typeInfo(@TypeOf(ntfs_builder.WithFormat(ntfs_format).Builder.finalize)).@"fn".return_type.?).error_union.error_set![]u8; native size 24, alignment 8. */
typedef struct R4SdkUpdateNativeValue296 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateNativeValue296;
#define R4SdkUpdateNativeValue296_TYPE 296u
/* @typeInfo(@typeInfo(@TypeOf(ntfs_builder.WithFormat(ntfs_format).Builder.prepare)).@"fn".return_type.?).error_union.error_set!storage_tools.ntfs_plan.Plan; native size 624, alignment 8. */
typedef struct R4SdkUpdateNativeValue297 { _Alignas(8) uint8_t opaque_bytes[624]; } R4SdkUpdateNativeValue297;
#define R4SdkUpdateNativeValue297_TYPE 297u
/* *storage_tools.ntfs_resize.Plan; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue298 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue298;
#define R4SdkUpdateNativeValue298_TYPE 298u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_resize.Plan.prepare)).@"fn".return_type.?).error_union.error_set!*storage_tools.ntfs_resize.Plan; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue299 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue299;
#define R4SdkUpdateNativeValue299_TYPE 299u
/* *const storage_tools.ntfs_resize.Plan; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue300 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue300;
#define R4SdkUpdateNativeValue300_TYPE 300u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_resize.Plan.execute)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue301 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue301;
#define R4SdkUpdateNativeValue301_TYPE 301u
/* [7][16]u8; native size 112, alignment 1. */
typedef struct R4SdkUpdateNativeValue302 { _Alignas(1) uint8_t opaque_bytes[112]; } R4SdkUpdateNativeValue302;
#define R4SdkUpdateNativeValue302_TYPE 302u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Identifiers.fromEntropy)).@"fn".return_type.?).error_union.error_set!storage_tools.installation.Identifiers; native size 114, alignment 2. */
typedef struct R4SdkUpdateNativeValue303 { _Alignas(2) uint8_t opaque_bytes[114]; } R4SdkUpdateNativeValue303;
#define R4SdkUpdateNativeValue303_TYPE 303u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Identifiers.validate)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue304 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue304;
#define R4SdkUpdateNativeValue304_TYPE 304u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Layout.prepare)).@"fn".return_type.?).error_union.error_set!storage_tools.installation.Layout; native size 208, alignment 8. */
typedef struct R4SdkUpdateNativeValue305 { _Alignas(8) uint8_t opaque_bytes[208]; } R4SdkUpdateNativeValue305;
#define R4SdkUpdateNativeValue305_TYPE 305u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Layout.prepareSource)).@"fn".return_type.?).error_union.error_set!storage_tools.installation.Layout; native size 208, alignment 8. */
typedef struct R4SdkUpdateNativeValue306 { _Alignas(8) uint8_t opaque_bytes[208]; } R4SdkUpdateNativeValue306;
#define R4SdkUpdateNativeValue306_TYPE 306u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Layout.bind)).@"fn".return_type.?).error_union.error_set!void; native size 2, alignment 2. */
typedef struct R4SdkUpdateNativeValue307 { _Alignas(2) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue307;
#define R4SdkUpdateNativeValue307_TYPE 307u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Layout.manifest)).@"fn".return_type.?).error_union.error_set![]u8; native size 24, alignment 8. */
typedef struct R4SdkUpdateNativeValue308 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateNativeValue308;
#define R4SdkUpdateNativeValue308_TYPE 308u
/* @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Layout.limineConfig)).@"fn".return_type.?).error_union.error_set![]u8; native size 24, alignment 8. */
typedef struct R4SdkUpdateNativeValue309 { _Alignas(8) uint8_t opaque_bytes[24]; } R4SdkUpdateNativeValue309;
#define R4SdkUpdateNativeValue309_TYPE 309u
/* *system_update_inventory.Inventory; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue310 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue310;
#define R4SdkUpdateNativeValue310_TYPE 310u
/* *const system_update_recovery.JournalPayload; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue311 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue311;
#define R4SdkUpdateNativeValue311_TYPE 311u
/* [*:0]const u8; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue312 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue312;
#define R4SdkUpdateNativeValue312_TYPE 312u
/* ?system_update_recovery.JournalComponentKind; native size 2, alignment 1. */
typedef struct R4SdkUpdateNativeValue313 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue313;
#define R4SdkUpdateNativeValue313_TYPE 313u
/* *const system_update_recovery.JournalComponent; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue314 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue314;
#define R4SdkUpdateNativeValue314_TYPE 314u
/* ?system_update_batch.Phase; native size 2, alignment 1. */
typedef struct R4SdkUpdateNativeValue315 { _Alignas(1) uint8_t opaque_bytes[2]; } R4SdkUpdateNativeValue315;
#define R4SdkUpdateNativeValue315_TYPE 315u
/* *const system_update_batch.PackageEntry; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue316 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue316;
#define R4SdkUpdateNativeValue316_TYPE 316u
/* []const update_catalog.Component; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue317 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue317;
#define R4SdkUpdateNativeValue317_TYPE 317u
/* []const update_catalog.Requirement; native size 16, alignment 8. */
typedef struct R4SdkUpdateNativeValue318 { _Alignas(8) uint8_t opaque_bytes[16]; } R4SdkUpdateNativeValue318;
#define R4SdkUpdateNativeValue318_TYPE 318u
/* *const update_catalog.Plan; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue319 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue319;
#define R4SdkUpdateNativeValue319_TYPE 319u
/* *update_helper_adapters.Replay; native size 8, alignment 8. */
typedef struct R4SdkUpdateNativeValue320 { _Alignas(8) uint8_t opaque_bytes[8]; } R4SdkUpdateNativeValue320;
#define R4SdkUpdateNativeValue320_TYPE 320u
#define R4SdkUpdate_ABI_FINGERPRINT UINT64_C(4924212398762475126)
int32_t R4SdkUpdateVerifyAbi(uint64_t);
#define R4SdkUpdateBlock_sector_size (512)
#define R4SdkUpdateBlock_max_transfer_bytes (131072)
#define R4SdkUpdateBlock_scratch_bytes (65536)
#define R4SdkUpdateStoragesparse_image_block_bytes (65536)
#define R4SdkUpdateStoragesparse_image_maximum_bytes (23622320128)
#define R4SdkUpdatePartition_max_entries (128)
#define R4SdkUpdatePartition_alignment_sectors (2048)
#define R4SdkUpdatePartition_max_array_bytes (16384)
static const uint8_t R4SdkUpdatePartition_CONST_esp_type[] = {40,115,42,193,31,248,210,17,186,75,0,160,201,62,201,59,0};
static inline R4SdkUpdateSlot R4SdkUpdatePartition_constant_esp_type(void) { return (R4SdkUpdateSlot){.ptr=(void *)R4SdkUpdatePartition_CONST_esp_type,.length=16,.flags=1u}; }
static const uint8_t R4SdkUpdatePartition_CONST_basic_type[] = {162,160,208,235,229,185,51,68,135,192,104,182,183,38,153,199,0};
static inline R4SdkUpdateSlot R4SdkUpdatePartition_constant_basic_type(void) { return (R4SdkUpdateSlot){.ptr=(void *)R4SdkUpdatePartition_CONST_basic_type,.length=16,.flags=1u}; }
static const uint8_t R4SdkUpdatePartition_CONST_bios_type[] = {72,97,104,33,73,100,111,110,116,78,101,101,100,69,70,73,0};
static inline R4SdkUpdateSlot R4SdkUpdatePartition_constant_bios_type(void) { return (R4SdkUpdateSlot){.ptr=(void *)R4SdkUpdatePartition_CONST_bios_type,.length=16,.flags=1u}; }
static const uint8_t R4SdkUpdateStorageguid_CONST_zero[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
static inline R4SdkUpdateSlot R4SdkUpdateStorageguid_constant_zero(void) { return (R4SdkUpdateSlot){.ptr=(void *)R4SdkUpdateStorageguid_CONST_zero,.length=16,.flags=1u}; }
#define R4SdkUpdateFat32_reserved_sectors (32)
#define R4SdkUpdateFat32_fat_count (2)
#define R4SdkUpdateFat32_root_cluster (2)
#define R4SdkUpdateFat32_last_data_cluster (268435446)
#define R4SdkUpdateNtfsFormat_SECTOR_SIZE (512)
#define R4SdkUpdateNtfsFormat_FILE_MAGIC (1162627398)
#define R4SdkUpdateNtfsFormat_INDX_MAGIC (1480871497)
#define R4SdkUpdateNtfsFormat_BAAD_MAGIC (1145127234)
#define R4SdkUpdateNtfsFormat_END_MARKER (4294967295)
#define R4SdkUpdateNtfsFormat_UPCASE_ENTRIES (65536)
#define R4SdkUpdateNtfsFormat_UPCASE_BYTES (131072)
#define R4SdkUpdateNtfsFormat_R4OS_PATH_SEGMENTS_MAX (24)
#define R4SdkUpdateNtfsFormat_MFT_RECORD_MFT (0)
#define R4SdkUpdateNtfsFormat_MFT_RECORD_MFTMIRR (1)
#define R4SdkUpdateNtfsFormat_MFT_RECORD_LOGFILE (2)
#define R4SdkUpdateNtfsFormat_MFT_RECORD_VOLUME (3)
#define R4SdkUpdateNtfsFormat_MFT_RECORD_ATTRDEF (4)
#define R4SdkUpdateNtfsFormat_MFT_RECORD_ROOT (5)
#define R4SdkUpdateNtfsFormat_MFT_RECORD_BITMAP (6)
#define R4SdkUpdateNtfsFormat_MFT_RECORD_BOOT (7)
#define R4SdkUpdateNtfsFormat_MFT_RECORD_BADCLUS (8)
#define R4SdkUpdateNtfsFormat_MFT_RECORD_SECURE (9)
#define R4SdkUpdateNtfsFormat_MFT_RECORD_UPCASE (10)
#define R4SdkUpdateNtfsFormat_MFT_RECORD_EXTEND (11)
#define R4SdkUpdateNtfsFormat_MFT_FIRST_NORMAL (16)
#define R4SdkUpdateNtfsFormat_ATTR_FLAG_COMPRESSED (1)
#define R4SdkUpdateNtfsFormat_ATTR_FLAG_ENCRYPTED (16384)
#define R4SdkUpdateNtfsFormat_ATTR_FLAG_SPARSE (32768)
#define R4SdkUpdateNtfsFormat_RECORD_IN_USE (1)
#define R4SdkUpdateNtfsFormat_RECORD_IS_DIRECTORY (2)
#define R4SdkUpdateNtfsFormat_NAMESPACE_POSIX (0)
#define R4SdkUpdateNtfsFormat_NAMESPACE_WIN32 (1)
#define R4SdkUpdateNtfsFormat_NAMESPACE_DOS (2)
#define R4SdkUpdateNtfsFormat_NAMESPACE_WIN32_DOS (3)
#define R4SdkUpdateNtfsFormat_FILE_ATTR_READ_ONLY (1)
#define R4SdkUpdateNtfsFormat_FILE_ATTR_HIDDEN (2)
#define R4SdkUpdateNtfsFormat_FILE_ATTR_SYSTEM (4)
#define R4SdkUpdateNtfsFormat_FILE_ATTR_ARCHIVE (32)
#define R4SdkUpdateNtfsFormat_FILE_ATTR_SPARSE (512)
#define R4SdkUpdateNtfsFormat_FILE_ATTR_REPARSE (1024)
#define R4SdkUpdateNtfsFormat_FILE_ATTR_COMPRESSED (2048)
#define R4SdkUpdateNtfsFormat_FILE_ATTR_ENCRYPTED (16384)
#define R4SdkUpdateNtfsFormat_FILE_ATTR_DIRECTORY_DUP (268435456)
#define R4SdkUpdateNtfsFormat_INDEX_ENTRY_NODE (1)
#define R4SdkUpdateNtfsFormat_INDEX_ENTRY_END (2)
#define R4SdkUpdateNtfsFormat_VOLUME_FLAG_DIRTY (1)
static const uint8_t R4SdkUpdateNtfsFormat_CONST_I30_NAME_UTF16[] = {36,0,73,0,51,0,48,0,0};
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_constant_I30_NAME_UTF16(void) { return (R4SdkUpdateSlot){.ptr=(void *)R4SdkUpdateNtfsFormat_CONST_I30_NAME_UTF16,.length=8,.flags=1u}; }
#define R4SdkUpdateNtfsFormat_COLLATION_FILE_NAME (1)
#define R4SdkUpdateNative_ntfs_builder_WithFormat_ntfs_format__max_path_segments (24)
#define R4SdkUpdateStorageinstallation_system_mb (16384)
#define R4SdkUpdateStorageinstallation_recovery_mb (5120)
#define R4SdkUpdateStorageinstallation_standard_bytes (23622320128)
#define R4SdkUpdateStorageinstallation_previous_bytes (17179869184)
#define R4SdkUpdateStorageinstallation_legacy_bytes (2147483648)
#define R4SdkUpdateStorageinstallation_minimum_data_sectors (32769)
#define R4SdkUpdateStorageinstallation_minimum_sectors (44339234)
static const uint8_t R4SdkUpdateStoragelimine_CONST_payload[] = {235,60,144,76,73,77,73,78,69,32,32,0,2,0,0,0,0,0,0,0,0,0,0,0,18,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,76,73,77,73,78,69,32,32,32,32,32,0,0,0,0,0,0,0,0,250,252,234,69,124,0,0,49,246,142,222,142,198,142,214,188,0,124,251,128,250,128,15,130,26,1,128,250,143,15,135,18,1,180,65,187,170,85,205,19,15,130,6,1,129,251,85,170,15,133,253,0,104,0,112,7,191,164,125,102,139,5,102,139,109,4,49,219,102,185,0,126,0,0,232,85,0,15,130,223,0,15,1,22,88,125,250,102,106,0,102,189,16,0,0,0,15,32,192,15,186,232,0,15,34,192,234,131,125,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,96,190,0,128,102,199,4,16,0,1,0,137,92,4,140,68,6,82,86,102,80,102,85,180,72,190,16,128,199,4,30,0,205,19,114,78,102,15,183,108,24,145,102,193,233,16,137,202,49,201,247,245,133,210,15,149,193,1,193,102,90,102,88,94,102,80,102,146,102,49,210,102,247,245,102,147,102,88,102,247,245,102,137,68,8,102,137,92,12,90,180,66,248,205,19,114,21,1,108,4,102,131,68,8,1,102,131,84,12,0,226,234,235,4,131,196,12,249,97,195,23,0,86,125,0,0,255,255,0,0,0,155,207,0,255,255,0,0,0,147,207,0,70,70,70,70,129,198,48,79,104,0,184,7,38,137,54,0,0,251,244,235,253,142,221,142,197,142,229,142,237,142,213,129,226,255,0,0,0,82,104,45,84,0,0,104,240,0,7,0,232,93,130,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,85,170,252,139,92,36,4,139,43,141,83,4,3,92,36,8,191,0,240,0,0,15,182,10,141,114,1,137,200,193,233,3,131,225,15,131,249,15,117,10,15,182,74,1,141,114,2,131,193,15,243,164,57,222,115,53,132,192,121,8,141,86,2,15,183,54,235,6,141,86,1,15,182,54,36,7,60,7,116,5,15,182,192,235,7,15,182,2,66,131,192,7,137,249,41,241,137,206,141,72,4,243,164,57,218,115,2,235,168,186,0,240,0,0,137,214,49,192,72,57,250,116,34,141,74,1,15,182,18,49,208,106,8,90,137,195,131,224,1,209,235,247,216,37,32,131,184,237,49,216,74,117,237,137,202,235,218,247,208,57,232,117,18,15,182,68,36,12,139,76,36,16,137,244,49,237,81,80,85,86,195,186,212,0,7,0,184,0,128,11,0,15,182,10,131,192,2,66,128,205,79,102,137,72,254,61,44,128,11,0,117,235,250,244,108,105,109,105,110,101,32,105,110,116,101,103,114,105,116,121,32,101,114,114,111,114,144,144,144,144,144,144,192,166,247,61,120,0,252,48,192,191,8,65,5,0,185,136,220,5,0,129,233,11,124,22,243,170,15,1,21,171,240,0,0,234,35,240,0,0,24,0,184,32,0,0,0,142,216,142,192,142,224,142,232,142,208,233,237,12,0,0,204,1,120,20,85,137,229,86,131,236,6,137,214,102,199,69,246,255,3,199,69,248,0,0,0,0,141,69,246,137,202,250,252,188,0,124,0,0,191,5,126,5,185,0,2,0,0,243,164,15,1,24,106,8,104,121,240,0,0,203,184,16,84,126,6,208,15,32,192,36,254,15,34,192,102,184,152,240,0,0,106,0,80,203,49,192,30,104,251,106,0,104,0,124,203,71,0,64,95,1,0,95,42,255,0,108,219,5,132,32,15,1,29,250,171,55,206,240,0,0,8,0,85,5,103,15,186,240,0,15,34,192,234,234,240,0,0,82,2,40,244,235,253,255,3,170,122,0,138,68,36,4,162,131,241,0,0,139,68,36,8,163,244,9,81,12,163,248,241,0,0,15,1,5,252,7,24,13,4,242,14,96,29,12,242,0,0,83,86,87,85,234,59,241,109,7,194,10,25,234,85,241,107,120,20,208,54,102,137,38,240,241,54,102,139,38,248,241,15,169,15,161,7,31,102,157,102,93,102,95,102,94,102,90,102,89,102,91,102,88,28,54,240,241,251,205,0,250,44,120,15,244,241,103,102,141,100,36,40,102,80,102,83,102,81,102,82,102,86,102,87,102,85,102,156,30,6,15,160,15,168,50,0,40,33,15,1,22,252,7,64,30,4,242,15,32,192,12,1,121,190,206,241,24,0,102,184,32,1,1,63,208,93,95,94,91,195,144,1,3,15,0,1,16,128,18,1,6,21,248,0,156,46,102,255,6,18,242,157,46,255,46,22,242,139,21,5,2,64,137,21,22,242,0,0,199,5,12,96,26,242,0,0,139,84,36,4,199,5,18,242,68,129,48,1,145,56,243,48,1,9,64,7,155,29,72,243,48,1,151,107,242,48,1,15,151,133,242,155,1,4,64,198,6,78,243,0,198,6,82,5,208,86,243,0,102,57,22,18,242,116,46,13,1,176,180,1,48,192,205,22,63,1,120,7,116,233,49,192,205,22,162,82,243,136,38,86,243,184,0,2,205,22,168,4,116,10,58,185,4,128,6,82,243,96,250,36,1,145,56,243,36,1,248,15,64,243,15,32,195,128,203,1,15,34,195,234,243,242,24,0,102,187,32,0,142,219,142,195,142,227,142,235,142,211,37,1,9,139,216,9,137,228,121,3,128,61,86,243,0,0,0,116,27,255,53,78,243,0,0,255,53,82,6,0,21,231,232,207,73,1,0,131,196,12,195,49,192,195,60,1,13,4,6,132,35,3,249,0,139,68,36,4,163,0,244,0,0,195,15,1,5,4,244,79,2,9,12,7,154,29,20,244,79,2,191,141,108,36,20,234,142,243,83,2,15,146,168,243,83,2,132,219,2,120,4,251,255,118,4,255,118,8,255,118,0,255,30,0,244,131,196,6,250,46,239,16,4,244,7,30,30,12,244,239,23,226,243,239,5,174,37,255,255,0,0,25,2,143,144,8,2,15,248,3,85,137,229,83,87,86,131,236,12,139,117,20,15,189,69,16,185,63,228,1,121,31,68,193,131,240,31,131,192,32,15,189,214,131,242,31,133,246,15,68,208,137,208,139,85,8,137,211,15,189,210,15,68,209,131,242,31,131,194,32,139,117,12,15,189,206,131,241,33,241,202,137,194,137,77,236,41,202,49,201,131,250,63,191,42,2,216,135,158,0,0,0,117,7,137,217,233,147,87,2,249,7,209,254,193,137,223,15,173,247,137,85,240,137,242,211,234,246,193,32,15,69,250,185,84,2,248,8,69,209,177,63,42,77,240,15,165,222,211,227,246,193,32,137,217,15,69,243,199,69,240,187,3,10,187,33,120,63,203,247,208,3,69,236,137,69,232,49,219,15,164,250,1,15,164,247,1,15,164,206,1,11,117,240,141,12,75,137,77,236,137,209,247,209,137,251,247,211,139,69,16,1,195,139,69,20,17,193,137,203,193,235,31,193,249,31,137,200,35,69,20,35,77,16,41,207,139,77,236,25,194,255,69,232,117,189,59,0,56,236,247,137,200,137,250,131,196,12,94,95,91,93,195,11,1,202,16,139,85,20,15,189,77,16,184,11,1,124,7,200,131,241,31,131,193,32,15,189,218,131,243,31,133,210,15,68,217,15,189,77,8,24,130,5,1,153,254,131,247,5,1,248,3,249,137,217,41,249,131,249,63,118,10,139,69,8,137,242,233,166,0,39,4,161,131,249,63,186,59,3,144,132,150,95,3,254,1,93,240,137,203,254,193,137,125,232,139,125,8,137,248,15,173,14,1,142,194,14,1,254,4,40,217,15,165,254,211,231,246,193,32,139,77,240,15,69,247,199,69,228,14,1,250,11,69,251,137,125,236,247,209,3,77,232,49,219,137,77,240,15,164,194,1,15,164,240,1,139,77,236,20,1,142,228,20,1,245,137,195,247,211,139,125,16,1,251,139,125,20,17,249,20,1,153,207,35,125,20,1,231,200,139,77,240,25,250,65,117,185,131,196,16,5,1,2,248,16,56,139,125,24,139,69,8,139,64,20,15,175,199,61,1,128,0,0,15,131,184,0,0,0,139,85,20,139,93,16,161,77,6,160,133,192,117,24,180,5,120,1,128,0,0,137,214,232,248,58,0,0,137,242,131,196,8,163,28,248,31,141,117,228,102,199,6,16,0,102,137,126,2,137,193,193,233,4,102,137,78,6,131,224,15,102,137,70,4,137,94,8,137,86,12,141,93,188,106,36,106,0,83,232,133,84,0,111,3,56,199,67,36,0,66,0,0,116,120,46,0,137,67,24,137,240,131,224,12,137,67,20,193,238,4,102,137,115,6,83,83,106,19,232,54,250,255,255,131,196,12,190,2,0,0,0,246,67,8,1,117,32,139,69,12,49,246,133,192,116,23,139,77,8,15,175,121,20,87,255,53,154,26,80,232,27,85,169,137,240,131,196,56,221,1,212,104,137,87,1,0,106,0,232,255,36,244,2,120,35,129,236,0,1,0,0,184,117,4,0,0,138,0,141,141,30,255,255,255,137,207,193,239,4,131,225,14,137,77,164,141,77,204,137,202,131,226,12,137,85,176,193,233,4,137,77,172,141,141,60,34,2,20,9,156,20,224,160,15,182,192,137,69,192,49,192,64,187,128,56,5,192,69,196,137,69,200,199,69,224,88,3,40,137,254,137,125,168,225,82,141,189,246,254,255,255,87,232,158,83,231,184,133,26,255,255,255,0,72,8,2,120,5,220,137,157,14,255,255,255,102,137,181,252,254,255,255,139,69,164,137,133,10,16,16,199,133,141,73,30,0,87,87,106,19,232,65,249,245,248,8,246,133,254,254,255,255,1,15,133,58,5,0,0,15,183,133,32,255,255,255,131,224,4,92,1,184,2,137,77,240,199,69,236,157,5,25,102,131,189,59,129,53,3,104,114,108,15,183,141,58,255,255,255,15,183,149,56,188,248,0,206,102,9,214,116,87,15,183,210,137,206,33,214,129,254,36,4,249,25,116,72,102,133,192,15,149,69,232,193,225,4,141,52,17,15,182,76,17,3,193,225,8,129,249,0,160,0,0,15,148,193,139,69,240,15,182,192,186,1,132,3,249,50,194,10,77,232,137,117,236,117,17,15,183,70,10,168,32,117,7,192,232,6,36,1,235,2,176,1,137,69,240,83,106,112,232,27,66,0,0,131,196,8,137,198,139,69,220,137,6,137,94,16,137,94,52,137,94,48,199,70,28,255,255,255,255,139,61,54,2,155,255,117,22,54,2,26,232,196,56,48,137,199,52,2,249,3,199,69,204,16,0,1,0,137,248,193,232,4,102,137,69,210,137,248,49,2,250,6,69,208,137,93,216,137,93,212,106,36,83,141,157,100,255,255,255,83,232,82,82,51,2,145,69,136,51,2,32,6,137,133,124,96,41,69,176,137,133,120,9,232,172,102,137,133,106,255,255,255,106,40,83,141,133,184,1,26,80,232,9,52,249,9,139,69,216,137,69,152,139,69,212,137,69,148,139,69,204,139,77,208,137,77,144,137,69,140,199,2,56,49,192,80,87,232,245,81,197,137,12,114,2,147,196,247,125,1,145,108,255,125,1,40,173,3,0,0,187,42,2,204,115,128,124,31,255,0,117,5,75,117,246,49,219,106,40,106,25,141,133,100,113,19,152,81,113,16,140,139,98,121,1,204,137,77,208,139,69,148,137,69,212,139,69,152,137,69,216,113,66,104,255,0,0,0,87,232,130,115,3,58,47,80,106,19,232,75,121,4,47,52,3,0,0,184,121,1,248,16,7,255,255,117,15,72,117,246,137,94,20,133,219,117,13,233,19,3,0,0,57,195,15,71,195,137,70,20,139,133,46,111,1,144,157,50,177,2,249,2,193,131,193,1,137,218,131,210,0,131,249,2,131,218,0,185,255,198,2,249,41,114,43,139,86,20,141,138,255,1,0,0,133,210,15,73,202,137,202,193,250,9,137,85,228,193,249,31,15,175,200,247,101,228,1,202,15,175,93,228,1,211,137,194,137,217,137,86,56,137,78,60,139,77,236,133,201,142,5,248,18,139,85,240,116,8,176,1,246,65,10,64,117,13,129,126,20,0,8,0,0,15,182,194,15,69,195,136,70,12,129,125,220,159,40,4,35,77,224,117,15,28,121,40,117,6,198,70,12,1,235,14,132,210,116,6,132,192,117,6,235,34,132,192,116,11,139,77,196,137,200,65,137,77,196,235,28,139,69,192,57,193,117,8,137,69,224,233,75,2,0,0,65,137,77,224,139,77,200,30,196,200,137,70,8,133,255,117,20,51,2,164,145,54,0,0,101,4,249,11,49,210,49,201,65,49,192,72,137,69,240,137,69,236,137,117,232,139,60,149,144,77,1,0,139,70,181,4,128,210,1,241,15,135,14,1,0,0,137,85,180,137,77,228,102,199,161,1,128,149,4,169,189,62,255,255,255,197,4,131,157,4,144,141,66,80,3,128,111,2,208,133,64,255,255,255,49,219,137,157,72,62,1,144,157,68,64,3,193,49,137,69,184,247,218,137,85,178,4,144,141,181,166,1,167,86,232,205,79,133,2,2,164,69,232,139,0,136,2,140,156,136,2,139,160,136,2,191,86,86,106,19,232,119,245,212,1,1,32,117,90,1,189,93,16,131,149,105,250,47,0,1,251,131,251,64,114,159,15,49,139,117,184,247,222,139,93,188,131,219,0,1,198,17,211,139,77,240,57,206,137,216,139,85,236,25,208,15,66,211,137,85,236,15,66,206,137,77,240,139,77,228,15,66,207,139,85,180,66,131,250,9,150,1,249,13,117,232,15,133,250,254,255,255,235,30,15,182,69,137,139,117,232,255,54,80,104,221,79,1,0,232,241,45,14,5,144,185,8,143,6,241,219,137,78,4,137,240,131,192,68,86,80,232,150,35,177,3,248,21,132,192,116,4,198,70,64,1,161,144,113,5,0,141,12,133,4,0,0,0,193,224,2,83,81,83,80,255,53,140,113,5,0,232,205,61,62,3,16,20,163,13,17,139,13,39,32,81,1,137,21,48,152,137,52,136,252,3,147,31,62,204,3,178,83,86,80,232,201,37,209,2,127,0,72,3,131,249,2,114,120,49,219,67,131,248,255,116,63,96,4,44,49,210,82,81,82,98,15,107,98,16,249,0,60,136,255,70,28,235,13,106,0,106,112,87,232,198,60,160,3,0,13,16,232,170,151,4,117,10,84,117,128,242,2,72,3,67,131,249,1,119,139,137,254,51,26,86,232,147,51,200,139,117,168,139,93,220,67,129,251,89,8,192,15,133,94,250,255,255,129,196,5,6,135,255,7,2,251,20,20,232,108,74,0,0,132,192,15,132,199,0,0,0,232,161,75,0,0,15,49,137,198,139,13,92,195,5,0,139,29,88,195,5,0,155,8,161,137,216,9,200,234,8,248,3,116,115,81,83,82,137,117,232,86,137,77,240,137,85,228,232,167,246,169,6,120,2,16,137,198,137,209,186,64,66,15,0,247,226,137,69,236,105,193,11,120,19,1,208,137,69,224,137,247,15,175,125,240,137,240,247,227,1,250,15,175,203,1,209,139,85,232,41,194,139,69,228,25,200,105,200,38,19,137,208,56,83,1,202,255,117,240,83,82,80,232,84,83,137,215,6,9,120,1,240,19,125,224,232,60,76,0,0,232,73,57,0,0,232,239,10,144,38,249,123,2,248,1,12,169,253,255,255,255,117,25,15,182,69,8,80,232,205,43,224,1,250,22,4,235,25,104,96,79,1,0,233,182,0,0,0,131,248,1,117,17,232,224,67,0,0,232,198,67,0,0,163,24,65,5,0,235,5,161,24,209,7,192,10,104,180,81,1,0,233,141,7,12,121,33,125,236,128,120,13,0,116,9,137,193,232,132,0,0,0,235,59,137,198,139,64,24,133,192,117,247,131,126,28,255,124,44,49,219,75,49,255,15,182,70,12,87,255,118,8,80,232,33,108,208,12,133,192,116,12,137,193,232,82,0,68,1,122,10,117,7,67,71,59,94,28,126,217,128,61,28,65,5,0,0,117,13,104,138,83,1,0,232,96,152,24,128,61,21,22,248,1,139,117,240,139,125,236,116,22,232,21,19,2,0,137,61,132,85,2,144,53,128,21,2,185,116,252,0,0,104,242,80,186,7,148,69,29,186,7,80,137,207,138,29,29,65,5,0,198,5,6,209,1,104,57,85,1,0,81,232,229,13,204,2,101,133,192,117,58,104,10,81,1,0,87,232,211,18,32,40,104,149,84,18,13,193,18,25,22,104,52,18,12,175,18,152,15,132,134,252,12,19,198,136,91,0,176,248,29,1,139,64,28,139,78,32,186,4,81,4,0,49,194,9,202,117,71,141,21,144,111,0,0,41,208,131,217,0,191,144,95,1,0,81,80,106,0,82,87,86,232,88,14,98,2,33,24,86,232,1,9,252,1,4,106,20,104,68,17,5,0,104,136,89,1,0,232,223,75,26,1,121,1,27,104,86,85,1,0,235,5,104,32,81,1,0,232,90,42,44,145,49,192,128,2,24,198,5,21,206,34,176,1,235,240,132,248,1,235,230,85,137,229,131,236,52,139,85,8,141,77,204,232,16,155,13,236,193,49,192,133,201,117,3,139,69,212,131,196,52,179,10,248,8,129,236,88,2,0,0,137,207,137,17,49,192,141,141,156,253,255,255,49,246,70,80,104,141,15,57,80,80,81,82,232,246,28,157,128,211,2,252,6,69,2,0,0,141,133,210,253,255,255,106,3,104,59,83,1,0,80,232,154,23,184,1,39,56,141,133,238,26,1,13,128,26,32,30,141,133,159,26,32,5,104,197,80,26,12,102,26,192,15,133,243,1,0,0,138,141,118,2,120,17,15,182,209,184,248,255,255,255,58,136,64,88,1,0,116,9,64,15,132,214,1,0,0,235,239,137,85,240,15,183,157,167,35,17,183,211,35,32,102,59,152,56,36,56,11,131,192,2,15,132,176,38,249,2,236,138,173,172,253,255,255,136,232,4,251,60,252,15,130,156,1,231,8,184,170,253,255,255,137,69,224,159,1,10,138,18,9,173,18,121,10,204,193,224,5,137,69,216,141,68,2,255,137,85,232,153,247,125,232,137,69,192,15,183,133,175,30,66,228,133,192,117,9,139,133,188,13,97,15,183,133,178,253,255,255,133,192,139,149,192,61,232,236,137,85,212,15,68,194,15,182,213,137,85,208,156,3,248,23,200,137,85,196,15,183,69,224,137,69,220,49,192,139,85,192,3,85,220,15,146,192,3,85,200,19,69,196,59,85,228,131,216,0,15,131,11,1,157,10,251,9,228,41,208,49,210,247,117,240,61,244,15,0,0,119,21,199,71,4,12,0,0,0,176,1,18,4,65,139,85,224,235,48,61,244,255,10,55,119,18,199,71,4,16,31,1,168,235,20,199,71,4,87,15,129,50,9,129,133,8,120,5,236,49,192,102,137,95,12,136,79,14,102,137,87,16,136,111,18,139,141,184,226,224,79,20,139,77,236,137,79,24,133,201,15,132,207,15,24,139,157,200,249,248,35,95,36,137,87,28,139,77,204,102,137,79,40,102,133,201,15,148,193,132,200,117,115,139,69,236,247,101,208,137,193,3,77,220,131,210,0,117,99,139,69,232,72,137,194,193,250,31,3,69,216,250,7,72,226,1,247,218,137,79,44,120,74,188,251,35,232,137,71,48,128,125,240,0,116,19,137,79,32,141,85,156,102,137,90,26,193,235,16,102,137,90,20,235,9,1,193,114,37,137,79,32,49,210,49,246,141,69,188,137,249,86,80,232,11,2,34,3,128,255,11,136,0,124,2,209,188,137,71,8,137,240,129,196,88,2,59,5,134,135,2,136,132,36,1,128,174,2,152,152,232,98,134,2,72,201,133,192,116,13,137,200,129,196,25,1,42,248,4,139,125,12,49,246,78,128,124,55,1,47,141,118,1,116,246,139,85,156,49,14,201,32,117,20,139,69,188,141,141,120,15,11,248,11,65,26,193,232,16,102,137,65,20,137,77,236,49,201,49,219,137,216,1,240,114,184,15,182,4,7,167,3,137,136,197,4,248,11,47,116,11,67,129,251,4,1,0,0,117,224,235,156,137,85,240,141,4,55,83,80,141,133,115,254,237,9,145,28,72,114,3,24,198,132,29,16,123,1,0,67,1,222,15,130,60,1,0,0,141,77,152,139,85,236,38,188,141,69,204,80,232,45,1,0,4,202,133,27,1,0,0,246,69,215,16,133,13,136,132,250,7,16,106,32,37,16,141,157,152,162,83,232,198,71,97,6,184,93,236,139,85,240,233,98,32,8,64,85,240,1,247,83,87,141,181,103,24,86,232,165,33,5,119,3,110,9,86,104,136,197,10,14,11,201,106,144,233,254,163,3,170,86,106,56,232,233,207,8,58,137,195,86,106,68,232,220,13,200,131,125,240,32,141,117,152,185,13,140,17,240,199,243,165,137,199,15,183,85,230,137,80,52,117,12,165,2,121,12,193,224,16,9,194,137,87,52,139,117,8,139,69,232,137,71,56,137,248,131,192,64,199,71,64,0,0,225,161,80,232,252,4,88,4,249,20,137,71,60,133,192,116,40,137,217,137,123,16,199,67,20,231,9,1,0,199,67,24,41,10,1,0,139,71,56,137,67,28,199,67,32,198,6,104,115,4,233,88,254,255,255,131,127,56,0,116,210,151,169,68,87,232,97,53,5,11,50,86,106,56,83,232,85,12,188,49,201,233,49,254,255,255,61,13,128,79,1,249,9,137,214,137,207,15,182,65,14,15,183,89,12,15,175,216,141,133,184,254,255,255,104,5,1,221,19,154,232,172,70,37,4,121,5,246,116,97,137,93,232,15,183,86,26,131,127,4,32,117,9,15,183,70,20,197,91,139,117,232,141,69,212,137,249,80,232,74,178,208,195,49,192,72,133,219,15,132,242,3,66,10,248,2,212,137,200,247,230,112,13,137,198,61,1,0,0,16,15,130,153,55,8,74,225,2,106,0,81,83,232,192,52,149,168,192,72,233,197,3,18,13,121,23,79,40,193,225,5,141,67,255,1,200,115,8,49,192,64,233,175,3,0,0,49,210,247,243,137,198,137,93,232,247,227,137,195,15,144,192,129,251,73,121,12,147,193,8,193,49,192,72,132,201,137,117,212,15,133,134,3,0,0,137,117,240,49,192,80,83,232,90,235,91,8,137,69,236,15,183,71,12,247,103,44,88,253,0,49,246,86,139,117,236,81,82,80,86,255,55,232,167,23,79,5,240,199,2,0,0,139,125,240,137,242,235,77,49,192,80,255,7,21,232,23,67,253,9,137,249,139,69,240,137,218,49,255,87,49,255,86,87,87,255,117,236,137,199,80,232,202,4,141,5,136,110,141,5,161,4,189,0,0,13,21,162,83,232,236,51,50,12,176,85,236,137,249,137,251,208,9,64,175,222,193,235,5,15,132,105,41,219,66,1,137,69,204,141,66,14,137,69,208,100,14,129,251,10,168,216,49,255,137,85,253,10,208,137,125,228,193,231,5,15,182,4,58,205,6,136,158,18,6,248,9,77,240,1,215,131,125,12,0,138,79,11,116,28,128,249,15,15,133,42,1,0,0,61,229,200,3,11,26,69,120,1,233,188,1,0,0,128,249,8,15,133,179,1,0,0,233,6,56,218,198,131,230,31,168,64,139,69,224,116,27,206,1,138,32,219,1,160,80,232,216,68,226,3,137,236,91,15,123,1,133,246,139,77,240,116,9,57,198,117,5,131,254,20,118,18,150,192,139,125,228,139,117,232,233,107,111,3,136,70,189,5,120,0,141,4,118,137,117,200,141,4,134,137,69,220,141,180,5,73,144,184,251,16,14,121,6,77,204,138,84,65,10,136,84,6,248,64,117,245,49,192,139,77,208,138,20,65,15,248,16,131,248,6,117,243,255,77,220,49,210,49,192,138,76,87,28,136,76,22,254,168,1,117,18,3,85,220,176,1,129,250,98,2,129,148,14,200,114,226,131,125,200,1,15,133,28,202,15,145,3,1,5,11,17,128,188,99,248,0,32,117,8,131,192,255,114,241,49,192,72,198,132,5,185,238,14,144,128,61,48,8,120,4,0,184,0,23,1,0,185,54,23,1,0,15,69,193,255,117,12,141,141,48,155,81,255,208,8,8,136,128,210,6,249,26,79,11,139,85,236,246,193,8,15,133,156,0,0,0,184,245,255,255,255,198,68,5,200,32,64,117,248,139,69,12,138,0,132,192,116,97,49,246,199,69,220,137,1,249,20,219,67,60,46,116,52,131,254,8,15,146,193,131,254,10,139,85,236,119,101,10,77,220,246,193,1,116,93,15,190,192,80,232,53,15,235,7,40,136,68,53,189,70,64,122,3,4,24,67,132,192,117,202,235,29,246,69,220,1,139,77,240,117,46,22,136,190,163,11,251,4,177,1,137,77,220,132,192,117,170,106,11,141,69,189,80,87,232,247,15,111,7,178,139,77,212,15,132,164,237,11,40,139,85,236,235,6,8,194,77,240,139,125,228,71,137,203,46,2,120,3,131,69,204,32,131,69,208,32,57,223,15,130,233,253,255,255,233,148,47,1,39,144,235,204,165,2,177,255,117,236,232,130,49,192,7,152,193,231,2,243,14,242,233,173,252,255,255,106,0,83,86,233,165,252,255,255,86,2,201,235,96,106,0,106,12,232,73,50,147,4,248,3,139,15,139,87,4,137,8,137,80,4,139,79,7,137,72,7,185,11,68,21,144,124,8,102,1,248,1,198,68,8,255,0,73,117,241,139,77,8,137,1,199,69,216,8,7,0,109,248,1,28,106,32,87,255,117,8,137,206,232,142,66,0,0,137,241,177,15,0,30,4,189,168,15,175,206,106,0,158,8,140,48,153,15,156,129,196,60,40,6,0,210,189,57,223,139,85,236,115,45,213,2,128,110,2,137,202,189,2,82,116,195,1,215,128,127,11,15,116,151,100,145,232,44,121,16,24,12,235,128,121,141,166,201,19,240,137,77,232,139,113,4,49,192,131,254,12,185,239,15,195,16,184,200,131,254,16,187,239,255,206,16,249,13,216,9,203,131,254,32,191,239,255,255,15,15,69,251,131,250,2,15,130,180,0,0,0,57,250,15,135,172,93,3,152,137,249,73,111,13,136,132,198,20,128,252,6,248,0,1,57,193,15,66,193,247,216,137,69,240,49,246,70,187,197,12,225,137,85,228,139,77,232,141,69,236,80,232,9,39,7,168,4,133,192,117,111,33,3,248,4,250,2,114,22,57,250,119,18,131,195,4,139,69,240,141,68,48,1,70,122,11,225,209,235,81,49,255,87,106,4,87,86,232,37,132,1,137,16,9,8,184,228,137,69,236,139,85,236,48,4,20,20,184,82,20,183,1,82,176,15,71,57,254,117,223,83,20,251,0,48,139,69,240,235,16,106,0,83,255,117,240,232,188,47,4,5,134,189,19,179,229,87,86,139,117,28,188,19,251,7,72,16,139,81,60,86,87,255,117,20,255,117,16,255,117,12,255,113,64,232,75,0,12,10,233,116,8,137,248,137,242,94,95,93,195,104,139,79,97,11,33,228,17,0,0,66,128,132,19,168,112,16,139,70,64,164,13,66,255,87,80,255,118,60,232,80,108,50,87,106,68,86,232,68,120,0,60,132,63,22,136,40,83,9,208,182,81,14,137,77,224,15,183,65,12,85,9,248,5,220,49,201,49,210,59,77,24,137,208,27,69,28,15,147,69,243,15,131,218,94,24,250,10,206,3,117,16,137,215,19,125,20,106,0,255,117,220,87,86,137,77,228,137,85,216,232,115,233,52,13,209,209,59,69,8,131,218,0,15,131,173,110,20,161,212,139,20,130,156,1,137,158,111,1,249,12,208,139,85,24,43,85,228,137,85,236,139,85,28,27,85,216,137,85,232,139,93,220,247,227,137,69,204,73,13,185,43,117,204,25,207,41,243,111,21,192,25,250,57,93,236,139,69,232,57,15,72,93,236,137,93,236,15,66,85,232,49,248,17,77,208,131,193,254,139,69,224,15,182,64,14,247,225,137,209,139,93,224,3,67,32,131,209,0,15,183,83,12,15,175,202,119,13,248,13,1,240,17,250,139,77,12,139,117,228,1,241,139,125,232,87,139,117,236,86,82,80,81,255,51,232,168,17,229,8,255,10,216,139,77,228,131,196,24,1,241,17,250,132,192,15,133,20,255,255,255,138,69,243,131,196,40,75,22,2,120,3,24,137,211,15,183,113,12,137,240,247,97,28,137,85,228,137,69,224,11,121,1,24,137,199,139,65,4,131,248,32,116,92,131,248,16,15,133,219,249,15,216,193,232,31,1,219,137,93,236,131,195,2,137,69,240,131,208,0,49,246,78,57,223,139,125,8,25,194,199,7,122,25,144,130,232,89,17,152,69,224,3,45,2,252,1,228,19,85,240,106,0,106,2,82,80,87,255,49,232,19,17,227,11,144,133,188,213,5,11,190,83,33,30,193,227,2,84,14,4,84,55,223,25,194,15,130,157,75,7,48,4,82,80,139,125,8,78,148,197,16,37,2,184,121,128,103,3,15,235,108,179,23,122,17,222,209,238,49,192,137,93,236,1,222,15,146,192,137,242,131,194,2,137,69,220,131,208,0,57,215,25,69,240,139,125,8,165,120,7,102,199,69,234,0,0,114,62,139,85,224,1,242,139,117,228,19,117,220,141,69,234,169,61,86,82,80,255,49,232,106,91,169,27,15,183,69,234,28,22,152,37,255,15,122,9,240,236,1,15,69,193,137,7,49,246,235,3,49,246,78,187,21,140,24,94,10,161,93,233,241,242,123,8,148,49,192,245,12,186,139,93,12,83,232,143,11,234,8,211,198,131,198,2,106,0,86,232,154,45,16,16,250,1,128,59,47,116,6,198,7,47,137,248,64,83,80,232,218,9,198,4,224,69,8,128,120,13,1,117,35,87,104,127,79,199,12,149,159,53,251,12,202,137,195,106,0,86,87,232,105,44,73,4,180,54,87,80,232,250,0,45,14,137,16,101,4,136,22,192,17,128,35,6,97,116,10,137,195,137,120,8,137,112,12,235,14,54,10,51,54,128,170,10,135,136,3,1,123,8,8,128,62,1,117,25,128,126,1,0,117,26,255,118,32,255,118,28,255,118,16,232,6,99,168,7,86,255,86,24,255,13,219,255,87,255,118,12,255,118,8,232,236,43,100,3,34,56,86,232,224,12,134,100,3,8,80,190,250,23,56,1,117,74,128,120,2,1,116,78,139,117,20,139,77,16,139,88,28,137,93,240,139,120,32,41,203,137,250,25,242,59,77,240,25,254,115,57,2,4,250,2,57,251,25,242,114,45,3,72,16,87,81,255,117,12,232,9,61,189,10,136,248,165,23,137,4,183,11,3,8,177,255,96,20,104,142,87,151,14,145,212,85,107,15,150,218,13,37,23,144,44,10,224,6,192,141,117,202,83,106,5,83,104,9,24,136,86,13,1,149,162,14,84,14,253,2,56,3,0,0,198,69,207,0,104,180,77,1,0,86,232,144,8,82,11,144,30,3,218,8,170,106,20,232,2,44,71,6,144,53,32,103,16,248,0,246,137,69,236,116,20,137,199,139,69,8,57,6,15,132,204,8,245,139,118,12,133,246,117,238,106,0,106,16,232,213,43,70,22,161,8,137,6,191,153,21,152,219,83,104,102,20,200,83,87,141,133,203,246,255,255,80,144,1,14,31,131,144,25,4,130,20,1,27,185,131,248,1,116,35,61,255,195,11,176,9,4,0,0,129,199,159,20,248,0,129,255,0,128,8,0,117,185,104,122,85,1,0,233,253,95,10,248,5,133,113,247,255,255,137,70,8,141,72,255,129,249,255,255,255,3,15,135,236,11,10,168,193,129,225,255,7,32,18,136,222,66,10,43,255,87,80,232,68,145,40,70,4,139,141,105,53,184,202,193,226,11,193,233,21,248,16,17,81,82,140,21,147,13,140,40,174,3,0,0,161,232,33,137,70,12,137,241,248,5,139,125,236,139,93,12,137,55,75,128,123,1,47,141,91,1,116,247,139,70,144,3,152,139,78,8,59,23,248,0,224,49,246,70,15,182,3,131,248,47,117,3,67,235,245,131,8,136,163,181,20,122,1,77,228,132,192,116,33,15,182,200,131,249,47,116,25,129,254,212,122,3,60,3,0,0,136,132,53,202,254,255,255,138,4,51,70,235,219,198,13,128,120,9,170,133,255,139,85,240,193,8,248,5,15,182,2,133,192,116,64,60,33,15,130,113,1,0,0,57,199,15,130,105,146,9,136,141,63,1,128,112,5,144,14,3,229,18,147,116,81,21,9,147,117,72,90,1,153,141,133,203,67,13,200,201,6,0,0,235,70,129,255,1,221,21,16,130,45,145,216,249,184,0,248,255,255,33,193,137,248,37,34,1,24,57,207,191,16,185,141,60,57,15,69,249,185,5,22,39,68,193,235,34,72,4,145,183,6,97,17,129,165,25,249,4,85,216,15,182,2,41,199,1,194,133,255,15,133,90,255,255,255,233,213,210,4,216,216,139,72,10,128,124,51,255,0,15,132,89,32,56,246,64,25,2,15,132,186,27,176,120,2,246,69,224,1,50,24,224,255,117,228,255,117,240,137,77,220,232,197,40,29,12,136,220,96,20,154,65,255,61,186,1,136,163,184,30,9,200,151,144,15,133,102,27,218,1,243,49,192,80,81,137,206,232,135,41,211,11,188,249,193,225,11,193,239,21,59,11,193,210,82,86,87,81,137,69,240,74,2,144,213,11,188,26,129,76,2,177,137,241,139,125,236,190,240,24,144,133,103,167,13,152,219,83,82,108,7,146,80,40,22,24,42,106,20,87,232,68,12,17,235,66,156,32,14,106,0,81,34,10,46,34,128,240,2,25,87,235,29,27,12,16,183,22,232,17,29,128,128,9,149,2,40,49,4,163,129,196,44,10,71,15,168,137,77,220,139,69,218,21,170,1,200,137,69,208,171,1,169,139,85,216,232,99,217,10,232,216,49,219,67,128,126,25,0,137,216,199,69,212,96,29,19,121,115,9,248,19,49,192,64,137,69,232,137,241,139,85,208,232,121,2,0,0,133,192,116,78,137,198,141,189,203,245,255,255,137,249,137,194,232,34,227,11,136,189,151,1,156,0,116,52,67,3,155,232,231,4,224,4,128,72,27,160,220,3,70,10,208,5,144,85,212,203,22,137,61,28,26,16,14,64,112,249,11,120,163,235,10,139,69,232,235,5,184,0,0,1,0,49,201,81,106,8,81,80,137,198,232,101,40,8,7,152,131,196,16,170,16,168,65,16,137,113,12,87,25,144,65,8,253,25,208,65,4,137,117,232,247,222,139,66,2,253,2,74,79,16,137,68,217,248,139,66,10,10,64,252,59,93,232,115,16,137,209,176,136,201,234,2,136,194,84,5,168,141,68,30,1,67,158,20,143,202,60,1,4,148,213,38,89,1,163,56,232,185,39,48,15,0,116,248,13,72,16,199,64,20,3,21,1,0,199,64,24,121,22,1,0,139,65,4,139,73,8,137,67,28,137,75,32,60,4,160,67,4,233,156,145,14,201,6,83,1,0,235,12,104,218,86,123,19,138,216,9,28,253,3,246,8,0,0,104,245,79,1,0,235,242,104,203,80,1,0,235,235,11,31,248,5,137,77,240,138,26,15,182,203,15,182,66,32,141,112,33,137,117,232,57,206,121,23,144,135,171,245,34,248,3,116,2,33,137,207,41,199,131,199,223,168,1,117,10,133,255,15,132,98,11,193,70,79,131,255,4,15,130,137,231,15,252,29,49,192,128,126,3,1,117,97,15,182,86,2,133,210,116,89,57,215,114,85,128,62,78,117,65,128,250,5,114,60,128,126,1,77,117,54,141,92,2,251,129,251,0,1,89,29,249,0,131,194,251,3,69,240,141,78,5,82,81,80,232,92,55,203,22,162,246,70,4,1,53,30,0,74,120,2,177,1,235,2,137,195,41,215,1,214,131,255,3,137,216,119,155,15,208,176,1,246,193,1,139,117,240,117,103,254,29,250,24,182,65,32,138,25,15,182,203,141,80,33,137,85,232,137,218,49,219,128,250,34,141,81,223,15,66,211,57,77,232,15,70,208,133,210,116,53,49,219,113,21,252,43,15,182,68,31,33,131,248,46,116,7,131,248,59,117,16,235,35,141,75,1,57,209,115,7,128,124,31,34,59,116,21,136,4,30,67,57,218,117,217,49,192,137,211,235,9,49,192,139,117,240,235,2,49,192,198,4,30,0,50,31,185,176,1,235,233,104,77,86,159,21,146,166,7,89,29,248,1,86,15,182,1,133,192,116,42,1,193,49,192,57,209,15,131,26,29,201,138,25,132,219,116,75,128,251,33,67,18,249,6,114,112,15,182,243,41,202,49,192,57,242,15,67,193,235,98,65,49,219,129,193,186,3,192,146,195,137,222,247,222,129,225,103,4,248,8,49,192,49,222,15,149,195,15,69,200,57,209,15,147,194,8,218,117,57,49,192,128,57,180,13,23,235,47,51,25,40,199,8,223,117,6,122,158,117,134,94,222,31,172,236,48,139,77,24,225,10,137,12,43,20,176,15,148,192,11,77,28,5,29,193,15,148,193,8,193,15,133,32,235,19,137,20,171,27,185,16,137,69,220,139,69,12,104,15,176,49,201,65,139,69,24,171,11,144,69,28,5,12,136,219,159,14,224,137,117,224,137,93,204,139,118,16,137,77,208,131,26,248,1,116,206,252,1,242,131,208,0,139,93,220,137,85,196,57,211,199,16,200,202,137,69,200,25,194,15,131,139,38,30,209,248,49,255,137,218,41,194,27,77,204,219,32,130,19,1,216,4,137,203,137,208,137,93,228,41,198,25,246,12,249,0,57,242,139,93,240,137,217,25,249,137,93,240,15,66,251,246,25,252,27,242,139,77,208,139,85,232,139,84,202,248,137,209,193,233,21,193,226,11,1,194,19,77,228,139,69,224,139,0,87,86,81,82,139,93,216,83,255,48,232,8,7,226,11,120,17,111,1,243,137,93,216,139,93,220,1,243,17,125,212,139,77,236,41,241,139,85,240,25,250,139,117,224,139,126,12,235,12,8,136,77,204,18,200,139,125,228,137,200,9,208,137,200,5,1,128,19,29,209,125,228,57,249,115,28,137,93,220,65,46,21,250,19,240,9,208,139,85,196,137,215,139,69,200,137,195,15,133,12,255,255,255,128,125,232,0,117,26,139,69,24,139,85,28,131,196,48,100,31,138,168,11,2,184,155,5,0,0,104,65,81,91,3,135,80,12,2,162,12,193,224,3,80,12,163,16,232,0,35,236,8,175,20,86,232,244,34,236,8,1,98,139,69,8,131,192,224,131,248,95,15,146,192,17,116,77,8,141,81,159,141,65,224,131,250,26,15,67,193,20,50,137,200,247,216,15,72,15,136,83,171,11,250,9,69,8,138,25,49,210,132,219,116,10,136,28,16,138,92,17,1,66,235,242,198,4,16,0,161,20,8,86,35,248,24,85,8,138,2,138,33,56,224,117,18,49,246,70,132,192,116,24,138,4,50,138,36,49,70,56,224,116,241,49,201,56,224,15,147,193,141,68,9,255,232,2,140,94,105,10,2,91,122,27,15,182,0,137,195,128,195,191,137,198,131,206,32,128,251,26,15,182,17,15,67,240,137,209,128,193,191,137,215,131,207,32,128,249,26,15,67,250,57,254,117,58,90,9,64,52,88,4,48,139,77,12,15,182,20,49,137,193,41,12,199,41,10,248,57,26,211,131,203,16,85,218,70,57,223,116,201,49,201,56,208,130,129,22,24,6,132,254,36,16,133,201,116,32,139,85,12,139,117,8,73,49,255,138,28,62,58,28,58,117,19,49,192,132,219,116,23,57,249,141,127,1,117,235,235,14,49,192,235,10,15,147,192,15,182,192,141,68,0,255,155,21,18,86,80,65,160,74,73,49,255,60,28,0,207,120,1,12,56,139,69,12,15,182,4,56,137,202,128,194,191,137,203,139,128,96,1,82,217,137,194,137,198,128,194,191,131,200,16,216,198,57,195,117,22,49,192,132,201,116,29,140,28,1,107,121,0,190,235,17,49,192,235,13,137,242,49,192,56,209,15,147,110,132,85,10,129,165,11,246,72,139,77,8,128,124,1,1,0,141,64,1,117,246,91,35,249,5,8,139,77,8,191,252,255,255,255,141,117,240,137,203,106,10,86,81,232,156,102,11,136,12,232,28,248,8,203,116,54,131,255,255,138,25,116,8,128,251,46,117,42,65,235,4,132,219,117,35,187,204,9,145,57,195,8,36,124,14,25,211,114,19,136,68,61,240,71,117,193,139,69,236,139,77,12,137,1,49,192,235,3,49,192,72,131,196,8,127,136,138,28,2,124,0,192,232,4,15,182,192,1,192,141,4,64,247,216,0,200,25,24,15,190,193,240,89,159,128,250,5,119,5,131,192,169,235,30,255,3,15,254,3,201,235,15,128,193,208,131,192,208,49,210,74,128,249,10,15,67,194,23,28,140,20,227,23,144,125,16,234,16,120,2,248,193,248,31,137,69,228,49,246,15,190,17,137,208,4,159,60,80,8,194,80,26,208,4,191,13,16,201,235,26,184,208,131,194,208,60,10,184,119,31,248,7,15,67,208,131,250,255,116,122,57,250,125,118,137,85,224,137,77,232,133,246,15,149,248,27,128,132,33,176,193,32,209,247,101,240,168,20,120,3,69,239,137,240,247,231,15,144,197,10,109,239,8,205,1,195,137,248,25,136,214,121,13,168,193,8,233,128,249,111,33,249,10,116,74,139,77,224,137,200,193,248,31,1,77,240,17,198,137,193,131,209,0,131,208,0,137,202,237,23,249,6,49,208,49,209,9,193,139,77,232,117,53,133,210,120,49,65,139,125,16,233,83,155,30,128,160,27,152,2,137,8,106,16,161,242,131,196,20,179,1,25,49,246,78,25,24,137,117,240,51,25,225,235,225,40,137,190,43,32,180,117,240,117,208,235,208,132,12,192,125,20,133,255,116,111,139,93,19,3,162,141,84,56,255,184,10,192,137,85,240,116,36,139,117,16,106,27,160,86,232,250,253,40,13,185,4,57,248,115,70,64,80,45,12,138,141,227,17,125,1,235,50,139,125,8,198,7,47,141,119,1,235,84,86,232,210,40,192,30,137,198,64,80,255,117,16,127,14,146,232,96,16,18,200,1,254,139,85,240,235,46,176,1,141,3,132,93,2,232,67,139,85,240,138,3,60,47,116,21,15,182,200,27,25,136,19,220,10,224,214,115,221,136,6,67,70,235,229,67,176,47,249,13,225,223,106,2,104,72,88,1,0,83,232,190,252,50,36,128,214,19,136,233,102,21,25,3,104,79,24,14,166,24,10,209,24,9,75,24,14,142,24,136,160,150,21,25,4,104,83,24,14,118,24,10,136,48,16,173,84,24,12,94,24,56,116,71,106,2,104,63,83,20,14,74,44,40,77,255,255,255,57,200,152,15,134,70,245,2,184,70,255,57,248,15,132,59,63,5,40,56,47,15,132,50,31,152,214,15,131,30,35,41,198,6,47,233,58,47,121,26,118,17,139,85,240,128,62,47,116,12,78,57,254,119,246,137,254,235,3,139,85,240,49,192,57,254,15,148,192,198,4,6,0,1,198,131,195,2,233,245,254,45,8,12,42,11,7,42,3,37,16,1,198,70,251,7,141,70,255,128,126,255,47,137,193,15,69,206,57,248,15,69,241,198,6,0,233,173,194,23,152,86,80,141,219,6,216,244,198,5,137,113,5,0,0,161,180,129,255,29,248,12,116,18,139,13,176,129,5,0,139,17,198,66,4,1,131,193,4,72,117,244,139,117,12,138,93,8,160,169,29,24,139,13,184,39,110,201,15,148,194,132,208,116,16,232,102,245,1,0,25,249,10,0,131,249,3,185,98,81,1,0,186,211,81,1,0,15,68,202,132,192,15,68,202,81,232,116,98,29,186,4,255,117,244,86,232,129,110,29,144,104,66,5,30,10,91,25,169,106,0,232,26,20,9,29,163,132,219,116,60,19,30,249,2,116,51,184,52,83,1,0,185,91,78,1,0,128,61,204,47,5,189,19,152,81,104,222,56,29,10,34,70,193,232,102,30,1,0,232,113,244,30,30,90,186,56,3,0,104,69,84,1,0,232,4,87,174,232,200,211,255,255,245,7,200,93,8,128,123,13,1,15,132,145,178,23,224,117,28,139,75,56,139,123,60,137,202,33,250,146,3,200,67,247,199,0,0,128,255,15,133,105,23,120,16,15,164,207,9,193,225,9,137,206,139,69,16,41,198,137,250,139,69,20,25,194,57,77,16,137,193,25,249,15,131,71,64,210,69,24,57,198,139,117,28,25,242,184,152,17,144,52,2,211,27,208,139,85,24,137,209,9,241,15,132,37,124,23,192,214,139,123,20,15,175,123,4,6,19,249,14,137,125,220,137,77,204,3,77,16,137,85,208,19,85,20,106,0,87,137,85,200,82,137,77,196,81,232,124,214,43,32,249,3,131,123,32,1,137,69,228,117,22,139,67,40,51,69,228,139,75,44,193,3,169,69,228,15,132,100,193,34,139,212,174,25,248,16,139,115,20,139,67,36,133,192,116,5,137,69,224,235,56,139,75,4,137,240,193,248,31,247,225,137,199,15,144,69,232,50,25,251,7,1,250,15,146,193,10,77,232,128,249,1,15,132,168,1,0,0,82,80,232,129,28,217,24,33,224,137,67,36,68,136,48,200,8,161,123,52,141,158,4,36,251,4,246,15,73,222,137,222,193,254,9,193,251,31,83,86,87,80,232,228,213,143,19,248,1,15,175,216,137,69,216,247,230,1,218,137,77,232,15,175,206,173,32,218,236,41,194,25,207,9,215,15,133,57,1,178,39,232,120,4,139,69,212,247,231,137,193,15,144,69,243,207,20,248,3,125,236,247,231,137,195,137,215,1,207,15,146,192,10,69,243,15,133,136,35,72,3,93,216,19,125,232,15,130,2,55,224,77,8,139,65,56,139,73,60,137,194,33,202,133,1,100,73,137,242,193,250,31,82,86,81,80,232,103,125,160,139,85,216,1,39,26,146,17,206,65,5,248,4,66,240,15,66,208,137,208,41,216,137,241,25,249,59,69,236,131,217,0,245,40,225,66,200,57,211,137,248,25,240,114,8,233,167,124,36,240,236,81,87,83,255,117,224,139,117,8,86,232,42,215,164,3,136,20,226,27,176,138,0,0,0,199,70,223,9,128,203,29,248,23,137,70,40,139,85,212,137,86,44,139,117,24,139,125,220,137,241,43,77,204,139,117,28,27,117,208,137,211,247,231,15,175,223,1,211,139,85,196,152,33,185,200,25,216,137,251,41,211,214,42,248,13,25,199,57,217,137,240,25,248,15,66,254,15,66,217,139,69,12,139,117,204,1,240,139,77,8,3,81,36,169,33,144,161,43,4,29,137,208,240,22,250,0,1,217,139,93,8,17,250,139,125,220,139,117,24,57,241,10,21,170,130,241,253,255,255,215,4,133,57,9,145,186,77,22,32,138,179,127,17,150,91,252,186,2,227,92,141,125,152,106,92,106,0,87,232,93,43,135,27,192,179,1,49,246,70,139,4,141,102,31,224,137,193,193,249,31,106,0,106,92,81,80,87,230,17,136,11,84,5,129,223,21,176,20,106,8,104,26,80,227,32,148,185,247,165,4,177,16,49,192,246,195,1,82,43,200,137,241,117,188,235,41,129,125,160,213,13,168,117,30,139,69,220,223,43,137,66,32,39,168,66,8,139,69,208,127,27,164,74,4,137,2,129,5,143,92,36,43,2,209,68,139,117,8,141,125,242,102,199,7,157,17,160,106,1,83,104,53,15,43,87,86,232,137,252,130,160,15,132,121,1,27,25,192,15,182,69,242,168,127,15,133,17,26,1,41,10,206,41,14,96,41,15,80,41,2,12,66,41,10,222,41,14,55,41,15,39,41,2,12,25,82,10,238,41,14,14,41,23,254,0,41,1,137,240,173,48,101,178,83,106,4,83,106,3,80,86,232,229,251,82,138,213,231,5,24,68,83,1,34,163,80,232,51,42,203,19,128,192,5,16,184,0,179,32,3,83,106,54,28,30,86,232,173,56,138,157,55,6,12,59,56,22,251,41,56,20,132,128,56,10,82,56,12,117,56,23,116,105,52,1,14,199,52,144,116,80,95,19,18,106,3,48,13,69,48,137,57,115,33,3,156,14,151,48,73,116,32,83,106,2,83,104,56,4,249,13,21,48,254,0,9,102,129,125,242,83,239,15,149,195,137,216,131,196,68,142,20,128,219,21,177,49,246,87,232,59,254,117,7,160,132,192,116,31,227,31,124,0,244,86,106,4,86,104,184,1,0,0,80,87,232,206,250,71,177,3,139,117,244,137,240,118,7,134,101,34,136,20,144,24,184,125,16,0,15,136,21,6,70,34,160,224,254,255,255,155,2,155,80,232,194,207,16,138,192,155,2,144,60,133,155,2,128,35,9,129,155,2,18,80,87,44,136,80,135,20,13,106,100,139,26,161,2,3,29,156,232,18,245,167,2,141,14,165,2,192,240,117,178,235,107,129,189,232,172,42,128,168,2,153,95,187,253,198,8,160,16,59,133,48,153,39,144,131,142,63,36,176,133,52,255,255,255,61,117,1,200,114,62,137,249,247,217,15,72,207,19,40,169,200,247,165,44,255,240,33,24,15,144,195,14,137,40,16,41,248,10,137,214,3,117,236,15,146,192,8,216,139,69,240,117,13,247,101,16,1,193,17,214,15,131,132,220,41,136,254,103,4,162,117,12,232,20,156,8,128,92,20,145,43,5,245,9,200,131,255,4,114,78,49,219,67,191,29,18,128,189,31,49,16,86,87,141,69,212,213,148,149,249,57,1,128,120,37,248,3,216,131,248,15,116,5,131,248,5,117,11,139,85,224,133,210,15,133,156,43,73,67,131,199,16,131,251,5,117,198,195,152,233,213,4,11,14,33,193,224,4,5,80,33,201,141,85,212,220,176,81,106,16,81,80,82,177,21,12,64,85,184,139,117,8,15,132,165,4,250,2,200,75,128,125,216,0,15,132,152,4,8,24,129,22,35,8,141,11,248,24,85,12,139,10,137,14,139,74,4,137,78,4,139,74,8,137,78,8,138,74,12,136,78,12,71,137,126,16,139,74,20,137,78,20,139,77,220,49,219,142,43,218,78,48,137,94,60,137,70,56,137,86,24,176,42,186,86,80,232,164,232,255,255,6,40,153,38,139,133,247,40,41,70,80,139,133,68,9,145,76,139,53,41,144,139,141,23,41,113,137,78,72,137,70,68,179,1,136,94,64,86,232,101,54,138,4,242,2,128,28,2,184,137,70,108,176,1,233,12,248,29,136,181,212,40,160,49,192,185,25,23,45,152,247,243,171,68,13,249,14,1,137,70,244,139,65,4,137,70,248,139,65,8,137,70,252,138,65,12,136,6,137,94,4,139,65,20,137,70,53,18,252,1,70,36,49,192,137,70,40,137,70,48,137,86,44,137,78,12,237,1,136,61,218,29,152,15,135,162,210,31,160,219,131,192,252,210,1,144,132,176,249,18,200,255,49,192,137,198,15,164,248,9,223,19,152,9,129,201,91,4,128,68,22,147,80,81,86,2,132,254,43,149,243,247,68,4,144,124,254,171,36,144,133,228,243,32,186,248,15,116,9,131,248,5,235,19,144,139,133,104,2,24,137,69,240,209,248,0,86,254,255,255,133,219,15,148,192,59,125,240,131,222,0,122,11,136,193,81,7,145,133,61,171,45,185,240,59,133,116,255,255,255,0,8,137,27,237,41,152,15,131,35,47,20,144,192,67,117,26,161,125,240,116,26,33,34,232,49,192,136,70,104,198,70,84,0,233,228,2,0,56,40,131,30,29,41,137,200,193,232,23,179,128,108,20,144,141,149,153,42,7,185,2,28,82,232,64,179,129,24,2,162,15,132,163,2,2,2,8,189,186,160,0,15,132,147,138,8,16,133,236,168,160,192,15,132,133,152,8,144,141,112,103,45,170,85,240,3,149,108,157,34,128,212,26,144,130,106,179,8,0,21,0,223,4,21,10,85,21,200,1,194,137,202,131,210,0,15,130,25,38,9,139,135,185,139,117,8,137,22,139,149,240,1,41,86,4,139,149,68,9,145,8,138,168,42,105,136,86,12,139,85,16,66,137,86,16,139,149,80,34,32,20,137,78,52,209,65,78,48,137,70,56,199,70,60,225,145,133,84,61,2,203,24,141,69,188,86,80,232,68,230,96,2,153,15,132,235,49,8,136,200,97,2,144,69,196,94,2,170,69,188,139,77,192,88,2,152,176,1,233,27,6,145,186,128,188,5,130,78,45,152,82,83,80,85,33,146,97,36,148,45,8,184,28,137,80,17,1,160,86,255,117,240,114,45,131,88,4,149,18,246,37,6,136,122,122,32,248,3,69,188,49,201,137,72,12,137,72,8,137,72,4,137,8,141,141,76,98,1,42,16,80,81,232,81,76,153,49,219,75,163,11,128,194,8,144,181,104,159,46,136,149,126,45,153,139,133,92,239,2,138,96,58,4,224,57,194,137,240,137,77,240,25,200,15,130,35,227,2,185,117,208,137,85,204,141,183,56,45,240,255,15,73,247,137,247,193,255,9,193,254,31,15,149,43,47,128,75,47,168,195,32,203,247,231,118,38,128,142,9,121,7,240,139,77,236,247,225,15,144,199,10,125,232,8,223,139,85,228,141,52,2,137,200,32,144,1,242,132,4,161,248,15,133,200,217,28,248,8,232,139,117,204,41,206,139,69,208,27,69,240,137,241,33,193,131,249,255,15,132,173,0,118,23,112,193,249,31,131,198,1,131,208,0,15,149,199,133,201,98,8,251,66,168,240,15,144,69,236,240,9,49,139,77,240,141,12,1,101,152,236,8,223,59,14,144,1,202,176,2,145,249,187,205,4,176,110,139,125,12,139,15,214,1,153,14,139,79,34,4,137,79,34,4,136,79,34,4,202,139,77,16,65,137,78,16,139,79,37,4,137,232,205,1,136,228,205,1,137,86,38,4,212,126,24,141,69,212,86,80,232,129,228,35,4,161,54,139,69,224,191,1,137,220,191,1,164,212,139,77,216,191,1,168,235,28,49,219,75,210,22,140,20,84,43,128,255,2,162,64,233,208,251,9,3,173,64,86,232,48,228,53,4,145,116,7,49,4,148,235,2,36,3,152,1,141,149,165,1,144,139,2,201,4,248,6,70,88,137,78,92,139,66,8,137,70,96,139,66,12,137,70,100,235,166,131,61,111,44,153,0,116,97,85,18,129,208,6,145,139,13,145,44,251,3,4,177,128,120,64,1,117,28,131,192,68,106,16,87,80,232,110,34,48,33,5,32,89,116,50,128,120,84,1,117,25,131,192,88,34,15,76,34,3,40,116,16,70,59,53,94,224,114,179,49,192,235,6,49,192,195,139,4,177,124,27,128,178,44,128,25,13,15,61,116,6,249,0,20,177,128,122,104,1,117,27,87,255,114,108,232,156,237,27,28,5,79,9,17,56,47,70,57,198,114,215,80,3,130,60,45,163,133,201,116,51,93,18,146,85,16,97,13,17,139,61,170,251,7,7,57,112,8,117,10,56,88,12,117,5,57,80,16,116,8,131,199,4,73,117,233,12,18,0,71,4,64,137,30,211,18,33,85,8,139,53,226,16,6,57,45,169,198,4,73,117,244,187,18,144,49,192,137,17,128,52,28,210,141,77,12,137,77,252,81,80,232,5,105,17,135,10,21,2,202,12,139,125,8,141,117,240,199,6,198,34,184,131,199,2,15,182,71,254,209,5,144,146,3,43,44,208,37,116,58,60,10,117,26,129,251,254,239,40,98,11,198,131,148,113,5,0,13,67,137,93,240,11,11,0,26,17,10,136,15,6,25,248,9,0,71,235,181,15,182,71,255,131,248,98,127,58,131,248,82,126,91,131,248,83,15,132,55,67,8,168,248,85,15,132,15,48,6,176,202,131,248,88,15,133,175,3,120,7,137,243,137,208,141,114,8,139,18,137,217,255,112,4,232,152,5,0,0,233,255,0,35,224,141,72,144,131,249,8,119,68,255,36,141,88,240,10,144,211,139,83,33,48,137,241,106,0,232,114,38,9,186,82,24,35,116,78,78,39,68,15,133,44,78,7,177,250,3,0,0,233,177,251,44,33,99,15,132,147,49,152,100,15,133,133,12,4,79,136,208,206,17,32,241,80,232,207,43,136,103,213,12,208,49,131,193,4,137,77,236,86,232,44,219,1,128,134,33,152,15,142,155,229,6,251,10,193,72,128,124,14,255,35,117,238,133,192,116,65,49,192,64,138,84,6,255,128,250,10,117,23,11,1,140,8,37,1,135,34,1,3,152,7,136,147,34,1,4,22,200,64,57,193,117,197,137,93,240,141,115,17,152,236,233,28,174,37,194,243,141,113,8,139,17,137,200,4,1,146,251,3,197,39,168,241,137,222,233,253,94,7,176,200,139,9,141,112,8,245,16,8,95,161,79,80,4,133,210,116,58,138,1,60,123,24,15,131,123,1,160,65,74,117,201,132,54,144,241,233,133,1,135,219,1,3,142,63,194,1,152,0,233,133,8,1,24,2,131,194,252,145,132,50,84,28,176,8,131,249,10,116,10,121,17,136,101,180,43,7,121,22,15,139,244,2,151,235,190,191,1,1,136,26,120,39,176,217,131,196,4,233,30,61,8,159,209,138,2,107,2,37,28,131,193,4,172,138,219,247,13,239,15,182,6,131,248,10,116,6,133,192,116,50,235,23,1,35,154,70,235,194,144,1,120,0,233,143,0,0,0,185,7,88,1,0,15,182,17,131,250,240,152,210,15,132,99,29,143,235,228,1,35,32,65,235,190,184,71,129,55,1,0,149,8,201,149,135,51,1,35,1,149,128,162,34,193,240,233,95,252,255,255,128,61,175,17,146,117,51,39,17,168,1,117,51,131,61,187,17,176,0,116,33,49,246,161,187,17,16,83,104,146,184,255,52,176,232,216,181,2,72,19,24,70,59,53,34,49,114,225,133,219,117,63,220,128,97,41,136,135,55,28,160,246,141,125,196,132,55,161,87,232,1,29,116,19,153,15,190,134,118,1,144,0,14,206,54,193,232,87,87,106,16,232,193,194,207,18,100,70,57,243,117,211,49,246,191,0,36,0,8,125,12,64,143,161,55,128,61,138,155,5,11,46,66,154,80,232,51,30,10,24,15,182,142,223,249,3,132,192,117,10,131,249,27,119,14,15,163,207,115,9,81,232,12,182,250,46,0,85,136,178,62,24,133,167,12,156,15,182,2,193,1,185,66,235,31,139,49,129,254,195,2,58,14,141,126,1,137,57,198,158,18,139,49,9,13,0,31,9,13,31,9,136,22,5,30,159,66,235,178,162,36,1,200,32,137,215,139,85,8,49,192,137,109,37,128,234,45,136,137,10,54,216,212,198,69,232,0,137,248,9,208,116,85,188,49,128,8,4,209,49,194,49,199,41,199,25,194,190,19,114,36,210,236,106,0,106,10,82,87,232,211,196,212,49,248,5,193,1,193,141,12,137,137,251,41,203,128,203,48,136,92,53,212,78,185,9,161,22,137,249,188,57,123,4,27,77,236,137,199,114,201,131,125,8,0,120,35,70,235,37,139,1,61,193,176,80,1,137,17,198,128,253,3,26,48,139,1,9,249,2,0,235,17,198,68,53,212,45,141,84,53,212,139,77,240,232,250,156,13,136,32,141,58,6,183,23,139,117,181,12,224,208,9,240,116,76,137,215,137,77,240,141,93,151,55,0,168,35,86,87,232,43,168,9,214,170,111,20,137,137,249,41,209,128,201,48,136,75,255,75,169,7,128,255,57,161,137,218,232,129,54,52,7,172,19,6,153,137,229,15,23,128,32,19,152,8,49,201,242,50,248,38,77,236,137,77,232,137,77,228,198,69,244,0,137,209,9,193,116,59,141,125,244,137,193,15,164,209,28,131,226,15,138,146,109,86,1,0,136,87,255,79,193,232,4,137,202,9,193,117,228,137,241,186,219,201,19,136,9,112,11,169,241,137,250,232,0,150,14,136,20,238,34,58,137,241,186,80,82,1,0,14,156,233,231,253,114,44,249,3,80,139,117,8,133,246,117,2,137,238,104,84,82,1,0,232,29,249,97,2,243,191,88,17,5,0,139,70,4,133,192,116,103,139,54,62,20,152,185,156,89,221,41,184,207,139,17,57,194,115,62,221,43,249,28,219,137,214,137,223,131,199,4,137,251,128,60,25,0,141,91,1,117,247,139,20,25,57,194,114,231,1,249,137,194,41,242,82,81,80,104,202,86,1,0,232,198,248,144,19,25,139,117,240,90,40,235,14,80,104,97,111,9,174,24,0,130,66,146,104,248,85,1,0,232,157,17,135,101,25,1,200,128,61,48,95,1,0,1,15,132,91,62,128,118,9,160,93,8,129,195,220,36,168,131,215,0,15,146,151,25,249,34,137,193,247,217,9,193,15,133,217,0,0,0,129,227,0,240,255,255,161,60,95,1,0,139,53,56,95,1,0,137,241,1,217,137,194,17,250,137,125,240,137,223,187,0,0,16,0,57,203,17,60,248,21,25,209,114,96,49,201,81,81,81,106,1,104,0,16,0,0,139,93,240,83,87,80,86,104,208,145,5,0,104,224,145,5,0,232,176,12,97,23,9,44,72,128,119,51,9,61,87,16,129,198,46,128,22,24,8,241,230,23,17,218,85,3,9,137,46,8,163,42,162,115,160,104,7,188,27,144,223,233,123,29,178,87,80,86,232,237,24,136,23,8,61,84,16,17,29,39,30,49,192,80,117,155,232,87,0,100,59,132,158,23,200,104,177,84,1,0,235,186,104,251,251,27,136,179,113,25,254,9,69,32,138,77,36,15,182,85,40,15,182,201,15,182,192,82,81,80,255,117,28,255,117,24,147,40,22,117,8,82,25,232,233,11,199,134,48,26,136,80,96,19,136,24,177,4,136,8,243,14,248,5,117,8,141,70,8,137,69,196,49,201,141,4,73,131,124,198,16,1,15,133,65,32,152,141,4,198,25,3,249,5,77,204,137,77,188,137,93,232,137,222,139,93,196,131,109,188,1,15,130,235,139,56,176,216,139,57,139,81,4,119,14,216,125,220,1,248,139,73,12,17,209,15,130,231,7,129,58,45,248,18,192,139,115,248,139,83,252,139,59,137,117,200,1,247,139,117,192,137,125,224,139,123,4,137,85,212,17,215,137,125,228,15,130,198,61,125,11,57,69,224,139,85,228,25,202,15,146,69,211,139,125,200,57,125,220,139,85,236,27,85,212,114,14,26,136,131,249,46,216,59,125,220,139,125,212,137,250,27,85,236,244,40,121,7,57,69,200,25,207,15,146,194,34,85,243,139,125,220,57,125,224,139,125,228,27,125,27,123,18,138,117,211,34,117,243,32,214,128,254,1,15,132,69,3,0,0,246,194,1,15,69,77,212,15,69,69,200,139,125,224,57,199,112,208,194,132,85,243,139,85,220,15,69,215,180,31,144,69,125,93,21,184,139,125,216,137,23,41,208,135,40,248,5,125,236,137,122,4,25,249,137,66,8,137,74,12,131,195,24,78,15,133,1,234,25,128,85,35,248,3,8,139,64,12,137,202,9,194,116,126,128,125,16,0,116,93,129,249,17,2,248,4,137,194,131,218,0,114,107,139,117,216,139,22,139,118,4,137,215,129,199,165,2,248,9,137,117,236,131,214,0,137,117,228,15,146,195,15,182,243,137,243,247,219,9,243,117,68,190,166,2,200,33,247,1,202,139,77,236,17,193,31,20,152,56,41,250,49,30,248,4,120,4,25,249,33,242,137,80,8,9,202,137,72,12,116,27,139,93,232,147,48,248,2,77,204,235,57,139,85,216,137,2,137,74,4,49,192,137,66,12,79,20,216,93,232,75,57,93,204,115,26,141,4,91,32,50,161,52,194,185,6,35,3,250,7,216,243,165,137,214,49,201,73,235,6,49,201,73,139,117,8,65,57,217,15,130,32,123,15,144,132,21,241,14,248,1,192,138,13,212,145,5,0,136,77,236,141,12,64,131,124,206,243,1,128,197,6,201,141,60,206,128,125,236,0,117,101,155,44,136,190,102,3,153,57,206,190,161,21,225,214,114,80,139,119,8,137,117,228,139,119,12,158,31,249,3,232,137,203,3,93,228,139,117,224,17,242,15,146,69,220,129,251,1,69,3,136,232,103,42,72,146,194,10,85,220,117,39,129,201,231,240,3,77,228,131,214,255,137,79,8,137,119,12,199,71,225,43,153,0,199,7,114,3,114,79,8,11,79,12,117,22,75,57,216,115,16,141,12,197,9,202,197,216,243,165,72,139,117,8,64,57,216,15,130,210,36,169,131,251,2,15,130,179,23,144,93,232,9,34,152,64,137,243,247,46,184,4,73,141,4,198,139,48,83,32,224,120,4,137,93,224,137,200,137,69,228,139,19,200,42,216,67,4,57,242,137,194,25,250,15,66,248,240,23,248,3,66,117,236,15,66,193,65,131,195,24,57,77,232,117,217,141,4,64,50,1,138,28,50,1,201,141,69,164,137,199,137,222,243,165,64,1,46,137,223,139,93,212,14,152,223,137,198,79,1,120,4,139,77,220,141,65,1,139,93,224,131,195,24,59,69,232,117,128,141,70,120,224,49,219,49,201,65,141,20,91,139,68,214,16,36,39,200,18,61,3,16,0,0,116,11,61,36,4,153,15,133,147,84,1,161,214,139,87,8,54,1,248,12,236,139,55,137,85,228,1,214,137,125,220,139,127,4,19,125,236,115,5,139,117,8,235,112,141,20,73,232,45,248,27,85,224,57,68,209,16,137,200,117,93,139,77,224,141,4,200,51,48,51,120,4,9,247,117,219,139,77,228,3,72,8,139,85,236,19,80,12,137,85,236,114,202,10,62,145,72,8,174,35,200,12,141,67,2,59,69,232,115,35,238,56,121,1,218,131,194,254,139,69,212,141,12,91,141,4,200,141,120,232,195,0,193,248,14,131,192,24,74,117,238,255,77,232,75,235,141,137,198,141,67,1,131,195,2,59,93,232,137,217,137,195,15,130,192,59,169,235,12,199,69,232,78,53,160,3,137,93,232,33,4,186,77,232,137,8,131,196,80,232,63,145,122,81,46,56,145,23,229,48,42,128,134,41,150,106,1,181,4,145,232,162,195,21,144,12,161,199,4,161,137,6,198,5,178,5,136,184,208,4,142,94,2,66,168,16,131,61,96,195,115,26,145,132,169,157,19,144,184,100,251,57,9,61,52,160,77,236,129,255,90,55,16,15,132,6,177,137,125,240,141,12,253,13,71,16,148,73,70,2,200,8,215,202,248,10,139,122,4,139,10,139,114,8,1,206,139,90,12,17,251,137,93,228,115,8,139,125,240,233,64,72,21,155,122,16,1,173,12,248,11,117,232,186,14,4,0,0,102,139,18,15,191,210,15,183,242,193,230,4,129,250,0,160,255,255,186,236,70,82,15,77,242,57,241,131,223,0,114,96,128,17,141,20,110,24,139,140,82,180,164,190,255,255,15,248,2,121,13,27,180,82,228,145,5,0,114,55,129,125,232,1,0,16,0,139,117,228,131,222,0,139,117,236,15,130,209,160,1,50,250,0,129,201,0,0,240,255,1,74,8,131,82,12,255,199,66,228,2,136,2,109,6,10,185,134,79,9,15,191,209,15,183,202,193,225,134,3,25,202,186,0,84,163,232,57,242,186,230,49,178,25,250,114,101,57,241,162,6,31,249,115,90,64,20,144,139,21,115,1,128,169,53,145,20,213,119,52,121,9,251,137,247,139,180,82,232,145,5,0,41,254,139,188,82,236,145,5,0,25,223,1,206,137,20,128,51,7,10,137,21,161,235,9,139,13,122,1,128,232,48,152,240,71,137,135,1,0,215,176,70,131,192,24,59,53,168,1,168,137,241,15,130,100,141,22,142,0,158,6,146,232,185,56,65,136,184,242,72,152,49,201,5,33,4,225,15,146,193,137,202,247,218,49,202,117,84,185,214,4,176,200,1,200,49,246,185,1,3,136,191,215,6,136,187,7,2,241,86,86,106,1,86,81,86,80,86,81,87,83,232,88,249,8,50,44,86,87,83,232,105,80,130,50,2,140,0,47,67,153,104,96,78,111,2,162,168,226,255,255,248,6,138,242,195,34,17,139,13,154,137,8,59,2,129,1,33,146,106,0,240,6,135,137,15,3,129,30,35,8,169,158,144,117,81,13,16,161,77,12,129,193,51,8,147,210,0,136,5,187,247,247,223,9,247,117,60,93,8,177,116,58,129,225,0,240,226,57,129,86,52,175,87,86,82,81,87,150,7,1,17,165,4,179,129,127,17,152,80,104,50,216,43,138,12,146,7,136,5,160,7,128,28,3,148,251,225,85,9,50,139,93,24,139,125,20,120,225,137,248,9,216,139,69,8,116,65,184,0,16,145,52,169,80,83,87,232,0,132,48,152,20,137,198,210,10,248,2,116,55,139,77,12,57,207,139,69,16,25,195,15,67,249,137,203,224,49,162,86,232,175,16,183,67,144,85,16,207,13,153,12,235,6,147,67,136,11,200,38,128,236,66,129,35,8,132,27,34,5,92,131,12,1,17,160,0,96,131,55,34,129,139,1,153,80,81,81,223,43,10,133,27,134,39,1,128,163,70,129,49,33,133,46,33,136,16,245,28,248,4,195,137,240,247,101,8,141,52,7,15,144,197,8,221,8,205,139,69,8,212,23,140,242,45,33,26,116,24,185,209,50,81,81,82,80,232,47,113,130,189,1,138,81,11,40,145,235,224,92,46,148,106,0,151,8,134,167,1,6,128,128,137,59,160,77,20,139,125,117,42,152,3,69,8,211,9,25,130,163,1,88,136,87,15,41,144,190,185,201,29,128,50,30,185,117,228,25,215,137,125,216,14,10,128,104,62,161,135,1,0,0,112,4,152,141,72,255,209,64,200,69,204,141,4,64,141,4,197,216,131,4,145,69,208,190,41,136,212,211,53,131,25,58,185,220,131,125,200,0,15,136,202,28,216,125,208,139,93,204,131,63,1,15,133,140,42,43,248,2,71,240,139,79,244,139,119,248,1,198,139,87,252,17,202,114,122,251,64,152,117,236,57,235,28,248,5,212,137,240,137,85,232,25,208,115,19,139,85,224,57,85,240,137,200,25,240,23,54,168,206,114,7,235,82,84,54,160,206,137,208,43,95,42,216,232,25,241,59,69,228,27,77,216,114,59,128,6,152,69,236,43,94,12,136,196,9,9,169,117,232,27,117,216,8,1,170,86,80,232,236,184,11,11,200,77,196,41,193,25,214,137,202,59,118,64,249,3,236,137,117,240,27,117,192,115,54,75,131,199,232,133,219,15,143,95,87,34,163,220,132,69,24,13,53,129,170,29,129,174,12,209,212,15,133,49,255,255,255,104,105,82,147,5,208,132,223,255,255,137,215,137,203,41,211,199,38,254,5,117,240,25,242,49,192,49,201,65,80,80,81,81,255,117,16,82,83,86,87,93,10,145,232,222,253,50,160,44,128,125,24,169,58,137,61,44,1,48,53,220,145,5,0,191,11,168,235,14,255,117,228,185,14,137,72,111,61,143,12,250,3,2,138,191,73,26,170,137,248,131,196,52,232,1,48,118,78,1,0,233,122,139,128,2,3,136,233,38,23,133,185,50,129,65,6,208,16,131,193,16,137,77,212,49,210,185,119,11,144,49,255,194,2,161,15,132,202,0,22,9,128,74,41,149,77,228,188,52,200,212,137,125,220,131,62,1,15,133,10,34,248,8,139,86,240,139,94,244,139,78,248,1,209,139,126,252,17,223,114,118,137,85,208,57,85,29,10,240,137,93,204,25,218,139,93,220,15,147,69,224,57,203,193,65,137,250,9,10,89,224,136,85,243,137,250,137,77,224,117,6,38,136,224,5,8,160,93,228,59,93,222,39,248,29,27,85,204,15,147,194,137,93,228,57,203,139,93,232,25,251,15,146,198,32,214,138,93,243,8,243,132,246,117,6,139,125,232,139,77,228,139,85,216,8,218,137,85,216,57,51,0,17,216,224,137,77,220,131,198,24,72,15,133,101,63,21,48,125,220,246,69,216,1,40,145,69,12,105,1,145,236,15,16,68,137,184,82,12,200,199,15,67,248,133,246,15,69,248,93,47,160,120,4,129,193,15,6,147,137,8,185,50,145,194,4,170,2,129,66,44,131,213,12,144,190,240,111,5,224,126,240,139,78,244,139,94,248,1,251,139,86,121,2,137,35,131,66,120,15,8,57,249,139,125,12,27,125,240,15,147,193,57,93,8,139,125,12,25,215,15,146,194,32,202,128,250,1,116,19,148,200,117,197,49,210,74,137,208,235,10,172,56,179,194,195,139,6,49,210,41,38,134,89,37,250,19,139,125,28,139,117,24,138,77,44,139,85,12,137,240,9,248,15,148,192,34,77,48,8,193,139,10,137,77,224,178,1,15,133,243,120,72,128,219,73,250,0,240,137,69,232,17,250,137,85,236,115,20,128,125,40,0,192,29,144,104,225,224,1,136,223,219,16,176,201,116,122,139,125,36,247,20,248,0,112,16,49,210,133,255,116,4,57,62,117,97,137,85,240,169,1,9,70,194,217,211,139,126,252,137,69,228,17,199,115,8,251,40,248,4,36,235,65,139,69,16,57,208,139,85,20,27,85,228,15,146,192,57,93,2,74,192,25,250,15,147,194,59,93,232,174,11,248,36,146,195,8,211,8,195,128,125,44,0,117,5,246,195,1,116,43,128,243,1,139,85,240,8,218,246,195,1,139,125,36,117,85,131,198,24,73,117,145,138,77,48,137,200,52,1,138,85,40,32,194,2,1,184,75,132,201,116,56,141,125,135,32,128,230,14,159,255,117,32,254,12,1,146,232,53,252,4,136,106,187,30,145,11,243,102,17,145,139,7,212,38,136,178,245,36,181,210,128,226,1,137,208,172,4,145,73,83,216,8,150,63,220,188,2,136,56,224,54,232,77,16,139,93,8,137,222,1,206,139,69,12,19,181,42,161,208,15,130,225,186,19,129,202,26,144,137,85,173,30,129,187,24,128,2,28,168,93,196,141,60,91,70,42,248,15,28,250,139,68,250,4,139,76,250,8,137,222,137,77,200,1,206,137,125,216,139,84,250,12,137,193,17,209,115,11,25,1,161,93,196,233,65,60,69,176,204,57,117,220,137,202,42,71,160,207,137,85,224,226,1,152,69,239,137,177,2,176,8,137,199,27,125,12,222,32,128,134,53,248,6,216,141,20,218,15,146,69,216,137,195,114,44,57,247,137,200,27,69,224,114,35,117,17,224,240,74,139,93,196,57,211,115,16,141,4,82,46,55,147,52,193,57,11,153,75,233,224,98,3,248,1,212,139,117,228,57,254,137,93,188,137,216,25,200,15,146,192,229,28,248,12,139,93,196,138,101,239,117,33,32,224,116,29,41,254,139,69,188,25,200,3,117,200,19,69,204,137,58,151,32,136,114,172,32,138,233,20,54,192,228,138,77,216,136,200,52,1,14,23,184,117,212,57,242,139,125,12,128,13,136,224,54,44,224,226,8,194,246,194,1,116,95,32,225,128,249,179,1,176,117,113,139,117,200,3,58,61,176,204,17,248,43,117,212,237,24,224,113,8,139,117,224,25,240,137,65,12,129,250,218,9,192,115,106,141,60,82,139,81,16,88,10,240,84,249,16,139,85,240,66,139,69,208,137,68,249,4,215,72,224,4,249,139,69,212,43,69,220,137,68,249,8,43,34,82,116,249,12,235,28,139,85,200,3,85,85,168,41,242,27,69,224,68,25,248,2,81,8,137,65,12,139,85,240,67,137,85,240,57,211,15,130,128,228,73,169,117,240,129,254,255,38,63,128,183,1,145,118,11,64,8,224,235,57,49,246,137,202,139,69,24,141,60,118,205,10,48,68,249,16,139,69,12,113,152,137,28,249,137,44,237,68,249,12,137,84,249,8,70,139,69,192,137,48,210,74,145,217,77,234,10,145,45,218,190,6,129,16,69,138,154,149,16,161,198,64,13,1,245,42,128,154,55,152,141,117,212,105,75,162,86,232,28,9,105,75,168,70,36,80,86,0,232,8,161,26,232,228,174,221,19,248,11,102,129,126,36,78,86,117,114,15,183,69,216,193,224,4,15,183,117,244,1,198,106,6,104,163,78,209,51,10,32,56,120,16,133,192,117,88,102,129,126,6,0,2,118,87,139,70,40,15,183,240,193,232,12,131,224,240,1,198,106,4,104,100,83,42,20,246,8,42,136,60,228,43,145,230,176,4,20,160,128,61,136,113,172,20,201,13,104,65,80,1,0,232,100,231,26,20,128,114,4,160,93,195,104,35,123,47,161,19,104,142,82,163,47,145,253,78,30,67,138,0,152,7,145,83,217,111,62,134,91,64,136,117,77,62,171,48,86,232,152,213,148,23,153,116,35,141,9,32,32,80,86,232,153,20,130,201,63,136,50,31,31,136,181,33,32,145,233,131,31,49,144,141,141,46,32,240,137,1,137,65,8,137,65,4,102,199,65,2,3,0,130,29,104,4,131,225,12,15,183,192,81,80,106,113,232,67,173,130,211,66,137,235,31,52,146,54,255,90,29,137,221,21,52,240,193,233,12,131,225,240,15,183,240,1,206,128,61,80,29,12,161,117,39,15,183,122,32,144,185,40,97,51,242,200,15,66,200,81,86,104,40,194,5,0,232,157,7,127,64,8,5,41,176,1,139,118,20,141,189,190,75,144,106,50,108,21,10,149,29,129,231,74,233,131,231,14,15,183,192,87,80,106,12,232,195,175,104,21,136,49,206,29,146,133,208,254,66,136,4,32,72,184,248,47,119,19,80,104,178,244,18,138,41,73,29,144,233,177,110,31,144,69,224,69,4,145,141,212,104,21,130,254,32,152,18,104,32,239,71,137,2,112,29,24,4,233,138,39,152,195,141,189,43,33,145,104,142,102,62,27,87,232,22,127,160,119,2,141,133,29,76,103,137,93,236,67,83,255,117,16,80,232,231,6,153,1,10,15,153,31,37,232,42,153,1,129,193,25,152,69,224,208,197,58,153,56,232,43,232,70,136,8,98,15,248,20,195,139,69,186,137,123,32,137,67,28,176,1,136,3,136,67,44,137,115,48,102,199,67,52,69,0,139,69,236,131,192,2,137,69,228,83,55,10,245,49,123,4,67,8,198,0,47,139,67,8,64,255,117,236,139,77,16,81,80,232,106,125,137,93,14,59,152,67,12,184,172,37,152,141,157,112,12,31,35,87,83,232,96,31,64,115,2,139,117,224,102,199,131,30,168,0,69,102,137,179,23,9,152,141,133,122,184,33,17,117,232,199,11,32,74,136,216,224,1,136,227,96,1,188,83,80,106,32,232,99,174,95,34,33,23,15,183,133,88,144,104,207,48,40,138,212,219,28,168,235,65,15,183,133,136,77,240,102,57,240,137,241,118,94,15,183,201,81,80,104,255,82,40,137,178,181,28,168,12,141,69,214,102,19,72,129,180,56,235,131,224,14,15,183,201,80,81,106,33,232,9,174,33,1,163,87,139,117,240,203,55,16,33,244,20,130,203,55,10,21,12,150,137,248,8,67,168,195,15,183,193,106,253,9,162,80,232,192,235,19,1,20,69,232,128,128,26,16,0,73,128,49,56,16,232,200,73,128,124,54,209,16,139,70,28,11,70,32,15,132,18,116,39,200,232,137,193,131,225,15,137,77,192,85,21,44,69,196,141,69,214,151,251,1,49,246,15,183,192,137,69,200,15,183,193,137,69,204,49,219,27,78,155,199,69,214,160,57,136,218,102,79,145,192,102,217,48,253,1,196,102,137,69,222,255,117,200,255,117,204,106,34,232,63,173,4,3,137,9,130,2,201,69,218,102,59,69,224,15,135,237,114,17,136,3,107,62,240,81,28,139,73,32,57,250,137,207,131,223,0,15,130,128,52,128,55,72,194,57,211,25,206,15,130,205,0,205,71,226,78,16,1,217,80,255,117,232,81,232,147,4,89,24,248,3,183,85,218,1,211,102,59,85,228,15,147,193,10,77,236,139,70,28,183,50,195,78,32,116,4,137,223,235,48,190,78,148,137,223,231,45,176,203,115,28,82,104,96,46,4,145,54,227,103,21,0,122,8,65,122,217,178,1,137,85,236,49,246,137,251,57,199,125,41,128,154,31,136,33,92,43,135,157,1,12,147,108,172,142,43,144,117,70,129,13,185,208,255,117,232,232,132,242,109,7,128,140,15,128,227,53,144,104,34,125,4,249,2,32,86,104,14,88,1,0,106,1,232,220,212,255,255,104,126,86,52,52,138,11,145,4,138,25,145,4,8,194,26,147,14,82,217,48,160,86,184,254,125,242,14,123,9,8,102,199,0,52,18,102,139,16,184,254,125,16,0,102,139,48,176,1,102,57,242,117,30,31,82,16,247,210,102,137,16,102,139,0,186,31,65,18,102,57,208,15,149,192,186,61,147,137,10,119,16,128,68,61,184,179,1,232,165,255,255,255,80,60,128,178,53,154,141,117,208,185,5,148,99,3,185,5,145,1,36,185,5,161,21,232,43,169,116,2,19,232,117,48,128,157,85,248,11,185,79,195,0,0,228,100,131,233,1,15,146,194,168,2,116,4,132,210,116,240,168,2,15,133,194,89,12,31,173,230,100,33,14,136,161,122,12,15,208,33,5,18,1,117,33,138,1,209,38,9,186,29,89,96,137,193,228,100,131,234,1,15,146,196,66,8,228,66,49,117,99,176,209,230,100,33,7,29,8,71,70,128,201,2,137,200,230,96,127,12,39,117,38,176,174,156,14,168,117,9,232,146,254,19,1,248,1,117,19,228,146,168,2,117,6,36,252,12,2,230,146,232,125,170,35,129,228,38,143,40,221,51,1,136,16,18,36,201,15,162,131,248,21,114,38,184,21,140,53,161,15,162,137,198,228,51,128,206,35,152,194,8,194,53,71,192,192,8,208,60,1,15,133,206,237,86,136,61,215,75,144,137,61,215,75,211,228,97,137,193,136,69,243,128,225,252,98,18,131,86,81,168,49,192,136,77,242,131,25,248,30,200,230,97,176,176,230,67,176,156,230,66,176,46,230,66,228,97,12,1,230,97,15,49,137,211,137,199,228,97,168,32,116,250,15,49,57,199,137,222,25,214,115,39,41,248,253,11,176,232,137,222,131,198,255,32,55,249,5,207,131,215,255,57,198,25,215,15,67,202,137,77,236,138,77,242,15,67,216,191,18,224,228,64,131,248,3,117,161,138,69,243,230,97,202,18,120,4,200,139,117,236,9,240,116,45,137,200,185,222,52,18,0,247,225,105,206,8,242,1,209,106,0,104,156,46,0,0,81,80,232,72,170,139,26,8,21,187,136,163,145,76,131,190,83,128,230,38,153,227,137,215,204,60,39,82,80,232,32,40,6,145,57,243,182,3,136,19,71,19,140,203,149,49,160,64,141,69,204,139,83,132,242,60,136,12,231,27,216,232,255,255,141,93,180,199,69,240,32,232,60,4,145,232,24,67,4,192,228,80,65,77,83,137,93,220,22,71,178,80,106,21,232,164,166,167,80,235,69,212,1,117,50,137,240,137,250,141,191,100,219,5,19,128,153,20,250,3,131,125,236,0,116,22,137,198,70,131,194,24,137,215,117,176,104,73,107,64,81,121,209,255,255,137,198,70,137,53,96,189,140,64,58,50,161,86,139,69,20,118,63,248,1,8,186,129,87,1,0,131,254,30,119,7,139,20,181,124,88,106,75,154,82,104,170,109,17,176,59,209,255,255,184,128,43,34,120,12,136,120,89,1,0,102,137,140,0,108,220,5,0,199,132,0,110,220,5,0,24,0,0,142,193,233,16,22,248,6,114,220,5,0,131,192,4,117,215,85,137,229,15,1,29,181,240,0,0,93,195,80,90,144,86,87,0,90,120,7,137,199,139,116,36,16,139,76,36,20,243,164,95,94,195,87,139,84,36,8,137,215,26,87,139,76,36,16,243,170,137,208,95,195,42,5,120,7,57,247,119,4,243,164,235,12,141,124,15,255,141,116,14,255,253,243,164,252,95,94,39,29,124,36,12,79,224,166,116,11,138,71,255,42,70,255,15,190,192,77,52,16,95,94,119,6,3,152,252,49,192,159,33,76,106,0,232,7,255,255,255,144,144,16,39,1,232,247,254,16,1,31,2,232,231,16,2,31,3,232,215,32,2,31,4,232,199,48,2,31,5,232,183,64,2,31,6,232,167,80,2,26,7,232,151,96,9,88,127,24,8,232,136,111,6,128,31,9,232,119,32,1,24,10,232,104,32,5,48,31,11,232,88,16,2,31,12,232,72,32,2,31,13,232,56,48,2,31,14,232,40,96,3,31,15,232,23,224,2,31,16,232,7,144,1,39,17,232,248,253,144,2,144,18,232,1,28,134,32,1,31,19,232,215,16,2,31,20,232,199,32,2,31,21,232,183,48,2,31,22,232,167,64,2,31,23,232,151,80,2,31,24,232,135,96,2,31,25,232,119,112,2,31,26,232,103,128,2,31,27,232,87,144,2,31,28,232,71,160,2,24,29,232,55,176,132,96,1,31,30,232,40,208,3,162,31,232,23,253,203,42,136,0,68,22,136,0,127,21,128,149,81,128,220,77,128,98,3,128,145,73,160,48,0,0,0,204,73,123,144,67,68,48,48,49,0,65,116,116,101,109,112,116,101,100,32,118,111,108,117,109,101,95,114,101,97,100,40,41,32,111,110,32,112,120,101,0,112,109,109,58,32,73,110,116,101,103,101,114,32,111,118,101,114,102,108,111,119,32,105,110,32,109,101,109,111,114,121,32,114,97,110,103,101,32,99,97,108,99,117,108,97,116,105,111,110,0,116,102,116,112,58,32,83,101,114,118,101,114,32,114,101,116,117,114,110,101,100,32,122,101,114,111,32,98,121,116,101,115,32,98,101,102,111,114,101,32,116,114,97,110,115,102,101,114,32,99,111,109,112,108,101,116,101,0,78,77,73,0,83,101,99,117,114,105,116,121,0,79,108,58,0,109,101,110,117,0,77,110,125,20,109,97,112,32,101,120,104,97,117,115,116,101,100,46,0,101,120,116,95,109,101,109,95,97,108,108,111,99,58,32,99,111,117,110,116,165,120,16,115,32,119,104,101,110,32,97,108,105,103,110,105,110,103,0,80,88,69,78,86,43,0,37,115,32,101,120,99,101,112,172,96,32,97,116,32,37,120,46,32,69,114,114,111,136,124,11,100,101,58,32,37,120,0,83,101,103,109,101,110,116,32,110,111,116,32,112,114,101,115,101,110,116,129,1,106,1,232,133,13,1,80,46,0,112,120,101,32,118,101,114,115,82,120,3,116,111,111,32,111,108,100,0,73,110,118,97,108,105,100,32,111,112,87,131,21,1,65,70,105,108,101,110,97,109,101,38,121,35,108,111,110,103,32,40,109,97,120,32,49,50,55,32,99,104,97,114,115,41,10,0,84,111,111,32,109,97,110,121,32,69,56,50,48,32,101,110,116,114,105,101,115,33,0,67,111,117,108,100,145,248,27,101,110,97,98,108,101,32,65,50,48,32,108,105,110,101,0,83,73,77,68,0,0,66,114,101,97,107,112,111,105,110,116,0,102,97,116,51,50,58,32,99,108,37,1,8,114,89,152,105,110,32,213,1,241,32,102,97,105,108,101,100,32,40,99,111,114,114,117,243,1,249,12,102,105,108,101,115,121,115,116,101,109,63,41,0,71,101,110,101,114,97,108,32,112,114,111,116,101,99,32,1,224,102,97,117,108,116,0,68,105,115,107,32,101,36,1,129,46,1,168,68,114,105,118,101,40,1,76,73,83,79,57,54,54,48,58,32,237,216,114,111,111,116,32,100,105,114,101,99,116,45,1,232,115,105,122,101,0,69,70,73,32,80,65,82,84,128,1,186,32,105,110,115,116,97,108,41,2,51,32,99,104,101,99,107,149,128,68,1,255,12,58,32,83,117,99,99,101,115,115,102,117,108,108,121,32,105,110,105,116,105,97,108,105,122,101,100,10,85,2,3,113,105,115,32,115,101,110,100,105,110,103,32,116,104,101,197,128,146,2,120,4,115,109,97,108,108,101,114,32,112,97,99,107,101,116,115,32,40,105,116,40,162,116,32,37,100,122,2,249,7,41,44,32,100,111,119,110,108,111,97,100,32,109,105,103,104,116,32,116,97,107,101,137,1,85,101,114,46,10,0,70,65,84,51,50,214,132,47,1,144,116,111,62,1,7,221,5,21,0,70,30,1,80,127,16,115,116,97,103,101,32,51,46,0,47,98,111,111,116,47,108,105,109,105,110,101,45,98,105,111,115,46,115,121,115,0,16,4,128,27,1,0,180,24,99,111,114,80,177,46,10,0,105,115,111,76,1,130,170,1,105,98,101,121,111,110,100,32,101,110,100,32,111,102,225,249,18,0,27,91,51,49,109,80,65,78,73,67,27,91,51,55,59,49,109,27,91,48,109,58,32,0,65,32,110,111,110,45,117,115,22,2,141,109,39,3,129,59,2,136,121,43,1,75,105,110,115,105,100,101,32,97,32,36,138,115,220,1,140,46,84,2,0,214,32,101,116,101,114,177,17,32,98,229,128,225,1,9,0,108,248,2,58,32,0,48,120,0,80,114,101,115,115,32,97,32,107,101,121,15,1,130,213,3,0,251,168,37,115,46,0,65,97,3,128,48,3,133,31,4,131,238,2,169,67,108,111,115,101,224,1,148,117,114,2,3,134,54,1,248,10,103,101,116,32,68,72,67,80,32,99,97,99,104,101,100,32,105,110,102,111,0,68,105,118,105,71,3,121,15,0,48,120,48,0,83,116,97,99,107,116,114,97,99,101,58,10,0,32,32,91,37,112,93,10,0,72,105,103,104,231,134,141,3,184,111,114,58,32,79,117,116,42,1,2,25,130,235,3,121,1,32,115,116,114,117,99,116,117,114,101,32,115,105,103,110,97,10,133,251,2,1,164,134,186,2,200,77,84,85,32,40,37,117,41,44,155,3,130,74,2,250,9,32,102,111,114,32,84,70,84,80,32,104,101,97,100,101,114,115,10,0,66,111,117,110,100,243,4,129,69,4,176,101,100,101,100,0,80,249,1,129,41,3,135,59,2,12,132,90,5,120,4,32,100,101,115,99,114,105,112,116,111,114,0,63,63,63,0,101,100,105,11,239,70,65,84,0,46,47,0,10,0,78,84,70,83,104,4,7,132,65,1,233,46,0,33,80,88,69,0,68,101,118,105,99,101,182,1,168,97,118,97,105,108,13,4,133,109,4,202,84,83,83,0,10,33,33,32,83,141,2,128,26,3,2,43,8,102,185,8,33,27,255,1,72,97,118,101,32,121,111,117,32,99,111,112,105,101,100,32,153,2,5,144,116,111,84,3,129,237,2,33,44,32,47,98,7,131,206,2,34,44,32,111,114,19,3,17,0,80,131,17,3,128,166,4,128,171,2,152,111,110,101,178,2,128,151,3,168,112,97,114,116,105,18,6,136,115,76,6,148,116,104,93,2,1,193,167,63,10,10,0,37,3,5,131,103,2,226,67,84,82,76,43,65,76,84,43,68,69,76,125,3,0,56,138,46,15,2,146,45,115,156,5,130,154,4,134,124,2,130,77,4,168,0,77,97,99,104,199,2,1,14,4,97,7,104,6,159,46,46,47,104,1,3,2,166,152,100,105,115,73,6,141,119,29,2,134,173,2,162,111,112,101,110,104,4,144,37,120,6,1,155,98,97,100,103,4,129,229,4,135,244,6,5,152,113,117,101,161,6,7,35,1,155,32,37,117,51,2,169,115,32,111,117,114,113,2,159,37,117,10,47,4,2,135,54,4,22,253,4,98,117,105,108,100,32,73,68,32,109,105,115,109,97,116,99,104,46,10,133,5,133,145,2,199,32,109,97,120,105,109,117,109,118,2,7,185,32,115,101,97,114,99,104,244,1,145,116,0,120,3,65,95,98,108,111,99,107,58,32,7,1,169,134,198,3,136,102,139,4,157,58,32,97,33,8,138,111,101,3,136,98,6,3,137,115,169,4,146,0,69,162,4,129,166,3,200,46,32,0,67,111,110,118,101,110,7,8,148,97,108,166,3,134,203,2,132,236,5,172,68,111,117,98,108,52,3,233,120,56,55,0,86,105,114,116,117,97,108,105,115,66,8,132,12,5,134,48,7,129,66,1,134,114,3,255,1,48,49,50,51,52,53,54,55,56,57,97,98,99,100,101,102,30,6,2,130,243,5,136,109,98,8,248,0,100,97,116,97,32,116,104,97,110,32,101,120,112,101,99,246,3,0,91,135,221,5,7,129,9,7,2,48,131,105,4,198,32,60,37,115,43,37,112,62,96,1,223,32,110,111,32,112,114,105,109,97,114,121,208,3,8,159,33,112,120,103,4,17,136,82,127,7,132,10,5,168,68,101,98,117,103,89,9,200,95,102,114,101,101,58,32,85,110,164,8,128,37,9,128,193,7,128,180,7,151,37,112,219,8,3,137,95,218,8,136,101,141,1,133,77,1,135,173,1,4,227,85,110,107,110,111,119,110,0,88,70,69,82,186,1,128,14,5,129,180,2,144,114,101,2,6,240,115,32,97,98,111,118,101,32,52,32,71,105,66,59,179,9,128,45,7,193,109,117,115,116,32,117,115,101,198,6,195,95,97,100,100,114,95,54,52,214,3,150,108,121,139,1,161,80,97,116,104,170,9,144,111,110,83,7,131,203,2,133,108,2,239,108,101,110,103,116,104,0,40,110,117,108,108,41,92,5,4,40,73,80,118,52,32,90,201,101,115,115,58,32,34,37,115,34,157,10,232,4,0,8,0,16,1,2,4,8,16,32,64,128,173,10,128,165,10,32,46,0,0,46,4,8,47,8,74,47,0,0,201,42,1,0,26,44,4,11,57,8,21,136,44,20,1,32,200,71,82,1,0,44,87,1,0,69,203,59,122,30,79,1,0,82,78,1,0,230,82,1,0,17,79,1,0,105,83,1,0,45,86,1,0,48,83,1,0,126,83,1,0,205,78,1,0,99,84,1,0,196,79,1,0,251,82,24,121,2,58,86,1,0,119,84,1,0,135,84,1,0,122,79,1,0,62,48,7,4,23,249,116,73,78,1,0,144,75,1,0,160,75,1,0,176,75,1,0,192,75,1,0,208,75,1,0,224,75,1,0,240,75,1,0,0,76,1,0,16,76,1,0,32,76,1,0,48,76,1,0,64,76,1,0,80,76,1,0,96,76,1,0,112,76,1,0,128,76,1,0,144,76,1,0,160,76,1,0,176,76,1,0,192,76,1,0,208,76,1,0,224,76,1,0,240,76,1,0,0,77,1,0,16,77,1,0,32,77,1,0,48,77,1,0,64,77,1,0,80,77,1,0,96,77,1,0,112,77,1,0,128,77,1,224,11,160,20,0,0,0,55,102,121,36,71,78,85,0,56,115,35,197,229,163,121,250,90,240,149,147,16,152,134,231,165,206,13,143,64,240,0,0,115,112,105,110,117,112,0,26,244,0,0,95,95,117,100,105,118,100,105,51,0,37,245,14,24,109,111,100,14,193,42,246,0,0,100,105,115,107,1,12,145,95,115,214,5,35,115,0,14,247,22,249,2,99,114,101,97,116,101,95,105,110,100,101,120,0,36,253,0,0,97,8,169,0,200,254,0,0,252,8,144,51,95,177,9,162,0,183,255,0,130,10,100,95,103,101,116,95,108,97,98,101,108,0,216,20,1,35,99,95,99,111,110,116,101,120,116,0,95,2,1,43,128,95,5,31,0,75,4,15,1,187,95,105,110,0,238,8,1,166,4,131,205,10,137,95,205,10,28,0,231,9,57,129,132,4,20,41,10,72,136,99,114,8,40,0,89,10,1,0,196,7,54,4,23,112,11,23,4,126,0,102,114,111,109,95,109,97,112,0,189,12,1,0,102,115,177,22,0,198,17,48,103,117,105,100,0,205,16,1,165,42,111,13,1,0,102,103,8,189,11,1,129,156,51,14,1,180,4,2,203,161,37,19,1,0,80,3,128,189,4,30,0,103,20,31,136,110,179,12,130,58,1,21,3,21,23,2,200,21,121,22,40,3,202,9,169,18,144,112,114,215,11,122,18,186,22,1,0,116,111,117,112,112,101,114,0,206,22,1,0,97,98,115,0,221,22,1,0,115,116,114,99,112,121,0,0,23,11,35,109,112,0,54,11,24,97,115,101,15,10,186,15,8,110,27,11,250,12,4,28,17,107,24,43,248,14,108,101,110,0,128,24,1,0,105,110,101,116,95,112,116,111,110,0,234,24,1,0,98,99,100,95,116,111,95,84,12,76,3,25,1,0,100,105,103,105,116,17,17,59,25,100,200,116,111,117,105,0,65,26,1,0,43,1,254,13,97,98,115,111,108,117,116,101,95,112,97,116,104,0,13,28,1,0,112,97,110,105,99,0,248,28,1,0,92,14,206,100,0,178,31,1,0,103,112,116,95,1,16,73,32,249,137,95,46,4,97,95,109,98,114,0,253,33,1,0,109,98,114,34,40,105,100,0,61,34,75,9,114,50,28,0,197,40,78,1,65,18,98,121,68,23,57,41,23,5,146,102,115,205,1,15,137,26,6,63,99,111,111,114,100,0,201,24,6,128,33,8,138,95,253,10,162,244,41,1,0,120,1,42,13,42,1,0,118,11,16,164,46,21,59,110,95,115,116,114,0,251,12,34,105,0,178,47,10,42,117,105,0,75,48,21,35,120,0,189,48,64,149,95,115,198,10,206,0,95,49,1,0,99,111,110,118,180,14,219,0,116,50,1,0,109,101,109,109,97,112,234,5,129,80,15,161,0,176,50,1,33,6,144,115,97,5,13,155,115,101,95,9,14,154,0,246,54,108,1,2,52,152,0,39,55,181,1,13,105,16,146,108,57,139,1,28,114,97,119,35,157,129,57,1,108,6,136,95,146,13,38,95,116,0,150,20,34,101,0,18,58,13,18,114,101,147,153,134,58,1,89,15,6,165,15,162,18,5,4,72,8,189,25,135,169,6,9,31,0,34,59,26,5,171,116,121,112,101,95,233,6,23,0,61,31,18,144,95,109,51,15,160,18,61,1,0,25,1,129,6,2,129,30,12,18,43,62,183,129,222,9,1,81,159,0,148,62,64,1,9,128,61,4,18,206,63,45,155,110,101,119,113,3,152,224,65,1,171,15,178,95,98,105,110,100,95,195,7,18,0,245,20,130,188,4,153,186,66,1,187,12,130,197,3,58,82,71,1,0,97,50,48,110,19,0,158,14,130,127,15,152,0,224,72,155,4,160,108,105,98,114,21,5,179,116,115,99,0,21,74,139,1,202,101,56,50,48,0,165,74,1,0,103,16,20,0,210,25,160,105,100,116,0,101,64,128,25,109,140,1,51,109,143,16,0,108,3,1,30,11,155,8,12,147,16,11,207,16,10,207,42,136,155,87,91,0,32,131,104,109,143,137,142,109,7,0,0};
static inline R4SdkUpdateSlot R4SdkUpdateStoragelimine_constant_payload(void) { return (R4SdkUpdateSlot){.ptr=(void *)R4SdkUpdateStoragelimine_CONST_payload,.length=22301,.flags=1u}; }
static const uint8_t R4SdkUpdateStoragelimine_CONST_bios_system_sha256[] = {99,51,50,53,100,98,48,101,54,56,99,48,57,53,52,98,99,49,99,54,98,51,50,49,52,56,102,101,51,49,49,101,57,101,54,97,57,100,101,56,57,99,52,55,54,50,49,51,57,55,99,102,52,102,49,55,97,55,48,55,99,52,51,100,0};
static inline R4SdkUpdateSlot R4SdkUpdateStoragelimine_constant_bios_system_sha256(void) { return (R4SdkUpdateSlot){.ptr=(void *)R4SdkUpdateStoragelimine_CONST_bios_system_sha256,.length=64,.flags=1u}; }
static const uint8_t R4SdkUpdateNative_version_info_CONST_release_field[] = {82,69,76,69,65,83,69,95,86,69,82,83,73,79,78,61,0};
static inline R4SdkUpdateSlot R4SdkUpdateNative_version_info_constant_release_field(void) { return (R4SdkUpdateSlot){.ptr=(void *)R4SdkUpdateNative_version_info_CONST_release_field,.length=16,.flags=1u}; }
static const uint8_t R4SdkUpdateNative_version_info_CONST_release_file_path[] = {47,82,52,79,83,47,67,79,78,70,73,71,47,86,69,82,83,73,79,78,46,82,52,83,0};
static inline R4SdkUpdateSlot R4SdkUpdateNative_version_info_constant_release_file_path(void) { return (R4SdkUpdateSlot){.ptr=(void *)R4SdkUpdateNative_version_info_CONST_release_file_path,.length=24,.flags=1u}; }
static const uint8_t R4SdkUpdateNative_version_info_CONST_inventory_file_path[] = {47,82,52,79,83,47,67,79,78,70,73,71,47,77,79,68,85,76,69,83,46,74,83,79,78,0};
static inline R4SdkUpdateSlot R4SdkUpdateNative_version_info_constant_inventory_file_path(void) { return (R4SdkUpdateSlot){.ptr=(void *)R4SdkUpdateNative_version_info_CONST_inventory_file_path,.length=25,.flags=1u}; }
#define R4SdkUpdateNative_r4u_manifest_manifest_version (2)
static const uint8_t R4SdkUpdateNative_r4u_manifest_CONST_header_magic[] = {82,52,85,50,0};
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_constant_header_magic(void) { return (R4SdkUpdateSlot){.ptr=(void *)R4SdkUpdateNative_r4u_manifest_CONST_header_magic,.length=4,.flags=1u}; }
#define R4SdkUpdateNative_r4u_manifest_header_version (2)
#define R4SdkUpdateNative_r4u_manifest_header_size (64)
#define R4SdkUpdateNative_r4u_manifest_max_package_payloads (32)
#define R4SdkUpdateNative_r4u_manifest_manifest_max_bytes (32768)
#define R4SdkUpdateNative_r4u_manifest_title_max_bytes (96)
#define R4SdkUpdateNative_r4u_manifest_description_max_bytes (2048)
#define R4SdkUpdateNative_r4u_manifest_package_name_max_bytes (48)
#define R4SdkUpdateNative_r4u_manifest_component_name_max_bytes (48)
#define R4SdkUpdateNative_r4u_manifest_version_max_bytes (24)
#define R4SdkUpdateNative_r4u_artifact_name_capacity (49)
#define R4SdkUpdateNative_r4u_artifact_version_capacity (25)
#define R4SdkUpdateInventory_max_entries (192)
#define R4SdkUpdateInventory_max_bytes (65536)
#define R4SdkUpdateInventory_max_guest_formats (16)
#define R4SdkUpdateInventory_max_guest_extensions (32)
#define R4SdkUpdateInventory_max_guest_features (32)
#define R4SdkUpdateInventory_max_guest_probe_bytes (262144)
#define R4SdkUpdateInventory_subsystem_display_name_max_bytes (96)
#define R4SdkUpdateRecovery_journal_max (196608)
#define R4SdkUpdateRecovery_max_package_payloads (32)
#define R4SdkUpdateRecovery_max_payloads (34)
#define R4SdkUpdateRecovery_max_path (1024)
#define R4SdkUpdateRecovery_max_version (32)
#define R4SdkUpdateRecovery_checksum_seed (2166136261)
#define R4SdkUpdateBatch_journal_version (1)
#define R4SdkUpdateBatch_max_packages (16)
#define R4SdkUpdateBatch_max_components (32)
#define R4SdkUpdateBatch_max_requirements (32)
#define R4SdkUpdateBatch_journal_max (65536)
#define R4SdkUpdateBatch_max_reason (64)
#define R4SdkUpdateCatalog_max_catalog_bytes (524288)
#define R4SdkUpdateCatalog_max_releases (32)
#define R4SdkUpdateCatalog_max_packages (64)
#define R4SdkUpdateCatalog_max_profile_components (192)
#define R4SdkUpdateCatalog_max_package_components (192)
#define R4SdkUpdateCatalog_max_requirements (512)
#define R4SdkUpdateCatalog_max_download_url_bytes (1024)
#define R4SdkUpdateCatalog_max_filename_bytes (128)
#include "r4os/data_helpers.h"
#define R4SdkUpdateBlockPhase_preflight 0u
#define R4SdkUpdateBlockPhase_invalidate 1u
#define R4SdkUpdateBlockPhase_erase 2u
#define R4SdkUpdateBlockPhase_metadata 3u
#define R4SdkUpdateBlockPhase_backup 4u
#define R4SdkUpdateBlockPhase_primary 5u
#define R4SdkUpdateBlockPhase_flush 6u
#define R4SdkUpdateBlockPhase_verify 7u
#define R4SdkUpdateBlockPhase_complete 8u
#define R4SdkUpdatePartitionKind_none 0u
#define R4SdkUpdatePartitionKind_mbr 1u
#define R4SdkUpdatePartitionKind_gpt 2u
#define R4SdkUpdateStoragefat32_update_Backing_maximum_bytes (8589934592)
#define R4SdkUpdateNtfsFormatAttrType_standard_information 16u
#define R4SdkUpdateNtfsFormatAttrType_attribute_list 32u
#define R4SdkUpdateNtfsFormatAttrType_file_name 48u
#define R4SdkUpdateNtfsFormatAttrType_object_id 64u
#define R4SdkUpdateNtfsFormatAttrType_security_descriptor 80u
#define R4SdkUpdateNtfsFormatAttrType_volume_name 96u
#define R4SdkUpdateNtfsFormatAttrType_volume_information 112u
#define R4SdkUpdateNtfsFormatAttrType_data 128u
#define R4SdkUpdateNtfsFormatAttrType_index_root 144u
#define R4SdkUpdateNtfsFormatAttrType_index_allocation 160u
#define R4SdkUpdateNtfsFormatAttrType_bitmap 176u
#define R4SdkUpdateNtfsFormatAttrType_reparse_point 192u
#define R4SdkUpdateNtfsFormatAttrType_ea_information 208u
#define R4SdkUpdateNtfsFormatAttrType_ea 224u
#define R4SdkUpdateNtfsFormatAttrType_logged_utility_stream 256u
#define R4SdkUpdateNtfsFormatFixupError_ok 0u
#define R4SdkUpdateNtfsFormatFixupError_too_short 1u
#define R4SdkUpdateNtfsFormatFixupError_bad_offsets 2u
#define R4SdkUpdateNtfsFormatFixupError_usn_mismatch 3u
#define R4SdkUpdateNative_math_Order_gt 0u
#define R4SdkUpdateNative_math_Order_lt 1u
#define R4SdkUpdateNative_math_Order_eq 2u
#define R4SdkUpdateStoragegpt_repair_Status_healthy 0u
#define R4SdkUpdateStoragegpt_repair_Status_primary_damaged 1u
#define R4SdkUpdateStoragegpt_repair_Status_backup_damaged 2u
#define R4SdkUpdateStoragegpt_repair_Status_both_invalid 3u
#define R4SdkUpdateStoragegpt_repair_Status_conflict 4u
#define R4SdkUpdateStoragegpt_repair_Status_protective_mbr_invalid 5u
#define R4SdkUpdateStorageinstallation_Role_BIOSBOOT 0u
#define R4SdkUpdateStorageinstallation_Role_BOOT 1u
#define R4SdkUpdateStorageinstallation_Role_SYSTEM 2u
#define R4SdkUpdateStorageinstallation_Role_RECOVERY 3u
#define R4SdkUpdateStorageinstallation_Role_DATA 4u
#define R4SdkUpdateStorageinstallation_Medium_local 0u
#define R4SdkUpdateStorageinstallation_Medium_usb 1u
#define R4SdkUpdateInventoryModuleRole_subsystem 0u
#define R4SdkUpdateInventoryProfile_slim 0u
#define R4SdkUpdateInventoryProfile_full 1u
#define R4SdkUpdateInventoryProfile_test_image 2u
#define R4SdkUpdateRecoveryJournalPhase_prepare 0u
#define R4SdkUpdateRecoveryJournalPhase_stage 1u
#define R4SdkUpdateRecoveryJournalPhase_commit 2u
#define R4SdkUpdateRecoveryJournalPhase_verify 3u
#define R4SdkUpdateRecoveryJournalPhase_inventory 4u
#define R4SdkUpdateRecoveryJournalPhase_applied 5u
#define R4SdkUpdateRecoveryJournalPhase_post_boot 6u
#define R4SdkUpdateRecoveryJournalPhase_cleanup 7u
#define R4SdkUpdateRecoveryJournalPhase_rollback 8u
#define R4SdkUpdateRecoveryJournalPhase_rolled_back 9u
#define R4SdkUpdateRecoveryPathState_match 0u
#define R4SdkUpdateRecoveryPathState_not_found 1u
#define R4SdkUpdateRecoveryPathState_other 2u
#define R4SdkUpdateRecoveryPathState_io 3u
#define R4SdkUpdateRecoveryPresenceState_file 0u
#define R4SdkUpdateRecoveryPresenceState_other 1u
#define R4SdkUpdateRecoveryPresenceState_not_found 2u
#define R4SdkUpdateRecoveryPresenceState_io 3u
#define R4SdkUpdateRecoveryMutationStatus_ok 0u
#define R4SdkUpdateRecoveryMutationStatus_conflict 1u
#define R4SdkUpdateRecoveryMutationStatus_io 2u
#define R4SdkUpdateRecoveryReplayStatus_ok 0u
#define R4SdkUpdateRecoveryReplayStatus_invalid 1u
#define R4SdkUpdateRecoveryReplayStatus_conflict 2u
#define R4SdkUpdateRecoveryReplayStatus_io 3u
#define R4SdkUpdateNative__typeInfo_system_update_recovery_SlotSelection____union__tag_type___selected 0u
#define R4SdkUpdateNative__typeInfo_system_update_recovery_SlotSelection____union__tag_type___not_found 1u
#define R4SdkUpdateNative__typeInfo_system_update_recovery_SlotSelection____union__tag_type___invalid 2u
#define R4SdkUpdateRecoveryJournalComponentKind_kernel 0u
#define R4SdkUpdateRecoveryJournalComponentKind_r4x 1u
#define R4SdkUpdateRecoveryJournalComponentKind_r4l 2u
#define R4SdkUpdateRecoveryJournalComponentKind_r4d 3u
#define R4SdkUpdateRecoveryJournalComponentKind_r4p 4u
#define R4SdkUpdateBatchPhase_staged 0u
#define R4SdkUpdateBatchPhase_verifying 1u
#define R4SdkUpdateBatchPhase_staging 2u
#define R4SdkUpdateBatchPhase_committing 3u
#define R4SdkUpdateBatchPhase_pending_restart 4u
#define R4SdkUpdateBatchPhase_installed 5u
#define R4SdkUpdateBatchPhase_failed 6u
#define R4SdkUpdateBatchPhase_rolling_back 7u
#define R4SdkUpdateBatchPhase_rolled_back 8u
#define R4SdkUpdateNative__typeInfo_system_update_batch_SlotSelection____union__tag_type___selected 0u
#define R4SdkUpdateNative__typeInfo_system_update_batch_SlotSelection____union__tag_type___not_found 1u
#define R4SdkUpdateNative__typeInfo_system_update_batch_SlotSelection____union__tag_type___invalid 2u
#define R4SdkUpdateCallbackKind_block_read 0u
#define R4SdkUpdateCallbackKind_block_write 1u
#define R4SdkUpdateCallbackKind_block_flush 2u
#define R4SdkUpdateCallbackKind_block_continue 3u
#define R4SdkUpdateCallbackKind_source_read 4u
#define R4SdkUpdateCallbackKind_journal_persist 5u
#define R4SdkUpdateCallbackKind_payload_rollback 6u
#define R4SdkUpdateCallbackKind_payload_commit 7u
#define R4SdkUpdateCallbackKind_payload_cleanup 8u
#define R4SdkUpdateCallbackKind_path_state 9u
#define R4SdkUpdateCallbackKind_path_presence 10u
#define R4SdkUpdateCallbackKind_archive_unreferenced 11u
#define R4SdkUpdateCallbackKind_archive_copy 12u
#define R4SdkUpdateCallbackKind_archive_verify 13u
#define R4SdkUpdateCallbackKind_archive_remove 14u
#define R4SdkUpdateNtfsFormatBootSector_ParseError_ok 0u
#define R4SdkUpdateNtfsFormatBootSector_ParseError_too_short 1u
#define R4SdkUpdateNtfsFormatBootSector_ParseError_bad_oem 2u
#define R4SdkUpdateNtfsFormatBootSector_ParseError_bad_signature 3u
#define R4SdkUpdateNtfsFormatBootSector_ParseError_bad_sector_size 4u
#define R4SdkUpdateNtfsFormatBootSector_ParseError_bad_cluster_size 5u
#define R4SdkUpdateNtfsFormatBootSector_ParseError_bad_record_size 6u
#define R4SdkUpdateNtfsFormatBootSector_ParseError_bad_index_size 7u
#define R4SdkUpdateNtfsFormatBootSector_ParseError_bad_geometry 8u
#define R4SdkUpdateNative_math_CompareOperator_lt 0u
#define R4SdkUpdateNative_math_CompareOperator_lte 1u
#define R4SdkUpdateNative_math_CompareOperator_eq 2u
#define R4SdkUpdateNative_math_CompareOperator_gte 3u
#define R4SdkUpdateNative_math_CompareOperator_gt 4u
#define R4SdkUpdateNative_math_CompareOperator_neq 5u
/* storage_tools.standardNtfsMetadata -> ntfs_builder.WithFormat(ntfs_format).Meta */
static inline R4SdkUpdateSlot R4SdkUpdateStorage_standardNtfsMetadata(uint32_t reserved, R4SdkUpdateNtfsMetadata *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,0u,a,0u,output);
}
/* update_host_file.open -> anyerror!void */
static inline R4SdkUpdateSlot R4SdkUpdateHost_open(uint32_t reserved, R4SdkUpdateHostFile * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,1u,a,2u,0);
}
/* update_host_file.borrow -> anyerror!void */
static inline R4SdkUpdateSlot R4SdkUpdateHost_borrow(uint32_t reserved, R4SdkUpdateHostFile * p0, uint64_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,2u,a,2u,0);
}
/* update_host_file.acquire -> anyerror!void */
static inline R4SdkUpdateSlot R4SdkUpdateHost_acquire(uint32_t reserved, R4SdkUpdateHostFile * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,3u,a,1u,0);
}
/* update_host_file.release -> anyerror!void */
static inline R4SdkUpdateSlot R4SdkUpdateHost_release(uint32_t reserved, R4SdkUpdateHostFile * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,4u,a,1u,0);
}
/* update_host_file.resize -> anyerror!void */
static inline R4SdkUpdateSlot R4SdkUpdateHost_resize(uint32_t reserved, R4SdkUpdateHostFile * p0, uint64_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,5u,a,2u,0);
}
/* update_host_file.device -> anyerror!storage_tools.io.Device */
static inline R4SdkUpdateSlot R4SdkUpdateHost_device(uint32_t reserved, R4SdkUpdateHostFile * p0, R4SdkUpdateSlot p1, R4SdkUpdateBlockDevice *output) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = p1;
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,6u,a,2u,output);
}
/* update_host_file.lastError -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateHost_lastError(uint32_t reserved, R4SdkUpdateHostFile * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,7u,a,1u,0);
}
/* update_host_file.close -> anyerror!void */
static inline R4SdkUpdateSlot R4SdkUpdateHost_close(uint32_t reserved, R4SdkUpdateHostFile * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,8u,a,1u,0);
}
/* storage_tools.partition.clean -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.clean)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdatePartition_clean(uint32_t reserved, const R4SdkUpdateBlockDevice * p0, uint8_t p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,9u,a,3u,0);
}
/* storage_tools.partition.asciiName -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.asciiName)).@"fn".return_type.?).error_union.error_set![36]u16 */
static inline R4SdkUpdateSlot R4SdkUpdatePartition_asciiName(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNativeValue28 *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,10u,a,1u,output);
}
/* storage_tools.guid.parse -> ?[16]u8 */
static inline R4SdkUpdateSlot R4SdkUpdateStorageguid_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNativeValue27 *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,11u,a,1u,output);
}
/* storage_tools.guid.format -> [36]u8 */
static inline R4SdkUpdateSlot R4SdkUpdateStorageguid_format(uint32_t reserved, const R4SdkUpdateNativeValue27 * p0, R4SdkUpdateNativeValue38 *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,12u,a,1u,output);
}
/* storage_tools.guid.eql -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateStorageguid_eql(uint32_t reserved, const R4SdkUpdateNativeValue27 * p0, const R4SdkUpdateNativeValue27 * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,13u,a,2u,0);
}
/* storage_tools.guid.isZero -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateStorageguid_isZero(uint32_t reserved, const R4SdkUpdateNativeValue27 * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,14u,a,1u,0);
}
/* storage_tools.fat32.fsInfo -> [512]u8 */
static inline R4SdkUpdateSlot R4SdkUpdateFat32_fsInfo(uint32_t reserved, uint32_t p0, uint32_t p1, R4SdkUpdateNativeValue42 *output) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,15u,a,2u,output);
}
/* storage_tools.fat32.volumeLabel -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32.volumeLabel)).@"fn".return_type.?).error_union.error_set![11]u8 */
static inline R4SdkUpdateSlot R4SdkUpdateFat32_volumeLabel(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNativeValue41 *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,16u,a,1u,output);
}
/* storage_tools.fat32_image.prepare -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_image.prepare)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_image.Prepared */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_prepare(uint32_t reserved, const R4SdkDataAllocator * p0, uint64_t p1, uint64_t p2, const uint8_t * p3, uintptr_t n3, uint32_t p4, const R4SdkUpdateStoragefat32_image_File * p5, uintptr_t n5, R4SdkUpdateStoragefat32_image_Prepared *output) {
 (void)reserved; R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,17u,a,6u,output);
}
/* storage_tools.fat32_image.buildInto -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_image.buildInto)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_image.Stats */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_buildInto(uint32_t reserved, const R4SdkDataAllocator * p0, uint8_t * p1, uintptr_t n1, uint64_t p2, uint32_t p3, const uint8_t * p4, uintptr_t n4, uint32_t p5, const R4SdkUpdateStoragefat32_image_File * p6, uintptr_t n6, R4SdkUpdateStoragefat32_image_Stats *output) {
 (void)reserved; R4SdkUpdateSlot a[7]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,18u,a,7u,output);
}
/* storage_tools.fat32_image.prepareStreamed -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_image.prepareStreamed)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_image.Streamed */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_prepareStreamed(uint32_t reserved, const R4SdkDataAllocator * p0, uint64_t p1, uint64_t p2, uint32_t p3, const uint8_t * p4, uintptr_t n4, uint32_t p5, const R4SdkUpdateStoragefat32_image_File * p6, uintptr_t n6, R4SdkUpdateStoragefat32_image_Streamed *output) {
 (void)reserved; R4SdkUpdateSlot a[7]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,19u,a,7u,output);
}
/* storage_tools.fat32_update.prepareBacking -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.prepareBacking)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_update.Prepared */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_prepareBacking(uint32_t reserved, const R4SdkDataAllocator * p0, R4SdkUpdateStoragefat32_update_Backing * p1, const R4SdkUpdateStoragefat32_update_Change * p2, uintptr_t n2, R4SdkUpdateStoragefat32_update_Prepared *output) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,20u,a,3u,output);
}
/* storage_tools.fat32_update.verifyTree -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.verifyTree)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_verifyTree(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint64_t p1, const uint8_t * p2, uintptr_t n2, const R4SdkDataNative_Value31 * p3, uintptr_t n3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,21u,a,4u,0);
}
/* storage_tools.fat32_update.verifyTreeBacking -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.verifyTreeBacking)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_verifyTreeBacking(uint32_t reserved, R4SdkUpdateStoragefat32_update_Backing * p0, const uint8_t * p1, uintptr_t n1, const R4SdkDataNative_Value31 * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,22u,a,3u,0);
}
/* storage_tools.fat32_update.prepare -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.prepare)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_update.Prepared */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_prepare(uint32_t reserved, const R4SdkDataAllocator * p0, const uint8_t * p1, uintptr_t n1, uint64_t p2, const R4SdkUpdateStoragefat32_update_Change * p3, uintptr_t n3, R4SdkUpdateStoragefat32_update_Prepared *output) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,23u,a,4u,output);
}
/* storage_tools.fat32_update.prepareDelta -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.prepareDelta)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_update.Prepared */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_prepareDelta(uint32_t reserved, const R4SdkDataAllocator * p0, uint8_t * p1, uintptr_t n1, uint64_t p2, const R4SdkUpdateStoragefat32_update_Change * p3, uintptr_t n3, R4SdkUpdateStoragefat32_update_Prepared *output) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,24u,a,4u,output);
}
/* ntfs_format.applyFixups -> ntfs_format.FixupError */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_applyFixups(uint32_t reserved, uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,25u,a,1u,0);
}
/* ntfs_format.installFixups -> ntfs_format.FixupError */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_installFixups(uint32_t reserved, uint8_t * p0, uintptr_t n0, uint16_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,26u,a,2u,0);
}
/* ntfs_format.findAttribute -> ?ntfs_format.Attribute */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_findAttribute(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const R4SdkUpdateNtfsFormatFileRecordHeader * p1, uint32_t p2, const uint8_t * p3, uintptr_t n3, R4SdkUpdateNtfsFormatAttribute *output) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,27u,a,4u,output);
}
/* ntfs_format.encodeRun -> ?usize */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_encodeRun(uint32_t reserved, uint8_t * p0, uintptr_t n0, uint64_t p1, R4SdkUpdateSlot p2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = p2;
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,28u,a,3u,0);
}
/* ntfs_format.upcaseUnit -> u16 */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_upcaseUnit(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint16_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,29u,a,2u,0);
}
/* ntfs_format.compareFileNames -> math.Order */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_compareFileNames(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,30u,a,3u,0);
}
/* ntfs_format.asciiMatchesUtf16 -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_asciiMatchesUtf16(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,31u,a,3u,0);
}
/* ntfs_format.utf16ToAscii -> ?usize */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_utf16ToAscii(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,32u,a,2u,0);
}
/* ntfs_format.asciiToUtf16 -> ?usize */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_asciiToUtf16(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,33u,a,2u,0);
}
/* ntfs_format.utf8ToUtf16 -> ?usize */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_utf8ToUtf16(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,34u,a,2u,0);
}
/* ntfs_format.utf16ToUtf8 -> ?usize */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_utf16ToUtf8(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,35u,a,2u,0);
}
/* ntfs_format.lznt1Decompress -> ?usize */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormat_lznt1Decompress(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,36u,a,2u,0);
}
/* storage_tools.ntfs_plan.fillBitmap -> void */
static inline R4SdkUpdateSlot R4SdkUpdateNtfs_fillBitmap(uint32_t reserved, uint8_t * p0, uintptr_t n0, uint64_t p1, uint64_t p2, uint64_t p3, uint64_t p4) {
 (void)reserved; R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,37u,a,5u,0);
}
/* storage_tools.installation.sourceRanges -> @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.sourceRanges)).@"fn".return_type.?).error_union.error_set![5]storage_tools.partition.Range */
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_sourceRanges(uint32_t reserved, uint64_t p0, R4SdkUpdateNativeValue33 *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,38u,a,1u,output);
}
/* storage_tools.installation.bootPath -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_bootPath(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,39u,a,1u,0);
}
/* storage_tools.limine.supportsBiosSystem -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateStoragelimine_supportsBiosSystem(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,40u,a,1u,0);
}
/* storage_tools.limine.verifyBios -> @typeInfo(@typeInfo(@TypeOf(storage_tools.limine.verifyBios)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragelimine_verifyBios(uint32_t reserved, const R4SdkUpdateBlockDevice * p0, const R4SdkUpdatePartitionPlan * p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,41u,a,3u,0);
}
/* storage_tools.limine.installBios -> @typeInfo(@typeInfo(@TypeOf(storage_tools.limine.installBios)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragelimine_installBios(uint32_t reserved, const R4SdkUpdateBlockDevice * p0, const R4SdkUpdatePartitionPlan * p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,42u,a,3u,0);
}
/* version_info.stripBom -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateNative_version_info_stripBom(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,43u,a,1u,0);
}
/* version_info.parseReleaseVersion -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateNative_version_info_parseReleaseVersion(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,44u,a,1u,0);
}
/* version_info.parseInstalledKernelVersion -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateNative_version_info_parseInstalledKernelVersion(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,45u,a,1u,0);
}
/* version_info.parseSemanticVersion -> ?version_info.SemanticVersion */
static inline R4SdkUpdateSlot R4SdkUpdateNative_version_info_parseSemanticVersion(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkDataVersionSemanticVersion *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,46u,a,1u,output);
}
/* version_info.fromKernelVersion -> version_info.SemanticVersion */
static inline R4SdkUpdateSlot R4SdkUpdateNative_version_info_fromKernelVersion(uint32_t reserved, const R4KernelVersion * p0, R4SdkDataVersionSemanticVersion *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,47u,a,1u,output);
}
/* version_info.formatKernelVersion -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateNative_version_info_formatKernelVersion(uint32_t reserved, const R4KernelVersion * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,48u,a,2u,0);
}
/* version_info.formatSemanticVersion -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateNative_version_info_formatSemanticVersion(uint32_t reserved, const R4SdkDataVersionSemanticVersion * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,49u,a,2u,0);
}
/* version_info.restartRequired -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNative_version_info_restartRequired(uint32_t reserved, const R4KernelVersion * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,50u,a,2u,0);
}
/* r4u_manifest.kernelSupportsCompanions -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_kernelSupportsCompanions(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,51u,a,1u,0);
}
/* r4u_manifest.companionRecoveryRequirement -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_companionRecoveryRequirement(uint32_t reserved, uint32_t p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, uint32_t p4) {
 (void)reserved; R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,52u,a,5u,0);
}
/* r4u_manifest.kernelSupportsCompanionSet -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_kernelSupportsCompanionSet(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint8_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,53u,a,2u,0);
}
/* r4u_manifest.companionSetRecoveryRequirement -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_companionSetRecoveryRequirement(uint32_t reserved, uint32_t p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, uint32_t p4, uint8_t p5) {
 (void)reserved; R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,54u,a,6u,0);
}
/* r4u_manifest.includeCompanion -> void */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_includeCompanion(uint32_t reserved, R4SdkDataUpdateMetadataDerivedClass * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,55u,a,2u,0);
}
/* r4u_manifest.componentKindForPayload -> ?r4u_manifest.ComponentKind */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_componentKindForPayload(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,56u,a,2u,0);
}
/* r4u_manifest.installModeFor -> r4u_manifest.InstallMode */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_installModeFor(uint32_t reserved, uint32_t p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,57u,a,2u,0);
}
/* r4u_manifest.priorityFor -> r4u_manifest.Priority */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_priorityFor(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,58u,a,1u,0);
}
/* r4u_manifest.includeComponent -> void */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_includeComponent(uint32_t reserved, R4SdkDataUpdateMetadataDerivedClass * p0, uint32_t p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,59u,a,3u,0);
}
/* r4u_manifest.validSemanticVersion -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_validSemanticVersion(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,60u,a,1u,0);
}
/* r4u_manifest.compareVersions -> ?i8 */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_compareVersions(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,61u,a,2u,0);
}
/* r4u_manifest.validToken -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_validToken(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint64_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,62u,a,2u,0);
}
/* r4u_manifest.validDisplayText -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_validDisplayText(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint64_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,63u,a,2u,0);
}
/* r4u_manifest.canonicalInventoryTarget -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_canonicalInventoryTarget(uint32_t reserved, uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,64u,a,2u,0);
}
/* r4u_manifest.targetEquals -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_targetEquals(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,65u,a,2u,0);
}
/* r4u_manifest.isManagedStateTarget -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNative_r4u_manifest_isManagedStateTarget(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,66u,a,1u,0);
}
/* system_update_recovery.phaseTerminal -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_phaseTerminal(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,67u,a,1u,0);
}
/* system_update_recovery.phaseName -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_phaseName(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,68u,a,1u,0);
}
/* system_update_recovery.replayStatusName -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_replayStatusName(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,69u,a,1u,0);
}
/* system_update_recovery.selectNewestSlot -> system_update_recovery.SlotSelection */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_selectNewestSlot(uint32_t reserved, const R4SdkUpdateNativeValue162 * p0, const R4SdkUpdateNativeValue162 * p1, const R4SdkUpdateNativeValue163 * p2, R4SdkUpdateRecoverySlotSelection *output) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,70u,a,3u,output);
}
/* system_update_recovery.serializeJournal -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_serializeJournal(uint32_t reserved, const R4SdkUpdateRecoveryTransactionJournal * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,71u,a,2u,0);
}
/* system_update_recovery.parseJournalInto -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_parseJournalInto(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint8_t p1, R4SdkUpdateRecoveryTransactionJournal * p2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,72u,a,3u,0);
}
/* system_update_recovery.journalValid -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_journalValid(uint32_t reserved, const R4SdkUpdateRecoveryTransactionJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,73u,a,1u,0);
}
/* system_update_recovery.journalPathsValid -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_journalPathsValid(uint32_t reserved, const R4SdkUpdateRecoveryTransactionJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,74u,a,1u,0);
}
/* system_update_recovery.normalizeAbsolutePath -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_normalizeAbsolutePath(uint32_t reserved, uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,75u,a,2u,0);
}
/* system_update_recovery.buildInternal83Name -> ?usize */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_buildInternal83Name(uint32_t reserved, uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, uint8_t p2, uint64_t p3, uint64_t p4) {
 (void)reserved; R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,76u,a,5u,0);
}
/* system_update_recovery.validateShortName83Text -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_validateShortName83Text(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,77u,a,1u,0);
}
/* system_update_recovery.pathEqualsIgnoreCase -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_pathEqualsIgnoreCase(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,78u,a,2u,0);
}
/* system_update_recovery.versionTextValid -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_versionTextValid(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,79u,a,1u,0);
}
/* system_update_recovery.checksum -> u32 */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_checksum(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,80u,a,1u,0);
}
/* system_update_recovery.checksumUpdate -> u32 */
static inline R4SdkUpdateSlot R4SdkUpdateRecovery_checksumUpdate(uint32_t reserved, uint32_t p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,81u,a,2u,0);
}
/* system_update_batch.phaseTerminal -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateBatch_phaseTerminal(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,82u,a,1u,0);
}
/* system_update_batch.selectNewestSlot -> system_update_batch.SlotSelection */
static inline R4SdkUpdateSlot R4SdkUpdateBatch_selectNewestSlot(uint32_t reserved, const R4SdkUpdateNativeValue162 * p0, const R4SdkUpdateNativeValue162 * p1, const R4SdkUpdateNativeValue163 * p2, R4SdkUpdateBatchSlotSelection *output) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,83u,a,3u,output);
}
/* system_update_batch.serializeJournal -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateBatch_serializeJournal(uint32_t reserved, const R4SdkUpdateBatchBatchJournal * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,84u,a,2u,0);
}
/* system_update_batch.parseJournalInto -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateBatch_parseJournalInto(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint8_t p1, R4SdkUpdateBatchBatchJournal * p2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,85u,a,3u,0);
}
/* system_update_batch.journalValid -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateBatch_journalValid(uint32_t reserved, const R4SdkUpdateBatchBatchJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,86u,a,1u,0);
}
/* system_update_batch.planOrder -> error{DependencyCycle,DuplicateComponent,InvalidReference,TooManyPackages,UnresolvedRequirement}![]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateBatch_planOrder(uint32_t reserved, const R4SdkUpdateBatchPlanPackage * p0, uintptr_t n0, const R4SdkUpdateBatchPlanComponent * p1, uintptr_t n1, const R4SdkUpdateBatchPlanRequirement * p2, uintptr_t n2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,87u,a,4u,0);
}
/* system_update_backup.validName -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateBackup_validName(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,88u,a,1u,0);
}
/* system_update_backup.samePath -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateBackup_samePath(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,89u,a,2u,0);
}
/* update_catalog.buildPlan -> error{DependencyOrder,InvalidCatalog,InvalidInventory,TooManyPackages,UnmetRequirement}!update_catalog.Plan */
static inline R4SdkUpdateSlot R4SdkUpdateCatalog_buildPlan(uint32_t reserved, const R4SdkUpdateCatalogCatalogRelease * p0, const R4SdkUpdateInventoryInventory * p1, const uint8_t * p2, uintptr_t n2, R4SdkUpdateSlot p3, R4SdkUpdateCatalogPlan *output) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = p3;
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,90u,a,4u,output);
}
/* update_catalog.packageDelta -> error{DependencyOrder,InvalidCatalog,InvalidInventory,TooManyPackages,UnmetRequirement}!update_catalog.PackageDelta */
static inline R4SdkUpdateSlot R4SdkUpdateCatalog_packageDelta(uint32_t reserved, const R4SdkUpdateCatalogCatalogRelease * p0, const R4SdkUpdateInventoryInventory * p1, const R4SdkUpdateCatalogPackage * p2, R4SdkUpdateCatalogPackageDelta *output) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,91u,a,3u,output);
}
/* update_catalog.installedEntry -> ?*const system_update_inventory.Entry */
static inline R4SdkUpdateSlot R4SdkUpdateCatalog_installedEntry(uint32_t reserved, const R4SdkUpdateInventoryInventory * p0, uint32_t p1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,92u,a,4u,0);
}
/* update_catalog.decodeJsonString -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateCatalog_decodeJsonString(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,93u,a,2u,0);
}
/* update_helper_adapters.checkLastGood -> error{MissingCallback}!system_update_recovery.ReplayStatus */
static inline R4SdkUpdateSlot R4SdkUpdate_checkLastGood(uint32_t reserved, const R4SdkUpdateCallbackTable * p0, const R4SdkUpdateRecoveryTransactionJournal * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,94u,a,2u,0);
}
/* update_helper_adapters.rollbackToTerminal -> error{MissingCallback}!system_update_recovery.ReplayStatus */
static inline R4SdkUpdateSlot R4SdkUpdate_rollbackToTerminal(uint32_t reserved, const R4SdkUpdateCallbackTable * p0, R4SdkUpdateRecoveryTransactionJournal * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,95u,a,2u,0);
}
/* update_helper_adapters.resumeBatchForward -> error{MissingCallback}!system_update_recovery.ReplayStatus */
static inline R4SdkUpdateSlot R4SdkUpdate_resumeBatchForward(uint32_t reserved, const R4SdkUpdateCallbackTable * p0, R4SdkUpdateRecoveryTransactionJournal * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,96u,a,2u,0);
}
/* update_helper_adapters.cleanupToTerminal -> error{MissingCallback}!system_update_recovery.ReplayStatus */
static inline R4SdkUpdateSlot R4SdkUpdate_cleanupToTerminal(uint32_t reserved, const R4SdkUpdateCallbackTable * p0, R4SdkUpdateRecoveryTransactionJournal * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,97u,a,2u,0);
}
/* update_helper_adapters.archive -> error{Copy,MissingCallback,Referenced,Remove,Verification}!void */
static inline R4SdkUpdateSlot R4SdkUpdate_archive(uint32_t reserved, const R4SdkUpdateCallbackTable * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,98u,a,1u,0);
}
/* update_helper_adapters.referenced -> bool */
static inline R4SdkUpdateSlot R4SdkUpdate_referenced(uint32_t reserved, const R4SdkUpdateRecoveryTransactionJournal * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,99u,a,2u,0);
}
/* update_helper_adapters.device -> error{MissingCallback}!storage_tools.io.Device */
static inline R4SdkUpdateSlot R4SdkUpdate_device(uint32_t reserved, const R4SdkUpdateCallbackTable * p0, uint64_t p1, uint8_t p2, R4SdkUpdateSlot p3, R4SdkUpdateBlockDevice *output) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = p3;
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,100u,a,4u,output);
}
/* update_helper_adapters.source -> error{MissingCallback}!storage_tools.byte_source.Source */
static inline R4SdkUpdateSlot R4SdkUpdate_source(uint32_t reserved, const R4SdkUpdateCallbackTable * p0, uint64_t p1, R4SdkUpdateByteSource *output) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,101u,a,2u,output);
}
/* update_helper_adapters.guestTarget -> void */
static inline R4SdkUpdateSlot R4SdkUpdate_guestTarget(uint32_t reserved, R4SdkUpdateGuestTarget * p0, const R4SdkDataContext * p1, const R4StorageTarget * p2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,102u,a,3u,0);
}
/* update_helper_adapters.inspectArtifact -> ?r4u_artifact.Identity */
static inline R4SdkUpdateSlot R4SdkUpdate_inspectArtifact(uint32_t reserved, const R4SdkUpdateByteSource * p0, uint64_t p1, R4SdkDataArtifactIdentity *output) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,103u,a,2u,output);
}
/* update_helper_adapters.gptRead -> @typeInfo(@typeInfo(@TypeOf(update_helper_adapters.gptRead)).@"fn".return_type.?).error_union.error_set!*storage_tools.gpt_repair.Report */
static inline R4SdkUpdateSlot R4SdkUpdate_gptRead(uint32_t reserved, const R4SdkDataAllocator * p0, const R4SdkUpdateBlockDevice * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,104u,a,2u,0);
}
/* update_helper_adapters.gptDeinit -> void */
static inline R4SdkUpdateSlot R4SdkUpdate_gptDeinit(uint32_t reserved, R4SdkUpdateStoragegpt_repair_Report * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,105u,a,1u,0);
}
/* update_helper_adapters.gptRepairable -> @typeInfo(@typeInfo(@TypeOf(update_helper_adapters.gptRepairable)).@"fn".return_type.?).error_union.error_set!usize */
static inline R4SdkUpdateSlot R4SdkUpdate_gptRepairable(uint32_t reserved, const R4SdkUpdateStoragegpt_repair_Report * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,106u,a,1u,0);
}
/* update_helper_adapters.gptRepair -> @typeInfo(@typeInfo(@TypeOf(update_helper_adapters.gptRepair)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdate_gptRepair(uint32_t reserved, const R4SdkUpdateStoragegpt_repair_Report * p0, const R4SdkUpdateBlockDevice * p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,107u,a,3u,0);
}
/* update_helper_adapters.gptStatus -> storage_tools.gpt_repair.Status */
static inline R4SdkUpdateSlot R4SdkUpdate_gptStatus(uint32_t reserved, const R4SdkUpdateStoragegpt_repair_Report * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,108u,a,1u,0);
}
/* update_helper_adapters.gptValid -> bool */
static inline R4SdkUpdateSlot R4SdkUpdate_gptValid(uint32_t reserved, const R4SdkUpdateStoragegpt_repair_Report * p0, uint64_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,109u,a,2u,0);
}
/* update_helper_adapters.gptReason -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdate_gptReason(uint32_t reserved, const R4SdkUpdateStoragegpt_repair_Report * p0, uint64_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,110u,a,2u,0);
}
/* update_helper_adapters.gptMbrReason -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdate_gptMbrReason(uint32_t reserved, const R4SdkUpdateStoragegpt_repair_Report * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,111u,a,1u,0);
}
/* update_helper_adapters.parseCatalog -> error{BadJson,BadSchema,DuplicateField,DuplicateRelease,InvalidValue,LimitExceeded,NoEligibleRelease,UnknownField}!void */
static inline R4SdkUpdateSlot R4SdkUpdate_parseCatalog(uint32_t reserved, R4SdkDataJsonDocument * p0, uint32_t p1, const uint8_t * p2, uintptr_t n2, R4SdkUpdateCatalogCatalogRelease * p3, R4SdkUpdateCatalogCatalogRelease * p4) {
 (void)reserved; R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,112u,a,5u,0);
}
/* storage_tools.io.Device.validate -> error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}!void */
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_validate(uint32_t reserved, const R4SdkUpdateBlockDevice * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,113u,a,1u,0);
}
/* storage_tools.io.Device.requireExclusive -> error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}!void */
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_requireExclusive(uint32_t reserved, const R4SdkUpdateBlockDevice * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,114u,a,1u,0);
}
/* storage_tools.io.Device.checkRange -> error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}!void */
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_checkRange(uint32_t reserved, const R4SdkUpdateBlockDevice * p0, uint64_t p1, uint64_t p2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,115u,a,3u,0);
}
/* storage_tools.io.Device.phase -> void */
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_phase(uint32_t reserved, const R4SdkUpdateBlockDevice * p0, uint32_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,116u,a,2u,0);
}
/* storage_tools.io.Device.read -> error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}!void */
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_read(uint32_t reserved, const R4SdkUpdateBlockDevice * p0, uint64_t p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,117u,a,3u,0);
}
/* storage_tools.io.Device.write -> error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}!void */
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_write(uint32_t reserved, const R4SdkUpdateBlockDevice * p0, uint64_t p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,118u,a,3u,0);
}
/* storage_tools.io.Device.flush -> error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}!void */
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_flush(uint32_t reserved, const R4SdkUpdateBlockDevice * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,119u,a,1u,0);
}
/* storage_tools.io.Device.verify -> error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}!void */
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_verify(uint32_t reserved, const R4SdkUpdateBlockDevice * p0, uint64_t p1, const uint8_t * p2, uintptr_t n2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,120u,a,4u,0);
}
/* storage_tools.io.Device.complete -> void */
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_complete(uint32_t reserved, const R4SdkUpdateBlockDevice * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,121u,a,1u,0);
}
/* storage_tools.io.Device.fill -> error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}!void */
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_fill(uint32_t reserved, const R4SdkUpdateBlockDevice * p0, uint64_t p1, uint64_t p2, uint8_t p3, uint8_t * p4, uintptr_t n4) {
 (void)reserved; R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,122u,a,5u,0);
}
/* storage_tools.io.Device.writePadded -> error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}!void */
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_writePadded(uint32_t reserved, const R4SdkUpdateBlockDevice * p0, uint64_t p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,123u,a,3u,0);
}
/* storage_tools.io.Region.device -> error{Bounds,Cancelled,ExclusiveRequired,FlushFailed,Geometry,ReadFailed,VerifyFailed,WriteFailed}!storage_tools.io.Device */
static inline R4SdkUpdateSlot R4SdkUpdateBlockRegion_device(uint32_t reserved, R4SdkUpdateBlockRegion * p0, R4SdkUpdateBlockDevice *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,124u,a,1u,output);
}
/* storage_tools.io.Memory.device -> storage_tools.io.Device */
static inline R4SdkUpdateSlot R4SdkUpdateBlockMemory_device(uint32_t reserved, R4SdkUpdateBlockMemory * p0, R4SdkUpdateBlockDevice *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,125u,a,1u,output);
}
/* storage_tools.byte_source.Source.read -> @typeInfo(@typeInfo(@TypeOf(storage_tools.byte_source.Source.read)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_read(uint32_t reserved, const R4SdkUpdateByteSource * p0, uint64_t p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,126u,a,3u,0);
}
/* storage_tools.byte_source.Source.range -> @typeInfo(@typeInfo(@TypeOf(storage_tools.byte_source.Source.range)).@"fn".return_type.?).error_union.error_set!storage_tools.byte_source.Source */
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_range(uint32_t reserved, const R4SdkUpdateByteSource * p0, uint64_t p1, uint64_t p2, R4SdkUpdateByteSource *output) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,127u,a,3u,output);
}
/* storage_tools.byte_source.Source.slice -> storage_tools.byte_source.Source */
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_slice(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateByteSource *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,128u,a,1u,output);
}
/* storage_tools.sparse_image.Image.init -> @typeInfo(@typeInfo(@TypeOf(storage_tools.sparse_image.Image.init)).@"fn".return_type.?).error_union.error_set!*storage_tools.sparse_image.Image */
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_init(uint32_t reserved, const R4SdkDataAllocator * p0, uint64_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,129u,a,2u,0);
}
/* storage_tools.sparse_image.Image.deinit -> void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_deinit(uint32_t reserved, R4SdkUpdateStoragesparse_image_Image * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,130u,a,1u,0);
}
/* storage_tools.sparse_image.Image.append -> @typeInfo(@typeInfo(@TypeOf(storage_tools.sparse_image.Image.append)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_append(uint32_t reserved, R4SdkUpdateStoragesparse_image_Image * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,131u,a,2u,0);
}
/* storage_tools.sparse_image.Image.finish -> @typeInfo(@typeInfo(@TypeOf(storage_tools.sparse_image.Image.finish)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_finish(uint32_t reserved, R4SdkUpdateStoragesparse_image_Image * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,132u,a,1u,0);
}
/* storage_tools.sparse_image.Image.source -> storage_tools.byte_source.Source */
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_source(uint32_t reserved, const R4SdkUpdateStoragesparse_image_Image * p0, R4SdkUpdateByteSource *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,133u,a,1u,output);
}
/* storage_tools.partition.Plan.read -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.read)).@"fn".return_type.?).error_union.error_set!storage_tools.partition.Plan */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_read(uint32_t reserved, const R4SdkUpdateBlockDevice * p0, uint8_t * p1, uintptr_t n1, R4SdkUpdatePartitionPlan *output) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,134u,a,2u,output);
}
/* storage_tools.partition.Plan.initializeGpt -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.initializeGpt)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_initializeGpt(uint32_t reserved, R4SdkUpdatePartitionPlan * p0, const R4SdkUpdateNativeValue27 * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,135u,a,2u,0);
}
/* storage_tools.partition.Plan.initializeMbr -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.initializeMbr)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_initializeMbr(uint32_t reserved, R4SdkUpdatePartitionPlan * p0, uint32_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,136u,a,2u,0);
}
/* storage_tools.partition.Plan.convertEmpty -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.convertEmpty)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_convertEmpty(uint32_t reserved, R4SdkUpdatePartitionPlan * p0, uint32_t p1, const R4SdkUpdateNativeValue27 * p2, uint32_t p3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,137u,a,4u,0);
}
/* storage_tools.partition.Plan.validate -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.validate)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_validate(uint32_t reserved, const R4SdkUpdatePartitionPlan * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,138u,a,1u,0);
}
/* storage_tools.partition.Plan.add -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.add)).@"fn".return_type.?).error_union.error_set!u32 */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_add(uint32_t reserved, R4SdkUpdatePartitionPlan * p0, const R4SdkUpdatePartitionEntry * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,139u,a,2u,0);
}
/* storage_tools.partition.Plan.remove -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.remove)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_remove(uint32_t reserved, R4SdkUpdatePartitionPlan * p0, uint32_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,140u,a,2u,0);
}
/* storage_tools.partition.Plan.get -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.get)).@"fn".return_type.?).error_union.error_set!*storage_tools.partition.Entry */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get(uint32_t reserved, R4SdkUpdatePartitionPlan * p0, uint32_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,141u,a,2u,0);
}
/* storage_tools.partition.Plan.freeRanges -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.freeRanges)).@"fn".return_type.?).error_union.error_set!usize */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_freeRanges(uint32_t reserved, const R4SdkUpdatePartitionPlan * p0, R4SdkUpdatePartitionRange * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,142u,a,2u,0);
}
/* storage_tools.partition.Plan.firstFit -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.firstFit)).@"fn".return_type.?).error_union.error_set!u64 */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_firstFit(uint32_t reserved, const R4SdkUpdatePartitionPlan * p0, uint64_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,143u,a,2u,0);
}
/* storage_tools.partition.Plan.extend -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.extend)).@"fn".return_type.?).error_union.error_set!u64 */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_extend(uint32_t reserved, R4SdkUpdatePartitionPlan * p0, uint32_t p1, R4SdkUpdateSlot p2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = p2;
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,144u,a,3u,0);
}
/* storage_tools.partition.Plan.shrink -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.shrink)).@"fn".return_type.?).error_union.error_set!u64 */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_shrink(uint32_t reserved, R4SdkUpdatePartitionPlan * p0, uint32_t p1, uint64_t p2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,145u,a,3u,0);
}
/* storage_tools.partition.Plan.revalidate -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.revalidate)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_revalidate(uint32_t reserved, const R4SdkUpdatePartitionPlan * p0, const R4SdkUpdateBlockDevice * p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,146u,a,3u,0);
}
/* storage_tools.partition.Plan.commit -> @typeInfo(@typeInfo(@TypeOf(storage_tools.partition.Plan.commit)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_commit(uint32_t reserved, const R4SdkUpdatePartitionPlan * p0, const R4SdkUpdateBlockDevice * p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,147u,a,3u,0);
}
/* storage_tools.fat32.Geometry.init -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32.Geometry.init)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32.Geometry */
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_init(uint32_t reserved, uint64_t p0, uint64_t p1, uint32_t p2, R4SdkUpdateFat32Geometry *output) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,148u,a,3u,output);
}
/* storage_tools.fat32.Geometry.boot -> [512]u8 */
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_boot(uint32_t reserved, const R4SdkUpdateFat32Geometry * p0, const R4SdkUpdateNativeValue41 * p1, uint32_t p2, R4SdkUpdateNativeValue42 *output) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,149u,a,3u,output);
}
/* storage_tools.fat32.Plan.prepare -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32.Plan.prepare)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32.Plan */
static inline R4SdkUpdateSlot R4SdkUpdateFat32Plan_prepare(uint32_t reserved, uint64_t p0, uint64_t p1, const uint8_t * p2, uintptr_t n2, uint32_t p3, uint32_t p4, R4SdkUpdateFat32Plan *output) {
 (void)reserved; R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,150u,a,5u,output);
}
/* storage_tools.fat32.Plan.execute -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32.Plan.execute)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateFat32Plan_execute(uint32_t reserved, const R4SdkUpdateFat32Plan * p0, const R4SdkUpdateBlockDevice * p1, uint8_t p2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,151u,a,4u,0);
}
/* storage_tools.fat32_image.Streamed.deinit -> void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_deinit(uint32_t reserved, R4SdkUpdateStoragefat32_image_Streamed * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,152u,a,1u,0);
}
/* storage_tools.fat32_image.Streamed.execute -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_image.Streamed.execute)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_execute(uint32_t reserved, const R4SdkUpdateStoragefat32_image_Streamed * p0, const R4SdkUpdateBlockDevice * p1, uint8_t p2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,153u,a,4u,0);
}
/* storage_tools.fat32_image.Prepared.deinit -> void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Prepared_deinit(uint32_t reserved, R4SdkUpdateStoragefat32_image_Prepared * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,154u,a,1u,0);
}
/* storage_tools.fat32_image.Prepared.execute -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_image.Prepared.execute)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Prepared_execute(uint32_t reserved, const R4SdkUpdateStoragefat32_image_Prepared * p0, const R4SdkUpdateBlockDevice * p1, uint8_t p2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,155u,a,4u,0);
}
/* storage_tools.fat32_view.View.init -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_view.View.init)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_view.View */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_view_View_init(uint32_t reserved, const uint8_t * p0, uintptr_t n0, uint64_t p1, R4SdkUpdateStoragefat32_view_View *output) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,156u,a,2u,output);
}
/* storage_tools.fat32_view.View.initSource -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_view.View.initSource)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_view.View */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_view_View_initSource(uint32_t reserved, const R4SdkUpdateByteSource * p0, uint64_t p1, R4SdkUpdateStoragefat32_view_View *output) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,157u,a,2u,output);
}
/* storage_tools.fat32_view.View.readFile -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_view.View.readFile)).@"fn".return_type.?).error_union.error_set![]u8 */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_view_View_readFile(uint32_t reserved, const R4SdkUpdateStoragefat32_view_View * p0, const R4SdkDataAllocator * p1, const uint8_t * p2, uintptr_t n2, uint64_t p3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,158u,a,4u,0);
}
/* storage_tools.fat32_view.View.matches -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_view.View.matches)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_view_View_matches(uint32_t reserved, const R4SdkUpdateStoragefat32_view_View * p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,159u,a,3u,0);
}
/* storage_tools.fat32_update.Backing.init -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.Backing.init)).@"fn".return_type.?).error_union.error_set!storage_tools.fat32_update.Backing */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_init(uint32_t reserved, const R4SdkDataAllocator * p0, const R4SdkUpdateByteSource * p1, uint64_t p2, R4SdkUpdateStoragefat32_update_Backing *output) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,160u,a,3u,output);
}
/* storage_tools.fat32_update.Backing.deinit -> void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_deinit(uint32_t reserved, R4SdkUpdateStoragefat32_update_Backing * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,161u,a,1u,0);
}
/* storage_tools.fat32_update.Backing.source -> storage_tools.byte_source.Source */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_source(uint32_t reserved, const R4SdkUpdateStoragefat32_update_Backing * p0, R4SdkUpdateByteSource *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,162u,a,1u,output);
}
/* storage_tools.fat32_update.Prepared.deinit -> void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_deinit(uint32_t reserved, R4SdkUpdateStoragefat32_update_Prepared * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,163u,a,1u,0);
}
/* storage_tools.fat32_update.Prepared.checkSource -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.Prepared.checkSource)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_checkSource(uint32_t reserved, const R4SdkUpdateStoragefat32_update_Prepared * p0, const R4SdkUpdateBlockDevice * p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,164u,a,3u,0);
}
/* storage_tools.fat32_update.Prepared.execute -> @typeInfo(@typeInfo(@TypeOf(storage_tools.fat32_update.Prepared.execute)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_execute(uint32_t reserved, const R4SdkUpdateStoragefat32_update_Prepared * p0, const R4SdkUpdateBlockDevice * p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,165u,a,3u,0);
}
/* ntfs_format.FileReference.parse -> ntfs_format.FileReference */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileReference_parse(uint32_t reserved, uint64_t p0, R4SdkUpdateNtfsFormatFileReference *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,166u,a,1u,output);
}
/* ntfs_format.FileReference.pack -> u64 */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileReference_pack(uint32_t reserved, const R4SdkUpdateNtfsFormatFileReference * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,167u,a,1u,0);
}
/* ntfs_format.BootSector.parse -> ntfs_format.BootSector.ParseError */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNtfsFormatBootSector * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,168u,a,2u,0);
}
/* ntfs_format.FileRecordHeader.parse -> ?ntfs_format.FileRecordHeader */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNtfsFormatFileRecordHeader *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,169u,a,1u,output);
}
/* ntfs_format.FileRecordHeader.inUse -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_inUse(uint32_t reserved, const R4SdkUpdateNtfsFormatFileRecordHeader * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,170u,a,1u,0);
}
/* ntfs_format.FileRecordHeader.isDirectory -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_isDirectory(uint32_t reserved, const R4SdkUpdateNtfsFormatFileRecordHeader * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,171u,a,1u,0);
}
/* ntfs_format.Attribute.typed -> ntfs_format.AttrType */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_typed(uint32_t reserved, const R4SdkUpdateNtfsFormatAttribute * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,172u,a,1u,0);
}
/* ntfs_format.Attribute.isCompressed -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_isCompressed(uint32_t reserved, const R4SdkUpdateNtfsFormatAttribute * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,173u,a,1u,0);
}
/* ntfs_format.Attribute.isSparse -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_isSparse(uint32_t reserved, const R4SdkUpdateNtfsFormatAttribute * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,174u,a,1u,0);
}
/* ntfs_format.Attribute.isEncrypted -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_isEncrypted(uint32_t reserved, const R4SdkUpdateNtfsFormatAttribute * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,175u,a,1u,0);
}
/* ntfs_format.AttributeIterator.init -> ntfs_format.AttributeIterator */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeIterator_init(uint32_t reserved, const uint8_t * p0, uintptr_t n0, const R4SdkUpdateNtfsFormatFileRecordHeader * p1, R4SdkUpdateNtfsFormatAttributeIterator *output) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,176u,a,2u,output);
}
/* ntfs_format.AttributeIterator.next -> ?ntfs_format.Attribute */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeIterator_next(uint32_t reserved, R4SdkUpdateNtfsFormatAttributeIterator * p0, R4SdkUpdateNtfsFormatAttribute *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,177u,a,1u,output);
}
/* ntfs_format.RunlistIterator.init -> ntfs_format.RunlistIterator */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_init(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNtfsFormatRunlistIterator *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,178u,a,1u,output);
}
/* ntfs_format.RunlistIterator.next -> ?ntfs_format.Run */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_next(uint32_t reserved, R4SdkUpdateNtfsFormatRunlistIterator * p0, R4SdkUpdateNtfsFormatRun *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,179u,a,1u,output);
}
/* ntfs_format.RunlistIterator.hadError -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_hadError(uint32_t reserved, const R4SdkUpdateNtfsFormatRunlistIterator * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,180u,a,1u,0);
}
/* ntfs_format.StandardInformation.parse -> ?ntfs_format.StandardInformation */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNtfsFormatStandardInformation *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,181u,a,1u,output);
}
/* ntfs_format.FileName.parse -> ?ntfs_format.FileName */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNtfsFormatFileName *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,182u,a,1u,output);
}
/* ntfs_format.AttributeListEntry.typed -> ntfs_format.AttrType */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_typed(uint32_t reserved, const R4SdkUpdateNtfsFormatAttributeListEntry * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,183u,a,1u,0);
}
/* ntfs_format.AttributeListIterator.init -> ntfs_format.AttributeListIterator */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListIterator_init(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNtfsFormatAttributeListIterator *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,184u,a,1u,output);
}
/* ntfs_format.AttributeListIterator.next -> ?ntfs_format.AttributeListEntry */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListIterator_next(uint32_t reserved, R4SdkUpdateNtfsFormatAttributeListIterator * p0, R4SdkUpdateNtfsFormatAttributeListEntry *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,185u,a,1u,output);
}
/* ntfs_format.IndexRoot.parse -> ?ntfs_format.IndexRoot */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNtfsFormatIndexRoot *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,186u,a,1u,output);
}
/* ntfs_format.IndexHeader.parse -> ?ntfs_format.IndexHeader */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNtfsFormatIndexHeader *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,187u,a,1u,output);
}
/* ntfs_format.IndexHeader.hasSubNodes -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_hasSubNodes(uint32_t reserved, const R4SdkUpdateNtfsFormatIndexHeader * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,188u,a,1u,0);
}
/* ntfs_format.IndexBlock.parse -> ?ntfs_format.IndexBlock */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexBlock_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNtfsFormatIndexBlock *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,189u,a,1u,output);
}
/* ntfs_format.IndexEntry.isEnd -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_isEnd(uint32_t reserved, const R4SdkUpdateNtfsFormatIndexEntry * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,190u,a,1u,0);
}
/* ntfs_format.IndexEntry.hasSubNode -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_hasSubNode(uint32_t reserved, const R4SdkUpdateNtfsFormatIndexEntry * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,191u,a,1u,0);
}
/* ntfs_format.IndexEntry.fileName -> ?ntfs_format.FileName */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_fileName(uint32_t reserved, const R4SdkUpdateNtfsFormatIndexEntry * p0, R4SdkUpdateNtfsFormatFileName *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,192u,a,1u,output);
}
/* ntfs_format.IndexEntryIterator.init -> ntfs_format.IndexEntryIterator */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntryIterator_init(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNtfsFormatIndexEntryIterator *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,193u,a,1u,output);
}
/* ntfs_format.IndexEntryIterator.next -> ?ntfs_format.IndexEntry */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntryIterator_next(uint32_t reserved, R4SdkUpdateNtfsFormatIndexEntryIterator * p0, R4SdkUpdateNtfsFormatIndexEntry *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,194u,a,1u,output);
}
/* math.Order.invert -> math.Order */
static inline R4SdkUpdateSlot R4SdkUpdateNative_math_Order_invert(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,195u,a,1u,0);
}
/* math.Order.differ -> ?math.Order */
static inline R4SdkUpdateSlot R4SdkUpdateNative_math_Order_differ(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,196u,a,1u,0);
}
/* math.Order.compare -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateNative_math_Order_compare(uint32_t reserved, uint32_t p0, uint32_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,197u,a,2u,0);
}
/* ntfs_format.VolumeInformation.parse -> ?ntfs_format.VolumeInformation */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatVolumeInformation_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateNtfsFormatVolumeInformation *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,198u,a,1u,output);
}
/* storage_tools.ntfs_plan.Plan.deinit -> void */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_deinit(uint32_t reserved, R4SdkUpdateNtfsPlan * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,199u,a,1u,0);
}
/* storage_tools.ntfs_plan.Plan.addBorrowed -> @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_plan.Plan.addBorrowed)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_addBorrowed(uint32_t reserved, R4SdkUpdateNtfsPlan * p0, uint64_t p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,200u,a,3u,0);
}
/* storage_tools.ntfs_plan.Plan.addOwned -> @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_plan.Plan.addOwned)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_addOwned(uint32_t reserved, R4SdkUpdateNtfsPlan * p0, uint64_t p1, uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,201u,a,3u,0);
}
/* storage_tools.ntfs_plan.Plan.addCopy -> @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_plan.Plan.addCopy)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_addCopy(uint32_t reserved, R4SdkUpdateNtfsPlan * p0, uint64_t p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,202u,a,3u,0);
}
/* storage_tools.ntfs_plan.Plan.validate -> @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_plan.Plan.validate)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_validate(uint32_t reserved, const R4SdkUpdateNtfsPlan * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,203u,a,1u,0);
}
/* storage_tools.ntfs_plan.Plan.execute -> @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_plan.Plan.execute)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_execute(uint32_t reserved, const R4SdkUpdateNtfsPlan * p0, const R4SdkUpdateBlockDevice * p1, uint8_t p2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,204u,a,4u,0);
}
/* ntfs_builder.WithFormat(ntfs_format).Builder.init -> @typeInfo(@typeInfo(@TypeOf(ntfs_builder.WithFormat(ntfs_format).Builder.init)).@"fn".return_type.?).error_union.error_set!ntfs_builder.WithFormat(ntfs_format).Builder */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_init(uint32_t reserved, const R4SdkDataAllocator * p0, uint64_t p1, const uint8_t * p2, uintptr_t n2, uint32_t p3, const R4SdkUpdateNtfsMetadata * p4, uint64_t p5, uint64_t p6, R4SdkUpdateNtfsBuilder *output) {
 (void)reserved; R4SdkUpdateSlot a[7]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,205u,a,7u,output);
}
/* ntfs_builder.WithFormat(ntfs_format).Builder.root -> u32 */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_root(uint32_t reserved, R4SdkUpdateNtfsBuilder * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,206u,a,1u,0);
}
/* ntfs_builder.WithFormat(ntfs_format).Builder.addDirectory -> @typeInfo(@typeInfo(@TypeOf(ntfs_builder.WithFormat(ntfs_format).Builder.addDirectory)).@"fn".return_type.?).error_union.error_set!u32 */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_addDirectory(uint32_t reserved, R4SdkUpdateNtfsBuilder * p0, uint32_t p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,207u,a,3u,0);
}
/* ntfs_builder.WithFormat(ntfs_format).Builder.ensureDirectory -> @typeInfo(@typeInfo(@TypeOf(ntfs_builder.WithFormat(ntfs_format).Builder.ensureDirectory)).@"fn".return_type.?).error_union.error_set!u32 */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_ensureDirectory(uint32_t reserved, R4SdkUpdateNtfsBuilder * p0, uint32_t p1, const uint8_t * p2, uintptr_t n2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,208u,a,3u,0);
}
/* ntfs_builder.WithFormat(ntfs_format).Builder.addFile -> @typeInfo(@typeInfo(@TypeOf(ntfs_builder.WithFormat(ntfs_format).Builder.addFile)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_addFile(uint32_t reserved, R4SdkUpdateNtfsBuilder * p0, uint32_t p1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,209u,a,4u,0);
}
/* ntfs_builder.WithFormat(ntfs_format).Builder.deinit -> void */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_deinit(uint32_t reserved, R4SdkUpdateNtfsBuilder * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,210u,a,1u,0);
}
/* ntfs_builder.WithFormat(ntfs_format).Builder.finalize -> @typeInfo(@typeInfo(@TypeOf(ntfs_builder.WithFormat(ntfs_format).Builder.finalize)).@"fn".return_type.?).error_union.error_set![]u8 */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_finalize(uint32_t reserved, R4SdkUpdateNtfsBuilder * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,211u,a,1u,0);
}
/* ntfs_builder.WithFormat(ntfs_format).Builder.prepare -> @typeInfo(@typeInfo(@TypeOf(ntfs_builder.WithFormat(ntfs_format).Builder.prepare)).@"fn".return_type.?).error_union.error_set!storage_tools.ntfs_plan.Plan */
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_prepare(uint32_t reserved, R4SdkUpdateNtfsBuilder * p0, R4SdkUpdateNtfsPlan *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,212u,a,1u,output);
}
/* storage_tools.ntfs_resize.Plan.deinit -> void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_deinit(uint32_t reserved, R4SdkUpdateStoragentfs_resize_Plan * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,213u,a,1u,0);
}
/* storage_tools.ntfs_resize.Plan.prepare -> @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_resize.Plan.prepare)).@"fn".return_type.?).error_union.error_set!*storage_tools.ntfs_resize.Plan */
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_prepare(uint32_t reserved, const R4SdkDataAllocator * p0, const R4SdkUpdateBlockDevice * p1, R4SdkUpdatePartitionPlan * p2, uint32_t p3, uint64_t p4, uint8_t * p5, uintptr_t n5) {
 (void)reserved; R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,214u,a,6u,0);
}
/* storage_tools.ntfs_resize.Plan.execute -> @typeInfo(@typeInfo(@TypeOf(storage_tools.ntfs_resize.Plan.execute)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_execute(uint32_t reserved, const R4SdkUpdateStoragentfs_resize_Plan * p0, const R4SdkUpdateBlockDevice * p1, const R4SdkUpdatePartitionPlan * p2, uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,215u,a,4u,0);
}
/* storage_tools.installation.Identifiers.fromEntropy -> @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Identifiers.fromEntropy)).@"fn".return_type.?).error_union.error_set!storage_tools.installation.Identifiers */
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Identifiers_fromEntropy(uint32_t reserved, const R4SdkUpdateNativeValue302 * p0, R4SdkUpdateStorageinstallation_Identifiers *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,216u,a,1u,output);
}
/* storage_tools.installation.Identifiers.validate -> @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Identifiers.validate)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Identifiers_validate(uint32_t reserved, const R4SdkUpdateStorageinstallation_Identifiers * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,217u,a,1u,0);
}
/* storage_tools.installation.Layout.prepare -> @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Layout.prepare)).@"fn".return_type.?).error_union.error_set!storage_tools.installation.Layout */
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_prepare(uint32_t reserved, uint64_t p0, uint32_t p1, const R4SdkUpdateStorageinstallation_Identifiers * p2, R4SdkUpdateStorageinstallation_Layout *output) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,218u,a,3u,output);
}
/* storage_tools.installation.Layout.prepareSource -> @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Layout.prepareSource)).@"fn".return_type.?).error_union.error_set!storage_tools.installation.Layout */
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_prepareSource(uint32_t reserved, uint64_t p0, const R4SdkUpdateStorageinstallation_Identifiers * p1, R4SdkUpdateStorageinstallation_Layout *output) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,219u,a,2u,output);
}
/* storage_tools.installation.Layout.part -> storage_tools.partition.Range */
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_part(uint32_t reserved, const R4SdkUpdateStorageinstallation_Layout * p0, uint32_t p1, R4SdkUpdatePartitionRange *output) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,220u,a,2u,output);
}
/* storage_tools.installation.Layout.typeGuid -> [16]u8 */
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_typeGuid(uint32_t reserved, uint32_t p0, R4SdkUpdateNativeValue27 *output) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,221u,a,1u,output);
}
/* storage_tools.installation.Layout.bind -> @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Layout.bind)).@"fn".return_type.?).error_union.error_set!void */
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_bind(uint32_t reserved, const R4SdkUpdateStorageinstallation_Layout * p0, R4SdkUpdatePartitionPlan * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,222u,a,2u,0);
}
/* storage_tools.installation.Layout.manifest -> @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Layout.manifest)).@"fn".return_type.?).error_union.error_set![]u8 */
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_manifest(uint32_t reserved, const R4SdkUpdateStorageinstallation_Layout * p0, const R4SdkDataAllocator * p1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const R4SdkDataNative_Value31 * p4, uintptr_t n4) {
 (void)reserved; R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,223u,a,5u,0);
}
/* storage_tools.installation.Layout.limineConfig -> @typeInfo(@typeInfo(@TypeOf(storage_tools.installation.Layout.limineConfig)).@"fn".return_type.?).error_union.error_set![]u8 */
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_limineConfig(uint32_t reserved, const R4SdkUpdateStorageinstallation_Layout * p0, const R4SdkDataAllocator * p1, uint32_t p2) {
 (void)reserved; R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,224u,a,3u,0);
}
/* storage_tools_guest.Target.acquire -> i32 */
static inline R4SdkUpdateSlot R4SdkUpdateGuestTarget_acquire(uint32_t reserved, R4SdkUpdateGuestTarget * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,225u,a,1u,0);
}
/* storage_tools_guest.Target.release -> i32 */
static inline R4SdkUpdateSlot R4SdkUpdateGuestTarget_release(uint32_t reserved, R4SdkUpdateGuestTarget * p0, uint8_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,226u,a,2u,0);
}
/* storage_tools_guest.Target.device -> storage_tools.io.Device */
static inline R4SdkUpdateSlot R4SdkUpdateGuestTarget_device(uint32_t reserved, R4SdkUpdateGuestTarget * p0, R4SdkUpdateSlot p1, R4SdkUpdateBlockDevice *output) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = p1;
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,227u,a,2u,output);
}
/* system_update_inventory.Profile.text -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateInventoryProfile_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,228u,a,1u,0);
}
/* system_update_inventory.Entry.guestFormatSlice -> []const []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_guestFormatSlice(uint32_t reserved, const R4SdkUpdateInventoryEntry * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,229u,a,1u,0);
}
/* system_update_inventory.Entry.guestExtensionSlice -> []const []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_guestExtensionSlice(uint32_t reserved, const R4SdkUpdateInventoryEntry * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,230u,a,1u,0);
}
/* system_update_inventory.Entry.guestFeatureSlice -> []const []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_guestFeatureSlice(uint32_t reserved, const R4SdkUpdateInventoryEntry * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,231u,a,1u,0);
}
/* system_update_inventory.Inventory.parse -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0, R4SdkUpdateInventoryInventory * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,232u,a,2u,0);
}
/* system_update_inventory.Inventory.upsert -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_upsert(uint32_t reserved, R4SdkUpdateInventoryInventory * p0, const R4SdkUpdateInventoryEntry * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,233u,a,2u,0);
}
/* system_update_inventory.Inventory.removeExact -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_removeExact(uint32_t reserved, R4SdkUpdateInventoryInventory * p0, uint32_t p1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,234u,a,4u,0);
}
/* system_update_inventory.Inventory.render -> ?[]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_render(uint32_t reserved, const R4SdkUpdateInventoryInventory * p0, uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,235u,a,2u,0);
}
/* system_update_recovery.JournalPayload.targetText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_targetText(uint32_t reserved, const R4SdkUpdateRecoveryJournalPayload * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,236u,a,1u,0);
}
/* system_update_recovery.JournalPayload.stageText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_stageText(uint32_t reserved, const R4SdkUpdateRecoveryJournalPayload * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,237u,a,1u,0);
}
/* system_update_recovery.JournalPayload.backupText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_backupText(uint32_t reserved, const R4SdkUpdateRecoveryJournalPayload * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,238u,a,1u,0);
}
/* system_update_recovery.JournalPayload.previousBackupText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_previousBackupText(uint32_t reserved, const R4SdkUpdateRecoveryJournalPayload * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,239u,a,1u,0);
}
/* system_update_recovery.JournalPayload.targetPtr -> [*:0]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_targetPtr(uint32_t reserved, const R4SdkUpdateRecoveryJournalPayload * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,240u,a,1u,0);
}
/* system_update_recovery.JournalPayload.stagePtr -> [*:0]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_stagePtr(uint32_t reserved, const R4SdkUpdateRecoveryJournalPayload * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,241u,a,1u,0);
}
/* system_update_recovery.JournalPayload.backupPtr -> [*:0]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_backupPtr(uint32_t reserved, const R4SdkUpdateRecoveryJournalPayload * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,242u,a,1u,0);
}
/* system_update_recovery.JournalPayload.previousBackupPtr -> [*:0]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_previousBackupPtr(uint32_t reserved, const R4SdkUpdateRecoveryJournalPayload * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,243u,a,1u,0);
}
/* system_update_recovery.JournalComponentKind.text -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponentKind_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,244u,a,1u,0);
}
/* system_update_recovery.JournalComponentKind.parse -> ?system_update_recovery.JournalComponentKind */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponentKind_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,245u,a,1u,0);
}
/* system_update_recovery.JournalComponent.nameText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_nameText(uint32_t reserved, const R4SdkUpdateRecoveryJournalComponent * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,246u,a,1u,0);
}
/* system_update_recovery.JournalComponent.targetText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_targetText(uint32_t reserved, const R4SdkUpdateRecoveryJournalComponent * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,247u,a,1u,0);
}
/* system_update_recovery.JournalComponent.versionText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_versionText(uint32_t reserved, const R4SdkUpdateRecoveryJournalComponent * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,248u,a,1u,0);
}
/* system_update_recovery.TransactionJournal.sourceText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_sourceText(uint32_t reserved, const R4SdkUpdateRecoveryTransactionJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,249u,a,1u,0);
}
/* system_update_recovery.TransactionJournal.sourcePtr -> [*:0]const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_sourcePtr(uint32_t reserved, const R4SdkUpdateRecoveryTransactionJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,250u,a,1u,0);
}
/* system_update_recovery.TransactionJournal.sourceVersionText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_sourceVersionText(uint32_t reserved, const R4SdkUpdateRecoveryTransactionJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,251u,a,1u,0);
}
/* system_update_recovery.TransactionJournal.targetVersionText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_targetVersionText(uint32_t reserved, const R4SdkUpdateRecoveryTransactionJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,252u,a,1u,0);
}
/* system_update_recovery.TransactionJournal.sourceReleaseText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_sourceReleaseText(uint32_t reserved, const R4SdkUpdateRecoveryTransactionJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,253u,a,1u,0);
}
/* system_update_recovery.TransactionJournal.releaseText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_releaseText(uint32_t reserved, const R4SdkUpdateRecoveryTransactionJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,254u,a,1u,0);
}
/* system_update_recovery.TransactionJournal.packageVersionText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_packageVersionText(uint32_t reserved, const R4SdkUpdateRecoveryTransactionJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,255u,a,1u,0);
}
/* system_update_batch.Phase.text -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateBatchPhase_text(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,256u,a,1u,0);
}
/* system_update_batch.Phase.parse -> ?system_update_batch.Phase */
static inline R4SdkUpdateSlot R4SdkUpdateBatchPhase_parse(uint32_t reserved, const uint8_t * p0, uintptr_t n0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,257u,a,1u,0);
}
/* system_update_batch.PackageEntry.pathText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_pathText(uint32_t reserved, const R4SdkUpdateBatchPackageEntry * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,258u,a,1u,0);
}
/* system_update_batch.PackageEntry.packageText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_packageText(uint32_t reserved, const R4SdkUpdateBatchPackageEntry * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,259u,a,1u,0);
}
/* system_update_batch.PackageEntry.packageVersionText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_packageVersionText(uint32_t reserved, const R4SdkUpdateBatchPackageEntry * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,260u,a,1u,0);
}
/* system_update_batch.PackageEntry.releaseText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_releaseText(uint32_t reserved, const R4SdkUpdateBatchPackageEntry * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,261u,a,1u,0);
}
/* system_update_batch.BatchJournal.sourceReleaseText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_sourceReleaseText(uint32_t reserved, const R4SdkUpdateBatchBatchJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,262u,a,1u,0);
}
/* system_update_batch.BatchJournal.targetReleaseText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_targetReleaseText(uint32_t reserved, const R4SdkUpdateBatchBatchJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,263u,a,1u,0);
}
/* system_update_batch.BatchJournal.reasonText -> []const u8 */
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_reasonText(uint32_t reserved, const R4SdkUpdateBatchBatchJournal * p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,264u,a,1u,0);
}
/* update_catalog.CatalogRelease.packageComponents -> []const update_catalog.Component */
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_packageComponents(uint32_t reserved, const R4SdkUpdateCatalogCatalogRelease * p0, const R4SdkUpdateCatalogPackage * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,265u,a,2u,0);
}
/* update_catalog.CatalogRelease.packageRequirements -> []const update_catalog.Requirement */
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_packageRequirements(uint32_t reserved, const R4SdkUpdateCatalogCatalogRelease * p0, const R4SdkUpdateCatalogPackage * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,266u,a,2u,0);
}
/* update_catalog.Plan.packageIndex -> ?usize */
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_packageIndex(uint32_t reserved, const R4SdkUpdateCatalogPlan * p0, uint64_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,267u,a,2u,0);
}
/* update_callback_bridge.Table.has -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateCallbackTable_has(uint32_t reserved, const R4SdkUpdateCallbackTable * p0, uint32_t p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,268u,a,2u,0);
}
/* update_helper_adapters.Replay.persist -> bool */
static inline R4SdkUpdateSlot R4SdkUpdateReplay_persist(uint32_t reserved, R4SdkUpdateReplay * p0, R4SdkUpdateRecoveryTransactionJournal * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,269u,a,2u,0);
}
/* update_helper_adapters.Replay.rollbackPayload -> system_update_recovery.MutationStatus */
static inline R4SdkUpdateSlot R4SdkUpdateReplay_rollbackPayload(uint32_t reserved, R4SdkUpdateReplay * p0, const R4SdkUpdateRecoveryJournalPayload * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,270u,a,2u,0);
}
/* update_helper_adapters.Replay.commitPayload -> system_update_recovery.MutationStatus */
static inline R4SdkUpdateSlot R4SdkUpdateReplay_commitPayload(uint32_t reserved, R4SdkUpdateReplay * p0, const R4SdkUpdateRecoveryJournalPayload * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,271u,a,2u,0);
}
/* update_helper_adapters.Replay.cleanupPayload -> system_update_recovery.MutationStatus */
static inline R4SdkUpdateSlot R4SdkUpdateReplay_cleanupPayload(uint32_t reserved, R4SdkUpdateReplay * p0, const R4SdkUpdateRecoveryJournalPayload * p1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,272u,a,2u,0);
}
/* update_helper_adapters.Replay.pathState -> system_update_recovery.PathState */
static inline R4SdkUpdateSlot R4SdkUpdateReplay_pathState(uint32_t reserved, R4SdkUpdateReplay * p0, const uint8_t * p1, uintptr_t n1, uint64_t p2, uint32_t p3) {
 (void)reserved; R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,273u,a,4u,0);
}
/* update_helper_adapters.Replay.presence -> system_update_recovery.PresenceState */
static inline R4SdkUpdateSlot R4SdkUpdateReplay_presence(uint32_t reserved, R4SdkUpdateReplay * p0, const uint8_t * p1, uintptr_t n1) {
 (void)reserved; R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,274u,a,2u,0);
}
/* math.CompareOperator.reverse -> math.CompareOperator */
static inline R4SdkUpdateSlot R4SdkUpdateNative_math_CompareOperator_reverse(uint32_t reserved, uint32_t p0) {
 (void)reserved; R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateInvoke(R4SdkUpdate_ABI_FINGERPRINT,275u,a,1u,0);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_create(R4SdkUpdateNtfsMetadata *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, const uint8_t * p5, uintptr_t n5, const uint8_t * p6, uintptr_t n6, const uint8_t * p7, uintptr_t n7, const uint8_t * p8, uintptr_t n8, const uint8_t * p9, uintptr_t n9, const uint8_t * p10, uintptr_t n10, const uint8_t * p11, uintptr_t n11, const uint8_t * p12, uintptr_t n12, const uint8_t * p13, uintptr_t n13, const uint8_t * p14, uintptr_t n14, const uint8_t * p15, uintptr_t n15) {
 R4SdkUpdateSlot a[20]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.ptr=(void *)p7,.length=n7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.ptr=(void *)p8,.length=n8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.ptr=(void *)p9,.length=n9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.ptr=(void *)p10,.length=n10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.ptr=(void *)p11,.length=n11,.flags=R4SDKUPDATE_PRESENT};
 a[12] = (R4SdkUpdateSlot){.ptr=(void *)p12,.length=n12,.flags=R4SDKUPDATE_PRESENT};
 a[13] = (R4SdkUpdateSlot){.ptr=(void *)p13,.length=n13,.flags=R4SDKUPDATE_PRESENT};
 a[14] = (R4SdkUpdateSlot){.ptr=(void *)p14,.length=n14,.flags=R4SDKUPDATE_PRESENT};
 a[15] = (R4SdkUpdateSlot){.ptr=(void *)p15,.length=n15,.flags=R4SDKUPDATE_PRESENT};
 a[16].flags=R4SDKUPDATE_DEFAULT;
 a[17].flags=R4SDKUPDATE_DEFAULT;
 a[18].flags=R4SDKUPDATE_DEFAULT;
 a[19].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,0u,a,20u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_from_fields(R4SdkUpdateNtfsMetadata *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, const uint8_t * p5, uintptr_t n5, const uint8_t * p6, uintptr_t n6, const uint8_t * p7, uintptr_t n7, const uint8_t * p8, uintptr_t n8, const uint8_t * p9, uintptr_t n9, const uint8_t * p10, uintptr_t n10, const uint8_t * p11, uintptr_t n11, const uint8_t * p12, uintptr_t n12, const uint8_t * p13, uintptr_t n13, const uint8_t * p14, uintptr_t n14, const uint8_t * p15, uintptr_t n15, uint32_t p16, uint32_t p17, uint32_t p18, uint32_t p19) {
 R4SdkUpdateSlot a[20]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.ptr=(void *)p7,.length=n7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.ptr=(void *)p8,.length=n8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.ptr=(void *)p9,.length=n9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.ptr=(void *)p10,.length=n10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.ptr=(void *)p11,.length=n11,.flags=R4SDKUPDATE_PRESENT};
 a[12] = (R4SdkUpdateSlot){.ptr=(void *)p12,.length=n12,.flags=R4SDKUPDATE_PRESENT};
 a[13] = (R4SdkUpdateSlot){.ptr=(void *)p13,.length=n13,.flags=R4SDKUPDATE_PRESENT};
 a[14] = (R4SdkUpdateSlot){.ptr=(void *)p14,.length=n14,.flags=R4SDKUPDATE_PRESENT};
 a[15] = (R4SdkUpdateSlot){.ptr=(void *)p15,.length=n15,.flags=R4SDKUPDATE_PRESENT};
 a[16] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p16,.flags=R4SDKUPDATE_PRESENT};
 a[17] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p17,.flags=R4SDKUPDATE_PRESENT};
 a[18] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p18,.flags=R4SDKUPDATE_PRESENT};
 a[19] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p19,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,0u,a,20u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_upcase(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_upcase(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_upcase_info(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_upcase_info(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_attrdef(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_attrdef(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_sds_prefix(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_sds_prefix(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_sdh_root(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_sdh_root(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_sii_root(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_sii_root(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_sdh_alloc(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_sdh_alloc(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_sii_alloc(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_sii_alloc(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_sdh_bitmap(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_sdh_bitmap(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_sii_bitmap(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_sii_bitmap(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_objid_o_root(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,10u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_objid_o_root(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_quota_o_root(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,11u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_quota_o_root(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,11u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_quota_q_root(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,12u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_quota_q_root(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,12u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_reparse_r_root(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,13u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_reparse_r_root(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,13u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_root_sd(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,14u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_root_sd(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,14u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_boot_sd(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,15u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_boot_sd(R4SdkUpdateNtfsMetadata *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,15u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_security_id_file(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,16u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_security_id_file(R4SdkUpdateNtfsMetadata *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,16u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_security_id_dir(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,17u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_security_id_dir(R4SdkUpdateNtfsMetadata *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,17u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_security_id_sys(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,18u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_security_id_sys(R4SdkUpdateNtfsMetadata *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,18u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_get_security_id_sys_dir(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,19u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_set_security_id_sys_dir(R4SdkUpdateNtfsMetadata *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,0u,19u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsMetadata_inspectNative(const R4SdkUpdateNtfsMetadata *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,0u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockPhase_create(R4SdkUpdateBlockPhase *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,2u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockPhase_inspectNative(const R4SdkUpdateBlockPhase *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,2u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_create(R4SdkUpdateBlockProgress *output) {
 R4SdkUpdateSlot a[8]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,3u,a,8u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_from_fields(R4SdkUpdateBlockProgress *output, uint32_t p0, uint8_t p1, uint64_t p2, uint8_t p3, uint8_t p4, R4SdkUpdateSlot p5, R4SdkUpdateSlot p6, int32_t p7) {
 R4SdkUpdateSlot a[8]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = p5;
 a[6] = p6;
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,3u,a,8u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_get_phase(const R4SdkUpdateBlockProgress *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_set_phase(R4SdkUpdateBlockProgress *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_get_write_attempted(const R4SdkUpdateBlockProgress *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_set_write_attempted(R4SdkUpdateBlockProgress *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_get_written_sectors(const R4SdkUpdateBlockProgress *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_set_written_sectors(R4SdkUpdateBlockProgress *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_get_flushed(const R4SdkUpdateBlockProgress *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_set_flushed(R4SdkUpdateBlockProgress *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_get_verified(const R4SdkUpdateBlockProgress *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_set_verified(R4SdkUpdateBlockProgress *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_get_failed_lba(const R4SdkUpdateBlockProgress *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_set_failed_lba(R4SdkUpdateBlockProgress *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_get_failure(const R4SdkUpdateBlockProgress *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_set_failure(R4SdkUpdateBlockProgress *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_get_native_error(const R4SdkUpdateBlockProgress *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_set_native_error(R4SdkUpdateBlockProgress *self, int32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,3u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockProgress_inspectNative(const R4SdkUpdateBlockProgress *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,3u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue4_create(R4SdkUpdateNativeValue4 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,4u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue4_inspectNative(const R4SdkUpdateNativeValue4 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,4u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue5_create(R4SdkUpdateNativeValue5 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,5u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue5_inspectNative(const R4SdkUpdateNativeValue5 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,5u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_create(R4SdkUpdateBlockDevice *output, void * p0, uint64_t p1, uintptr_t p4, uintptr_t p5, uintptr_t p6) {
 R4SdkUpdateSlot a[10]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7].flags=R4SDKUPDATE_DEFAULT;
 a[8].flags=R4SDKUPDATE_DEFAULT;
 a[9].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,6u,a,10u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_from_fields(R4SdkUpdateBlockDevice *output, void * p0, uint64_t p1, uint32_t p2, uint8_t p3, uintptr_t p4, uintptr_t p5, uintptr_t p6, R4SdkUpdateSlot p7, R4SdkUpdateSlot p8, R4SdkUpdateSlot p9) {
 R4SdkUpdateSlot a[10]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = p7;
 a[8] = p8;
 a[9] = p9;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,6u,a,10u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_get_context(const R4SdkUpdateBlockDevice *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_set_context(R4SdkUpdateBlockDevice *self, void * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_get_sectors(const R4SdkUpdateBlockDevice *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_set_sectors(R4SdkUpdateBlockDevice *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_get_sector_bytes(const R4SdkUpdateBlockDevice *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_set_sector_bytes(R4SdkUpdateBlockDevice *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_get_exclusive(const R4SdkUpdateBlockDevice *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_set_exclusive(R4SdkUpdateBlockDevice *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_get_read_fn(const R4SdkUpdateBlockDevice *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_set_read_fn(R4SdkUpdateBlockDevice *self, uintptr_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_get_write_fn(const R4SdkUpdateBlockDevice *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_set_write_fn(R4SdkUpdateBlockDevice *self, uintptr_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_get_flush_fn(const R4SdkUpdateBlockDevice *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_set_flush_fn(R4SdkUpdateBlockDevice *self, uintptr_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_get_progress(const R4SdkUpdateBlockDevice *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_set_progress(R4SdkUpdateBlockDevice *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_get_cancel_context(const R4SdkUpdateBlockDevice *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_set_cancel_context(R4SdkUpdateBlockDevice *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_get_continue_fn(const R4SdkUpdateBlockDevice *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_set_continue_fn(R4SdkUpdateBlockDevice *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,6u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockDevice_inspectNative(const R4SdkUpdateBlockDevice *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,6u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue7_create(R4SdkUpdateNativeValue7 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,7u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue7_inspectNative(const R4SdkUpdateNativeValue7 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,7u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue8_create(R4SdkUpdateNativeValue8 *output, R4SdkUpdateBlockProgress * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,8u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue8_inspectNative(const R4SdkUpdateNativeValue8 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,8u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue10_create(R4SdkUpdateNativeValue10 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,10u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue10_inspectNative(const R4SdkUpdateNativeValue10 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,10u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockRegion_create(R4SdkUpdateBlockRegion *output, const R4SdkUpdateBlockDevice * p0, uint64_t p1, uint64_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,11u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBlockRegion_from_fields(R4SdkUpdateBlockRegion *output, const R4SdkUpdateBlockDevice * p0, uint64_t p1, uint64_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,11u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBlockRegion_get_parent(const R4SdkUpdateBlockRegion *self, R4SdkUpdateBlockDevice *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,11u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockRegion_set_parent(R4SdkUpdateBlockRegion *self, const R4SdkUpdateBlockDevice * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,11u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockRegion_get_first(const R4SdkUpdateBlockRegion *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,11u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockRegion_set_first(R4SdkUpdateBlockRegion *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,11u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockRegion_get_count(const R4SdkUpdateBlockRegion *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,11u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockRegion_set_count(R4SdkUpdateBlockRegion *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,11u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockRegion_inspectNative(const R4SdkUpdateBlockRegion *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,11u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockMemory_create(R4SdkUpdateBlockMemory *output, uint8_t * p0, uintptr_t n0) {
 R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,12u,a,1u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBlockMemory_from_fields(R4SdkUpdateBlockMemory *output, uint8_t * p0, uintptr_t n0) {
 R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,12u,a,1u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBlockMemory_get_bytes(const R4SdkUpdateBlockMemory *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,12u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockMemory_set_bytes(R4SdkUpdateBlockMemory *self, uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,12u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBlockMemory_inspectNative(const R4SdkUpdateBlockMemory *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,12u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_create(R4SdkUpdateByteSource *output, const void * p0, uint64_t p1, uintptr_t p3) {
 R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,14u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_from_fields(R4SdkUpdateByteSource *output, const void * p0, uint64_t p1, uint64_t p2, uintptr_t p3) {
 R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,14u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_get_context(const R4SdkUpdateByteSource *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,14u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_set_context(R4SdkUpdateByteSource *self, const void * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,14u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_get_length(const R4SdkUpdateByteSource *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,14u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_set_length(R4SdkUpdateByteSource *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,14u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_get_offset(const R4SdkUpdateByteSource *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,14u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_set_offset(R4SdkUpdateByteSource *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,14u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_get_read_fn(const R4SdkUpdateByteSource *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,14u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_set_read_fn(R4SdkUpdateByteSource *self, uintptr_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,14u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateByteSource_inspectNative(const R4SdkUpdateByteSource *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,14u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_create(R4SdkUpdateStoragesparse_image_Image *output, const R4SdkDataAllocator * p0, uint64_t p1, R4SdkDataNative_Value109 * p2, uintptr_t n2) {
 R4SdkUpdateSlot a[8]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,15u,a,8u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_from_fields(R4SdkUpdateStoragesparse_image_Image *output, const R4SdkDataAllocator * p0, uint64_t p1, R4SdkDataNative_Value109 * p2, uintptr_t n2, uint64_t p3, uint64_t p4, const R4SdkUpdateNativeValue19 * p5, uint64_t p6, uint8_t p7) {
 R4SdkUpdateSlot a[8]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.ptr=(void *)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,15u,a,8u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_get_allocator(const R4SdkUpdateStoragesparse_image_Image *self, R4SdkDataAllocator *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_set_allocator(R4SdkUpdateStoragesparse_image_Image *self, const R4SdkDataAllocator * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_get_length(const R4SdkUpdateStoragesparse_image_Image *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_set_length(R4SdkUpdateStoragesparse_image_Image *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_get_blocks(const R4SdkUpdateStoragesparse_image_Image *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_set_blocks(R4SdkUpdateStoragesparse_image_Image *self, R4SdkDataNative_Value109 * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_get_written(const R4SdkUpdateStoragesparse_image_Image *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_set_written(R4SdkUpdateStoragesparse_image_Image *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_get_stored_bytes(const R4SdkUpdateStoragesparse_image_Image *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_set_stored_bytes(R4SdkUpdateStoragesparse_image_Image *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_get_pending(const R4SdkUpdateStoragesparse_image_Image *self, R4SdkUpdateNativeValue19 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,5u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_set_pending(R4SdkUpdateStoragesparse_image_Image *self, const R4SdkUpdateNativeValue19 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_get_pending_bytes(const R4SdkUpdateStoragesparse_image_Image *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_set_pending_bytes(R4SdkUpdateStoragesparse_image_Image *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_get_complete(const R4SdkUpdateStoragesparse_image_Image *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_set_complete(R4SdkUpdateStoragesparse_image_Image *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,15u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragesparse_image_Image_inspectNative(const R4SdkUpdateStoragesparse_image_Image *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,15u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue17_create(R4SdkUpdateNativeValue17 *output, R4SdkDataNative_Value109 * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,17u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue17_inspectNative(const R4SdkUpdateNativeValue17 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,17u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue19_create(R4SdkUpdateNativeValue19 *output, const R4SdkUpdateNativeValue19 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,19u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue19_inspectNative(const R4SdkUpdateNativeValue19 *self, R4SdkUpdateNativeValue19 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,19u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue21_create(R4SdkUpdateNativeValue21 *output, R4SdkUpdateHostFile * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,21u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue21_inspectNative(const R4SdkUpdateNativeValue21 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,21u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue22_inspectNative(const R4SdkUpdateNativeValue22 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,22u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue23_inspectNative(const R4SdkUpdateNativeValue23 *self, R4SdkUpdateBlockDevice *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,23u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionKind_create(R4SdkUpdatePartitionKind *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,24u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionKind_inspectNative(const R4SdkUpdatePartitionKind *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,24u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionRange_create(R4SdkUpdatePartitionRange *output, uint64_t p0, uint64_t p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,25u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdatePartitionRange_from_fields(R4SdkUpdatePartitionRange *output, uint64_t p0, uint64_t p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,25u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdatePartitionRange_get_first(const R4SdkUpdatePartitionRange *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,25u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionRange_set_first(R4SdkUpdatePartitionRange *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,25u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionRange_get_count(const R4SdkUpdatePartitionRange *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,25u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionRange_set_count(R4SdkUpdatePartitionRange *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,25u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionRange_inspectNative(const R4SdkUpdatePartitionRange *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,25u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_create(R4SdkUpdatePartitionEntry *output) {
 R4SdkUpdateSlot a[10]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 a[8].flags=R4SDKUPDATE_DEFAULT;
 a[9].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,26u,a,10u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_from_fields(R4SdkUpdatePartitionEntry *output, uint8_t p0, uint64_t p1, uint64_t p2, const R4SdkUpdateNativeValue27 * p3, const R4SdkUpdateNativeValue27 * p4, uint64_t p5, const R4SdkUpdateNativeValue28 * p6, uint8_t p7, uint8_t p8, const R4SdkUpdateNativeValue27 * p9) {
 R4SdkUpdateSlot a[10]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.ptr=(void *)p9,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,26u,a,10u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_get_present(const R4SdkUpdatePartitionEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_set_present(R4SdkUpdatePartitionEntry *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_get_first(const R4SdkUpdatePartitionEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_set_first(R4SdkUpdatePartitionEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_get_count(const R4SdkUpdatePartitionEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_set_count(R4SdkUpdatePartitionEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_get_type_guid(const R4SdkUpdatePartitionEntry *self, R4SdkUpdateNativeValue27 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,3u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_set_type_guid(R4SdkUpdatePartitionEntry *self, const R4SdkUpdateNativeValue27 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_get_unique_guid(const R4SdkUpdatePartitionEntry *self, R4SdkUpdateNativeValue27 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,4u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_set_unique_guid(R4SdkUpdatePartitionEntry *self, const R4SdkUpdateNativeValue27 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_get_attributes(const R4SdkUpdatePartitionEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_set_attributes(R4SdkUpdatePartitionEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_get_name(const R4SdkUpdatePartitionEntry *self, R4SdkUpdateNativeValue28 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,6u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_set_name(R4SdkUpdatePartitionEntry *self, const R4SdkUpdateNativeValue28 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_get_mbr_type(const R4SdkUpdatePartitionEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_set_mbr_type(R4SdkUpdatePartitionEntry *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_get_active(const R4SdkUpdatePartitionEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_set_active(R4SdkUpdatePartitionEntry *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_get_mbr_original(const R4SdkUpdatePartitionEntry *self, R4SdkUpdateNativeValue27 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,9u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_set_mbr_original(R4SdkUpdatePartitionEntry *self, const R4SdkUpdateNativeValue27 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,26u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionEntry_inspectNative(const R4SdkUpdatePartitionEntry *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,26u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue27_create(R4SdkUpdateNativeValue27 *output, const R4SdkUpdateNativeValue27 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,27u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue27_inspectNative(const R4SdkUpdateNativeValue27 *self, R4SdkUpdateNativeValue27 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,27u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue28_create(R4SdkUpdateNativeValue28 *output, const R4SdkUpdateNativeValue28 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,28u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue28_inspectNative(const R4SdkUpdateNativeValue28 *self, R4SdkUpdateNativeValue28 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,28u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_create(R4SdkUpdatePartitionPlan *output, uint64_t p0, uint64_t p6) {
 R4SdkUpdateSlot a[14]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7].flags=R4SDKUPDATE_DEFAULT;
 a[8].flags=R4SDKUPDATE_DEFAULT;
 a[9].flags=R4SDKUPDATE_DEFAULT;
 a[10].flags=R4SDKUPDATE_DEFAULT;
 a[11].flags=R4SDKUPDATE_DEFAULT;
 a[12].flags=R4SDKUPDATE_DEFAULT;
 a[13].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,29u,a,14u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_from_fields(R4SdkUpdatePartitionPlan *output, uint64_t p0, uint32_t p1, uint8_t p2, const R4SdkUpdateNativeValue27 * p3, uint32_t p4, uint64_t p5, uint64_t p6, uint32_t p7, uint64_t p8, uint64_t p9, const R4SdkUpdateNativeValue30 * p10, const R4SdkUpdateNativeValue31 * p11, const R4SdkUpdatePartitionSource * p12, uint8_t p13) {
 R4SdkUpdateSlot a[14]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.ptr=(void *)p10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.ptr=(void *)p11,.flags=R4SDKUPDATE_PRESENT};
 a[12] = (R4SdkUpdateSlot){.ptr=(void *)p12,.flags=R4SDKUPDATE_PRESENT};
 a[13] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,29u,a,14u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_sectors(const R4SdkUpdatePartitionPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_sectors(R4SdkUpdatePartitionPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_kind(const R4SdkUpdatePartitionPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_kind(R4SdkUpdatePartitionPlan *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_blank(const R4SdkUpdatePartitionPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_blank(R4SdkUpdatePartitionPlan *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_disk_guid(const R4SdkUpdatePartitionPlan *self, R4SdkUpdateNativeValue27 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,3u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_disk_guid(R4SdkUpdatePartitionPlan *self, const R4SdkUpdateNativeValue27 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_disk_id(const R4SdkUpdatePartitionPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_disk_id(R4SdkUpdatePartitionPlan *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_first_usable(const R4SdkUpdatePartitionPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_first_usable(R4SdkUpdatePartitionPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_last_usable(const R4SdkUpdatePartitionPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_last_usable(R4SdkUpdatePartitionPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_entry_count(const R4SdkUpdatePartitionPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_entry_count(R4SdkUpdatePartitionPlan *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_primary_array(const R4SdkUpdatePartitionPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_primary_array(R4SdkUpdatePartitionPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_backup_array(const R4SdkUpdatePartitionPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_backup_array(R4SdkUpdatePartitionPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_mbr_prefix(const R4SdkUpdatePartitionPlan *self, R4SdkUpdateNativeValue30 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,10u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_mbr_prefix(R4SdkUpdatePartitionPlan *self, const R4SdkUpdateNativeValue30 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_entries(const R4SdkUpdatePartitionPlan *self, R4SdkUpdateNativeValue31 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,11u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_entries(R4SdkUpdatePartitionPlan *self, const R4SdkUpdateNativeValue31 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,11u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_source(const R4SdkUpdatePartitionPlan *self, R4SdkUpdatePartitionSource *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,12u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_source(R4SdkUpdatePartitionPlan *self, const R4SdkUpdatePartitionSource * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,12u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_get_erase_source_gpt(const R4SdkUpdatePartitionPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,13u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_set_erase_source_gpt(R4SdkUpdatePartitionPlan *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,29u,13u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionPlan_inspectNative(const R4SdkUpdatePartitionPlan *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,29u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue30_create(R4SdkUpdateNativeValue30 *output, const R4SdkUpdateNativeValue30 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,30u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue30_inspectNative(const R4SdkUpdateNativeValue30 *self, R4SdkUpdateNativeValue30 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,30u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue31_create(R4SdkUpdateNativeValue31 *output, const R4SdkUpdateNativeValue31 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,31u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue31_inspectNative(const R4SdkUpdateNativeValue31 *self, R4SdkUpdateNativeValue31 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,31u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionSource_create(R4SdkUpdatePartitionSource *output) {
 R4SdkUpdateSlot a[3]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,32u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdatePartitionSource_from_fields(R4SdkUpdatePartitionSource *output, const R4SdkUpdateNativeValue33 * p0, uint64_t p1, const R4SdkDataNative_Value158 * p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,32u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdatePartitionSource_get_spans(const R4SdkUpdatePartitionSource *self, R4SdkUpdateNativeValue33 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,32u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionSource_set_spans(R4SdkUpdatePartitionSource *self, const R4SdkUpdateNativeValue33 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,32u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionSource_get_count(const R4SdkUpdatePartitionSource *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,32u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionSource_set_count(R4SdkUpdatePartitionSource *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,32u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionSource_get_digest(const R4SdkUpdatePartitionSource *self, R4SdkDataNative_Value158 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,32u,2u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionSource_set_digest(R4SdkUpdatePartitionSource *self, const R4SdkDataNative_Value158 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,32u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdatePartitionSource_inspectNative(const R4SdkUpdatePartitionSource *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,32u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue33_create(R4SdkUpdateNativeValue33 *output, const R4SdkUpdateNativeValue33 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,33u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue33_inspectNative(const R4SdkUpdateNativeValue33 *self, R4SdkUpdateNativeValue33 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,33u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue35_inspectNative(const R4SdkUpdateNativeValue35 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,35u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue36_inspectNative(const R4SdkUpdateNativeValue36 *self, R4SdkUpdateNativeValue28 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,36u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue37_create(R4SdkUpdateNativeValue37 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,37u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue37_inspectNative(const R4SdkUpdateNativeValue37 *self, R4SdkUpdateNativeValue27 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,37u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue38_create(R4SdkUpdateNativeValue38 *output, const R4SdkUpdateNativeValue38 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,38u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue38_inspectNative(const R4SdkUpdateNativeValue38 *self, R4SdkUpdateNativeValue38 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,38u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_create(R4SdkUpdateFat32Geometry *output, uint32_t p0, uint32_t p1, uint32_t p2, uint32_t p3, uint32_t p4, uint32_t p5) {
 R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,39u,a,6u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_from_fields(R4SdkUpdateFat32Geometry *output, uint32_t p0, uint32_t p1, uint32_t p2, uint32_t p3, uint32_t p4, uint32_t p5) {
 R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,39u,a,6u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_get_sectors(const R4SdkUpdateFat32Geometry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,39u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_set_sectors(R4SdkUpdateFat32Geometry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,39u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_get_hidden(const R4SdkUpdateFat32Geometry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,39u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_set_hidden(R4SdkUpdateFat32Geometry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,39u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_get_sectors_per_cluster(const R4SdkUpdateFat32Geometry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,39u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_set_sectors_per_cluster(R4SdkUpdateFat32Geometry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,39u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_get_sectors_per_fat(const R4SdkUpdateFat32Geometry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,39u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_set_sectors_per_fat(R4SdkUpdateFat32Geometry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,39u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_get_data_start(const R4SdkUpdateFat32Geometry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,39u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_set_data_start(R4SdkUpdateFat32Geometry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,39u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_get_clusters(const R4SdkUpdateFat32Geometry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,39u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_set_clusters(R4SdkUpdateFat32Geometry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,39u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Geometry_inspectNative(const R4SdkUpdateFat32Geometry *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,39u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Plan_create(R4SdkUpdateFat32Plan *output, const R4SdkUpdateFat32Geometry * p0, const R4SdkUpdateNativeValue41 * p1, uint32_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,40u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateFat32Plan_from_fields(R4SdkUpdateFat32Plan *output, const R4SdkUpdateFat32Geometry * p0, const R4SdkUpdateNativeValue41 * p1, uint32_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,40u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateFat32Plan_get_geometry(const R4SdkUpdateFat32Plan *self, R4SdkUpdateFat32Geometry *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,40u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Plan_set_geometry(R4SdkUpdateFat32Plan *self, const R4SdkUpdateFat32Geometry * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,40u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Plan_get_label(const R4SdkUpdateFat32Plan *self, R4SdkUpdateNativeValue41 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,40u,1u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Plan_set_label(R4SdkUpdateFat32Plan *self, const R4SdkUpdateNativeValue41 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,40u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Plan_get_serial(const R4SdkUpdateFat32Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,40u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Plan_set_serial(R4SdkUpdateFat32Plan *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,40u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateFat32Plan_inspectNative(const R4SdkUpdateFat32Plan *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,40u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue41_create(R4SdkUpdateNativeValue41 *output, const R4SdkUpdateNativeValue41 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,41u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue41_inspectNative(const R4SdkUpdateNativeValue41 *self, R4SdkUpdateNativeValue41 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,41u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue42_create(R4SdkUpdateNativeValue42 *output, const R4SdkUpdateNativeValue42 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,42u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue42_inspectNative(const R4SdkUpdateNativeValue42 *self, R4SdkUpdateNativeValue42 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,42u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue43_inspectNative(const R4SdkUpdateNativeValue43 *self, R4SdkUpdateNativeValue41 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,43u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_File_create(R4SdkUpdateStoragefat32_image_File *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,44u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_File_from_fields(R4SdkUpdateStoragefat32_image_File *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,44u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_File_get_path(const R4SdkUpdateStoragefat32_image_File *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,44u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_File_set_path(R4SdkUpdateStoragefat32_image_File *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,44u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_File_get_bytes(const R4SdkUpdateStoragefat32_image_File *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,44u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_File_set_bytes(R4SdkUpdateStoragefat32_image_File *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,44u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_File_inspectNative(const R4SdkUpdateStoragefat32_image_File *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,44u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Stats_create(R4SdkUpdateStoragefat32_image_Stats *output, const R4SdkUpdateFat32Geometry * p0, uint32_t p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,45u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Stats_from_fields(R4SdkUpdateStoragefat32_image_Stats *output, const R4SdkUpdateFat32Geometry * p0, uint32_t p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,45u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Stats_get_geometry(const R4SdkUpdateStoragefat32_image_Stats *self, R4SdkUpdateFat32Geometry *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,45u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Stats_set_geometry(R4SdkUpdateStoragefat32_image_Stats *self, const R4SdkUpdateFat32Geometry * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,45u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Stats_get_used_sectors(const R4SdkUpdateStoragefat32_image_Stats *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,45u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Stats_set_used_sectors(R4SdkUpdateStoragefat32_image_Stats *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,45u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Stats_inspectNative(const R4SdkUpdateStoragefat32_image_Stats *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,45u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_create(R4SdkUpdateStoragefat32_image_Streamed *output, const R4SdkDataAllocator * p0, uint8_t * p1, uintptr_t n1, const R4SdkUpdateNative_array_list_Aligned_storage_tools_fat32_image_Streamed_Segment_null_ * p2, const R4SdkUpdateStoragefat32_image_Stats * p3) {
 R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,46u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_from_fields(R4SdkUpdateStoragefat32_image_Streamed *output, const R4SdkDataAllocator * p0, uint8_t * p1, uintptr_t n1, const R4SdkUpdateNative_array_list_Aligned_storage_tools_fat32_image_Streamed_Segment_null_ * p2, const R4SdkUpdateStoragefat32_image_Stats * p3) {
 R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,46u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_get_allocator(const R4SdkUpdateStoragefat32_image_Streamed *self, R4SdkDataAllocator *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,46u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_set_allocator(R4SdkUpdateStoragefat32_image_Streamed *self, const R4SdkDataAllocator * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,46u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_get_metadata(const R4SdkUpdateStoragefat32_image_Streamed *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,46u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_set_metadata(R4SdkUpdateStoragefat32_image_Streamed *self, uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,46u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_get_segments(const R4SdkUpdateStoragefat32_image_Streamed *self, R4SdkUpdateNative_array_list_Aligned_storage_tools_fat32_image_Streamed_Segment_null_ *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,46u,2u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_set_segments(R4SdkUpdateStoragefat32_image_Streamed *self, const R4SdkUpdateNative_array_list_Aligned_storage_tools_fat32_image_Streamed_Segment_null_ * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,46u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_get_stats(const R4SdkUpdateStoragefat32_image_Streamed *self, R4SdkUpdateStoragefat32_image_Stats *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,46u,3u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_set_stats(R4SdkUpdateStoragefat32_image_Streamed *self, const R4SdkUpdateStoragefat32_image_Stats * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,46u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Streamed_inspectNative(const R4SdkUpdateStoragefat32_image_Streamed *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,46u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Prepared_create(R4SdkUpdateStoragefat32_image_Prepared *output, const R4SdkDataAllocator * p0, uint8_t * p1, uintptr_t n1, const R4SdkUpdateStoragefat32_image_Stats * p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,48u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Prepared_from_fields(R4SdkUpdateStoragefat32_image_Prepared *output, const R4SdkDataAllocator * p0, uint8_t * p1, uintptr_t n1, const R4SdkUpdateStoragefat32_image_Stats * p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,48u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Prepared_get_allocator(const R4SdkUpdateStoragefat32_image_Prepared *self, R4SdkDataAllocator *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,48u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Prepared_set_allocator(R4SdkUpdateStoragefat32_image_Prepared *self, const R4SdkDataAllocator * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,48u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Prepared_get_bytes(const R4SdkUpdateStoragefat32_image_Prepared *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,48u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Prepared_set_bytes(R4SdkUpdateStoragefat32_image_Prepared *self, uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,48u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Prepared_get_stats(const R4SdkUpdateStoragefat32_image_Prepared *self, R4SdkUpdateStoragefat32_image_Stats *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,48u,2u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Prepared_set_stats(R4SdkUpdateStoragefat32_image_Prepared *self, const R4SdkUpdateStoragefat32_image_Stats * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,48u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_image_Prepared_inspectNative(const R4SdkUpdateStoragefat32_image_Prepared *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,48u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue49_create(R4SdkUpdateNativeValue49 *output, const R4SdkUpdateStoragefat32_image_File * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,49u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue49_inspectNative(const R4SdkUpdateNativeValue49 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,49u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue50_inspectNative(const R4SdkUpdateNativeValue50 *self, R4SdkUpdateStoragefat32_image_Prepared *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,50u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue51_inspectNative(const R4SdkUpdateNativeValue51 *self, R4SdkUpdateStoragefat32_image_Stats *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,51u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue52_inspectNative(const R4SdkUpdateNativeValue52 *self, R4SdkUpdateStoragefat32_image_Streamed *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,52u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_view_View_create(R4SdkUpdateStoragefat32_view_View *output, const R4SdkUpdateByteSource * p0, const R4SdkUpdateFat32Geometry * p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,53u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_view_View_from_fields(R4SdkUpdateStoragefat32_view_View *output, const R4SdkUpdateByteSource * p0, const R4SdkUpdateFat32Geometry * p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,53u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_view_View_get_source(const R4SdkUpdateStoragefat32_view_View *self, R4SdkUpdateByteSource *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,53u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_view_View_set_source(R4SdkUpdateStoragefat32_view_View *self, const R4SdkUpdateByteSource * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,53u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_view_View_get_geometry(const R4SdkUpdateStoragefat32_view_View *self, R4SdkUpdateFat32Geometry *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,53u,1u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_view_View_set_geometry(R4SdkUpdateStoragefat32_view_View *self, const R4SdkUpdateFat32Geometry * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,53u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_view_View_inspectNative(const R4SdkUpdateStoragefat32_view_View *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,53u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Change_create(R4SdkUpdateStoragefat32_update_Change *output, const uint8_t * p0, uintptr_t n0, R4SdkUpdateSlot p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = p1;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,54u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Change_from_fields(R4SdkUpdateStoragefat32_update_Change *output, const uint8_t * p0, uintptr_t n0, R4SdkUpdateSlot p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = p1;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,54u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Change_get_path(const R4SdkUpdateStoragefat32_update_Change *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,54u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Change_set_path(R4SdkUpdateStoragefat32_update_Change *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,54u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Change_get_bytes(const R4SdkUpdateStoragefat32_update_Change *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,54u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Change_set_bytes(R4SdkUpdateStoragefat32_update_Change *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,54u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Change_inspectNative(const R4SdkUpdateStoragefat32_update_Change *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,54u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_create(R4SdkUpdateStoragefat32_update_Backing *output, const R4SdkDataAllocator * p0, const R4SdkUpdateByteSource * p1, const R4SdkUpdateFat32Geometry * p2, uint8_t * p3, uintptr_t n3, R4SdkDataNative_Value5 * p4, uintptr_t n4) {
 R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,55u,a,6u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_from_fields(R4SdkUpdateStoragefat32_update_Backing *output, const R4SdkDataAllocator * p0, const R4SdkUpdateByteSource * p1, const R4SdkUpdateFat32Geometry * p2, uint8_t * p3, uintptr_t n3, R4SdkDataNative_Value5 * p4, uintptr_t n4, const R4SdkUpdateNative_array_list_Aligned___u8_null_ * p5) {
 R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.ptr=(void *)p5,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,55u,a,6u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_get_allocator(const R4SdkUpdateStoragefat32_update_Backing *self, R4SdkDataAllocator *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,55u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_set_allocator(R4SdkUpdateStoragefat32_update_Backing *self, const R4SdkDataAllocator * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,55u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_get_original(const R4SdkUpdateStoragefat32_update_Backing *self, R4SdkUpdateByteSource *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,55u,1u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_set_original(R4SdkUpdateStoragefat32_update_Backing *self, const R4SdkUpdateByteSource * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,55u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_get_geometry(const R4SdkUpdateStoragefat32_update_Backing *self, R4SdkUpdateFat32Geometry *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,55u,2u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_set_geometry(R4SdkUpdateStoragefat32_update_Backing *self, const R4SdkUpdateFat32Geometry * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,55u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_get_metadata(const R4SdkUpdateStoragefat32_update_Backing *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,55u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_set_metadata(R4SdkUpdateStoragefat32_update_Backing *self, uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,55u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_get_clusters(const R4SdkUpdateStoragefat32_update_Backing *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,55u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_set_clusters(R4SdkUpdateStoragefat32_update_Backing *self, R4SdkDataNative_Value5 * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,55u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_get_cached(const R4SdkUpdateStoragefat32_update_Backing *self, R4SdkUpdateNative_array_list_Aligned___u8_null_ *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,55u,5u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_set_cached(R4SdkUpdateStoragefat32_update_Backing *self, const R4SdkUpdateNative_array_list_Aligned___u8_null_ * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,55u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Backing_inspectNative(const R4SdkUpdateStoragefat32_update_Backing *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,55u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue56_create(R4SdkUpdateNativeValue56 *output, R4SdkDataNative_Value5 * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,56u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue56_inspectNative(const R4SdkUpdateNativeValue56 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,56u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue59_create(R4SdkUpdateNativeValue59 *output, R4SdkUpdateStoragefat32_update_Backing * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,59u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue59_inspectNative(const R4SdkUpdateNativeValue59 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,59u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue60_create(R4SdkUpdateNativeValue60 *output, const R4SdkUpdateStoragefat32_update_Change * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,60u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue60_inspectNative(const R4SdkUpdateNativeValue60 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,60u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue61_inspectNative(const R4SdkUpdateNativeValue61 *self, R4SdkUpdateStoragefat32_update_Prepared *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,61u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_create(R4SdkUpdateStoragefat32_update_Prepared *output, const R4SdkDataAllocator * p0, uint8_t * p1, uintptr_t n1, R4SdkUpdateStoragefat32_update_Write * p2, uintptr_t n2, const R4SdkDataNative_Value158 * p3, uint64_t p5) {
 R4SdkUpdateSlot a[8]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,62u,a,8u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_from_fields(R4SdkUpdateStoragefat32_update_Prepared *output, const R4SdkDataAllocator * p0, uint8_t * p1, uintptr_t n1, R4SdkUpdateStoragefat32_update_Write * p2, uintptr_t n2, const R4SdkDataNative_Value158 * p3, R4SdkUpdateStoragefat32_update_SourceRange * p4, uintptr_t n4, uint64_t p5, uint64_t p6, uint8_t p7) {
 R4SdkUpdateSlot a[8]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,62u,a,8u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_get_allocator(const R4SdkUpdateStoragefat32_update_Prepared *self, R4SdkDataAllocator *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_set_allocator(R4SdkUpdateStoragefat32_update_Prepared *self, const R4SdkDataAllocator * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_get_bytes(const R4SdkUpdateStoragefat32_update_Prepared *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_set_bytes(R4SdkUpdateStoragefat32_update_Prepared *self, uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_get_writes(const R4SdkUpdateStoragefat32_update_Prepared *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_set_writes(R4SdkUpdateStoragefat32_update_Prepared *self, R4SdkUpdateStoragefat32_update_Write * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_get_source_sha256(const R4SdkUpdateStoragefat32_update_Prepared *self, R4SdkDataNative_Value158 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,3u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_set_source_sha256(R4SdkUpdateStoragefat32_update_Prepared *self, const R4SdkDataNative_Value158 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_get_source_ranges(const R4SdkUpdateStoragefat32_update_Prepared *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_set_source_ranges(R4SdkUpdateStoragefat32_update_Prepared *self, R4SdkUpdateStoragefat32_update_SourceRange * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_get_changed_files(const R4SdkUpdateStoragefat32_update_Prepared *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_set_changed_files(R4SdkUpdateStoragefat32_update_Prepared *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_get_volume_bytes(const R4SdkUpdateStoragefat32_update_Prepared *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_set_volume_bytes(R4SdkUpdateStoragefat32_update_Prepared *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_get_compact(const R4SdkUpdateStoragefat32_update_Prepared *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_set_compact(R4SdkUpdateStoragefat32_update_Prepared *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,62u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Prepared_inspectNative(const R4SdkUpdateStoragefat32_update_Prepared *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,62u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue63_create(R4SdkUpdateNativeValue63 *output, R4SdkUpdateStoragefat32_update_Write * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,63u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue63_inspectNative(const R4SdkUpdateNativeValue63 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,63u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Write_create(R4SdkUpdateStoragefat32_update_Write *output, uint32_t p0, uint32_t p1, uint8_t p2) {
 R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,64u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Write_from_fields(R4SdkUpdateStoragefat32_update_Write *output, uint32_t p0, uint32_t p1, uint8_t p2, uint64_t p3) {
 R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,64u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Write_get_first(const R4SdkUpdateStoragefat32_update_Write *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,64u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Write_set_first(R4SdkUpdateStoragefat32_update_Write *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,64u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Write_get_count(const R4SdkUpdateStoragefat32_update_Write *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,64u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Write_set_count(R4SdkUpdateStoragefat32_update_Write *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,64u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Write_get_order(const R4SdkUpdateStoragefat32_update_Write *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,64u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Write_set_order(R4SdkUpdateStoragefat32_update_Write *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,64u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Write_get_data_offset(const R4SdkUpdateStoragefat32_update_Write *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,64u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Write_set_data_offset(R4SdkUpdateStoragefat32_update_Write *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,64u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_Write_inspectNative(const R4SdkUpdateStoragefat32_update_Write *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,64u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue65_create(R4SdkUpdateNativeValue65 *output, R4SdkUpdateStoragefat32_update_SourceRange * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,65u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue65_inspectNative(const R4SdkUpdateNativeValue65 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,65u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_SourceRange_create(R4SdkUpdateStoragefat32_update_SourceRange *output, uint32_t p0, uint32_t p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,66u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_SourceRange_from_fields(R4SdkUpdateStoragefat32_update_SourceRange *output, uint32_t p0, uint32_t p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,66u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_SourceRange_get_first(const R4SdkUpdateStoragefat32_update_SourceRange *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,66u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_SourceRange_set_first(R4SdkUpdateStoragefat32_update_SourceRange *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,66u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_SourceRange_get_count(const R4SdkUpdateStoragefat32_update_SourceRange *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,66u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_SourceRange_set_count(R4SdkUpdateStoragefat32_update_SourceRange *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,66u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragefat32_update_SourceRange_inspectNative(const R4SdkUpdateStoragefat32_update_SourceRange *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,66u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue68_inspectNative(const R4SdkUpdateNativeValue68 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,68u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue69_inspectNative(const R4SdkUpdateNativeValue69 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,69u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue70_inspectNative(const R4SdkUpdateNativeValue70 *self, R4SdkUpdateStoragefat32_update_Prepared *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,70u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue71_inspectNative(const R4SdkUpdateNativeValue71 *self, R4SdkUpdateStoragefat32_update_Prepared *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,71u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttrType_create(R4SdkUpdateNtfsFormatAttrType *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,72u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttrType_inspectNative(const R4SdkUpdateNtfsFormatAttrType *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,72u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileReference_create(R4SdkUpdateNtfsFormatFileReference *output, uint64_t p0, uint16_t p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,73u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileReference_from_fields(R4SdkUpdateNtfsFormatFileReference *output, uint64_t p0, uint16_t p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,73u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileReference_get_record(const R4SdkUpdateNtfsFormatFileReference *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,73u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileReference_set_record(R4SdkUpdateNtfsFormatFileReference *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,73u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileReference_get_sequence(const R4SdkUpdateNtfsFormatFileReference *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,73u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileReference_set_sequence(R4SdkUpdateNtfsFormatFileReference *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,73u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileReference_inspectNative(const R4SdkUpdateNtfsFormatFileReference *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,73u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_create(R4SdkUpdateNtfsFormatBootSector *output, uint16_t p0, uint8_t p1, uint32_t p2, uint64_t p3, uint64_t p4, uint64_t p5, uint32_t p6, uint32_t p7, uint64_t p8) {
 R4SdkUpdateSlot a[9]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,74u,a,9u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_from_fields(R4SdkUpdateNtfsFormatBootSector *output, uint16_t p0, uint8_t p1, uint32_t p2, uint64_t p3, uint64_t p4, uint64_t p5, uint32_t p6, uint32_t p7, uint64_t p8) {
 R4SdkUpdateSlot a[9]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,74u,a,9u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_get_bytes_per_sector(const R4SdkUpdateNtfsFormatBootSector *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_set_bytes_per_sector(R4SdkUpdateNtfsFormatBootSector *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_get_sectors_per_cluster_raw(const R4SdkUpdateNtfsFormatBootSector *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_set_sectors_per_cluster_raw(R4SdkUpdateNtfsFormatBootSector *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_get_cluster_bytes(const R4SdkUpdateNtfsFormatBootSector *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_set_cluster_bytes(R4SdkUpdateNtfsFormatBootSector *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_get_total_sectors(const R4SdkUpdateNtfsFormatBootSector *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_set_total_sectors(R4SdkUpdateNtfsFormatBootSector *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_get_mft_lcn(const R4SdkUpdateNtfsFormatBootSector *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_set_mft_lcn(R4SdkUpdateNtfsFormatBootSector *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_get_mftmirr_lcn(const R4SdkUpdateNtfsFormatBootSector *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_set_mftmirr_lcn(R4SdkUpdateNtfsFormatBootSector *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_get_file_record_bytes(const R4SdkUpdateNtfsFormatBootSector *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_set_file_record_bytes(R4SdkUpdateNtfsFormatBootSector *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_get_index_block_bytes(const R4SdkUpdateNtfsFormatBootSector *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_set_index_block_bytes(R4SdkUpdateNtfsFormatBootSector *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_get_serial_number(const R4SdkUpdateNtfsFormatBootSector *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_set_serial_number(R4SdkUpdateNtfsFormatBootSector *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,74u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_inspectNative(const R4SdkUpdateNtfsFormatBootSector *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,74u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFixupError_create(R4SdkUpdateNtfsFormatFixupError *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,75u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFixupError_inspectNative(const R4SdkUpdateNtfsFormatFixupError *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,75u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_create(R4SdkUpdateNtfsFormatFileRecordHeader *output, uint32_t p0, uint64_t p1, uint16_t p2, uint16_t p3, uint16_t p4, uint16_t p5, uint32_t p6, uint32_t p7, const R4SdkUpdateNtfsFormatFileReference * p8, uint16_t p9, uint32_t p10) {
 R4SdkUpdateSlot a[11]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.ptr=(void *)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,76u,a,11u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_from_fields(R4SdkUpdateNtfsFormatFileRecordHeader *output, uint32_t p0, uint64_t p1, uint16_t p2, uint16_t p3, uint16_t p4, uint16_t p5, uint32_t p6, uint32_t p7, const R4SdkUpdateNtfsFormatFileReference * p8, uint16_t p9, uint32_t p10) {
 R4SdkUpdateSlot a[11]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.ptr=(void *)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,76u,a,11u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_get_magic(const R4SdkUpdateNtfsFormatFileRecordHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_set_magic(R4SdkUpdateNtfsFormatFileRecordHeader *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_get_lsn(const R4SdkUpdateNtfsFormatFileRecordHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_set_lsn(R4SdkUpdateNtfsFormatFileRecordHeader *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_get_sequence(const R4SdkUpdateNtfsFormatFileRecordHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_set_sequence(R4SdkUpdateNtfsFormatFileRecordHeader *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_get_link_count(const R4SdkUpdateNtfsFormatFileRecordHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_set_link_count(R4SdkUpdateNtfsFormatFileRecordHeader *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_get_attrs_offset(const R4SdkUpdateNtfsFormatFileRecordHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_set_attrs_offset(R4SdkUpdateNtfsFormatFileRecordHeader *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_get_flags(const R4SdkUpdateNtfsFormatFileRecordHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_set_flags(R4SdkUpdateNtfsFormatFileRecordHeader *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_get_bytes_in_use(const R4SdkUpdateNtfsFormatFileRecordHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_set_bytes_in_use(R4SdkUpdateNtfsFormatFileRecordHeader *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_get_bytes_allocated(const R4SdkUpdateNtfsFormatFileRecordHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_set_bytes_allocated(R4SdkUpdateNtfsFormatFileRecordHeader *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_get_base_record(const R4SdkUpdateNtfsFormatFileRecordHeader *self, R4SdkUpdateNtfsFormatFileReference *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,8u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_set_base_record(R4SdkUpdateNtfsFormatFileRecordHeader *self, const R4SdkUpdateNtfsFormatFileReference * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_get_next_attr_instance(const R4SdkUpdateNtfsFormatFileRecordHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_set_next_attr_instance(R4SdkUpdateNtfsFormatFileRecordHeader *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_get_record_number(const R4SdkUpdateNtfsFormatFileRecordHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,10u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_set_record_number(R4SdkUpdateNtfsFormatFileRecordHeader *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,76u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileRecordHeader_inspectNative(const R4SdkUpdateNtfsFormatFileRecordHeader *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,76u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_create(R4SdkUpdateNtfsFormatAttribute *output, uint32_t p0, uint32_t p1, uint8_t p2, const uint8_t * p3, uintptr_t n3, uint16_t p4, uint16_t p5, const uint8_t * p6, uintptr_t n6, uint64_t p7, uint64_t p8, const uint8_t * p9, uintptr_t n9, uint8_t p10, uint64_t p11, uint64_t p12, uint64_t p13) {
 R4SdkUpdateSlot a[14]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.ptr=(void *)p9,.length=n9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKUPDATE_PRESENT};
 a[12] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKUPDATE_PRESENT};
 a[13] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,77u,a,14u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_from_fields(R4SdkUpdateNtfsFormatAttribute *output, uint32_t p0, uint32_t p1, uint8_t p2, const uint8_t * p3, uintptr_t n3, uint16_t p4, uint16_t p5, const uint8_t * p6, uintptr_t n6, uint64_t p7, uint64_t p8, const uint8_t * p9, uintptr_t n9, uint8_t p10, uint64_t p11, uint64_t p12, uint64_t p13) {
 R4SdkUpdateSlot a[14]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.ptr=(void *)p9,.length=n9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKUPDATE_PRESENT};
 a[12] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKUPDATE_PRESENT};
 a[13] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,77u,a,14u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_attr_type(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_attr_type(R4SdkUpdateNtfsFormatAttribute *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_length(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_length(R4SdkUpdateNtfsFormatAttribute *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_non_resident(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_non_resident(R4SdkUpdateNtfsFormatAttribute *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_name(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_name(R4SdkUpdateNtfsFormatAttribute *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_flags(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_flags(R4SdkUpdateNtfsFormatAttribute *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_instance(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_instance(R4SdkUpdateNtfsFormatAttribute *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_value(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_value(R4SdkUpdateNtfsFormatAttribute *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_lowest_vcn(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_lowest_vcn(R4SdkUpdateNtfsFormatAttribute *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_highest_vcn(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_highest_vcn(R4SdkUpdateNtfsFormatAttribute *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_mapping_pairs(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_mapping_pairs(R4SdkUpdateNtfsFormatAttribute *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_compression_unit(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,10u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_compression_unit(R4SdkUpdateNtfsFormatAttribute *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_allocated_size(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,11u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_allocated_size(R4SdkUpdateNtfsFormatAttribute *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,11u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_data_size(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,12u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_data_size(R4SdkUpdateNtfsFormatAttribute *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,12u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_get_initialized_size(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,13u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_set_initialized_size(R4SdkUpdateNtfsFormatAttribute *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,77u,13u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttribute_inspectNative(const R4SdkUpdateNtfsFormatAttribute *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,77u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeIterator_create(R4SdkUpdateNtfsFormatAttributeIterator *output, const uint8_t * p0, uintptr_t n0, uint64_t p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,78u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeIterator_from_fields(R4SdkUpdateNtfsFormatAttributeIterator *output, const uint8_t * p0, uintptr_t n0, uint64_t p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,78u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeIterator_get_record(const R4SdkUpdateNtfsFormatAttributeIterator *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,78u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeIterator_set_record(R4SdkUpdateNtfsFormatAttributeIterator *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,78u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeIterator_get_offset(const R4SdkUpdateNtfsFormatAttributeIterator *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,78u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeIterator_set_offset(R4SdkUpdateNtfsFormatAttributeIterator *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,78u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeIterator_inspectNative(const R4SdkUpdateNtfsFormatAttributeIterator *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,78u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue79_create(R4SdkUpdateNativeValue79 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,79u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue79_inspectNative(const R4SdkUpdateNativeValue79 *self, R4SdkUpdateNtfsFormatAttribute *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,79u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRun_create(R4SdkUpdateNtfsFormatRun *output, uint64_t p0, R4SdkUpdateSlot p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = p1;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,80u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRun_from_fields(R4SdkUpdateNtfsFormatRun *output, uint64_t p0, R4SdkUpdateSlot p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = p1;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,80u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRun_get_length_clusters(const R4SdkUpdateNtfsFormatRun *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,80u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRun_set_length_clusters(R4SdkUpdateNtfsFormatRun *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,80u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRun_get_lcn(const R4SdkUpdateNtfsFormatRun *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,80u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRun_set_lcn(R4SdkUpdateNtfsFormatRun *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,80u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRun_inspectNative(const R4SdkUpdateNtfsFormatRun *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,80u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_create(R4SdkUpdateNtfsFormatRunlistIterator *output, const uint8_t * p0, uintptr_t n0, uint64_t p1, int64_t p2, uint8_t p3) {
 R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,81u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_from_fields(R4SdkUpdateNtfsFormatRunlistIterator *output, const uint8_t * p0, uintptr_t n0, uint64_t p1, int64_t p2, uint8_t p3) {
 R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,81u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_get_mapping(const R4SdkUpdateNtfsFormatRunlistIterator *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,81u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_set_mapping(R4SdkUpdateNtfsFormatRunlistIterator *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,81u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_get_offset(const R4SdkUpdateNtfsFormatRunlistIterator *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,81u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_set_offset(R4SdkUpdateNtfsFormatRunlistIterator *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,81u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_get_current_lcn(const R4SdkUpdateNtfsFormatRunlistIterator *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,81u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_set_current_lcn(R4SdkUpdateNtfsFormatRunlistIterator *self, int64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,81u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_get_failed(const R4SdkUpdateNtfsFormatRunlistIterator *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,81u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_set_failed(R4SdkUpdateNtfsFormatRunlistIterator *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,81u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatRunlistIterator_inspectNative(const R4SdkUpdateNtfsFormatRunlistIterator *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,81u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue82_create(R4SdkUpdateNativeValue82 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,82u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue82_inspectNative(const R4SdkUpdateNativeValue82 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,82u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue83_create(R4SdkUpdateNativeValue83 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,83u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue83_inspectNative(const R4SdkUpdateNativeValue83 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,83u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_create(R4SdkUpdateNtfsFormatStandardInformation *output, uint64_t p0, uint64_t p1, uint64_t p2, uint64_t p3, uint32_t p4) {
 R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,84u,a,5u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_from_fields(R4SdkUpdateNtfsFormatStandardInformation *output, uint64_t p0, uint64_t p1, uint64_t p2, uint64_t p3, uint32_t p4) {
 R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,84u,a,5u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_get_creation_time(const R4SdkUpdateNtfsFormatStandardInformation *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,84u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_set_creation_time(R4SdkUpdateNtfsFormatStandardInformation *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,84u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_get_data_change_time(const R4SdkUpdateNtfsFormatStandardInformation *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,84u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_set_data_change_time(R4SdkUpdateNtfsFormatStandardInformation *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,84u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_get_mft_change_time(const R4SdkUpdateNtfsFormatStandardInformation *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,84u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_set_mft_change_time(R4SdkUpdateNtfsFormatStandardInformation *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,84u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_get_access_time(const R4SdkUpdateNtfsFormatStandardInformation *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,84u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_set_access_time(R4SdkUpdateNtfsFormatStandardInformation *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,84u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_get_file_attributes(const R4SdkUpdateNtfsFormatStandardInformation *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,84u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_set_file_attributes(R4SdkUpdateNtfsFormatStandardInformation *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,84u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatStandardInformation_inspectNative(const R4SdkUpdateNtfsFormatStandardInformation *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,84u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_create(R4SdkUpdateNtfsFormatFileName *output, const R4SdkUpdateNtfsFormatFileReference * p0, uint64_t p1, uint64_t p2, uint64_t p3, uint64_t p4, uint64_t p5, uint64_t p6, uint32_t p7, uint8_t p8, uint8_t p9, const uint8_t * p10, uintptr_t n10) {
 R4SdkUpdateSlot a[11]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.ptr=(void *)p10,.length=n10,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,85u,a,11u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_from_fields(R4SdkUpdateNtfsFormatFileName *output, const R4SdkUpdateNtfsFormatFileReference * p0, uint64_t p1, uint64_t p2, uint64_t p3, uint64_t p4, uint64_t p5, uint64_t p6, uint32_t p7, uint8_t p8, uint8_t p9, const uint8_t * p10, uintptr_t n10) {
 R4SdkUpdateSlot a[11]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.ptr=(void *)p10,.length=n10,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,85u,a,11u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_get_parent(const R4SdkUpdateNtfsFormatFileName *self, R4SdkUpdateNtfsFormatFileReference *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_set_parent(R4SdkUpdateNtfsFormatFileName *self, const R4SdkUpdateNtfsFormatFileReference * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_get_creation_time(const R4SdkUpdateNtfsFormatFileName *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_set_creation_time(R4SdkUpdateNtfsFormatFileName *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_get_data_change_time(const R4SdkUpdateNtfsFormatFileName *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_set_data_change_time(R4SdkUpdateNtfsFormatFileName *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_get_mft_change_time(const R4SdkUpdateNtfsFormatFileName *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_set_mft_change_time(R4SdkUpdateNtfsFormatFileName *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_get_access_time(const R4SdkUpdateNtfsFormatFileName *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_set_access_time(R4SdkUpdateNtfsFormatFileName *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_get_allocated_size(const R4SdkUpdateNtfsFormatFileName *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_set_allocated_size(R4SdkUpdateNtfsFormatFileName *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_get_data_size(const R4SdkUpdateNtfsFormatFileName *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_set_data_size(R4SdkUpdateNtfsFormatFileName *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_get_flags(const R4SdkUpdateNtfsFormatFileName *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_set_flags(R4SdkUpdateNtfsFormatFileName *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_get_name_length(const R4SdkUpdateNtfsFormatFileName *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_set_name_length(R4SdkUpdateNtfsFormatFileName *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_get_namespace(const R4SdkUpdateNtfsFormatFileName *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_set_namespace(R4SdkUpdateNtfsFormatFileName *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_get_name(const R4SdkUpdateNtfsFormatFileName *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,10u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_set_name(R4SdkUpdateNtfsFormatFileName *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,85u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatFileName_inspectNative(const R4SdkUpdateNtfsFormatFileName *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,85u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_create(R4SdkUpdateNtfsFormatAttributeListEntry *output, uint32_t p0, uint16_t p1, uint64_t p2, const R4SdkUpdateNtfsFormatFileReference * p3, uint16_t p4, const uint8_t * p5, uintptr_t n5) {
 R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,86u,a,6u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_from_fields(R4SdkUpdateNtfsFormatAttributeListEntry *output, uint32_t p0, uint16_t p1, uint64_t p2, const R4SdkUpdateNtfsFormatFileReference * p3, uint16_t p4, const uint8_t * p5, uintptr_t n5) {
 R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.ptr=(void *)p5,.length=n5,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,86u,a,6u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_get_attr_type(const R4SdkUpdateNtfsFormatAttributeListEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,86u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_set_attr_type(R4SdkUpdateNtfsFormatAttributeListEntry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,86u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_get_entry_length(const R4SdkUpdateNtfsFormatAttributeListEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,86u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_set_entry_length(R4SdkUpdateNtfsFormatAttributeListEntry *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,86u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_get_lowest_vcn(const R4SdkUpdateNtfsFormatAttributeListEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,86u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_set_lowest_vcn(R4SdkUpdateNtfsFormatAttributeListEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,86u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_get_mft_reference(const R4SdkUpdateNtfsFormatAttributeListEntry *self, R4SdkUpdateNtfsFormatFileReference *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,86u,3u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_set_mft_reference(R4SdkUpdateNtfsFormatAttributeListEntry *self, const R4SdkUpdateNtfsFormatFileReference * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,86u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_get_instance(const R4SdkUpdateNtfsFormatAttributeListEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,86u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_set_instance(R4SdkUpdateNtfsFormatAttributeListEntry *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,86u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_get_name(const R4SdkUpdateNtfsFormatAttributeListEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,86u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_set_name(R4SdkUpdateNtfsFormatAttributeListEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,86u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListEntry_inspectNative(const R4SdkUpdateNtfsFormatAttributeListEntry *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,86u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListIterator_create(R4SdkUpdateNtfsFormatAttributeListIterator *output, const uint8_t * p0, uintptr_t n0, uint64_t p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,87u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListIterator_from_fields(R4SdkUpdateNtfsFormatAttributeListIterator *output, const uint8_t * p0, uintptr_t n0, uint64_t p1) {
 R4SdkUpdateSlot a[2]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,87u,a,2u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListIterator_get_value(const R4SdkUpdateNtfsFormatAttributeListIterator *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,87u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListIterator_set_value(R4SdkUpdateNtfsFormatAttributeListIterator *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,87u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListIterator_get_offset(const R4SdkUpdateNtfsFormatAttributeListIterator *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,87u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListIterator_set_offset(R4SdkUpdateNtfsFormatAttributeListIterator *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,87u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatAttributeListIterator_inspectNative(const R4SdkUpdateNtfsFormatAttributeListIterator *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,87u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_create(R4SdkUpdateNtfsFormatIndexRoot *output, uint32_t p0, uint32_t p1, uint32_t p2, const R4SdkUpdateNtfsFormatIndexHeader * p3, const uint8_t * p4, uintptr_t n4) {
 R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,88u,a,5u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_from_fields(R4SdkUpdateNtfsFormatIndexRoot *output, uint32_t p0, uint32_t p1, uint32_t p2, const R4SdkUpdateNtfsFormatIndexHeader * p3, const uint8_t * p4, uintptr_t n4) {
 R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,88u,a,5u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_get_indexed_attr_type(const R4SdkUpdateNtfsFormatIndexRoot *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,88u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_set_indexed_attr_type(R4SdkUpdateNtfsFormatIndexRoot *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,88u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_get_collation_rule(const R4SdkUpdateNtfsFormatIndexRoot *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,88u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_set_collation_rule(R4SdkUpdateNtfsFormatIndexRoot *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,88u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_get_index_block_bytes(const R4SdkUpdateNtfsFormatIndexRoot *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,88u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_set_index_block_bytes(R4SdkUpdateNtfsFormatIndexRoot *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,88u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_get_header(const R4SdkUpdateNtfsFormatIndexRoot *self, R4SdkUpdateNtfsFormatIndexHeader *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,88u,3u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_set_header(R4SdkUpdateNtfsFormatIndexRoot *self, const R4SdkUpdateNtfsFormatIndexHeader * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,88u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_get_entries(const R4SdkUpdateNtfsFormatIndexRoot *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,88u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_set_entries(R4SdkUpdateNtfsFormatIndexRoot *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,88u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexRoot_inspectNative(const R4SdkUpdateNtfsFormatIndexRoot *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,88u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_create(R4SdkUpdateNtfsFormatIndexHeader *output, uint32_t p0, uint32_t p1, uint32_t p2, uint8_t p3) {
 R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,89u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_from_fields(R4SdkUpdateNtfsFormatIndexHeader *output, uint32_t p0, uint32_t p1, uint32_t p2, uint8_t p3) {
 R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,89u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_get_entries_offset(const R4SdkUpdateNtfsFormatIndexHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,89u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_set_entries_offset(R4SdkUpdateNtfsFormatIndexHeader *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,89u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_get_index_length(const R4SdkUpdateNtfsFormatIndexHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,89u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_set_index_length(R4SdkUpdateNtfsFormatIndexHeader *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,89u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_get_allocated_size(const R4SdkUpdateNtfsFormatIndexHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,89u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_set_allocated_size(R4SdkUpdateNtfsFormatIndexHeader *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,89u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_get_flags(const R4SdkUpdateNtfsFormatIndexHeader *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,89u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_set_flags(R4SdkUpdateNtfsFormatIndexHeader *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,89u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexHeader_inspectNative(const R4SdkUpdateNtfsFormatIndexHeader *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,89u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexBlock_create(R4SdkUpdateNtfsFormatIndexBlock *output, uint64_t p0, uint64_t p1, const uint8_t * p2, uintptr_t n2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,90u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexBlock_from_fields(R4SdkUpdateNtfsFormatIndexBlock *output, uint64_t p0, uint64_t p1, const uint8_t * p2, uintptr_t n2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,90u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexBlock_get_lsn(const R4SdkUpdateNtfsFormatIndexBlock *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,90u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexBlock_set_lsn(R4SdkUpdateNtfsFormatIndexBlock *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,90u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexBlock_get_vcn(const R4SdkUpdateNtfsFormatIndexBlock *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,90u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexBlock_set_vcn(R4SdkUpdateNtfsFormatIndexBlock *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,90u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexBlock_get_entries(const R4SdkUpdateNtfsFormatIndexBlock *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,90u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexBlock_set_entries(R4SdkUpdateNtfsFormatIndexBlock *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,90u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexBlock_inspectNative(const R4SdkUpdateNtfsFormatIndexBlock *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,90u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_create(R4SdkUpdateNtfsFormatIndexEntry *output, uint64_t p0, uint16_t p1, uint16_t p2, uint16_t p3, const uint8_t * p4, uintptr_t n4, R4SdkUpdateSlot p5) {
 R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = p5;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,91u,a,6u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_from_fields(R4SdkUpdateNtfsFormatIndexEntry *output, uint64_t p0, uint16_t p1, uint16_t p2, uint16_t p3, const uint8_t * p4, uintptr_t n4, R4SdkUpdateSlot p5) {
 R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = p5;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,91u,a,6u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_get_file_reference(const R4SdkUpdateNtfsFormatIndexEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,91u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_set_file_reference(R4SdkUpdateNtfsFormatIndexEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,91u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_get_entry_length(const R4SdkUpdateNtfsFormatIndexEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,91u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_set_entry_length(R4SdkUpdateNtfsFormatIndexEntry *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,91u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_get_key_length(const R4SdkUpdateNtfsFormatIndexEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,91u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_set_key_length(R4SdkUpdateNtfsFormatIndexEntry *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,91u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_get_flags(const R4SdkUpdateNtfsFormatIndexEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,91u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_set_flags(R4SdkUpdateNtfsFormatIndexEntry *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,91u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_get_key(const R4SdkUpdateNtfsFormatIndexEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,91u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_set_key(R4SdkUpdateNtfsFormatIndexEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,91u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_get_sub_node_vcn(const R4SdkUpdateNtfsFormatIndexEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,91u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_set_sub_node_vcn(R4SdkUpdateNtfsFormatIndexEntry *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,91u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntry_inspectNative(const R4SdkUpdateNtfsFormatIndexEntry *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,91u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntryIterator_create(R4SdkUpdateNtfsFormatIndexEntryIterator *output, const uint8_t * p0, uintptr_t n0, uint64_t p1, uint8_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,92u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntryIterator_from_fields(R4SdkUpdateNtfsFormatIndexEntryIterator *output, const uint8_t * p0, uintptr_t n0, uint64_t p1, uint8_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,92u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntryIterator_get_entries(const R4SdkUpdateNtfsFormatIndexEntryIterator *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,92u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntryIterator_set_entries(R4SdkUpdateNtfsFormatIndexEntryIterator *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,92u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntryIterator_get_offset(const R4SdkUpdateNtfsFormatIndexEntryIterator *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,92u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntryIterator_set_offset(R4SdkUpdateNtfsFormatIndexEntryIterator *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,92u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntryIterator_get_done(const R4SdkUpdateNtfsFormatIndexEntryIterator *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,92u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntryIterator_set_done(R4SdkUpdateNtfsFormatIndexEntryIterator *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,92u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatIndexEntryIterator_inspectNative(const R4SdkUpdateNtfsFormatIndexEntryIterator *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,92u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNative_math_Order_create(R4SdkUpdateNative_math_Order *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,93u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNative_math_Order_inspectNative(const R4SdkUpdateNative_math_Order *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,93u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatVolumeInformation_create(R4SdkUpdateNtfsFormatVolumeInformation *output, uint8_t p0, uint8_t p1, uint16_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,94u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatVolumeInformation_from_fields(R4SdkUpdateNtfsFormatVolumeInformation *output, uint8_t p0, uint8_t p1, uint16_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,94u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatVolumeInformation_get_major(const R4SdkUpdateNtfsFormatVolumeInformation *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,94u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatVolumeInformation_set_major(R4SdkUpdateNtfsFormatVolumeInformation *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,94u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatVolumeInformation_get_minor(const R4SdkUpdateNtfsFormatVolumeInformation *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,94u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatVolumeInformation_set_minor(R4SdkUpdateNtfsFormatVolumeInformation *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,94u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatVolumeInformation_get_flags(const R4SdkUpdateNtfsFormatVolumeInformation *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,94u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatVolumeInformation_set_flags(R4SdkUpdateNtfsFormatVolumeInformation *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,94u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatVolumeInformation_inspectNative(const R4SdkUpdateNtfsFormatVolumeInformation *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,94u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_create(R4SdkUpdateNtfsPlan *output, const R4SdkDataAllocator * p0, uint64_t p1, uint64_t p2) {
 R4SdkUpdateSlot a[11]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 a[8].flags=R4SDKUPDATE_DEFAULT;
 a[9].flags=R4SDKUPDATE_DEFAULT;
 a[10].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,95u,a,11u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_from_fields(R4SdkUpdateNtfsPlan *output, const R4SdkDataAllocator * p0, uint64_t p1, uint64_t p2, uint64_t p3, uint64_t p4, uint64_t p5, uint64_t p6, uint64_t p7, uint64_t p8, const R4SdkUpdateNativeValue42 * p9, const R4SdkUpdateNative_array_list_Aligned_storage_tools_ntfs_plan_Segment_null_ * p10) {
 R4SdkUpdateSlot a[11]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.ptr=(void *)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.ptr=(void *)p10,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,95u,a,11u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_get_allocator(const R4SdkUpdateNtfsPlan *self, R4SdkDataAllocator *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_set_allocator(R4SdkUpdateNtfsPlan *self, const R4SdkDataAllocator * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_get_bytes(const R4SdkUpdateNtfsPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_set_bytes(R4SdkUpdateNtfsPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_get_clusters(const R4SdkUpdateNtfsPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_set_clusters(R4SdkUpdateNtfsPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_get_used_clusters(const R4SdkUpdateNtfsPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_set_used_clusters(R4SdkUpdateNtfsPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_get_bitmap_offset(const R4SdkUpdateNtfsPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_set_bitmap_offset(R4SdkUpdateNtfsPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_get_bitmap_bytes(const R4SdkUpdateNtfsPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_set_bitmap_bytes(R4SdkUpdateNtfsPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_get_bitmap_allocated_bytes(const R4SdkUpdateNtfsPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_set_bitmap_allocated_bytes(R4SdkUpdateNtfsPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_get_logfile_offset(const R4SdkUpdateNtfsPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_set_logfile_offset(R4SdkUpdateNtfsPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_get_logfile_bytes(const R4SdkUpdateNtfsPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_set_logfile_bytes(R4SdkUpdateNtfsPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_get_boot(const R4SdkUpdateNtfsPlan *self, R4SdkUpdateNativeValue42 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,9u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_set_boot(R4SdkUpdateNtfsPlan *self, const R4SdkUpdateNativeValue42 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_get_segments(const R4SdkUpdateNtfsPlan *self, R4SdkUpdateNative_array_list_Aligned_storage_tools_ntfs_plan_Segment_null_ *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,10u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_set_segments(R4SdkUpdateNtfsPlan *self, const R4SdkUpdateNative_array_list_Aligned_storage_tools_ntfs_plan_Segment_null_ * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,95u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsPlan_inspectNative(const R4SdkUpdateNtfsPlan *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,95u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_create(R4SdkUpdateNtfsBuilder *output, const R4SdkDataAllocator * p0, const R4SdkUpdateNtfsMetadata * p1, const uint8_t * p2, uintptr_t n2, uint32_t p3, uint64_t p4, uint64_t p5, uint64_t p6) {
 R4SdkUpdateSlot a[12]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7].flags=R4SDKUPDATE_DEFAULT;
 a[8].flags=R4SDKUPDATE_DEFAULT;
 a[9].flags=R4SDKUPDATE_DEFAULT;
 a[10].flags=R4SDKUPDATE_DEFAULT;
 a[11].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,97u,a,12u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_from_fields(R4SdkUpdateNtfsBuilder *output, const R4SdkDataAllocator * p0, const R4SdkUpdateNtfsMetadata * p1, const uint8_t * p2, uintptr_t n2, uint32_t p3, uint64_t p4, uint64_t p5, uint64_t p6, const R4SdkUpdateNative_array_list_Aligned_ntfs_builder_WithFormat_ntfs_format__Node_null_ * p7, uint64_t p8, uint64_t p9, uint64_t p10, uint8_t p11) {
 R4SdkUpdateSlot a[12]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.ptr=(void *)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,97u,a,12u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_get_allocator(const R4SdkUpdateNtfsBuilder *self, R4SdkDataAllocator *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_set_allocator(R4SdkUpdateNtfsBuilder *self, const R4SdkDataAllocator * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_get_meta(const R4SdkUpdateNtfsBuilder *self, R4SdkUpdateNtfsMetadata *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,1u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_set_meta(R4SdkUpdateNtfsBuilder *self, const R4SdkUpdateNtfsMetadata * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_get_label(const R4SdkUpdateNtfsBuilder *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_set_label(R4SdkUpdateNtfsBuilder *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_get_partition_lba(const R4SdkUpdateNtfsBuilder *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_set_partition_lba(R4SdkUpdateNtfsBuilder *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_get_total_bytes(const R4SdkUpdateNtfsBuilder *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_set_total_bytes(R4SdkUpdateNtfsBuilder *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_get_timestamp(const R4SdkUpdateNtfsBuilder *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_set_timestamp(R4SdkUpdateNtfsBuilder *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_get_serial(const R4SdkUpdateNtfsBuilder *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_set_serial(R4SdkUpdateNtfsBuilder *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_get_nodes(const R4SdkUpdateNtfsBuilder *self, R4SdkUpdateNative_array_list_Aligned_ntfs_builder_WithFormat_ntfs_format__Node_null_ *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,7u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_set_nodes(R4SdkUpdateNtfsBuilder *self, const R4SdkUpdateNative_array_list_Aligned_ntfs_builder_WithFormat_ntfs_format__Node_null_ * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_get_layout_mft_bytes(const R4SdkUpdateNtfsBuilder *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_set_layout_mft_bytes(R4SdkUpdateNtfsBuilder *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_get_layout_bitmap_alloc(const R4SdkUpdateNtfsBuilder *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_set_layout_bitmap_alloc(R4SdkUpdateNtfsBuilder *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_get_layout_bitmap_bytes(const R4SdkUpdateNtfsBuilder *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,10u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_set_layout_bitmap_bytes(R4SdkUpdateNtfsBuilder *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_get_prepared_once(const R4SdkUpdateNtfsBuilder *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,11u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_set_prepared_once(R4SdkUpdateNtfsBuilder *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,97u,11u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsBuilder_inspectNative(const R4SdkUpdateNtfsBuilder *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,97u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsSegment_create(R4SdkUpdateNtfsSegment *output, uint64_t p0, const uint8_t * p1, uintptr_t n1, uint8_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,99u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsSegment_from_fields(R4SdkUpdateNtfsSegment *output, uint64_t p0, const uint8_t * p1, uintptr_t n1, uint8_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,99u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateNtfsSegment_get_offset(const R4SdkUpdateNtfsSegment *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,99u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsSegment_set_offset(R4SdkUpdateNtfsSegment *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,99u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsSegment_get_data(const R4SdkUpdateNtfsSegment *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,99u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsSegment_set_data(R4SdkUpdateNtfsSegment *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,99u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsSegment_get_owned(const R4SdkUpdateNtfsSegment *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,99u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsSegment_set_owned(R4SdkUpdateNtfsSegment *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,99u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsSegment_inspectNative(const R4SdkUpdateNtfsSegment *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,99u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_ShrinkLimits_create(R4SdkUpdateStoragentfs_resize_ShrinkLimits *output) {
 R4SdkUpdateSlot a[4]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,100u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_ShrinkLimits_from_fields(R4SdkUpdateStoragentfs_resize_ShrinkLimits *output, uint64_t p0, uint64_t p1, uint64_t p2, R4SdkUpdateSlot p3) {
 R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = p3;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,100u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_ShrinkLimits_get_maximum_sectors(const R4SdkUpdateStoragentfs_resize_ShrinkLimits *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,100u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_ShrinkLimits_set_maximum_sectors(R4SdkUpdateStoragentfs_resize_ShrinkLimits *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,100u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_ShrinkLimits_get_minimum_sectors(const R4SdkUpdateStoragentfs_resize_ShrinkLimits *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,100u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_ShrinkLimits_set_minimum_sectors(R4SdkUpdateStoragentfs_resize_ShrinkLimits *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,100u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_ShrinkLimits_get_highest_fixed_cluster(const R4SdkUpdateStoragentfs_resize_ShrinkLimits *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,100u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_ShrinkLimits_set_highest_fixed_cluster(R4SdkUpdateStoragentfs_resize_ShrinkLimits *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,100u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_ShrinkLimits_get_bitmap_lcn(const R4SdkUpdateStoragentfs_resize_ShrinkLimits *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,100u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_ShrinkLimits_set_bitmap_lcn(R4SdkUpdateStoragentfs_resize_ShrinkLimits *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,100u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_ShrinkLimits_inspectNative(const R4SdkUpdateStoragentfs_resize_ShrinkLimits *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,100u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_create(R4SdkUpdateStoragentfs_resize_Plan *output, const R4SdkDataAllocator * p0, uint64_t p1, uint64_t p2, uint64_t p3, uint32_t p4, uint64_t p5, uint64_t p6, uint64_t p7, uint64_t p8, uint64_t p9) {
 R4SdkUpdateSlot a[25]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10].flags=R4SDKUPDATE_DEFAULT;
 a[11].flags=R4SDKUPDATE_DEFAULT;
 a[12].flags=R4SDKUPDATE_DEFAULT;
 a[13].flags=R4SDKUPDATE_DEFAULT;
 a[14].flags=R4SDKUPDATE_DEFAULT;
 a[15].flags=R4SDKUPDATE_DEFAULT;
 a[16].flags=R4SDKUPDATE_DEFAULT;
 a[17].flags=R4SDKUPDATE_DEFAULT;
 a[18].flags=R4SDKUPDATE_DEFAULT;
 a[19].flags=R4SDKUPDATE_DEFAULT;
 a[20].flags=R4SDKUPDATE_DEFAULT;
 a[21].flags=R4SDKUPDATE_DEFAULT;
 a[22].flags=R4SDKUPDATE_DEFAULT;
 a[23].flags=R4SDKUPDATE_DEFAULT;
 a[24].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,101u,a,25u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_from_fields(R4SdkUpdateStoragentfs_resize_Plan *output, const R4SdkDataAllocator * p0, uint64_t p1, uint64_t p2, uint64_t p3, uint32_t p4, uint64_t p5, uint64_t p6, uint64_t p7, uint64_t p8, uint64_t p9, const R4SdkUpdateStoragentfs_resize_Map * p10, const R4SdkUpdateStoragentfs_resize_ShrinkLimits * p11, const R4SdkDataNative_Value158 * p12, const R4SdkUpdateStoragentfs_resize_Map * p13, R4SdkUpdateSlot p14, uint64_t p15, uint16_t p16, const R4SdkUpdateNativeValue105 * p17, uint64_t p18, const R4SdkUpdateNativeValue107 * p19, uint64_t p20, const R4SdkUpdateNativeValue110 * p21, const R4SdkUpdateNativeValue110 * p22, uint64_t p23, const R4SdkUpdateNativeValue42 * p24) {
 R4SdkUpdateSlot a[25]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.ptr=(void *)p10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.ptr=(void *)p11,.flags=R4SDKUPDATE_PRESENT};
 a[12] = (R4SdkUpdateSlot){.ptr=(void *)p12,.flags=R4SDKUPDATE_PRESENT};
 a[13] = (R4SdkUpdateSlot){.ptr=(void *)p13,.flags=R4SDKUPDATE_PRESENT};
 a[14] = p14;
 a[15] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p15,.flags=R4SDKUPDATE_PRESENT};
 a[16] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p16,.flags=R4SDKUPDATE_PRESENT};
 a[17] = (R4SdkUpdateSlot){.ptr=(void *)p17,.flags=R4SDKUPDATE_PRESENT};
 a[18] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p18,.flags=R4SDKUPDATE_PRESENT};
 a[19] = (R4SdkUpdateSlot){.ptr=(void *)p19,.flags=R4SDKUPDATE_PRESENT};
 a[20] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p20,.flags=R4SDKUPDATE_PRESENT};
 a[21] = (R4SdkUpdateSlot){.ptr=(void *)p21,.flags=R4SDKUPDATE_PRESENT};
 a[22] = (R4SdkUpdateSlot){.ptr=(void *)p22,.flags=R4SDKUPDATE_PRESENT};
 a[23] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p23,.flags=R4SDKUPDATE_PRESENT};
 a[24] = (R4SdkUpdateSlot){.ptr=(void *)p24,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,101u,a,25u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_allocator(const R4SdkUpdateStoragentfs_resize_Plan *self, R4SdkDataAllocator *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_allocator(R4SdkUpdateStoragentfs_resize_Plan *self, const R4SdkDataAllocator * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_first(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_first(R4SdkUpdateStoragentfs_resize_Plan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_old_sectors(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_old_sectors(R4SdkUpdateStoragentfs_resize_Plan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_new_sectors(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_new_sectors(R4SdkUpdateStoragentfs_resize_Plan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_number(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_number(R4SdkUpdateStoragentfs_resize_Plan *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_old_clusters(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_old_clusters(R4SdkUpdateStoragentfs_resize_Plan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_new_clusters(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_new_clusters(R4SdkUpdateStoragentfs_resize_Plan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_bitmap_lcn(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_bitmap_lcn(R4SdkUpdateStoragentfs_resize_Plan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_bitmap_bytes(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_bitmap_bytes(R4SdkUpdateStoragentfs_resize_Plan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_bitmap_clusters(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_bitmap_clusters(R4SdkUpdateStoragentfs_resize_Plan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_bitmap(const R4SdkUpdateStoragentfs_resize_Plan *self, R4SdkUpdateStoragentfs_resize_Map *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,10u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_bitmap(R4SdkUpdateStoragentfs_resize_Plan *self, const R4SdkUpdateStoragentfs_resize_Map * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_shrink(const R4SdkUpdateStoragentfs_resize_Plan *self, R4SdkUpdateStoragentfs_resize_ShrinkLimits *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,11u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_shrink(R4SdkUpdateStoragentfs_resize_Plan *self, const R4SdkUpdateStoragentfs_resize_ShrinkLimits * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,11u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_bitmap_sha(const R4SdkUpdateStoragentfs_resize_Plan *self, R4SdkDataNative_Value158 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,12u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_bitmap_sha(R4SdkUpdateStoragentfs_resize_Plan *self, const R4SdkDataNative_Value158 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,12u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_mft(const R4SdkUpdateStoragentfs_resize_Plan *self, R4SdkUpdateStoragentfs_resize_Map *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,13u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_mft(R4SdkUpdateStoragentfs_resize_Plan *self, const R4SdkUpdateStoragentfs_resize_Map * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,13u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_mft_sha(const R4SdkUpdateStoragentfs_resize_Plan *self, R4SdkDataNative_Value158 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,14u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_mft_sha(R4SdkUpdateStoragentfs_resize_Plan *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,14u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_mirror_lcn(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,15u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_mirror_lcn(R4SdkUpdateStoragentfs_resize_Plan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,15u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_bitmap_sequence(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,16u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_bitmap_sequence(R4SdkUpdateStoragentfs_resize_Plan *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,16u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_sources(const R4SdkUpdateStoragentfs_resize_Plan *self, R4SdkUpdateNativeValue105 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,17u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_sources(R4SdkUpdateStoragentfs_resize_Plan *self, const R4SdkUpdateNativeValue105 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,17u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_source_count(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,18u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_source_count(R4SdkUpdateStoragentfs_resize_Plan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,18u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_patches(const R4SdkUpdateStoragentfs_resize_Plan *self, R4SdkUpdateNativeValue107 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,19u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_patches(R4SdkUpdateStoragentfs_resize_Plan *self, const R4SdkUpdateNativeValue107 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,19u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_patch_count(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,20u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_patch_count(R4SdkUpdateStoragentfs_resize_Plan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,20u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_clean_volume(const R4SdkUpdateStoragentfs_resize_Plan *self, R4SdkUpdateNativeValue110 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,21u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_clean_volume(R4SdkUpdateStoragentfs_resize_Plan *self, const R4SdkUpdateNativeValue110 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,21u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_dirty_volume(const R4SdkUpdateStoragentfs_resize_Plan *self, R4SdkUpdateNativeValue110 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,22u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_dirty_volume(R4SdkUpdateStoragentfs_resize_Plan *self, const R4SdkUpdateNativeValue110 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,22u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_volume_lba(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,23u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_volume_lba(R4SdkUpdateStoragentfs_resize_Plan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,23u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_get_boot(const R4SdkUpdateStoragentfs_resize_Plan *self, R4SdkUpdateNativeValue42 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,24u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_set_boot(R4SdkUpdateStoragentfs_resize_Plan *self, const R4SdkUpdateNativeValue42 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,101u,24u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Plan_inspectNative(const R4SdkUpdateStoragentfs_resize_Plan *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,101u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Map_create(R4SdkUpdateStoragentfs_resize_Map *output) {
 R4SdkUpdateSlot a[4]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,102u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Map_from_fields(R4SdkUpdateStoragentfs_resize_Map *output, const R4SdkUpdateNativeValue103 * p0, uint64_t p1, uint64_t p2, uint64_t p3) {
 R4SdkUpdateSlot a[4]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,102u,a,4u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Map_get_runs(const R4SdkUpdateStoragentfs_resize_Map *self, R4SdkUpdateNativeValue103 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,102u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Map_set_runs(R4SdkUpdateStoragentfs_resize_Map *self, const R4SdkUpdateNativeValue103 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,102u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Map_get_count(const R4SdkUpdateStoragentfs_resize_Map *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,102u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Map_set_count(R4SdkUpdateStoragentfs_resize_Map *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,102u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Map_get_clusters(const R4SdkUpdateStoragentfs_resize_Map *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,102u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Map_set_clusters(R4SdkUpdateStoragentfs_resize_Map *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,102u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Map_get_bytes(const R4SdkUpdateStoragentfs_resize_Map *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,102u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Map_set_bytes(R4SdkUpdateStoragentfs_resize_Map *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,102u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Map_inspectNative(const R4SdkUpdateStoragentfs_resize_Map *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,102u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue103_create(R4SdkUpdateNativeValue103 *output, const R4SdkUpdateNativeValue103 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,103u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue103_inspectNative(const R4SdkUpdateNativeValue103 *self, R4SdkUpdateNativeValue103 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,103u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue104_create(R4SdkUpdateNativeValue104 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,104u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue104_inspectNative(const R4SdkUpdateNativeValue104 *self, R4SdkDataNative_Value158 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,104u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue105_create(R4SdkUpdateNativeValue105 *output, const R4SdkUpdateNativeValue105 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,105u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue105_inspectNative(const R4SdkUpdateNativeValue105 *self, R4SdkUpdateNativeValue105 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,105u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Source_create(R4SdkUpdateStoragentfs_resize_Source *output, uint64_t p0, uint32_t p1, const R4SdkDataNative_Value158 * p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,106u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Source_from_fields(R4SdkUpdateStoragentfs_resize_Source *output, uint64_t p0, uint32_t p1, const R4SdkDataNative_Value158 * p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,106u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Source_get_lba(const R4SdkUpdateStoragentfs_resize_Source *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,106u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Source_set_lba(R4SdkUpdateStoragentfs_resize_Source *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,106u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Source_get_count(const R4SdkUpdateStoragentfs_resize_Source *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,106u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Source_set_count(R4SdkUpdateStoragentfs_resize_Source *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,106u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Source_get_sha(const R4SdkUpdateStoragentfs_resize_Source *self, R4SdkDataNative_Value158 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,106u,2u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Source_set_sha(R4SdkUpdateStoragentfs_resize_Source *self, const R4SdkDataNative_Value158 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,106u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Source_inspectNative(const R4SdkUpdateStoragentfs_resize_Source *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,106u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue107_create(R4SdkUpdateNativeValue107 *output, const R4SdkUpdateNativeValue107 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,107u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue107_inspectNative(const R4SdkUpdateNativeValue107 *self, R4SdkUpdateNativeValue107 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,107u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Patch_create(R4SdkUpdateStoragentfs_resize_Patch *output, uint64_t p0, uint64_t p1) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,108u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Patch_from_fields(R4SdkUpdateStoragentfs_resize_Patch *output, uint64_t p0, uint64_t p1, const R4SdkUpdateNativeValue109 * p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,108u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Patch_get_lba(const R4SdkUpdateStoragentfs_resize_Patch *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,108u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Patch_set_lba(R4SdkUpdateStoragentfs_resize_Patch *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,108u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Patch_get_length(const R4SdkUpdateStoragentfs_resize_Patch *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,108u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Patch_set_length(R4SdkUpdateStoragentfs_resize_Patch *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,108u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Patch_get_bytes(const R4SdkUpdateStoragentfs_resize_Patch *self, R4SdkUpdateNativeValue109 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,108u,2u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Patch_set_bytes(R4SdkUpdateStoragentfs_resize_Patch *self, const R4SdkUpdateNativeValue109 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,108u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragentfs_resize_Patch_inspectNative(const R4SdkUpdateStoragentfs_resize_Patch *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,108u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue109_create(R4SdkUpdateNativeValue109 *output, const R4SdkUpdateNativeValue109 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,109u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue109_inspectNative(const R4SdkUpdateNativeValue109 *self, R4SdkUpdateNativeValue109 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,109u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue110_create(R4SdkUpdateNativeValue110 *output, const R4SdkUpdateNativeValue110 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,110u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue110_inspectNative(const R4SdkUpdateNativeValue110 *self, R4SdkUpdateNativeValue110 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,110u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragegpt_repair_Status_create(R4SdkUpdateStoragegpt_repair_Status *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,111u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStoragegpt_repair_Status_inspectNative(const R4SdkUpdateStoragegpt_repair_Status *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,111u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Role_create(R4SdkUpdateStorageinstallation_Role *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,113u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Role_inspectNative(const R4SdkUpdateStorageinstallation_Role *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,113u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Medium_create(R4SdkUpdateStorageinstallation_Medium *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,114u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Medium_inspectNative(const R4SdkUpdateStorageinstallation_Medium *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,114u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue115_inspectNative(const R4SdkUpdateNativeValue115 *self, R4SdkUpdateNativeValue33 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,115u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Identifiers_create(R4SdkUpdateStorageinstallation_Identifiers *output, const R4SdkUpdateNativeValue27 * p0, const R4SdkUpdateNativeValue27 * p1, const R4SdkUpdateNativeValue117 * p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,116u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Identifiers_from_fields(R4SdkUpdateStorageinstallation_Identifiers *output, const R4SdkUpdateNativeValue27 * p0, const R4SdkUpdateNativeValue27 * p1, const R4SdkUpdateNativeValue117 * p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,116u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Identifiers_get_installation(const R4SdkUpdateStorageinstallation_Identifiers *self, R4SdkUpdateNativeValue27 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,116u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Identifiers_set_installation(R4SdkUpdateStorageinstallation_Identifiers *self, const R4SdkUpdateNativeValue27 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,116u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Identifiers_get_disk(const R4SdkUpdateStorageinstallation_Identifiers *self, R4SdkUpdateNativeValue27 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,116u,1u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Identifiers_set_disk(R4SdkUpdateStorageinstallation_Identifiers *self, const R4SdkUpdateNativeValue27 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,116u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Identifiers_get_partitions(const R4SdkUpdateStorageinstallation_Identifiers *self, R4SdkUpdateNativeValue117 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,116u,2u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Identifiers_set_partitions(R4SdkUpdateStorageinstallation_Identifiers *self, const R4SdkUpdateNativeValue117 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,116u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Identifiers_inspectNative(const R4SdkUpdateStorageinstallation_Identifiers *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,116u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue117_create(R4SdkUpdateNativeValue117 *output, const R4SdkUpdateNativeValue117 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,117u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue117_inspectNative(const R4SdkUpdateNativeValue117 *self, R4SdkUpdateNativeValue117 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,117u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_create(R4SdkUpdateStorageinstallation_Layout *output, uint64_t p0, const R4SdkUpdateStorageinstallation_Identifiers * p1, const R4SdkUpdateNativeValue33 * p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,118u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_from_fields(R4SdkUpdateStorageinstallation_Layout *output, uint64_t p0, const R4SdkUpdateStorageinstallation_Identifiers * p1, const R4SdkUpdateNativeValue33 * p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,118u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_get_sectors(const R4SdkUpdateStorageinstallation_Layout *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,118u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_set_sectors(R4SdkUpdateStorageinstallation_Layout *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,118u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_get_ids(const R4SdkUpdateStorageinstallation_Layout *self, R4SdkUpdateStorageinstallation_Identifiers *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,118u,1u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_set_ids(R4SdkUpdateStorageinstallation_Layout *self, const R4SdkUpdateStorageinstallation_Identifiers * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,118u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_get_ranges(const R4SdkUpdateStorageinstallation_Layout *self, R4SdkUpdateNativeValue33 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,118u,2u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_set_ranges(R4SdkUpdateStorageinstallation_Layout *self, const R4SdkUpdateNativeValue33 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,118u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateStorageinstallation_Layout_inspectNative(const R4SdkUpdateStorageinstallation_Layout *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,118u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue119_create(R4SdkUpdateNativeValue119 *output, const R4SdkUpdatePartitionPlan * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,119u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue119_inspectNative(const R4SdkUpdateNativeValue119 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,119u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue120_inspectNative(const R4SdkUpdateNativeValue120 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,120u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue121_inspectNative(const R4SdkUpdateNativeValue121 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,121u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateGuestTarget_create(R4SdkUpdateGuestTarget *output, const R4SdkUpdateNative_storage_Context * p0, const R4StorageTarget * p1) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,122u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateGuestTarget_from_fields(R4SdkUpdateGuestTarget *output, const R4SdkUpdateNative_storage_Context * p0, const R4StorageTarget * p1, uint64_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,122u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateGuestTarget_get_storage(const R4SdkUpdateGuestTarget *self, R4SdkUpdateNative_storage_Context *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,122u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateGuestTarget_set_storage(R4SdkUpdateGuestTarget *self, const R4SdkUpdateNative_storage_Context * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,122u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateGuestTarget_get_target(const R4SdkUpdateGuestTarget *self, R4StorageTarget *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,122u,1u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateGuestTarget_set_target(R4SdkUpdateGuestTarget *self, const R4StorageTarget * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,122u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateGuestTarget_get_claim(const R4SdkUpdateGuestTarget *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,122u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateGuestTarget_set_claim(R4SdkUpdateGuestTarget *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,122u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateGuestTarget_inspectNative(const R4SdkUpdateGuestTarget *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,122u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryModuleRole_create(R4SdkUpdateInventoryModuleRole *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,138u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryModuleRole_inspectNative(const R4SdkUpdateInventoryModuleRole *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,138u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryProfile_create(R4SdkUpdateInventoryProfile *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,139u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryProfile_inspectNative(const R4SdkUpdateInventoryProfile *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,139u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_create(R4SdkUpdateInventoryEntry *output, const uint8_t * p0, uintptr_t n0, uint32_t p1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3) {
 R4SdkUpdateSlot a[13]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 a[8].flags=R4SDKUPDATE_DEFAULT;
 a[9].flags=R4SDKUPDATE_DEFAULT;
 a[10].flags=R4SDKUPDATE_DEFAULT;
 a[11].flags=R4SDKUPDATE_DEFAULT;
 a[12].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,140u,a,13u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_from_fields(R4SdkUpdateInventoryEntry *output, const uint8_t * p0, uintptr_t n0, uint32_t p1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, R4SdkUpdateSlot p4, R4SdkUpdateSlot p5, R4SdkUpdateSlot p6, const R4SdkUpdateNativeValue142 * p7, uint64_t p8, const R4SdkUpdateNativeValue143 * p9, uint64_t p10, const R4SdkUpdateNativeValue143 * p11, uint64_t p12) {
 R4SdkUpdateSlot a[13]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = p4;
 a[5] = p5;
 a[6] = p6;
 a[7] = (R4SdkUpdateSlot){.ptr=(void *)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.ptr=(void *)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.ptr=(void *)p11,.flags=R4SDKUPDATE_PRESENT};
 a[12] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,140u,a,13u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_name(const R4SdkUpdateInventoryEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_name(R4SdkUpdateInventoryEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_kind(const R4SdkUpdateInventoryEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_kind(R4SdkUpdateInventoryEntry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_version(const R4SdkUpdateInventoryEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_version(R4SdkUpdateInventoryEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_target(const R4SdkUpdateInventoryEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_target(R4SdkUpdateInventoryEntry *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_module_role(const R4SdkUpdateInventoryEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_module_role(R4SdkUpdateInventoryEntry *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_subsystem_id(const R4SdkUpdateInventoryEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_subsystem_id(R4SdkUpdateInventoryEntry *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_subsystem_display_name(const R4SdkUpdateInventoryEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_subsystem_display_name(R4SdkUpdateInventoryEntry *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_guest_formats(const R4SdkUpdateInventoryEntry *self, R4SdkUpdateNativeValue142 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,7u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_guest_formats(R4SdkUpdateInventoryEntry *self, const R4SdkUpdateNativeValue142 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_guest_format_count(const R4SdkUpdateInventoryEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_guest_format_count(R4SdkUpdateInventoryEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_guest_extensions(const R4SdkUpdateInventoryEntry *self, R4SdkUpdateNativeValue143 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,9u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_guest_extensions(R4SdkUpdateInventoryEntry *self, const R4SdkUpdateNativeValue143 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_guest_extension_count(const R4SdkUpdateInventoryEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,10u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_guest_extension_count(R4SdkUpdateInventoryEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_guest_features(const R4SdkUpdateInventoryEntry *self, R4SdkUpdateNativeValue143 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,11u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_guest_features(R4SdkUpdateInventoryEntry *self, const R4SdkUpdateNativeValue143 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,11u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_get_guest_feature_count(const R4SdkUpdateInventoryEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,12u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_set_guest_feature_count(R4SdkUpdateInventoryEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,140u,12u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryEntry_inspectNative(const R4SdkUpdateInventoryEntry *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,140u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue141_create(R4SdkUpdateNativeValue141 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,141u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue141_inspectNative(const R4SdkUpdateNativeValue141 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,141u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue142_create(R4SdkUpdateNativeValue142 *output, const R4SdkUpdateNativeValue142 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,142u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue142_inspectNative(const R4SdkUpdateNativeValue142 *self, R4SdkUpdateNativeValue142 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,142u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue143_create(R4SdkUpdateNativeValue143 *output, const R4SdkUpdateNativeValue143 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,143u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue143_inspectNative(const R4SdkUpdateNativeValue143 *self, R4SdkUpdateNativeValue143 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,143u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_create(R4SdkUpdateInventoryInventory *output) {
 R4SdkUpdateSlot a[3]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,144u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_from_fields(R4SdkUpdateInventoryInventory *output, uint32_t p0, const R4SdkUpdateNativeValue145 * p1, uint64_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,144u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_get_profile(const R4SdkUpdateInventoryInventory *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,144u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_set_profile(R4SdkUpdateInventoryInventory *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,144u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_get_entries(const R4SdkUpdateInventoryInventory *self, R4SdkUpdateNativeValue145 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,144u,1u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_set_entries(R4SdkUpdateInventoryInventory *self, const R4SdkUpdateNativeValue145 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,144u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_get_count(const R4SdkUpdateInventoryInventory *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,144u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_set_count(R4SdkUpdateInventoryInventory *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,144u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateInventoryInventory_inspectNative(const R4SdkUpdateInventoryInventory *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,144u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue145_create(R4SdkUpdateNativeValue145 *output, const R4SdkUpdateNativeValue145 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,145u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue145_inspectNative(const R4SdkUpdateNativeValue145 *self, R4SdkUpdateNativeValue145 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,145u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPhase_create(R4SdkUpdateRecoveryJournalPhase *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,146u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPhase_inspectNative(const R4SdkUpdateRecoveryJournalPhase *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,146u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryPathState_create(R4SdkUpdateRecoveryPathState *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,147u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryPathState_inspectNative(const R4SdkUpdateRecoveryPathState *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,147u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryPresenceState_create(R4SdkUpdateRecoveryPresenceState *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,148u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryPresenceState_inspectNative(const R4SdkUpdateRecoveryPresenceState *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,148u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryMutationStatus_create(R4SdkUpdateRecoveryMutationStatus *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,149u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryMutationStatus_inspectNative(const R4SdkUpdateRecoveryMutationStatus *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,149u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryReplayStatus_create(R4SdkUpdateRecoveryReplayStatus *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,150u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryReplayStatus_inspectNative(const R4SdkUpdateRecoveryReplayStatus *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,150u,(void *)self,0); }
#define R4SdkUpdateRecoverySlotSelection_TAG_selected 0u
#define R4SdkUpdateRecoverySlotSelection_TAG_not_found 1u
#define R4SdkUpdateRecoverySlotSelection_TAG_invalid 2u
static inline R4SdkUpdateSlot R4SdkUpdateRecoverySlotSelection_get_selected(const R4SdkUpdateRecoverySlotSelection *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,151u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoverySlotSelection_set_selected(R4SdkUpdateRecoverySlotSelection *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,151u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoverySlotSelection_get_not_found(const R4SdkUpdateRecoverySlotSelection *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,151u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoverySlotSelection_set_not_found(R4SdkUpdateRecoverySlotSelection *self) { R4SdkUpdateSlot a[1]={0};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,151u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoverySlotSelection_get_invalid(const R4SdkUpdateRecoverySlotSelection *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,151u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoverySlotSelection_set_invalid(R4SdkUpdateRecoverySlotSelection *self) { R4SdkUpdateSlot a[1]={0};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,151u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoverySlotSelection_inspectNative(const R4SdkUpdateRecoverySlotSelection *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,151u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNative__typeInfo_system_update_recovery_SlotSelection____union__tag_type___create(R4SdkUpdateNative__typeInfo_system_update_recovery_SlotSelection____union__tag_type__ *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,152u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNative__typeInfo_system_update_recovery_SlotSelection____union__tag_type___inspectNative(const R4SdkUpdateNative__typeInfo_system_update_recovery_SlotSelection____union__tag_type__ *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,152u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_create(R4SdkUpdateRecoveryJournalPayload *output) {
 R4SdkUpdateSlot a[20]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 a[8].flags=R4SDKUPDATE_DEFAULT;
 a[9].flags=R4SDKUPDATE_DEFAULT;
 a[10].flags=R4SDKUPDATE_DEFAULT;
 a[11].flags=R4SDKUPDATE_DEFAULT;
 a[12].flags=R4SDKUPDATE_DEFAULT;
 a[13].flags=R4SDKUPDATE_DEFAULT;
 a[14].flags=R4SDKUPDATE_DEFAULT;
 a[15].flags=R4SDKUPDATE_DEFAULT;
 a[16].flags=R4SDKUPDATE_DEFAULT;
 a[17].flags=R4SDKUPDATE_DEFAULT;
 a[18].flags=R4SDKUPDATE_DEFAULT;
 a[19].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,153u,a,20u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_from_fields(R4SdkUpdateRecoveryJournalPayload *output, const R4SdkUpdateNativeValue154 * p0, uint64_t p1, const R4SdkUpdateNativeValue154 * p2, uint64_t p3, const R4SdkUpdateNativeValue154 * p4, uint64_t p5, const R4SdkUpdateNativeValue154 * p6, uint64_t p7, uint8_t p8, uint64_t p9, uint32_t p10, uint64_t p11, uint32_t p12, uint8_t p13, uint8_t p14, uint64_t p15, uint32_t p16, uint8_t p17, uint8_t p18, uint8_t p19) {
 R4SdkUpdateSlot a[20]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKUPDATE_PRESENT};
 a[12] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKUPDATE_PRESENT};
 a[13] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKUPDATE_PRESENT};
 a[14] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p14,.flags=R4SDKUPDATE_PRESENT};
 a[15] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p15,.flags=R4SDKUPDATE_PRESENT};
 a[16] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p16,.flags=R4SDKUPDATE_PRESENT};
 a[17] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p17,.flags=R4SDKUPDATE_PRESENT};
 a[18] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p18,.flags=R4SDKUPDATE_PRESENT};
 a[19] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p19,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,153u,a,20u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_target_path(const R4SdkUpdateRecoveryJournalPayload *self, R4SdkUpdateNativeValue154 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_target_path(R4SdkUpdateRecoveryJournalPayload *self, const R4SdkUpdateNativeValue154 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_target_len(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_target_len(R4SdkUpdateRecoveryJournalPayload *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_stage_path(const R4SdkUpdateRecoveryJournalPayload *self, R4SdkUpdateNativeValue154 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,2u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_stage_path(R4SdkUpdateRecoveryJournalPayload *self, const R4SdkUpdateNativeValue154 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_stage_len(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_stage_len(R4SdkUpdateRecoveryJournalPayload *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_backup_path(const R4SdkUpdateRecoveryJournalPayload *self, R4SdkUpdateNativeValue154 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,4u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_backup_path(R4SdkUpdateRecoveryJournalPayload *self, const R4SdkUpdateNativeValue154 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_backup_len(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_backup_len(R4SdkUpdateRecoveryJournalPayload *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_previous_backup_path(const R4SdkUpdateRecoveryJournalPayload *self, R4SdkUpdateNativeValue154 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,6u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_previous_backup_path(R4SdkUpdateRecoveryJournalPayload *self, const R4SdkUpdateNativeValue154 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_previous_backup_len(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_previous_backup_len(R4SdkUpdateRecoveryJournalPayload *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_previous_backup_known(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_previous_backup_known(R4SdkUpdateRecoveryJournalPayload *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_previous_backup_size(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_previous_backup_size(R4SdkUpdateRecoveryJournalPayload *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_previous_backup_checksum(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,10u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_previous_backup_checksum(R4SdkUpdateRecoveryJournalPayload *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_size(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,11u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_size(R4SdkUpdateRecoveryJournalPayload *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,11u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_checksum(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,12u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_checksum(R4SdkUpdateRecoveryJournalPayload *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,12u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_target_existed(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,13u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_target_existed(R4SdkUpdateRecoveryJournalPayload *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,13u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_old_known(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,14u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_old_known(R4SdkUpdateRecoveryJournalPayload *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,14u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_old_size(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,15u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_old_size(R4SdkUpdateRecoveryJournalPayload *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,15u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_old_checksum(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,16u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_old_checksum(R4SdkUpdateRecoveryJournalPayload *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,16u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_committed(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,17u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_committed(R4SdkUpdateRecoveryJournalPayload *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,17u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_rolled_back(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,18u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_rolled_back(R4SdkUpdateRecoveryJournalPayload *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,18u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_get_replace_required(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,19u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_set_replace_required(R4SdkUpdateRecoveryJournalPayload *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,153u,19u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalPayload_inspectNative(const R4SdkUpdateRecoveryJournalPayload *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,153u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue154_create(R4SdkUpdateNativeValue154 *output, const R4SdkUpdateNativeValue154 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,154u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue154_inspectNative(const R4SdkUpdateNativeValue154 *self, R4SdkUpdateNativeValue154 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,154u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponentKind_create(R4SdkUpdateRecoveryJournalComponentKind *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,155u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponentKind_inspectNative(const R4SdkUpdateRecoveryJournalComponentKind *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,155u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_create(R4SdkUpdateRecoveryJournalComponent *output) {
 R4SdkUpdateSlot a[8]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,156u,a,8u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_from_fields(R4SdkUpdateRecoveryJournalComponent *output, uint32_t p0, uint32_t p1, const R4SdkUpdateNativeValue157 * p2, uint64_t p3, const R4SdkUpdateNativeValue154 * p4, uint64_t p5, const R4SdkUpdateNativeValue158 * p6, uint64_t p7) {
 R4SdkUpdateSlot a[8]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,156u,a,8u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_get_payload_index(const R4SdkUpdateRecoveryJournalComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_set_payload_index(R4SdkUpdateRecoveryJournalComponent *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_get_kind(const R4SdkUpdateRecoveryJournalComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_set_kind(R4SdkUpdateRecoveryJournalComponent *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_get_name(const R4SdkUpdateRecoveryJournalComponent *self, R4SdkUpdateNativeValue157 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,2u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_set_name(R4SdkUpdateRecoveryJournalComponent *self, const R4SdkUpdateNativeValue157 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_get_name_len(const R4SdkUpdateRecoveryJournalComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_set_name_len(R4SdkUpdateRecoveryJournalComponent *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_get_target(const R4SdkUpdateRecoveryJournalComponent *self, R4SdkUpdateNativeValue154 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,4u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_set_target(R4SdkUpdateRecoveryJournalComponent *self, const R4SdkUpdateNativeValue154 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_get_target_len(const R4SdkUpdateRecoveryJournalComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_set_target_len(R4SdkUpdateRecoveryJournalComponent *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_get_version(const R4SdkUpdateRecoveryJournalComponent *self, R4SdkUpdateNativeValue158 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,6u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_set_version(R4SdkUpdateRecoveryJournalComponent *self, const R4SdkUpdateNativeValue158 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_get_version_len(const R4SdkUpdateRecoveryJournalComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_set_version_len(R4SdkUpdateRecoveryJournalComponent *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,156u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryJournalComponent_inspectNative(const R4SdkUpdateRecoveryJournalComponent *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,156u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue157_create(R4SdkUpdateNativeValue157 *output, const R4SdkUpdateNativeValue157 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,157u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue157_inspectNative(const R4SdkUpdateNativeValue157 *self, R4SdkUpdateNativeValue157 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,157u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue158_create(R4SdkUpdateNativeValue158 *output, const R4SdkUpdateNativeValue158 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,158u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue158_inspectNative(const R4SdkUpdateNativeValue158 *self, R4SdkUpdateNativeValue158 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,158u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_create(R4SdkUpdateRecoveryTransactionJournal *output) {
 R4SdkUpdateSlot a[29]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 a[8].flags=R4SDKUPDATE_DEFAULT;
 a[9].flags=R4SDKUPDATE_DEFAULT;
 a[10].flags=R4SDKUPDATE_DEFAULT;
 a[11].flags=R4SDKUPDATE_DEFAULT;
 a[12].flags=R4SDKUPDATE_DEFAULT;
 a[13].flags=R4SDKUPDATE_DEFAULT;
 a[14].flags=R4SDKUPDATE_DEFAULT;
 a[15].flags=R4SDKUPDATE_DEFAULT;
 a[16].flags=R4SDKUPDATE_DEFAULT;
 a[17].flags=R4SDKUPDATE_DEFAULT;
 a[18].flags=R4SDKUPDATE_DEFAULT;
 a[19].flags=R4SDKUPDATE_DEFAULT;
 a[20].flags=R4SDKUPDATE_DEFAULT;
 a[21].flags=R4SDKUPDATE_DEFAULT;
 a[22].flags=R4SDKUPDATE_DEFAULT;
 a[23].flags=R4SDKUPDATE_DEFAULT;
 a[24].flags=R4SDKUPDATE_DEFAULT;
 a[25].flags=R4SDKUPDATE_DEFAULT;
 a[26].flags=R4SDKUPDATE_DEFAULT;
 a[27].flags=R4SDKUPDATE_DEFAULT;
 a[28].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,159u,a,29u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_from_fields(R4SdkUpdateRecoveryTransactionJournal *output, uint8_t p0, uint8_t p1, uint64_t p2, uint64_t p3, uint32_t p4, uint32_t p5, uint64_t p6, uint32_t p7, uint32_t p8, uint32_t p9, uint8_t p10, const R4SdkUpdateNativeValue160 * p11, uint8_t p12, const R4SdkUpdateNativeValue158 * p13, uint64_t p14, const R4SdkUpdateNativeValue154 * p15, uint64_t p16, const R4SdkUpdateNativeValue158 * p17, uint64_t p18, const R4SdkUpdateNativeValue158 * p19, uint64_t p20, uint32_t p21, uint32_t p22, uint32_t p23, uint32_t p24, uint8_t p25, uint8_t p26, uint8_t p27, const R4SdkUpdateNativeValue161 * p28) {
 R4SdkUpdateSlot a[29]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.ptr=(void *)p11,.flags=R4SDKUPDATE_PRESENT};
 a[12] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKUPDATE_PRESENT};
 a[13] = (R4SdkUpdateSlot){.ptr=(void *)p13,.flags=R4SDKUPDATE_PRESENT};
 a[14] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p14,.flags=R4SDKUPDATE_PRESENT};
 a[15] = (R4SdkUpdateSlot){.ptr=(void *)p15,.flags=R4SDKUPDATE_PRESENT};
 a[16] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p16,.flags=R4SDKUPDATE_PRESENT};
 a[17] = (R4SdkUpdateSlot){.ptr=(void *)p17,.flags=R4SDKUPDATE_PRESENT};
 a[18] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p18,.flags=R4SDKUPDATE_PRESENT};
 a[19] = (R4SdkUpdateSlot){.ptr=(void *)p19,.flags=R4SDKUPDATE_PRESENT};
 a[20] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p20,.flags=R4SDKUPDATE_PRESENT};
 a[21] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p21,.flags=R4SDKUPDATE_PRESENT};
 a[22] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p22,.flags=R4SDKUPDATE_PRESENT};
 a[23] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p23,.flags=R4SDKUPDATE_PRESENT};
 a[24] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p24,.flags=R4SDKUPDATE_PRESENT};
 a[25] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p25,.flags=R4SDKUPDATE_PRESENT};
 a[26] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p26,.flags=R4SDKUPDATE_PRESENT};
 a[27] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p27,.flags=R4SDKUPDATE_PRESENT};
 a[28] = (R4SdkUpdateSlot){.ptr=(void *)p28,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,159u,a,29u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_valid(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_valid(R4SdkUpdateRecoveryTransactionJournal *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_slot(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_slot(R4SdkUpdateRecoveryTransactionJournal *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_transaction_generation(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_transaction_generation(R4SdkUpdateRecoveryTransactionJournal *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_journal_generation(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_journal_generation(R4SdkUpdateRecoveryTransactionJournal *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_phase(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_phase(R4SdkUpdateRecoveryTransactionJournal *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_package_digest(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_package_digest(R4SdkUpdateRecoveryTransactionJournal *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_package_length(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_package_length(R4SdkUpdateRecoveryTransactionJournal *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_manifest_checksum(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_manifest_checksum(R4SdkUpdateRecoveryTransactionJournal *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_component_digest(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_component_digest(R4SdkUpdateRecoveryTransactionJournal *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_component_count(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_component_count(R4SdkUpdateRecoveryTransactionJournal *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_components_bound(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,10u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_components_bound(R4SdkUpdateRecoveryTransactionJournal *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_components(const R4SdkUpdateRecoveryTransactionJournal *self, R4SdkUpdateNativeValue160 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,11u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_components(R4SdkUpdateRecoveryTransactionJournal *self, const R4SdkUpdateNativeValue160 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,11u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_foundation(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,12u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_foundation(R4SdkUpdateRecoveryTransactionJournal *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,12u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_package_version(const R4SdkUpdateRecoveryTransactionJournal *self, R4SdkUpdateNativeValue158 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,13u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_package_version(R4SdkUpdateRecoveryTransactionJournal *self, const R4SdkUpdateNativeValue158 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,13u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_package_version_len(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,14u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_package_version_len(R4SdkUpdateRecoveryTransactionJournal *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,14u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_source_path(const R4SdkUpdateRecoveryTransactionJournal *self, R4SdkUpdateNativeValue154 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,15u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_source_path(R4SdkUpdateRecoveryTransactionJournal *self, const R4SdkUpdateNativeValue154 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,15u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_source_len(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,16u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_source_len(R4SdkUpdateRecoveryTransactionJournal *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,16u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_source_version(const R4SdkUpdateRecoveryTransactionJournal *self, R4SdkUpdateNativeValue158 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,17u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_source_version(R4SdkUpdateRecoveryTransactionJournal *self, const R4SdkUpdateNativeValue158 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,17u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_source_version_len(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,18u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_source_version_len(R4SdkUpdateRecoveryTransactionJournal *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,18u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_target_version(const R4SdkUpdateRecoveryTransactionJournal *self, R4SdkUpdateNativeValue158 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,19u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_target_version(R4SdkUpdateRecoveryTransactionJournal *self, const R4SdkUpdateNativeValue158 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,19u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_target_version_len(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,20u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_target_version_len(R4SdkUpdateRecoveryTransactionJournal *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,20u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_package_payload_count(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,21u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_package_payload_count(R4SdkUpdateRecoveryTransactionJournal *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,21u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_payload_count(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,22u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_payload_count(R4SdkUpdateRecoveryTransactionJournal *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,22u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_committed_count(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,23u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_committed_count(R4SdkUpdateRecoveryTransactionJournal *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,23u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_rollback_count(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,24u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_rollback_count(R4SdkUpdateRecoveryTransactionJournal *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,24u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_reboot(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,25u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_reboot(R4SdkUpdateRecoveryTransactionJournal *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,25u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_batch(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,26u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_batch(R4SdkUpdateRecoveryTransactionJournal *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,26u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_rollback_markers_present(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,27u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_rollback_markers_present(R4SdkUpdateRecoveryTransactionJournal *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,27u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_get_payloads(const R4SdkUpdateRecoveryTransactionJournal *self, R4SdkUpdateNativeValue161 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,28u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_set_payloads(R4SdkUpdateRecoveryTransactionJournal *self, const R4SdkUpdateNativeValue161 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,159u,28u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateRecoveryTransactionJournal_inspectNative(const R4SdkUpdateRecoveryTransactionJournal *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,159u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue160_create(R4SdkUpdateNativeValue160 *output, const R4SdkUpdateNativeValue160 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,160u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue160_inspectNative(const R4SdkUpdateNativeValue160 *self, R4SdkUpdateNativeValue160 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,160u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue161_create(R4SdkUpdateNativeValue161 *output, const R4SdkUpdateNativeValue161 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,161u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue161_inspectNative(const R4SdkUpdateNativeValue161 *self, R4SdkUpdateNativeValue161 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,161u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue162_create(R4SdkUpdateNativeValue162 *output, const R4SdkUpdateNativeValue162 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,162u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue162_inspectNative(const R4SdkUpdateNativeValue162 *self, R4SdkUpdateNativeValue162 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,162u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue163_create(R4SdkUpdateNativeValue163 *output, const R4SdkUpdateNativeValue163 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,163u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue163_inspectNative(const R4SdkUpdateNativeValue163 *self, R4SdkUpdateNativeValue163 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,163u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue164_create(R4SdkUpdateNativeValue164 *output, const R4SdkUpdateRecoveryTransactionJournal * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,164u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue164_inspectNative(const R4SdkUpdateNativeValue164 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,164u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue165_create(R4SdkUpdateNativeValue165 *output, R4SdkUpdateRecoveryTransactionJournal * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,165u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue165_inspectNative(const R4SdkUpdateNativeValue165 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,165u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPhase_create(R4SdkUpdateBatchPhase *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,166u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPhase_inspectNative(const R4SdkUpdateBatchPhase *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,166u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_create(R4SdkUpdateBatchPackageEntry *output) {
 R4SdkUpdateSlot a[15]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 a[8].flags=R4SDKUPDATE_DEFAULT;
 a[9].flags=R4SDKUPDATE_DEFAULT;
 a[10].flags=R4SDKUPDATE_DEFAULT;
 a[11].flags=R4SDKUPDATE_DEFAULT;
 a[12].flags=R4SDKUPDATE_DEFAULT;
 a[13].flags=R4SDKUPDATE_DEFAULT;
 a[14].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,167u,a,15u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_from_fields(R4SdkUpdateBatchPackageEntry *output, uint8_t p0, const R4SdkUpdateNativeValue154 * p1, uint64_t p2, const R4SdkDataNative_Value138 * p3, uint64_t p4, const R4SdkDataNative_Value139 * p5, uint64_t p6, const R4SdkDataNative_Value139 * p7, uint64_t p8, uint64_t p9, uint32_t p10, uint32_t p11, uint32_t p12, uint32_t p13, uint32_t p14) {
 R4SdkUpdateSlot a[15]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.ptr=(void *)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.ptr=(void *)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKUPDATE_PRESENT};
 a[12] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKUPDATE_PRESENT};
 a[13] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKUPDATE_PRESENT};
 a[14] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p14,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,167u,a,15u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_order(const R4SdkUpdateBatchPackageEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_order(R4SdkUpdateBatchPackageEntry *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_path(const R4SdkUpdateBatchPackageEntry *self, R4SdkUpdateNativeValue154 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,1u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_path(R4SdkUpdateBatchPackageEntry *self, const R4SdkUpdateNativeValue154 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_path_len(const R4SdkUpdateBatchPackageEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_path_len(R4SdkUpdateBatchPackageEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_package(const R4SdkUpdateBatchPackageEntry *self, R4SdkDataNative_Value138 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,3u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_package(R4SdkUpdateBatchPackageEntry *self, const R4SdkDataNative_Value138 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_package_len(const R4SdkUpdateBatchPackageEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_package_len(R4SdkUpdateBatchPackageEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_package_version(const R4SdkUpdateBatchPackageEntry *self, R4SdkDataNative_Value139 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,5u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_package_version(R4SdkUpdateBatchPackageEntry *self, const R4SdkDataNative_Value139 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_package_version_len(const R4SdkUpdateBatchPackageEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_package_version_len(R4SdkUpdateBatchPackageEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_release(const R4SdkUpdateBatchPackageEntry *self, R4SdkDataNative_Value139 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,7u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_release(R4SdkUpdateBatchPackageEntry *self, const R4SdkDataNative_Value139 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_release_len(const R4SdkUpdateBatchPackageEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_release_len(R4SdkUpdateBatchPackageEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_package_length(const R4SdkUpdateBatchPackageEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_package_length(R4SdkUpdateBatchPackageEntry *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_package_digest(const R4SdkUpdateBatchPackageEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,10u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_package_digest(R4SdkUpdateBatchPackageEntry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_manifest_checksum(const R4SdkUpdateBatchPackageEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,11u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_manifest_checksum(R4SdkUpdateBatchPackageEntry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,11u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_component_digest(const R4SdkUpdateBatchPackageEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,12u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_component_digest(R4SdkUpdateBatchPackageEntry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,12u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_activation(const R4SdkUpdateBatchPackageEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,13u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_activation(R4SdkUpdateBatchPackageEntry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,13u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_get_priority(const R4SdkUpdateBatchPackageEntry *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,14u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_set_priority(R4SdkUpdateBatchPackageEntry *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,167u,14u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPackageEntry_inspectNative(const R4SdkUpdateBatchPackageEntry *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,167u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_create(R4SdkUpdateBatchBatchJournal *output) {
 R4SdkUpdateSlot a[14]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 a[8].flags=R4SDKUPDATE_DEFAULT;
 a[9].flags=R4SDKUPDATE_DEFAULT;
 a[10].flags=R4SDKUPDATE_DEFAULT;
 a[11].flags=R4SDKUPDATE_DEFAULT;
 a[12].flags=R4SDKUPDATE_DEFAULT;
 a[13].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,170u,a,14u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_from_fields(R4SdkUpdateBatchBatchJournal *output, uint8_t p0, uint8_t p1, uint64_t p2, uint64_t p3, uint32_t p4, uint32_t p5, uint32_t p6, const R4SdkDataNative_Value139 * p7, uint64_t p8, const R4SdkDataNative_Value139 * p9, uint64_t p10, const R4SdkUpdateNativeValue171 * p11, uint64_t p12, const R4SdkUpdateNativeValue172 * p13) {
 R4SdkUpdateSlot a[14]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.ptr=(void *)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.ptr=(void *)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.ptr=(void *)p11,.flags=R4SDKUPDATE_PRESENT};
 a[12] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKUPDATE_PRESENT};
 a[13] = (R4SdkUpdateSlot){.ptr=(void *)p13,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,170u,a,14u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_slot(const R4SdkUpdateBatchBatchJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_slot(R4SdkUpdateBatchBatchJournal *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_valid(const R4SdkUpdateBatchBatchJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_valid(R4SdkUpdateBatchBatchJournal *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_batch_generation(const R4SdkUpdateBatchBatchJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_batch_generation(R4SdkUpdateBatchBatchJournal *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_journal_generation(const R4SdkUpdateBatchBatchJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_journal_generation(R4SdkUpdateBatchBatchJournal *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_phase(const R4SdkUpdateBatchBatchJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_phase(R4SdkUpdateBatchBatchJournal *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_package_count(const R4SdkUpdateBatchBatchJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_package_count(R4SdkUpdateBatchBatchJournal *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_current_package(const R4SdkUpdateBatchBatchJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_current_package(R4SdkUpdateBatchBatchJournal *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_source_release(const R4SdkUpdateBatchBatchJournal *self, R4SdkDataNative_Value139 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,7u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_source_release(R4SdkUpdateBatchBatchJournal *self, const R4SdkDataNative_Value139 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_source_release_len(const R4SdkUpdateBatchBatchJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_source_release_len(R4SdkUpdateBatchBatchJournal *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_target_release(const R4SdkUpdateBatchBatchJournal *self, R4SdkDataNative_Value139 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,9u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_target_release(R4SdkUpdateBatchBatchJournal *self, const R4SdkDataNative_Value139 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_target_release_len(const R4SdkUpdateBatchBatchJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,10u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_target_release_len(R4SdkUpdateBatchBatchJournal *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_reason(const R4SdkUpdateBatchBatchJournal *self, R4SdkUpdateNativeValue171 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,11u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_reason(R4SdkUpdateBatchBatchJournal *self, const R4SdkUpdateNativeValue171 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,11u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_reason_len(const R4SdkUpdateBatchBatchJournal *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,12u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_reason_len(R4SdkUpdateBatchBatchJournal *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,12u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_get_packages(const R4SdkUpdateBatchBatchJournal *self, R4SdkUpdateNativeValue172 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,13u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_set_packages(R4SdkUpdateBatchBatchJournal *self, const R4SdkUpdateNativeValue172 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,170u,13u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchBatchJournal_inspectNative(const R4SdkUpdateBatchBatchJournal *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,170u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue171_create(R4SdkUpdateNativeValue171 *output, const R4SdkUpdateNativeValue171 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,171u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue171_inspectNative(const R4SdkUpdateNativeValue171 *self, R4SdkUpdateNativeValue171 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,171u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue172_create(R4SdkUpdateNativeValue172 *output, const R4SdkUpdateNativeValue172 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,172u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue172_inspectNative(const R4SdkUpdateNativeValue172 *self, R4SdkUpdateNativeValue172 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,172u,(void *)self,output); }
#define R4SdkUpdateBatchSlotSelection_TAG_selected 0u
#define R4SdkUpdateBatchSlotSelection_TAG_not_found 1u
#define R4SdkUpdateBatchSlotSelection_TAG_invalid 2u
static inline R4SdkUpdateSlot R4SdkUpdateBatchSlotSelection_get_selected(const R4SdkUpdateBatchSlotSelection *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,173u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchSlotSelection_set_selected(R4SdkUpdateBatchSlotSelection *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,173u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchSlotSelection_get_not_found(const R4SdkUpdateBatchSlotSelection *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,173u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchSlotSelection_set_not_found(R4SdkUpdateBatchSlotSelection *self) { R4SdkUpdateSlot a[1]={0};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,173u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchSlotSelection_get_invalid(const R4SdkUpdateBatchSlotSelection *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,173u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchSlotSelection_set_invalid(R4SdkUpdateBatchSlotSelection *self) { R4SdkUpdateSlot a[1]={0};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,173u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchSlotSelection_inspectNative(const R4SdkUpdateBatchSlotSelection *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,173u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNative__typeInfo_system_update_batch_SlotSelection____union__tag_type___create(R4SdkUpdateNative__typeInfo_system_update_batch_SlotSelection____union__tag_type__ *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,174u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNative__typeInfo_system_update_batch_SlotSelection____union__tag_type___inspectNative(const R4SdkUpdateNative__typeInfo_system_update_batch_SlotSelection____union__tag_type__ *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,174u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue175_create(R4SdkUpdateNativeValue175 *output, const R4SdkUpdateBatchBatchJournal * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,175u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue175_inspectNative(const R4SdkUpdateNativeValue175 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,175u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue176_create(R4SdkUpdateNativeValue176 *output, R4SdkUpdateBatchBatchJournal * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,176u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue176_inspectNative(const R4SdkUpdateNativeValue176 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,176u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_create(R4SdkUpdateBatchPlanComponent *output, uint8_t p0, uint32_t p1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4) {
 R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,177u,a,5u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_from_fields(R4SdkUpdateBatchPlanComponent *output, uint8_t p0, uint32_t p1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4) {
 R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,177u,a,5u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_get_package_index(const R4SdkUpdateBatchPlanComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,177u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_set_package_index(R4SdkUpdateBatchPlanComponent *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,177u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_get_kind(const R4SdkUpdateBatchPlanComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,177u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_set_kind(R4SdkUpdateBatchPlanComponent *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,177u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_get_name(const R4SdkUpdateBatchPlanComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,177u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_set_name(R4SdkUpdateBatchPlanComponent *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,177u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_get_target(const R4SdkUpdateBatchPlanComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,177u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_set_target(R4SdkUpdateBatchPlanComponent *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,177u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_get_version(const R4SdkUpdateBatchPlanComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,177u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_set_version(R4SdkUpdateBatchPlanComponent *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,177u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanComponent_inspectNative(const R4SdkUpdateBatchPlanComponent *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,177u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_create(R4SdkUpdateBatchPlanRequirement *output, uint8_t p0, uint32_t p1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4) {
 R4SdkUpdateSlot a[7]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,178u,a,7u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_from_fields(R4SdkUpdateBatchPlanRequirement *output, uint8_t p0, uint32_t p1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, uint32_t p5, uint8_t p6) {
 R4SdkUpdateSlot a[7]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p6,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,178u,a,7u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_get_package_index(const R4SdkUpdateBatchPlanRequirement *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_set_package_index(R4SdkUpdateBatchPlanRequirement *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_get_kind(const R4SdkUpdateBatchPlanRequirement *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_set_kind(R4SdkUpdateBatchPlanRequirement *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_get_name(const R4SdkUpdateBatchPlanRequirement *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_set_name(R4SdkUpdateBatchPlanRequirement *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_get_target(const R4SdkUpdateBatchPlanRequirement *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_set_target(R4SdkUpdateBatchPlanRequirement *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_get_version(const R4SdkUpdateBatchPlanRequirement *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_set_version(R4SdkUpdateBatchPlanRequirement *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_get_state(const R4SdkUpdateBatchPlanRequirement *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_set_state(R4SdkUpdateBatchPlanRequirement *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_get_current_satisfied(const R4SdkUpdateBatchPlanRequirement *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_set_current_satisfied(R4SdkUpdateBatchPlanRequirement *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,178u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanRequirement_inspectNative(const R4SdkUpdateBatchPlanRequirement *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,178u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanPackage_create(R4SdkUpdateBatchPlanPackage *output) {
 R4SdkUpdateSlot a[1]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,179u,a,1u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanPackage_from_fields(R4SdkUpdateBatchPlanPackage *output, uint32_t p0) {
 R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,179u,a,1u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanPackage_get_priority(const R4SdkUpdateBatchPlanPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,179u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanPackage_set_priority(R4SdkUpdateBatchPlanPackage *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,179u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateBatchPlanPackage_inspectNative(const R4SdkUpdateBatchPlanPackage *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,179u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue180_create(R4SdkUpdateNativeValue180 *output, const R4SdkUpdateBatchPlanPackage * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,180u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue180_inspectNative(const R4SdkUpdateNativeValue180 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,180u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue181_create(R4SdkUpdateNativeValue181 *output, const R4SdkUpdateBatchPlanComponent * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,181u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue181_inspectNative(const R4SdkUpdateNativeValue181 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,181u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue182_create(R4SdkUpdateNativeValue182 *output, const R4SdkUpdateBatchPlanRequirement * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,182u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue182_inspectNative(const R4SdkUpdateNativeValue182 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,182u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue183_inspectNative(const R4SdkUpdateNativeValue183 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,183u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_create(R4SdkUpdateCatalogComponent *output) {
 R4SdkUpdateSlot a[6]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,184u,a,6u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_from_fields(R4SdkUpdateCatalogComponent *output, uint8_t p0, uint32_t p1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, uint32_t p5) {
 R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,184u,a,6u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_get_payload(const R4SdkUpdateCatalogComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,184u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_set_payload(R4SdkUpdateCatalogComponent *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,184u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_get_kind(const R4SdkUpdateCatalogComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,184u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_set_kind(R4SdkUpdateCatalogComponent *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,184u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_get_name(const R4SdkUpdateCatalogComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,184u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_set_name(R4SdkUpdateCatalogComponent *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,184u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_get_target(const R4SdkUpdateCatalogComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,184u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_set_target(R4SdkUpdateCatalogComponent *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,184u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_get_version(const R4SdkUpdateCatalogComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,184u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_set_version(R4SdkUpdateCatalogComponent *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,184u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_get_install(const R4SdkUpdateCatalogComponent *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,184u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_set_install(R4SdkUpdateCatalogComponent *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,184u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogComponent_inspectNative(const R4SdkUpdateCatalogComponent *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,184u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_create(R4SdkUpdateCatalogRequirement *output) {
 R4SdkUpdateSlot a[5]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,185u,a,5u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_from_fields(R4SdkUpdateCatalogRequirement *output, uint32_t p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, uint32_t p4) {
 R4SdkUpdateSlot a[5]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,185u,a,5u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_get_kind(const R4SdkUpdateCatalogRequirement *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,185u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_set_kind(R4SdkUpdateCatalogRequirement *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,185u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_get_name(const R4SdkUpdateCatalogRequirement *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,185u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_set_name(R4SdkUpdateCatalogRequirement *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,185u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_get_target(const R4SdkUpdateCatalogRequirement *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,185u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_set_target(R4SdkUpdateCatalogRequirement *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,185u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_get_version(const R4SdkUpdateCatalogRequirement *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,185u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_set_version(R4SdkUpdateCatalogRequirement *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,185u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_get_state(const R4SdkUpdateCatalogRequirement *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,185u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_set_state(R4SdkUpdateCatalogRequirement *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,185u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogRequirement_inspectNative(const R4SdkUpdateCatalogRequirement *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,185u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_create(R4SdkUpdateCatalogPackage *output) {
 R4SdkUpdateSlot a[16]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 a[8].flags=R4SDKUPDATE_DEFAULT;
 a[9].flags=R4SDKUPDATE_DEFAULT;
 a[10].flags=R4SDKUPDATE_DEFAULT;
 a[11].flags=R4SDKUPDATE_DEFAULT;
 a[12].flags=R4SDKUPDATE_DEFAULT;
 a[13].flags=R4SDKUPDATE_DEFAULT;
 a[14].flags=R4SDKUPDATE_DEFAULT;
 a[15].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,186u,a,16u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_from_fields(R4SdkUpdateCatalogPackage *output, const uint8_t * p0, uintptr_t n0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const uint8_t * p4, uintptr_t n4, uint64_t p5, const uint8_t * p6, uintptr_t n6, uint8_t p7, uint32_t p8, uint32_t p9, uint32_t p10, uint16_t p11, uint16_t p12, uint16_t p13, uint16_t p14, const uint8_t * p15, uintptr_t n15) {
 R4SdkUpdateSlot a[16]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.length=n4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)p6,.length=n6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKUPDATE_PRESENT};
 a[12] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p12,.flags=R4SDKUPDATE_PRESENT};
 a[13] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p13,.flags=R4SDKUPDATE_PRESENT};
 a[14] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p14,.flags=R4SDKUPDATE_PRESENT};
 a[15] = (R4SdkUpdateSlot){.ptr=(void *)p15,.length=n15,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,186u,a,16u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_id(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_id(R4SdkUpdateCatalogPackage *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_package_version(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_package_version(R4SdkUpdateCatalogPackage *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_title(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_title(R4SdkUpdateCatalogPackage *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_description(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_description(R4SdkUpdateCatalogPackage *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_filename(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_filename(R4SdkUpdateCatalogPackage *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_size(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_size(R4SdkUpdateCatalogPackage *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_sha256(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,6u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_sha256(R4SdkUpdateCatalogPackage *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_reboot_required(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_reboot_required(R4SdkUpdateCatalogPackage *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_activation(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,8u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_activation(R4SdkUpdateCatalogPackage *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_priority(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_priority(R4SdkUpdateCatalogPackage *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_install_order(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,10u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_install_order(R4SdkUpdateCatalogPackage *self, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_component_start(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,11u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_component_start(R4SdkUpdateCatalogPackage *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,11u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_component_count(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,12u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_component_count(R4SdkUpdateCatalogPackage *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,12u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_requirement_start(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,13u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_requirement_start(R4SdkUpdateCatalogPackage *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,13u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_requirement_count(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,14u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_requirement_count(R4SdkUpdateCatalogPackage *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,14u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_get_download_url(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,15u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_set_download_url(R4SdkUpdateCatalogPackage *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,186u,15u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackage_inspectNative(const R4SdkUpdateCatalogPackage *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,186u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_create(R4SdkUpdateCatalogCatalogRelease *output) {
 R4SdkUpdateSlot a[12]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 a[6].flags=R4SDKUPDATE_DEFAULT;
 a[7].flags=R4SDKUPDATE_DEFAULT;
 a[8].flags=R4SDKUPDATE_DEFAULT;
 a[9].flags=R4SDKUPDATE_DEFAULT;
 a[10].flags=R4SDKUPDATE_DEFAULT;
 a[11].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,187u,a,12u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_from_fields(R4SdkUpdateCatalogCatalogRelease *output, uint8_t p0, const uint8_t * p1, uintptr_t n1, const uint8_t * p2, uintptr_t n2, const uint8_t * p3, uintptr_t n3, const R4SdkUpdateNativeValue188 * p4, uint64_t p5, const R4SdkUpdateNativeValue189 * p6, uint64_t p7, const R4SdkUpdateNativeValue188 * p8, uint64_t p9, const R4SdkUpdateNativeValue190 * p10, uint64_t p11) {
 R4SdkUpdateSlot a[12]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.ptr=(void *)p1,.length=n1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.ptr=(void *)p2,.length=n2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.ptr=(void *)p3,.length=n3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.ptr=(void *)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 a[6] = (R4SdkUpdateSlot){.ptr=(void *)p6,.flags=R4SDKUPDATE_PRESENT};
 a[7] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p7,.flags=R4SDKUPDATE_PRESENT};
 a[8] = (R4SdkUpdateSlot){.ptr=(void *)p8,.flags=R4SDKUPDATE_PRESENT};
 a[9] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p9,.flags=R4SDKUPDATE_PRESENT};
 a[10] = (R4SdkUpdateSlot){.ptr=(void *)p10,.flags=R4SDKUPDATE_PRESENT};
 a[11] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p11,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,187u,a,12u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_get_valid(const R4SdkUpdateCatalogCatalogRelease *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_set_valid(R4SdkUpdateCatalogCatalogRelease *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_get_release(const R4SdkUpdateCatalogCatalogRelease *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_set_release(R4SdkUpdateCatalogCatalogRelease *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_get_manifest_filename(const R4SdkUpdateCatalogCatalogRelease *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_set_manifest_filename(R4SdkUpdateCatalogCatalogRelease *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_get_manifest_sha256(const R4SdkUpdateCatalogCatalogRelease *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_set_manifest_sha256(R4SdkUpdateCatalogCatalogRelease *self, const uint8_t * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_get_required(const R4SdkUpdateCatalogCatalogRelease *self, R4SdkUpdateNativeValue188 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,4u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_set_required(R4SdkUpdateCatalogCatalogRelease *self, const R4SdkUpdateNativeValue188 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_get_required_count(const R4SdkUpdateCatalogCatalogRelease *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_set_required_count(R4SdkUpdateCatalogCatalogRelease *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_get_packages(const R4SdkUpdateCatalogCatalogRelease *self, R4SdkUpdateNativeValue189 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,6u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_set_packages(R4SdkUpdateCatalogCatalogRelease *self, const R4SdkUpdateNativeValue189 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,6u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_get_package_count(const R4SdkUpdateCatalogCatalogRelease *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,7u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_set_package_count(R4SdkUpdateCatalogCatalogRelease *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,7u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_get_components(const R4SdkUpdateCatalogCatalogRelease *self, R4SdkUpdateNativeValue188 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,8u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_set_components(R4SdkUpdateCatalogCatalogRelease *self, const R4SdkUpdateNativeValue188 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,8u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_get_component_count(const R4SdkUpdateCatalogCatalogRelease *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,9u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_set_component_count(R4SdkUpdateCatalogCatalogRelease *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,9u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_get_requirements(const R4SdkUpdateCatalogCatalogRelease *self, R4SdkUpdateNativeValue190 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,10u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_set_requirements(R4SdkUpdateCatalogCatalogRelease *self, const R4SdkUpdateNativeValue190 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,10u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_get_requirement_count(const R4SdkUpdateCatalogCatalogRelease *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,11u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_set_requirement_count(R4SdkUpdateCatalogCatalogRelease *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,187u,11u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogCatalogRelease_inspectNative(const R4SdkUpdateCatalogCatalogRelease *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,187u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue188_create(R4SdkUpdateNativeValue188 *output, const R4SdkUpdateNativeValue188 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,188u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue188_inspectNative(const R4SdkUpdateNativeValue188 *self, R4SdkUpdateNativeValue188 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,188u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue189_create(R4SdkUpdateNativeValue189 *output, const R4SdkUpdateNativeValue189 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,189u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue189_inspectNative(const R4SdkUpdateNativeValue189 *self, R4SdkUpdateNativeValue189 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,189u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue190_create(R4SdkUpdateNativeValue190 *output, const R4SdkUpdateNativeValue190 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,190u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue190_inspectNative(const R4SdkUpdateNativeValue190 *self, R4SdkUpdateNativeValue190 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,190u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackageDelta_create(R4SdkUpdateCatalogPackageDelta *output) {
 R4SdkUpdateSlot a[3]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,191u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackageDelta_from_fields(R4SdkUpdateCatalogPackageDelta *output, uint8_t p0, uint16_t p1, uint16_t p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,191u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackageDelta_get_eligible(const R4SdkUpdateCatalogPackageDelta *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,191u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackageDelta_set_eligible(R4SdkUpdateCatalogPackageDelta *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,191u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackageDelta_get_update_count(const R4SdkUpdateCatalogPackageDelta *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,191u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackageDelta_set_update_count(R4SdkUpdateCatalogPackageDelta *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,191u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackageDelta_get_repair_count(const R4SdkUpdateCatalogPackageDelta *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,191u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackageDelta_set_repair_count(R4SdkUpdateCatalogPackageDelta *self, uint16_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,191u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPackageDelta_inspectNative(const R4SdkUpdateCatalogPackageDelta *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,191u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_create(R4SdkUpdateCatalogPlan *output) {
 R4SdkUpdateSlot a[6]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 a[3].flags=R4SDKUPDATE_DEFAULT;
 a[4].flags=R4SDKUPDATE_DEFAULT;
 a[5].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,192u,a,6u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_from_fields(R4SdkUpdateCatalogPlan *output, const R4SdkUpdateNativeValue193 * p0, uint64_t p1, uint64_t p2, uint64_t p3, uint8_t p4, uint8_t p5) {
 R4SdkUpdateSlot a[6]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p2,.flags=R4SDKUPDATE_PRESENT};
 a[3] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p3,.flags=R4SDKUPDATE_PRESENT};
 a[4] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p4,.flags=R4SDKUPDATE_PRESENT};
 a[5] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p5,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,192u,a,6u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_get_package_indices(const R4SdkUpdateCatalogPlan *self, R4SdkUpdateNativeValue193 *output) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,192u,0u,(void *)self,0,output); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_set_package_indices(R4SdkUpdateCatalogPlan *self, const R4SdkUpdateNativeValue193 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,192u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_get_package_count(const R4SdkUpdateCatalogPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,192u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_set_package_count(R4SdkUpdateCatalogPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,192u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_get_update_component_count(const R4SdkUpdateCatalogPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,192u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_set_update_component_count(R4SdkUpdateCatalogPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,192u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_get_missing_required_count(const R4SdkUpdateCatalogPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,192u,3u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_set_missing_required_count(R4SdkUpdateCatalogPlan *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,192u,3u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_get_restart_required(const R4SdkUpdateCatalogPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,192u,4u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_set_restart_required(R4SdkUpdateCatalogPlan *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,192u,4u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_get_release_newer(const R4SdkUpdateCatalogPlan *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,192u,5u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_set_release_newer(R4SdkUpdateCatalogPlan *self, uint8_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,192u,5u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCatalogPlan_inspectNative(const R4SdkUpdateCatalogPlan *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,192u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue193_create(R4SdkUpdateNativeValue193 *output, const R4SdkUpdateNativeValue193 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,193u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue193_inspectNative(const R4SdkUpdateNativeValue193 *self, R4SdkUpdateNativeValue193 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,193u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue194_create(R4SdkUpdateNativeValue194 *output, const R4SdkUpdateCatalogCatalogRelease * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,194u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue194_inspectNative(const R4SdkUpdateNativeValue194 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,194u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue195_create(R4SdkUpdateNativeValue195 *output, const R4SdkUpdateInventoryInventory * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,195u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue195_inspectNative(const R4SdkUpdateNativeValue195 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,195u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue196_inspectNative(const R4SdkUpdateNativeValue196 *self, R4SdkUpdateCatalogPlan *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,196u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue197_create(R4SdkUpdateNativeValue197 *output, const R4SdkUpdateCatalogPackage * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,197u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue197_inspectNative(const R4SdkUpdateNativeValue197 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,197u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue198_inspectNative(const R4SdkUpdateNativeValue198 *self, R4SdkUpdateCatalogPackageDelta *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,198u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue199_create(R4SdkUpdateNativeValue199 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,199u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue199_inspectNative(const R4SdkUpdateNativeValue199 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,199u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue200_create(R4SdkUpdateNativeValue200 *output, const R4SdkUpdateInventoryEntry * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,200u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue200_inspectNative(const R4SdkUpdateNativeValue200 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,200u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCallbackKind_create(R4SdkUpdateCallbackKind *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,201u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateCallbackKind_inspectNative(const R4SdkUpdateCallbackKind *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,201u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCallbackTable_create(R4SdkUpdateCallbackTable *output) {
 R4SdkUpdateSlot a[3]={0};
 a[0].flags=R4SDKUPDATE_DEFAULT;
 a[1].flags=R4SDKUPDATE_DEFAULT;
 a[2].flags=R4SDKUPDATE_DEFAULT;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,202u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCallbackTable_from_fields(R4SdkUpdateCallbackTable *output, R4SdkUpdateSlot p0, uint64_t p1, R4SdkUpdateSlot p2) {
 R4SdkUpdateSlot a[3]={0};
 a[0] = p0;
 a[1] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p1,.flags=R4SDKUPDATE_PRESENT};
 a[2] = p2;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,202u,a,3u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateCallbackTable_get_user(const R4SdkUpdateCallbackTable *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,202u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCallbackTable_set_user(R4SdkUpdateCallbackTable *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,202u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCallbackTable_get_mask(const R4SdkUpdateCallbackTable *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,202u,1u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCallbackTable_set_mask(R4SdkUpdateCallbackTable *self, uint64_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,202u,1u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCallbackTable_get_invoke(const R4SdkUpdateCallbackTable *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,202u,2u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCallbackTable_set_invoke(R4SdkUpdateCallbackTable *self, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,202u,2u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateCallbackTable_inspectNative(const R4SdkUpdateCallbackTable *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,202u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue203_create(R4SdkUpdateNativeValue203 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,203u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue203_inspectNative(const R4SdkUpdateNativeValue203 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,203u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateReplay_create(R4SdkUpdateReplay *output, const R4SdkUpdateCallbackTable * p0) {
 R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,204u,a,1u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateReplay_from_fields(R4SdkUpdateReplay *output, const R4SdkUpdateCallbackTable * p0) {
 R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,204u,a,1u,output);
}
static inline R4SdkUpdateSlot R4SdkUpdateReplay_get_table(const R4SdkUpdateReplay *self) { return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,204u,0u,(void *)self,0,0); }
static inline R4SdkUpdateSlot R4SdkUpdateReplay_set_table(R4SdkUpdateReplay *self, const R4SdkUpdateCallbackTable * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateField(R4SdkUpdate_ABI_FINGERPRINT,204u,0u,self,a,0); }
static inline R4SdkUpdateSlot R4SdkUpdateReplay_inspectNative(const R4SdkUpdateReplay *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,204u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue205_create(R4SdkUpdateNativeValue205 *output, const R4SdkUpdateCallbackTable * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,205u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue205_inspectNative(const R4SdkUpdateNativeValue205 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,205u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue206_inspectNative(const R4SdkUpdateNativeValue206 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,206u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue207_inspectNative(const R4SdkUpdateNativeValue207 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,207u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue208_inspectNative(const R4SdkUpdateNativeValue208 *self, R4SdkUpdateBlockDevice *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,208u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue209_inspectNative(const R4SdkUpdateNativeValue209 *self, R4SdkUpdateByteSource *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,209u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue210_create(R4SdkUpdateNativeValue210 *output, R4SdkUpdateGuestTarget * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,210u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue210_inspectNative(const R4SdkUpdateNativeValue210 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,210u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue213_inspectNative(const R4SdkUpdateNativeValue213 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,213u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue214_create(R4SdkUpdateNativeValue214 *output, R4SdkUpdateStoragegpt_repair_Report * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,214u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue214_inspectNative(const R4SdkUpdateNativeValue214 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,214u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue215_create(R4SdkUpdateNativeValue215 *output, const R4SdkUpdateStoragegpt_repair_Report * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,215u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue215_inspectNative(const R4SdkUpdateNativeValue215 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,215u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue216_inspectNative(const R4SdkUpdateNativeValue216 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,216u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue217_inspectNative(const R4SdkUpdateNativeValue217 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,217u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue219_create(R4SdkUpdateNativeValue219 *output, R4SdkUpdateCatalogCatalogRelease * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,219u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue219_inspectNative(const R4SdkUpdateNativeValue219 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,219u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue220_inspectNative(const R4SdkUpdateNativeValue220 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,220u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue221_inspectNative(const R4SdkUpdateNativeValue221 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,221u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue222_create(R4SdkUpdateNativeValue222 *output, R4SdkUpdateBlockRegion * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,222u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue222_inspectNative(const R4SdkUpdateNativeValue222 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,222u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue223_inspectNative(const R4SdkUpdateNativeValue223 *self, R4SdkUpdateBlockDevice *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,223u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue224_create(R4SdkUpdateNativeValue224 *output, R4SdkUpdateBlockMemory * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,224u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue224_inspectNative(const R4SdkUpdateNativeValue224 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,224u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue225_inspectNative(const R4SdkUpdateNativeValue225 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,225u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue226_inspectNative(const R4SdkUpdateNativeValue226 *self, R4SdkUpdateByteSource *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,226u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue227_inspectNative(const R4SdkUpdateNativeValue227 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,227u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue228_create(R4SdkUpdateNativeValue228 *output, R4SdkUpdateStoragesparse_image_Image * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,228u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue228_inspectNative(const R4SdkUpdateNativeValue228 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,228u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue229_inspectNative(const R4SdkUpdateNativeValue229 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,229u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue230_inspectNative(const R4SdkUpdateNativeValue230 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,230u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue231_create(R4SdkUpdateNativeValue231 *output, const R4SdkUpdateStoragesparse_image_Image * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,231u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue231_inspectNative(const R4SdkUpdateNativeValue231 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,231u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue232_inspectNative(const R4SdkUpdateNativeValue232 *self, R4SdkUpdatePartitionPlan *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,232u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue233_create(R4SdkUpdateNativeValue233 *output, R4SdkUpdatePartitionPlan * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,233u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue233_inspectNative(const R4SdkUpdateNativeValue233 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,233u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue234_inspectNative(const R4SdkUpdateNativeValue234 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,234u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue235_inspectNative(const R4SdkUpdateNativeValue235 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,235u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue236_inspectNative(const R4SdkUpdateNativeValue236 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,236u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue237_inspectNative(const R4SdkUpdateNativeValue237 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,237u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue238_inspectNative(const R4SdkUpdateNativeValue238 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,238u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue239_inspectNative(const R4SdkUpdateNativeValue239 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,239u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue240_inspectNative(const R4SdkUpdateNativeValue240 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,240u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue241_create(R4SdkUpdateNativeValue241 *output, R4SdkUpdatePartitionEntry * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,241u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue241_inspectNative(const R4SdkUpdateNativeValue241 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,241u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue242_create(R4SdkUpdateNativeValue242 *output, R4SdkUpdatePartitionRange * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,242u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue242_inspectNative(const R4SdkUpdateNativeValue242 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,242u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue243_inspectNative(const R4SdkUpdateNativeValue243 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,243u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue244_inspectNative(const R4SdkUpdateNativeValue244 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,244u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue245_inspectNative(const R4SdkUpdateNativeValue245 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,245u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue246_inspectNative(const R4SdkUpdateNativeValue246 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,246u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue247_inspectNative(const R4SdkUpdateNativeValue247 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,247u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue248_inspectNative(const R4SdkUpdateNativeValue248 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,248u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue249_inspectNative(const R4SdkUpdateNativeValue249 *self, R4SdkUpdateFat32Geometry *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,249u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue250_inspectNative(const R4SdkUpdateNativeValue250 *self, R4SdkUpdateFat32Plan *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,250u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue251_inspectNative(const R4SdkUpdateNativeValue251 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,251u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue252_create(R4SdkUpdateNativeValue252 *output, R4SdkUpdateStoragefat32_image_Streamed * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,252u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue252_inspectNative(const R4SdkUpdateNativeValue252 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,252u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue253_create(R4SdkUpdateNativeValue253 *output, const R4SdkUpdateStoragefat32_image_Streamed * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,253u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue253_inspectNative(const R4SdkUpdateNativeValue253 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,253u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue254_inspectNative(const R4SdkUpdateNativeValue254 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,254u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue255_create(R4SdkUpdateNativeValue255 *output, R4SdkUpdateStoragefat32_image_Prepared * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,255u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue255_inspectNative(const R4SdkUpdateNativeValue255 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,255u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue256_inspectNative(const R4SdkUpdateNativeValue256 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,256u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue257_inspectNative(const R4SdkUpdateNativeValue257 *self, R4SdkUpdateStoragefat32_view_View *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,257u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue258_inspectNative(const R4SdkUpdateNativeValue258 *self, R4SdkUpdateStoragefat32_view_View *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,258u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue259_inspectNative(const R4SdkUpdateNativeValue259 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,259u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue260_inspectNative(const R4SdkUpdateNativeValue260 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,260u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue261_inspectNative(const R4SdkUpdateNativeValue261 *self, R4SdkUpdateStoragefat32_update_Backing *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,261u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue262_create(R4SdkUpdateNativeValue262 *output, const R4SdkUpdateStoragefat32_update_Backing * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,262u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue262_inspectNative(const R4SdkUpdateNativeValue262 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,262u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue263_create(R4SdkUpdateNativeValue263 *output, R4SdkUpdateStoragefat32_update_Prepared * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,263u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue263_inspectNative(const R4SdkUpdateNativeValue263 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,263u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue264_inspectNative(const R4SdkUpdateNativeValue264 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,264u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue265_inspectNative(const R4SdkUpdateNativeValue265 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,265u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue266_create(R4SdkUpdateNativeValue266 *output, R4SdkUpdateNtfsFormatBootSector * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,266u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue266_inspectNative(const R4SdkUpdateNativeValue266 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,266u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_ParseError_create(R4SdkUpdateNtfsFormatBootSector_ParseError *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,267u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNtfsFormatBootSector_ParseError_inspectNative(const R4SdkUpdateNtfsFormatBootSector_ParseError *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,267u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue268_create(R4SdkUpdateNativeValue268 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,268u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue268_inspectNative(const R4SdkUpdateNativeValue268 *self, R4SdkUpdateNtfsFormatFileRecordHeader *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,268u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue269_create(R4SdkUpdateNativeValue269 *output, R4SdkUpdateNtfsFormatAttributeIterator * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,269u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue269_inspectNative(const R4SdkUpdateNativeValue269 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,269u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue270_create(R4SdkUpdateNativeValue270 *output, R4SdkUpdateNtfsFormatRunlistIterator * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,270u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue270_inspectNative(const R4SdkUpdateNativeValue270 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,270u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue271_create(R4SdkUpdateNativeValue271 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,271u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue271_inspectNative(const R4SdkUpdateNativeValue271 *self, R4SdkUpdateNtfsFormatRun *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,271u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue272_create(R4SdkUpdateNativeValue272 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,272u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue272_inspectNative(const R4SdkUpdateNativeValue272 *self, R4SdkUpdateNtfsFormatStandardInformation *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,272u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue273_create(R4SdkUpdateNativeValue273 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,273u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue273_inspectNative(const R4SdkUpdateNativeValue273 *self, R4SdkUpdateNtfsFormatFileName *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,273u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue274_create(R4SdkUpdateNativeValue274 *output, R4SdkUpdateNtfsFormatAttributeListIterator * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,274u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue274_inspectNative(const R4SdkUpdateNativeValue274 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,274u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue275_create(R4SdkUpdateNativeValue275 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,275u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue275_inspectNative(const R4SdkUpdateNativeValue275 *self, R4SdkUpdateNtfsFormatAttributeListEntry *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,275u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue276_create(R4SdkUpdateNativeValue276 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,276u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue276_inspectNative(const R4SdkUpdateNativeValue276 *self, R4SdkUpdateNtfsFormatIndexRoot *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,276u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue277_create(R4SdkUpdateNativeValue277 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,277u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue277_inspectNative(const R4SdkUpdateNativeValue277 *self, R4SdkUpdateNtfsFormatIndexHeader *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,277u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue278_create(R4SdkUpdateNativeValue278 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,278u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue278_inspectNative(const R4SdkUpdateNativeValue278 *self, R4SdkUpdateNtfsFormatIndexBlock *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,278u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue279_create(R4SdkUpdateNativeValue279 *output, R4SdkUpdateNtfsFormatIndexEntryIterator * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,279u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue279_inspectNative(const R4SdkUpdateNativeValue279 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,279u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue280_create(R4SdkUpdateNativeValue280 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,280u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue280_inspectNative(const R4SdkUpdateNativeValue280 *self, R4SdkUpdateNtfsFormatIndexEntry *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,280u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue281_create(R4SdkUpdateNativeValue281 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,281u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue281_inspectNative(const R4SdkUpdateNativeValue281 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,281u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNative_math_CompareOperator_create(R4SdkUpdateNative_math_CompareOperator *output, uint32_t p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.bits=(uint64_t)(int64_t)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,282u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNative_math_CompareOperator_inspectNative(const R4SdkUpdateNative_math_CompareOperator *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,282u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue283_create(R4SdkUpdateNativeValue283 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,283u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue283_inspectNative(const R4SdkUpdateNativeValue283 *self, R4SdkUpdateNtfsFormatVolumeInformation *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,283u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue284_create(R4SdkUpdateNativeValue284 *output, R4SdkUpdateNtfsPlan * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,284u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue284_inspectNative(const R4SdkUpdateNativeValue284 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,284u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue285_inspectNative(const R4SdkUpdateNativeValue285 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,285u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue286_inspectNative(const R4SdkUpdateNativeValue286 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,286u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue287_inspectNative(const R4SdkUpdateNativeValue287 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,287u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue288_create(R4SdkUpdateNativeValue288 *output, const R4SdkUpdateNtfsPlan * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,288u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue288_inspectNative(const R4SdkUpdateNativeValue288 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,288u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue289_inspectNative(const R4SdkUpdateNativeValue289 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,289u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue290_inspectNative(const R4SdkUpdateNativeValue290 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,290u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue291_inspectNative(const R4SdkUpdateNativeValue291 *self, R4SdkUpdateNtfsBuilder *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,291u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue292_create(R4SdkUpdateNativeValue292 *output, R4SdkUpdateNtfsBuilder * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,292u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue292_inspectNative(const R4SdkUpdateNativeValue292 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,292u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue293_inspectNative(const R4SdkUpdateNativeValue293 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,293u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue294_inspectNative(const R4SdkUpdateNativeValue294 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,294u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue295_inspectNative(const R4SdkUpdateNativeValue295 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,295u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue296_inspectNative(const R4SdkUpdateNativeValue296 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,296u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue297_inspectNative(const R4SdkUpdateNativeValue297 *self, R4SdkUpdateNtfsPlan *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,297u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue298_create(R4SdkUpdateNativeValue298 *output, R4SdkUpdateStoragentfs_resize_Plan * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,298u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue298_inspectNative(const R4SdkUpdateNativeValue298 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,298u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue299_inspectNative(const R4SdkUpdateNativeValue299 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,299u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue300_create(R4SdkUpdateNativeValue300 *output, const R4SdkUpdateStoragentfs_resize_Plan * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,300u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue300_inspectNative(const R4SdkUpdateNativeValue300 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,300u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue301_inspectNative(const R4SdkUpdateNativeValue301 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,301u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue302_create(R4SdkUpdateNativeValue302 *output, const R4SdkUpdateNativeValue302 * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,302u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue302_inspectNative(const R4SdkUpdateNativeValue302 *self, R4SdkUpdateNativeValue302 *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,302u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue303_inspectNative(const R4SdkUpdateNativeValue303 *self, R4SdkUpdateStorageinstallation_Identifiers *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,303u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue304_inspectNative(const R4SdkUpdateNativeValue304 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,304u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue305_inspectNative(const R4SdkUpdateNativeValue305 *self, R4SdkUpdateStorageinstallation_Layout *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,305u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue306_inspectNative(const R4SdkUpdateNativeValue306 *self, R4SdkUpdateStorageinstallation_Layout *output) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,306u,(void *)self,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue307_inspectNative(const R4SdkUpdateNativeValue307 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,307u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue308_inspectNative(const R4SdkUpdateNativeValue308 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,308u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue309_inspectNative(const R4SdkUpdateNativeValue309 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,309u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue310_create(R4SdkUpdateNativeValue310 *output, R4SdkUpdateInventoryInventory * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,310u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue310_inspectNative(const R4SdkUpdateNativeValue310 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,310u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue311_create(R4SdkUpdateNativeValue311 *output, const R4SdkUpdateRecoveryJournalPayload * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,311u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue311_inspectNative(const R4SdkUpdateNativeValue311 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,311u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue312_create(R4SdkUpdateNativeValue312 *output, const uint8_t * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,312u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue312_inspectNative(const R4SdkUpdateNativeValue312 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,312u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue313_create(R4SdkUpdateNativeValue313 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,313u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue313_inspectNative(const R4SdkUpdateNativeValue313 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,313u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue314_create(R4SdkUpdateNativeValue314 *output, const R4SdkUpdateRecoveryJournalComponent * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,314u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue314_inspectNative(const R4SdkUpdateNativeValue314 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,314u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue315_create(R4SdkUpdateNativeValue315 *output, R4SdkUpdateSlot p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = p0;
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,315u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue315_inspectNative(const R4SdkUpdateNativeValue315 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,315u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue316_create(R4SdkUpdateNativeValue316 *output, const R4SdkUpdateBatchPackageEntry * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,316u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue316_inspectNative(const R4SdkUpdateNativeValue316 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,316u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue317_create(R4SdkUpdateNativeValue317 *output, const R4SdkUpdateCatalogComponent * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,317u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue317_inspectNative(const R4SdkUpdateNativeValue317 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,317u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue318_create(R4SdkUpdateNativeValue318 *output, const R4SdkUpdateCatalogRequirement * p0, uintptr_t n0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.length=n0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,318u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue318_inspectNative(const R4SdkUpdateNativeValue318 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,318u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue319_create(R4SdkUpdateNativeValue319 *output, const R4SdkUpdateCatalogPlan * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,319u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue319_inspectNative(const R4SdkUpdateNativeValue319 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,319u,(void *)self,0); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue320_create(R4SdkUpdateNativeValue320 *output, R4SdkUpdateReplay * p0) { R4SdkUpdateSlot a[1]={0};
 a[0] = (R4SdkUpdateSlot){.ptr=(void *)p0,.flags=R4SDKUPDATE_PRESENT};
 return R4SdkUpdateConstruct(R4SdkUpdate_ABI_FINGERPRINT,320u,a,1u,output); }
static inline R4SdkUpdateSlot R4SdkUpdateNativeValue320_inspectNative(const R4SdkUpdateNativeValue320 *self) { return R4SdkUpdateInspect(R4SdkUpdate_ABI_FINGERPRINT,320u,(void *)self,0); }
#endif
