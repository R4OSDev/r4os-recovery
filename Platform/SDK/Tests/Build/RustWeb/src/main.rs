#![no_std]
extern crate alloc;
use core::fmt::Write;
use r4os_sdk::App;
#[path = "../../../Simulation/WebCases.rs"]
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
    let hash = match cases::c_and_layout() {
        Ok(h) => h,
        Err(e) => {
            let _ = writeln!(&mut Output(app), "FAIL WEB62 C/layout {:?}", e);
            return 1;
        }
    };
    app.write("PASS WEB62 C/layout, host/get/set, exception, cancellation, GC and pixels\n");
    let cases: [fn() -> r4os_sdk::web::Result<()>; 4] = [
        cases::document_forms_fonts_images,
        cases::script_callbacks_and_budgets,
        cases::canvas_and_background,
        cases::runtime_document_lifecycle,
    ];
    for (i, case) in cases.iter().enumerate() {
        if let Err(e) = case() {
            let _ = writeln!(&mut Output(app), "FAIL WEB62 case={} {:?}", i + 2, e);
            return (i + 2) as i32;
        }
        let _ = writeln!(&mut Output(app), "PASS WEB62 case={}", i + 2);
    }
    let after = app.heap().unwrap().stats().unwrap();
    if before.get(c"active_allocations") != after.get(c"active_allocations")
        || before.get(c"active_bytes") != after.get(c"active_bytes")
    {
        app.write("FAIL WEB62 heap balance\n");
        return 90;
    }
    let _ = writeln!(
        &mut Output(app),
        "PASS WEB62 Rust/C original document/layout/script/form/font/image/background/canvas/runtime; hash={:016x}; exact heap release",
        hash
    );
    0
}
r4os_sdk::app!(main);
