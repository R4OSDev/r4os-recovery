use super::*;
#[must_use = "requesting close is not a process completion/reap acknowledgement"]
pub struct Process<'a> {
    raw: c::R4Process,
    owner: &'a Resources<'a>,
}
impl Resources<'_> {
    pub fn spawn(
        &self,
        file: &FilePath,
        args: &CStr,
        policy: abi::LaunchPolicy,
    ) -> Result<Process<'_>> {
        let mut raw = unsafe { core::mem::zeroed() };
        exact(unsafe {
            c::r4_resources_spawn(
                &mut self.raw(),
                path(file),
                args.as_ptr().cast(),
                policy.0,
                &mut raw,
            )
        })?;
        Ok(Process { raw, owner: self })
    }
    pub fn spawn_with_console_host(
        &self,
        file: &FilePath,
        args: &CStr,
        policy: abi::LaunchPolicy,
        host: abi::ConsoleHostKind,
    ) -> Result<Process<'_>> {
        let mut raw = unsafe { core::mem::zeroed() };
        exact(unsafe {
            c::r4os_spawn_with_console_host(
                &mut self.raw(),
                path(file),
                args.as_ptr().cast(),
                policy.0,
                host.0,
                &mut raw,
            )
        })?;
        Ok(Process { raw, owner: self })
    }
    pub fn open_process(&self, id: u32) -> Result<Process<'_>> {
        let mut raw = unsafe { core::mem::zeroed() };
        exact(unsafe { c::r4_resources_open_process(&mut self.raw(), id, &mut raw) })?;
        Ok(Process { raw, owner: self })
    }
    /// Preserve an exact known identity. Status still validates its generation
    /// at the kernel owner; this never grants reap ownership.
    pub fn borrow_process(&self, handle: &abi::ProgramProcessHandle) -> Result<Process<'_>> {
        let mut raw = unsafe { core::mem::zeroed() };
        exact(unsafe { c::r4_resources_borrow_process(&mut self.raw(), handle, &mut raw) })?;
        Ok(Process { raw, owner: self })
    }
    /// Metadata-only, generation-checked registry acquisition. Full task/thread/
    /// memory inventory remains an explicit independent operation.
    pub fn lifecycle(&self) -> Result<Lifecycle<'_>> {
        let mut value = Lifecycle {
            owner: self,
            cursor: abi::ProgramInventoryCursor::default(),
        };
        exact(unsafe {
            c::r4_resources_program_lifecycle_begin(&mut self.raw(), &mut value.cursor)
        })?;
        Ok(value)
    }
    pub fn inventory(&self) -> Result<Inventory<'_>> {
        let mut value = Inventory {
            owner: self,
            cursor: abi::ProgramInventoryCursor::default(),
            summary: abi::ProgramInventorySummary::default(),
        };
        exact(unsafe {
            c::r4_resources_program_inventory_begin(
                &mut self.raw(),
                &mut value.cursor,
                &mut value.summary,
            )
        })?;
        Ok(value)
    }
}
impl Process<'_> {
    pub fn valid(&self) -> bool {
        unsafe { c::r4_process_valid(&self.raw) != 0 }
    }
    pub fn owned(&self) -> bool {
        self.raw.owned != 0
    }
    pub fn handle(&self) -> abi::ProgramProcessHandle {
        abi::ProgramProcessHandle {
            instance_id: self.raw.raw,
            reserved: self.raw.handle_reserved,
            generation: self.raw.generation,
        }
    }
    pub fn status(&mut self) -> Result<Option<abi::ProgramInstanceInfo>> {
        let mut value = abi::ProgramInstanceInfo::default();
        let raw = unsafe { c::r4_process_status(&mut self.raw, &mut value) };
        if raw == abi::program_handle_error_not_found {
            return Ok(None);
        }
        exact(raw)?;
        Ok(Some(value))
    }
    pub fn request_close(&mut self) -> Result<()> {
        exact(unsafe { c::r4_process_request_close(&mut self.raw) })
    }
    pub fn kill(&mut self) -> Result<()> {
        exact(unsafe { c::r4_process_kill(&mut self.raw) })
    }
    pub fn wait_ready(&mut self, timeout: Timeout) -> Result<Wait<abi::ProgramProcessCompletion>> {
        let mut value = abi::ProgramProcessCompletion::default();
        let raw = unsafe { c::r4os_process_wait_ready(&mut self.raw, timeout.raw(), &mut value) };
        match raw {
            abi::program_handle_error_would_block => Ok(Wait::WouldBlock),
            abi::program_handle_error_timeout => Ok(Wait::TimedOut),
            0 => Ok(Wait::Completed(value)),
            _ => Err(Error::Raw(raw)),
        }
    }
    pub fn completion_read(&mut self, offset: u32, buffer: &mut [u8]) -> Result<Wait<usize>> {
        let mut count = 0;
        let raw = unsafe {
            c::r4os_process_completion_read(
                &mut self.raw,
                offset,
                buffer.as_mut_ptr(),
                crate::storage::length(buffer.len())?,
                &mut count,
            )
        };
        if raw == abi::program_handle_error_would_block {
            return Ok(Wait::WouldBlock);
        }
        exact(raw)?;
        if count as usize > buffer.len() {
            return Err(Error::InvalidProvider);
        }
        Ok(Wait::Completed(count as usize))
    }
    pub fn reap(&mut self) -> Result<Wait<i32>> {
        outcome(unsafe { c::r4_process_reap(&mut self.raw) })
    }
    pub fn wait(&mut self, timeout: Timeout) -> Result<Wait<i32>> {
        outcome(unsafe { c::r4_process_wait(&mut self.raw, timeout.raw()) })
    }
    pub fn resources(&self) -> &Resources<'_> {
        self.owner
    }
}

