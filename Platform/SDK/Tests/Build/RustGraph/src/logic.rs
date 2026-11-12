pub fn value() -> u64 {
    let seed = core::hint::black_box(include_bytes!("payload.txt")[0] as u64);
    #[cfg(feature = "with-helper")]
    return helper::value(seed);
    #[cfg(not(feature = "with-helper"))]
    return seed;
}
