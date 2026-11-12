// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Optional image consumer over VIDEO_V1. No pixel copy or implicit software
//! fallback. The application retains its R4IMG color/ICC characterization and
//! supplies the eventual R4GFX consumer receipt before releasing the image.
const std = @import("std");
pub const Dimensions = struct { width: u32, height: u32 };
/// Preflight only; the native decoder validates the complete coded image.
pub fn dimensions(bytes: []const u8) error{Unsupported}!Dimensions {
    if (bytes.len < 4 or bytes.len > 8 * 1024 * 1024 or bytes[0] != 0xff or bytes[1] != 0xd8) return error.Unsupported;
    var at: usize = 2;
    while (at + 4 <= bytes.len) {
        if (bytes[at] != 0xff) return error.Unsupported;
        at += 1;
        while (at < bytes.len and bytes[at] == 0xff) at += 1;
        if (at + 3 > bytes.len) return error.Unsupported;
        const marker = bytes[at]; at += 1;
        const n = std.mem.readInt(u16, bytes[at..][0..2], .big);
        if (n < 2 or n > bytes.len - at) return error.Unsupported;
        if (marker == 0xc0) {
            if (n != 17 or bytes[at + 2] != 8 or bytes[at + 7] != 3 or bytes[at + 9] != 0x22 or
                bytes[at + 12] != 0x11 or bytes[at + 15] != 0x11) return error.Unsupported;
            const height = std.mem.readInt(u16, bytes[at + 3 ..][0..2], .big);
            const width = std.mem.readInt(u16, bytes[at + 5 ..][0..2], .big);
            if (width < 64 or height < 64 or width > 4096 or height > 4096 or (width | height) & 1 != 0) return error.Unsupported;
            return .{ .width = width, .height = height };
        }
        if (marker != 0xc4 and marker != 0xdb and marker != 0xdd and marker != 0xfe and (marker < 0xe0 or marker > 0xef)) return error.Unsupported;
        at += n;
    }
    return error.Unsupported;
}
/// Instantiate with the imported R4VIDEO binding. All methods execute bounded
/// facade calls; advance/close/release return AGAIN or BUSY for later polling.
pub fn Consumer(comptime video: type) type {
    return struct {
        const Self = @This();
        api: video.VideoV1Client,
        decoder: video.R4VideoDecoder,
        source: []const u8,
        sent: bool = false,
        draining: bool = false,
        received: bool = false,
        closing: bool = false,
        closed: bool = false,
        held: ?video.R4VideoLease = null,
        pub fn capabilities(api: video.VideoV1Client, runtime: *const video.R4VideoRuntime, adapter: u32,
            encoded: []const u8, output: *video.R4VideoCaps) i32 {
            const extent = dimensions(encoded) catch return video.error_unsupported;
            var caps: video.R4VideoCaps = undefined;
            const rc = api.query_caps(runtime, &.{ .version = 1, .size = @sizeOf(video.R4VideoCapsQuery),
                .backend = video.backend_amd, .adapter_id = adapter, .codec = video.codec_jpeg,
                .profile = 0, .bit_depth = 8, .chroma = video.chroma_420 }, &caps);
            if (rc != video.ok) return rc;
            if (extent.width < caps.min_width or extent.height < caps.min_height or extent.width > caps.max_width or
                extent.height > caps.max_height or caps.output_formats & video.formats_nv12 == 0 or encoded.len > caps.max_packet_bytes)
                return video.error_unsupported;
            output.* = caps; return video.ok;
        }
        /// encoded must remain unchanged until advance accepts the packet
        /// (sent == true), or close completes without sending it.
        pub fn start(api: video.VideoV1Client, runtime: *const video.R4VideoRuntime, adapter: u32,
            encoded: []const u8, memory_limit: u64, output: *Self) i32 {
            var caps: video.R4VideoCaps = undefined;
            const queried = capabilities(api, runtime, adapter, encoded, &caps);
            if (queried != video.ok) return queried;
            const extent = dimensions(encoded) catch return video.error_unsupported;
            var decoder: video.R4VideoDecoder = undefined;
            const rc = api.create(runtime, &.{ .version = 1, .size = @sizeOf(video.R4VideoConfig), .query = caps.query,
                .memory_limit = memory_limit, .max_width = extent.width, .max_height = extent.height,
                // Keep one free receive slot so drain can observe EOS while
                // the consumer still holds the sole image.
                .pending_packets = 1, .frame_leases = 2, .threads = 1, .flags = 0 }, &decoder);
            if (rc != video.ok) return rc;
            output.* = .{ .api = api, .decoder = decoder, .source = encoded }; return video.ok;
        }
        pub fn advance(self: *Self, output: *video.R4VideoFrame) i32 {
            if (self.closing or self.closed or self.received) return video.error_invalid;
            if (!self.sent) {
                const rc = self.api.send(&self.decoder, &.{ .version = 1, .size = @sizeOf(video.R4VideoPacket),
                    .data_address = @intFromPtr(self.source.ptr), .data_bytes = self.source.len, .stream_generation = 1,
                    .tag = 1, .pts_ns = 0, .dts_ns = 0, .duration_ns = 0, .flags = 0, .reserved = 0 });
                if (rc != video.ok) return rc;
                self.sent = true; self.source = &.{};
            }
            if (!self.draining) {
                var state: video.R4VideoState = undefined;
                const rc = self.api.control(&self.decoder, &.{ .version = 1, .size = @sizeOf(video.R4VideoControl),
                    .request_id = 1, .operation = video.control_drain, .reserved = 0 }, &state);
                if (rc != video.ok) return rc;
                self.draining = true;
            }
            var frame: video.R4VideoFrame = undefined;
            const rc = self.api.receive(&self.decoder, &frame);
            if (rc != video.ok) return rc;
            self.held = frame.lease; self.received = true; output.* = frame; return video.ok;
        }
        /// Receipt is caller-owned until the release ACK. It must remain
        /// identical on retries; VIDEO_V1 checks its exact fence identity.
        pub fn release(self: *Self, receipt: *const video.R4VideoReceipt) i32 {
            const lease = self.held orelse return video.error_invalid;
            const rc = self.api.release(&lease, receipt);
            if (rc == video.ok) self.held = null;
            return rc;
        }
        /// May start with a held image. Destruction waits for its release ACK
        /// and all decoder/queue/resource retirement, including failed decode.
        pub fn close(self: *Self) i32 {
            if (self.closed) return video.ok;
            var state: video.R4VideoState = undefined;
            const rc = self.api.control(&self.decoder, &.{ .version = 1, .size = @sizeOf(video.R4VideoControl),
                .request_id = if (self.closing) 0 else 2,
                .operation = if (self.closing) video.control_query else video.control_close, .reserved = 0 }, &state);
            if (rc != video.ok) return rc;
            self.closing = true;
            if (self.held != null or state.phase != video.phase_closed) return video.again;
            const destroyed = self.api.destroy(&self.decoder);
            if (destroyed != video.ok) return destroyed;
            self.closed = true; self.source = &.{}; return video.ok;
        }
    };
}
