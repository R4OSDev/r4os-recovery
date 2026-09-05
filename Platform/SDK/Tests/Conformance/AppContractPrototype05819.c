#include <r4os/r4os.h>

static R4Status console_prototype(const R4XStartContext *context, R4App *app) {
    return r4_app_init(context, R4_APP_PROFILE_CONSOLE, app);
}

static R4Status desktop_prototype(const R4XStartContext *context, R4App *app) {
    return r4_app_init(context, R4_APP_PROFILE_DESKTOP, app);
}

static R4Status service_prototype(const R4XStartContext *context, R4App *app) {
    return r4_app_init(context, R4_APP_PROFILE_SERVICE, app);
}

int main(void) {
    if (R4_ERROR_DOMAIN_NONE != 0 || R4_ERROR_DOMAIN_AUDIO != 14 || R4_ERROR_DOMAIN_DEVICE != 15) return 1;
    R4Status failures[] = {
        r4_status_failure(R4_ERROR_DOMAIN_CONTRACT, R4OS_ERR_NO_GROUP),
        r4_status_failure(R4_ERROR_DOMAIN_CONTRACT, R4OS_ERR_NO_FN),
        r4_status_failure(R4_ERROR_DOMAIN_FILESYSTEM, -101),
        r4_status_failure(R4_ERROR_DOMAIN_THREAD, -202),
        r4_status_failure(R4_ERROR_DOMAIN_SERVICE, -303),
        r4_status_failure(R4_ERROR_DOMAIN_NETWORK, -404),
        r4_status_failure(R4_ERROR_DOMAIN_AUDIO, -505)
    };
    const int32_t expected[] = {
        R4OS_ERR_NO_GROUP, R4OS_ERR_NO_FN, -101, -202, -303, -404, -505
    };

    for (unsigned int index = 0; index < sizeof(failures) / sizeof(failures[0]); ++index) {
        if (failures[index].raw_code != expected[index]) return 10 + (int)index;
        if (r4_status_succeeded(failures[index])) return 20 + (int)index;
    }
    if (failures[4].domain != R4_ERROR_DOMAIN_SERVICE) return 28;

    R4ThreadHandle owned = {42u, 1u, {0}};
    if (R4ThreadHandle_apply_close_result(&owned, -202) != -202) return 29;
    if (!R4ThreadHandle_valid(&owned)) return 30;
    R4ThreadHandle_apply_close_result(&owned, 0);
    if (R4ThreadHandle_valid(&owned)) return 30;

    R4ThreadHandle borrowed = {42u, 0u, {0}};
    R4ThreadHandle_apply_close_result(&borrowed, 0);
    if (!R4ThreadHandle_valid(&borrowed)) return 31;

    R4WindowHandle window = {7, 1u, {0}};
    R4WindowHandle_apply_close_result(&window, 0);
    if (R4WindowHandle_valid(&window) || window.raw != -1) return 32;

    (void)console_prototype;
    (void)desktop_prototype;
    (void)service_prototype;
    return 0;
}
