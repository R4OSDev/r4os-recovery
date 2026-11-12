/* Scalar exports of existing SDK facade algorithms. Rust links this SDK-owned
 * object; C retains the same inline owner, without a third path parser. */
#include <r4os/r4dev.h>
/* Export the existing scalar time and serial owners before App includes their
 * headers. Supporting platform functions remain private. */
#define static
#define inline
#include <r4os/path_timeout.h>
#include <r4os/serial.h>
#undef inline
#undef static
#include <r4os/app_contract.h>
#include <r4os/heap.h>
/* Emit the existing inline facade bodies once for foreign-language callers.
 * The supporting platform helpers remain private to this object. */
#define static
#define inline
#include <r4os/app_storage.h>
#include <r4os/app_resources.h>
#include <r4os/desktop_evidence.h>
#include <r4os/desktop_actions.h>
#include <r4os/app_network.h>
#include <r4os/app_tray.h>
#include <r4os/storage.h>
#include <r4os/directory_page.h>
#include <r4os/gui_bridge.h>
#include <r4os/platform_facade2.h>
#include <r4os/data_helpers.h>
#include <r4os/web_helpers.h>
#include <r4os/transport_helpers.h>
#include <r4os/update_helpers.h>
#include <r4os/subsystem_helpers.h>
#include <r4os/driver_helpers.h>
#undef inline
#undef static
#include <r4os/facades.h>

int32_t R4SdkFilePath(const uint8_t *input, uintptr_t length, int32_t kind,
                     uint8_t *out, uintptr_t capacity, uint16_t *out_length,
                     uint8_t *out_absolute) {
    if (!out || capacity < R4OS_FILE_PATH_MAX_BYTES + 1u || !out_length || !out_absolute || kind < -1 || kind > 1)
        return R4_PATH_WRONG_KIND;
    *out_length = 0;
    *out_absolute = 0;
    return r4_path_normalize(input,length,kind,out,out_length,out_absolute);
}

int32_t R4SdkRegistryPath(const uint8_t *input, uintptr_t length,
                         uint8_t *out, uintptr_t capacity, uint16_t *out_length) {
    if (!out || capacity < R4OS_REGISTRY_PATH_MAX_BYTES + 1u || !out_length) return R4_PATH_TOO_LONG;
    *out_length = 0;
    R4RegistryPath path;
    int32_t result = r4_registry_path(input,length,&path);
    if (result != R4_PATH_OK) return result;
    r4_contract_copy(out,path.bytes,(uintptr_t)path.length + 1u);
    *out_length = path.length;
    return R4_PATH_OK;
}

int32_t R4SdkAppFacade(const R4XStartContext *context, R4App *out) {
    if (!context) return R4OS_ERROR_INVALID;
    R4AppProfile profile;
    switch (context->app_class) {
    case R4XSTART_APP_CLASS_CONSOLE: profile = R4_APP_PROFILE_CONSOLE; break;
    case R4XSTART_APP_CLASS_GUI: profile = R4_APP_PROFILE_DESKTOP; break;
    case R4XSTART_APP_CLASS_SERVICE: profile = R4_APP_PROFILE_SERVICE; break;
    default: return R4OS_ERROR_INVALID;
    }
    return r4_app_init(context, profile, out).raw_code;
}

int32_t R4SdkAppFacade2(const R4OS2Context *context, const R4App2Memory *memory, R4App *out) {
    return r4_app_init2(context, memory, out);
}
