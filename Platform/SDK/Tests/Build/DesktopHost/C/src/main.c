#include <r4os/r4os.h>
#include <r4os/gui_bridge.h>
#include <r4std.h>
#include <r4img.h>
#include <r4gfx.h>
#include "../../Shared/pixels.h"
/* All checks are ordinary branches; no side effect depends on assert/NDEBUG. */
static int checked(R4SdkGuiSlot s){return s.status==0 && !(s.flags&R4SDK_GUI_NATIVE_ERROR) && (int32_t)s.bits>=0;}
static int report(R4App *app,const char *message,uint32_t len){
 R4Files files=r4_app_files(app);R4FilePath path;
 if(r4_file_path((const uint8_t *)"C:\\TEMP\\DH71C.TXT",17,&path)!=R4_PATH_OK)return -1;
 return r4_files_write(&files,&path,(const uint8_t *)message,len).raw_code;
}
static int exercise(R4App *app,R4SdkGuiSession *host){
 const R4XStartContext *ctx=app->context;
 R4StdSettingsV1Client settings;R4StdTimeV1Client time;R4StdConfigV1Client config;
 R4ImgApiV1Client images;R4ImgPngV1Client png;R4ImgRasterV1Client raster;
 R4GfxDeviceV1Client devices;R4GfxColorV1Client colors;
 if(r4std_settings_v1_init(ctx,&settings) || r4std_time_v1_init(ctx,&time) || r4std_config_v1_init(ctx,&config) ||
 r4img_api_v1_init(ctx,&images) || r4img_png_v1_init(ctx,&png) || r4img_raster_v1_init(ctx,&raster) ||
 r4gfx_device_v1_init(ctx,&devices) || r4gfx_color_v1_init(ctx,&colors))return 10;
 R4Heap heap;if(r4_heap_init(&app->system,&heap))return 11;
 uint8_t *allocation=r4_heap_alloc(&heap,24576,64);if(!allocation || ((uintptr_t)allocation&63))return 12;
 for(uint32_t i=0;i<24576;i++)allocation[i]=(uint8_t)(i*17+3);
 for(uint32_t i=0;i<24576;i++)if(allocation[i]!=(uint8_t)(i*17+3))return 13;
 if(r4_heap_free(&heap,allocation))return 14;
 uint8_t label[64];static const uint8_t utf8[]="SDK71 C A\xcc\x81 \xf0\x9f\x99\x82";
 if(!R4SdkTextValid(utf8,sizeof(utf8)-1) || !R4SdkTextAssign(label,sizeof(label),utf8,sizeof(utf8)-1))return 15;
 R4ImgInfo info={0};uint64_t scratch_bytes=0,count=0;uint32_t pixels[2],scaled[64];
 if(r4img_probe(&images,bitmap,sizeof(bitmap),(const uint8_t *)"image/bmp",9,&info) || info.width!=2 || info.height!=1 ||
 r4img_scratch_bytes(&images,&info,sizeof(bitmap),&scratch_bytes) || scratch_bytes>16*1024*1024)return 16;
 uint8_t *scratch=r4_heap_alloc(&heap,scratch_bytes?scratch_bytes:1,16);if(!scratch)return 17;
 int rc=r4img_decode(&images,bitmap,sizeof(bitmap),(const uint8_t *)"image/bmp",9,pixels,2,scratch,scratch_bytes,&info,&count);
 if(r4_heap_free(&heap,scratch))return 18;
 if(rc || count!=2 || (pixels[0]&0xffffff)!=0xff0000 || (pixels[1]&0xffffff)!=0x00ff00)return 19;
 if(r4img_scale_composite(&images,&info,pixels,2,scaled,64,8,8,0,&count) || count!=64)return 20;
 R4SdkGuiDrawContext *draw=R4SdkGuiSessionDraw(host);
 if(!checked(R4SdkGuiDrawContext_displayBeginFrameRect(0,draw,0,0,240,64)))return 21;
 if(!checked(R4SdkGuiDrawContext_rect(0,draw,0,0,240,64,0x24384c)) ||
 !checked(R4SdkGuiDrawContext_text(0,draw,8,8,label,0xffffff,0x24384c)) ||
 !checked(R4SdkGuiDrawContext_displayBlitXrgb32(0,draw,8,32,8,8,scaled,64)) ||
 !checked(R4SdkGuiDrawContext_displayPresent(0,draw)))return 22;
 R4SdkGuiDesktopContext *desk=R4SdkGuiSessionDesktop(host);R4Mouse mouse={0};
 if(!checked(R4SdkGuiDesktopContext_mouseState(0,desk,&mouse)))return 23;
 if(report(app,"READY C claim/imports/allocator/image/text/raster\r\n",sizeof("READY C claim/imports/allocator/image/text/raster\r\n")-1)<0)return 24;
 for(uint32_t i=0;i<120000;i++){
  R4SdkGuiSlot key=R4SdkGuiDesktopContext_readKeyCodepoint(0,desk);if(key.status)return 25;
  if(key.bits=='q')return 0;r4sys_sleep_ticks(&app->system,1);
 }
 return 26;
}
int32_t r4_app_main(R4App *app){
 R4SdkGuiSession host;int rc=R4SdkGuiSessionOpen(&host,app->context,1,0,0);if(rc)return rc;
 R4Timeout timeout={.kind=R4OS_TIMEOUT_KIND_FINITE,.nanoseconds=2000000000};R4TrayDesktopExchange claim={0};
 rc=R4SdkGuiSessionHostClaim(&host,&claim,&timeout);
 if(!rc && (claim.desktop_owner.instance_id!=app->context->instance_id || !claim.desktop_epoch))rc=2;
 if(!rc)rc=exercise(app,&host);
 /* Close the exact endpoint before publishing success. WINSVC binds the live
  * process generation until root return; close is not a false unregister. */
 R4SdkGuiSessionClose(&host);
 char result[]="C71 result=000 close=done\r\n";result[11]='0'+rc/100;result[12]='0'+(rc/10)%10;result[13]='0'+rc%10;
 report(app,result,sizeof(result)-1);
 return rc;
}
