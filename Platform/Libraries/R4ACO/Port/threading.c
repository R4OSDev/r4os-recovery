/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "c11/threads.h"
#include "r4nak_libc.h"
#include "../Bindings/C/r4aco.h"
extern uint64_t r4aco_port_epoch(void);
extern _Noreturn void r4aco_port_fail(int);

/* Private compiler transport: admission guarantees exactly one live worker
 * across all programs. This is not an exported general C11 thread library.
 * notification stores a compilation epoch here, never a kernel handle.
 * Reinitializing a resident gate requires the previous worker's proven
 * retirement; the public compiler owner enforces that before changing epoch. */
static void current(mtx_t *m) {
   uint64_t epoch=r4aco_port_epoch();
   if(m->notification!=epoch) { uint32_t flags=m->flags;*m=(mtx_t){.flags=flags,.notification=epoch}; }
}
int mtx_init(mtx_t *m,int flags) {
   if(flags&~(mtx_plain|mtx_recursive|mtx_timed))return thrd_error;
   *m=(mtx_t){.flags=(uint32_t)flags,.notification=r4aco_port_epoch()};return thrd_success;
}
int mtx_trylock(mtx_t *m) {
   current(m);
   if(m->state && !(m->flags&mtx_recursive))return thrd_busy;
   if(m->depth==UINT32_MAX)return thrd_error;
   m->state=1;m->depth++;return thrd_success;
}
int mtx_lock(mtx_t *m) { int status=mtx_trylock(m);return status==thrd_busy?thrd_error:status; }
int mtx_unlock(mtx_t *m) {
   current(m);if(!m->state || !m->depth)return thrd_error;
   if(!--m->depth)m->state=0;return thrd_success;
}
void mtx_destroy(mtx_t *m) { current(m);if(m->state)r4aco_port_fail(R4ACO_STATUS_COMPILER);*m=(mtx_t){0}; }
static bool enter(once_flag *once) {
   uint64_t epoch=r4aco_port_epoch();
   if(once->notification!=epoch)*once=(once_flag){.notification=epoch};
   if(once->state==2)return false;
   if(once->state)r4aco_port_fail(R4ACO_STATUS_COMPILER);
   once->state=1;return true;
}
void call_once(once_flag *once,void (*callback)(void)) { if(enter(once)) {callback();once->state=2;} }
void util_call_once_data_slow(once_flag *once,void (*callback)(const void *),const void *data) { if(enter(once)) {callback(data);once->state=2;} }
