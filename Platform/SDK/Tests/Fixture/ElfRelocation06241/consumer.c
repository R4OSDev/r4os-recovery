#include <stdbool.h>
#include <stdint.h>

extern const uint8_t r4_reloc_table[8];

uintptr_t r4_reloc_add(uintptr_t value) {
    return value + (uintptr_t)r4_reloc_table;
}

bool r4_reloc_equal(const void *value) {
    return value == (const void *)r4_reloc_table;
}

const void *r4_reloc_address(void) {
    return r4_reloc_table;
}

void R4XStart(void) {
    volatile uintptr_t result = r4_reloc_add((uintptr_t)r4_reloc_address());
    if (r4_reloc_equal((const void *)result)) __asm__ volatile ("" ::: "memory");
}