pub struct Inventory<'a> {
    owner: &'a Resources<'a>,
    cursor: abi::ProgramInventoryCursor,
    summary: abi::ProgramInventorySummary,
}
impl Inventory<'_> {
    pub fn cursor(&self) -> &abi::ProgramInventoryCursor {
        &self.cursor
    }
    pub fn summary(&self) -> &abi::ProgramInventorySummary {
        &self.summary
    }
    // Callers receive the exact page status/generation, including restarts.
    // Only the reported prefix contains records for this call.
    pub fn programs(
        &mut self,
        out: &mut [abi::ProgramInstanceSnapshot],
    ) -> Result<abi::ProgramInventoryPageInfo> {
        let mut page = abi::ProgramInventoryPageInfo::default();
        exact(unsafe {
            c::r4_resources_program_inventory_programs(
                &mut self.owner.raw(),
                &mut self.cursor,
                out.as_mut_ptr(),
                crate::storage::length(out.len())?,
                &mut page,
            )
        })?;
        if page.returned as usize > out.len() {
            return Err(Error::InvalidProvider);
        }
        Ok(page)
    }
    pub fn tasks(
        &mut self,
        out: &mut [abi::ProgramTaskSnapshot],
    ) -> Result<abi::ProgramInventoryPageInfo> {
        let mut page = abi::ProgramInventoryPageInfo::default();
        exact(unsafe {
            c::r4_resources_program_inventory_tasks(
                &mut self.owner.raw(),
                &mut self.cursor,
                out.as_mut_ptr(),
                crate::storage::length(out.len())?,
                &mut page,
            )
        })?;
        if page.returned as usize > out.len() {
            return Err(Error::InvalidProvider);
        }
        Ok(page)
    }
    pub fn threads(
        &mut self,
        out: &mut [abi::ProgramThreadSnapshot],
    ) -> Result<abi::ProgramInventoryPageInfo> {
        let mut page = abi::ProgramInventoryPageInfo::default();
        exact(unsafe {
            c::r4_resources_program_inventory_threads(
                &mut self.owner.raw(),
                &mut self.cursor,
                out.as_mut_ptr(),
                crate::storage::length(out.len())?,
                &mut page,
            )
        })?;
        if page.returned as usize > out.len() {
            return Err(Error::InvalidProvider);
        }
        Ok(page)
    }
}

