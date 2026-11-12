pub const prefix = "R4SdkData";
pub const macro = "R4SDKDATA";

pub fn name(comptime T: type) []const u8 {
    return @import("schema").nativeName(T);
}
