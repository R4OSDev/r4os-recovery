# Vulkan enumeration

`Enumerate.zig` is a small complete console entry point using the public
R4VK ICD bootstrap and ordinary Vulkan 1.3 instance/device enumeration.
Zero devices is a normal result without an admitted NVIDIA backend; choose
R4DRAW or explicit software OpenGL in an application that has such a renderer.
R4VK does not create a software Vulkan device. Initialization/enumeration errors
are reported and return failure; they are not silently converted into success.

Use an SDK R4X manifest with ENTRY_MODE=app, APP_CLASS=console,
SDK_PROFILE=r4os-zig-generation2 and imports R4SYS:Query2:2,
R4DRAW:Query2:2, R4DEV:Query2:2, R4VK:Query2:2, R4VK:VULKAN_V1:1.
Bind `r4vk` to Bindings/Zig/r4vk.zig and `vulkan` to a Zig translation of
`vulkan/vulkan_core.h` from the pinned Mesa build inputs. The SDK build
supports a generated module root via addR4MFWithOptions/zig_module_roots;
use addTranslateC on a file containing that include and the pinned include
path. No Mesa/NVK objects are linked into this consumer. Keep the R4L import
and generation2 startup imports alive for the lifetime of all Vulkan objects.
Runtime version2 carries the actual Start2 address in sys with draw/dev zero;
VULKAN_V1 keeps its independent interface revision1.

For rendering, query each device's features, formats, queue families and
limits before enabling them. The supported window bootstrap and standard
KHR surface/swapchain calls are described in ../README.md and Docs/API.md;
use the actual current window extent, handle OUT_OF_DATE/SUBOPTIMAL and
retain submitted images until real consumer retirement. Create shader and
pipeline objects outside the frame loop. Physical GPU performance and official
Khronos conformance are separate from software API availability.

The App2 source was compiled with the actual pinned Vulkan header and public
generation2 binding in 0.90.46. A separate real consumer created/destroyed an
instance and enumerated zero devices on KVM software graphics. This is no new
physical-device qualification; earlier hardware evidence remains scoped to
its original artifacts and reports.
