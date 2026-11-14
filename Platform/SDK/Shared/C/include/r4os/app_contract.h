#ifndef R4OS_APP_CONTRACT_H
#define R4OS_APP_CONTRACT_H

#include "r4sys.h"
#include "r4desk.h"
#include "r4draw.h"
#include "r4net.h"
#include "r4audio.h"
#include "r4dev.h"
#include "serial.h"
#include "path_timeout.h"
#include "startup.h"

enum {
    R4_STATUS_PROGRESS_VALID = 0x00000001u,
    R4_STATUS_REQUIRED_SIZE_VALID = 0x00000002u,
    R4_STATUS_SIDE_EFFECTS_MAY_HAVE_OCCURRED = 0x00000004u,
    R4_STATUS_SIDE_EFFECTS_CONFIRMED_PROGRESS = 0x00000008u
};

typedef struct R4Status {
    uint16_t domain;
    uint16_t reserved0;
    int32_t raw_code;
    uint32_t flags;
    uint32_t reserved1;
    uint64_t progress;
    uint64_t required_size;
} R4Status;

typedef R4Status R4Failure;

typedef struct R4App {
    const R4XStartContext2 *context;
    R4Sys system;
    R4Desk desktop;
    R4Draw drawing;
    R4Net network;
    R4Audio audio;
    R4Dev devices;
    uint32_t group_mask;
    R4AppProfile profile;
    uint8_t reserved[3];
} R4App;

/* SDK facade binding to the actual second-generation view; no old start or
 * table is synthesized. Keep the supplied view and callbacks resident. */
static inline int32_t r4_app_init2(const R4OS2Context *context, const R4App2Memory *memory, R4App *out) {
    if (!out || !context || !context->raw) return R4OS_ERROR_INVALID;
    R4App value = {0};
    switch (context->raw->app_class) {
    case R4XSTART_APP_CLASS_CONSOLE: value.profile = R4_APP_PROFILE_CONSOLE; break;
    case R4XSTART_APP_CLASS_GUI: value.profile = R4_APP_PROFILE_DESKTOP; break;
    case R4XSTART_APP_CLASS_SERVICE: value.profile = R4_APP_PROFILE_SERVICE; break;
    default: return R4OS_ERROR_INVALID;
    }
    const int32_t rc = r4sys_init2(context, memory, &value.system);
    if (rc != 0) return rc;
    for (uint32_t group = 1; group <= 6; ++group) {
        if (R4OS2ContextGroup(context, group)) value.group_mask |= UINT32_C(1) << group;
    }
    if (R4OS2ContextGroup(context, 2)) {
        const int32_t desktop_rc = r4desk_init2(context, &value.desktop);
        if (desktop_rc != 0) return desktop_rc;
    }
    if (R4OS2ContextGroup(context, 3)) {
        const int32_t drawing_rc = r4draw_init2(context, &value.drawing);
        if (drawing_rc != 0) return drawing_rc;
    }
    if (R4OS2ContextGroup(context, 4)) {
        const int32_t network_rc = r4net_init2(context, &value.network);
        if (network_rc != 0) return network_rc;
    }
    if (R4OS2ContextGroup(context, 5)) {
        const int32_t audio_rc = r4audio_init2(context, &value.audio);
        if (audio_rc != 0) return audio_rc;
    }
    if (R4OS2ContextGroup(context, 6)) {
        const int32_t device_rc = r4dev_init2(context, &value.devices);
        if (device_rc != 0) return device_rc;
    }
    *out = value;
    return 0;
}
int32_t R4SdkAppFacade2(const R4OS2Context *, const R4App2Memory *, R4App *);

static inline int32_t r4app_serial(const R4App *app,R4Serial *out){return r4serial_init(app?&app->devices:0,out);}

typedef struct R4OutcomeU64 {
    R4Status status;
    uint64_t value;
} R4OutcomeU64;

typedef enum R4WaitState {
    R4_WAIT_COMPLETED = R4OS_WAIT_STATE_COMPLETED,
    R4_WAIT_WOULD_BLOCK = R4OS_WAIT_STATE_WOULD_BLOCK,
    R4_WAIT_TIMED_OUT = R4OS_WAIT_STATE_TIMED_OUT,
    R4_WAIT_CANCELLED = R4OS_WAIT_STATE_CANCELLED,
    R4_WAIT_FAILED = R4OS_WAIT_STATE_FAILED
} R4WaitState;

typedef enum R4ServiceStopPolicy {
    R4_SERVICE_STOP_GRACEFUL = R4OS_SERVICE_STOP_POLICY_GRACEFUL,
    R4_SERVICE_STOP_KILL_AFTER_GRACE = R4OS_SERVICE_STOP_POLICY_KILL_AFTER_GRACE
} R4ServiceStopPolicy;

