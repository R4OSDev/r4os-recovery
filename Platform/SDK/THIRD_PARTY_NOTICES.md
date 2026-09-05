# Third-Party Notices

## NTFS test fixtures

`Tests/Fixture/Ntfs` contains R4OS test data generated on Microsoft Windows
with DiskPart and the Windows NTFS formatter. The fixture archive contains disk
and filesystem test data, not Microsoft executable or source code. The
generation environment and hashes are recorded in
`Tests/Fixture/Ntfs/NtfsFixtureManifest.json`; the captured command log
retains Microsoft's displayed copyright notice.

No other third-party redistributable material has been identified in this
repository. R4OS dependencies referenced by build metadata remain separate
R4OS projects.

## NTFS formatter metadata

`r4os/storage_tools/ntfs_metadata` contains byte-identical copies of the 16
volume-independent `.bin` templates previously used by the Distribution
ImageCreator and `Tests/Fixture/Ntfs/Meta0605`. These are the same Windows-
generated filesystem data described above. `provenance.json` records every
source path, size, SHA-256 and the original fixture manifest hash. The
original fixture, generation log and notices remain in place. The shared
formatter implementation is R4OS source moved from Distribution, not Microsoft
formatter code.
