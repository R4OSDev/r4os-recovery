/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
/* Host-only materialization of the pinned FFmpeg film-grain database. */
#include <stdio.h>
#define R4OS_TABLEGEN 1
#include "libavcodec/h274.c"

int main(void)
{
    puts("/* Generated from FFmpeg 9.0.1 h274.c. LGPL-2.1-or-later. */");
    puts("/* R4OS: immutable film-grain database, no runtime synthesis or mutex. */");
    puts("static const H274FilmGrainDatabase film_grain_db = {.db = {");
    for (unsigned h = 0; h < 13; ++h) {
        puts("{");
        for (unsigned v = 0; v < 13; ++v) {
            init_slice(h, v);
            puts("{");
            for (unsigned y = 0; y < 64; ++y) {
                putchar('{');
                for (unsigned x = 0; x < 64; ++x)
                    printf("%d,", film_grain_db.db[h][v][y][x]);
                puts("},");
            }
            puts("},");
        }
        puts("},");
    }
    puts("}};");
    return ferror(stdout) ? 1 : 0;
}