static inline void r4_stop_flag_init(R4StopFlag *flag) { if (flag != 0) __atomic_store_n(&flag->value, 0u, __ATOMIC_RELEASE); }
static inline void r4_stop_flag_request(R4StopFlag *flag) { if (flag != 0) __atomic_store_n(&flag->value, 1u, __ATOMIC_RELEASE); }
static inline int r4_stop_flag_requested(const R4StopFlag *flag) { return flag != 0 && __atomic_load_n(&flag->value, __ATOMIC_ACQUIRE) != 0u; }

static inline R4WaitState r4_wait_classify(int32_t raw, int32_t timeout_code, int32_t cancelled_code, int32_t would_block_code) {
    if (raw >= 0) return R4_WAIT_COMPLETED;
    if (raw == timeout_code) return R4_WAIT_TIMED_OUT;
    if (raw == cancelled_code) return R4_WAIT_CANCELLED;
    if (raw == would_block_code) return R4_WAIT_WOULD_BLOCK;
    return R4_WAIT_FAILED;
}

static inline R4Status r4_status_ok(void) {
    R4Status status = {0};
    return status;
}

static inline R4Status r4_status_failure(R4ErrorDomain domain, int32_t raw_code) {
    R4Status status = {0};
    status.domain = (uint16_t)domain;
    status.raw_code = raw_code;
    return status;
}

static inline int r4_status_succeeded(R4Status status) {
    return status.raw_code >= 0;
}

static inline const void *r4_app_group_table(const R4XStartContext2 *context, uint32_t group_id, uint32_t magic, uint32_t version, uint32_t size) {
    const R4XStartImport *item = r4xstart_find_import(context, group_id);
    if (item == 0 || item->table == 0 || (item->flags & R4XSTART_IMPORT_FLAG_GROUP_INTERFACE) == 0) return 0;
    const uint32_t *header = (const uint32_t *)(uintptr_t)item->table;
    if (header[0] != magic || header[1] < version || header[2] < size) return 0;
    return (const void *)(uintptr_t)item->table;
}

static inline R4Status r4_app_init(const R4XStartContext2 *context, R4AppProfile profile, R4App *out_app) {
    if (out_app == 0 || context == 0) return r4_status_failure(R4_ERROR_DOMAIN_CONTRACT, R4OS_ERROR_INVALID);
    *out_app = (R4App){0};
    out_app->profile = profile;
    if (!r4xstart_context_valid(context)) return r4_status_failure(R4_ERROR_DOMAIN_CONTRACT, R4OS_ERROR_INVALID);
    if (profile != R4_APP_PROFILE_CONSOLE && profile != R4_APP_PROFILE_DESKTOP && profile != R4_APP_PROFILE_SERVICE) {
        return r4_status_failure(R4_ERROR_DOMAIN_CONTRACT, R4OS_ERROR_INVALID);
    }
    if ((profile == R4_APP_PROFILE_SERVICE && context->app_class != R4XSTART_APP_CLASS_SERVICE) ||
        (profile != R4_APP_PROFILE_SERVICE && context->app_class != R4XSTART_APP_CLASS_CONSOLE && context->app_class != R4XSTART_APP_CLASS_GUI))
        return r4_status_failure(R4_ERROR_DOMAIN_CONTRACT, R4OS_ERROR_INVALID);
    out_app->system.ctx = context;
    out_app->system.table = (const R4XStartR4Sys2 *)r4_app_group_table(context, R4L_GROUP_R4SYS, R4OS2_R4SYS_MAGIC, R4OS2_R4SYS_VERSION, sizeof(R4XStartR4Sys2));
    out_app->desktop.table = (const R4XStartR4Desk2 *)r4_app_group_table(context, R4L_GROUP_R4DESK, R4OS2_R4DESK_MAGIC, R4OS2_R4DESK_VERSION, sizeof(R4XStartR4Desk2));
    out_app->drawing.table = (const R4XStartR4Draw2 *)r4_app_group_table(context, R4L_GROUP_R4DRAW, R4OS2_R4DRAW_MAGIC, R4OS2_R4DRAW_VERSION, sizeof(R4XStartR4Draw2));
    out_app->network.table = (const R4XStartR4Net2 *)r4_app_group_table(context, R4L_GROUP_R4NET, R4OS2_R4NET_MAGIC, R4OS2_R4NET_VERSION, sizeof(R4XStartR4Net2));
    out_app->audio.table = (const R4XStartR4Audio2 *)r4_app_group_table(context, R4L_GROUP_R4AUDIO, R4OS2_R4AUDIO_MAGIC, R4OS2_R4AUDIO_VERSION, sizeof(R4XStartR4Audio2));
    out_app->devices.table = (const R4XStartR4Dev2 *)r4_app_group_table(context, R4L_GROUP_R4DEV, R4OS2_R4DEV_MAGIC, R4OS2_R4DEV_VERSION, sizeof(R4XStartR4Dev2));
    if (out_app->system.table != 0) out_app->group_mask |= 1u << R4L_GROUP_R4SYS;
    if (out_app->desktop.table != 0) out_app->group_mask |= 1u << R4L_GROUP_R4DESK;
    if (out_app->drawing.table != 0) out_app->group_mask |= 1u << R4L_GROUP_R4DRAW;
    if (out_app->network.table != 0) out_app->group_mask |= 1u << R4L_GROUP_R4NET;
    if (out_app->audio.table != 0) out_app->group_mask |= 1u << R4L_GROUP_R4AUDIO;
    if (out_app->devices.table != 0) out_app->group_mask |= 1u << R4L_GROUP_R4DEV;
    uint32_t required = profile == R4_APP_PROFILE_DESKTOP ? R4_APP_PROFILE_DESKTOP_REQUIRED_GROUPS :
        (profile == R4_APP_PROFILE_SERVICE ? R4_APP_PROFILE_SERVICE_REQUIRED_GROUPS : R4_APP_PROFILE_CONSOLE_REQUIRED_GROUPS);
    if ((out_app->group_mask & required) != required) {
        *out_app = (R4App){0};
        return r4_status_failure(R4_ERROR_DOMAIN_CONTRACT, R4OS_ERR_NO_GROUP);
    }
    out_app->context = context;
    return r4_status_ok();
}

