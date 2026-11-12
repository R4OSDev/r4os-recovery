// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Private C rand/srand state for the calling process, not a security RNG.
const local = @import("process_local.zig");

const State = struct { value: u64 = 1 };
var state_key: u8 = 0;
fn initialize(state: *State) void {
    state.* = .{};
}
fn stateForCaller() error{Unavailable}!*State {
    return local.getOrCreate(State, &state_key, initialize) orelse error.Unavailable;
}

pub fn seed(value: u32) error{Unavailable}!void {
    const state = try stateForCaller();
    @atomicStore(u64, &state.value, value, .monotonic);
}

pub fn next() error{Unavailable}!u31 {
    const state = try stateForCaller();
    var previous = @atomicLoad(u64, &state.value, .monotonic);
    while (true) {
        // Full-period LCG modulo 2^64, exposing only its upper 31 bits.
        const value = previous *% 6364136223846793005 +% 1;
        if (@cmpxchgWeak(u64, &state.value, previous, value, .monotonic, .monotonic)) |observed| {
            previous = observed;
        } else return @intCast(value >> 33);
    }
}
