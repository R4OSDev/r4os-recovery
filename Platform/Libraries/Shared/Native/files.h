/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4NATIVE_FILES_H
#define R4NATIVE_FILES_H
#include <stdint.h>
#include <stddef.h>
/* Private path-based C stream adapter, not a kernel FD namespace. Results
 * are byte counts/zero or negative errno. The caller owns its path and cursor. */
#define R4NATIVE_FILE_READ 1u
#define R4NATIVE_FILE_WRITE 2u
#define R4NATIVE_FILE_APPEND 4u
#define R4NATIVE_FILE_CREATE 8u
#define R4NATIVE_FILE_TRUNCATE 16u
#define R4NATIVE_FILE_EXCLUSIVE 32u
#define R4NATIVE_PATH_CAPACITY 1024u
int32_t r4native_file_path(const char *, char *, uint32_t);
int32_t r4native_file_open(const char *, unsigned);
int64_t r4native_file_read(const char *, uint64_t, void *, uint32_t);
int64_t r4native_file_write(const char *, uint64_t, const void *, uint32_t, unsigned);
int32_t r4native_file_size(const char *, uint64_t *);
int32_t r4native_stream_read(unsigned, void *, uint32_t);
int32_t r4native_stream_write(unsigned, const void *, uint32_t);
int32_t r4native_stream_terminal(unsigned);
void *r4native_stdio_state(const void *, size_t, size_t, void (*)(void *));
/* Requires all stream users to have stopped. Published memory buffers remain
 * caller-owned. OK and IO_ERROR both mean complete, with the same result on
 * repeat; RETRY retains remaining records for another close attempt. A stream
 * error does not prevent closing other streams. No disk fsync promise. */
enum { R4NATIVE_STDIO_RETRY = -1, R4NATIVE_STDIO_OK = 0, R4NATIVE_STDIO_IO_ERROR = 1 };
int r4native_stdio_finish(void);
int r4native_mutex_close(void *);
/* Private numeric errno ABI shared by the C adapter and Zig provider. */
enum { R4N_ENOENT=2, R4N_EIO=5, R4N_EBADF=9, R4N_ENOMEM=12, R4N_EBUSY=16,
 R4N_EEXIST=17, R4N_EISDIR=21, R4N_EINVAL=22, R4N_ENOTTY=25, R4N_EFBIG=27,
 R4N_ESPIPE=29, R4N_ENOSYS=38, R4N_EOVERFLOW=75, R4N_ENOTSUP=95 };
#endif
