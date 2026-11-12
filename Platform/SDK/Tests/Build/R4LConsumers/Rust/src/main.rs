#![no_std]
use l66r_abi::{ApiV1_openFn, ApiV1Client, R4L66State};
use r4os_sdk::{
    App,
    r4l::{self, Interface},
};
unsafe extern "C" {
    fn sdk66_consume(
        start: *const r4os_sdk::abi::R4XStartContext,
        module: *const core::ffi::c_char,
        tag: u64,
    ) -> i32;
}
fn main(app: &mut App<'_>) -> i32 {
    let before = app.heap().unwrap().stats().unwrap();
    // Real generated Rust client and generic same-interface cross-vendor client.
    let client = match ApiV1Client::init(app) {
        Ok(c) => c,
        Err(_) => return 1,
    };
    let mut state: R4L66State = unsafe { core::mem::zeroed() };
    if unsafe { client.r#open(&mut state, 0, 11, 0, 0, 0) } != -1 {
        return 2;
    }
    if r4l::query(app, "L66R").is_err() || r4l::query(app, "L66C").is_err() {
        return 3;
    }
    let other = match Interface::new(app, "L66C", "API_V1", l66r_abi::api_v1_expectation) {
        Ok(i) => i,
        Err(_) => return 4,
    };
    let open: ApiV1_openFn = match unsafe { other.function(32) } {
        Some(f) => f,
        None => return 5,
    };
    if unsafe { open(&mut state, 0, 11, 0, 0, 0) } != -1 {
        return 6;
    }
    for (module, tag) in [(c"L66C", 0x43), (c"L66R", 0x52)] {
        let rc = unsafe { sdk66_consume(app.start_context(), module.as_ptr(), tag) };
        if rc != 0 {
            return rc;
        }
    }
    let after = app.heap().unwrap().stats().unwrap();
    if before.get(c"active_allocations") != after.get(c"active_allocations")
        || before.get(c"active_bytes") != after.get(c"active_bytes")
    {
        return 99;
    }
    app.write("PASS R4L66 Rust generated/generic clients and exact active heap release\n");
    0
}
r4os_sdk::app!(main);
