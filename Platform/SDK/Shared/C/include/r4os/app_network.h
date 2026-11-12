#ifndef R4OS_APP_NETWORK_H
#define R4OS_APP_NETWORK_H

#include "app_services.h"
#include "net_bridge.h"

typedef struct R4Ipv4Address { uint8_t octets[4]; } R4Ipv4Address;
typedef struct R4SocketAddress { R4Ipv4Address address; uint16_t port; uint16_t reserved; } R4SocketAddress;
typedef struct R4Network { R4App *app; } R4Network;
typedef struct R4Resolver { R4Network network; } R4Resolver;

/* DNSSVC/TCPSVC/UDPSVC wire replies come from the Contract projection.
 * Public callers use the facade objects below. */

typedef struct R4TcpSocket {
    R4Network network;
    uint32_t raw;
    uint8_t owned;
    uint8_t reserved[3];
    R4SocketAddress remote;
} R4TcpSocket;

typedef struct R4TcpListener {
    R4Network network;
    uint16_t port;
    uint8_t owned;
    uint8_t reserved;
} R4TcpListener;

typedef struct R4UdpSocket {
    R4Network network;
    uint32_t raw;
    uint16_t local_port;
    uint8_t owned;
    uint8_t reserved;
} R4UdpSocket;

typedef struct R4Datagram {
    R4SocketAddress source;
    R4SocketAddress destination;
    uint32_t bytes;
} R4Datagram;

typedef enum R4NetResultKind {
    R4_NET_RESULT_OK = 0,
    R4_NET_RESULT_WOULD_BLOCK = 1,
    R4_NET_RESULT_TIMED_OUT = 2,
    R4_NET_RESULT_RESET = 3,
    R4_NET_RESULT_PEER_CLOSED = 4,
    R4_NET_RESULT_CLOSED = 5,
    R4_NET_RESULT_NOT_FOUND = 6,
    R4_NET_RESULT_NO_SERVICE = 7,
    R4_NET_RESULT_FAILED = 8,
    /* No validated operation reply: bytes is unavailable, not confirmed zero.
     * A read/write may already have taken effect. Never retry automatically. */
    R4_NET_RESULT_OUTCOME_UNKNOWN = 9
} R4NetResultKind;

typedef struct R4NetResult {
    R4NetResultKind kind;
    int32_t raw_code;
    uint32_t bytes;
} R4NetResult;

/* A poll transfers no bytes. Readiness is available only after a validated
 * structured provider reply, including terminal replies. This does not
 * acknowledge disposal of the still-owned local frontend handle. */
typedef struct R4TcpPollResult {
    R4NetResult result;
    R4SdkTcpReadiness readiness;
    uint32_t available;
} R4TcpPollResult;

/* A positive close receipt releases the TCPSVC frontend handle. A pending
 * network shutdown is still in progress and is not a disposal ACK. */
typedef struct R4TcpCloseReceipt {
    R4NetResult outcome;
    uint16_t operation;
    uint16_t action;
    uint32_t ack;
    uint32_t lifecycle_cause;
    uint32_t service_status;
    uint32_t accepted;
    uint32_t pending_shutdown;
    uint32_t frontend_released;
    uint32_t submitted;
} R4TcpCloseReceipt;

typedef struct R4TcpServiceCall {
    R4ServiceCallResult call;
    uint32_t submitted;
} R4TcpServiceCall;

static inline R4Ipv4Address r4_ipv4(uint8_t a, uint8_t b, uint8_t c, uint8_t d) { R4Ipv4Address value = {{a, b, c, d}}; return value; }
static inline int r4_ipv4_is_unspecified(R4Ipv4Address value) { return value.octets[0] == 0u && value.octets[1] == 0u && value.octets[2] == 0u && value.octets[3] == 0u; }
static inline R4Network r4_app_network(R4App *app) { R4Network value = {app}; return value; }
static inline R4Resolver r4_network_resolver(R4Network network) { R4Resolver value = {network}; return value; }
static inline int r4_network_available(const R4Network *network) { R4Services services = r4_app_services(network != 0 ? network->app : 0); return network != 0 && network->app != 0 && R4NET_HAS(&network->app->network, tcp_connect) && r4_services_available(&services); }
static inline int r4_tcp_socket_valid(const R4TcpSocket *socket) { return socket != 0 && socket->network.app != 0 && socket->raw != 0u; }
static inline int r4_tcp_listener_valid(const R4TcpListener *listener) { return listener != 0 && listener->network.app != 0 && listener->port != 0u; }
static inline int r4_udp_socket_valid(const R4UdpSocket *socket) { return socket != 0 && socket->network.app != 0 && socket->raw != 0u; }

static inline R4NetResult r4_net_result(R4NetResultKind kind, int32_t raw, uint32_t bytes) { R4NetResult value = {kind, raw, bytes}; return value; }
static inline void r4_net_write_u16(uint8_t *out, uint16_t value) { out[0] = (uint8_t)value; out[1] = (uint8_t)(value >> 8); }
static inline void r4_net_write_u32(uint8_t *out, uint32_t value) { out[0] = (uint8_t)value; out[1] = (uint8_t)(value >> 8); out[2] = (uint8_t)(value >> 16); out[3] = (uint8_t)(value >> 24); }

