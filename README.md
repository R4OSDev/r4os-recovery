# R4OS Recovery

R4OS Recovery is the independent recovery environment developed in R4OS roadmap
0.76.X. It boots through Limine with its own lightweight kernel and a
complete RAM-resident console runtime.

The current baseline contains pinned kernel, platform contract and SDK sources,
39 precompiled console, service, driver, protocol and library modules, and
their original source archives and license notices. Since 0.76.2 the separate
Recovery kernel boots under BIOS and UEFI without a SYSTEM partition. The
complete 64-MB FAT32 runtime is loaded by Limine, checked against its kernel's
recorded runtime hash, and mounted as writable RAM drive C: in 0.76.3. Since 0.76.6,
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

## Recovery tools

- Install R4OS from a stored release ZIP or a release downloaded from GitHub.
- Replace a selected R4OS system installation and update Recovery independently.
- Manage partitions through the reusable R4PART console application.
- Run the existing terminal and provide SSH and FTP access for offline repair.
- Use keyboard input and display menus and console programs inside the recovery
  background's monitor area.

Update Recovery preserves a verified PREVIOUS package before replacing CURRENT.
Only a confirmation matching the installation, manifest and actually booted
kernel/runtime can promote CURRENT to PREVIOUS. The running session stays in
RAM. A failed update can be recovered through the fixed Previous entry in
Limine; shared filesystem or bootloader damage still needs an external USB.
The original ZIP cache and existing Limine configuration remain intact.

The recovery kernel reuses selected R4OS kernel components. Compatible
drivers, protocols, services, console applications, and libraries are
imported as a pinned, jointly verified set. Recovery has its own release cycle;
normal R4OS packages include an explicitly selected complete Recovery release.

`./Release.sh Prepare` (Windows: `Release.bat Prepare`) creates the independent
ZIP, input/owner provenance and SHA256SUMS from the clean, pushed Recovery
source. `Publish` uploads through the shared workspace GitHub transport;
it does not build normal R4OS. The production kernel's named pair section must
match the exact runtime and both versions. Use `Prepare -Technical` only for
explicit local acceptance candidates; `Publish` refuses technical mode.
`SelfTest` checks the local producer/pair contract without a network upload.

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

Imported runtime binaries are versioned together with their provenance and
license notices. Generated build and release outputs remain untracked. Shared
host orchestration uses PowerShell 7 with thin Windows and Linux launchers.

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
USB-/AHCI-/NVMe- und Fehlerfaelle mit SMP4. Installation und beide Updatewege
sind implementiert. Details und Grenzen stehen in
[DOCUMENTATION.de.txt](DOCUMENTATION.de.txt).

## Keyboard input

`./Build.sh -Mode InputTest` (Windows: `Build.bat -Mode InputTest`) exercises
PS/2 and USB keyboards through BIOS/UEFI Recovery guests with four CPUs.
USB-only cases disable the emulated PS/2 controller. The shared input path
supports R4OS layouts, navigation and the existing Terminal; Recovery does
not bind a mouse. Results live under `Artifacts/BootProbe/input/`.

## Recovery console host

`RecoveryTools/Menu` owns RECOVERY.R4X and builds against the pinned SDK and
Contract. The 39 imported binaries stay fixed; the runtime image additionally
contains the locally built Recovery application. Its manifest and source
participate in input verification, and the build checks its real imports.

The six English menu entries use Up/Down and Enter. Terminal starts the
unchanged TERMINAL.R4X in a separate console session; EXIT restores the menu.
Image scaling, text, cursor, scrolling and clear are confined to the source
image's monitor. The shell uses existing R4DRAW and console-host APIs without
a desktop. The footer shows the actual SSH address or network waiting state.
The first three entries select a fixed cached ZIP or their GitHub channel,
then a live disk or an identified SYSTEM/RECOVERY partition. Review defaults
to Back and revalidates the target before dispatch. Since 0.76.15, local
packages are checked through the frozen R4ZIP protocol and prepared in pinned
physical RAM. Install R4OS and Update R4OS execute their validated write plans;
Update Recovery rotates confirmed CURRENT to PREVIOUS before replacement.
Readable OS markers add comma-separated names; no
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

`Tools/Package.ps1` owns the independent Recovery ZIP producer; the frozen
Distribution `Tools/ReleasePackage.ps1` supplies self-contained test fixtures.
The canonical Distribution owns the current production OS package.
`./Build.sh -Mode PackageTest` (Windows: `Build.bat -Mode PackageTest`)
builds the production package kernel and existing UI diagnostic kernel, then
generates real .NET ZIP fixtures, checks
the shared guest decoder and NTFS content import on the host, and runs bounded
SMP4 guest package checks. After those builds,
`pwsh -File Tools/Test-Packages.ps1 -HostOnly` or `-GuestOnly` selects one half.
Physical installation has its separate complete-package acceptance. Public
channel checks additionally verify the actual released assets.

