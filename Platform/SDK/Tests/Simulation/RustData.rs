#![cfg(test)]
use core::pin::pin;
use r4os_sdk::{
    abi,
    data::{
        Arena, ArenaStorage, Decoder, Encoding, Icon, MemoryPolicy, Raster, SearchParams, Sha256,
        digest, encode_into, resolve_url,
    },
};
unsafe extern "C" {
    fn sdk_textmetrics_c_case() -> i32;
    fn sdk_textmetrics_tables(
        sys: *mut abi::generation2::R4XStartR4Sys2,
        draw: *mut abi::generation2::R4XStartR4Draw2,
    );
    fn sdk_textmetrics_mode(mode: i32);
    fn sdk_textmetrics_calls() -> u32;
    fn sdk_metadata2_c_case() -> i32;
    fn sdk_metadata2_tables(out: *mut abi::generation2::R4XStartR4Sys2);
    fn sdk_metadata2_mode(value: i32);
    fn sdk_device_snapshot_c_case() -> i32;
    fn sdk_inventory_c_case() -> i32;
    fn sdk_transfer_c_case() -> i32;
    fn sdk_cli_c_case() -> i32;
    fn sdk_wire_c_case() -> i32;
    fn sdk_data_c_case(manifest: *const u8, length: usize) -> i32;
    fn sdk_ico_c_case(bytes: *const u8, length: usize) -> i32;
}
#[test]
fn wide_metadata_native_query_pages_and_returned_storage_keep_exact_values_and_loans() {
    use core::mem::MaybeUninit;
    use r4os_sdk::{metadata2, platform2::Context};
    assert_eq!(unsafe { sdk_metadata2_c_case() }, 0);
    let mut table = abi::generation2::R4XStartR4Sys2::default();
    unsafe { sdk_metadata2_tables(&mut table) };
    let imports = [abi::R4XStartImport {
        group_id: 1,
        resolved_version: 2,
        table: &table as *const _ as u64,
        ..Default::default()
    }];
    let raw = abi::generation2::R4XStartContext2 {
        import_count: 1,
        imports: imports.as_ptr() as u64,
        ..Default::default()
    };
    let context = unsafe { Context::new(&raw) }.unwrap();
    let info = metadata2::query(&context, c"file").unwrap().unwrap();
    assert_eq!(info.backend_node, 0x100000001);
    assert_eq!(metadata2::file_size(&info), Some(0x100000003));
    assert_eq!(metadata2::identity(&info).unwrap().namespace_generation, 0);
    assert!(metadata2::query(&context, c"missing").unwrap().is_none());
    let mut rows = [MaybeUninit::uninit(); 1];
    let mut directory = metadata2::Directory::new(&context, c"directory", &mut rows).unwrap();
    assert_eq!(directory.validate(), Err(metadata2::Error(-1)));
    unsafe { sdk_metadata2_mode(1) };
    assert!(matches!(
        directory.next_page().unwrap(),
        metadata2::Page::Progress
    ));
    unsafe { sdk_metadata2_mode(0) };
    for i in 0..2 {
        let metadata2::Page::Rows(page) = directory.next_page().unwrap() else {
            panic!("missing metadata page")
        };
        assert_eq!(page.len(), 1);
        assert_eq!(page[0].info.identity.object_hi, 0x100000001 + i);
        assert_eq!(page[0].path[0], b'A' + i as u8);
    }
    assert!(matches!(
        directory.next_page().unwrap(),
        metadata2::Page::End
    ));
    directory.validate().unwrap();
    unsafe { sdk_metadata2_mode(-10) };
    assert!(matches!(
        directory.next_page().unwrap(),
        metadata2::Page::Restart
    ));
    directory.reset();
    unsafe { sdk_metadata2_mode(0) };
    assert!(matches!(
        directory.next_page().unwrap(),
        metadata2::Page::Rows(_)
    ));
    let unknown = abi::FileMetadata2 {
        byte_size: 42,
        ..Default::default()
    };
    assert!(metadata2::identity(&unknown).is_none());
    assert!(metadata2::file_size(&unknown).is_none());
}
#[test]
fn shared_device_capture_pages_keep_one_collection_and_borrowed_complete_views() {
    use core::{
        mem::MaybeUninit,
        sync::atomic::{AtomicU64, Ordering},
    };
    use r4os_sdk::device_snapshot::*;
    assert_eq!(unsafe { sdk_device_snapshot_c_case() }, 0);
    static CALLS: AtomicU64 = AtomicU64::new(0);
    unsafe extern "C" fn capture(
        rows: *mut abi::DeviceInventoryRecord,
        capacity: u32,
        info: *mut abi::DeviceInventorySnapshotInfo,
    ) -> i32 {
        let call = CALLS.fetch_add(1, Ordering::Relaxed) + 1;
        let count = capacity.min(3);
        for i in 0..count {
            let mut row = abi::DeviceInventoryRecord::default();
            row.name[0] = b'A' + i as u8;
            unsafe { rows.add(i as usize).write(row) };
        }
        unsafe {
            info.write(abi::DeviceInventorySnapshotInfo {
                snapshot_generation: if capacity >= 3 { call } else { 0 },
                count,
                required_count: 3,
                capacity,
                flags: if capacity >= 3 { 3 } else { 2 },
                with_driver: 3,
                source_mask: 1,
                ..Default::default()
            })
        };
        if capacity >= 3 { 0 } else { -2 }
    }
    CALLS.store(0, Ordering::Relaxed);
    let provider = NativeProvider {
        capture: Some(capture),
    };
    let mut rows = [MaybeUninit::uninit(); 3];
    let mut snapshot = unsafe { Snapshot::from_native_provider(&provider, &mut rows) }.unwrap();
    assert!(snapshot.view().is_err());
    let done = snapshot.capture(false).unwrap();
    assert!(done.complete && !done.in_call);
    let mut cursor = snapshot.begin_pages().unwrap();
    {
        let page = snapshot.page(&mut cursor, 1).unwrap();
        assert_eq!(page.records[0].name[0], b'A');
        assert_eq!(page.status, PageStatus::More);
    }
    {
        let page = snapshot.page(&mut cursor, 2).unwrap();
        assert_eq!(page.records.len(), 2);
        assert_eq!(page.records[1].name[0], b'C');
        assert_eq!(page.status, PageStatus::Complete);
    }
    assert_eq!(CALLS.load(Ordering::Relaxed), 1);
    assert_eq!(snapshot.view().unwrap().len(), 3);
    snapshot.capture(false).unwrap();
    let page = snapshot.page(&mut cursor, 1).unwrap();
    assert_eq!(page.status, PageStatus::Restart);
    assert!(page.records.is_empty());
    assert_eq!(CALLS.load(Ordering::Relaxed), 2);
    snapshot.close().unwrap();
    assert!(snapshot.view().is_err());
}
#[test]
fn shared_inventory_only_publishes_complete_typed_views_and_exact_borrowed_membership() {
    use core::mem::MaybeUninit;
    use r4os_sdk::{inventory::*, resources::Timeout, time::checked::ClockSample};
    assert_eq!(unsafe { sdk_inventory_c_case() }, 0);
    unsafe extern "C" fn begin(cursor: *mut abi::ProgramInventoryCursor) -> i32 {
        unsafe {
            cursor.write(abi::ProgramInventoryCursor {
                snapshot_generation: 9,
                program_epoch: 9,
                flags: 3,
                ..Default::default()
            })
        };
        0
    }
    unsafe extern "C" fn page(
        cursor: *mut abi::ProgramInventoryCursor,
        out: *mut abi::ProgramLifecycleSnapshot,
        capacity: u32,
        header: *mut abi::ProgramInventoryPageInfo,
    ) -> i32 {
        if capacity == 0 {
            return -77;
        }
        let cursor = unsafe { &mut *cursor };
        let generation = if cursor.program_after_generation == 0 {
            11
        } else {
            12
        };
        unsafe {
            out.write(abi::ProgramLifecycleSnapshot {
                handle: abi::ProgramProcessHandle {
                    instance_id: (generation - 4) as u32,
                    generation,
                    ..Default::default()
                },
                ..Default::default()
            })
        };
        cursor.program_after_generation = generation;
        let more = u32::from(generation == 11);
        unsafe {
            header.write(abi::ProgramInventoryPageInfo {
                snapshot_generation: 9,
                next_generation: generation,
                total: 2,
                returned: 1,
                has_more: more,
                kind: 4,
                status: more as i32,
                ..Default::default()
            })
        };
        0
    }
    let provider = NativeProvider {
        full_begin: None,
        full_page: None,
        lifecycle_begin: Some(begin),
        lifecycle_page: Some(page),
    };
    let info = abi::MonotonicClockInfo {
        flags: abi::monotonic_clock_flag_valid,
        source: 1,
        generation: 1,
        resolution_ns: 1,
        event_requested_hz: 1000,
        instant_ns: 100,
        ..Default::default()
    };
    let initial = ClockSample::from_info(&info).unwrap();
    let mut rows = [MaybeUninit::uninit(); 2];
    let mut reader = unsafe {
        LifecycleReader::from_native_provider(&mut rows, 1, &provider, initial, Timeout::Forever)
    }
    .unwrap();
    assert!(matches!(
        reader
            .find_exact(abi::ProgramProcessHandle {
                instance_id: 7,
                generation: 11,
                ..Default::default()
            })
            .unwrap(),
        Lookup::Unknown { .. }
    ));
    assert!(reader.view().is_err());
    let mut clock = || Ok(initial);
    assert_eq!(reader.step(false, &mut clock).unwrap().status, Status::More);
    let first = reader.step(false, &mut clock).unwrap();
    assert_eq!(first.staged_count, 1);
    assert!(!first.in_call);
    assert!(reader.view().is_err());
    assert!(reader.step(false, &mut clock).unwrap().complete);
    assert_eq!(reader.view().unwrap()[1].handle.generation, 12);
    match reader
        .find_exact(abi::ProgramProcessHandle {
            instance_id: 7,
            generation: 11,
            ..Default::default()
        })
        .unwrap()
    {
        Lookup::Found {
            snapshot_generation,
            record,
        } => assert_eq!((snapshot_generation, record.handle.instance_id), (9, 7)),
        _ => panic!("Complete actual row must be found"),
    }
    assert!(matches!(
        reader
            .find_exact(abi::ProgramProcessHandle {
                instance_id: 7,
                generation: 12,
                ..Default::default()
            })
            .unwrap(),
        Lookup::Missing {
            snapshot_generation: 9
        }
    ));
    assert_eq!(reader.restart().unwrap().restarts, 1);
    assert!(reader.view().is_err());
    assert_eq!(reader.cancel().unwrap().status, Status::Cancelled);
    assert!(matches!(
        reader
            .find_exact(abi::ProgramProcessHandle {
                instance_id: 7,
                generation: 11,
                ..Default::default()
            })
            .unwrap(),
        Lookup::Unknown {
            status: Status::Cancelled,
            ..
        }
    ));
}
#[test]
fn shared_transfer_native_state_retains_prefix_deadline_and_actual_callback_return() {
    use core::cell::Cell;
    use r4os_sdk::{resources::Timeout, time::checked::ClockSample, transfer::*};
    assert_eq!(unsafe { sdk_transfer_c_case() }, 0);
    let mut info = abi::MonotonicClockInfo::default();
    info.flags = abi::monotonic_clock_flag_valid;
    info.source = 1;
    info.generation = 1;
    info.resolution_ns = 1;
    info.event_requested_hz = 1000;
    info.instant_ns = 100;
    let initial = ClockSample::from_info(&info).unwrap();
    let now = Cell::new(100);
    let mut clock = || {
        let mut value = info;
        value.instant_ns = now.get();
        ClockSample::from_info(&value).map_err(|_| Error(-101))
    };
    let mut writer = WriteAll::new(b"abcdef", initial, Timeout::AfterNanos(10)).unwrap();
    let one = writer
        .step(4, false, &mut clock, |c| {
            assert_eq!(c.offset, 0);
            assert_eq!(c.bytes, b"abcd");
            now.set(103);
            Ack::bytes(2)
        })
        .unwrap();
    assert_eq!((one.bytes, one.outcome), (2, Outcome::Pending));
    assert!(!one.in_call);
    let two = writer
        .step(4, false, &mut clock, |c| {
            assert_eq!(c.offset, 2);
            assert_eq!(c.bytes, b"cdef");
            now.set(110);
            Ack::bytes(1)
        })
        .unwrap();
    assert_eq!((two.bytes, two.outcome), (3, Outcome::TimedOut));
    assert!(two.terminal);
    let called = Cell::new(false);
    writer
        .step(4, false, &mut clock, |_| {
            called.set(true);
            Ack::bytes(0)
        })
        .unwrap();
    assert!(!called.get());
    now.set(100);
    let mut output = [0u8; 5];
    let mut reader = ReadExact::new(&mut output, initial, Timeout::AfterNanos(10)).unwrap();
    let eof = reader
        .step(5, false, &mut clock, |c| {
            c.bytes[..2].copy_from_slice(b"AB");
            Ack {
                bytes: 2,
                kind: IoKind::Eof,
                error_code: 0,
            }
        })
        .unwrap();
    assert_eq!((eof.bytes, eof.outcome), (2, Outcome::Eof));
    assert_eq!(reader.confirmed(), b"AB");
    let mut invalid = WriteAll::new(b"ab", initial, Timeout::AfterNanos(10)).unwrap();
    let result = invalid
        .step(2, false, &mut clock, |_| Ack::bytes(3))
        .unwrap();
    assert_eq!(
        (result.bytes, result.outcome),
        (0, Outcome::InvalidProgress)
    );
    assert!(result.effect_uncertain);
}
#[test]
fn shared_cli_grammar_and_record_sink_keep_input_loans_and_exact_accepted_bytes() {
    use r4os_sdk::cli::*;
    assert_eq!(unsafe { sdk_cli_c_case() }, 0);
    let mut cursor = ArgCursor::new(b" \"\" /Out:  cmd  \"a b\" ", ArgPolicy::default()).unwrap();
    let empty = cursor.next_token().unwrap().unwrap();
    assert!(empty.quoted());
    assert!(empty.bytes().is_empty());
    let option = cursor.next_token().unwrap().unwrap();
    assert!(option.switch_is(b"out").unwrap());
    assert_eq!(
        option.switch_parts().unwrap().unwrap().value,
        Some(&b""[..])
    );
    assert_eq!(cursor.remaining_raw().unwrap(), b"  cmd  \"a b\" ");
    assert_eq!(cursor.remaining_arguments().unwrap(), b"cmd  \"a b\" ");
    let mut bad = ArgCursor::new(b"x \"unterminated", ArgPolicy::default()).unwrap();
    assert!(bad.next_token().unwrap().is_some());
    assert_eq!(
        bad.next_token().err(),
        Some(ArgError {
            code: -5,
            offset: 2
        })
    );
    assert_eq!(
        bad.next_token().err(),
        Some(ArgError {
            code: -5,
            offset: 2
        })
    );
    assert_eq!(
        ArgCursor::new(b"\xc3x", ArgPolicy::default()).err(),
        Some(ArgError {
            code: -3,
            offset: 0
        })
    );
    let mut storage = [0u8; 24];
    let mut queue = BoundedDiagnosticBuffer::new(&mut storage).unwrap();
    assert_eq!(queue.append_record("€", Severity::Warning).unwrap().kind, 0);
    let mut bytes = Vec::new();
    let first = queue
        .flush_once(1, |c| {
            assert_eq!(c.total, 3);
            assert_eq!(c.offset, 0);
            bytes.extend_from_slice(c.bytes);
            Ack {
                accepted_bytes: 1,
                kind: SinkKind::Failed,
                error_code: -7,
            }
        })
        .unwrap();
    assert_eq!(
        (first.kind, first.accepted_bytes, first.completed_records),
        (3, 1, 0)
    );
    assert_eq!(queue.stats().unwrap().pending_bytes, 2);
    let blocked = queue
        .flush_once(8, |_| Ack {
            accepted_bytes: 0,
            kind: SinkKind::WouldBlock,
            error_code: 0,
        })
        .unwrap();
    assert_eq!((blocked.kind, queue.stats().unwrap().pending_bytes), (2, 2));
    let last = queue
        .flush_once(8, |c| {
            assert_eq!(c.offset, 1);
            bytes.extend_from_slice(c.bytes);
            Ack::accepted(c.bytes.len() as u32)
        })
        .unwrap();
    assert_eq!(last.completed_records, 1);
    assert_eq!(bytes, "€".as_bytes());
    queue.append_record("record", Severity::Error).unwrap();
    assert_eq!(
        queue
            .flush_once(8, |_| Ack {
                accepted_bytes: 0,
                kind: SinkKind::Uncertain,
                error_code: -10
            })
            .unwrap()
            .kind,
        4
    );
    assert_eq!(
        queue
            .flush_once(8, |_| panic!("poisoned buffer replayed"))
            .unwrap()
            .kind,
        5
    );
    assert_eq!(queue.discard().unwrap().uncertain, 1);
}
#[test]
fn shared_wire_cursor_checksum_and_geometry_keep_atomic_fields_and_explicit_units() {
    use r4os_sdk::wire::*;
    assert_eq!(unsafe { sdk_wire_c_case() }, 0);
    let bytes = [0xff, 1, 2, 3, 4, 5, 6, 7, 8];
    let mut reader = Reader::new(&bytes[1..]).unwrap();
    assert_eq!(reader.read_u16(Order::Big), Ok(0x0102));
    let mark = reader.checkpoint().unwrap();
    assert_eq!(reader.read_u64(Order::Little), Err(Error::Truncated));
    assert_eq!(reader.position(), 2);
    reader.restore(&mark).unwrap();
    assert_eq!(reader.take(2).unwrap(), [3, 4]);
    assert_eq!(reader.read_u32(Order::Little), Ok(0x08070605));
    let mut output = [0u8; 6];
    {
        let mut writer = Writer::new(&mut output).unwrap();
        writer.write_u16(0x1234, Order::Big).unwrap();
        let mark = writer.checkpoint().unwrap();
        writer.write_u32(0x55667788, Order::Little).unwrap();
        assert_eq!(writer.write_u8(1), Err(Error::Capacity));
        writer.restore(&mark).unwrap();
        writer.write_u8(0xff).unwrap();
        assert_eq!(writer.written().unwrap(), [0x12, 0x34, 0xff]);
    }
    assert_eq!(output, [0x12, 0x34, 0xff, 0x77, 0x66, 0x55]);
    let mut sum = InternetChecksum16::new().unwrap();
    sum.add(&[1]).unwrap();
    sum.add(&[2, 3]).unwrap();
    assert_eq!(sum.finish(), Ok(0xfbfd));
    assert_eq!(sum.finish(), Ok(0xfbfd));
    sum.add(&[4]).unwrap();
    assert_eq!(sum.finish(), Ok(0xfbf9));
    assert_eq!(sum.bytes_processed(), 4);
    let limits = BlockLimits {
        capacity_blocks: 1000,
        max_blocks: 128,
        max_bytes: 1048576,
        lba_bits: 28,
        buffer_mode: BufferMode::Exact,
    };
    assert_eq!(
        block_transfer(996, 4, 4096, 16384, limits),
        Ok(BlockShape {
            byte_count: 16384,
            last_lba: 999
        })
    );
    assert_eq!(
        block_transfer(997, 4, 4096, 16384, limits),
        Err(BlockError::OutOfRange)
    );
    assert_eq!(
        block_transfer(u64::MAX, 2, 1, 2, limits),
        Err(BlockError::Overflow)
    );
}
#[test]
fn native_record_intake_is_unsafe_and_output_does_not_read_uninitialized_payload() {
    use r4os_sdk::wire::native::*;
    #[repr(C)]
    #[derive(Clone, Copy)]
    struct Record {
        version: u32,
        size: u32,
        value: u64,
    }
    let header = Header {
        version_offset: Some(0),
        size_offset: Some(4),
        expected_version: 1,
    };
    let mut record = Record {
        version: 1,
        size: 16,
        value: 55,
    };
    let mut buffer = abi::ProtocolBuffer {
        data: (&mut record as *mut Record).cast(),
        len: 16,
        capacity: 16,
        flags: 0,
        reserved: 0,
    };
    {
        let input = unsafe { Input::<Record>::new(&buffer, SizeMode::Exact, header, 0) }.unwrap();
        assert_eq!(input.get().value, 55);
    }
    record.version = 2;
    // Renew the raw payload loan after the direct mutation of its owner.
    buffer.data = (&mut record as *mut Record).cast();
    assert!(matches!(
        unsafe { Input::<Record>::new(&buffer, SizeMode::Exact, header, 0) },
        Err(Error::UnsupportedVersion)
    ));
    let mut output = core::mem::MaybeUninit::<Record>::uninit();
    buffer = abi::ProtocolBuffer {
        data: output.as_mut_ptr().cast(),
        len: 0,
        capacity: 16,
        flags: 0,
        reserved: 0,
    };
    {
        let mut view =
            unsafe { Output::<Record>::new(&mut buffer, SizeMode::Exact, header, 0) }.unwrap();
        assert_eq!(
            view.write(Record {
                version: 2,
                size: 16,
                value: 7
            }),
            Err(Error::UnsupportedVersion)
        );
    }
    assert_eq!(buffer.len, 0);
    {
        let mut view =
            unsafe { Output::<Record>::new(&mut buffer, SizeMode::Exact, header, 0) }.unwrap();
        view.write(Record {
            version: 1,
            size: 16,
            value: 99,
        })
        .unwrap();
    }
    assert_eq!(buffer.len, 16);
    assert_eq!(unsafe { output.assume_init() }.value, 99);
}
const MANIFEST: &[u8] = include_bytes!("../Fixtures/Data/manifest.r4mf.txt");
#[test]
fn c_scalar_facades_use_original_state_error_values_and_allocator() {
    assert_eq!(
        unsafe { sdk_data_c_case(MANIFEST.as_ptr(), MANIFEST.len()) },
        0
    );
}
#[test]
fn original_streaming_hash_and_overlap_policy_preserve_exact_bytes() {
    let mut hash = Sha256::software().unwrap();
    hash.update(b"a").unwrap();
    hash.update(b"bc").unwrap();
    assert_eq!(hash.peek().unwrap(), hash.finish().unwrap());
    let mut out = [0; 32];
    let expected = digest(b"sHa-256", b"abc", &mut out).unwrap();
    assert_eq!(expected[0], 0xba);
    assert_eq!(expected[31], 0xad);
    assert!(digest(b"SHA-1", b"abc", &mut [0; 32]).is_err());
    assert!(digest(b"SHA-256", b"abc", &mut [0; 31]).is_err());
    let input: Vec<u8> = (0..12289).map(|i| (i * 73) as u8).collect();
    let expected = digest(b"SHA-256", &input, &mut out).unwrap();
    let mut streaming = Sha256::software().unwrap();
    for part in input.chunks(511) {
        streaming.update(part).unwrap();
    }
    assert_eq!(streaming.counters().unwrap(), (0, 0));
    assert_eq!(streaming.finish().unwrap(), expected);
    let policy = MemoryPolicy::from_info(&abi::CpuAccelerationInfo::default()).unwrap();
    let mut buffer: [u8; 32] = core::array::from_fn(|i| i as u8);
    let mut oracle = buffer;
    oracle.copy_within(0..24, 4);
    policy.copy_within(&mut buffer, 0..24, 4).unwrap();
    assert_eq!(buffer, oracle);
    assert!(policy.copy_within(&mut buffer, 0..33, 0).is_err());
}
#[test]
fn text_streams_and_url_views_preserve_owner_progress_and_failures() {
    assert_eq!(Encoding::parse(b"latin1").unwrap(), Encoding::Windows1252);
    assert!(Encoding::parse(b"utf-16").is_err());
    let mut d = Decoder::new(Encoding::Utf8, true, false).unwrap();
    let mut bytes = [0; 16];
    assert_eq!(d.decode(b"\xc3", &mut bytes, true).unwrap(), "");
    let mut d = Decoder::from_packed(d.packed().unwrap()).unwrap();
    assert_eq!(d.decode(b"\xbc", &mut bytes, false).unwrap(), "ü");
    assert!(d.decode(b"\xff", &mut bytes, false).is_err());
    assert_eq!(d.decode(b"A", &mut bytes, false).unwrap(), "A");
    assert_eq!(encode_into("🙂!", &mut [0; 3]).unwrap(), (0, 0));
    assert_eq!(encode_into("🙂!", &mut [0; 4]).unwrap(), (2, 4));
    let mut params = SearchParams::new(b"a=one+two&a=three&b=%e2%82%ac").unwrap();
    assert_eq!(params.get(b"a").unwrap(), Some(&b"one two"[..]));
    assert!(params.has(b"a", Some(b"three")).unwrap());
    params.delete(b"a", Some(b"one two")).unwrap();
    params.append(b"c", b"!").unwrap();
    params.sort().unwrap();
    let mut out = [0; 128];
    assert_eq!(
        params.serialize(&mut out).unwrap(),
        b"a=three&b=%E2%82%AC&c=%21"
    );
    assert_eq!(
        resolve_url(b"https://example.test", b"/a/b", b"../c?x=1", &mut out).unwrap(),
        b"https://example.test/c?x=1"
    );
}
#[test]
fn original_raster_resize_and_existing_ico_fixture_match_owner_oracles() {
    let mut pixels = [0; 16];
    let mut raster = Raster::new(&mut pixels, 2, 2, 0xffffff).unwrap();
    assert!(raster.set(1, 0, 0x010203).unwrap());
    raster.resize(3, 3, 0x090909).unwrap();
    assert_eq!(raster.pixel(1, 0).unwrap(), Some(0x010203));
    assert_eq!(raster.pixel(2, 2).unwrap(), Some(0x090909));
    assert!(raster.resize(129, 1, 0).is_err());
    assert_eq!(raster.pixels().unwrap().len(), 9);
    let icon = Icon::open(include_bytes!("../Fixtures/Icons/windows32.ico")).unwrap();
    assert_eq!(icon.count().unwrap(), 1);
    let image = icon.bitmap(0).unwrap();
    assert_eq!(image.dimensions().unwrap(), (2, 2));
    assert_eq!(image.pixel(0, 0).unwrap(), Some((0xff, 0xff)));
    assert_eq!(image.pixel(1, 0).unwrap().unwrap().1, 0);
    assert!(Icon::open(b"bad").is_err());
    for (bytes, colors) in [
        (
            include_bytes!("../Fixtures/Icons/windows32.ico").as_slice(),
            [0xff, 0xff00, 0xff0000, 0xffffff],
        ),
        (
            include_bytes!("../Fixtures/Icons/indexed8.ico").as_slice(),
            [0xff0000, 0xff, 0xff, 0xff0000],
        ),
    ] {
        assert_eq!(unsafe { sdk_ico_c_case(bytes.as_ptr(), bytes.len()) }, 0);
        let bitmap = Icon::open(bytes).unwrap().best_bitmap(32).unwrap();
        let mut rgb = [0x12345678; 24];
        let mut alpha = [91; 24];
        bitmap
            .copy_scaled_pixels(&mut rgb, &mut alpha, 4, 4, 6)
            .unwrap();
        for i in 0..24 {
            let (x, y) = (i % 6, i / 6);
            if x < 4 {
                let at = y / 2 * 2 + x / 2;
                assert_eq!(rgb[i], colors[at]);
                assert_eq!(alpha[i], [255, 0, 255, 255][at]);
            } else {
                assert_eq!((rgb[i], alpha[i]), (0x12345678, 91));
            }
        }
        let before = (rgb, alpha);
        assert_eq!(
            bitmap.copy_scaled_pixels(&mut rgb[..3], &mut alpha, 2, 2, 2),
            Err(r4os_sdk::data::Error::Bounds)
        );
        assert_eq!((rgb, alpha), before);
    }
}
#[test]
fn current_manifest_parser_plan_and_scratch_bounds_are_shared() {
    let mut storage = pin!(ArenaStorage::new());
    let mut bytes = [0; 65536];
    let mut arena = Arena::open(storage.as_mut(), &mut bytes).unwrap();
    {
        let m = arena.manifest(b"module.R4MF", MANIFEST).unwrap();
        assert_eq!(m.name().unwrap(), b"DATAUNIT");
        assert_eq!(m.version().unwrap(), (1, 2, 3));
        let mut plan = [0; 8192];
        let (text, ok) = m.contract_plan(&mut plan).unwrap();
        assert!(ok && text.windows(8).any(|b| b == b"DATAUNIT"));
    }
    assert!(arena.used().unwrap() > 0);
    arena.reset().unwrap();
    assert_eq!(arena.used().unwrap(), 0);
    assert!(
        arena
            .manifest(b"module.R4MF", b"R4OS_MODULE_MANIFEST=1\n")
            .is_err()
    );
    let mut small_storage = pin!(ArenaStorage::new());
    let mut tiny = [0; 8];
    let mut small = Arena::open(small_storage.as_mut(), &mut tiny).unwrap();
    assert!(small.manifest(b"module.R4MF", MANIFEST).is_err());
}