static inline R4ServiceCallResult r4_network_service_call(R4Network *network, const char *service_name, uint16_t op, const void *request, uint32_t request_len, void *response, uint32_t response_capacity, R4Timeout timeout) {
    R4ServiceCallResult failed = {R4_SERVICE_CALL_FAILED, R4OS_ERR_NO_GROUP, 0u, {0}};
    if (!r4_network_available(network)) return failed;
    R4Services services = r4_app_services(network->app); R4ServiceConnection connection;
    int32_t raw = r4_services_open(&services, service_name, &connection);
    if (raw != R4OS_SERVICE_API_RESULT_OK) { failed.raw_code = raw; return failed; }
    R4ServiceCallResult result = r4_service_connection_call(&connection, op, request, request_len, response, response_capacity, timeout);
    (void)r4_service_connection_close(&connection);
    if (result.kind == R4_SERVICE_CALL_RESPONSE && (result.bytes > response_capacity ||
        result.header.magic != R4OS_SERVICE_API_MAGIC || result.header.version != R4OS_SERVICE_API_VERSION || result.header.op != op)) {
        result.kind = R4_SERVICE_CALL_FAILED; result.raw_code = R4OS_SERVICE_API_RESULT_INVALID; result.bytes = 0u;
    }
    return result;
}

static inline R4NetResult r4_net_from_call(R4ServiceCallResult call) {
    if (call.kind == R4_SERVICE_CALL_TIMED_OUT) return r4_net_result(R4_NET_RESULT_TIMED_OUT, R4OS_SERVICE_API_RESULT_TIMEOUT, 0u);
    if (call.kind == R4_SERVICE_CALL_RESPONSE) return r4_net_result(R4_NET_RESULT_OK, R4OS_OK, call.bytes);
    if (call.raw_code == R4OS_SERVICE_API_RESULT_NOT_FOUND || call.raw_code == R4OS_SERVICE_API_RESULT_NO_ENDPOINT || call.raw_code == R4OS_SERVICE_API_RESULT_NOT_RUNNING) return r4_net_result(R4_NET_RESULT_NO_SERVICE, call.raw_code, 0u);
    return r4_net_result(R4_NET_RESULT_FAILED, call.raw_code, 0u);
}

static inline int r4_net_progress_known(R4NetResult result) { return result.kind != R4_NET_RESULT_OUTCOME_UNKNOWN; }

static inline R4NetResult r4_tcp_reply_unknown(void) { return r4_net_result(R4_NET_RESULT_OUTCOME_UNKNOWN, R4OS_SERVICE_API_RESULT_INVALID, 0u); }

static inline R4TcpServiceCall r4_network_tcp_service_call(R4Network *network, uint16_t op, const void *request, uint32_t request_len, void *response, uint32_t response_capacity, R4Timeout timeout) {
    R4TcpServiceCall result = {{R4_SERVICE_CALL_FAILED, R4OS_ERR_NO_GROUP, 0u, {0}}, 0u};
    if (!r4_network_available(network)) return result;
    if (request_len > R4OS_SERVICE_API_MAX_PAYLOAD - sizeof(R4ServiceDeadlineFooter) || (request_len && !request)) { result.call.raw_code = R4OS_SERVICE_API_RESULT_INVALID; return result; }
    uint64_t ticks = 0u;
    if (r4_timeout_to_ticks(timeout, r4_services_monotonic_hz(network->app), &ticks) != R4OS_OK) { result.call.raw_code = R4OS_SERVICE_API_RESULT_INVALID; return result; }
    const int finite = timeout.kind == R4OS_TIMEOUT_KIND_FINITE;
    if (finite && !R4SYS_HAS(&network->app->system, ticks)) { result.call.raw_code = R4OS_ERR_NO_FN; return result; }
    uint64_t now = finite ? r4_app_ticks(network->app) : 0u;
    if (finite && (ticks == UINT64_MAX || now >= UINT64_MAX - ticks)) { result.call.raw_code = R4OS_SERVICE_API_RESULT_INVALID; return result; }
    uint64_t deadline = timeout.kind == R4OS_TIMEOUT_KIND_POLL ? R4OS_NET_SERVICE_TCP_DEADLINE_POLL : (finite ? now + ticks : UINT64_MAX);
    if (finite && !ticks) { result.call.kind = R4_SERVICE_CALL_TIMED_OUT; result.call.raw_code = R4OS_SERVICE_API_RESULT_TIMEOUT; return result; }
    uint8_t encoded[R4OS_SERVICE_API_MAX_PAYLOAD];
    if (request_len) __builtin_memcpy(encoded, request, request_len);
    R4ServiceDeadlineFooter footer = {.magic = R4OS_SERVICE_DEADLINE_FOOTER_MAGIC, .version = R4OS_SERVICE_DEADLINE_FOOTER_VERSION, .size = sizeof(footer), .payload_len = request_len, .deadline_tick = deadline};
    __builtin_memcpy(encoded + request_len, &footer, sizeof(footer));
    R4Services services = r4_app_services(network->app); R4ServiceConnection connection;
    int32_t raw = r4_services_open(&services, "TCPSVC", &connection);
    if (raw != R4OS_SERVICE_API_RESULT_OK) { result.call.raw_code = raw; return result; }
    if (finite) {
        now = r4_app_ticks(network->app);
        if (now >= deadline) { result.call.kind = R4_SERVICE_CALL_TIMED_OUT; result.call.raw_code = R4OS_SERVICE_API_RESULT_TIMEOUT; (void)r4_service_connection_close(&connection); return result; }
        ticks = deadline - now;
    }
    result.submitted = 1u;
    result.call = r4_service_connection_call_ticks(&connection, op, encoded, request_len + sizeof(footer), response, response_capacity, ticks);
    (void)r4_service_connection_close(&connection);
    if (result.call.kind == R4_SERVICE_CALL_RESPONSE && (result.call.bytes > response_capacity || result.call.header.magic != R4OS_SERVICE_API_MAGIC || result.call.header.version != R4OS_SERVICE_API_VERSION || result.call.header.op != op)) {
        result.call.kind = R4_SERVICE_CALL_FAILED; result.call.raw_code = R4OS_SERVICE_API_RESULT_INVALID; result.call.bytes = 0u;
    }
    return result;
}

