/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VIDEO_STATE_H
#define R4VIDEO_STATE_H
#include <stddef.h>
#include <stdint.h>
#include <stdatomic.h>
#include <pthread.h>

/* One calling-process owner. Table data is const; these are settings/locks. */
struct r4video_ffmpeg_state {
    atomic_int cpu_flags, cpu_count, cpu_printed;
    atomic_size_t max_alloc_size;
    pthread_mutex_t codec_mutex, log_mutex;
    atomic_int log_level, log_flags;
    atomic_uintptr_t log_callback;
    int log_prefix, log_count, log_atty, log_color;
    char log_previous[1024];
};
void *r4video_process_state(const void *, size_t, size_t, void (*)(void *));
struct r4video_ffmpeg_state *r4video_ffmpeg_state(void);
int r4video_ffmpeg_prepare(void);
int r4video_ffmpeg_finish(void);
int r4video_cpu_count(void);
uint32_t r4video_random_seed(void); /* Noncryptographic decoder seed. */
#endif
