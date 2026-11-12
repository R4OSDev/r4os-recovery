/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "errno.h"
#include "r4nak_libc.h"
#include "files.h"

/* Compile with -femulated-tls. The shared native TLS owner keys this cell by
 * exact process/thread generation; there is no shared emergency error cell. */
static _Thread_local int error_number;
int *r4native_errno_location(void) { return &error_number; }

/* Immutable C-locale messages for the private runtime's admitted errno set.
 * Unknown codes have stable storage too; no TLS scratch buffer or errno write. */
char *strerror(int error)
{
   switch (error) {
   case 0: return "Success";
   case R4N_ENOENT: return "File not found";
   case R4N_EIO: return "Input/output error";
   case R4N_EBADF: return "Invalid stream";
   case R4N_EBUSY: return "Resource busy";
   case R4N_EISDIR: return "Is a directory";
   case R4N_ENOTTY: return "Not a terminal";
   case R4N_EFBIG: return "File too large";
   case R4N_ESPIPE: return "Stream is not seekable";
   case R4N_EOVERFLOW: return "Value cannot be represented";
   case R4N_ENOTSUP: return "Operation not supported";
   case EPERM: return "Operation not permitted";
   case EINTR: return "Interrupted operation";
   case ENOMEM: return "Out of memory";
   case EEXIST: return "Already exists";
   case EINVAL: return "Invalid argument";
   case ERANGE: return "Result out of range";
   case EDEADLK: return "Deadlock detected";
   case ENOSYS: return "Function not implemented";
   case ETIMEDOUT: return "Operation timed out";
   default: return "Unknown error";
   }
}
