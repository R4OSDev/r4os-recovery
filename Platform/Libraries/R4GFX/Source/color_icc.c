/* R4OS userland adapter. LittleCMS is internal; no raw CMS context escapes
 * this owner. Every context and transform owns a bounded caller arena. */
#include "lcms2_plugin.h"
#include <stdint.h>

extern void *r4gfx_icc_alloc(void *arena, uint32_t bytes);
extern void *r4gfx_icc_realloc(void *arena, void *old, uint32_t bytes);
extern void r4gfx_icc_error(void *arena, uint32_t error);

static void *allocate(cmsContext ctx, cmsUInt32Number n) { return r4gfx_icc_alloc(cmsGetContextUserData(ctx), n); }
static void release(cmsContext ctx, void *p) { (void)ctx; (void)p; }
static void *resize(cmsContext ctx, void *p, cmsUInt32Number n) { return r4gfx_icc_realloc(cmsGetContextUserData(ctx), p, n); }
static void *zero(cmsContext ctx, cmsUInt32Number n) {
    void *p = allocate(ctx, n); if (p) memset(p, 0, n); return p;
}
static void *array(cmsContext ctx, cmsUInt32Number count, cmsUInt32Number size) {
    if (size && count > UINT32_MAX / size) return NULL;
    return zero(ctx, count * size);
}
static void *duplicate(cmsContext ctx, const void *data, cmsUInt32Number n) {
    void *p = allocate(ctx, n); if (p && n) memcpy(p, data, n); return p;
}
static const cmsPluginMemHandler memory_plugin = {
    { cmsPluginMagicNumber, LCMS_VERSION, cmsPluginMemHandlerSig, NULL },
    allocate, release, resize, zero, array, duplicate
};
static void report(cmsContext ctx, cmsUInt32Number code, const char *text) {
    (void)text; r4gfx_icc_error(cmsGetContextUserData(ctx), code);
}
static cmsContext context(void *arena) {
    cmsContext ctx = cmsCreateContext((void *)&memory_plugin, arena);
    if (ctx) cmsSetLogErrorHandlerTHR(ctx, report);
    return ctx;
}
typedef struct {
    cmsContext context;
    cmsHPROFILE profile, working;
    cmsHTRANSFORM transform;
    const cmsToneCurve *calibration[3];
    unsigned gray_input;
} R4GfxIcc;

void r4gfx_icc_close(void *handle) {
    R4GfxIcc *state = handle;
    if (!state || !state->context) return;
    if (state->transform) cmsDeleteTransform(state->transform);
    if (state->working) cmsCloseProfile(state->working);
    if (state->profile) cmsCloseProfile(state->profile);
    cmsDeleteContext(state->context);
    memset(state, 0, sizeof(*state));
}

/* direction0: encoded RGB -> relative PCS XYZ(D50). direction1: reverse.
 * input bytes remain in the caller arena through close; no host I/O exists. */
int r4gfx_icc_open(void *arena, const void *data, uint32_t length, uint32_t direction,
                   uint32_t intent, uint32_t black_compensation, uint32_t calibration, void **out) {
    cmsContext ctx;
    R4GfxIcc *state;
    cmsProfileClassSignature kind;
    cmsUInt32Number flags = cmsFLAGS_NOCACHE | cmsFLAGS_NOOPTIMIZE;
    if (direction > 1 || intent > 3 || black_compensation > 1 || calibration > 1 || (calibration && !direction)) return -1;
    ctx = context(arena);
    if (!ctx) return -2;
    state = zero(ctx, sizeof(*state));
    if (!state) { cmsDeleteContext(ctx); return -2; }
    state->context = ctx;
    state->profile = cmsOpenProfileFromMemTHR(ctx, data, length);
    if (!state->profile) goto fail;
    kind = cmsGetDeviceClass(state->profile);
    state->gray_input = !direction && cmsGetColorSpace(state->profile) == cmsSigGrayData;
    if ((!state->gray_input && cmsGetColorSpace(state->profile) != cmsSigRgbData) ||
        (direction && kind != cmsSigDisplayClass) ||
        (!direction && kind != cmsSigDisplayClass && kind != cmsSigInputClass && kind != cmsSigColorSpaceClass)) goto fail;
    /* Transform creation owns ICC.1:2022 section 8.10.2 tag precedence,
     * including A2B0/B2A0 when the requested intent has no dedicated LUT.
     * cmsIsIntentSupported only tests dedicated CLUT or matrix/shaper tags
     * and would reject valid LUT-only profiles before this fallback. */
    state->working = cmsCreateXYZProfileTHR(ctx);
    if (!state->working) goto fail;
    if (black_compensation) flags |= cmsFLAGS_BLACKPOINTCOMPENSATION;
    state->transform = direction ?
        cmsCreateTransformTHR(ctx, state->working, TYPE_XYZ_FLT, state->profile, TYPE_RGB_FLT, intent, flags) :
        cmsCreateTransformTHR(ctx, state->profile, state->gray_input ? TYPE_GRAY_FLT : TYPE_RGB_FLT, state->working, TYPE_XYZ_FLT, intent, flags);
    if (!state->transform) goto fail;
    if (calibration && cmsIsTag(state->profile, cmsSigVcgtTag)) {
        cmsToneCurve **curves = cmsReadTag(state->profile, cmsSigVcgtTag);
        unsigned i;
        if (!curves) goto fail;
        for (i = 0; i < 3; ++i) {
            if (!curves[i] || !cmsIsToneCurveMonotonic(curves[i]) || cmsIsToneCurveDescending(curves[i])) goto fail;
            state->calibration[i] = curves[i];
        }
    }
    *out = state;
    return 0;
fail:
    r4gfx_icc_close(state);
    return -3;
}

