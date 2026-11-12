use super::{boolean, c, slot};
use crate::{
    abi,
    storage::{Error, Result},
};
use core::{marker::PhantomData, mem::MaybeUninit, ptr::NonNull};
/// A borrowed native retained-prefix queue. UTF-8 decoding stays in R4STD.
pub struct InputQueue<'a> {
    native: MaybeUninit<c::R4SdkGuiInputQueue>,
    events: NonNull<abi::ConsoleInputEvent>,
    capacity: usize,
    _loan: PhantomData<&'a mut [abi::ConsoleInputEvent]>,
}
impl<'a> InputQueue<'a> {
    pub fn new(events: &'a mut [abi::ConsoleInputEvent]) -> Result<Self> {
        if events.is_empty() {
            return Err(Error::Length);
        }
        let capacity = events.len();
        let events = NonNull::new(events.as_mut_ptr()).ok_or(Error::Length)?;
        let mut native = MaybeUninit::uninit();
        let r = slot(unsafe {
            c::R4SdkGuiInput_borrowedQueue(0, events.as_ptr(), capacity as _, native.as_mut_ptr())
        })?;
        if r.flags & 1 == 0 {
            return Err(Error::Length);
        }
        Ok(Self {
            native,
            events,
            capacity,
            _loan: PhantomData,
        })
    }
    pub fn append(&mut self, events: &[abi::ConsoleInputEvent]) -> Result<bool> {
        boolean(unsafe {
            c::R4SdkGuiInputQueue_append(
                0,
                self.native.as_mut_ptr(),
                events.as_ptr(),
                events.len() as _,
            )
        })
    }
    pub fn consume(&mut self, count: usize) -> Result<bool> {
        boolean(unsafe { c::R4SdkGuiInputQueue_consume(0, self.native.as_mut_ptr(), count as _) })
    }
    pub fn peek(&self) -> Result<&[abi::ConsoleInputEvent]> {
        let r = slot(unsafe { c::R4SdkGuiInputQueue_peek(0, self.native.as_ptr()) })?;
        if r.length == 0 {
            return Ok(&[]);
        }
        let start = self.events.as_ptr().addr();
        let end = start + self.capacity * core::mem::size_of::<abi::ConsoleInputEvent>();
        let address = r.ptr.addr();
        if r.length as usize > self.capacity
            || address < start
            || address > end
            || r.length as usize > (end - address) / core::mem::size_of::<abi::ConsoleInputEvent>()
            || !(address - start).is_multiple_of(core::mem::size_of::<abi::ConsoleInputEvent>())
        {
            return Err(Error::InvalidProvider);
        }
        Ok(unsafe { core::slice::from_raw_parts(r.ptr.cast(), r.length as usize) })
    }
    pub fn clear(&mut self) -> Result<()> {
        slot(unsafe { c::R4SdkGuiInputQueue_clear(0, self.native.as_mut_ptr()) })?;
        Ok(())
    }
}
