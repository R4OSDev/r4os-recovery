#ifndef R4OS_APP_NETWORK_H
#define R4OS_APP_NETWORK_H

#include "app_services.h"

typedef struct R4Ipv4Address { uint8_t octets[4]; } R4Ipv4Address;
typedef struct R4SocketAddress { R4Ipv4Address address; uint16_t port; uint16_t reserved; } R4SocketAddress;
typedef struct R4Network { R4App *app; } R4Network;
typedef struct R4Resolver { R4Network network; } R4Resolver;

/* Private DNSSVC/TCPSVC/UDPSVC wire replies. Public callers use the typed
 * facade objects below and never construct these service payloads. */
typedef struct R4NetServiceDnsResult {
    uint32_t magic;
    uint16_t version;
    uint16_t action;
    int32_t result;
    uint32_t flags;
    uint8_t answer[4];
    uint8_t server[4];
    uint8_t cache_answer[4];
    uint32_t cache_age_seconds;
    uint32_t cache_ttl_seconds;
    uint32_t cache_remaining_seconds;
    uint64_t queries_tx;
    uint64_t resolve_requests;
    uint64_t responses_rx;
    uint64_t a_records;
    uint64_t timeouts;
    uint64_t nxdomain;
    uint64_t tx_errors;
    uint64_t malformed;
    uint64_t cache_hits;
    uint64_t cache_stores;
    uint16_t last_id;
    uint16_t name_len;
    uint8_t name[96];
    uint8_t last_error[32];
} R4NetServiceDnsResult;

typedef struct R4NetServiceTcpResult {
    uint32_t magic;
    uint16_t version;
    uint16_t action;
    int32_t result;
    uint32_t flags;
    uint32_t handle;
    uint32_t conn_id;
    uint32_t bytes;
    uint32_t requested_bytes;
    uint16_t port;
    uint16_t remote_port;
    uint8_t remote_ip[4];
    uint32_t active_connections;
    uint32_t max_connections;
    uint32_t active_listeners;
    uint32_t handle_count;
    uint32_t max_handles;
    uint32_t tcp_buffer_size;
    uint32_t message_payload_max;
    uint32_t write_max;
    uint32_t read_max;
    uint32_t pending_rx;
    uint32_t rx_window;
    uint32_t tx_window;
    uint32_t tx_seq;
    uint32_t tx_ack;
    uint32_t retransmits;
    uint32_t rx_drops;
    uint8_t local_ip[4];
    uint16_t local_port;
    uint16_t reserved3;
    uint8_t last_error[32];
    uint32_t lifecycle_cause;
    uint32_t service_status;
    uint16_t owner_id;
    uint16_t reserved4;
} R4NetServiceTcpResult;

typedef struct R4NetServiceUdpResult {
    uint32_t magic;
    uint16_t version;
    uint16_t action;
    int32_t result;
    uint32_t flags;
    uint32_t handle;
    uint32_t bytes;
    uint32_t requested_bytes;
    uint8_t source_ip[4];
    uint8_t dest_ip[4];
    uint16_t source_port;
    uint16_t dest_port;
    uint32_t active_sockets;
    uint32_t max_sockets;
    uint32_t queued_packets;
    uint32_t queue_limit;
    uint32_t payload_max;
    uint32_t message_payload_max;
    uint32_t send_max;
    uint32_t recv_max;
    uint64_t delivered;
    uint64_t drops;
    uint8_t last_error[32];
    uint32_t lifecycle_cause;
    uint32_t service_status;
} R4NetServiceUdpResult;

_Static_assert(sizeof(R4NetServiceDnsResult) == 256u, "DNSSVC result wire-size mismatch");
_Static_assert(sizeof(R4NetServiceTcpResult) == 156u, "TCPSVC result wire-size mismatch");
_Static_assert(sizeof(R4NetServiceUdpResult) == 128u, "UDPSVC result wire-size mismatch");
_Static_assert(offsetof(R4NetServiceTcpResult, lifecycle_cause) == 144u, "TCPSVC lifecycle offset mismatch");
_Static_assert(offsetof(R4NetServiceUdpResult, lifecycle_cause) == 120u, "UDPSVC lifecycle offset mismatch");

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
    R4_NET_RESULT_FAILED = 8
} R4NetResultKind;

