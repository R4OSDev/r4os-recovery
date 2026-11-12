use super::*;
#[must_use = "a stop request is not the exact thread join acknowledgement"]
pub struct JoinHandle<'a> {
    raw: c::R4JoinHandle,
    _owner: &'a Resources<'a>,
}
impl Resources<'_> {
    /// # Safety
    /// Same resident entry/argument contract as `create_thread`; this is the
    /// independent native ID API, without an automatic handle fallback.
    pub unsafe fn create_thread_raw(
        &self,
        entry: abi::ThreadEntryFn,
        arg: u64,
        reserve: u64,
        flags: u32,
    ) -> Result<u32> {
        let mut id = 0;
        exact(unsafe {
            c::r4_resources_thread_create_raw(
                &mut self.raw(),
                Some(entry),
                arg,
                reserve,
                flags,
                &mut id,
            )
        })?;
        Ok(id)
    }
    pub fn current_thread_id(&self) -> u32 {
        unsafe { c::r4_resources_thread_current_id(&mut self.raw()) }
    }
    pub fn thread_status_raw(&self, id: u32) -> Result<abi::ProgramThreadInfo> {
        let mut value = abi::ProgramThreadInfo::default();
        exact(unsafe { c::r4_resources_thread_status_raw(&mut self.raw(), id, &mut value) })?;
        Ok(value)
    }
    pub fn join_thread_raw(&self, id: u32, timeout: Timeout) -> Result<Wait<i32>> {
        let mut code = 0;
        match unsafe {
            c::r4_resources_thread_join_raw(
                &mut self.raw(),
                id,
                self.timeout_ticks(timeout)?,
                &mut code,
            )
        } {
            0 => Ok(Wait::Completed(code)),
            abi::thread_error_timeout => Ok(Wait::TimedOut),
            raw => Err(Error::Raw(raw)),
        }
    }
    /// # Safety
    /// This is the terminal current-thread transition. Its caller must finish
    /// Rust destructors and every foreign loan/operation before entering it.
    pub unsafe fn exit_thread(&self, code: i32) -> Result<core::convert::Infallible> {
        Err(Error::Raw(unsafe {
            c::r4_resources_thread_exit(&mut self.raw(), code)
        }))
    }

    /// # Safety
    /// Entry and its code remain resident; the argument and every shared object
    /// obey their callback/threading contract until the exact join. Forgetting
    /// a handle does not cancel a worker or extend a borrowed argument's life.
    pub unsafe fn create_thread(
        &self,
        entry: abi::ThreadEntryFn,
        arg: u64,
        reserve: u64,
        flags: u32,
    ) -> Result<JoinHandle<'_>> {
        let mut raw = unsafe { core::mem::zeroed() };
        exact(unsafe {
            c::r4_resources_create_thread_flags(
                &mut self.raw(),
                Some(entry),
                arg,
                reserve,
                flags,
                &mut raw,
            )
        })?;
        Ok(JoinHandle { raw, _owner: self })
    }
    /// # Safety
    /// Same resident entry/argument contract as `create_thread`. The manifest
    /// must admit owned compute workers; rejection creates no substitute task.
    pub unsafe fn create_compute_worker(
        &self,
        entry: abi::ThreadEntryFn,
        arg: u64,
        reserve: u64,
    ) -> Result<JoinHandle<'_>> {
        unsafe { self.create_thread(entry, arg, reserve, abi::thread_create_flag_compute_worker) }
    }
    pub fn current_thread(&self) -> Result<JoinHandle<'_>> {
        let mut raw = unsafe { core::mem::zeroed() };
        exact(unsafe { c::r4_resources_current_thread(&mut self.raw(), &mut raw) })?;
        Ok(JoinHandle { raw, _owner: self })
    }
}
impl JoinHandle<'_> {
    pub fn valid(&self) -> bool {
        unsafe { c::r4_join_handle_valid(&self.raw) != 0 }
    }
    pub fn owned(&self) -> bool {
        self.raw.owned != 0
    }
    pub fn handle(&self) -> abi::ProgramJoinHandle {
        self.raw.handle
    }
    pub fn status(&mut self) -> Result<abi::ProgramThreadInfo> {
        let mut value = abi::ProgramThreadInfo::default();
        exact(unsafe { c::r4_join_status(&mut self.raw, &mut value) })?;
        Ok(value)
    }
    /// Preserve both native status and required CPU-word metadata, including
    /// capacity errors; a caller can size its next request from this result.
    pub fn placement(&mut self, cpus: &mut [u64]) -> Placement {
        let mut info = abi::ThreadPlacementInfo::default();
        let raw_code = match u32::try_from(cpus.len()) {
            Ok(count) => unsafe {
                c::r4_join_placement(&mut self.raw, &mut info, cpus.as_mut_ptr(), count)
            },
            Err(_) => abi::thread_placement_error_capacity,
        };
        Placement { raw_code, info }
    }
    pub fn set_placement(&mut self, request: &abi::ThreadPlacementRequest, cpus: &[u64]) -> i32 {
        let Ok(count) = u32::try_from(cpus.len()) else {
            return abi::thread_placement_error_capacity;
        };
        unsafe { c::r4_join_set_placement(&mut self.raw, request, cpus.as_ptr(), count) }
    }
    pub fn join(&mut self, timeout: Timeout) -> Result<Wait<i32>> {
        outcome(unsafe { c::r4_join_wait(&mut self.raw, timeout.raw()) })
    }
}

pub struct Placement {
    pub raw_code: i32,
    pub info: abi::ThreadPlacementInfo,
}
