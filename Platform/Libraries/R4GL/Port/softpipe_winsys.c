/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4gl_sw.h"
#include "frontend/sw_winsys.h"
#include "pipe/p_defines.h"
#include "util/format/u_format.h"
#include "util/u_atomic.h"
#include <assert.h>
#include <stdlib.h>

struct native_winsys {
   struct sw_winsys base;
   struct r4gl_sw_host host;
   int targets;
};
struct sw_displaytarget {
   struct native_winsys *owner;
   struct r4gl_sw_storage storage;
   int maps;
};
static struct native_winsys *native(struct sw_winsys *ws)
{
   return (struct native_winsys *)ws;
}
static bool supports(struct sw_winsys *ws, unsigned usage, enum pipe_format format)
{
   /* POSIX file descriptors and DRM handles are outside this native boundary. */
   if ((unsigned)format == PIPE_FORMAT_NONE || (unsigned)format >= PIPE_FORMAT_COUNT ||
       (usage & PIPE_BIND_SHARED))
      return false;
   return native(ws)->host.supports(native(ws)->host.owner, usage, format);
}
static struct sw_displaytarget *create(struct sw_winsys *ws, unsigned usage,
                                      enum pipe_format format, unsigned width,
                                      unsigned height, unsigned alignment,
                                      const void *front, unsigned *stride)
{
   if (!stride || !width || !height || !alignment ||
       (alignment & (alignment - 1)) || !supports(ws, usage, format))
      return NULL;
   struct native_winsys *w = native(ws);
   struct sw_displaytarget *target = calloc(1, sizeof(*target));
   if (!target)
      return NULL;
   if (!w->host.allocate(w->host.owner, front, usage, format,
                         width, height, alignment, &target->storage)) {
      free(target);
      return NULL;
   }
   const struct util_format_description *description = util_format_description(format);
   uint64_t row_bytes = ((uint64_t)width + description->block.width - 1) /
      description->block.width * (description->block.bits / 8);
   uint64_t rows = ((uint64_t)height + description->block.height - 1) /
      description->block.height;
   if (!target->storage.token || !target->storage.mapping ||
       (uintptr_t)target->storage.mapping % alignment ||
       target->storage.stride < row_bytes || target->storage.stride % alignment ||
       target->storage.bytes < rows * target->storage.stride) {
      w->host.release(w->host.owner, &target->storage);
      free(target);
      return NULL;
   }
   target->owner = w;
   p_atomic_inc(&w->targets);
   *stride = target->storage.stride;
   return target;
}
static void *map(struct sw_winsys *ws, struct sw_displaytarget *target, unsigned flags)
{
   (void)flags;
   assert(target && target->owner == native(ws));
   p_atomic_inc(&target->maps);
   return target->storage.mapping;
}
static void unmap(struct sw_winsys *ws, struct sw_displaytarget *target)
{
   assert(target && target->owner == native(ws));
   assert(p_atomic_read(&target->maps) > 0);
   p_atomic_dec(&target->maps);
}
static void destroy_target(struct sw_winsys *ws, struct sw_displaytarget *target)
{
   assert(target && target->owner == native(ws) && p_atomic_read(&target->maps) == 0);
   struct native_winsys *w = native(ws);
   w->host.release(w->host.owner, &target->storage);
   p_atomic_dec(&w->targets);
   free(target);
}
static void display(struct sw_winsys *ws, struct sw_displaytarget *target,
                    void *context, unsigned count, struct pipe_box *damage)
{
   assert(target && target->owner == native(ws) && (!count || damage));
   struct native_winsys *w = native(ws);
   w->host.present(w->host.owner, &target->storage, context, count, damage);
}
static struct sw_displaytarget *from_handle(struct sw_winsys *ws,
                                           const struct pipe_resource *template,
                                           struct winsys_handle *handle,
                                           unsigned *stride)
{
   (void)ws; (void)template; (void)handle; (void)stride;
   return NULL;
}
static bool get_handle(struct sw_winsys *ws, struct sw_displaytarget *target,
                       struct winsys_handle *handle)
{
   (void)ws; (void)target; (void)handle;
   return false;
}
static struct sw_displaytarget *create_mapped(struct sw_winsys *ws, unsigned usage,
                                              enum pipe_format format,
                                              unsigned width, unsigned height,
                                              unsigned stride, void *data,
                                              struct winsys_handle *handle)
{
   /* Imported application pointers do not carry a canonical buffer lease. */
   (void)ws; (void)usage; (void)format; (void)width; (void)height;
   (void)stride; (void)data; (void)handle;
   return NULL;
}
static int get_fd(struct sw_winsys *ws) { (void)ws; return -1; }
static void destroy(struct sw_winsys *ws)
{
   assert(p_atomic_read(&native(ws)->targets) == 0);
   free(ws);
}
struct sw_winsys *r4gl_sw_create(const struct r4gl_sw_host *host)
{
   if (!host || !host->supports || !host->allocate || !host->release || !host->present)
      return NULL;
   struct native_winsys *w = calloc(1, sizeof(*w));
   if (!w)
      return NULL;
   w->host = *host;
   w->base = (struct sw_winsys) {
      .destroy = destroy, .get_fd = get_fd,
      .is_displaytarget_format_supported = supports,
      .displaytarget_create = create, .displaytarget_from_handle = from_handle,
      .displaytarget_get_handle = get_handle, .displaytarget_map = map,
      .displaytarget_unmap = unmap, .displaytarget_display = display,
      .displaytarget_destroy = destroy_target, .displaytarget_create_mapped = create_mapped,
   };
   return &w->base;
}
