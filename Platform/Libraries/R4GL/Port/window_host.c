/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#define EGL_NO_PLATFORM_SPECIFIC_TYPES
#include "r4gl_window_host.h"
#include "r4gl_state.h"
#include "r4gl_vulkan.h"
#include "kopper_interface.h"
#include "r4gfx.h"
#include "pipe/p_defines.h"
#include "util/cnd_monotonic.h"
#include <assert.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

#define OK R4OS_WINDOW_GRAPHICS_OK
#define COUNT(a) (sizeof(a) / sizeof((a)[0]))
struct chain;
struct window {
   mtx_t gate;
   bool used, live;
   uint64_t application;
   R4Draw draw;
   R4WindowGraphicsSurface identity;
   R4WindowGraphicsConfig config;
   uint64_t revision;
   struct chain *chains, *active, *pending_owner;
   R4WindowGraphicsRequest pending;
   EGLint status, interval;
};
struct chain {
   struct chain *next;
   struct window *window;
   R4WindowGraphicsConfig config;
   uint64_t id;
   unsigned attached, acquired, count, mode;
   uint64_t tokens[3];
   R4GfxBufferReference images[3];
   R4GfxFence fences[3];
   R4GfxQueueHandle queue;
   bool closing, close_acked, remote_closed;
};
struct state {
   mtx_t gate;
   struct u_cnd_monotonic changed;
   bool initialized, started, stop;
   uint64_t serial, wake;
   thrd_t worker;
   struct window windows[16]; /* matches the broker's surface capacity */
};
struct host { uint64_t application; R4Draw draw; };
struct storage {
   R4Draw draw;
   R4GfxBufferReference bo;
   R4GfxBufferMap map;
   struct window *window;
   uint64_t revision;
   unsigned width, height;
};
static const unsigned char state_key;
static void lock(mtx_t *gate) { if (mtx_lock(gate) != thrd_success) abort(); }
static void unlock(mtx_t *gate) { if (mtx_unlock(gate) != thrd_success) abort(); }
static void initialize(void *value)
{
   struct state *s = value;
   if (mtx_init(&s->gate, mtx_plain) != thrd_success) return;
   if (u_cnd_monotonic_init(&s->changed) != thrd_success) { mtx_destroy(&s->gate); return; }
   unsigned i = 0;
   for (; i < COUNT(s->windows); i++)
      if (mtx_init(&s->windows[i].gate, mtx_plain) != thrd_success) break;
   if (i != COUNT(s->windows)) {
      while (i) mtx_destroy(&s->windows[--i].gate);
      u_cnd_monotonic_destroy(&s->changed); mtx_destroy(&s->gate); return;
   }
   s->initialized = true;
}
static struct state *state(void)
{
   struct state *s = r4gl_process_state(&state_key, sizeof(*s), _Alignof(struct state), initialize);
   return s && s->initialized ? s : NULL;
}
static void wake(struct state *s)
{
   lock(&s->gate); s->wake++;
   if (u_cnd_monotonic_broadcast(&s->changed) != thrd_success) abort();
   unlock(&s->gate);
}
static EGLint result(int32_t rc)
{
   switch (rc) {
   case OK: return EGL_SUCCESS;
   case R4OS_WINDOW_GRAPHICS_NOT_READY:
   case R4OS_WINDOW_GRAPHICS_BUSY:
   case R4OS_WINDOW_GRAPHICS_UNAVAILABLE: return EGL_BAD_ACCESS;
   case R4OS_WINDOW_GRAPHICS_CAPACITY: return EGL_BAD_ALLOC;
   case R4OS_WINDOW_GRAPHICS_OUT_OF_DATE: return EGL_BAD_SURFACE;
   case R4OS_WINDOW_GRAPHICS_DEVICE_LOST: return EGL_CONTEXT_LOST;
   default: return EGL_BAD_NATIVE_WINDOW;
   }
}
static void retire(struct chain *c)
{
   if (c->closing) return;
   c->closing = true;
   if (c->window->active == c) c->window->active = NULL;
   wake(state());
}
static R4WindowGraphicsRequest command(struct chain *c, unsigned action)
{
   return (R4WindowGraphicsRequest) { .version = 1, .size = sizeof(R4WindowGraphicsRequest),
      .owner = c->window->identity.owner, .window_id = c->window->identity.window_id,
      .surface = c->window->identity, .chain = c->id, .config_revision = c->config.revision, .action = action };
}
/* All chains belonging to a native window share this one immutable pending
 * mutation. No retry, resize or destructor may overtake an unknown outcome. */
