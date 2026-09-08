// Shared x86_64 hardware entropy source. CPUID admission and the carry flag
// are required for every result; ten failed instructions end the request.
// Failure clears all output and never falls back to clocks or identifiers.
pub fn available() bool {
    return (cpuid(1, 0).ecx & (@as(u32, 1) << 30)) != 0;
}

pub fn fill(out: []u8) bool {
    if (!available()) {
        @memset(out, 0);
        return false;
    }
    var offset: usize = 0;
    while (offset < out.len) {
        var attempt: u8 = 0;
        var value: ?u64 = null;
        while (attempt < 10 and value == null) : (attempt += 1) value = rdrand64();
        const word = value orelse {
            @memset(out, 0);
            return false;
        };
        const count = @min(@as(usize, 8), out.len - offset);
        for (0..count) |index| out[offset + index] = @truncate(word >> @intCast(index * 8));
        offset += count;
    }
    return true;
}

const CpuId = struct {
    eax: u32,
    ebx: u32,
    ecx: u32,
    edx: u32,
};

fn cpuid(leaf: u32, subleaf: u32) CpuId {
    var eax: u32 = leaf;
    var ebx: u32 = 0;
    var ecx: u32 = subleaf;
    var edx: u32 = 0;
    asm volatile ("cpuid"
        : [eax] "={eax}" (eax),
          [ebx] "={ebx}" (ebx),
          [ecx] "={ecx}" (ecx),
          [edx] "={edx}" (edx),
        : [leaf] "{eax}" (leaf),
          [subleaf] "{ecx}" (subleaf),
    );
    return .{ .eax = eax, .ebx = ebx, .ecx = ecx, .edx = edx };
}

fn rdrand64() ?u64 {
    var value: u64 = 0;
    var success: u8 = 0;
    asm volatile (
        \\rdrand %[value]
        \\setc %[success]
        : [value] "=r" (value),
          [success] "=r" (success),
    );
    return if (success != 0) value else null;
}
