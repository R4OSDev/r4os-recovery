use super::*;
pub struct Power<'a> {
    native: MaybeUninit<c::R4SdkPowerClient>,
    _loan: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
impl Power<'_> {
    pub(super) fn open(
        sys: *mut c::R4SdkGuiSystemContext,
        t: crate::resources::Timeout,
    ) -> Result<Self> {
        let mut out = MaybeUninit::uninit();
        value(unsafe { c::R4SdkPowerClient_open(0, sys, &timeout(t), out.as_mut_ptr()) })?;
        match value(unsafe { c::R4SdkPowerOpen_inspect(out.as_ptr()) })?.bits as u32 {
            c::R4SdkPowerOpen_TAG_client => {
                let mut native = MaybeUninit::uninit();
                value(unsafe { c::R4SdkPowerOpen_get_client(out.as_ptr(), native.as_mut_ptr()) })?;
                Ok(Self {
                    native,
                    _loan: PhantomData,
                    _local: PhantomData,
                })
            }
            c::R4SdkPowerOpen_TAG_failure => Err(Error::Raw(
                value(unsafe { c::R4SdkPowerOpen_get_failure(out.as_ptr()) })?.bits as i32,
            )),
            _ => Err(Error::InvalidProvider),
        }
    }
    pub fn status(&mut self, t: crate::resources::Timeout) -> Result<abi::PowerProfileInfo> {
        let mut r = MaybeUninit::uninit();
        value(unsafe {
            c::R4SdkPowerClient_status(0, self.native.as_mut_ptr(), &timeout(t), r.as_mut_ptr())
        })?;
        reply(r.as_ptr())
    }
    /// Explicit policy mutation may change this machine. Accepted state and
    /// masks are receipts, never proof of physical frequency/energy changes.
    pub fn select(
        &mut self,
        profile: u32,
        sticky: bool,
        t: crate::resources::Timeout,
    ) -> Result<abi::PowerProfileInfo> {
        let mut r = MaybeUninit::uninit();
        value(unsafe {
            c::R4SdkPowerClient_select(
                0,
                self.native.as_mut_ptr(),
                profile,
                u8::from(sticky),
                &timeout(t),
                r.as_mut_ptr(),
            )
        })?;
        reply(r.as_ptr())
    }
    pub fn cpu(
        &self,
        index: u32,
        t: crate::resources::Timeout,
    ) -> Result<abi::PowerCpuProfileInfo> {
        let mut r = MaybeUninit::uninit();
        value(unsafe {
            c::R4SdkPowerClient_cpu(0, self.native.as_ptr(), index, &timeout(t), r.as_mut_ptr())
        })?;
        match value(unsafe { c::R4SdkPowerCpuReply_inspect(r.as_ptr()) })?.bits as u32 {
            c::R4SdkPowerCpuReply_TAG_value => {
                let mut out = abi::PowerCpuProfileInfo::default();
                value(unsafe { c::R4SdkPowerCpuReply_get_value(r.as_ptr(), &mut out) })?;
                Ok(out)
            }
            c::R4SdkPowerCpuReply_TAG_timed_out => Err(Error::Raw(abi::service_api_result_timeout)),
            c::R4SdkPowerCpuReply_TAG_failure => Err(Error::Raw(
                value(unsafe { c::R4SdkPowerCpuReply_get_failure(r.as_ptr()) })?.bits as i32,
            )),
            c::R4SdkPowerCpuReply_TAG_remote_failure => Err(Error::Raw(
                value(unsafe { c::R4SdkPowerCpuReply_get_remote_failure(r.as_ptr()) })?.bits as i32,
            )),
            _ => Err(Error::InvalidProvider),
        }
    }
    /// # Safety
    /// Explicit mutation/retry/epoch policy and this owner's lifetime apply.
    pub unsafe fn native(&mut self) -> *mut c::R4SdkPowerClient {
        self.native.as_mut_ptr()
    }
}
fn reply(r: *const c::R4SdkPowerReply) -> Result<abi::PowerProfileInfo> {
    match value(unsafe { c::R4SdkPowerReply_inspect(r) })?.bits as u32 {
        c::R4SdkPowerReply_TAG_value => {
            let mut out = abi::PowerProfileInfo::default();
            value(unsafe { c::R4SdkPowerReply_get_value(r, &mut out) })?;
            Ok(out)
        }
        c::R4SdkPowerReply_TAG_timed_out => Err(Error::Raw(abi::service_api_result_timeout)),
        c::R4SdkPowerReply_TAG_failure => Err(Error::Raw(
            value(unsafe { c::R4SdkPowerReply_get_failure(r) })?.bits as i32,
        )),
        c::R4SdkPowerReply_TAG_remote_failure => Err(Error::Raw(
            value(unsafe { c::R4SdkPowerReply_get_remote_failure(r) })?.bits as i32,
        )),
        _ => Err(Error::InvalidProvider),
    }
}
