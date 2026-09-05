const std = @import("std");
const navigation = @import("web_navigation.zig");
const web_url = @import("web_url.zig");

pub const max_origin_host_bytes: usize = 253;
pub const max_policy_bytes: usize = 1024;
pub const max_cookies: usize = 32;
pub const max_cookie_name_bytes: usize = 64;
pub const max_cookie_value_bytes: usize = 4096;
pub const max_cookie_path_bytes: usize = 256;
pub const max_storage_origins: usize = 8;
pub const max_storage_entries: usize = 24;
pub const max_storage_key_bytes: usize = 96;
pub const max_storage_value_bytes: usize = 512;
pub const max_persistence_bytes: usize = 192 * 1024;

pub const Error = error{
    InvalidUrl,
    UnsupportedOrigin,
    OriginLimit,
    PolicyTooLarge,
    InvalidPolicy,
    CookieLimit,
    InvalidCookie,
    StorageLimit,
    KeyTooLarge,
    ValueTooLarge,
    PersistenceLimit,
    MalformedPersistence,
};

pub const OriginScheme = enum(u8) {
    opaque_origin,
    http,
    https,
};

pub const Origin = struct {
    scheme: OriginScheme = .opaque_origin,
    host: [max_origin_host_bytes + 1]u8 = .{0} ** (max_origin_host_bytes + 1),
    host_len: usize = 0,
    port: u16 = 0,
    opaque_id: u32 = 0,

    pub fn parse(raw_url: []const u8, opaque_id: u32) Error!Origin {
        const normalized = navigation.parse(raw_url) catch return error.InvalidUrl;
        if (normalized.scheme == .about) return .{ .opaque_id = opaque_id };
        const bytes = normalized.bytes();
        const parsed = web_url.parts(bytes) catch return error.InvalidUrl;
        if (parsed.hostname.len > max_origin_host_bytes) return error.InvalidUrl;
        const default_port: u16 = if (normalized.scheme == .https) 443 else 80;
        const port = if (parsed.port.len > 0) std.fmt.parseInt(u16, parsed.port, 10) catch return error.InvalidUrl else default_port;
        var result = Origin{
            .scheme = if (normalized.scheme == .https) .https else .http,
            .host_len = parsed.hostname.len,
            .port = port,
        };
        for (parsed.hostname, 0..) |byte, index| result.host[index] = std.ascii.toLower(byte);
        return result;
    }

    pub fn same(self: *const Origin, other: *const Origin) bool {
        if (self.scheme != other.scheme) return false;
        if (self.scheme == .opaque_origin) return self.opaque_id != 0 and self.opaque_id == other.opaque_id;
        return self.port == other.port and equal(self.hostBytes(), other.hostBytes());
    }

    pub fn potentiallyTrustworthy(self: *const Origin) bool {
        return self.scheme == .https or self.scheme == .opaque_origin;
    }

    pub fn hostBytes(self: *const Origin) []const u8 {
        return self.host[0..self.host_len];
    }

    pub fn serialize(self: *const Origin, out: []u8) ?[]const u8 {
        if (self.scheme == .opaque_origin) {
            if (out.len < 4) return null;
            @memcpy(out[0..4], "null");
            return out[0..4];
        }
        const scheme = if (self.scheme == .https) "https://" else "http://";
        const default_port: u16 = if (self.scheme == .https) 443 else 80;
        var len: usize = 0;
        if (!append(out, &len, scheme) or !append(out, &len, self.hostBytes())) return null;
        if (self.port != default_port) {
            if (!appendByte(out, &len, ':') or !appendUnsigned(out, &len, self.port)) return null;
        }
        return out[0..len];
    }
};

pub const ResourceKind = enum(u8) {
    document,
    script,
    style,
    image,
    font,
    subdocument,
    connect,
    form,
};

pub const RequestMode = enum(u8) {
    same_origin,
    cors,
    no_cors,
    navigate,
};

pub const CredentialsMode = enum(u8) {
    omit,
    same_origin,
    include,
};

pub const BlockReason = enum(u8) {
    none,
    stale_generation,
    invalid_url,
    mixed_content,
    same_origin,
    content_security_policy,
    cors,
    insecure_context,
};

pub const Decision = struct {
    allowed: bool,
    reason: BlockReason = .none,
    target: Origin = .{},
};

