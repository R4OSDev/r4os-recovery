use super::*;
pub struct Devices<'a> {
    pub(super) native: *mut c::R4SdkGfxDeviceContext,
    pub(super) _loan: PhantomData<&'a ()>,
    pub(super) _local: PhantomData<*mut ()>,
}
macro_rules! optional{
    ($name:ident,$method:ident,$ty:ty $(,$arg:ident:$at:ty)*)=>{pub fn $name(&self,$($arg:$at),*)->Result<Option<$ty>>{let mut out=<$ty>::default();let r=value(unsafe{c::$method(0,self.native,$($arg,)*&mut out)})?;Ok(if r.flags&1!=0{Some(out)}else{None})}};
}
macro_rules! query{
    ($name:ident,$method:ident,$ty:ty,$ok:literal $(,$arg:ident:$at:ty)*)=>{pub fn $name(&self,$($arg:$at),*)->Result<$ty>{let mut out=<$ty>::default();let rc=code(unsafe{c::$method(0,self.native,$($arg,)*&mut out)})?;if rc==$ok {Ok(out)}else if rc==0 {Err(Error::Unavailable)}else{Err(Error::Raw(rc))}}};
}
impl Devices<'_> {
    query!(
        inventory,
        R4SdkGfxDeviceContext_deviceInventorySummary,
        abi::DeviceInventorySummary,
        1
    );
    query!(record,R4SdkGfxDeviceContext_deviceInventoryRecord,abi::DeviceInventoryRecord,1,index:u32);
    optional!(
        memory,
        R4SdkGfxDeviceContext_memorySummary,
        abi::ProgramMemorySummary
    );
    optional!(
        pressure,
        R4SdkGfxDeviceContext_memoryPressure,
        abi::ProgramMemoryPressureSnapshot
    );
    optional!(
        performance,
        R4SdkGfxDeviceContext_performanceSummary,
        abi::ProgramPerformanceSummary
    );
    optional!(
        instrumentation,
        R4SdkGfxDeviceContext_performanceInstrumentation,
        abi::ProgramInstrumentationInfo
    );
    optional!(
        hardware,
        R4SdkGfxDeviceContext_hardwareSummary,
        abi::HardwareSummary
    );
    optional!(
        kernel,
        R4SdkGfxDeviceContext_kernelVersion,
        abi::KernelVersion
    );
    optional!(
        display,
        R4SdkGfxDeviceContext_displayState,
        abi::DisplayStateInfo
    );
    query!(cpu_capabilities,R4SdkGfxDeviceContext_cpuCapabilities,abi::CpuCapabilitiesInfo,0,cpu:u32);
    /// # Safety
    /// Passive reads, explicit work/callback lifetimes and exact device/epoch
    /// admission retain their original contracts; status never grants work.
    pub unsafe fn native(&self) -> *mut c::R4SdkGfxDeviceContext {
        self.native
    }
}
