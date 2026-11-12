//! Only existing bounded owner cases are selected by web-parity-test.
const std = @import("std");
const sdk = @import("../../r4os.zig");
test {
    inline for (.{ sdk.html, sdk.css, sdk.web_layout, sdk.web_font, sdk.web_fonts, sdk.web_font_cache, sdk.web_font_activation, sdk.web_images, sdk.web_background, sdk.web_forms, sdk.web_navigation, sdk.javascript, sdk.web_runtime, sdk.web_canvas }) |M| std.testing.refAllDecls(M);
}
