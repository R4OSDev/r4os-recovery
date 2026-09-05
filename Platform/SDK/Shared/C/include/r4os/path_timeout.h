#ifndef R4OS_PATH_TIMEOUT_H
#define R4OS_PATH_TIMEOUT_H

#include "abi.h"

static inline void r4_contract_zero(void *target, size_t len) {
    uint8_t *bytes = (uint8_t *)target;
    for (size_t i = 0; i < len; ++i) bytes[i] = 0;
}

static inline void r4_contract_copy(void *target, const void *source, size_t len) {
    uint8_t *out = (uint8_t *)target;
    const uint8_t *in = (const uint8_t *)source;
    for (size_t i = 0; i < len; ++i) out[i] = in[i];
}

typedef struct R4FilePath {
    uint8_t bytes[R4OS_FILE_PATH_MAX_BYTES + 1u];
    uint16_t length;
    uint8_t absolute;
    uint8_t reserved;
} R4FilePath;

typedef struct R4AbsoluteFilePath {
    uint8_t bytes[R4OS_FILE_PATH_MAX_BYTES + 1u];
    uint16_t length;
} R4AbsoluteFilePath;

typedef struct R4RelativeFilePath {
    uint8_t bytes[R4OS_FILE_PATH_MAX_BYTES + 1u];
    uint16_t length;
} R4RelativeFilePath;

typedef struct R4RegistryPath {
    uint8_t bytes[R4OS_REGISTRY_PATH_MAX_BYTES + 1u];
    uint16_t length;
} R4RegistryPath;

typedef struct R4PathZ {
    const uint8_t *ptr;
    uint16_t length;
} R4PathZ;

enum {
    R4_PATH_OK = 0,
    R4_PATH_EMPTY = -1,
    R4_PATH_TOO_LONG = -2,
    R4_PATH_COMPONENT_TOO_LONG = -3,
    R4_PATH_EMBEDDED_NUL = -4,
    R4_PATH_INVALID_CHARACTER = -5,
    R4_PATH_WRONG_KIND = -6,
    R4_PATH_ROOT_TRAVERSAL = -7
};

static inline uint8_t r4_ascii_upper(uint8_t byte) {
    return byte >= 'a' && byte <= 'z' ? (uint8_t)(byte - 32u) : byte;
}

static inline int r4_path_separator(uint8_t byte) { return byte == '\\' || byte == '/'; }
static inline int r4_path_alpha(uint8_t byte) { byte = r4_ascii_upper(byte); return byte >= 'A' && byte <= 'Z'; }

static inline int r4_path_byte_valid(uint8_t byte) {
    if (byte == 0) return R4_PATH_EMBEDDED_NUL;
    if (byte < 0x20u || byte == 0x7Fu || byte == '<' || byte == '>' || byte == '"' || byte == '|' || byte == '?' || byte == '*' || byte == ':') return R4_PATH_INVALID_CHARACTER;
    return R4_PATH_OK;
}

/* Component validation since 0.60.18: UTF-8 restricted to the BMP.  ASCII
 * keeps the reserved-character rules; multi-byte sequences must be
 * well-formed 2- or 3-byte UTF-8 without overlong forms or surrogates.
 * 4-byte sequences (non-BMP) and malformed bytes are visible errors.
 * Since 0.60.19 the CHARACTER count is reported for the Windows-parity
 * character limits (255 per component, 260 per path). */
static inline int r4_path_segment_valid(const uint8_t *segment, size_t len, size_t *out_chars) {
    size_t i = 0u;
    size_t chars = 0u;
    while (i < len) {
        uint8_t byte = segment[i];
        if (byte < 0x80u) {
            int valid = r4_path_byte_valid(byte);
            if (valid != 0) return valid;
            ++i;
            ++chars;
            continue;
        }
        if ((byte & 0xE0u) == 0xC0u) {
            if (byte < 0xC2u) return R4_PATH_INVALID_CHARACTER; /* overlong */
            if (i + 1u >= len || (segment[i + 1u] & 0xC0u) != 0x80u) return R4_PATH_INVALID_CHARACTER;
            i += 2u;
            ++chars;
            continue;
        }
        if ((byte & 0xF0u) == 0xE0u) {
            uint8_t b1, b2;
            if (i + 2u >= len) return R4_PATH_INVALID_CHARACTER;
            b1 = segment[i + 1u];
            b2 = segment[i + 2u];
            if ((b1 & 0xC0u) != 0x80u || (b2 & 0xC0u) != 0x80u) return R4_PATH_INVALID_CHARACTER;
            if (byte == 0xE0u && b1 < 0xA0u) return R4_PATH_INVALID_CHARACTER; /* overlong */
            if (byte == 0xEDu && b1 >= 0xA0u) return R4_PATH_INVALID_CHARACTER; /* surrogate */
            i += 3u;
            ++chars;
            continue;
        }
        return R4_PATH_INVALID_CHARACTER; /* stray continuation or non-BMP lead */
    }
    if (out_chars != 0) *out_chars = chars;
    return R4_PATH_OK;
}

