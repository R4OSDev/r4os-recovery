//! Copied optional AUDSVC input; explicit channel and capture lifetime.
use crate::{
    abi as a,
    platform2::Context,
    resources::Timeout,
    time::checked::{self, BudgetValue, ClockSample, DeadlineBudget},
};
use core::{marker::PhantomData, mem, ptr};
pub type Source = a::AudioCaptureSourceId;
pub type Format = a::AudioCaptureFormat;
pub type Handle = a::AudioCaptureHandle;
pub type Reply = a::AudioCaptureReply;
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Error(pub i32);
fn exact(rc: i32) -> Result<(), Error> {
    if rc == 0 { Ok(()) } else { Err(Error(rc)) }
}
fn same(x: &Handle, y: &Handle) -> bool {
    x.service.instance_id == y.service.instance_id
        && x.service.reserved == y.service.reserved
        && x.service.generation == y.service.generation
        && x.source.registration == y.source.registration
        && x.source.source == y.source.source
        && x.source.generation == y.source.generation
        && x.stream == y.stream
        && x.generation == y.generation
}
pub struct Client<'a> {
    call: a::R4SysFns::service_call,
    disconnect: a::R4SysFns::service_close,
    clock: a::R4SysFns::monotonic_clock,
    channel: u32,
    client_generation: u64,
    transport_ticks: u64,
    _borrow: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
