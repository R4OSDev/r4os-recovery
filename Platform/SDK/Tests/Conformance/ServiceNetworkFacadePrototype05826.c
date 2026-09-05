#include <r4os/r4os.h>
#include <string.h>

enum ReplyMode { MODE_OK, MODE_WOULD_BLOCK, MODE_TIMEOUT, MODE_RESET, MODE_PEER_CLOSE, MODE_NO_SERVICE };
static enum ReplyMode reply_mode;
static uint32_t open_handles;
static int endpoint_registered;
static int endpoint_ready;

static int32_t fake_open(const uint8_t *name, R4ServiceInfo *out) {
    if (reply_mode == MODE_NO_SERVICE || strcmp((const char *)name, "STOPPED") == 0) return R4OS_SERVICE_API_RESULT_NOT_RUNNING;
    *out = (R4ServiceInfo){0};
    out->handle = strcmp((const char *)name, "DNSSVC") == 0 ? 101u : (strcmp((const char *)name, "TCPSVC") == 0 ? 102u : (strcmp((const char *)name, "UDPSVC") == 0 ? 103u : 104u));
    ++open_handles;
    return R4OS_SERVICE_API_RESULT_OK;
}

static int32_t fake_close(uint32_t handle) {
    if (handle < 101u || handle > 104u || open_handles == 0u) return R4OS_SERVICE_API_RESULT_BAD_HANDLE;
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
    (void)timeout;
    *header = (R4ServiceMessageHeader){0}; header->magic = R4OS_SERVICE_API_MAGIC; header->version = R4OS_SERVICE_API_VERSION; header->op = op; header->status = R4OS_SERVICE_API_RESULT_OK;
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
        if (op == R4OS_NET_SERVICE_OP_TCP_CLOSE_RESULT || op == R4OS_NET_SERVICE_OP_TCP_CLOSE_LISTEN_RESULT) result.lifecycle_cause = R4OS_NET_SERVICE_SOCKET_LIFECYCLE_LOCAL_CLOSE;
        if (sizeof(result) + payload_len > capacity) return R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL; memcpy(response, &result, sizeof(result)); memcpy(response + sizeof(result), payload, payload_len); return (int32_t)(sizeof(result) + payload_len);
    }
    if (handle == 103u) {
        R4NetServiceUdpResult result = {0}; result.magic = R4OS_NET_SERVICE_UDP_RESULT_MAGIC; result.version = R4OS_NET_SERVICE_UDP_RESULT_VERSION; result.action = op; result.flags = R4OS_NET_SERVICE_UDP_FLAG_OK | R4OS_NET_SERVICE_UDP_FLAG_HANDLE_VALID; result.handle = 601u; result.source_ip[0] = 10u; result.source_ip[2] = 2u; result.source_ip[3] = 3u; result.source_port = 7000u; result.dest_port = 8000u; result.lifecycle_cause = lifecycle(); result.service_status = service_status();
        const char *payload = (op == R4OS_NET_SERVICE_OP_UDP_RECV_RESULT && reply_mode == MODE_OK) ? "UDP" : ""; uint32_t payload_len = (uint32_t)strlen(payload);
        result.bytes = op == R4OS_NET_SERVICE_OP_UDP_SENDTO_RESULT ? request_len - 10u : payload_len;
        if (op == R4OS_NET_SERVICE_OP_UDP_CLOSE_RESULT) result.lifecycle_cause = R4OS_NET_SERVICE_SOCKET_LIFECYCLE_LOCAL_CLOSE;
        if (sizeof(result) + payload_len > capacity) return R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL; memcpy(response, &result, sizeof(result)); memcpy(response + sizeof(result), payload, payload_len); return (int32_t)(sizeof(result) + payload_len);
    }
    return R4OS_SERVICE_API_RESULT_BAD_HANDLE;
}

