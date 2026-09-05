#ifndef R4OS_APP_AUDIO_H
#define R4OS_APP_AUDIO_H

#include "app_services.h"

typedef struct R4AudioFacade { R4App *app; } R4AudioFacade;
typedef struct R4AdvancedAudio { R4App *app; } R4AdvancedAudio;

enum { R4_AUDIO_FORMAT_S16LE = R4OS_AUDIO_BACKEND_FORMAT_S16LE };

/* AUDSVC wire records are facade-private transport details, not a second ABI. */
typedef struct R4AudioWireOpenRequest {
    uint32_t magic; uint16_t version; uint16_t reserved0; uint32_t rate;
    uint16_t channels; uint16_t format; uint32_t fixed_volume; uint32_t flags;
} R4AudioWireOpenRequest;
typedef struct R4AudioWireWriteRequest {
    uint32_t magic; uint16_t version; uint16_t reserved0; uint32_t stream_id;
    uint32_t byte_count; uint32_t flags;
} R4AudioWireWriteRequest;
typedef struct R4AudioWireControlRequest {
    uint32_t magic; uint16_t version; uint16_t reserved0; uint32_t stream_id;
    uint32_t fixed_volume; uint32_t flags;
} R4AudioWireControlRequest;
typedef struct R4AudioWireResult {
    uint32_t magic; uint16_t version; uint16_t action; int32_t result;
    uint32_t stream_id; uint32_t bytes; uint32_t flags; uint32_t master_volume_fixed;
    uint32_t open_sessions; uint64_t total_bytes_written; uint64_t request_ticks;
    uint64_t write_ticks; uint8_t last_error[R4OS_AUDIO_SERVICE_ERROR_BYTES]; uint8_t reserved0[32];
} R4AudioWireResult;

_Static_assert(sizeof(R4AudioWireOpenRequest) == 24u, "AUDSVC open wire layout mismatch");
_Static_assert(sizeof(R4AudioWireWriteRequest) == 20u, "AUDSVC write wire layout mismatch");
_Static_assert(sizeof(R4AudioWireControlRequest) == 20u, "AUDSVC control wire layout mismatch");
_Static_assert(sizeof(R4AudioWireResult) == 120u, "AUDSVC result wire layout mismatch");

typedef struct R4AudioStream {
    R4ServiceConnection connection;
    uint32_t stream_id;
    uint8_t owned;
    uint8_t reserved[3];
} R4AudioStream;

typedef enum R4AudioResultKind {
    R4_AUDIO_RESULT_OK = 0,
    R4_AUDIO_RESULT_TIMED_OUT = 1,
    R4_AUDIO_RESULT_NO_SERVICE = 2,
    R4_AUDIO_RESULT_FAILED = 3
} R4AudioResultKind;

typedef struct R4AudioResult {
    R4AudioResultKind kind;
    int32_t raw_code;
    uint32_t bytes;
} R4AudioResult;

static inline R4AudioFacade r4_app_audio(R4App *app) { R4AudioFacade value = {app}; return value; }
static inline R4AdvancedAudio r4_audio_advanced(R4AudioFacade audio) { R4AdvancedAudio value = {audio.app}; return value; }
static inline int r4_audio_stream_valid(const R4AudioStream *stream) { return stream != 0 && stream->owned != 0u && stream->stream_id != 0u && r4_service_connection_valid(&stream->connection); }
static inline R4AudioResult r4_audio_result(R4AudioResultKind kind, int32_t raw, uint32_t bytes) { R4AudioResult result = {kind, raw, bytes}; return result; }
static inline void r4_audio_copy_bytes(void *destination, const void *source, uint32_t count) {
    uint8_t *out = (uint8_t *)destination; const uint8_t *in = (const uint8_t *)source;
    uint32_t index; for (index = 0u; index < count; ++index) out[index] = in[index];
}

