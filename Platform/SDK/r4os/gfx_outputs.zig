const abi = @import("r4os_contract").abi;
const program = @import("program.zig");
pub const Context = struct {
    pub fn power(self: *const Context, identity: *const abi.GfxOutputId, output: *abi.GfxOutputPower) i32 { return self.base.gfxOutputPower(identity, output); }
    pub fn requestPower(self: *const Context, input: *const abi.GfxPowerRequest, output: *abi.GfxPowerRequest) i32 { return self.base.gfxPowerRequest(input, output); }
    pub fn brightness(self: *const Context, identity: *const abi.GfxOutputId, output: *abi.GfxOutputBrightness) i32 { return self.base.gfxOutputBrightness(identity, output); }
    pub fn requestBrightness(self: *const Context, input: *const abi.GfxBrightnessRequest, output: *abi.GfxBrightnessRequest) i32 { return self.base.gfxBrightnessRequest(input, output); }
    base: program.Context,
    pub fn revision(self: *const Context, output: *abi.GfxDisplayRevision) i32 { return self.base.gfxOutputRevision(output); }
    pub fn info(self: *const Context, index: u32, output: *abi.GfxOutputInfo) i32 { return self.base.gfxOutputInfo(index, output); }
    pub fn color(self: *const Context, identity: *const abi.GfxOutputId, output: *abi.GfxOutputColorState) i32 { return self.base.gfxOutputColor(identity, output); }
    pub fn refresh(self: *const Context, target: *const abi.GfxOutputTarget, output: *abi.GfxOutputRefresh) i32 { return self.base.gfxOutputRefresh(target, output); }
    pub fn requestRefresh(self: *const Context, input: *const abi.GfxRefreshRequest, output: *abi.GfxRefreshRequest) i32 { return self.base.gfxRefreshRequest(input, output); }
    pub fn mode(self: *const Context, identity: *const abi.GfxOutputId, index: u32, output: *abi.GfxOutputMode) i32 { return self.base.gfxOutputMode(identity, index, output); }
    pub fn edid(self: *const Context, identity: *const abi.GfxOutputId, index: u32, output: *abi.GfxEdidBlock) i32 { return self.base.gfxOutputEdid(identity, index, output); }
    pub fn testState(self: *const Context, state: *const abi.GfxAtomicState, output: *abi.GfxAtomicResult) i32 { return self.base.gfxAtomicTest(state, output); }
    pub fn testColor(self: *const Context, request: *const abi.GfxModeColorRequest, output: *abi.GfxAtomicResult) i32 { return self.base.gfxAtomicTestColor(request, output); }
    pub fn submitColor(self: *const Context, request: *const abi.GfxModeColorRequest, confirmation_ms: u32, output: *abi.GfxModeStatus) i32 { return self.base.gfxAtomicSubmitColor(request, confirmation_ms, output); }
    pub fn commit(self: *const Context, state: *const abi.GfxAtomicState, output: *abi.GfxAtomicResult) i32 { return self.base.gfxAtomicCommit(state, output); }
    pub fn submit(self: *const Context, state: *const abi.GfxAtomicState, confirmation_ms: u32, output: *abi.GfxModeStatus) i32 { return self.base.gfxAtomicSubmit(state, confirmation_ms, output); }
    pub fn status(self: *const Context, ticket: u64, output: *abi.GfxModeStatus) i32 { return self.base.gfxAtomicStatus(ticket, output); }
    pub fn resolve(self: *const Context, ticket: u64, action: u32, output: *abi.GfxModeStatus) i32 { return self.base.gfxAtomicResolve(ticket, action, output); }
};
