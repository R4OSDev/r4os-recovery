#include <r4os/r4os.h>
#include <string.h>

enum ReplyMode { MODE_OK, MODE_WOULD_BLOCK, MODE_TIMEOUT, MODE_RESET, MODE_PEER_CLOSE, MODE_NO_SERVICE, MODE_SHORT };
static enum ReplyMode reply_mode;
static uint32_t open_handles;
static int endpoint_registered;
static int endpoint_ready;
static uint32_t clock_rate=1000, clock_mode, calendar_calls, observed_calls;
static uint64_t observed_timeout;
static void fake_calendar(R4TimeState *out) { ++calendar_calls; *out=(R4TimeState){.monotonic_hz=7}; }
static int32_t fake_monotonic(R4MonotonicClockInfo *out) {
    *out=(R4MonotonicClockInfo){.flags=clock_mode==3?0:R4OS_MONOTONIC_CLOCK_FLAG_VALID,
        .frequency_hz=clock_mode==4?1000:R4OS_MONOTONIC_CLOCK_FREQUENCY_HZ,
        .event_requested_hz=clock_mode==5?0:clock_rate,.event_effective_hz=clock_rate+7};
    return clock_mode==1?0:clock_mode==2?-13:1;
}


static uint32_t power_mode,power_calls;static uint64_t power_revision=UINT64_C(0x123456781234abcd);
static R4PowerProfileRequest power_last;static const uint64_t power_generation=UINT64_C(0x12345678abcd4321);
static int32_t power_call(uint16_t op,const uint8_t *in,uint32_t len,R4ServiceMessageHeader *header,uint8_t *response,uint32_t capacity){
    ++power_calls;if(len!=sizeof(power_last))return R4OS_SERVICE_API_RESULT_INVALID;memcpy(&power_last,in,len);
    if(power_mode==3){header->status=R4OS_SERVICE_API_RESULT_TIMEOUT;return 0;}
    if(op!=R4OS_POWER_PROFILE_OP_STATUS&&op!=R4OS_POWER_PROFILE_OP_CPU){if(power_last.expected_service_generation!=power_generation||power_last.expected_revision!=power_revision)return -99;++power_revision;}
    if(op==R4OS_POWER_PROFILE_OP_CPU){R4PowerCpuProfileInfo value={.version=1,.size=sizeof(value),.cpu_index=power_last.cpu_index,.service_generation=power_mode==1?power_generation+1:power_generation};if(capacity<sizeof(value))return -99;memcpy(response,&value,sizeof(value));return sizeof(value);}
    R4PowerProfileInfo value={.version=1,.size=sizeof(value),.state=R4OS_POWER_PROFILE_STATE_UNSUPPORTED,.selected_profile=power_last.profile,.configured_cpus=4,.online_cpus=4,.service_instance_id=55,.service_generation=power_mode==1?power_generation+1:power_generation,.revision=power_revision};
    if(capacity<sizeof(value))return -99;memcpy(response,&value,sizeof(value));return sizeof(value)-(power_mode==2?1:0);
}
static int32_t fake_open(const uint8_t *name, R4ServiceInfo *out) {
    if (reply_mode == MODE_NO_SERVICE || strcmp((const char *)name, "STOPPED") == 0) return R4OS_SERVICE_API_RESULT_NOT_RUNNING;
    if(strcmp((const char *)name,"POWERSVC")==0){*out=(R4ServiceInfo){.handle=105,.instance_id=power_mode==5?56:55};++open_handles;return 0;}
    *out = (R4ServiceInfo){0};
    out->handle = strcmp((const char *)name, "DNSSVC") == 0 ? 101u : (strcmp((const char *)name, "TCPSVC") == 0 ? 102u : (strcmp((const char *)name, "UDPSVC") == 0 ? 103u : 104u));
    ++open_handles;
    return R4OS_SERVICE_API_RESULT_OK;
}

static int32_t fake_close(uint32_t handle) {
    if (handle < 101u || handle > 105u || open_handles == 0u) return R4OS_SERVICE_API_RESULT_BAD_HANDLE;
    --open_handles;
    return R4OS_SERVICE_API_RESULT_OK;
}