impl<'a> Client<'a> {
    pub fn connect(context: &'a Context<'_>, ticks: u64) -> Result<Self, Error> {
        if ticks == 0 {
            return Err(Error(a::audio_capture_error_invalid));
        }
        let own_id = u32::try_from(context.raw().instance_id)
            .map_err(|_| Error(a::audio_capture_error_invalid))?;
        if own_id == 0 {
            return Err(Error(a::audio_capture_error_invalid));
        }
        let lookup = |offset: usize| {
            context
                .lookup(1, offset as u32)
                .map_err(|_| Error(a::audio_capture_error_unsupported))
        };
        let open = lookup(mem::offset_of!(
            a::generation2::R4XStartR4Sys2,
            service_open
        ))?;
        let call = lookup(mem::offset_of!(
            a::generation2::R4XStartR4Sys2,
            service_call
        ))?;
        let disconnect = lookup(mem::offset_of!(
            a::generation2::R4XStartR4Sys2,
            service_close
        ))?;
        let clock = lookup(mem::offset_of!(
            a::generation2::R4XStartR4Sys2,
            monotonic_clock
        ))?;
        let process = lookup(mem::offset_of!(
            a::generation2::R4XStartR4Sys2,
            program_open_handle
        ))?;
        let open = unsafe { mem::transmute::<u64, a::R4SysFns::service_open>(open) };
        let process = unsafe { mem::transmute::<u64, a::R4SysFns::program_open_handle>(process) };
        let mut identity = a::ProgramProcessHandle::default();
        exact(unsafe { process(own_id, &mut identity) })?;
        if identity.instance_id != own_id || identity.reserved != 0 || identity.generation == 0 {
            return Err(Error(a::audio_capture_error_stale));
        }
        let mut endpoint = a::ServiceInfo::default();
        exact(unsafe { open(c"AUDSVC".as_ptr().cast(), &mut endpoint) })?;
        if endpoint.handle == 0 {
            return Err(Error(a::audio_capture_error_unsupported));
        }
        Ok(Self {
            call: unsafe { mem::transmute::<u64, a::R4SysFns::service_call>(call) },
            disconnect: unsafe { mem::transmute::<u64, a::R4SysFns::service_close>(disconnect) },
            clock: unsafe { mem::transmute::<u64, a::R4SysFns::monotonic_clock>(clock) },
            channel: endpoint.handle,
            client_generation: identity.generation,
            transport_ticks: ticks,
            _borrow: PhantomData,
            _local: PhantomData,
        })
    }
    /// Closes only the transport. Stream Stop/Close remains explicit; no Drop.
    pub fn disconnect(&mut self) -> Result<(), Error> {
        if self.channel == 0 {
            return Err(Error(a::audio_capture_error_stale));
        }
        let rc = unsafe { (self.disconnect)(self.channel) };
        if rc >= 0 {
            self.channel = 0;
        }
        exact(rc)
    }
    pub fn sample(&self) -> Result<ClockSample, Error> {
        let mut info = a::MonotonicClockInfo::default();
        if unsafe { (self.clock)(&mut info) } <= 0 {
            return Err(Error(a::audio_capture_error_clock_changed));
        }
        ClockSample::from_info(&info).map_err(|_| Error(a::audio_capture_error_clock_changed))
    }
    fn request(
        &self,
        mut q: a::AudioCaptureRequest,
        bytes: &mut [u8],
        ticks: u64,
    ) -> Result<Reply, Error> {
        if self.channel == 0 || ticks == 0 || bytes.len() > a::audio_capture_max_read_bytes as usize
        {
            return Err(Error(a::audio_capture_error_invalid));
        }
        q.client_generation = self.client_generation;
        q.buffer_bytes = if q.op == a::audio_capture_op_read {
            bytes.len() as u32
        } else {
            0
        };
        let mut payload = [0u8; mem::size_of::<Reply>() + a::audio_capture_max_read_bytes as usize];
        let mut header = a::ServiceMessageHeader::default();
        let rc = unsafe {
            (self.call)(
                self.channel,
                a::audio_capture_op_service,
                ptr::from_ref(&q).cast(),
                mem::size_of_val(&q) as u32,
                &mut header,
                payload.as_mut_ptr(),
                payload.len() as u32,
                ticks,
            )
        };
        if rc < 0 {
            return Err(Error(
                if q.op == a::audio_capture_op_catalog || q.op == a::audio_capture_op_query {
                    rc
                } else {
                    a::audio_capture_error_unknown_outcome
                },
            ));
        }
        if header.status == a::service_api_result_bad_op {
            return Err(Error(a::audio_capture_error_unsupported));
        }
        if header.status != 0 {
            return Err(Error(if header.status < 0 {
                header.status
            } else {
                a::audio_capture_error_invalid
            }));
        }
        if (rc as usize) < mem::size_of::<Reply>() {
            return Err(Error(a::audio_capture_error_provider));
        }
        // All fields are fixed integers/byte arrays, with no invalid bit patterns.
        let r = unsafe { ptr::read_unaligned(payload.as_ptr().cast::<Reply>()) };
        if r.version != 1
            || r.size as usize != mem::size_of::<Reply>()
            || r.reserved != 0
            || r.result > 0
            || r.flags & !31 != 0
            || r.bytes as usize > bytes.len()
            || r.bytes as usize + mem::size_of::<Reply>() != rc as usize
            || r.result < 0 && (r.bytes != 0 || r.frames != 0)
        {
            return Err(Error(a::audio_capture_error_provider));
        }
        if r.bytes > 0
            && (q.op != a::audio_capture_op_read
                || r.format.frame_bytes == 0
                || r.frames > q.frames
                || u64::from(r.frames) * u64::from(r.format.frame_bytes) != u64::from(r.bytes))
        {
            return Err(Error(a::audio_capture_error_provider));
        }
        if q.op >= a::audio_capture_op_read && !same(&q.handle, &r.handle) {
            return Err(Error(a::audio_capture_error_stale));
        }
        if r.flags & a::audio_capture_reply_hardware_timestamp == 0 && r.first_timestamp != 0 {
            return Err(Error(a::audio_capture_error_provider));
        }
        let start = mem::size_of::<Reply>();
        bytes[..r.bytes as usize].copy_from_slice(&payload[start..start + r.bytes as usize]);
        Ok(r)
    }
    pub fn catalog(&self, index: u64) -> Result<Reply, Error> {
        self.request(
            a::AudioCaptureRequest {
                op: a::audio_capture_op_catalog,
                handle: Handle {
                    source: Source {
                        source: index,
                        ..Default::default()
                    },
                    ..Default::default()
                },
                ..Default::default()
            },
            &mut [],
            self.transport_ticks,
        )
    }
    pub fn open(&self, source: Source, format: Format, queue_frames: u32) -> Result<Reply, Error> {
        self.request(
            a::AudioCaptureRequest {
                op: a::audio_capture_op_open,
                handle: Handle {
                    source,
                    ..Default::default()
                },
                format,
                queue_frames,
                ..Default::default()
            },
            &mut [],
            self.transport_ticks,
        )
    }
    pub fn query(&self, id: Handle) -> Result<Reply, Error> {
        self.control(a::audio_capture_op_query, id)
    }
    pub fn stop(&self, id: Handle) -> Result<Reply, Error> {
        self.control(a::audio_capture_op_stop, id)
    }
    pub fn close(&self, id: Handle) -> Result<Reply, Error> {
        self.control(a::audio_capture_op_close, id)
    }
    fn control(&self, op: u32, id: Handle) -> Result<Reply, Error> {
        self.request(
            a::AudioCaptureRequest {
                op,
                handle: id,
                ..Default::default()
            },
            &mut [],
            self.transport_ticks,
        )
    }
    pub fn read_poll(&self, id: Handle, frames: u32, bytes: &mut [u8]) -> Result<Reply, Error> {
        self.request(
            a::AudioCaptureRequest {
                op: a::audio_capture_op_read,
                handle: id,
                frames,
                ..Default::default()
            },
            bytes,
            self.transport_ticks,
        )
    }
}
/// A copied explicit read budget. Caller pumps steps and waits outside owner
/// locks. Cancel/timeout retains the capture handle and all physical resources.
pub struct Read {
    id: Handle,
    budget: DeadlineBudget,
    mode: u32,
    cancelled: bool,
    done: bool,
}
impl Read {
    pub fn new(id: Handle, sample: ClockSample, timeout: Timeout) -> Result<Self, Error> {
        let mode = match timeout {
            Timeout::Poll | Timeout::AfterNanos(0) => 0,
            Timeout::AfterNanos(_) => 1,
            Timeout::Forever => 2,
        };
        let budget = DeadlineBudget::new(sample, timeout)
            .map_err(|_| Error(a::audio_capture_error_clock_changed))?;
        Ok(Self {
            id,
            budget,
            mode,
            cancelled: false,
            done: false,
        })
    }
    pub fn cancel(&mut self) {
        self.cancelled = true;
    }
    pub fn step(
        &mut self,
        client: &Client<'_>,
        frames: u32,
        bytes: &mut [u8],
    ) -> Result<Reply, Error> {
        if self.cancelled {
            self.done = true;
            return Err(Error(a::audio_capture_error_cancelled));
        }
        if self.done {
            return Err(Error(a::audio_capture_error_stale));
        }
        let sample = match client.sample() {
            Ok(s) => s,
            Err(e) => {
                self.done = true;
                return Err(e);
            }
        };
        let remaining = match self.budget.remaining(sample) {
            Ok(v) => v,
            Err(_) => {
                self.done = true;
                return Err(Error(a::audio_capture_error_clock_changed));
            }
        };
        if self.mode == 1 && remaining == BudgetValue::Poll {
            self.done = true;
            return Err(Error(a::audio_capture_error_timed_out));
        }
        let ticks = match remaining {
            BudgetValue::Finite(n) => {
                let value = match checked::timeout_ticks(Timeout::AfterNanos(n), sample.tick_hz()) {
                    Ok(BudgetValue::Finite(t)) => t,
                    Ok(BudgetValue::Poll) => 1,
                    _ => {
                        self.done = true;
                        return Err(Error(a::audio_capture_error_clock_changed));
                    }
                };
                client.transport_ticks.min(value).max(1)
            }
            _ => client.transport_ticks,
        };
        let r = client.request(
            a::AudioCaptureRequest {
                op: a::audio_capture_op_read,
                handle: self.id,
                frames,
                ..Default::default()
            },
            bytes,
            ticks,
        );
        if !matches!(&r,Ok(v)if v.result==a::audio_capture_error_would_block) || self.mode == 0 {
            self.done = true;
        }
        r
    }
}