pub const ContentSecurityPolicy = struct {
    bytes: [max_policy_bytes]u8 = .{0} ** max_policy_bytes,
    len: usize = 0,
    default_src: Slice = .{},
    script_src: Slice = .{},
    connect_src: Slice = .{},
    style_src: Slice = .{},
    image_src: Slice = .{},
    font_src: Slice = .{},
    frame_src: Slice = .{},
    form_action: Slice = .{},
    has_default: bool = false,
    has_script: bool = false,
    has_connect: bool = false,
    has_style: bool = false,
    has_image: bool = false,
    has_font: bool = false,
    has_frame: bool = false,
    has_form: bool = false,

    const Slice = struct {
        offset: u16 = 0,
        len: u16 = 0,

        fn bytes(self: Slice, source: []const u8) []const u8 {
            const start: usize = self.offset;
            const count: usize = self.len;
            if (start > source.len or count > source.len - start) return "";
            return source[start .. start + count];
        }
    };

    pub fn parse(raw: []const u8) Error!ContentSecurityPolicy {
        if (raw.len > max_policy_bytes) return error.PolicyTooLarge;
        var policy = ContentSecurityPolicy{};
        if (raw.len > 0) @memcpy(policy.bytes[0..raw.len], raw);
        policy.len = raw.len;
        var cursor: usize = 0;
        while (cursor < raw.len) {
            const end = std.mem.indexOfScalarPos(u8, raw, cursor, ';') orelse raw.len;
            const directive = trim(raw[cursor..end]);
            cursor = if (end < raw.len) end + 1 else raw.len;
            if (directive.len == 0) continue;
            const split = firstSpace(directive);
            const name = directive[0..split];
            const values = trim(directive[split..]);
            const source_offset = @intFromPtr(values.ptr) - @intFromPtr(raw.ptr);
            if (source_offset > std.math.maxInt(u16) or values.len > std.math.maxInt(u16)) return error.PolicyTooLarge;
            const slice = Slice{ .offset = @intCast(source_offset), .len = @intCast(values.len) };
            if (equalIgnoreCase(name, "default-src") and !policy.has_default) {
                policy.default_src = slice;
                policy.has_default = true;
            } else if (equalIgnoreCase(name, "script-src") and !policy.has_script) {
                policy.script_src = slice;
                policy.has_script = true;
            } else if (equalIgnoreCase(name, "connect-src") and !policy.has_connect) {
                policy.connect_src = slice;
                policy.has_connect = true;
            } else if (equalIgnoreCase(name, "style-src") and !policy.has_style) {
                policy.style_src = slice;
                policy.has_style = true;
            } else if (equalIgnoreCase(name, "img-src") and !policy.has_image) {
                policy.image_src = slice;
                policy.has_image = true;
            } else if (equalIgnoreCase(name, "font-src") and !policy.has_font) {
                policy.font_src = slice;
                policy.has_font = true;
            } else if (equalIgnoreCase(name, "frame-src") and !policy.has_frame) {
                policy.frame_src = slice;
                policy.has_frame = true;
            } else if (equalIgnoreCase(name, "form-action") and !policy.has_form) {
                policy.form_action = slice;
                policy.has_form = true;
            }
        }
        return policy;
    }

    pub fn allows(
        self: *const ContentSecurityPolicy,
        document_origin: *const Origin,
        target_origin: *const Origin,
        kind: ResourceKind,
        inline_script: bool,
        nonce: []const u8,
    ) bool {
        const selected = self.sources(kind) orelse return true;
        const source_list = selected.bytes(self.bytes[0..self.len]);
        if (source_list.len == 0 or containsToken(source_list, "'none'")) return false;
        if (inline_script) {
            if (containsToken(source_list, "'unsafe-inline'")) return true;
            if (nonce.len > 0) {
                var buffer: [160]u8 = undefined;
                var len: usize = 0;
                if (append(buffer[0..], &len, "'nonce-") and
                    append(buffer[0..], &len, nonce) and
                    appendByte(buffer[0..], &len, '\'') and
                    containsToken(source_list, buffer[0..len]))
                {
                    return true;
                }
            }
            return false;
        }
        if (containsToken(source_list, "*")) return true;
        if (containsToken(source_list, "'self'") and document_origin.same(target_origin)) return true;
        if (target_origin.scheme == .https and containsToken(source_list, "https:")) return true;
        if (target_origin.scheme == .http and containsToken(source_list, "http:")) return true;
        var token_cursor: usize = 0;
        while (nextToken(source_list, &token_cursor)) |token| {
            if (sourceMatchesHost(token, target_origin)) return true;
        }
        return false;
    }

    /// Applies a CSP source list to a non-network scheme such as `data:`.
    /// The caller remains responsible for decoding and bounding the embedded
    /// resource; this helper only answers the policy question without
    /// inventing an HTTP origin for an opaque URL.
    pub fn allowsScheme(self: *const ContentSecurityPolicy, kind: ResourceKind, scheme: []const u8) bool {
        const selected = self.sources(kind) orelse return true;
        const source_list = selected.bytes(self.bytes[0..self.len]);
        if (source_list.len == 0 or containsToken(source_list, "'none'")) return false;
        return containsToken(source_list, "*") or containsToken(source_list, scheme);
    }

    fn sources(self: *const ContentSecurityPolicy, kind: ResourceKind) ?Slice {
        return switch (kind) {
            .script => if (self.has_script) self.script_src else if (self.has_default) self.default_src else null,
            .connect => if (self.has_connect) self.connect_src else if (self.has_default) self.default_src else null,
            .style => if (self.has_style) self.style_src else if (self.has_default) self.default_src else null,
            .image => if (self.has_image) self.image_src else if (self.has_default) self.default_src else null,
            .font => if (self.has_font) self.font_src else if (self.has_default) self.default_src else null,
            .subdocument => if (self.has_frame) self.frame_src else if (self.has_default) self.default_src else null,
            .form => if (self.has_form) self.form_action else if (self.has_default) self.default_src else null,
            .document => if (self.has_default) self.default_src else null,
        };
    }
};

