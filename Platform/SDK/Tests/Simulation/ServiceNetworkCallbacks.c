/* Reuse the actual existing C protocol peers, without unrelated power cases. */
#define main sdk_service_unused_fixture
#include "../Conformance/ServiceNetworkFacadePrototype05826.c"
#undef main
#include <r4os/facades.h>
#include <r4os/net_bridge.h>
#include <assert.h>

static uint64_t clock_tick=100, last_wait;
static uint32_t forbidden_calls;
static int32_t forbidden_open(uint32_t id,R4ProgramProcessHandle *out){(void)id;(void)out;++forbidden_calls;return -99;}
static uint32_t queued, yielded, stopping, reply_cancelled, io_live, io_done;
static uint8_t *async_out;
static const uint8_t *async_in;
static R4ServiceMessageHeader *async_header;
static uint16_t async_op;
static uint32_t async_handle,async_length,async_capacity;
static int32_t async_result;
static uint32_t serial_live, serial_closing;
static uint64_t serial_id=UINT64_C(0x1122334455667788),serial_generation=UINT64_C(0x99aabbccddeeff00),serial_handle=UINT64_C(0xabcd0123456789ef);
int sdk_service_c_case(void){return service_network_checks();}
void sdk_service_clock_rate(uint32_t value){clock_rate=value;}
uint32_t sdk_service_calendar_calls(void){return calendar_calls;}
uint64_t sdk_service_call_timeout(void){return observed_timeout;}
void sdk_service_mode(uint32_t value){reply_mode=(enum ReplyMode)value;}
void sdk_service_queue(uint32_t n){queued=n;}
void sdk_service_stop(uint32_t value){stopping=value;}
void sdk_service_cancel_reply(uint32_t value){reply_cancelled=value;}
uint32_t sdk_service_yielded(void){return yielded;}
uint64_t sdk_service_last_wait(void){return last_wait;}
uint32_t sdk_service_open_handles(void){return open_handles;}
static uint64_t ticks(void){return clock_tick;}
static int32_t service2_clock(R4MonotonicClockInfo *out){
 *out=(R4MonotonicClockInfo){.version=1,.size=sizeof(*out),.flags=R4OS_MONOTONIC_CLOCK_FLAG_VALID,.source=1,.generation=43,.frequency_hz=R4OS_MONOTONIC_CLOCK_FREQUENCY_HZ,.resolution_ns=1,.instant_ns=(clock_tick+100000)*1000000,.event_requested_hz=clock_rate,.event_effective_hz=clock_rate+7};return 1;
}
uint32_t sdk_service2_should_close(const R4XStartContext2 *raw){(void)raw;return stopping;}
void sdk_service2_yield(const R4XStartContext2 *raw){(void)raw;++yielded;}
static int32_t service2_ipc_poll(uint32_t id){return id==11?17:-99;}
static void time_state(R4TimeState *out){++calendar_calls;memset(out,0,sizeof(*out));out->monotonic_hz=1000;}
static uint32_t should_close(void){return stopping;}
static void task_yield(void){++yielded;}
static int32_t endpoint_wait(uint32_t handle,uint64_t timeout){last_wait=timeout;return handle==201&&endpoint_registered?(int32_t)queued:R4OS_SERVICE_API_RESULT_BAD_HANDLE;}
static int32_t endpoint_poll(uint32_t handle){return endpoint_wait(handle,0);}
static int32_t endpoint_recv(uint32_t handle,R4ServiceMessageHeader *header,uint8_t *out,uint32_t capacity){endpoint_ready=queued!=0;int32_t rc=fake_recv(handle,header,out,capacity);if(rc>=0&&queued)--queued;return rc;}
static int32_t endpoint_reply(uint32_t handle,uint32_t id,int32_t status,const uint8_t *bytes,uint32_t n){if(reply_cancelled)return R4OS_SERVICE_API_RESULT_NOT_FOUND;return fake_reply(handle,id,status,bytes,n);}
static int32_t io_begin(uint32_t handle,uint16_t op,const uint8_t *in,uint32_t n,R4ServiceMessageHeader *header,uint8_t *out,uint32_t capacity,uint64_t timeout,uint32_t flags,uint32_t *id){
    assert((handle==102||handle==103)&&capacity>=sizeof(R4NetServiceTcpResult)+2&&flags==0&&!io_live);
    if(op==37)assert(n==4&&memcmp(in,"PING",4)==0&&timeout==17);
    async_in=in;async_out=out;async_header=header;async_op=op;async_handle=handle;async_length=n;async_capacity=capacity;io_live=1;io_done=0;*id=901;return 0;
}
static int32_t io_status(uint32_t id,R4ProgramIoInfo *out){
    if(id!=901||!io_live)return R4OS_IO_ERROR_NOT_FOUND;
    memset(out,0,sizeof(*out));out->state=io_done?R4OS_IO_STATE_COMPLETED:R4OS_IO_STATE_PENDING;
    out->result=io_done?async_result:0;return 0;
}
void sdk_service_complete(void){
    assert(io_live&&!io_done);
    if(async_op!=37){R4SdkDeadlineView view=R4SdkDeadlineSplit(async_in,async_length);async_result=fake_call(async_handle,async_op,async_in,(uint32_t)view.length,async_header,async_out,async_capacity,17);io_done=1;return;}
    assert(memcmp(async_in,"PING",4)==0);
    R4NetServiceTcpResult result={.magic=R4OS_NET_SERVICE_TCP_RESULT_MAGIC,.version=R4OS_NET_SERVICE_TCP_RESULT_VERSION,.flags=R4OS_NET_SERVICE_TCP_FLAG_DATA,.bytes=2,.pending_rx=2,.tx_window=9};
    memcpy(async_out,&result,sizeof(result));memcpy(async_out+sizeof(result),"OK",2);
    *async_header=(R4ServiceMessageHeader){.magic=R4OS_SERVICE_API_MAGIC,.version=R4OS_SERVICE_API_VERSION,.op=async_op};async_result=sizeof(result)+2;io_done=1;
}
static int32_t io_wait(uint32_t id,uint64_t timeout,R4ProgramIoInfo *out){if(id==901&&io_live&&!io_done&&async_op!=37)sdk_service_complete();int32_t rc=io_status(id,out);return rc!=0?rc:(!io_done&&timeout!=R4OS_IO_WAIT_FOREVER?R4OS_IO_ERROR_TIMEOUT:0);}
static int32_t io_close(uint32_t id){if(id!=901||!io_live)return R4OS_IO_ERROR_NOT_FOUND;if(!io_done)return R4OS_IO_ERROR_BUSY;io_live=0;return 0;}
void sdk_service_reap_pending(void){assert(io_live&&io_done);assert(io_close(901)==0);assert(fake_close(async_handle)==0);}
static uint32_t port_count(void){return 1;}
static int32_t port_at(uint32_t index,R4SerialPortInfo *out){if(index)return R4OS_SERIAL_ERROR_NOT_FOUND;memset(out,0,sizeof(*out));out->com_number=3;out->port_id=serial_id;out->generation=serial_generation;return 0;}
static int32_t port_open(uint64_t id,uint64_t generation,const R4SerialConfig *config,uint64_t *out){(void)config;if(id!=serial_id||generation!=serial_generation)return R4OS_SERIAL_ERROR_STALE;if(serial_live)return R4OS_SERIAL_ERROR_BUSY;serial_live=1;*out=serial_handle;return 0;}
static int32_t port_configure(uint64_t handle,const R4SerialConfig *config){(void)config;return handle==serial_handle?0:R4OS_SERIAL_ERROR_STALE;}
static int32_t port_read(uint64_t handle,uint8_t *out,uint32_t n,uint64_t ticks_value,R4SerialTransfer *info){assert(handle==serial_handle&&serial_live&&n>=2&&ticks_value==19);out[0]='R';out[1]='X';memset(info,0,sizeof(*info));info->completed=2;info->requested=n;return R4OS_SERIAL_ERROR_TIMEOUT;}
static int32_t port_write(uint64_t handle,const uint8_t *bytes,uint32_t n,uint64_t ticks_value,R4SerialTransfer *info){assert(handle==serial_handle&&serial_live&&n==4&&memcmp(bytes,"SEND",4)==0&&ticks_value==19);memset(info,0,sizeof(*info));info->completed=2;info->requested=n;return 0;}
static int32_t port_drain(uint64_t handle,uint64_t ticks_value){(void)ticks_value;return handle==serial_handle?0:R4OS_SERIAL_ERROR_STALE;}
static int32_t port_status(uint64_t handle,R4SerialStatus *out){if(handle!=serial_handle)return R4OS_SERIAL_ERROR_STALE;memset(out,0,sizeof(*out));return 0;}
static int32_t port_cancel(uint64_t handle){if(handle!=serial_handle)return R4OS_SERIAL_ERROR_STALE;serial_closing=0;return 0;}
static int32_t port_close(uint64_t handle,uint32_t flags,uint64_t timeout){(void)flags;(void)timeout;if(handle!=serial_handle)return R4OS_SERIAL_ERROR_STALE;if(serial_closing)return R4OS_SERIAL_ERROR_BUSY;serial_live=0;return 0;}
void sdk_serial_busy(uint32_t value){serial_closing=value;}
uint32_t sdk_serial_live(void){return serial_live;}