static bool drain(struct window *w, R4WindowGraphicsReply *out)
{
   struct chain *c = w->pending_owner;
   if (!c) return true;
   R4WindowGraphicsReply reply;
   if (!r4gl_window_request(w->application, &w->pending, &reply)) return false;
   if (reply.result == OK) {
      if (memcmp(&reply.surface, &w->identity, sizeof(w->identity))) return false;
      switch (w->pending.action) {
      case R4OS_WINDOW_GRAPHICS_CREATE_CHAIN:
         if (!reply.chain) return false;
         c->id = reply.chain; break;
      case R4OS_WINDOW_GRAPHICS_ATTACH:
         if (reply.chain != c->id || reply.image_slot != w->pending.image_slot) return false;
         c->attached |= 1u << reply.image_slot; break;
      case R4OS_WINDOW_GRAPHICS_ACQUIRE:
         if (reply.chain != c->id || reply.image_slot >= c->count || !reply.acquire_token) return false;
         c->tokens[reply.image_slot] = reply.acquire_token;
         c->acquired |= 1u << reply.image_slot; break;
      case R4OS_WINDOW_GRAPHICS_PRESENT:
      case R4OS_WINDOW_GRAPHICS_CANCEL_ACQUIRE:
         if (reply.chain != c->id || reply.image_slot != w->pending.image_slot || reply.acquire_token != w->pending.acquire_token) return false;
         c->acquired &= ~(1u << reply.image_slot); break;
      case R4OS_WINDOW_GRAPHICS_CLOSE_CHAIN:
         if (reply.chain != c->id) return false;
         c->close_acked = true; break;
      }
   } else if ((reply.result == R4OS_WINDOW_GRAPHICS_STALE && !reply.surface.serial) ||
       (w->pending.action == R4OS_WINDOW_GRAPHICS_CLOSE_CHAIN && reply.result == R4OS_WINDOW_GRAPHICS_CLOSED)) {
      c->remote_closed = true;
   }
   w->revision = reply.revision;
   w->pending_owner = NULL;
   if (out) *out = reply;
   return true;
}
static bool issue(struct chain *c, R4WindowGraphicsRequest request, R4WindowGraphicsReply *out)
{
   struct state *s = state(); struct window *w = c->window;
   if (!drain(w, NULL)) return false;
   lock(&s->gate);
   if (s->serial == UINT64_MAX) { unlock(&s->gate); return false; }
   request.request_serial = ++s->serial;
   unlock(&s->gate);
   w->pending = request; w->pending_owner = c;
   return drain(w, out);
}
static bool release_fence(struct chain *c, unsigned slot)
{
   R4GfxFence *fence = &c->fences[slot];
   if (!fence->slot) return true;
   R4GfxFenceStatus status;
   if (r4draw_gfx_fence_query(&c->window->draw, fence, &status) != 1 ||
       status.result == R4OS_GFX_QUEUE_RESULT_PENDING || status.flags & R4OS_GFX_QUEUE_FLAG_RESOURCES_HELD) return false;
   if (r4draw_gfx_fence_release(&c->window->draw, fence) != 1) return false;
   *fence = (R4GfxFence){0}; return true;
}
static bool retire_step(struct window *w)
{
   bool outstanding = false;
   lock(&w->gate);
   const bool dead = r4gl_window_service_dead(w->application, &w->identity.service);
   if (dead) w->pending_owner = NULL;
   else if (!drain(w, NULL)) { unlock(&w->gate); return true; }
   struct chain **link = &w->chains;
   while (*link) {
      struct chain *c = *link;
      if (dead) { c->remote_closed = true; retire(c); }
      if (!c->closing) { link = &c->next; continue; }
      if (!c->id) c->remote_closed = true;
      if (!c->remote_closed && !c->close_acked) {
         R4WindowGraphicsReply reply;
         if (!issue(c, command(c, R4OS_WINDOW_GRAPHICS_CLOSE_CHAIN), &reply)) { outstanding = true; break; }
      }
      bool held = false;
      for (unsigned i = 0; i < c->count; i++) {
         if (c->fences[i].slot) {
            bool loan_ended = c->remote_closed;
            if (!loan_ended && c->close_acked) {
               R4WindowGraphicsRequest request = command(c, R4OS_WINDOW_GRAPHICS_CHAIN_STATUS);
               request.image_slot = i;
               R4WindowGraphicsReply reply;
               if (r4gl_window_request(w->application, &request, &reply))
                  loan_ended = (reply.result == R4OS_WINDOW_GRAPHICS_STALE && !reply.surface.serial) ||
                     (reply.result == R4OS_WINDOW_GRAPHICS_CLOSED && reply.flags != R4OS_WINDOW_GRAPHICS_IMAGE_LEASED);
            }
            if (!loan_ended || !release_fence(c, i)) held = true;
         }
         if (c->images[i].reference.id) {
            if (w->pending_owner == c || r4draw_gfx_buffer_release(&w->draw, &c->images[i].reference) != 1) held = true;
            else c->images[i] = (R4GfxBufferReference){0};
         }
      }
      if (!held && (c->close_acked || c->remote_closed) && w->pending_owner != c) {
         if (c->queue.timeline && r4draw_gfx_queue_close(&w->draw, &c->queue) != 1) { outstanding = true; link = &c->next; continue; }
         *link = c->next; free(c);
      } else { outstanding = true; link = &c->next; }
   }
   if (!w->live && !w->chains) {
      struct state *s = state();
      lock(&s->gate); w->used = false; unlock(&s->gate);
   }
   unlock(&w->gate);
   return outstanding;
}
static int worker(void *value)
{
   struct state *s = value;
   for (;;) {
      lock(&s->gate); bool stop = s->stop; uint64_t observed = s->wake; unlock(&s->gate);
      if (stop) return 0;
      bool outstanding = false;
      for (unsigned i = 0; i < COUNT(s->windows); i++) {
         lock(&s->gate); bool used = s->windows[i].used; unlock(&s->gate);
         if (used) outstanding |= retire_step(&s->windows[i]);
      }
      lock(&s->gate);
      if (s->wake == observed && !s->stop) {
         int rc;
         if (outstanding) {
            uint64_t until = r4gl_native_now() + 25000000ull;
            struct timespec time = {until / 1000000000ull, until % 1000000000ull};
            rc = u_cnd_monotonic_timedwait(&s->changed, &s->gate, &time);
         } else rc = u_cnd_monotonic_wait(&s->changed, &s->gate);
         if (rc != thrd_success && rc != thrd_timedout) abort();
      }
      unlock(&s->gate);
   }
}
bool r4gl_window_finish(uint64_t deadline)
{
   struct state *s = state(); if (!s) return false;
   for (;;) {
      lock(&s->gate); bool used = false;
      for (unsigned i = 0; i < COUNT(s->windows); i++) used |= s->windows[i].used;
      bool started = s->started;
      if (!used) s->stop = true;
      unlock(&s->gate);
      if (!used) {
         if (!started) return true;
         wake(s); int code;
         if (thrd_join(s->worker, &code) != thrd_success || code) return false;
         lock(&s->gate); s->started = false; unlock(&s->gate); return true;
      }
      if (r4gl_native_now() >= deadline) return false;
      thrd_yield();
   }
}
static bool config_ok(const R4WindowGraphicsConfig *c)
{
   const bool gpu = r4gl_native_profile() == 1;
   const bool software = c->backend.binding.adapter_id == 0;
   const bool headless = c->flags & R4OS_WINDOW_GRAPHICS_HEADLESS;
   const R4GfxOutputId no_output = {0};
   /* Zink's renderer and the window's consumer have separate owners. The
    * real GPU can render portable images for a CPU compositor on an actual
    * output or without scanout. Its CPU receipt does not prove GPU rendering
    * or synchronized scanout; those owners retain their separate receipts. */
   return c->version == 1 && c->size == sizeof(*c) && c->revision && c->width && c->height &&
      c->width <= 32768 && c->height <= 32768 && !c->reserved && c->display_generation &&
      !(c->flags & ~(R4OS_WINDOW_GRAPHICS_VISIBLE | R4OS_WINDOW_GRAPHICS_HEADLESS)) &&
      (headless ? (software && !memcmp(&c->output, &no_output, sizeof(no_output))) :
         (c->output.connector_id && c->output.connection_generation && c->output.device_generation &&
          (software || (c->output.adapter_id == c->backend.binding.adapter_id &&
                        c->output.device_generation == c->backend.binding.device_generation)))) &&
      c->backend.version == 1 && c->backend.size == sizeof(c->backend) &&
      c->backend.binding.version == 1 && c->backend.binding.size == sizeof(c->backend.binding) &&
      c->backend.binding.device_generation && c->backend.binding.reset_generation &&
      (software ? c->backend.binding.milestone == R4OS_GFX_QUEUE_MILESTONE_CPU_STORES :
         (gpu && c->backend.binding.milestone == R4OS_GFX_QUEUE_MILESTONE_DEVICE_EXECUTION)) &&
      c->min_images >= 2 && c->max_images <= 3 && c->min_images <= c->max_images &&
      c->format_count && c->format_count <= COUNT(c->formats) && (c->present_modes & R4OS_WINDOW_GRAPHICS_FIFO) &&
      !(c->present_modes & ~(R4OS_WINDOW_GRAPHICS_MAILBOX | R4OS_WINDOW_GRAPHICS_FIFO));
}
static EGLint refresh(struct window *w)
{
   R4WindowGraphicsReply reply;
   int32_t rc = r4gl_window_query(w->application, w->identity.window_id, &w->identity, &reply);
   if (rc != OK) return result(rc);
   if (!config_ok(&reply.config)) return EGL_BAD_MATCH;
   w->config = reply.config; w->revision = reply.revision;
   if (w->active && w->active->config.revision != w->config.revision) retire(w->active);
   return EGL_SUCCESS;
}
static EGLint acquire_window(void *value, void *native, void **lease)
{
   struct host *host = value;
   if (!(uintptr_t)native || (uintptr_t)native > UINT32_MAX) return EGL_BAD_NATIVE_WINDOW;
   R4WindowGraphicsReply reply;
   int32_t rc = r4gl_window_query(host->application, (uintptr_t)native, NULL, &reply);
   if (rc != OK) return result(rc);
   if (!config_ok(&reply.config)) return EGL_BAD_MATCH;
   struct state *s = state(); if (!s) return EGL_BAD_ALLOC;
   lock(&s->gate);
   for (unsigned i = 0; i < COUNT(s->windows); i++) if (s->windows[i].used &&
       !memcmp(&s->windows[i].identity, &reply.surface, sizeof(reply.surface))) { unlock(&s->gate); return EGL_BAD_ALLOC; }
   struct window *w = NULL;
   for (unsigned i = 0; i < COUNT(s->windows); i++) if (!s->windows[i].used) { w = &s->windows[i]; break; }
   if (!w) { unlock(&s->gate); return EGL_BAD_ALLOC; }
   s->stop = false;
   if (!s->started && thrd_create(&s->worker, worker, s) != thrd_success) { unlock(&s->gate); return EGL_BAD_ALLOC; }
   s->started = true;
   assert(!w->chains && !w->pending_owner && !w->active);
   w->application = host->application; w->draw = host->draw; w->identity = reply.surface;
   w->config = reply.config; w->revision = reply.revision; w->live = w->used = true; w->status = EGL_SUCCESS; w->interval = 0;
   unlock(&s->gate); *lease = w; return EGL_SUCCESS;
}
static void release_window(void *value, void *lease)
{
   (void)value; struct window *w = lease;
   lock(&w->gate); w->live = false;
   for (struct chain *c = w->chains; c; c = c->next) retire(c);
   unlock(&w->gate); wake(state());
}
static EGLint window_state(void *value, void *lease, struct r4gl_egl_geometry *out)
{
   (void)value; struct window *w = lease;
   lock(&w->gate); EGLint rc = refresh(w);
   if (rc == EGL_SUCCESS) *out = (struct r4gl_egl_geometry){w->config.width, w->config.height, w->config.revision};
   unlock(&w->gate); return rc;
}
static EGLint window_loader(void *value, void *lease, struct kopper_loader_info *out)
{
   (void)value; struct window *w = lease;
   if (r4gl_native_profile() != 1) return EGL_BAD_MATCH;
   lock(&w->gate); EGLint rc = refresh(w);
   if (rc == EGL_SUCCESS) *out = (struct kopper_loader_info) {
      .r4os_application = w->application, .r4os_surface = w->identity,
      .initial_swap_interval = w->interval, .present_opaque = true,
   };
   unlock(&w->gate); return rc;
}
static bool supports(void *value, unsigned usage, enum pipe_format format)
{
   (void)value;
   /* Both views store BGRA8 bytes. GL performs the optional sRGB encoding;
    * the opaque SDR window transport presents those bytes unchanged. */
   return (format == PIPE_FORMAT_B8G8R8A8_UNORM || format == PIPE_FORMAT_B8G8R8A8_SRGB) &&
      !(usage & PIPE_BIND_SHARED);
}
static R4GfxBufferDescriptor descriptor(unsigned width, unsigned height, unsigned stride, unsigned alignment)
{
   return (R4GfxBufferDescriptor){ .version = 1, .size = sizeof(R4GfxBufferDescriptor), .byte_length = (uint64_t)stride * height,
      .alignment = alignment, .width = width, .height = height, .format = R4OS_GFX_BUFFER_FORMAT_XRGB8888,
      .plane_count = 1, .plane_pitches = {stride}, .usage = R4OS_GFX_BUFFER_USAGE_CPU_READ | R4OS_GFX_BUFFER_USAGE_CPU_WRITE |
         R4OS_GFX_BUFFER_USAGE_RENDER | R4OS_GFX_BUFFER_USAGE_TRANSFER_SOURCE | R4OS_GFX_BUFFER_USAGE_TRANSFER_TARGET };
}
static bool allocate(void *value, const void *front, unsigned usage, enum pipe_format format,
                     unsigned width, unsigned height, unsigned alignment, struct r4gl_sw_storage *out)
{
   struct host *host = value; struct window *w = (void *)front;
   if (!w || !width || !height || width > 32768 || height > 32768 || !alignment ||
       (alignment & (alignment - 1)) || alignment > 4096 || !supports(value, usage, format)) return false;
   struct storage *s = calloc(1, sizeof(*s)); if (!s) return false;
   s->draw = host->draw; s->window = w; s->width = width; s->height = height;
   lock(&w->gate);
   EGLint rc = refresh(w);
   s->revision = w->config.revision;
   bool matches = w->config.width == width && w->config.height == height;
   unlock(&w->gate);
   if (rc != EGL_SUCCESS || !matches) { free(s); return false; }
   unsigned stride = (width * 4 + alignment - 1) & ~(alignment - 1);
   R4GfxBufferDescriptor desc = descriptor(width, height, stride, 4096);
   if (r4draw_gfx_buffer_create(&s->draw, &desc, &s->bo) != 1) { free(s); return false; }
   if (r4draw_gfx_buffer_map_persistent(&s->draw, &s->bo.reference, R4OS_GFX_BUFFER_MAP_WRITE, 0, desc.byte_length, &s->map) != 1) {
      if (r4draw_gfx_buffer_release(&s->draw, &s->bo.reference) != 1) abort(); free(s); return false;
   }
   *out = (struct r4gl_sw_storage){s, (void *)(uintptr_t)s->map.cpu_address, desc.byte_length, stride};
   return true;
}
static void release(void *value, struct r4gl_sw_storage *storage)
{
   (void)value; struct storage *s = storage->token;
   if (r4draw_gfx_buffer_unmap(&s->draw, &s->map.lease) != 1 || r4draw_gfx_buffer_release(&s->draw, &s->bo.reference) != 1) abort();
   free(s); *storage = (struct r4gl_sw_storage){0};
}
static EGLint create_chain(struct window *w, unsigned mode, R4WindowGraphicsReply *failed)
{
   const R4GfxColorDescription color = { .version = 1, .size = sizeof(color),
      .primaries = R4GFX_COLOR_PRIMARIES_SRGB, .transfer = R4GFX_COLOR_TRANSFER_SRGB,
      .range = R4GFX_COLOR_RANGE_FULL, .alpha = R4GFX_COLOR_ALPHA_OPAQUE,
      .precision = R4GFX_COLOR_PRECISION_UNORM8, .reference_white = 1000000, .peak = 1000000 };
   _Static_assert(sizeof(color) == sizeof(w->config.formats[0].color), "Window color ABI");
   unsigned format = UINT_MAX;
   for (unsigned i = 0; i < w->config.format_count; i++)
      if (w->config.formats[i].format == R4OS_GFX_BUFFER_FORMAT_XRGB8888 &&
          !memcmp(&color, w->config.formats[i].color, sizeof(color))) { format = i; break; }
   if (format == UINT_MAX) return EGL_BAD_MATCH;
   struct chain *c = calloc(1, sizeof(*c)); if (!c) return EGL_BAD_ALLOC;
   c->window = w; c->config = w->config; c->count = c->config.min_images; c->mode = mode;
   c->next = w->chains; w->chains = c;
   R4GfxQueueConfig config = { .version = 1, .size = sizeof(config), .capacity = 3,
      .device_generation = w->config.backend.binding.device_generation, .reset_generation = w->config.backend.binding.reset_generation };
   EGLint error = EGL_BAD_ALLOC;
   if (r4draw_gfx_queue_open(&w->draw, &config, &c->queue) != 1) goto fail;
   R4WindowGraphicsRequest request = command(c, R4OS_WINDOW_GRAPHICS_CREATE_CHAIN);
   request.image_count = c->count; request.format_index = format; request.present_mode = mode;
   R4WindowGraphicsReply reply;
   if (!issue(c, request, &reply)) { error = EGL_BAD_ACCESS; goto fail; }
   if ((error = result(reply.result)) != EGL_SUCCESS) { *failed = reply; goto fail; }
   for (unsigned i = 0; i < c->count; i++) {
      R4GfxBufferDescriptor desc = descriptor(c->config.width, c->config.height, c->config.width * 4, 4096);
      if (r4draw_gfx_buffer_create(&w->draw, &desc, &c->images[i]) != 1) { error = EGL_BAD_ALLOC; goto fail; }
      request = command(c, R4OS_WINDOW_GRAPHICS_ATTACH); request.image_slot = i; request.source = c->images[i].reference;
      if (!issue(c, request, &reply)) { error = EGL_BAD_ACCESS; goto fail; }
      if ((error = result(reply.result)) != EGL_SUCCESS) { *failed = reply; goto fail; }
   }
   w->active = c; return EGL_SUCCESS;
fail:
   retire(c); return error;
}
static EGLint swap_interval(void *value, void *lease, EGLint interval)
{
   (void)value;
   if (interval < 0 || interval > 1) return EGL_BAD_PARAMETER;
   struct window *w = lease;
   lock(&w->gate);
   EGLint rc = refresh(w);
   if (rc == EGL_SUCCESS && interval && !r4gl_window_swap_limit(w->application, &w->config)) rc = EGL_BAD_MATCH;
   if (rc == EGL_SUCCESS) w->interval = interval;
   unlock(&w->gate);
   return rc;
}
/* Changing the next posting's policy cannot cancel an earlier FIFO posting.
 * Its source may be returned later; reaching leased/returning is sufficient
 * because the desktop retains it until its last composition/capture use. */
