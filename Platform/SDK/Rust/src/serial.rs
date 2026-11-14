//! Exact serial identities and partial transfer results, using the C owner.
use crate::{
    App, abi, c_facades as c,
    storage::{Error, Result},
};
pub use abi::{
    SerialConfig as Config, SerialPortInfo as PortInfo, SerialStatus as Status,
    SerialTransfer as Transfer,
};
use core::marker::PhantomData;
pub struct Serial<'a> {
    raw: c::R4Serial,
    _loan: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
pub struct IoResult {
    pub code: i32,
    pub info: Transfer,
}
impl<'a> Serial<'a> {
    pub fn new2(app: &'a crate::app2::App<'_>) -> Result<Self> {
        let mut snapshot = unsafe { core::mem::zeroed() };
        let rc = unsafe { c::R4SdkAppFacade2(app.native_context(), &app.memory, &mut snapshot) };
        if rc != 0 {
            return Err(Error::Raw(rc));
        }
        let mut raw = unsafe { core::mem::zeroed() };
        let rc = unsafe { c::r4serial_init(&snapshot.devices, &mut raw) };
        if rc != 0 {
            return Err(Error::Raw(rc));
        }
        Ok(Self {
            raw,
            _loan: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn new(app: &'a App<'_>) -> Result<Self> {
        Self::new2(app)
    }
    pub fn count(&self) -> u32 {
        unsafe { c::r4serial_count(&self.raw) }
    }
    pub fn port_at(&self, index: u32) -> Result<PortInfo> {
        let mut info = PortInfo::default();
        let rc = unsafe { c::r4serial_port_at(&self.raw, index, &mut info) };
        if rc == 0 {
            Ok(info)
        } else {
            Err(Error::Raw(rc))
        }
    }
    pub fn find(&self, number: u32) -> Option<PortInfo> {
        (0..self.count())
            .filter_map(|i| self.port_at(i).ok())
            .find(|info| info.com_number == number)
    }
    pub fn open(&self, port: &PortInfo, config: &Config) -> Result<Port<'_>> {
        let mut handle = 0;
        let rc = unsafe {
            c::r4serial_open(
                &self.raw,
                port.port_id,
                port.generation,
                config,
                &mut handle,
            )
        };
        if rc != 0 {
            return Err(Error::Raw(rc));
        }
        if handle == 0 {
            return Err(Error::InvalidProvider);
        }
        Ok(Port {
            owner: self,
            handle,
        })
    }
    pub fn open_number(&self, number: u32, config: &Config) -> Result<Port<'_>> {
        self.open(
            &self
                .find(number)
                .ok_or(Error::Raw(abi::serial_error_not_found))?,
            config,
        )
    }
}
pub struct Port<'a> {
    owner: &'a Serial<'a>,
    handle: u64,
}
impl Port<'_> {
    pub fn handle(&self) -> u64 {
        self.handle
    }
    pub fn configure(&mut self, config: &Config) -> i32 {
        unsafe { c::r4serial_configure(&self.owner.raw, self.handle, config) }
    }
    pub fn read(&mut self, out: &mut [u8], ticks: u64) -> IoResult {
        let mut info = Transfer::default();
        let code = if out.len() > abi::serial_max_transfer_bytes as usize {
            abi::serial_error_too_large
        } else {
            unsafe {
                c::r4serial_read(
                    &self.owner.raw,
                    self.handle,
                    out.as_mut_ptr(),
                    out.len() as u32,
                    ticks,
                    &mut info,
                )
            }
        };
        IoResult { code, info }
    }
    pub fn write(&mut self, bytes: &[u8], ticks: u64) -> IoResult {
        let mut info = Transfer::default();
        let code = if bytes.len() > abi::serial_max_transfer_bytes as usize {
            abi::serial_error_too_large
        } else {
            unsafe {
                c::r4serial_write(
                    &self.owner.raw,
                    self.handle,
                    bytes.as_ptr(),
                    bytes.len() as u32,
                    ticks,
                    &mut info,
                )
            }
        };
        IoResult { code, info }
    }
    pub fn drain(&mut self, ticks: u64) -> i32 {
        unsafe { c::r4serial_drain(&self.owner.raw, self.handle, ticks) }
    }
    pub fn status(&self) -> Result<Status> {
        let mut info = Status::default();
        let rc = unsafe { c::r4serial_status(&self.owner.raw, self.handle, &mut info) };
        if rc == 0 {
            Ok(info)
        } else {
            Err(Error::Raw(rc))
        }
    }
    pub fn cancel(&self) -> i32 {
        unsafe { c::r4serial_cancel(&self.owner.raw, self.handle) }
    }
    pub fn close(&mut self, flags: u32, ticks: u64) -> i32 {
        if self.handle == 0 {
            return 0;
        }
        let rc = unsafe { c::r4serial_close(&self.owner.raw, self.handle, flags, ticks) };
        if rc == 0 {
            self.handle = 0;
        }
        rc
    }
}
impl Drop for Port<'_> {
    fn drop(&mut self) {
        let _ = self.close(0, 0);
    }
}
