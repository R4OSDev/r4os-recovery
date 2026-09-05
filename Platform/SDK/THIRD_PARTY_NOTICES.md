# Third-Party Notices

## NTFS test fixtures

`Tests/Fixture/Ntfs` contains R4OS test data generated on Microsoft Windows
with DiskPart and the Windows NTFS formatter. The fixture archive contains disk
and filesystem test data, not Microsoft executable or source code. The
generation environment and hashes are recorded in
`Tests/Fixture/Ntfs/NtfsFixtureManifest.json`; the captured command log
retains Microsoft's displayed copyright notice.

R4OS dependencies referenced by build metadata remain separate R4OS projects.

## NTFS formatter metadata

`r4os/storage_tools/ntfs_metadata` contains byte-identical copies of the 16
volume-independent `.bin` templates previously used by the Distribution
ImageCreator and `Tests/Fixture/Ntfs/Meta0605`. These are the same Windows-
generated filesystem data described above. `provenance.json` records every
source path, size, SHA-256 and the original fixture manifest hash. The
original fixture, generation log and notices remain in place. The shared
formatter implementation is R4OS source moved from Distribution, not Microsoft
formatter code.

## Limine BIOS boot support

`r4os/storage_tools/limine.zig` adapts the GPT BIOS installation sequence
from Limine 12.0.1. The adjacent `limine/` directory retains the exact
`limine.c`, `limine-bios-hdd.h`, BSD-2-Clause `LICENSE`, and the unchanged
boot payload extracted from that header. `provenance.json` records all
sizes, SHA-256 hashes and the extraction method. Upstream is
[limine-bootloader/limine](https://github.com/limine-bootloader/limine).

Copyright (C) 2019-2026 Mintsuki and contributors. R4OS does not relicense
these files; redistributors must retain the supplied BSD-2-Clause notice.
The R4OS adapter adds bounded device access, explicit exclusive ownership,
and stage-2 flush/readback before publishing the stage-1 boot sector.
