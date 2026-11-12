R4VK Runtime-R4L API
====================

Native Vulkan ICD bootstrap. Vulkan objects and commands retain their standard C ABI; NVIDIA.R4D owns hardware.

VULKAN_V1
---------

Native library-to-ICD bootstrap ABI1.

- ELF-Symbol: `r4vk_vulkan_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x31494241534f3452:0x4e414b4c55563452`
- Tabellengroesse: 40 Byte

- Slot 0, Offset 32: `open` - Bind the explicitly selected original tables or actual Start2 caller and obtain standard ICD entrypoints. Version2 retains only process-owned copied start metadata, immutable boot tables and process-lifetime import/name views. Idempotent for matching binding; no Vulkan instance/device or GPU support is created.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `VkResult`; Besitz: No device, instance or caller buffer is retained. The imported R4VK generation must remain loaded while using its entrypoints or objects..

Typen
-----

- `R4VkRuntime`: 32 Byte, Alignment 8. Native versioned platform binding. Version1 retains the original three immutable kernel table addresses. Version2 carries an actual Start2 address in sys and zero draw/dev; the library admits its real imports and copies a process-owned start/C-view snapshot. The32-byte record and VULKAN_V1 layout/IDs/revisions/slots are unchanged.
- `R4VkLoader`: 32 Byte, Alignment 8. Borrowed entrypoint addresses from this R4VK generation. Negotiate before creating instances; query Vulkan functions and capabilities through the standard API.

Besitzregeln
------------

- objects: Vulkan objects, allocation callbacks and mutable runtime/compiler state belong to the creating process. Applications obey Vulkan synchronization and lifetime rules; destroy objects before discarding their library binding.
- hardware: R4VK uses native resource/queue/VA/fence contracts. NVIDIA.R4D is the sole GPU owner. No Linux ioctl, FD, device file or host Vulkan loader is exposed as the native ABI.
- fallback: A valid instance can enumerate zero eligible GPUs. Missing R4VK or no compatible device leaves the ordinary software-rendering fallback available. Opening the ICD does not establish device support or Vulkan conformance.
