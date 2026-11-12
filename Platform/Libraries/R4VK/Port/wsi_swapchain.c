/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_wsi.h"
#include "r4vk_wsi_backend.h"
#include "r4vk_provider.h"
#include "util/log.h"
#include "vk_queue.h"
#include "vk_image.h"
#include "r4vk_state.h"
#include "nvk_entrypoints.h"
#include "vk_common_entrypoints.h"
#include "vk_fence.h"
#include "vk_semaphore.h"
#include "vk_alloc.h"
#include "util/cnd_monotonic.h"
#include <stdlib.h>

int r4vk_monotonic_time(uint64_t *);
int r4vk_operation_deadline(uint64_t, uint64_t *, uint64_t *);

struct native_chain;
struct native_window {
   mtx_t mutex;
   uint32_t references; /* state mutex; records and temporary callers */
   R4WindowGraphicsSurface identity;
   uint64_t application;
   struct native_chain *chains, *active, *pending_owner;
   R4WindowGraphicsRequest pending;
   uint64_t revision;
};
struct native_chain {
   struct native_chain *next;
   struct native_window *window;
   uint64_t chain;
   R4WindowGraphicsConfig config;
   uint32_t count, attached, acquired;
   uint64_t tokens[3];
   void *points[3];
   const struct r4vk_wsi_backend *ops;
   R4Draw draw;
   R4GfxBufferReference sources[3];
   VkResult error;
   bool live, retired, closing, close_acked, remote_closed;
};
/* Vulkan storage and user callbacks end synchronously at DestroySwapchain.
 * The independent record retains only native point pins and broker identity. */
struct r4vk_swapchain {
   struct vk_object_base base;
   struct vk_device *device;
   struct native_chain *record;
   uint32_t count;
   struct r4vk_wsi_image images[3];
   VkImageFormatListCreateInfo format_list;
   VkFormat view_formats[]; /* owned copy; application arrays may expire */
};
struct wsi_state {
   once_flag once;
   mtx_t mutex;
   struct u_cnd_monotonic condition;
   thrd_t worker;
   bool initialized, started;
   uint64_t serial, wake_revision;
   struct native_window windows[16];
};
static const unsigned char state_key;
static int retire_worker(void *argument);
static void initialize(void)
{
   struct wsi_state *s = r4vk_state_get(&state_key);
   if (mtx_init(&s->mutex, mtx_plain) != thrd_success ||
       u_cnd_monotonic_init(&s->condition) != thrd_success) return;
   for (uint32_t i = 0; i < ARRAY_SIZE(s->windows); i++)
      if (mtx_init(&s->windows[i].mutex, mtx_plain) != thrd_success) return;
   s->initialized = true;
}
static void lock(mtx_t *mutex) { if (mtx_lock(mutex) != thrd_success) __builtin_trap(); }
static void unlock(mtx_t *mutex) { if (mtx_unlock(mutex) != thrd_success) __builtin_trap(); }
static struct wsi_state *state(void)
{
   if (!r4vk_state_ensure(&state_key, sizeof(struct wsi_state), _Alignof(struct wsi_state))) return NULL;
   struct wsi_state *s = r4vk_state_get(&state_key);
   call_once(&s->once, initialize);
   if (!s->initialized) return NULL;
   lock(&s->mutex);
   if (!s->started && thrd_create(&s->worker, retire_worker, s) == thrd_success) s->started = true;
   bool ready = s->started;
   unlock(&s->mutex);
   return ready ? s : NULL;
}
static struct native_window *window_get(struct wsi_state *s, const struct r4vk_surface *surface)
{
   struct native_window *empty = NULL, *out = NULL;
   lock(&s->mutex);
   for (uint32_t i = 0; i < ARRAY_SIZE(s->windows); i++) {
      struct native_window *w = &s->windows[i];
      if (!w->references) { if (!empty) empty = w; continue; }
      if (!memcmp(&w->identity, &surface->identity, sizeof(w->identity))) { out = w; break; }
   }
   if (!out && empty) {
      out = empty;
      out->identity = surface->identity;
      out->application = surface->application;
      out->revision = 0;
      assert(!out->chains && !out->active && !out->pending_owner);
   }
   if (out) out->references++;
   unlock(&s->mutex);
   return out;
}
static void window_put(struct wsi_state *s, struct native_window *w)
{
   lock(&s->mutex);
   assert(w->references);
   w->references--;
   unlock(&s->mutex);
}
static void wake_worker(struct wsi_state *s)
{
   lock(&s->mutex);
   s->wake_revision++;
   if (u_cnd_monotonic_broadcast(&s->condition) != thrd_success) __builtin_trap();
   unlock(&s->mutex);
}
static void release_point(struct native_chain *chain, uint32_t slot)
{
   if (!chain->points[slot]) return;
   chain->ops->unpin(chain->points[slot]);
   chain->ops->unref(chain->points[slot]);
   chain->points[slot] = NULL;
}
static VkResult vk_result(int32_t status)
{
   switch (status) {
   case R4OS_WINDOW_GRAPHICS_OK: return VK_SUCCESS;
   case R4OS_WINDOW_GRAPHICS_NOT_READY: return VK_NOT_READY;
   case R4OS_WINDOW_GRAPHICS_OUT_OF_DATE: return VK_ERROR_OUT_OF_DATE_KHR;
   case R4OS_WINDOW_GRAPHICS_DEVICE_LOST: return VK_ERROR_DEVICE_LOST;
   case R4OS_WINDOW_GRAPHICS_CAPACITY: return VK_ERROR_OUT_OF_HOST_MEMORY;
   default: return VK_ERROR_SURFACE_LOST_KHR;
   }
}
static void fail(struct native_chain *chain, VkResult result)
{
   if (chain->error == VK_SUCCESS) chain->error = result;
   chain->closing = true;
}
static R4WindowGraphicsRequest request_for(struct native_chain *chain, uint32_t action)
{
   return (R4WindowGraphicsRequest) {
      .version = 1, .size = sizeof(R4WindowGraphicsRequest), .owner = chain->window->identity.owner,
      .window_id = chain->window->identity.window_id, .surface = chain->window->identity,
      .chain = chain->chain, .config_revision = chain->config.revision, .action = action,
   };
}
/* The one outstanding mutating request is shared by all VkSurfaces and
 * swapchains for this native window. An unknown outcome can never be
 * overtaken by another serial, including oldSwapchain and worker cleanup. */
