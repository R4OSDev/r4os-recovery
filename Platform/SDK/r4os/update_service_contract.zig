const std = @import("std");

pub const service_name: [*:0]const u8 = "UPDSVC";
pub const config_path: [*:0]const u8 = "C:\\R4OS\\CONFIG\\UPDATE.R4S";
pub const state_path: [*:0]const u8 = "C:\\R4OS\\UPDATE\\STAGED\\UPDSVC.R4S";
pub const download_state_path: [*:0]const u8 = "C:\\R4OS\\UPDATE\\STAGED\\UPDSVC-DOWNLOAD.R4S";

pub const magic: u32 = 0x5550_4431; // UPD1
pub const version: u16 = 1;
pub const selection_capacity: usize = 1024;
pub const reason_capacity: usize = 96;
pub const offer_id_capacity: usize = 48;
pub const offer_version_capacity: usize = 24;
pub const offer_release_capacity: usize = 24;
pub const offer_title_capacity: usize = 96;
pub const offer_description_capacity: usize = 2048;
pub const offer_filename_capacity: usize = 128;
pub const offer_sha256_capacity: usize = 64;
pub const offer_url_capacity: usize = 1024;
pub const component_name_capacity: usize = 48;
pub const component_kind_capacity: usize = 8;
pub const component_version_capacity: usize = 24;
pub const component_target_capacity: usize = 256;

pub const op_status: u16 = 1;
pub const op_search: u16 = 2;
pub const op_download: u16 = 3;
pub const op_install: u16 = 4;
pub const op_update_all: u16 = 5;
pub const op_cancel: u16 = 6;
pub const op_results: u16 = 7;
pub const op_components: u16 = 8;
pub const op_restart: u16 = 9;

pub const result_ok: i32 = 0;
pub const result_busy: i32 = -7;
pub const result_invalid: i32 = -1;
pub const result_not_found: i32 = -2;
pub const result_not_ready: i32 = -20;
pub const result_cancelled: i32 = -21;
pub const result_persist_failed: i32 = -22;
pub const result_auth_failed: i32 = -23;
pub const result_access_warning: i32 = -24;
pub const result_network_failed: i32 = -25;
pub const result_catalog_invalid: i32 = -26;
pub const result_inventory_invalid: i32 = -27;
pub const result_requirement_unmet: i32 = -28;
pub const result_response_too_large: i32 = -29;
pub const result_selection_stale: i32 = -30;
pub const result_download_failed: i32 = -31;
pub const result_integrity_failed: i32 = -32;
pub const result_publish_failed: i32 = -33;
pub const result_partial_discarded: i32 = -34;

pub const flag_busy: u32 = 1 << 0;
pub const flag_cancelable: u32 = 1 << 1;
pub const flag_restart_required: u32 = 1 << 2;
pub const flag_recovered: u32 = 1 << 3;
pub const flag_config_valid: u32 = 1 << 4;
pub const flag_worker_ready: u32 = 1 << 5;
pub const flag_results_ready: u32 = 1 << 6;

pub const offer_flag_restart_required: u32 = 1 << 0;
pub const offer_flag_foundation: u32 = 1 << 1;
pub const offer_flag_mandatory_repair: u32 = 1 << 2;
pub const component_flag_missing: u32 = 1 << 0;
pub const component_flag_kernel: u32 = 1 << 1;
pub const component_flag_restart_required: u32 = 1 << 2;
pub const component_flag_active_differs: u32 = 1 << 3;

pub const Operation = enum(u16) {
    search = op_search,
    download = op_download,
    install = op_install,
    update_all = op_update_all,
    restart = op_restart,
};

pub const State = enum(u16) {
    booting = 0,
    idle = 1,
    queued = 2,
    authenticating = 3,
    searching = 4,
    downloading = 5,
    verifying = 6,
    installing = 7,
    staged = 8,
    pending_restart = 9,
    installed = 10,
    cancelling = 11,
    cancelled = 12,
    failed = 13,
    interrupted = 14,
    stopping = 15,
    available = 16,
    up_to_date = 17,
    downloaded = 18,
};

pub const RequestHeader = extern struct {
    magic: u32 = magic,
    version: u16 = version,
    size: u16,

    pub fn init(comptime T: type) RequestHeader {
        return .{ .size = @sizeOf(T) };
    }

    pub fn valid(self: RequestHeader, expected_size: usize) bool {
        return self.magic == magic and self.version == version and
            self.size == expected_size;
    }
};

pub const StatusRequest = extern struct {
    header: RequestHeader = RequestHeader.init(StatusRequest),
    job_id: u32 = 0,
};

