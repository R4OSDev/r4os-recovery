#![no_std]
extern crate alloc;
use alloc::{boxed::Box, vec::Vec};
use core::sync::atomic::{AtomicPtr, AtomicU32, AtomicU64, Ordering};
use r4os_sdk::{
    App, abi,
    path::FilePath,
    resources::{IoBuffers, IoControl, Resources, StopFlag, Timeout, Wait, WriteKind},
    storage::{Presence, System},
};
static API: AtomicPtr<abi::R4XStartR4Sys> = AtomicPtr::new(core::ptr::null_mut());
static SIGNAL: AtomicU64 = AtomicU64::new(0);
static SEEN_CPUS: AtomicU64 = AtomicU64::new(0);
static READY: AtomicU32 = AtomicU32::new(0);
static STOP: StopFlag = StopFlag::new();
unsafe extern "C" {
    fn sdk54_c_resources(context: *const abi::R4XStartContext, path: *const u8) -> i32;
}
unsafe extern "C" fn worker(seed: u64) -> i32 {
    // Same bounded Vec/Box byte pattern as the qualified worker case in50.
    let mut bytes = Vec::new();
    for i in 0..4096 {
        bytes.push((i as u64 ^ seed) as u8);
    }
    let boxed = Box::new([0xa5u8; 128]);
    if bytes[4095] != (4095 ^ seed) as u8 || boxed[0] != 0xa5 {
        return 21;
    }
    let api = unsafe { &*API.load(Ordering::Acquire) };
    let query: abi::R4SysFns::notification_query =
        unsafe { core::mem::transmute(api.notification_query) };
    let wait: abi::R4SysFns::notification_wait =
        unsafe { core::mem::transmute(api.notification_wait) };
    let notification = SIGNAL.load(Ordering::Acquire);
    let current: abi::R4SysFns::thread_current_handle =
        unsafe { core::mem::transmute(api.thread_current_handle) };
    let placement: abi::R4SysFns::thread_placement_get =
        unsafe { core::mem::transmute(api.thread_placement_get) };
    let mut handle = abi::ProgramJoinHandle::default();
    let mut info = abi::ThreadPlacementInfo::default();
    let mut cpus = [0u64; 2];
    if unsafe { current(&mut handle) } != 0
        || unsafe { placement(&handle, &mut info, cpus.as_mut_ptr(), 2) } < 0
    {
        return 24;
    }
    if info.running_cpu < 64 {
        SEEN_CPUS.fetch_or(1u64 << info.running_cpu, Ordering::Release);
    }
    READY.fetch_add(1, Ordering::Release);
    while !STOP.requested() {
        let mut observed = 0;
        if unsafe { query(notification, &mut observed) } != 0 {
            return 22;
        }
        if STOP.requested() {
            break;
        }
        let raw = unsafe { wait(notification, observed, 100) };
        if raw != 0 && raw != abi::notification_timeout {
            return 23;
        }
    }
    0
}
fn close_io(app: &App<'_>, io: &mut r4os_sdk::resources::OwnedIo<'_>) {
    for _ in 0..2000 {
        match io.close() {
            Ok(()) => return,
            Err(r4os_sdk::resources::Error::Raw(abi::io_error_busy)) => app.sleep(1),
            Err(e) => panic!("close {:?}", e),
        }
    }
    panic!("I/O close did not acknowledge");
}
fn main(app: &mut App<'_>) -> i32 {
    if app.args() == b"child" {
        app.write("[SDK54] child output\n");
        return 42;
    }
    if app.args() == b"child-c" {
        return 43;
    }
    if app.args() == b"child-sync" {
        return 44;
    }
    if app.args() == b"hold" {
        while !app.should_close() {
            app.sleep(1);
        }
        return 7;
    }
    let resources = Resources::new(app).unwrap();
    let file = FilePath::parse(b"C:\\TEMP\\SDKRS54\\R54.BIN").unwrap();
    if app.args() == b"pending-panic" {
        let io = resources
            .io_read(&file, alloc::vec![0;128*1024].into_boxed_slice(), None, 0)
            .unwrap_or_else(|e| panic!("{:?}", e.error));
        core::mem::forget(io);
        panic!("SDK54 deliberate pending-I/O exit");
    }
    assert_eq!(resources.capacity().unwrap().available_cpus, 4);
    let system = System::new(app).unwrap();
    let files = system.files();
    let directory = FilePath::parse(b"C:\\TEMP\\SDKRS54").unwrap();
    assert_eq!(
        files.create_directory(&directory).unwrap(),
        Presence::Present
    );
    let payload = b"DATA\0\xa5\x5a\xff";
    let mut io = resources
        .io_write(&file, Box::from(*payload), WriteKind::Replace, 0)
        .unwrap_or_else(|e| panic!("{:?}", e.error));
    assert!(
        matches!(io.wait(Timeout::AfterNanos(5_000_000_000)),Ok(Wait::Completed(info))if info.result==8&&info.processed_bytes==8)
    );
    assert!(io.take_buffers().is_err());
    close_io(app, &mut io);
    drop(io.take_buffers().unwrap());
    let mut io = resources
        .io_read(&file, alloc::vec![0;64].into_boxed_slice(), None, 0)
        .unwrap_or_else(|e| panic!("{:?}", e.error));
    assert!(
        matches!(io.wait(Timeout::AfterNanos(5_000_000_000)),Ok(Wait::Completed(info))if info.result==8&&info.processed_bytes==8)
    );
    close_io(app, &mut io);
    assert!(matches!(io.take_buffers(),Ok(IoBuffers::Bytes(bytes))if bytes[..8]==*payload));
    let mut info = resources.io_control(&file, IoControl::FileInfo, 0).unwrap();
    assert!(
        matches!(info.wait(Timeout::AfterNanos(5_000_000_000)),Ok(Wait::Completed(v))if v.result>=0)
    );
    info.close().unwrap();
    let key = 0x53544f5253353441;
    assert_eq!(resources.local_get(key), Ok(0));
    let publication = resources.local_publish(key, 0x1122334455667788).unwrap();
    assert!(publication.inserted);
    let publication = resources.local_publish(key, 2).unwrap();
    assert!(!publication.inserted);
    assert_eq!(publication.value, 0x1122334455667788);
    let mut region = resources
        .reserve_vm(8192, 4096, abi::vm_region_flags_default)
        .unwrap();
    assert!(region.commit(8192, 4096).is_err());
    assert!(region.valid());
    region.commit(0, 8192).unwrap();
    let view = region.info().unwrap();
    assert!(view.base != 0 && view.len >= 8192);
    if view.guard_len != 0 {
        assert!(
            view.base + view.len <= view.guard_base
                || view.guard_base + view.guard_len <= view.base
        );
    }
    unsafe {
        let bytes = region.bytes_mut(0, 8192).unwrap();
        assert!(bytes.iter().all(|b| *b == 0));
        bytes[0] = 0x12;
        bytes[8191] = 0x34;
    }
    region.decommit(4096, 4096).unwrap();
    region
        .commit_flags(4096, 4096, abi::vm_commit_flag_resident)
        .unwrap();
    unsafe {
        let bytes = region.bytes_mut(0, 8192).unwrap();
        assert_eq!(bytes[0], 0x12);
        assert_eq!(bytes[8191], 0);
    }
    region.release().unwrap();
    assert!(!region.valid());
    let mut notification = resources.notification().unwrap();
    let sequence = notification.sequence().unwrap();
    assert_eq!(
        notification.wait(sequence, Timeout::Poll),
        Ok(Wait::TimedOut)
    );
    API.store(
        core::ptr::from_ref(app.system_api().unwrap()).cast_mut(),
        Ordering::Release,
    );
    SIGNAL.store(notification.handle(), Ordering::Release);
    let mut workers = [const { None }; 4];
    for (i, slot) in workers.iter_mut().enumerate() {
        *slot = Some(unsafe { resources.create_compute_worker(worker, i as u64, 0) }.unwrap());
    }
    for _ in 0..2000 {
        if READY.load(Ordering::Acquire) == 4 {
            break;
        }
        app.sleep(1);
    }
    assert_eq!(READY.load(Ordering::Acquire), 4);
    assert_ne!(
        SEEN_CPUS.load(Ordering::Acquire) & 14,
        0,
        "workers did not execute on APs"
    );
    for join in workers.iter_mut().flatten() {
        let mut cpus = [0; 2];
        let placement = join.placement(&mut cpus);
        assert!(placement.raw_code >= 0);
        assert!(placement.info.cpu_word_count > 0);
        assert_ne!(cpus[0] & 15, 0);
        let request = abi::ThreadPlacementRequest {
            work_class: abi::thread_placement_class_batch,
            flags: abi::thread_placement_flag_default_cpus,
            ..Default::default()
        };
        assert!(join.set_placement(&request, &[]) >= 0);
        assert!(join.valid());
    }
    STOP.request();
    notification.notify(4).unwrap();
    for join in workers.iter_mut().flatten() {
        assert_eq!(
            join.join(Timeout::AfterNanos(5_000_000_000)),
            Ok(Wait::Completed(0))
        );
        assert!(!join.valid());
    }
    notification.close().unwrap();
    let mut buffer = [0; 1024];
    let length = resources.module_path(&mut buffer).unwrap();
    let module = FilePath::parse(&buffer[..length]).unwrap();
    let mut child = resources
        .spawn(&module, c"child", abi::LaunchPolicy::console)
        .unwrap();
    let identity = child.handle();
    let mut borrowed = resources.borrow_process(&identity).unwrap();
    assert!(!borrowed.owned());
    assert!(borrowed.reap().is_err());
    let completed = match child
        .wait_ready(Timeout::AfterNanos(5_000_000_000))
        .unwrap()
    {
        Wait::Completed(c) => c,
        _ => panic!("child wait"),
    };
    assert_eq!(completed.exit_code, 42);
    assert_eq!(completed.handle.generation, identity.generation);
    let mut output = [0; 128];
    assert!(matches!(child.completion_read(0,&mut output),Ok(Wait::Completed(n))if n>0));
    assert_eq!(child.reap(), Ok(Wait::Completed(42)));
    assert!(!child.valid());
    assert!(!matches!(borrowed.status(), Ok(Some(_))));
    let mut child = resources
        .spawn(&module, c"hold", abi::LaunchPolicy::console)
        .unwrap();
    child.request_close().unwrap();
    assert_eq!(
        child.wait(Timeout::AfterNanos(5_000_000_000)),
        Ok(Wait::Completed(7))
    );
    let mut child = resources
        .spawn(&module, c"hold", abi::LaunchPolicy::console)
        .unwrap();
    child.kill().unwrap();
    let completed = match child
        .wait_ready(Timeout::AfterNanos(5_000_000_000))
        .unwrap()
    {
        Wait::Completed(c) => c,
        _ => panic!("killed child"),
    };
    assert_eq!(completed.exit_reason, abi::program_exit_reason_killed);
    assert_eq!(child.reap(), Ok(Wait::Completed(completed.exit_code)));
    let mut child = resources
        .spawn(&module, c"pending-panic", abi::LaunchPolicy::console)
        .unwrap();
    assert_eq!(
        child.wait(Timeout::AfterNanos(5_000_000_000)),
        Ok(Wait::Completed(-101))
    );
    assert_eq!(resources.run(&module, c"child-sync"), 0);
    assert_eq!(
        unsafe { sdk54_c_resources(app.start_context(), module.as_c_str().as_ptr().cast()) },
        0
    );
    let mut inventory = resources.inventory().unwrap();
    let page = inventory
        .programs(&mut [abi::ProgramInstanceSnapshot::default(); 8])
        .unwrap();
    assert!(page.returned <= 8);
    assert_eq!(files.delete(&file).unwrap(), Presence::Present);
    assert_eq!(
        files
            .delete(&FilePath::parse(b"C:\\TEMP\\SDKRS54\\C54.BIN").unwrap())
            .unwrap(),
        Presence::Present
    );
    assert_eq!(
        files.delete_directory(&directory).unwrap(),
        Presence::Present
    );
    app.write("[SDK54] Rust/C resources, four joined AP workers, VM and retained I/O PASS\n");
    0
}
r4os_sdk::app!(main);