static uint32_t lifecycle(void) {
    if (reply_mode == MODE_WOULD_BLOCK) return R4OS_NET_SERVICE_SOCKET_LIFECYCLE_WOULD_BLOCK;
    if (reply_mode == MODE_TIMEOUT) return R4OS_NET_SERVICE_SOCKET_LIFECYCLE_TIMEOUT;
    if (reply_mode == MODE_RESET) return R4OS_NET_SERVICE_SOCKET_LIFECYCLE_RESET;
    if (reply_mode == MODE_PEER_CLOSE) return R4OS_NET_SERVICE_SOCKET_LIFECYCLE_PEER_GONE;
    return R4OS_NET_SERVICE_SOCKET_LIFECYCLE_ACTIVE;
}

static uint32_t service_status(void) {
    if (reply_mode == MODE_WOULD_BLOCK) return R4OS_NET_SERVICE_STATUS_WOULD_BLOCK;
    if (reply_mode == MODE_TIMEOUT) return R4OS_NET_SERVICE_STATUS_TIMEOUT;
    return R4OS_NET_SERVICE_STATUS_OK;
}

static int32_t fake_call(uint32_t handle, uint16_t op, const uint8_t *request, uint32_t request_len, R4ServiceMessageHeader *header, uint8_t *response, uint32_t capacity, uint64_t timeout) {
    /* Decode the optional TCP suffix independently of the SDK encoder. */
    if (handle == 102u && request_len >= sizeof(R4ServiceDeadlineFooter)) {
        R4ServiceDeadlineFooter footer; memcpy(&footer, request + request_len - sizeof(footer), sizeof(footer));
        if (footer.magic == R4OS_SERVICE_DEADLINE_FOOTER_MAGIC && footer.version == R4OS_SERVICE_DEADLINE_FOOTER_VERSION && footer.size == sizeof(footer) && !footer.reserved0 && footer.payload_len == request_len - sizeof(footer)) request_len = footer.payload_len;
    }
    observed_timeout=timeout; ++observed_calls;
    *header = (R4ServiceMessageHeader){0}; header->magic = R4OS_SERVICE_API_MAGIC; header->version = R4OS_SERVICE_API_VERSION; header->op = op; header->status = R4OS_SERVICE_API_RESULT_OK;
    if(handle==105u)return power_call(op,request,request_len,header,response,capacity);
    if (handle == 104u) {
        if (op == 7u) { if (request_len > capacity) return R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL; memcpy(response, request, request_len); return (int32_t)request_len; }
        header->status = R4OS_SERVICE_API_RESULT_INVALID; return 0;
    }
    if (handle == 101u) {
        R4NetServiceDnsResult result = {0}; result.magic = R4OS_NET_SERVICE_DNS_RESULT_MAGIC; result.version = R4OS_NET_SERVICE_DNS_RESULT_VERSION; result.result = R4OS_DNS_RESULT_OK; result.flags = R4OS_NET_SERVICE_DNS_FLAG_OK; result.answer[0] = 10u; result.answer[2] = 2u; result.answer[3] = 15u;
        if (reply_mode == MODE_TIMEOUT) result.result = R4OS_DNS_RESULT_TIMEOUT; else if (reply_mode == MODE_WOULD_BLOCK) result.result = R4OS_DNS_RESULT_NXDOMAIN;
        if (capacity < sizeof(result)) return R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL; memcpy(response, &result, sizeof(result)); return (int32_t)sizeof(result);
    }
    if (handle == 102u) {
        R4NetServiceTcpResult result = {0}; result.magic = R4OS_NET_SERVICE_TCP_RESULT_MAGIC; result.version = R4OS_NET_SERVICE_TCP_RESULT_VERSION; result.action = op; result.flags = R4OS_NET_SERVICE_TCP_FLAG_OK | R4OS_NET_SERVICE_TCP_FLAG_HANDLE_VALID; result.handle = 501u; result.remote_ip[0] = 10u; result.remote_ip[2] = 2u; result.remote_ip[3] = 2u; result.remote_port = 1234u; result.lifecycle_cause = lifecycle(); result.service_status = service_status();
        const char *payload = (op == R4OS_NET_SERVICE_OP_TCP_READ_RESULT && reply_mode == MODE_OK) ? "OK" : ""; uint32_t payload_len = (uint32_t)strlen(payload);
        result.bytes = op == R4OS_NET_SERVICE_OP_TCP_WRITE_RESULT ? request_len - 4u : payload_len;
        if(reply_mode==MODE_SHORT&&op==R4OS_NET_SERVICE_OP_TCP_WRITE_RESULT&&result.bytes>2)result.bytes=2;
        result.pending_rx=op==R4OS_NET_SERVICE_OP_TCP_POLL_RESULT?4:0;
        if(payload_len)result.flags|=R4OS_NET_SERVICE_TCP_FLAG_DATA;
        if (op == R4OS_NET_SERVICE_OP_TCP_CLOSE_RESULT || op == R4OS_NET_SERVICE_OP_TCP_CLOSE_LISTEN_RESULT) result.lifecycle_cause = R4OS_NET_SERVICE_SOCKET_LIFECYCLE_LOCAL_CLOSE;
        if (sizeof(result) + payload_len > capacity) return R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL; memcpy(response, &result, sizeof(result)); memcpy(response + sizeof(result), payload, payload_len); return (int32_t)(sizeof(result) + payload_len);
    }
    if (handle == 103u) {
        R4NetServiceUdpResult result = {0}; result.magic = R4OS_NET_SERVICE_UDP_RESULT_MAGIC; result.version = R4OS_NET_SERVICE_UDP_RESULT_VERSION; result.action = op; result.flags = R4OS_NET_SERVICE_UDP_FLAG_OK | R4OS_NET_SERVICE_UDP_FLAG_HANDLE_VALID; result.handle = 601u; result.source_ip[0] = 10u; result.source_ip[2] = 2u; result.source_ip[3] = 3u; result.source_port = 7000u; result.dest_port = 8000u; result.lifecycle_cause = lifecycle(); result.service_status = service_status();
        const char *payload = (op == R4OS_NET_SERVICE_OP_UDP_RECV_RESULT && reply_mode == MODE_OK) ? "UDP" : ""; uint32_t payload_len = (uint32_t)strlen(payload);
        result.bytes = op == R4OS_NET_SERVICE_OP_UDP_SENDTO_RESULT ? request_len - 10u : payload_len;
        if(payload_len)result.flags|=R4OS_NET_SERVICE_UDP_FLAG_DATA;
        if (op == R4OS_NET_SERVICE_OP_UDP_CLOSE_RESULT) result.lifecycle_cause = R4OS_NET_SERVICE_SOCKET_LIFECYCLE_LOCAL_CLOSE;
        if (sizeof(result) + payload_len > capacity) return R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL; memcpy(response, &result, sizeof(result)); memcpy(response + sizeof(result), payload, payload_len); return (int32_t)(sizeof(result) + payload_len);
    }
    return R4OS_SERVICE_API_RESULT_BAD_HANDLE;
}

