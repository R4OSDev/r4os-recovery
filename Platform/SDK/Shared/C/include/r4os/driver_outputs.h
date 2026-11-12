#ifndef R4OS_DRIVER_OUTPUTS_H
#define R4OS_DRIVER_OUTPUTS_H
#include "r4draw.h"

static inline int r4driver_output_supports_power(const R4GfxDriverOutputApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverOutputApi, power_read) + sizeof(uint64_t) &&
        table->power_publish != 0 && table->power_read != 0;
}
static inline int32_t r4driver_output_publish_power(const R4GfxDriverOutputApi *table, const R4GfxOutputPower *input) {
    if (!r4driver_output_supports_power(table)) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxOutputPower *);
    return ((Callback)(uintptr_t)table->power_publish)(input);
}
static inline int32_t r4driver_output_read_power(const R4GfxDriverOutputApi *table, const R4GfxOutputId *identity, R4GfxPowerRequest *output) {
    if (!r4driver_output_supports_power(table)) return R4OS_ERR_NO_FN;
    if (identity == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxOutputId *, R4GfxPowerRequest *);
    R4GfxPowerRequest value = {0}; value.version = 1; value.size = sizeof(value);
    int32_t code = ((Callback)(uintptr_t)table->power_read)(identity, &value);
    if (code == R4OS_GFX_OUTPUT_OK) *output = value;
    return code;
}
static inline int r4driver_output_supports_brightness(const R4GfxDriverOutputApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverOutputApi, brightness_read) + sizeof(uint64_t) &&
        table->brightness_publish != 0 && table->brightness_read != 0;
}
static inline int32_t r4driver_output_publish_brightness(const R4GfxDriverOutputApi *table, const R4GfxOutputBrightness *input) {
    if (!r4driver_output_supports_brightness(table)) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxOutputBrightness *);
    return ((Callback)(uintptr_t)table->brightness_publish)(input);
}
static inline int32_t r4driver_output_read_brightness(const R4GfxDriverOutputApi *table, const R4GfxOutputId *identity, R4GfxBrightnessRequest *output) {
    if (!r4driver_output_supports_brightness(table)) return R4OS_ERR_NO_FN;
    if (identity == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxOutputId *, R4GfxBrightnessRequest *);
    R4GfxBrightnessRequest value = {0}; value.version = 1; value.size = sizeof(value);
    int32_t code = ((Callback)(uintptr_t)table->brightness_read)(identity, &value);
    if (code == R4OS_GFX_OUTPUT_OK) *output = value;
    return code;
}

static inline int r4driver_output_supports_refresh(const R4GfxDriverOutputApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverOutputApi, refresh_read) + sizeof(uint64_t) &&
        table->refresh_publish != 0 && table->refresh_read != 0;
}
static inline int32_t r4driver_output_publish_refresh(const R4GfxDriverOutputApi *table, const R4GfxOutputRefresh *input) {
    if (!r4driver_output_supports_refresh(table)) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxOutputRefresh *);
    return ((Callback)(uintptr_t)table->refresh_publish)(input);
}
static inline int32_t r4driver_output_read_refresh(const R4GfxDriverOutputApi *table, const R4GfxOutputTarget *target, R4GfxRefreshRequest *output) {
    if (!r4driver_output_supports_refresh(table)) return R4OS_ERR_NO_FN;
    if (target == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxOutputTarget *, R4GfxRefreshRequest *);
    R4GfxRefreshRequest value = {0}; value.version = 1; value.size = sizeof(value);
    int32_t code = ((Callback)(uintptr_t)table->refresh_read)(target, &value);
    if (code == R4OS_GFX_OUTPUT_OK) *output = value;
    return code;
}

static inline int r4driver_output_supports_mode_color(const R4GfxDriverOutputApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverOutputApi, mode_read_color) + sizeof(uint64_t) &&
        table->mode_enable != 0 && table->mode_take != 0 && table->mode_complete != 0 && table->mode_read_color != 0;
}
static inline int32_t r4driver_output_read_mode_color(const R4GfxDriverOutputApi *table, uint64_t ticket, uint64_t sequence, R4GfxDriverModeColor *output) {
    if (!r4driver_output_supports_mode_color(table)) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(uint64_t, uint64_t, R4GfxDriverModeColor *);
    return ((Callback)(uintptr_t)table->mode_read_color)(ticket, sequence, output);
}

static inline int r4driver_output_supports_color(const R4GfxDriverOutputApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverOutputApi, color_publish) + sizeof(uint64_t) && table->color_publish != 0;
}
static inline int32_t r4driver_output_publish_color(const R4GfxDriverOutputApi *table, const R4GfxOutputColorState *input) {
    if (!r4driver_output_supports_color(table)) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxOutputColorState *);
    return ((Callback)(uintptr_t)table->color_publish)(input);
}

