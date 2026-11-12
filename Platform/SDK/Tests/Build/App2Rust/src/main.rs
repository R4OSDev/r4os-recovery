#![no_std]
extern crate alloc;
use r4os_sdk::App2;
use r4os_sdk::platform2::abi;
fn main(app: &mut App2<'_>) -> i32 {
    if app.args() == b"initfail" {
        return -73;
    }
    let mut bytes = alloc::vec![0xa5u8; 4096];
    bytes.resize(8192, 0x5a);
    if bytes[0] != 0xa5 || bytes[8191] != 0x5a {
        return -60;
    }
    drop(bytes);
    let mut entropy = [0xa5u8; 32];
    let filled = unsafe {
        r4os_sdk::c_facades::R4SdkDataRandom_fill(0, entropy.as_mut_ptr(), entropy.len() as u64)
    };
    if filled.status != 0 || (filled.bits == 0 && entropy.iter().any(|b| *b != 0)) {
        return -61;
    }
    let address = match app.context().lookup(
        1,
        core::mem::offset_of!(abi::R4XStartR4Sys2, entropy_source_info) as u32,
    ) {
        Ok(address) => address,
        Err(error) => return error,
    };
    let info: abi::R4SysFns2::entropy_source_info = unsafe { core::mem::transmute(address) };
    let mut source = r4os_sdk::abi::EntropySourceInfo::default();
    if unsafe { info(&mut source) } == 0
        && source.state == r4os_sdk::abi::entropy_state_ready as u32
    {
        let mut bound = r4os_sdk::abi::EntropySourceInfo::default();
        let result = unsafe { r4os_sdk::c_facades::R4SdkDataRandom_sourceInfo(0, &mut bound) };
        if filled.bits == 0
            || result.status != 0
            || result.bits as i32 != 0
            || bound.generation != source.generation
        {
            return -66;
        }
    }
    let view = app.context();
    let raw = view.raw();
    let held = view.args() == b"hold";
    let imports = unsafe {
        core::slice::from_raw_parts(
            raw.imports as *const r4os_sdk::abi::R4XStartImport,
            raw.import_count as usize,
        )
    };
    if raw.instance_id == 0
        || (!held && view.should_close())
        || imports[1].group_id != 0
        || imports[1].resolved_version != 2
        || imports[1].table == 0
    {
        return -20;
    }
    if raw.import_count < 4
        || imports[2].group_id != 0
        || imports[2].resolved_version != 1
        || imports[2].table == 0
        || imports[3].resolved_version != 0
        || imports[3].table != 0
        || imports[3].flags != 0
    {
        return -62;
    }
    let query = unsafe { &*(imports[1].table as *const abi::R4LQuery2) };
    if query.magic != 0x324c3452 || query.size != 24 || query.group != 0 || query.reserved != 0 {
        return -21;
    }
    if !view.yield_current() || (!held && view.should_close()) || query.magic != 0x324c3452 {
        return -22;
    }
    let address = match view.lookup(1, core::mem::offset_of!(abi::R4XStartR4Sys2, write) as u32) {
        Ok(v) => v,
        Err(e) => return e,
    };
    let write: abi::R4SysFns2::write = unsafe { core::mem::transmute(address) };
    let message = b"PASS APP2R context=120 query=24 borrowed_args/imports callbacks=2\r\n";
    unsafe { write(message.as_ptr(), message.len() as u32) };
    if view.args() == b"fault" {
        panic!("Start2 fault retirement probe");
    }
    if view.args() == b"hold" {
        while !view.should_close() {
            view.yield_current();
        }
    }
    if view.args() == b"return" { 37 } else { 0 }
}
r4os_sdk::app2!(main);
