R4OS SDK Windows Host Profile
=============================

This profile supports R4CodePad and standalone Zig or C projects on Windows.
Projects bind the r4os_sdk package through build.zig.zon and keep their own
source paths project-local. The SDK resolves r4os.zig, linker scripts,
C headers, startup objects, and host tools from its mapped roots.

Windows-specific executable paths belong in host settings, never in portable
module.R4MF project manifests. R4CP is accepted only by the explicit one-time
converter and is not a current project format.
