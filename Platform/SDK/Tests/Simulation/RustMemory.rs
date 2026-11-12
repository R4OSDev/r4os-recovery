#[path = "../../Rust/src/memory.rs"]
mod memory;

#[test]
fn copy_fill_and_compare_keep_guards_and_unsigned_byte_order() {
    let input = [0x80u8, 0xff, 2, 4, 9];
    let mut output = [0x5au8; 9];
    unsafe {
        memory::memcpy(output.as_mut_ptr().add(2).cast(), input.as_ptr().cast(), 5);
    }
    assert_eq!(&output[..2], &[0x5a; 2]);
    assert_eq!(&output[2..7], &input);
    assert_eq!(&output[7..], &[0x5a; 2]);
    unsafe {
        memory::memset(output.as_mut_ptr().add(2).cast(), 0x1ee, 5);
    }
    assert_eq!(&output[2..7], &[0xee; 5]);
    assert_eq!(output[1], 0x5a);
    assert_eq!(output[7], 0x5a);
    unsafe {
        assert_eq!(
            memory::memcmp(input.as_ptr().cast(), input.as_ptr().cast(), 5),
            0
        );
        assert!(memory::memcmp([0xffu8].as_ptr().cast(), [0x80u8].as_ptr().cast(), 1) > 0);
        assert!(memory::bcmp([1u8].as_ptr().cast(), [2u8].as_ptr().cast(), 1) < 0);
    }
    // Actual compiler helpers, including unrelated source/destination
    // alignments and the page/bulk boundaries used by the Desktop.
    let mut source = [0u8; 8192 + 32];
    for (index, byte) in source.iter_mut().enumerate() { *byte = index.wrapping_mul(137) as u8; }
    for from in [0, 1, 3, 7, 15] {
        for to in [0, 1, 5, 8, 15] {
            for count in [0, 1, 7, 8, 31, 32, 63, 64, 255, 256, 4095, 4096, 8192] {
                let mut output = [0x5au8; 8192 + 32];
                let destination = unsafe { output.as_mut_ptr().add(to) };
                assert_eq!(unsafe { memory::memcpy(destination.cast(), source.as_ptr().add(from).cast(), count) }, destination.cast());
                assert_eq!(&output[to..to + count], &source[from..from + count]);
                assert!(output[..to].iter().chain(output[to + count..].iter()).all(|v| *v == 0x5a));
                assert_eq!(unsafe { memory::memset(destination.cast(), -258, count) }, destination.cast());
                assert!(output[to..to + count].iter().all(|v| *v == 0xfe));
                assert!(output[..to].iter().chain(output[to + count..].iter()).all(|v| *v == 0x5a));
            }
        }
    }
    // Equality reads and first-difference order cross every bulk boundary;
    // a later opposite difference must not change the first byte's result.
    for offset in [0, 1, 5, 15] {
        for count in [1, 7, 8, 31, 32, 63, 64, 257, 4096, 8192] {
            let input = &source[offset..offset + count];
            let mut peer = [0u8; 8192 + 32];
            peer[3..3 + count].copy_from_slice(input);
            assert_eq!(unsafe { memory::memcmp(input.as_ptr().cast(), peer.as_ptr().add(3).cast(), count) }, 0);
            for first in [0, count / 2, count - 1] {
                let expected = i32::from(input[first]) - i32::from(input[first] ^ 0x80);
                peer[3 + first] ^= 0x80;
                if first + 1 < count { peer[3 + first + 1] ^= 0xff; }
                assert_eq!(unsafe { memory::memcmp(input.as_ptr().cast(), peer.as_ptr().add(3).cast(), count) }, expected);
                assert_eq!(unsafe { memory::bcmp(peer.as_ptr().add(3).cast(), input.as_ptr().cast(), count) }, -expected);
                peer[3..3 + count].copy_from_slice(input);
            }
        }
    }
}

#[test]
fn overlapping_moves_both_directions_and_empty_ranges() {
    let mut right = *b"0123456789";
    unsafe {
        memory::memmove(right.as_mut_ptr().add(2).cast(), right.as_ptr().cast(), 6);
    }
    assert_eq!(&right, b"0101234589");
    let mut left = *b"0123456789";
    unsafe {
        memory::memmove(left.as_mut_ptr().cast(), left.as_ptr().add(2).cast(), 6);
    }
    assert_eq!(&left, b"2345676789");
    for shift in [1, 3, 7, 8, 15, 31] {
        let mut right = [0u8; 8192 + 32];
        for (i, v) in right.iter_mut().enumerate() { *v = i.wrapping_mul(73) as u8; }
        let original = right;
        unsafe { memory::memmove(right.as_mut_ptr().add(shift).cast(), right.as_ptr().cast(), 8192); }
        assert_eq!(&right[..shift], &original[..shift]);
        assert_eq!(&right[shift..shift + 8192], &original[..8192]);
        assert_eq!(&right[shift + 8192..], &original[shift + 8192..]);
        let mut left = original;
        unsafe { memory::memmove(left.as_mut_ptr().cast(), left.as_ptr().add(shift).cast(), 8192); }
        assert_eq!(&left[..8192], &original[shift..shift + 8192]);
        assert_eq!(&left[8192..], &original[8192..]);
    }
    unsafe {
        memory::memmove(left.as_mut_ptr().cast(), left.as_ptr().cast(), 10);
        memory::memcpy(left.as_mut_ptr().cast(), right.as_ptr().cast(), 0);
        memory::memset(left.as_mut_ptr().cast(), 0, 0);
        assert_eq!(
            memory::memcmp(left.as_ptr().cast(), right.as_ptr().cast(), 0),
            0
        );
    }
    assert_eq!(&left, b"2345676789");
}