pub const CommandRequest = extern struct {
    header: RequestHeader = RequestHeader.init(CommandRequest),
    flags: u32 = 0,
    selection_len: u16 = 0,
    reserved: u16 = 0,
    selection: [selection_capacity]u8 = .{0} ** selection_capacity,

    pub fn selectionText(self: *const CommandRequest) ?[]const u8 {
        if (self.selection_len > self.selection.len) return null;
        return self.selection[0..self.selection_len];
    }
};

pub const CancelRequest = extern struct {
    header: RequestHeader = RequestHeader.init(CancelRequest),
    job_id: u32 = 0,
};

/// Downloads are selected only by the immutable search job and its stable
/// result index. A package name supplied independently by a caller is never a
/// valid download authority.
pub const DownloadRequest = extern struct {
    header: RequestHeader = RequestHeader.init(DownloadRequest),
    search_job_id: u32 = 0,
    result_index: u32 = 0,
};

/// Long-running operations bind to the immutable result set produced by one
/// completed search. The service never rebuilds a queue from a newer search.
pub const SnapshotRequest = extern struct {
    header: RequestHeader = RequestHeader.init(SnapshotRequest),
    search_job_id: u32 = 0,
};

pub const ResultsRequest = extern struct {
    header: RequestHeader = RequestHeader.init(ResultsRequest),
    job_id: u32 = 0,
    index: u32 = 0,
};

pub const ComponentRequest = extern struct {
    header: RequestHeader = RequestHeader.init(ComponentRequest),
    job_id: u32 = 0,
    result_index: u32 = 0,
    component_index: u32 = 0,
};

pub const Ack = extern struct {
    magic: u32 = magic,
    version: u16 = version,
    size: u16 = @sizeOf(Ack),
    job_id: u32 = 0,
    state: u16 = @intFromEnum(State.idle),
    operation: u16 = 0,
    result: i32 = result_ok,
    generation: u32 = 0,

    pub fn valid(self: Ack) bool {
        return self.magic == magic and self.version == version and self.size == @sizeOf(Ack);
    }
};

pub const Status = extern struct {
    magic: u32 = magic,
    version: u16 = version,
    size: u16 = @sizeOf(Status),
    job_id: u32 = 0,
    generation: u32 = 0,
    operation: u16 = 0,
    state: u16 = @intFromEnum(State.booting),
    flags: u32 = 0,
    result: i32 = result_ok,
    progress_current: u64 = 0,
    progress_total: u64 = 0,
    package_count: u32 = 0,
    completed_count: u32 = 0,
    source_job_id: u32 = 0,
    result_index: u32 = 0,
    reason_len: u16 = 0,
    reserved: u16 = 0,
    reason: [reason_capacity]u8 = .{0} ** reason_capacity,

    pub fn valid(self: *const Status) bool {
        return self.magic == magic and self.version == version and
            self.size == @sizeOf(Status) and self.reason_len <= self.reason.len and
            self.progress_current <= self.progress_total and stateFromWire(self.state) != null;
    }

    pub fn reasonText(self: *const Status) []const u8 {
        return self.reason[0..@min(@as(usize, self.reason_len), self.reason.len)];
    }
};

pub const Offer = extern struct {
    flags: u32 = 0,
    install_order: u32 = 0,
    size_bytes: u64 = 0,
    progress_current: u64 = 0,
    progress_total: u64 = 0,
    result: i32 = result_ok,
    state: u16 = @intFromEnum(State.available),
    reserved: u16 = 0,
    component_count: u16 = 0,
    update_component_count: u16 = 0,
    package_id_len: u16 = 0,
    package_version_len: u16 = 0,
    release_len: u16 = 0,
    title_len: u16 = 0,
    description_len: u16 = 0,
    filename_len: u16 = 0,
    sha256_len: u16 = 0,
    download_url_len: u16 = 0,
    package_id: [offer_id_capacity]u8 = .{0} ** offer_id_capacity,
    package_version: [offer_version_capacity]u8 = .{0} ** offer_version_capacity,
    release: [offer_release_capacity]u8 = .{0} ** offer_release_capacity,
    title: [offer_title_capacity]u8 = .{0} ** offer_title_capacity,
    description: [offer_description_capacity]u8 = .{0} ** offer_description_capacity,
    filename: [offer_filename_capacity]u8 = .{0} ** offer_filename_capacity,
    sha256: [offer_sha256_capacity]u8 = .{0} ** offer_sha256_capacity,
    download_url: [offer_url_capacity]u8 = .{0} ** offer_url_capacity,

    pub fn valid(self: *const Offer) bool {
        return offerStateValid(self.state) and self.progress_current <= self.progress_total and
            self.package_id_len <= self.package_id.len and
            self.package_version_len <= self.package_version.len and
            self.release_len <= self.release.len and self.title_len <= self.title.len and
            self.description_len <= self.description.len and self.filename_len <= self.filename.len and
            self.sha256_len <= self.sha256.len and self.download_url_len <= self.download_url.len;
    }

    pub fn packageIdText(self: *const Offer) []const u8 {
        return self.package_id[0..@min(@as(usize, self.package_id_len), self.package_id.len)];
    }

    pub fn titleText(self: *const Offer) []const u8 {
        return self.title[0..@min(@as(usize, self.title_len), self.title.len)];
    }

    pub fn descriptionText(self: *const Offer) []const u8 {
        return self.description[0..@min(@as(usize, self.description_len), self.description.len)];
    }
};

