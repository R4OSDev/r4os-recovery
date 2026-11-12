#ifndef R4OS_APP_SERVICES_H
#define R4OS_APP_SERVICES_H

#include "app_contract.h"
#include "poll_budget.h"

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

#define R4_SERVICES_HAS(table, field) ((table) != 0 && (table)->size >= offsetof(R4XStartR4Sys, field) + sizeof(uintptr_t) && (table)->field != 0)

static inline R4Services r4_app_services(R4App *app) { R4Services value = {app}; return value; }

/* Caller owns cursor and page buffers. Only END proves completeness; on
 * RESTART discard all accumulated pages. No fixed total service capacity. */
static inline int r4_services_inventory_available(const R4Services *services) {
    const R4Sys *sys = services != 0 && services->app != 0 ? &services->app->system : 0;
    return R4SYS_HAS(sys, service_inventory_page) && R4SYS_HAS(sys, service_control_bound);
}

static inline int32_t r4_services_inventory_page(const R4Services *services, R4ServiceInventoryCursor *cursor, R4ServiceInventoryRow *rows, uint32_t capacity) {
    if (cursor == 0 || rows == 0 || capacity == 0u) return R4OS_SERVICE_API_RESULT_INVALID;
    const R4Sys *sys = services != 0 && services->app != 0 ? &services->app->system : 0;
    if (!R4SYS_HAS(sys, service_inventory_page)) return R4OS_ERR_NO_FN;
    return ((R4SysServiceInventoryPageFn)(uintptr_t)R4SYS_SLOT(sys, service_inventory_page))(cursor, rows, capacity);
}

static inline int32_t r4_services_control_bound(const R4Services *services, const R4ServiceControlRequest *request) {
    if (request == 0) return R4OS_SERVICE_API_RESULT_INVALID;
    const R4Sys *sys = services != 0 && services->app != 0 ? &services->app->system : 0;
    if (!R4SYS_HAS(sys, service_control_bound)) return R4OS_ERR_NO_FN;
    return ((R4SysServiceControlBoundFn)(uintptr_t)R4SYS_SLOT(sys, service_control_bound))(request);
}

static inline R4ServiceControlRequest r4_service_control_request(const R4ServiceInventoryRow *row, uint32_t operation) {
    R4ServiceControlRequest request = {0};
    if (row != 0) {
        request.registration_id = row->registration_id;
        request.start_generation = row->start_generation;
        request.process = row->process;
    }
    request.operation = operation;
    return request;
}
static inline int r4_service_connection_valid(const R4ServiceConnection *connection) { return connection != 0 && connection->app != 0 && connection->raw != 0u; }
static inline int r4_service_endpoint_valid(const R4ServiceEndpoint *endpoint) { return endpoint != 0 && endpoint->app != 0 && endpoint->raw != 0u; }

static inline int r4_services_available(const R4Services *services) {
    const R4Sys *sys = services != 0 && services->app != 0 ? &services->app->system : 0;
    return R4SYS_HAS(sys, service_open) &&
        R4SYS_HAS(sys, service_close) &&
        R4SYS_HAS(sys, service_call) &&
        R4SYS_HAS(sys, service_endpoint_register) &&
        R4SYS_HAS(sys, service_endpoint_unregister) &&
        R4SYS_HAS(sys, service_endpoint_wait) &&
        R4SYS_HAS(sys, service_endpoint_recv) &&
        R4SYS_HAS(sys, service_endpoint_reply);
}

/* One generation-validated metadata/identity snapshot. A terminal row may
 * return its last retained process handle; this value grants no retention. */
static inline int32_t r4_services_bound_detail(const R4Services *services, const char *name, R4ServiceDetail *detail, R4ProgramProcessHandle *process) {
    if (detail != 0) *detail = (R4ServiceDetail){0};
    if (process != 0) *process = (R4ProgramProcessHandle){0};
    if (name == 0 || detail == 0 || process == 0) return R4OS_SERVICE_API_RESULT_INVALID;
    const R4Sys *sys = services != 0 && services->app != 0 ? &services->app->system : 0;
    if (!R4SYS_HAS(sys, service_bound_detail)) return R4OS_ERR_NO_FN;
    return ((R4SysServiceBoundDetailFn)(uintptr_t)R4SYS_SLOT(sys, service_bound_detail))((const uint8_t *)name, detail, process);
}

