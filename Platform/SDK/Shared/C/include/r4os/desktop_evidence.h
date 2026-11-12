#ifndef R4OS_DESKTOP_EVIDENCE_H
#define R4OS_DESKTOP_EVIDENCE_H

#include "app_services.h"

/* Transport/local validation return code is separate from reply.result and
 * the original completion.exit_code. No operation here spawns or reaps. */
static inline int r4_desktop_evidence_same_process(R4ProgramProcessHandle a, R4ProgramProcessHandle b) {
    return a.instance_id == b.instance_id && a.reserved == b.reserved && a.generation == b.generation;
}
static inline int r4_desktop_evidence_same_words(const uint64_t a[3], const uint64_t b[3]) {
    return a[0] == b[0] && a[1] == b[1] && a[2] == b[2];
}
static inline int r4_desktop_evidence_valid_process(R4ProgramProcessHandle p) {
    return p.instance_id != 0u && p.reserved == 0u && p.generation != 0u;
}
static inline int32_t r4_desktop_evidence_prepare(const R4DesktopEvidenceToken *scope,
        R4ProgramProcessHandle request, const uint64_t intent[3], R4DesktopEvidenceToken *out) {
    if (!scope || !intent || !out || scope->version != 1u || scope->size != sizeof(*scope) ||
        !r4_desktop_evidence_valid_process(scope->broker) || !r4_desktop_evidence_valid_process(request) ||
        (scope->epoch[0] | scope->epoch[1] | scope->epoch[2]) == 0u || (intent[0] | intent[1] | intent[2]) == 0u)
        return R4OS_DESKTOP_EVIDENCE_RESULT_INVALID;
    *out = (R4DesktopEvidenceToken){0}; out->version = 1u; out->size = sizeof(*out);
    out->broker = scope->broker; out->request = request;
    for (uint32_t i = 0; i != 3u; ++i) { out->epoch[i] = scope->epoch[i]; out->intent[i] = intent[i]; }
    return 0;
}
static inline int32_t r4_desktop_evidence_call(R4App *app, uint16_t op,
        const R4DesktopEvidenceRequest *request, R4DesktopEvidenceReply *reply, uint8_t *data, uint32_t capacity) {
    if (!app || !request || !reply || capacity > R4OS_DESKTOP_EVIDENCE_MAX_OUTPUT_CHUNK || (capacity && !data))
        return R4OS_DESKTOP_EVIDENCE_RESULT_INVALID;
    R4Services services = r4_app_services(app);
    R4ServiceConnection connection = {0};
    int32_t rc = r4_services_open(&services, R4OS_WINDOW_SERVICE_NAME, &connection);
    if (rc != 0) return rc;
    uint8_t bytes[R4OS_SERVICE_API_MAX_PAYLOAD];
    const R4Duration duration = {500000000u};
    R4ServiceCallResult result = r4_service_connection_call(&connection, op, request, sizeof(*request),
        bytes, sizeof(bytes), r4_timeout_finite(duration));
    (void)r4_service_connection_close(&connection);
    if (result.kind == R4_SERVICE_CALL_TIMED_OUT) return R4OS_SERVICE_API_RESULT_TIMEOUT;
    if (result.kind != R4_SERVICE_CALL_RESPONSE) return result.raw_code;
    if (result.bytes < sizeof(*reply)) return R4OS_DESKTOP_EVIDENCE_RESULT_INVALID;
    R4DesktopEvidenceReply value;
    r4_contract_copy(&value, bytes, sizeof(value));
    if (value.token.version != 1u || value.token.size != sizeof(value.token) ||
        value.phase > R4OS_DESKTOP_EVIDENCE_PHASE_UNAVAILABLE || value.result > 0 ||
        value.result < R4OS_DESKTOP_EVIDENCE_RESULT_RELEASED || value.data_bytes > capacity ||
        result.bytes != sizeof(value) + value.data_bytes) return R4OS_DESKTOP_EVIDENCE_RESULT_INVALID;
    if (op != R4OS_DESKTOP_EVIDENCE_OP_SCOPE &&
        (!r4_desktop_evidence_same_process(value.token.broker, request->token.broker) ||
         !r4_desktop_evidence_same_process(value.token.request, request->token.request) ||
         !r4_desktop_evidence_same_words(value.token.epoch, request->token.epoch) ||
         !r4_desktop_evidence_same_words(value.token.intent, request->token.intent) ||
         (request->token.serial && value.token.serial != request->token.serial) ||
         (r4_desktop_evidence_valid_process(request->token.process) && !r4_desktop_evidence_same_process(value.token.process, request->token.process)) ||
         (r4_desktop_evidence_valid_process(request->token.desktop) && !r4_desktop_evidence_same_process(value.token.desktop, request->token.desktop))))
        return R4OS_DESKTOP_EVIDENCE_RESULT_INVALID;
    if (value.data_bytes) r4_contract_copy(data, bytes + sizeof(value), value.data_bytes);
    *reply = value;
    return 0;
}
static inline int32_t r4_desktop_evidence_scope(R4App *app, R4DesktopEvidenceReply *reply) {
    R4DesktopEvidenceRequest request = {0}; request.token.version = 1u; request.token.size = sizeof(request.token);
    return r4_desktop_evidence_call(app, R4OS_DESKTOP_EVIDENCE_OP_SCOPE, &request, reply, 0, 0);
}
static inline int32_t r4_desktop_evidence_reserve(R4App *app, const R4DesktopEvidenceToken *intent, R4DesktopEvidenceReply *reply) {
    if (!intent || intent->serial != 0u) return R4OS_DESKTOP_EVIDENCE_RESULT_INVALID;
    R4DesktopEvidenceRequest request = {0}; request.token = *intent;
    return r4_desktop_evidence_call(app, R4OS_DESKTOP_EVIDENCE_OP_RESERVE, &request, reply, 0, 0);
}
static inline int32_t r4_desktop_evidence_token_call(R4App *app, uint16_t op, const R4DesktopEvidenceToken *token, R4DesktopEvidenceReply *reply) {
    if (!token || (op != R4OS_DESKTOP_EVIDENCE_OP_STATUS && token->serial == 0u)) return R4OS_DESKTOP_EVIDENCE_RESULT_INVALID;
    R4DesktopEvidenceRequest request = {0}; request.token = *token;
    return r4_desktop_evidence_call(app, op, &request, reply, 0, 0);
}
static inline int32_t r4_desktop_evidence_offer(R4App *app, const R4DesktopEvidenceToken *token, R4DesktopEvidenceReply *reply) {
    return r4_desktop_evidence_token_call(app, R4OS_DESKTOP_EVIDENCE_OP_OFFER, token, reply);
}
static inline int32_t r4_desktop_evidence_acknowledge(R4App *app, const R4DesktopEvidenceToken *token, R4DesktopEvidenceReply *reply) {
    return r4_desktop_evidence_token_call(app, R4OS_DESKTOP_EVIDENCE_OP_ACK, token, reply);
}
static inline int32_t r4_desktop_evidence_status(R4App *app, const R4DesktopEvidenceToken *token, R4DesktopEvidenceReply *reply) {
    return r4_desktop_evidence_token_call(app, R4OS_DESKTOP_EVIDENCE_OP_STATUS, token, reply);
}
static inline int32_t r4_desktop_evidence_read(R4App *app, const R4DesktopEvidenceToken *token, uint32_t offset,
        uint8_t *out, uint32_t capacity, R4DesktopEvidenceReply *reply) {
    if (!token || !out || !capacity || capacity > R4OS_DESKTOP_EVIDENCE_MAX_OUTPUT_CHUNK) return R4OS_DESKTOP_EVIDENCE_RESULT_INVALID;
    R4DesktopEvidenceRequest request = {0}; request.token = *token; request.offset = offset; request.capacity = capacity;
    return r4_desktop_evidence_call(app, R4OS_DESKTOP_EVIDENCE_OP_READ, &request, reply, out, capacity);
}
static inline int32_t r4_desktop_evidence_release(R4App *app, const R4DesktopEvidenceToken *token, R4DesktopEvidenceReply *reply) {
    return r4_desktop_evidence_token_call(app, R4OS_DESKTOP_EVIDENCE_OP_RELEASE, token, reply);
}

