/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "nvk_instance.h"

void r4vk_nvk_init_instance_options(struct nvk_instance *instance)
{
   /* Native baseline follows the pinned generated NVK defaults. Linux DRIRC,
    * identity overrides, experimental DLSS and RMV/file tracing are not part
    * of this platform policy. Every instance owns its own option structure. */
   instance->debug_flags = 0;
   instance->experimental_flags = 0;
   instance->drirc = (struct nvk_drirc) {
      .debug = { .app_layer = "", .force_vk_devicename = "" },
      .misc = { .heap_memory_percent = 0.75f },
   };
}
