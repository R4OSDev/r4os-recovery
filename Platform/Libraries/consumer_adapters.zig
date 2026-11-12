//! Concrete specializations of the existing generic helpers. No policy or
//! implementation is duplicated across language consumers.
const owners = @import("consumer_helpers.zig");
const r4os = @import("r4os");
const Sys = r4os.r4sys.Context;
const Editor = r4os.gui.TextArea([]u8);
pub const Saver = struct {
    user: ?*anyopaque = null,
    callback: *const fn (?*anyopaque) callconv(.c) i32,
    pub fn save(self: Saver) i32 {
        return self.callback(self.user);
    }
};

pub const Config = struct {
    const original = owners.config;
    pub fn readString(ctx: *Sys, path: [*:0]const u8, key: []const u8, fallback: []const u8, out: []u8) i32 {
        return original.readString(ctx, path, key, fallback, out);
    }
    pub fn readBool(ctx: *Sys, path: [*:0]const u8, key: []const u8, fallback: bool, out: *bool) i32 {
        return original.readBool(ctx, path, key, fallback, out);
    }
    pub fn readU32(ctx: *Sys, path: [*:0]const u8, key: []const u8, fallback: u32, out: *u32) i32 {
        return original.readU32(ctx, path, key, fallback, out);
    }
    pub fn readI32(ctx: *Sys, path: [*:0]const u8, key: []const u8, fallback: i32, out: *i32) i32 {
        return original.readI32(ctx, path, key, fallback, out);
    }
    pub fn readRgb24(ctx: *Sys, path: [*:0]const u8, key: []const u8, fallback: u32, out: *u32) i32 {
        return original.readRgb24(ctx, path, key, fallback, out);
    }
    pub fn writeString(ctx: *Sys, path: [*:0]const u8, key: []const u8, value: []const u8) i32 {
        return original.writeString(ctx, path, key, value);
    }
    pub fn writeBool(ctx: *Sys, path: [*:0]const u8, key: []const u8, value: bool) i32 {
        return original.writeBool(ctx, path, key, value);
    }
    pub fn writeU32(ctx: *Sys, path: [*:0]const u8, key: []const u8, value: u32) i32 {
        return original.writeU32(ctx, path, key, value);
    }
    pub fn writeI32(ctx: *Sys, path: [*:0]const u8, key: []const u8, value: i32) i32 {
        return original.writeI32(ctx, path, key, value);
    }
    pub fn writeRgb24(ctx: *Sys, path: [*:0]const u8, key: []const u8, value: u32) i32 {
        return original.writeRgb24(ctx, path, key, value);
    }
    pub fn saveDocument(ctx: *Sys, path: [*:0]const u8, bytes: []const u8) i32 {
        return original.saveDocument(ctx, path, bytes);
    }
    pub fn recoverDocumentSave(ctx: *Sys, path: [*:0]const u8) i32 {
        return original.recoverDocumentSave(ctx, path);
    }
    pub fn hasDocumentSaveLeftovers(ctx: *Sys, path: [*:0]const u8) bool {
        return original.hasDocumentSaveLeftovers(ctx, path);
    }
};

pub const Settings = struct {
    const original = owners.settings;
    pub fn ensureSystemDirs(ctx: *Sys) void {
        return original.ensureSystemDirs(ctx);
    }
    pub fn ensureAppDirs(ctx: *Sys) void {
        return original.ensureAppDirs(ctx);
    }
    pub fn ensureDesktopDirs(ctx: *Sys) void {
        return original.ensureDesktopDirs(ctx);
    }
    pub fn flushIfDue(self: *original.Writeback, now: u64, saver: Saver) original.WritebackFlush {
        return original.Writeback.flushIfDue(self, now, saver);
    }
    pub fn flushNow(self: *original.Writeback, now: u64, saver: Saver) original.WritebackFlush {
        return original.Writeback.flushNow(self, now, saver);
    }
};

pub const TextFile = struct {
    const original = @import("R4STD/Bindings/Zig/text_file.zig");
    pub fn loadIntoTextArea(sys: *Sys, path: [*:0]const u8, editor: *Editor, view: r4os.gui.TextAreaView) original.LoadResult {
        return original.loadIntoTextArea(sys, path, editor, view);
    }
    pub fn saveFromTextArea(sys: *Sys, path: [*:0]const u8, editor: *Editor) original.SaveResult {
        return original.saveFromTextArea(sys, path, editor);
    }
};

pub const FileHandler = struct {
    const original = owners.file_handler;
    pub fn resolvePath(
        sys: *Sys,
        config: *const owners.app_assoc.Config,
        catalog: *const r4os.subsystem_catalog.Catalog,
        path: []const u8,
        args_out: []u8,
        out: *original.Resolution,
        access: *owners.subsystem_runtime.AccessStats,
    ) original.PathError!void {
        return original.resolvePath(sys, config, catalog, path, args_out, out, access);
    }
    pub fn collectPathChoices(
        sys: *Sys,
        config: *const owners.app_assoc.Config,
        catalog: *const r4os.subsystem_catalog.Catalog,
        path: []const u8,
        out: *original.ChoiceList,
        access: *owners.subsystem_runtime.AccessStats,
    ) original.PathError!void {
        return original.collectPathChoices(sys, config, catalog, path, out, access);
    }
};

pub const Subsystem = struct {
    const original = owners.subsystem_runtime;
    pub fn load(sys: *Sys) original.LoadStatus {
        return original.load(sys);
    }
    pub fn inspect(sys: *Sys, guest_path: []const u8) original.ProbeError!original.Inspection {
        return original.inspect(sys, guest_path);
    }
    pub fn completeProbe(sys: *Sys, input: r4os.subsystem_catalog.Input, access: *original.AccessStats) original.ProbeError!r4os.subsystem_catalog.Input {
        return original.completeProbe(sys, input, access);
    }
    pub fn probe(sys: *Sys, guest_path: []const u8) original.ProbeError!r4os.subsystem_catalog.Input {
        return original.probe(sys, guest_path);
    }
    pub fn hostPresent(sys: *Sys, host_path: []const u8) bool {
        return original.hostPresent(sys, host_path);
    }
};