typedef struct R4NetResult {
    R4NetResultKind kind;
    int32_t raw_code;
    uint32_t bytes;
} R4NetResult;

static inline R4Ipv4Address r4_ipv4(uint8_t a, uint8_t b, uint8_t c, uint8_t d) { R4Ipv4Address value = {{a, b, c, d}}; return value; }
static inline int r4_ipv4_is_unspecified(R4Ipv4Address value) { return value.octets[0] == 0u && value.octets[1] == 0u && value.octets[2] == 0u && value.octets[3] == 0u; }
static inline R4Network r4_app_network(R4App *app) { R4Network value = {app}; return value; }
static inline R4Resolver r4_network_resolver(R4Network network) { R4Resolver value = {network}; return value; }
static inline int r4_network_available(const R4Network *network) { R4Services services = r4_app_services(network != 0 ? network->app : 0); return network != 0 && network->app != 0 && network->app->network.table != 0 && network->app->network.table->tcp_connect != 0 && r4_services_available(&services); }
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
    return result;
}

static inline R4NetResult r4_net_from_call(R4ServiceCallResult call) {
    if (call.kind == R4_SERVICE_CALL_TIMED_OUT) return r4_net_result(R4_NET_RESULT_TIMED_OUT, R4OS_SERVICE_API_RESULT_TIMEOUT, 0u);
    if (call.kind == R4_SERVICE_CALL_RESPONSE) return r4_net_result(R4_NET_RESULT_OK, R4OS_OK, call.bytes);
    if (call.raw_code == R4OS_SERVICE_API_RESULT_NOT_FOUND || call.raw_code == R4OS_SERVICE_API_RESULT_NO_ENDPOINT || call.raw_code == R4OS_SERVICE_API_RESULT_NOT_RUNNING) return r4_net_result(R4_NET_RESULT_NO_SERVICE, call.raw_code, 0u);
    return r4_net_result(R4_NET_RESULT_FAILED, call.raw_code, 0u);
}

static inline R4NetResult r4_net_classify_socket(uint32_t service_status, uint32_t lifecycle, int32_t raw, uint32_t bytes) {
    if (service_status == R4OS_NET_SERVICE_STATUS_WOULD_BLOCK || lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_WOULD_BLOCK) return r4_net_result(R4_NET_RESULT_WOULD_BLOCK, raw, 0u);
    if (service_status == R4OS_NET_SERVICE_STATUS_TIMEOUT || lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_TIMEOUT) return r4_net_result(R4_NET_RESULT_TIMED_OUT, raw, 0u);
    if (lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_RESET) return r4_net_result(R4_NET_RESULT_RESET, raw, 0u);
    if (lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_PEER_GONE) return r4_net_result(R4_NET_RESULT_PEER_CLOSED, raw, 0u);
    if (lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_LOCAL_CLOSE || lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_CLOSED || lifecycle == R4OS_NET_SERVICE_SOCKET_LIFECYCLE_BAD_HANDLE) return r4_net_result(R4_NET_RESULT_CLOSED, raw, 0u);
    return raw == 0 ? r4_net_result(R4_NET_RESULT_OK, raw, bytes) : r4_net_result(R4_NET_RESULT_FAILED, raw, 0u);
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
    R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport;
    if (call.bytes < sizeof(response) || response.magic != R4OS_NET_SERVICE_DNS_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_DNS_RESULT_VERSION) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u);
    if (response.result == R4OS_DNS_RESULT_TIMEOUT) return r4_net_result(R4_NET_RESULT_TIMED_OUT, response.result, 0u);
    if (response.result == R4OS_DNS_RESULT_NXDOMAIN) return r4_net_result(R4_NET_RESULT_NOT_FOUND, response.result, 0u);
    if (response.result != R4OS_DNS_RESULT_OK || (response.flags & R4OS_NET_SERVICE_DNS_FLAG_OK) == 0u) return r4_net_result(R4_NET_RESULT_FAILED, response.result, 0u);
    out->octets[0] = response.answer[0]; out->octets[1] = response.answer[1]; out->octets[2] = response.answer[2]; out->octets[3] = response.answer[3];
    return r4_net_result(R4_NET_RESULT_OK, R4OS_DNS_RESULT_OK, 0u);
}