static inline int r4_path_normalize(const uint8_t *input, size_t len, int required_kind, uint8_t out[R4OS_FILE_PATH_MAX_BYTES + 1u], uint16_t *out_len, uint8_t *out_absolute) {
    if (input == 0 || len == 0) return R4_PATH_EMPTY;
    if (len > R4OS_FILE_PATH_MAX_BYTES) return R4_PATH_TOO_LONG;
    int absolute = len >= 3u && r4_path_alpha(input[0]) && input[1] == ':' && r4_path_separator(input[2]);
    if ((required_kind == 1 && !absolute) || (required_kind == 0 && absolute)) return R4_PATH_WRONG_KIND;
    if (!absolute && r4_path_separator(input[0])) return R4_PATH_WRONG_KIND;
    size_t pos = 0u, index = 0u, count = 0u;
    uint16_t starts[160], char_starts[160];
    size_t chars = absolute ? 3u : 0u;
    if (absolute) { out[0] = r4_ascii_upper(input[0]); out[1] = ':'; out[2] = '\\'; pos = 3u; index = 3u; }
    while (index < len) {
        while (index < len && r4_path_separator(input[index])) ++index;
        if (index >= len) break;
        size_t start = index;
        while (index < len && !r4_path_separator(input[index])) ++index;
        size_t segment = index - start;
        if (segment == 1u && input[start] == '.') continue;
        if (segment == 2u && input[start] == '.' && input[start + 1u] == '.') {
            if (count == 0u) return R4_PATH_ROOT_TRAVERSAL;
            --count;
            pos = (size_t)starts[count];
            chars = (size_t)char_starts[count];
            if (absolute && pos == 2u) pos = 3u;
            if (absolute && chars < 3u) chars = 3u;
            continue;
        }
        if (segment > R4OS_FAT_PATH_COMPONENT_MAX_BYTES) return R4_PATH_COMPONENT_TOO_LONG;
        size_t segment_chars = 0u;
        { int valid = r4_path_segment_valid(input + start, segment, &segment_chars); if (valid != 0) return valid; }
        if (segment_chars > R4OS_PATH_COMPONENT_MAX_CHARS) return R4_PATH_COMPONENT_TOO_LONG;
        if (count >= 160u) return R4_PATH_TOO_LONG;
        size_t before = pos;
        size_t before_chars = chars;
        if ((absolute && pos > 3u) || (!absolute && pos > 0u)) { out[pos++] = '\\'; ++chars; }
        starts[count] = (uint16_t)before;
        char_starts[count] = (uint16_t)before_chars;
        ++count;
        if (segment > R4OS_FILE_PATH_MAX_BYTES - pos) return R4_PATH_TOO_LONG;
        chars += segment_chars;
        if (chars > R4OS_FILE_PATH_MAX_CHARS) return R4_PATH_TOO_LONG;
        r4_contract_copy(out + pos, input + start, segment); pos += segment;
    }
    if (!absolute && pos == 0u) out[pos++] = '.';
    out[pos] = 0;
    if (out_len != 0) *out_len = (uint16_t)pos;
    if (out_absolute != 0) *out_absolute = (uint8_t)absolute;
    return R4_PATH_OK;
}

static inline int r4_file_path(const uint8_t *input, size_t len, R4FilePath *out) {
    if (out == 0) return R4_PATH_EMPTY;
    return r4_path_normalize(input, len, -1, out->bytes, &out->length, &out->absolute);
}

static inline int r4_absolute_file_path(const uint8_t *input, size_t len, R4AbsoluteFilePath *out) {
    if (out == 0) return R4_PATH_EMPTY;
    return r4_path_normalize(input, len, 1, out->bytes, &out->length, 0);
}

static inline int r4_relative_file_path(const uint8_t *input, size_t len, R4RelativeFilePath *out) {
    if (out == 0) return R4_PATH_EMPTY;
    return r4_path_normalize(input, len, 0, out->bytes, &out->length, 0);
}

static inline int r4_registry_path(const uint8_t *input, size_t len, R4RegistryPath *out) {
    if (input == 0 || out == 0 || len == 0) return R4_PATH_EMPTY;
    if (len > R4OS_REGISTRY_PATH_MAX_BYTES) return R4_PATH_TOO_LONG;
    size_t pos = 0u; int previous = 0;
    for (size_t i = 0; i < len; ++i) {
        uint8_t byte = input[i];
        if (byte == 0) return R4_PATH_EMBEDDED_NUL;
        if (byte < 0x20u || byte == 0x7Fu) return R4_PATH_INVALID_CHARACTER;
        if (r4_path_separator(byte)) {
            if (pos == 0u || previous) continue;
            out->bytes[pos++] = '\\'; previous = 1;
        } else { out->bytes[pos++] = byte; previous = 0; }
    }
    while (pos > 0u && out->bytes[pos - 1u] == '\\') --pos;
    if (pos == 0u) return R4_PATH_EMPTY;
    out->bytes[pos] = 0; out->length = (uint16_t)pos;
    return R4_PATH_OK;
}

