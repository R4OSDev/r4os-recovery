/* Same engine and bounded examples as the existing web owner cases. This
 * file is freestanding and is also linked into the real Rust/C R4X probe. */
#include <r4os/web_helpers.h>
#define TRY(x) do { R4SdkWebSlot v_=(x); if(v_.status || (v_.flags&R4SDKWEB_NATIVE_ERROR)) return __LINE__; } while(0)
#define CHECK(x) do { if(!(x)) return __LINE__; } while(0)
#define BYTES(s) (const uint8_t *)(s), sizeof(s)-1
static int equal(R4SdkWebSlot v,const char *s,uintptr_t n){
    if(v.status || (v.flags&3)!=1 || v.length!=n || (!v.ptr&&n))return 0;
    for(uintptr_t i=0;i<n;i++)if(((const uint8_t *)v.ptr)[i]!=(uint8_t)s[i])return 0;
    return 1;
}
typedef struct WebState { uint32_t calls,gets,sets,roots,weak,sweeps,clock,cancel; double value; } WebState;
static R4SdkWebSlot callback(void *user,uint32_t kind,const R4SdkWebSlot *a,uint32_t n,void *out){
    WebState *s=(WebState *)user;
    if(kind==R4SdkWebCallbackKind_js_host_function){
        s->calls++;
        if(n!=5 || a[1].ptr!=user)return (R4SdkWebSlot){.status=-1};
        if(a[2].bits==9)return (R4SdkWebSlot){.ptr=(void *)"TypeError",.length=9,.flags=R4SDKWEB_NATIVE_ERROR};
        double x=42.5;
        R4SdkWebSlot v=R4SdkWebJsValue_set_number((R4SdkWebJsValue *)out,&x);
        return v.status?v:(R4SdkWebSlot){.ptr=out,.flags=R4SDKWEB_PRESENT};
    }
    if(kind==R4SdkWebCallbackKind_js_host_get){
        s->gets++;
        if(n!=5 || a[1].ptr!=user)return (R4SdkWebSlot){.status=-1};
        if(!equal(a[4],"score",5))return (R4SdkWebSlot){0};
        R4SdkWebSlot v=R4SdkWebJsValue_set_number((R4SdkWebJsValue *)out,&s->value);
        return v.status?v:(R4SdkWebSlot){.ptr=out,.flags=1};
    }
    if(kind==R4SdkWebCallbackKind_js_host_set){
        s->sets++;double value=0;
        if(n!=6 || !equal(a[4],"score",5))return (R4SdkWebSlot){.bits=0,.flags=1};
        R4SdkWebSlot v=R4SdkWebJsRuntime_valueNumber(0,(R4SdkWebJsRuntime *)a[0].ptr,(const R4SdkWebJsValue *)a[5].ptr,&value);
        if(v.status||(v.flags&2))return v;
        s->value=value;return (R4SdkWebSlot){.bits=1,.flags=1};
    }
    if(kind==R4SdkWebCallbackKind_js_clock){
        s->clock++;*(double *)out=123456.25;return (R4SdkWebSlot){.ptr=out,.flags=1};
    }
    if(kind==R4SdkWebCallbackKind_js_offset){
        if(n!=2 || *(const double *)a[1].ptr!=123456.0)return (R4SdkWebSlot){.status=-1};
        return (R4SdkWebSlot){.bits=(uint64_t)(int64_t)-60,.flags=1};
    }
    if(kind==R4SdkWebCallbackKind_js_cancel)return (R4SdkWebSlot){.bits=s->cancel,.flags=1};
    if(kind==R4SdkWebCallbackKind_root_mark)s->roots++;
    if(kind==R4SdkWebCallbackKind_root_mark_weak)s->weak++;
    if(kind==R4SdkWebCallbackKind_root_sweep)s->sweeps++;
    if(kind==R4SdkWebCallbackKind_font_resolve){
        if(n!=6 || a[0].ptr!=user)return (R4SdkWebSlot){.status=-1};
        R4SdkWebSlot v=R4SdkWebLayoutFontFace_from_fields((R4SdkWebLayoutFontFace *)out,77,12,14,10,7);
        return v.status?v:(R4SdkWebSlot){.ptr=out,.flags=1};
    }
    return (R4SdkWebSlot){0};
}
int sdk_web_c_case(R4SdkWebHtmlDocument *document,R4SdkWebCssStylesheet *sheet,R4SdkWebLayoutLayout *layout,
                  R4SdkWebJsProgram *program,R4SdkWebJsRuntime *runtime,R4SdkWebCanvasManager *canvas,
                  R4SdkWebMemory *memory,const uint8_t *fixture,uintptr_t fixture_len,uint64_t *layout_hash){
    R4SdkWebHtmlParseOptions options;R4SdkWebHtmlParseStats parsed;
    TRY(R4SdkWebHtmlParseOptions_from_fields(&options,BYTES("text/html"),1));
    TRY(R4SdkWebHtmlDocument_parse(0,document,fixture,fixture_len,&options,&parsed));
    CHECK(R4SdkWebHtmlDocument_get_node_count(document).bits<=32);
    TRY(R4SdkWebCssStylesheet_reset(0,sheet));
    TRY(R4SdkWebCssStylesheet_appendDocumentStyles(0,sheet,document));
    R4SdkWebLayoutViewport viewport;R4SdkWebLayoutLayoutStats stats;
    TRY(R4SdkWebLayoutLayout_create(layout));
    TRY(R4SdkWebLayoutViewport_create(&viewport,480,240));
    TRY(R4SdkWebLayoutLayout_reflow(0,layout,document,sheet,&viewport,&stats));
    uint64_t ops=R4SdkWebLayoutLayoutStats_get_render_ops(&stats).bits;CHECK(ops>=2&&ops<=64);
    *layout_hash=R4SdkWebLayoutLayout_structuralHash(0,layout).bits;
    /* Required callback rejection is a real owner adapter error. */
    R4SdkWebCallbackTable empty;R4SdkWebJsProgramAllocator pa;
    TRY(R4SdkWebCallbackTable_create(&empty));
    R4SdkWebSlot missing=R4SdkWeb_programAllocator(0,&empty,&pa);CHECK((missing.flags&2)&&missing.length==15);
    TRY(R4SdkWeb_memoryPrograms(0,memory,&pa));
    TRY(R4SdkWebJsProgram_create(program));
    TRY(R4SdkWebJsRuntime_initialize(0,runtime,&pa));
    TRY(R4SdkWebJsRuntime_init(0,runtime));
    WebState state={0};state.value=5.25;
    R4SdkWebCallbackTable table;
    uint64_t mask=(UINT64_C(1)<<R4SdkWebCallbackKind_js_host_function)|(UINT64_C(1)<<R4SdkWebCallbackKind_js_host_get)|(UINT64_C(1)<<R4SdkWebCallbackKind_js_host_set)|
      (UINT64_C(1)<<R4SdkWebCallbackKind_js_clock)|(UINT64_C(1)<<R4SdkWebCallbackKind_js_offset)|(UINT64_C(1)<<R4SdkWebCallbackKind_js_cancel)|
      (UINT64_C(1)<<R4SdkWebCallbackKind_root_mark)|(UINT64_C(1)<<R4SdkWebCallbackKind_root_mark_weak)|(UINT64_C(1)<<R4SdkWebCallbackKind_root_sweep)|(UINT64_C(1)<<R4SdkWebCallbackKind_font_resolve);
    TRY(R4SdkWebCallbackTable_from_fields(&table,(R4SdkWebSlot){.ptr=&state,.flags=1},mask,(R4SdkWebSlot){.ptr=(void *)(uintptr_t)&callback,.flags=1}));
    R4SdkWebJsClockSource clock;R4SdkWebJsStop stop;R4SdkWebJsExternalRootMarker roots;
    TRY(R4SdkWeb_clock(0,&table,&clock));TRY(R4SdkWebJsRuntime_setClockSource(0,runtime,&clock));
    TRY(R4SdkWeb_stop(0,&table,1,&stop));TRY(R4SdkWebJsRuntime_setStop(0,runtime,&stop));
    TRY(R4SdkWeb_rootMarker(0,&table,&roots));TRY(R4SdkWebJsRuntime_setExternalRootMarker(0,runtime,&roots));
    R4SdkWebSlot context=R4SdkWeb_callbackContext(0,&table),host=R4SdkWeb_hostFunction(0),get=R4SdkWeb_hostGet(0),set=R4SdkWeb_hostSet(0);
    R4SdkWebJsValue fn,fail,obj,value;double number=0;
    TRY(R4SdkWebJsRuntime_createHostFunction(0,runtime,7,context,(uintptr_t)host.ptr,&fn));
    TRY(R4SdkWebJsRuntime_defineGlobal(0,runtime,BYTES("nativeAnswer"),&fn,1));
    TRY(R4SdkWebJsRuntime_createHostFunction(0,runtime,9,context,(uintptr_t)host.ptr,&fail));
    TRY(R4SdkWebJsRuntime_defineGlobal(0,runtime,BYTES("nativeFail"),&fail,1));
    TRY(R4SdkWebJsRuntime_createObject(0,runtime,&obj));
    TRY(R4SdkWebJsRuntime_defineGlobal(0,runtime,BYTES("nativeObject"),&obj,1));
    TRY(R4SdkWebJsRuntime_setHostPropertyHooks(0,runtime,&obj,2,context,get,set));
    TRY(R4SdkWebJsRuntime_evaluateSource(0,runtime,program,BYTES("nativeObject.score=7.5;nativeAnswer()+nativeObject.score;"),&value));
    TRY(R4SdkWebJsRuntime_valueNumber(0,runtime,&value,&number));CHECK(number==50.0&&state.value==7.5&&state.calls==1&&state.gets>0&&state.sets==1);
    TRY(R4SdkWebJsRuntime_evaluateSource(0,runtime,program,BYTES("let caught=false;try{nativeFail();}catch(e){caught=e instanceof TypeError;}caught;"),&value));
    CHECK(R4SdkWebJsRuntime_valueBoolean(0,runtime,&value).bits==1);
    TRY(R4SdkWebJsRuntime_evaluateSource(0,runtime,program,BYTES("typeof nativeObject.absent==='undefined';"),&value));
    CHECK(R4SdkWebJsRuntime_valueBoolean(0,runtime,&value).bits==1);
    TRY(R4SdkWebJsRuntime_evaluateSource(0,runtime,program,BYTES("Date.now();"),&value));
    TRY(R4SdkWebJsRuntime_valueNumber(0,runtime,&value,&number));CHECK(number==123456.0&&state.clock>0);
    TRY(R4SdkWebJsRuntime_evaluateSource(0,runtime,program,BYTES("new Date().getTimezoneOffset();"),&value));
    TRY(R4SdkWebJsRuntime_valueNumber(0,runtime,&value,&number));CHECK(number==60);
    TRY(R4SdkWebJsRuntime_collectGarbage(0,runtime));CHECK(state.roots&&state.weak&&state.sweeps);
    state.cancel=1;
    R4SdkWebSlot cancelled=R4SdkWebJsRuntime_evaluateSource(0,runtime,program,BYTES("while(true){}"),&value);
    CHECK(!cancelled.status&&(cancelled.flags&2));
    cancelled.flags=1;CHECK(equal(cancelled,"Cancelled",9));state.cancel=0;
    TRY(R4SdkWebJsRuntime_deinit(0,runtime));
    /* The exact native six-argument hook, with optional scalar, is usable by
     * the original bounded glyph run cache as well as layout providers. */
    R4SdkWebRunResolver run;R4SdkWebLayoutFontFace face;
    TRY(R4SdkWeb_runResolver(0,&table,BYTES("sans-serif"),12,400,0,&run));
    TRY(R4SdkWebRunResolver_resolve(0,&run,'A',&face));TRY(R4SdkWebRunResolver_resolve(0,&run,'A',&face));
    CHECK(R4SdkWebLayoutFontFace_get_id(&face).bits==77&&R4SdkWebRunResolver_get_calls(&run).bits==1&&R4SdkWebRunResolver_get_hits(&run).bits==1);
    R4SdkWebCanvasAllocator ca;TRY(R4SdkWeb_memoryCanvas(0,memory,&ca));
    TRY(R4SdkWebCanvasManager_initialize(0,canvas,&ca));
    R4SdkWebSlot surface=R4SdkWebCanvasManager_ensure(0,canvas,3,4,3);CHECK(surface.ptr&&(surface.flags&1));
    double x=1,y=0,w=2,h=2;
    TRY(R4SdkWebCanvasManager_fillRectColor(0,canvas,(R4SdkWebCanvasSurface *)surface.ptr,&x,&y,&w,&h,0xff112233));
    R4SdkWebCanvasSurfaceView view;TRY(R4SdkWebCanvasManager_view(0,canvas,3,&view));
    R4SdkWebSlot pixels=R4SdkWebCanvasSurfaceView_get_pixels(&view);CHECK(pixels.length==12);
    const uint32_t *p=(const uint32_t *)pixels.ptr;CHECK(p[0]==0xffffffff&&p[1]==0xff112233&&p[2]==0xff112233&&p[4]==0xffffffff&&p[5]==0xff112233&&p[10]==0xffffffff);
    R4SdkWebSlot bad=R4SdkWebCanvasManager_ensure(0,canvas,8,513,1);CHECK(bad.flags&2);
    TRY(R4SdkWebCanvasManager_deinit(0,canvas));
    return 0;
}
