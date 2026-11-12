#![cfg(test)]
use r4os_sdk::{
    App, ImportSpec, StartupInfo, abi,
    network::{Network, SocketService},
    resources::Timeout,
    serial::Serial,
    services::{Call, Receive, Services, Wake},
    time,
};
use std::alloc::{GlobalAlloc, Layout, System};
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
struct Tracking;
static TRACK: AtomicBool = AtomicBool::new(false);
static WATCH: AtomicUsize = AtomicUsize::new(0);
static FREED: AtomicUsize = AtomicUsize::new(0);
unsafe impl GlobalAlloc for Tracking {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        let p = unsafe { System.alloc(layout) };
        if layout.size() == core::mem::size_of::<r4os_sdk::network::RawRequest>()
            && TRACK.swap(false, Ordering::Relaxed)
        {
            WATCH.store(p.addr(), Ordering::Relaxed);
        }
        p
    }
    unsafe fn dealloc(&self, p: *mut u8, layout: Layout) {
        if p.addr() == WATCH.load(Ordering::Relaxed) {
            FREED.fetch_add(1, Ordering::Relaxed);
        }
        unsafe { System.dealloc(p, layout) }
    }
}
#[global_allocator]
static ALLOCATOR: Tracking = Tracking;
unsafe extern "C" {
    fn sdk_inventory_c_case() -> i32;
    fn sdk_inventory_tables(sys: *mut abi::R4XStartR4Sys);
    fn sdk_inventory_reset(mode: u32);
    fn sdk_link_c_case() -> i32;
    fn sdk_link_tables(sys: *mut abi::R4XStartR4Sys);
    fn sdk_link_activations() -> u32;
    fn sdk_service_c_case() -> i32;
    fn sdk_service_tcp_deadline_case() -> i32;
    fn sdk_service_tcp_readiness_case() -> i32;
    fn sdk_service_tcp_close_receipt_case() -> i32;
    fn sdk_service_clock_rate(value: u32);
    fn sdk_service_calendar_calls() -> u32;
    fn sdk_service_call_timeout() -> u64;
    fn sdk_service_extra_c_case() -> i32;
    fn sdk_service_bound_c_case() -> i32;
    fn sdk_service_bound_reset();
    fn sdk_service_bound_result(value: i32);
    fn sdk_service_bound_replace();
    fn sdk_service_bound_ack();
    fn sdk_service_bound_closes() -> u32;
    fn sdk_service_bound_budget() -> u64;
    fn sdk_net_current_admission(start: *const abi::R4XStartContext) -> i32;
    fn sdk_service_tables(
        sys: *mut abi::R4XStartR4Sys,
        net: *mut abi::R4XStartR4Net,
        desk: *mut abi::R4XStartR4Desk,
        dev: *mut abi::R4XStartR4Dev,
    );
    fn sdk_service_mode(value: u32);
    fn sdk_service_queue(value: u32);
    fn sdk_service_stop(value: u32);
    fn sdk_service_cancel_reply(value: u32);
    fn sdk_service_yielded() -> u32;
    fn sdk_service_last_wait() -> u64;
    fn sdk_service_open_handles() -> u32;
    fn sdk_service_complete();
    fn sdk_service_reap_pending();
    fn sdk_serial_busy(value: u32);
    fn sdk_serial_live() -> u32;
}
#[test]
fn service_network_serial_deadline_owners_and_retained_requests() {
    assert_eq!(unsafe { sdk_service_tcp_deadline_case() }, 0);
    assert_eq!(unsafe { sdk_service_tcp_readiness_case() }, 0);
    assert_eq!(unsafe { sdk_service_tcp_close_receipt_case() }, 0);
    assert_eq!(unsafe { sdk_service_c_case() }, 0);
    assert_eq!(unsafe { sdk_service_extra_c_case() }, 0);
    assert_eq!(unsafe { sdk_service_bound_c_case() }, 0);
    let (mut sys, mut net, mut desk, mut dev) = (
        abi::R4XStartR4Sys::default(),
        abi::R4XStartR4Net::default(),
        abi::R4XStartR4Desk::default(),
        abi::R4XStartR4Dev::default(),
    );
    unsafe { sdk_service_tables(&mut sys, &mut net, &mut desk, &mut dev) };
    let records = [
        (
            abi::R4LGroup::r4sys.0,
            c"R4SYS",
            (&sys as *const _) as u64,
            sys.magic,
            sys.abi_version,
            sys.size,
        ),
        (
            abi::R4LGroup::r4net.0,
            c"R4NET",
            (&net as *const _) as u64,
            net.magic,
            net.abi_version,
            net.size,
        ),
        (
            abi::R4LGroup::r4desk.0,
            c"R4DESK",
            (&desk as *const _) as u64,
            desk.magic,
            desk.abi_version,
            desk.size,
        ),
        (
            abi::R4LGroup::r4dev.0,
            c"R4DEV",
            (&dev as *const _) as u64,
            dev.magic,
            dev.abi_version,
            dev.size,
        ),
    ];
    let imports = records.map(|(id, name, table, _, _, _)| abi::R4XStartImport {
        group_id: id,
        min_version: 1,
        resolved_version: 1,
        flags: abi::r4xstart_import_flag_group_interface,
        module_name: name.as_ptr() as u64,
        symbol_name: c"Query".as_ptr() as u64,
        table,
    });
    let specs = records.map(|(id, name, _, magic, version, size)| ImportSpec {
        module_name: name.to_bytes(),
        symbol_name: b"Query",
        minimum: 1,
        optional: false,
        group_id: id,
        magic,
        version,
        size,
    });
    let ctx = abi::R4XStartContext {
        app_class: abi::R4XStartAppClass::console.0,
        instance_id: 42,
        flags: abi::r4xstart_flag_imports_valid,
        imports: imports.as_ptr() as u64,
        import_count: 4,
        ..Default::default()
    };
    let expected = StartupInfo {
        app_class: abi::R4XStartAppClass::console,
        required_groups: records.iter().fold(0, |m, r| m | (1 << r.0)),
        imports: &specs,
    };
    let app = unsafe { App::from_raw(&ctx, &expected, c"SERVICE-INTEROP") }.unwrap();
    let services = Services::new(&app).unwrap();
    assert!(services.available());
    assert_eq!(unsafe { sdk_inventory_c_case() }, 0);
    unsafe {
        sdk_inventory_tables(&mut sys);
        sdk_inventory_reset(1);
    }
    assert!(services.inventory_available());
    let inventory = services.inventory().unwrap();
    assert_eq!(inventory.rows.len(), 300);
    assert_eq!(inventory.revision, 12);
    for (index, row) in inventory.rows.iter().enumerate() {
        assert_eq!(row.registration_id, index as u64 + 1);
    }
    services
        .control_entry(
            &inventory.rows[299],
            r4os_sdk::services::InventoryAction::Start,
        )
        .unwrap();
    let mut stale = inventory.rows[299];
    stale.process.generation -= 1;
    assert_eq!(
        services.control_entry(&stale, r4os_sdk::services::InventoryAction::Start),
        Err(r4os_sdk::storage::Error::Raw(abi::service_api_result_busy))
    );
    drop(inventory);
    unsafe {
        sdk_inventory_reset(2);
    }
    assert!(
        matches!(services.inventory(),Err(r4os_sdk::storage::Error::Raw(code)) if code==abi::service_api_result_busy)
    );
    unsafe {
        sdk_inventory_reset(0);
    }

    assert_eq!(unsafe { sdk_link_c_case() }, 0);
    unsafe { sdk_link_tables(&mut sys) };
    let link_scope = services.link_scope().unwrap();
    assert!(r4os_sdk::services::link_supported(&link_scope));
    let link_intent = r4os_sdk::services::prepare_link_binding(
        link_scope.request.token,
        abi::ProgramProcessHandle {
            instance_id: 42,
            generation: 123,
            reserved: 0,
        },
        [1, 2, 3],
        999,
        b"C:\\TEMP\\SELF.LNK",
        b"R4S_FORMAT=1\nSCHEMA=R4LNK\nTARGET=C:\\TEMP\\SELF.R4X\n",
    )
    .unwrap();
    let link_saved = services.link_prepare(&link_intent).unwrap().request;
    assert_eq!(link_saved.token.serial, 55);
    assert!(
        matches!(services.link_activate(&link_saved),Err(r4os_sdk::storage::Error::Raw(code)) if code == abi::service_api_result_timeout)
    );
    let link_readback = services.link_status(&link_saved).unwrap();
    assert_eq!(link_readback.process.generation, 0xfedcba9876543210);
    assert_eq!(unsafe { sdk_link_activations() }, 1);

    let bound = services.bound_detail(c"MANAGED").unwrap();
    assert_eq!(bound.process.instance_id, 41);
    assert_eq!(bound.process.generation, 0x1122334455667788);
    unsafe { sdk_service_bound_replace() };
    assert_eq!(
        services
            .stop_bound(c"MANAGED", &bound.process, Timeout::Poll)
            .raw_code,
        abi::service_api_result_busy
    );
    assert_eq!(unsafe { sdk_service_bound_closes() }, 0);
    let replacement = services.bound_detail(c"MANAGED").unwrap();
    assert_eq!(replacement.process.instance_id, bound.process.instance_id);
    assert_eq!(replacement.process.generation, bound.process.generation + 1);
    let pending = services.stop_bound(
        c"MANAGED",
        &replacement.process,
        Timeout::AfterNanos(7_000_000),
    );
    assert_eq!(pending.raw_code, abi::service_api_result_timeout);
    assert_eq!(pending.info.instance_id, 41);
    assert_eq!(unsafe { sdk_service_bound_budget() }, 7);
    assert_eq!(unsafe { sdk_service_bound_closes() }, 1);
    unsafe { sdk_service_bound_ack() };
    let terminal = services.bound_detail(c"MANAGED").unwrap();
    assert_eq!(terminal.detail.info.instance_id, 0);
    assert_eq!(terminal.detail.info.exit_code, -23);
    assert_eq!(terminal.process.generation, replacement.process.generation);
    assert_eq!(
        services
            .stop_bound(c"MANAGED", &replacement.process, Timeout::Poll)
            .raw_code,
        0
    );
    // Capability truncation is exercised by the actual C consumer above.
    // Keep this admitted Rust table immutable and test error propagation via
    // the shared callback instead of changing its live ABI header.
    unsafe { sdk_service_bound_result(abi::err_no_fn) };
    assert!(matches!(
        services.bound_detail(c"MANAGED"),
        Err(r4os_sdk::storage::Error::Raw(abi::err_no_fn))
    ));
    unsafe { sdk_service_bound_reset() };
    let mut response = [0; 16];
    let mut connection = services.open(c"EXAMPLE").unwrap();
    let calendar_before = unsafe { sdk_service_calendar_calls() };
    for (hz, ticks) in [(1000, 18), (250, 5)] {
        unsafe { sdk_service_clock_rate(hz) };
        assert!(matches!(
            connection
                .call(7, b"PING", &mut response, Timeout::AfterNanos(17_000_001))
                .unwrap(),
            Call::Response { .. }
        ));
        assert_eq!(unsafe { sdk_service_call_timeout() }, ticks);
    }
    assert_eq!(unsafe { sdk_service_calendar_calls() }, calendar_before);
    unsafe { sdk_service_clock_rate(1000) };

    assert!(matches!(
        connection
            .call(7, b"PING", &mut response, Timeout::Forever)
            .unwrap(),
        Call::Response { bytes: 4, .. }
    ));
    assert_eq!(&response[..4], b"PING");
    assert!(matches!(
        connection
            .call(999, &[], &mut response, Timeout::Poll)
            .unwrap(),
        Call::RemoteFailure(_)
    ));
    connection.close().unwrap();
    assert_eq!(connection.handle(), 0);
    assert_eq!(connection.info.handle, 0);
    check_service_loop(&services, &mut response);

    assert_eq!(
        time::duration_to_ticks(time::Duration { nanoseconds: 1 }, 333).unwrap(),
        1
    );
    assert_eq!(
        time::duration_from_ticks(1, 333).unwrap().nanoseconds,
        3_003_004
    );
    assert!(time::duration_from_ticks(1, 0).is_err());
    assert_eq!(
        time::remaining_ticks(
            time::Deadline { nanoseconds: 5 },
            time::Instant { nanoseconds: 5 },
            0
        )
        .unwrap(),
        0
    );
    assert_eq!(
        time::request_deadline(Timeout::AfterNanos(2_000_000_000), 100, 10).unwrap(),
        120
    );
    assert_eq!(
        time::request_remaining(120, 115, 10),
        Timeout::AfterNanos(500_000_000)
    );
    let mut wire = [0; 64];
    let n = time::append_deadline(&mut wire, b"request", 120)
        .unwrap()
        .len();
    assert_eq!(
        time::split_deadline(&wire[..n]).unwrap(),
        (&b"request"[..], Some(120))
    );
    assert_eq!(
        time::split_deadline(b"plain-current-request").unwrap(),
        (&b"plain-current-request"[..], None)
    );
    wire[b"request".len()] ^= 1;
    assert_eq!(time::split_deadline(&wire[..n]).unwrap().1, None);

    let network = Network::new(&app).unwrap();
    assert_eq!(unsafe { sdk_net_current_admission(app.start_context()) }, 0);
    use r4os_sdk::network::{Ipv4Address, SocketAddress, SocketState};
    assert!(network.available());
    assert_eq!(
        network
            .resolve_a(b"r4os.local", None, Timeout::Forever)
            .unwrap(),
        Ipv4Address([10, 0, 2, 15])
    );
    let address = SocketAddress {
        address: Ipv4Address([10, 0, 2, 2]),
        port: 1234,
    };
    let mut tcp = network.connect_tcp(address, Timeout::Forever).unwrap();
    assert_eq!(tcp.remote(), address);
    let ready = tcp.readiness(Timeout::Poll);
    assert_eq!(ready.outcome.bytes, 0);
    assert_eq!(ready.readiness.unwrap().pending_rx, 4);
    unsafe { sdk_service_mode(6) };
    assert_eq!(tcp.write(b"GET", Timeout::Forever).bytes, 2);
    assert_eq!(tcp.handle(), 501);
    let mut borrowed = network.borrow_tcp(tcp.handle(), address);
    assert_eq!(borrowed.close(Timeout::Poll).raw_code, abi::err_not_owned);
    unsafe { sdk_service_mode(1) };
    assert_eq!(
        tcp.read(&mut response, Timeout::Poll).state,
        SocketState::WouldBlock
    );
    assert!(tcp.valid());
    unsafe { sdk_service_mode(4) };
    assert_eq!(
        tcp.read(&mut response, Timeout::Forever).state,
        SocketState::PeerClosed
    );
    assert!(tcp.valid());
    unsafe { sdk_service_mode(0) };
    assert_eq!(tcp.close(Timeout::Forever).state, SocketState::Closed);
    assert!(!tcp.valid());
    unsafe { sdk_service_mode(0) };
    let mut listener = network.listen_tcp(1234, Timeout::Forever).unwrap();
    let mut accepted = listener.accept(Timeout::Poll).unwrap();
    assert_eq!(accepted.close(Timeout::Forever).state, SocketState::Closed);
    assert_eq!(listener.close(Timeout::Forever).state, SocketState::Closed);
    let mut socket = network.bind_udp(8000, Timeout::Forever).unwrap();
    assert_eq!(socket.send_to(address, b"UDP", Timeout::Forever).bytes, 3);
    let (result, datagram) = socket.receive_from(&mut response, Timeout::Forever);
    assert_eq!(result.state, SocketState::Ok);
    assert_eq!(datagram.bytes, 3);
    assert_eq!(&response[..3], b"UDP");
    assert_eq!(socket.close(Timeout::Forever).state, SocketState::Closed);
    // No legacy raw IPC substitution when the current callback is absent.
    let before_missing = response;
    let mut current_reply = [0xB7; abi::net_service_header_size as usize];
    let before_reply = current_reply;
    assert_eq!(
        network.net_service_request(1, 2, 3, &[], &mut current_reply),
        abi::err_no_fn
    );
    assert_eq!(current_reply, before_reply);
    // Exact shared wire bounds are checked before optional capability lookup.
    assert_eq!(
        network.net_service_request(1, 2, 3, &[], &mut response),
        abi::net_service_result_bad_request
    );
    assert_eq!(response, before_missing);
    let mut structured = abi::NetServiceTcpResult::default();
    assert_eq!(
        network.tcp_connect_service_result(10, 0, 2, 2, 1234, &mut structured),
        501
    );
    assert_eq!(structured.handle, 501);
    assert_eq!(
        network.tcp_write_chunk_service_result(501, b"GET", &mut structured),
        3
    );
    assert_eq!(structured.bytes, 3);
    assert_eq!(
        network.tcp_read_service_result(501, &mut response, &mut structured),
        2
    );
    assert_eq!(&response[..2], b"OK");
    unsafe { sdk_service_mode(6) };
    assert_eq!(
        network.tcp_write_chunk_service_result(501, b"GET", &mut structured),
        2
    );
    assert_eq!(structured.bytes, 2);
    unsafe { sdk_service_mode(1) };
    assert_eq!(network.tcp_poll_service(501, &mut structured), 0);
    assert_ne!(
        network.tcp_readiness_from_result(&structured).would_block,
        0
    );
    unsafe { sdk_service_mode(0) };
    let mut udp = abi::NetServiceUdpResult::default();
    let mut source = abi::UdpRecvInfo::default();
    assert_eq!(network.udp_bind_service(8000), 601);
    assert_eq!(
        network.udp_recv_from_service_result(601, &mut source, &mut response, &mut udp),
        3
    );
    assert_eq!(&response[..3], b"UDP");
    assert_eq!(network.udp_close_service(601), 0);
    assert_eq!(unsafe { sdk_service_open_handles() }, 0);

    check_owned_requests(&network);
    let serial = Serial::new(&app).unwrap();
    let info = serial.find(3).unwrap();
    assert!(serial.find(4).is_none());
    assert_eq!(info.generation, 0x99aabbccddeeff00);
    let mut port = serial.open(&info, &abi::SerialConfig::default()).unwrap();
    let read = port.read(&mut response, 19);
    assert_eq!(read.code, abi::serial_error_timeout);
    assert_eq!(read.info.completed, 2);
    assert_eq!(&response[..2], b"RX");
    let write = port.write(b"SEND", 19);
    assert_eq!(write.code, 0);
    assert_eq!(write.info.completed, 2);
    unsafe { sdk_serial_busy(1) };
    assert_eq!(port.close(0, 0), abi::serial_error_busy);
    assert_ne!(port.handle(), 0);
    assert_eq!(unsafe { sdk_serial_live() }, 1);
    assert_eq!(port.cancel(), 0);
    assert_eq!(port.close(0, 0), 0);
    assert_eq!(port.handle(), 0);
    actual_app2_service_loop_and_network_use_the_same_original_oracles();
}