int r4gfx_icc_apply(void *handle, const float *input, float *output, uint32_t pixels) {
    R4GfxIcc *state = handle;
    uint32_t pixel;
    unsigned channel;
    if (state->gray_input) {
        float gray[64];
        /* RGBA image decoders expand gray into equal RGB channels. Reject
         * contradictory colored data before touching the destination. */
        for (pixel = 0; pixel < pixels; ++pixel)
            if (input[pixel * 3] != input[pixel * 3 + 1] || input[pixel * 3] != input[pixel * 3 + 2]) return -1;
        for (pixel = 0; pixel < pixels;) {
            unsigned n = pixels - pixel, i;
            if (n > 64) n = 64;
            for (i = 0; i < n; ++i) gray[i] = input[(pixel + i) * 3];
            cmsDoTransform(state->transform, gray, output + pixel * 3, n);
            pixel += n;
        }
    } else cmsDoTransform(state->transform, input, output, pixels);
    if (state->calibration[0]) for (pixel = 0; pixel < pixels; ++pixel)
        for (channel = 0; channel < 3; ++channel)
            output[pixel * 3 + channel] = cmsEvalToneCurveFloat(state->calibration[channel], output[pixel * 3 + channel]);
    return 0;
}

/* Original R4OS profile construction using the public LCMS API. Values are
 * white xy, RGB xy and three decoding exponents. Gray retains its one-channel
 * ICC characterization even though the image container uses RGBA storage. */
int r4gfx_icc_generate(void *arena, uint32_t gray, uint32_t srgb_curve,
                      const double *values, void *output, uint32_t *length) {
    cmsContext ctx = context(arena);
    cmsHPROFILE profile = NULL;
    cmsToneCurve *curves[3] = { NULL, NULL, NULL };
    const cmsCIExyY white = { values[0], values[1], 1 };
    const cmsCIExyYTRIPLE primaries = {
        { values[2], values[3], 1 }, { values[4], values[5], 1 }, { values[6], values[7], 1 }
    };
    const double srgb[5] = { 2.4, 1.0 / 1.055, 0.055 / 1.055, 1.0 / 12.92, 0.04045 };
    cmsUInt32Number needed = 0;
    int result = -1;
    unsigned i, channels = gray ? 1 : 3;
    if (!ctx) return -2;
    for (i = 0; i < channels; ++i) {
        curves[i] = srgb_curve ? cmsBuildParametricToneCurve(ctx, 4, srgb) : cmsBuildGamma(ctx, values[8 + i]);
        if (!curves[i]) goto done;
    }
    profile = gray ? cmsCreateGrayProfileTHR(ctx, &white, curves[0]) : cmsCreateRGBProfileTHR(ctx, &white, &primaries, curves);
    if (profile && cmsSaveProfileToMem(profile, NULL, &needed) && needed <= *length && cmsSaveProfileToMem(profile, output, &needed)) {
        *length = needed;
        result = 0;
    }
done:
    if (profile) cmsCloseProfile(profile);
    for (i = 0; i < channels; ++i) if (curves[i]) cmsFreeToneCurve(curves[i]);
    cmsDeleteContext(ctx);
    return result;
}

/* Deterministic standard profiles, serialized entirely in caller memory.
 * kind0: sRGB, kind1: linear BT.709, kind2: linear BT.2020. */
int r4gfx_icc_builtin(void *arena, uint32_t kind, void *output, uint32_t *length) {
    cmsContext ctx = context(arena);
    cmsHPROFILE profile = NULL;
    cmsToneCurve *curve = NULL;
    cmsUInt32Number needed = 0;
    int result = -1;
    if (!ctx) return -2;
    if (kind == 0) profile = cmsCreate_sRGBProfileTHR(ctx);
    else if (kind == 1 || kind == 2) {
        const cmsCIExyY white = { 0.3127, 0.3290, 1.0 };
        const cmsCIExyYTRIPLE srgb = { { 0.64, 0.33, 1 }, { 0.30, 0.60, 1 }, { 0.15, 0.06, 1 } };
        const cmsCIExyYTRIPLE bt2020 = { { 0.708, 0.292, 1 }, { 0.170, 0.797, 1 }, { 0.131, 0.046, 1 } };
        cmsToneCurve *curves[3];
        curve = cmsBuildGamma(ctx, 1.0);
        curves[0] = curves[1] = curves[2] = curve;
        if (curve) profile = cmsCreateRGBProfileTHR(ctx, &white, kind == 1 ? &srgb : &bt2020, curves);
    }
    if (profile && cmsSaveProfileToMem(profile, NULL, &needed) && needed <= *length &&
        cmsSaveProfileToMem(profile, output, &needed)) {
        *length = needed;
        result = 0;
    }
    if (profile) cmsCloseProfile(profile);
    if (curve) cmsFreeToneCurve(curve);
    cmsDeleteContext(ctx);
    return result;
}