#[test]
fn prepared_text_metrics_use_shared_rows_keys_and_checked_font_invalidations() {
    use core::mem::MaybeUninit;
    use r4os_sdk::{platform2::Context, text_metrics::*};
    assert_eq!(unsafe { sdk_textmetrics_c_case() }, 0);
    let mut sys = abi::generation2::R4XStartR4Sys2::default();
    let mut draw = abi::generation2::R4XStartR4Draw2::default();
    unsafe { sdk_textmetrics_tables(&mut sys, &mut draw) };
    let imports = [
        abi::R4XStartImport {
            group_id: 1,
            resolved_version: 2,
            table: &sys as *const _ as u64,
            ..Default::default()
        },
        abi::R4XStartImport {
            group_id: 3,
            resolved_version: 2,
            table: &draw as *const _ as u64,
            ..Default::default()
        },
    ];
    let raw = abi::generation2::R4XStartContext2 {
        import_count: 2,
        imports: imports.as_ptr() as u64,
        ..Default::default()
    };
    let context = unsafe { Context::new(&raw) }.unwrap();
    let mut rows = [MaybeUninit::uninit(); 2];
    let mut cache = Cache::new(&context, "Wi", &mut rows).unwrap();
    assert!(cache.key().is_err());
    let done = cache.prepare(9, 33).unwrap();
    assert!(done.complete && !done.in_call);
    assert_eq!(done.count, 2);
    let key = cache.key().unwrap();
    assert_eq!(key.font_revision, 41);
    for _ in 0..100 {
        assert_eq!(cache.hit(key, 5).unwrap(), 1);
    }
    assert_eq!(unsafe { sdk_textmetrics_calls() }, 1);
    assert_eq!(cache.rows().unwrap()[1].prefix_width, 14);
    let mut wrong = key;
    wrong.text_revision += 1;
    assert_eq!(cache.hit(wrong, 5).unwrap_err().code, -10);
    cache.validate_font().unwrap();
    assert_eq!(unsafe { sdk_textmetrics_calls() }, 2);
    unsafe { sdk_textmetrics_mode(1) };
    assert_eq!(cache.validate_font().unwrap_err().code, -10);
    assert!(cache.rows().is_err());
    unsafe { sdk_textmetrics_mode(2) };
    assert_eq!(cache.prepare(9, 33).err().unwrap().code, -9);
    assert!(!cache.progress().unwrap().complete);
    cache.reset().unwrap();
}