static bool drain(struct native_window *w, R4WindowGraphicsReply *out)
{
   if (!w->pending_owner) return true;
   struct native_chain *chain = w->pending_owner;
   R4WindowGraphicsReply reply;
   if (!r4vk_window_request(w->application, &w->pending, &reply)) return false;
   if (reply.result == R4OS_WINDOW_GRAPHICS_OK) {
      if (memcmp(&reply.surface, &w->identity, sizeof(w->identity))) return false;
      switch (w->pending.action) {
      case R4OS_WINDOW_GRAPHICS_CREATE_CHAIN:
         if (!reply.chain) return false;
         chain->chain = reply.chain;
         break;
      case R4OS_WINDOW_GRAPHICS_ATTACH:
         if (reply.chain != chain->chain || reply.image_slot != w->pending.image_slot) return false;
         chain->attached |= 1u << w->pending.image_slot;
         break;
      case R4OS_WINDOW_GRAPHICS_ACQUIRE:
         if (reply.chain != chain->chain || reply.image_slot >= chain->count || !reply.acquire_token) return false;
         chain->tokens[reply.image_slot] = reply.acquire_token;
         chain->acquired |= 1u << reply.image_slot;
         release_point(chain, reply.image_slot);
         break;
      case R4OS_WINDOW_GRAPHICS_PRESENT:
      case R4OS_WINDOW_GRAPHICS_CANCEL_ACQUIRE:
         if (reply.chain != chain->chain || reply.image_slot != w->pending.image_slot ||
             reply.acquire_token != w->pending.acquire_token) return false;
         chain->acquired &= ~(1u << w->pending.image_slot);
         break;
      case R4OS_WINDOW_GRAPHICS_CLOSE_CHAIN:
         if (reply.chain != chain->chain) return false;
         chain->close_acked = true;
         break;
      }
   } else if (w->pending.action == R4OS_WINDOW_GRAPHICS_CLOSE_CHAIN &&
              reply.result == R4OS_WINDOW_GRAPHICS_CLOSED) {
      chain->close_acked = chain->remote_closed = true;
   }
   w->revision = reply.revision;
   w->pending_owner = NULL;
   if (out) *out = reply;
   return true;
}
static bool request(struct wsi_state *s, struct native_chain *chain,
                    R4WindowGraphicsRequest command, R4WindowGraphicsReply *out)
{
   struct native_window *w = chain->window;
   if (!drain(w, NULL)) return false;
   lock(&s->mutex);
   if (s->serial == UINT64_MAX) { unlock(&s->mutex); return false; }
   command.request_serial = ++s->serial;
   unlock(&s->mutex);
   w->pending = command;
   w->pending_owner = chain;
   return drain(w, out);
}
static bool retire_step(struct wsi_state *s, struct native_window *w)
{
   bool outstanding = false;
   lock(&w->mutex);
   bool dead = r4vk_window_service_dead(w->application, &w->identity.service);
   if (dead) w->pending_owner = NULL;
   else if (!drain(w, NULL)) { unlock(&w->mutex); return true; }
   struct native_chain **link = &w->chains;
   while (*link) {
      struct native_chain *chain = *link;
      if (dead) { chain->remote_closed = true; fail(chain, VK_ERROR_SURFACE_LOST_KHR); }
      if (!chain->closing) { link = &chain->next; continue; }
      if (!chain->chain) chain->remote_closed = true;
      if (!chain->remote_closed && !chain->close_acked) {
         R4WindowGraphicsReply reply;
         if (!request(s, chain, request_for(chain, R4OS_WINDOW_GRAPHICS_CLOSE_CHAIN), &reply)) {
            outstanding = true; break;
         }
         if (reply.result == R4OS_WINDOW_GRAPHICS_STALE && !reply.surface.serial)
            chain->remote_closed = true;
      }
      for (uint32_t slot = 0; slot < chain->count; slot++) {
         if (chain->sources[slot].reference.id && w->pending_owner != chain) {
            if (r4draw_gfx_buffer_release(&chain->draw, &chain->sources[slot].reference) != 1) {
               outstanding = true;
               continue;
            }
            chain->sources[slot] = (R4GfxBufferReference){0};
         }
      }
      for (uint32_t slot = 0; slot < chain->count; slot++) {
         if (!chain->points[slot]) continue;
         if (chain->remote_closed) { release_point(chain, slot); continue; }
         R4WindowGraphicsRequest query = request_for(chain, R4OS_WINDOW_GRAPHICS_CHAIN_STATUS);
         query.image_slot = slot;
         R4WindowGraphicsReply reply;
         if (!r4vk_window_request(w->application, &query, &reply)) { outstanding = true; continue; }
         /* A closed chain can still contain a leased image. Only an absent
          * chain/surface or a non-leased slot ends its producer-fence loan. */
         if ((reply.result == R4OS_WINDOW_GRAPHICS_STALE && !reply.surface.serial) ||
             (chain->close_acked && reply.result == R4OS_WINDOW_GRAPHICS_CLOSED &&
              reply.flags != R4OS_WINDOW_GRAPHICS_IMAGE_LEASED)) release_point(chain, slot);
         else outstanding = true;
      }
      bool points = false;
      for (uint32_t slot = 0; slot < chain->count; slot++)
         points |= chain->points[slot] != NULL || chain->sources[slot].reference.id != 0;
      if (!chain->live && !points && (chain->remote_closed || chain->close_acked) && w->pending_owner != chain) {
         *link = chain->next;
         if (w->active == chain) w->active = NULL;
         free(chain);
         window_put(s, w);
      } else {
         if (!chain->close_acked && !chain->remote_closed) outstanding = true;
         link = &chain->next;
      }
   }
   unlock(&w->mutex);
   return outstanding;
}
static int retire_worker(void *argument)
{
   struct wsi_state *s = argument;
   for (;;) {
      lock(&s->mutex);
      uint64_t observed = s->wake_revision;
      unlock(&s->mutex);
      bool outstanding = false;
      for (uint32_t i = 0; i < ARRAY_SIZE(s->windows); i++) {
         struct native_window *w = &s->windows[i];
         lock(&s->mutex);
         bool used = w->references != 0;
         if (used) w->references++;
         unlock(&s->mutex);
         if (!used) continue;
         outstanding |= retire_step(s, w);
         window_put(s, w);
      }
      lock(&s->mutex);
      if (observed != s->wake_revision) {
         unlock(&s->mutex);
         continue;
      } else if (outstanding) {
         uint64_t now;
         if (r4vk_monotonic_time(&now) != 0) __builtin_trap();
         const uint64_t until = now + 25000000ull;
         const struct timespec deadline = {until / 1000000000ull, until % 1000000000ull};
         int rc = u_cnd_monotonic_timedwait(&s->condition, &s->mutex, &deadline);
         if (rc != thrd_success && rc != thrd_timedout) __builtin_trap();
      } else if (u_cnd_monotonic_wait(&s->condition, &s->mutex) != thrd_success) __builtin_trap();
      unlock(&s->mutex);
   }
}

