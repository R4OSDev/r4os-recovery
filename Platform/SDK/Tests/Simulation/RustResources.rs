#![cfg(test)]
use core::sync::atomic::{AtomicUsize, Ordering};
use r4os_sdk::{
    App, ImportSpec, StartupInfo, abi,
    path::FilePath,
    resources::{
        Error, IoBuffers, IoControl, IoOperation, Resources, StopFlag, Timeout, Wait, WriteKind,
    },
};
use std::alloc::{GlobalAlloc, Layout, System};
struct Tracking;
static WATCH: AtomicUsize = AtomicUsize::new(0);
static FREED: AtomicUsize = AtomicUsize::new(0);
unsafe impl GlobalAlloc for Tracking {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        unsafe { System.alloc(layout) }
    }
    unsafe fn dealloc(&self, p: *mut u8, layout: Layout) {
        if p.addr() == WATCH.load(Ordering::Relaxed) {
            FREED.fetch_add(1, Ordering::Relaxed);
        }
        unsafe { System.dealloc(p, layout) }
    }
}
#[global_allocator]
static ALLOCATOR: Tracking = Tracking;
unsafe extern "C" {
    fn sdk_resource_c_app_case() -> i32;
    fn sdk_resource_prefix_case() -> i32;
    fn sdk_resource_table(sys: *mut abi::R4XStartR4Sys, desk: *mut abi::R4XStartR4Desk);
    fn sdk_resource_mode(mode: i32);
    fn sdk_resource_slots() -> u32;
    fn sdk_resource_last_kind() -> u32;
    fn sdk_resource_complete_dropped() -> i32;
}
unsafe extern "C" fn entry(value: u64) -> i32 {
    value as i32
}
#[test]
fn current_lifecycle_partial_progress_and_retained_native_buffers() {
    assert_eq!(unsafe { sdk_resource_c_app_case() }, 0);
    assert_eq!(unsafe { sdk_resource_prefix_case() }, 0);
    let mut sys = abi::R4XStartR4Sys::default();
    let mut desk = abi::R4XStartR4Desk::default();
    unsafe { sdk_resource_table(&mut sys, &mut desk) };
    let imports = [
        abi::R4XStartImport {
            group_id: abi::R4LGroup::r4sys.0,
            min_version: 1,
            resolved_version: 1,
            flags: abi::r4xstart_import_flag_group_interface,
            module_name: c"R4SYS".as_ptr() as u64,
            symbol_name: c"Query".as_ptr() as u64,
            table: core::ptr::from_ref(&sys) as u64,
        },
        abi::R4XStartImport {
            group_id: abi::R4LGroup::r4desk.0,
            min_version: 1,
            resolved_version: 1,
            flags: abi::r4xstart_import_flag_group_interface,
            module_name: c"R4DESK".as_ptr() as u64,
            symbol_name: c"Query".as_ptr() as u64,
            table: core::ptr::from_ref(&desk) as u64,
        },
    ];
    let ctx = abi::R4XStartContext {
        app_class: abi::R4XStartAppClass::console.0,
        instance_id: 42,
        flags: abi::r4xstart_flag_imports_valid,
        imports: imports.as_ptr() as u64,
        import_count: 2,
        ..Default::default()
    };
    let expected = StartupInfo {
        app_class: abi::R4XStartAppClass::console,
        required_groups: 2,
        imports: &[
            ImportSpec {
                module_name: b"R4SYS",
                symbol_name: b"Query",
                minimum: 1,
                optional: false,
                group_id: abi::R4LGroup::r4sys.0,
                magic: sys.magic,
                version: sys.abi_version,
                size: sys.size,
            },
            ImportSpec {
                module_name: b"R4DESK",
                symbol_name: b"Query",
                minimum: 1,
                optional: false,
                group_id: abi::R4LGroup::r4desk.0,
                magic: desk.magic,
                version: desk.abi_version,
                size: desk.size,
            },
        ],
    };
    let app = unsafe { App::from_raw(&ctx, &expected, c"RESOURCES") }.unwrap();
    let resources = Resources::new(&app).unwrap();
    assert!(resources.available());
    assert_eq!(resources.timeout_ticks(Timeout::Poll), Ok(0));
    assert_eq!(resources.timeout_ticks(Timeout::Forever), Ok(u64::MAX));
    assert_eq!(resources.timeout_ticks(Timeout::AfterNanos(1)), Ok(1));
    assert_eq!(resources.capacity().unwrap().available_cpus, 3);
    let path = FilePath::parse(b"C:\\TEST.R4X").unwrap();
    let mut process = resources
        .spawn(&path, c"", abi::LaunchPolicy::console)
        .unwrap();
    assert!(process.owned());
    assert!(process.valid());
    let old = process.handle();
    let mut borrowed = resources.open_process(old.instance_id).unwrap();
    assert!(!borrowed.owned());
    assert_eq!(process.status().unwrap().unwrap().id, 41);
    assert!(matches!(
        process.wait_ready(Timeout::Poll),
        Ok(Wait::TimedOut)
    ));
    assert_eq!(process.reap(), Ok(Wait::WouldBlock));
    assert_eq!(
        borrowed.wait(Timeout::Forever),
        Err(Error::Raw(abi::err_not_owned))
    );
    process.request_close().unwrap();
    assert!(
        matches!(borrowed.wait_ready(Timeout::Forever),Ok(Wait::Completed(v)) if v.handle.generation==old.generation)
    );
    let mut text = [0; 8];
    assert_eq!(
        process.completion_read(0, &mut text),
        Ok(Wait::Completed(2))
    );
    assert_eq!(&text[..2], b"OK");
    assert_eq!(process.reap(), Ok(Wait::Completed(0)));
    assert!(!process.valid());
    let mut second = resources
        .spawn_with_console_host(
            &path,
            c"",
            abi::LaunchPolicy::console,
            abi::ConsoleHostKind::terminal_window,
        )
        .unwrap();
    assert_ne!(second.handle().generation, old.generation);
    assert!(matches!(
        borrowed.status(),
        Err(Error::Raw(abi::program_handle_error_stale))
    ));
    second.kill().unwrap();
    assert_eq!(second.wait(Timeout::Forever), Ok(Wait::Completed(-9)));
    let mut join = unsafe { resources.create_compute_worker(entry, 17, 0) }.unwrap();
    assert_eq!(join.status().unwrap().thread_id, 51);
    assert_eq!(join.join(Timeout::Poll), Ok(Wait::TimedOut));
    assert!(join.valid());
    assert_eq!(join.join(Timeout::Forever), Ok(Wait::Completed(17)));
    assert!(!join.valid());
    let mut current = resources.current_thread().unwrap();
    assert!(!current.owned());
    let mut cpus = [0; 3];
    let placement = current.placement(&mut cpus);
    assert_eq!(placement.raw_code, 37);
    assert_eq!(placement.info.cpu_word_count, 2);
    assert_eq!(cpus[..2], [1, 1 << 13]);
    let request = abi::ThreadPlacementRequest {
        work_class: abi::thread_placement_class_batch,
        ..Default::default()
    };
    assert_eq!(current.set_placement(&request, &cpus[..2]), 41);
    let mut region = resources
        .reserve_vm(4096, 4096, abi::vm_region_flags_default)
        .unwrap();
    region.commit(0, 4096).unwrap();
    unsafe { sdk_resource_mode(3) };
    assert_eq!(
        region.release(),
        Err(Error::Raw(abi::vm_error_owner_mismatch))
    );
    assert!(region.valid());
    unsafe { sdk_resource_mode(0) };
    assert_eq!(region.info().unwrap().len, 4096);
    region.decommit(0, 4096).unwrap();
    region.release().unwrap();
    assert!(!region.valid());
    let mut notification = resources.notification().unwrap();
    assert_eq!(notification.handle(), 0x1122334455667788);
    let sequence = notification.sequence().unwrap();
    assert_eq!(
        notification.wait(sequence, Timeout::Poll),
        Ok(Wait::TimedOut)
    );
    notification.notify(1).unwrap();
    assert_eq!(
        notification.wait(sequence, Timeout::Poll),
        Ok(Wait::Completed(()))
    );
    unsafe { sdk_resource_mode(2) };
    assert_eq!(
        notification.close(),
        Err(Error::Raw(abi::notification_error_release))
    );
    assert!(notification.valid());
    unsafe { sdk_resource_mode(0) };
    notification.close().unwrap();
    assert!(!notification.valid());
    let key = 0x1122334455667788;
    assert_eq!(resources.local_get(key), Ok(0));
    let p = resources.local_publish(key, 0x8877665544332211).unwrap();
    assert!(p.inserted);
    assert_eq!(p.value, 0x8877665544332211);
    let p = resources.local_publish(key, 4).unwrap();
    assert!(!p.inserted);
    assert_eq!(p.value, 0x8877665544332211);
    // The same canonical C/Rust lifecycle facade keeps exact fields and page
    // restart semantics, without requesting diagnostic inventory as admission.
    let mut lifecycle = resources.lifecycle().unwrap();
    assert_eq!(lifecycle.cursor().snapshot_generation, 91);
    let mut light = [abi::ProgramLifecycleSnapshot::default(); 2];
    let light_page = lifecycle.programs(&mut light).unwrap();
    assert_eq!(light_page.returned, 1);
    assert_eq!(
        light_page.kind,
        abi::program_inventory_kind_lifecycle as u32
    );
    assert_eq!(light[0].handle.generation, 0x1234567887654321);
    assert_eq!(light[0].task_id, 73);
    assert_eq!(
        (
            light[0].role,
            light[0].app_class,
            light[0].state,
            light[0].flags
        ),
        (2, 1, 1, 2)
    );
    assert_eq!((light[0].exit_code, light[0].window_id), (-17, -1));
    let exact = light[0];
    unsafe { sdk_resource_mode(4) };
    assert_eq!(
        lifecycle.programs(&mut light).unwrap().status,
        abi::program_inventory_status_restart as i32
    );
    assert_eq!(light[0].handle.generation, exact.handle.generation);
    assert_eq!(lifecycle.cursor().program_after_generation, 0);
    unsafe { sdk_resource_mode(7) };
    assert!(matches!(
        resources.lifecycle(),
        Err(Error::Raw(abi::program_handle_error_would_block))
    ));
    unsafe { sdk_resource_mode(8) };
    assert!(matches!(
        lifecycle.programs(&mut light),
        Err(Error::InvalidProvider)
    ));
    unsafe { sdk_resource_mode(0) };
    assert!(matches!(
        lifecycle.programs(&mut []),
        Err(Error::Raw(abi::program_handle_error_invalid))
    ));
    let mut inventory = resources.inventory().unwrap();
    assert_eq!(inventory.cursor().snapshot_generation, 77);
    assert_eq!(
        inventory
            .programs(&mut [abi::ProgramInstanceSnapshot::default(); 2])
            .unwrap()
            .returned,
        1
    );
    assert_eq!(
        inventory
            .tasks(&mut [abi::ProgramTaskSnapshot::default(); 2])
            .unwrap()
            .returned,
        1
    );
    assert_eq!(
        inventory
            .threads(&mut [abi::ProgramThreadSnapshot::default(); 2])
            .unwrap()
            .returned,
        1
    );
    unsafe { sdk_resource_mode(4) };
    assert_eq!(
        inventory
            .programs(&mut [abi::ProgramInstanceSnapshot::default(); 1])
            .unwrap()
            .status,
        abi::program_inventory_status_restart as i32
    );
    assert_eq!(inventory.cursor().snapshot_generation, 78);
    unsafe { sdk_resource_mode(0) };
    for (kind, expected) in [
        (WriteKind::Replace, 3),
        (WriteKind::Append, 4),
        (WriteKind::At(17), 5),
        (WriteKind::Stream(17), 6),
    ] {
        let mut io = resources
            .io_write(&path, Box::from(*b"DATA1234"), kind, 0)
            .unwrap_or_else(|e| panic!("{:?}", e.error));
        assert!(matches!(io.wait(Timeout::Poll), Ok(Wait::TimedOut)));
        assert_eq!(io.close(), Err(Error::Raw(abi::io_error_busy)));
        assert!(io.take_buffers().is_err());
        assert!(
            matches!(io.wait(Timeout::Forever),Ok(Wait::Completed(info)) if info.processed_bytes==4&&info.requested_bytes==8)
        );
        assert!(io.take_buffers().is_err());
        io.close().unwrap();
        assert!(matches!(io.take_buffers(),Ok(IoBuffers::Bytes(bytes)) if bytes[..4]==*b"DATA"));
        assert_eq!(unsafe { sdk_resource_last_kind() }, expected);
    }
    for offset in [None, Some(17)] {
        let mut io = resources
            .io_read(&path, vec![0; 8].into_boxed_slice(), offset, 0)
            .unwrap_or_else(|e| panic!("{:?}", e.error));
        assert!(matches!(io.wait(Timeout::Forever), Ok(Wait::Completed(_))));
        io.close().unwrap();
        assert!(matches!(io.take_buffers(),Ok(IoBuffers::Bytes(bytes)) if bytes[..4]==*b"DATA"));
    }
    let mut bytes = [0; 8];
    let mut io = unsafe {
        resources.io(
            Some(&path),
            IoOperation::Read {
                buffer: &mut bytes,
                offset: None,
            },
            0,
        )
    }
    .unwrap();
    assert!(io.buffers_held());
    assert_eq!(
        io.release_buffers(),
        Err(Error::Raw(abi::err_buffer_in_use))
    );
    assert!(matches!(io.wait(Timeout::Forever), Ok(Wait::Completed(_))));
    io.close().unwrap();
    io.release_buffers().unwrap();
    drop(io);
    assert_eq!(&bytes[..4], b"DATA");
    for control in [
        IoControl::FileInfo,
        IoControl::FileLock {
            offset: 17,
            length: 31,
        },
        IoControl::StreamBegin,
        IoControl::StreamFinish { expected: 31 },
        IoControl::StreamAbort,
    ] {
        let mut io = resources.io_control(&path, control, 0).unwrap();
        assert!(matches!(io.wait(Timeout::Forever), Ok(Wait::Completed(_))));
        io.close().unwrap();
    }
    let mut io = resources
        .io_service(
            91,
            37,
            Box::from(*b"PING"),
            Box::default(),
            vec![0; 8].into_boxed_slice(),
            17,
            0,
        )
        .unwrap_or_else(|e| panic!("{:?}", e.error));
    assert!(matches!(io.wait(Timeout::Forever), Ok(Wait::Completed(_))));
    io.close().unwrap();
    assert!(
        matches!(io.take_buffers(),Ok(IoBuffers::Service {header,response,..}) if header.op==37&&response[..4]==*b"DATA")
    );
    unsafe { sdk_resource_mode(6) };
    let mut io = resources
        .io_read(&path, vec![0; 8].into_boxed_slice(), None, 0)
        .unwrap_or_else(|e| panic!("{:?}", e.error));
    assert!(
        matches!(io.wait(Timeout::Forever),Ok(Wait::Completed(info)) if info.state==abi::io_state_failed&&info.result == -7&&info.processed_bytes==2)
    );
    io.close().unwrap();
    drop(io);
    unsafe { sdk_resource_mode(5) };
    let err = resources
        .io_read(&path, vec![0; 8].into_boxed_slice(), None, 0)
        .err()
        .unwrap();
    assert_eq!(err.error, Error::Raw(abi::io_error_no_slots));
    assert!(matches!(err.buffers,IoBuffers::Bytes(b) if b.len()==8));
    for forget in [false, true] {
        unsafe { sdk_resource_mode(if forget { 0 } else { 1 }) };
        let buffer = vec![0; 8].into_boxed_slice();
        let ptr = buffer.as_ptr() as *mut u8;
        WATCH.store(ptr.addr(), Ordering::Relaxed);
        FREED.store(0, Ordering::Relaxed);
        let io = resources
            .io_read(&path, buffer, None, 0)
            .unwrap_or_else(|e| panic!("{:?}", e.error));
        if forget {
            core::mem::forget(io)
        } else {
            drop(io)
        }
        assert_eq!(
            FREED.load(Ordering::Relaxed),
            0,
            "native pending buffer was freed"
        );
        assert_eq!(unsafe { sdk_resource_complete_dropped() }, 0);
        let recovered = unsafe { Box::from_raw(core::ptr::slice_from_raw_parts_mut(ptr, 8)) };
        assert_eq!(&recovered[..4], b"DATA");
        drop(recovered);
        assert_eq!(FREED.load(Ordering::Relaxed), 1);
        WATCH.store(0, Ordering::Relaxed);
    }
    let mut stop = StopFlag::new();
    assert!(!stop.requested());
    stop.request();
    assert!(stop.requested());
    stop.clear();
    assert!(!stop.requested());
    assert_eq!(unsafe { sdk_resource_slots() }, 0);
}
