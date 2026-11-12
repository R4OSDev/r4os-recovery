/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#define EGL_NO_PLATFORM_SPECIFIC_TYPES
#include "r4gl_state.h"
#include "r4gl_egl.h"
#include "r4gl_vulkan.h"
#include "gallium/drivers/zink/zink_public.h"
#include "gallium/drivers/zink/zink_screen.h"
#include "gallium/drivers/zink/zink_context.h"
#include "gallium/drivers/zink/zink_resource.h"
#include "gallium/drivers/zink/zink_kopper.h"
#include "r4vk_wsi.h"
#include "egl/main/eglarray.h"
#include "egl/main/eglconfig.h"
#include "egl/main/eglcontext.h"
#include "egl/main/eglcurrent.h"
#include "egl/main/egldriver.h"
#include "egl/main/eglimage.h"
#include "egl/main/eglsurface.h"
#include "egl/main/eglsync.h"
#include "frontend/api.h"
#include "frontend/sw_winsys.h"
#include "gallium/drivers/softpipe/sp_public.h"
#include "mesa/state_tracker/st_context.h"
#include "mesa/state_tracker/st_cb_texture.h"
#include "mesa/state_tracker/st_texture.h"
#include "mesa/state_tracker/st_format.h"
#include "mesa/main/texobj.h"
#include "mesa/main/renderbuffer.h"
#include "mesa/main/glthread.h"
#include "pipe/p_screen.h"
#include "util/u_atomic.h"
#include "util/u_inlines.h"
#include <limits.h>
#include <stddef.h>
#include <stdlib.h>

struct native_display {
   struct pipe_frontend_screen frontend;
   _EGLDisplay *egl;
   struct sw_winsys *winsys;
   struct r4gl_egl_host host;
   mtx_t gate;
   int references;
   uint32_t next_drawable;
   _EGLArray *retired_configs;
   bool zink, zink_window;
};
struct native_context {
   _EGLContext base;
   struct native_display *owner;
   struct st_context *st;
};
struct native_sync {
   _EGLSync base;
   struct native_display *owner;
   struct pipe_fence_handle *fence;
};
struct native_image {
   _EGLImage base;
   struct native_display *owner;
   struct st_egl_image storage;
};
struct native_surface {
   _EGLSurface base;
   struct native_display *owner;
   struct pipe_frontend_drawable drawable;
   struct st_visual visual;
   mtx_t gate;
   void *window;
   struct kopper_loader_info loader;
   struct pipe_resource *textures[ST_ATTACHMENT_COUNT];
   struct r4gl_egl_geometry storage;
   EGLint error;
};
static struct native_surface *surface_of(struct pipe_frontend_drawable *drawable)
{
   return (void *)((char *)drawable - offsetof(struct native_surface, drawable));
}
static struct pipe_frontend_drawable *drawable_of(_EGLSurface *surface)
{
   return surface ? &((struct native_surface *)surface)->drawable : NULL;
}
static struct st_context *context_of(_EGLContext *context)
{
   return context ? ((struct native_context *)context)->st : NULL;
}
static void display_put(struct native_display *display)
{
   if (!p_atomic_dec_zero(&display->references))
      return;
   st_screen_destroy(&display->frontend);
   if (display->frontend.screen)
      display->frontend.screen->destroy(display->frontend.screen);
   if (display->winsys)
      display->winsys->destroy(display->winsys);
   if (display->retired_configs)
      _eglDestroyArray(display->retired_configs, free);
   display->host.close(display->host.sw.owner);
   mtx_destroy(&display->gate);
   free(display);
}
static struct st_visual visual_for(_EGLConfig *config, bool double_buffer)
{
   return (struct st_visual) {
      .buffer_mask = ST_ATTACHMENT_FRONT_LEFT_MASK |
         (double_buffer ? ST_ATTACHMENT_BACK_LEFT_MASK : 0) |
         (config->DepthSize ? ST_ATTACHMENT_DEPTH_STENCIL_MASK : 0),
      .color_format = PIPE_FORMAT_B8G8R8A8_UNORM,
      .depth_stencil_format = config->DepthSize ? PIPE_FORMAT_Z24_UNORM_S8_UINT : PIPE_FORMAT_NONE,
      .accum_format = PIPE_FORMAT_NONE,
   };
}

/* EGL's resource loans cover the entire unlocked dispatcher call, including
 * the gap before entering this driver and after returning from it. Free only
 * when the last such loan and the native owner reference have been returned. */
