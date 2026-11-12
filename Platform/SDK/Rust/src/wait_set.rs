//! Borrowed Query2 wait-any over the actual native resource owners.
//! Creating task owns configuration/wait. No transfer to another task, no source
//! consumption or work/DMA/buffer-release receipt follows from a batch.
use crate::{abi, platform2, time::checked};
use core::{marker::PhantomData, mem};
pub type Source = abi::WaitSource;
pub type Deadline = abi::WaitSetDeadline;
pub type Event = abi::WaitSetEvent;
pub type Batch = abi::WaitSetBatch;
pub type Request = abi::WaitSourceRequest;
/// Snapshot the current source incarnation without retaining it. Enroll can
/// still return Stale after close. Preserve the returned opaque generation.
pub fn prepare(context: &platform2::Context<'_>, request: Request) -> Result<Source, Error> {
    let address = context
        .lookup(
            1,
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, waitset_source_prepare) as u32,
        )
        .map_err(Error)?;
    let call: abi::R4SysFns::waitset_source_prepare = unsafe { mem::transmute(address) };
    let mut source = Source::default();
    exact(unsafe { call(&request, &mut source) })?;
    Ok(source)
}
pub fn io(request_id: u32, tag: u64) -> Request {
    Request {
        kind: abi::waitset_source_io,
        object: u64::from(request_id),
        user_tag: tag,
        ..Request::default()
    }
}
pub fn process(handle: abi::ProgramProcessHandle, tag: u64) -> Request {
    Request {
        kind: abi::waitset_source_process,
        object: u64::from(handle.instance_id),
        generation: handle.generation,
        flags: u32::from(handle.reserved != 0),
        user_tag: tag,
        ..Request::default()
    }
}
pub fn thread(handle: abi::ProgramJoinHandle, tag: u64) -> Request {
    Request {
        kind: abi::waitset_source_thread,
        object: u64::from(handle.thread_id),
        generation: handle.thread_generation,
        scope_id: u64::from(handle.instance_id),
        scope_generation: handle.instance_generation,
        flags: u32::from(handle.reserved != 0),
        user_tag: tag,
        ..Request::default()
    }
}
pub fn endpoint(handle: u32, tag: u64) -> Request {
    Request {
        kind: abi::waitset_source_service_endpoint,
        object: u64::from(handle),
        user_tag: tag,
        ..Request::default()
    }
}
/// Main GUI only. Worker tasks use IO/Thread/Notification sources and leave
/// ordinary GUI event pumping with the owner. This never grants worker access.
pub fn gui_activity(observed: u64, tag: u64) -> Request {
    Request {
        kind: abi::waitset_source_gui_activity,
        observed_revision: observed,
        user_tag: tag,
        ..Request::default()
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Error(pub i32);
fn exact(code: i32) -> Result<(), Error> {
    if code == 0 { Ok(()) } else { Err(Error(code)) }
}
pub fn notification(handle: u64, observed: u64, tag: u64, stop: bool) -> Source {
    Source {
        kind: abi::waitset_source_notification,
        object: handle,
        observed_revision: observed,
        user_tag: tag,
        flags: if stop {
            abi::waitset_source_flag_stop
        } else {
            0
        },
        ..Source::default()
    }
}
pub fn timer(sample: checked::ClockSample, absolute_ns: u64, tag: u64) -> Result<Source, Error> {
    let key = sample.raw().identity;
    if key.source == 0 || key.generation == 0 || key.tick_hz == 0 {
        return Err(Error(abi::waitset_error_clock_unavailable));
    }
    Ok(Source {
        kind: abi::waitset_source_timer,
        user_tag: tag,
        deadline_ns: absolute_ns,
        clock_source: key.source,
        clock_generation: key.generation,
        event_backend: key.event_backend,
        tick_hz: key.tick_hz,
        ..Source::default()
    })
}
pub fn deadline(budget: &checked::DeadlineBudget) -> Result<Deadline, Error> {
    let budget = budget.raw();
    if budget.kind > 2 || budget.reserved != 0 {
        return Err(Error(abi::waitset_error_invalid));
    }
    if budget.kind != 1 {
        return Ok(Deadline {
            kind: budget.kind,
            ..Deadline::default()
        });
    }
    let key = budget.identity;
    if key.source == 0 || key.generation == 0 || key.tick_hz == 0 {
        return Err(Error(abi::waitset_error_clock_unavailable));
    }
    Ok(Deadline {
        kind: 1,
        absolute_ns: budget.deadline_ns,
        last_ns: budget.last_ns,
        clock_source: key.source,
        clock_generation: key.generation,
        event_backend: key.event_backend,
        tick_hz: key.tick_hz,
        ..Deadline::default()
    })
}
/// Context and tables remain borrowed through every call and Drop. Drop tries
/// Close; a failed backing release stays closed in the kernel for exact task
/// retirement. Use explicit close to observe/retry that error. No Send/Sync.
pub struct WaitSet<'context, 'raw> {
    _context: &'context platform2::Context<'raw>,
    functions: [u64; 6],
    handle: u64,
    _local: PhantomData<*mut ()>,
}
impl<'context, 'raw> WaitSet<'context, 'raw> {
    pub fn new(context: &'context platform2::Context<'raw>, capacity: u32) -> Result<Self, Error> {
        let offsets = [
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, waitset_create),
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, waitset_enroll),
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, waitset_rearm),
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, waitset_remove),
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, waitset_wait),
            mem::offset_of!(abi::generation2::R4XStartR4Sys2, waitset_close),
        ];
        let mut functions = [0; 6];
        for (out, offset) in functions.iter_mut().zip(offsets) {
            *out = context.lookup(1, offset as u32).map_err(Error)?;
        }
        let create: abi::R4SysFns::waitset_create = unsafe { mem::transmute(functions[0]) };
        let mut handle = 0;
        exact(unsafe { create(capacity, &mut handle) })?;
        Ok(Self {
            _context: context,
            functions,
            handle,
            _local: PhantomData,
        })
    }
    pub fn handle(&self) -> u64 {
        self.handle
    }
    pub fn enroll(&mut self, source: &Source) -> Result<u64, Error> {
        let call: abi::R4SysFns::waitset_enroll = unsafe { mem::transmute(self.functions[1]) };
        let mut id = 0;
        exact(unsafe { call(self.handle, source, &mut id) })?;
        Ok(id)
    }
    pub fn rearm(&mut self, id: u64, source: &Source) -> Result<(), Error> {
        let call: abi::R4SysFns::waitset_rearm = unsafe { mem::transmute(self.functions[2]) };
        exact(unsafe { call(self.handle, id, source) })
    }
    pub fn remove(&mut self, id: u64) -> Result<(), Error> {
        let call: abi::R4SysFns::waitset_remove = unsafe { mem::transmute(self.functions[3]) };
        exact(unsafe { call(self.handle, id) })
    }
    pub fn wait(&mut self, limit: &Deadline, events: &mut [Event]) -> Result<Batch, Error> {
        if events.is_empty() || events.len() > abi::waitset_max_sources as usize {
            return Err(Error(abi::waitset_error_invalid));
        }
        let call: abi::R4SysFns::waitset_wait = unsafe { mem::transmute(self.functions[4]) };
        let mut batch = Batch::default();
        exact(unsafe {
            call(
                self.handle,
                limit,
                events.as_mut_ptr(),
                events.len() as u32,
                &mut batch,
            )
        })?;
        Ok(batch)
    }
    pub fn close(&mut self) -> Result<(), Error> {
        if self.handle == 0 {
            return Ok(());
        }
        let call: abi::R4SysFns::waitset_close = unsafe { mem::transmute(self.functions[5]) };
        let code = unsafe { call(self.handle) };
        if code == 0 || code == abi::waitset_error_stale {
            self.handle = 0;
        }
        exact(code)
    }
}
impl Drop for WaitSet<'_, '_> {
    fn drop(&mut self) {
        let _ = self.close();
    }
}