static struct r4vk_swapchain *swapchain(VkSwapchainKHR handle)
{
   return (struct r4vk_swapchain *)(uintptr_t)handle;
}

VkResult r4vk_create_swapchain_alias(VkDevice device, const VkImageCreateInfo *info,
   const VkAllocationCallbacks *allocator, VkImage *out)
{
   const VkImageSwapchainCreateInfoKHR *alias = vk_find_struct_const(info->pNext, IMAGE_SWAPCHAIN_CREATE_INFO_KHR);
   struct r4vk_swapchain *sc = alias ? swapchain(alias->swapchain) : NULL;
   if (!sc || sc->device != vk_device_from_handle(device)) return VK_ERROR_INITIALIZATION_FAILED;
   const struct vk_image *original = sc->record->ops->image(sc->images[0].image);
   if (info->imageType != VK_IMAGE_TYPE_2D || info->format != original->format ||
       info->extent.width != original->extent.width || info->extent.height != original->extent.height ||
       info->extent.depth != 1 || info->mipLevels != 1 || info->arrayLayers != 1 ||
       info->samples != VK_SAMPLE_COUNT_1_BIT || info->tiling != VK_IMAGE_TILING_OPTIMAL ||
       info->usage != original->usage || info->initialLayout != VK_IMAGE_LAYOUT_UNDEFINED ||
       info->sharingMode != VK_SHARING_MODE_EXCLUSIVE || (info->flags & ~VK_IMAGE_CREATE_ALIAS_BIT) != original->create_flags)
      return VK_ERROR_INITIALIZATION_FAILED;
   const VkImageFormatListCreateInfo *formats =
      vk_find_struct_const(info->pNext, IMAGE_FORMAT_LIST_CREATE_INFO);
   if (!r4vk_wsi_equal_formats(formats, &sc->format_list))
      return VK_ERROR_INITIALIZATION_FAILED;
   const R4GfxBufferDescriptor *desc = &sc->images[0].descriptor;
   const VkSubresourceLayout plane = {.rowPitch = desc->plane_pitches[0]};
   const VkImageDrmFormatModifierExplicitCreateInfoEXT modifier = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_EXPLICIT_CREATE_INFO_EXT,
      .pNext = sc->format_list.viewFormatCount ? &sc->format_list : NULL,
      .drmFormatModifier = desc->modifier, .drmFormatModifierPlaneCount = 1, .pPlaneLayouts = &plane,
   };
   VkImageCreateInfo native = *info;
   native.pNext = &modifier;
   native.tiling = VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT;
   /* The alias owns an ordinary VkImage. Binding selects an existing BO;
    * neither allocation nor publication creates another native image. */
   return sc->record->ops->create_image(device, &native, allocator, out);
}

