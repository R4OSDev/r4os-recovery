#![no_std]
//! Pure text primitives for resident native consumers. R4STD owns the pinned
//! mapping data; presentation, controls, replacement and column policy remain
//! with each consumer. No allocation, CPU probes or hardware instructions.
mod tables;
pub mod utf16;
pub const UTF8: u32 = 65001;
pub const CP437: u32 = 437;
pub const WINDOWS1252: u32 = 1252;
pub const REPLACEMENT: u32 = 0xfffd;
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LegacyError {
    Unsupported,
    Undefined,
    InvalidScalar,
    Unrepresentable,
}
pub fn supported(encoding: u32) -> bool {
    matches!(encoding, UTF8 | CP437 | WINDOWS1252)
}
pub fn legacy_decode(encoding: u32, byte: u8) -> Result<u32, LegacyError> {
    let table = match encoding {
        CP437 => &tables::CP437,
        WINDOWS1252 => &tables::WINDOWS1252,
        _ => return Err(LegacyError::Unsupported),
    };
    let scalar = table[usize::from(byte)];
    if scalar == u32::MAX {
        Err(LegacyError::Undefined)
    } else {
        Ok(scalar)
    }
}
pub fn legacy_encode(encoding: u32, scalar: u32) -> Result<u8, LegacyError> {
    if char::from_u32(scalar).is_none() {
        return Err(LegacyError::InvalidScalar);
    }
    let table = match encoding {
        CP437 => &tables::CP437,
        WINDOWS1252 => &tables::WINDOWS1252,
        _ => return Err(LegacyError::Unsupported),
    };
    table
        .iter()
        .position(|&v| v == scalar)
        .map(|i| i as u8)
        .ok_or(LegacyError::Unrepresentable)
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Decoded {
    Scalar(u32),
    Incomplete,
    Invalid,
}
#[derive(Clone, Copy, Default, Debug, PartialEq, Eq)]
pub struct Stream {
    bytes: [u8; 4],
    len: u8,
}
impl Stream {
    pub const EMPTY: Self = Self {
        bytes: [0; 4],
        len: 0,
    };
    pub fn pending(self) -> u32 {
        u32::from(self.len)
    }
    pub fn clear(&mut self) -> u32 {
        let old = self.pending();
        *self = Self::EMPTY;
        old
    }
    /// A negative result consumes nothing and preserves the old state, just
    /// like CODEC_V1. The caller chooses whether to reset/retry/report.
    pub fn push(&mut self, byte: u8) -> Decoded {
        if self.len >= 4 {
            return Decoded::Invalid;
        }
        let mut candidate = *self;
        candidate.bytes[usize::from(candidate.len)] = byte;
        candidate.len += 1;
        match core::str::from_utf8(&candidate.bytes[..usize::from(candidate.len)]) {
            Ok(text) => {
                let scalar = u32::from(text.chars().next().expect("nonempty scalar"));
                *self = Self::EMPTY;
                Decoded::Scalar(scalar)
            }
            Err(error) if error.error_len().is_none() => {
                *self = candidate;
                Decoded::Incomplete
            }
            Err(_) => Decoded::Invalid,
        }
    }
}
/// The byte prefix ending at a complete valid scalar. Incomplete/malformed
/// suffixes are never made printable by guessing a codepage.
pub fn complete_prefix(bytes: &[u8]) -> usize {
    match core::str::from_utf8(bytes) {
        Ok(_) => bytes.len(),
        Err(error) => error.valid_up_to(),
    }
}
pub fn continuation(byte: u8) -> bool {
    byte & 0xc0 == 0x80
}
pub fn encode(scalar: u32, out: &mut [u8; 4]) -> Option<&str> {
    Some(char::from_u32(scalar)?.encode_utf8(out))
}

pub fn printable(scalar: u32) -> bool {
    scalar >= 0x20 && scalar != 0x7f && !(0x80..=0x9f).contains(&scalar)
}

/// One decoder per output stream. Transcripts only receive complete canonical
/// UTF-8 scalars. Malformed prefixes produce U+FFFD; the offending byte is then
/// retried as a fresh sequence, preserving a following ASCII/control character.
#[derive(Clone, Copy, Debug)]
pub struct Output {
    pub encoding: u32,
    pub errors: u32,
    pub truncated: u32,
    pub closed: bool,
    streams: [Stream; 3],
}
impl Output {
    pub const EMPTY: Self = Self {
        encoding: UTF8,
        errors: 0,
        truncated: 0,
        closed: false,
        streams: [Stream::EMPTY; 3],
    };
    pub fn pending(self) -> u32 {
        self.streams.iter().map(|s| s.pending()).sum()
    }
    pub fn configure(&mut self, encoding: u32) -> bool {
        if self.closed || !supported(encoding) || self.pending() != 0 {
            return false;
        }
        self.encoding = encoding;
        true
    }
    pub fn push(&mut self, stream: usize, byte: u8) -> [Option<u32>; 2] {
        if self.closed || stream >= self.streams.len() {
            return [None, None];
        }
        if self.encoding != UTF8 {
            let scalar = legacy_decode(self.encoding, byte).unwrap_or_else(|_| {
                self.errors = self.errors.wrapping_add(1);
                REPLACEMENT
            });
            return [Some(scalar), None];
        }
        let decoder = &mut self.streams[stream];
        match decoder.push(byte) {
            Decoded::Scalar(value) => [Some(value), None],
            Decoded::Incomplete => [None, None],
            Decoded::Invalid => {
                self.errors = self.errors.wrapping_add(1);
                let had_prefix = decoder.clear() != 0;
                let retry = if had_prefix {
                    match decoder.push(byte) {
                        Decoded::Scalar(value) => Some(value),
                        Decoded::Incomplete => None,
                        Decoded::Invalid => {
                            self.errors = self.errors.wrapping_add(1);
                            Some(REPLACEMENT)
                        }
                    }
                } else {
                    None
                };
                [Some(REPLACEMENT), retry]
            }
        }
    }
    pub fn finish(&mut self, stream: usize) -> Option<u32> {
        if stream >= self.streams.len() || self.streams[stream].clear() == 0 {
            return None;
        }
        self.truncated = self.truncated.wrapping_add(1);
        Some(REPLACEMENT)
    }
}

#[cfg(test)]
mod tests {
    extern crate std;
    use super::*;
    #[test]
    fn output_streams_legacy_conversion_recovery_and_close() {
        let mut output = Output::EMPTY;
        assert_eq!(output.push(1, 0xc3), [None, None]);
        assert_eq!(output.pending(), 1);
        assert!(!output.configure(CP437));
        assert_eq!(output.push(2, b'Z'), [Some(90), None]);
        assert_eq!(output.push(1, 0xbc), [Some(0xfc), None]);
        assert!(output.configure(CP437));
        assert_eq!(output.push(1, 0xc4), [Some(0x2500), None]);
        assert_eq!(output.push(1, 0x81), [Some(0xfc), None]);
        assert!(output.configure(UTF8));
        assert_eq!(output.push(1, 0xc3), [None, None]);
        assert_eq!(output.push(1, b'\n'), [Some(REPLACEMENT), Some(10)]);
        assert_eq!(output.errors, 1);
        assert_eq!(output.push(2, 0xf0), [None, None]);
        assert_eq!(output.finish(2), Some(REPLACEMENT));
        assert_eq!(output.finish(2), None);
        assert_eq!(output.truncated, 1);
        output.closed = true;
        assert!(!output.configure(CP437));
        assert_eq!(output.push(1, b'Z'), [None, None]);
    }
    fn table_matches_original(encoding: u32, original: &str, undefined: usize) {
        let mut expected = [None; 256];
        for line in original.lines() {
            let mut fields = line.split('#').next().unwrap().split_whitespace();
            let Some(byte) = fields.next() else {
                continue;
            };
            let Some(scalar) = fields.next() else {
                continue;
            };
            if !scalar.starts_with("0x") {
                continue;
            }
            let byte = usize::from_str_radix(byte.trim_start_matches("0x"), 16).unwrap();
            expected[byte] =
                Some(u32::from_str_radix(scalar.trim_start_matches("0x"), 16).unwrap());
        }
        let mut holes = 0;
        for (byte, scalar) in expected.into_iter().enumerate() {
            match scalar {
                Some(scalar) => {
                    assert_eq!(legacy_decode(encoding, byte as u8), Ok(scalar));
                    assert_eq!(legacy_encode(encoding, scalar), Ok(byte as u8));
                }
                None => {
                    assert_eq!(
                        legacy_decode(encoding, byte as u8),
                        Err(LegacyError::Undefined)
                    );
                    holes += 1;
                }
            }
        }
        assert_eq!(holes, undefined);
    }
    #[test]
    fn exact_official_tables_and_inverse() {
        table_matches_original(CP437, include_str!("../ThirdParty/Unicode/CP437.TXT"), 0);
        table_matches_original(
            WINDOWS1252,
            include_str!("../ThirdParty/Unicode/CP1252.TXT"),
            5,
        );
        assert_eq!(legacy_decode(CP437, 0xc4), Ok(0x2500));
        assert_eq!(legacy_decode(CP437, 0x81), Ok(0xfc));
        assert_eq!(legacy_decode(850, 0x81), Err(LegacyError::Unsupported));
        assert_eq!(
            legacy_encode(CP437, 0x20ac),
            Err(LegacyError::Unrepresentable)
        );
    }
    #[test]
    fn every_scalar_and_every_split_uses_strict_complete_values() {
        for scalar in 0..=0x10ffff {
            let Some(value) = char::from_u32(scalar) else {
                continue;
            };
            let mut out = [0; 4];
            let bytes = value.encode_utf8(&mut out).as_bytes();
            let mut stream = Stream::EMPTY;
            for (index, &byte) in bytes.iter().enumerate() {
                let result = stream.push(byte);
                assert_eq!(
                    result,
                    if index + 1 == bytes.len() {
                        Decoded::Scalar(scalar)
                    } else {
                        Decoded::Incomplete
                    }
                );
                assert_eq!(
                    complete_prefix(&bytes[..index + 1]),
                    if index + 1 == bytes.len() {
                        bytes.len()
                    } else {
                        0
                    }
                );
            }
            assert_eq!(stream.pending(), 0);
        }
    }
    #[test]
    fn invalid_does_not_consume_state_and_clear_reports_the_exact_prefix() {
        for bytes in [
            &b"\xc0\x80"[..],
            &b"\xed\xa0\x80"[..],
            &b"\xf4\x90\x80\x80"[..],
            &b"\x80"[..],
        ] {
            let mut stream = Stream::EMPTY;
            for &byte in bytes {
                let old = stream;
                if stream.push(byte) == Decoded::Invalid {
                    assert_eq!(stream, old);
                    break;
                }
            }
        }
        let mut stream = Stream::EMPTY;
        assert_eq!(stream.push(0xd0), Decoded::Incomplete);
        let old = stream;
        assert_eq!(stream.push(b'Q'), Decoded::Invalid);
        assert_eq!(stream, old);
        assert_eq!(stream.clear(), 1);
        assert_eq!(stream.push(b'Q'), Decoded::Scalar(u32::from(b'Q')));
    }
    #[test]
    fn independent_streams_scalar_byte_counts_and_exact_prefix_limits() {
        let mut a = Stream::EMPTY;
        let mut b = Stream::EMPTY;
        assert_eq!(a.push(0xc3), Decoded::Incomplete);
        assert_eq!(b.push(0xd0), Decoded::Incomplete);
        assert_eq!(a.push(0xbc), Decoded::Scalar(0xfc));
        assert_eq!(b.push(0x81), Decoded::Scalar(0x401));
        let text = "A\u{fc}\u{20ac}\u{1f600}".as_bytes();
        for cap in 0..=text.len() {
            let prefix = complete_prefix(&text[..cap]);
            assert!(core::str::from_utf8(&text[..prefix]).is_ok());
        }
        assert_eq!(complete_prefix(&text[..2]), 1);
        assert_eq!(complete_prefix(&text[..5]), 3);
    }
}
