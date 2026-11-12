R4FONT Third-Party Foundation
=============================

R4FONT uses three pinned upstream components. UPSTREAM.json is the
machine-readable source, version, license, patch, and verification record.

FreeType
--------

- Version: 2.14.3
- Canonical upstream: https://gitlab.freedesktop.org/freetype/freetype.git
- Mirror: https://github.com/freetype/freetype.git
- Tag: VER-2-14-3
- Tag object: c740f0fda4274d6ffd2e5b64a25b06ef69803a07
- Resolved commit: 0a0221a1347e2f1e07c395263540026e9a0aa7c7
- License choice: FreeType License 1.0
- License files: freetype/LICENSE.TXT, freetype/FTL.TXT, freetype/GPLv2.TXT

The vendored tree is limited to paths listed in UPSTREAM.json. The sole R4OS
patch is Patches/freetype-2.14.3-r4font.patch. Its upstream and patched hashes
are pinned, and it is applied with line-ending conversion disabled.

Brotli
------

- Version: 1.2.0
- Upstream: https://github.com/google/brotli
- Tag: v1.2.0
- Commit: 028fb5a23661f123017c060daa546b55cf4bde29
- License: MIT
- License file: brotli/LICENSE

Only the bounded WOFF2 decoder is compiled.

zlib
----

- Version: 1.3.1, from the pinned FreeType snapshot
- Upstream: https://github.com/madler/zlib.git
- Tag: v1.3.1
- Tag object: 925af44f3cde53c6b076611c297850091b5dc7bb
- Resolved commit: 51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf
- License: zlib License
- License file: ZLIB-LICENSE

FreeType's ftgzip.c includes the six zlib source files listed in
UPSTREAM.json and routes their allocations through caller-owned FT_Memory.

Source and freestanding contract
--------------------------------

R4FONT/module.R4MF is the single productive source list. Host tests use the
same decoder sources. Consumers import only R4FONT:API_V1:1 and do not depend
on the vendored implementation.

Production builds are freestanding and do not link host libc. The
freestanding directory provides narrow headers, while the R4OS bridge sources
provide the required memory, string, sorting, abort, and system-memory hooks.

R4OS configuration disables file streams, environment properties, embedded
TrueType bytecode, and unused formats. The WOFF2 integration uses caller-owned
memory, requires complete input and output consumption, and limits rebuilt
SFNT data to 32 MB.

Reproducible verification
-------------------------

VENDOR.sha256 pins all vendored, configuration, bridge, freestanding, and
patch files. The verification also checks license hashes and reverses the
local FreeType patch to recover the pinned upstream hash:

    python R4FONT/ThirdParty/r4font/Tools/verify_vendor.py --check

Use --write only for an explicit reviewed vendor baseline change, followed by
intentional manifest, script, and patch hash updates.

Retrieved and verified for R4OS: 2026-08-08