/// Eine absichtlich eintraegige Seite haelt selbst die maximale R4U-
/// Beschreibung zusammen mit Download-URL und Hash unter dem 4-KB-
/// Servicevertrag. Der Client blaettert deterministisch per Index.
pub const ResultsPage = extern struct {
    magic: u32 = magic,
    version: u16 = version,
    size: u16 = @sizeOf(ResultsPage),
    job_id: u32 = 0,
    generation: u32 = 0,
    result: i32 = result_ok,
    flags: u32 = 0,
    total: u32 = 0,
    index: u32 = 0,
    has_offer: u8 = 0,
    current_release_len: u8 = 0,
    reserved: [2]u8 = .{ 0, 0 },
    current_release: [offer_release_capacity]u8 = .{0} ** offer_release_capacity,
    offer: Offer = .{},

    pub fn valid(self: *const ResultsPage) bool {
        return self.magic == magic and self.version == version and self.size == @sizeOf(ResultsPage) and
            self.has_offer <= 1 and self.current_release_len <= self.current_release.len and self.offer.valid();
    }

    pub fn currentReleaseText(self: *const ResultsPage) []const u8 {
        return self.current_release[0..@min(@as(usize, self.current_release_len), self.current_release.len)];
    }
};

pub const OfferComponent = extern struct {
    flags: u32 = 0,
    name_len: u16 = 0,
    kind_len: u16 = 0,
    installed_version_len: u16 = 0,
    offered_version_len: u16 = 0,
    active_version_len: u16 = 0,
    target_len: u16 = 0,
    name: [component_name_capacity]u8 = .{0} ** component_name_capacity,
    kind: [component_kind_capacity]u8 = .{0} ** component_kind_capacity,
    installed_version: [component_version_capacity]u8 = .{0} ** component_version_capacity,
    offered_version: [component_version_capacity]u8 = .{0} ** component_version_capacity,
    active_version: [component_version_capacity]u8 = .{0} ** component_version_capacity,
    target: [component_target_capacity]u8 = .{0} ** component_target_capacity,

    pub fn valid(self: *const OfferComponent) bool {
        return self.name_len <= self.name.len and self.kind_len <= self.kind.len and
            self.installed_version_len <= self.installed_version.len and
            self.offered_version_len <= self.offered_version.len and
            self.active_version_len <= self.active_version.len and self.target_len <= self.target.len;
    }
};

pub const ComponentPage = extern struct {
    magic: u32 = magic,
    version: u16 = version,
    size: u16 = @sizeOf(ComponentPage),
    job_id: u32 = 0,
    result_index: u32 = 0,
    component_index: u32 = 0,
    total: u32 = 0,
    result: i32 = result_ok,
    has_component: u8 = 0,
    reserved: [3]u8 = .{ 0, 0, 0 },
    component: OfferComponent = .{},

    pub fn valid(self: *const ComponentPage) bool {
        return self.magic == magic and self.version == version and self.size == @sizeOf(ComponentPage) and
            self.has_component <= 1 and self.component.valid();
    }
};

pub fn operationFromWire(raw: u16) ?Operation {
    return switch (raw) {
        op_search => .search,
        op_download => .download,
        op_install => .install,
        op_update_all => .update_all,
        op_restart => .restart,
        else => null,
    };
}

pub fn stateFromWire(raw: u16) ?State {
    return switch (raw) {
        0 => .booting,
        1 => .idle,
        2 => .queued,
        3 => .authenticating,
        4 => .searching,
        5 => .downloading,
        6 => .verifying,
        7 => .installing,
        8 => .staged,
        9 => .pending_restart,
        10 => .installed,
        11 => .cancelling,
        12 => .cancelled,
        13 => .failed,
        14 => .interrupted,
        15 => .stopping,
        16 => .available,
        17 => .up_to_date,
        18 => .downloaded,
        else => null,
    };
}

