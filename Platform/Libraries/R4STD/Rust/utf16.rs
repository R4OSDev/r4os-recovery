//! Strict allocation-free UTF-8/UTF-16 conversions. Counts name neither cells
//! nor bytes implicitly: unit APIs return u16 counts, LE APIs return bytes.
//! Every error preserves the complete caller output. Filesystem restrictions,
//! NUL/terminator policy, case collation and normalization belong to callers.

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    InvalidUtf8,
    InvalidUtf16,
    BufferTooSmall,
}

pub fn units_required(input: &[u8]) -> Result<usize, Error> {
    let text = core::str::from_utf8(input).map_err(|_| Error::InvalidUtf8)?;
    Ok(text.encode_utf16().count())
}

fn utf8_required(units: impl Iterator<Item = u16>) -> Result<usize, Error> {
    let mut required = 0usize;
    for scalar in char::decode_utf16(units) {
        let scalar = scalar.map_err(|_| Error::InvalidUtf16)?;
        required = required
            .checked_add(scalar.len_utf8())
            .ok_or(Error::BufferTooSmall)?;
    }
    Ok(required)
}

pub fn from_utf8(input: &[u8], out: &mut [u16]) -> Result<usize, Error> {
    let text = core::str::from_utf8(input).map_err(|_| Error::InvalidUtf8)?;
    let required = text.encode_utf16().count();
    if required > out.len() {
        return Err(Error::BufferTooSmall);
    }
    for (to, unit) in out[..required].iter_mut().zip(text.encode_utf16()) {
        *to = unit;
    }
    Ok(required)
}

pub fn to_utf8(input: &[u16], out: &mut [u8]) -> Result<usize, Error> {
    let required = utf8_required(input.iter().copied())?;
    if required > out.len() {
        return Err(Error::BufferTooSmall);
    }
    let mut offset = 0;
    for scalar in char::decode_utf16(input.iter().copied()) {
        let scalar = scalar.expect("preflight retained the exact immutable input");
        let n = scalar.len_utf8();
        scalar.encode_utf8(&mut out[offset..offset + n]);
        offset += n;
    }
    Ok(required)
}

pub fn from_utf8_le(input: &[u8], out: &mut [u8]) -> Result<usize, Error> {
    let text = core::str::from_utf8(input).map_err(|_| Error::InvalidUtf8)?;
    let required = text
        .encode_utf16()
        .count()
        .checked_mul(2)
        .ok_or(Error::BufferTooSmall)?;
    if required > out.len() {
        return Err(Error::BufferTooSmall);
    }
    for (to, unit) in out[..required]
        .as_chunks_mut::<2>()
        .0
        .iter_mut()
        .zip(text.encode_utf16())
    {
        *to = unit.to_le_bytes();
    }
    Ok(required)
}

pub fn validate_le(input: &[u8]) -> Result<usize, Error> {
    if !input.len().is_multiple_of(2) {
        return Err(Error::InvalidUtf16);
    }
    let units = input
        .as_chunks::<2>()
        .0
        .iter()
        .map(|u| u16::from_le_bytes(*u));
    utf8_required(units)
}