static int32_t fake_register(const uint8_t *name, uint32_t flags, R4ServiceInfo *out) { (void)name; (void)flags; if (endpoint_registered) return R4OS_SERVICE_API_RESULT_INVALID; endpoint_registered = 1; *out = (R4ServiceInfo){0}; out->handle = 201u; return 0; }
static int32_t fake_unregister(uint32_t handle) { if (!endpoint_registered || handle != 201u) return R4OS_SERVICE_API_RESULT_BAD_HANDLE; endpoint_registered = 0; return 0; }
static int32_t fake_wait(uint32_t handle, uint64_t timeout) { observed_timeout=timeout; return endpoint_registered && handle == 201u ? (endpoint_ready ? 1 : 0) : R4OS_SERVICE_API_RESULT_BAD_HANDLE; }
static int32_t fake_recv(uint32_t handle, R4ServiceMessageHeader *header, uint8_t *out, uint32_t capacity) { if (!endpoint_registered || handle != 201u) return R4OS_SERVICE_API_RESULT_BAD_HANDLE; if (!endpoint_ready) { *header = (R4ServiceMessageHeader){0}; return 0; } if (capacity < sizeof(uint32_t)) return R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL; *header = (R4ServiceMessageHeader){0}; header->magic = R4OS_SERVICE_API_MAGIC; header->request_id = 88u; *(uint32_t *)(void *)out = 42u; endpoint_ready = 0; return (int32_t)sizeof(uint32_t); }
static int32_t fake_reply(uint32_t handle, uint32_t request_id, int32_t status, const uint8_t *payload, uint32_t payload_len) { (void)payload; (void)payload_len; return handle == 201u && request_id == 88u && status == 0 ? 0 : R4OS_SERVICE_API_RESULT_INVALID; }
static int32_t fake_tcp_marker(uint8_t a, uint8_t b, uint8_t c, uint8_t d, uint16_t port) { (void)a; (void)b; (void)c; (void)d; (void)port; return -1; }

