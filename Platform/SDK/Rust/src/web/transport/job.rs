extern crate alloc;
use super::{
    App, Error, MaybeUninit, PhantomData, Request, Response, Result, SCRATCH_BYTES, Timeout, c,
    options, required, response, result,
};
use alloc::{boxed::Box, vec, vec::Vec};
/// Owns every address retained by the native worker. Even forgetting this
/// value leaks its backing rather than ending a Rust buffer/callback loan
/// while a thread is still running. Advanced borrowed jobs stay unsafe raw.
pub struct Job {
    native: Box<MaybeUninit<c::R4SdkTransportJobsJob>>,
    _context: Box<MaybeUninit<c::R4SdkTransportContext>>,
    url: Vec<u8>,
    raw: Vec<u8>,
    body: Vec<u8>,
    scratch: Vec<u8>,
    joined: bool,
    _local: PhantomData<*mut ()>,
}
impl Job {
    /// Start a GET with owned request/response storage and the original
    /// absolute timeout. All worker callbacks are native owner machinery;
    /// there are no borrowed user callback states in this safe operation.
    pub fn get(
        app: &App<'_>,
        url: &[u8],
        raw_capacity: usize,
        body_capacity: usize,
        timeout: Timeout,
    ) -> Result<Self> {
        let mut context = Box::<c::R4SdkTransportContext>::new_uninit();
        if required(unsafe {
            c::R4SdkTransport_open(0, context.as_mut_ptr(), app.start_context())
        })?
        .bits
            == 0
        {
            return Err(Error::Unavailable);
        }
        let mut native = Box::<c::R4SdkTransportJobsJob>::new_uninit();
        result(unsafe { c::R4SdkTransport_job(0, native.as_mut_ptr(), context.as_ptr()) })?;
        let mut out = Self {
            native,
            _context: context,
            url: url.to_vec(),
            raw: vec![0; raw_capacity],
            body: vec![0; body_capacity],
            scratch: vec![0; SCRATCH_BYTES],
            joined: false,
            _local: PhantomData,
        };
        let mut request = Request::get(&out.url);
        request.timeout = timeout;
        let options = options(&request)?;
        let started = required(unsafe {
            c::R4SdkTransportJobsJob_start(
                0,
                out.native.as_mut_ptr(),
                out.url.as_ptr(),
                out.url.len() as u64,
                out.raw.as_mut_ptr(),
                out.raw.len() as u64,
                out.body.as_mut_ptr(),
                out.body.len() as u64,
                out.scratch.as_mut_ptr(),
                out.scratch.len() as u64,
                options.as_ptr(),
            )
        })?;
        if started.bits == 0 {
            return Err(Error::Unavailable);
        }
        Ok(out)
    }
    pub fn cancel(&mut self) -> Result<()> {
        result(unsafe { c::R4SdkTransportJobsJob_cancel(0, self.native.as_mut_ptr()) })?;
        Ok(())
    }
    /// Only true releases the worker's actual join. Cancellation alone does
    /// not make request/response storage reusable.
    pub fn collect(&mut self) -> Result<bool> {
        if !self.joined {
            self.joined =
                required(unsafe { c::R4SdkTransportJobsJob_collect(0, self.native.as_mut_ptr()) })?
                    .bits
                    != 0;
        }
        Ok(self.joined)
    }
    pub fn response(&self) -> Result<Response<'_>> {
        if !self.joined {
            return Err(Error::Unavailable);
        }
        let mut value = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkTransportJobsJob_get_result(self.native.as_ptr(), value.as_mut_ptr())
        })?;
        response(&value, &self.raw, &self.body)
    }
}
impl Drop for Job {
    fn drop(&mut self) {
        let _ = unsafe { c::R4SdkTransportJobsJob_deinit(0, self.native.as_mut_ptr()) };
    }
}