static inline int r4_audio_available(const R4AudioFacade *audio) {
    if (audio == 0 || audio->app == 0 || audio->app->audio.table == 0) return 0;
    const R4XStartR4Sys *sys = audio->app->system.table;
    return sys != 0 && sys->service_open != 0u && sys->service_close != 0u && sys->service_call != 0u && audio->app->audio.table->audio_open_stream != 0u;
}

static inline int r4_audio_response_valid(const R4AudioWireResult *response, uint16_t action) {
    return response->magic == R4OS_AUDIO_SERVICE_RESULT_MAGIC && response->version == R4OS_AUDIO_SERVICE_RESULT_VERSION && response->action == action;
}

static inline int r4_audio_master_state_valid(const R4AudioServiceMasterState *state) {
    return state != 0 && state->magic == R4OS_AUDIO_MASTER_STATE_MAGIC && state->version == R4OS_AUDIO_MASTER_STATE_VERSION && state->size == sizeof(R4AudioServiceMasterState);
}

static inline R4AudioResult r4_audio_master_call(R4AudioFacade *audio, uint16_t op, const void *request, uint32_t request_size, R4Timeout timeout, R4AudioServiceMasterState *out) {
    if (!r4_audio_available(audio) || out == 0) return r4_audio_result(R4_AUDIO_RESULT_NO_SERVICE, R4OS_ERR_NO_FN, 0u);
    R4Services services = r4_app_services(audio->app);
    R4ServiceConnection connection;
    int32_t opened = r4_services_open(&services, "AUDSVC", &connection);
    if (opened != R4OS_SERVICE_API_RESULT_OK) return r4_audio_result(R4_AUDIO_RESULT_NO_SERVICE, opened, 0u);
    *out = (R4AudioServiceMasterState){0};
    R4ServiceCallResult call = r4_service_connection_call_struct(&connection, op, request, request_size, out, sizeof(*out), timeout);
    (void)r4_service_connection_close(&connection);
    if (call.kind == R4_SERVICE_CALL_TIMED_OUT) return r4_audio_result(R4_AUDIO_RESULT_TIMED_OUT, R4OS_SERVICE_API_RESULT_TIMEOUT, 0u);
    if (call.kind != R4_SERVICE_CALL_RESPONSE || !r4_audio_master_state_valid(out)) return r4_audio_result(R4_AUDIO_RESULT_FAILED, call.kind == R4_SERVICE_CALL_RESPONSE ? R4OS_SERVICE_API_RESULT_INVALID : call.raw_code, 0u);
    return r4_audio_result(R4_AUDIO_RESULT_OK, R4OS_OK, 0u);
}

static inline R4AudioResult r4_audio_master_status(R4AudioFacade *audio, R4Timeout timeout, R4AudioServiceMasterState *out) {
    return r4_audio_master_call(audio, R4OS_AUDIO_SERVICE_OP_MASTER_STATUS, 0, 0u, timeout, out);
}

static inline R4AudioResult r4_audio_set_master_state(R4AudioFacade *audio, uint32_t update_flags, uint32_t fixed_volume, int muted, uint64_t expected_revision, R4Timeout timeout, R4AudioServiceMasterState *out) {
    const uint32_t allowed = R4OS_AUDIO_MASTER_REQUEST_FLAG_SET_VOLUME | R4OS_AUDIO_MASTER_REQUEST_FLAG_SET_MUTED;
    if ((update_flags & allowed) == 0u || (update_flags & ~allowed) != 0u) return r4_audio_result(R4_AUDIO_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u);
    R4AudioServiceMasterRequest request = {0};
    request.magic = R4OS_AUDIO_MASTER_REQUEST_MAGIC; request.version = R4OS_AUDIO_MASTER_REQUEST_VERSION; request.size = (uint16_t)sizeof(request);
    request.flags = update_flags; request.fixed_volume = fixed_volume; request.expected_revision = expected_revision;
    if ((update_flags & R4OS_AUDIO_MASTER_REQUEST_FLAG_SET_MUTED) != 0u && muted) request.flags |= R4OS_AUDIO_MASTER_REQUEST_FLAG_MUTED;
    return r4_audio_master_call(audio, R4OS_AUDIO_SERVICE_OP_SET_MASTER_STATE, &request, sizeof(request), timeout, out);
}