static inline R4NetResult r4_tcp_from_call(R4TcpServiceCall value) {
    if (value.call.kind == R4_SERVICE_CALL_RESPONSE) return r4_net_from_call(value.call);
    if (!value.submitted) return r4_net_from_call(value.call);
    return r4_net_result(R4_NET_RESULT_OUTCOME_UNKNOWN, value.call.raw_code, 0u);
}

static inline R4NetResult r4_net_classify_socket(uint32_t service_status, uint32_t lifecycle, int32_t raw, uint32_t bytes) {
    if (service_status == R4OS_NET_SERVICE_STATUS_WOULD_BLOCK || lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_WOULD_BLOCK) return r4_net_result(R4_NET_RESULT_WOULD_BLOCK, raw, 0u);
    if (service_status == R4OS_NET_SERVICE_STATUS_TIMEOUT || lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_TIMEOUT) return r4_net_result(R4_NET_RESULT_TIMED_OUT, raw, 0u);
    if (lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_RESET) return r4_net_result(R4_NET_RESULT_RESET, raw, 0u);
    if (lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_PEER_GONE) return r4_net_result(R4_NET_RESULT_PEER_CLOSED, raw, 0u);
    if (lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_LOCAL_CLOSE || lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_CLOSED || lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_BAD_HANDLE) return r4_net_result(R4_NET_RESULT_CLOSED, raw, 0u);
    return raw == 0 ? r4_net_result(R4_NET_RESULT_OK, raw, bytes) : r4_net_result(R4_NET_RESULT_FAILED, raw, 0u);
}

/* Packed status bits are part of the current wire result, also when the
 * dedicated status field is idle. Keep partial counts separate from state. */
static inline R4NetResult r4_net_classify_tcp(const R4NetServiceTcpResult *value, uint32_t bytes) {
    uint32_t packed = (value->flags & R4OS_NET_SERVICE_STATUS_MASK) >> R4OS_NET_SERVICE_STATUS_SHIFT;
    uint32_t status = value->service_status != R4OS_NET_SERVICE_STATUS_IDLE ? value->service_status : packed;
    if (packed == R4OS_NET_SERVICE_STATUS_WOULD_BLOCK) status = packed;
    if (status == R4OS_NET_SERVICE_STATUS_FAILED && value->result == R4OS_NET_TX_BACKEND_ERROR) return r4_net_result(R4_NET_RESULT_NO_SERVICE, value->result, 0u);
    R4NetResult result = r4_net_classify_socket(status, value->lifecycle_cause, value->result, bytes);
    result.bytes = bytes; /* Validated server prefix, independent of final state. */
    if (result.kind == R4_NET_RESULT_CLOSED && value->lifecycle_cause == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_CLOSED) result.kind = R4_NET_RESULT_PEER_CLOSED;
    return result;
}
static inline R4NetResult r4_net_classify_udp(const R4NetServiceUdpResult *value, uint32_t bytes) {
    uint32_t status = value->service_status != R4OS_NET_SERVICE_STATUS_IDLE ? value->service_status : (value->flags & R4OS_NET_SERVICE_STATUS_MASK) >> R4OS_NET_SERVICE_STATUS_SHIFT;
    if (status == R4OS_NET_SERVICE_STATUS_FAILED && value->result == R4OS_NET_TX_BACKEND_ERROR) return r4_net_result(R4_NET_RESULT_NO_SERVICE, value->result, 0u);
    return r4_net_classify_socket(status, value->lifecycle_cause, value->result, bytes);
}