VkDeviceMemory r4vk_swapchain_memory(VkDevice device, VkSwapchainKHR handle, uint32_t index)
{
   struct r4vk_swapchain *sc = swapchain(handle);
   return sc && sc->device == vk_device_from_handle(device) && index < sc->count ?
      sc->images[index].memory : VK_NULL_HANDLE;
}
static VkResult allocation_result(int32_t rc)
{
   switch (rc) {
   case R4OS_GFX_BUFFER_ERROR_OOM:
   case R4OS_GFX_BUFFER_ERROR_BUDGET:
   case R4OS_GFX_BUFFER_ERROR_CAPACITY: return VK_ERROR_OUT_OF_DEVICE_MEMORY;
   default: return VK_ERROR_DEVICE_LOST;
   }
}
static VkResult source_image(struct native_chain *chain, uint32_t format,
                             R4GfxBufferReference *out)
{
   if (chain->config.backend.binding.adapter_id == 0) {
      /* Render directly into the canonical portable BO consumed by Desktop.
       * There is no CPU-emulated producer or full-frame staging copy here.
       * Both providers import modifier-zero images through their usual VA
       * and real native queue owners. Native fence pins outlive the chain. */
      uint64_t pixel_bytes = 4;
      switch (format) {
      case R4OS_GFX_BUFFER_FORMAT_XRGB8888:
      case R4OS_GFX_BUFFER_FORMAT_ARGB8888: break;
      case R4OS_GFX_BUFFER_FORMAT_XRGB2101010:
      case R4OS_GFX_BUFFER_FORMAT_ARGB2101010:
         if (!(chain->config.flags & R4OS_WINDOW_GRAPHICS_HEADLESS))
            return VK_ERROR_FORMAT_NOT_SUPPORTED;
         break;
      case R4OS_GFX_BUFFER_FORMAT_ABGR16161616F:
         if (!(chain->config.flags & R4OS_WINDOW_GRAPHICS_HEADLESS))
            return VK_ERROR_FORMAT_NOT_SUPPORTED;
         pixel_bytes = 8;
         break;
      default: return VK_ERROR_FORMAT_NOT_SUPPORTED;
      }
      const uint64_t pitch = ((uint64_t)chain->config.width * pixel_bytes + 255) & ~255ull;
      if (!pitch || !chain->config.height || chain->config.height > (UINT64_MAX - 65535) / pitch)
         return VK_ERROR_OUT_OF_DEVICE_MEMORY;
      const R4GfxBufferDescriptor descriptor = {
         .version = 1, .size = sizeof(descriptor),
         .byte_length = (pitch * chain->config.height + 65535) & ~65535ull,
         .alignment = 4096, .location = R4OS_GFX_BUFFER_LOCATION_SYSTEM,
         .width = chain->config.width, .height = chain->config.height,
         .format = format, .plane_count = 1, .plane_pitches = {pitch},
         .usage = R4OS_GFX_BUFFER_USAGE_CPU_READ | R4OS_GFX_BUFFER_USAGE_CPU_WRITE |
            R4OS_GFX_BUFFER_USAGE_RENDER | R4OS_GFX_BUFFER_USAGE_TRANSFER_SOURCE |
            R4OS_GFX_BUFFER_USAGE_TRANSFER_TARGET,
      };
      const int32_t rc = r4draw_gfx_buffer_create(&chain->draw, &descriptor, out);
      return rc == 1 ? VK_SUCCESS : allocation_result(rc);
   }
   R4GfxNativeAllocation allocation = {
      .version = 1, .size = sizeof(allocation),
      .adapter_id = chain->config.backend.binding.adapter_id,
      .memory_generation = chain->config.backend.memory_generation,
      .kind = 1, .width = chain->config.width, .height = chain->config.height,
      .format = format, .usage = R4OS_GFX_BUFFER_USAGE_RENDER |
         R4OS_GFX_BUFFER_USAGE_TRANSFER_SOURCE | R4OS_GFX_BUFFER_USAGE_TRANSFER_TARGET,
      .layout = 0,
   };
   uint64_t ticks;
   if (r4vk_operation_deadline(5000000000ull, &allocation.deadline_ns, &ticks)) return VK_ERROR_DEVICE_LOST;
   R4GfxNativeStatus initial, ready;
   int32_t rc = r4draw_gfx_native_start(&chain->draw, &allocation, &initial);
   if (rc != 1) return allocation_result(rc);
   if (!initial.request.id || !initial.request.generation || initial.request.reserved0) return VK_ERROR_DEVICE_LOST;
   VkResult result = VK_ERROR_DEVICE_LOST;
   rc = r4draw_gfx_native_wait(&chain->draw, &initial.request, ticks, &ready);
   if (rc != 1) { result = allocation_result(rc); goto close; }
   if (ready.version != 1 || ready.size < sizeof(ready) || ready.reserved0 ||
       memcmp(&ready.request, &initial.request, sizeof(ready.request)) ||
       ready.phase != 2 || (ready.flags & ~1u) ||
       ready.deadline_ns != allocation.deadline_ns || !ready.completed_ns) goto close;
   if (ready.result != 1) { result = allocation_result(ready.result); goto close; }
   rc = r4draw_gfx_native_receive(&chain->draw, &initial.request, out);
   if (rc == 1) return VK_SUCCESS;
   result = allocation_result(rc);
close:
   if (r4draw_gfx_native_close(&chain->draw, &initial.request) != 1) result = VK_ERROR_DEVICE_LOST;
   return result;
}

