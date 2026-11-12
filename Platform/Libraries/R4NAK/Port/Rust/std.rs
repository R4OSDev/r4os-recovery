// Copyright 2026 R4
// SPDX-License-Identifier: Apache-2.0
// Deliberately small NAK compatibility surface, not a Rust OS implementation.
#![no_std]

extern crate alloc;
extern crate hashbrown;

pub use core::{array, cell, clone, cmp, convert, default, fmt, hash, iter, marker, mem, num, ops, option, pin, ptr, result, slice, str};
pub use alloc::{boxed, format, string, vec};
pub mod prelude {
    pub use alloc::{borrow::ToOwned, boxed::Box, string::{String, ToString}, vec::Vec};
}
pub mod ffi {
    pub use core::ffi::*;
    pub use alloc::ffi::*;
}
pub mod os {
    pub mod raw { pub use core::ffi::*; }
}
pub mod collections {
    pub use alloc::collections::*;
    pub use hashbrown::{HashMap, HashSet, hash_map, hash_set};
}

// The compiler is configured explicitly. No environment or host path is read.
pub mod env {
    pub fn var(_: &str) -> Result<alloc::string::String, ()> { Err(()) }
}

pub mod io {
    #[derive(Debug, Clone, Copy)]
    pub enum ErrorKind { InvalidInput, Other, Unsupported }
    #[derive(Debug, Clone, Copy)]
    pub struct Error(pub ErrorKind);
    pub type Result<T> = core::result::Result<T, Error>;
    impl Error {
        pub fn last_os_error() -> Self { Self(ErrorKind::Other) }
        pub fn new(kind: ErrorKind, _: &str) -> Self { Self(kind) }
    }
    impl core::fmt::Display for Error {
        fn fmt(&self, out: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
            write!(out, "NAK memory stream: {:?}", self.0)
        }
    }
}

pub mod sync {
    use core::{cell::UnsafeCell, mem::MaybeUninit, sync::atomic::{AtomicU8, Ordering}};
    pub struct OnceLock<T> { state: AtomicU8, value: UnsafeCell<MaybeUninit<T>> }
    unsafe impl<T: Send + Sync> Sync for OnceLock<T> {}
    impl<T> OnceLock<T> {
        pub const fn new() -> Self {
            Self { state: AtomicU8::new(0), value: UnsafeCell::new(MaybeUninit::uninit()) }
        }
        pub fn get_or_init(&self, init: impl FnOnce() -> T) -> &T {
            if self.state.load(Ordering::Acquire) != 2 {
                if self.state.compare_exchange(0, 1, Ordering::Acquire, Ordering::Acquire).is_ok() {
                    unsafe { (*self.value.get()).write(init()); }
                    self.state.store(2, Ordering::Release);
                } else {
                    while self.state.load(Ordering::Acquire) != 2 { core::hint::spin_loop(); }
                }
            }
            unsafe { (*self.value.get()).assume_init_ref() }
        }
    }
}

unsafe extern "C" {
    fn r4nak_port_allocate(size: usize, alignment: usize) -> *mut u8;
    fn r4nak_port_deallocate(ptr: *mut u8);
    fn r4nak_port_fail(reason: u32) -> !;
    fn r4nak_port_log(bytes: *const u8, length: usize);
}

struct Allocator;
unsafe impl core::alloc::GlobalAlloc for Allocator {
    unsafe fn alloc(&self, layout: core::alloc::Layout) -> *mut u8 {
        unsafe { r4nak_port_allocate(layout.size(), layout.align()) }
    }
    unsafe fn dealloc(&self, ptr: *mut u8, _: core::alloc::Layout) {
        unsafe { r4nak_port_deallocate(ptr); }
    }
}
#[global_allocator]
static ALLOCATOR: Allocator = Allocator;

#[panic_handler]
fn panic(info: &core::panic::PanicInfo<'_>) -> ! {
    log(format_args!("NAK Rust panic: {}", info));
    unsafe { r4nak_port_fail(3) }
}

pub fn log(args: core::fmt::Arguments<'_>) {
    struct Sink;
    impl core::fmt::Write for Sink {
        fn write_str(&mut self, text: &str) -> core::fmt::Result {
            unsafe { r4nak_port_log(text.as_ptr(), text.len()); }
            Ok(())
        }
    }
    let _ = core::fmt::write(&mut Sink, args);
}

#[macro_export]
macro_rules! eprintln {
    () => { $crate::log(format_args!("\n")) };
    ($($arg:tt)*) => { $crate::log(format_args!($($arg)*)) };
}
#[macro_export]
macro_rules! eprint {
    ($($arg:tt)*) => { $crate::log(format_args!($($arg)*)) };
}
#[macro_export]
macro_rules! println {
    ($($arg:tt)*) => { $crate::log(format_args!($($arg)*)) };
}