/* Controlled callbacks shared by real C/Rust facade consumers. The explicit
 * ACK below models completion; this host fixture is not physical guest proof. */
static R4ProgramProcessHandle managed_process;
static uint32_t managed_terminal,managed_closes;
static uint64_t managed_budget;
static int32_t managed_result;
void sdk_service_bound_reset(void){managed_process=(R4ProgramProcessHandle){.instance_id=41,.generation=UINT64_C(0x1122334455667788)};managed_terminal=managed_closes=0;managed_budget=0;managed_result=0;}
void sdk_service_bound_result(int32_t value){managed_result=value;}
void sdk_service_bound_replace(void){++managed_process.generation;}
void sdk_service_bound_ack(void){managed_terminal=1;}
uint32_t sdk_service_bound_closes(void){return managed_closes;}
uint64_t sdk_service_bound_budget(void){return managed_budget;}
static R4ServiceInfo managed_info(void){return (R4ServiceInfo){.instance_id=managed_terminal?0:managed_process.instance_id,.state=managed_terminal?R4OS_SERVICE_STATE_STOPPED:R4OS_SERVICE_STATE_STOPPING,.exit_code=managed_terminal?-23:0};}
static int32_t managed_bound_detail(const uint8_t *name,R4ServiceDetail *out,R4ProgramProcessHandle *process){assert(strcmp((const char *)name,"MANAGED")==0);if(managed_result)return managed_result;*out=(R4ServiceDetail){.info=managed_info()};*process=managed_process;return 0;}
static int32_t managed_stop_bound(const uint8_t *name,const R4ProgramProcessHandle *process,R4ServiceInfo *out,uint64_t budget){
    assert(strcmp((const char *)name,"MANAGED")==0);managed_budget=budget;
    if(process->instance_id!=managed_process.instance_id||process->reserved!=managed_process.reserved||process->generation!=managed_process.generation)return R4OS_SERVICE_API_RESULT_BUSY;
    *out=managed_info();if(managed_terminal)return 0;++managed_closes;return R4OS_SERVICE_API_RESULT_TIMEOUT;
}
int sdk_service_bound_c_case(void){
    R4App app;R4XStartR4Sys2 sys;R4XStartR4Net2 net;init_app(&app,&sys,&net);clock_rate=1000;sdk_service_bound_reset();
    sys.service_bound_detail=(uintptr_t)&managed_bound_detail;sys.service_stop_bound=(uintptr_t)&managed_stop_bound;
    R4Services services=r4_app_services(&app);R4ServiceDetail detail;R4ProgramProcessHandle process;R4ServiceInfo info;
    if(r4_services_bound_detail(&services,"MANAGED",&detail,&process)||process.generation!=UINT64_C(0x1122334455667788)||detail.info.instance_id!=41)return 1;
    sdk_service_bound_replace();
    if(r4_services_stop_bound(&services,"MANAGED",&process,poll_timeout(),&info)!=R4OS_SERVICE_API_RESULT_BUSY||managed_closes)return 2;
    if(r4_services_bound_detail(&services,"MANAGED",&detail,&process))return 3;
    if(r4_services_stop_bound(&services,"MANAGED",&process,r4_timeout_finite((R4Duration){7000000}),&info)!=R4OS_SERVICE_API_RESULT_TIMEOUT||managed_budget!=7||managed_closes!=1||info.instance_id!=41)return 4;
    sdk_service_bound_ack();
    if(r4_services_bound_detail(&services,"MANAGED",&detail,&process)||detail.info.instance_id||detail.info.exit_code!=-23||process.generation!=UINT64_C(0x1122334455667789))return 5;
    if(r4_services_stop_bound(&services,"MANAGED",&process,poll_timeout(),&info)||info.instance_id)return 6;
    sys.size=offsetof(R4XStartR4Sys2,service_bound_detail);
    if(r4_services_bound_detail(&services,"MANAGED",&detail,&process)!=R4OS_ERR_NO_FN||process.instance_id||process.generation)return 7;
    sys.size=offsetof(R4XStartR4Sys2,service_stop_bound);
    if(r4_services_stop_bound(&services,"MANAGED",&process,poll_timeout(),&info)!=R4OS_ERR_NO_FN||managed_closes!=1)return 8;
    sdk_service_bound_reset();return 0;
}
void sdk_service_tables(R4XStartR4Sys2 *sys,R4XStartR4Net2 *net,R4XStartR4Desk2 *desk,R4XStartR4Dev2 *dev){
    /* The caller supplies canonical current record defaults. C's public
     * R4XSTART_*_VERSION constants describe minimum query prefixes. */
    uint32_t sys_version=sys->abi_version,net_version=net->abi_version,desk_version=desk->abi_version,dev_version=dev->abi_version;
    R4App ignored;init_app(&ignored,sys,net);reply_mode=MODE_OK;open_handles=0;endpoint_registered=0;queued=yielded=stopping=reply_cancelled=io_live=serial_live=serial_closing=0;
    sys->abi_version=sys_version;net->abi_version=net_version;
    sys->ticks=(uintptr_t)&ticks;sys->time_state=(uintptr_t)&time_state;sys->program_should_close=(uintptr_t)&should_close;sys->task_yield=(uintptr_t)&task_yield;
    sys->monotonic_clock=(uintptr_t)&service2_clock;
    sys->service_endpoint_wait=(uintptr_t)&endpoint_wait;sys->service_endpoint_poll=(uintptr_t)&endpoint_poll;sys->service_endpoint_recv=(uintptr_t)&endpoint_recv;sys->service_endpoint_reply=(uintptr_t)&endpoint_reply;
    sys->io_service_call=(uintptr_t)&io_begin;sys->io_status=(uintptr_t)&io_status;sys->io_wait=(uintptr_t)&io_wait;sys->io_close=(uintptr_t)&io_close;
    sdk_service_bound_reset();sys->service_bound_detail=(uintptr_t)&managed_bound_detail;sys->service_stop_bound=(uintptr_t)&managed_stop_bound;
    *desk=(R4XStartR4Desk2){.magic=R4OS2_R4DESK_MAGIC,.abi_version=desk_version,.size=sizeof(*desk)};
    *dev=(R4XStartR4Dev2){.magic=R4OS2_R4DEV_MAGIC,.abi_version=dev_version,.size=sizeof(*dev),.serial_count=(uintptr_t)&port_count,.serial_port_at=(uintptr_t)&port_at,.serial_open=(uintptr_t)&port_open,.serial_configure=(uintptr_t)&port_configure,.serial_read=(uintptr_t)&port_read,.serial_write=(uintptr_t)&port_write,.serial_drain=(uintptr_t)&port_drain,.serial_status=(uintptr_t)&port_status,.serial_cancel=(uintptr_t)&port_cancel,.serial_close=(uintptr_t)&port_close};
}
int sdk_service_extra_c_case(void){
    R4NetServiceTcpResult tcp={.flags=R4OS_NET_SERVICE_STATUS_WOULD_BLOCK<<R4OS_NET_SERVICE_STATUS_SHIFT};
    if(r4_net_classify_tcp(&tcp,3).kind!=R4_NET_RESULT_WOULD_BLOCK)return 1;
    R4NetServiceUdpResult udp={.flags=R4OS_NET_SERVICE_STATUS_TIMEOUT<<R4OS_NET_SERVICE_STATUS_SHIFT};
    if(r4_net_classify_udp(&udp,3).kind!=R4_NET_RESULT_TIMED_OUT)return 2;
    uint64_t n=99;if(r4_remaining_ticks((R4Deadline){5},(R4MonotonicInstant){5},0,&n)!=0||n!=0)return 3;
    R4App app;R4XStartR4Sys2 sys;R4XStartR4Net2 net;init_app(&app,&sys,&net);
    R4Services services=r4_app_services(&app);sys.size=offsetof(R4XStartR4Sys2,service_open);R4ServiceConnection connection;
    if(r4_services_available(&services)||r4_services_open(&services,"EXAMPLE",&connection)!=R4OS_ERR_NO_FN)return 4;
    R4XStartContext2 ctx={.instance_id=42};app.context=&ctx;sys.size=offsetof(R4XStartR4Sys2,program_open_handle);sys.program_open_handle=(uintptr_t)&forbidden_open;
    R4Tray tray;forbidden_calls=0;if(r4_app_tray(&app,&tray)!=R4OS_ERR_NO_FN||forbidden_calls)return 5;
    return 0;
}

