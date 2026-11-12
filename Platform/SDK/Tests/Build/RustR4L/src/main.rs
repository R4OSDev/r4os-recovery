#![no_std]
use l66r_abi::{ApiV1, R4L66State};
type Allocate = unsafe extern "C" fn(u64, u64) -> u64;
type Release = unsafe extern "C" fn(u64, u64) -> i32;
type Notify = unsafe extern "C" fn(u64, u64, u64) -> i32;
#[unsafe(no_mangle)]
pub unsafe extern "C" fn l66r_open_impl(
    s: *mut R4L66State,
    owner: u64,
    generation: u64,
    allocate: u64,
    release: u64,
    notify: u64,
) -> i32 {
    if s.is_null() || owner == 0 || generation == 0 || allocate == 0 || release == 0 || notify == 0
    {
        return -1;
    }
    if unsafe { (*s).r#active != 0 || (*s).r#in_callback != 0 } {
        return -2;
    }
    let alloc: Allocate = unsafe { core::mem::transmute(allocate) };
    unsafe {
        (*s).r#in_callback = 1;
    }
    let memory = unsafe { alloc(owner, 16) };
    unsafe {
        (*s).r#in_callback = 0;
    }
    if memory == 0 {
        return -4;
    }
    unsafe {
        (memory as *mut u64).write(0x52344c36);
        (memory as *mut u64).add(1).write(generation);
        s.write(R4L66State {
            r#owner: owner,
            r#generation: generation,
            r#operations: 0,
            r#allocation: memory,
            r#allocate: allocate,
            r#release: release,
            r#notify: notify,
            r#active: 1,
            r#in_callback: 0,
        });
    }
    0
}
#[unsafe(no_mangle)]
pub unsafe extern "C" fn l66r_work_impl(
    s: *mut R4L66State,
    generation: u64,
    value: u64,
    output: *mut u64,
) -> i32 {
    if s.is_null() || output.is_null() {
        return -1;
    }
    let before = unsafe { s.read() };
    if before.r#active == 0 {
        return -1;
    }
    if before.r#generation != generation {
        return -3;
    }
    if before.r#in_callback != 0 {
        return -2;
    }
    // Raw pointers and copied snapshots: never retain &mut across a callback.
    unsafe {
        (*s).r#in_callback = 1;
    }
    let notify: Notify = unsafe { core::mem::transmute(before.r#notify) };
    let result = unsafe { notify(before.r#owner, generation, value) };
    let after = unsafe { s.read() };
    if after.r#owner != before.r#owner
        || after.r#generation != generation
        || after.r#allocation != before.r#allocation
        || after.r#active == 0
        || after.r#in_callback != 1
    {
        return -3;
    }
    unsafe {
        (*s).r#in_callback = 0;
    }
    if result != 0 {
        return result;
    }
    if unsafe { (before.r#allocation as *const u64).read() } != 0x52344c36
        || unsafe { (before.r#allocation as *const u64).add(1).read() } != generation
    {
        return -3;
    }
    unsafe {
        (*s).r#operations = before.r#operations.wrapping_add(1);
        output.write(
            value
                .wrapping_add(before.r#operations)
                .wrapping_add(1)
                .wrapping_add(0x52),
        );
    }
    0
}
#[unsafe(no_mangle)]
pub unsafe extern "C" fn l66r_close_impl(s: *mut R4L66State, generation: u64) -> i32 {
    if s.is_null() {
        return -1;
    }
    let before = unsafe { s.read() };
    if before.r#active == 0 {
        return -1;
    }
    if before.r#generation != generation {
        return -3;
    }
    if before.r#in_callback != 0 {
        return -2;
    }
    unsafe {
        (*s).r#in_callback = 1;
    }
    let release: Release = unsafe { core::mem::transmute(before.r#release) };
    let result = unsafe { release(before.r#owner, before.r#allocation) };
    unsafe {
        (*s).r#in_callback = 0;
    }
    if result != 0 {
        return result;
    }
    unsafe {
        (*s).r#allocation = 0;
        (*s).r#active = 0;
    }
    0
}
#[unsafe(no_mangle)]
#[unsafe(link_section = ".data.r4l_exports")]
pub static l66r_api_v1: ApiV1 = ApiV1 {
    header: r4os_sdk::r4l::provider_header(l66r_abi::api_v1_expectation),
    r#open: Some(l66r_open_impl),
    r#work: Some(l66r_work_impl),
    r#close: Some(l66r_close_impl),
};
r4os_sdk::r4l_provider!(l66r_query);