static inline R4NetResult r4_resolver_resolve_a(R4Resolver *resolver, const uint8_t *name, uint32_t name_len, const R4Ipv4Address *server, R4Timeout timeout, R4Ipv4Address *out) {
    if (out != 0) *out = (R4Ipv4Address){{0u, 0u, 0u, 0u}};
    if (resolver == 0 || out == 0 || name == 0 || name_len == 0u || name_len > R4OS_SERVICE_API_MAX_PAYLOAD - 4u) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_DNS_RESULT_NAME, 0u);
    uint8_t request[R4OS_SERVICE_API_MAX_PAYLOAD]; uint32_t offset = 0u;
    uint16_t op = R4OS_NET_SERVICE_OP_DNS_RESOLVE_A_RESULT;
    if (server != 0) { request[0] = server->octets[0]; request[1] = server->octets[1]; request[2] = server->octets[2]; request[3] = server->octets[3]; offset = 4u; op = R4OS_NET_SERVICE_OP_DNS_RESOLVE_A_SERVER_RESULT; }
    for (uint32_t i = 0u; i < name_len; ++i) request[offset + i] = name[i];
    R4NetServiceDnsResult response = {0};
    R4ServiceCallResult call = r4_network_service_call(&resolver->network, "DNSSVC", op, request, offset + name_len, &response, sizeof(response), timeout);
    R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport; if (call.bytes < sizeof(response) || call.bytes > sizeof(response) || response.magic != R4OS_NET_SERVICE_DNS_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_DNS_RESULT_VERSION) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u);
    if (response.result == R4OS_DNS_RESULT_TIMEOUT) return r4_net_result(R4_NET_RESULT_TIMED_OUT, response.result, 0u);
    if (response.result == R4OS_DNS_RESULT_NXDOMAIN) return r4_net_result(R4_NET_RESULT_NOT_FOUND, response.result, 0u);
    if (response.result != R4OS_DNS_RESULT_OK || (response.flags & R4OS_NET_SERVICE_DNS_FLAG_OK) == 0u) return r4_net_result(R4_NET_RESULT_FAILED, response.result, 0u);
    out->octets[0] = response.answer[0]; out->octets[1] = response.answer[1]; out->octets[2] = response.answer[2]; out->octets[3] = response.answer[3];
    return r4_net_result(R4_NET_RESULT_OK, R4OS_DNS_RESULT_OK, 0u);
}

static inline R4NetResult r4_network_connect_tcp(R4Network *network, R4SocketAddress remote, R4Timeout timeout, R4TcpSocket *out) {
    if (out != 0) *out = (R4TcpSocket){0}; if (network == 0 || out == 0) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERROR_INVALID, 0u);
    uint8_t request[6] = {remote.address.octets[0], remote.address.octets[1], remote.address.octets[2], remote.address.octets[3], 0u, 0u}; r4_net_write_u16(&request[4], remote.port);
    R4NetServiceTcpResult response = {0}; R4TcpServiceCall tcp_call = r4_network_tcp_service_call(network, R4OS_NET_SERVICE_OP_TCP_CONNECT_RESULT, request, sizeof(request), &response, sizeof(response), timeout); R4ServiceCallResult call = tcp_call.call;
    R4NetResult transport = r4_tcp_from_call(tcp_call); if (transport.kind != R4_NET_RESULT_OK) return transport; if (call.bytes < sizeof(response) || call.bytes > sizeof(response) || response.magic != R4OS_NET_SERVICE_TCP_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_TCP_RESULT_VERSION) return r4_tcp_reply_unknown();
    R4NetResult result = r4_net_classify_tcp(&response, response.bytes);
    if (result.kind != R4_NET_RESULT_OK || response.handle == 0u || (response.flags & R4OS_NET_SERVICE_TCP_FLAG_HANDLE_VALID) == 0u) return result.kind == R4_NET_RESULT_OK ? r4_tcp_reply_unknown() : result;
    out->network = *network; out->raw = response.handle; out->owned = 1u; out->remote = remote; return result;
}

static inline R4NetResult r4_network_listen_tcp(R4Network *network, uint16_t port, R4Timeout timeout, R4TcpListener *out) {
    if (out != 0) *out = (R4TcpListener){0}; if (network == 0 || out == 0 || port == 0u) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERROR_INVALID, 0u);
    uint8_t request[2]; r4_net_write_u16(request, port); R4NetServiceTcpResult response = {0};
    R4TcpServiceCall tcp_call = r4_network_tcp_service_call(network, R4OS_NET_SERVICE_OP_TCP_LISTEN_RESULT, request, sizeof(request), &response, sizeof(response), timeout); R4ServiceCallResult call = tcp_call.call;
    R4NetResult transport = r4_tcp_from_call(tcp_call); if (transport.kind != R4_NET_RESULT_OK) return transport; if (call.bytes < sizeof(response) || call.bytes > sizeof(response) || response.magic != R4OS_NET_SERVICE_TCP_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_TCP_RESULT_VERSION) return r4_tcp_reply_unknown();
    R4NetResult result = r4_net_classify_tcp(&response, 0u); if (result.kind == R4_NET_RESULT_OK) { out->network = *network; out->port = port; out->owned = 1u; } return result;
}

