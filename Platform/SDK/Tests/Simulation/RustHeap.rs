//! Real Rust -> C ABI -> shared SDK VM heap; only the kernel VM callbacks
//! are supplied by the native host. One instance keeps the whole test scope.
#![cfg(test)]
use abi::generation2::{R4XStartContext2 as StartContext, R4XStartR4Sys2 as SystemTable};
use r4os_sdk::{App, ImportSpec, StartupInfo, abi, heap::Error};
use std::{
    alloc::{GlobalAlloc, Layout, System},
    sync::{
        Mutex,
        atomic::{AtomicBool, AtomicU32, AtomicU64, Ordering},
    },
};

struct Region {
    base: usize,
    layout: Layout,
    live: bool,
}
static REGIONS: Mutex<Vec<Region>> = Mutex::new(Vec::new());
static OWNER: AtomicU32 = AtomicU32::new(42);
static GENERATION: AtomicU64 = AtomicU64::new(7);
static FAIL_COMMIT: AtomicBool = AtomicBool::new(false);
static FAIL_RELEASE: AtomicBool = AtomicBool::new(false);
unsafe extern "C" fn current(out: *mut abi::ProgramJoinHandle) -> i32 {
    unsafe {
        out.write(abi::ProgramJoinHandle {
            thread_id: 1,
            instance_id: OWNER.load(Ordering::Relaxed),
            thread_generation: 9,
            instance_generation: GENERATION.load(Ordering::Relaxed),
            reserved: 0,
        })
    };
    0
}
unsafe extern "C" fn reserve(
    size: u64,
    alignment: u64,
    _: u64,
    out: *mut abi::ProgramVmRegionInfo,
) -> i32 {
    let Ok(layout) = Layout::from_size_align(size as usize, alignment as usize) else {
        return -1;
    };
    let p = unsafe { System.alloc_zeroed(layout) };
    if p.is_null() {
        return -1;
    }
    let mut regions = REGIONS.lock().unwrap();
    regions.push(Region {
        base: p as usize,
        layout,
        live: true,
    });
    unsafe {
        out.write(abi::ProgramVmRegionInfo {
            id: regions.len() as u32,
            base: p as u64,
            len: size,
            ..Default::default()
        })
    };
    0
}
unsafe extern "C" fn commit(id: u32, offset: u64, len: u64, _: u64) -> i32 {
    if FAIL_COMMIT.load(Ordering::Relaxed) {
        return -1;
    }
    let regions = REGIONS.lock().unwrap();
    if let Some(region) = regions.get(id.wrapping_sub(1) as usize)
        && region.live
        && offset
            .checked_add(len)
            .is_some_and(|end| end <= region.layout.size() as u64)
    {
        return 0;
    }
    -1
}
unsafe extern "C" fn decommit(id: u32, offset: u64, len: u64) -> i32 {
    unsafe { commit(id, offset, len, 0) }
}
unsafe extern "C" fn release(id: u32) -> i32 {
    let mut regions = REGIONS.lock().unwrap();
    let Some(region) = regions.get_mut(id.wrapping_sub(1) as usize) else {
        return -1;
    };
    if !region.live {
        return -1;
    }
    if FAIL_RELEASE.load(Ordering::Relaxed) {
        // Simulate partial unmapping by destroying the old header page. The
        // retry must use resident value metadata, not payload/backreferences.
        unsafe { std::ptr::write_bytes(region.base as *mut u8, 0, 4096.min(region.layout.size())) };
        return -1;
    }
    unsafe { System.dealloc(region.base as *mut u8, region.layout) };
    region.live = false;
    0
}
#[test]
fn exact_owner_alignment_resize_failure_and_all_release_acknowledgements() {
    let api = SystemTable {
        thread_current_handle: current as *const () as _,
        vm_reserve: reserve as *const () as _,
        vm_commit: commit as *const () as _,
        vm_decommit: decommit as *const () as _,
        vm_release: release as *const () as _,
        ..Default::default()
    };
    let import = abi::R4XStartImport {
        group_id: abi::R4LGroup::r4sys.0,
        min_version: 2,
        resolved_version: 2,
        flags: abi::r4xstart_import_flag_group_interface,
        module_name: c"R4SYS".as_ptr() as u64,
        symbol_name: c"Query2".as_ptr() as u64,
        table: std::ptr::from_ref(&api) as u64,
    };
    let ctx = StartContext {
        app_class: abi::R4XStartAppClass::console.0,
        instance_id: 42,
        flags: abi::r4xstart_flag_imports_valid,
        imports: std::ptr::from_ref(&import) as u64,
        import_count: 1,
        ..Default::default()
    };
    let expected = StartupInfo {
        profile: 0,
        app_class: 1,
        required_groups: 2,
        imports: &[ImportSpec {
            module_name: c"R4SYS".as_ptr().cast(),
            symbol_name: c"Query2".as_ptr().cast(),
            minimum: 2,
            optional: 0,
            group_id: 1,
            reserved: 0,
        }],
    };
    {
        let gui = StartContext {
            app_class: abi::R4XStartAppClass::gui.0,
            ..ctx
        };
        let app = unsafe { App::from_raw(&gui, &expected, c"HEAPTEST") }.unwrap();
        assert!(std::ptr::eq(app.start_context(), &gui));
    }
    let app = unsafe { App::from_raw(&ctx, &expected, c"HEAPTEST") }.unwrap();
    let heap = app.heap().unwrap();
    let empty = heap.allocate(0, 4096).unwrap();
    assert!(empty.as_slice().is_empty());
    assert!(matches!(heap.allocate(1, 3), Err(Error::InvalidLayout)));
    assert!(matches!(
        heap.allocate(usize::MAX, 8),
        Err(Error::InvalidLayout)
    ));

    FAIL_COMMIT.store(true, Ordering::Relaxed);
    assert!(matches!(heap.allocate(9000, 8192), Err(Error::OutOfMemory)));
    FAIL_COMMIT.store(false, Ordering::Relaxed);
    assert!(REGIONS.lock().unwrap().iter().all(|r| !r.live));
    let mut buffer = heap.allocate(32, 64).unwrap();
    assert_eq!(buffer.as_slice().as_ptr() as usize % 64, 0);
    assert_eq!(buffer.as_slice(), &[0; 32]);
    buffer.as_mut_slice().fill(0xa5);
    let original = buffer.as_slice().as_ptr();
    FAIL_COMMIT.store(true, Ordering::Relaxed);
    assert_eq!(buffer.resize(2 * 1024 * 1024), Err(Error::OutOfMemory));
    assert_eq!(buffer.as_slice().as_ptr(), original);
    assert_eq!(buffer.as_slice(), &[0xa5; 32]);
    FAIL_COMMIT.store(false, Ordering::Relaxed);
    buffer.resize(2 * 1024 * 1024).unwrap();
    assert_eq!(&buffer.as_slice()[..32], &[0xa5; 32]);
    assert!(buffer.as_slice()[32..].iter().all(|byte| *byte == 0));
    buffer.resize(16).unwrap();
    OWNER.store(43, Ordering::Relaxed);
    assert!(matches!(heap.stats(), Err(Error::Runtime(-2))));
    OWNER.store(42, Ordering::Relaxed);
    GENERATION.store(8, Ordering::Relaxed);
    assert!(matches!(heap.stats(), Err(Error::Runtime(-2))));
    GENERATION.store(7, Ordering::Relaxed);
    assert_eq!(buffer.as_slice(), &[0xa5; 16]);
    buffer.resize(0).unwrap();
    buffer.resize(128).unwrap();
    assert_eq!(buffer.as_slice(), &[0; 128]);
    drop(buffer);
    let aligned = heap.allocate(8192, 8192).unwrap();
    assert_eq!(aligned.as_slice().as_ptr() as usize % 8192, 0);
    drop(aligned);
    assert_eq!(heap.stats().unwrap().get(c"active_allocations"), Some(0));

    let first = heap.allocate(9 * 1024 * 1024, 64).unwrap();
    let second = heap.allocate(9 * 1024 * 1024, 64).unwrap();
    let live = heap.allocate(32, 8).unwrap();
    assert_eq!(unsafe { heap.finish_instance() }, Err(Error::Runtime(1)));
    assert!(matches!(heap.allocate(8, 8), Err(Error::OutOfMemory)));
    drop(live);
    FAIL_RELEASE.store(true, Ordering::Relaxed);
    drop(first);
    drop(second);
    assert_eq!(heap.stats().unwrap().get(c"direct_retiring"), Some(2));
    assert_eq!(unsafe { heap.finish_instance() }, Err(Error::Runtime(2)));
    FAIL_RELEASE.store(false, Ordering::Relaxed);
    assert_eq!(unsafe { heap.finish_instance() }, Ok(()));
    assert!(REGIONS.lock().unwrap().iter().all(|r| !r.live));
    assert!(app.heap().is_err());
}
