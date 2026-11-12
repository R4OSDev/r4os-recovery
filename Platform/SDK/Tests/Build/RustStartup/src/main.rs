#![no_std]
use core::sync::atomic::{AtomicPtr, AtomicU64, Ordering};
use r4os_sdk::App;

static ZERO: AtomicU64 = AtomicU64::new(0);
static DATA_POINTER: &[u8] = b"[RUSTSTART] entry/BSS/data/stack OK\n";
static INITIALIZED_POINTER: AtomicPtr<u8> = AtomicPtr::new(DATA_POINTER.as_ptr().cast_mut());

fn main(app: &mut App<'_>) -> i32 {
    if ZERO.load(Ordering::Relaxed) != 0 {
        return 21;
    }
    ZERO.store(app.instance_id(), Ordering::Relaxed);
    if ZERO.load(Ordering::Relaxed) == 0 || stack_probe(7) != 7 {
        return 22;
    }
    if app.system_api().is_none()
        || app
            .import("R4STD", "SETTINGS_V1")
            .is_none_or(|entry| entry.table == 0)
        || app
            .import("SDKABSENT", "API_V1")
            .is_none_or(|entry| entry.table != 0 || entry.resolved_version != 0)
    {
        return 26;
    }
    core::hint::black_box(&INITIALIZED_POINTER);
    let pointer = INITIALIZED_POINTER.load(Ordering::Relaxed);
    if pointer != DATA_POINTER.as_ptr().cast_mut() {
        return 24;
    }
    INITIALIZED_POINTER.store(pointer, Ordering::Relaxed);
    let text = unsafe { core::slice::from_raw_parts(pointer, DATA_POINTER.len()) };
    if app.write(core::str::from_utf8(text).unwrap()) < 0 {
        return 23;
    }
    if app.args() == b"/BADCTX" {
        let invalid = r4os_sdk::abi::R4XStartContext::default();
        let expected = r4os_sdk::StartupInfo {
            app_class: r4os_sdk::abi::R4XStartAppClass::console,
            required_groups: 0,
            imports: &[],
        };
        if unsafe { r4os_sdk::App::from_raw(&invalid, &expected, c"RUSTSTART") }.is_ok() {
            return 25;
        }
        let _ = app.write("[RUSTSTART] bad-context rejected\n");
        return 9;
    }
    if app.args() == b"/PANIC" {
        panic!("intentional SDK startup qualification");
    }
    7
}

#[inline(never)]
fn stack_probe(seed: u8) -> u32 {
    let mut pages = [0u8; 16384];
    core::hint::black_box(&mut pages);
    pages[16383] = seed;
    pages.iter().map(|x| *x as u32).sum()
}

r4os_sdk::app!(main);
