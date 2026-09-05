# Third-Party Notices

Original R4OS material is Apache-2.0. Imported materials retain their original
licenses. `Provenance/inputs.lock.json` records source repositories, commits,
binary versions, manifests and hashes. `Legal/Sources/` contains exact source
archives for the pinned build inputs; each archive preserves its own notices
and third-party license texts. Extracted owner notices are in `Legal/Notices/`.

`Runtime/R4OS/DRIVERS/RTL8168.R4D` contains firmware/register tables extracted
from GPL-2.0-only Realtek vendor material. This binary retains that license;
it is not relicensed under Apache-2.0. See
`Legal/Notices/Drivers-RTL8168/LICENSE-GPL-2.0-only.txt` and the corresponding
complete source archive `Legal/Sources/Drivers-RTL8168.zip`. The pinned SDK,
contract and build sources used with it are supplied in the same source set.

The original Libraries source archive includes its third-party image/font
sources and their licenses; Recovery currently imports only R4STD.R4L from
that owner. The pinned SDK includes NTFS test fixtures, with their recorded
origin and notices. The Distribution archive includes its own bootloader,
font, certificate and other distribution notices. No optional image/font,
audio, browser or desktop runtime module is imported by implication.

The kernel implements the public Limine protocol. Actual bootloader files and
the Recovery background asset will be imported explicitly with their boot/UI
implementation steps and recorded in the input inventory.
