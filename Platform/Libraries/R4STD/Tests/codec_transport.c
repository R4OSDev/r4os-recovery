#include "r4std_abi.h"
#include <stdint.h>

int r4std_codec_c_transport(const R4StdCodecV1 *api) {
    uint32_t scalar = UINT32_C(0xdeadbeef), written = 99;
    uint8_t byte = 0xa5, bytes[4] = {0xa5,0xa5,0xa5,0xa5};
    R4StdScalarResult result = {0};
    R4StdUtf8State state = {0};
    if (sizeof(*api) != 80 || sizeof(result) != 16 || sizeof(state) != 16) return 1;
    if (api->legacy_decode(437, 0, 0x81, &scalar) != 0 || scalar != 0xfc) return 2;
    if (api->legacy_encode(437, 0, scalar, &byte) != 0 || byte != 0x81) return 3;
    if (api->utf8_encode(0x1f600, bytes, sizeof(bytes), &written) != 0 || written != 4) return 4;
    if (api->utf8_decode(bytes, written, &result) != 0 || result.scalar != 0x1f600 || result.byte_length != 4) return 5;
    if (api->utf8_push(&state, 0xc3, &result) != R4STD_CODEC_INCOMPLETE || state.length != 1) return 6;
    if (api->utf8_finish(&state) != R4STD_CODEC_INCOMPLETE || state.length != 1) return 7;
    if (api->utf8_push(&state, 0xbc, &result) != 0 || result.scalar != 0xfc || state.length != 0) return 8;
    if (api->utf8_finish(&state) != 0) return 9;
    written = 99;
    if (api->utf8_encode(0x20ac, bytes, 2, &written) != R4STD_STATUS_BUFFER_TOO_SMALL || written != 99) return 10;
    if (api->utf8_encode(0xd800, bytes, sizeof(bytes), &written) != R4STD_STATUS_INVALID_SCALAR || written != 99) return 11;
    scalar = UINT32_C(0xdeadbeef);
    if (api->legacy_decode(1252, 0, 0x81, &scalar) != R4STD_STATUS_UNDEFINED_BYTE || scalar != UINT32_C(0xdeadbeef)) return 12;
    return 0;
}
