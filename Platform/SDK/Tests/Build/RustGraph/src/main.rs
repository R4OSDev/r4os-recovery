#![no_std]
mod logic;
unsafe extern "C" {
    fn r4_graph_mix(value: u64) -> u64;
}
fn main(app: &mut r4os_sdk::App<'_>) -> i32 {
    let value = logic::value();
    if unsafe { r4_graph_mix(value) } != value + 17 {
        return 1;
    }
    let _ = app.write(
        "[RUSTGRAPH] Rust modules/include, optional renamed crate and two C companions OK\n",
    );
    0
}
r4os_sdk::app!(main);