pub const SecurityContext = struct {
    generation: u32 = 0,
    document_origin: Origin = .{},
    secure_context: bool = false,
    policy: ContentSecurityPolicy = .{},

    pub fn init(url: []const u8, generation: u32, csp: []const u8) Error!SecurityContext {
        const origin = try Origin.parse(url, generation);
        return .{
            .generation = generation,
            .document_origin = origin,
            .secure_context = origin.potentiallyTrustworthy(),
            .policy = try ContentSecurityPolicy.parse(csp),
        };
    }

    pub fn authorize(
        self: *const SecurityContext,
        generation: u32,
        target_url: []const u8,
        kind: ResourceKind,
        mode: RequestMode,
    ) Decision {
        if (generation != self.generation) return .{ .allowed = false, .reason = .stale_generation };
        const target = Origin.parse(target_url, generation) catch return .{ .allowed = false, .reason = .invalid_url };
        if (self.document_origin.scheme == .https and target.scheme == .http and kind != .document) {
            return .{ .allowed = false, .reason = .mixed_content, .target = target };
        }
        if (mode == .same_origin and !self.document_origin.same(&target)) {
            return .{ .allowed = false, .reason = .same_origin, .target = target };
        }
        if (!self.policy.allows(&self.document_origin, &target, kind, false, "")) {
            return .{ .allowed = false, .reason = .content_security_policy, .target = target };
        }
        return .{ .allowed = true, .target = target };
    }

    pub fn allowsInlineScript(self: *const SecurityContext, nonce: []const u8) bool {
        return self.policy.allows(&self.document_origin, &self.document_origin, .script, true, nonce);
    }

    pub fn allowsEmbeddedScheme(self: *const SecurityContext, generation: u32, kind: ResourceKind, scheme: []const u8) Decision {
        if (generation != self.generation) return .{ .allowed = false, .reason = .stale_generation };
        if (!self.policy.allowsScheme(kind, scheme)) return .{ .allowed = false, .reason = .content_security_policy };
        return .{ .allowed = true };
    }

    pub fn acceptsCors(
        self: *const SecurityContext,
        target: *const Origin,
        mode: RequestMode,
        credentials: CredentialsMode,
        allow_origin: []const u8,
        allow_credentials: bool,
    ) bool {
        if (mode == .navigate or mode == .no_cors or self.document_origin.same(target)) return true;
        if (mode == .same_origin) return false;
        var serialized: [max_origin_host_bytes + 24]u8 = undefined;
        const own = self.document_origin.serialize(serialized[0..]) orelse return false;
        if (equal(allow_origin, "*")) return credentials != .include;
        if (!equal(allow_origin, own)) return false;
        return credentials != .include or allow_credentials;
    }
};

pub const SameSite = enum(u8) {
    lax,
    strict,
    none,
};

pub const Cookie = struct {
    occupied: bool = false,
    name: Fixed(max_cookie_name_bytes) = .{},
    value: Fixed(max_cookie_value_bytes) = .{},
    domain: Fixed(max_origin_host_bytes) = .{},
    path: Fixed(max_cookie_path_bytes) = .{},
    host_only: bool = true,
    secure: bool = false,
    http_only: bool = false,
    persistent: bool = false,
    same_site: SameSite = .lax,
    sequence: u32 = 0,
};

