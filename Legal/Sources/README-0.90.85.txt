R4OS Recovery generation2 corresponding sources (0.90.85)

RecoveryTools/Embedded contains38 Recovery-owned derivatives. They preserve
original notices/licenses, including GPL-2.0-only RTL8168 firmware material.
Recovery-Embedded-0.90.85.zip supplies their actual current build inputs,
Menu28, source plan and builder scripts, from Recovery commit 97f7ccd69a4c074b5f149fec897669449560e2c5.
The independent R4STD0.2.9 source is in Libraries-0.90.85.zip (Libraries58).
Contract-0.90.84.zip (Contract93) and SDK-0.90.84.zip (SDK210) supply the exact
canonical compiled platform sources. SDK-Controller-0.90.85.zip supplies the
shared source/profile controller212. Original historical archives/notices
remain included; their old code is not the rebuilt runtime implementation.

The full Recovery checkout contains the input lock, sources, runtime39,
Kernel and Build.ps1. With PowerShell7 and the selected Zig toolchain,
./Build.sh -Mode Embedded rebuilds all39 and compares them byte for byte
against Runtime. Windows uses Build.bat with the same PowerShell logic.
Tools/Embedded.ps1 invokes the shared SDK controller and creates an SDK policy
overlay under Artifacts/SDKProfile; pinned canonical source is never edited.
Profiles/Components.json of the controller selects the exact canonical roots.
The published source repository includes all these files and original legal
materials. There is no dependency on a precompiled original runtime module
for compiling its replacement. Tests have separate native/hardware scope.