static inline R4NetResult r4_tcp_listener_accept(R4TcpListener *listener, R4Timeout timeout, R4TcpSocket *out) {
    if (out != 0) *out = (R4TcpSocket){0}; if (!r4_tcp_listener_valid(listener) || out == 0) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u);
    uint8_t request[2]; r4_net_write_u16(request, listener->port); R4NetServiceTcpResult response = {0};
    R4TcpServiceCall tcp_call = r4_network_tcp_service_call(&listener->network, R4OS_NET_SERVICE_OP_TCP_ACCEPT_POLL_RESULT, request, sizeof(request), &response, sizeof(response), timeout); R4ServiceCallResult call = tcp_call.call;
    R4NetResult transport = r4_tcp_from_call(tcp_call); if (transport.kind != R4_NET_RESULT_OK) return transport; if (call.bytes < sizeof(response) || call.bytes > sizeof(response) || response.magic != R4OS_NET_SERVICE_TCP_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_TCP_RESULT_VERSION) return r4_tcp_reply_unknown();
    R4NetResult result = r4_net_classify_tcp(&response, 0u);
    if (result.kind == R4_NET_RESULT_OK && response.handle != 0u && (response.flags & R4OS_NET_SERVICE_TCP_FLAG_HANDLE_VALID) != 0u) { out->network = listener->network; out->raw = response.handle; out->owned = 1u; out->remote.address.octets[0] = response.remote_ip[0]; out->remote.address.octets[1] = response.remote_ip[1]; out->remote.address.octets[2] = response.remote_ip[2]; out->remote.address.octets[3] = response.remote_ip[3]; out->remote.port = response.remote_port; return result; }
    return result.kind == R4_NET_RESULT_OK ? r4_net_result(R4_NET_RESULT_WOULD_BLOCK, response.result, 0u) : result;
}

static inline R4NetResult r4_tcp_socket_write(R4TcpSocket *socket, const uint8_t *data, uint32_t len, R4Timeout timeout) {
    if (!r4_tcp_socket_valid(socket)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (len > R4OS_NET_SERVICE_TCP_WRITE_MAX || (len != 0u && data == 0)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_NET_TX_TOO_LARGE, 0u);
    uint8_t request[4u + R4OS_NET_SERVICE_TCP_WRITE_MAX]; r4_net_write_u32(request, socket->raw); for (uint32_t i = 0u; i < len; ++i) request[4u + i] = data[i]; R4NetServiceTcpResult response = {0};
    R4TcpServiceCall tcp_call = r4_network_tcp_service_call(&socket->network, R4OS_NET_SERVICE_OP_TCP_WRITE_RESULT, request, 4u + len, &response, sizeof(response), timeout); R4ServiceCallResult call = tcp_call.call; R4NetResult transport = r4_tcp_from_call(tcp_call); if (transport.kind != R4_NET_RESULT_OK) return transport; if (call.bytes < sizeof(response) || call.bytes > sizeof(response) || response.magic != R4OS_NET_SERVICE_TCP_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_TCP_RESULT_VERSION) return r4_tcp_reply_unknown();
    if (response.bytes > len) return r4_tcp_reply_unknown(); R4NetResult result = r4_net_classify_tcp(&response, response.bytes);  return result;
}

static inline R4NetResult r4_tcp_socket_read(R4TcpSocket *socket, uint8_t *out, uint32_t capacity, R4Timeout timeout) {
    if (!r4_tcp_socket_valid(socket)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (capacity != 0u && out == 0) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERROR_INVALID, 0u); if (capacity > R4OS_NET_SERVICE_TCP_READ_MAX) capacity = R4OS_NET_SERVICE_TCP_READ_MAX;
    uint8_t request[6]; r4_net_write_u32(request, socket->raw); r4_net_write_u16(&request[4], (uint16_t)capacity); uint8_t response[sizeof(R4NetServiceTcpResult) + R4OS_NET_SERVICE_TCP_READ_MAX];
    R4TcpServiceCall tcp_call = r4_network_tcp_service_call(&socket->network, R4OS_NET_SERVICE_OP_TCP_READ_RESULT, request, sizeof(request), response, sizeof(response), timeout); R4ServiceCallResult call = tcp_call.call; R4NetResult transport = r4_tcp_from_call(tcp_call); if (transport.kind != R4_NET_RESULT_OK) return transport;
    if (call.bytes < sizeof(R4NetServiceTcpResult)) return r4_tcp_reply_unknown(); R4NetServiceTcpResult parsed; __builtin_memcpy(&parsed, response, sizeof(parsed)); if (parsed.magic != R4OS_NET_SERVICE_TCP_RESULT_MAGIC || parsed.version != R4OS_NET_SERVICE_TCP_RESULT_VERSION) return r4_tcp_reply_unknown();
    if (parsed.bytes > capacity || sizeof(parsed) + parsed.bytes > call.bytes) return r4_tcp_reply_unknown(); R4NetResult result = r4_net_classify_tcp(&parsed, parsed.bytes); for (uint32_t i = 0u; i < parsed.bytes; ++i) out[i] = response[sizeof(parsed) + i];  return result;
}

static inline R4TcpPollResult r4_tcp_socket_readiness(R4TcpSocket *socket, R4Timeout timeout) {
    R4TcpPollResult out = {0};
    out.result = r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u);
    if (!r4_tcp_socket_valid(socket)) return out;
    uint8_t request[4]; r4_net_write_u32(request, socket->raw);
    R4NetServiceTcpResult response = {0};
    R4TcpServiceCall tcp_call = r4_network_tcp_service_call(&socket->network, R4OS_NET_SERVICE_OP_TCP_POLL_RESULT, request, sizeof(request), &response, sizeof(response), timeout);
    out.result = r4_tcp_from_call(tcp_call);
    if (out.result.kind != R4_NET_RESULT_OK) return out;
    if (tcp_call.call.bytes != sizeof(response) || response.magic != R4OS_NET_SERVICE_TCP_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_TCP_RESULT_VERSION) {
        out.result = r4_tcp_reply_unknown(); return out;
    }
    out.result = r4_net_classify_tcp(&response, 0u);
    uint32_t packed = (response.flags & R4OS_NET_SERVICE_STATUS_MASK) >> R4OS_NET_SERVICE_STATUS_SHIFT;
    uint32_t status = response.service_status != R4OS_NET_SERVICE_STATUS_IDLE ? response.service_status : packed;
    if (packed == R4OS_NET_SERVICE_STATUS_WOULD_BLOCK) status = packed;
    out.available = 1u;
    out.readiness.readable = response.pending_rx != 0u;
    out.readiness.writable = response.tx_window != 0u;
    out.readiness.pending_rx = response.pending_rx;
    out.readiness.rx_window = response.rx_window;
    out.readiness.tx_window = response.tx_window;
    out.readiness.lifecycle_cause = response.lifecycle_cause;
    out.readiness.service_status = status;
    out.readiness.would_block = status == R4OS_NET_SERVICE_STATUS_WOULD_BLOCK || response.lifecycle_cause == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_WOULD_BLOCK;
    out.readiness.reset = response.lifecycle_cause == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_RESET;
    out.readiness.peer_closed = response.lifecycle_cause == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_PEER_GONE || response.lifecycle_cause == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_CLOSED;
    switch (response.lifecycle_cause) {
        case R4OS_NET_SERVICE_SOCKET_LIFECYCLE_CLOSED:
        case R4OS_NET_SERVICE_SOCKET_LIFECYCLE_RESET:
        case R4OS_NET_SERVICE_SOCKET_LIFECYCLE_PEER_GONE:
        case R4OS_NET_SERVICE_SOCKET_LIFECYCLE_LOCAL_ABORT:
        case R4OS_NET_SERVICE_SOCKET_LIFECYCLE_LOCAL_CLOSE:
        case R4OS_NET_SERVICE_SOCKET_LIFECYCLE_BAD_HANDLE:
        case R4OS_NET_SERVICE_SOCKET_LIFECYCLE_OWNER_MISMATCH:
        case R4OS_NET_SERVICE_SOCKET_LIFECYCLE_DROPPED: out.readiness.terminal = 1u; break;
        default: break;
    }
    return out;
}