pub const CookieJar = struct {
    entries: [max_cookies]Cookie = [_]Cookie{.{}} ** max_cookies,
    next_sequence: u32 = 1,

    pub fn setFromHeader(self: *CookieJar, origin: *const Origin, request_path: []const u8, header: []const u8) Error!void {
        try self.set(origin, request_path, header, true);
    }

    pub fn setFromDocument(self: *CookieJar, origin: *const Origin, request_path: []const u8, source: []const u8) Error!void {
        try self.set(origin, request_path, source, false);
    }

    pub fn writeRequestHeader(
        self: *const CookieJar,
        origin: *const Origin,
        request_path: []const u8,
        same_site: bool,
        out: []u8,
    ) []const u8 {
        var len: usize = 0;
        for (self.entries) |entry| {
            if (!entry.occupied or !cookieMatches(&entry, origin, request_path, same_site, false)) continue;
            if (len > 0 and !append(out, &len, "; ")) break;
            if (!append(out, &len, entry.name.bytes()) or
                !appendByte(out, &len, '=') or
                !append(out, &len, entry.value.bytes()))
            {
                break;
            }
        }
        return out[0..len];
    }

    pub fn writeDocumentCookie(self: *const CookieJar, origin: *const Origin, request_path: []const u8, out: []u8) []const u8 {
        var len: usize = 0;
        for (self.entries) |entry| {
            if (!entry.occupied or !cookieMatches(&entry, origin, request_path, true, true)) continue;
            if (len > 0 and !append(out, &len, "; ")) break;
            if (!append(out, &len, entry.name.bytes()) or
                !appendByte(out, &len, '=') or
                !append(out, &len, entry.value.bytes()))
            {
                break;
            }
        }
        return out[0..len];
    }

    fn set(self: *CookieJar, origin: *const Origin, request_path: []const u8, source: []const u8, allow_http_only: bool) Error!void {
        if (origin.scheme == .opaque_origin) return error.InvalidCookie;
        const first_end = std.mem.indexOfScalar(u8, source, ';') orelse source.len;
        const pair = trim(source[0..first_end]);
        const separator = std.mem.indexOfScalar(u8, pair, '=') orelse return error.InvalidCookie;
        const name = trim(pair[0..separator]);
        const value = trim(pair[separator + 1 ..]);
        if (!validCookieName(name) or value.len > max_cookie_value_bytes) return error.InvalidCookie;

        var candidate = Cookie{};
        try candidate.name.set(name);
        try candidate.value.set(value);
        try candidate.domain.set(origin.hostBytes());
        try candidate.path.set(defaultCookiePath(request_path));
        var delete = false;

        var cursor = if (first_end < source.len) first_end + 1 else source.len;
        while (cursor < source.len) {
            const end = std.mem.indexOfScalarPos(u8, source, cursor, ';') orelse source.len;
            const attribute = trim(source[cursor..end]);
            cursor = if (end < source.len) end + 1 else source.len;
            if (attribute.len == 0) continue;
            const equals_index = std.mem.indexOfScalar(u8, attribute, '=');
            const key = trim(attribute[0 .. equals_index orelse attribute.len]);
            const attribute_value = if (equals_index) |index| trim(attribute[index + 1 ..]) else "";
            if (equalIgnoreCase(key, "Domain")) {
                var domain = attribute_value;
                while (domain.len > 0 and domain[0] == '.') domain = domain[1..];
                if (!domainMatches(origin.hostBytes(), domain)) return error.InvalidCookie;
                try candidate.domain.setLower(domain);
                candidate.host_only = false;
            } else if (equalIgnoreCase(key, "Path")) {
                if (attribute_value.len > 0 and attribute_value[0] == '/') try candidate.path.set(attribute_value);
            } else if (equalIgnoreCase(key, "Secure")) {
                candidate.secure = true;
            } else if (equalIgnoreCase(key, "HttpOnly")) {
                if (allow_http_only) candidate.http_only = true;
            } else if (equalIgnoreCase(key, "SameSite")) {
                if (equalIgnoreCase(attribute_value, "Strict")) candidate.same_site = .strict else if (equalIgnoreCase(attribute_value, "None")) candidate.same_site = .none else candidate.same_site = .lax;
            } else if (equalIgnoreCase(key, "Max-Age") and equal(attribute_value, "0")) {
                delete = true;
            } else if (equalIgnoreCase(key, "Max-Age")) {
                const seconds = std.fmt.parseInt(i64, attribute_value, 10) catch return error.InvalidCookie;
                if (seconds <= 0) delete = true else candidate.persistent = true;
            } else if (equalIgnoreCase(key, "Expires") and attribute_value.len > 0) {
                candidate.persistent = true;
            }
        }
        if (candidate.same_site == .none and !candidate.secure) return error.InvalidCookie;
        if (candidate.secure and origin.scheme != .https) return error.InvalidCookie;
        if (self.find(candidate.name.bytes(), candidate.domain.bytes(), candidate.path.bytes())) |index| {
            if (delete) {
                self.entries[index] = .{};
                return;
            }
            candidate.sequence = self.entries[index].sequence;
            self.entries[index] = candidate;
            return;
        }
        if (delete) return;
        for (&self.entries) |*entry| {
            if (entry.occupied) continue;
            candidate.occupied = true;
            candidate.sequence = self.next_sequence;
            self.next_sequence +%= 1;
            entry.* = candidate;
            return;
        }
        return error.CookieLimit;
    }

    fn find(self: *const CookieJar, name: []const u8, domain: []const u8, path: []const u8) ?usize {
        for (self.entries, 0..) |entry, index| {
            if (entry.occupied and equal(entry.name.bytes(), name) and equal(entry.domain.bytes(), domain) and equal(entry.path.bytes(), path)) return index;
        }
        return null;
    }
};

pub fn Fixed(comptime capacity: usize) type {
    return struct {
        storage: [capacity + 1]u8 = .{0} ** (capacity + 1),
        len: usize = 0,

        const Self = @This();

        pub fn bytes(self: *const Self) []const u8 {
            return self.storage[0..self.len];
        }

        pub fn set(self: *Self, value: []const u8) Error!void {
            if (value.len > capacity) return if (capacity == max_storage_key_bytes) error.KeyTooLarge else error.ValueTooLarge;
            @memset(&self.storage, 0);
            if (value.len > 0) @memcpy(self.storage[0..value.len], value);
            self.len = value.len;
        }

        pub fn setLower(self: *Self, value: []const u8) Error!void {
            try self.set(value);
            for (self.storage[0..self.len]) |*byte| byte.* = std.ascii.toLower(byte.*);
        }
    };
}

