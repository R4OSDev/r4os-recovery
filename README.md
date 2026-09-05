# R4OS Recovery

R4OS Recovery is the independent recovery environment planned for R4OS roadmap
0.76.X. It will boot through Limine with its own lightweight kernel and a
complete RAM-resident console runtime.

The 0.76.1 baseline contains pinned kernel, platform contract and SDK sources,
37 precompiled console, service, driver, protocol and library modules, and
their original source archives and license notices. Since 0.76.2 the separate
Recovery kernel boots under BIOS and UEFI without a SYSTEM partition. The
complete 64-MB FAT32 runtime is loaded by Limine, checked against the paired
kernel hash, and mounted as writable RAM drive C: in 0.76.3. Since 0.76.6,
RECOVERY.R4X hosts the menu and the standard Terminal inside the supplied
background's monitor. Since 0.76.7, DHCP and the frozen SSH/FTP services start
from RAM; independent remote shells and transfers can repair offline volumes.
Both services use the agreed `r4os` / `rosebud` login.

Run `Build.bat` on Windows or `./Build.sh` on Linux with PowerShell 7 to verify
the local inventory. The shared `Build.ps1` checks file hashes, actual binary
imports, protocol dependencies and original manifests. It does not import
from the normal workspace or fetch dependencies. Results are written to
`Artifacts/Verification/inventory.json`.

Add `-Mode Kernel` to build `Artifacts/Kernel/bin/recovery.elf` using the
recorded Zig version and the paired `Artifacts/Runtime/runtime.img`.
`-Mode Runtime` builds that volume and the Recovery-owned console tools.
`-Mode RuntimeTest` checks late
module/media access after removing the USB boot medium, normal console
commands, RAM writes and rejection of invalid boot payloads. After the normal
kernel build, `pwsh -File Tools/Test-Boot.ps1 -Action terminal` exercises the
production menu's Terminal with keyboard input and regular shutdown after
removing the boot medium.
`-Mode NetworkTest` checks SSH/SFTP/SCP, active/passive FTP, offline file
repair, isolated console output, and an offline boot with damaged SYSTEM.
It needs host OpenSSH clients.
Add `-Mode BootTest` for the bounded BIOS/UEFI SMP4
foundation check, or `-Mode BootTest -BootProbe reboot` to verify reset.
Diagnostic kernels and logs remain in `Artifacts/BootProbe/`. The Linux UEFI
check uses the Debian `ovmf` package; Windows uses matching firmware from QEMU.

An explicit initial import uses `Tools/Import.ps1` and the source revisions in
`Provenance/import-plan.json`. Later explicit owner transfers record the
base commit, source patch and content hashes under Provenance and Legal.
Source and configuration changes are recorded
separately with `Tools/Record-Inputs.ps1 -Reason 'description'`; this is never
an automatic build action. See [DOCUMENTATION.de.txt](DOCUMENTATION.de.txt)
and [the technical contracts](RecoveryTools/Contracts.de.txt) for details.

## Planned scope

- Install R4OS from a stored release ZIP or a release downloaded from GitHub.
- Replace a selected R4OS system installation and update Recovery independently.
- Manage partitions through the reusable R4PART console application.
- Run the existing terminal and provide SSH and FTP access for offline repair.
- Use keyboard input and display menus and console programs inside the recovery
  background's monitor area.

The recovery kernel reuses selected R4OS kernel components. Compatible
drivers, protocols, services, console applications, and libraries will be
imported as a pinned, jointly verified set. Recovery has its own release cycle;
normal R4OS releases will include an explicitly selected Recovery release.

## Repository layout

The frozen inputs and their owners are separated explicitly:

    Kernel/             Recovery kernel sources
    Platform/Contract/  Pinned platform API and ABI contract
    Platform/SDK/       Pinned SDK sources
    Platform/Distribution/  Explicitly frozen ImageCreator sources
    RecoveryTools/      Recovery menu and installation/update workflows
    Runtime/            Configuration, imported modules, and recovery media
    Provenance/         Import versions, source commits, hashes, and manifests
    Legal/              Original source archives, manifests and notices
    Tools/              Build, import, and release tooling

Imported runtime binaries will be versioned together with their provenance and
license notices. Generated build and release outputs remain untracked. Shared
host orchestration will use PowerShell 7 with thin Windows and Linux launchers.

## Workspace integration

