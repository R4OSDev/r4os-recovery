const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;

pub fn main() void {
    @setEvalBranchQuota(20_000);
    emitNamespace("", abi, true);
}

fn emitNamespace(comptime prefix: []const u8, comptime namespace: type, comptime only_extern: bool) void {
    inline for (@typeInfo(namespace).@"struct".decls) |declaration| {
        const value = @field(namespace, declaration.name);
        const public_name = prefix ++ declaration.name;
        if (@TypeOf(value) == type) {
            const Payload = value;
            switch (@typeInfo(Payload)) {
                .@"struct" => |info| if (!only_extern or info.layout == .@"extern") emitStruct(public_name, Payload),
                .@"enum" => emitEnum(public_name, Payload),
                .pointer => |pointer| switch (@typeInfo(pointer.child)) {
                    .@"fn" => emitCallback(public_name, Payload),
                    else => {},
                },
                else => {},
            }
        } else switch (@typeInfo(@TypeOf(value))) {
            .int, .comptime_int => std.debug.print("CONST|{s}|{s}|{d}\n", .{ public_name, @typeName(@TypeOf(value)), value }),
            else => {},
        }
    }
}

fn emitStruct(comptime name: []const u8, comptime Payload: type) void {
    const info = @typeInfo(Payload).@"struct";
    std.debug.print("TYPE|{s}|struct|{d}|{d}|{s}\n", .{
        name,
        @sizeOf(Payload),
        @alignOf(Payload),
        @tagName(info.layout),
    });
    inline for (info.fields) |field| {
        std.debug.print("FIELD|{s}|{s}|{d}|{d}|{d}|{s}\n", .{
            name,
            field.name,
            @offsetOf(Payload, field.name),
            @sizeOf(field.type),
            @alignOf(field.type),
            @typeName(field.type),
        });
        if (field.defaultValue()) |default_value| {
            emitDefault(name, field.name, field.type, default_value);
        } else {
            std.debug.print("DEFAULT|{s}|{s}|none|\n", .{ name, field.name });
        }
    }
}

fn emitDefault(comptime type_name: []const u8, comptime field_name: []const u8, comptime FieldType: type, value: FieldType) void {
    switch (@typeInfo(FieldType)) {
        .int, .comptime_int => std.debug.print("DEFAULT|{s}|{s}|integer|{d}\n", .{ type_name, field_name, value }),
        .bool => std.debug.print("DEFAULT|{s}|{s}|boolean|{any}\n", .{ type_name, field_name, value }),
        .@"enum" => std.debug.print("DEFAULT|{s}|{s}|integer|{d}\n", .{ type_name, field_name, @intFromEnum(value) }),
        .@"struct" => std.debug.print("DEFAULT|{s}|{s}|empty|\n", .{ type_name, field_name }),
        .optional => {
            if (value == null) std.debug.print("DEFAULT|{s}|{s}|null_pointer|\n", .{ type_name, field_name }) else std.debug.print("DEFAULT|{s}|{s}|unsupported|\n", .{ type_name, field_name });
        },
        .array => |array| switch (@typeInfo(array.child)) {
            .@"struct" => std.debug.print("DEFAULT|{s}|{s}|empty_array|\n", .{ type_name, field_name }),
            else => {
                const bytes = std.mem.asBytes(&value);
                for (bytes) |byte| {
                    if (byte != 0) {
                        std.debug.print("DEFAULT|{s}|{s}|unsupported|\n", .{ type_name, field_name });
                        return;
                    }
                }
                std.debug.print("DEFAULT|{s}|{s}|zero_array|\n", .{ type_name, field_name });
            },
        },
        else => std.debug.print("DEFAULT|{s}|{s}|unsupported|\n", .{ type_name, field_name }),
    }
}

fn emitEnum(comptime name: []const u8, comptime Payload: type) void {
    const info = @typeInfo(Payload).@"enum";
    std.debug.print("TYPE|{s}|enum|{d}|{d}|{s}\n", .{ name, @sizeOf(Payload), @alignOf(Payload), @typeName(info.tag_type) });
    inline for (info.fields) |field| {
        std.debug.print("VALUE|{s}|{s}|{d}\n", .{ name, field.name, field.value });
    }
}

fn emitCallback(comptime name: []const u8, comptime Callback: type) void {
    std.debug.print("TYPE|{s}|callback|{d}|{d}|pointer\n", .{ name, @sizeOf(Callback), @alignOf(Callback) });
}