/* Compatibility state-only view: pending_rx is not transferred progress. */
static inline R4NetResult r4_tcp_socket_poll(R4TcpSocket *socket, R4Timeout timeout) {
    return r4_tcp_socket_readiness(socket, timeout).result;
}

/* One close request. An unconfirmed submitted request is never repeated by
 * this facade or by the compatibility close method on the same socket. */
static inline R4TcpCloseReceipt r4_tcp_socket_close_receipt(R4TcpSocket *socket, R4Timeout timeout) {
    R4TcpCloseReceipt receipt = {0};
    receipt.operation = R4OS_NET_SERVICE_OP_TCP_CLOSE_RESULT;
    receipt.outcome = r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u);
    if (!r4_tcp_socket_valid(socket)) return receipt;
    if (!socket->owned) { receipt.outcome.raw_code = R4OS_ERR_NOT_OWNED; return receipt; }
    if (socket->reserved[0]) { receipt.outcome = r4_tcp_reply_unknown(); receipt.submitted = 1u; return receipt; }
    uint8_t request[4]; r4_net_write_u32(request, socket->raw);
    R4NetServiceTcpResult response = {0};
    R4TcpServiceCall call = r4_network_tcp_service_call(&socket->network, receipt.operation, request, sizeof(request), &response, sizeof(response), timeout);
    receipt.submitted = call.submitted;
    receipt.outcome = r4_tcp_from_call(call);
    if (receipt.outcome.kind != R4_NET_RESULT_OK) {
        if (receipt.outcome.kind == R4_NET_RESULT_OUTCOME_UNKNOWN) socket->reserved[0] = 1u;
        return receipt;
    }
    if (call.call.bytes != sizeof(response) || response.magic != R4OS_NET_SERVICE_TCP_RESULT_MAGIC ||
        response.version != R4OS_NET_SERVICE_TCP_RESULT_VERSION || response.action != R4OS_NET_SERVICE_TCP_ACTION_CLOSE ||
        (response.flags & R4OS_NET_SERVICE_TCP_FLAG_HANDLE_VALID) == 0u || response.handle != socket->raw) {
        receipt.outcome = r4_tcp_reply_unknown();
        socket->reserved[0] = 1u;
        return receipt;
    }
    receipt.action = response.action;
    receipt.ack = response.tx_ack;
    receipt.lifecycle_cause = response.lifecycle_cause;
    receipt.service_status = response.service_status;
    receipt.outcome = r4_net_classify_tcp(&response, 0u);
    if (response.result == 0) {
        receipt.accepted = 1u;
        receipt.pending_shutdown = response.lifecycle_cause == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_PENDING_CLOSE;
        receipt.frontend_released = 1u;
        receipt.outcome = r4_net_result(R4_NET_RESULT_CLOSED, R4OS_OK, 0u);
        socket->raw = 0u;
    } else {
        /* TCPSVC can release its frontend after a backend error. */
        socket->reserved[0] = 1u;
    }
    return receipt;
}

