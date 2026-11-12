/* Public C consumer: focus the MouseLook window and capture there during the
 * first second. This unfocused window then requests its own exact identity;
 * BUSY must leave the token untouched. No mouse packet may reach this window. */
#include <r4os/app_gui.h>
static void text(R4App *a,const char *v){(void)r4sys_write_cstr(&a->system,v);}
static void number(R4App *a,int32_t v){char b[16];uint32_t n=0,u=v<0?(uint32_t)(-(v+1))+1:(uint32_t)v;if(v<0)text(a,"-");do{b[n++]=(char)('0'+u%10);u/=10;}while(u);while(n)(void)r4sys_write(&a->system,(const uint8_t *)&b[--n],1);}
int32_t r4_app_main(R4App *app){
 R4Window window;if(!r4_window_open(app,0,0,&window))return 1;
 (void)r4_window_set_title(&window,"Native capture contender");
 R4PaintContext paint;if(!r4_window_begin_paint(&window,&paint))return 1;R4Canvas canvas=r4_paint_canvas(&paint);
 if(r4_canvas_clear(canvas,0x302018)<0||r4_canvas_text(canvas,8,16,"Capture in the other window now",0xffffff,0x302018)<0||r4_paint_present(&paint)<0){r4_paint_discard(&paint);return 1;}
 r4sys_sleep_ticks(&app->system,1000);
 R4GuiPointerWindowIdentity identity={0};R4GuiPointerCaptureHandle token;
 for(uint32_t i=0;i<sizeof token;++i)((uint8_t *)&token)[i]=0xa5;
 int32_t rc=r4_window_pointer_identity(&window,&identity);
 if(!rc)rc=r4_window_pointer_capture(&window,&identity,R4OS_GUI_POINTER_MODE_DRAG,&token);
 int untouched=1;for(uint32_t i=0;i<sizeof token;++i)if(((uint8_t *)&token)[i]!=0xa5)untouched=0;
 text(app,"M28RIVAL request=");number(app,rc);text(app," untouched=");number(app,untouched);text(app,"\n");
 if(!rc)(void)r4_window_pointer_release(&window,&token);
 r4sys_sleep_ticks(&app->system,1000);
 uint32_t mouse=0;for(;;){R4MessageNext next=r4_window_wait_message(&window,r4_timeout_poll());if(next.state!=R4_MESSAGE_NEXT_MESSAGE)break;
  if(next.message.kind==R4_MESSAGE_MOUSE||next.message.kind==R4_MESSAGE_MOUSE_RELATIVE||next.message.kind==R4_MESSAGE_MOUSE_WHEEL)++mouse;}
 text(app,"M28RIVAL mouse=");number(app,(int32_t)mouse);text(app,"\n");
 return rc==R4OS_GUI_POINTER_ERROR_BUSY&&untouched&&!mouse?0:1;
}
