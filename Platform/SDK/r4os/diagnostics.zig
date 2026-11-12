//! SDK-owned bounded records and synchronous adapters, not another log service.
pub const core = @import("diagnostic_buffer.zig");
pub const BoundedDiagnosticBuffer = core.BoundedDiagnosticBuffer;
pub const ConsoleSink = @import("diagnostic_sinks.zig").ConsoleSink;
pub const FileSink = @import("diagnostic_sinks.zig").FileSink;
pub const LogSink = @import("diagnostic_sinks.zig").LogSink;
