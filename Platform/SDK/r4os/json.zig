//! Typisierte Fassade auf JSON.R4P.
//!
//! Ein Programm soll JSON lesen und aendern koennen, ohne selbst JSON zu
//! koennen und ohne Opcodes und Puffer zu schreiben. Der Parser liegt EINMAL
//! im System unter /R4OS/PROTOCOLS/JSON.R4P; diese Fassade uebersetzt nur.
//!
//! Sie bettet den Parser ausdruecklich NICHT ein - sonst traege jedes Programm
//! seine eigene Kopie, und eine Korrektur muesste in jedem einzelnen neu
//! gebaut werden.
//!
//! Die Struktur Cursor ist die ABI-Seite des Protokolls und muss zu
//! Code/System/Protocols/Json/src/json_core.zig passen. Der Conformance-Test
//! unter Tests/Conformance haelt beide Seiten aneinander.

const std = @import("std");
const abi = @import("r4os_contract").abi;
const r4dev = @import("r4dev.zig");

pub const role = "format.json";

// Opcodes des Protokolls. Append-only.
pub const op_open: u32 = 1;
pub const op_next: u32 = 2;
pub const op_select: u32 = 3;
pub const op_value: u32 = 4;
pub const op_enter: u32 = 5;
pub const op_next_element: u32 = 6;
pub const op_set: u32 = 7;
pub const op_remove: u32 = 8;
pub const op_insert: u32 = 9;

pub const Token = enum(u32) {
    end = 0,
    object_begin = 1,
    object_end = 2,
    array_begin = 3,
    array_end = 4,
    key = 5,
    string = 6,
    number = 7,
    true_value = 8,
    false_value = 9,
    null_value = 10,
    none = 255,
    _,
};

pub const Error = error{
    Unavailable,
    BadRequest,
    BadDocument,
    UnknownOperation,
    OutputTooSmall,
    DepthExceeded,
    NotFound,
    BadPath,
    WrongToken,
};

/// Uebersetzt einen Protokollstatus in einen benannten Fehler; null heisst OK.
/// Oeffentlich, damit der Conformance-Test pruefen kann, dass der Kern keinen
/// Code meldet, den die Fassade nur als generisches Unavailable weiterreicht.
pub fn mapStatus(code: i32) ?Error {
    return switch (code) {
        0 => null,
        -2 => Error.BadRequest,
        -3 => Error.BadDocument,
        -4 => Error.UnknownOperation,
        -5 => Error.OutputTooSmall,
        -6 => Error.DepthExceeded,
        -7 => Error.NotFound,
        -8 => Error.BadPath,
        -9 => Error.WrongToken,
        else => Error.Unavailable,
    };
}

fn statusToError(code: i32) Error!void {
    if (mapStatus(code)) |failure| return failure;
}

/// Aufrufereigener Parserzustand. Muss binaergleich zu json_core.Cursor sein.
pub const Cursor = extern struct {
    doc: ?[*]const u8 = null,
    doc_len: u32 = 0,
    pos: u32 = 0,
    depth: u32 = 0,
    depth_stack: ?[*]u8 = null,
    depth_capacity: u32 = 0,
    token: u32 = 255,
    token_start: u32 = 0,
    token_end: u32 = 0,
    reserved: u32 = 0,
};

/// Muss binaergleich zu der Request in Json/src/main.zig sein.
pub const Request = extern struct {
    cursor: ?*Cursor = null,
    doc: ?[*]const u8 = null,
    doc_len: u32 = 0,
    path: ?[*]const u8 = null,
    path_len: u32 = 0,
    value: ?[*]const u8 = null,
    value_len: u32 = 0,
};

