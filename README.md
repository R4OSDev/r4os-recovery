# R4OS Recovery

R4OS Recovery is the independent recovery environment planned for R4OS roadmap
0.76.X. It will boot through Limine with its own lightweight kernel and a
complete RAM-resident console runtime.

The 0.76.1 baseline contains pinned kernel, platform contract and SDK sources,
37 precompiled console, service, driver, protocol and library modules, and
their original source archives and license notices. Since 0.76.2 the separate
Recovery kernel boots under BIOS and UEFI without a SYSTEM partition. The
complete RAM filesystem and console runtime follow in 0.76.3.

Run `Build.bat` on Windows or `./Build.sh` on Linux with PowerShell 7 to verify
the local inventory. The shared `Build.ps1` checks file hashes, actual binary
imports, protocol dependencies and original manifests. It does not import
from the normal workspace or fetch dependencies. Results are written to
`Artifacts/Verification/inventory.json`.

Add `-Mode Kernel` to build `Artifacts/Kernel/bin/recovery.elf` using the
recorded Zig version. Add `-Mode BootTest` for the bounded BIOS/UEFI SMP4
foundation check, or `-Mode BootTest -BootProbe reboot` to verify reset.
Diagnostic kernels and logs remain in `Artifacts/BootProbe/`. The Linux UEFI
check uses the Debian `ovmf` package; Windows uses matching firmware from QEMU.

An explicit initial import uses `Tools/Import.ps1` and the source revisions in
`Provenance/import-plan.json`. Source and configuration changes are recorded
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