static EGLint change_mode(struct window *w, unsigned mode, uint64_t until, R4WindowGraphicsReply *failed)
{
   struct chain *c = w->active;
   if (!c || c->mode == mode) return EGL_SUCCESS;
   if (c->mode == R4OS_WINDOW_GRAPHICS_FIFO) {
      for (;;) {
         if (!drain(w, NULL)) return EGL_BAD_ACCESS;
         bool queued = false;
         for (unsigned slot = 0; slot < c->count; slot++) {
            R4WindowGraphicsRequest request = command(c, R4OS_WINDOW_GRAPHICS_CHAIN_STATUS);
            request.image_slot = slot;
            R4WindowGraphicsReply reply;
            if (!r4gl_window_request(w->application, &request, &reply)) return EGL_BAD_ACCESS;
            if (reply.result != OK) { *failed = reply; return result(reply.result); }
            if (reply.chain != c->id || reply.image_slot != slot ||
                memcmp(&reply.surface, &w->identity, sizeof(w->identity))) return EGL_BAD_ACCESS;
            w->revision = reply.revision;
            queued |= reply.flags == R4OS_WINDOW_GRAPHICS_IMAGE_QUEUED;
         }
         if (!queued) break;
         if (r4gl_native_now() >= until) return EGL_BAD_ACCESS;
         r4gl_window_wait(w->application, &w->identity.owner, w->revision, 25000000ull);
      }
   }
   retire(c);
   return EGL_SUCCESS;
}
static EGLint publication_error(struct window *w, uint64_t revision,
                                const R4WindowGraphicsReply *reply, EGLint error)
{
   /* The broker can invalidate a chain after publish's first refresh, during
    * creation, attachment, acquisition or handoff. Only its known rejection
    * for this exact surface and a newly confirmed configuration can discard
    * that old frame. Unknown mutations and every other error stay failures;
    * retired chains keep their consumer/fence loans until ordinary collection. */
   if (reply->result != R4OS_WINDOW_GRAPHICS_OUT_OF_DATE) return error;
   if (memcmp(&reply->surface, &w->identity, sizeof(w->identity))) return EGL_BAD_ACCESS;
   if (!config_ok(&reply->config)) return EGL_BAD_MATCH;
   if (reply->config.revision <= revision) return error;
   EGLint rc = refresh(w);
   if (rc != EGL_SUCCESS) return rc;
   return w->config.revision >= reply->config.revision ? EGL_SUCCESS : error;
}
static EGLint publish(struct window *w, struct r4gl_sw_storage *input)
{
   struct storage *s = input->token;
   if (s->window != w) return EGL_BAD_NATIVE_WINDOW;
   EGLint rc = refresh(w);
   if (rc != EGL_SUCCESS) return rc;
   if (s->revision != w->config.revision || s->width != w->config.width || s->height != w->config.height) {
      /* Desktop may resize after EGL's geometry check but before this
       * refreshed publication. The exact live window has advanced: discard
       * the old frame and let EGL revalidate its drawable on the next frame.
       * Same-revision geometry corruption and future storage stay invalid. */
      return w->config.revision > s->revision ? EGL_SUCCESS : EGL_BAD_SURFACE;
   }
   unsigned mode = R4OS_WINDOW_GRAPHICS_MAILBOX;
   if (w->interval) {
      if (!r4gl_window_swap_limit(w->application, &w->config)) return EGL_BAD_MATCH;
      mode = R4OS_WINDOW_GRAPHICS_FIFO;
   } else if (!(w->config.present_modes & mode)) mode = R4OS_WINDOW_GRAPHICS_FIFO;
   uint64_t until = r4gl_native_now() + 1000000000ull;
   R4WindowGraphicsReply reply = {0};
   if ((rc = change_mode(w, mode, until, &reply)) != EGL_SUCCESS)
      return publication_error(w, s->revision, &reply, rc);
   if (!w->active && (rc = create_chain(w, mode, &reply)) != EGL_SUCCESS)
      return publication_error(w, s->revision, &reply, rc);
   struct chain *c = w->active;
   for (;;) {
      if (!issue(c, command(c, R4OS_WINDOW_GRAPHICS_ACQUIRE), &reply)) { retire(c); return EGL_BAD_ACCESS; }
      if (reply.result != R4OS_WINDOW_GRAPHICS_NOT_READY) break;
      if (r4gl_native_now() >= until) return EGL_BAD_ACCESS;
      r4gl_window_wait(w->application, &w->identity.owner, w->revision, 25000000ull);
   }
   if ((rc = result(reply.result)) != EGL_SUCCESS) {
      retire(c); return publication_error(w, s->revision, &reply, rc);
   }
   unsigned slot = reply.image_slot;
   if (!release_fence(c, slot)) { retire(c); return EGL_BAD_ACCESS; }
   R4GfxBufferMap map;
   uint64_t bytes = (uint64_t)s->width * s->height * 4;
   if (r4draw_gfx_buffer_map(&w->draw, &c->images[slot].reference, R4OS_GFX_BUFFER_MAP_WRITE, 0, bytes, &map) != 1) { retire(c); return EGL_BAD_ACCESS; }
   for (unsigned y = 0; y < s->height; y++)
      memcpy((char *)(uintptr_t)map.cpu_address + (size_t)y * s->width * 4,
         (char *)input->mapping + (size_t)y * input->stride, (size_t)s->width * 4);
   if (r4draw_gfx_buffer_unmap(&w->draw, &map.lease) != 1) abort();
   /* The CPU copy has ended. A real CPU-queue barrier records its completion;
    * WINSVC owns the immutable BO loan until its consumer returns the slot. */
   R4GfxSubmission submit = { .version = 1, .size = sizeof(submit), .operation = R4OS_GFX_QUEUE_OPERATION_BARRIER,
      .deadline_ns = r4gl_native_now() + 1000000000ull };
   R4GfxFenceStatus status;
   if (r4draw_gfx_queue_submit(&w->draw, &c->queue, &submit, &status) != 1) { retire(c); return EGL_BAD_ACCESS; }
   c->fences[slot] = status.fence;
   R4WindowGraphicsRequest request = command(c, R4OS_WINDOW_GRAPHICS_PRESENT);
   request.image_slot = slot; request.acquire_token = c->tokens[slot]; request.fence = status.fence;
   if (!issue(c, request, &reply)) { retire(c); return EGL_BAD_ACCESS; }
   rc = result(reply.result);
   if (rc != EGL_SUCCESS) {
      retire(c); return publication_error(w, s->revision, &reply, rc);
   }
   return rc;
}
static void present(void *value, struct r4gl_sw_storage *storage, void *context, unsigned count, const struct pipe_box *damage)
{
   (void)value; (void)count; (void)damage;
   struct window *w = context;
   lock(&w->gate); w->status = publish(w, storage); unlock(&w->gate);
}
static EGLint present_status(void *value, void *lease)
{
   (void)value; struct window *w = lease;
   lock(&w->gate); EGLint rc = w->status; w->status = EGL_SUCCESS; unlock(&w->gate); return rc;
}
static void close_host(void *value) { free(value); }
EGLint r4gl_egl_open_host(void *native_display, struct r4gl_egl_host *out)
{
   if (native_display) return EGL_BAD_DISPLAY;
   struct host *host = malloc(sizeof(*host)); if (!host) return EGL_BAD_ALLOC;
   if (!r4gl_native_application(&host->application, &host->draw)) { free(host); return EGL_NOT_INITIALIZED; }
   *out = (struct r4gl_egl_host){ .sw = {host, supports, allocate, release, present}, .close = close_host,
      .acquire_window = acquire_window, .release_window = release_window, .window_state = window_state, .present_status = present_status,
      .max_swap_interval = r4gl_window_swap_limit(host->application, NULL), .swap_interval = swap_interval,
      .window_loader = window_loader };
   return EGL_SUCCESS;
}
