#![no_std]
extern crate alloc;
use core::fmt::Write;
use r4os_sdk::App;
#[path = "../../../Simulation/UpdateCases.rs"]
mod cases;
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
fn main(app: &mut App<'_>) -> i32 {
    let before = app.heap().unwrap().stats().unwrap();
    if let Err(e) = cases::c_replay(Some(app)) {
        let _ = writeln!(
            &mut Output(app),
            "FAIL UPDATE64 real checked transaction {:?}",
            e
        );
        return 1;
    }
    app.write("PASS UPDATE64 C original journal interruption/reopen/idempotent commit/rollback on private real files\n");
    for (i, case) in [
        cases::c_archive as fn() -> r4os_sdk::update::Result<()>,
        cases::c_io_callbacks,
        cases::c_cleanup,
        cases::metadata,
        cases::memory_format,
    ]
    .into_iter()
    .enumerate()
    {
        if let Err(e) = case() {
            let _ = writeln!(&mut Output(app), "FAIL UPDATE64 case={} {:?}", i, e);
            return 2 + i as i32;
        }
        let _ = writeln!(&mut Output(app), "PASS UPDATE64 case={}", i);
    }
    if let Err(e) = cases::catalogue(app) {
        let _ = writeln!(&mut Output(app), "FAIL UPDATE64 catalogue JSON.R4P {:?}", e);
        return 6;
    }
    app.write("PASS UPDATE64 strict catalogue via original JSON.R4P\n");
    let after = app.heap().unwrap().stats().unwrap();
    if before.get(c"active_allocations") != after.get(c"active_allocations")
        || before.get(c"active_bytes") != after.get(c"active_bytes")
    {
        app.write("FAIL UPDATE64 heap balance\n");
        return 90;
    }
    app.write(
        "PASS UPDATE64 exact active heap release; original Rust/C update and storage owners\n",
    );
    0
}
r4os_sdk::app!(main);