static void sync_release(_EGLResource *resource)
{
   struct native_sync *sync = (void *)resource;
   struct native_display *display = sync->owner;
   if (sync->fence)
      display->frontend.screen->fence_reference(display->frontend.screen, &sync->fence, NULL);
   free(sync);
   display_put(display);
}
static bool sync_context(struct native_context *context)
{
   return context && context->st->ctx->Extensions.ARB_sync;
}
static _EGLSync *create_sync(_EGLDisplay *disp, EGLenum type, const EGLAttrib *attributes)
{
   struct native_display *display = disp->DriverData;
   struct native_context *context = (void *)_eglGetCurrentContext();
   if (type != EGL_SYNC_FENCE_KHR) {
      _eglError(EGL_BAD_PARAMETER, "R4GL sync type");
      return NULL;
   }
   if (!sync_context(context) || context->owner != display) {
      _eglError(EGL_BAD_MATCH, "R4GL sync context");
      return NULL;
   }
   struct native_sync *sync = calloc(1, sizeof(*sync));
   if (!sync) {
      _eglError(EGL_BAD_ALLOC, "R4GL sync");
      return NULL;
   }
   if (!_eglInitSync(&sync->base, disp, type, attributes)) {
      free(sync);
      return NULL;
   }
   sync->owner = display;
   /* Execute the real GL command stream and retain its Gallium fence.
    * Softpipe completes synchronously; asynchronous screens must supply
    * actual fence completion and server-ordering implementations. */
   r4gl_native_runtime_trace("egl-sync-before-flush");
   st_context_flush(context->st, 0, &sync->fence, NULL, NULL);
   r4gl_native_runtime_trace("egl-sync-after-flush");
   if (!sync->fence)
      goto fail;
   p_atomic_inc(&display->references);
   sync->base.Resource.R4OSRelease = sync_release;
   return &sync->base;
fail:
   free(sync);
   _eglError(EGL_BAD_ALLOC, "R4GL sync storage");
   return NULL;
}
static EGLBoolean destroy_sync(_EGLDisplay *disp, _EGLSync *base)
{
   (void)disp;
   _eglPutSync(base); /* Final release may instead happen in egl_relax_end. */
   return EGL_TRUE;
}
static bool sync_display_lost(struct native_display *display)
{
   return display->zink && zink_screen(display->frontend.screen)->device_lost;
}
static EGLint client_wait_sync(_EGLDisplay *disp, _EGLSync *base, EGLint flags, EGLTime timeout)
{
   (void)disp;
   struct native_sync *sync = (void *)base;
   struct native_context *context = (void *)_eglGetCurrentContext();
   if (sync_display_lost(sync->owner))
      return _eglError(EGL_CONTEXT_LOST, "R4GL sync device lost");
   if (context && (flags & EGL_SYNC_FLUSH_COMMANDS_BIT_KHR) &&
       p_atomic_read(&base->SyncStatus) != EGL_SIGNALED_KHR)
      st_context_flush(context->st, 0, NULL, NULL, NULL);
   struct pipe_context *pipe = context && context->owner == sync->owner ? context->st->pipe : NULL;
   struct pipe_screen *screen = sync->owner->frontend.screen;
   bool complete = screen->fence_finish(screen, pipe, sync->fence, timeout);
   if (sync_display_lost(sync->owner))
      return _eglError(EGL_CONTEXT_LOST, "R4GL sync device lost");
   if (complete)
      p_atomic_set(&base->SyncStatus, EGL_SIGNALED_KHR);
   return complete ? EGL_CONDITION_SATISFIED_KHR : EGL_TIMEOUT_EXPIRED_KHR;
}
static EGLint server_wait_sync(_EGLDisplay *disp, _EGLSync *base)
{
   (void)disp;
   struct native_sync *sync = (void *)base;
   struct native_context *context = (void *)_eglGetCurrentContext();
   if (!sync_context(context) || context->owner != sync->owner)
      return _eglError(EGL_BAD_MATCH, "R4GL server wait context");
   if (sync_display_lost(sync->owner))
      return _eglError(EGL_CONTEXT_LOST, "R4GL sync device lost");
   struct pipe_screen *screen = sync->owner->frontend.screen;
   struct pipe_context *pipe = context->st->pipe;
   bool complete = screen->fence_finish(screen, NULL, sync->fence, 0);
   if (sync_display_lost(sync->owner))
      return _eglError(EGL_CONTEXT_LOST, "R4GL server sync device lost");
   if (complete) {
      p_atomic_set(&base->SyncStatus, EGL_SIGNALED_KHR);
   } else if (pipe->fence_server_sync) {
      pipe->fence_server_sync(pipe, sync->fence, 0);
      if (sync_display_lost(sync->owner))
         return _eglError(EGL_CONTEXT_LOST, "R4GL server sync device lost");
   } else {
      return _eglError(EGL_BAD_MATCH, "R4GL server wait unavailable");
   }
   return EGL_TRUE;
}
static void image_release(_EGLResource *resource)
{
   struct native_image *image = (void *)resource;
   struct native_display *display = image->owner;
   pipe_resource_reference(&image->storage.texture, NULL);
   free(image);
   display_put(display);
}
static EGLBoolean destroy_image(_EGLDisplay *disp, _EGLImage *base)
{
   (void)disp;
   _eglPutImage(base);
   return EGL_TRUE;
}
/* Validate and acquire the storage under the same owner lock. A previous
 * validate callback is only a hint: the handle may have been deleted since. */
