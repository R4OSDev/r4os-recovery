#ifndef R4OS_APP_SERVICES_H
#define R4OS_APP_SERVICES_H

#include "app_contract.h"

typedef struct R4Services { R4App *app; } R4Services;

typedef struct R4ServiceConnection {
    R4App *app;
    uint32_t raw;
    uint8_t owned;
    uint8_t reserved[3];
    R4ServiceInfo info;
} R4ServiceConnection;

typedef struct R4ServiceEndpoint {
    R4App *app;
    uint32_t raw;
    uint8_t owned;
    uint8_t reserved[3];
    R4ServiceInfo info;
} R4ServiceEndpoint;

typedef enum R4ServiceCallKind {
    R4_SERVICE_CALL_RESPONSE = 0,
    R4_SERVICE_CALL_TIMED_OUT = 1,
    R4_SERVICE_CALL_REMOTE_FAILURE = 2,
    R4_SERVICE_CALL_FAILED = 3
} R4ServiceCallKind;

typedef struct R4ServiceCallResult {
    R4ServiceCallKind kind;
    int32_t raw_code;
    uint32_t bytes;
    R4ServiceMessageHeader header;
} R4ServiceCallResult;

typedef enum R4EndpointWaitKind {
    R4_ENDPOINT_WAIT_READY = 0,
    R4_ENDPOINT_WAIT_TIMED_OUT = 1,
    R4_ENDPOINT_WAIT_FAILED = 2
} R4EndpointWaitKind;

typedef struct R4EndpointWaitResult {
    R4EndpointWaitKind kind;
    int32_t raw_code;
    uint32_t pending;
} R4EndpointWaitResult;

typedef enum R4EndpointReceiveKind {
    R4_ENDPOINT_RECEIVE_MESSAGE = 0,
    R4_ENDPOINT_RECEIVE_WOULD_BLOCK = 1,
    R4_ENDPOINT_RECEIVE_FAILED = 2
} R4EndpointReceiveKind;

typedef struct R4EndpointReceiveResult {
    R4EndpointReceiveKind kind;
    int32_t raw_code;
    uint32_t bytes;
    R4ServiceMessageHeader header;
} R4EndpointReceiveResult;

static inline R4Services r4_app_services(R4App *app) { R4Services value = {app}; return value; }
static inline int r4_service_connection_valid(const R4ServiceConnection *connection) { return connection != 0 && connection->app != 0 && connection->raw != 0u; }
static inline int r4_service_endpoint_valid(const R4ServiceEndpoint *endpoint) { return endpoint != 0 && endpoint->app != 0 && endpoint->raw != 0u; }

static inline int r4_services_available(const R4Services *services) {
    const R4XStartR4Sys *table = services != 0 && services->app != 0 ? services->app->system.table : 0;
    return table != 0 && table->service_open != 0 && table->service_close != 0 && table->service_call != 0 &&
        table->service_endpoint_register != 0 && table->service_endpoint_unregister != 0 &&
        table->service_endpoint_wait != 0 && table->service_endpoint_recv != 0 && table->service_endpoint_reply != 0;
}

static inline uint32_t r4_services_monotonic_hz(R4App *app) {
    if (app == 0 || app->system.table == 0 || app->system.table->time_state == 0) return 0u;
    R4TimeState state = {0};
    ((R4SysTimeStateFn)(uintptr_t)app->system.table->time_state)(&state);
    return state.monotonic_hz;
}

static inline int32_t r4_services_open(R4Services *services, const char *name, R4ServiceConnection *out) {
    if (out != 0) *out = (R4ServiceConnection){0};
    const R4XStartR4Sys *table = services != 0 && services->app != 0 ? services->app->system.table : 0;
    if (table == 0 || table->service_open == 0 || name == 0 || out == 0) return R4OS_ERR_NO_FN;
    R4ServiceInfo info = {0};
    int32_t raw = ((R4SysServiceOpenFn)(uintptr_t)table->service_open)((const uint8_t *)name, &info);
    if (raw != R4OS_SERVICE_API_RESULT_OK || info.handle == 0u) return raw == R4OS_SERVICE_API_RESULT_OK ? R4OS_SERVICE_API_RESULT_NO_ENDPOINT : raw;
    out->app = services->app; out->raw = info.handle; out->owned = 1u; out->info = info;
    return R4OS_SERVICE_API_RESULT_OK;
}