VKAPI_ATTR VkResult VKAPI_CALL
nvk_CreateSwapchainKHR(VkDevice device, const VkSwapchainCreateInfoKHR *info,
                      const VkAllocationCallbacks *allocator, VkSwapchainKHR *out)
{
   *out = VK_NULL_HANDLE;
   VK_FROM_HANDLE(vk_device, dev, device);
   const struct r4vk_wsi_backend *ops = r4vk_wsi_backend(dev->physical);
   if (!ops) return VK_ERROR_FEATURE_NOT_PRESENT;
   struct r4vk_surface *surface = (struct r4vk_surface *)(uintptr_t)info->surface;
   struct wsi_state *s = state();
   if (!s) return VK_ERROR_OUT_OF_HOST_MEMORY;
   struct native_window *w = window_get(s, surface);
   if (!w) return VK_ERROR_OUT_OF_HOST_MEMORY;
   lock(&w->mutex);
   VkResult result = VK_SUCCESS;
   struct r4vk_swapchain *old = swapchain(info->oldSwapchain);
   if (old) {
      if (old->device != dev || old->record->window != w || old->record->retired) {
         result = VK_ERROR_NATIVE_WINDOW_IN_USE_KHR; goto fail_window;
      }
      /* The old chain retires even when allocating its replacement fails.
       * Already acquired images can still be presented through the old chain. */
      old->record->retired = true;
      if (w->active == old->record) w->active = NULL;
   } else if (w->active) {
      result = VK_ERROR_NATIVE_WINDOW_IN_USE_KHR; goto fail_window;
   }
   result = ops->check(dev);
   if (result != VK_SUCCESS) goto fail_window;
   struct r4vk_surface_caps caps;
   result = r4vk_surface_snapshot(dev->physical, info->surface, &caps);
   if (result != VK_SUCCESS) goto fail_window;
   if (!caps.supported) { result = VK_ERROR_SURFACE_LOST_KHR; goto fail_window; }
   bool advertised = false;
   for (uint32_t i = 0; i < caps.format_count; i++)
      advertised |= caps.formats[i].format == info->imageFormat &&
                    caps.formats[i].colorSpace == info->imageColorSpace;
   if (!advertised) { result = VK_ERROR_FORMAT_NOT_SUPPORTED; goto fail_window; }
   const uint32_t format = r4vk_surface_format(&caps.config, info->imageFormat,
      info->imageColorSpace, info->compositeAlpha);
   const uint32_t mode = info->presentMode == VK_PRESENT_MODE_FIFO_KHR ? R4OS_WINDOW_GRAPHICS_FIFO :
      info->presentMode == VK_PRESENT_MODE_MAILBOX_KHR ? R4OS_WINDOW_GRAPHICS_MAILBOX : 0;
   const VkImageFormatListCreateInfo *formats =
      vk_find_struct_const(info->pNext, IMAGE_FORMAT_LIST_CREATE_INFO);
   result = r4vk_wsi_validate_formats(info->imageFormat, info->flags, formats);
   if (result != VK_SUCCESS) goto fail_window;
   const VkImageCreateFlags image_flags = info->flags & VK_SWAPCHAIN_CREATE_MUTABLE_FORMAT_BIT_KHR ?
      VK_IMAGE_CREATE_MUTABLE_FORMAT_BIT | VK_IMAGE_CREATE_EXTENDED_USAGE_BIT : 0;
   if (image_flags && !dev->enabled_extensions.KHR_swapchain_mutable_format) {
      result = VK_ERROR_EXTENSION_NOT_PRESENT; goto fail_window;
   }
   if (info->imageArrayLayers != 1 || !info->imageUsage ||
       (info->imageUsage & ~caps.usage) || !info->compositeAlpha ||
       !(info->compositeAlpha & caps.common_alpha) || format == UINT32_MAX ||
       info->minImageCount < caps.config.min_images || info->minImageCount > caps.config.max_images ||
       !mode || !(caps.config.present_modes & mode) ||
       info->imageSharingMode != VK_SHARING_MODE_EXCLUSIVE ||
       info->preTransform != VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR) {
      result = VK_ERROR_INITIALIZATION_FAILED; goto fail_window;
   }
   if (info->imageExtent.width != caps.config.width || info->imageExtent.height != caps.config.height) {
      result = VK_ERROR_OUT_OF_DATE_KHR; goto fail_window;
   }
   vk_foreach_struct_const(ext, info->pNext) {
      if (ext->sType == VK_STRUCTURE_TYPE_DEVICE_GROUP_SWAPCHAIN_CREATE_INFO_KHR) {
         const VkDeviceGroupSwapchainCreateInfoKHR *group = (const void *)ext;
         if (group->modes != VK_DEVICE_GROUP_PRESENT_MODE_LOCAL_BIT_KHR) {
            result = VK_ERROR_INITIALIZATION_FAILED; goto fail_window;
         }
      } else if (ext->sType != VK_STRUCTURE_TYPE_IMAGE_FORMAT_LIST_CREATE_INFO)
         vk_debug_ignored_stype(ext->sType);
   }
   const uint32_t format_count = formats ? formats->viewFormatCount : 0;
   const uint64_t bytes = sizeof(struct r4vk_swapchain) + (uint64_t)format_count * sizeof(VkFormat);
   if (bytes > SIZE_MAX) { result = VK_ERROR_OUT_OF_HOST_MEMORY; goto fail_window; }
   struct r4vk_swapchain *sc = vk_zalloc2(&dev->alloc, allocator,
      (size_t)bytes, 8, VK_SYSTEM_ALLOCATION_SCOPE_OBJECT);
   if (!sc) { result = VK_ERROR_OUT_OF_HOST_MEMORY; goto fail_window; }
   struct native_chain *chain = calloc(1, sizeof(*chain));
   if (!chain) {
      vk_free2(&dev->alloc, allocator, sc);
      result = VK_ERROR_OUT_OF_HOST_MEMORY; goto fail_window;
   }
   vk_object_base_init(dev, &sc->base, VK_OBJECT_TYPE_SWAPCHAIN_KHR);
   sc->device = dev; sc->record = chain; sc->count = info->minImageCount;
   if (format_count) memcpy(sc->view_formats, formats->pViewFormats, format_count * sizeof(VkFormat));
   sc->format_list = (VkImageFormatListCreateInfo) {
      .sType = VK_STRUCTURE_TYPE_IMAGE_FORMAT_LIST_CREATE_INFO,
      .viewFormatCount = format_count, .pViewFormats = sc->view_formats,
   };
   chain->ops = ops; chain->window = w; chain->config = caps.config; chain->count = sc->count; chain->live = true;
   chain->next = w->chains; w->chains = chain; /* Takes window_get reference. */
   R4Dev devices;
   if (!r4vk_get_graphics_tables(&chain->draw, &devices)) {
      result = VK_ERROR_DEVICE_LOST; goto fail_chain;
   }
   R4WindowGraphicsRequest command = request_for(chain, R4OS_WINDOW_GRAPHICS_CREATE_CHAIN);
   command.image_count = sc->count; command.format_index = format; command.present_mode = mode;
   R4WindowGraphicsReply reply;
   if (!request(s, chain, command, &reply)) { result = VK_ERROR_SURFACE_LOST_KHR; goto fail_chain; }
   result = vk_result(reply.result);
   if (result != VK_SUCCESS) goto fail_chain;
   for (uint32_t i = 0; i < sc->count; i++) {
      result = source_image(chain, caps.config.formats[format].format, &chain->sources[i]);
      if (result != VK_SUCCESS) goto fail_chain;
      result = ops->import(device, &chain->sources[i].reference,
         info->imageFormat, info->imageUsage, image_flags,
         format_count ? &sc->format_list : NULL, allocator, &sc->images[i]);
      if (result != VK_SUCCESS) goto fail_chain;
      command = request_for(chain, R4OS_WINDOW_GRAPHICS_ATTACH);
      command.image_slot = i; command.source = chain->sources[i].reference;
      if (!request(s, chain, command, &reply)) { result = VK_ERROR_SURFACE_LOST_KHR; goto fail_chain; }
      result = vk_result(reply.result);
      if (result != VK_SUCCESS) goto fail_chain;
      if (r4draw_gfx_buffer_release(&chain->draw, &chain->sources[i].reference) != 1) {
         result = VK_ERROR_DEVICE_LOST; goto fail_chain;
      }
      chain->sources[i] = (R4GfxBufferReference){0};
   }
   w->active = chain;
   *out = (VkSwapchainKHR)(uintptr_t)sc;
   unlock(&w->mutex);
   return VK_SUCCESS;
fail_chain:
   fail(chain, result); chain->live = false;
   for (uint32_t i = 0; i < sc->count; i++) chain->ops->finish(device, allocator, &sc->images[i]);
   vk_object_base_finish(&sc->base);
   vk_free2(&dev->alloc, allocator, sc);
   unlock(&w->mutex);
   wake_worker(s);
   return result;
fail_window:
   unlock(&w->mutex);
   window_put(s, w);
   return result;
}

