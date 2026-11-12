//! Bounded original-core consumers shared by native and private guest tests.
extern crate alloc;
use alloc::{boxed::Box, vec};
use core::mem::MaybeUninit;
use r4os_sdk::{
    App,
    update::{Error, Fat32Plan, Inventory, Journal, MemoryBlock, Result, raw as c},
};
pub const JOURNAL: &[u8] = include_bytes!("../Fixtures/Update/JournalV5.txt");
pub const APPLIED: &[u8] = include_bytes!("../Fixtures/Update/JournalAppliedV5.txt");
pub const MODULES: &[u8] = include_bytes!("../Fixtures/Update/Modules.json");
#[cfg(target_os = "none")]
pub const CATALOG: &[u8] = include_bytes!("../Fixtures/Update/CatalogV2.json");
macro_rules! ensure {
    ($v:expr) => {
        if !$v {
            return Err(Error::Transport(line!() as i32));
        }
    };
}
unsafe extern "C" {
    fn sdk_update_journal_case(
        start: *const r4os_sdk::abi::R4XStartContext,
        first: *mut c::R4SdkUpdateRecoveryTransactionJournal,
        second: *mut c::R4SdkUpdateRecoveryTransactionJournal,
        input: *const u8,
        length: usize,
        durable: *mut u8,
        capacity: usize,
    ) -> i32;
    fn sdk_update_archive_case() -> i32;
    fn sdk_update_io_callbacks_case() -> i32;
    fn sdk_update_cleanup_case(
        journal: *mut c::R4SdkUpdateRecoveryTransactionJournal,
        input: *const u8,
        length: usize,
        durable: *mut u8,
        capacity: usize,
    ) -> i32;
}
pub fn c_replay(app: Option<&App<'_>>) -> Result<()> {
    let mut first = Box::<c::R4SdkUpdateRecoveryTransactionJournal>::new_uninit();
    let mut second = Box::<c::R4SdkUpdateRecoveryTransactionJournal>::new_uninit();
    let mut durable = vec![0; 8192];
    let code = unsafe {
        sdk_update_journal_case(
            app.map_or(core::ptr::null(), |a| a.start_context() as *const _),
            first.as_mut_ptr(),
            second.as_mut_ptr(),
            JOURNAL.as_ptr(),
            JOURNAL.len(),
            durable.as_mut_ptr(),
            durable.len(),
        )
    };
    if code != 0 {
        return Err(Error::Transport(code));
    }
    Ok(())
}
pub fn c_archive() -> Result<()> {
    let code = unsafe { sdk_update_archive_case() };
    if code != 0 {
        return Err(Error::Transport(code));
    }
    Ok(())
}
pub fn c_io_callbacks() -> Result<()> {
    let code = unsafe { sdk_update_io_callbacks_case() };
    if code != 0 {
        return Err(Error::Transport(code));
    }
    Ok(())
}
pub fn c_cleanup() -> Result<()> {
    let mut j = Box::<c::R4SdkUpdateRecoveryTransactionJournal>::new_uninit();
    let mut durable = vec![0; 8192];
    let code = unsafe {
        sdk_update_cleanup_case(
            j.as_mut_ptr(),
            APPLIED.as_ptr(),
            APPLIED.len(),
            durable.as_mut_ptr(),
            durable.len(),
        )
    };
    if code != 0 {
        return Err(Error::Transport(code));
    }
    Ok(())
}
pub fn metadata() -> Result<()> {
    let mut storage = Box::<c::R4SdkUpdateRecoveryTransactionJournal>::new_uninit();
    let journal = Journal::parse(&mut storage, JOURNAL, 0)?;
    ensure!(journal.phase()? == c::R4SdkUpdateRecoveryJournalPhase_stage);
    ensure!(journal.source()? == b"C:\\R4OS\\UPDATE\\INBOX\\SDK64.R4U");
    let mut text = vec![0; 8192];
    ensure!(journal.serialize(&mut text)? == JOURNAL);
    drop(journal);
    let mut corrupt = JOURNAL.to_vec();
    let i = corrupt.len() - 4;
    corrupt[i] ^= 1;
    ensure!(Journal::parse(&mut storage, &corrupt, 0).is_err());
    let mut storage = Box::<c::R4SdkUpdateInventoryInventory>::new_uninit();
    let inventory = Inventory::parse(&mut storage, MODULES)?;
    ensure!(
        inventory.count()? == 1
            && inventory.profile()? == c::R4SdkUpdateInventoryProfile_test_image
    );
    let text = inventory.serialize(&mut text)?;
    let mut other = Box::<c::R4SdkUpdateInventoryInventory>::new_uninit();
    let reparsed = Inventory::parse(&mut other, text)?;
    ensure!(reparsed.count()? == 1 && reparsed.profile()? == inventory.profile()?);
    Ok(())
}
pub fn memory_format() -> Result<()> {
    let mut bytes = vec![0x7a; 64 * 1024 * 1024];
    let sectors = bytes.len() as u64 / 512;
    let mut storage = MaybeUninit::uninit();
    let mut memory = MemoryBlock::open(&mut storage, &mut bytes)?;
    let plan = Fat32Plan::prepare(sectors, 0, b"SDKDATA", 0x12345678, 1)?;
    let mut work = vec![0; 8192];
    {
        let mut device = memory.device()?;
        ensure!(device.sectors()? == sectors);
        plan.execute(&mut device, false, &mut work)?;
        let mut boot = [0; 512];
        device.read(0, &mut boot)?;
        ensure!(&boot[82..90] == b"FAT32   " && boot[510..512] == [0x55, 0xaa]);
        ensure!(device.read(sectors, &mut boot) == Err(Error::Native("Bounds")));
    }
    ensure!(
        memory.bytes()[memory.bytes().len() - 512..]
            .iter()
            .all(|b| *b == 0)
    );
    ensure!(memory.bytes()[memory.bytes().len() / 2] == 0x7a);
    Ok(())
}
#[cfg(target_os = "none")]
pub fn catalogue(app: &App<'_>) -> Result<()> {
    let mut data_storage = core::pin::pin!(r4os_sdk::data::DataStorage::new());
    let data = r4os_sdk::data::Data::open(data_storage.as_mut(), app)?;
    let mut storage = Box::<c::R4SdkUpdateCatalogCatalogRelease>::new_uninit();
    let mut workspace = Box::<c::R4SdkUpdateCatalogCatalogRelease>::new_uninit();
    let mut depth = [0; 128];
    let catalogue = r4os_sdk::update::Catalog::parse(
        &mut storage,
        &mut workspace,
        &data,
        CATALOG,
        &mut depth,
        r4os_sdk::update::Profile::Full,
        b"0.63.16",
    )?;
    ensure!(
        catalogue.release()? == b"0.63.17"
            && catalogue.package_count()? == 0
            && catalogue.required_count()? == 2
    );
    Ok(())
}
