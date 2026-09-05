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
`../Artifacts/Kernel/bin/recovery.elf`. It never emits the normal `r4os.elf`.

`../Build.sh -Mode BootTest` (or the Windows starter) builds a separate
four-CPU diagnostic variant, then checks BIOS and UEFI boot and regular
poweroff with no SYSTEM partition. `-BootProbe reboot` checks reset instead.
Diagnostic artifacts are separate from the normal kernel output.

At 0.76.2 the normal kernel has a temporary foundation console with R to
restart and P to power off. The complete RAM filesystem and existing R4OS
Terminal are connected in 0.76.3. No Recovery desktop or mouse is started.
See `../DOCUMENTATION.de.txt` for prerequisites and validation scope.
