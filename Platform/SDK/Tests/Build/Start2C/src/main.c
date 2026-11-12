#include <r4os/platform2.h>
static uint32_t matches(const uint8_t *args,uint64_t length,const char *text,uint64_t expected) {
    if (length != expected) return 0;
    for (uint64_t i=0;i<length;++i) if (args[i] != (uint8_t)text[i]) return 0;
    return 1;
}
int32_t r4_main2(const R4OS2Context *view) {
    const R4XStartContext2 *raw = view->raw;
    const uint8_t *args = (const uint8_t *)(uintptr_t)raw->args;
    const uint64_t length = raw->args_len;
    const uint32_t held = matches(args,length,"hold",4);
    const R4XStartImport *imports = (const R4XStartImport *)(uintptr_t)raw->imports;
    if (!raw->instance_id || (!held && R4OS2ContextShouldClose(view)) || imports[1].group_id || imports[1].resolved_version != 2 || !imports[1].table) return -20;
    const R4LQuery2 *query = (const R4LQuery2 *)(uintptr_t)imports[1].table;
    if (query->magic != UINT32_C(0x324c3452) || query->size != 24 || query->group || query->reserved) return -21;
    if (!R4OS2ContextYield(view) || (!held && R4OS2ContextShouldClose(view)) || query->magic != UINT32_C(0x324c3452)) return -22;
    uint64_t address = 0;
    if (R4OS2ContextFunction(view,1,offsetof(R4XStartR4Sys2,write),&address)) return -23;
    static const uint8_t message[] = "PASS START2C context=120 query=24 borrowed_args/imports callbacks=2\r\n";
    ((R4SysWriteFn)(uintptr_t)address)(message,sizeof(message)-1);
    if (matches(args,length,"fault",5)) __builtin_trap();
    if (matches(args,length,"hold",4)) while (!R4OS2ContextShouldClose(view)) R4OS2ContextYield(view);
    return matches(args,length,"return",6) ? 37 : 0;
}