`./Build.sh -Mode DownloadTest` uses the production Recovery kernel and the
same guest web transport. It checks a real GitHub HTTPS/redirect download,
controlled complete and invalid packages, separate fixed caches, available
space, actual power cuts at three durable cache boundaries and representative
FAT32 alias/orphan-LFN states. Only disposable images under Artifacts are
written; an extra installation disk must remain byte-identical. Logs and
hashes live under `Artifacts/BootProbe/downloads/`. `Tools/Test-Downloads.ps1`
can select `-LiveOnly` or `-NoCuts`; `-ReuseFixture` requires matching recorded
input and fixture hashes. The complete production release channels are
checked after publication in the release integration step.

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

Since 0.76.18, Install R4OS performs the complete replacement after the
existing source, target and confirmation steps. It validates the original
release ZIP and the agreement between its outer BOOT files, inner image,
SYSTEM catalog and pinned Recovery. Every write plan and the original ZIP
reside in pinned RAM before exclusive access. The common SDK creates fresh
GPT identities, BOOT/SYSTEM/RECOVERY and DATA using the actual target size.
Both Recovery slots and INSTALL/RELEASE.ZIP are installed. Completion requires
flush/readback, new mount identities and a full hash of the stored original.

Build the production kernel with `-Mode Kernel` and its diagnostic UI sibling
with `-Mode Kernel -BootProbe ui`. `Tools/Test-Install.ps1 -SourcePackage PATH`
uses that real installer with a validated complete R4OS package on disposable
SMP4 QEMU media. It covers USB installation, own-device local replacement,
write failure and low RAM, then independently checks and boots successful
results. `-ReuseFixture` requires matching hashes; `-VerifyInstalled` only
rechecks already recorded results and boots them through snapshots.

Since 0.76.19, Update R4OS rebuilds the selected SYSTEM in its existing
partition and updates the matching normal kernel/preload/BOOT files from
the same validated release ZIP. Capacity includes NTFS metadata; a fitting
nonstandard SYSTEM size is retained. All old SYSTEM files and settings are
replaced. DATA, RECOVERY, GPT identities and partition boundaries persist.

BOOT is updated at file level. Its existing limine.conf bytes, foreign files,
names and attributes are retained. Preparation requires canonical R4OS
kernel/preload references in the existing configuration and the supported
Limine BIOS chain. A private FAT plan checks allocation ownership and space
before either write claim. BOOT and SYSTEM have separate exclusive claims;
the table and original BOOT fingerprint are checked again before writing.
Failure after writes is reported as incomplete, with affected claims closed
and unfinished filesystems kept offline. This recovery operation has no
transaction rollback or power-failure guarantee.

`Tools/Test-SystemUpdate.ps1 -SourcePackage PATH -BaseImage PATH` exercises
the menu on disposable USB/NVMe SMP4 guests. The fixture uses a standard old
2048-MB image and creates 768-MB and too-small SYSTEM variants. Independent
checks compare persistent partitions, GPT, custom menu bytes and foreign
BOOT files; a read-only NTFS witness checks the complete replacement tree.
The successfully updated normal system must boot and respond to Terminal.


## Qualified requirements and integration

Recovery/Kernel 0.1.19 and RECOVERY.R4X 0.1.11 use a complete 64-MB RAM image.
Install/update packages require at least 7 GB of OS-usable RAM, counted from
the boot memory map without MMIO holes; machines with 8 GB are qualified.
The complete source and write plans must fit in physically reserved RAM
before any target write. The shared minimum disk is 1,763,722,240 bytes;
BOOT/SYSTEM/RECOVERY retain 128/1024/512 MB and DATA uses the remaining space.

`Artifacts/Qualification/0.76.23/report.json` records actual RAM peaks,
capacity, complete install/update evidence and exact package identities.
`Artifacts/Qualification/0.76.24/report.json` adds combined BIOS/UEFI,
USB/local keyboard UI, remote repair/storage/R4PART, local self-update,
download power cuts and normal boot integration. All automated guests use
four CPUs and run sequentially. SeaBIOS 1.17's high-RAM NVMe boot limitation
is handled by the shared host firmware PCI allocation setting; no kernel
change is needed. Historical single failures remain documented separately.

After publication, `Tools/Test-PublishedRelease.ps1` downloads the entire
actual public Recovery or R4OS asset through the production keyboard menu,
verifies its cached bytes and preserves unrelated partitions. The only user
hardware acceptance remains the final Lenovo USB boot and local installation.


Recovery [0.1.19](https://github.com/R4OSDev/r4os-recovery/releases/tag/v0.1.19)
is published with its source receipt and checksums. The full public asset
passed the production-menu download acceptance; its unpacked contents match
the qualified kernel/runtime/license payloads exactly. Normal Distribution
pins the release ID and complete ZIP SHA256 explicitly.