fn check_service_loop(services: &Services<'_>, response: &mut [u8]) {
    let mut endpoint = services.register(c"EXAMPLE", 0).unwrap();
    assert_eq!(endpoint.wait(Timeout::Poll).unwrap(), None);
    let mut loop_owner = endpoint.service_loop(200, 2).unwrap();
    assert!(matches!(
        loop_owner.wait(Some(100)).unwrap(),
        Wake::Deadline
    ));
    assert!(matches!(loop_owner.wait(Some(105)).unwrap(), Wake::Idle));
    assert_eq!(unsafe { sdk_service_last_wait() }, 5);
    unsafe { sdk_service_queue(3) };
    assert!(matches!(loop_owner.wait(None).unwrap(), Wake::Requests(3)));
    let mut processed = 0;
    assert_eq!(
        loop_owner.drain(3, || {
            match endpoint.receive(response).unwrap() {
                Receive::Message { header, bytes: 4 } => {
                    processed += 1;
                    endpoint.reply(header.request_id, 0, &[])
                }
                _ => -99,
            }
        }),
        0
    );
    assert_eq!(processed, 2);
    assert_eq!(unsafe { sdk_service_yielded() }, 1);
    assert_eq!(
        loop_owner.drain(0, || {
            match endpoint.receive(response).unwrap() {
                Receive::Message { header, .. } => endpoint.reply(header.request_id, 0, &[]),
                _ => -99,
            }
        }),
        0
    );
    assert_eq!(loop_owner.metrics().drained_requests, 3);
    assert_eq!(loop_owner.metrics().limited_batches, 1);
    let mut report = [0; 384];
    let n = loop_owner.format_report(b"EXAMPLE", &mut report).unwrap();
    assert!(report[..n].starts_with(b"SVCLOOP|1|EXAMPLE|"));
    unsafe { sdk_service_cancel_reply(1) };
    assert_eq!(
        endpoint.reply(88, 0, &[]),
        abi::service_api_result_not_found
    );
    assert_eq!(endpoint.reply_if_pending(88, 0, &[]), 0);
    unsafe {
        sdk_service_cancel_reply(0);
        sdk_service_stop(1);
    }
    assert!(matches!(loop_owner.wait(None).unwrap(), Wake::Stop));
    drop(loop_owner);
    endpoint.close().unwrap();
    assert_eq!(endpoint.handle(), 0);
    assert_eq!(endpoint.info.handle, 0);
    unsafe { sdk_service_stop(0) };
}

