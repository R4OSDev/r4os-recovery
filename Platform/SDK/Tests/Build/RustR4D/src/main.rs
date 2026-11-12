#![no_std]
use core::sync::atomic::{AtomicPtr, AtomicU32, Ordering};
use r4os_sdk::{
    abi,
    driver::{Driver, raw as c},
};
static API: AtomicPtr<abi::DriverApi> = AtomicPtr::new(core::ptr::null_mut());
static HITS: AtomicU32 = AtomicU32::new(0);
#[repr(C, align(4096))]
struct Buffer([u8; 4096]);
static mut BUFFER: Buffer = Buffer([0; 4096]);
unsafe extern "C" {
    fn sdk67_backends_init(api: *const abi::DriverApi, rust: u32) -> i32;
    fn sdk67_backends_shutdown() -> i32;
}
unsafe extern "C" fn irq(line: u8, cookie: usize) -> u32 {
    if line == 0 && cookie == 68 {
        HITS.fetch_add(1, Ordering::Relaxed);
    }
    0
}
unsafe extern "C" fn work(cookie: usize) -> i32 {
    if cookie == 68 { 168 } else { -1 }
}
unsafe extern "C" fn task(cookie: usize) -> i32 {
    if cookie == 68 { 268 } else { -1 }
}
fn raw_result(s: c::R4SdkDriverSlot) -> Result<i32, i32> {
    if s.status < 0 {
        Err(s.status)
    } else {
        let n = s.bits as i32;
        if n < 0 { Err(n) } else { Ok(n) }
    }
}
unsafe fn run(api: *const abi::DriverApi) -> Result<(), i32> {
    let driver = unsafe { Driver::from_raw(api) }?;
    API.store(api.cast_mut(), Ordering::Release);
    let heap = driver.heap()?;
    let before = heap.stats()?;
    let mut allocation = heap.allocate(64, 16)?;
    unsafe { allocation.release() }?;
    let after = heap.stats()?;
    if before.allocations != after.allocations || before.bytes != after.bytes {
        return Err(-20);
    }
    let mut pci = abi::PciDeviceInfo::default();
    raw_result(unsafe {
        c::R4SdkDriverContext_pciFindByClass(0, driver.native(), 2, 0, 0, &mut pci)
    })?;
    if pci.vendor_id == 0xffff {
        return Err(-21);
    }
    let mut dma = unsafe { driver.pin(core::ptr::addr_of_mut!(BUFFER).cast(), 4096) }?;
    let constraints = abi::DmaConstraints {
        dma_mask: 0xffff_ffff,
        boundary: 4096,
        max_segment_bytes: 4096,
        alignment: 16,
        max_segments: 4,
        flags: abi::dma_flag_coherent | abi::dma_flag_allow_bounce,
        ..Default::default()
    };
    dma.map(&constraints, abi::dma_direction_bidirectional)?;
    let stale = *dma.mapping().ok_or(-22)?;
    raw_result(unsafe {
        c::R4SdkDriverContext_syncDmaForDevice(0, driver.native(), dma.mapping().ok_or(-23)?)
    })?;
    raw_result(unsafe {
        c::R4SdkDriverContext_syncDmaForCpu(0, driver.native(), dma.mapping().ok_or(-24)?)
    })?;
    unsafe { dma.close() }?;
    if raw_result(unsafe { c::R4SdkDriverContext_syncDmaForCpu(0, driver.native(), &stale) })
        .is_ok()
    {
        return Err(-25);
    }
    let mut registration = unsafe { driver.irq(0, irq, 68, abi::irq_flag_shared) }?;
    driver.wait_ticks(3);
    unsafe { registration.close() }?;
    if HITS.load(Ordering::Relaxed) == 0 {
        return Err(-26);
    }
    let mut ticket = unsafe { driver.work(work, 68, 0) }?;
    let stale_ticket = ticket.handle();
    if ticket.wait(200)? != 168 {
        return Err(-27);
    }
    ticket.release()?;
    let mut status = abi::DriverCompletionStatus::default();
    if raw_result(unsafe {
        c::R4SdkDriverContext_completionStatus(0, driver.native(), stale_ticket, &mut status)
    })
    .is_ok()
    {
        return Err(-28);
    }
    let threads = driver.threads()?;
    let mut thread = unsafe { threads.start(task, 68, abi::driver_thread_flag_parallel) }?;
    if thread.join(200)? != 268 {
        return Err(-29);
    }
    let status = thread.status()?;
    if status.owner_epoch == 0 || status.task_generation == 0 {
        return Err(-30);
    }
    thread.release()?;
    let rc = unsafe { sdk67_backends_init(api, 1) };
    if rc != 0 {
        return Err(rc);
    }
    driver.log(
        c"PASS D67R init PCI DMA-stale IRQ-ended work-released task-generation hotremove-A B-alive",
    );
    Ok(())
}
unsafe extern "C" fn init(api: *const abi::DriverApi) -> i32 {
    match unsafe { run(api) } {
        Ok(()) => 0,
        Err(n) => n,
    }
}
unsafe extern "C" fn shutdown() -> i32 {
    let api = API.load(Ordering::Acquire);
    let driver = match unsafe { Driver::from_raw(api) } {
        Ok(x) => x,
        Err(n) => return n,
    };
    let rc = unsafe { sdk67_backends_shutdown() };
    if rc == 0 {
        driver.log(c"PASS D67R shutdown callbacks-closed=2");
    }
    rc
}
r4os_sdk::driver_entry!(init, shutdown);
