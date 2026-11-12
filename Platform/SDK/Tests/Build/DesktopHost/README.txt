Desktop-host acceptance consumers (0.86.71)
=========================================

These are genuine C and Rust app roots with the complete import set of
R4DESK0.1.137, including optional native backends. They are not hosted-window
examples. No productive desktop implementation or hardware qualification is
introduced. Manifest versions belong to the fixtures only.

Tools/Test-DesktopHostBuild.ps1 accepts explicit independent SDK, Contract,
Libraries, tools and pinned compiler roots. It copies these fixture sources
into a fresh work directory, resolves only the caller-selected library root,
builds both original manifest projects, keeps the two artifacts and compact
builds.json, then removes successful work copies. C checks do not use assert;
-UNDEBUG remains explicit. Rust's shared BMP is an explicit dependency root.

The toolset's selected-source hashes must match the selected SDK/Contract.
The toolset alone is not a complete SDK. Linux and Windows execution must be
recorded separately; a built Windows PE tool is not Windows execution.

Guest execution is a separate, deliberate test on a private image only:
1. Select one artifact as CONFIG.R4S SHELL. Keep normal boot/services, use
   software graphics and SMP4 on the local QEMU host. Do not start R4DESK.
2. Boot and read C:\TEMP\DH71C.TXT or DH71R.TXT over SSH. READY means actual
   WINSVC host claim, all required local clients, allocation, image and screen
   work succeeded. A refused contender claim does not count.
3. Inject q through QEMU's real keyboard. The bounded input loop must receive
   that codepoint. Result=000 with close=done is written after exact endpoint
   close; root then returns. Check service health and regular shutdown.
4. Run the other language as the next private shell. Restore the exact old
   CONFIG after shutdown. Keep compact facts; remove completed guest copies.

The BMP has exact red/green pixels. Screen text uses the existing boot font;
UTF8 validation does not promise glyph coverage, shaping or display width.
The WindowService binding belongs to the live process generation. Closing a
session endpoint does not falsely claim to unregister that live process.
Existing console/window/service and R4L/R4D/R4P/lowlevel evidence stays with
its original SDK waves. No STANDARD is needed for fixtures/docs/host-only
acceptance without a changed productive runtime or performance path.