fn actual_app2_service_loop_and_network_use_the_same_original_oracles() {
    use r4os_sdk::app2::{App, ImportSpec, StartupInfo};
    unsafe extern "C" {
        fn sdk_service2_tables(
            sys: *mut abi::generation2::R4XStartR4Sys2,
            net: *mut abi::generation2::R4XStartR4Net2,
        );
        fn sdk_service2_should_close(raw: *const abi::generation2::R4XStartContext2) -> u32;
        fn sdk_service2_yield(raw: *const abi::generation2::R4XStartContext2);
    }
    let mut sys = abi::generation2::R4XStartR4Sys2::default();
    let mut net = abi::generation2::R4XStartR4Net2::default();
    unsafe { sdk_service2_tables(&mut sys, &mut net) };
    let groups = [
        (1, c"R4SYS", &sys as *const _ as u64),
        (4, c"R4NET", &net as *const _ as u64),
    ];
    let imports = groups.map(|(group_id, name, table)| abi::R4XStartImport {
        group_id,
        table,
        min_version: 2,
        resolved_version: 2,
        flags: abi::r4xstart_import_flag_group_interface,
        module_name: name.as_ptr() as u64,
        symbol_name: c"Query2".as_ptr() as u64,
    });
    let specs = groups.map(|(group_id, name, _)| ImportSpec {
        group_id,
        module_name: name.as_ptr().cast(),
        symbol_name: c"Query2".as_ptr().cast(),
        minimum: 2,
        optional: 0,
        reserved: 0,
    });
    let raw = abi::generation2::R4XStartContext2 {
        instance_id: 43,
        app_class: abi::R4XStartAppClass::console.0,
        flags: abi::r4xstart_flag_imports_valid
            | abi::r4xstart_flag_close_supported
            | abi::r4xstart_flag_yield_supported,
        import_count: 2,
        imports: imports.as_ptr() as u64,
        should_close: sdk_service2_should_close as *const () as u64,
        r#yield: sdk_service2_yield as *const () as u64,
        ..Default::default()
    };
    let facts = StartupInfo {
        profile: abi::R4AppProfile::console.0 as u32,
        app_class: abi::R4XStartAppClass::console.0,
        required_groups: 2,
        imports: &specs,
    };
    let app = unsafe { App::from_raw(&raw, &facts, c"SERVICE2-INTEROP") }.unwrap();
    let services = app.services().unwrap();
    let network = app.network().unwrap();
    assert_eq!(network.ipc_poll(11), 17);
    check_owned_requests(&network);
    let mut response = [0; 512];
    check_service_loop(&services, &mut response);
}