VKAPI_ATTR void VKAPI_CALL
nvk_DestroySwapchainKHR(VkDevice device, VkSwapchainKHR handle,
                       const VkAllocationCallbacks *allocator)
{
   if (!handle) return;
   struct r4vk_swapchain *sc = swapchain(handle);
   struct native_chain *chain = sc->record;
   struct native_window *w = chain->window;
   struct wsi_state *s = state();
   assert(s && sc->device == vk_device_from_handle(device));
   lock(&w->mutex);
   chain->live = false; chain->closing = true;
   if (w->active == chain) w->active = NULL;
   unlock(&w->mutex);
   for (uint32_t i = 0; i < sc->count; i++) chain->ops->finish(device, allocator, &sc->images[i]);
   vk_object_base_finish(&sc->base);
   vk_free2(&vk_device_from_handle(device)->alloc, allocator, sc);
   wake_worker(s);
}

VKAPI_ATTR VkResult VKAPI_CALL
nvk_GetSwapchainImagesKHR(VkDevice device, VkSwapchainKHR handle, uint32_t *count, VkImage *images)
{
   (void)device;
   struct r4vk_swapchain *sc = swapchain(handle);
   if (!images) { *count = sc->count; return VK_SUCCESS; }
   const uint32_t written = MIN2(*count, sc->count);
   for (uint32_t i = 0; i < written; i++) images[i] = sc->images[i].image;
   *count = written;
   return written < sc->count ? VK_INCOMPLETE : VK_SUCCESS;
}

VKAPI_ATTR VkResult VKAPI_CALL
r4vkDrainWindowSwapchain(VkDevice device, VkSwapchainKHR handle, uint64_t timeout_ns)
{
   struct r4vk_swapchain *sc = swapchain(handle);
   if (!sc || sc->device != vk_device_from_handle(device)) return VK_ERROR_DEVICE_LOST;
   struct native_chain *chain = sc->record;
   struct native_window *w = chain->window;
   uint64_t start;
   if (r4vk_monotonic_time(&start)) return VK_ERROR_DEVICE_LOST;
   const uint64_t until = timeout_ns > UINT64_MAX - start ? UINT64_MAX : start + timeout_ns;
   for (;;) {
      lock(&w->mutex);
      VkResult result = chain->error;
      bool queued = false;
      if (result == VK_SUCCESS) result = chain->ops->check(sc->device);
      if (result == VK_SUCCESS && !drain(w, NULL)) result = VK_NOT_READY;
      for (uint32_t slot = 0; result == VK_SUCCESS && slot < chain->count; slot++) {
         R4WindowGraphicsRequest query = request_for(chain, R4OS_WINDOW_GRAPHICS_CHAIN_STATUS);
         R4WindowGraphicsReply reply;
         query.image_slot = slot;
         if (!r4vk_window_request(w->application, &query, &reply)) {
            result = r4vk_window_service_dead(w->application, &w->identity.service) ?
               VK_ERROR_SURFACE_LOST_KHR : VK_NOT_READY;
            break;
         }
         result = vk_result(reply.result);
         if (result != VK_SUCCESS) break;
         if (memcmp(&reply.surface, &w->identity, sizeof(w->identity)) ||
             reply.chain != chain->chain || reply.image_slot != slot ||
             reply.flags > R4OS_WINDOW_GRAPHICS_IMAGE_RETURNING) {
            result = VK_ERROR_SURFACE_LOST_KHR;
            break;
         }
         queued |= reply.flags == R4OS_WINDOW_GRAPHICS_IMAGE_QUEUED;
         w->revision = reply.revision;
      }
      const uint64_t revision = w->revision;
      unlock(&w->mutex);
      if (result != VK_SUCCESS && result != VK_NOT_READY) return result;
      if (result == VK_SUCCESS && !queued) return VK_SUCCESS;
      if (!timeout_ns) return VK_NOT_READY;
      uint64_t now;
      if (r4vk_monotonic_time(&now)) return VK_ERROR_DEVICE_LOST;
      if (now >= until) return VK_TIMEOUT;
      r4vk_window_wait(w->application, &w->identity.owner, revision, until - now);
   }
}

