#ifndef R4OS_APP_TRAY_H
#define R4OS_APP_TRAY_H

#include "app_services.h"

#define R4_TRAY_SERVICE_NAME "WINSVC"

typedef struct R4Tray {
    R4App *app;
    R4ProgramProcessHandle owner;
    uint64_t desktop_epoch;
} R4Tray;

typedef struct R4TrayItem {
    uint64_t id;
    uint64_t revision;
    uint32_t flags;
    uint32_t status_flags;
    const uint8_t *tooltip;
    uint16_t tooltip_length;
    const uint32_t *icon;
} R4TrayItem;

typedef enum R4TrayCallKind {
    R4_TRAY_CALL_RESPONSE = 0,
    R4_TRAY_CALL_TIMED_OUT = 1,
    R4_TRAY_CALL_NO_SERVICE = 2,
    R4_TRAY_CALL_FAILED = 3
} R4TrayCallKind;

typedef struct R4TrayCallResult {
    R4TrayCallKind kind;
    int32_t raw_code;
    uint8_t epoch_changed;
    uint8_t reserved[3];
    R4TrayServiceResponse response;
} R4TrayCallResult;

static inline int r4_tray_owner_equal(R4ProgramProcessHandle left, R4ProgramProcessHandle right) {
    return left.instance_id == right.instance_id && left.reserved == right.reserved && left.generation == right.generation;
}

static inline int r4_tray_owner_valid(R4ProgramProcessHandle owner) {
    return owner.instance_id != 0u && owner.reserved == 0u && owner.generation != 0u;
}

static inline int32_t r4_app_tray(R4App *app, R4Tray *out) {
    if (out != 0) *out = (R4Tray){0};
    if (app == 0 || out == 0 || app->context == 0 || app->system.table == 0 ||
        app->system.table->program_open_handle == 0 || app->context->instance_id == 0u ||
        app->context->instance_id > UINT32_MAX)
    {
        return R4OS_ERR_NO_FN;
    }
    R4ProgramProcessHandle owner = {0};
    int32_t raw = ((R4SysProgramOpenHandleFn)(uintptr_t)app->system.table->program_open_handle)((uint32_t)app->context->instance_id, &owner);
    if (raw != R4OS_PROGRAM_HANDLE_OK || !r4_tray_owner_valid(owner)) {
        return raw == R4OS_PROGRAM_HANDLE_OK ? R4OS_PROGRAM_HANDLE_ERROR_INVALID : raw;
    }
    out->app = app;
    out->owner = owner;
    return R4OS_PROGRAM_HANDLE_OK;
}

static inline R4TrayServiceRequest r4_tray_request(R4ProgramProcessHandle owner) {
    R4TrayServiceRequest request = {0};
    request.magic = R4OS_TRAY_SERVICE_REQUEST_MAGIC;
    request.version = R4OS_TRAY_SERVICE_REQUEST_VERSION;
    request.size = (uint16_t)sizeof(R4TrayServiceRequest);
    request.owner = owner;
    return request;
}

static inline int r4_tray_response_valid(const R4TrayServiceResponse *response, R4ProgramProcessHandle owner) {
    return response != 0 && response->magic == R4OS_TRAY_SERVICE_RESPONSE_MAGIC &&
        response->version == R4OS_TRAY_SERVICE_RESPONSE_VERSION &&
        response->size == sizeof(R4TrayServiceResponse) &&
        (response->desktop_epoch != 0u || response->result == R4OS_TRAY_RESULT_NOT_FOUND) &&
        response->capacity == R4OS_TRAY_MAX_ITEMS && r4_tray_owner_equal(response->owner, owner);
}

static inline R4TrayCallResult r4_tray_call(R4Tray *tray, uint16_t op, const R4TrayServiceRequest *request, R4Timeout timeout) {
    R4TrayCallResult result = {R4_TRAY_CALL_FAILED, R4OS_ERR_CLOSED, 0u, {0}, {0}};
    if (tray == 0 || tray->app == 0 || !r4_tray_owner_valid(tray->owner) || request == 0 ||
        !r4_tray_owner_equal(request->owner, tray->owner))
    {
        result.raw_code = R4OS_TRAY_RESULT_BAD_REQUEST;
        return result;
    }

    R4Services services = r4_app_services(tray->app);
    R4ServiceConnection connection = {0};
    int32_t opened = r4_services_open(&services, R4_TRAY_SERVICE_NAME, &connection);
    if (opened != R4OS_SERVICE_API_RESULT_OK) {
        result.kind = R4_TRAY_CALL_NO_SERVICE;
        result.raw_code = opened;
        return result;
    }

    R4ServiceCallResult called = r4_service_connection_call_struct(
        &connection, op, request, (uint32_t)sizeof(*request), &result.response,
        (uint32_t)sizeof(result.response), timeout);
    (void)r4_service_connection_close(&connection);
    if (called.kind == R4_SERVICE_CALL_TIMED_OUT) {
        result.kind = R4_TRAY_CALL_TIMED_OUT;
        result.raw_code = R4OS_TRAY_RESULT_TIMEOUT;
        return result;
    }
    if (called.kind != R4_SERVICE_CALL_RESPONSE) {
        result.raw_code = called.raw_code;
        if (called.raw_code == R4OS_SERVICE_API_RESULT_NO_ENDPOINT ||
            called.raw_code == R4OS_SERVICE_API_RESULT_NOT_RUNNING ||
            called.raw_code == R4OS_SERVICE_API_RESULT_BAD_HANDLE)
        {
            result.kind = R4_TRAY_CALL_NO_SERVICE;
        }
        return result;
    }
    if (!r4_tray_response_valid(&result.response, tray->owner)) {
        result.raw_code = R4OS_SERVICE_API_RESULT_INVALID;
        return result;
    }

    result.kind = R4_TRAY_CALL_RESPONSE;
    result.raw_code = result.response.result;
    result.epoch_changed = tray->desktop_epoch != 0u && tray->desktop_epoch != result.response.desktop_epoch;
    tray->desktop_epoch = result.response.desktop_epoch;
    return result;
}

