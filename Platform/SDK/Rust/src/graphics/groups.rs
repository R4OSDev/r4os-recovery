use super::{Error, NonNull, PhantomData, Result, abi, c, positive};
macro_rules! group {
    ($name:ident) => {
        pub struct $name<'a> {
            draw: NonNull<c::R4SdkGuiDrawContext>,
            _loan: PhantomData<&'a ()>,
            _local: PhantomData<*mut ()>,
        }
        impl $name<'_> {
            pub(super) fn new(draw: NonNull<c::R4SdkGuiDrawContext>) -> Self {
                Self {
                    draw,
                    _loan: PhantomData,
                    _local: PhantomData,
                }
            }
        }
    };
}
macro_rules! query {
    ($name:ident, $native:ident, $out:ty $(, $arg:ident : $ty:ty)*) => {
        pub fn $name(&self, $($arg: $ty),*) -> Result<$out> {
            let mut out = <$out>::default();
            positive(unsafe { c::$native(0, self.draw.as_ptr(), $($arg,)* &mut out) })?;
            Ok(out)
        }
    };
}
macro_rules! action {
    ($name:ident, $native:ident $(, $arg:ident : $ty:ty)*) => {
        pub fn $name(&self, $($arg: $ty),*) -> Result<()> {
            positive(unsafe { c::$native(0, self.draw.as_ptr(), $($arg),*) })
        }
    };
}
group!(Buffers);
impl Buffers<'_> {
    query!(create, R4SdkGuiDrawContext_gfxBufferCreate, abi::GfxBufferReference, descriptor: &abi::GfxBufferDescriptor);
    query!(describe, R4SdkGuiDrawContext_gfxBufferDescribe, abi::GfxBufferDescriptor, reference: &abi::GfxBufferHandle);
    query!(import, R4SdkGuiDrawContext_gfxBufferImport, abi::GfxBufferReference, reference: &abi::GfxBufferHandle);
    query!(
        stats,
        R4SdkGuiDrawContext_gfxBufferStats,
        abi::GfxBufferStats
    );
    query!(memory_budget, R4SdkGuiDrawContext_gfxMemoryBudget, abi::GfxDeviceBudgetState, input: &abi::GfxDeviceBudgetRequest);
    action!(release, R4SdkGuiDrawContext_gfxBufferRelease, reference: &abi::GfxBufferHandle);
    action!(unmap, R4SdkGuiDrawContext_gfxBufferUnmap, lease: &abi::GfxBufferHandle);
    /// Mapping receipt only. No safe Rust slice is inferred from a native
    /// address. Aliasing/cache/retention and exact Unmap ACK remain explicit.
    pub fn map(
        &self,
        reference: &abi::GfxBufferHandle,
        access: u32,
        offset: u64,
        length: u64,
        persistent: bool,
    ) -> Result<abi::GfxBufferMap> {
        if offset.checked_add(length).is_none() {
            return Err(Error::Length);
        }
        let mut out = abi::GfxBufferMap::default();
        let value = unsafe {
            if persistent {
                c::R4SdkGuiDrawContext_gfxBufferMapPersistent(
                    0,
                    self.draw.as_ptr(),
                    reference,
                    access,
                    offset,
                    length,
                    &mut out,
                )
            } else {
                c::R4SdkGuiDrawContext_gfxBufferMap(
                    0,
                    self.draw.as_ptr(),
                    reference,
                    access,
                    offset,
                    length,
                    &mut out,
                )
            }
        };
        positive(value)?;
        Ok(out)
    }
    /// # Safety
    /// The exact shared-raster read lease remains live through native export.
    pub unsafe fn export_raster(
        &self,
        lease: &abi::GuiSharedRasterLease,
    ) -> Result<abi::GfxBufferReference> {
        let mut out = abi::GfxBufferReference::default();
        positive(unsafe {
            c::R4SdkGuiDrawContext_gfxBufferExportRaster(0, self.draw.as_ptr(), lease, &mut out)
        })?;
        Ok(out)
    }
}
group!(Outputs);
impl Outputs<'_> {
    query!(
        revision,
        R4SdkGuiDrawContext_gfxOutputRevision,
        abi::GfxDisplayRevision
    );
    query!(info, R4SdkGuiDrawContext_gfxOutputInfo, abi::GfxOutputInfo, index: u32);
    query!(mode, R4SdkGuiDrawContext_gfxOutputMode, abi::GfxOutputMode, identity: &abi::GfxOutputId, index: u32);
    query!(edid, R4SdkGuiDrawContext_gfxOutputEdid, abi::GfxEdidBlock, identity: &abi::GfxOutputId, index: u32);
    query!(power, R4SdkGuiDrawContext_gfxOutputPower, abi::GfxOutputPower, identity: &abi::GfxOutputId);
    query!(brightness, R4SdkGuiDrawContext_gfxOutputBrightness, abi::GfxOutputBrightness, identity: &abi::GfxOutputId);
    query!(refresh, R4SdkGuiDrawContext_gfxOutputRefresh, abi::GfxOutputRefresh, target: &abi::GfxOutputTarget);
    query!(target, R4SdkGuiDrawContext_displayOutputTarget, abi::GfxOutputTarget, adapter: u32, head: u32);
    query!(presentation_info, R4SdkGuiDrawContext_displayOutputPresentationInfo, abi::DisplayPresentationInfo, target: &abi::GfxOutputTarget);
    query!(presentation_feedback, R4SdkGuiDrawContext_displayOutputPresentationFeedback, abi::DisplayPresentationStats, target: &abi::GfxOutputTarget, source: &abi::GfxFence);
    query!(
        cursor_info,
        R4SdkGuiDrawContext_displayCursorInfo,
        abi::DisplayCursorInfo
    );
    query!(
        cursor_status,
        R4SdkGuiDrawContext_displayCursorStatus,
        abi::DisplayCursorStatus
    );
}
group!(Queues);
impl Queues<'_> {
    query!(open, R4SdkGuiDrawContext_gfxQueueOpen, abi::GfxQueueHandle, config: &abi::GfxQueueConfig);
    query!(backend, R4SdkGuiDrawContext_gfxQueueBackend, abi::GfxBackendBinding, index: u32);
    pub fn backend_info(&self, index: u32) -> Result<abi::GfxBackendInfo> {
        let mut owner = core::mem::MaybeUninit::uninit();
        super::transport(unsafe {
            c::R4SdkGuiDrawContext_queues(0, self.draw.as_ptr(), owner.as_mut_ptr())
        })?;
        let mut out = abi::GfxBackendInfo::default();
        positive(unsafe {
            c::R4SdkGfxQueueContext_backendInfo(0, owner.as_ptr(), index, &mut out)
        })?;
        Ok(out)
    }
    action!(close, R4SdkGuiDrawContext_gfxQueueClose, queue: &abi::GfxQueueHandle);
    query!(query, R4SdkGuiDrawContext_gfxFenceQuery, abi::GfxFenceStatus, fence: &abi::GfxFence);
    query!(wait, R4SdkGuiDrawContext_gfxFenceWait, abi::GfxFenceStatus, fence: &abi::GfxFence, ticks: u64, wait_for: u32);
    action!(cancel, R4SdkGuiDrawContext_gfxFenceCancel, fence: &abi::GfxFence);
    action!(release, R4SdkGuiDrawContext_gfxFenceRelease, fence: &abi::GfxFence);
    /// # Safety
    /// Retain source/target/dependency resources until their exact native
    /// completion/reset receipts. Pending/Retained/Busy never imply release.
    /// Set an explicit future monotonic deadline_ns; a zero/default deadline
    /// is invalid at the native owner and is never silently replaced here.
    pub unsafe fn submit(
        &self,
        queue: &abi::GfxQueueHandle,
        submission: &abi::GfxSubmission,
    ) -> Result<abi::GfxFenceStatus> {
        let mut out = abi::GfxFenceStatus::default();
        positive(unsafe {
            c::R4SdkGuiDrawContext_gfxQueueSubmit(
                0,
                self.draw.as_ptr(),
                queue,
                submission,
                &mut out,
            )
        })?;
        Ok(out)
    }
}