static R4Timeout poll_timeout(void) { R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_POLL; return value; }
static R4Timeout forever_timeout(void) { R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_FOREVER; return value; }

static uint64_t network_fixture_ticks(void) { return 100u; }
static void init_app(R4App *app, R4XStartR4Sys *sys, R4XStartR4Net *net) {
    *sys = (R4XStartR4Sys){.magic=R4XSTART_R4SYS_MAGIC,.abi_version=R4XSTART_R4SYS_VERSION,.size=sizeof(*sys)}; sys->ticks=(uintptr_t)&network_fixture_ticks; sys->monotonic_clock=(uintptr_t)&fake_monotonic; sys->time_state=(uintptr_t)&fake_calendar; sys->service_open = (uintptr_t)&fake_open; sys->service_close = (uintptr_t)&fake_close; sys->service_call = (uintptr_t)&fake_call; sys->service_endpoint_register = (uintptr_t)&fake_register; sys->service_endpoint_unregister = (uintptr_t)&fake_unregister; sys->service_endpoint_wait = (uintptr_t)&fake_wait; sys->service_endpoint_recv = (uintptr_t)&fake_recv; sys->service_endpoint_reply = (uintptr_t)&fake_reply;
    *net = (R4XStartR4Net){.magic=R4XSTART_R4NET_MAGIC,.abi_version=R4XSTART_R4NET_VERSION,.size=sizeof(*net)}; net->tcp_connect = (uintptr_t)&fake_tcp_marker;
    *app = (R4App){0}; app->system.table = sys; app->network.table = net;
}

