#include <r4os/text_composition.h>
/* Actual C-to-Zig calls: static field layouts alone did not detect the
 * original mixed aggregate-by-value argument classification mismatch. */
#define CHECK(X) do { if (!(X)) return __LINE__; } while (0)
static R4ProgramProcessHandle handle(void) { return (R4ProgramProcessHandle){.instance_id=1,.generation=2}; }
int R4TestTextCompositionABI(void) {
 R4SdkComposition state;R4CompositionId id,saved;__builtin_memset(&id,0xa5,sizeof(id));saved=id;
 R4ProgramProcessHandle own=handle();R4CompositionFocus focus={.version=1,.size=sizeof(focus),.window={.service=own,.desktop=own,.owner=own,.serial=3},.view_generation=4,.focus_generation=5,.input_revision=6,.observed_tick=7,.focused=1};
 R4CompositionProvider absent={.version=1,.size=sizeof(absent),.max_text_bytes=1024},provider=absent;provider.features=1;provider.process=own;provider.generation=8;
 R4CompositionCaret caret={.x=3,.height=12,.scale_numerator=3,.scale_denominator=2},observed={0};
 uint8_t doc[64],original[64];__builtin_memset(doc,0xa5,sizeof(doc));__builtin_memcpy(doc,"abcd",4);__builtin_memcpy(original,doc,sizeof(doc));uint64_t length=4,revision=7;
 R4SdkWireSpan current={(uintptr_t)doc,length},storage={(uintptr_t)doc,sizeof(doc)};R4Utf8ByteRange range={1,3};
 CHECK(R4SdkCompositionInit(91,&state)==0&&state.data[0]==0&&state.data[1023]==0);
 CHECK(R4SdkCompositionBegin(&state,&focus,&absent,revision,&current,&range,&caret,&id)==R4OS_COMPOSITION_ERROR_NO_PROVIDER&&!__builtin_memcmp(&id,&saved,sizeof(id)));
 CHECK(R4SdkCompositionBegin(&state,&focus,&provider,revision,&current,&range,&caret,&id)==0);
 const uint8_t preedit[3]={'e',0xcc,0x81};R4SdkWireSpan text={(uintptr_t)preedit,3},view={0};
 R4CompositionEvent e={.version=1,.size=sizeof(e),.id=id,.sequence=1,.text_revision=revision,.replacement=range,.selection={0,3},.kind=1,.text_bytes=3};
 CHECK(R4SdkCompositionApply(&state,&focus,&provider,&e,&text,&storage,&length,&revision)==0&&length==4&&revision==7&&!__builtin_memcmp(doc,original,sizeof(doc)));
 CHECK(R4SdkCompositionPreedit(&state,&view)==0&&view.length==3&&!__builtin_memcmp((const void*)view.address,preedit,3));
 CHECK(R4SdkCompositionCaret(&state,&focus,&provider,revision,&observed)==0&&observed.x==3&&observed.height==12&&observed.scale_denominator==2);
 caret.x=8;CHECK(R4SdkCompositionSetCaret(&state,&focus,&provider,revision,&caret)==0);
 uint8_t around[8]={0};uint64_t count=99;R4SdkWireSpan destination={(uintptr_t)around,1};
 CHECK(R4SdkCompositionSurrounding(&state,&focus,&provider,revision,&current,&range,&destination,&count)==R4OS_COMPOSITION_ERROR_CAPACITY&&count==99&&around[0]==0);
 destination.length=8;CHECK(R4SdkCompositionSurrounding(&state,&focus,&provider,revision,&current,&range,&destination,&count)==0&&count==2&&around[0]=='b'&&around[1]=='c');
 e.sequence=2;e.selection.end=1;CHECK(R4SdkCompositionApply(&state,&focus,&provider,&e,&text,&storage,&length,&revision)==R4OS_COMPOSITION_ERROR_RANGE&&!__builtin_memcmp(doc,original,sizeof(doc)));
 text=(R4SdkWireSpan){(uintptr_t)"Z",1};e.selection.end=1;e.text_bytes=1;e.kind=2;CHECK(R4SdkCompositionApply(&state,&focus,&provider,&e,&text,&storage,&length,&revision)==0&&length==3&&revision==8&&!__builtin_memcmp(doc,"aZd",3));
 R4CompositionId old=id;current.length=length;CHECK(R4SdkCompositionBegin(&state,&focus,&provider,revision,&current,&range,&caret,&id)==0&&id.session_generation>old.session_generation);
 CHECK(R4SdkCompositionCancel(&state,&old)==R4OS_COMPOSITION_ERROR_STALE_SESSION);
 focus.focused=0;CHECK(R4SdkCompositionRefresh(&state,&focus,&provider,revision)==R4OS_COMPOSITION_ERROR_NO_FOCUS&&length==3&&revision==8);
 return 0;
}