static inline int r4_path_equal_ignore_case(const uint8_t *a, size_t a_len, const uint8_t *b, size_t b_len) {
    if (a_len != b_len) return 0;
    for (size_t i = 0; i < a_len; ++i) if (r4_ascii_upper(a[i]) != r4_ascii_upper(b[i])) return 0;
    return 1;
}

static inline int r4_duration_to_ticks(R4Duration duration, uint32_t hz, uint64_t *out_ticks) {
    if (hz == 0u || out_ticks == 0) return R4OS_ERROR_INVALID;
    if (duration.nanoseconds == 0u) { *out_ticks = 0u; return R4OS_OK; }
    __uint128_t product = (__uint128_t)duration.nanoseconds * hz;
    __uint128_t rounded = (product + R4OS_NANOSECONDS_PER_SECOND - 1u) / R4OS_NANOSECONDS_PER_SECOND;
    *out_ticks = rounded > UINT64_MAX ? UINT64_MAX : (uint64_t)rounded;
    return R4OS_OK;
}

static inline R4Timeout r4_timeout_poll(void) {
    R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_POLL; return value;
}

static inline R4Timeout r4_timeout_finite(R4Duration duration) {
    R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_FINITE; value.nanoseconds = duration.nanoseconds; return value;
}

static inline R4Timeout r4_timeout_forever(void) {
    R4Timeout value = {0}; value.kind = R4OS_TIMEOUT_KIND_FOREVER; return value;
}

static inline int r4_timeout_to_ticks(R4Timeout timeout, uint32_t hz, uint64_t *out_ticks) {
    if (out_ticks == 0) return R4OS_ERROR_INVALID;
    if (timeout.kind == R4OS_TIMEOUT_KIND_POLL) { *out_ticks = 0; return R4OS_OK; }
    if (timeout.kind == R4OS_TIMEOUT_KIND_FOREVER) { *out_ticks = R4OS_IO_WAIT_FOREVER; return R4OS_OK; }
    if (timeout.kind != R4OS_TIMEOUT_KIND_FINITE) return R4OS_ERROR_INVALID;
    R4Duration duration = { timeout.nanoseconds };
    return r4_duration_to_ticks(duration, hz, out_ticks);
}

static inline int r4_timeout_deadline(R4Timeout timeout, R4MonotonicInstant now, R4Deadline *out, int *out_forever) {
    if (out == 0 || out_forever == 0) return R4OS_ERROR_INVALID;
    *out_forever = 0;
    if (timeout.kind == R4OS_TIMEOUT_KIND_FOREVER) { out->nanoseconds = 0; *out_forever = 1; return R4OS_OK; }
    if (timeout.kind == R4OS_TIMEOUT_KIND_POLL) { out->nanoseconds = now.nanoseconds; return R4OS_OK; }
    if (timeout.kind != R4OS_TIMEOUT_KIND_FINITE) return R4OS_ERROR_INVALID;
    out->nanoseconds = UINT64_MAX - now.nanoseconds < timeout.nanoseconds ? UINT64_MAX : now.nanoseconds + timeout.nanoseconds;
    return R4OS_OK;
}

static inline int r4_remaining_ticks(R4Deadline deadline, R4MonotonicInstant now, uint32_t hz, uint64_t *out_ticks) {
    R4Duration remaining = { deadline.nanoseconds > now.nanoseconds ? deadline.nanoseconds - now.nanoseconds : 0 };
    return r4_duration_to_ticks(remaining, hz, out_ticks);
}

static inline uint64_t r4_monotonic_resolution_ns(uint32_t hz) {
    return hz == 0u ? 0u : R4OS_NANOSECONDS_PER_SECOND / hz + (R4OS_NANOSECONDS_PER_SECOND % hz != 0u);
}

static inline R4Deadline r4_deadline_after(R4MonotonicInstant now, R4Duration duration) {
    R4Deadline value;
    value.nanoseconds = UINT64_MAX - now.nanoseconds < duration.nanoseconds ? UINT64_MAX : now.nanoseconds + duration.nanoseconds;
    return value;
}

_Static_assert(sizeof(R4Duration) == 8u, "R4Duration size mismatch");
_Static_assert(sizeof(R4UtcTime) == 16u, "R4UtcTime size mismatch");
_Static_assert(sizeof(uint16_t) * 160u * 2u == 640u, "path rollback storage mismatch");

#endif