static int32_t fake_register(const uint8_t *name, uint32_t flags, R4ServiceInfo *out) { (void)name; (void)flags; if (endpoint_registered) return R4OS_SERVICE_API_RESULT_INVALID; endpoint_registered = 1; *out = (R4ServiceInfo){0}; out->handle = 201u; return 0; }
static int32_t fake_unregister(uint32_t handle) { if (!endpoint_registered || handle != 201u) return R4OS_SERVICE_API_RESULT_BAD_HANDLE; endpoint_registered = 0; return 0; }
static int32_t fake_wait(uint32_t handle, uint64_t timeout) { (void)timeout; return endpoint_registered && handle == 201u ? (endpoint_ready ? 1 : 0) : R4OS_SERVICE_API_RESULT_BAD_HANDLE; }
static int32_t fake_recv(uint32_t handle, R4ServiceMessageHeader *header, uint8_t *out, uint32_t capacity) { if (!endpoint_registered || handle != 201u) return R4OS_SERVICE_API_RESULT_BAD_HANDLE; if (!endpoint_ready) { *header = (R4ServiceMessageHeader){0}; return 0; } if (capacity < sizeof(uint32_t)) return R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL; *header = (R4ServiceMessageHeader){0}; header->magic = R4OS_SERVICE_API_MAGIC; header->request_id = 88u; *(uint32_t *)(void *)out = 42u; endpoint_ready = 0; return (int32_t)sizeof(uint32_t); }
static int32_t fake_reply(uint32_t handle, uint32_t request_id, int32_t status, const uint8_t *payload, uint32_t payload_len) { (void)payload; (void)payload_len; return handle == 201u && request_id == 88u && status == 0 ? 0 : R4OS_SERVICE_API_RESULT_INVALID; }
static int32_t fake_tcp_marker(uint8_t a, uint8_t b, uint8_t c, uint8_t d, uint16_t port) { (void)a; (void)b; (void)c; (void)d; (void)port; return -1; }

static R4Timeout poll_timeout(void) { R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_POLL; return value; }
static R4Timeout forever_timeout(void) { R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_FOREVER; return value; }

static void init_app(R4App *app, R4XStartR4Sys *sys, R4XStartR4Net *net) {
    *sys = (R4XStartR4Sys){0}; sys->service_open = (uintptr_t)&fake_open; sys->service_close = (uintptr_t)&fake_close; sys->service_call = (uintptr_t)&fake_call; sys->service_endpoint_register = (uintptr_t)&fake_register; sys->service_endpoint_unregister = (uintptr_t)&fake_unregister; sys->service_endpoint_wait = (uintptr_t)&fake_wait; sys->service_endpoint_recv = (uintptr_t)&fake_recv; sys->service_endpoint_reply = (uintptr_t)&fake_reply;
    *net = (R4XStartR4Net){0}; net->tcp_connect = (uintptr_t)&fake_tcp_marker;
    *app = (R4App){0}; app->system.table = sys; app->network.table = net;
}

int main(void) {
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
    uint8_t buffer[8] = {0}; if (r4_tcp_socket_read(&socket, buffer, sizeof(buffer), forever_timeout()).bytes != 2u || memcmp(buffer, "OK", 2u) != 0) return 10;
    reply_mode = MODE_WOULD_BLOCK; if (r4_tcp_socket_read(&socket, buffer, sizeof(buffer), poll_timeout()).kind != R4_NET_RESULT_WOULD_BLOCK) return 11;
    reply_mode = MODE_PEER_CLOSE; if (r4_tcp_socket_read(&socket, buffer, sizeof(buffer), forever_timeout()).kind != R4_NET_RESULT_PEER_CLOSED) return 12;
    reply_mode = MODE_OK; R4UdpSocket udp; if (r4_network_bind_udp(&network, 8000u, forever_timeout(), &udp).kind != R4_NET_RESULT_OK || r4_udp_socket_send_to(&udp, remote, (const uint8_t *)"UDP", 3u, forever_timeout()).bytes != 3u) return 13;
    R4Datagram datagram; if (r4_udp_socket_receive_from(&udp, buffer, sizeof(buffer), forever_timeout(), &datagram).kind != R4_NET_RESULT_OK || datagram.bytes != 3u) return 14;
    reply_mode = MODE_TIMEOUT; resolver = r4_network_resolver(network); if (r4_resolver_resolve_a(&resolver, (const uint8_t *)"r4os.local", 10u, 0, forever_timeout(), &address).kind != R4_NET_RESULT_TIMED_OUT) return 15;
    reply_mode = MODE_NO_SERVICE; if (r4_network_connect_tcp(&network, remote, forever_timeout(), &socket).kind != R4_NET_RESULT_NO_SERVICE || open_handles != 0u) return 16;
    return 0;
}
