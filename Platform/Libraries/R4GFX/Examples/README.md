# Resources and output lifetime

`Images.zig` creates a system XRGB render target or imports a live canonical BO
reference. `Output.zig` is a small cooperative, CPU-rendered output loop for a
compositor that already owns an output. Ordinary applications use SDK Canvas,
EGL or Vulkan window surfaces; their window ID is not a physical head ID.
Both helper sources compile against the current public DEVICE_V1 revision 10.
Import `R4GFX:DEVICE_V1:10`, the normal R4SYS/R4DRAW/R4DEV platform tables and
bind `r4gfx` to `Bindings/Zig/r4gfx_abi.zig`. COLOR_V1 consumers currently declare
`R4GFX:COLOR_V1:4`. The manifest minimum must match the generated binding,
even when a newer provider is installed. Use normal SDK manifest builds.

The caller creates one stable, zeroed allocation with `storage_size()` bytes
and `device_storage_alignment` alignment. Check size/allocation results before
`device_open`; pass the original live R4X start context, the storage address
and length in a version-1 R4GfxDeviceConfig. Keep that context, allocation and
library generation alive until `device_close` returns status_ok. Resource/job
handles alone do not own the allocation containing the device.

Example lifecycle:

1. Call Images.createTarget twice with the current output size. On partial
   failure release the first successful resource. Importing with importImage
   retains an independent BO reference; after success the caller can release
   its original reference. On failure its original reference stays owned.
2. Create one resource_pipeline with operation render_operation_fill, using a
   zeroed version-1 R4GfxResourceDesc. Reuse it for every frame.
3. Read presentation_info for the selected head and its display_generation.
   Call Output.open with two distinct images matching the output. FIFO with
   flags=0 explicitly accepts an unsynchronized copy path. Requiring VSync on
   bootfb is unsupported; never relabel a CPU copy receipt as visible scanout.
4. On actual damage call Output.frame with the fill pipeline, complete output
   dimensions and a finite absolute monotonic deadline. The example fills an
   image synchronously and submits it; its zero render_job is valid only for
   this synchronous CPU work. Native asynchronous rendering supplies its real
   render job and preserves all referenced resources until retirement.
5. Call retire from the regular event loop while pending. Inspect last_receipt:
   result 1=presented, 2=copied, 3=discarded, 4=failed, 5=lost; 0 is pending.
   Only visible_ns proves the provider's visibility milestone. A successful
   release describes ownership cleanup, not successful presentation. Handle
   failed/lost receipts before requesting another application frame.
6. For resize stop producing, retire the old frame, create the replacement
   images and call swapchain_resize with the fresh generation/description.
   A rejected resize preserves the old chain; keep old images until accepted
   or closed. Release failed replacement resources separately. Alternatively
   close and reopen Output after the old consumer has retired.
7. Close Output, then release the fill/images, then close the device. Each
   release/close result matters. Busy retains all remaining owner storage for
   the next event/recovery step. A logical timeout never permits freeing DMA
   memory still held by a device or display consumer.

Unsupported/unavailable at initial admission allows an explicit software
choice. Busy uses backpressure; occluded waits for visibility; suboptimal/stale
requires fresh output discovery; lost requires teardown/recovery. Do not spin,
create an extra global wait or retry old generations indefinitely. Neither
helper allocates or compiles shaders per frame. They are source examples,
not additional installed applications or permanent test groups.
