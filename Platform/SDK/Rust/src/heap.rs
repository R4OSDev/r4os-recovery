//! Instance-bound views of the SDK's shared pooled VM heap. The same core
//! serves Zig, C and Rust; the kernel still owns VM and task retirement.
use crate::app2::{App as App2, Memory};
use crate::{App, abi};
use core::{
    alloc::Layout,
    ffi::{CStr, c_void},
    marker::PhantomData,
    ptr::NonNull,
};

unsafe extern "C" {
    fn R4SdkHeapBind(api: *const abi::R4XStartR4Sys, instance: u64) -> i32;
    fn R4SdkHeapAlloc(
        api: *const abi::R4XStartR4Sys,
        instance: u64,
        size: usize,
        alignment: usize,
    ) -> *mut c_void;
    fn R4SdkHeapRealloc(
        api: *const abi::R4XStartR4Sys,
        instance: u64,
        pointer: *mut c_void,
        size: usize,
        alignment: usize,
    ) -> *mut c_void;
    fn R4SdkHeapFree(api: *const abi::R4XStartR4Sys, instance: u64, pointer: *mut c_void) -> i32;
    fn R4SdkHeapStats(
        api: *const abi::R4XStartR4Sys,
        instance: u64,
        values: *mut u64,
        capacity: u32,
    ) -> i32;
    fn R4SdkHeapStatName(index: u32) -> *const core::ffi::c_char;
    fn R4SdkHeapFinish(api: *const abi::R4XStartR4Sys, instance: u64) -> i32;
}

unsafe extern "C" {
    fn R4SdkHeapBind2(api: *const Memory, instance: u64) -> i32;
    fn R4SdkHeapAlloc2(
        api: *const Memory,
        instance: u64,
        size: usize,
        alignment: usize,
    ) -> *mut c_void;
    fn R4SdkHeapRealloc2(
        api: *const Memory,
        instance: u64,
        pointer: *mut c_void,
        size: usize,
        alignment: usize,
    ) -> *mut c_void;
    fn R4SdkHeapFree2(api: *const Memory, instance: u64, pointer: *mut c_void) -> i32;
    fn R4SdkHeapStats2(api: *const Memory, instance: u64, values: *mut u64, capacity: u32) -> i32;
    fn R4SdkHeapFinish2(api: *const Memory, instance: u64) -> i32;
    #[cfg(all(feature = "alloc", target_os = "none"))]
    fn R4SdkHeapMemory2(api: *const Memory, instance: u64) -> *const Memory;
}

