#![no_std]
extern crate alloc;
use alloc::vec;
use core::fmt::Write;
use r4os_library_helpers::{
    Heap,
    font::{self, Fonts},
    image::{Images, Png},
    standard::{Codepage, Graphemes, Mode, Standard},
};
use r4os_sdk::App;
#[path = "../../fixtures.rs"]
mod fixtures;
struct Output<'a, 'b>(&'a App<'b>);
impl core::fmt::Write for Output<'_, '_> {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        if self.0.write(s) < 0 {
            Err(core::fmt::Error)
        } else {
            Ok(())
        }
    }
}
unsafe extern "C" {
    fn r4libraries59_guest(
        start: *const r4os_sdk::abi::R4XStartContext,
        png: *const u8,
        png_length: usize,
        font: *const u8,
        font_length: usize,
    ) -> i32;
}
fn main(app: &mut App<'_>) -> i32 {
    let before = app.heap().unwrap().stats().unwrap();
    if let Err((step, error)) = exercise(app) {
        let _ = writeln!(
            &mut Output(app),
            "FAIL LIBHELP59 step={} error={:?}",
            step,
            error
        );
        return step;
    }
    let after = app.heap().unwrap().stats().unwrap();
    if before.get(c"active_allocations") != after.get(c"active_allocations")
        || before.get(c"active_bytes") != after.get(c"active_bytes")
    {
        let _ = writeln!(
            &mut Output(app),
            "FAIL LIBHELP59 live heap allocations/bytes {:?}/{:?} -> {:?}/{:?}",
            before.get(c"active_allocations"),
            before.get(c"active_bytes"),
            after.get(c"active_allocations"),
            after.get(c"active_bytes")
        );
        return 90;
    }
    app.write("PASS LIBHELP59 Rust/C real text/settings/date/time/config/codec, PNG/SVG/PNG16, font raster/import and exact allocation release\n");
    0
}
fn exercise(app: &App<'_>) -> Result<(), (i32, r4os_library_helpers::Error)> {
    use r4os_library_helpers::Error;
    let bad = Error::InvalidProvider;
    let standard = Standard::open(app).map_err(|e| (1, e))?;
    if standard
        .utf8("Aü".as_bytes())
        .map_err(|e| (2, e))?
        .scalar_count()
        .map_err(|e| (3, e))?
        != 2
    {
        return Err((4, bad));
    }
    if standard.utf8(&[0xff]).is_ok() {
        return Err((5, bad));
    }
    let mut canonical = [0u8; 32];
    if standard
        .canonicalize(b"A\nB\r\n", &mut canonical)
        .map_err(|e| (6, e))?
        .as_bytes()
        != b"\xef\xbb\xbfA\r\nB\r\n"
    {
        return Err((7, bad));
    }
    let bytes = b"R4S_FORMAT=1\r\nSCHEMA=TEST\r\nCOUNT=42\r\nON=true\r\n";
    let document = standard.settings(bytes).map_err(|e| (8, e))?;
    if document.u32_value(b"COUNT").map_err(|e| (9, e))? != Some(42) {
        return Err((10, bad));
    }
    if standard.entries(bytes).map_err(|e| (11, e))?.count() != 4 {
        return Err((12, bad));
    }
    let mut written = [0u8; 128];
    let mut writer = standard.writer(&mut written).map_err(|e| (13, e))?;
    writer.header(b"TEST").map_err(|e| (14, e))?;
    writer.u32_pair(b"COUNT", 42).map_err(|e| (15, e))?;
    if !writer.is_ok().map_err(|e| (16, e))?
        || standard
            .settings(writer.bytes().map_err(|e| (17, e))?)
            .map_err(|e| (18, e))?
            .u32_value(b"COUNT")
            .map_err(|e| (19, e))?
            != Some(42)
    {
        return Err((20, bad));
    }
    let mut tiny = [0u8; 2];
    let mut writer = standard.writer(&mut tiny).map_err(|e| (21, e))?;
    writer.header(b"TEST").map_err(|e| (22, e))?;
    if writer.is_ok().map_err(|e| (23, e))? {
        return Err((24, bad));
    }
    if Graphemes::new("A\u{308}B".as_bytes())
        .map_err(|e| (25, e))?
        .count()
        != 2
    {
        return Err((26, bad));
    }
    let codec = standard.codec();
    if codec
        .decode_legacy(Codepage::Cp437, Mode::PcGraphics, 0xc4)
        .map_err(|e| (27, e))?
        != '─'
    {
        return Err((28, bad));
    }
    let mut converted = [0u8; 8];
    if codec
        .legacy_to_utf8(
            Codepage::Windows1252,
            Mode::Controls,
            &[0x80],
            &mut converted,
        )
        .map_err(|e| (29, e))?
        != "€"
    {
        return Err((30, bad));
    }
    let mut stream = codec.stream().map_err(|e| (31, e))?;
    if stream.push(0xc3).map_err(|e| (32, e))?.is_some()
        || stream.push(0xbc).map_err(|e| (33, e))? != Some('ü')
        || !stream.finish().map_err(|e| (34, e))?
    {
        return Err((35, bad));
    }
    if standard.date_days(2024, 2).map_err(|e| (36, e))? != 29 {
        return Err((37, bad));
    }
    let date = standard
        .parse_date_time("2026-10-22 12:34:56")
        .map_err(|e| (38, e))?
        .ok_or((39, bad))?;
    let mut date_out = [0u8; 32];
    if standard
        .format_date_time(date, &mut date_out)
        .map_err(|e| (40, e))?
        != "2026-10-22 12:34:56"
    {
        return Err((41, bad));
    }
    let mut zone = [0u8; 32];
    if standard.zone_count().map_err(|e| (42, e))? == 0
        || standard
            .zone_id(0, &mut zone)
            .map_err(|e| (43, e))?
            .is_empty()
    {
        return Err((44, bad));
    }
    if standard
        .config_write_u32(c"C:\\TEMP\\LIBH59.R4S", b"COUNT", 59)
        .map_err(|e| (45, e))?
        < 0
    {
        return Err((46, bad));
    }
    let (status, value) = standard
        .config_read_u32(c"C:\\TEMP\\LIBH59.R4S", b"COUNT", 0)
        .map_err(|e| (47, e))?;
    if status < 0 || value != 59 {
        return Err((48, bad));
    }
    let images = Images::open(app).map_err(|e| (49, e))?;
    let info = images
        .probe(fixtures::PNG, "image/png")
        .map_err(|e| (50, e))?;
    if info.width != 10 || info.pixel_count().map_err(|e| (51, e))? != 100 {
        return Err((52, bad));
    }
    let mut scratch = vec![
        0;
        images
            .scratch_bytes(info, fixtures::PNG.len())
            .map_err(|e| (53, e))?
    ];
    let mut pixels = [0u32; 100];
    let image = images
        .decode(fixtures::PNG, "image/png", &mut pixels, &mut scratch)
        .map_err(|e| (54, e))?;
    if image.pixels[0] != 0xff0000ff {
        return Err((55, bad));
    }
    let mut scaled = [0u32; 4];
    images
        .scale_composite(&image, &mut scaled, 2, 2, 0)
        .map_err(|e| (56, e))?;
    if images
        .decode(fixtures::PNG, "image/png", &mut [0; 99], &mut scratch)
        .is_ok()
    {
        return Err((57, bad));
    }
    let png = Png::open(app).map_err(|e| (58, e))?;
    let mut precise_scratch = vec![
        0;
        png.scratch_bytes(info, fixtures::PNG.len())
            .map_err(|e| (59, e))?
    ];
    let mut rgba = [0u16; 400];
    let precise = png
        .decode(fixtures::PNG, &mut rgba, &mut precise_scratch)
        .map_err(|e| (60, e))?;
    if precise.rgba[..4] != [0, 0, 65535, 65535] {
        return Err((61, bad));
    }
    let svg = b"<svg width=\"2\" height=\"2\"><rect width=\"2\" height=\"2\" fill=\"red\"/></svg>";
    let svg_info = images.probe(svg, "image/svg+xml").map_err(|e| (62, e))?;
    let mut svg_scratch = vec![
        0;
        images
            .scratch_bytes(svg_info, svg.len())
            .map_err(|e| (62, e))?
    ];
    let mut svg_pixels = [0u32; 4];
    images
        .decode_svg(svg, &mut svg_pixels, &mut svg_scratch, 2, 2)
        .map_err(|e| (62, e))?;
    let heap = Heap::new().map_err(|e| (63, e))?;
    let fonts = Fonts::open(app).map_err(|e| (64, e))?;
    let mut decoder = fonts.decoder(&heap, 8 * 1024 * 1024).map_err(|e| (65, e))?;
    let initial = decoder.allocated_bytes().map_err(|e| (66, e))?;
    {
        let face = decoder.open_face(fixtures::FONT, 0).map_err(|e| (67, e))?;
        if face.info().map_err(|e| (68, e))?.family != b"CanvasTest" {
            return Err((69, bad));
        }
        let glyph = face.glyph_index('A').map_err(|e| (70, e))?;
        let mut alpha = [0u8; 4096];
        if face
            .rasterize(glyph, 32, &mut alpha)
            .map_err(|e| (71, e))?
            .alpha
            .is_empty()
        {
            return Err((72, bad));
        }
        face.kerning(glyph, glyph).map_err(|e| (73, e))?;
    }
    if decoder.allocated_bytes().map_err(|e| (74, e))? != initial {
        return Err((75, bad));
    }
    if decoder.open_face(b"invalid", 0).is_ok() {
        return Err((76, bad));
    }
    let source = fixtures::fnt();
    let imported = font::import(&heap, &source, b"tiny.fnt", 0).map_err(|e| (77, e))?;
    if &imported.bytes()[..4] != b"R4F1" {
        return Err((78, bad));
    }
    drop(imported);
    let code = unsafe {
        r4libraries59_guest(
            app.start_context(),
            fixtures::PNG.as_ptr(),
            fixtures::PNG.len(),
            fixtures::FONT.as_ptr(),
            fixtures::FONT.len(),
        )
    };
    if code != 0 {
        return Err((100 + code, bad));
    }
    Ok(())
}
r4os_sdk::app!(main);