static inline R4NetResult r4_network_connect_tcp(R4Network *network, R4SocketAddress remote, R4Timeout timeout, R4TcpSocket *out) {
    if (out != 0) *out = (R4TcpSocket){0}; if (network == 0 || out == 0) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERROR_INVALID, 0u);
    uint8_t request[6] = {remote.address.octets[0], remote.address.octets[1], remote.address.octets[2], remote.address.octets[3], 0u, 0u}; r4_net_write_u16(&request[4], remote.port);
    R4NetServiceTcpResult response = {0}; R4ServiceCallResult call = r4_network_service_call(network, "TCPSVC", R4OS_NET_SERVICE_OP_TCP_CONNECT_RESULT, request, sizeof(request), &response, sizeof(response), timeout);
    R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport;
    if (call.bytes < sizeof(response) || response.magic != R4OS_NET_SERVICE_TCP_RESULT_MAGIC || response.version != R4OS_NET_SERVICE_TCP_RESULT_VERSION) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u);
    R4NetResult result = r4_net_classify_socket(response.service_status, response.lifecycle_cause, response.result, response.bytes);
    if (result.kind != R4_NET_RESULT_OK || response.handle == 0u || (response.flags & R4OS_NET_SERVICE_TCP_FLAG_HANDLE_VALID) == 0u) return result.kind == R4_NET_RESULT_OK ? r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u) : result;
    out->network = *network; out->raw = response.handle; out->owned = 1u; out->remote = remote; return result;
}

static inline R4NetResult r4_network_listen_tcp(R4Network *network, uint16_t port, R4Timeout timeout, R4TcpListener *out) {
    if (out != 0) *out = (R4TcpListener){0}; if (network == 0 || out == 0 || port == 0u) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERROR_INVALID, 0u);
    uint8_t request[2]; r4_net_write_u16(request, port); R4NetServiceTcpResult response = {0};
    R4ServiceCallResult call = r4_network_service_call(network, "TCPSVC", R4OS_NET_SERVICE_OP_TCP_LISTEN_RESULT, request, sizeof(request), &response, sizeof(response), timeout);
    R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport;
    if (call.bytes < sizeof(response)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u);
    R4NetResult result = r4_net_classify_socket(response.service_status, response.lifecycle_cause, response.result, 0u); if (result.kind == R4_NET_RESULT_OK) { out->network = *network; out->port = port; out->owned = 1u; } return result;
}

static inline R4NetResult r4_tcp_listener_accept(R4TcpListener *listener, R4Timeout timeout, R4TcpSocket *out) {
    if (out != 0) *out = (R4TcpSocket){0}; if (!r4_tcp_listener_valid(listener) || out == 0) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u);
    uint8_t request[2]; r4_net_write_u16(request, listener->port); R4NetServiceTcpResult response = {0};
    R4ServiceCallResult call = r4_network_service_call(&listener->network, "TCPSVC", R4OS_NET_SERVICE_OP_TCP_ACCEPT_POLL_RESULT, request, sizeof(request), &response, sizeof(response), timeout);
    R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport;
    if (call.bytes < sizeof(response)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u);
    R4NetResult result = r4_net_classify_socket(response.service_status, response.lifecycle_cause, response.result, 0u);
    if (result.kind == R4_NET_RESULT_OK && response.handle != 0u && (response.flags & R4OS_NET_SERVICE_TCP_FLAG_HANDLE_VALID) != 0u) { out->network = listener->network; out->raw = response.handle; out->owned = 1u; out->remote.address.octets[0] = response.remote_ip[0]; out->remote.address.octets[1] = response.remote_ip[1]; out->remote.address.octets[2] = response.remote_ip[2]; out->remote.address.octets[3] = response.remote_ip[3]; out->remote.port = response.remote_port; return result; }
    return result.kind == R4_NET_RESULT_OK ? r4_net_result(R4_NET_RESULT_WOULD_BLOCK, response.result, 0u) : result;
}

