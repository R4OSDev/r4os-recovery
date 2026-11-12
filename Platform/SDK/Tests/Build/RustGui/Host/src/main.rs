#![no_std]
use core::pin::pin;
use r4os_sdk::{
    App, abi,
    gui::{Role, Session, SessionStorage, raw as c},
    path::FilePath,
    resources::{Resources, Timeout},
    storage::{Error, System},
};
fn exercise(app: &App<'_>) -> i32 {
    let Ok(resources) = Resources::new(app) else {
        return 10;
    };
    let Ok(mut process) = resources.open_process(app.instance_id() as u32) else {
        return 11;
    };
    let Ok(Some(info)) = process.status() else {
        return 12;
    };
    // Process inventory uses native classes 0/1/2; R4XStart uses 1/2/3.
    // This is the same eligibility predicate as the WindowService broker.
    if info.app_class != 1
        || (info.role != 1 && info.flags & abi::program_instance_flag_desktop_host == 0)
    {
        return 13;
    }
    let mut storage = pin!(SessionStorage::new());
    let mut timers = [];
    let Ok(mut host) = Session::open(storage.as_mut(), app, Role::DesktopHost, &mut timers) else {
        return 2;
    };
    if !matches!(host.window_info(), Ok(None)) {
        return 3;
    }
    let binding = unsafe { c::R4SdkGuiDesktopContext_programWindowId(0, host.native_desktop()) };
    if binding.status != 0 || (binding.bits as i32) >= 0 {
        return 1;
    }
    let path = if app.args().is_empty() {
        &b"C:\\TEMP\\GUI56A.R4X"[..]
    } else {
        app.args()
    };
    if host.clipboard_write(path).is_err() {
        return 6;
    }
    let Ok(info) = host.clipboard_info() else {
        return 7;
    };
    if info.length as usize != path.len() {
        return 8;
    }
    let mut buffer = [0u8; 128];
    if !matches!(host.clipboard_read(&mut buffer),Ok(value) if value==path) {
        return 9;
    }
    // A running Full-profile Desktop already owns the real broker. The
    // contender must preserve that exact live generation and its windows.
    match host.claim_host(Timeout::AfterNanos(2_000_000_000)) {
        Err(Error::Raw(code)) if code == abi::tray_result_not_owner => {}
        _ => return 4,
    }
    host.reset_host_connection();
    if !matches!(host.claim_host(Timeout::AfterNanos(2_000_000_000)),Err(Error::Raw(code)) if code==abi::tray_result_not_owner)
    {
        return 5;
    }
    app.write("[SDK56] independent Rust/C host admission without app window; live WINSVC owner preserved PASS\n");
    0
}
fn main(app: &mut App<'_>) -> i32 {
    let code = exercise(app);
    let Ok(system) = System::new(app) else {
        return 90;
    };
    let Ok(path) = FilePath::parse(b"C:\\TEMP\\G56HOST.TXT") else {
        return 91;
    };
    let mut message = *b"HOST56 result=00\r\n";
    message[14] = b'0' + (code / 10) as u8;
    message[15] = b'0' + (code % 10) as u8;
    if system.files().write(&path, &message).is_err() {
        return 92;
    }
    code
}
r4os_sdk::app!(main);
