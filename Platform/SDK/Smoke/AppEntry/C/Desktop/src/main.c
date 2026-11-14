#include <r4os/app2.h>
#include <r4os/r4os.h>
static int32_t smoke_case(R4App *app) {
    if (app->profile != R4_APP_PROFILE_DESKTOP || !r4_app_has_group(app, R4L_GROUP_R4DESK) || !r4_app_has_group(app, R4L_GROUP_R4DRAW)) return 82;
    return r4sys_write_line(&app->system, "APPCDESK app entry: OK");
}

int32_t r4_app_main(R4App2 *app) {
    R4App facade;
    const int32_t rc = r4_app2_facade(app, &facade);
    return rc < 0 ? rc : smoke_case(&facade);
}