static inline R4NetResult r4_tcp_socket_write(R4TcpSocket *socket, const uint8_t *data, uint32_t len, R4Timeout timeout) {
    if (!r4_tcp_socket_valid(socket)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (len > R4OS_NET_SERVICE_TCP_WRITE_MAX || (len != 0u && data == 0)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_NET_TX_TOO_LARGE, 0u);
    uint8_t request[4u + R4OS_NET_SERVICE_TCP_WRITE_MAX]; r4_net_write_u32(request, socket->raw); for (uint32_t i = 0u; i < len; ++i) request[4u + i] = data[i]; R4NetServiceTcpResult response = {0};
    R4ServiceCallResult call = r4_network_service_call(&socket->network, "TCPSVC", R4OS_NET_SERVICE_OP_TCP_WRITE_RESULT, request, 4u + len, &response, sizeof(response), timeout); R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport;
    R4NetResult result = r4_net_classify_socket(response.service_status, response.lifecycle_cause, response.result, response.bytes); if (result.kind == R4_NET_RESULT_CLOSED || result.kind == R4_NET_RESULT_RESET || result.kind == R4_NET_RESULT_PEER_CLOSED) socket->raw = 0u; return result;
}

static inline R4NetResult r4_tcp_socket_read(R4TcpSocket *socket, uint8_t *out, uint32_t capacity, R4Timeout timeout) {
    if (!r4_tcp_socket_valid(socket)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (capacity != 0u && out == 0) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERROR_INVALID, 0u); if (capacity > R4OS_NET_SERVICE_TCP_READ_MAX) capacity = R4OS_NET_SERVICE_TCP_READ_MAX;
    uint8_t request[6]; r4_net_write_u32(request, socket->raw); r4_net_write_u16(&request[4], (uint16_t)capacity); uint8_t response[sizeof(R4NetServiceTcpResult) + R4OS_NET_SERVICE_TCP_READ_MAX];
    R4ServiceCallResult call = r4_network_service_call(&socket->network, "TCPSVC", R4OS_NET_SERVICE_OP_TCP_READ_RESULT, request, sizeof(request), response, sizeof(response), timeout); R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport;
    if (call.bytes < sizeof(R4NetServiceTcpResult)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u); R4NetServiceTcpResult parsed; __builtin_memcpy(&parsed, response, sizeof(parsed));
    R4NetResult result = r4_net_classify_socket(parsed.service_status, parsed.lifecycle_cause, parsed.result, parsed.bytes); if (result.kind == R4_NET_RESULT_OK) { if (parsed.bytes > capacity || sizeof(parsed) + parsed.bytes > call.bytes) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u); for (uint32_t i = 0u; i < parsed.bytes; ++i) out[i] = response[sizeof(parsed) + i]; } else if (result.kind == R4_NET_RESULT_CLOSED || result.kind == R4_NET_RESULT_RESET || result.kind == R4_NET_RESULT_PEER_CLOSED) socket->raw = 0u; return result;
}

