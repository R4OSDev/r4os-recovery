//! Minimal pinned-backend reproducer, independent of QEMU and the SDK runtime.
//! Compile as an rlib with --emit=asm for x86_64-unknown-none. The explicit
//! SIMD variants lose alternating bytes in 56/72-byte result moves; target
//! defaults retain complete copies. Actual semantics are checked by the mixed
//! RustStorage consumer with nonzero bytes across the complete generation.
#![no_std]
#[repr(C)]
pub struct Header {
    kind: u16,
    generation: u64,
    fields: [u32; 10],
}
#[repr(C)]
pub struct View {
    bytes: *const u8,
    length: u64,
    header: Header,
}
unsafe extern "C" {
    fn fill_header(out: *mut Header) -> i32;
    fn fill_view(out: *mut View) -> i32;
}
#[unsafe(no_mangle)]
pub fn copy_header() -> Result<Header, i32> {
    let mut raw = core::mem::MaybeUninit::uninit();
    let status = unsafe { fill_header(raw.as_mut_ptr()) };
    if status < 0 {
        Err(status)
    } else {
        Ok(unsafe { raw.assume_init() })
    }
}
#[unsafe(no_mangle)]
pub fn copy_view() -> Result<View, i32> {
    let mut raw = core::mem::MaybeUninit::uninit();
    let status = unsafe { fill_view(raw.as_mut_ptr()) };
    if status < 0 {
        Err(status)
    } else {
        Ok(unsafe { raw.assume_init() })
    }
}
