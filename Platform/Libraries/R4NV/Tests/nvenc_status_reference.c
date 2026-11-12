#include <stdio.h>
#include <stddef.h>
#include <string.h>
#define NV_NVENC_8_2 1
#include "nvenc_drv.h"

_Static_assert(sizeof(nvenc_pic_stat_s) == 128, "actual picture status size");
_Static_assert(sizeof(nvenc_slice_stat_s) == 16, "actual slice status size");
_Static_assert(offsetof(nvenc_pic_stat_s, actual_min_qp_used) == 68, "QP offset");
_Static_assert(offsetof(nvenc_stat_data_s, slice_stat) == 128, "slice array offset");

static int emit(FILE *out, unsigned int kind, unsigned int code) {
    nvenc_pic_stat_s p = {0};
    nvenc_slice_stat_s s = {0};
    p.picture_index = 0x12345678;
    p.error_status = code & 3;
    p.ucode_error_status = code >> 2;
    p.total_bit_count = 160;
    p.type1_bit_count = 128;
    p.pic_type = kind;
    p.num_slices = 1;
    p.avgQP = 24;
    p.actual_min_qp_used = 18;
    p.actual_max_qp_used = 32;
    p.bitstream_start_pos = 256;
    p.last_valid_byte_offset = 276; // Physical C7 firmware writes an exclusive end.
    p.intra_mb_count = kind == 3 ? 240 : 40;
    p.inter_mb_count = kind == 3 ? 0 : 200;
    p.cycle_count = 0x76543210;
    s.slice_offset = 256;
    s.slice_size = 20;
    s.slh_bit_count = 16;
    return fwrite(&p, 1, sizeof p, out) == sizeof p && fwrite(&s, 1, sizeof s, out) == sizeof s;
}
int main(int argc, char **argv) {
    if (argc != 2) return 1;
    FILE *out = fopen(argv[1], "wb");
    if (!out) return 2;
    int ok = emit(out, 3, 2) && emit(out, 0, 2) && emit(out, 3, 1) && emit(out, 3, 0x30000006);
    if (fclose(out)) return 3;
    return ok ? 0 : 4;
}