The canonical checkout is `Repositories/Recovery` within the
[R4OS project workspace](https://github.com/R4OSDev/r4os-project). From the
workspace root, use `Tools\Github.bat -Pull -Recovery` on Windows or
`./Tools/Github.sh -Pull -Recovery` on Linux. The repository uses `main` and the
public remote `https://github.com/R4OSDev/r4os-recovery.git`.

## License

Original R4OS material is licensed under Apache License 2.0. See
[LICENSE](LICENSE), [NOTICE](NOTICE), and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Seit 0.76.4 stehen das physische Medieninventar, die echte Limine-Bootquelle
und stabile C:/R:/weitere Mounts bereit. `-Mode StorageTest` prueft die
USB-/AHCI-/NVMe- und Fehlerfaelle mit SMP4. Die Installationsaktionen folgen
in ihren geplanten Unterversionen. Details und Grenzen stehen in
[DOCUMENTATION.de.txt](DOCUMENTATION.de.txt).

## Keyboard input

`./Build.sh -Mode InputTest` (Windows: `Build.bat -Mode InputTest`) exercises
PS/2 and USB keyboards through BIOS/UEFI Recovery guests with four CPUs.
USB-only cases disable the emulated PS/2 controller. The shared input path
supports R4OS layouts, navigation and the existing Terminal; Recovery does
not bind a mouse. Results live under `Artifacts/BootProbe/input/`.

## Recovery console host

`RecoveryTools/Menu` owns RECOVERY.R4X and builds against the pinned SDK and
Contract. The 38 imported binaries stay fixed; the runtime image additionally
contains the locally built Recovery application. Its manifest and source
participate in input verification, and the build checks its real imports.

The six English menu entries use Up/Down and Enter. Terminal starts the
unchanged TERMINAL.R4X in a separate console session; EXIT restores the menu.
Image scaling, text, cursor, scrolling and clear are confined to the source
image's monitor. The shell uses existing R4DRAW and console-host APIs without
a desktop. The footer shows the actual SSH address or network waiting state.
The first three entries select a fixed cached ZIP or their GitHub channel,
then a live disk or an identified SYSTEM/RECOVERY partition. Review defaults
to Back and revalidates the target before dispatch. Package processing and
writes follow in their respective roadmap steps; no placeholder claims a
completed installation. Readable OS markers add comma-separated names; no
marker leaves the extra display empty. Details and current limits are in
[DOCUMENTATION.de.txt](DOCUMENTATION.de.txt).

`-Mode UITest` exercises BIOS at 640x480, 800x600, 1024x768 and 1920x1080 plus UEFI at
1024x768, with four CPUs and a USB keyboard. Its `/UISMOKE` diagnostic session
uses the existing shell stdout mirror and a second standard Terminal to
check console isolation. QMP screendumps compare every pixel outside the
monitor, and verify visible selection, dialogs, progress, clear, scrolling,
Terminal return and reset. The disk fixtures cover an existing installation,
a blank disk and combined OS markers. `Tools/Test-UI.ps1 -BootMedium LOCAL
-Firmware Bios -Resolution 1024x768x32` checks local-source USB exclusion and
own-disk eligibility. Artifacts stay under `Artifacts/BootProbe/ui/`.

Since 0.76.9, the pinned SDK and ImageCreator share GPT/MBR editing and streamed
FAT32/NTFS formatting. `-Mode StorageToolsTest` exercises those same routines
through real guest claims on a disposable 128-MB NVMe disk, then mounts both
filesystems and checks file access. The existing network runner provides
BIOS/UEFI SMP4 and menu/remote-access coverage in the same sessions.

Since 0.76.10, Manage Partitions starts the frozen R4PART.R4X directly.
The same console application is installed in the normal R4OS Terminal path.
It provides real disk/partition/volume inventory, selection, GPT/MBR creation
and editing, FAT32/NTFS Quick/Full formatting, drive letters and mount state.
Writes require an explicit confirmation naming the target disk/partition.
R4PART imports the console portion of R4DESK as well as physical R4SYS storage.
Neither a desktop nor GUI applications are required.

`-Mode R4PartTest` extends the existing network acceptance with real R4PART
operations on a disposable NVMe, identifier changes and the menu/Terminal
return paths. `pwsh -File Tools/Test-R4Part-Normal.ps1` exercises that identical
binary in an already built normal Full image, then verifies the ordinary
local Terminal in a private QEMU snapshot. Both run with four virtual CPUs.