VKAPI_ATTR VkResult VKAPI_CALL
nvk_AcquireNextImage2KHR(VkDevice device, const VkAcquireNextImageInfoKHR *info, uint32_t *index)
{
   struct r4vk_swapchain *sc = swapchain(info->swapchain);
   struct native_chain *chain = sc->record;
   struct native_window *w = chain->window;
   struct wsi_state *s = state();
   if (!s) return VK_ERROR_OUT_OF_HOST_MEMORY;
   if (info->deviceMask != 1) return VK_ERROR_DEVICE_LOST;
   uint64_t start;
   if (r4vk_monotonic_time(&start)) return VK_ERROR_DEVICE_LOST;
   const uint64_t until = info->timeout > UINT64_MAX - start ? UINT64_MAX : start + info->timeout;
   for (;;) {
      lock(&w->mutex);
      VkResult result = chain->error;
      if (result == VK_SUCCESS && chain->retired) {
         unlock(&w->mutex);
         return VK_ERROR_OUT_OF_DATE_KHR;
      }
      if (result == VK_SUCCESS) result = chain->ops->check(sc->device);
      R4WindowGraphicsReply reply;
      if (result == VK_SUCCESS) {
         if (!request(s, chain, request_for(chain, R4OS_WINDOW_GRAPHICS_ACQUIRE), &reply))
            result = VK_ERROR_SURFACE_LOST_KHR;
         else result = vk_result(reply.result);
      }
      if (result == VK_SUCCESS) {
         /* The broker has returned this exact image's previous consumer
          * loans. Only this confirmed acquisition restores native writes. */
         if (chain->ops->acquired)
            result = chain->ops->acquired(device, &sc->images[reply.image_slot], true);
         if (result == VK_SUCCESS && info->semaphore) result = vk_sync_signal(sc->device,
            vk_semaphore_get_active_sync(vk_semaphore_from_handle(info->semaphore)), 0);
         if (result == VK_SUCCESS && info->fence) result = vk_sync_signal(sc->device,
            vk_fence_get_active_sync(vk_fence_from_handle(info->fence)), 0);
         if (result == VK_SUCCESS) *index = reply.image_slot;
         else {
            /* Acquisition happened. Close owns cancellation and retirement;
             * a partly signalled Vulkan acquire cannot be reported as OOM. */
            result = VK_ERROR_DEVICE_LOST;
         }
      }
      if (result < 0) fail(chain, result);
      const uint64_t revision = w->revision;
      unlock(&w->mutex);
      if (result != VK_NOT_READY) {
         if (result < 0) wake_worker(s);
         return result;
      }
      if (!info->timeout) return VK_NOT_READY;
      uint64_t now;
      if (r4vk_monotonic_time(&now)) return VK_ERROR_DEVICE_LOST;
      if (now >= until) return VK_TIMEOUT;
      r4vk_window_wait(w->application, &w->identity.owner, revision, until - now);
   }
}

VKAPI_ATTR VkResult VKAPI_CALL
nvk_AcquireNextImageKHR(VkDevice device, VkSwapchainKHR chain, uint64_t timeout,
                      VkSemaphore semaphore, VkFence fence, uint32_t *index)
{
   const VkAcquireNextImageInfoKHR info = {
      .sType = VK_STRUCTURE_TYPE_ACQUIRE_NEXT_IMAGE_INFO_KHR, .swapchain = chain,
      .timeout = timeout, .semaphore = semaphore, .fence = fence, .deviceMask = 1,
   };
   return nvk_AcquireNextImage2KHR(device, &info, index);
}

static VkResult present_result(VkResult previous, VkResult next)
{
   if (previous == VK_ERROR_DEVICE_LOST || next == VK_ERROR_DEVICE_LOST) return VK_ERROR_DEVICE_LOST;
   if (previous == VK_ERROR_SURFACE_LOST_KHR || next == VK_ERROR_SURFACE_LOST_KHR) return VK_ERROR_SURFACE_LOST_KHR;
   if (previous == VK_ERROR_OUT_OF_DATE_KHR || next == VK_ERROR_OUT_OF_DATE_KHR) return VK_ERROR_OUT_OF_DATE_KHR;
   return next != VK_SUCCESS ? next : previous;
}