/// A caller-owned cursor, not a registry lease. Complete paging is required
/// before lifecycle decisions; Busy or restart never makes partial rows current.
pub struct Lifecycle<'a> {
    owner: &'a Resources<'a>,
    cursor: abi::ProgramInventoryCursor,
}
impl Lifecycle<'_> {
    pub fn cursor(&self) -> &abi::ProgramInventoryCursor {
        &self.cursor
    }
    pub fn programs(
        &mut self,
        out: &mut [abi::ProgramLifecycleSnapshot],
    ) -> Result<abi::ProgramInventoryPageInfo> {
        let mut page = abi::ProgramInventoryPageInfo::default();
        exact(unsafe {
            c::r4_resources_program_lifecycle_programs(
                &mut self.owner.raw(),
                &mut self.cursor,
                out.as_mut_ptr(),
                crate::storage::length(out.len())?,
                &mut page,
            )
        })?;
        if page.returned as usize > out.len() {
            return Err(Error::InvalidProvider);
        }
        Ok(page)
    }
}

/// Separate terminal evidence reference. It never owns/reaps the target.
#[must_use = "close or export the observation when its evidence is no longer needed"]
pub struct Observation<'a> {
    raw: abi::ProgramObservationHandle,
    owner: &'a Resources<'a>,
}
impl Resources<'_> {
    /// Bind while the exact completion still exists. Portable bindings survive
    /// this process only when explicitly exported; close them in the consumer.
    pub fn observe_process(
        &self,
        process: &abi::ProgramProcessHandle,
        portable: bool,
    ) -> Result<Observation<'_>> {
        let mut raw = abi::ProgramObservationHandle::default();
        exact(unsafe {
            c::r4_resources_observation_retain(
                &mut self.raw(),
                process,
                if portable {
                    abi::program_observation_flag_portable
                } else {
                    0
                },
                &mut raw,
            )
        })?;
        Ok(Observation { raw, owner: self })
    }
    /// Adopt one previously exported binding, without retaining another one.
    /// Copies of its token name the same reference and close together.
    pub fn adopt_observation(&self, raw: abi::ProgramObservationHandle) -> Observation<'_> {
        Observation { raw, owner: self }
    }
}
impl Observation<'_> {
    pub fn handle(&self) -> abi::ProgramObservationHandle {
        self.raw
    }
    /// Transfer explicit release responsibility. Only portable bindings survive
    /// their creator generation; exporting does not change that kernel policy.
    pub fn export(mut self) -> abi::ProgramObservationHandle {
        let value = self.raw;
        self.raw = abi::ProgramObservationHandle::default();
        value
    }
    pub fn wait_ready(&self, timeout: Timeout) -> Result<Wait<abi::ProgramProcessCompletion>> {
        let mut value = abi::ProgramProcessCompletion::default();
        let code = unsafe {
            c::r4_resources_observation_wait(
                &mut self.owner.raw(),
                &self.raw,
                timeout.raw(),
                &mut value,
            )
        };
        match code {
            abi::program_handle_error_would_block => Ok(Wait::WouldBlock),
            abi::program_handle_error_timeout => Ok(Wait::TimedOut),
            0 => Ok(Wait::Completed(value)),
            _ => Err(Error::Raw(code)),
        }
    }
    pub fn read(&self, offset: u32, bytes: &mut [u8]) -> Result<Wait<usize>> {
        let mut count = 0;
        let code = unsafe {
            c::r4_resources_observation_read(
                &mut self.owner.raw(),
                &self.raw,
                offset,
                bytes.as_mut_ptr(),
                crate::storage::length(bytes.len())?,
                &mut count,
            )
        };
        if code == abi::program_handle_error_would_block {
            return Ok(Wait::WouldBlock);
        }
        exact(code)?;
        if count as usize > bytes.len() {
            return Err(Error::InvalidProvider);
        }
        Ok(Wait::Completed(count as usize))
    }
    pub fn close(&mut self) -> Result<()> {
        if self.raw.id == 0 {
            return Ok(());
        }
        exact(unsafe { c::r4_resources_observation_release(&mut self.owner.raw(), &self.raw) })?;
        self.raw = abi::ProgramObservationHandle::default();
        Ok(())
    }
}
impl Drop for Observation<'_> {
    fn drop(&mut self) {
        let _ = self.close();
    }
}
