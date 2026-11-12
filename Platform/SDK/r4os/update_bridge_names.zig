const s = @import("schema");
pub const prefix = "R4SdkUpdate";
pub const macro = "R4SDKUPDATE";
pub const extra_include = "r4os/data_helpers.h";
pub fn name(comptime T: type) []const u8 {
    return s.nativeName(T);
}