/* Same typed bridge used by a real C consumer, with a valid current import. */
int sdk_net_current_admission(const R4XStartContext2 *start) {
    R4OS2Context view;
    if (R4OS2ContextInit(start, &view) != 0) return 5;
    uint8_t response[R4OS_NET_SERVICE_HEADER_SIZE], before[sizeof(response)];
    memset(response, 0xB7, sizeof(response)); memcpy(before, response, sizeof(before));
    if (R4SdkNet2_netServiceRequest(&view, 1, 2, 3, 0, 0, response, sizeof(response)) != R4OS_ERR_NO_FN) return 1;
    if (memcmp(response, before, sizeof(response))) return 2;
    if (R4SdkNet2_netServiceRequest(&view, 1, 2, 3, 0, 0, response, sizeof(response)-1) != R4OS_NET_SERVICE_RESULT_BAD_REQUEST) return 3;
    return memcmp(response, before, sizeof(response)) ? 4 : 0;
}

/* One controlled TCP peer: discovery consumes budget; a lost reply may have
 * consumed bytes; a structured timeout can still acknowledge a prefix. */
static uint64_t tcp_deadline_now, tcp_discovery_ticks, tcp_expected_deadline, tcp_expected_wait;
static uint32_t tcp_deadline_calls, tcp_deadline_effects, tcp_deadline_missing_footer, tcp_deadline_mode;
static uint64_t tcp_deadline_ticks(void){return tcp_deadline_now;}
static int32_t tcp_deadline_open(const uint8_t *name,R4ServiceInfo *out){
    tcp_deadline_now+=tcp_discovery_ticks;return fake_open(name,out);
}
static int32_t tcp_deadline_call(uint32_t handle,uint16_t op,const uint8_t *request,uint32_t n,R4ServiceMessageHeader *header,uint8_t *out,uint32_t capacity,uint64_t wait){
    ++tcp_deadline_calls;
    if(n<sizeof(R4ServiceDeadlineFooter)){++tcp_deadline_missing_footer;return R4OS_SERVICE_API_RESULT_INVALID;}
    R4ServiceDeadlineFooter footer;memcpy(&footer,request+n-sizeof(footer),sizeof(footer));
    if(footer.magic!=UINT32_C(1279538258)||footer.version!=1||footer.size!=sizeof(footer)||footer.reserved0||footer.payload_len!=n-sizeof(footer)||footer.deadline_tick!=tcp_expected_deadline||wait!=tcp_expected_wait){
        ++tcp_deadline_missing_footer;return R4OS_SERVICE_API_RESULT_INVALID;
    }
    if(tcp_deadline_mode==1){++tcp_deadline_effects;return R4OS_SERVICE_API_RESULT_TIMEOUT;}
    if(tcp_deadline_mode==2){
        R4NetServiceTcpResult reply={0};reply.magic=R4OS_NET_SERVICE_TCP_RESULT_MAGIC;reply.version=R4OS_NET_SERVICE_TCP_RESULT_VERSION;reply.action=op;
        reply.flags=R4OS_NET_SERVICE_TCP_FLAG_DATA|R4OS_NET_SERVICE_TCP_FLAG_TIMEOUT;reply.service_status=R4OS_NET_SERVICE_STATUS_TIMEOUT;
        reply.lifecycle_cause=R4OS_NET_SERVICE_SOCKET_LIFECYCLE_TIMEOUT;reply.bytes=3;
        assert(capacity>=sizeof(reply)+3);memcpy(out,&reply,sizeof(reply));memcpy(out+sizeof(reply),"ACK",3);
        *header=(R4ServiceMessageHeader){.magic=R4OS_SERVICE_API_MAGIC,.version=R4OS_SERVICE_API_VERSION,.op=op,.status=R4OS_SERVICE_API_RESULT_OK};
        return (int32_t)sizeof(reply)+3;
    }
    return fake_call(handle,op,request,footer.payload_len,header,out,capacity,wait);
}
void sdk_tcp_deadline_reset(uint32_t mode,uint64_t discovery,uint64_t deadline,uint64_t wait){
    tcp_deadline_now=100;tcp_discovery_ticks=discovery;tcp_expected_deadline=deadline;tcp_expected_wait=wait;
    tcp_deadline_calls=0;tcp_deadline_effects=0;tcp_deadline_missing_footer=0;tcp_deadline_mode=mode;reply_mode=MODE_OK;clock_rate=1000;clock_mode=0;
}
void sdk_tcp_deadline_tables(R4XStartR4Sys2 *sys,R4XStartR4Net2 *net){
    R4App app;init_app(&app,sys,net);sys->ticks=(uintptr_t)&tcp_deadline_ticks;
    sys->service_open=(uintptr_t)&tcp_deadline_open;sys->service_call=(uintptr_t)&tcp_deadline_call;
}
uint32_t sdk_tcp_deadline_calls(void){return tcp_deadline_calls;}
uint32_t sdk_tcp_deadline_effects(void){return tcp_deadline_effects;}
uint32_t sdk_tcp_deadline_bad_footer(void){return tcp_deadline_missing_footer;}
int sdk_service_tcp_deadline_case(void){
    R4App app;R4XStartR4Sys2 sys;R4XStartR4Net2 net;init_app(&app,&sys,&net);sdk_tcp_deadline_tables(&sys,&net);
    R4Network network=r4_app_network(&app);
    R4TcpSocket socket={.network=network,.raw=501,.owned=1};
    uint8_t bytes[8]={0};R4Timeout finite=r4_timeout_finite((R4Duration){20000000});
    sdk_tcp_deadline_reset(0,5,120,15);
    R4NetResult result=r4_tcp_socket_write(&socket,(const uint8_t *)"HELLO",5,finite);
    if(tcp_deadline_missing_footer||tcp_deadline_calls!=1||result.kind!=R4_NET_RESULT_OK||result.bytes!=5)return 101;
    sdk_tcp_deadline_reset(1,0,120,20);
    result=r4_tcp_socket_read(&socket,bytes,sizeof(bytes),finite);
    /* 9 is the additive facade outcome-unknown state, not a wire status. */
    if(result.kind!=9||result.raw_code!=R4OS_SERVICE_API_RESULT_TIMEOUT||tcp_deadline_calls!=1||tcp_deadline_effects!=1)return 102;
    sdk_tcp_deadline_reset(2,0,120,20);
    result=r4_tcp_socket_read(&socket,bytes,sizeof(bytes),finite);
    if(result.kind!=R4_NET_RESULT_TIMED_OUT||result.bytes!=3||memcmp(bytes,"ACK",3))return 103;
    sdk_tcp_deadline_reset(0,20,120,0);
    result=r4_tcp_socket_read(&socket,bytes,sizeof(bytes),finite);
    if(result.kind!=R4_NET_RESULT_TIMED_OUT||result.bytes||tcp_deadline_calls)return 104;
    sdk_tcp_deadline_reset(0,0,0,0);
    result=r4_tcp_socket_write(&socket,(const uint8_t *)"X",1,r4_timeout_poll());
    if(result.kind!=R4_NET_RESULT_OK||result.bytes!=1||tcp_deadline_missing_footer)return 105;
    sdk_tcp_deadline_reset(0,5,UINT64_MAX,UINT64_MAX);
    result=r4_tcp_socket_write(&socket,(const uint8_t *)"X",1,r4_timeout_forever());
    if(result.kind!=R4_NET_RESULT_OK||result.bytes!=1||tcp_deadline_missing_footer)return 106;
    sdk_tcp_deadline_reset(0,0,0,0);tcp_deadline_now=UINT64_MAX-10;
    result=r4_tcp_socket_read(&socket,bytes,sizeof(bytes),finite);
    if(result.kind!=R4_NET_RESULT_FAILED||tcp_deadline_calls)return 107;
    return 0;
}