VKAPI_ATTR VkResult VKAPI_CALL
nvk_QueuePresentKHR(VkQueue handle, const VkPresentInfoKHR *info)
{
   struct vk_queue *queue = vk_queue_from_handle(handle);
   struct vk_device *dev = queue->base.device;
   const struct r4vk_wsi_backend *ops = r4vk_wsi_backend(dev->physical);
   VkDevice device = vk_device_to_handle(dev);
   struct wsi_state *s = state();
   VkResult result = s ? VK_SUCCESS : VK_ERROR_OUT_OF_HOST_MEMORY;
   VkSemaphoreSubmitInfo *waits = NULL;
   VkFence fence = VK_NULL_HANDLE;
   void *point = NULL;
   R4GfxFence native_fence;
   if (result != VK_SUCCESS) goto all_failed;
   if (!ops) { result = VK_ERROR_FEATURE_NOT_PRESENT; goto all_failed; }
   if (!ops->can_present(dev->physical, queue->queue_family_index)) {
      result = VK_ERROR_DEVICE_LOST; goto all_failed;
   }
   if (info->waitSemaphoreCount) {
      waits = vk_alloc(&dev->alloc, (size_t)info->waitSemaphoreCount * sizeof(*waits),
         8, VK_SYSTEM_ALLOCATION_SCOPE_COMMAND);
      if (!waits) { result = VK_ERROR_OUT_OF_HOST_MEMORY; goto all_failed; }
      for (uint32_t i = 0; i < info->waitSemaphoreCount; i++) waits[i] = (VkSemaphoreSubmitInfo) {
         .sType = VK_STRUCTURE_TYPE_SEMAPHORE_SUBMIT_INFO, .semaphore = info->pWaitSemaphores[i],
         .stageMask = VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
      };
   }
   const VkFenceCreateInfo create = {.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO};
   result = vk_common_CreateFence(device, &create, NULL, &fence);
   if (result != VK_SUCCESS) goto all_failed;
   struct vk_sync *sync = vk_fence_get_active_sync(vk_fence_from_handle(fence));
   result = ops->prepare(sync);
   if (result != VK_SUCCESS) goto all_failed;
   const VkSubmitInfo2 submit = {
      .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO_2,
      .waitSemaphoreInfoCount = info->waitSemaphoreCount, .pWaitSemaphoreInfos = waits,
   };
   /* Consume the binary waits once, including rejected/outdated surfaces.
    * Native submission emits an actual device checkpoint. Its metadata pin
    * survives Vulkan fence destruction and asynchronous Desktop consumption. */
   result = vk_common_QueueSubmit2(handle, 1, &submit, fence);
   if (result != VK_SUCCESS) {
      r4vk_native_failure("present-submit", result, info->waitSemaphoreCount, 0, 0);
      result = VK_ERROR_DEVICE_LOST; goto all_failed;
   }
   result = ops->take(sync, &point, &native_fence);
   if (result != VK_SUCCESS) {
      r4vk_native_failure("present-take", result, 0, 0, 0);
      result = VK_ERROR_DEVICE_LOST; goto all_failed;
   }
   vk_common_DestroyFence(device, fence, NULL); fence = VK_NULL_HANDLE;
   vk_free(&dev->alloc, waits); waits = NULL;
   result = VK_SUCCESS;
   for (uint32_t i = 0; i < info->swapchainCount; i++) {
      struct r4vk_swapchain *sc = swapchain(info->pSwapchains[i]);
      struct native_chain *chain = sc->record;
      struct native_window *w = chain->window;
      const uint32_t slot = info->pImageIndices[i];
      lock(&w->mutex);
      VkResult one = chain->error;
      if (one == VK_SUCCESS && (sc->device != dev || slot >= chain->count ||
          !(chain->acquired & (1u << slot)))) one = VK_ERROR_SURFACE_LOST_KHR;
      if (one == VK_SUCCESS) {
         assert(!chain->points[slot]);
         /* QueuePresent's checkpoint already owns the submitted writers.
          * Mark all canonical aliases read-only before the host may publish
          * a CPU/read-only consumer loan. Future snapshots retain every BO
          * without falsely writing this previous front image. */
         if (ops->acquired) one = ops->acquired(device, &sc->images[slot], false);
         if (one == VK_SUCCESS) one = ops->pin(point, NULL);
         if (one == VK_SUCCESS) {
            ops->ref(point); chain->points[slot] = point;
            R4WindowGraphicsRequest command = request_for(chain, R4OS_WINDOW_GRAPHICS_PRESENT);
            command.image_slot = slot; command.acquire_token = chain->tokens[slot]; command.fence = native_fence;
            R4WindowGraphicsReply reply;
            if (!request(s, chain, command, &reply)) one = VK_ERROR_SURFACE_LOST_KHR;
            else {
               one = vk_result(reply.result);
               if (one != VK_SUCCESS)
                  r4vk_native_failure("present-host", one, reply.result,
                                       chain->chain, slot);
               if (one != VK_SUCCESS) release_point(chain, slot);
            }
         }
      }
      /* Host OOM is only legal before the queue operations were enqueued. */
      if (one != VK_SUCCESS && one != VK_ERROR_OUT_OF_DATE_KHR && one != VK_ERROR_SURFACE_LOST_KHR)
         one = VK_ERROR_DEVICE_LOST;
      if (one < 0) fail(chain, one);
      unlock(&w->mutex);
      if (info->pResults) info->pResults[i] = one;
      result = present_result(result, one);
   }
   ops->unpin(point); ops->unref(point);
   if (result < 0) wake_worker(s);
   return result;
all_failed:
   r4vk_native_failure("present-failed", result, info->waitSemaphoreCount, 0, 0);
   vk_common_DestroyFence(device, fence, NULL);
   vk_free(&dev->alloc, waits);
   for (uint32_t i = 0; i < info->swapchainCount; i++) if (info->pResults) info->pResults[i] = result;
   return result;
}

VKAPI_ATTR VkResult VKAPI_CALL
nvk_GetDeviceGroupPresentCapabilitiesKHR(VkDevice device, VkDeviceGroupPresentCapabilitiesKHR *out)
{
   (void)device;
   memset(out->presentMask, 0, sizeof(out->presentMask));
   out->presentMask[0] = 1;
   out->modes = VK_DEVICE_GROUP_PRESENT_MODE_LOCAL_BIT_KHR;
   return VK_SUCCESS;
}
VKAPI_ATTR VkResult VKAPI_CALL
nvk_GetDeviceGroupSurfacePresentModesKHR(VkDevice device, VkSurfaceKHR surface,
                                       VkDeviceGroupPresentModeFlagsKHR *modes)
{
   struct r4vk_surface_caps caps;
   VkResult result = r4vk_surface_snapshot(vk_device_from_handle(device)->physical, surface, &caps);
   if (result != VK_SUCCESS) return result;
   if (!caps.supported) return VK_ERROR_SURFACE_LOST_KHR;
   *modes = VK_DEVICE_GROUP_PRESENT_MODE_LOCAL_BIT_KHR;
   return VK_SUCCESS;
}
VKAPI_ATTR VkResult VKAPI_CALL
nvk_GetPhysicalDevicePresentRectanglesKHR(VkPhysicalDevice handle, VkSurfaceKHR surface,
                                        uint32_t *count, VkRect2D *rectangles)
{
   struct r4vk_surface_caps caps;
   VkResult result = r4vk_surface_snapshot(vk_physical_device_from_handle(handle), surface, &caps);
   if (result != VK_SUCCESS) return result;
   if (!caps.supported) return VK_ERROR_SURFACE_LOST_KHR;
   if (!rectangles) { *count = 1; return VK_SUCCESS; }
   if (!*count) return VK_INCOMPLETE;
   rectangles[0] = (VkRect2D){.extent = {caps.config.width, caps.config.height}};
   *count = 1;
   return VK_SUCCESS;
}