static inline R4NetResult r4_tcp_socket_close(R4TcpSocket *socket, R4Timeout timeout) {
    if (!r4_tcp_socket_valid(socket)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (!socket->owned) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_NOT_OWNED, 0u);
    if (socket->reserved[0]) return r4_tcp_reply_unknown();
    uint8_t request[4]; r4_net_write_u32(request, socket->raw); R4NetServiceTcpResult response = {0}; R4TcpServiceCall tcp_call = r4_network_tcp_service_call(&socket->network, R4OS_NET_SERVICE_OP_TCP_CLOSE_RESULT, request, sizeof(request), &response, sizeof(response), timeout); R4ServiceCallResult call = tcp_call.call; R4NetResult transport = r4_tcp_from_call(tcp_call); if (transport.kind != R4_NET_RESULT_OK) return transport; if (call.bytes < sizeof(response) || call.bytes > sizeof(response) || response.magic != R4OS_NET_SERVICE_TCP_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_TCP_RESULT_VERSION) return r4_tcp_reply_unknown();
    R4NetResult result = r4_net_classify_tcp(&response, 0u); if (result.kind == R4_NET_RESULT_OK || result.kind == R4_NET_RESULT_CLOSED || (result.kind == R4_NET_RESULT_PEER_CLOSED && response.lifecycle_cause == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_CLOSED)) { socket->raw = 0u; return r4_net_result(R4_NET_RESULT_CLOSED, R4OS_OK, 0u); } return result;
}

static inline R4NetResult r4_tcp_listener_close(R4TcpListener *listener, R4Timeout timeout) {
    if (!r4_tcp_listener_valid(listener)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (!listener->owned) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_NOT_OWNED, 0u);
    uint8_t request[2]; r4_net_write_u16(request, listener->port); R4NetServiceTcpResult response = {0}; R4TcpServiceCall tcp_call = r4_network_tcp_service_call(&listener->network, R4OS_NET_SERVICE_OP_TCP_CLOSE_LISTEN_RESULT, request, sizeof(request), &response, sizeof(response), timeout); R4ServiceCallResult call = tcp_call.call; R4NetResult transport = r4_tcp_from_call(tcp_call); if (transport.kind != R4_NET_RESULT_OK) return transport; if (call.bytes < sizeof(response) || call.bytes > sizeof(response) || response.magic != R4OS_NET_SERVICE_TCP_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_TCP_RESULT_VERSION) return r4_tcp_reply_unknown();
    R4NetResult result = r4_net_classify_tcp(&response, 0u); if (result.kind == R4_NET_RESULT_OK || result.kind == R4_NET_RESULT_CLOSED || (result.kind == R4_NET_RESULT_PEER_CLOSED && response.lifecycle_cause == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_CLOSED)) { listener->port = 0u; return r4_net_result(R4_NET_RESULT_CLOSED, R4OS_OK, 0u); } return result;
}

static inline R4NetResult r4_network_bind_udp(R4Network *network, uint16_t port, R4Timeout timeout, R4UdpSocket *out) {
    if (out != 0) *out = (R4UdpSocket){0}; if (network == 0 || out == 0) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERROR_INVALID, 0u); uint8_t request[2]; r4_net_write_u16(request, port); R4NetServiceUdpResult response = {0};
    R4ServiceCallResult call = r4_network_service_call(network, "UDPSVC", R4OS_NET_SERVICE_OP_UDP_BIND_RESULT, request, sizeof(request), &response, sizeof(response), timeout); R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport; if (call.bytes < sizeof(response) || call.bytes > sizeof(response) || response.magic != R4OS_NET_SERVICE_UDP_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_UDP_RESULT_VERSION) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u);
    R4NetResult result = r4_net_classify_udp(&response, 0u); if (result.kind == R4_NET_RESULT_OK && response.handle != 0u && (response.flags & R4OS_NET_SERVICE_UDP_FLAG_HANDLE_VALID) != 0u) { out->network = *network; out->raw = response.handle; out->local_port = port; out->owned = 1u; return result; } return result.kind == R4_NET_RESULT_OK ? r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u) : result;
}