/* One controlled TCP lifecycle: readiness is a snapshot, transfer is a count,
 * peer termination never disposes the still-owned local frontend. */
static const uint8_t tcp80_payload[]="TCP80-remaining-payload\n";
static uint32_t tcp80_offset,tcp80_calls,tcp80_mode,tcp80_close_unknown,tcp80_close_pending;
static int32_t tcp80_call(uint32_t handle,uint16_t op,const uint8_t *request,uint32_t n,R4ServiceMessageHeader *header,uint8_t *out,uint32_t capacity,uint64_t wait){
    (void)handle;(void)wait;++tcp80_calls;
    R4ServiceDeadlineFooter footer;assert(n>=4+sizeof(footer));memcpy(&footer,request+n-sizeof(footer),sizeof(footer));
    assert(footer.magic==R4OS_SERVICE_DEADLINE_FOOTER_MAGIC&&footer.version==R4OS_SERVICE_DEADLINE_FOOTER_VERSION&&footer.size==sizeof(footer)&&footer.payload_len==n-sizeof(footer)&&footer.deadline_tick==UINT64_MAX);
    assert(((uint32_t)request[0]|((uint32_t)request[1]<<8)|((uint32_t)request[2]<<16)|((uint32_t)request[3]<<24))==501);
    *header=(R4ServiceMessageHeader){.magic=R4OS_SERVICE_API_MAGIC,.version=R4OS_SERVICE_API_VERSION,.op=op,.status=R4OS_SERVICE_API_RESULT_OK};
    if(op==R4OS_NET_SERVICE_OP_TCP_CLOSE_RESULT&&tcp80_close_unknown)return R4OS_SERVICE_API_RESULT_TIMEOUT;
    R4NetServiceTcpResult reply={0};reply.magic=R4OS_NET_SERVICE_TCP_RESULT_MAGIC;reply.version=R4OS_NET_SERVICE_TCP_RESULT_VERSION;reply.handle=501;
    reply.flags=R4OS_NET_SERVICE_TCP_FLAG_HANDLE_VALID|R4OS_NET_SERVICE_TCP_FLAG_OK;
    reply.service_status=R4OS_NET_SERVICE_STATUS_OK;reply.lifecycle_cause=R4OS_NET_SERVICE_SOCKET_LIFECYCLE_PEER_GONE;
    reply.pending_rx=(uint32_t)sizeof(tcp80_payload)-1-tcp80_offset;reply.tx_window=123;
    if(tcp80_mode==1){reply.lifecycle_cause=R4OS_NET_SERVICE_SOCKET_LIFECYCLE_RESET;reply.result=-777;reply.pending_rx=0;}
    if(tcp80_mode==2){reply.lifecycle_cause=R4OS_NET_SERVICE_SOCKET_LIFECYCLE_BAD_HANDLE;reply.result=R4OS_SERVICE_API_RESULT_BAD_HANDLE;reply.pending_rx=0;}
    if(op==R4OS_NET_SERVICE_OP_TCP_CLOSE_RESULT){reply.action=R4OS_NET_SERVICE_TCP_ACTION_CLOSE;reply.lifecycle_cause=tcp80_close_pending?R4OS_NET_SERVICE_SOCKET_LIFECYCLE_PENDING_CLOSE:R4OS_NET_SERVICE_SOCKET_LIFECYCLE_LOCAL_CLOSE;reply.tx_ack=12345;reply.result=0;reply.pending_rx=0;}
    if(op==R4OS_NET_SERVICE_OP_TCP_READ_RESULT&&tcp80_mode==0){
        uint32_t size=(uint32_t)request[4]|((uint32_t)request[5]<<8);
        if(size>reply.pending_rx)size=reply.pending_rx;
        reply.bytes=size;reply.pending_rx-=size;assert(sizeof(reply)+size<=capacity);
        memcpy(out+sizeof(reply),tcp80_payload+tcp80_offset,size);tcp80_offset+=size;
    }
    if(tcp80_mode==3&&op==R4OS_NET_SERVICE_OP_TCP_READ_RESULT)reply.bytes=capacity+1;
    assert(capacity>=sizeof(reply));memcpy(out,&reply,sizeof(reply));return (int32_t)(sizeof(reply)+(tcp80_mode==0?reply.bytes:0));
}
int sdk_service_tcp_readiness_case(void){
    R4App app;R4XStartR4Sys2 sys;R4XStartR4Net2 net;init_app(&app,&sys,&net);sys.service_call=(uintptr_t)&tcp80_call;
    R4TcpSocket socket={.network=r4_app_network(&app),.raw=501,.owned=1};tcp80_offset=tcp80_calls=tcp80_mode=tcp80_close_unknown=tcp80_close_pending=0;
    R4NetResult result=r4_tcp_socket_poll(&socket,r4_timeout_forever());
    if(!r4_tcp_socket_valid(&socket)||result.kind!=R4_NET_RESULT_PEER_CLOSED||result.bytes!=0)return 181;
#ifndef SDK_TCP80_OLD_SOURCE
    R4TcpPollResult snapshot=r4_tcp_socket_readiness(&socket,r4_timeout_forever());
    if(!snapshot.available||!snapshot.readiness.readable||!snapshot.readiness.peer_closed||!snapshot.readiness.terminal||snapshot.readiness.pending_rx!=sizeof(tcp80_payload)-1||snapshot.result.bytes||tcp80_offset)return 182;
#endif
    uint8_t data[sizeof(tcp80_payload)]={0};uint32_t total=0;
    while(total<sizeof(tcp80_payload)-1){
#ifndef SDK_TCP80_OLD_SOURCE
        R4TcpPollResult before=r4_tcp_socket_readiness(&socket,r4_timeout_forever());
        if(!before.available||!before.readiness.readable||!before.readiness.peer_closed||before.readiness.pending_rx!=sizeof(tcp80_payload)-1-total||tcp80_offset!=total)return 183;
#endif
        result=r4_tcp_socket_read(&socket,data+total,5,r4_timeout_forever());
        if(result.kind!=R4_NET_RESULT_PEER_CLOSED||!result.bytes||result.bytes>5||!r4_tcp_socket_valid(&socket))return 184;
        total+=result.bytes;
    }
    if(memcmp(data,tcp80_payload,total))return 185;
    result=r4_tcp_socket_read(&socket,data,5,r4_timeout_forever());
    if(result.kind!=R4_NET_RESULT_PEER_CLOSED||result.bytes||!r4_tcp_socket_valid(&socket))return 186;
#ifndef SDK_TCP80_OLD_SOURCE
    R4TcpPollResult eof=r4_tcp_socket_readiness(&socket,r4_timeout_forever());
    if(!eof.available||eof.readiness.readable||!eof.readiness.peer_closed||eof.readiness.pending_rx||eof.result.bytes)return 187;
#endif
    result=r4_tcp_socket_write(&socket,(const uint8_t *)"W",1,r4_timeout_forever());
    if(result.kind!=R4_NET_RESULT_PEER_CLOSED||!r4_tcp_socket_valid(&socket))return 188;
    tcp80_mode=1;memset(data,0xA5,sizeof(data));
    result=r4_tcp_socket_read(&socket,data,5,r4_timeout_forever());
    if(result.kind!=R4_NET_RESULT_RESET||result.bytes||data[0]!=0xA5||!r4_tcp_socket_valid(&socket))return 189;
#ifndef SDK_TCP80_OLD_SOURCE
    R4TcpPollResult reset=r4_tcp_socket_readiness(&socket,r4_timeout_forever());
    if(!reset.available||!reset.readiness.reset||!reset.readiness.terminal||reset.readiness.readable||reset.result.bytes)return 190;
#endif
    tcp80_mode=2;result=r4_tcp_socket_poll(&socket,r4_timeout_forever());
    if(result.kind!=R4_NET_RESULT_CLOSED||!r4_tcp_socket_valid(&socket))return 191;
    tcp80_close_unknown=1;result=r4_tcp_socket_close(&socket,r4_timeout_forever());
    if(result.kind!=R4_NET_RESULT_OUTCOME_UNKNOWN||r4_net_progress_known(result)||!r4_tcp_socket_valid(&socket))return 192;
    tcp80_close_unknown=0;socket.owned=0;uint32_t calls=tcp80_calls;
    result=r4_tcp_socket_close(&socket,r4_timeout_forever());
    if(result.raw_code!=R4OS_ERR_NOT_OWNED||tcp80_calls!=calls||!r4_tcp_socket_valid(&socket))return 193;
    socket.owned=1;result=r4_tcp_socket_close(&socket,r4_timeout_forever());
    if(result.kind!=R4_NET_RESULT_CLOSED||r4_tcp_socket_valid(&socket))return 194;
    socket.raw=501;tcp80_mode=3;memset(data,0xA5,sizeof(data));
    result=r4_tcp_socket_read(&socket,data,5,r4_timeout_forever());
    if(result.kind!=R4_NET_RESULT_OUTCOME_UNKNOWN||data[0]!=0xA5||!r4_tcp_socket_valid(&socket))return 195;
    tcp80_mode=0;result=r4_tcp_socket_close(&socket,r4_timeout_forever());
    return result.kind==R4_NET_RESULT_CLOSED&&!r4_tcp_socket_valid(&socket)&&open_handles==0?0:196;
}

