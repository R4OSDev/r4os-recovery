#![no_std]
extern crate alloc;
use alloc::vec;
use core::fmt::Write;
use r4os_library_helpers::{
    Error, Heap,
    graphics::{ColorProfile, Receiver},
    media::{BuiltinShader, Nv12, shader},
    video::Clock,
};
use r4os_sdk::App;
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
    fn r4libraries60_color(
        start: *const r4os_sdk::abi::R4XStartContext,
        bytes: *const u8,
        length: usize,
        pixels: *mut u32,
    ) -> i32;
    fn r4libraries60_workers(start: *const r4os_sdk::abi::R4XStartContext) -> i32;
}
const ICC: &[u8] = include_bytes!("../../../../R4GFX/Tests/Color/Fixtures/vcgt-display.icc");
const EDID: &[u8] = include_bytes!("../../../../R4GFX/Tests/Display/Fixtures/qemu.edid");
fn exercise(app: &App<'_>) -> Result<(), (i32, Error)> {
    let bad = Error::InvalidProvider;
    let heap = Heap::new().map_err(|e| (1, e))?;
    let mut profile = ColorProfile::open(app, &heap, ICC, 1, 2).map_err(|e| (2, e))?;
    let mut rust = [0xffffff, 0, 0xff0000, 0x00ff00];
    let mut c = rust;
    profile.apply_sdr(&mut rust, 4, 1).map_err(|e| (3, e))?;
    let rc = unsafe {
        r4libraries60_color(app.start_context(), ICC.as_ptr(), ICC.len(), c.as_mut_ptr())
    };
    if rc != 0 {
        return Err((100 + rc, bad));
    }
    if rust != c
        || ((rust[0] >> 16) & 255).abs_diff(191) > 1
        || ((rust[0] >> 8) & 255).abs_diff(128) > 1
        || rust[0] & 255 != 255
    {
        return Err((4, bad));
    }
    if profile.apply_sdr(&mut [0; 1], 4, 1).is_ok() {
        return Err((5, bad));
    }
    drop(profile);
    let receiver = Receiver::parse(EDID).map_err(|e| (6, e))?;
    if !receiver.complete().map_err(|e| (7, e))? || receiver.timing(0).map_err(|e| (8, e))?.0 == 0 {
        return Err((9, bad));
    }
    let layout = Nv12::new(18, 16, false).map_err(|e| (10, e))?;
    let mut pixels = vec![0; layout.bytes().map_err(|e| (11, e))?];
    layout
        .rows(&[0; 20 * 16], 20, &mut pixels, 0, 16)
        .map_err(|e| (12, e))?;
    if pixels[0] != 16
        || pixels[layout.uv_offset().map_err(|e| (13, e))?] != 128
        || shader(BuiltinShader::Copy).map_err(|e| (14, e))?[0] != 0x07230203
    {
        return Err((15, bad));
    }
    let mut clock = Clock::new(100, 1000).map_err(|e| (16, e))?;
    clock.pause(150, true).map_err(|e| (17, e))?;
    if clock.position(200).map_err(|e| (18, e))? != 1050 {
        return Err((19, bad));
    }
    let rc = unsafe { r4libraries60_workers(app.start_context()) };
    if rc > 0 {
        return Err((200 + rc, bad));
    }
    if rc < 0 {
        let _ = writeln!(
            &mut Output(app),
            "MEDIA60 optional compiler providers absent mask={} (ACO=1, NAK=2); native init rejection checked",
            -rc
        );
    }
    Ok(())
}
fn main(app: &mut App<'_>) -> i32 {
    let before = app.heap().unwrap().stats().unwrap();
    if let Err((step, error)) = exercise(app) {
        let _ = writeln!(
            &mut Output(app),
            "FAIL MEDIA60 step={} error={:?}",
            step,
            error
        );
        return step;
    }
    let after = app.heap().unwrap().stats().unwrap();
    if before.get(c"active_allocations") != after.get(c"active_allocations")
        || before.get(c"active_bytes") != after.get(c"active_bytes")
    {
        app.write("FAIL MEDIA60 live heap balance\n");
        return 90;
    }
    app.write("PASS MEDIA60 Rust/C original ICC/VCGT, receiver, NV12, clock, shader data; optional compiler availability and exact allocation release\n");
    0
}
r4os_sdk::app!(main);
