//! Prepared borrowed text metrics through the shared native SDK owner.
use crate::{abi, c_facades as c, platform2::Context};
use core::{
    marker::PhantomData,
    mem::{self, MaybeUninit},
};
pub type Key = c::R4SdkTextMetricsKey;
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Error {
    pub code: i32,
    pub required_count: u32,
}
impl Error {
    fn new(code: i32) -> Self {
        Self {
            code,
            required_count: 0,
        }
    }
}
pub struct Progress {
    pub key: Key,
    pub required_count: u32,
    pub count: u32,
    pub complete: bool,
    pub in_call: bool,
    pub error_code: i32,
}
fn exact(code: i32) -> Result<(), Error> {
    if code == 0 {
        Ok(())
    } else {
        Err(Error::new(code))
    }
}
fn progress(raw: c::R4SdkTextMetricsProgress) -> Progress {
    Progress {
        key: raw.key,
        required_count: raw.required_count,
        count: raw.count,
        complete: raw.flags & 1 != 0,
        in_call: raw.flags & 2 != 0,
        error_code: raw.error_code,
    }
}
fn empty_progress() -> c::R4SdkTextMetricsProgress {
    c::R4SdkTextMetricsProgress {
        key: Key {
            source_address: 0,
            text_revision: 0,
            font_revision: 0,
            font_id: 0,
            text_bytes: 0,
        },
        required_count: 0,
        count: 0,
        flags: 0,
        error_code: 0,
    }
}
/// Source, whole storage, Context/provider code and returned views remain
/// borrowed. A mutable prepare/reset/current-font validation cannot coexist
/// with a subsequently used view. This stores no Kernel font handle/lease.
pub struct Cache<'a> {
    raw: c::R4SdkTextMetrics,
    context: &'a Context<'a>,
    _source: &'a str,
    storage: &'a mut [MaybeUninit<abi::FontAdvance2>],
    _local: PhantomData<*mut ()>,
}
impl<'a> Cache<'a> {
    pub(crate) fn native(&self) -> *const c::R4SdkTextMetrics {
        &self.raw
    }
    pub fn new(
        context: &'a Context<'a>,
        source: &'a str,
        storage: &'a mut [MaybeUninit<abi::FontAdvance2>],
    ) -> Result<Self, Error> {
        if source.len() > abi::font_metrics2_max_bytes as usize
            || storage.len() > abi::font_metrics2_max_bytes as usize
        {
            return Err(Error::new(-102));
        }
        let address = context
            .lookup(
                3,
                mem::offset_of!(abi::generation2::R4XStartR4Draw2, font_prefix_metrics2) as u32,
            )
            .map_err(Error::new)?;
        let call: abi::R4DrawFns::font_prefix_metrics2 = unsafe { mem::transmute(address) };
        let provider = c::R4SdkTextMetricsProvider {
            measure: Some(call),
        };
        let input = c::R4SdkWireSpan {
            address: source.as_ptr() as u64,
            length: source.len() as u64,
        };
        let output = c::R4SdkWireSpan {
            address: storage.as_ptr() as u64,
            length: mem::size_of_val(storage) as u64,
        };
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkTextMetricsInit(
                input,
                output,
                storage.len() as u32,
                provider,
                raw.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            context,
            _source: source,
            storage,
            _local: PhantomData,
        })
    }
    pub fn prepare(&mut self, text_revision: u64, font_id: u32) -> Result<Progress, Error> {
        let mut output = empty_progress();
        let code = unsafe {
            c::R4SdkTextMetricsPrepare(&mut self.raw, text_revision, font_id, &mut output)
        };
        if code != 0 {
            return Err(Error {
                code,
                required_count: output.required_count,
            });
        }
        Ok(progress(output))
    }
    pub fn progress(&self) -> Result<Progress, Error> {
        let mut output = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkTextMetricsGetProgress(&self.raw, output.as_mut_ptr()) })?;
        Ok(progress(unsafe { output.assume_init() }))
    }
    pub fn key(&self) -> Result<Key, Error> {
        let mut output = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkTextMetricsGetKey(&self.raw, output.as_mut_ptr()) })?;
        Ok(unsafe { output.assume_init() })
    }
    pub fn rows(&self) -> Result<&[abi::FontAdvance2], Error> {
        let mut output = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkTextMetricsGetView(&self.raw, output.as_mut_ptr()) })?;
        let span = unsafe { output.assume_init() };
        let size = mem::size_of::<abi::FontAdvance2>() as u64;
        if !span.length.is_multiple_of(size)
            || span.length / size > self.storage.len() as u64
            || span.address != self.storage.as_ptr() as u64
        {
            return Err(Error::new(-105));
        }
        if span.length == 0 {
            return Ok(&[]);
        }
        // The exact shared owner validated and initialized these complete
        // projected rows. Caller storage/code remains borrowed for this view.
        Ok(unsafe {
            core::slice::from_raw_parts(
                span.address as *const abi::FontAdvance2,
                (span.length / size) as usize,
            )
        })
    }
    pub fn hit(&self, key: Key, x: i32) -> Result<u32, Error> {
        let mut output = 0;
        exact(unsafe { c::R4SdkTextMetricsHit(&self.raw, key, x, &mut output) })?;
        Ok(output)
    }
    pub fn reset(&mut self) -> Result<(), Error> {
        exact(unsafe { c::R4SdkTextMetricsReset(&mut self.raw) })
    }
    /// A fresh checked empty-source observation, never a full-text scan.
    /// Failure/mismatch discards this cache. No later-render atomicity claim.
    pub fn validate_font(&mut self) -> Result<(), Error> {
        let key = self.key()?;
        let observed = (|| {
            let address = self
                .context
                .lookup(
                    3,
                    mem::offset_of!(abi::generation2::R4XStartR4Draw2, font_prefix_metrics2) as u32,
                )
                .map_err(Error::new)?;
            let call: abi::R4DrawFns::font_prefix_metrics2 = unsafe { mem::transmute(address) };
            let mut info = MaybeUninit::uninit();
            exact(unsafe {
                call(
                    key.font_id,
                    core::ptr::null(),
                    0,
                    core::ptr::null_mut(),
                    0,
                    info.as_mut_ptr(),
                )
            })?;
            let info = unsafe { info.assume_init() };
            if info.version != abi::font_metrics2_version
                || info.size as usize != mem::size_of::<abi::FontAdvanceInfo2>()
                || info.font_id != key.font_id
                || info.font_revision == 0
                || info.text_bytes != 0
                || info.count != 0
                || info.required_count != 0
                || info.flags != abi::font_metrics2_flag_complete
                || info.reserved0 != 0
            {
                return Err(Error::new(-105));
            }
            if info.font_revision != key.font_revision {
                return Err(Error::new(abi::font_metrics2_stale));
            }
            Ok(())
        })();
        if observed.is_err() {
            self.reset()?;
        }
        observed
    }
}
