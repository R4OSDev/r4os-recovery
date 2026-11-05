# Recovery tools

This directory owns the Recovery menu, installation and update workflows.
`Menu/` implements RECOVERY.R4X using the pinned SDK and its regular
console/program interfaces. The build validates its R4M0 imports and installs
it beside the frozen runtime modules. UI rendering remains application code;
the Recovery kernel supplies the ordinary framebuffer and console mechanisms.
Reusable disk operations belong to the normal SDK, R4PART application and
storage APIs; ZIP decoding belongs to the external R4ZIP protocol project.

`Contracts.de.txt` defines the version 1 boot identity, package/state formats
and the implemented installation and update contracts.

The menu hosts all six recovery entry points, the supplied BMP and independent
console sessions. Installation, SYSTEM replacement and CURRENT/PREVIOUS updates
validate their package and destination before the confirmed write operation.
`zig build view-test` checks rendering geometry; the root `-Mode UITest` checks
the real guest.