#[test]
fn bounded_picker_shared_owner_keeps_whole_views_errors_and_explicit_save_policy() {
    use core::{ffi::CStr, mem::MaybeUninit};
    use r4os_sdk::{file_picker::*, platform2::Context};
    unsafe extern "C" {
        fn sdk_picker24_c_case() -> i32;
        fn sdk_picker24_tables(table: *mut abi::generation2::R4XStartR4Sys2);
        fn sdk_picker24_mode(mode: i32);
        fn sdk_picker24_calls() -> u32;
    }
    assert_eq!(unsafe { sdk_picker24_c_case() }, 0);
    let mut table = abi::generation2::R4XStartR4Sys2::default();
    unsafe { sdk_picker24_tables(&mut table) };
    let imports = [abi::R4XStartImport {
        group_id: 1,
        resolved_version: 2,
        table: &table as *const _ as u64,
        ..Default::default()
    }];
    let raw = abi::generation2::R4XStartContext2 {
        import_count: 1,
        imports: imports.as_ptr() as u64,
        ..Default::default()
    };
    let context = unsafe { Context::new(&raw) }.unwrap();
    let mut a = [MaybeUninit::<Row>::uninit(); 6];
    let mut b = [MaybeUninit::<Row>::uninit(); 6];
    let mut s = Session::new(&context, &mut a, &mut b, Mode::Save, b".TXT").unwrap();
    assert!(s.rows().is_err());
    s.begin(c"C:\\DIR", 0).unwrap();
    for _ in 0..20 {
        let before = unsafe { sdk_picker24_calls() };
        let p = s.step(1).unwrap();
        assert!(unsafe { sdk_picker24_calls() } - before <= 1);
        if p.flags & 2 == 0 {
            break;
        }
    }
    let p = s.progress().unwrap();
    assert_eq!((p.flags, p.count, p.revision), (1, 4, 1));
    assert_eq!(s.rows().unwrap().len(), 4);
    assert_eq!(s.directory().unwrap(), c"C:\\DIR");
    s.select(p.revision, 1, 2).unwrap();
    assert_eq!(s.activate(p.revision, false, false).unwrap().kind, 2);
    assert_eq!(s.selection().kind, 0);
    let confirmed = s.activate(p.revision, false, true).unwrap();
    assert_eq!(confirmed.kind, 1);
    assert_eq!(confirmed.entry.info.identity.object_hi, 2);
    unsafe { sdk_picker24_mode(9) };
    assert_eq!(s.activate(p.revision, false, true).err(), Some(Error(-10)));
    let fields = |v: &abi::FileIdentity2| {
        (
            v.mount_generation,
            v.namespace_generation,
            v.object_hi,
            v.object_lo,
            v.mount_slot,
            v.provider,
            v.flags,
            v.reserved0,
        )
    };
    assert_eq!(
        fields(&s.selection().entry.info.identity),
        fields(&confirmed.entry.info.identity)
    );
    unsafe { sdk_picker24_mode(0) };
    s.set_name("A.TXT").unwrap();
    assert_eq!(s.activate(p.revision, true, false).unwrap().kind, 2);
    unsafe { sdk_picker24_mode(9) };
    assert_eq!(s.activate(p.revision, true, true).err(), Some(Error(-10)));
    unsafe { sdk_picker24_mode(0) };
    assert_eq!(s.activate(p.revision, true, true).unwrap().kind, 1);
    s.set_name("NEW.TXT").unwrap();
    assert_eq!(s.set_name(".."), Err(Error(-201)));
    assert_eq!(s.filename().unwrap(), c"NEW.TXT");
    let d = s.activate(p.revision, true, false).unwrap();
    assert_eq!((d.kind, d.entry.info.flags), (1, 0));
    assert_eq!(
        CStr::from_bytes_until_nul(&d.entry.path).unwrap(),
        c"C:\\DIR\\NEW.TXT"
    );
    unsafe { sdk_picker24_mode(-9) };
    s.begin(c"C:\\DIR", 1).unwrap();
    assert_eq!(s.step(64).err(), Some(Error(-9)));
    assert_eq!(s.progress().unwrap().revision, 1);
    assert_eq!(s.rows().unwrap().len(), 4);
    assert_eq!(s.cancel().unwrap().kind, 3);
    assert_eq!(s.step(1).err(), Some(Error(-206)));
    assert_eq!(s.selection().kind, 1);
}
#[path = "AudioWrite.rs"]
mod audio_write25;