static inline int r4driver_output_supports_hotplug(const R4GfxDriverOutputApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverOutputApi, mode_status) + sizeof(uint64_t) &&
        table->output_pause != 0 && table->mode_restore != 0 && table->mode_status != 0;
}
static inline int32_t r4driver_output_pause(const R4GfxDriverOutputApi *table, const R4GfxOutputId *output, uint32_t paused) {
    if (!r4driver_output_supports_hotplug(table)) return R4OS_ERR_NO_FN;
    if (output == 0 || paused > 1) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxOutputId *, uint32_t);
    return ((Callback)(uintptr_t)table->output_pause)(output, paused);
}
static inline int32_t r4driver_output_restore_mode(const R4GfxDriverOutputApi *table, const R4GfxAtomicState *input, R4GfxModeStatus *output) {
    if (!r4driver_output_supports_hotplug(table)) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxAtomicState *, R4GfxModeStatus *);
    return ((Callback)(uintptr_t)table->mode_restore)(input, output);
}
static inline int32_t r4driver_output_mode_status(const R4GfxDriverOutputApi *table, uint64_t ticket, R4GfxModeStatus *output) {
    if (!r4driver_output_supports_hotplug(table)) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(uint64_t, R4GfxModeStatus *);
    return ((Callback)(uintptr_t)table->mode_status)(ticket, output);
}

static inline int r4driver_output_supports_audio(const R4GfxDriverOutputApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverOutputApi, audio_query) + sizeof(uint64_t) &&
        table->audio_publish != 0 && table->audio_query != 0;
}
static inline int32_t r4driver_output_publish_audio(const R4GfxDriverOutputApi *table, const R4GfxAudioRoute *input) {
    if (!r4driver_output_supports_audio(table)) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxAudioRoute *);
    return ((Callback)(uintptr_t)table->audio_publish)(input);
}
static inline int32_t r4driver_output_query_audio(const R4GfxDriverOutputApi *table, uint32_t location, uint32_t device, uint32_t index, R4GfxAudioRoute *output) {
    if (!r4driver_output_supports_audio(table)) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(uint32_t, uint32_t, uint32_t, R4GfxAudioRoute *);
    return ((Callback)(uintptr_t)table->audio_query)(location, device, index, output);
}

static inline int r4driver_output_supports_modes(const R4GfxDriverOutputApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverOutputApi, mode_complete) + sizeof(uint64_t) &&
        table->mode_enable != 0 && table->mode_take != 0 && table->mode_complete != 0;
}
static inline int32_t r4driver_output_enable_modes(const R4GfxDriverOutputApi *table, const R4GfxBackendBinding *backend) {
    if (!r4driver_output_supports_modes(table)) return R4OS_ERR_NO_FN;
    if (backend == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxBackendBinding *);
    return ((Callback)(uintptr_t)table->mode_enable)(backend);
}
static inline int32_t r4driver_output_take_mode(const R4GfxDriverOutputApi *table, const R4GfxBackendBinding *backend, R4GfxDriverModeJob *output) {
    if (!r4driver_output_supports_modes(table)) return R4OS_ERR_NO_FN;
    if (backend == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxBackendBinding *, R4GfxDriverModeJob *);
    return ((Callback)(uintptr_t)table->mode_take)(backend, output);
}
static inline int32_t r4driver_output_complete_mode(const R4GfxDriverOutputApi *table, const R4GfxDriverModeCompletion *input) {
    if (!r4driver_output_supports_modes(table)) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxDriverModeCompletion *);
    return ((Callback)(uintptr_t)table->mode_complete)(input);
}

static inline int r4driver_output_supports_receivers(const R4GfxDriverOutputApi *table) {
    return table != 0 && table->version == 1 && table->size >= offsetof(R4GfxDriverOutputApi, close_source) + sizeof(uint64_t) &&
        table->register_source != 0 && table->replace_receivers != 0 && table->close_source != 0;
}
static inline int32_t r4driver_output_register_source(const R4GfxDriverOutputApi *table, uint32_t adapter, R4GfxReceiverSource *output) {
    if (!r4driver_output_supports_receivers(table)) return R4OS_ERR_NO_FN;
    if (output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(uint32_t, R4GfxReceiverSource *);
    return ((Callback)(uintptr_t)table->register_source)(adapter, output);
}
static inline int32_t r4driver_output_replace_receivers(const R4GfxDriverOutputApi *table, const R4GfxReceiverUpdate *input) {
    if (!r4driver_output_supports_receivers(table)) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxReceiverUpdate *);
    return ((Callback)(uintptr_t)table->replace_receivers)(input);
}
static inline int32_t r4driver_output_close_source(const R4GfxDriverOutputApi *table, const R4GfxReceiverSource *input) {
    if (!r4driver_output_supports_receivers(table)) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxReceiverSource *);
    return ((Callback)(uintptr_t)table->close_source)(input);
}

static inline int32_t r4driver_output_publish(const R4GfxDriverOutputApi *table, const R4GfxOutputPublication *input, R4GfxOutputId *output) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverOutputApi, publish) + sizeof(uint64_t) || table->publish == 0) return R4OS_ERR_NO_FN;
    if (input == 0 || output == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxOutputPublication *, R4GfxOutputId *);
    return ((Callback)(uintptr_t)table->publish)(input, output);
}
static inline int32_t r4driver_output_withdraw(const R4GfxDriverOutputApi *table, const R4GfxOutputId *input) {
    if (table == 0 || table->version != 1 || table->size < offsetof(R4GfxDriverOutputApi, withdraw) + sizeof(uint64_t) || table->withdraw == 0) return R4OS_ERR_NO_FN;
    if (input == 0) return R4OS_GFX_OUTPUT_ERROR_INVALID;
    typedef int32_t (*Callback)(const R4GfxOutputId *);
    return ((Callback)(uintptr_t)table->withdraw)(input);
}
#endif
