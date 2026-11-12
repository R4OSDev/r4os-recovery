const std = @import("std");
const r4os = @import("r4os");
pub const abi = @import("r4std_abi.zig");

pub const Runtime = struct {
    raw_address: u64,
    generation: u8,
    text: ?abi.TextV1Client,
    settings: ?abi.SettingsV1Client,
    date: ?abi.DateV1Client,
    time: ?abi.TimeV1Client,
    config: ?abi.ConfigV1Client,
    codec: ?abi.CodecV1Client,
};

var storage: Runtime = undefined;
var ready: bool = false;

pub fn init(raw: *const r4os.abi.R4XStartContext) bool {
    return install(.{
        .raw_address = @intFromPtr(raw),
        .generation = 1,
        .text = abi.TextV1Client.init(raw) catch null,
        .settings = abi.SettingsV1Client.init(raw) catch null,
        .date = abi.DateV1Client.init(raw) catch null,
        .time = abi.TimeV1Client.init(raw) catch null,
        .config = abi.ConfigV1Client.init(raw) catch null,
        .codec = abi.CodecV1Client.init(raw) catch null,
    });
}

pub fn init2(raw: *const r4os.platform2.abi.R4XStartContext2) bool {
    return install(.{
        .raw_address = @intFromPtr(raw),
        .generation = 2,
        .text = abi.TextV1Client.init2(raw) catch null,
        .settings = abi.SettingsV1Client.init2(raw) catch null,
        .date = abi.DateV1Client.init2(raw) catch null,
        .time = abi.TimeV1Client.init2(raw) catch null,
        .config = abi.ConfigV1Client.init2(raw) catch null,
        .codec = abi.CodecV1Client.init2(raw) catch null,
    });
}

fn install(candidate: Runtime) bool {
    if (candidate.text == null and candidate.settings == null and candidate.date == null and candidate.time == null and candidate.config == null and candidate.codec == null) return false;
    if (ready and (storage.raw_address != candidate.raw_address or storage.generation != candidate.generation)) return false;
    storage = candidate;
    ready = true;
    return true;
}

pub fn initialized() bool {
    return ready;
}

fn get() *Runtime {
    std.debug.assert(ready);
    return &storage;
}

pub fn text() *const abi.TextV1Client {
    if (get().text) |*client| return client;
    unreachable;
}

pub fn settings() *const abi.SettingsV1Client {
    if (get().settings) |*client| return client;
    unreachable;
}

pub fn date() *const abi.DateV1Client {
    if (get().date) |*client| return client;
    unreachable;
}

pub fn time() *const abi.TimeV1Client {
    if (get().time) |*client| return client;
    unreachable;
}

pub fn config() *const abi.ConfigV1Client {
    if (get().config) |*client| return client;
    unreachable;
}

pub fn hasText() bool {
    return ready and storage.text != null;
}

pub fn hasSettings() bool {
    return ready and storage.settings != null;
}

pub fn hasDate() bool {
    return ready and storage.date != null;
}

pub fn hasTime() bool {
    return ready and storage.time != null;
}

pub fn hasConfig() bool {
    return ready and storage.config != null;
}

pub fn rawAddress() u64 {
    return get().raw_address;
}

pub fn hasCodec() bool {
    return ready and storage.codec != null;
}

pub fn codec() *const abi.CodecV1Client {
    if (get().codec) |*client| return client;
    unreachable;
}

pub fn resetForTesting() void {
    ready = false;
    storage = undefined;
}
