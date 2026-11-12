#include <r4std_helpers.h>
#include <r4img_helpers.h>
#include <r4font_helpers.h>
#include <r4os/heap.h>
static int ok(R4LibrariesSlot v){return !v.status && !(v.flags&R4LIBRARIES_NATIVE_ERROR);}
struct MemoryState {R4Heap heap;uint32_t live,failed;};
static uint8_t *allocate(void *user,uintptr_t bytes,uintptr_t alignment){
    struct MemoryState *s=user;uint8_t *p=r4_heap_alloc(&s->heap,bytes,alignment);
    if(p)++s->live;return p;
}
static void release(void *user,uint8_t *p,uintptr_t bytes,uintptr_t alignment){
    (void)bytes;(void)alignment;struct MemoryState *s=user;
    if(!s->live || r4_heap_free(&s->heap,p)){s->failed=1;return;}--s->live;
}
int32_t r4libraries59_guest(const R4XStartContext *start,const uint8_t *png,uintptr_t png_length,const uint8_t *font,uintptr_t font_length){
    R4Sys sys;struct MemoryState memory={0};
    if(r4sys_init(start,&sys) || r4_heap_init(&sys,&memory.heap))return 1;
    R4StdTextUtf8Text text;const uint8_t sample[]={'A',0xc3,0xbc};
    if(!ok(R4Std_init(0,start)) || !ok(R4StdTextUtf8Text_init(0,sample,sizeof(sample),&text)) || R4StdTextUtf8Text_scalarCount(0,&text).bits!=2)return 2;
    if(!(R4StdTextUtf8Text_init(0,(const uint8_t *)"\xff",1,&text).flags&R4LIBRARIES_NATIVE_ERROR))return 3;
    if(R4StdCodec_legacyDecode(0,437,1,0xc4).bits!=0x2500)return 4;
    R4ImgHelpersContext images;R4ImgHelpersInfo info;R4ImgHelpersImage decoded;
    if(!ok(R4ImgHelpersContext_init(0,start,&images)) || !ok(R4ImgHelpersContext_probe(0,&images,png,png_length,(const uint8_t *)"image/png",9,&info)))return 5;
    if(R4ImgHelpersInfo_get_width(&info).bits!=10 || R4ImgHelpersInfo_pixelCount(0,&info).bits!=100)return 6;
    R4LibrariesSlot size=R4ImgHelpersContext_scratchBytesFor(0,&images,&info,png_length);
    if(!ok(size))return 7;
    uint8_t *scratch=r4_heap_alloc(&memory.heap,size.bits?size.bits:1,16);if(!scratch)return 8;
    uint32_t pixels[100];int32_t result=0;
    if(!ok(R4ImgHelpersContext_decode(0,&images,png,png_length,(const uint8_t *)"image/png",9,pixels,100,scratch,size.bits,&decoded)) || pixels[0]!=0xff0000ff)result=9;
    else if(!(R4ImgHelpersContext_decode(0,&images,png,png_length,(const uint8_t *)"image/png",9,pixels,99,scratch,size.bits,&decoded).flags&R4LIBRARIES_NATIVE_ERROR))result=10;
    if(r4_heap_free(&memory.heap,scratch))return 11;
    if(result)return result;
    R4LibraryMemory callbacks;R4LibraryAllocator allocator;R4FontHelpersContext fonts;R4FontHelpersDecoder decoder;R4FontHelpersFace face;
    R4LibrariesSlot user={.ptr=&memory,.flags=R4LIBRARIES_PRESENT};
    if(!ok(R4LibraryMemory_from_fields(&callbacks,user,(uintptr_t)allocate,(uintptr_t)release)) || !ok(R4LibraryMemory_allocator(0,&callbacks,&allocator)))return 12;
    if(!ok(R4FontHelpersContext_init(0,start,&fonts)) || !ok(R4FontHelpersContext_createDecoder(0,&fonts,&allocator,8*1024*1024,&decoder)))return 13;
    int opened=0;
    if(!ok(R4FontHelpersDecoder_openFace(0,&decoder,font,font_length,0,&face))){result=14;goto cleanup;}
    opened=1;R4LibrariesSlot glyph=R4FontHelpersFace_glyphIndex(0,&face,'A');
    if(!ok(glyph) || !glyph.bits){result=15;goto cleanup;}
    uint8_t alpha[4096];R4FontHelpersRaster raster;
    if(!ok(R4FontHelpersFace_rasterize(0,&face,(uint32_t)glyph.bits,32,alpha,sizeof(alpha),&raster)) || !R4FontHelpersRaster_get_alpha(&raster).length)result=16;
cleanup:
    if(opened && !ok(R4FontHelpersFace_deinit(0,&face)))return 17;
    if(!ok(R4FontHelpersDecoder_deinit(0,&decoder)))return 18;
    if(memory.live || memory.failed)return 19;
    return result;
}
