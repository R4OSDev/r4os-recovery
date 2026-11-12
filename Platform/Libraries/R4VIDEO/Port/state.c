/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4video_state.h"
#include "libavutil/log.h"
#include <limits.h>
#include <stdlib.h>

static const char state_key;
static void initialize(void *pointer)
{
    struct r4video_ffmpeg_state *value = pointer;
    *value = (struct r4video_ffmpeg_state){
        .cpu_flags = -1, .cpu_count = -1, .max_alloc_size = INT_MAX,
        .log_level = AV_LOG_INFO, .log_callback = (uintptr_t)av_log_default_callback,
        .log_prefix = 1, .log_color = -1,
    };
}
static struct r4video_ffmpeg_state *lookup(void)
{
    return r4video_process_state(&state_key, sizeof(struct r4video_ffmpeg_state),
                                _Alignof(struct r4video_ffmpeg_state), initialize);
}
int r4video_ffmpeg_prepare(void) { return lookup() != NULL; }
struct r4video_ffmpeg_state *r4video_ffmpeg_state(void)
{
    /* Runtime bind prepares this fixed owner before admitting any decoder.
     * A missing owner here is a violated calling context, not decoder OOM. */
    struct r4video_ffmpeg_state *value = lookup();
    if (!value) abort();
    return value;
}
int r4video_ffmpeg_finish(void)
{
    struct r4video_ffmpeg_state *value = lookup();
    if (!value) return 0;
    /* Caller has retired all decoder workers. Retry keeps each live handle. */
    if (pthread_mutex_destroy(&value->codec_mutex)) return 0;
    return pthread_mutex_destroy(&value->log_mutex) == 0;
}
