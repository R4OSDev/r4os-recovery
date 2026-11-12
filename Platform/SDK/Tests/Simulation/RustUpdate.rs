#![cfg(test)]
#[path = "UpdateCases.rs"]
mod cases;
use r4os_sdk::update::{self, HostFile, raw as c};
#[test]
fn c_replay_preserves_durable_journal_and_exact_idempotent_receipts() {
    cases::c_replay(None).unwrap();
}
#[test]
fn c_archive_retains_original_on_each_failure_and_missing_callback() {
    cases::c_archive().unwrap();
}
#[test]
fn original_journal_and_inventory_metadata() {
    cases::metadata().unwrap();
    let mut output = [0u8; 128];
    let input = "d:\\Apps\\Grüße\\APP.R4X".as_bytes();
    let observed = unsafe {
        c::R4SdkUpdateNative_r4u_manifest_canonicalInventoryTarget(
            0, output.as_mut_ptr(), output.len() as u64, input.as_ptr(), input.len() as u64,
        )
    };
    assert_eq!(observed.status, 0);
    assert_ne!(observed.flags & 1, 0);
    let length = usize::try_from(observed.length).unwrap();
    assert!(length <= output.len());
    assert_eq!(&output[..length], "D:/Apps/Grüße/APP.R4X".as_bytes());
}
#[test]
fn original_fat32_formatter_over_scoped_memory_device() {
    cases::memory_format().unwrap();
}
#[test]
fn original_host_file_lock_resize_flush_and_borrowed_handle() {
    use std::{
        fs,
        io::{Read, Seek, SeekFrom},
    };
    let path = "host-disk.bin";
    let file = fs::File::create(path).unwrap();
    file.set_len(4096).unwrap();
    drop(file);
    let mut storage = Box::<c::R4SdkUpdateHostFile>::new_uninit();
    {
        let mut file = HostFile::open(&mut storage, path.as_bytes()).unwrap();
        {
            let mut dev = file.device().unwrap();
            assert_eq!(
                dev.write(0, &[1; 512]),
                Err(update::Error::Native("ExclusiveRequired"))
            );
        }
        file.acquire().unwrap();
        file.resize(16).unwrap();
        {
            let mut dev = file.device().unwrap();
            assert_eq!(dev.sectors().unwrap(), 16);
            dev.write(1, &[0x63; 512]).unwrap();
            dev.flush().unwrap();
            let mut check = [0; 512];
            dev.read(1, &mut check).unwrap();
            assert_eq!(check, [0x63; 512]);
        }
        file.release().unwrap();
    }
    assert_eq!(fs::metadata(path).unwrap().len(), 8192);
    let mut file = fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(path)
        .unwrap();
    #[cfg(unix)]
    let handle = {
        use std::os::fd::AsRawFd;
        file.as_raw_fd() as u64
    };
    #[cfg(windows)]
    let handle = {
        use std::os::windows::io::AsRawHandle;
        file.as_raw_handle() as usize as u64
    };
    unsafe {
        let v = c::R4SdkUpdateHost_borrow(0, storage.as_mut_ptr(), handle);
        assert_eq!(v.status, 0);
        assert_eq!(v.flags & 2, 0);
        let v = c::R4SdkUpdateHost_close(0, storage.as_mut_ptr());
        assert_eq!(v.status, 0);
        assert_eq!(v.flags & 2, 0);
    }
    assert_eq!(file.metadata().unwrap().len(), 8192);
    file.seek(SeekFrom::Start(512)).unwrap();
    let mut b = [0; 512];
    file.read_exact(&mut b).unwrap();
    assert_eq!(b, [0x63; 512]);
    drop(file);
    fs::remove_file(path).unwrap();
}

#[test]
fn original_block_and_source_callbacks_preserve_errors_and_cancel() {
    cases::c_io_callbacks().unwrap();
}

#[test]
fn original_checked_cleanup_preserves_applied_owner_until_terminal_receipt() {
    cases::c_cleanup().unwrap();
}
