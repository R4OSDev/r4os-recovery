#include <assert.h>
#include <stdint.h>
#include <r4os/protocol.h>
static _Alignas(16) uint8_t storage[64];
static uint32_t allocations,releases,logs,owner;
static void log_message(const uint8_t *text){assert(owner==68 && text && text[0]=='p');++logs;}
static int32_t register_role(const uint8_t *role,uint32_t category,uint32_t flags){assert(owner==68 && role[0]=='m' && category==R4ABI_PROTOCOL_CATEGORY_MISC && flags==7);return 0;}
static int32_t set_status(uint32_t state,const uint8_t *note){assert(owner==68 && state==R4ABI_PROTOCOL_STATE_ACTIVE && note[0]=='p');return 0;}
static int32_t dependency(const uint8_t *role){assert(owner==68 && role[0]=='m');return 1;}
static void *allocate(uint32_t bytes,uint32_t align){assert(owner==68 && bytes==64 && align==16);++allocations;return storage;}
static void release(void *p,uint32_t bytes){assert(owner==68 && p==storage && bytes==64);++releases;}
static int32_t file_read(const uint8_t *path,uint8_t *out,uint32_t capacity){assert(owner==68 && path[0]=='p' && capacity>=4);out[0]='p';out[1]='6';out[2]='8';out[3]='!';return 4;}
const R4ProtocolApi *sdk68_protocol_oracle(void){
 static R4ProtocolApi api;
 api=(R4ProtocolApi){.magic=R4OS_PROTOCOL_MAGIC,.version=R4OS_PROTOCOL_API_VERSION,.size=sizeof(api),.log_info=log_message,.log_warn=log_message,.log_error=log_message,.register_role=register_role,.set_status=set_status,.dependency_status=dependency,.alloc=allocate,.free=release,.file_read=file_read};
 owner=68;allocations=releases=logs=0;return &api;
}
uint32_t sdk68_protocol_allocations(void){return allocations;}
uint32_t sdk68_protocol_releases(void){return releases;}
int32_t sdk68_protocol_c_case(void){
 const R4ProtocolApi *api=sdk68_protocol_oracle();R4ProtocolContext c;
 assert(r4protocol_init(&c,0)<0);assert(r4protocol_init(&c,api)==0);
 r4protocol_log_info(&c,(const uint8_t *)"p");r4protocol_log_warn(&c,(const uint8_t *)"p");r4protocol_log_error(&c,(const uint8_t *)"p");assert(logs==3);
 assert(!r4protocol_register(&c,(const uint8_t *)"misc.p68",R4ABI_PROTOCOL_CATEGORY_MISC,7));
 assert(!r4protocol_status(&c,R4ABI_PROTOCOL_STATE_ACTIVE,(const uint8_t *)"p"));assert(r4protocol_dependency(&c,(const uint8_t *)"misc.p68")==1);
 uint8_t bytes[8];assert(r4protocol_file_read(&c,(const uint8_t *)"p",bytes,8)==4 && bytes[2]=='8');
 void *p=r4protocol_alloc(&c,64,16);assert(p==storage && allocations==1 && releases==0);
 R4ProtocolGate g,other;R4ProtocolLease lease;R4ProtocolClosed receipt={0};
 assert(!r4protocol_gate_init(&g,71));assert(!r4protocol_gate_init(&other,71));
 assert(!r4protocol_gate_enter(&g,&lease));assert(r4protocol_gate_close(&g,&receipt)==R4PROTOCOL_GATE_BUSY && !receipt.epoch && releases==0);
 R4ProtocolLease rejected;assert(r4protocol_gate_enter(&g,&rejected)==R4PROTOCOL_GATE_CLOSED);
 assert(!r4protocol_lease_finish(&lease));assert(r4protocol_lease_finish(&lease)==R4PROTOCOL_GATE_STALE);
 assert(!r4protocol_gate_close(&g,&receipt));R4ProtocolClosed foreign;assert(!r4protocol_gate_close(&other,&foreign));
 assert(r4protocol_gate_reset(&g,foreign,72)==R4PROTOCOL_GATE_STALE);
 assert(!r4protocol_gate_reset(&g,receipt,72));assert(r4protocol_gate_reset(&g,receipt,73)==R4PROTOCOL_GATE_STALE);
 r4protocol_free(&c,p,64);assert(releases==1);return 0;
}