static inline R4AudioResult r4_audio_open_stream(R4AudioFacade *audio, uint32_t rate, uint16_t channels, uint16_t format, uint32_t fixed_volume, R4Timeout timeout, R4AudioStream *out) {
    if (out != 0) *out = (R4AudioStream){0};
    if (!r4_audio_available(audio) || out == 0) return r4_audio_result(R4_AUDIO_RESULT_NO_SERVICE, R4OS_ERR_NO_FN, 0u);
    if (rate == 0u || channels == 0u || format != R4_AUDIO_FORMAT_S16LE) return r4_audio_result(R4_AUDIO_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u);
    R4Services services = r4_app_services(audio->app);
    R4ServiceConnection connection;
    int32_t opened = r4_services_open(&services, "AUDSVC", &connection);
    if (opened != R4OS_SERVICE_API_RESULT_OK) return r4_audio_result(R4_AUDIO_RESULT_NO_SERVICE, opened, 0u);
    R4AudioWireOpenRequest request = {0};
    request.magic = R4OS_AUDIO_SERVICE_REQUEST_MAGIC; request.version = R4OS_AUDIO_SERVICE_REQUEST_VERSION;
    request.rate = rate; request.channels = channels; request.format = (uint16_t)format; request.fixed_volume = fixed_volume;
    R4AudioWireResult response = {0};
    R4ServiceCallResult call = r4_service_connection_call_struct(&connection, R4OS_AUDIO_SERVICE_OP_OPEN_STREAM, &request, sizeof(request), &response, sizeof(response), timeout);
    if (call.kind == R4_SERVICE_CALL_TIMED_OUT) { (void)r4_service_connection_close(&connection); return r4_audio_result(R4_AUDIO_RESULT_TIMED_OUT, R4OS_SERVICE_API_RESULT_TIMEOUT, 0u); }
    if (call.kind != R4_SERVICE_CALL_RESPONSE || !r4_audio_response_valid(&response, R4OS_AUDIO_SERVICE_OP_OPEN_STREAM) || response.result < 0 || response.stream_id == 0u) {
        int32_t raw = call.kind == R4_SERVICE_CALL_RESPONSE ? (response.result < 0 ? response.result : R4OS_SERVICE_API_RESULT_INVALID) : call.raw_code;
        (void)r4_service_connection_close(&connection); return r4_audio_result(R4_AUDIO_RESULT_FAILED, raw, 0u);
    }
    out->connection = connection; out->stream_id = response.stream_id; out->owned = 1u;
    return r4_audio_result(R4_AUDIO_RESULT_OK, R4OS_OK, 0u);
}

