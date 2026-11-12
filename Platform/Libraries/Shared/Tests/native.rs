#![cfg(test)]
use r4os_library_helpers::{Heap, font, standard::Graphemes};
mod fixtures;
unsafe extern "C" {
    fn r4libraries59_pure() -> i32;
}
#[test]
fn c_rust_share_pinned_graphemes_and_boundary_validation() {
    assert_eq!(unsafe { r4libraries59_pure() }, 0);
    let text = "A\u{308}B";
    let actual = Graphemes::new(text.as_bytes())
        .unwrap()
        .collect::<Result<Vec<_>, _>>()
        .unwrap();
    assert_eq!(actual, vec!["A\u{308}".as_bytes(), b"B"]);
    assert_eq!(Graphemes::prefix(text.as_bytes(), 2).unwrap(), 0);
    assert!(Graphemes::prefix(&[b'A', 0xff], 1).is_err());
    use core::mem::MaybeUninit;
    use r4os_library_helpers::raw as r;
    // Construct through the compiler-owned boundary; opaque layouts are not
    // reconstructed as Rust structs or copied from private implementation data.
    unsafe {
        let mut outputs: [r::R4GfxTopologyOutput; 2] = MaybeUninit::zeroed().assume_init();
        for (i, output) in outputs.iter_mut().enumerate() {
            let mut key = MaybeUninit::zeroed().assume_init();
            let mut point = MaybeUninit::zeroed().assume_init();
            let mut view = MaybeUninit::zeroed().assume_init();
            assert_eq!(r::R4GfxTopologyKey_create(&mut key).status, 0);
            assert_eq!(r::R4GfxTopologyKey_set_connector(&mut key, i as u32 + 1).status, 0);
            assert_eq!(r::R4GfxTopologyPoint_from_fields(&mut point, if i == 0 { -640 } else { 0 }, 0).status, 0);
            assert_eq!(r::R4GfxTopologyViewport_from_fields(&mut view, &point, 640, 480, 120, 0).status, 0);
            assert_eq!(r::R4GfxTopologyOutput_from_fields(output, &key, &view, 1, u8::from(i == 0), 0, 60_000).status, 0);
        }
        let mut layout = MaybeUninit::zeroed().assume_init();
        let admitted = r::R4GfxTopologyLayout_init(0, outputs.as_ptr(), 2, 1, &mut layout);
        assert_eq!((admitted.status, admitted.flags), (0, 1));
        for (i, output) in outputs.iter_mut().enumerate() {
            let mut point = MaybeUninit::zeroed().assume_init();
            let mut view = MaybeUninit::zeroed().assume_init();
            assert_eq!(r::R4GfxTopologyPoint_from_fields(&mut point, if i == 0 { i32::MIN } else { i32::MAX - 640 }, 0).status, 0);
            assert_eq!(r::R4GfxTopologyViewport_from_fields(&mut view, &point, 640, 480, 120, 0).status, 0);
            assert_eq!(r::R4GfxTopologyOutput_set_view(output, &view).status, 0);
        }
        let refused = r::R4GfxTopologyLayout_init(0, outputs.as_ptr(), 2, 2, &mut layout);
        assert_eq!(refused.status, 0);
        assert_ne!(refused.flags & 2, 0);
        let mut rect = MaybeUninit::zeroed().assume_init();
        assert_eq!(r::R4GfxTopologyRect_from_fields(&mut rect, i32::MAX - 127, 0, 128, 1).status, 0);
        let valid = r::R4GfxTopologyRect_valid(0, &rect);
        assert_eq!((valid.status, valid.flags, valid.bits), (0, 1, 0));
    }
}
#[test]
fn native_font_import_retains_allocator_and_releases_owned_bytes() {
    let heap = Heap::new().unwrap();
    let source = fixtures::fnt();
    let output = font::import(&heap, &source, b"test.fnt", 0).unwrap();
    assert_eq!(&output.bytes()[..4], b"R4F1");
    assert!(font::import(&heap, b"invalid", b"bad.fnt", 0).is_err());
    drop(output);
    assert_eq!(&fixtures::PNG[..8], b"\x89PNG\r\n\x1a\n");
    assert!(fixtures::FONT.len() > 100);
}