static inline R4TrayCallResult r4_tray_status(R4Tray *tray, uint64_t item_id, R4Timeout timeout) {
    R4TrayServiceRequest request = r4_tray_request(tray != 0 ? tray->owner : (R4ProgramProcessHandle){0});
    request.item_id = item_id;
    return r4_tray_call(tray, R4OS_TRAY_SERVICE_OP_STATUS, &request, timeout);
}

static inline R4TrayCallResult r4_tray_upsert(R4Tray *tray, const R4TrayItem *item, R4Timeout timeout) {
    R4TrayServiceRequest request = r4_tray_request(tray != 0 ? tray->owner : (R4ProgramProcessHandle){0});
    const uint32_t valid_flags = R4OS_TRAY_ITEM_FLAG_VISIBLE | R4OS_TRAY_ITEM_FLAG_ENABLED | R4OS_TRAY_ITEM_FLAG_ATTENTION;
    if (item == 0 || item->id == 0u || item->revision == 0u || item->icon == 0 ||
        item->tooltip_length > R4OS_TRAY_TOOLTIP_BYTES ||
        (item->tooltip_length != 0u && item->tooltip == 0) || (item->flags & ~valid_flags) != 0u)
    {
        R4TrayCallResult invalid = {R4_TRAY_CALL_FAILED, R4OS_TRAY_RESULT_BAD_REQUEST, 0u, {0}, {0}};
        return invalid;
    }
    request.item_id = item->id;
    request.item_revision = item->revision;
    request.item_flags = item->flags;
    request.status_flags = item->status_flags;
    request.tooltip_length = item->tooltip_length;
    request.icon_width = (uint16_t)R4OS_TRAY_ICON_WIDTH;
    request.icon_height = (uint16_t)R4OS_TRAY_ICON_HEIGHT;
    request.icon_format = R4OS_TRAY_ICON_FORMAT_ARGB32;
    for (uint16_t i = 0; i < item->tooltip_length; ++i) request.tooltip[i] = item->tooltip[i];
    for (uint16_t i = 0; i < R4OS_TRAY_ICON_PIXEL_COUNT; ++i) request.icon[i] = item->icon[i];
    return r4_tray_call(tray, R4OS_TRAY_SERVICE_OP_UPSERT, &request, timeout);
}

static inline R4TrayCallResult r4_tray_remove(R4Tray *tray, uint64_t item_id, R4Timeout timeout) {
    R4TrayServiceRequest request = r4_tray_request(tray != 0 ? tray->owner : (R4ProgramProcessHandle){0});
    if (item_id == 0u) {
        R4TrayCallResult invalid = {R4_TRAY_CALL_FAILED, R4OS_TRAY_RESULT_BAD_REQUEST, 0u, {0}, {0}};
        return invalid;
    }
    request.item_id = item_id;
    return r4_tray_call(tray, R4OS_TRAY_SERVICE_OP_REMOVE, &request, timeout);
}

static inline R4TrayCallResult r4_tray_wait_event(R4Tray *tray, uint64_t after_sequence, R4Timeout timeout) {
    R4TrayServiceRequest request = r4_tray_request(tray != 0 ? tray->owner : (R4ProgramProcessHandle){0});
    uint64_t budget = 0u;
    uint32_t hz = tray != 0 && tray->app != 0 ? r4_services_monotonic_hz(tray->app) : 0u;
    if (timeout.kind == R4OS_TIMEOUT_KIND_FOREVER || r4_timeout_to_ticks(timeout, hz, &budget) != R4OS_OK) {
        R4TrayCallResult invalid = {R4_TRAY_CALL_FAILED, R4OS_TRAY_RESULT_BAD_REQUEST, 0u, {0}, {0}};
        return invalid;
    }
    uint64_t now = tray != 0 && tray->app != 0 ? r4_app_ticks(tray->app) : 0u;
    uint64_t server_budget = budget > 0u ? budget - 1u : 0u;
    request.after_sequence = after_sequence;
    request.deadline_tick = UINT64_MAX - now < server_budget ? UINT64_MAX : now + server_budget;
    return r4_tray_call(tray, R4OS_TRAY_SERVICE_OP_WAIT_EVENT, &request, timeout);
}

#endif