static inline R4AudioResult r4_audio_stream_write(R4AudioStream *stream, const uint8_t *data, uint32_t data_len, R4Timeout timeout) {
    if (!r4_audio_stream_valid(stream)) return r4_audio_result(R4_AUDIO_RESULT_FAILED, R4OS_ERR_CLOSED, 0u);
    if (data_len != 0u && data == 0) return r4_audio_result(R4_AUDIO_RESULT_FAILED, R4OS_SERVICE_API_RESULT_INVALID, 0u);
    uint32_t offset = 0u;
    while (offset < data_len) {
        uint8_t payload[R4OS_SERVICE_API_MAX_PAYLOAD];
        const uint32_t capacity = R4OS_SERVICE_API_MAX_PAYLOAD - (uint32_t)sizeof(R4AudioWireWriteRequest);
        uint32_t chunk = data_len - offset; if (chunk > capacity) chunk = capacity;
        R4AudioWireWriteRequest request = {0}; request.magic = R4OS_AUDIO_SERVICE_REQUEST_MAGIC; request.version = R4OS_AUDIO_SERVICE_REQUEST_VERSION; request.stream_id = stream->stream_id; request.byte_count = chunk;
        r4_audio_copy_bytes(payload, &request, (uint32_t)sizeof(request)); r4_audio_copy_bytes(payload + sizeof(request), data + offset, chunk);
        R4AudioWireResult response = {0};
        R4ServiceCallResult call = r4_service_connection_call_struct(&stream->connection, R4OS_AUDIO_SERVICE_OP_WRITE_STREAM, payload, (uint32_t)sizeof(request) + chunk, &response, sizeof(response), timeout);
        if (call.kind == R4_SERVICE_CALL_TIMED_OUT) return r4_audio_result(R4_AUDIO_RESULT_TIMED_OUT, R4OS_SERVICE_API_RESULT_TIMEOUT, offset);
        if (call.kind != R4_SERVICE_CALL_RESPONSE || !r4_audio_response_valid(&response, R4OS_AUDIO_SERVICE_OP_WRITE_STREAM) || response.result < 0 || response.bytes == 0u || response.bytes > chunk) {
            int32_t raw = call.kind == R4_SERVICE_CALL_RESPONSE ? (response.result < 0 ? response.result : R4OS_SERVICE_API_RESULT_INVALID) : call.raw_code;
            return r4_audio_result(R4_AUDIO_RESULT_FAILED, raw, offset);
        }
        offset += response.bytes;
    }
    return r4_audio_result(R4_AUDIO_RESULT_OK, R4OS_OK, offset);
}

static inline R4AudioResult r4_audio_stream_control(R4AudioStream *stream, uint16_t op, uint32_t volume, R4Timeout timeout, int closes) {
    if (!r4_audio_stream_valid(stream)) return r4_audio_result(R4_AUDIO_RESULT_FAILED, R4OS_ERR_CLOSED, 0u);
    R4AudioWireControlRequest request = {0}; request.magic = R4OS_AUDIO_SERVICE_REQUEST_MAGIC; request.version = R4OS_AUDIO_SERVICE_REQUEST_VERSION; request.stream_id = stream->stream_id; request.fixed_volume = volume;
    R4AudioWireResult response = {0};
    R4ServiceCallResult call = r4_service_connection_call_struct(&stream->connection, op, &request, sizeof(request), &response, sizeof(response), timeout);
    if (call.kind == R4_SERVICE_CALL_TIMED_OUT) return r4_audio_result(R4_AUDIO_RESULT_TIMED_OUT, R4OS_SERVICE_API_RESULT_TIMEOUT, 0u);
    if (call.kind != R4_SERVICE_CALL_RESPONSE || !r4_audio_response_valid(&response, op) || response.result < 0) return r4_audio_result(R4_AUDIO_RESULT_FAILED, call.kind == R4_SERVICE_CALL_RESPONSE ? (response.result < 0 ? response.result : R4OS_SERVICE_API_RESULT_INVALID) : call.raw_code, 0u);
    if (closes) { stream->stream_id = 0u; stream->owned = 0u; (void)r4_service_connection_close(&stream->connection); }
    return r4_audio_result(R4_AUDIO_RESULT_OK, R4OS_OK, 0u);
}

static inline R4AudioResult r4_audio_stream_set_volume(R4AudioStream *stream, uint32_t volume, R4Timeout timeout) { return r4_audio_stream_control(stream, R4OS_AUDIO_SERVICE_OP_SET_STREAM_VOLUME, volume, timeout, 0); }
static inline R4AudioResult r4_audio_stream_close(R4AudioStream *stream, R4Timeout timeout) { return r4_audio_stream_control(stream, R4OS_AUDIO_SERVICE_OP_CLOSE_STREAM, 0x00010000u, timeout, 1); }

