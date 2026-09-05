#include <r4os/r4os.h>
int32_t r4_app_main(R4App *app) {
    if (app->profile != R4_APP_PROFILE_SERVICE || !r4_app_has_group(app, R4L_GROUP_R4SYS) || r4_app_has_group(app, R4L_GROUP_R4DESK)) return 83;
    return r4sys_write_line(&app->system, "APPCSVC app entry: OK");
}