static int power_checks(void){
    R4App app;R4XStartR4Sys sys;R4XStartR4Net net;init_app(&app,&sys,&net);reply_mode=MODE_OK;power_mode=0;open_handles=0;power_calls=0;
    R4PowerProfiles client={0};R4PowerProfileInfo out={.revision=71};R4Timeout timeout=poll_timeout();
    if(r4_power_profiles_open(&app,&client,timeout)!=0||client.info.service_generation!=power_generation||open_handles)return 1;
    uint32_t calls=power_calls;if(r4_power_profiles_select(&client,99,0,&out,timeout)!=R4OS_SERVICE_API_RESULT_INVALID||calls!=power_calls||out.revision!=71)return 2;
    if(r4_power_profiles_select(&client,R4OS_POWER_PROFILE_PERFORMANCE,0,&out,timeout)!=0||out.state!=R4OS_POWER_PROFILE_STATE_UNSUPPORTED||power_last.expected_service_generation!=power_generation||open_handles)return 3;
    R4PowerProfileInfo saved=out;power_mode=3;calls=power_calls;
    if(r4_power_profiles_quiesce(&client,&out,timeout)!=R4OS_SERVICE_API_RESULT_TIMEOUT||calls+1!=power_calls||memcmp(&out,&saved,sizeof(out))||open_handles)return 4;
    power_mode=1;if(r4_power_profiles_status(&client,&out,timeout)!=R4OS_SERVICE_API_RESULT_INVALID||memcmp(&out,&saved,sizeof(out))||memcmp(&client.info,&saved,sizeof(saved)))return 5;
    power_mode=2;if(r4_power_profiles_status(&client,&out,timeout)!=R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL||memcmp(&out,&saved,sizeof(out)))return 6;
    power_mode=5;calls=power_calls;if(r4_power_profiles_resume(&client,&out,timeout)!=R4OS_SERVICE_API_RESULT_NOT_RUNNING||calls!=power_calls||open_handles)return 7;
    power_mode=0;R4PowerCpuProfileInfo cpu={0};if(r4_power_profiles_cpu(&client,3,&cpu,timeout)!=0||cpu.cpu_index!=3||cpu.service_generation!=power_generation||power_last.expected_revision||open_handles)return 8;
    power_mode=1;R4PowerCpuProfileInfo old=cpu;if(r4_power_profiles_cpu(&client,3,&cpu,timeout)!=R4OS_SERVICE_API_RESULT_INVALID||memcmp(&cpu,&old,sizeof(old)))return 9;
    power_mode=0;if(r4_power_profiles_cpu(&client,4,&cpu,timeout)!=R4OS_SERVICE_API_RESULT_INVALID||open_handles)return 10;return 0;
}
static int32_t fake_power_transition(uint32_t action,uint64_t budget){return action==R4OS_POWER_TRANSITION_ACTION_POWEROFF&&budget==UINT64_C(0x12345678abcd4321)?R4OS_POWER_TRANSITION_ERROR_RETAINED:-99;}
static int system_power_checks(void){
    R4App app;R4XStartR4Sys table;R4XStartR4Net net;init_app(&app,&table,&net);table.system_power_transition=(uintptr_t)&fake_power_transition;
    for(uint32_t size=1280;size<1288;size++){table.size=size;if(r4sys_system_power_transition(&app.system,R4OS_POWER_TRANSITION_ACTION_POWEROFF,UINT64_C(0x12345678abcd4321))!=R4OS_ERR_NO_FN)return 1;}
    table.size=1288;if(r4sys_system_power_transition(&app.system,R4OS_POWER_TRANSITION_ACTION_POWEROFF,UINT64_C(0x12345678abcd4321))!=R4OS_POWER_TRANSITION_ERROR_RETAINED)return 2;
    if(r4sys_system_power_transition(&app.system,3,0)!=R4OS_POWER_TRANSITION_ERROR_INVALID)return 3;
    table.system_power_transition=0;if(r4sys_system_power_transition(&app.system,R4OS_POWER_TRANSITION_ACTION_POWEROFF,0)!=R4OS_ERR_NO_FN)return 4;return 0;
}
static int calendar_free_timeouts(void) {
    R4App app; R4XStartR4Sys sys; R4XStartR4Net net; init_app(&app,&sys,&net);
    reply_mode=MODE_OK; clock_mode=0; clock_rate=1000; calendar_calls=0;
    R4Services services=r4_app_services(&app); R4ServiceConnection connection;
    uint32_t value=123, response=0;
    if(r4_services_open(&services,"EXAMPLE",&connection)!=0) return 1;
    R4Timeout finite=r4_timeout_finite((R4Duration){17000001});
    if(r4_service_connection_call(&connection,7,&value,4,&response,4,finite).kind!=R4_SERVICE_CALL_RESPONSE || observed_timeout!=18) return 2;
    clock_rate=250;
    if(r4_service_connection_call(&connection,7,&value,4,&response,4,finite).kind!=R4_SERVICE_CALL_RESPONSE || observed_timeout!=5) return 3;
    for(clock_mode=1;clock_mode<=5;++clock_mode) {
        uint32_t before=observed_calls;
        R4ServiceCallResult result=r4_service_connection_call(&connection,7,&value,4,&response,4,finite);
        if(result.kind!=R4_SERVICE_CALL_FAILED || result.raw_code!=R4OS_SERVICE_API_RESULT_INVALID || before!=observed_calls) return 4;
    }
    sys.monotonic_clock=0;
    if(r4_service_connection_call(&connection,7,&value,4,&response,4,finite).raw_code!=R4OS_SERVICE_API_RESULT_INVALID) return 5;
    if(r4_service_connection_call(&connection,7,&value,4,&response,4,poll_timeout()).kind!=R4_SERVICE_CALL_RESPONSE || observed_timeout!=0) return 6;
    if(r4_service_connection_call(&connection,7,&value,4,&response,4,forever_timeout()).kind!=R4_SERVICE_CALL_RESPONSE || observed_timeout!=R4OS_IO_WAIT_FOREVER) return 7;
    if(r4_service_connection_close(&connection)!=0) return 8;
    clock_mode=0; sys.monotonic_clock=(uintptr_t)&fake_monotonic;
    R4ServiceEndpoint endpoint;
    if(r4_services_register(&services,"EXAMPLE",0,&endpoint)!=0) return 9;
    if(r4_service_endpoint_wait(&endpoint,finite).kind!=R4_ENDPOINT_WAIT_TIMED_OUT || observed_timeout!=5) return 10;
    if(r4_service_endpoint_unregister(&endpoint)!=0 || calendar_calls!=0 || open_handles!=0) return 11;
    clock_rate=1000;
    return 0;
}