pub const StorageEntry = struct {
    occupied: bool = false,
    key: Fixed(max_storage_key_bytes) = .{},
    value: Fixed(max_storage_value_bytes) = .{},
};

pub const StorageArea = struct {
    occupied: bool = false,
    origin: Origin = .{},
    entries: [max_storage_entries]StorageEntry = [_]StorageEntry{.{}} ** max_storage_entries,

    pub fn get(self: *const StorageArea, key: []const u8) ?[]const u8 {
        for (&self.entries) |*entry| {
            if (entry.occupied and equal(entry.key.bytes(), key)) return entry.value.bytes();
        }
        return null;
    }

    pub fn set(self: *StorageArea, key: []const u8, value: []const u8) Error!void {
        if (key.len > max_storage_key_bytes) return error.KeyTooLarge;
        if (value.len > max_storage_value_bytes) return error.ValueTooLarge;
        for (&self.entries) |*entry| {
            if (!entry.occupied or !equal(entry.key.bytes(), key)) continue;
            try entry.value.set(value);
            return;
        }
        for (&self.entries) |*entry| {
            if (entry.occupied) continue;
            entry.occupied = true;
            try entry.key.set(key);
            try entry.value.set(value);
            return;
        }
        return error.StorageLimit;
    }

    pub fn remove(self: *StorageArea, key: []const u8) void {
        for (&self.entries) |*entry| {
            if (entry.occupied and equal(entry.key.bytes(), key)) {
                entry.* = .{};
                return;
            }
        }
    }

    pub fn clear(self: *StorageArea) void {
        self.entries = [_]StorageEntry{.{}} ** max_storage_entries;
    }

    pub fn count(self: *const StorageArea) usize {
        var result: usize = 0;
        for (self.entries) |entry| if (entry.occupied) {
            result += 1;
        };
        return result;
    }
};

pub const StorageSet = struct {
    areas: [max_storage_origins]StorageArea = [_]StorageArea{.{}} ** max_storage_origins,

    pub fn area(self: *StorageSet, origin: *const Origin) Error!*StorageArea {
        for (&self.areas) |*candidate| {
            if (candidate.occupied and candidate.origin.same(origin)) return candidate;
        }
        for (&self.areas) |*candidate| {
            if (candidate.occupied) continue;
            candidate.occupied = true;
            candidate.origin = origin.*;
            return candidate;
        }
        return error.OriginLimit;
    }
};

pub const BrowserStorage = struct {
    cookies: CookieJar = .{},
    local: StorageSet = .{},
    session: StorageSet = .{},

    pub fn reset(self: *BrowserStorage) void {
        self.cookies.next_sequence = 1;
        for (&self.cookies.entries) |*entry| entry.occupied = false;
        resetStorageSet(&self.local);
        resetStorageSet(&self.session);
    }

    pub fn encode(self: *const BrowserStorage, out: []u8) Error![]const u8 {
        var writer = PersistenceWriter{ .out = out };
        try writer.bytes("R4WS");
        try writer.u16Value(1);
        var cookie_count: u16 = 0;
        for (self.cookies.entries) |entry| if (entry.occupied and entry.persistent) {
            cookie_count += 1;
        };
        try writer.u16Value(cookie_count);
        for (self.cookies.entries) |entry| {
            if (!entry.occupied or !entry.persistent) continue;
            try writer.string(entry.name.bytes());
            try writer.string(entry.value.bytes());
            try writer.string(entry.domain.bytes());
            try writer.string(entry.path.bytes());
            var flags: u8 = 0;
            if (entry.host_only) flags |= 1;
            if (entry.secure) flags |= 2;
            if (entry.http_only) flags |= 4;
            flags |= @as(u8, @intFromEnum(entry.same_site)) << 3;
            if (entry.persistent) flags |= 0x20;
            try writer.byte(flags);
            try writer.u32Value(entry.sequence);
        }

        var area_count: u16 = 0;
        for (self.local.areas) |area| if (area.occupied and area.count() > 0) {
            area_count += 1;
        };
        try writer.u16Value(area_count);
        for (self.local.areas) |area| {
            if (!area.occupied or area.count() == 0) continue;
            try writer.origin(&area.origin);
            try writer.u16Value(@intCast(area.count()));
            for (area.entries) |entry| {
                if (!entry.occupied) continue;
                try writer.string(entry.key.bytes());
                try writer.string(entry.value.bytes());
            }
        }
        return out[0..writer.len];
    }

    pub fn decode(self: *BrowserStorage, input: []const u8) Error!void {
        var reader = PersistenceReader{ .input = input };
        if (!equal(try reader.take(4), "R4WS") or try reader.u16Value() != 1) return error.MalformedPersistence;
        self.reset();
        const cookie_count = try reader.u16Value();
        if (cookie_count > max_cookies) return error.MalformedPersistence;
        var cookie_index: usize = 0;
        while (cookie_index < cookie_count) : (cookie_index += 1) {
            var entry = Cookie{ .occupied = true };
            try entry.name.set(try reader.string(max_cookie_name_bytes));
            try entry.value.set(try reader.string(max_cookie_value_bytes));
            try entry.domain.setLower(try reader.string(max_origin_host_bytes));
            try entry.path.set(try reader.string(max_cookie_path_bytes));
            const flags = try reader.byte();
            entry.host_only = flags & 1 != 0;
            entry.secure = flags & 2 != 0;
            entry.http_only = flags & 4 != 0;
            entry.persistent = flags & 0x20 != 0;
            const same_site: u8 = (flags >> 3) & 3;
            if (same_site > @intFromEnum(SameSite.none)) return error.MalformedPersistence;
            entry.same_site = @enumFromInt(same_site);
            entry.sequence = try reader.u32Value();
            self.cookies.entries[cookie_index] = entry;
            self.cookies.next_sequence = @max(self.cookies.next_sequence, entry.sequence +% 1);
        }

        const area_count = try reader.u16Value();
        if (area_count > max_storage_origins) return error.MalformedPersistence;
        var area_index: usize = 0;
        while (area_index < area_count) : (area_index += 1) {
            const area = &self.local.areas[area_index];
            area.occupied = true;
            area.origin = try reader.origin();
            const entry_count = try reader.u16Value();
            if (entry_count > max_storage_entries) return error.MalformedPersistence;
            var entry_index: usize = 0;
            while (entry_index < entry_count) : (entry_index += 1) {
                area.entries[entry_index].occupied = true;
                try area.entries[entry_index].key.set(try reader.string(max_storage_key_bytes));
                try area.entries[entry_index].value.set(try reader.string(max_storage_value_bytes));
            }
        }
        if (reader.pos != input.len) return error.MalformedPersistence;
    }
};