pub fn stateName(raw: u16) []const u8 {
    const state = stateFromWire(raw) orelse return "unknown";
    return switch (state) {
        .booting => "booting",
        .idle => "idle",
        .queued => "queued",
        .authenticating => "authenticating",
        .searching => "searching",
        .downloading => "downloading",
        .verifying => "verifying",
        .installing => "installing",
        .staged => "staged",
        .pending_restart => "pending-restart",
        .installed => "installed",
        .cancelling => "cancelling",
        .cancelled => "cancelled",
        .failed => "failed",
        .interrupted => "interrupted",
        .stopping => "stopping",
        .available => "available",
        .up_to_date => "up-to-date",
        .downloaded => "downloaded",
    };
}

pub fn operationName(raw: u16) []const u8 {
    return switch (raw) {
        0 => "none",
        op_search => "search",
        op_download => "download",
        op_install => "install",
        op_update_all => "update-all",
        op_status => "status",
        op_cancel => "cancel",
        op_results => "results",
        op_components => "components",
        op_restart => "restart",
        else => "unknown",
    };
}

pub fn setReason(status: *Status, text: []const u8) void {
    @memset(status.reason[0..], 0);
    const len = @min(text.len, status.reason.len);
    if (len != 0) @memcpy(status.reason[0..len], text[0..len]);
    status.reason_len = @intCast(len);
}

fn offerStateValid(raw: u16) bool {
    return raw == @intFromEnum(State.available) or raw == @intFromEnum(State.downloading) or
        raw == @intFromEnum(State.downloaded) or raw == @intFromEnum(State.verifying) or
        raw == @intFromEnum(State.installing) or raw == @intFromEnum(State.staged) or
        raw == @intFromEnum(State.pending_restart) or raw == @intFromEnum(State.installed) or
        raw == @intFromEnum(State.failed);
}

test "wire contract is bounded versioned and rejects unknown values" {
    try std.testing.expect(@sizeOf(CommandRequest) <= 4096);
    try std.testing.expect(@sizeOf(Status) <= 4096);
    try std.testing.expect(@sizeOf(ResultsPage) <= 4096);
    try std.testing.expect((StatusRequest{}).header.valid(@sizeOf(StatusRequest)));
    try std.testing.expect((CommandRequest{}).header.valid(@sizeOf(CommandRequest)));
    try std.testing.expect((CancelRequest{}).header.valid(@sizeOf(CancelRequest)));
    try std.testing.expect((DownloadRequest{}).header.valid(@sizeOf(DownloadRequest)));
    try std.testing.expect((SnapshotRequest{}).header.valid(@sizeOf(SnapshotRequest)));
    try std.testing.expect((ResultsRequest{}).header.valid(@sizeOf(ResultsRequest)));
    try std.testing.expect((ComponentRequest{}).header.valid(@sizeOf(ComponentRequest)));
    try std.testing.expect(operationFromWire(0xFFFF) == null);
    try std.testing.expect(stateFromWire(0xFFFF) == null);
}

test "one-offer result page retains maximum description under service payload" {
    var page = ResultsPage{ .has_offer = 1, .total = 1 };
    page.offer.package_id_len = 4;
    @memcpy(page.offer.package_id[0..4], "TEST");
    page.offer.description_len = page.offer.description.len;
    try std.testing.expect(page.valid());
    try std.testing.expectEqualStrings("TEST", page.offer.packageIdText());
    try std.testing.expect(@sizeOf(ResultsPage) <= 4096);
    try std.testing.expect(@sizeOf(ComponentPage) <= 4096);
}

test "component pages separate installed offered and active kernel versions" {
    var page = ComponentPage{ .has_component = 1, .total = 1 };
    page.component.flags = component_flag_kernel | component_flag_restart_required | component_flag_active_differs;
    page.component.name_len = 6;
    @memcpy(page.component.name[0..6], "KERNEL");
    page.component.installed_version_len = 5;
    @memcpy(page.component.installed_version[0..5], "0.1.1");
    page.component.offered_version_len = 5;
    @memcpy(page.component.offered_version[0..5], "0.1.2");
    page.component.active_version_len = 5;
    @memcpy(page.component.active_version[0..5], "0.1.0");
    try std.testing.expect(page.valid());
    try std.testing.expect(@sizeOf(ComponentPage) <= 4096);
}

test "download request is snapshot bound and offer progress is explicit" {
    const request = DownloadRequest{ .search_job_id = 17, .result_index = 2 };
    try std.testing.expect(request.header.valid(@sizeOf(DownloadRequest)));
    var offer = Offer{
        .state = @intFromEnum(State.downloading),
        .progress_current = 4093,
        .progress_total = 8192,
    };
    try std.testing.expect(offer.valid());
    offer.progress_current = offer.progress_total + 1;
    try std.testing.expect(!offer.valid());
}

test "status text is fixed capacity and safe" {
    var status = Status{};
    setReason(&status, "ready");
    try std.testing.expect(status.valid());
    try std.testing.expectEqualStrings("ready", status.reasonText());
    try std.testing.expectEqualStrings("booting", stateName(status.state));
}
