#include <r4os/r4os.h>
#include "../../../../Simulation/R4LProviders.c"
int32_t r4_app_main(R4App *app){int rc=sdk66_consume(app->context,"L66C",0x43);if(rc)return rc;return sdk66_consume(app->context,"L66R",0x52);}