static inline R4ServiceCallResult r4_service_connection_call(R4ServiceConnection *connection, uint16_t op, const void *request, uint32_t request_len, void *response, uint32_t response_capacity, R4Timeout timeout) {
    R4ServiceCallResult result = {R4_SERVICE_CALL_FAILED, R4OS_ERR_CLOSED, 0u, {0}};
    if (!r4_service_connection_valid(connection)) return result;
    if (request_len > R4OS_SERVICE_API_MAX_PAYLOAD || response_capacity > R4OS_SERVICE_API_MAX_PAYLOAD || (request_len != 0u && request == 0) || (response_capacity != 0u && response == 0)) { result.raw_code = R4OS_SERVICE_API_RESULT_INVALID; return result; }
    const R4XStartR4Sys *table = connection->app->system.table;
    if (table == 0 || table->service_call == 0) { result.raw_code = R4OS_ERR_NO_FN; return result; }
    uint64_t ticks = 0u;
    if (r4_timeout_to_ticks(timeout, r4_services_monotonic_hz(connection->app), &ticks) != R4OS_OK) { result.raw_code = R4OS_SERVICE_API_RESULT_INVALID; return result; }
    R4ServiceMessageHeader header = {0};
    int32_t raw = ((R4SysServiceCallFn)(uintptr_t)table->service_call)(connection->raw, op, (const uint8_t *)request, request_len, &header, (uint8_t *)response, response_capacity, ticks);
    result.header = header; result.raw_code = raw;
    if (raw == R4OS_SERVICE_API_RESULT_TIMEOUT || header.status == R4OS_SERVICE_API_RESULT_TIMEOUT) { result.kind = R4_SERVICE_CALL_TIMED_OUT; return result; }
    if (raw == R4OS_SERVICE_API_RESULT_BAD_HANDLE || raw == R4OS_SERVICE_API_RESULT_NOT_RUNNING) connection->raw = 0u;
    if (raw < 0) return result;
    if (header.status != R4OS_SERVICE_API_RESULT_OK) { result.kind = R4_SERVICE_CALL_REMOTE_FAILURE; result.raw_code = header.status; return result; }
    result.kind = R4_SERVICE_CALL_RESPONSE; result.raw_code = R4OS_SERVICE_API_RESULT_OK; result.bytes = (uint32_t)raw;
    return result;
}

static inline R4ServiceCallResult r4_service_connection_call_struct(R4ServiceConnection *connection, uint16_t op, const void *request, uint32_t request_size, void *response, uint32_t response_size, R4Timeout timeout) {
    R4ServiceCallResult result = r4_service_connection_call(connection, op, request, request_size, response, response_size, timeout);
    if (result.kind == R4_SERVICE_CALL_RESPONSE && result.bytes != response_size) { result.kind = R4_SERVICE_CALL_FAILED; result.raw_code = R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL; }
    return result;
}

static inline int32_t r4_service_connection_close(R4ServiceConnection *connection) {
    if (!r4_service_connection_valid(connection)) return R4OS_ERR_CLOSED;
    if (!connection->owned) return R4OS_ERR_NOT_OWNED;
    const R4XStartR4Sys *table = connection->app->system.table;
    if (table == 0 || table->service_close == 0) return R4OS_ERR_NO_FN;
    int32_t raw = ((R4SysServiceCloseFn)(uintptr_t)table->service_close)(connection->raw);
    if (raw == R4OS_SERVICE_API_RESULT_OK || raw == R4OS_SERVICE_API_RESULT_BAD_HANDLE) {
        *connection = (R4ServiceConnection){0};
        return raw == R4OS_SERVICE_API_RESULT_OK ? raw : R4OS_ERR_CLOSED;
    }
    return raw;
}

static inline int32_t r4_services_register(R4Services *services, const char *name, uint32_t flags, R4ServiceEndpoint *out) {
    if (out != 0) *out = (R4ServiceEndpoint){0};
    const R4XStartR4Sys *table = services != 0 && services->app != 0 ? services->app->system.table : 0;
    if (table == 0 || table->service_endpoint_register == 0 || name == 0 || out == 0) return R4OS_ERR_NO_FN;
    R4ServiceInfo info = {0};
    int32_t raw = ((R4SysServiceEndpointRegisterFn)(uintptr_t)table->service_endpoint_register)((const uint8_t *)name, flags, &info);
    if (raw != R4OS_SERVICE_API_RESULT_OK || info.handle == 0u) return raw == R4OS_SERVICE_API_RESULT_OK ? R4OS_SERVICE_API_RESULT_NO_ENDPOINT : raw;
    out->app = services->app; out->raw = info.handle; out->owned = 1u; out->info = info;
    return R4OS_SERVICE_API_RESULT_OK;
}

