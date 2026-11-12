/* Public C window API. Capture success accepts PENDING: only an ACTIVE
 * notification starts mouse-look. Keep the exact identity/token; MouseCapture
 * in gui.zig is merely local widget bookkeeping.
 *
 * Left Down starts an outside-client drag; Up releases it.
 * 2 requests physical relative mouse-look, Esc releases, Q exits.
 * I/J exercise stale window/owner rejection, V an old release during a new
 * lease, B pauses consumption for the queue-overflow qualification.
 * No absolute remote coordinates are converted to relative motion.
 */
#include <r4os/app_gui.h>

static void text(R4App *app,const char *value) { (void)r4sys_write_cstr(&app->system,value); }
static void number(R4App *app,int64_t value) {
    char bytes[24];uint32_t n=0;uint64_t u=value<0?(uint64_t)(-(value+1))+1:(uint64_t)value;
    if(value<0)text(app,"-");do { bytes[n++]=(char)('0'+u%10);u/=10; }while(u);
    while(n)(void)r4sys_write(&app->system,(const uint8_t *)&bytes[--n],1);
}
static void field(R4App *app,const char *name,int64_t value) { text(app,name);number(app,value); }
static void line(R4App *app,const char *name,int64_t value) { text(app,"M28 ");field(app,name,value);text(app,"\n"); }
static uint32_t checks,failures;
static void check(R4App *app,int ok,const char *name) {
    ++checks;if(!ok){++failures;text(app,"M28 FAIL ");text(app,name);text(app,"\n");}
}
static int untouched(const void *value,uint32_t length) {
    const uint8_t *p=value;for(uint32_t i=0;i<length;++i)if(p[i]!=0xa5)return 0;return 1;
}
static int32_t request(R4Window *window,uint32_t mode,R4GuiPointerCaptureHandle *capture) {
    R4GuiPointerWindowIdentity identity={0};R4GuiPointerCaptureHandle next={0};
    int32_t rc=r4_window_pointer_identity(window,&identity);
    if(!rc)rc=r4_window_pointer_capture(window,&identity,mode,&next);
    text(window->app,"M28 request");field(window->app," mode=",mode);field(window->app," rc=",rc);
    field(window->app," epoch=",identity.epoch);field(window->app," generation=",identity.owner.generation);
    field(window->app," id=",next.id);text(window->app,"\n");
    if(!rc)*capture=next;return rc;
}
static void stale(R4Window *window,int owner) {
    R4GuiPointerWindowIdentity identity={0};R4GuiPointerCaptureHandle out;
    int32_t rc=r4_window_pointer_identity(window,&identity);
    if(rc){line(window->app,"identity-unavailable=",rc);return;}
    if(owner)identity.owner.generation^=UINT64_C(0x100000000);
    else identity.epoch^=UINT64_C(0x100000000);
    for(uint32_t i=0;i<sizeof out;++i)((uint8_t *)&out)[i]=0xa5;
    rc=r4_window_pointer_capture(window,&identity,R4OS_GUI_POINTER_MODE_DRAG,&out);
    check(window->app,rc==R4OS_GUI_POINTER_ERROR_STALE&&untouched(&out,sizeof out),"stale request preserves output");
    line(window->app,owner?"stale-owner=":"stale-window=",rc);
}
int32_t r4_app_main(R4App *app) {
    R4Window window;
    if(!r4_window_open(app,0,0,&window))return 1;
    if(r4_window_set_title(&window,"C native MouseLook")<0)return 1;
    R4GuiPointerCaptureHandle capture={0},last={0};
    uint32_t state=R4OS_GUI_POINTER_STATE_NONE,mode=0,held=0,motions=0,wheels=0;
    int64_t yaw=0,pitch=0;int dirty=1;
    line(app,"opened-window=",window.id);
    R4GuiWindowInfo info={0};
    if(r4desk_gui_window_info(&app->desktop,&info)>=0) {
        text(app,"M28 client");field(app," x=",info.client_x);field(app," y=",info.client_y);
        field(app," w=",info.client_w);field(app," h=",info.client_h);text(app,"\n");
    }

    for(;;) {
        if(dirty) {
            R4PaintContext paint;
            if(!r4_window_begin_paint(&window,&paint))return 1;
            R4Canvas canvas=r4_paint_canvas(&paint);
            const char *status=state==R4OS_GUI_POINTER_STATE_ACTIVE
                ?(mode==R4OS_GUI_POINTER_MODE_RELATIVE?"ACTIVE: raw physical mouse-look":"ACTIVE: outside-client drag")
                :state==R4OS_GUI_POINTER_STATE_PENDING?"PENDING: waiting for desktop grant":"Normal desktop cursor";
            if(r4_canvas_clear(canvas,0x182030)<0||
                r4_canvas_text(canvas,12,14,status,0xffffff,0x182030)<0||
                r4_canvas_text(canvas,12,38,"Left drag | 2: FPS | Esc: release | Q: exit",0xe0e0e0,0x182030)<0||
                r4_canvas_text(canvas,12,62,"I/J: stale token | V: old release | B: pause",0xa0d0e0,0x182030)<0||
                r4_canvas_text(canvas,152+(int32_t)(yaw%80),112+(int32_t)(pitch%60),"+",0xffe050,0x182030)<0||
                r4_paint_present(&paint)<0) {
                r4_paint_discard(&paint);return 1;
            }
            dirty=0;
        }
        R4MessageNext next=r4_window_wait_message(&window,r4_timeout_forever());
        if(next.state==R4_MESSAGE_NEXT_FAILED){line(app,"wait-failed=",next.raw_code);return 1;}
        if(next.state!=R4_MESSAGE_NEXT_MESSAGE)continue;
        R4Message message=next.message;
        switch(message.kind) {
        case R4_MESSAGE_CLOSE: goto done;
        case R4_MESSAGE_RESIZE: dirty=1;break;
        case R4_MESSAGE_FOCUS_GAINED:line(app,"focus=",1);break;
        case R4_MESSAGE_FOCUS_LOST:line(app,"focus=",0);held=0;break;
        case R4_MESSAGE_POINTER_CAPTURE: {
            R4PointerCaptureMessage value=message.value.capture;
            text(app,"M28 capture");field(app," state=",value.state);field(app," reason=",value.reason);
            field(app," mode=",value.mode);field(app," id=",value.capture_id);text(app,"\n");
            check(app,!capture.id||value.capture_id==capture.id,"capture notification exact serial");
            state=value.state;mode=value.mode;dirty=1;
            if(state==R4OS_GUI_POINTER_STATE_RELEASED||state==R4OS_GUI_POINTER_STATE_CANCELLED) {
                last=capture;held=0;
                text(app,"M28 totals");field(app," dx=",yaw);field(app," dy=",pitch);
                field(app," packets=",motions);field(app," wheels=",wheels);text(app,"\n");
            }
            break;
        }
        case R4_MESSAGE_MOUSE: {
            R4MouseMessage value=message.value.mouse;
            text(app,"M28 mouse");field(app," action=",value.action);field(app," x=",value.x);
            field(app," y=",value.y);field(app," buttons=",value.buttons);text(app,"\n");
            held=value.buttons;
            if(value.action==R4_MOUSE_DOWN&&(value.buttons&1)&&state!=R4OS_GUI_POINTER_STATE_ACTIVE&&state!=R4OS_GUI_POINTER_STATE_PENDING) {
                int32_t rc=request(&window,R4OS_GUI_POINTER_MODE_DRAG,&capture);
                if(!rc){state=R4OS_GUI_POINTER_STATE_PENDING;dirty=1;}
            } else if(value.action==R4_MOUSE_UP&&mode==R4OS_GUI_POINTER_MODE_DRAG&&!held&&capture.id) {
                line(app,"drag-release=",r4_window_pointer_release(&window,&capture));
            }
            break;
        }
        case R4_MESSAGE_MOUSE_RELATIVE: {
            R4RelativeMouseMessage value=message.value.relative;
            check(app,value.source==R4OS_GUI_POINTER_SOURCE_PHYSICAL_RELATIVE,"physical relative source");
            check(app,state==R4OS_GUI_POINTER_STATE_ACTIVE&&mode==R4OS_GUI_POINTER_MODE_RELATIVE,"relative after grant");
            yaw+=value.dx;pitch+=value.dy;++motions;dirty=1;
            if(motions<=24) {
                text(app,"M28 raw");field(app," dx=",value.dx);field(app," dy=",value.dy);
                field(app," source=",value.source);field(app," buttons=",value.buttons);text(app,"\n");
            }
            break;
        }
        case R4_MESSAGE_MOUSE_WHEEL:
            ++wheels;line(app,"wheel=",message.value.wheel.delta);break;
        case R4_MESSAGE_KEY: {
            uint32_t key=message.value.key.codepoint;
            if(key=='q'||key=='Q')goto done;
            if(key==27&&capture.id) {
                int32_t rc=r4_window_pointer_release(&window,&capture);
                check(app,rc==0,"explicit release");
                check(app,r4_window_pointer_release(&window,&capture)==0,"repeat exact release");
                line(app,"explicit-release=",rc);
            } else if(key=='2') {
                int32_t rc=request(&window,R4OS_GUI_POINTER_MODE_RELATIVE,&capture);
                if(!rc){state=R4OS_GUI_POINTER_STATE_PENDING;dirty=1;}
            } else if(key=='i'||key=='I')stale(&window,0);
            else if(key=='j'||key=='J')stale(&window,1);
            else if((key=='v'||key=='V')&&last.id&&capture.id!=last.id) {
                R4GuiPointerCaptureInfo before={0},after={0};
                int32_t first=r4_window_pointer_status(&window,&capture,&before);
                int32_t rc=r4_window_pointer_release(&window,&last);
                int32_t second=r4_window_pointer_status(&window,&capture,&after);
                check(app,!first&&!second&&before.capture.id==after.capture.id&&before.state==after.state,"old release leaves new capture intact");
                line(app,"old-release=",rc);
            } else if(key=='b'||key=='B') {
                line(app,"pause-ticks=",3000);r4sys_sleep_ticks(&app->system,3000);line(app,"resumed=",1);
            }
            break;
        }
        default:break;
        }
    }
done:
    if(capture.id)(void)r4_window_pointer_release(&window,&capture);
    text(app,"M28 finished");field(app," checks=",checks);field(app," failures=",failures);
    field(app," dx=",yaw);field(app," dy=",pitch);field(app," held=",held);text(app,"\n");
    return failures?1:0;
}
