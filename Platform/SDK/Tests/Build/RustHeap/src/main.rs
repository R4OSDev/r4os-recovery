#![no_std]
extern crate alloc;
use alloc::{boxed::Box, string::String, vec::Vec};
use core::sync::atomic::{AtomicBool, AtomicPtr, AtomicU32, Ordering};
use r4os_sdk::{App, abi};

static API: AtomicPtr<abi::R4XStartR4Sys> = AtomicPtr::new(core::ptr::null_mut());
static READY: AtomicU32 = AtomicU32::new(0);
static RELEASE: AtomicBool = AtomicBool::new(false);

unsafe extern "C" fn worker(seed: u64) -> i32 {
    let mut values = Vec::new();
    for i in 0..4096 {
        values.push((i as u64 ^ seed) as u8);
    }
    let boxed = Box::new([0xa5u8; 128]);
    let mut text = String::from("R4OS ");
    text.push_str("Rust allocation");
    if values.len() != 4096
        || values[4095] != (4095 ^ seed) as u8
        || boxed[0] != 0xa5
        || !text.ends_with("allocation")
    {
        return 21;
    }
    READY.fetch_add(1, Ordering::Release);
    let api = unsafe { &*API.load(Ordering::Acquire) };
    let sleep: abi::R4SysFns::sleep_ticks = unsafe { core::mem::transmute(api.sleep_ticks) };
    while !RELEASE.load(Ordering::Acquire) {
        unsafe { sleep(1) };
    }
    drop(text);
    drop(boxed);
    drop(values);
    0
}

fn main(app: &mut App<'_>) -> i32 {
    let Ok(heap) = app.heap() else {
        return 1;
    };
    let Ok(mut empty) = heap.allocate(0, 4096) else {
        return 2;
    };
    if empty.resize(128).is_err() || empty.as_slice() != [0; 128] {
        return 3;
    }
    empty.as_mut_slice().fill(0x5a);
    if empty.resize(256 * 1024).is_err()
        || empty.as_slice()[..128] != [0x5a; 128]
        || empty.as_slice()[128..].iter().any(|byte| *byte != 0)
    {
        return 4;
    }
    if empty.resize(16).is_err() {
        return 5;
    }
    drop(empty);
    {
        let large = alloc::vec![0x3cu8;9*1024*1024];
        if large[large.len() - 1] != 0x3c {
            return 6;
        }
        let mut checked = Vec::<u8>::new();
        if checked.try_reserve(usize::MAX).is_ok() {
            return 7;
        }
    }
    let api = app.system_api().unwrap();
    API.store(core::ptr::from_ref(api).cast_mut(), Ordering::Release);
    let create: abi::R4SysFns::thread_create_handle =
        unsafe { core::mem::transmute(api.thread_create_handle) };
    let join: abi::R4SysFns::thread_handle_join =
        unsafe { core::mem::transmute(api.thread_handle_join) };
    let mut handles = [abi::ProgramJoinHandle::default(); 4];
    for (i, handle) in handles.iter_mut().enumerate() {
        if unsafe {
            create(
                worker,
                i as u64,
                0,
                abi::thread_create_flag_compute_worker,
                handle,
            )
        } != 0
        {
            return 8;
        }
    }
    let mut waits = 0;
    while READY.load(Ordering::Acquire) != 4 {
        if waits == 2000 {
            return 9;
        }
        waits += 1;
        app.sleep(1);
    }
    if unsafe { heap.finish_instance() } != Err(r4os_sdk::heap::Error::Runtime(1)) {
        return 10;
    }
    RELEASE.store(true, Ordering::Release);
    for handle in &handles {
        let mut exit = -1;
        if unsafe { join(handle, 10000, &mut exit) } != 0 || exit != 0 {
            return 11;
        }
    }
    let Ok(stats) = heap.stats() else {
        return 12;
    };
    if stats.get(c"active_allocations") != Some(0) {
        return 13;
    }
    if unsafe { heap.finish_instance() }.is_err() {
        return 14;
    }
    let _=app.write("[HEAPRUST] Box/Vec/String, resize/alignment, four joined workers and full heap release OK\n");
    0
}
r4os_sdk::app!(main);