static inline R4Status r4_app_init_declared(const R4XStartContext2 *context, const R4StartupInfo *info, R4App *out_app) {
    if (out_app == 0) return r4_status_failure(R4_ERROR_DOMAIN_CONTRACT, R4OS_ERROR_INVALID);
    *out_app = (R4App){0};
    const int32_t raw = r4xstart_validate_declared(context, info);
    if (raw < 0) return r4_status_failure(R4_ERROR_DOMAIN_CONTRACT, raw);
    return r4_app_init(context, info->profile, out_app);
}

static inline int r4_app_has_group(const R4App *app, uint32_t group_id) {
    return app != 0 && group_id < 32u && (app->group_mask & (1u << group_id)) != 0u;
}

static inline uint64_t r4_app_instance_id(const R4App *app) {
    if (!app) return 0;
    if (app->system.generation2) return app->system.generation2->raw->instance_id;
    return app->context ? app->context->instance_id : 0;
}

static inline const uint8_t *r4_app_args(const R4App *app, uint64_t *out_len) {
    if (app && app->system.generation2) return R4OS2ContextArgs(app->system.generation2, out_len);
    if (out_len != 0) *out_len = app != 0 && app->context != 0 ? app->context->args_len : 0u;
    return app != 0 ? r4xstart_args(app->context) : 0;
}

static inline int r4_app_should_close(R4App *app) { return app != 0 ? r4sys_program_should_close(&app->system) : 1; }
static inline uint64_t r4_app_ticks(R4App *app) {
    if (!app || !R4SYS_HAS(&app->system, ticks)) return 0;
    return ((R4SysTicksFn)(uintptr_t)R4SYS_SLOT(&app->system, ticks))();
}

#define R4_DECLARE_HANDLE(NAME, RAW) \
    typedef struct NAME { RAW raw; uint8_t owned; uint8_t reserved[7]; } NAME; \
    static inline int NAME##_valid(const NAME *handle) { return handle != 0 && handle->raw != 0; } \
    static inline int32_t NAME##_apply_close_result(NAME *handle, int32_t raw_code) { \
        if (handle != 0 && handle->owned && raw_code >= 0) handle->raw = 0; \
        return raw_code; \
    }

R4_DECLARE_HANDLE(R4ProgramHandle, uint32_t)
R4_DECLARE_HANDLE(R4ThreadHandle, uint32_t)
R4_DECLARE_HANDLE(R4IoRequestHandle, uint32_t)
R4_DECLARE_HANDLE(R4ServiceHandle, uint32_t)
R4_DECLARE_HANDLE(R4ServiceEndpointHandle, uint32_t)
R4_DECLARE_HANDLE(R4VmRegionHandle, uint32_t)
R4_DECLARE_HANDLE(R4TcpConnectionHandle, uint32_t)
R4_DECLARE_HANDLE(R4IpcChannelHandle, uint32_t)
R4_DECLARE_HANDLE(R4AudioStreamHandle, uint32_t)
R4_DECLARE_HANDLE(R4SidSessionHandle, uint32_t)
R4_DECLARE_HANDLE(R4MidiSynthHandle, uint32_t)

typedef struct R4WindowHandle {
    int32_t raw;
    uint8_t owned;
    uint8_t reserved[7];
} R4WindowHandle;

static inline int R4WindowHandle_valid(const R4WindowHandle *handle) {
    return handle != 0 && handle->raw >= 0;
}

static inline int32_t R4WindowHandle_apply_close_result(R4WindowHandle *handle, int32_t raw_code) {
    if (handle != 0 && handle->owned && raw_code >= 0) handle->raw = -1;
    return raw_code;
}

_Static_assert(sizeof(R4Status) == 32u, "R4Status size mismatch");
_Static_assert(sizeof(R4ProgramHandle) == 12u, "R4ProgramHandle size mismatch");
_Static_assert(sizeof(R4Timeout) == 16u, "R4Timeout size mismatch");
_Static_assert(sizeof(R4StopFlag) == 4u, "R4StopFlag size mismatch");

#endif