static inline uint32_t r4_services_monotonic_hz(R4App *app) {
    if (app == 0 || !R4SYS_HAS(&app->system, monotonic_clock)) return 0u;
    R4MonotonicClockInfo clock = {0};
    int32_t rc = ((R4SysMonotonicClockFn)(uintptr_t)R4SYS_SLOT(&app->system, monotonic_clock))(&clock);
    if (rc <= 0 || !(clock.flags & R4OS_MONOTONIC_CLOCK_FLAG_VALID) ||
        clock.frequency_hz != R4OS_MONOTONIC_CLOCK_FREQUENCY_HZ) return 0u;
    /* Same logical scale as ticks()/TimeState, read anew for each conversion.
       event_effective_hz describes the physical timer's rounded rate. */
    return clock.event_requested_hz;
}

/* A replacement process is rejected before Close; the original active
 * process handle must come from the generation-bound detail snapshot. */
static inline int32_t r4_services_stop_bound(const R4Services *services, const char *name, const R4ProgramProcessHandle *process, R4Timeout timeout, R4ServiceInfo *out) {
    if (out != 0) *out = (R4ServiceInfo){0};
    if (name == 0 || process == 0 || out == 0) return R4OS_SERVICE_API_RESULT_INVALID;
    const R4Sys *sys = services != 0 && services->app != 0 ? &services->app->system : 0;
    if (!R4SYS_HAS(sys, service_stop_bound)) return R4OS_ERR_NO_FN;
    uint64_t ticks = 0;
    if (r4_timeout_to_ticks(timeout, r4_services_monotonic_hz(services->app), &ticks) != R4OS_OK) return R4OS_SERVICE_API_RESULT_INVALID;
    return ((R4SysServiceStopBoundFn)(uintptr_t)R4SYS_SLOT(sys, service_stop_bound))((const uint8_t *)name, process, out, ticks);
}

static inline int32_t r4_services_open(R4Services *services, const char *name, R4ServiceConnection *out) {
    if (out != 0) *out = (R4ServiceConnection){0};
    const R4Sys *sys = services != 0 && services->app != 0 ? &services->app->system : 0;
    if (!R4SYS_HAS(sys, service_open) || name == 0 || out == 0) return R4OS_ERR_NO_FN;
    R4ServiceInfo info = {0};
    int32_t raw = ((R4SysServiceOpenFn)(uintptr_t)R4SYS_SLOT(sys, service_open))((const uint8_t *)name, &info);
    if (raw != R4OS_SERVICE_API_RESULT_OK || info.handle == 0u) return raw == R4OS_SERVICE_API_RESULT_OK ? R4OS_SERVICE_API_RESULT_NO_ENDPOINT : raw;
    out->app = services->app; out->raw = info.handle; out->owned = 1u; out->info = info;
    return R4OS_SERVICE_API_RESULT_OK;
}

/* Internal tick budget: callers carrying an absolute deadline must not
 * round remaining ticks through nanoseconds and start another full budget. */
static inline R4ServiceCallResult r4_service_connection_call_ticks(R4ServiceConnection *connection, uint16_t op, const void *request, uint32_t request_len, void *response, uint32_t response_capacity, uint64_t ticks) {
    R4ServiceCallResult result = {R4_SERVICE_CALL_FAILED, R4OS_ERR_CLOSED, 0u, {0}};
    if (!r4_service_connection_valid(connection)) return result;
    if (request_len > R4OS_SERVICE_API_MAX_PAYLOAD || response_capacity > R4OS_SERVICE_API_MAX_PAYLOAD || (request_len != 0u && request == 0) || (response_capacity != 0u && response == 0)) { result.raw_code = R4OS_SERVICE_API_RESULT_INVALID; return result; }
    const R4Sys *sys = &connection->app->system;
    if (!R4SYS_HAS(sys, service_call)) { result.raw_code = R4OS_ERR_NO_FN; return result; }
    R4ServiceMessageHeader header = {0};
    int32_t raw = ((R4SysServiceCallFn)(uintptr_t)R4SYS_SLOT(sys, service_call))(connection->raw, op, (const uint8_t *)request, request_len, &header, (uint8_t *)response, response_capacity, ticks);
    result.header = header; result.raw_code = raw;
    if (raw == R4OS_SERVICE_API_RESULT_TIMEOUT || header.status == R4OS_SERVICE_API_RESULT_TIMEOUT) { result.kind = R4_SERVICE_CALL_TIMED_OUT; return result; }
    if (raw == R4OS_SERVICE_API_RESULT_BAD_HANDLE || raw == R4OS_SERVICE_API_RESULT_NOT_RUNNING) connection->raw = 0u;
    if (raw < 0) return result;
    if (header.status != R4OS_SERVICE_API_RESULT_OK) { result.kind = R4_SERVICE_CALL_REMOTE_FAILURE; result.raw_code = header.status; return result; }
    result.kind = R4_SERVICE_CALL_RESPONSE; result.raw_code = R4OS_SERVICE_API_RESULT_OK; result.bytes = (uint32_t)raw;
    return result;
}

