#![cfg(test)]
use r4os_sdk::{abi, driver::Driver};
unsafe extern "C" {
    fn sdk67_driver_oracle() -> *const abi::DriverApi;
    fn sdk67_driver_terminal();
    fn sdk67_driver_counts() -> u32;
    fn sdk67_driver_c_case() -> i32;
}
unsafe extern "C" fn work(_: usize) -> i32 {
    0
}
unsafe extern "C" fn irq(_: u8, _: usize) -> u32 {
    0
}
#[test]
fn exact_dma_irq_and_work_tokens_survive_refusal_and_drop_does_not_quiesce() {
    assert_eq!(unsafe { sdk67_driver_c_case() }, 0);
    let driver = unsafe { Driver::from_raw(sdk67_driver_oracle()) }.unwrap();
    let mut bytes = [0u8; 16];
    let mut dma = unsafe { driver.pin(bytes.as_mut_ptr(), bytes.len()) }.unwrap();
    dma.map(
        &abi::DmaConstraints::default(),
        abi::dma_direction_bidirectional,
    )
    .unwrap();
    assert_eq!(unsafe { dma.close() }, Err(-6));
    assert_eq!(dma.mapping().unwrap().handle, 31);
    assert_eq!(dma.pin_identity().handle, 17);
    assert_eq!(unsafe { sdk67_driver_counts() }, 1);
    unsafe { dma.close() }.unwrap();
    assert!(dma.mapping().is_none());
    assert_eq!(dma.pin_identity().handle, 0);
    assert_eq!(unsafe { sdk67_driver_counts() }, 18);
    let mut w = unsafe { driver.work(work, 71, 0) }.unwrap();
    assert_eq!(w.release(), Err(abi::driver_work_owner_busy));
    assert_eq!(w.handle(), 19);
    unsafe { sdk67_driver_terminal() };
    assert_eq!(w.release(), Err(-6));
    assert_eq!(w.handle(), 19);
    w.release().unwrap();
    assert_eq!(w.handle(), 0);
    let mut i = unsafe { driver.irq(9, irq, 71, 1) }.unwrap();
    assert_eq!(unsafe { i.close() }, Err(-6));
    unsafe { i.close() }.unwrap();
    let before = unsafe { sdk67_driver_counts() };
    // Losing the token cannot make an unacknowledged callback/DMA safe to free.
    let dropped = unsafe { driver.work(work, 71, 0) }.unwrap();
    drop(dropped);
    assert_eq!(unsafe { sdk67_driver_counts() }, before);
}
