/* Import into an observer using SDK126/Contract67 and WINSVC29/DESKRUN3.
 * launch_scope MUST come from the original launch JSON (or a scope saved
 * before that launch), with its exact broker/request generation. A fresh
 * scope read after restart cannot authenticate an old numeric launch key.
 *
 * persist must atomically save all128token bytes and confirm success. Use
 * provider-aware staging names and the SDK atomic replacement contract.
 * Each observer chooses/persists its own nonzero receiver_intent. */
#include <r4os/r4os.h>
typedef int32_t (*EvidencePersist)(void *context, const R4DesktopEvidenceToken *token);

static int32_t evidence_commit_offer(R4App *app, R4DesktopEvidenceReply *reply,
        EvidencePersist persist, void *context, R4DesktopEvidenceToken *saved) {
    *saved = reply->token;
    if (reply->result != 0 && reply->result != R4OS_DESKTOP_EVIDENCE_RESULT_PENDING) return reply->result;
    if (reply->phase != R4OS_DESKTOP_EVIDENCE_PHASE_OFFERED) return reply->result;
    int32_t rc = persist(context, saved); /* Canonical process identity before ACK. */
    if (rc != 0) return rc;
    rc = r4_desktop_evidence_acknowledge(app, saved, reply);
    if (rc != 0) return rc; /* Keep saved token; resolve a lost ACK with Status. */
    return reply->result;
}

int32_t desktop_evidence_begin(R4App *app, const R4DesktopEvidenceToken *launch_scope,
        R4ProgramProcessHandle request, const uint64_t receiver_intent[3],
        EvidencePersist persist, void *context, R4DesktopEvidenceToken *saved) {
    if (!persist || !saved) return R4OS_DESKTOP_EVIDENCE_RESULT_INVALID;
    int32_t rc = r4_desktop_evidence_prepare(launch_scope, request, receiver_intent, saved);
    if (rc != 0 || (rc = persist(context, saved)) != 0) return rc;
    R4DesktopEvidenceReply reply = {0};
    rc = r4_desktop_evidence_reserve(app, saved, &reply);
    if (rc != 0) return rc; /* Saved pre-intent resolves a lost reserve response. */
    if (reply.phase != R4OS_DESKTOP_EVIDENCE_PHASE_RESERVED || !reply.token.serial) return reply.result;
    *saved = reply.token;
    if ((rc = persist(context, saved)) != 0) return rc; /* Serial before any Retain. */
    rc = r4_desktop_evidence_offer(app, saved, &reply);
    if (rc != 0) return rc;
    return evidence_commit_offer(app, &reply, persist, context, saved);
}

int32_t desktop_evidence_resume(R4App *app, const R4DesktopEvidenceToken *saved,
        EvidencePersist persist, void *context, R4DesktopEvidenceToken *canonical,
        R4DesktopEvidenceReply *reply) {
    if (!saved || !persist || !canonical || !reply) return R4OS_DESKTOP_EVIDENCE_RESULT_INVALID;
    int32_t rc = r4_desktop_evidence_status(app, saved, reply); /* Read-only first. */
    if (rc != 0) return rc;
    if (reply->phase == R4OS_DESKTOP_EVIDENCE_PHASE_RESERVED) {
        /* The authoritative status confirmed that Offer did not apply.
         * Save/reuse this SAME serial; never allocate a new intent/reference. */
        *canonical = reply->token;
        if ((rc = persist(context, canonical)) != 0) return rc;
        rc = r4_desktop_evidence_offer(app, canonical, reply);
        if (rc != 0) return rc;
    }
    if (reply->phase == R4OS_DESKTOP_EVIDENCE_PHASE_OFFERED)
        return evidence_commit_offer(app, reply, persist, context, canonical);
    *canonical = reply->token;
    return reply->result; /* Acked: observe. Waiting: wait in the caller's loop.
                          * Expired/Unknown/Stale: explicit loss, no respawn. */
}

/* After acknowledged Status returns0, use r4_desktop_evidence_read and the
 * original completion.sequence/handle/flags. data_bytes0 is genuine empty/EOF;
 * unavailable is a separate result. Finally release this exact saved token.
 * An acknowledged lease survives observer exit until Release or broker end.
 * Copies alias one lease; use separate intents for independent observers. */
