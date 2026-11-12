//! Checked SDK budgets backed by the same pure arithmetic/poll owner as Zig/C.
//! An elapsed or stopped budget never acknowledges a hardware or callback loan.
use crate::{abi, c_facades as c, resources::Timeout};
use core::{mem::MaybeUninit, ptr};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Error {
    UnknownFrequency,
    InvalidTimeout,
    Overflow,
    ClockUnavailable,
    ClockChanged,
    ClockRegressed,
    InvalidBudget,
}
fn exact(code: i32) -> Result<(), Error> {
    match code {
        0 => Ok(()),
        -1 => Err(Error::UnknownFrequency),
        -2 => Err(Error::InvalidTimeout),
        -3 => Err(Error::Overflow),
        -4 => Err(Error::ClockUnavailable),
        -5 => Err(Error::ClockChanged),
        -6 => Err(Error::ClockRegressed),
        _ => Err(Error::InvalidBudget),
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BudgetValue {
    Poll,
    Finite(u64),
    Forever,
}
fn value(raw: c::R4SdkBudgetValue) -> Result<BudgetValue, Error> {
    match (raw.kind, raw.reserved, raw.value) {
        (0, 0, 0) => Ok(BudgetValue::Poll),
        (1, 0, n) if n != 0 => Ok(BudgetValue::Finite(n)),
        (2, 0, 0) => Ok(BudgetValue::Forever),
        _ => Err(Error::InvalidBudget),
    }
}
#[derive(Clone, Copy)]
pub struct ClockSample {
    raw: c::R4SdkClockSample,
}
impl ClockSample {
    pub(crate) fn raw(self) -> c::R4SdkClockSample {
        self.raw
    }
    pub(crate) fn from_raw(raw: c::R4SdkClockSample) -> Self {
        Self { raw }
    }
    pub fn from_info(info: &abi::MonotonicClockInfo) -> Result<Self, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkClockSampleRead(info, raw.as_mut_ptr()) })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
        })
    }
    pub fn instant_nanoseconds(self) -> u64 {
        self.raw.instant_ns
    }
    pub fn tick_hz(self) -> u32 {
        self.raw.identity.tick_hz
    }
    pub fn milliseconds_to_ticks(self, ms: u64) -> Result<u64, Error> {
        milliseconds_to_ticks(ms, self.tick_hz())
    }
}
pub fn milliseconds_to_ticks(ms: u64, hz: u32) -> Result<u64, Error> {
    let mut ticks = 0;
    exact(unsafe { c::R4SdkMillisecondsToTicksChecked(ms, hz, &mut ticks) })?;
    Ok(ticks)
}
/// The result stays tagged: finite u64::MAX is never changed into Forever.
pub fn timeout_ticks(timeout: Timeout, hz: u32) -> Result<BudgetValue, Error> {
    let mut raw = MaybeUninit::uninit();
    exact(unsafe { c::R4SdkTimeoutTicksChecked(timeout.raw(), hz, raw.as_mut_ptr()) })?;
    value(unsafe { raw.assume_init() })
}
pub struct DeadlineBudget {
    raw: c::R4SdkDeadlineBudget,
}
impl DeadlineBudget {
    pub(crate) fn raw(&self) -> c::R4SdkDeadlineBudget {
        self.raw
    }
    pub fn new(sample: ClockSample, timeout: Timeout) -> Result<Self, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkDeadlineBudgetInit(sample.raw, timeout.raw(), raw.as_mut_ptr()) })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
        })
    }
    pub fn remaining(&mut self, sample: ClockSample) -> Result<BudgetValue, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkDeadlineBudgetRemaining(&mut self.raw, sample.raw, raw.as_mut_ptr())
        })?;
        value(unsafe { raw.assume_init() })
    }
}
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PollContext {
    Task = 0,
    NoSleep = 1,
    Irq = 2,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PollOutcome {
    Proceed,
    Expired,
    Stop,
    ClockUnavailable,
    ClockChanged,
    ClockRegressed,
    InvalidBudget,
}
fn outcome(raw: u32) -> PollOutcome {
    match raw {
        0 => PollOutcome::Proceed,
        1 => PollOutcome::Expired,
        2 => PollOutcome::Stop,
        3 => PollOutcome::ClockUnavailable,
        4 => PollOutcome::ClockChanged,
        5 => PollOutcome::ClockRegressed,
        _ => PollOutcome::InvalidBudget,
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PollLimit {
    Iterations,
    TimeAndIterations(BudgetValue),
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PollRemaining {
    pub limit: PollLimit,
    pub iterations: u64,
    pub outcome: PollOutcome,
}
pub struct DriverPollBudget {
    raw: c::R4SdkDriverPollBudget,
}
impl DriverPollBudget {
    pub fn iterations(count: u64, context: PollContext) -> Result<Self, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkDriverPollIterations(count, context as u32, raw.as_mut_ptr()) })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
        })
    }
    pub fn timed(
        sample: ClockSample,
        timeout: Timeout,
        max_steps: u64,
        context: PollContext,
    ) -> Result<Self, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkDriverPollTimed(
                sample.raw,
                timeout.raw(),
                max_steps,
                context as u32,
                raw.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
        })
    }
    /// Only computes permission for one more caller-owned attempt.
    pub fn step(&mut self, sample: Option<ClockSample>, stop_requested: bool) -> PollOutcome {
        let now = sample.map(|s| s.raw);
        outcome(unsafe {
            c::R4SdkDriverPollStep(
                &mut self.raw,
                now.as_ref().map_or(ptr::null(), |p| p),
                u32::from(stop_requested),
            )
        })
    }
    pub fn remaining(&mut self, sample: Option<ClockSample>) -> Result<PollRemaining, Error> {
        let now = sample.map(|s| s.raw);
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkDriverPollRemaining(
                &mut self.raw,
                now.as_ref().map_or(ptr::null(), |p| p),
                raw.as_mut_ptr(),
            )
        })?;
        let raw = unsafe { raw.assume_init() };
        let limit = match raw.kind {
            0 => PollLimit::Iterations,
            1 => PollLimit::TimeAndIterations(value(raw.time)?),
            _ => return Err(Error::InvalidBudget),
        };
        Ok(PollRemaining {
            limit,
            iterations: raw.iterations,
            outcome: outcome(raw.outcome),
        })
    }
}