static inline R4NetResult r4_tcp_socket_close(R4TcpSocket *socket, R4Timeout timeout) {
    if (!r4_tcp_socket_valid(socket)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (!socket->owned) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_NOT_OWNED, 0u);
    uint8_t request[4]; r4_net_write_u32(request, socket->raw); R4NetServiceTcpResult response = {0}; R4ServiceCallResult call = r4_network_service_call(&socket->network, "TCPSVC", R4OS_NET_SERVICE_OP_TCP_CLOSE_RESULT, request, sizeof(request), &response, sizeof(response), timeout); R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport;
    R4NetResult result = r4_net_classify_socket(response.service_status, response.lifecycle_cause, response.result, 0u); if (result.kind == R4_NET_RESULT_OK || result.kind == R4_NET_RESULT_CLOSED) { socket->raw = 0u; return r4_net_result(R4_NET_RESULT_CLOSED, R4OS_OK, 0u); } return result;
}

static inline R4NetResult r4_tcp_listener_close(R4TcpListener *listener, R4Timeout timeout) {
    if (!r4_tcp_listener_valid(listener)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (!listener->owned) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_NOT_OWNED, 0u);
    uint8_t request[2]; r4_net_write_u16(request, listener->port); R4NetServiceTcpResult response = {0}; R4ServiceCallResult call = r4_network_service_call(&listener->network, "TCPSVC", R4OS_NET_SERVICE_OP_TCP_CLOSE_LISTEN_RESULT, request, sizeof(request), &response, sizeof(response), timeout); R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport;
    R4NetResult result = r4_net_classify_socket(response.service_status, response.lifecycle_cause, response.result, 0u); if (result.kind == R4_NET_RESULT_OK || result.kind == R4_NET_RESULT_CLOSED) { listener->port = 0u; return r4_net_result(R4_NET_RESULT_CLOSED, R4OS_OK, 0u); } return result;
}

static inline R4NetResult r4_network_bind_udp(R4Network *network, uint16_t port, R4Timeout timeout, R4UdpSocket *out) {
    if (out != 0) *out = (R4UdpSocket){0}; if (network == 0 || out == 0) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERROR_INVALID, 0u); uint8_t request[2]; r4_net_write_u16(request, port); R4NetServiceUdpResult response = {0};
    R4ServiceCallResult call = r4_network_service_call(network, "UDPSVC", R4OS_NET_SERVICE_OP_UDP_BIND_RESULT, request, sizeof(request), &response, sizeof(response), timeout); R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport;
    R4NetResult result = r4_net_classify_socket(response.service_status, response.lifecycle_cause, response.result, 0u); if (result.kind == R4_NET_RESULT_OK && response.handle != 0u && (response.flags & R4OS_NET_SERVICE_UDP_FLAG_HANDLE_VALID) != 0u) { out->network = *network; out->raw = response.handle; out->local_port = port; out->owned = 1u; return result; } return result.kind == R4_NET_RESULT_OK ? r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u) : result;
}

