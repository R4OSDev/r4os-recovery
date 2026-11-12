use super::{Error, Result, required, scalar, view};
use crate::{abi, c_facades as c};
use core::{marker::PhantomData, mem::MaybeUninit, ops::Range};
pub fn digest<'o>(algorithm: &[u8], input: &[u8], out: &'o mut [u8]) -> Result<&'o [u8]> {
    let v = unsafe {
        c::R4SdkDataCrypto_digest(
            0,
            algorithm.as_ptr(),
            algorithm.len() as u64,
            input.as_ptr(),
            input.len() as u64,
            out.as_mut_ptr(),
            out.len() as u64,
        )
    };
    view(v, out)
}
pub struct Sha256<'c> {
    native: MaybeUninit<c::R4SdkDataSha256>,
    context: Option<*const c::R4SdkDataContext>,
    _context: PhantomData<&'c ()>,
    _local: PhantomData<*mut ()>,
}
impl Sha256<'static> {
    pub fn software() -> Result<Self> {
        Self::open(None)
    }
}
impl Sha256<'_> {
    pub(super) fn open(context: Option<*const c::R4SdkDataContext>) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        super::result(unsafe { c::R4SdkData_hashInit(0, native.as_mut_ptr()) })?;
        Ok(Self {
            native,
            context,
            _context: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn update(&mut self, bytes: &[u8]) -> Result<()> {
        let v = unsafe {
            match self.context {
                Some(ctx) => c::R4SdkData_hashUpdate(
                    0,
                    self.native.as_mut_ptr(),
                    ctx,
                    bytes.as_ptr(),
                    bytes.len() as u64,
                ),
                None => c::R4SdkDataSha256_update(
                    0,
                    self.native.as_mut_ptr(),
                    bytes.as_ptr(),
                    bytes.len() as u64,
                ),
            }
        };
        super::result(v)?;
        Ok(())
    }
    pub fn peek(&self) -> Result<[u8; 32]> {
        let mut out = MaybeUninit::<[u8; 32]>::uninit();
        required(unsafe {
            c::R4SdkDataSha256_peek(0, self.native.as_ptr(), out.as_mut_ptr().cast())
        })?;
        Ok(unsafe { out.assume_init() })
    }
    pub fn finish(mut self) -> Result<[u8; 32]> {
        let mut out = MaybeUninit::<[u8; 32]>::uninit();
        required(unsafe {
            c::R4SdkDataSha256_finalResult(0, self.native.as_mut_ptr(), out.as_mut_ptr().cast())
        })?;
        Ok(unsafe { out.assume_init() })
    }
    pub fn counters(&self) -> Result<(u64, u64)> {
        Ok((
            scalar(unsafe { c::R4SdkDataSha256_get_accepted_blocks(self.native.as_ptr()) })?,
            scalar(unsafe { c::R4SdkDataSha256_get_refused_windows(self.native.as_ptr()) })?,
        ))
    }
}
pub struct Random<'c> {
    native: MaybeUninit<c::R4SdkDataRandomProvider>,
    _context: PhantomData<&'c ()>,
    _local: PhantomData<*mut ()>,
}
impl Random<'_> {
    pub(super) fn open(context: *const c::R4SdkDataContext) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe { c::R4SdkData_entropyProvider(0, context, native.as_mut_ptr()) })?;
        Ok(Self {
            native,
            _context: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn available(&self) -> Result<bool> {
        Ok(scalar(unsafe { c::R4SdkDataRandomProvider_available(0, self.native.as_ptr()) })? != 0)
    }
    /// Failure keeps the owner's secure-zero policy. Availability is a hint;
    /// every hardware batch still needs its own exact OS admission receipt.
    pub fn fill(&mut self, output: &mut [u8]) -> Result<bool> {
        Ok(scalar(unsafe {
            c::R4SdkDataRandomProvider_fill(
                0,
                self.native.as_ptr(),
                output.as_mut_ptr(),
                output.len() as u64,
            )
        })? != 0)
    }
}
pub struct MemoryPolicy {
    native: MaybeUninit<c::R4SdkDataMemoryPolicy>,
}
impl MemoryPolicy {
    pub fn from_info(info: &abi::CpuAccelerationInfo) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe { c::R4SdkDataMemoryPolicy_fromInfo(0, info, native.as_mut_ptr()) })?;
        Ok(Self { native })
    }
    pub fn copy(&self, to: &mut [u8], from: &[u8]) -> Result<()> {
        if to.len() != from.len() {
            return Err(Error::Bounds);
        }
        super::result(unsafe {
            c::R4SdkDataMemoryPolicy_move(
                0,
                self.native.as_ptr(),
                to.as_mut_ptr(),
                to.len() as u64,
                from.as_ptr(),
                from.len() as u64,
            )
        })?;
        Ok(())
    }
    pub fn copy_within(
        &self,
        bytes: &mut [u8],
        source: Range<usize>,
        destination: usize,
    ) -> Result<()> {
        let n = source.end.checked_sub(source.start).ok_or(Error::Bounds)?;
        if source.end > bytes.len() || destination > bytes.len() || n > bytes.len() - destination {
            return Err(Error::Bounds);
        }
        let p = bytes.as_mut_ptr();
        super::result(unsafe {
            c::R4SdkDataMemoryPolicy_move(
                0,
                self.native.as_ptr(),
                p.add(destination),
                n as u64,
                p.add(source.start),
                n as u64,
            )
        })?;
        Ok(())
    }
}