/* Advanced synth surface: deliberately separate from the normal PCM lifecycle. */
static inline int32_t r4_audio_sid_acquire(R4AdvancedAudio *audio) { return audio != 0 && audio->app != 0 && audio->app->audio.table != 0 && audio->app->audio.table->sid_acquire != 0 ? ((R4AudioSidAcquireFn)(uintptr_t)audio->app->audio.table->sid_acquire)() : R4OS_ERR_NO_FN; }
static inline int32_t r4_audio_sid_write_register(R4AdvancedAudio *audio, uint32_t handle, uint8_t reg, uint8_t value) { return audio != 0 && audio->app != 0 && audio->app->audio.table != 0 && audio->app->audio.table->sid_write_register != 0 ? ((R4AudioSidWriteRegisterFn)(uintptr_t)audio->app->audio.table->sid_write_register)(handle, reg, value) : R4OS_ERR_NO_FN; }
static inline int32_t r4_audio_sid_release(R4AdvancedAudio *audio, uint32_t handle) { return audio != 0 && audio->app != 0 && audio->app->audio.table != 0 && audio->app->audio.table->sid_release != 0 ? ((R4AudioSidReleaseFn)(uintptr_t)audio->app->audio.table->sid_release)(handle) : R4OS_ERR_NO_FN; }
static inline int32_t r4_audio_midi_open_synth(R4AdvancedAudio *audio, const uint8_t *backend) { return audio != 0 && audio->app != 0 && audio->app->audio.table != 0 && audio->app->audio.table->midi_open_synth != 0 ? ((R4AudioMidiOpenSynthFn)(uintptr_t)audio->app->audio.table->midi_open_synth)(backend) : R4OS_ERR_NO_FN; }
static inline int32_t r4_audio_midi_send(R4AdvancedAudio *audio, uint32_t handle, uint8_t channel, uint8_t status, uint8_t data1, uint8_t data2) { return audio != 0 && audio->app != 0 && audio->app->audio.table != 0 && audio->app->audio.table->midi_send != 0 ? ((R4AudioMidiSendFn)(uintptr_t)audio->app->audio.table->midi_send)(handle, channel, status, data1, data2) : R4OS_ERR_NO_FN; }
static inline int32_t r4_audio_midi_close(R4AdvancedAudio *audio, uint32_t handle) { return audio != 0 && audio->app != 0 && audio->app->audio.table != 0 && audio->app->audio.table->midi_close != 0 ? ((R4AudioMidiCloseFn)(uintptr_t)audio->app->audio.table->midi_close)(handle) : R4OS_ERR_NO_FN; }
static inline int32_t r4_audio_opl3_write_register(R4AdvancedAudio *audio, uint8_t bank, uint8_t reg, uint8_t value) { return audio != 0 && audio->app != 0 && audio->app->audio.table != 0 && audio->app->audio.table->opl3_write_register != 0 ? ((R4AudioOpl3WriteRegisterFn)(uintptr_t)audio->app->audio.table->opl3_write_register)(bank, reg, value) : R4OS_ERR_NO_FN; }
static inline int32_t r4_audio_opl3_reset(R4AdvancedAudio *audio) { return audio != 0 && audio->app != 0 && audio->app->audio.table != 0 && audio->app->audio.table->opl3_reset != 0 ? ((R4AudioOpl3ResetFn)(uintptr_t)audio->app->audio.table->opl3_reset)() : R4OS_ERR_NO_FN; }
static inline int32_t r4_audio_opl3_render_block(R4AdvancedAudio *audio) { return audio != 0 && audio->app != 0 && audio->app->audio.table != 0 && audio->app->audio.table->opl3_render_block != 0 ? ((R4AudioOpl3RenderBlockFn)(uintptr_t)audio->app->audio.table->opl3_render_block)() : R4OS_ERR_NO_FN; }
static inline int32_t r4_audio_opl3_stop(R4AdvancedAudio *audio) { return audio != 0 && audio->app != 0 && audio->app->audio.table != 0 && audio->app->audio.table->opl3_stop != 0 ? ((R4AudioOpl3StopFn)(uintptr_t)audio->app->audio.table->opl3_stop)() : R4OS_ERR_NO_FN; }

#endif