// This language view selects the actual source. The Zig heap remains the one
// implementation, with one owner binding and the original region/ACK state.
#[derive(Clone, Copy)]
enum Api<'a> {
    Legacy(&'a abi::R4XStartR4Sys),
    Mapped(&'a Memory),
}
unsafe fn heap_bind(api: Api<'_>, instance: u64) -> i32 {
    unsafe {
        match api {
            Api::Legacy(table) => R4SdkHeapBind(table, instance),
            Api::Mapped(memory) => R4SdkHeapBind2(memory, instance),
        }
    }
}
unsafe fn heap_alloc(api: Api<'_>, instance: u64, size: usize, alignment: usize) -> *mut c_void {
    unsafe {
        match api {
            Api::Legacy(table) => R4SdkHeapAlloc(table, instance, size, alignment),
            Api::Mapped(memory) => R4SdkHeapAlloc2(memory, instance, size, alignment),
        }
    }
}
unsafe fn heap_realloc(
    api: Api<'_>,
    instance: u64,
    pointer: *mut c_void,
    size: usize,
    alignment: usize,
) -> *mut c_void {
    unsafe {
        match api {
            Api::Legacy(table) => R4SdkHeapRealloc(table, instance, pointer, size, alignment),
            Api::Mapped(memory) => R4SdkHeapRealloc2(memory, instance, pointer, size, alignment),
        }
    }
}
unsafe fn heap_free(api: Api<'_>, instance: u64, pointer: *mut c_void) -> i32 {
    unsafe {
        match api {
            Api::Legacy(table) => R4SdkHeapFree(table, instance, pointer),
            Api::Mapped(memory) => R4SdkHeapFree2(memory, instance, pointer),
        }
    }
}
unsafe fn heap_stats(api: Api<'_>, instance: u64, values: *mut u64, capacity: u32) -> i32 {
    unsafe {
        match api {
            Api::Legacy(table) => R4SdkHeapStats(table, instance, values, capacity),
            Api::Mapped(memory) => R4SdkHeapStats2(memory, instance, values, capacity),
        }
    }
}
unsafe fn heap_finish(api: Api<'_>, instance: u64) -> i32 {
    unsafe {
        match api {
            Api::Legacy(table) => R4SdkHeapFinish(table, instance),
            Api::Mapped(memory) => R4SdkHeapFinish2(memory, instance),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    InvalidLayout,
    OutOfMemory,
    Runtime(i32),
}

pub struct Heap<'a> {
    api: Api<'a>,
    instance: u64,
    _local: PhantomData<*mut ()>,
}
impl<'a> Heap<'a> {
    pub(crate) fn new(app: &'a App<'_>) -> Result<Self, Error> {
        let api = Api::Legacy(app.system_api().ok_or(Error::Runtime(-1))?);
        let instance = app.instance_id();
        let rc = unsafe { heap_bind(api, instance) };
        if rc != 0 {
            return Err(Error::Runtime(rc));
        }
        Ok(Self {
            api,
            instance,
            _local: PhantomData,
        })
    }
    pub(crate) fn new2(app: &'a App2<'_>) -> Result<Self, Error> {
        let api = Api::Mapped(&app.memory);
        let instance = app.instance_id();
        let rc = unsafe { heap_bind(api, instance) };
        if rc != 0 {
            return Err(Error::Runtime(rc));
        }
        Ok(Self {
            api,
            instance,
            _local: PhantomData,
        })
    }
    pub fn allocate(&self, size: usize, alignment: usize) -> Result<Buffer<'_, 'a>, Error> {
        let layout = Layout::from_size_align(size, alignment).map_err(|_| Error::InvalidLayout)?;
        let pointer = if size == 0 {
            NonNull::new(alignment as *mut u8).unwrap()
        } else {
            NonNull::new(unsafe { heap_alloc(self.api, self.instance, size, alignment) }.cast())
                .ok_or(Error::OutOfMemory)?
        };
        // Safe slice views require initialized bytes. GlobalAlloc remains
        // uninitialized, as required by its separate raw allocation contract.
        unsafe { core::ptr::write_bytes(pointer.as_ptr(), 0, size) };
        Ok(Buffer {
            heap: self,
            pointer,
            layout,
        })
    }
    pub fn stats(&self) -> Result<Stats, Error> {
        let mut stats = Stats {
            values: [0; 64],
            count: 0,
        };
        let count = unsafe { heap_stats(self.api, self.instance, stats.values.as_mut_ptr(), 64) };
        if count < 0 {
            return Err(Error::Runtime(count));
        }
        if count as usize > stats.values.len() {
            return Err(Error::Runtime(-1));
        }
        stats.count = count as usize;
        Ok(stats)
    }
    /// Close allocation admission for this entire R4X heap. Existing buffers
    /// may be freed before retry. Success includes actual VM/notification ACKs.
    /// # Safety
    /// All allocator users, including any worker threads, must be joined or
    /// otherwise quiescent. No allocation may follow this irreversible call.
    pub unsafe fn finish_instance(&self) -> Result<(), Error> {
        let rc = unsafe { heap_finish(self.api, self.instance) };
        if rc == 0 {
            Ok(())
        } else {
            Err(Error::Runtime(rc))
        }
    }
}

pub struct Buffer<'h, 'a> {
    heap: &'h Heap<'a>,
    pointer: NonNull<u8>,
    layout: Layout,
}
impl Buffer<'_, '_> {
    pub fn as_slice(&self) -> &[u8] {
        unsafe { core::slice::from_raw_parts(self.pointer.as_ptr(), self.layout.size()) }
    }
    pub fn as_mut_slice(&mut self) -> &mut [u8] {
        unsafe { core::slice::from_raw_parts_mut(self.pointer.as_ptr(), self.layout.size()) }
    }
    pub fn resize(&mut self, size: usize) -> Result<(), Error> {
        let next =
            Layout::from_size_align(size, self.layout.align()).map_err(|_| Error::InvalidLayout)?;
        let pointer = if size == 0 {
            if self.layout.size() != 0 {
                let rc = unsafe {
                    heap_free(
                        self.heap.api,
                        self.heap.instance,
                        self.pointer.as_ptr().cast(),
                    )
                };
                if rc != 0 {
                    return Err(Error::Runtime(rc));
                }
            }
            NonNull::new(next.align() as *mut u8).unwrap()
        } else {
            let old = if self.layout.size() == 0 {
                core::ptr::null_mut()
            } else {
                self.pointer.as_ptr().cast()
            };
            NonNull::new(
                unsafe { heap_realloc(self.heap.api, self.heap.instance, old, size, next.align()) }
                    .cast(),
            )
            .ok_or(Error::OutOfMemory)?
        };
        if size > self.layout.size() {
            unsafe {
                core::ptr::write_bytes(
                    pointer.as_ptr().add(self.layout.size()),
                    0,
                    size - self.layout.size(),
                )
            };
        }
        self.pointer = pointer;
        self.layout = next;
        Ok(())
    }
}
impl Drop for Buffer<'_, '_> {
    fn drop(&mut self) {
        if self.layout.size() != 0 {
            let rc = unsafe {
                heap_free(
                    self.heap.api,
                    self.heap.instance,
                    self.pointer.as_ptr().cast(),
                )
            };
            assert_eq!(rc, 0, "SDK heap ownership lost");
        }
    }
}

/// A single locked snapshot of every metric of the canonical VM allocator.
/// Names are provided by that owner, not duplicated per language.
pub struct Stats {
    values: [u64; 64],
    count: usize,
}
impl Stats {
    pub fn iter(&self) -> impl Iterator<Item = (&CStr, u64)> {
        self.values[..self.count]
            .iter()
            .enumerate()
            .map(|(index, value)| {
                let name = unsafe { CStr::from_ptr(R4SdkHeapStatName(index as u32)) };
                (name, *value)
            })
    }
    pub fn get(&self, name: &CStr) -> Option<u64> {
        self.iter()
            .find_map(|(key, value)| if key == name { Some(value) } else { None })
    }
}

#[cfg(all(feature = "alloc", target_os = "none"))]
mod global {
    use super::*;
    use core::{
        alloc::GlobalAlloc,
        sync::atomic::{AtomicPtr, AtomicU64, Ordering},
    };
    // Only the immutable provider pointer/instance identity is retained.
    // No root App/Context loan survives into a worker. The kernel pins this
    // module image and VM ownership until all tasks have actually retired.
    pub(super) struct InstanceAllocator {
        api: AtomicPtr<c_void>,
        instance: AtomicU64,
    }
    #[global_allocator]
    static ALLOCATOR: InstanceAllocator = InstanceAllocator {
        api: AtomicPtr::new(core::ptr::null_mut()),
        instance: AtomicU64::new(0),
    };
    pub(crate) fn install(app: &App<'_>) -> Result<(), Error> {
        let heap = Heap::new(app)?;
        ALLOCATOR.instance.store(heap.instance, Ordering::Relaxed);
        ALLOCATOR.api.store(
            match heap.api {
                Api::Legacy(api) => core::ptr::from_ref(api).cast_mut().cast(),
                Api::Mapped(_) => unreachable!(),
            },
            Ordering::Release,
        );
        Ok(())
    }
    pub(crate) fn install2(app: &App2<'_>) -> Result<(), Error> {
        let heap = Heap::new2(app)?;
        let resident = unsafe { R4SdkHeapMemory2(&app.memory, heap.instance) };
        if resident.is_null() {
            return Err(Error::Runtime(-2));
        }
        // Only this SDK-owned resident callback copy crosses into workers.
        ALLOCATOR.instance.store(heap.instance, Ordering::Relaxed);
        ALLOCATOR
            .api
            .store(((resident as usize) | 1) as *mut c_void, Ordering::Release);
        Ok(())
    }
    unsafe fn decode<'a>(pointer: *mut c_void) -> Api<'a> {
        let address = pointer as usize;
        if address & 1 == 0 {
            Api::Legacy(unsafe { &*pointer.cast::<abi::R4XStartR4Sys>() })
        } else {
            Api::Mapped(unsafe { &*((address & !1) as *const Memory) })
        }
    }
    unsafe impl GlobalAlloc for InstanceAllocator {
        unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
            let api = self.api.load(Ordering::Acquire);
            if api.is_null() {
                return core::ptr::null_mut();
            }
            unsafe {
                heap_alloc(
                    decode(api),
                    self.instance.load(Ordering::Relaxed),
                    layout.size(),
                    layout.align(),
                )
                .cast()
            }
        }
        unsafe fn dealloc(&self, pointer: *mut u8, _: Layout) {
            let api = self.api.load(Ordering::Acquire);
            assert!(!api.is_null(), "SDK allocator not initialized");
            let rc = unsafe {
                heap_free(
                    decode(api),
                    self.instance.load(Ordering::Relaxed),
                    pointer.cast(),
                )
            };
            assert_eq!(rc, 0, "SDK heap ownership lost");
        }
        unsafe fn realloc(&self, pointer: *mut u8, old: Layout, size: usize) -> *mut u8 {
            let api = self.api.load(Ordering::Acquire);
            if api.is_null() {
                return core::ptr::null_mut();
            }
            unsafe {
                heap_realloc(
                    decode(api),
                    self.instance.load(Ordering::Relaxed),
                    pointer.cast(),
                    size,
                    old.align(),
                )
                .cast()
            }
        }
    }
}
#[cfg(all(feature = "alloc", target_os = "none"))]
pub(crate) use global::{install, install2};