static inline R4NetResult r4_udp_socket_send_to(R4UdpSocket *socket, R4SocketAddress destination, const uint8_t *data, uint32_t len, R4Timeout timeout) {
    if (!r4_udp_socket_valid(socket)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (len > R4OS_NET_SERVICE_UDP_SEND_MAX || (len != 0u && data == 0)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_NET_TX_TOO_LARGE, 0u);
    uint8_t request[10u + R4OS_NET_SERVICE_UDP_SEND_MAX]; r4_net_write_u32(request, socket->raw); request[4] = destination.address.octets[0]; request[5] = destination.address.octets[1]; request[6] = destination.address.octets[2]; request[7] = destination.address.octets[3]; r4_net_write_u16(&request[8], destination.port); for (uint32_t i = 0u; i < len; ++i) request[10u + i] = data[i]; R4NetServiceUdpResult response = {0};
    R4ServiceCallResult call = r4_network_service_call(&socket->network, "UDPSVC", R4OS_NET_SERVICE_OP_UDP_SENDTO_RESULT, request, 10u + len, &response, sizeof(response), timeout); R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport; if (call.bytes < sizeof(response) || call.bytes > sizeof(response) || response.magic != R4OS_NET_SERVICE_UDP_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_UDP_RESULT_VERSION) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u); if (response.bytes > len) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u); R4NetResult result = r4_net_classify_udp(&response, response.bytes); if (result.kind == R4_NET_RESULT_CLOSED || result.kind == R4_NET_RESULT_RESET) socket->raw = 0u; return result;
}

static inline R4NetResult r4_udp_socket_receive_from(R4UdpSocket *socket, uint8_t *out, uint32_t capacity, R4Timeout timeout, R4Datagram *datagram) {
    if (datagram != 0) *datagram = (R4Datagram){0}; if (!r4_udp_socket_valid(socket) || datagram == 0) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (capacity != 0u && out == 0) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERROR_INVALID, 0u); if (capacity > R4OS_NET_SERVICE_UDP_READ_MAX) capacity = R4OS_NET_SERVICE_UDP_READ_MAX;
    uint8_t request[6]; r4_net_write_u32(request, socket->raw); r4_net_write_u16(&request[4], (uint16_t)capacity); uint8_t response[sizeof(R4NetServiceUdpResult) + R4OS_NET_SERVICE_UDP_READ_MAX]; R4ServiceCallResult call = r4_network_service_call(&socket->network, "UDPSVC", R4OS_NET_SERVICE_OP_UDP_RECV_RESULT, request, sizeof(request), response, sizeof(response), timeout); R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport;
    if (call.bytes < sizeof(R4NetServiceUdpResult)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u); R4NetServiceUdpResult parsed; __builtin_memcpy(&parsed, response, sizeof(parsed)); if (parsed.magic != R4OS_NET_SERVICE_UDP_RESULT_MAGIC || parsed.version != R4OS_NET_SERVICE_UDP_RESULT_VERSION) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u); R4NetResult result = r4_net_classify_udp(&parsed, parsed.bytes); if (result.kind != R4_NET_RESULT_OK) { if (result.kind == R4_NET_RESULT_CLOSED || result.kind == R4_NET_RESULT_RESET) socket->raw = 0u; return result; }
    if (parsed.bytes > capacity || sizeof(parsed) + parsed.bytes > call.bytes) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u); for (uint32_t i = 0u; i < parsed.bytes; ++i) out[i] = response[sizeof(parsed) + i]; datagram->source.address.octets[0] = parsed.source_ip[0]; datagram->source.address.octets[1] = parsed.source_ip[1]; datagram->source.address.octets[2] = parsed.source_ip[2]; datagram->source.address.octets[3] = parsed.source_ip[3]; datagram->source.port = parsed.source_port; datagram->destination.address.octets[0] = parsed.dest_ip[0]; datagram->destination.address.octets[1] = parsed.dest_ip[1]; datagram->destination.address.octets[2] = parsed.dest_ip[2]; datagram->destination.address.octets[3] = parsed.dest_ip[3]; datagram->destination.port = parsed.dest_port; datagram->bytes = parsed.bytes; return result;
}

static inline R4NetResult r4_udp_socket_close(R4UdpSocket *socket, R4Timeout timeout) {
    if (!r4_udp_socket_valid(socket)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (!socket->owned) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_NOT_OWNED, 0u); uint8_t request[4]; r4_net_write_u32(request, socket->raw); R4NetServiceUdpResult response = {0}; R4ServiceCallResult call = r4_network_service_call(&socket->network, "UDPSVC", R4OS_NET_SERVICE_OP_UDP_CLOSE_RESULT, request, sizeof(request), &response, sizeof(response), timeout); R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport; if (call.bytes < sizeof(response) || call.bytes > sizeof(response) || response.magic != R4OS_NET_SERVICE_UDP_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_UDP_RESULT_VERSION) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u); R4NetResult result = r4_net_classify_udp(&response, 0u); if (result.kind == R4_NET_RESULT_OK || result.kind == R4_NET_RESULT_CLOSED || (result.kind == R4_NET_RESULT_PEER_CLOSED && response.lifecycle_cause == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_CLOSED)) { socket->raw = 0u; return r4_net_result(R4_NET_RESULT_CLOSED, R4OS_OK, 0u); } return result;
}

#endif
