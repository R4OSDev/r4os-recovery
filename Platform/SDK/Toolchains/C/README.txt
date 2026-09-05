R4OS SDK C Toolchain
====================

This is the installed target location for the native R4OS C toolchain:

    C:/R4OS/SDK/Toolchains/C

R4CC.R4X is installed under bin. R4CC is an R4OS bootstrap compiler; the
native path does not use an external host compiler or a private compiler copy
inside R4CODE.

The current R4MF v2 C application subset supports:

    #include <r4os/r4os.h>
    R4OS_TEXT(name, "text")
    int32_t r4_app_main(R4App *app)
    r4sys_write_line(&app->system, name)

R4CC emits raw text-section bytes for R4XStart and R4SYS. R4BUILD then uses
the R4PACK core to create an R4M0 .R4X in the project's out directory.

Supported profiles are R4X_C_App_Console and R4X_C_App_Desktop. Unsupported
profiles or languages fail with an explicit capability error; the build never
falls back to a host compiler or old entry point.

R4CC.STATUS records installed toolchain capabilities for R4BUILD. Worker
builds use the same R4CC and R4PACK logic directly without host tools or a
prebuilt example artifact.

Subdirectories:

- bin contains executable toolchain programs.
- lib is reserved for future runtime and helper objects.
- include-extra is reserved for toolchain-specific private headers.
