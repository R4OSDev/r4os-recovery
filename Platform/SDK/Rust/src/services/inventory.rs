//! Revision-bound service inventory. Page storage belongs to the caller;
//! optional allocated captures own their Vec and release it normally on Drop.
use super::Services;
use crate::{
    abi, c_facades as c,
    resources::Timeout,
    storage::{Error, Result, length},
};

pub enum InventoryAction {
    Start,
    Stop(Timeout),
    Restart,
    Mode(u32),
    Remove,
}

impl Services<'_> {
    pub fn inventory_available(&self) -> bool {
        unsafe { c::r4_services_inventory_available(&self.raw()) != 0 }
    }

    /// END is the only completion proof. RESTART requires discarding the full
    /// partial capture; it never authorizes acting on a replacement row.
    pub fn inventory_page(
        &self,
        cursor: &mut abi::ServiceInventoryCursor,
        rows: &mut [abi::ServiceInventoryRow],
    ) -> Result<usize> {
        if rows.is_empty() {
            return Err(Error::Length);
        }
        let count = unsafe {
            c::r4_services_inventory_page(
                &self.raw(),
                cursor,
                rows.as_mut_ptr(),
                length(rows.len())?,
            )
        };
        if count < 0 {
            return Err(Error::Raw(count));
        }
        if count as usize > rows.len() {
            return Err(Error::InvalidProvider);
        }
        Ok(count as usize)
    }

    pub fn control_bound(&self, request: &abi::ServiceControlRequest) -> Result<()> {
        super::exact(unsafe { c::r4_services_control_bound(&self.raw(), request) })
    }

    pub fn control_entry(
        &self,
        row: &abi::ServiceInventoryRow,
        action: InventoryAction,
    ) -> Result<()> {
        let mut request = abi::ServiceControlRequest {
            registration_id: row.registration_id,
            start_generation: row.start_generation,
            process: row.process,
            ..Default::default()
        };
        match action {
            InventoryAction::Start => request.operation = abi::service_control_start,
            InventoryAction::Stop(timeout) => {
                request.operation = abi::service_control_stop;
                super::exact(unsafe {
                    c::r4_timeout_to_ticks(
                        timeout.raw(),
                        c::r4_services_monotonic_hz(self.raw().app),
                        &mut request.timeout_ticks,
                    )
                })?;
            }
            InventoryAction::Restart => request.operation = abi::service_control_restart,
            InventoryAction::Mode(mode) => {
                request.operation = abi::service_control_mode;
                request.mode = mode;
            }
            InventoryAction::Remove => request.operation = abi::service_control_remove,
        }
        self.control_bound(&request)
    }
}

#[cfg(feature = "alloc")]
mod allocated {
    extern crate alloc;
    use super::*;
    use alloc::vec::Vec;

    pub struct ServiceInventory {
        pub rows: Vec<abi::ServiceInventoryRow>,
        pub revision: u64,
    }

    impl Services<'_> {
        pub fn inventory(&self) -> Result<ServiceInventory> {
            let mut values = Vec::new();
            for _ in 0..3 {
                values.clear();
                let mut cursor = abi::ServiceInventoryCursor::default();
                let mut page =
                    [abi::ServiceInventoryRow::default(); abi::service_inventory_page_rows];
                loop {
                    let previous = cursor;
                    let count = match self.inventory_page(&mut cursor, &mut page) {
                        Err(Error::Raw(code))
                            if code == abi::service_api_result_restart
                                || code == abi::service_api_result_busy =>
                        {
                            break;
                        }
                        other => other?,
                    };
                    if cursor.revision == 0
                        || cursor.reserved != 0
                        || cursor.flags & abi::service_inventory_dynamic == 0
                        || cursor.flags
                            & !(abi::service_inventory_dynamic | abi::service_inventory_end)
                            != 0
                        || (previous.revision != 0
                            && (cursor.revision != previous.revision
                                || cursor.total != previous.total))
                    {
                        return Err(Error::InvalidProvider);
                    }
                    let mut last = previous.after_id;
                    for row in &page[..count] {
                        if row.registration_id <= last {
                            return Err(Error::InvalidProvider);
                        }
                        last = row.registration_id;
                    }
                    if cursor.after_id != last
                        || values.len() as u64 > cursor.total
                        || count as u64 > cursor.total - values.len() as u64
                    {
                        return Err(Error::InvalidProvider);
                    }
                    values
                        .try_reserve(count)
                        .map_err(|_| Error::Raw(abi::service_api_result_memory))?;
                    values.extend_from_slice(&page[..count]);
                    if cursor.flags & abi::service_inventory_end != 0 {
                        if values.len() as u64 != cursor.total {
                            return Err(Error::InvalidProvider);
                        }
                        return Ok(ServiceInventory {
                            rows: values,
                            revision: cursor.revision,
                        });
                    }
                    if count == 0 {
                        return Err(Error::InvalidProvider);
                    }
                }
            }
            Err(Error::Raw(abi::service_api_result_busy))
        }
    }
}
#[cfg(feature = "alloc")]
pub use allocated::ServiceInventory;