int sdk_service_tcp_close_receipt_case(void){
    R4App app;R4XStartR4Sys2 sys;R4XStartR4Net2 net;init_app(&app,&sys,&net);sys.service_call=(uintptr_t)&tcp80_call;
    R4TcpSocket socket={.network=r4_app_network(&app),.raw=501,.owned=1};
    tcp80_offset=tcp80_calls=tcp80_mode=tcp80_close_unknown=0;tcp80_close_pending=1;
    R4TcpCloseReceipt receipt=r4_tcp_socket_close_receipt(&socket,r4_timeout_forever());
    if(!receipt.submitted||!receipt.accepted||!receipt.frontend_released||!receipt.pending_shutdown||
       receipt.operation!=R4OS_NET_SERVICE_OP_TCP_CLOSE_RESULT||receipt.action!=R4OS_NET_SERVICE_TCP_ACTION_CLOSE||
       receipt.ack!=12345||receipt.lifecycle_cause!=R4OS_NET_SERVICE_SOCKET_LIFECYCLE_PENDING_CLOSE||
       receipt.outcome.kind!=R4_NET_RESULT_CLOSED||r4_tcp_socket_valid(&socket)||tcp80_calls!=1)return 1;
    if(r4_tcp_socket_close(&socket,r4_timeout_forever()).raw_code!=R4OS_ERR_CLOSED||tcp80_calls!=1)return 2;
    socket.raw=501;tcp80_close_pending=0;tcp80_close_unknown=1;
    receipt=r4_tcp_socket_close_receipt(&socket,r4_timeout_forever());
    if(!receipt.submitted||receipt.accepted||receipt.frontend_released||receipt.outcome.kind!=R4_NET_RESULT_OUTCOME_UNKNOWN||!r4_tcp_socket_valid(&socket)||tcp80_calls!=2)return 3;
    receipt=r4_tcp_socket_close_receipt(&socket,r4_timeout_forever());
    if(receipt.outcome.kind!=R4_NET_RESULT_OUTCOME_UNKNOWN||tcp80_calls!=2)return 4;
    if(r4_tcp_socket_close(&socket,r4_timeout_forever()).kind!=R4_NET_RESULT_OUTCOME_UNKNOWN||tcp80_calls!=2)return 5;
    return 0;
}

