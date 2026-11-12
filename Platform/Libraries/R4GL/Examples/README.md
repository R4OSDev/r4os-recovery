# OpenGL triangle

`Triangle.zig` is a regular hosted GUI application using R4GL's public EGL
loader. It draws a GLSL 330 Core triangle, uses the complete client size, and
requests borderless fullscreen through `r4os.window_mode`. Press **F** to
switch modes; **Escape** restores the decorated window or closes it.

Use the file as `SOURCE` of an SDK R4X manifest with `ENTRY_MODE=app` and
`APP_CLASS=gui` and `SDK_PROFILE=r4os-zig-generation2`. Import
`R4SYS:Query2:2`, `R4DESK:Query2:2`, `R4DRAW:Query2:2`, `R4DEV:Query2:2`,
`R4GL:Query2:2`, `R4GL:EGL_V1:1`, `R4VK:Query2:2`, and `R4VK:VULKAN_V1:1`; bind `r4gl` to
`R4GL/Bindings/Zig/r4gl.zig`. Launch the resulting R4X from Desktop.
It is an example source, not a separately installed application or test gate.

Software rendering is the default. `/ZINK` explicitly selects the native
Vulkan backend and fails if its requirements are unavailable. Both use swap
interval zero; fullscreen does not change monitor timing or promise VSync.
The example selects a 0..0 EGL config explicitly. Another output's VSync
capability does not make this window's CPU consumer a synchronized target.

An optional observer passed to `run` receives renderer/version/extensions and
logical client geometry and EGL framebuffer dimensions. Framebuffer dimensions
may differ on scaled outputs; viewport sizes always come from EGL. With an observer, the example also checks the center pixel
before swapping. The regular entry point omits these diagnostic readbacks.
