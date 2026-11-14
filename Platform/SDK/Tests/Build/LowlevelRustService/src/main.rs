#![no_std]
use r4os_sdk as sdk;
#[inline(never)]
fn stack_probe() -> bool {
    let mut bytes = [0u8; 24576];
    let p = bytes.as_mut_ptr();
    for i in 0..bytes.len() {
        unsafe {
            p.add(i)
                .write_volatile((i as u8).wrapping_mul(13).wrapping_add(91))
        };
    }
    for i in 0..bytes.len() {
        if unsafe { p.add(i).read_volatile() } != (i as u8).wrapping_mul(13).wrapping_add(91) {
            return false;
        }
    }
    true
}
fn raw(view: &sdk::platform2::Context<'_>) -> i32 {
    let raw = view.raw();
    let app = match sdk::lowlevel_context2!(view) {
        Ok(x) => x,
        Err(e) => return e,
    };
    if !core::ptr::eq(raw, app.start_context()) || app.instance_id() == 0 || !stack_probe() {
        return -20;
    }
    if sdk::lowlevel::initialize_runtime2(&app).is_err() {
        return -21;
    }
    if app.args() == b"panic" {
        panic!("raw69 panic qualification");
    }
    if app.args() == b"fault" {
        unsafe { core::arch::asm!("ud2", options(noreturn)) };
    }
    if app.args() == b"return" {
        return 37;
    }
    let class = app.start_context().app_class;
    if class != 3 {
        return -22;
    }
    let marker =
        b"PASS RAW69RS raw-context/current imports/class/24KB stack/explicit runtime/return\n";
    let address = match view.lookup(1, core::mem::offset_of!(sdk::platform2::abi::R4XStartR4Sys2, file_write) as u32) {
        Ok(address) => address,
        Err(_) => return -23,
    };
    let write: sdk::platform2::abi::R4SysFns2::file_write = unsafe { core::mem::transmute(address) };
    if unsafe {
        write(
            c"C:\\TEMP\\RAW69RS.OUT".as_ptr().cast(),
            marker.as_ptr(),
            marker.len() as u32,
        )
    } != marker.len() as i32
    {
        return -25;
    }
    let _ = app.write(unsafe { core::str::from_utf8_unchecked(marker) });
    0
}
sdk::lowlevel_entry2!(raw);