fn check_owned_requests(network: &Network<'_>) {
    TRACK.store(true, Ordering::Relaxed);
    FREED.store(0, Ordering::Relaxed);
    let mut request = network.request();
    assert_ne!(WATCH.load(Ordering::Relaxed), 0);
    assert_eq!(
        request.net_socket_begin(SocketService::Tcp, 37, b"PING", 17),
        0
    );
    assert!(request.active());
    assert!(!request.completed());
    assert!(request.response().is_none());
    assert_eq!(request.reset(), abi::io_error_busy);
    assert_eq!(request.wait(0), abi::io_error_timeout);
    assert_eq!(request.close(), abi::io_error_busy);
    assert!(request.active());
    unsafe { sdk_service_complete() };
    assert_eq!(request.wait(17), 0);
    let result = request.tcp_result().unwrap();
    assert_eq!(request.tcp_data(&result).unwrap(), b"OK");
    assert_eq!(request.close(), 0);
    assert!(!request.active());
    drop(request);
    assert_eq!(FREED.load(Ordering::Relaxed), 1);
    TRACK.store(true, Ordering::Relaxed);
    FREED.store(0, Ordering::Relaxed);
    let mut request = network.request();
    assert_eq!(
        request.net_socket_begin(SocketService::Tcp, 37, b"PING", 17),
        0
    );
    drop(request);
    assert_eq!(FREED.load(Ordering::Relaxed), 0);
    unsafe { sdk_service_complete() };
    // Simulate the instance-reaper's native completion, preserving the loaned
    // allocation. The deliberately dropped object has no Rust owner to resume.
    assert_eq!(FREED.load(Ordering::Relaxed), 0);

    unsafe { sdk_service_reap_pending() };
    TRACK.store(true, Ordering::Relaxed);
    FREED.store(0, Ordering::Relaxed);
    let mut forgotten = network.request();
    assert_eq!(
        forgotten.net_socket_begin(SocketService::Tcp, 37, b"PING", 17),
        0
    );
    core::mem::forget(forgotten);
    assert_eq!(FREED.load(Ordering::Relaxed), 0);
    unsafe {
        sdk_service_complete();
        sdk_service_reap_pending();
    }
    assert_eq!(FREED.load(Ordering::Relaxed), 0);
    assert_eq!(unsafe { sdk_service_open_handles() }, 0);
}
