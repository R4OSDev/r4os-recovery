#![no_std]
use r4os_sdk::{
    App, abi,
    path::{AbsoluteFilePath, FilePath, RegistryPath},
    storage::{AtomicReplace, Presence, RegistryBatch, SaveResult, SnapshotKind, System},
};
#[path = "../../../Conformance/StorageCodecChecks.rs"]
mod common;
fn main(app: &mut App<'_>) -> i32 {
    common::codecs();
    let system = System::new(app).unwrap();
    let files = system.files();
    let directory = FilePath::parse(b"C:\\TEMP\\SDKST53").unwrap();
    assert_eq!(
        files.create_directory(&directory).unwrap(),
        Presence::Present
    );
    let path = FilePath::parse(b"C:\\TEMP\\SDKST53\\DATA.BIN").unwrap();
    let target = FilePath::parse(b"C:\\TEMP\\SDKST53\\SAVED.BIN").unwrap();
    let copy = FilePath::parse(b"C:\\TEMP\\SDKST53\\COPY.BIN").unwrap();
    let bytes = b"R4OS\0\xc4\xff\x01";
    let mut writer = files
        .stream_writer(&path, abi::file_stream_open_create)
        .unwrap();
    writer.write(&bytes[..3]).unwrap();
    writer.write(&bytes[3..]).unwrap();
    assert_eq!(writer.offset(), bytes.len() as u64);
    writer.finish().unwrap();
    let mut reader = files.stream_reader(&path);
    let mut out = [0; 64];
    assert_eq!(reader.read(&mut out[..3]).unwrap(), Some(3));
    assert_eq!(&out[..3], &bytes[..3]);
    assert_eq!(reader.read(&mut out).unwrap(), Some(bytes.len() - 3));
    assert_eq!(&out[..bytes.len() - 3], &bytes[3..]);
    assert_eq!(reader.read(&mut out).unwrap(), None);
    let mut sequence = 0;
    assert!(matches!(
        files.save(&mut sequence, &target, bytes, false),
        SaveResult::Saved
    ));
    assert_eq!(files.read(&target, &mut out).unwrap(), Some(bytes.len()));
    assert_eq!(&out[..bytes.len()], bytes);
    let copied = files.copy(&path, &copy, &mut out).unwrap();
    assert_eq!(copied.ok, 1);
    assert_eq!(copied.progress.bytes, bytes.len() as u64);
    let mut changes = abi::DirectoryChangeCursor::default();
    files
        .begin_directory_changes(&directory, &mut changes)
        .unwrap();
    files.delete(&copy).unwrap();
    assert!(files.poll_directory_changes(&mut changes).unwrap() > 0);
    let stage = AbsoluteFilePath::parse(b"C:\\TEMP\\SDKST53\\STAGE.BIN").unwrap();
    let published = FilePath::parse(b"C:\\TEMP\\SDKST53\\PUB.BIN").unwrap();
    let backup = FilePath::parse(b"C:\\TEMP\\SDKST53\\BACK.BIN").unwrap();
    let mut owned = files.owned_create_writer(&stage).unwrap();
    owned.write(bytes).unwrap();
    owned.finish_keep_ownership().unwrap();
    assert_eq!(
        owned.publish_create(&published, &backup),
        AtomicReplace::Committed
    );
    assert!(!owned.needs_abort());
    let mut fresh = files
        .stream_writer(stage.as_path(), abi::file_stream_open_create)
        .unwrap();
    owned.abort().unwrap();
    fresh.write(bytes).unwrap();
    fresh.abort().unwrap();
    assert_eq!(files.delete(&published).unwrap(), Presence::Present);
    let registry = system.registry();
    let key = RegistryPath::parse(b"SYSTEM\\Software\\SDKStorage53").unwrap();
    let mut ops = [abi::RegistryBatchOperation::default(); 2];
    let mut blob = [0; 256];
    let mut batch = RegistryBatch::new(&mut ops, &mut blob).unwrap();
    batch.set_u32(&key, c"Count", 99).unwrap();
    batch.set_string(&key, c"Text", "ä€".as_bytes()).unwrap();
    let applied = registry.apply_batch(&batch);
    assert_eq!(applied.raw_code, 0);
    assert_eq!(applied.result.status, abi::registry_batch_status_committed);
    assert_eq!(
        registry
            .get(&key, c"Count", &mut out)
            .unwrap()
            .unwrap()
            .as_u32(),
        Some(99)
    );
    assert_eq!(
        registry
            .get(&key, c"Text", &mut out)
            .unwrap()
            .unwrap()
            .as_string(),
        Some("ä€".as_bytes())
    );
    let mut snapshot = registry
        .begin_snapshot(&key, SnapshotKind::Values)
        .unwrap()
        .unwrap();
    let generation = snapshot.cursor().generation;
    let mut entries = [abi::RegistrySnapshotEntry::default(); 2];
    let page = snapshot.page(&mut entries, &mut out).unwrap();
    assert_eq!(page.generation, generation);
    assert_eq!(page.returned, 2);
    assert_eq!(page.status, abi::registry_snapshot_status_complete);
    batch.reset();
    batch.delete(&key, c"Count").unwrap();
    batch.delete(&key, c"Text").unwrap();
    assert_eq!(
        registry.apply_batch(&batch).result.status,
        abi::registry_batch_status_committed
    );
    let recent = RegistryPath::parse(b"SYSTEM\\Shell\\RecentDocuments").unwrap();
    registry.set_bool(&recent, c"Enabled", true).unwrap();
    let mut opened = *b"C:\\TEMP\\SDKST53\\F0.TXT";
    let digit = opened.len() - 5;
    for index in 0..8 {
        opened[digit] = b'0' + index;
        let path = FilePath::parse(&opened).unwrap();
        assert!(files.add_recent_document(&path, b"SDK53"));
    }
    let mut entries = unsafe { core::mem::zeroed::<[r4os_sdk::c_facades::R4RecentEntry; 8]>() };
    assert_eq!(files.recent_documents(&mut entries).unwrap(), 8);
    assert_eq!(files.delete(&path).unwrap(), Presence::Present);
    assert_eq!(files.delete(&target).unwrap(), Presence::Present);
    assert_eq!(
        files.delete_directory(&directory).unwrap(),
        Presence::Present
    );
    system
        .console()
        .line(b"[SDK53] Rust/C storage and codec owner PASS")
        .unwrap();
    0
}
r4os_sdk::app!(main);
