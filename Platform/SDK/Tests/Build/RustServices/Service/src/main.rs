#![no_std]
use r4os_sdk::{
    App, abi,
    services::{Receive, Services, Wake},
};
fn main(app: &mut App<'_>) -> i32 {
    let Ok(services) = Services::new(app) else {
        return 1;
    };
    let Ok(mut endpoint) = services.register(c"NET55SVC", 0) else {
        return 2;
    };
    let Ok(mut owner) = endpoint.service_loop(200, abi::service_api_endpoint_queue_depth as u32)
    else {
        return 3;
    };
    app.write("[SDK55] service loop ready\n");
    loop {
        match owner.wait(None) {
            Ok(Wake::Requests(n)) => {
                let result = owner.drain(n, || {
                    let mut bytes = [0; abi::service_api_max_payload];
                    match endpoint.receive(&mut bytes) {
                        Ok(Receive::Message { header, bytes: n }) => {
                            if header.op == 9 {
                                app.sleep(10);
                            }
                            endpoint.reply_if_pending(header.request_id, 0, &bytes[..n])
                        }
                        Ok(Receive::WouldBlock) => 0,
                        Err(_) => -1,
                    }
                });
                if result < 0 && !app.should_close() {
                    return 4;
                }
            }
            Ok(Wake::Stop) => break,
            Ok(Wake::Idle | Wake::Deadline) => {}
            Err(_) if app.should_close() => break,
            Err(_) => return 5,
        }
    }
    drop(owner);
    if endpoint.close().is_err() {
        return 6;
    }
    app.write("[SDK55] service loop stopped\n");
    0
}
r4os_sdk::app!(main);
