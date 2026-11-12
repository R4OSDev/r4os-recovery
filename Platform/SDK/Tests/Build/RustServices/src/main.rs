#![no_std]
use r4os_sdk::{
    App, abi,
    network::{Ipv4Address, Network, SocketAddress, SocketState},
    path::FilePath,
    resources::Timeout,
    serial::Serial,
    services::{Call, Services, TrayItem},
    time,
};
unsafe extern "C" {
    fn sdk55_c_network(context: *const abi::R4XStartContext) -> i32;
}
fn exercise(app: &App<'_>, services: &Services<'_>) -> i32 {
    let mut response = [0; 64];
    let clock = time::Clock::new(app);
    let Ok(state) = clock.state() else {
        return 10;
    };
    let Ok(tick) = clock.ticks() else {
        return 10;
    };
    let Ok(deadline) =
        time::request_deadline(Timeout::AfterNanos(2_000_000_000), tick, state.monotonic_hz)
    else {
        return 10;
    };
    let mut connection = loop {
        match services.open(c"NET55SVC") {
            Ok(v) => break v,
            Err(_) => {
                if clock.ticks().unwrap_or(u64::MAX) >= deadline {
                    return 11;
                }
                app.sleep(1);
            }
        }
    };
    for payload in [&b"Rust service"[..], &b""[..]] {
        match connection.call(
            1,
            payload,
            &mut response,
            Timeout::AfterNanos(2_000_000_000),
        ) {
            Ok(Call::Response { bytes, .. })
                if bytes == payload.len() && response[..bytes] == *payload => {}
            _ => return 12,
        }
    }
    if !matches!(
        connection.call(
            9,
            b"late reply",
            &mut response,
            Timeout::AfterNanos(1_000_000)
        ),
        Ok(Call::TimedOut)
    ) {
        return 13;
    }
    app.sleep(20);
    if !matches!(
        connection.call(
            1,
            b"next",
            &mut response,
            Timeout::AfterNanos(2_000_000_000)
        ),
        Ok(Call::Response { bytes: 4, .. })
    ) {
        return 14;
    }
    if connection.close().is_err() {
        return 15;
    }
    let Ok(mut tray) = services.tray() else {
        return 31;
    };
    let icon = [0xff224466; abi::tray_icon_pixel_count];
    let item = TrayItem {
        id: 55,
        revision: 1,
        flags: 0,
        status_flags: 0,
        tooltip: "SDK55",
        icon: &icon,
    };
    let Ok(updated) = tray.upsert(item, Timeout::AfterNanos(2_000_000_000)) else {
        return 32;
    };
    if updated.kind != 0 || updated.raw_code != abi::tray_result_ok {
        return 33;
    }
    let status = tray.status(55, Timeout::AfterNanos(2_000_000_000));
    let removed = tray.remove(55, Timeout::AfterNanos(2_000_000_000));
    if status.kind != 0 || removed.kind != 0 || removed.raw_code != abi::tray_result_ok {
        return 34;
    }
    let Ok(network) = Network::new(app) else {
        return 20;
    };
    let timeout = Timeout::AfterNanos(2_000_000_000);
    let end = time::request_deadline(
        timeout,
        clock.ticks().unwrap_or(u64::MAX),
        state.monotonic_hz,
    )
    .unwrap();
    let address = SocketAddress {
        address: Ipv4Address([10, 0, 2, 2]),
        port: 18555,
    };
    let Ok(mut tcp) = network.connect_tcp(address, timeout) else {
        return 21;
    };
    let input = b"RUST TCP";
    let mut sent = 0;
    while sent < input.len() {
        if clock.ticks().unwrap_or(u64::MAX) >= end {
            return 22;
        }
        let result = tcp.write(&input[sent..], timeout);
        match result.state {
            SocketState::Ok if result.bytes > 0 => sent += result.bytes,
            SocketState::WouldBlock => app.sleep(1),
            _ => return 22,
        }
    }
    let mut received = 0;
    while received < input.len() {
        if clock.ticks().unwrap_or(u64::MAX) >= end {
            return 23;
        }
        let result = tcp.read(&mut response[received..input.len()], timeout);
        match result.state {
            SocketState::Ok if result.bytes > 0 => received += result.bytes,
            SocketState::WouldBlock => app.sleep(1),
            _ => return 23,
        }
    }
    if response[..received] != input[..] || tcp.close(timeout).state != SocketState::Closed {
        return 24;
    }
    let Ok(mut udp) = network.bind_udp(19555, timeout) else {
        return 25;
    };
    let sent = udp.send_to(
        SocketAddress {
            address: address.address,
            port: 18556,
        },
        b"RUST UDP",
        timeout,
    );
    if sent.state != SocketState::Ok || sent.bytes != 8 {
        return 26;
    }
    loop {
        if clock.ticks().unwrap_or(u64::MAX) >= end {
            return 27;
        }
        let (result, info) = udp.receive_from(&mut response, timeout);
        if result.state == SocketState::WouldBlock {
            app.sleep(1);
            continue;
        }
        if result.state != SocketState::Ok
            || info.bytes != 8
            || info.source.port != 18556
            || response[..8] != *b"RUST UDP"
        {
            return 27;
        }
        break;
    }
    if udp.close(timeout).state != SocketState::Closed {
        return 27;
    }
    let Ok(serial) = Serial::new(app) else {
        return 28;
    };
    for i in 0..serial.count() {
        if serial.port_at(i).is_err() {
            return 29;
        }
    }
    if time::duration_from_ticks(1, 333).map(|x| x.nanoseconds) != Ok(3_003_004) {
        return 30;
    }
    let rc = unsafe { sdk55_c_network(app.start_context()) };
    if rc != 0 {
        return 100 + rc;
    }
    app.write(
        "[SDK55] Rust/C service, cancelled reply, TCP chunks, UDP and serial inventory PASS\n",
    );
    0
}
fn main(app: &mut App<'_>) -> i32 {
    let Ok(path) = FilePath::parse(app.args()) else {
        return 1;
    };
    let Ok(services) = Services::new(app) else {
        return 2;
    };
    let install = services.install(
        c"NET55SVC",
        &path,
        c"",
        abi::service_start_manual,
        c"SDK service loop fixture",
    );
    if install.raw_code != 0 {
        return 3;
    }
    let started = services.start(c"NET55SVC");
    let result = if started.raw_code == 0 {
        exercise(app, &services)
    } else {
        4
    };
    let stopped = services.stop(c"NET55SVC", Timeout::AfterNanos(2_000_000_000));
    let removed = services.remove(c"NET55SVC");
    if result != 0 {
        return result;
    }
    if stopped.raw_code != 0 || removed.raw_code != 0 {
        return 5;
    }
    app.write("[SDK55] exact service stop/remove PASS\n");
    0
}
r4os_sdk::app!(main);