static inline R4EndpointWaitResult r4_service_endpoint_wait(R4ServiceEndpoint *endpoint, R4Timeout timeout) {
    R4EndpointWaitResult result = {R4_ENDPOINT_WAIT_FAILED, R4OS_ERR_CLOSED, 0u};
    if (!r4_service_endpoint_valid(endpoint)) return result;
    const R4XStartR4Sys *table = endpoint->app->system.table;
    if (table == 0 || table->service_endpoint_wait == 0) { result.raw_code = R4OS_ERR_NO_FN; return result; }
    uint64_t ticks = 0u;
    if (r4_timeout_to_ticks(timeout, r4_services_monotonic_hz(endpoint->app), &ticks) != R4OS_OK) { result.raw_code = R4OS_SERVICE_API_RESULT_INVALID; return result; }
    int32_t raw = ((R4SysServiceEndpointWaitFn)(uintptr_t)table->service_endpoint_wait)(endpoint->raw, ticks);
    result.raw_code = raw;
    if (raw == 0) { result.kind = R4_ENDPOINT_WAIT_TIMED_OUT; return result; }
    if (raw == R4OS_SERVICE_API_RESULT_BAD_HANDLE || raw == R4OS_SERVICE_API_RESULT_NOT_RUNNING) endpoint->raw = 0u;
    if (raw < 0) return result;
    result.kind = R4_ENDPOINT_WAIT_READY; result.raw_code = R4OS_SERVICE_API_RESULT_OK; result.pending = (uint32_t)raw;
    return result;
}

static inline R4EndpointReceiveResult r4_service_endpoint_recv(R4ServiceEndpoint *endpoint, void *out, uint32_t capacity) {
    R4EndpointReceiveResult result = {R4_ENDPOINT_RECEIVE_FAILED, R4OS_ERR_CLOSED, 0u, {0}};
    if (!r4_service_endpoint_valid(endpoint)) return result;
    if (capacity > R4OS_SERVICE_API_MAX_PAYLOAD || (capacity != 0u && out == 0)) { result.raw_code = R4OS_SERVICE_API_RESULT_INVALID; return result; }
    const R4XStartR4Sys *table = endpoint->app->system.table;
    if (table == 0 || table->service_endpoint_recv == 0) { result.raw_code = R4OS_ERR_NO_FN; return result; }
    R4ServiceMessageHeader header = {0};
    int32_t raw = ((R4SysServiceEndpointRecvFn)(uintptr_t)table->service_endpoint_recv)(endpoint->raw, &header, (uint8_t *)out, capacity);
    result.header = header; result.raw_code = raw;
    if (raw == 0 && header.magic != R4OS_SERVICE_API_MAGIC) { result.kind = R4_ENDPOINT_RECEIVE_WOULD_BLOCK; return result; }
    if (raw == R4OS_SERVICE_API_RESULT_BAD_HANDLE || raw == R4OS_SERVICE_API_RESULT_NOT_RUNNING) endpoint->raw = 0u;
    if (raw < 0) return result;
    result.kind = R4_ENDPOINT_RECEIVE_MESSAGE; result.raw_code = R4OS_SERVICE_API_RESULT_OK; result.bytes = (uint32_t)raw;
    return result;
}

static inline int32_t r4_service_endpoint_reply(R4ServiceEndpoint *endpoint, uint32_t request_id, int32_t status, const void *payload, uint32_t payload_len) {
    if (!r4_service_endpoint_valid(endpoint)) return R4OS_ERR_CLOSED;
    if (payload_len > R4OS_SERVICE_API_MAX_PAYLOAD || (payload_len != 0u && payload == 0)) return R4OS_SERVICE_API_RESULT_PAYLOAD_TOO_LARGE;
    const R4XStartR4Sys *table = endpoint->app->system.table;
    if (table == 0 || table->service_endpoint_reply == 0) return R4OS_ERR_NO_FN;
    int32_t raw = ((R4SysServiceEndpointReplyFn)(uintptr_t)table->service_endpoint_reply)(endpoint->raw, request_id, status, (const uint8_t *)payload, payload_len);
    if (raw == R4OS_SERVICE_API_RESULT_BAD_HANDLE || raw == R4OS_SERVICE_API_RESULT_NOT_RUNNING) endpoint->raw = 0u;
    return raw;
}

static inline int32_t r4_service_endpoint_unregister(R4ServiceEndpoint *endpoint) {
    if (!r4_service_endpoint_valid(endpoint)) return R4OS_ERR_CLOSED;
    if (!endpoint->owned) return R4OS_ERR_NOT_OWNED;
    const R4XStartR4Sys *table = endpoint->app->system.table;
    if (table == 0 || table->service_endpoint_unregister == 0) return R4OS_ERR_NO_FN;
    int32_t raw = ((R4SysServiceEndpointUnregisterFn)(uintptr_t)table->service_endpoint_unregister)(endpoint->raw);
    if (raw == R4OS_SERVICE_API_RESULT_OK || raw == R4OS_SERVICE_API_RESULT_BAD_HANDLE) {
        *endpoint = (R4ServiceEndpoint){0};
        return raw == R4OS_SERVICE_API_RESULT_OK ? raw : R4OS_ERR_CLOSED;
    }
    return raw;
}

#endif