#include <r4os/desktop_links.h>
/* Interop peer exercises exact native request bytes and response-loss recovery.
 * Production idempotence and binding rejection are tested by WINSVC itself. */
static uint32_t link_activations,link_statuses;
static R4DesktopLinkRequest link_original;
static int32_t link_open(const uint8_t*name,R4ServiceInfo*out){if(strcmp((const char*)name,"WINSVC")==0){*out=(R4ServiceInfo){.handle=505,.instance_id=31};return 0;}return fake_open(name,out);}
static int32_t link_close(uint32_t handle){return handle==505?0:fake_close(handle);}
static int32_t link_call(uint32_t handle,uint16_t op,const uint8_t*bytes,uint32_t n,R4ServiceMessageHeader*header,uint8_t*out,uint32_t capacity,uint64_t timeout){
 if(op<R4OS_DESKTOP_LINK_OP_SCOPE||op>R4OS_DESKTOP_LINK_OP_RELEASE)return fake_call(handle,op,bytes,n,header,out,capacity,timeout);
 assert(handle==505&&n==sizeof(R4DesktopLinkRequest)&&capacity>=sizeof(R4DesktopLinkReply));
 R4DesktopLinkRequest q;memcpy(&q,bytes,sizeof(q));R4DesktopLinkReply r={0};r.request=q;r.flags=R4OS_DESKTOP_LINK_CAPABILITIES;
 if(op==R4OS_DESKTOP_LINK_OP_SCOPE){r.request.token=(R4DesktopLinkToken){.version=1,.size=sizeof(R4DesktopLinkToken),.service={.instance_id=31,.generation=UINT64_C(0xabc0000000000001)},.epoch={6,7,8}};}
 if(op==R4OS_DESKTOP_LINK_OP_PREPARE){r.request.token.serial=55;link_original=r.request;r.phase=R4OS_DESKTOP_LINK_PHASE_PREPARED;}
 if(op==R4OS_DESKTOP_LINK_OP_ACTIVATE){assert(memcmp(&q,&link_original,sizeof(q))==0);++link_activations;return R4OS_SERVICE_API_RESULT_TIMEOUT;}
 if(op==R4OS_DESKTOP_LINK_OP_STATUS){assert(memcmp(&q,&link_original,sizeof(q))==0);++link_statuses;r.phase=R4OS_DESKTOP_LINK_PHASE_PROCESS;r.process=(R4ProgramProcessHandle){.instance_id=87,.generation=UINT64_C(0xfedcba9876543210)};r.started_tick=77;}
 if(op==R4OS_DESKTOP_LINK_OP_RELEASE){r.phase=R4OS_DESKTOP_LINK_PHASE_CLEANED;r.cleanup_tick=99;}
 *header=(R4ServiceMessageHeader){.magic=R4OS_SERVICE_API_MAGIC,.version=R4OS_SERVICE_API_VERSION,.op=op};memcpy(out,&r,sizeof(r));return sizeof(r);
}
void sdk_link_tables(R4XStartR4Sys2*sys){sys->service_open=(uintptr_t)&link_open;sys->service_close=(uintptr_t)&link_close;sys->service_call=(uintptr_t)&link_call;link_activations=link_statuses=0;}
uint32_t sdk_link_activations(void){return link_activations;}
int sdk_link_c_case(void){
 R4App app;R4XStartR4Sys2 sys;R4XStartR4Net2 net;init_app(&app,&sys,&net);sdk_link_tables(&sys);
 R4DesktopLinkReply r;R4DesktopLinkRequest q;uint64_t intent[3]={1,2,3};const uint8_t path[]="C:\\TEMP\\SELF.LNK",bytes[]="R4S_FORMAT=1\nSCHEMA=R4LNK\nTARGET=C:\\TEMP\\SELF.R4X\n";
 if(r4_desktop_link_scope(&app,&r)||!r4_desktop_link_supported(&r))return 1;
 if(r4_desktop_link_binding(&r.request.token,(R4ProgramProcessHandle){.instance_id=42,.generation=123},intent,999,path,sizeof(path)-1,bytes,sizeof(bytes)-1,&q))return 2;
 if(r4_desktop_link_prepare(&app,&q,&r)||r.request.token.serial!=55)return 3;q=r.request;
 if(r4_desktop_link_activate(&app,&q,&r)!=R4OS_SERVICE_API_RESULT_TIMEOUT||link_activations!=1)return 4;
 if(r4_desktop_link_status(&app,&q,&r)||r.process.generation!=UINT64_C(0xfedcba9876543210)||link_activations!=1||link_statuses!=1)return 5;
 return 0;
}