fn resetStorageSet(set: *StorageSet) void {
    for (&set.areas) |*area| {
        area.occupied = false;
        for (&area.entries) |*entry| entry.occupied = false;
    }
}

const PersistenceWriter = struct {
    out: []u8,
    len: usize = 0,

    fn byte(self: *PersistenceWriter, value: u8) Error!void {
        if (self.len >= self.out.len or self.len >= max_persistence_bytes) return error.PersistenceLimit;
        self.out[self.len] = value;
        self.len += 1;
    }

    fn bytes(self: *PersistenceWriter, value: []const u8) Error!void {
        if (value.len > self.out.len -| self.len or value.len > max_persistence_bytes -| self.len) return error.PersistenceLimit;
        if (value.len > 0) @memcpy(self.out[self.len .. self.len + value.len], value);
        self.len += value.len;
    }

    fn u16Value(self: *PersistenceWriter, value: u16) Error!void {
        try self.byte(@truncate(value));
        try self.byte(@truncate(value >> 8));
    }

    fn u32Value(self: *PersistenceWriter, value: u32) Error!void {
        try self.u16Value(@truncate(value));
        try self.u16Value(@truncate(value >> 16));
    }

    fn string(self: *PersistenceWriter, value: []const u8) Error!void {
        if (value.len > std.math.maxInt(u16)) return error.PersistenceLimit;
        try self.u16Value(@intCast(value.len));
        try self.bytes(value);
    }

    fn origin(self: *PersistenceWriter, value: *const Origin) Error!void {
        try self.byte(@intFromEnum(value.scheme));
        try self.string(value.hostBytes());
        try self.u16Value(value.port);
        try self.u32Value(value.opaque_id);
    }
};

const PersistenceReader = struct {
    input: []const u8,
    pos: usize = 0,

    fn take(self: *PersistenceReader, count: usize) Error![]const u8 {
        if (count > self.input.len -| self.pos or self.pos + count > max_persistence_bytes) return error.MalformedPersistence;
        const value = self.input[self.pos .. self.pos + count];
        self.pos += count;
        return value;
    }

    fn byte(self: *PersistenceReader) Error!u8 {
        return (try self.take(1))[0];
    }

    fn u16Value(self: *PersistenceReader) Error!u16 {
        const value = try self.take(2);
        return @as(u16, value[0]) | (@as(u16, value[1]) << 8);
    }

    fn u32Value(self: *PersistenceReader) Error!u32 {
        const low = try self.u16Value();
        const high = try self.u16Value();
        return @as(u32, low) | (@as(u32, high) << 16);
    }

    fn string(self: *PersistenceReader, maximum: usize) Error![]const u8 {
        const count = try self.u16Value();
        if (count > maximum) return error.MalformedPersistence;
        return self.take(count);
    }

    fn origin(self: *PersistenceReader) Error!Origin {
        const raw_scheme = try self.byte();
        if (raw_scheme > @intFromEnum(OriginScheme.https)) return error.MalformedPersistence;
        const host = try self.string(max_origin_host_bytes);
        var result = Origin{
            .scheme = @enumFromInt(raw_scheme),
            .port = try self.u16Value(),
            .opaque_id = try self.u32Value(),
            .host_len = host.len,
        };
        for (host, 0..) |value, index| result.host[index] = std.ascii.toLower(value);
        if (result.scheme == .opaque_origin and result.opaque_id == 0) return error.MalformedPersistence;
        return result;
    }
};

