# Third-Party Notices

This repository vendors the following external material. The named upstream
license applies to that material; Apache License 2.0 applies only to original
R4OS material.

| Unit | Component | Version | License | Local license/provenance |
| --- | --- | --- | --- | --- |
| R4IMG | stb_image | 2.30 | MIT (selected from the upstream MIT/public-domain dual offer) | `R4IMG/ThirdParty/stb/LICENSE-MIT` and `R4IMG/ThirdParty/stb/stb_image.h` |
| R4IMG tests | Web Platform Tests image fixtures | commit 4a5810a124fa0523dd2494996bf1542d4b67f394 | BSD-3-Clause | `R4IMG/Tests/Decoder/Fixtures/LICENSE-WPT-BSD-3-Clause.txt` |
| R4FONT | FreeType | 2.14.3 | FreeType License 1.0 | `R4FONT/ThirdParty/r4font/freetype/FTL.TXT` |
| R4FONT | Google Brotli | 1.2.0 | MIT | `R4FONT/ThirdParty/r4font/brotli/LICENSE` |
| R4FONT | zlib | 1.3.1 | zlib License | `R4FONT/ThirdParty/r4font/ZLIB-LICENSE` |

Exact upstream commits, included paths, local patches, hashes, and verification
commands are recorded in
`R4FONT/ThirdParty/r4font/UPSTREAM.json` and
`R4FONT/ThirdParty/r4font/VENDOR.sha256`.

## Test fixtures

Some R4FONT test fonts originate from Web Platform Tests under BSD-3-Clause or
from Philip Taylor under MIT. R4IMG also contains four byte-for-byte WPT image
fixtures under BSD-3-Clause. Per-file paths, hashes, transformations, and
notices are recorded in `R4FONT/Tests/Fixtures/FIXTURES.json` and
`R4IMG/Tests/Decoder/Fixtures/FIXTURES.json` with their adjacent license
files. Other listed fixtures are original or generated R4OS material.
