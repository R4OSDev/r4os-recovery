//! Original cases in the same SDK test package; never just a dependency module.
const std = @import("std");
const sdk = @import("../../r4os.zig");
test {
    inline for (.{ sdk.server_profile, sdk.server_credentials, sdk.app_web, sdk.http, sdk.web_security, sdk.web_response_cache, sdk.app_web_jobs, sdk.web_runtime_jobs, sdk.web_resources, sdk.web_documents, sdk.web_fetch }) |M| std.testing.refAllDecls(M);
}

// HTTP81 uses the four directly affected HTTP/app_web owner cases through
// the existing transport-parity filter; no separate gate or broad rerun.