fn cookieMatches(entry: *const Cookie, origin: *const Origin, path: []const u8, same_site: bool, document_access: bool) bool {
    if (origin.scheme == .opaque_origin) return false;
    if (entry.host_only) {
        if (!equal(entry.domain.bytes(), origin.hostBytes())) return false;
    } else if (!domainMatches(origin.hostBytes(), entry.domain.bytes())) return false;
    if (!std.mem.startsWith(u8, path, entry.path.bytes())) return false;
    if (entry.secure and origin.scheme != .https) return false;
    if (document_access and entry.http_only) return false;
    if (!same_site and entry.same_site != .none) return false;
    return true;
}

fn defaultCookiePath(path: []const u8) []const u8 {
    if (path.len == 0 or path[0] != '/') return "/";
    const slash = std.mem.lastIndexOfScalar(u8, path, '/') orelse return "/";
    return if (slash == 0) "/" else path[0..slash];
}

fn domainMatches(host: []const u8, domain: []const u8) bool {
    if (domain.len == 0 or domain.len > host.len) return false;
    if (equalIgnoreCase(host, domain)) return true;
    const start = host.len - domain.len;
    return start > 0 and host[start - 1] == '.' and equalIgnoreCase(host[start..], domain);
}

fn validCookieName(name: []const u8) bool {
    if (name.len == 0 or name.len > max_cookie_name_bytes) return false;
    for (name) |byte| {
        if (byte <= 0x20 or byte >= 0x7F or std.mem.indexOfScalar(u8, "()<>@,;:\\\"/[]?={}", byte) != null) return false;
    }
    return true;
}

fn sourceMatchesHost(token: []const u8, origin: *const Origin) bool {
    if (token.len == 0 or token[0] == '\'') return false;
    var url_buffer: [navigation.url_capacity + 1]u8 = undefined;
    var len: usize = 0;
    if (std.mem.indexOf(u8, token, "://") == null) {
        const scheme = if (origin.scheme == .https) "https://" else "http://";
        if (!append(url_buffer[0..], &len, scheme)) return false;
    }
    if (!append(url_buffer[0..], &len, token)) return false;
    const parsed = Origin.parse(url_buffer[0..len], 1) catch return false;
    return parsed.same(origin);
}

fn containsToken(source: []const u8, wanted: []const u8) bool {
    var cursor: usize = 0;
    while (nextToken(source, &cursor)) |token| if (equalIgnoreCase(token, wanted)) return true;
    return false;
}

fn nextToken(source: []const u8, cursor: *usize) ?[]const u8 {
    while (cursor.* < source.len and std.ascii.isWhitespace(source[cursor.*])) cursor.* += 1;
    if (cursor.* >= source.len) return null;
    const start = cursor.*;
    while (cursor.* < source.len and !std.ascii.isWhitespace(source[cursor.*])) cursor.* += 1;
    return source[start..cursor.*];
}

fn firstSpace(source: []const u8) usize {
    for (source, 0..) |byte, index| if (std.ascii.isWhitespace(byte)) return index;
    return source.len;
}

fn trim(source: []const u8) []const u8 {
    return std.mem.trim(u8, source, " \t\r\n");
}

fn equal(left: []const u8, right: []const u8) bool {
    return std.mem.eql(u8, left, right);
}

fn equalIgnoreCase(left: []const u8, right: []const u8) bool {
    return std.ascii.eqlIgnoreCase(left, right);
}

fn append(out: []u8, len: *usize, value: []const u8) bool {
    if (value.len > out.len -| len.*) return false;
    if (value.len > 0) @memcpy(out[len.* .. len.* + value.len], value);
    len.* += value.len;
    return true;
}

fn appendByte(out: []u8, len: *usize, value: u8) bool {
    if (len.* >= out.len) return false;
    out[len.*] = value;
    len.* += 1;
    return true;
}

fn appendUnsigned(out: []u8, len: *usize, value: u16) bool {
    var digits: [5]u8 = undefined;
    var count: usize = 0;
    var remaining = value;
    if (remaining == 0) return appendByte(out, len, '0');
    while (remaining > 0) : (remaining /= 10) {
        digits[count] = @intCast('0' + remaining % 10);
        count += 1;
    }
    while (count > 0) {
        count -= 1;
        if (!appendByte(out, len, digits[count])) return false;
    }
    return true;
}

