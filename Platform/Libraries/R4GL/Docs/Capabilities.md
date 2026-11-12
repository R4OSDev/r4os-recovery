# R4GL capability record — 0.80.27

Applications query EGL configs, GL context versions and extensions from the
selected backend. Archive contents or GPU PCI identity alone enable no feature.
The AMD target is EGL 1.5 / OpenGL 4.6 Core / GLSL 4.60 over Vulkan 1.3.
Software/NVK retain their 3.3 ceiling. This is not CTS certification.

| Profile | Runtime declaration | Focused evidence | Remaining physical work |
| --- | --- | --- | --- |
| 0: Mesa Softpipe, no LLVM/JIT | EGL 1.5, GL 3.3 Core, 189 GL extensions in the recorded context | Real shader/sRGB/blending/image pixels, contexts/threads, four contexts at 1 GB; complete Desktop window/fullscreen/restore/close | No NVIDIA prerequisite; firmware scanout has no VSync promise |
| 1: Mesa Zink → native R4VK/NVK | EGL 1.5, GL 3.3 Core / GLSL 3.30, 215 GL extensions on the GA106 model; GL 4.6 context rejected | Vulkan admission, shader submission, window/pbuffer, resize, FIFO/MAILBOX transitions, fences and device-loss retirement | GPU pixel correctness, actual execution/scanout, timing, hotplug and reset recovery |
| 1: Mesa Zink → native R4VK/RADV | EGL 1.5, GL 4.6 Core / GLSL 4.60 on the Picasso model with admitted Vulkan 1.3 | 657 Core proc resolutions, 61 Mesa version extension predicates, actual GLSL460/compute/tessellation/FP64/SPIR-V submission, persistent maps/sync, bounded queries and complete window/pbuffer retirement | Physical AMD drawing, scanout/VSync and reset qualification in 0.80.39 |

R4GL 0.1.16 implements the GFX9 border-color swizzle fallback through identity
Vulkan views and per-binding NIR mapping; Vulkan does not advertise the absent
extension. Bindless textures are disabled for this path. Missing native line
stipple modes use the existing Zink geometry/fragment lowering. R4VK 0.1.21
retains pooled byte extents until every submission using their root completes.
The 32-binding limit remains finite. Focused AMD evidence is in
`Docs/Drivers/AMDEGL08026.txt` and `AMDOpenGL08027.txt` with their JSON evidence in the workspace's Docs repository.

The lists record runtime declarations, not 189/215 individually passed extension
tests. Mesa derives them from backend capabilities; Zink additionally checks the
native Vulkan features/limits and required entrypoints. The native model executes
no GPU instructions. Its extension list must never be presented as physical GPU
qualification. A different real adapter may expose a different list.

The final capture advertises no POSIX-fd/Win32 external-memory or semaphore
interop, OpenCL-event sync, or native-fence-fd extensions. The exposed EGL image,
colorspace, context and fence paths have the focused owner/software evidence
listed in README. Surface availability and swap intervals additionally require
the exact window/output lifetime. A native profile failure does not silently
select software; the application chooses profile 0 in a new runtime/process.

R4GL 0.1.29 also admits Zink windows consumed by the CPU compositor on a
registered physical output. The producer supplies its actual Vulkan GPU fence;
the consumer retains its CPU receipt and exact output incarnation. Headless
publications require an empty output identity. Swap interval admission uses
the real presentation capabilities; the 19-case production admission check
passes. On the physical GA106, the original EGL/native GUI cycle passes window,
border resize, 1080p fullscreen, return and actual Desktop Run-dialog occlusion
with unchanged frame bounds and pixel oracles. The full client restores byte
exactly. Regular EGL/app retirement and the exact warm BO balance pass, with
48 additional native submit/visible/release receipts and no lost frames.
GPU-Desktop readiness and further display integration remain open in 0.82.37;
this finite case establishes no panel, throughput or 60 FPS qualification.
Evidence: `ExFiles/Reports/OssiGPU/20261005-tv08237/N258GuiVerified` and
`ExFiles/Reports/OssiGPU/20261005-tv08237/Checkpoint.txt` (workspace).

Full lists, artifact hashes, captures and check inputs:
`ExFiles/Reference/GFX/0.79.39/Evidence/EGLDesktop` (workspace).
NVIDIA physical follow-up: `ExFiles/Reports/OssiGPU.txt`, section 0.79.39.
AMD physical follow-up: roadmap 0.80.39.

The 4.6 ceiling requires the real AMD/RADV features, limits and format bits
from the pinned Zink baseline, followed by Mesa's complete version computation.
A missing requirement retains 330 and cannot qualify the 4.6 target. Three
Core bounded-query aliases use existing ARB dispatch slots. Optional vendor
extensions, raytracing and OpenCL/HIP/ROCm are outside this target.
