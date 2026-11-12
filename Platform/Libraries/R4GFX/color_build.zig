//! Same freestanding ICC core and adapter in product and existing owner tests.
const std = @import("std");
const sources: []const []const u8 = &.{
    "Source/color_icc.c",
    "ThirdParty/LittleCMS/src/cmsalpha.c",
    "ThirdParty/LittleCMS/src/cmscam02.c",
    "ThirdParty/LittleCMS/src/cmscnvrt.c",
    "ThirdParty/LittleCMS/src/cmserr.c",
    "ThirdParty/LittleCMS/src/cmsgamma.c",
    "ThirdParty/LittleCMS/src/cmsgmt.c",
    "ThirdParty/LittleCMS/src/cmshalf.c",
    "ThirdParty/LittleCMS/src/cmsintrp.c",
    "ThirdParty/LittleCMS/src/cmsio0.c",
    "ThirdParty/LittleCMS/src/cmsio1.c",
    "ThirdParty/LittleCMS/src/cmslut.c",
    "ThirdParty/LittleCMS/src/cmsmd5.c",
    "ThirdParty/LittleCMS/src/cmsmtrx.c",
    "ThirdParty/LittleCMS/src/cmsnamed.c",
    "ThirdParty/LittleCMS/src/cmsopt.c",
    "ThirdParty/LittleCMS/src/cmspack.c",
    "ThirdParty/LittleCMS/src/cmspcs.c",
    "ThirdParty/LittleCMS/src/cmsplugin.c",
    "ThirdParty/LittleCMS/src/cmssamp.c",
    "ThirdParty/LittleCMS/src/cmssm.c",
    "ThirdParty/LittleCMS/src/cmstypes.c",
    "ThirdParty/LittleCMS/src/cmsvirt.c",
    "ThirdParty/LittleCMS/src/cmswtpnt.c",
    "ThirdParty/LittleCMS/src/cmsxform.c",
};
pub fn add(b: *std.Build, module: *std.Build.Module) void {
    addAt(b, module, b.path("."));
}
pub fn addAt(b: *std.Build, module: *std.Build.Module, root: std.Build.LazyPath) void {
    module.addIncludePath(root.path(b, "Source/ColorPort"));
    module.addIncludePath(root.path(b, "ThirdParty/LittleCMS/include"));
    module.addCSourceFiles(.{ .root = root, .files = sources, .flags = &.{
        "-std=c11", "-fno-builtin", "-fno-pic", "-mcmodel=large", "-DCMS_R4OS=1", "-DCMS_NO_PTHREADS=1", "-DCMS_NO_REGISTER_KEYWORD=1",
    } });
}