static bool get_image(struct pipe_frontend_screen *frontend, void *handle,
                      struct st_egl_image *out)
{
   struct native_display *display = (void *)frontend;
   simple_mtx_lock(&display->egl->Mutex);
   struct native_image *image = (void *)_eglLookupImage(handle, display->egl);
   bool valid = image && image->owner == display;
   if (valid) {
      *out = image->storage;
      out->texture = NULL;
      pipe_resource_reference(&out->texture, image->storage.texture);
   }
   simple_mtx_unlock(&display->egl->Mutex);
   return valid;
}
static bool validate_image(struct pipe_frontend_screen *frontend, void *handle)
{
   struct native_display *display = (void *)frontend;
   simple_mtx_lock(&display->egl->Mutex);
   struct native_image *image = (void *)_eglLookupImage(handle, display->egl);
   bool valid = image && image->owner == display;
   simple_mtx_unlock(&display->egl->Mutex);
   return valid;
}
static _EGLImage *create_image(_EGLDisplay *disp, _EGLContext *base, EGLenum target,
                              EGLClientBuffer buffer, const EGLint *attributes)
{
   struct native_display *display = disp->DriverData;
   struct native_context *context = (void *)base;
   GLenum gl_target;
   unsigned face = 0;
   switch (target) {
   case EGL_GL_TEXTURE_2D_KHR: gl_target = GL_TEXTURE_2D; break;
   case EGL_GL_TEXTURE_3D_KHR: gl_target = GL_TEXTURE_3D; break;
   case EGL_GL_RENDERBUFFER_KHR: gl_target = GL_RENDERBUFFER; break;
   case EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_X_KHR:
   case EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_X_KHR:
   case EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_Y_KHR:
   case EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_KHR:
   case EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_Z_KHR:
   case EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_KHR:
      gl_target = GL_TEXTURE_CUBE_MAP;
      face = target - EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_X_KHR;
      break;
   default:
      _eglError(EGL_BAD_PARAMETER, "R4GL image target");
      return NULL;
   }
   if (!base) {
      _eglError(EGL_BAD_CONTEXT, "R4GL image needs GL context");
      return NULL;
   }
   if (base->ClientAPI != EGL_OPENGL_API || context->owner != display) {
      _eglError(EGL_BAD_MATCH, "R4GL image context owner");
      return NULL;
   }
   _EGLImageAttribs attrs;
   if (!_eglParseImageAttribList(&attrs, disp, attributes))
      return NULL;
   if (attrs.ImagePreserved != EGL_FALSE && attrs.ImagePreserved != EGL_TRUE) {
      _eglError(EGL_BAD_PARAMETER, "R4GL image preservation");
      return NULL;
   }
   for (const EGLint *a = attributes; a && *a != EGL_NONE; a += 2) {
      if ((a[0] == EGL_GL_TEXTURE_LEVEL_KHR && gl_target == GL_RENDERBUFFER) ||
          (a[0] == EGL_GL_TEXTURE_ZOFFSET_KHR && gl_target != GL_TEXTURE_3D)) {
         _eglError(EGL_BAD_MATCH, "R4GL image attribute target");
         return NULL;
      }
   }
   uintptr_t name = (uintptr_t)buffer;
   if (!name || name > UINT_MAX) {
      _eglError(EGL_BAD_PARAMETER, "R4GL image object name");
      return NULL;
   }
   struct native_image *image = calloc(1, sizeof(*image));
   if (!image) {
      _eglError(EGL_BAD_ALLOC, "R4GL image storage");
      return NULL;
   }
   _eglInitImage(&image->base, disp);
   struct st_context *st = context->st;
   struct gl_context *ctx = st->ctx;
   EGLint error = EGL_BAD_PARAMETER;
   _mesa_glthread_finish(ctx);
   if (gl_target == GL_RENDERBUFFER) {
      struct gl_renderbuffer *rb = _mesa_lookup_renderbuffer(ctx, name);
      if (!rb || rb->NumSamples || !rb->texture || !rb->Width || !rb->Height)
         goto fail;
      if (p_atomic_cmpxchg(&rb->R4OSImageSibling, 0, 1) != 0) {
         error = EGL_BAD_ACCESS;
         goto fail;
      }
      pipe_resource_reference(&image->storage.texture, rb->texture);
      image->storage.internalformat = rb->InternalFormat;
      image->storage.format = rb->surface.format;
      image->storage.level = rb->surface.level;
      image->storage.layer = rb->surface.first_layer;
   } else {
      struct gl_texture_object *obj = _mesa_lookup_texture(ctx, name);
      if (!obj || obj->Target != gl_target)
         goto fail;
      if (attrs.GLTextureLevel < 0 || attrs.GLTextureLevel >= MAX_TEXTURE_LEVELS) {
         error = EGL_BAD_MATCH;
         goto fail;
      }
      _mesa_lock_texture(ctx, obj);
      _mesa_test_texobj_completeness(ctx, obj);
      bool complete = _mesa_is_texture_complete(obj, &obj->Sampler, false);
      if (!complete) {
         if (attrs.GLTextureLevel != 0 || !obj->_BaseComplete)
            goto fail_texture;
         /* The non-mipmapped exception requires only level zero to exist. */
         unsigned faces = gl_target == GL_TEXTURE_CUBE_MAP ? 6 : 1;
         for (unsigned f = 0; f < faces; f++)
            for (unsigned level = 1; level < MAX_TEXTURE_LEVELS; level++)
               if (obj->Image[f][level] && obj->Image[f][level]->Width)
                  goto fail_texture;
      }
      struct gl_texture_image *tex = obj->Image[face][attrs.GLTextureLevel];
      if (!tex || !tex->pt || !tex->Width || !tex->Height || tex->Border) {
         error = EGL_BAD_MATCH;
         goto fail_texture;
      }
      if (gl_target == GL_TEXTURE_3D &&
          (attrs.GLTextureZOffset < 0 || (unsigned)attrs.GLTextureZOffset >= tex->Depth))
         goto fail_texture;
      /* Consolidate before taking the external reference. A later sampler
       * validation must not silently move an exported mip into other storage. */
      if (!st_r4os_prepare_egl_image(ctx, obj, face, attrs.GLTextureLevel)) {
         error = EGL_BAD_ALLOC;
         goto fail_texture;
      }
      if (gl_target == GL_TEXTURE_3D) {
         unsigned slice = attrs.GLTextureZOffset;
         if (!tex->R4OSImageLayers) {
            tex->R4OSImageLayers = calloc((tex->Depth + 7) / 8, 1);
            if (!tex->R4OSImageLayers) {
               error = EGL_BAD_ALLOC;
               goto fail_texture;
            }
         }
         unsigned char mask = 1u << (slice % 8);
         if (tex->R4OSImageLayers[slice / 8] & mask) {
            error = EGL_BAD_ACCESS;
            goto fail_texture;
         }
         tex->R4OSImageLayers[slice / 8] |= mask;
      } else if (tex->R4OSImageSibling) {
         error = EGL_BAD_ACCESS;
         goto fail_texture;
      }
      tex->R4OSImageSibling = true;
      pipe_resource_reference(&image->storage.texture, tex->pt);
      image->storage.internalformat = tex->InternalFormat;
      image->storage.format = st_mesa_format_to_pipe_format(st, tex->TexFormat);
      image->storage.level = st_r4os_image_level(tex);
      image->storage.layer = st_r4os_image_layer(tex,
         gl_target == GL_TEXTURE_3D ? attrs.GLTextureZOffset : 0);
      _mesa_unlock_texture(ctx, obj);
      goto acquired;
fail_texture:
      _mesa_unlock_texture(ctx, obj);
      goto fail;
   }
acquired:
   /* KHR exports select one 2D image, including a cube face or a 3D slice. */
   image->storage.r4os_target = PIPE_TEXTURE_2D;
   if (st->pipe->flush_resource)
      st->pipe->flush_resource(st->pipe, image->storage.texture);
   st_context_flush(st, 0, NULL, NULL, NULL);
   ctx->Shared->HasExternallySharedImages = true;
   image->owner = display;
   p_atomic_inc(&display->references);
   image->base.Resource.R4OSRelease = image_release;
   return &image->base;
fail:
   free(image);
   _eglError(error, "R4GL image source");
   return NULL;
}
static EGLint geometry(struct native_surface *surface, struct r4gl_egl_geometry *out)
{
   if (!surface->window) {
      *out = (struct r4gl_egl_geometry) {
         .width = surface->base.Width, .height = surface->base.Height,
      };
      return EGL_SUCCESS;
   }
   struct native_display *display = surface->owner;
   EGLint error = display->host.window_state(display->host.sw.owner, surface->window, out);
   if (error == EGL_SUCCESS && (!out->width || !out->height ||
       out->width > (unsigned)surface->base.Config->MaxPbufferWidth ||
       out->height > (unsigned)surface->base.Config->MaxPbufferHeight))
      error = EGL_BAD_NATIVE_WINDOW;
   if (error == EGL_SUCCESS) {
      if (surface->base.Width != (EGLint)out->width || surface->base.Height != (EGLint)out->height)
         p_atomic_inc(&surface->drawable.stamp);
      surface->base.Width = out->width;
      surface->base.Height = out->height;
   }
   return error;
}
static bool fail_surface(struct native_surface *surface, EGLint error)
{
   if (surface->error == EGL_SUCCESS)
      surface->error = error;
   return false;
}
/* gate held. Allocation is transactional; failed resize preserves old buffers. */
static bool prepare(struct native_surface *surface, unsigned mask)
{
   struct r4gl_egl_geometry size;
   EGLint error = geometry(surface, &size);
   if (error != EGL_SUCCESS)
      return fail_surface(surface, error);
   bool resized = size.width != surface->storage.width || size.height != surface->storage.height ||
      size.revision != surface->storage.revision;
   struct pipe_screen *screen = surface->owner->frontend.screen;
   struct pipe_resource *pending[ST_ATTACHMENT_COUNT] = {0};
   bool kopper = surface->window && surface->owner->zink;
   bool front_alias = kopper && (surface->visual.buffer_mask & ST_ATTACHMENT_BACK_LEFT_MASK);
   if (front_alias && (mask & ST_ATTACHMENT_FRONT_LEFT_MASK))
      mask |= ST_ATTACHMENT_BACK_LEFT_MASK;
   /* A Kopper front resource receives its back resource as loader data.
    * Create the back first, including a transactional replacement on resize. */
   for (unsigned pass = 0; pass < ST_ATTACHMENT_COUNT; pass++) {
      unsigned i = pass == ST_ATTACHMENT_FRONT_LEFT ? ST_ATTACHMENT_BACK_LEFT :
         pass == ST_ATTACHMENT_BACK_LEFT ? ST_ATTACHMENT_FRONT_LEFT : pass;
      if (!(mask & (1u << i)) || (!resized && surface->textures[i]))
         continue;
      bool depth = i == ST_ATTACHMENT_DEPTH_STENCIL;
      struct pipe_resource template = {
         .target = PIPE_TEXTURE_2D,
         .format = depth ? surface->visual.depth_stencil_format : surface->visual.color_format,
         .width0 = MAX2(size.width, 1), .height0 = MAX2(size.height, 1),
         .depth0 = 1, .array_size = 1, .usage = PIPE_USAGE_DEFAULT,
         .bind = depth ? PIPE_BIND_DEPTH_STENCIL : PIPE_BIND_RENDER_TARGET,
      };
      if (surface->window && !depth) {
         void *loader = surface->window;
         if (front_alias && i == ST_ATTACHMENT_FRONT_LEFT) {
            loader = pending[ST_ATTACHMENT_BACK_LEFT] ? pending[ST_ATTACHMENT_BACK_LEFT] :
               surface->textures[ST_ATTACHMENT_BACK_LEFT];
            if (!loader) {
               for (unsigned j = 0; j < ST_ATTACHMENT_COUNT; j++)
                  pipe_resource_reference(&pending[j], NULL);
               return fail_surface(surface, EGL_BAD_ALLOC);
            }
         } else if (surface->owner->zink) {
            template.bind |= PIPE_BIND_DISPLAY_TARGET;
            error = surface->owner->host.window_loader(surface->owner->host.sw.owner,
               surface->window, &surface->loader);
            if (error != EGL_SUCCESS) {
               for (unsigned j = 0; j < ST_ATTACHMENT_COUNT; j++)
                  pipe_resource_reference(&pending[j], NULL);
               return fail_surface(surface, error);
            }
            loader = &surface->loader;
         } else {
            template.bind |= PIPE_BIND_DISPLAY_TARGET;
         }
         pending[i] = surface->owner->zink ? screen->resource_create_drawable(screen, &template, loader) :
            screen->resource_create_front(screen, &template, loader);
      } else {
         pending[i] = screen->resource_create(screen, &template);
      }
      if (!pending[i]) {
         for (unsigned j = 0; j < ST_ATTACHMENT_COUNT; j++)
            pipe_resource_reference(&pending[j], NULL);
         return fail_surface(surface, EGL_BAD_ALLOC);
      }
   }
   for (unsigned i = 0; i < ST_ATTACHMENT_COUNT; i++) {
      if (resized || pending[i]) {
         pipe_resource_reference(&surface->textures[i], NULL);
         surface->textures[i] = pending[i];
      }
   }
   surface->storage = size;
   if (resized)
      p_atomic_inc(&surface->drawable.stamp);
   return true;
}
static bool validate(struct st_context *st, struct pipe_frontend_drawable *drawable,
                     const enum st_attachment_type *attachments, unsigned count,
                     struct pipe_resource **out, struct pipe_resource **resolve)
{
   (void)st;
   struct native_surface *surface = surface_of(drawable);
   if (resolve)
      *resolve = NULL;
   if (count > ST_ATTACHMENT_COUNT)
      return false;
   unsigned mask = 0;
   for (unsigned i = 0; i < count; i++) {
      if ((unsigned)attachments[i] >= ST_ATTACHMENT_COUNT ||
          !(surface->visual.buffer_mask & (1u << attachments[i])))
         return false;
      mask |= 1u << attachments[i];
   }
   mtx_lock(&surface->gate);
   bool ok = prepare(surface, mask);
   if (ok)
      for (unsigned i = 0; i < count; i++)
         pipe_resource_reference(&out[i], surface->textures[attachments[i]]);
   mtx_unlock(&surface->gate);
   return ok;
}
static bool present(struct native_surface *surface, struct st_context *st,
                    enum st_attachment_type attachment)
{
   if (!surface->window)
      return true;
   struct native_display *display = surface->owner;
   struct r4gl_egl_geometry size;
   EGLint error = geometry(surface, &size);
   if (error != EGL_SUCCESS)
      return fail_surface(surface, error);
   bool obsolete = size.width != surface->storage.width ||
      size.height != surface->storage.height || size.revision != surface->storage.revision;
   if (obsolete) {
      /* Only the exact live window's confirmed advance can discard contents.
       * Corrupt same-revision geometry and future storage remain errors. */
      if (size.revision <= surface->storage.revision)
         return fail_surface(surface, EGL_BAD_SURFACE);
      p_atomic_inc(&surface->drawable.stamp);
      if (!display->zink)
         return true;
      /* A native image is still acquired and may have a present semaphore.
       * Submit its ordinary WSI handoff even when the old frame cannot be
       * displayed. WINSVC rejects the obsolete revision before publication,
       * and Kopper retains the exact submitted image until retirement. */
   }
   if (!surface->textures[attachment])
      return true; /* No rendering has allocated this attachment yet. */
   if (display->zink) {
      /* Complete Gallium's queued CPU work before touching its Kopper state.
       * This does not wait for GPU completion. */
      zink_tc_context_unwrap(st->pipe);
      if (zink_screen(display->frontend.screen)->device_lost)
         return fail_surface(surface, EGL_CONTEXT_LOST);
      if (!zink_kopper_check(surface->textures[attachment]))
         return fail_surface(surface, EGL_BAD_SURFACE);
      zink_kopper_set_swap_interval(display->frontend.screen,
         surface->textures[attachment], surface->base.SwapInterval);
      struct kopper_displaytarget *dt = zink_resource(surface->textures[attachment])->obj->dt;
      if (dt->r4os_result != VK_SUCCESS) {
         if (dt->r4os_result == VK_ERROR_DEVICE_LOST)
            return fail_surface(surface, EGL_CONTEXT_LOST);
         if (dt->r4os_result == VK_ERROR_OUT_OF_HOST_MEMORY ||
             dt->r4os_result == VK_ERROR_OUT_OF_DEVICE_MEMORY)
            return fail_surface(surface, EGL_BAD_ALLOC);
         return fail_surface(surface, dt->r4os_result == VK_TIMEOUT || dt->r4os_result == VK_NOT_READY ?
            EGL_BAD_ACCESS : EGL_BAD_SURFACE);
      }
   }
   display->frontend.screen->flush_frontbuffer(display->frontend.screen, st->pipe,
      surface->textures[attachment], 0, 0, surface->window, 0, NULL);
   if (display->zink) {
      if (zink_screen(display->frontend.screen)->device_lost)
         return fail_surface(surface, EGL_CONTEXT_LOST);
      struct kopper_displaytarget *dt = zink_resource(surface->textures[attachment])->obj->dt;
      if (!dt) return fail_surface(surface, EGL_BAD_SURFACE);
      switch (dt->r4os_result) {
      case VK_SUCCESS: case VK_SUBOPTIMAL_KHR: return true;
      case VK_ERROR_OUT_OF_DATE_KHR:
         /* The window may also advance during the WSI handoff. Validate that
          * exact change; unrelated OUT_OF_DATE failures are not success. */
         error = geometry(surface, &size);
         if (error != EGL_SUCCESS)
            return fail_surface(surface, error);
         if (size.revision <= surface->storage.revision)
            return fail_surface(surface, EGL_BAD_SURFACE);
         p_atomic_inc(&surface->drawable.stamp);
         return true;
      case VK_ERROR_DEVICE_LOST: return fail_surface(surface, EGL_CONTEXT_LOST);
      case VK_ERROR_OUT_OF_HOST_MEMORY: case VK_ERROR_OUT_OF_DEVICE_MEMORY:
         return fail_surface(surface, EGL_BAD_ALLOC);
      case VK_NOT_READY: case VK_TIMEOUT: return fail_surface(surface, EGL_BAD_ACCESS);
      default: return fail_surface(surface, EGL_BAD_SURFACE);
      }
   }
   error = display->host.present_status(display->host.sw.owner, surface->window);
   return error == EGL_SUCCESS || fail_surface(surface, error);
}
struct present_flush {
   struct native_surface *surface;
   struct st_context *st;
   enum st_attachment_type attachment;
};
static void before_present_flush(void *data)
{
   struct present_flush *args = data;
   struct native_surface *surface = args->surface;
   mtx_lock(&surface->gate);
   struct pipe_resource *texture = surface->textures[args->attachment];
   if (texture && surface->error == EGL_SUCCESS &&
       !zink_screen(surface->owner->frontend.screen)->device_lost) {
      /* Reject a lost timing promise before creating a present semaphore.
       * A subsequent interval-zero retry can submit the still-owned image. */
      EGLint error = surface->owner->host.swap_interval(surface->owner->host.sw.owner,
         surface->window, surface->base.SwapInterval);
      if (error == EGL_SUCCESS)
         args->st->pipe->flush_resource(args->st->pipe, texture);
      else
         fail_surface(surface, error);
   }
   mtx_unlock(&surface->gate);
}
static void flush_for_present(struct native_surface *surface, struct st_context *st,
                              enum st_attachment_type attachment, unsigned flags)
{
   /* Drain GL dispatch before taking the drawable lock: pending work can
    * validate it. Like Mesa's DRI frontend, mark the resource for presentation
    * after pending vertices, but before submitting the batch. Zink needs this
    * to transition the image and signal its presentation semaphore. */
   _mesa_glthread_finish(st->ctx);
   bool native = surface->window && surface->owner->zink;
   struct present_flush args = {surface, st, attachment};
   struct pipe_fence_handle *fence = NULL;
   st_context_flush(st, flags | (native ? 0 : ST_FLUSH_WAIT),
      native ? NULL : &fence, native ? before_present_flush : NULL, &args);
}
static bool flush_front(struct st_context *st, struct pipe_frontend_drawable *drawable,
                        enum st_attachment_type attachment)
{
   struct native_surface *surface = surface_of(drawable);
   if (attachment != ST_ATTACHMENT_FRONT_LEFT)
      return false;
   /* Do not request ST_FLUSH_FRONT here: this is already that callback. */
   flush_for_present(surface, st, attachment, 0);
   mtx_lock(&surface->gate);
   bool ok = surface->error == EGL_SUCCESS && present(surface, st, attachment);
   mtx_unlock(&surface->gate);
   return ok;
}
static void flush_wait(struct st_context *st, unsigned flags)
{
   _mesa_glthread_finish(st->ctx);
   struct pipe_fence_handle *fence = NULL;
   st_context_flush(st, flags | ST_FLUSH_WAIT, &fence, NULL, NULL);
}
static void context_release(_EGLResource *resource)
{
   struct native_context *context = (void *)resource;
   struct native_display *display = context->owner;
   mtx_lock(&display->gate);
   st_destroy_context(context->st);
   mtx_unlock(&display->gate);
   free(context);
   display_put(display);
}
static EGLBoolean destroy_context(_EGLDisplay *disp, _EGLContext *base)
{
   (void)disp;
   _eglPutContext(base);
   return EGL_TRUE;
}
static void surface_release(_EGLResource *resource)
{
   struct native_surface *surface = (void *)resource;
   struct native_display *display = surface->owner;
   mtx_lock(&display->gate);
   st_api_destroy_drawable(&surface->drawable);
   for (unsigned i = 0; i < ST_ATTACHMENT_COUNT; i++)
      pipe_resource_reference(&surface->textures[i], NULL);
   if (surface->window)
      display->host.release_window(display->host.sw.owner, surface->window);
   mtx_unlock(&display->gate);
   mtx_destroy(&surface->gate);
   free(surface);
   display_put(display);
}
static EGLBoolean destroy_surface(_EGLDisplay *disp, _EGLSurface *base)
{
   (void)disp;
   _eglPutSurface(base);
   return EGL_TRUE;
}
static void release_binding(_EGLContext *context, _EGLSurface *draw, _EGLSurface *read)
{
   destroy_surface(NULL, draw);
   destroy_surface(NULL, read);
   destroy_context(NULL, context);
}
static int get_param(struct pipe_frontend_screen *screen, enum st_manager_param param)
{
   (void)screen;
   /* Native geometry is polled on validation, viewport and swap. */
   return param == ST_MANAGER_BROKEN_INVALIDATE;
}
static EGLBoolean initialize(_EGLDisplay *disp)
{
   const bool zink = r4gl_native_profile() == 1;
   if ((disp->Options.Zink && !zink) ||
       (disp->Platform != _EGL_PLATFORM_R4OS && disp->Platform != _EGL_PLATFORM_SURFACELESS))
      return EGL_FALSE;
   struct native_display *display = calloc(1, sizeof(*display));
   if (!display)
      return _eglError(EGL_BAD_ALLOC, "R4GL display");
   if (mtx_init(&display->gate, mtx_plain) != thrd_success) {
      free(display);
      return _eglError(EGL_BAD_ALLOC, "R4GL display mutex");
   }
   EGLint error = r4gl_egl_open_host(disp->PlatformDisplay, &display->host);
   if (error != EGL_SUCCESS) {
      mtx_destroy(&display->gate);
      free(display);
      return _eglError(error, "R4GL native display");
   }
   display->references = 1;
   display->zink = zink;
   display->egl = disp;
   display->next_drawable = 1;
   display->frontend.get_param = get_param;
   display->frontend.get_egl_image = get_image;
   display->frontend.validate_egl_image = validate_image;
   if (!display->host.close || !display->host.acquire_window || !display->host.release_window ||
       !display->host.window_state || !display->host.present_status || !display->host.swap_interval ||
       display->host.max_swap_interval < 0 || display->host.max_swap_interval > 1) {
      if (display->host.close)
         display->host.close(display->host.sw.owner);
      mtx_destroy(&display->gate);
      free(display);
      return _eglError(EGL_NOT_INITIALIZED, "R4GL incomplete native host");
   }
   if (zink) {
      display->frontend.screen = zink_create_screen(NULL, NULL);
   } else {
      display->winsys = r4gl_sw_create(&display->host.sw);
      if (display->winsys)
         display->frontend.screen = softpipe_create_screen(display->winsys);
   }
   struct pipe_screen *screen = display->frontend.screen;
   if (!screen)
      goto fail;
   if (zink) {
      const struct zink_screen *zs = zink_screen(screen);
      if (!r4gl_native_vulkan_proc(zs->instance, R4VK_WINDOW_DRAIN_ENTRYPOINT))
         display->host.max_swap_interval = 0;
      display->zink_window = zs->info.have_KHR_swapchain && zs->info.have_KHR_swapchain_mutable_format &&
         r4gl_native_vulkan_proc(zs->instance, R4VK_WINDOW_SURFACE_ENTRYPOINT) && display->host.window_loader &&
         screen->resource_create_drawable && screen->flush_frontbuffer;
   }
   if (!screen->is_format_supported(screen, PIPE_FORMAT_B8G8R8A8_UNORM, PIPE_TEXTURE_2D,
          0, 0, PIPE_BIND_RENDER_TARGET | PIPE_BIND_DISPLAY_TARGET) ||
       !screen->is_format_supported(screen, PIPE_FORMAT_Z24_UNORM_S8_UINT, PIPE_TEXTURE_2D,
          0, 0, PIPE_BIND_DEPTH_STENCIL))
      goto fail;
   /* Keep an unsynchronized config available even when another output can
    * synchronize. A native window must match its selected config's default. */
   const int config_count = display->host.max_swap_interval ? 4 : 2;
   for (int i = 0; i < config_count; i++) {
      _EGLConfig *config = calloc(1, sizeof(*config));
      if (!config)
         goto fail;
      _eglInitConfig(config, disp, i + 1);
      config->BufferSize = 32;
      config->RedSize = config->GreenSize = config->BlueSize = config->AlphaSize = 8;
      config->DepthSize = (i & 1) ? 24 : 0;
      config->StencilSize = (i & 1) ? 8 : 0;
      config->SurfaceType = EGL_PBUFFER_BIT |
         ((!zink || display->zink_window) && disp->Platform == _EGL_PLATFORM_R4OS ? EGL_WINDOW_BIT : 0);
      config->RenderableType = EGL_OPENGL_BIT;
      config->ConfigCaveat = zink ? EGL_NONE : EGL_SLOW_CONFIG;
      config->MinSwapInterval = 0;
      config->MaxSwapInterval = i < 2 ? display->host.max_swap_interval : 0;
      config->MaxPbufferWidth = config->MaxPbufferHeight = screen->caps.max_texture_2d_size;
      uint64_t pixels = (uint64_t)config->MaxPbufferWidth * config->MaxPbufferHeight;
      config->MaxPbufferPixels = MIN2(pixels, INT_MAX);
      if (!_eglLinkConfig(config)) {
         free(config);
         goto fail;
      }
   }
   disp->ClientAPIs = EGL_OPENGL_BIT;
   disp->Extensions.KHR_create_context = EGL_TRUE;
   disp->Extensions.KHR_surfaceless_context = EGL_TRUE;
   disp->Extensions.KHR_fence_sync = EGL_TRUE;
   disp->Extensions.KHR_wait_sync = EGL_TRUE;
   disp->Extensions.KHR_image_base = EGL_TRUE;
   disp->Extensions.KHR_gl_colorspace = screen->is_format_supported(
      screen, PIPE_FORMAT_B8G8R8A8_SRGB, PIPE_TEXTURE_2D, 0, 0,
      PIPE_BIND_RENDER_TARGET | PIPE_BIND_DISPLAY_TARGET);
   disp->Extensions.KHR_gl_texture_2D_image = EGL_TRUE;
   disp->Extensions.KHR_gl_texture_cubemap_image = EGL_TRUE;
   disp->Extensions.KHR_gl_texture_3D_image = EGL_TRUE;
   disp->Extensions.KHR_gl_renderbuffer_image = EGL_TRUE;
   disp->DriverData = display;
   return EGL_TRUE;
fail:
   display->retired_configs = disp->Configs;
   disp->Configs = NULL;
   display_put(display);
   return _eglError(zink ? EGL_NOT_INITIALIZED : EGL_BAD_ALLOC, "R4GL backend screen");
}
static EGLBoolean terminate(_EGLDisplay *disp)
{
   struct native_display *display = disp->DriverData;
   _eglReleaseDisplayResources(disp);
   /* Current resources survive termination. Reinitialize creates a new owner;
    * old bound contexts never look through the new display's DriverData. */
   display->retired_configs = disp->Configs;
   disp->Configs = NULL;
   disp->DriverData = NULL;
   display_put(display);
   return EGL_TRUE;
}
static _EGLContext *create_context(_EGLDisplay *disp, _EGLConfig *config,
                                  _EGLContext *share, const EGLint *attributes)
{
   struct native_display *display = disp->DriverData;
   struct native_context *context = calloc(1, sizeof(*context));
   if (!context) {
      _eglError(EGL_BAD_ALLOC, "R4GL context");
      return NULL;
   }
   if (!_eglInitContext(&context->base, disp, config, share, attributes))
      goto fail;
   _EGLContext *base = &context->base;
   /* Optional robust/no-error/release-control modes are not admitted yet. */
   if (!config || base->ClientAPI != EGL_OPENGL_API || base->Protected || base->NoError ||
       (base->Flags & EGL_CONTEXT_OPENGL_ROBUST_ACCESS_BIT_KHR) ||
       base->ResetNotificationStrategy != EGL_NO_RESET_NOTIFICATION_KHR ||
       base->ReleaseBehavior != EGL_CONTEXT_RELEASE_BEHAVIOR_FLUSH_KHR ||
       (share && ((struct native_context *)share)->owner != display)) {
      _eglError(EGL_BAD_MATCH, "R4GL context profile");
      goto fail;
   }
   bool core = base->ClientMajorVersion > 3 ||
      (base->ClientMajorVersion == 3 && base->ClientMinorVersion >= 2);
   core = core && base->Profile == EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT_KHR;
   struct st_context_attribs request = {
      .profile = core ? API_OPENGL_CORE : API_OPENGL_COMPAT,
      .major = base->ClientMajorVersion, .minor = base->ClientMinorVersion,
      .visual = visual_for(config, true),
      .flags = ((base->Flags & EGL_CONTEXT_OPENGL_DEBUG_BIT_KHR) ? ST_CONTEXT_FLAG_DEBUG : 0) |
         ((base->Flags & EGL_CONTEXT_OPENGL_FORWARD_COMPATIBLE_BIT_KHR) ? ST_CONTEXT_FLAG_FORWARD_COMPATIBLE : 0),
   };
   enum st_context_error error;
   mtx_lock(&display->gate);
   context->st = st_api_create_context(&display->frontend, &request, &error, context_of(share));
   mtx_unlock(&display->gate);
   if (!context->st) {
      _eglError(error == ST_CONTEXT_ERROR_BAD_VERSION ? EGL_BAD_MATCH : EGL_BAD_ALLOC,
         "R4GL Mesa context");
      goto fail;
   }
   context->owner = display;
   p_atomic_inc(&display->references);
   base->Resource.R4OSRelease = context_release;
   return base;
fail:
   free(context);
   return NULL;
}
static _EGLSurface *create_surface(_EGLDisplay *disp, _EGLConfig *config,
                                  EGLint type, void *window, const EGLint *attributes)
{
   struct native_display *display = disp->DriverData;
   struct native_surface *surface = calloc(1, sizeof(*surface));
   EGLint error = EGL_BAD_ALLOC;
   if (!surface) {
      _eglError(error, "R4GL surface");
      return NULL;
   }
   if (!_eglInitSurface(&surface->base, disp, type, config, attributes, window)) {
      free(surface);
      return NULL;
   }
   if (mtx_init(&surface->gate, mtx_plain) != thrd_success) {
      free(surface);
      _eglError(error, "R4GL surface mutex");
      return NULL;
   }
   surface->owner = display;
   surface->error = EGL_SUCCESS;
   bool double_buffer = type == EGL_WINDOW_BIT;
   surface->visual = visual_for(config, double_buffer);
   if (surface->base.GLColorspace == EGL_GL_COLORSPACE_SRGB_KHR)
      surface->visual.color_format = PIPE_FORMAT_B8G8R8A8_SRGB;
   surface->base.ActiveRenderBuffer = surface->base.RequestedRenderBuffer =
      double_buffer ? EGL_BACK_BUFFER : EGL_SINGLE_BUFFER;
   surface->base.SwapInterval = config->MaxSwapInterval;
   if (type == EGL_WINDOW_BIT) {
      error = display->host.acquire_window(display->host.sw.owner, window, &surface->window);
      if (error != EGL_SUCCESS)
         goto fail;
      if (!surface->window) {
         error = EGL_BAD_NATIVE_WINDOW;
         goto fail;
      }
      error = display->host.swap_interval(display->host.sw.owner, surface->window, surface->base.SwapInterval);
      if (error != EGL_SUCCESS)
         goto fail;
      struct r4gl_egl_geometry size;
      error = geometry(surface, &size);
      if (error != EGL_SUCCESS)
         goto fail;
   } else if (surface->base.Width > config->MaxPbufferWidth ||
              surface->base.Height > config->MaxPbufferHeight ||
              (uint64_t)surface->base.Width * surface->base.Height > (unsigned)config->MaxPbufferPixels) {
      error = EGL_BAD_ALLOC;
      goto fail;
   }
   mtx_lock(&display->gate);
   uint32_t id = display->next_drawable;
   if (id)
      display->next_drawable++;
   mtx_unlock(&display->gate);
   if (!id) {
      error = EGL_BAD_ALLOC;
      goto fail;
   }
   surface->drawable = (struct pipe_frontend_drawable) {
      .stamp = 1, .ID = id, .fscreen = &display->frontend, .visual = &surface->visual,
      .validate = validate, .flush_front = flush_front,
   };
   p_atomic_inc(&display->references);
   surface->base.Resource.R4OSRelease = surface_release;
   return &surface->base;
fail:
   if (surface->window)
      display->host.release_window(display->host.sw.owner, surface->window);
   mtx_destroy(&surface->gate);
   free(surface);
   _eglError(error, "R4GL native surface");
   return NULL;
}
static _EGLSurface *create_window(_EGLDisplay *disp, _EGLConfig *config, void *window, const EGLint *attributes)
{
   return create_surface(disp, config, EGL_WINDOW_BIT, window, attributes);
}
static _EGLSurface *create_pbuffer(_EGLDisplay *disp, _EGLConfig *config, const EGLint *attributes)
{
   return create_surface(disp, config, EGL_PBUFFER_BIT, NULL, attributes);
}
static _EGLSurface *create_pixmap(_EGLDisplay *disp, _EGLConfig *config, void *pixmap, const EGLint *attributes)
{
   (void)disp; (void)config; (void)pixmap; (void)attributes;
   _eglError(EGL_BAD_MATCH, "R4GL pixmap unsupported");
   return NULL;
}
static bool prepare_binding(_EGLSurface *base)
{
   if (!base)
      return true;
   struct native_surface *surface = (void *)base;
   mtx_lock(&surface->gate);
   unsigned mask = surface->visual.buffer_mask;
   if (mask & ST_ATTACHMENT_BACK_LEFT_MASK)
      mask &= ~ST_ATTACHMENT_FRONT_LEFT_MASK;
   bool ok = prepare(surface, mask);
   EGLint error = surface->error;
   if (!ok)
      surface->error = EGL_SUCCESS;
   mtx_unlock(&surface->gate);
   if (!ok)
      _eglError(error, "R4GL framebuffer");
   return ok;
}
static EGLBoolean make_current(_EGLDisplay *disp, _EGLSurface *draw, _EGLSurface *read, _EGLContext *context)
{
   (void)disp;
   _EGLContext *previous = _eglGetCurrentContext();
   struct native_display *a = previous ? ((struct native_context *)previous)->owner : NULL;
   struct native_display *b = context ? ((struct native_context *)context)->owner : NULL;
   if ((uintptr_t)a > (uintptr_t)b) {
      struct native_display *swap = a; a = b; b = swap;
   }
   if (a) mtx_lock(&a->gate);
   if (b && b != a) mtx_lock(&b->gate);
   _EGLContext *old_context = NULL, *failed_context = NULL;
   _EGLSurface *old_draw = NULL, *old_read = NULL, *failed_draw = NULL, *failed_read = NULL;
   EGLBoolean ok = _eglBindContext(context, draw, read, &old_context, &old_draw, &old_read);
   if (ok) {
      ok = prepare_binding(draw) && (read == draw || prepare_binding(read));
      if (ok && !st_api_make_current(context_of(context), drawable_of(draw), drawable_of(read))) {
         _eglError(EGL_BAD_ALLOC, "R4GL make current");
         ok = EGL_FALSE;
      }
      if (!ok) {
         bool restored = _eglBindContext(old_context, old_draw, old_read,
            &failed_context, &failed_draw, &failed_read);
         if (restored)
            restored = st_api_make_current(context_of(old_context), drawable_of(old_draw), drawable_of(old_read));
         if (!restored) {
            /* Rollback allocation can also fail. Leave both dispatchers unbound. */
            _EGLContext *lost_context;
            _EGLSurface *lost_draw, *lost_read;
            _eglBindContext(NULL, NULL, NULL, &lost_context, &lost_draw, &lost_read);
            st_api_make_current(NULL, NULL, NULL);
            if (b && b != a) mtx_unlock(&b->gate);
            if (a) mtx_unlock(&a->gate);
            release_binding(lost_context, lost_draw, lost_read);
            release_binding(old_context, old_draw, old_read);
            release_binding(failed_context, failed_draw, failed_read);
            return _eglError(EGL_CONTEXT_LOST, "R4GL binding rollback");
         }
      }
   }
   if (b && b != a) mtx_unlock(&b->gate);
   if (a) mtx_unlock(&a->gate);
   release_binding(old_context, old_draw, old_read);
   release_binding(failed_context, failed_draw, failed_read);
   return ok;
}
static EGLBoolean query_surface(_EGLDisplay *disp, _EGLSurface *base, EGLint attribute, EGLint *value)
{
   struct native_surface *surface = (void *)base;
   struct r4gl_egl_geometry size;
   mtx_lock(&surface->gate);
   EGLint error = geometry(surface, &size);
   EGLBoolean result = error == EGL_SUCCESS ? _eglQuerySurface(disp, base, attribute, value) : EGL_FALSE;
   mtx_unlock(&surface->gate);
   return error == EGL_SUCCESS ? result : _eglError(error, "R4GL query geometry");
}
static EGLBoolean swap_interval(_EGLDisplay *disp, _EGLSurface *surface, EGLint interval)
{
   (void)disp;
   struct native_surface *native = (void *)surface;
   mtx_lock(&native->gate);
   EGLint error = native->owner->host.swap_interval(native->owner->host.sw.owner, native->window, interval);
   mtx_unlock(&native->gate);
   return error == EGL_SUCCESS ? EGL_TRUE : _eglError(error, "R4GL swap interval");
}
static EGLBoolean swap_buffers(_EGLDisplay *disp, _EGLSurface *base)
{
   (void)disp;
   struct native_surface *surface = (void *)base;
   struct st_context *st = context_of(_eglGetCurrentContext());
   if (!st)
      return _eglError(EGL_BAD_CONTEXT, "R4GL swap context");
   flush_for_present(surface, st, ST_ATTACHMENT_BACK_LEFT, ST_FLUSH_END_OF_FRAME);
   mtx_lock(&surface->gate);
   bool ok = surface->error == EGL_SUCCESS && present(surface, st, ST_ATTACHMENT_BACK_LEFT);
   EGLint error = surface->error;
   surface->error = EGL_SUCCESS;
   if (ok) {
      /* Kopper's back resource follows its Vulkan swapchain. Until a front
       * read/draw has requested another resource, keep that back resource:
       * exchanging it with NULL needlessly creates another Kopper drawable.
       * Software surfaces still exchange their CPU buffers. */
      if (!surface->window || !surface->owner->zink ||
          surface->textures[ST_ATTACHMENT_FRONT_LEFT]) {
         struct pipe_resource *front = surface->textures[ST_ATTACHMENT_FRONT_LEFT];
         surface->textures[ST_ATTACHMENT_FRONT_LEFT] = surface->textures[ST_ATTACHMENT_BACK_LEFT];
         surface->textures[ST_ATTACHMENT_BACK_LEFT] = front;
      }
      p_atomic_inc(&surface->drawable.stamp);
   }
   mtx_unlock(&surface->gate);
   st_invalidate_buffers(st);
   return ok ? EGL_TRUE : _eglError(error, "R4GL present");
}
static EGLBoolean wait_client(_EGLDisplay *disp, _EGLContext *context)
{
   (void)disp;
   flush_wait(context_of(context), ST_FLUSH_FRONT);
   if (context->DrawSurface) {
      struct native_surface *surface = (void *)context->DrawSurface;
      mtx_lock(&surface->gate);
      EGLint error = surface->error;
      surface->error = EGL_SUCCESS;
      mtx_unlock(&surface->gate);
      if (error != EGL_SUCCESS)
         return _eglError(error, "R4GL client flush");
   }
   return EGL_TRUE;
}
static EGLBoolean wait_native(EGLint engine)
{
   return engine == EGL_CORE_NATIVE_ENGINE ? EGL_TRUE : _eglError(EGL_BAD_PARAMETER, "R4GL native engine");
}
static EGLBoolean texture_image(_EGLDisplay *disp, _EGLSurface *surface, EGLint buffer)
{
   (void)disp; (void)surface; (void)buffer;
   return _eglError(EGL_BAD_MATCH, "R4GL surface texture unsupported");
}
static EGLBoolean copy_buffers(_EGLDisplay *disp, _EGLSurface *surface, void *target)
{
   (void)disp; (void)surface; (void)target;
   return _eglError(EGL_BAD_NATIVE_PIXMAP, "R4GL pixmap unsupported");
}
const _EGLDriver _eglDriver = {
   .Initialize = initialize, .Terminate = terminate,
   .CreateContext = create_context, .DestroyContext = destroy_context, .MakeCurrent = make_current,
   .CreateWindowSurface = create_window, .CreatePbufferSurface = create_pbuffer,
   .CreatePixmapSurface = create_pixmap, .DestroySurface = destroy_surface, .QuerySurface = query_surface,
   .SwapInterval = swap_interval, .SwapBuffers = swap_buffers,
   .WaitClient = wait_client, .WaitNative = wait_native,
   .BindTexImage = texture_image, .ReleaseTexImage = texture_image, .CopyBuffers = copy_buffers,
   .CreateSyncKHR = create_sync, .DestroySyncKHR = destroy_sync,
   .ClientWaitSyncKHR = client_wait_sync,
   .WaitSyncKHR = server_wait_sync,
   .CreateImageKHR = create_image, .DestroyImageKHR = destroy_image,
};