/* Page memory belongs to the consumer. Deliberately use one-row pages in the
 * C check: transfer size must never become a total-inventory cap. */
static uint32_t inv_calls, inv_mode, inv_starts;
static uint64_t inv_revision=11;
void sdk_inventory_reset(uint32_t mode){inv_calls=inv_starts=0;inv_mode=mode;inv_revision=11;}
static int32_t inventory_page(R4ServiceInventoryCursor *cursor,R4ServiceInventoryRow *rows,uint32_t capacity){
    ++inv_calls;
    if(inv_mode==2||(inv_mode==1&&inv_calls==2)){++inv_revision;return R4OS_SERVICE_API_RESULT_RESTART;}
    uint64_t after=cursor->after_id;
    uint32_t n=(uint32_t)(300-after);if(n>capacity)n=capacity;if(n>8)n=8;
    for(uint32_t i=0;i<n;++i){memset(&rows[i],0,sizeof(rows[i]));rows[i].registration_id=after+i+1;rows[i].start_generation=91;rows[i].process.instance_id=77;rows[i].process.generation=8;}
    *cursor=(R4ServiceInventoryCursor){.revision=inv_revision,.after_id=after+n,.total=300,.flags=R4OS_SERVICE_INVENTORY_DYNAMIC|((after+n==300)?R4OS_SERVICE_INVENTORY_END:0)};
    return (int32_t)n;
}
static int32_t inventory_control(const R4ServiceControlRequest *request){
    if(request->registration_id!=300||request->start_generation!=91||request->process.instance_id!=77||request->process.generation!=8)return R4OS_SERVICE_API_RESULT_BUSY;
    ++inv_starts;return 0;
}
void sdk_inventory_tables(R4XStartR4Sys2 *sys){sys->service_inventory_page=(uintptr_t)&inventory_page;sys->service_control_bound=(uintptr_t)&inventory_control;}
int sdk_inventory_c_case(void){
    R4App app;R4XStartR4Sys2 sys;R4XStartR4Net2 net;init_app(&app,&sys,&net);sys.abi_version=35;
    sdk_inventory_tables(&sys);sdk_inventory_reset(0);R4Services services=r4_app_services(&app);
    if(!r4_services_inventory_available(&services))return 1;
    R4ServiceInventoryCursor cursor={0};R4ServiceInventoryRow row={0};uint64_t count=0;
    do {if(r4_services_inventory_page(&services,&cursor,&row,1)!=1||row.registration_id!=++count)return 2;}while(!(cursor.flags&R4OS_SERVICE_INVENTORY_END));
    if(count!=300||cursor.total!=300)return 3;
    R4ServiceControlRequest request=r4_service_control_request(&row,R4OS_SERVICE_CONTROL_START);
    if(r4_services_control_bound(&services,&request)!=0)return 4;
    --request.process.generation;if(r4_services_control_bound(&services,&request)!=R4OS_SERVICE_API_RESULT_BUSY||inv_starts!=1)return 5;
    sys.size=offsetof(R4XStartR4Sys2,service_inventory_page);
    if(r4_services_inventory_available(&services)||r4_services_inventory_page(&services,&cursor,&row,1)!=R4OS_ERR_NO_FN)return 6;
    return 0;
}

