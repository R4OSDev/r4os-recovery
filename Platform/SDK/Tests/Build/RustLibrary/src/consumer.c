#include "r4std_abi.h"
int32_t r4_library_c_consumer(const R4XStartContext2 *context) {
    R4StdTextV1Client text;
    if (r4std_text_v1_init2(context,&text) != R4L_BINDING_OK) return 1;
    R4StdDateV1Client absent;
    if (r4std_date_v1_init2_optional(context,&absent) != R4L_BINDING_ABSENT || absent.header != 0) return 2;
    R4OS2Context view;
    if (R4OS2ContextInit(context, &view) != R4OS2_CONTEXT_OK) return 3;
    const R4LQuery2 *query = 0;
    if (r4l_query2(&view,"R4STD",&query) != R4L_BINDING_OK || query->group != 0 || query->reserved != 0) return 3;
    const uint8_t input[] = {0x41,0xc3,0xa4,0xe2,0x82,0xac};
    R4StdTextInfo info = {0};
    if (r4std_text_inspect(&text,input,sizeof(input),R4STD_TEXT_KIND_UTF8,&info) != 0) return 4;
    return info.scalar_count == 3 && info.content_length == sizeof(input) ? 0 : 5;
}
