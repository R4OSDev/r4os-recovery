#![no_std]
extern crate alloc;
use core::fmt::Write;
use r4os_sdk::{App, subsystems::Launch};
#[path = "../../../Simulation/SubsystemCases.rs"]
mod cases;
unsafe extern "C" {
    fn sdk65_guest_catalogue(
        start: *const r4os_sdk::abi::R4XStartContext,
        id: *const core::ffi::c_char,
    ) -> i32;
    fn sdk65_guest_media_save(start: *const r4os_sdk::abi::R4XStartContext) -> i32;
    fn sdk65_guest_source(start: *const r4os_sdk::abi::R4XStartContext) -> i32;
}
struct Output<'a, 'b>(&'a App<'b>);
impl Write for Output<'_, '_> {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        if self.0.write(s) < 0 {
            Err(core::fmt::Error)
        } else {
            Ok(())
        }
    }
}
fn run(app: &mut App<'_>) -> i32 {
    let before = app.heap().unwrap().stats().unwrap();
    let launch = match Launch::parse(app.args()) {
        Ok(v) => v,
        Err(e) => {
            let _ = writeln!(&mut Output(app), "FAIL SDK65 launch {:?}", e);
            return 1;
        }
    };
    if launch.guest() != Ok(b"C:\\TEMP\\SYNTH65.S65".as_slice()) {
        return 2;
    }
    let source = unsafe { sdk65_guest_source(app.start_context()) };
    if source != 0 {
        let _ = writeln!(&mut Output(app), "FAIL SDK65 source {}", source);
        return source;
    }
    let catalog =
        unsafe { sdk65_guest_catalogue(app.start_context(), c"test.sdk65.rust".as_ptr()) };
    if catalog != 0 {
        return catalog;
    }
    for (i, case) in [
        cases::clock_launch as fn() -> r4os_sdk::subsystems::Result<()>,
        cases::refused_driver,
        cases::video,
        cases::catalogue,
        cases::audio_failure,
    ]
    .into_iter()
    .enumerate()
    {
        if let Err(e) = case() {
            let _ = writeln!(&mut Output(app), "FAIL SDK65 case={} {:?}", i, e);
            return 10 + i as i32;
        }
    }
    let summary = match cases::runtime_summary() {
        Ok(v) => v,
        Err(e) => {
            let _ = writeln!(&mut Output(app), "FAIL SDK65 work {:?}", e);
            return 20;
        }
    };
    let _ = writeln!(
        &mut Output(app),
        "SDK65 WORK steps={} ops={} resets={} presents={} checksum={} time_ns={}",
        summary[0],
        summary[1],
        summary[2],
        summary[3],
        summary[4],
        summary[5]
    );
    let result = unsafe { sdk65_guest_media_save(app.start_context()) };
    if result != 0 {
        let _ = writeln!(&mut Output(app), "FAIL SDK65 real media/save {}", result);
        return result;
    }
    let after = app.heap().unwrap().stats().unwrap();
    if before.get(c"active_allocations") != after.get(c"active_allocations")
        || before.get(c"active_bytes") != after.get(c"active_bytes")
    {
        app.write("FAIL SDK65 heap balance\n");
        return 90;
    }
    app.write("PASS SDK65 Rust/C guest: launch, synthetic work, resize/damage, pause/reset/close, audio failure, real owned save/reopen/async join and window; exact active heap release\n");
    0
}
fn main(app: &mut App<'_>) -> i32 {
    unsafe extern "C" {
        fn sdk65_guest_report(
            start: *const r4os_sdk::abi::R4XStartContext,
            language: core::ffi::c_char,
            code: i32,
        ) -> i32;
    }
    let code = run(app);
    unsafe { sdk65_guest_report(app.start_context(), b'R' as core::ffi::c_char, code) }
}
r4os_sdk::app!(main);
