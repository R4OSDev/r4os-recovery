#![no_std]
use r4os_sdk::platform2::{Context, abi};
fn main(view: &Context<'_>) -> i32 {
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
    let message = b"PASS START2R context=120 query=24 borrowed_args/imports callbacks=2\r\n";
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
r4os_sdk::lowlevel_entry2!(main);
