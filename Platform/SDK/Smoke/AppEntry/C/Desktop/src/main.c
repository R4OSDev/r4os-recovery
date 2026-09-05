#include <r4os/r4os.h>
int32_t r4_app_main(R4App *app) {
    if (app->profile != R4_APP_PROFILE_DESKTOP || !r4_app_has_group(app, R4L_GROUP_R4DESK) || !r4_app_has_group(app, R4L_GROUP_R4DRAW)) return 82;
    return r4sys_write_line(&app->system, "APPCDESK app entry: OK");
}