typedef struct R4DesktopEvidenceLease { R4App *app; R4DesktopEvidenceToken token; uint8_t owned; } R4DesktopEvidenceLease;
/* Adopt a persisted token without Retain. Every operation validates its old
 * service epoch; exporting transfers explicit release responsibility. */
static inline R4DesktopEvidenceLease r4_desktop_evidence_adopt(R4App *app, R4DesktopEvidenceToken token) {
    R4DesktopEvidenceLease lease = {app, token, 1u}; return lease;
}
static inline R4DesktopEvidenceToken r4_desktop_evidence_export(R4DesktopEvidenceLease *lease) {
    if (!lease) { R4DesktopEvidenceToken empty = {0}; return empty; }
    lease->owned = 0u; return lease->token;
}
static inline int32_t r4_desktop_evidence_close(R4DesktopEvidenceLease *lease, R4DesktopEvidenceReply *reply) {
    if (!lease || !lease->owned) return R4OS_ERR_NOT_OWNED;
    int32_t rc = r4_desktop_evidence_release(lease->app, &lease->token, reply);
    if (rc == 0 && (reply->result == R4OS_DESKTOP_EVIDENCE_RESULT_RELEASED || reply->result == R4OS_DESKTOP_EVIDENCE_RESULT_EXPIRED ||
        reply->result == R4OS_DESKTOP_EVIDENCE_RESULT_UNKNOWN || reply->result == R4OS_DESKTOP_EVIDENCE_RESULT_STALE)) lease->owned = 0u;
    return rc;
}
#endif