static inline R4ServiceCallResult r4_service_connection_call(R4ServiceConnection *connection, uint16_t op, const void *request, uint32_t request_len, void *response, uint32_t response_capacity, R4Timeout timeout) {
    uint64_t ticks = 0u;
    if (!r4_service_connection_valid(connection)) return (R4ServiceCallResult){R4_SERVICE_CALL_FAILED, R4OS_ERR_CLOSED, 0u, {0}};
    if (request_len > R4OS_SERVICE_API_MAX_PAYLOAD || response_capacity > R4OS_SERVICE_API_MAX_PAYLOAD || (request_len != 0u && request == 0) || (response_capacity != 0u && response == 0)) return (R4ServiceCallResult){R4_SERVICE_CALL_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u, {0}};
    if (!R4SYS_HAS(&connection->app->system, service_call)) return (R4ServiceCallResult){R4_SERVICE_CALL_FAILED, R4OS_ERR_NO_FN, 0u, {0}};
    if (connection->app->system.generation2) {
        R4SdkRpcBudget operation;
        R4SysMonotonicClockFn clock = R4SYS_HAS(&connection->app->system,monotonic_clock) ? (R4SysMonotonicClockFn)(uintptr_t)R4SYS_SLOT(&connection->app->system,monotonic_clock) : 0;
        int32_t rc = R4SdkRpcBudgetInit(clock,&timeout,&operation);
        if (!rc) rc = R4SdkRpcBudgetRemaining(&operation,&ticks);
        if (rc) return (R4ServiceCallResult){rc==R4OS_SERVICE_API_RESULT_TIMEOUT ? R4_SERVICE_CALL_TIMED_OUT : R4_SERVICE_CALL_FAILED,rc,0u,{0}};
    } else if (r4_timeout_to_ticks(timeout, r4_services_monotonic_hz(connection->app), &ticks) != R4OS_OK) return (R4ServiceCallResult){R4_SERVICE_CALL_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u, {0}};
    return r4_service_connection_call_ticks(connection, op, request, request_len, response, response_capacity, ticks);
}

static inline R4ServiceCallResult r4_service_connection_call_struct(R4ServiceConnection *connection, uint16_t op, const void *request, uint32_t request_size, void *response, uint32_t response_size, R4Timeout timeout) {
    R4ServiceCallResult result = r4_service_connection_call(connection, op, request, request_size, response, response_size, timeout);
    if (result.kind == R4_SERVICE_CALL_RESPONSE && result.bytes != response_size) { result.kind = R4_SERVICE_CALL_FAILED; result.raw_code = R4OS_SERVICE_API_RESULT_BUFFER_TOO_SMALL; }
    return result;
}

static inline int32_t r4_service_connection_close(R4ServiceConnection *connection) {
    if (!r4_service_connection_valid(connection)) return R4OS_ERR_CLOSED;
    if (!connection->owned) return R4OS_ERR_NOT_OWNED;
    const R4Sys *sys = &connection->app->system;
    if (!R4SYS_HAS(sys, service_close)) return R4OS_ERR_NO_FN;
    int32_t raw = ((R4SysServiceCloseFn)(uintptr_t)R4SYS_SLOT(sys, service_close))(connection->raw);
    if (raw == R4OS_SERVICE_API_RESULT_OK || raw == R4OS_SERVICE_API_RESULT_BAD_HANDLE) {
        *connection = (R4ServiceConnection){0};
        return raw == R4OS_SERVICE_API_RESULT_OK ? raw : R4OS_ERR_CLOSED;
    }
    return raw;
}

