//! Close the freestanding compiler memory helpers inside the same R4X.
//! Integer x86-64 string instructions avoid both byte-loop overhead and LLVM
//! rewriting these bodies into recursive libc calls. The ordinary x86-64 ABI
//! supplies DF=0; these instructions leave it and all other flags unchanged.
//! The caller supplies valid ranges; no allocation or SIMD state is involved.

use core::{arch::asm, ffi::c_void, ptr};

#[inline(always)]
unsafe fn forward(dst: *mut c_void, src: *const c_void, len: usize) {
    unsafe {
        asm!("rep movsb", inout("rdi") dst => _, inout("rsi") src => _,
            inout("rcx") len => _, options(nostack, preserves_flags));
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn memcpy(dst: *mut c_void, src: *const c_void, len: usize) -> *mut c_void {
    unsafe { forward(dst, src, len) };
    dst
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn memmove(dst: *mut c_void, src: *const c_void, len: usize) -> *mut c_void {
    let dst = dst.cast::<u8>();
    let src = src.cast::<u8>();
    if (dst as usize).wrapping_sub(src as usize) < len {
        for index in (0..len).rev() {
            unsafe { ptr::write_volatile(dst.add(index), ptr::read_volatile(src.add(index))) };
        }
    } else {
        unsafe { forward(dst.cast(), src.cast(), len) };
    }
    dst.cast()
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn memset(dst: *mut c_void, value: i32, len: usize) -> *mut c_void {
    unsafe {
        asm!("rep stosb", inout("rdi") dst => _, in("al") value as u8,
            inout("rcx") len => _, options(nostack, preserves_flags));
    }
    dst
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn memcmp(left: *const c_void, right: *const c_void, len: usize) -> i32 {
    let left = left.cast::<u8>();
    let right = right.cast::<u8>();
    for index in 0..len {
        let a = unsafe { ptr::read_volatile(left.add(index)) };
        let b = unsafe { ptr::read_volatile(right.add(index)) };
        if a != b {
            return i32::from(a) - i32::from(b);
        }
    }
    0
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn bcmp(left: *const c_void, right: *const c_void, len: usize) -> i32 {
    unsafe { memcmp(left, right, len) }
}