/// Ein Dokument samt Cursor. Das Tiefenfeld gehoert dem Aufrufer: seine
/// Groesse IST die Verschachtelungsgrenze, und wer flache Inventare liest,
/// zahlt auch nur dafuer.
///
///     var speicher: [16]u8 = undefined;
///     var doc = Document.init(&dev, bytes, &speicher);
///     const version = try doc.readString("entries[3].version", &puffer);
pub const Document = struct {
    dev: *const r4dev.Context,
    cursor: Cursor,

    pub fn init(dev: *const r4dev.Context, bytes: []const u8, depth_stack: []u8) Document {
        var self = Document{
            .dev = dev,
            .cursor = .{ .depth_stack = depth_stack.ptr, .depth_capacity = @intCast(depth_stack.len) },
        };
        var request = Request{ .cursor = &self.cursor, .doc = bytes.ptr, .doc_len = @intCast(bytes.len) };
        _ = self.call(op_open, &request, null);
        return self;
    }

    pub fn token(self: *const Document) Token {
        return @enumFromInt(self.cursor.token);
    }

    /// Rohbytes des aktuellen Tokens direkt aus dem aufrufereigenen
    /// Dokument. Der Cursor wurde weiterhin ausschliesslich durch JSON.R4P
    /// bewegt; diese Sicht vermeidet nur eine zweite Kopie grosser Kataloge.
    pub fn tokenBytes(self: *const Document) ?[]const u8 {
        const bytes = self.cursor.doc orelse return null;
        if (self.cursor.token_start > self.cursor.token_end or
            self.cursor.token_end > self.cursor.doc_len) return null;
        return bytes[self.cursor.token_start..self.cursor.token_end];
    }

    /// Einen einzelnen Token weiterschalten. Container-Iteratoren bauen
    /// darauf auf; ein strikter Objektleser benoetigt den Schritt auch fuer
    /// den Wechsel vom Membernamen zu dessen Wert.
    pub fn next(self: *Document) Error!void {
        var request = Request{ .cursor = &self.cursor };
        return statusToError(self.call(op_next, &request, null));
    }

    /// Stellt den Cursor auf den Wert unter dem Pfad. Pfadsyntax: Schluessel
    /// mit Punkt, Index mit [n].
    pub fn select(self: *Document, path: []const u8) Error!void {
        var request = Request{ .cursor = &self.cursor, .path = path.ptr, .path_len = @intCast(path.len) };
        return statusToError(self.call(op_select, &request, null));
    }

    /// Rohbytes des aktuellen Tokens in den Puffer des Aufrufers. Bei
    /// Zeichenketten ohne Anfuehrungszeichen; Escapes bleiben unaufgeloest.
    pub fn value(self: *Document, out: []u8) Error![]u8 {
        var request = Request{ .cursor = &self.cursor };
        var buffer = abi.ProtocolBuffer{ .data = out.ptr, .len = 0, .capacity = @intCast(out.len) };
        try statusToError(self.call(op_value, &request, &buffer));
        return out[0..@intCast(buffer.len)];
    }

    /// Bequemer Einzelgriff: auswaehlen und Wert holen.
    pub fn readString(self: *Document, path: []const u8, out: []u8) Error![]u8 {
        try self.select(path);
        return self.value(out);
    }

    pub fn readU64(self: *Document, path: []const u8) Error!u64 {
        var scratch: [24]u8 = undefined;
        const bytes = try self.readString(path, &scratch);
        var result: u64 = 0;
        if (bytes.len == 0) return Error.BadDocument;
        for (bytes) |ch| {
            if (ch < '0' or ch > '9') return Error.BadDocument;
            result = result * 10 + (ch - '0');
        }
        return result;
    }

    /// In das aktuelle Array oder Objekt hineingehen.
    pub fn enter(self: *Document) Error!void {
        var request = Request{ .cursor = &self.cursor };
        return statusToError(self.call(op_enter, &request, null));
    }

    /// Naechstes Element derselben Ebene. Ohne diesen Weg waere ein Durchlauf
    /// ueber n Eintraege quadratisch, weil jeder Selektor am Dokumentanfang
    /// neu beginnt.
    pub fn nextElement(self: *Document) Error!void {
        var request = Request{ .cursor = &self.cursor };
        return statusToError(self.call(op_next_element, &request, null));
    }

    /// Ersetzt den Wert unter dem Pfad. value ist roher JSON-Text, also mit
    /// Anfuehrungszeichen fuer Zeichenketten. Unberuehrte Bereiche des
    /// Dokuments bleiben byteidentisch.
    pub fn set(self: *Document, path: []const u8, raw_value: []const u8, out: []u8) Error![]u8 {
        return self.editInto(op_set, path, raw_value, out);
    }

    pub fn remove(self: *Document, path: []const u8, out: []u8) Error![]u8 {
        return self.editInto(op_remove, path, null, out);
    }

    /// Fuegt als letztes Element in das Array unter dem Pfad ein.
    pub fn insert(self: *Document, path: []const u8, raw_value: []const u8, out: []u8) Error![]u8 {
        return self.editInto(op_insert, path, raw_value, out);
    }

    fn editInto(self: *Document, op: u32, path: []const u8, raw_value: ?[]const u8, out: []u8) Error![]u8 {
        var request = Request{ .cursor = &self.cursor, .path = path.ptr, .path_len = @intCast(path.len) };
        if (raw_value) |v| {
            request.value = v.ptr;
            request.value_len = @intCast(v.len);
        }
        var buffer = abi.ProtocolBuffer{ .data = out.ptr, .len = 0, .capacity = @intCast(out.len) };
        try statusToError(self.call(op, &request, &buffer));
        return out[0..@intCast(buffer.len)];
    }

    fn call(self: *const Document, op: u32, request: *Request, out: ?*abi.ProtocolBuffer) i32 {
        var empty = abi.ProtocolBuffer{ .data = null, .len = 0, .capacity = 0 };
        const in = abi.ProtocolBuffer{
            .data = @ptrCast(request),
            .len = @sizeOf(Request),
            .capacity = @sizeOf(Request),
        };
        return self.dev.protocolDispatch(role, op, &in, out orelse &empty);
    }
};

// Das Layout gegen den Protokollkern zu halten waere hier ein Test gegen
// selbstgeschriebene Zahlen. Er steht deshalb als Conformance-Test bei dem
// Modul, das beide Seiten importieren kann:
// Code/System/Protocols/Json/Tests/Conformance/CheckJsonAbi.zig

test "protocol status codes map onto named errors" {
    try std.testing.expectError(Error.NotFound, statusToError(-7));
    try std.testing.expectError(Error.OutputTooSmall, statusToError(-5));
    try std.testing.expectError(Error.DepthExceeded, statusToError(-6));
    try std.testing.expectError(Error.Unavailable, statusToError(-1));
    try statusToError(0);
    try std.testing.expect(mapStatus(0) == null);
}
