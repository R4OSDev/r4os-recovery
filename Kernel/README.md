# Recovery kernel

This is the independent R4OS Recovery kernel, derived from the source commit
recorded in `../Provenance/inputs.lock.json`. Original unmodified sources and
notices remain available in `../Legal/Sources/Kernel.zip`.

`recovery_main.zig` is the executable entry point. The copied `main.zig` is
reference material from the original kernel and is not compiled as the entry
point. Recovery boots without scanning or requiring a SYSTEM partition. It
retains the existing memory, interrupt, SMP, task and platform mechanisms,
with its own boot ordering and kernel version in `VERSION.R4S`.

Use `../Build.bat -Mode Kernel` or `../Build.sh -Mode Kernel`. The local
starters delegate to this same PowerShell 7 orchestration. The build pins the
local `../Platform/Contract`, uses ReleaseSafe without kernel SIMD, and writes
`../Artifacts/Kernel/bin/recovery.elf` together with the complete
`../Artifacts/Runtime/runtime.img`. Image size and SHA-256 are embedded in the
kernel; a different or incomplete runtime is rejected before mounting C:.

`../Build.sh -Mode BootTest` (or the Windows starter) builds a separate
four-CPU diagnostic variant, then checks BIOS and UEFI boot and regular
poweroff with no SYSTEM partition. `-BootProbe reboot` checks reset instead.
Diagnostic artifacts are separate from the normal kernel output.

Since 0.76.3 the normal kernel mounts the retained Limine FAT32 image as
writable RAM drive C: and starts the existing Terminal with direct keyboard
input. `-Mode RuntimeTest` verifies late module/media reads after physical USB
removal, console children, RAM writes and rejection of invalid images. The
separate `Tools/Test-Boot.ps1 -Action terminal` run checks the regular
interactive build. No Recovery desktop or mouse is started.
See `../DOCUMENTATION.de.txt` for prerequisites and validation scope.
