R4FONT.R4L
==========

R4FONT is an independent Runtime-R4L for validated font sources. It exports
the versioned API_V1:1 table and owns its implementation, contract, baseline,
Zig/C/Rust contract bindings, FreeType, Brotli, and zlib integration. Higher
Rust/C consumers use Libraries/Shared/Rust and Bindings/C/r4font_helpers.h;
see Libraries/Shared/Rust/README.md for decoder/source/allocator loans and
original cache/import lifetime rules. The core SDK does
not contain R4FONT types or decoder sources.

Supported inputs include TTF, OpenType/CFF, WOFF, WOFF2, and SFNT collections
with CMAP, metrics, kerning, and deterministic Alpha8 rasterization. Source
data, decoder state, raster buffers, and reconstruction allocations belong to
the calling process.

Consumers declare IMPORT=R4FONT:API_V1:1 and bind
Bindings/Zig/r4font.zig or Bindings/C/r4font.h. Docs/API.md is generated from
the contract.

Build and test:

    Build.bat R4FONT test
    ./Build.sh R4FONT test

The optional host profile compares the same 32-pixel glyph-raster workload
under both manifest optimization modes. It is not part of the normal test
gate:

    Build.bat R4FONT profile -Dhost-test-optimize=ReleaseSmall
    Build.bat R4FONT profile -Dhost-test-optimize=ReleaseFast
    ./Build.sh R4FONT profile -Dhost-test-optimize=ReleaseSmall
    ./Build.sh R4FONT profile -Dhost-test-optimize=ReleaseFast

Verify vendored sources and generated fixtures:

    python R4FONT/ThirdParty/r4font/Tools/verify_vendor.py --check
    python R4FONT/Tests/Tools/generate_minimal_fonts.py --check


Input bounds and ownership (0.78.65)
-----------------------------------
R4FONT 0.2.2 reads the WOFF/WOFF2 size field only with at least 20 input bytes.
The FNT import helper transfers each bitmap to its owning list exactly once;
a later RasterGlyph allocation failure no longer frees it twice. FON/NE
header and resource offsets use checked, input-bounded arithmetic, including
resource alignment shifts. FONTS 0.1.4 embeds the corrected import helper.
No decoder API, interface layout or upstream library version changes.
The existing vendor byte manifest records the corrected local bridge.
Focused checks reuse the small R4F/FNT/FON/WOFF examples; no raster profiles
or long font runs are added.

Legacy helper text semantics (0.85.40)
------------------------------------
font_tools is a static consumer helper; it does not change API_V1 or the
R4FONT.R4L implementation. Consumers supply the r4std_legacy_tables and
r4std_console_text modules from the same Libraries package. The exact R4STD
mapping tables are reused, with no new independently maintained codepage.
FNT ANSI=0 uses Windows-1252; OEM=255 explicitly uses R4OS's US CP437 policy.
Windows OEM is locale dependent: a foreign OEM font is not proved CP437 by
its header alone. DEFAULT=1, SYMBOL and other charsets are rejected until a
real codec/policy exists. Undefined 1252 slots are omitted, never relabeled.
GMAP codepoints are Unicode scalars; new records use CHARSET_UNICODE. FACE
flags retain source repertoire plus UNICODE. OEM control-picture glyphs use
their separate Unicode graphic scalars; text C0 controls are not redefined.
Preview samples are strict UTF-8; bad text/charset leaves pixels unchanged.
Distribution's font-test directly runs the owner helper cases and an authored
two-resource NE/FON fixture. The optional -Dlegacy-font-fixtures directory
also runs six local research FON sources; these are not distributed. A missing
optional directory skips only that research case. Old ambiguous raw-byte
imports require reimporting.
