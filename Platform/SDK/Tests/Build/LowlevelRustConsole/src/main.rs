#![no_std]
use r4os_sdk::{self as sdk, abi};
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
unsafe extern "C" fn raw(raw: *const abi::R4XStartContext) -> i32 {
    let app = match unsafe { sdk::lowlevel_context!(raw) } {
        Ok(x) => x,
        Err(e) => return e,
    };
    if !core::ptr::eq(raw, app.start_context()) || app.instance_id() == 0 || !stack_probe() {
        return -20;
    }
    if sdk::lowlevel::initialize_runtime(&app).is_err() {
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
    if class != 1 {
        return -22;
    }
    let marker =
        b"PASS RAW69RC raw-context/current imports/class/24KB stack/explicit runtime/return\n";
    let Some(sys) = app.system_api() else {
        return -23;
    };
    if sys.file_write == 0 {
        return -24;
    }
    let write: abi::R4SysFns::file_write = unsafe { core::mem::transmute(sys.file_write) };
    if unsafe {
        write(
            c"C:\\TEMP\\RAW69RC.OUT".as_ptr().cast(),
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
sdk::lowlevel_entry!(raw);
