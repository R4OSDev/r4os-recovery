R4OS SDK Templates
==================

These are installable project templates for R4CODE and R4BUILD under
C:/R4OS/SDK/Templates. Templates belong to the SDK, not to an application's
private directory.

The initial templates are:

  R4X C Terminal Hello  -> R4X_C_Console
  R4X C Desktop OK      -> R4X_C_Desktop_OK

R4CODE creates module.R4MF and source files from these templates. R4BUILD
validates, plans, and builds that manifest through R4PACK and R4CC.

The C console and desktop template directories own their module.R4MF and
source templates. Host-created projects use the same R4MF v2 contract and
thin build.zig/build.zig.zon entry points that delegate to the SDK. Zig
console templates are host-only because the native R4CC path implements the
current C subset.

Do not create a second template source of truth. template.ini describes only
catalog entries and filenames; language, module kind, application class,
imports, and targets remain in module.R4MF.template.
