// Reuse the library owners' existing small authored fixtures.
pub const PNG: &[u8] = include_bytes!("../../R4IMG/Tests/Decoder/Fixtures/rgba.png");
pub const FONT: &[u8] = include_bytes!("../../R4FONT/Tests/Fixtures/sample-glyf.ttf");
// Same 138-byte FNT vector as R4FONT/Bindings/Zig/font_import.zig::testFnt.
pub fn fnt() -> [u8; 138] {
    let mut fnt = [0; 138];
    for (index, value) in [
        (1, 1),
        (2, 138),
        (68, 8),
        (74, 7),
        (85, 255),
        (86, 8),
        (88, 8),
        (91, 8),
        (93, 8),
        (95, 0xc4),
        (96, 0xc4),
        (99, 1),
        (105, 130),
        (113, 118),
        (130, b'T'),
    ] {
        fnt[index] = value;
    }
    fnt[118..126].copy_from_slice(&[0x18, 0x24, 0x42, 0x7e, 0x42, 0x42, 0, 0]);
    fnt
}
