#![no_std]
pub fn value(seed: u64) -> u64 {
    #[cfg(feature = "scaled")]
    return seed.wrapping_mul(2);
    #[cfg(not(feature = "scaled"))]
    return seed;
}
