#include <r4os/app2.h>
#include <r4os/data_helpers.h>
static uint32_t matches(const uint8_t *args,uint64_t length,const char *text,uint64_t expected) {
    if (length != expected) return 0;
    for (uint64_t i=0;i<length;++i) if (args[i] != (uint8_t)text[i]) return 0;
    return 1;
}
int32_t r4_app_main(R4App2 *app) {
    const R4OS2Context *view = &app->context;
    uint64_t arg_length = 0;
    const uint8_t *arg_bytes = r4_app2_args(app, &arg_length);
    if (matches(arg_bytes, arg_length, "initfail", 8)) return -73;
    uint8_t *memory = r4_app2_alloc(app, 4096, 64);
    if (!memory) return -60;
    for (size_t i=0; i<4096; ++i) memory[i]=0xa5;
    uint8_t entropy[32]; for (size_t i=0; i<sizeof(entropy); ++i) entropy[i]=0xa5;
    R4SdkDataSlot filled = R4SdkDataRandom_fill(0, entropy, sizeof(entropy));
    if (filled.status != 0) return -61;
    if (!filled.bits) for (size_t i=0; i<sizeof(entropy); ++i) if (entropy[i]) return -62;
    uint64_t source_address = 0;
    if (R4OS2ContextFunction(view, 1, offsetof(R4XStartR4Sys2, entropy_source_info), &source_address) != 0) return -65;
    R4EntropySourceInfo source = {.version=1, .size=sizeof(source)};
    if (((R4SysEntropySourceInfoFn)(uintptr_t)source_address)(&source) == 0 && source.state == R4OS_ENTROPY_STATE_READY) {
        R4EntropySourceInfo bound = {.version=1, .size=sizeof(bound)};
        R4SdkDataSlot info = R4SdkDataRandom_sourceInfo(0, &bound);
        if (!filled.bits || info.status != 0 || (int32_t)info.bits != 0 || bound.generation != source.generation) return -66;
    }
    if (r4_app2_free(app, memory) != 0) return -63;
    const R4XStartImport *all = (const R4XStartImport *)(uintptr_t)view->raw->imports;
    if (view->raw->import_count < 4 || all[2].group_id || all[2].resolved_version != 1 || !all[2].table ||
        all[3].resolved_version || all[3].table || all[3].flags) return -64;
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
    static const uint8_t message[] = "PASS APP2C context=120 query=24 borrowed_args/imports callbacks=2\r\n";
    ((R4SysWriteFn)(uintptr_t)address)(message,sizeof(message)-1);
    if (matches(args,length,"fault",5)) __builtin_trap();
    if (matches(args,length,"hold",4)) while (!R4OS2ContextShouldClose(view)) R4OS2ContextYield(view);
    return matches(args,length,"return",6) ? 37 : 0;
}