static inline int32_t r4_services_register(R4Services *services, const char *name, uint32_t flags, R4ServiceEndpoint *out) {
    if (out != 0) *out = (R4ServiceEndpoint){0};
    const R4Sys *sys = services != 0 && services->app != 0 ? &services->app->system : 0;
    if (!R4SYS_HAS(sys, service_endpoint_register) || name == 0 || out == 0) return R4OS_ERR_NO_FN;
    R4ServiceInfo info = {0};
    int32_t raw = ((R4SysServiceEndpointRegisterFn)(uintptr_t)R4SYS_SLOT(sys, service_endpoint_register))((const uint8_t *)name, flags, &info);
    if (raw != R4OS_SERVICE_API_RESULT_OK || info.handle == 0u) return raw == R4OS_SERVICE_API_RESULT_OK ? R4OS_SERVICE_API_RESULT_NO_ENDPOINT : raw;
    out->app = services->app; out->raw = info.handle; out->owned = 1u; out->info = info;
    return R4OS_SERVICE_API_RESULT_OK;
}

static inline R4EndpointWaitResult r4_service_endpoint_wait(R4ServiceEndpoint *endpoint, R4Timeout timeout) {
    R4EndpointWaitResult result = {R4_ENDPOINT_WAIT_FAILED, R4OS_ERR_CLOSED, 0u};
    if (!r4_service_endpoint_valid(endpoint)) return result;
    const R4Sys *sys = &endpoint->app->system;
    if (!R4SYS_HAS(sys, service_endpoint_wait)) { result.raw_code = R4OS_ERR_NO_FN; return result; }
    uint64_t ticks = 0u;
    if (r4_timeout_to_ticks(timeout, r4_services_monotonic_hz(endpoint->app), &ticks) != R4OS_OK) { result.raw_code = R4OS_SERVICE_API_RESULT_INVALID; return result; }
    int32_t raw = ((R4SysServiceEndpointWaitFn)(uintptr_t)R4SYS_SLOT(sys, service_endpoint_wait))(endpoint->raw, ticks);
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
    const R4Sys *sys = &endpoint->app->system;
    if (!R4SYS_HAS(sys, service_endpoint_recv)) { result.raw_code = R4OS_ERR_NO_FN; return result; }
    R4ServiceMessageHeader header = {0};
    int32_t raw = ((R4SysServiceEndpointRecvFn)(uintptr_t)R4SYS_SLOT(sys, service_endpoint_recv))(endpoint->raw, &header, (uint8_t *)out, capacity);
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
    const R4Sys *sys = &endpoint->app->system;
    if (!R4SYS_HAS(sys, service_endpoint_reply)) return R4OS_ERR_NO_FN;
    int32_t raw = ((R4SysServiceEndpointReplyFn)(uintptr_t)R4SYS_SLOT(sys, service_endpoint_reply))(endpoint->raw, request_id, status, (const uint8_t *)payload, payload_len);
    if (raw == R4OS_SERVICE_API_RESULT_BAD_HANDLE || raw == R4OS_SERVICE_API_RESULT_NOT_RUNNING) endpoint->raw = 0u;
    return raw;
}

static inline int32_t r4_service_endpoint_unregister(R4ServiceEndpoint *endpoint) {
    if (!r4_service_endpoint_valid(endpoint)) return R4OS_ERR_CLOSED;
    if (!endpoint->owned) return R4OS_ERR_NOT_OWNED;
    const R4Sys *sys = &endpoint->app->system;
    if (!R4SYS_HAS(sys, service_endpoint_unregister)) return R4OS_ERR_NO_FN;
    int32_t raw = ((R4SysServiceEndpointUnregisterFn)(uintptr_t)R4SYS_SLOT(sys, service_endpoint_unregister))(endpoint->raw);
    if (raw == R4OS_SERVICE_API_RESULT_OK || raw == R4OS_SERVICE_API_RESULT_BAD_HANDLE) {
        *endpoint = (R4ServiceEndpoint){0};
        return raw == R4OS_SERVICE_API_RESULT_OK ? raw : R4OS_ERR_CLOSED;
    }
    return raw;
}

#endif
