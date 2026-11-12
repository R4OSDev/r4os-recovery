/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4nak_libc.h"
#include "../../R4NAK/ThirdParty/stb/stb_sprintf.h"
#ifdef R4NATIVE_FILE_IO
#include "files.h"
#include <c11/threads.h>
#endif

/* Console identities never retain an application's output handle. The base
 * profile supplies caller-serialized memory streams. R4NATIVE_FILE_IO adds
 * process-owned stream locks and native path-based files; no host FILE or
 * shared-library list of caller buffers is used. */
struct r4nak_file {
   unsigned console;
   char *bytes;
   size_t position, length, capacity;
   char **out_bytes;
   size_t *out_length;
   bool failed;
#ifdef R4NATIVE_FILE_IO
   bool eof, closed, readable, writable;
   unsigned mode;
   char *path;
   mtx_t mutex;
   struct r4nak_file *next;
#endif
};
static struct r4nak_file out_stream = {.console = 1}, err_stream = {.console = 2};
FILE *stdout = &out_stream;
FILE *stderr = &err_stream;
extern int32_t r4native_console_write(const char *, uint32_t);

#ifdef R4NATIVE_FILE_IO
static struct r4nak_file in_stream = {.console = 3};
FILE *stdin = &in_stream;
enum { STDIO_EMPTY, STDIO_INITIALIZING, STDIO_READY, STDIO_CLOSING, STDIO_CLOSED, STDIO_FINISHING };
struct stdio_state { mtx_t mutex; FILE streams[3]; FILE *files; unsigned phase; int finish_result; };
static const char stdio_key;
static void initialize_stdio(void *pointer) { memset(pointer, 0, sizeof(struct stdio_state)); }
static bool prepare_stdio(struct stdio_state *s)
{
   if (mtx_init(&s->mutex, mtx_plain) != thrd_success) return false;
   unsigned i = 0;
   for (; i < 3; i++) {
      if (mtx_init(&s->streams[i].mutex, mtx_plain) != thrd_success) break;
      s->streams[i].console = i + 1;
      s->streams[i].readable = i == 0;
      s->streams[i].writable = i != 0;
   }
   if (i != 3) {
      while (i) mtx_destroy(&s->streams[--i].mutex);
      mtx_destroy(&s->mutex); return false;
   }
   return true;
}
static struct stdio_state *stdio_state(void)
{
   struct stdio_state *s = r4native_stdio_state(&stdio_key, sizeof(*s), _Alignof(struct stdio_state), initialize_stdio);
   if (!s) { errno = R4N_ENOMEM; return NULL; }
   while (__atomic_load_n(&s->phase, __ATOMIC_ACQUIRE) != STDIO_READY) {
      if (__atomic_load_n(&s->phase, __ATOMIC_ACQUIRE) >= STDIO_CLOSING) { errno = R4N_EBADF; return NULL; }
      unsigned expected = 0;
      if (__atomic_compare_exchange_n(&s->phase, &expected, 1, false, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
         bool ready = prepare_stdio(s);
         __atomic_store_n(&s->phase, ready ? 2 : 0, __ATOMIC_RELEASE);
         if (!ready) { errno = R4N_ENOMEM; return NULL; }
      } else thrd_yield();
   }
   return s;
}
static FILE *lock_file(FILE *file)
{
   if (!file) { errno = R4N_EINVAL; return NULL; }
   if (file == stdin || file == stdout || file == stderr) {
      struct stdio_state *s = stdio_state(); if (!s) return NULL;
      file = &s->streams[file == stdin ? 0 : file == stdout ? 1 : 2];
   }
   if (mtx_lock(&file->mutex) != thrd_success) { errno = R4N_EIO; return NULL; }
   return file;
}
static void unlock_file(FILE *file) { if (mtx_unlock(&file->mutex) != thrd_success) abort(); }
static bool register_file(FILE *file)
{
   struct stdio_state *s = stdio_state(); if (!s) return false;
   if (mtx_init(&file->mutex, mtx_plain) != thrd_success) { errno = R4N_ENOMEM; return false; }
   if (mtx_lock(&s->mutex) != thrd_success) { mtx_destroy(&file->mutex); errno = R4N_EIO; return false; }
   file->next = s->files; s->files = file;
   if (mtx_unlock(&s->mutex) != thrd_success) abort();
   return true;
}
static void unregister_file(FILE *file)
{
   struct stdio_state *s = stdio_state(); if (!s || mtx_lock(&s->mutex) != thrd_success) abort();
   FILE **link = &s->files;
   while (*link && *link != file) link = &(*link)->next;
   if (*link != file) abort();
   *link = file->next;
   if (mtx_unlock(&s->mutex) != thrd_success) abort();
}
#else
static FILE *lock_file(FILE *file) { return file; }
static void unlock_file(FILE *file) { (void)file; }
#endif

static bool is_console(FILE *file) { return file->console != 0; }
static size_t write_console(FILE *file, const char *data, size_t bytes)
{
   size_t written = 0;
   while (written < bytes) {
      uint32_t chunk = bytes - written > INT_MAX ? INT_MAX : bytes - written;
#ifdef R4NATIVE_FILE_IO
      int32_t result = r4native_stream_write(file->console - 1, data + written, chunk);
      if (result < 0) errno = -result;
#else
      (void)file;
      int32_t result = r4native_console_write(data + written, chunk);
#endif
      if (result <= 0 || (uint32_t)result > chunk) break;
      written += result;
   }
   return written;
}
struct print_context { char buffer[STB_SPRINTF_MIN]; FILE *file; bool failed; };
static size_t write_bytes(const void *, size_t, size_t, FILE *);
static char *print_chunk(const char *bytes, void *user, int count)
{
   struct print_context *ctx = user;
   if (write_bytes(bytes, 1, count, ctx->file) != (size_t)count) {
      ctx->failed = true;
      return NULL;
   }
   return ctx->buffer;
}
int vfprintf(FILE *file, const char *format, va_list args)
{
   file = lock_file(file); if (!file) return EOF;
   struct print_context ctx = {.file = file};
   int result = stbsp_vsprintfcb(print_chunk, &ctx, ctx.buffer, format, args);
   unlock_file(file); return ctx.failed ? EOF : result;
}
int fprintf(FILE *file, const char *format, ...)
{
   va_list args;
   va_start(args, format);
   int result = vfprintf(file, format, args);
   va_end(args);
   return result;
}
int vprintf(const char *format, va_list args) { return vfprintf(stdout, format, args); }
int printf(const char *format, ...)
{
   va_list args;
   va_start(args, format);
   int result = vprintf(format, args);
   va_end(args);
   return result;
}
static size_t write_bytes(const void *data, size_t size, size_t count, FILE *file)
{
   if (!file || !size || !count) return 0;
#ifdef R4NATIVE_FILE_IO
   if (file->closed || !file->writable) { file->failed = true; errno = R4N_EBADF; return 0; }
#endif
   if (count > SIZE_MAX / size) {
#ifdef R4NATIVE_FILE_IO
      file->failed = true;
      errno = R4N_EOVERFLOW;
#else
      if (!is_console(file)) file->failed = true;
#endif
      return 0;
   }
   const size_t bytes = size * count;
   if (is_console(file)) {
      size_t n = write_console(file, data, bytes);
#ifdef R4NATIVE_FILE_IO
      if (n != bytes) file->failed = true;
#endif
      return n / size;
   }
#ifdef R4NATIVE_FILE_IO
   if (file->path) {
      size_t written = 0;
      while (written < bytes) {
         uint32_t chunk = bytes - written > INT_MAX ? INT_MAX : bytes - written;
         if (chunk > (size_t)LONG_MAX - file->position) { errno = R4N_EOVERFLOW; break; }
         int64_t n = r4native_file_write(file->path, file->position, (const char *)data + written, chunk, file->mode);
         if (n < 0) { errno = -n; break; }
         if (!n || n > chunk) { errno = R4N_EIO; break; }
         written += n; file->position += n;
         if (file->mode & R4NATIVE_FILE_APPEND) {
            uint64_t length; int rc = r4native_file_size(file->path, &length);
            if (rc || length > LONG_MAX) { errno = rc ? -rc : R4N_EOVERFLOW; file->failed = true; break; }
            file->position = length;
         }
      }
      if (written != bytes) file->failed = true;
      return written / size;
   }
#endif
   if (bytes > (size_t)LONG_MAX - file->position) {
      file->failed = true;
#ifdef R4NATIVE_FILE_IO
      errno = R4N_EOVERFLOW;
#endif
      return 0;
   }
   const size_t end = file->position + bytes;
   if (end + 1 > file->capacity) {
      size_t capacity = file->capacity <= SIZE_MAX / 2 ? file->capacity * 2 : end + 1;
      if (capacity < end + 1) capacity = end + 1;
      char *replacement = realloc(file->bytes, capacity);
      if (!replacement) {
         file->failed = true;
#ifdef R4NATIVE_FILE_IO
         errno = R4N_ENOMEM;
#endif
         return 0;
      }
      file->bytes = replacement;
      file->capacity = capacity;
   }
   if (file->position > file->length)
      memset(file->bytes + file->length, 0, file->position - file->length);
   memcpy(file->bytes + file->position, data, bytes);
   file->position = end;
   if (end > file->length) file->length = end;
   file->bytes[file->length] = 0;
   return count;
}
size_t fwrite(const void *data, size_t size, size_t count, FILE *file)
{
   file = lock_file(file); if (!file) return 0;
   size_t result = write_bytes(data, size, count, file);
   unlock_file(file); return result;
}
int fputs(const char *text, FILE *file)
{
   size_t bytes = strlen(text);
   return fwrite(text, 1, bytes, file) == bytes ? 0 : EOF;
}
int fputc(int value, FILE *file)
{
   unsigned char byte = value;
   return fwrite(&byte, 1, 1, file) == 1 ? byte : EOF;
}
int putchar(int value) { return fputc(value, stdout); }
int puts(const char *text) { return fputs(text, stdout) == EOF ? EOF : fputc('\n', stdout); }
FILE *open_memstream(char **bytes, size_t *length)
{
   if (!bytes || !length) {
#ifdef R4NATIVE_FILE_IO
      errno = R4N_EINVAL;
#endif
      return NULL;
   }
   FILE *file = calloc(1, sizeof(*file));
   if (!file) goto no_memory;
   file->bytes = malloc(1);
   if (!file->bytes) { free(file); goto no_memory; }
   file->bytes[0] = 0;
   file->capacity = 1;
   file->out_bytes = bytes;
   file->out_length = length;
#ifdef R4NATIVE_FILE_IO
   file->writable = true;
   if (!register_file(file)) { free(file->bytes); free(file); return NULL; }
#endif
   *bytes = file->bytes;
   *length = 0;
   return file;
no_memory:
#ifdef R4NATIVE_FILE_IO
   errno = R4N_ENOMEM;
#endif
   return NULL;
}
static int flush_file(FILE *file)
{
   /* The base profile only flushes explicit streams; the native file profile
    * implements fflush(NULL) through its process-owned registry below. */
   if (!file) return EOF;
#ifdef R4NATIVE_FILE_IO
   if (file->closed) { errno = R4N_EBADF; return EOF; }
   /* Native writes have no C buffer: the SDK operation has already ended.
    * This does not claim a stronger fsync/disk durability contract. */
   if (file->path || is_console(file)) return file->failed ? EOF : 0;
#else
   if (is_console(file)) return 0;
#endif
   *file->out_bytes = file->bytes;
   *file->out_length = file->position < file->length ? file->position : file->length;
   return file->failed ? EOF : 0;
}
int fflush(FILE *file)
{
#ifdef R4NATIVE_FILE_IO
   if (!file) {
      struct stdio_state *s = stdio_state(); if (!s) return EOF;
      if (mtx_lock(&s->mutex) != thrd_success) { errno = R4N_EIO; return EOF; }
      int result = 0;
      for (FILE *f = s->files; f; f = f->next) {
         if (!lock_file(f)) { result = EOF; continue; }
         if (flush_file(f)) result = EOF;
         unlock_file(f);
      }
      if (mtx_unlock(&s->mutex) != thrd_success) abort();
      return result;
   }
#endif
   file = lock_file(file); if (!file) return EOF;
   int result = flush_file(file); unlock_file(file); return result;
}
int fclose(FILE *file)
{
#ifdef R4NATIVE_FILE_IO
   if (!file) { errno = R4N_EINVAL; return EOF; }
   bool standard = file == stdin || file == stdout || file == stderr;
   if (!standard) unregister_file(file); /* registry precedes stream lock */
   file = lock_file(file); if (!file) return EOF;
   int result = flush_file(file);
   file->closed = true;
   unlock_file(file);
   if (standard) return result;
   mtx_destroy(&file->mutex); free(file->path);
#else
   if (!file || is_console(file)) return EOF;
   int result = flush_file(file);
#endif
   /* The caller owns the published buffer even after a failed write. */
   free(file);
   return result;
}
#ifdef R4NATIVE_FILE_IO
int r4native_stdio_finish(void)
{
   struct stdio_state *s = r4native_stdio_state(&stdio_key, sizeof(*s), _Alignof(struct stdio_state), initialize_stdio);
   if (!s) { errno = R4N_ENOMEM; return EOF; }
   unsigned phase = __atomic_load_n(&s->phase, __ATOMIC_ACQUIRE);
   for (;;) {
      if (phase == STDIO_CLOSED) return s->finish_result;
      if (phase == STDIO_INITIALIZING || phase == STDIO_FINISHING) { errno = R4N_EBUSY; return EOF; }
      unsigned next = phase == STDIO_EMPTY ? STDIO_CLOSED : STDIO_FINISHING;
      if (__atomic_compare_exchange_n(&s->phase, &phase, next, false, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
         if (next == STDIO_CLOSED) return s->finish_result;
         break;
      }
   }
   // The owning runtime has quiesced all stream users. Keep each record until
   // its mutex is retired, so an incomplete close can retry the same identity.
   while (s->files) {
      FILE *file = s->files;
      if (!lock_file(file)) goto retry;
      if (flush_file(file)) s->finish_result = R4NATIVE_STDIO_IO_ERROR;
      unlock_file(file);
      if (r4native_mutex_close(&file->mutex) != thrd_success) goto retry;
      s->files = file->next;
      free(file->path);
      free(file); // open_memstream output remains caller-owned.
   }
   for (unsigned i = 0; i < 3; i++) {
      FILE *file = &s->streams[i];
      if (!file->closed) {
         if (!lock_file(file)) goto retry;
         if (flush_file(file)) s->finish_result = R4NATIVE_STDIO_IO_ERROR;
         file->closed = true;
         unlock_file(file);
      }
      if (r4native_mutex_close(&file->mutex) != thrd_success) goto retry;
   }
   if (r4native_mutex_close(&s->mutex) != thrd_success) goto retry;
   __atomic_store_n(&s->phase, STDIO_CLOSED, __ATOMIC_RELEASE);
   return s->finish_result;
retry:
   errno = R4N_EIO;
   __atomic_store_n(&s->phase, STDIO_CLOSING, __ATOMIC_RELEASE);
   return EOF;
}
#endif
int ferror(FILE *file) {
   file = lock_file(file); if (!file) return 0;
   int value = file->failed; unlock_file(file); return value;
}
long ftell(FILE *file)
{
   file = lock_file(file); if (!file) return -1;
   long result = !is_console(file) && file->position <= LONG_MAX ? (long)file->position : -1;
#ifdef R4NATIVE_FILE_IO
   if (file->closed) { errno = R4N_EBADF; result = -1; }
   else if (is_console(file)) errno = R4N_ESPIPE;
#endif
   unlock_file(file); return result;
}
static int seek_file(FILE *file, long offset, int origin)
{
   if (!file || is_console(file) || origin < SEEK_SET || origin > SEEK_END) {
#ifdef R4NATIVE_FILE_IO
      errno = file && is_console(file) ? R4N_ESPIPE : R4N_EINVAL;
#endif
      return -1;
   }
   /* SEEK_END uses the full buffer length. Seeking beyond it does not allocate;
    * the next write zero-fills the gap (POSIX permits both choices). */
   size_t base = origin == SEEK_SET ? 0 : origin == SEEK_CUR ? file->position : file->length;
#ifdef R4NATIVE_FILE_IO
   if (file->closed) { errno = R4N_EBADF; return -1; }
   if (origin == SEEK_END && file->path) {
      uint64_t length; int rc = r4native_file_size(file->path, &length);
      if (rc || length > LONG_MAX) { errno = rc ? -rc : R4N_EOVERFLOW; return -1; }
      base = length;
   }
#endif
   size_t magnitude = offset < 0 ? (size_t)(-(offset + 1)) + 1 : (size_t)offset;
   if (base > LONG_MAX || (offset < 0 ? magnitude > base : magnitude > (size_t)LONG_MAX - base)) {
#ifdef R4NATIVE_FILE_IO
      errno = R4N_EINVAL;
#endif
      return -1;
   }
   file->position = offset < 0 ? base - magnitude : base + magnitude;
#ifdef R4NATIVE_FILE_IO
   file->eof = false;
#endif
   return 0;
}
int fseek(FILE *file, long offset, int origin)
{
   file = lock_file(file); if (!file) return -1;
   int result = seek_file(file, offset, origin); unlock_file(file); return result;
}

#ifdef R4NATIVE_FILE_IO
FILE *fopen(const char *name, const char *mode)
{
   if (!name || !mode || !*mode) { errno = R4N_EINVAL; return NULL; }
   unsigned flags = *mode == 'r' ? R4NATIVE_FILE_READ : *mode == 'w' ? R4NATIVE_FILE_WRITE | R4NATIVE_FILE_CREATE | R4NATIVE_FILE_TRUNCATE :
      *mode == 'a' ? R4NATIVE_FILE_WRITE | R4NATIVE_FILE_CREATE | R4NATIVE_FILE_APPEND : 0;
   if (!flags) { errno = R4N_EINVAL; return NULL; }
   unsigned seen = 0;
   for (const char *p = mode + 1; *p; p++) {
      unsigned bit = *p == '+' ? 1 : *p == 'b' ? 2 : *p == 't' ? 4 : *p == 'x' ? 8 : *p == 'e' ? 16 : 0;
      if (!bit || (seen & bit) || ((bit & 6) && (seen & 6)) || (*p == 'x' && *mode != 'w')) { errno = R4N_EINVAL; return NULL; }
      seen |= bit;
   }
   if (seen & 1) flags |= R4NATIVE_FILE_READ | R4NATIVE_FILE_WRITE;
   if (seen & 8) flags |= R4NATIVE_FILE_EXCLUSIVE;
   FILE *file = calloc(1, sizeof(*file));
   if (!file) { errno = R4N_ENOMEM; return NULL; }
   file->path = malloc(R4NATIVE_PATH_CAPACITY);
   if (!file->path) { free(file); errno = R4N_ENOMEM; return NULL; }
   int rc = r4native_file_path(name, file->path, R4NATIVE_PATH_CAPACITY);
   if (rc < 0) { free(file->path); free(file); errno = -rc; return NULL; }
   file->readable = flags & R4NATIVE_FILE_READ;
   file->writable = flags & R4NATIVE_FILE_WRITE;
   file->mode = flags;
   if (!register_file(file)) { free(file->path); free(file); return NULL; }
   rc = r4native_file_open(file->path, flags);
   if (rc) { fclose(file); errno = -rc; return NULL; }
   if ((flags & R4NATIVE_FILE_APPEND) && !(flags & R4NATIVE_FILE_READ)) {
      uint64_t length; rc = r4native_file_size(file->path, &length);
      if (rc || length > LONG_MAX) { fclose(file); errno = rc ? -rc : R4N_EOVERFLOW; return NULL; }
      file->position = length;
   }
   return file;
}
static size_t read_bytes(void *data, size_t size, size_t count, FILE *file)
{
   if (!size || !count) return 0;
   if (file->closed || !file->readable) { file->failed = true; errno = R4N_EBADF; return 0; }
   if (count > SIZE_MAX / size) { file->failed = true; errno = R4N_EOVERFLOW; return 0; }
   if (file->eof) return 0;
   size_t bytes = count * size, read = 0;
   while (read < bytes) {
      uint32_t chunk = bytes - read > INT_MAX ? INT_MAX : bytes - read;
      if (chunk > (size_t)LONG_MAX - file->position) { file->failed = true; errno = R4N_EOVERFLOW; break; }
      int64_t n = is_console(file) ? r4native_stream_read(file->console - 1, (char *)data + read, chunk) :
         r4native_file_read(file->path, file->position, (char *)data + read, chunk);
      if (n < 0) { file->failed = true; errno = -n; break; }
      if (n > chunk) { file->failed = true; errno = R4N_EIO; break; }
      if (!n) { file->eof = true; break; }
      read += n; file->position += n;
   }
   return read / size;
}
size_t fread(void *data, size_t size, size_t count, FILE *file)
{
   file = lock_file(file); if (!file) return 0;
   size_t n = read_bytes(data, size, count, file); unlock_file(file); return n;
}
int getc(FILE *file) { unsigned char byte; return fread(&byte, 1, 1, file) == 1 ? byte : EOF; }
int fgetc(FILE *file) { return getc(file); }
char *fgets(char *out, int size, FILE *file)
{
   if (!out || size <= 0) { errno = R4N_EINVAL; return NULL; }
   file = lock_file(file); if (!file) return NULL;
   int used = 0; bool failed = false;
   while (used < size - 1) {
      unsigned char byte;
      if (read_bytes(&byte, 1, 1, file) != 1) { failed = !file->eof; break; }
      out[used++] = byte; if (byte == '\n') break;
   }
   unlock_file(file);
   if (failed || (!used && size > 1)) return NULL;
   out[used] = 0; return out;
}
int feof(FILE *file) { file = lock_file(file); if (!file) return 0; int value = file->eof; unlock_file(file); return value; }
void clearerr(FILE *file) { file = lock_file(file); if (!file) return; file->failed = file->eof = false; unlock_file(file); }
int fileno(FILE *file)
{
   file = lock_file(file); if (!file) return -1;
   int result = !file->closed && is_console(file) ? (int)file->console - 1 : -1;
   if (result < 0) errno = file->closed ? R4N_EBADF : R4N_ENOTSUP;
   unlock_file(file); return result;
}
int isatty(int fd)
{
   if (fd < 0 || fd > 2) { errno = R4N_EBADF; return 0; }
   FILE *file = lock_file(fd == 0 ? stdin : fd == 1 ? stdout : stderr); if (!file) return 0;
   int rc = file->closed ? -R4N_EBADF : r4native_stream_terminal(fd);
   unlock_file(file); if (rc < 0) errno = -rc; return rc == 1;
}
int close(int fd)
{
   if (fd < 0 || fd > 2) { errno = R4N_EBADF; return -1; }
   return fclose(fd == 0 ? stdin : fd == 1 ? stdout : stderr);
}
int os_dupfd_cloexec(int fd)
{
   (void)fd; errno = R4N_ENOTSUP; return -1; /* No external FD owner exists. */
}
FILE *os_file_create_unique(const char *name, int mode)
{
   (void)mode; /* R4OS has no permission mode bits. */
   return fopen(name, "wx");
}
#endif
