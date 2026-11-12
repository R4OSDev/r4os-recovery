#![cfg(test)]
use r4os_library_helpers::{
    graphics::Receiver,
    media::{BuiltinShader, Mux, Nv12, shader},
    video::Clock,
};
#[path = "native.rs"]
mod previous;
unsafe extern "C" {
    fn r4libraries47_start2() -> *const core::ffi::c_void;
    fn r4libraries47_compiler_context() -> i32;
    fn r4libraries60_transport() -> i32;
    fn r4libraries60_mux(bytes: *const u8, length: usize) -> u64;
    fn r4libraries60_mux_color(bytes: *const u8, length: usize, transfer: u8, centered: u8) -> u64;
    fn R4LibrariesAvcOracle(bytes: *mut u8, capacity: usize) -> usize;
    fn R4LibrariesRecordingOracle() -> i32;
}
#[test]
fn aligned_storage_and_named_error_are_not_private_layout_guesses() {
    assert_eq!(unsafe { r4libraries47_compiler_context() }, 0);
    assert_eq!(unsafe { r4libraries60_transport() }, 0);
    use core::mem::MaybeUninit;
    use r4os_library_helpers::raw as c;
    let mut compiler = MaybeUninit::<c::R4MediaCompilerContext2>::uninit();
    unsafe {
        let admitted = c::R4MediaCompilerContext2_init(0, r4libraries47_start2(), compiler.as_mut_ptr());
        assert_eq!(admitted.status, 0);
        assert_eq!(admitted.flags & 2, 0);
        // The host fixture supplies no independent compiler imports. Missing
        // providers must fail without producing an apparently valid worker.
        let mut nak = MaybeUninit::<c::R4NakWorker>::uninit();
        let mut aco = MaybeUninit::<c::R4AcoWorker>::uninit();
        for rejected in [
            c::R4MediaCompilerContext2_nakWorker(0, compiler.as_mut_ptr(), nak.as_mut_ptr()),
            c::R4MediaCompilerContext2_acoWorker(0, compiler.as_mut_ptr(), aco.as_mut_ptr()),
        ] {
            assert!(rejected.status != 0 || rejected.flags & 2 != 0);
        }
    }
    let mut refresh = MaybeUninit::<c::R4GfxRefreshClientClient>::uninit();
    let mut choice = MaybeUninit::<c::R4GfxRefreshPreferencesChoice>::uninit();
    let mut brightness = MaybeUninit::<c::R4GfxBrightnessClientClient>::uninit();
    let mut level = MaybeUninit::<c::R4GfxBrightnessPreferencesChoice>::uninit();
    unsafe {
        for slot in [
            c::R4Media_refreshInit(0, refresh.as_mut_ptr()),
            c::R4GfxRefreshPreferencesChoice_create(choice.as_mut_ptr()),
            c::R4Media_refreshSelect(0, refresh.as_mut_ptr(), choice.as_ptr()),
            c::R4Media_brightnessInit(0, brightness.as_mut_ptr()),
            c::R4GfxBrightnessPreferencesChoice_create(level.as_mut_ptr()),
        ] {
            assert_eq!(slot.status, 0);
            assert_eq!(slot.flags & 2, 0);
        }
        let selected = c::R4LibrariesSlot {
            ptr: level.as_mut_ptr().cast(),
            flags: 1,
            ..MaybeUninit::<c::R4LibrariesSlot>::zeroed().assume_init()
        };
        for value in [
            selected,
            MaybeUninit::<c::R4LibrariesSlot>::zeroed().assume_init(),
        ] {
            let slot = c::R4Media_brightnessSelect(0, brightness.as_mut_ptr(), value);
            assert_eq!(slot.status, 0);
            assert_eq!(slot.flags & 2, 0);
        }
        let mut colors = MaybeUninit::<c::R4GfxColorPreferencesConfig>::uninit();
        let mut changed = MaybeUninit::<c::R4GfxColorPreferencesConfig>::uninit();
        assert_eq!(
            c::R4GfxColorPreferencesConfig_create(colors.as_mut_ptr()).status,
            0
        );
        assert_eq!(
            c::R4GfxColorPreferencesConfig_create(changed.as_mut_ptr()).status,
            0
        );
        assert_eq!(
            c::R4Media_colorPreferencesEqual(0, colors.as_ptr(), changed.as_ptr()).bits,
            1
        );
        assert_eq!(
            c::R4GfxColorPreferencesConfig_set_count(changed.as_mut_ptr(), 1).status,
            0
        );
        assert_eq!(
            c::R4Media_colorPreferencesEqual(0, colors.as_ptr(), changed.as_ptr()).bits,
            0
        );
        let mut color = MaybeUninit::<c::R4GfxColorPreferencesChoice>::uninit();
        let mut other = MaybeUninit::<c::R4GfxColorPreferencesChoice>::uninit();
        assert_eq!(
            c::R4GfxColorPreferencesChoice_create(color.as_mut_ptr()).status,
            0
        );
        assert_eq!(
            c::R4GfxColorPreferencesChoice_create(other.as_mut_ptr()).status,
            0
        );
        let slot = |ptr| c::R4LibrariesSlot {
            ptr,
            flags: 1,
            ..MaybeUninit::zeroed().assume_init()
        };
        let left = slot(color.as_mut_ptr().cast());
        let right = slot(other.as_mut_ptr().cast());
        assert_eq!(c::R4Media_colorChoiceEqual(0, left, right).bits, 1);
        assert_eq!(
            c::R4GfxColorPreferencesChoice_set_intent(other.as_mut_ptr(), 2).status,
            0
        );
        assert_eq!(c::R4Media_colorChoiceEqual(0, left, right).bits, 0);
    }
}
#[test]
fn original_recording_oracles_and_identical_c_rust_mux_bytes() {
    assert_eq!(unsafe { R4LibrariesRecordingOracle() }, 0);
    let mut packet = [0u8; 512];
    let length = unsafe { R4LibrariesAvcOracle(packet.as_mut_ptr(), packet.len()) };
    assert!(length > 6 && length <= packet.len());
    let packet = &packet[..length];
    let mut output = Vec::new();
    let mut writer = Mux::new(64, 64).unwrap();
    writer
        .packet(packet, true, 0, 1, |bytes| {
            output.extend_from_slice(bytes);
            true
        })
        .unwrap();
    let hash = output.iter().fold(14695981039346656037u64, |h, &b| {
        (h ^ u64::from(b)).wrapping_mul(1099511628211)
    });
    assert_eq!(
        unsafe { r4libraries60_mux(packet.as_ptr(), packet.len()) },
        hash
    );
    assert_eq!(writer.frames().unwrap(), 1);
    for (transfer, centered) in [(1, false), (13, false), (13, true)] {
        let mut writer = Mux::with_color(64, 64, transfer, centered).unwrap();
        let mut output = Vec::new();
        writer
            .packet(packet, true, 0, 1, |part| {
                output.extend_from_slice(part);
                true
            })
            .unwrap();
        let hash = output.iter().fold(14695981039346656037u64, |h, &b| {
            (h ^ u64::from(b)).wrapping_mul(1099511628211)
        });
        assert_eq!(
            unsafe {
                r4libraries60_mux_color(packet.as_ptr(), packet.len(), transfer, u8::from(centered))
            },
            hash
        );
        assert!(
            output
                .windows(4)
                .any(|part| part == [0x55, 0xba, 0x81, transfer])
        );
        assert!(
            output
                .windows(4)
                .any(|part| part == [0x55, 0xb7, 0x81, if centered { 2 } else { 1 }])
        );
    }
    let mut failed = Mux::new(64, 64).unwrap();
    let mut calls = 0;
    let mut partial = 0;
    assert!(
        failed
            .packet(packet, true, 0, 1, |bytes| {
                calls += 1;
                if calls == 1 {
                    partial += bytes.len();
                    true
                } else {
                    false
                }
            })
            .is_err()
    );
    assert!(partial > 0 && failed.failed().unwrap());
    assert_eq!(failed.frames().unwrap(), 0);
    assert!(
        failed
            .packet(packet, true, 0, 1, |_| panic!(
                "closed writer must not write"
            ))
            .is_err()
    );
    let layout = Nv12::new(18, 16, false).unwrap();
    let mut nv12 = vec![0; layout.bytes().unwrap()];
    layout.rows(&[0u32; 20 * 16], 20, &mut nv12, 0, 16).unwrap();
    assert_eq!(nv12[0], 16);
    assert_eq!(nv12[layout.uv_offset().unwrap()], 128);
    assert!(
        layout
            .rows(&[0u32; 20 * 16], 20, &mut [0; 1], 0, 16)
            .is_err()
    );
    assert_eq!(shader(BuiltinShader::Copy).unwrap()[0], 0x07230203);
}
#[test]
fn receiver_and_media_clock_keep_original_data_and_progress() {
    let bytes = include_bytes!("../../R4GFX/Tests/Display/Fixtures/qemu.edid");
    let receiver = Receiver::parse(bytes).unwrap();
    assert!(receiver.complete().unwrap());
    assert!(receiver.digital().unwrap() && receiver.mode_count().unwrap() > 0);
    assert!(
        receiver
            .manufacturer()
            .unwrap()
            .iter()
            .all(u8::is_ascii_uppercase)
    );
    let (w, h, rate) = receiver.timing(0).unwrap();
    assert!(w > 0 && h > 0 && rate > 0);
    assert!(Receiver::parse(b"invalid").is_err());
    let mut clock = Clock::new(100, 1000).unwrap();
    assert_eq!(clock.position(150).unwrap(), 1050);
    clock.pause(150, true).unwrap();
    assert_eq!(clock.position(200).unwrap(), 1050);
    clock.seek(200, 100).unwrap();
    assert_eq!(clock.position(250).unwrap(), 100);
    assert!(clock.position(249).is_err());
}
