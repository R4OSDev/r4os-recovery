//! Source API over one shared static owner. Existing resources are borrowed.
pub const core = @import("stream_transfer.zig");
pub const Transfer = core.Transfer;
pub const Mode = core.Mode;
pub const Outcome = core.Outcome;
pub const IoKind = core.IoKind;
pub const Ack = core.Ack;
pub const Progress = core.Progress;
pub const Clock = core.Clock;
pub const Read = core.Read;
pub const Write = core.Write;
pub const adapters = @import("stream_adapters.zig");