static int service_network_checks(void) {
    if(calendar_free_timeouts()!=0)return 20;
    R4App app; R4XStartR4Sys sys; R4XStartR4Net net; init_app(&app, &sys, &net); reply_mode = MODE_OK;
    R4Services services = r4_app_services(&app); R4ServiceConnection connection; uint32_t request = 123u, response = 0u;
    if (!r4_services_available(&services) || r4_services_open(&services, "EXAMPLE", &connection) != 0) return 1;
    if (r4_service_connection_call_struct(&connection, 7u, &request, sizeof(request), &response, sizeof(response), forever_timeout()).kind != R4_SERVICE_CALL_RESPONSE || response != request) return 2;
    if (r4_service_connection_call(&connection, 999u, 0, 0u, 0, 0u, poll_timeout()).kind != R4_SERVICE_CALL_REMOTE_FAILURE) return 3;
    if (r4_service_connection_close(&connection) != 0 || r4_service_connection_close(&connection) != R4OS_ERR_CLOSED) return 4;
    R4ServiceEndpoint endpoint; if (r4_services_register(&services, "EXAMPLE", 0u, &endpoint) != 0 || r4_service_endpoint_wait(&endpoint, poll_timeout()).kind != R4_ENDPOINT_WAIT_TIMED_OUT) return 5;
    endpoint_ready = 1; if (r4_service_endpoint_wait(&endpoint, forever_timeout()).kind != R4_ENDPOINT_WAIT_READY) return 6;
    uint32_t endpoint_payload = 0u; R4EndpointReceiveResult received = r4_service_endpoint_recv(&endpoint, &endpoint_payload, sizeof(endpoint_payload)); if (received.kind != R4_ENDPOINT_RECEIVE_MESSAGE || endpoint_payload != 42u || r4_service_endpoint_reply(&endpoint, received.header.request_id, 0, 0, 0u) != 0 || r4_service_endpoint_unregister(&endpoint) != 0) return 7;

    R4Network network = r4_app_network(&app); R4Resolver resolver = r4_network_resolver(network); R4Ipv4Address address;
    if (!r4_network_available(&network) || r4_resolver_resolve_a(&resolver, (const uint8_t *)"r4os.local", 10u, 0, forever_timeout(), &address).kind != R4_NET_RESULT_OK || address.octets[3] != 15u) return 8;
    R4SocketAddress remote = {r4_ipv4(10u, 0u, 2u, 2u), 1234u, 0u}; R4TcpSocket socket;
    if (r4_network_connect_tcp(&network, remote, forever_timeout(), &socket).kind != R4_NET_RESULT_OK || r4_tcp_socket_write(&socket, (const uint8_t *)"GET", 3u, forever_timeout()).bytes != 3u) return 9;
    R4TcpPollResult ready=r4_tcp_socket_readiness(&socket,forever_timeout()); if(!ready.available||ready.readiness.pending_rx!=4||!ready.readiness.readable||ready.result.bytes!=0)return 17;
    uint8_t buffer[8] = {0}; if (r4_tcp_socket_read(&socket, buffer, sizeof(buffer), forever_timeout()).bytes != 2u || memcmp(buffer, "OK", 2u) != 0) return 10;
    reply_mode = MODE_WOULD_BLOCK; if (r4_tcp_socket_read(&socket, buffer, sizeof(buffer), poll_timeout()).kind != R4_NET_RESULT_WOULD_BLOCK) return 11;
    reply_mode = MODE_PEER_CLOSE; if (r4_tcp_socket_read(&socket, buffer, sizeof(buffer), forever_timeout()).kind != R4_NET_RESULT_PEER_CLOSED) return 12;
    reply_mode = MODE_OK; R4UdpSocket udp; if (r4_network_bind_udp(&network, 8000u, forever_timeout(), &udp).kind != R4_NET_RESULT_OK || r4_udp_socket_send_to(&udp, remote, (const uint8_t *)"UDP", 3u, forever_timeout()).bytes != 3u) return 13;
    R4Datagram datagram; if (r4_udp_socket_receive_from(&udp, buffer, sizeof(buffer), forever_timeout(), &datagram).kind != R4_NET_RESULT_OK || datagram.bytes != 3u) return 14;
    reply_mode = MODE_TIMEOUT; resolver = r4_network_resolver(network); if (r4_resolver_resolve_a(&resolver, (const uint8_t *)"r4os.local", 10u, 0, forever_timeout(), &address).kind != R4_NET_RESULT_TIMED_OUT) return 15;
    reply_mode = MODE_NO_SERVICE; if (r4_network_connect_tcp(&network, remote, forever_timeout(), &socket).kind != R4_NET_RESULT_NO_SERVICE || open_handles != 0u) return 16;
    return 0;
}
int main(void) {
    if(system_power_checks()!=0)return 101;
    if(power_checks()!=0)return 100;
    return service_network_checks();
}
