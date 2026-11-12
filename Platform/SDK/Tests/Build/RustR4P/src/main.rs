#![no_std]
use core::{cell::UnsafeCell, mem::MaybeUninit, num::NonZeroU64, ptr};
use r4os_sdk::{
    abi,
    protocol::{Allocation, Gate, GateError, Lease, Protocol},
};
#[repr(C)]
#[derive(Clone, Copy)]
struct Request {
    epoch: u64,
    value: u64,
    ticket: u64,
}
struct State {
    context: MaybeUninit<Protocol<'static>>,
    gate: Gate,
    allocation: Option<Allocation<'static>>,
    loan: Option<Lease<'static>>,
    sequence: u64,
    pending: u64,
    initialized: bool,
}
struct Shared(UnsafeCell<State>);
// Only the original kernel's per-module serialized PPI callbacks access this
// resident state. No &mut State spans calls into the kernel or caller code.
unsafe impl Sync for Shared {}
static STATE: Shared = Shared(UnsafeCell::new(State {
    context: MaybeUninit::uninit(),
    gate: Gate::new(NonZeroU64::new(0x680052).unwrap()),
    allocation: None,
    loan: None,
    sequence: 0,
    pending: 0,
    initialized: false,
}));
unsafe fn context() -> &'static Protocol<'static> {
    unsafe { &*ptr::addr_of!((*STATE.0.get()).context).cast::<Protocol<'static>>() }
}
unsafe extern "C" fn init(api: *const abi::ProtocolApi) -> i32 {
    let protocol = match unsafe { Protocol::from_raw(api) } {
        Ok(x) => x,
        Err(n) => return n,
    };
    unsafe {
        ptr::addr_of_mut!((*STATE.0.get()).context).write(MaybeUninit::new(protocol));
    }
    let p = unsafe { context() };
    if p.register(c"misc.sdk68.wrong", abi::ProtocolCategory::misc, 0) != -2 {
        return -2;
    }
    if p.register(c"misc.sdk68.rust", abi::ProtocolCategory::misc, 0) != 0
        || p.dependency(c"misc.sdk68.c") != 1
    {
        return -3;
    }
    let allocation = match p.allocate(64, 8) {
        Ok(x) => x,
        Err(n) => return n,
    };
    let pointer = allocation.pointer().unwrap().as_ptr().cast::<u64>();
    for i in 0..8 {
        unsafe { pointer.add(i).write(0) }
    }
    unsafe {
        ptr::addr_of_mut!((*STATE.0.get()).allocation).write(Some(allocation));
        (*STATE.0.get()).initialized = true;
    }
    p.set_status(abi::ProtocolState::active, c"P68R real Rust root");
    p.log(c"PASS P68R Init dependency active wrong-role rejected current PPI borrowed");
    0
}
unsafe extern "C" fn shutdown() -> i32 {
    let s = STATE.0.get();
    if !unsafe { (*s).initialized } {
        return 0;
    }
    let gate = unsafe { &*ptr::addr_of!((*s).gate) };
    match gate.close() {
        Ok(_) => {}
        Err(GateError::Busy) => return -6,
        Err(_) => return -8,
    }
    let mut allocation = unsafe { ptr::addr_of_mut!((*s).allocation).read() };
    if let Some(a) = allocation.as_mut() {
        unsafe { a.release() }
    }
    unsafe { ptr::addr_of_mut!((*s).allocation).write(None) };
    let p = unsafe { context() };
    if p.set_status(abi::ProtocolState::disabled, c"P68R resources closed") != 0 {
        return -9;
    }
    p.log(c"PASS P68R explicit ProtocolShutdown backing=closed calls=0");
    0
}
unsafe extern "C" fn query(out: *mut abi::ProtocolStatus) -> i32 {
    if out.is_null() {
        return -2;
    }
    unsafe {
        out.write(abi::ProtocolStatus {
            state: if unsafe {
                (*STATE.0.get()).initialized && (*STATE.0.get()).allocation.is_none()
            } {
                abi::ProtocolState::disabled.0
            } else {
                abi::ProtocolState::active.0
            },
            ..Default::default()
        })
    };
    0
}
unsafe fn respond(out: *mut abi::ProtocolBuffer, value: Request) -> i32 {
    if out.is_null() {
        return -2;
    }
    let b = unsafe { out.read() };
    if b.data.is_null() || b.capacity < (core::mem::size_of::<Request>() as u32) {
        return -2;
    }
    unsafe {
        b.data.cast::<Request>().write_unaligned(value);
        (*out).len = core::mem::size_of::<Request>() as u32;
    }
    0
}
unsafe extern "C" fn dispatch(
    op: u32,
    input: *const abi::ProtocolBuffer,
    out: *mut abi::ProtocolBuffer,
) -> i32 {
    if op == 4 {
        return unsafe { shutdown() };
    }
    let s = STATE.0.get();
    let gate: &'static Gate = unsafe { &*ptr::addr_of!((*s).gate) };
    if op == 0 {
        return unsafe {
            respond(
                out,
                Request {
                    epoch: gate.epoch(),
                    value: u64::from(gate.active()),
                    ticket: u64::from((*s).allocation.is_some()),
                },
            )
        };
    }
    if input.is_null() {
        return -2;
    }
    let b = unsafe { input.read() };
    if b.data.is_null() || b.len != 24 || b.capacity < b.len {
        return -2;
    }
    let r = unsafe { b.data.cast::<Request>().read_unaligned() };
    if r.epoch != gate.epoch() {
        return -3;
    }
    if op == 1 {
        if out.is_null() || unsafe { (*out).data.is_null() || (*out).capacity < 24 } {
            return -2;
        }
        if unsafe { (*s).pending != 0 || (*s).allocation.is_none() || (*s).sequence == u64::MAX } {
            return -6;
        }
        let loan = match gate.enter() {
            Ok(x) => x,
            Err(_) => return -7,
        };
        let pointer = unsafe {
            (*s).allocation
                .as_ref()
                .unwrap()
                .pointer()
                .unwrap()
                .as_ptr()
                .cast::<u64>()
        };
        unsafe {
            pointer.write(r.value);
            (*s).sequence += 1;
            (*s).pending = (*s).sequence;
            ptr::addr_of_mut!((*s).loan).write(Some(loan));
        }
        return unsafe {
            respond(
                out,
                Request {
                    epoch: gate.epoch(),
                    value: u64::from(gate.active()),
                    ticket: (*s).pending,
                },
            )
        };
    }
    if (op == 2 || op == 3) && unsafe { (*s).pending != 0 && r.ticket == (*s).pending } {
        if out.is_null() || unsafe { (*out).data.is_null() || (*out).capacity < 24 } {
            return -2;
        }
        let pointer = unsafe {
            (*s).allocation
                .as_ref()
                .unwrap()
                .pointer()
                .unwrap()
                .as_ptr()
                .cast::<u64>()
        };
        let value = if op == 2 {
            unsafe { pointer.read() }.wrapping_add(0x52)
        } else {
            0
        };
        let ticket = unsafe { (*s).pending };
        let loan = unsafe { ptr::addr_of_mut!((*s).loan).read() };
        unsafe {
            ptr::addr_of_mut!((*s).loan).write(None);
            (*s).pending = 0;
        }
        drop(loan);
        return unsafe {
            respond(
                out,
                Request {
                    epoch: gate.epoch(),
                    value,
                    ticket,
                },
            )
        };
    }
    -4
}
r4os_sdk::protocol_entry!(init, shutdown, query, dispatch);