pub fn le_to_utf8(input: &[u8], out: &mut [u8]) -> Result<usize, Error> {
    let required = validate_le(input)?;
    if required > out.len() {
        return Err(Error::BufferTooSmall);
    }
    let units = input
        .as_chunks::<2>()
        .0
        .iter()
        .map(|u| u16::from_le_bytes(*u));
    let mut offset = 0;
    for scalar in char::decode_utf16(units) {
        let scalar = scalar.expect("preflight retained the exact immutable input");
        let n = scalar.len_utf8();
        scalar.encode_utf8(&mut out[offset..offset + n]);
        offset += n;
    }
    Ok(required)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_unicode_scalar_matches_core_in_both_endian_and_unit_forms() {
        for value in 0..=0x10ffff {
            let Some(scalar) = char::from_u32(value) else {
                continue;
            };
            let mut utf8 = [0; 4];
            let text = scalar.encode_utf8(&mut utf8);
            let mut expected = [0; 2];
            let expected = scalar.encode_utf16(&mut expected);
            let mut units = [0xffff; 2];
            let n = from_utf8(text.as_bytes(), &mut units).unwrap();
            assert_eq!(&units[..n], expected);
            assert_eq!(units_required(text.as_bytes()), Ok(n));
            let mut bytes = [0; 4];
            assert_eq!(to_utf8(&units[..n], &mut bytes), Ok(text.len()));
            assert_eq!(&bytes[..text.len()], text.as_bytes());
            let mut le = [0; 4];
            assert_eq!(from_utf8_le(text.as_bytes(), &mut le), Ok(n * 2));
            for i in 0..n {
                assert_eq!(&le[i * 2..i * 2 + 2], &expected[i].to_le_bytes());
            }
            assert_eq!(validate_le(&le[..n * 2]), Ok(text.len()));
            assert_eq!(le_to_utf8(&le[..n * 2], &mut bytes), Ok(text.len()));
            assert_eq!(&bytes[..text.len()], text.as_bytes());
        }
    }

    #[test]
    fn malformed_utf8_utf16_and_every_short_output_preserve_all_caller_bytes() {
        for input in [
            &b"\xc1\xa1"[..],
            b"\xe0\x80\xaf",
            b"\xed\xa0\x80",
            b"\xf4\x90\x80\x80",
            b"\xc3",
            b"\x80",
            b"A\xe2\x82",
        ] {
            let mut units = [0x5a5a; 12];
            let mut bytes = [0xa5; 24];
            assert_eq!(from_utf8(input, &mut units), Err(Error::InvalidUtf8));
            assert_eq!(from_utf8_le(input, &mut bytes), Err(Error::InvalidUtf8));
            assert_eq!(units, [0x5a5a; 12]);
            assert_eq!(bytes, [0xa5; 24]);
        }
        for unit in 0xd800u16..=0xdfff {
            let mut out = [0xa5; 16];
            assert_eq!(
                to_utf8(&[b'A' as u16, unit], &mut out),
                Err(Error::InvalidUtf16)
            );
            assert_eq!(
                le_to_utf8(&unit.to_le_bytes(), &mut out),
                Err(Error::InvalidUtf16)
            );
            assert_eq!(out, [0xa5; 16]);
        }
        for input in [&b"A"[..], b"A\0B", b"\x00\xd8\x41\x00", b"\x00\xdc\x00\xd8"] {
            let mut out = [0xa5; 16];
            assert_eq!(le_to_utf8(input, &mut out), Err(Error::InvalidUtf16));
            assert_eq!(out, [0xa5; 16]);
        }
        let text = "A\u{fc}\u{1f600}Z";
        let mut units = [0; 5];
        assert_eq!(from_utf8(text.as_bytes(), &mut units), Ok(5));
        for cap in 0..5 {
            let mut out = [0x5a5a; 8];
            assert_eq!(
                from_utf8(text.as_bytes(), &mut out[..cap]),
                Err(Error::BufferTooSmall)
            );
            assert_eq!(out, [0x5a5a; 8]);
        }
        for cap in 0..10 {
            let mut out = [0xa5; 16];
            assert_eq!(
                from_utf8_le(text.as_bytes(), &mut out[..cap]),
                Err(Error::BufferTooSmall)
            );
            assert_eq!(out, [0xa5; 16]);
        }
        for cap in 0..text.len() {
            let mut out = [0xa5; 16];
            assert_eq!(to_utf8(&units, &mut out[..cap]), Err(Error::BufferTooSmall));
            assert_eq!(out, [0xa5; 16]);
        }
        let mut le = [0; 10];
        from_utf8_le(text.as_bytes(), &mut le).unwrap();
        for cap in 0..text.len() {
            let mut out = [0xa5; 16];
            assert_eq!(le_to_utf8(&le, &mut out[..cap]), Err(Error::BufferTooSmall));
            assert_eq!(out, [0xa5; 16]);
        }
        let mut out = [0xa5; 16];
        assert_eq!(le_to_utf8(&le, &mut out[..text.len()]), Ok(text.len()));
        assert_eq!(&out[..text.len()], text.as_bytes());
        assert_eq!(&out[text.len()..], &[0xa5; 16][text.len()..]);
    }
}