static inline R4NetResult r4_udp_socket_send_to(R4UdpSocket *socket, R4SocketAddress destination, const uint8_t *data, uint32_t len, R4Timeout timeout) {
    if (!r4_udp_socket_valid(socket)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (len > R4OS_NET_SERVICE_UDP_SEND_MAX || (len != 0u && data == 0)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_NET_TX_TOO_LARGE, 0u);
    uint8_t request[10u + R4OS_NET_SERVICE_UDP_SEND_MAX]; r4_net_write_u32(request, socket->raw); request[4] = destination.address.octets[0]; request[5] = destination.address.octets[1]; request[6] = destination.address.octets[2]; request[7] = destination.address.octets[3]; r4_net_write_u16(&request[8], destination.port); for (uint32_t i = 0u; i < len; ++i) request[10u + i] = data[i]; R4NetServiceUdpResult response = {0};
    R4ServiceCallResult call = r4_network_service_call(&socket->network, "UDPSVC", R4OS_NET_SERVICE_OP_UDP_SENDTO_RESULT, request, 10u + len, &response, sizeof(response), timeout); R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport; R4NetResult result = r4_net_classify_socket(response.service_status, response.lifecycle_cause, response.result, response.bytes != 0u ? response.bytes : len); if (result.kind == R4_NET_RESULT_CLOSED || result.kind == R4_NET_RESULT_RESET) socket->raw = 0u; return result;
}

static inline R4NetResult r4_udp_socket_receive_from(R4UdpSocket *socket, uint8_t *out, uint32_t capacity, R4Timeout timeout, R4Datagram *datagram) {
    if (datagram != 0) *datagram = (R4Datagram){0}; if (!r4_udp_socket_valid(socket) || datagram == 0) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (capacity != 0u && out == 0) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERROR_INVALID, 0u); if (capacity > R4OS_NET_SERVICE_UDP_READ_MAX) capacity = R4OS_NET_SERVICE_UDP_READ_MAX;
    uint8_t request[6]; r4_net_write_u32(request, socket->raw); r4_net_write_u16(&request[4], (uint16_t)capacity); uint8_t response[sizeof(R4NetServiceUdpResult) + R4OS_NET_SERVICE_UDP_READ_MAX]; R4ServiceCallResult call = r4_network_service_call(&socket->network, "UDPSVC", R4OS_NET_SERVICE_OP_UDP_RECV_RESULT, request, sizeof(request), response, sizeof(response), timeout); R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport;
    if (call.bytes < sizeof(R4NetServiceUdpResult)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u); R4NetServiceUdpResult parsed; __builtin_memcpy(&parsed, response, sizeof(parsed)); R4NetResult result = r4_net_classify_socket(parsed.service_status, parsed.lifecycle_cause, parsed.result, parsed.bytes); if (result.kind != R4_NET_RESULT_OK) { if (result.kind == R4_NET_RESULT_CLOSED || result.kind == R4_NET_RESULT_RESET) socket->raw = 0u; return result; }
    if (parsed.bytes > capacity || sizeof(parsed) + parsed.bytes > call.bytes) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u); for (uint32_t i = 0u; i < parsed.bytes; ++i) out[i] = response[sizeof(parsed) + i]; datagram->source.address.octets[0] = parsed.source_ip[0]; datagram->source.address.octets[1] = parsed.source_ip[1]; datagram->source.address.octets[2] = parsed.source_ip[2]; datagram->source.address.octets[3] = parsed.source_ip[3]; datagram->source.port = parsed.source_port; datagram->destination.address.octets[0] = parsed.dest_ip[0]; datagram->destination.address.octets[1] = parsed.dest_ip[1]; datagram->destination.address.octets[2] = parsed.dest_ip[2]; datagram->destination.address.octets[3] = parsed.dest_ip[3]; datagram->destination.port = parsed.dest_port; datagram->bytes = parsed.bytes; return result;
}

static inline R4NetResult r4_udp_socket_close(R4UdpSocket *socket, R4Timeout timeout) {
    if (!r4_udp_socket_valid(socket)) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_CLOSED, 0u); if (!socket->owned) return r4_net_result(R4_NET_RESULT_FAILED, R4OS_ERR_NOT_OWNED, 0u); uint8_t request[4]; r4_net_write_u32(request, socket->raw); R4NetServiceUdpResult response = {0}; R4ServiceCallResult call = r4_network_service_call(&socket->network, "UDPSVC", R4OS_NET_SERVICE_OP_UDP_CLOSE_RESULT, request, sizeof(request), &response, sizeof(response), timeout); R4NetResult transport = r4_net_from_call(call); if (transport.kind != R4_NET_RESULT_OK) return transport; R4NetResult result = r4_net_classify_socket(response.service_status, response.lifecycle_cause, response.result, 0u); if (result.kind == R4_NET_RESULT_OK || result.kind == R4_NET_RESULT_CLOSED) { socket->raw = 0u; return r4_net_result(R4_NET_RESULT_CLOSED, R4OS_OK, 0u); } return result;
}

#endif
