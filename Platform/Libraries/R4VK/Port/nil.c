/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_nil.h"

/* Only called on a disposable native worker. Rust does not unwind across C. */
extern bool r4vk_nil_image_init_unchecked(const struct nv_device_info *,
                                         struct nil_image *,
                                         const struct nil_image_init_info *);
extern bool r4vk_nil_image_init_planar_unchecked(const struct nv_device_info *,
                                                struct nil_image *,
                                                const struct nil_image_init_info *,
                                                size_t, size_t);
extern int32_t r4vk_nil_run(int32_t (*callback)(void *), void *argument);

struct image_call {
   const struct nv_device_info *dev;
   const struct nil_image_init_info *info;
   struct nil_image image;
   size_t plane, plane_count;
   bool planar;
};
static int32_t calculate(void *argument)
{
   struct image_call *call = argument;
   bool ok = call->planar ?
      r4vk_nil_image_init_planar_unchecked(call->dev, &call->image, call->info,
                                           call->plane, call->plane_count) :
      r4vk_nil_image_init_unchecked(call->dev, &call->image, call->info);
   return ok ? VK_SUCCESS : VK_ERROR_FORMAT_NOT_SUPPORTED;
}
static VkResult run(struct image_call *call, struct nil_image *out)
{
   if (!call->dev || !call->info || !out || !call->plane_count ||
       call->plane >= call->plane_count)
      return VK_ERROR_FORMAT_NOT_SUPPORTED;
   VkResult result = r4vk_nil_run(calculate, call);
   /* A Rust assertion rejects the layout. Worker/arena allocation failures
    * retain OUT_OF_HOST_MEMORY; failure to start retains INITIALIZATION_FAILED. */
   if (result == VK_ERROR_UNKNOWN)
      return VK_ERROR_FORMAT_NOT_SUPPORTED;
   if (result == VK_SUCCESS)
      *out = call->image;
   return result;
}
VkResult r4vk_nil_image_init(const struct nv_device_info *dev,
                           struct nil_image *out,
                           const struct nil_image_init_info *info)
{
   struct image_call call = {.dev = dev, .info = info, .plane_count = 1};
   return run(&call, out);
}
VkResult r4vk_nil_image_init_planar(const struct nv_device_info *dev,
                                  struct nil_image *out,
                                  const struct nil_image_init_info *info,
                                  size_t plane, size_t plane_count)
{
   struct image_call call = {.dev = dev, .info = info, .plane = plane,
                             .plane_count = plane_count, .planar = true};
   return run(&call, out);
}
