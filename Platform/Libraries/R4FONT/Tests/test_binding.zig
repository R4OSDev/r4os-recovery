const std = @import("std");
const binding = @import("binding");
const project = @import("project");

pub const Format = binding.Format;
pub const Error = binding.Error;
pub const Diagnostics = binding.Diagnostics;
pub const TestingFaultInjection = binding.TestingFaultInjection;
pub const Face = binding.Face;
pub const FaceInfo = binding.FaceInfo;
pub const GlyphMetrics = binding.GlyphMetrics;
pub const Raster = binding.Raster;
pub const max_source_bytes = binding.max_source_bytes;
pub const max_reconstructed_bytes = binding.max_reconstructed_bytes;
pub const max_raster_dimension = binding.max_raster_dimension;
pub const default_allocation_limit = binding.default_allocation_limit;

fn context() binding.Context {
    return binding.Context.initHeader(&project.r4font_api_v1.header).?;
}

pub fn sniff(bytes: []const u8) ?Format {
    var api = context();
    return api.sniff(bytes);
}

pub const Decoder = struct {
    inner: binding.Decoder,

    pub fn init(allocator: std.mem.Allocator, allocation_limit: usize) Error!Decoder {
        var api = context();
        return .{ .inner = try api.createDecoder(allocator, allocation_limit) };
    }

    pub fn deinit(self: *Decoder) void {
        self.inner.deinit();
        self.* = undefined;
    }

    pub fn diagnostics(self: *const Decoder) Diagnostics {
        return self.inner.diagnostics();
    }

    pub fn openFace(self: *Decoder, bytes: []const u8, face_index: u32) Error!Face {
        return self.inner.openFace(bytes, face_index);
    }

    pub fn testingSetFaultInjection(self: *Decoder, injection: TestingFaultInjection) void {
        self.inner.testingSetFaultInjection(injection);
    }
};
