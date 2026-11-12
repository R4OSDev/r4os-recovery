#![cfg(test)]
use core::num::NonZeroU64;
use r4os_sdk::{
    abi,
    protocol::{Gate, GateError, Protocol},
};
unsafe extern "C" {
    fn sdk68_protocol_c_case() -> i32;
    fn sdk68_protocol_oracle() -> *const abi::ProtocolApi;
    fn sdk68_protocol_allocations() -> u32;
    fn sdk68_protocol_releases() -> u32;
}
#[test]
fn current_protocol_arguments_and_exact_logical_close_without_implicit_free() {
    assert_eq!(unsafe { sdk68_protocol_c_case() }, 0);
    let p = unsafe { Protocol::from_raw(sdk68_protocol_oracle()) }.unwrap();
    p.log(c"p");
    p.warn(c"p");
    p.error(c"p");
    assert_eq!(p.register(c"misc.p68", abi::ProtocolCategory::misc, 7), 0);
    assert_eq!(p.set_status(abi::ProtocolState::active, c"p"), 0);
    assert_eq!(p.dependency(c"misc.p68"), 1);
    let mut bytes = [0u8; 8];
    assert_eq!(p.read_file(c"p", &mut bytes), Ok(4));
    assert_eq!(&bytes[..4], b"p68!");
    let mut allocation = p.allocate(64, 16).unwrap();
    assert_eq!(unsafe { sdk68_protocol_allocations() }, 1);
    let mut gate = Gate::new(NonZeroU64::new(71).unwrap());
    let other = Gate::new(NonZeroU64::new(71).unwrap());
    let loan = gate.enter().unwrap();
    assert_eq!(gate.close().unwrap_err(), GateError::Busy);
    assert!(matches!(gate.enter(), Err(GateError::Closed)));
    assert_eq!(unsafe { sdk68_protocol_releases() }, 0);
    drop(loan);
    let receipt = gate.close().unwrap();
    let foreign = other.close().unwrap();
    assert_eq!(
        gate.reset(foreign, NonZeroU64::new(72).unwrap()),
        Err(GateError::Stale)
    );
    gate.reset(receipt, NonZeroU64::new(72).unwrap()).unwrap();
    assert_eq!(gate.epoch(), 72);
    assert_eq!(unsafe { sdk68_protocol_releases() }, 0);
    unsafe { allocation.release() };
    assert_eq!(unsafe { sdk68_protocol_releases() }, 1);
    unsafe { allocation.release() };
    assert_eq!(unsafe { sdk68_protocol_releases() }, 1);
    let unfreed = p.allocate(64, 16).unwrap();
    drop(unfreed);
    assert_eq!(unsafe { sdk68_protocol_releases() }, 1);
}