void sdk_service2_tables(R4XStartR4Sys2 *sys,R4XStartR4Net2 *net){
 R4XStartR4Sys2 old={0};R4XStartR4Net2 old_net={0};R4XStartR4Desk2 desk={0};R4XStartR4Dev2 dev={0};
 sdk_service_tables(&old,&old_net,&desk,&dev);clock_tick=100;
 *sys=(R4XStartR4Sys2){.magic=R4OS2_R4SYS_MAGIC,.abi_version=2,.size=sizeof(*sys),.monotonic_clock=(uintptr_t)&service2_clock};
 sys->service_open=old.service_open;
 sys->service_close=old.service_close;
 sys->service_call=old.service_call;
 sys->service_endpoint_register=old.service_endpoint_register;
 sys->service_endpoint_unregister=old.service_endpoint_unregister;
 sys->service_endpoint_wait=old.service_endpoint_wait;
 sys->service_endpoint_poll=old.service_endpoint_poll;
 sys->service_endpoint_recv=old.service_endpoint_recv;
 sys->service_endpoint_reply=old.service_endpoint_reply;
 sys->ticks=old.ticks;
 sys->task_yield=old.task_yield;
 sys->io_service_call=old.io_service_call;
 sys->io_status=old.io_status;
 sys->io_wait=old.io_wait;
 sys->io_close=old.io_close;
 *net=(R4XStartR4Net2){.magic=R4OS2_R4NET_MAGIC,.abi_version=2,.size=sizeof(*net),.ipc_poll=(uintptr_t)&service2_ipc_poll};
}
