#include <r4os/abi_generated.h>
#include <r4os/generation2.h>
#include <emmintrin.h>

int32_t r4os_c_generation2(const R4XStartContext2 *context, const R4XStartR4Sys2 *table) {
    if(context->magic != R4OS2_START_MAGIC || context->abi_major != 2 || context->size != 120 ||
       table->magic != R4OS2_R4SYS_MAGIC || table->abi_version != 6 || table->size != sizeof(*table) || table->write == 0) return -1;
    const R4SysWriteFn call = (R4SysWriteFn)(uintptr_t)table->write;
    return call((const uint8_t*)"API2",4);
}

/* Two independent projections of the existing borrowed callback-slot ABI. */
_Static_assert(__builtin_types_compatible_p(__typeof__(((R4ProtocolApi *)0)->cpu_acceleration_work), R4DevCpuAccelerationWorkFn), "protocol callback pointer/const levels");

uint32_t r4os_c_gui_window_flag(uint32_t index) {
    const uint32_t flags[] = {R4ABI_GUI_WINDOW_FLAG_VISIBLE, R4ABI_GUI_WINDOW_FLAG_MINIMIZED,
        R4ABI_GUI_WINDOW_FLAG_MAXIMIZED, R4ABI_GUI_WINDOW_FLAG_CLOSE_REQUESTED};
    return index < sizeof(flags) / sizeof(flags[0]) ? flags[index] : 0;
}

/* Pure table/callback transport, not a driver/protocol lifecycle or allocator. */
static uint8_t protocol_marker;
static void technical_log(const uint8_t *text) { (void)text; }
static int32_t technical_role(const uint8_t *role, uint32_t major, uint32_t minor) { (void)role; (void)major; (void)minor; return 0; }
static int32_t technical_status(uint32_t state, const uint8_t *text) { (void)state; (void)text; return 0; }
static int32_t technical_dependency(const uint8_t *name) { (void)name; return 0; }
static void *technical_alloc(uint32_t bytes, uint32_t alignment) { return bytes == 17 && alignment == 64 ? &protocol_marker : 0; }
static void technical_free(void *data, uint32_t bytes) { (void)data; (void)bytes; }
static int32_t technical_read(const uint8_t *path, uint8_t *data, uint32_t bytes) { (void)path; (void)data; (void)bytes; return -1; }

int32_t r4os_c_technical_callbacks(void *(*forward)(const R4ProtocolApi *, uint32_t, uint32_t), R4AudioSidModelNameFn model_name) {
    const R4ProtocolApi api = {
        .magic = 0x81234567u, .version = 1, .size = sizeof(R4ProtocolApi),
        .log_info = technical_log, .log_warn = technical_log, .log_error = technical_log,
        .register_role = technical_role, .set_status = technical_status,
        .dependency_status = technical_dependency, .alloc = technical_alloc,
        .free = technical_free, .file_read = technical_read
    };
    if (forward(&api, 17, 64) != &protocol_marker || forward(&api, 0, 64) != 0) return -1;
    const uint8_t *name = model_name();
    const uint8_t expected[] = "SID-ABI";
    for (uint32_t i = 0; i < sizeof(expected); ++i) if (name[i] != expected[i]) return -2;
    return 0;
}

/* Pure event/handle transport: no console, CPU or hardware access. */
int32_t r4os_c_console_events(const R4ProgramProcessHandle *handle, const R4ConsoleInputEvent *events, uint32_t count) {
    if (handle->instance_id != 37 || handle->reserved != 0 || handle->generation != UINT64_C(0xfedcba9876543210) || count != 4) return -1;
    const uint32_t kinds[4] = {1, 2, 3, 1};
    const uint32_t values[4] = {0x20ac, 0x80, 0x81, 0x1f600};
    for (uint32_t i = 0; i < count; ++i)
        if (events[i].version != 1 || events[i].flags != 0 || events[i].kind != kinds[i] || events[i].value != values[i]) return -2;
    return 3; /* A successful prefix, not a byte count. */
}

// A SIMD-capable module consumer calls the integer/pointer Platform ABI.
// Live vector and floating-point data are retained across the Rust call.
int32_t r4os_c_rust_call(R4SysWriteFn callback, const uint8_t *data, uint32_t size) {
    const __m128i original = _mm_set_epi32(0x12345678, 0x23456789, 0x3456789a, 0x456789ab);
    volatile double multiplier = 1.25;
    const double floating = multiplier * 4.0;
    __m128i saved = original;
    // The barrier prevents the vector from being regenerated as constants.
    __asm__ volatile("" : "+x"(saved) : : "memory");
    const int32_t result = callback(data, size);
    __asm__ volatile("" : "+x"(saved) : : "memory");
    if (_mm_movemask_epi8(_mm_cmpeq_epi8(original, saved)) != 0xffff) return -1;
    if (floating != 5.0) return -2;
    return result;
}

/* Typed pure callback transport only, no actual PMU or hardware probe. */
int32_t r4os_c_pmu_work(uint64_t context, uint32_t iterations) {
    return context == UINT64_C(0x8123456789abcdef) && iterations == 4096 ? -30005 : -1;
}

/* Typed transport only; never execute optional CPU instructions on the host. */
int32_t r4os_c_pure_work(uint64_t context, uint32_t iterations) {
    return context == UINT64_C(0x8123456789abcdef) && iterations == 64 ? -30015 : -1;
}

/* Integer/pointer transport fixture, not a device or random-value test. */
int32_t r4os_c_entropy_read(uint64_t context, uint8_t *data, uint32_t bytes, R4EntropyDeviceReceipt *out) {
    if (context != UINT64_C(0xfedcba9876543210) || bytes != 17) return -1;
    static const uint8_t marker[17] = "entropy-fixture!!";
    for (uint32_t i = 0; i < bytes; ++i) data[i] = marker[i];
    R4EntropyDeviceReceipt value = {0};
    value.version = 1; value.size = sizeof(value);
    value.requested_bytes = bytes; value.completed_bytes = bytes;
    value.status = R4OS_ENTROPY_DEVICE_STATUS_BAD_COMPLETION;
    value.flags = R4OS_ENTROPY_RECEIPT_FLAG_RETAINED;
    value.request_generation = context;
    value.available_index_before = 65534; value.available_index_after = 3;
    *out = value;
    return -30027;
}
