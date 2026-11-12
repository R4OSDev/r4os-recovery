use core::mem::MaybeUninit;
use r4os_sdk::{
    c_facades as c,
    published_frame::{Bridge, CopyFeatures, Damage, Error, Published, Rectangle, Stamp},
    subsystems::Callbacks,
};
unsafe extern "C" {
    fn sdk65_fixture_init(user: *mut core::ffi::c_void);
    fn sdk65_fixture_mask() -> u64;
    fn sdk65_fixture_dispatch(
        user: *mut core::ffi::c_void,
        kind: u32,
        args: *const c::R4SdkSubsystemSlot,
        count: u32,
        output: *mut core::ffi::c_void,
    ) -> c::R4SdkSubsystemSlot;
    fn sdk_published26_color(user: *const core::ffi::c_void, index: u32) -> u32;
    fn sdk_published26_c_case() -> i32;
}
fn stamp(revision: u64) -> Stamp {
    Stamp {
        binding_generation: 1,
        revision,
        palette_revision: 0,
    }
}
#[test]
fn published_frame_shared_c_rust_copy_renderer_and_scoped_source() {
    assert_eq!(unsafe { sdk_published26_c_case() }, 0);
    let mut user = [0u64; 1024];
    unsafe { sdk65_fixture_init(user.as_mut_ptr().cast()) };
    let mut storage = MaybeUninit::uninit();
    let mask = unsafe { sdk65_fixture_mask() } & !(1 << 6);
    let callbacks =
        unsafe { Callbacks::open(&mut storage, &mut user, mask, sdk65_fixture_dispatch) }.unwrap();
    let mut scratch = [0u32; 128 * 128];
    let mut bridge = Bridge::new(&callbacks, &mut scratch, CopyFeatures::default()).unwrap();
    bridge.bind(1).unwrap();
    let mut pixels = [0x112233u32; 64];
    {
        let source = unsafe { Published::xrgb(&pixels, 8, 8, stamp(1), Damage::Full) }.unwrap();
        let mut frame = bridge.sync(source).unwrap();
        assert!(frame.updated());
        let out = frame.present(16, 16).unwrap();
        assert_eq!((out.kind, out.mode, out.viewport.integer_scale), (2, 0, 2));
    }
    assert_eq!(bridge.progress().unwrap().active_ticket, 0);
    pixels[9] = 0x334455;
    {
        let source = unsafe {
            Published::xrgb(
                &pixels,
                8,
                8,
                stamp(2),
                Damage::Rectangle {
                    base_revision: 1,
                    rect: Rectangle {
                        x: 1,
                        y: 1,
                        w: 1,
                        h: 1,
                    },
                },
            )
        }
        .unwrap();
        let mut frame = bridge.sync(source).unwrap();
        let out = frame.present(16, 16).unwrap();
        assert_eq!((out.kind, out.mode, out.damage_regions), (2, 1, 1));
    }
    bridge.pause(true).unwrap();
    bridge.close().unwrap();
    assert_eq!(bridge.progress().unwrap().state, 3);
    drop(bridge);
    drop(callbacks);
    assert_eq!(
        unsafe { sdk_published26_color(user.as_ptr().cast(), 0) },
        0x112233
    );
    assert_eq!(
        unsafe { sdk_published26_color(user.as_ptr().cast(), 2 * 16 + 2) },
        0x334455
    );
}
#[test]
fn forgotten_frame_exposes_only_scalar_state_and_close_until_owner_ends() {
    let mut user = [0u64; 1024];
    unsafe { sdk65_fixture_init(user.as_mut_ptr().cast()) };
    let mut storage = MaybeUninit::uninit();
    let mask = unsafe { sdk65_fixture_mask() } & !(1 << 6);
    let callbacks =
        unsafe { Callbacks::open(&mut storage, &mut user, mask, sdk65_fixture_dispatch) }.unwrap();
    let mut scratch = [0u32; 128 * 128];
    let mut bridge = Bridge::new(&callbacks, &mut scratch, CopyFeatures::default()).unwrap();
    bridge.bind(1).unwrap();
    let pixels = vec![0x112233u32; 64];
    let source = unsafe { Published::xrgb(&pixels, 8, 8, stamp(1), Damage::Full) }.unwrap();
    let frame = bridge.sync(source).unwrap();
    core::mem::forget(frame);
    drop(pixels);
    assert_ne!(bridge.progress().unwrap().active_ticket, 0);
    assert_eq!(bridge.bind(2), Err(Error(-407)));
    bridge.close().unwrap();
    assert_eq!(bridge.progress().unwrap().active_ticket, 0);
}