test "origin policy blocks mixed content same-origin violations and stale work" {
    const context = try SecurityContext.init(
        "https://example.com/app/index.html",
        7,
        "default-src 'self'; connect-src 'self' https://api.example.com; script-src 'nonce-r4'; frame-src https://frames.example.com",
    );
    try std.testing.expect(context.secure_context);
    try std.testing.expect(context.authorize(7, "https://example.com/data", .connect, .same_origin).allowed);
    try std.testing.expectEqual(BlockReason.same_origin, context.authorize(7, "https://api.example.com/data", .connect, .same_origin).reason);
    try std.testing.expect(context.authorize(7, "https://api.example.com/data", .connect, .cors).allowed);
    try std.testing.expectEqual(BlockReason.mixed_content, context.authorize(7, "http://example.com/a.js", .script, .cors).reason);
    try std.testing.expect(context.authorize(7, "https://frames.example.com/child", .subdocument, .navigate).allowed);
    try std.testing.expectEqual(BlockReason.content_security_policy, context.authorize(7, "https://other.example.com/child", .subdocument, .navigate).reason);
    try std.testing.expectEqual(BlockReason.mixed_content, context.authorize(7, "http://frames.example.com/child", .subdocument, .navigate).reason);
    try std.testing.expectEqual(BlockReason.stale_generation, context.authorize(6, "https://example.com/data", .connect, .cors).reason);
    try std.testing.expect(context.allowsInlineScript("r4"));
    try std.testing.expect(!context.allowsInlineScript(""));
}

test "CSP treats bounded embedded image schemes without a network origin" {
    const allowed = try SecurityContext.init("https://example.com/", 9, "default-src 'self'; img-src 'self' data:");
    try std.testing.expect(allowed.allowsEmbeddedScheme(9, .image, "data:").allowed);
    try std.testing.expectEqual(BlockReason.content_security_policy, allowed.allowsEmbeddedScheme(9, .script, "data:").reason);
    try std.testing.expectEqual(BlockReason.stale_generation, allowed.allowsEmbeddedScheme(8, .image, "data:").reason);

    const denied = try SecurityContext.init("https://example.com/", 10, "img-src 'none'");
    try std.testing.expectEqual(BlockReason.content_security_policy, denied.allowsEmbeddedScheme(10, .image, "data:").reason);
}

test "CORS requires an exact origin and credentials acknowledgement" {
    const context = try SecurityContext.init(
        "https://app.example/",
        1,
        "",
    );
    const target = try Origin.parse("https://api.example/data", 1);
    try std.testing.expect(context.acceptsCors(&target, .cors, .omit, "*", false));
    try std.testing.expect(!context.acceptsCors(&target, .cors, .include, "*", true));
    try std.testing.expect(!context.acceptsCors(&target, .cors, .include, "https://app.example", false));
    try std.testing.expect(context.acceptsCors(&target, .cors, .include, "https://app.example", true));
}

test "cookies honor host path secure HttpOnly and SameSite boundaries" {
    const origin = try Origin.parse("https://shop.example/account/view", 1);
    var jar = CookieJar{};
    try jar.setFromHeader(&origin, "/account/view", "sid=abc; Path=/account; Secure; HttpOnly; SameSite=Strict");
    try jar.setFromDocument(&origin, "/account/view", "theme=dark; Path=/");
    var out: [512]u8 = undefined;
    try std.testing.expectEqualStrings("sid=abc; theme=dark", jar.writeRequestHeader(&origin, "/account/orders", true, out[0..]));
    try std.testing.expectEqualStrings("theme=dark", jar.writeDocumentCookie(&origin, "/account/orders", out[0..]));
    try std.testing.expectEqualStrings("", jar.writeRequestHeader(&origin, "/account/orders", false, out[0..]));
    try jar.setFromHeader(&origin, "/account/view", "sid=gone; Path=/account; Max-Age=0");
    try std.testing.expectEqualStrings("theme=dark", jar.writeRequestHeader(&origin, "/account/orders", true, out[0..]));
}

test "local and session storage are partitioned by origin" {
    var storage = BrowserStorage{};
    const first = try Origin.parse("https://one.example/", 1);
    const second = try Origin.parse("https://two.example/", 1);
    const first_local = try storage.local.area(&first);
    try first_local.set("answer", "42");
    try std.testing.expectEqualStrings("42", first_local.get("answer").?);
    try std.testing.expect((try storage.local.area(&second)).get("answer") == null);
    const first_session = try storage.session.area(&first);
    try std.testing.expect(first_session.get("answer") == null);
    try first_session.set("tab", "active");
    try std.testing.expectEqual(@as(usize, 1), first_session.count());
    first_session.clear();
    try std.testing.expectEqual(@as(usize, 0), first_session.count());

    try storage.cookies.setFromHeader(&first, "/", "persist=yes; Path=/; Secure; Max-Age=3600");
    var encoded: [max_persistence_bytes]u8 = undefined;
    const bytes = try storage.encode(encoded[0..]);
    var restored = BrowserStorage{};
    try restored.decode(bytes);
    try std.testing.expectEqualStrings("42", (try restored.local.area(&first)).get("answer").?);
    try std.testing.expect((try restored.session.area(&first)).get("tab") == null);
    var cookie_out: [128]u8 = undefined;
    try std.testing.expectEqualStrings("persist=yes", restored.cookies.writeRequestHeader(&first, "/", true, cookie_out[0..]));
    try std.testing.expectError(error.MalformedPersistence, restored.decode(bytes[0 .. bytes.len - 1]));
}
