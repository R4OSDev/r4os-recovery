Decoder Fixtures
================

Four PNG and JPEG fixtures are byte-for-byte copies from Web Platform Tests
commit 4a5810a124fa0523dd2494996bf1542d4b67f394. Their exact upstream paths,
hashes, and BSD-3-Clause notice are recorded in FIXTURES.json and
LICENSE-WPT-BSD-3-Clause.txt.

The files provide small deterministic positive cases for RGBA PNG,
transparent PNG, baseline JPEG, and progressive JPEG. Tests generate the BMP
fixture deterministically at runtime.

basic.svg is an original R4OS SVG 2 conformance fixture covering viewBox,
basic shapes, paths, use, transforms, clipping, color, transparency, and a
synthetic link hit bound to the HTML DOM.
