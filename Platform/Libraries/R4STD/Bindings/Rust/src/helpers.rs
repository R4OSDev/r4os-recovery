//! R4STD higher helpers over the original native owner. Bytes, scalars and
//! graphemes are separate quantities; none of them promises rendered width.
use crate::{Error, Result, raw as c, required, result, scalar, storage, view};
use alloc::boxed::Box;
use core::{ffi::CStr, marker::PhantomData, mem::MaybeUninit, ptr::NonNull};
use r4os_sdk::App;

pub struct Standard<'a> {
    session: Box<MaybeUninit<c::R4LibrarySession>>,
    _app: PhantomData<&'a App<'a>>,
    _local: PhantomData<*mut ()>,
}
impl<'a> Standard<'a> {
    pub fn open(app: &'a App<'_>) -> Result<Self> {
        let mut session = storage();
        if scalar(unsafe {
            c::R4Library_openSession(0, session.as_mut_ptr(), app.start_context())
        })? == 0
            || scalar(unsafe { c::R4Std_init(0, app.start_context()) })? == 0
        {
            return Err(Error::Unavailable);
        }
        Ok(Self {
            session,
            _app: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn utf8<'s, 'b>(&'s self, bytes: &'b [u8]) -> Result<Utf8<'s, 'b>> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4StdTextUtf8Text_init(0, bytes.as_ptr(), bytes.len() as u64, native.as_mut_ptr())
        })?;
        Ok(Utf8 {
            native,
            _standard: PhantomData,
            _bytes: PhantomData,
        })
    }
    pub fn open2(app: &'a r4os_sdk::app2::App<'_>) -> Result<Self> {
        let mut session = storage();
        if scalar(unsafe {
            c::R4Library_openSession2(
                0,
                session.as_mut_ptr(),
                core::ptr::from_ref(app.start_context()).cast(),
            )
        })? == 0
            || scalar(unsafe {
                c::R4Std_init2(0, core::ptr::from_ref(app.start_context()).cast())
            })? == 0
        {
            return Err(Error::Unavailable);
        }
        Ok(Self {
            session,
            _app: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn canonicalize<'b>(&self, bytes: &[u8], output: &'b mut [u8]) -> Result<&'b str> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4StdTextSystemText_parse(0, bytes.as_ptr(), bytes.len() as u64, native.as_mut_ptr())
        })?;
        let value = unsafe {
            c::R4StdTextSystemText_writeCanonical(
                0,
                native.as_ptr(),
                output.as_mut_ptr(),
                output.len() as u64,
            )
        };
        core::str::from_utf8(view(value, output)?).map_err(|_| Error::InvalidProvider)
    }
    pub fn settings<'s, 'b>(&'s self, bytes: &'b [u8]) -> Result<Document<'s, 'b>> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4StdSettingsDocument_init(
                0,
                bytes.as_ptr(),
                bytes.len() as u64,
                native.as_mut_ptr(),
            )
        })?;
        Ok(Document {
            native,
            bytes,
            _standard: PhantomData,
        })
    }
    pub fn entries<'s, 'b>(&'s self, bytes: &'b [u8]) -> Result<Entries<'s, 'b>> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4StdSettingsEntryIterator_init(
                0,
                bytes.as_ptr(),
                bytes.len() as u64,
                native.as_mut_ptr(),
            )
        })?;
        Ok(Entries {
            native,
            bytes,
            ended: false,
            _standard: PhantomData,
        })
    }
    pub fn shortcut<'s>(&'s self, target: &[u8]) -> Result<Shortcut<'s>> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4StdShortcutShortcut_init(
                0,
                target.as_ptr(),
                target.len() as u64,
                native.as_mut_ptr(),
            )
        })?;
        Ok(Shortcut {
            native,
            _standard: PhantomData,
        })
    }
    pub fn parse_shortcut<'s>(&'s self, bytes: &[u8]) -> Result<Shortcut<'s>> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4StdShortcut_parse(0, bytes.as_ptr(), bytes.len() as u64, native.as_mut_ptr())
        })?;
        Ok(Shortcut {
            native,
            _standard: PhantomData,
        })
    }
    pub fn writer<'s, 'b>(&'s self, output: &'b mut [u8]) -> Result<Writer<'s, 'b>> {
        let mut native = MaybeUninit::uninit();
        let buffer = NonNull::new(output.as_mut_ptr()).ok_or(Error::InvalidProvider)?;
        let length = output.len();
        required(unsafe {
            c::R4StdSettingsWriter_init(0, buffer.as_ptr(), length as u64, native.as_mut_ptr())
        })?;
        Ok(Writer {
            native,
            buffer,
            length,
            _standard: PhantomData,
            _buffer: PhantomData,
        })
    }
    pub fn codec(&self) -> Codec<'_> {
        Codec {
            _standard: PhantomData,
        }
    }
    pub fn date_days(&self, year: u16, month: u8) -> Result<u8> {
        Ok(scalar(unsafe { c::R4StdDate_daysInMonth(0, year, month) })? as u8)
    }
    pub fn parse_date_time(&self, bytes: &str) -> Result<Option<DateTime>> {
        let mut native = MaybeUninit::uninit();
        let answer = result(unsafe {
            c::R4StdDate_parseDateTimeIso(
                0,
                bytes.as_ptr(),
                bytes.len() as u64,
                native.as_mut_ptr(),
            )
        })?;
        if answer.flags & 1 == 0 {
            return Ok(None);
        }
        DateTime::read(native.as_ptr()).map(Some)
    }
    pub fn format_date_time<'b>(&self, value: DateTime, output: &'b mut [u8]) -> Result<&'b str> {
        let native = value.native()?;
        let value = unsafe {
            c::R4StdDate_formatDateTimeIso(
                0,
                output.as_mut_ptr(),
                output.len() as u64,
                native.as_ptr(),
            )
        };
        core::str::from_utf8(view(value, output)?).map_err(|_| Error::InvalidProvider)
    }
    pub fn zone_count(&self) -> Result<usize> {
        Ok(scalar(unsafe { c::R4StdTime_zoneCount(0) })? as usize)
    }
    pub fn zone_id<'b>(&self, index: usize, output: &'b mut [u8]) -> Result<&'b str> {
        let value = unsafe {
            c::R4StdTime_copyZoneId(0, output.as_mut_ptr(), output.len() as u64, index as u64)
        };
        core::str::from_utf8(view(value, output)?).map_err(|_| Error::InvalidProvider)
    }
    pub fn config_read_u32(&self, path: &CStr, key: &[u8], fallback: u32) -> Result<(i32, u32)> {
        let sys =
            required(unsafe { c::R4Library_system(0, self.session.as_ptr().cast_mut()) })?.ptr;
        let mut output = fallback;
        let answer = scalar(unsafe {
            c::R4StdAdaptersConfig_readU32(
                0,
                sys.cast(),
                path.as_ptr().cast(),
                key.as_ptr(),
                key.len() as u64,
                fallback,
                &mut output,
            )
        })? as i32;
        Ok((answer, output))
    }
    pub fn config_write_u32(&self, path: &CStr, key: &[u8], value: u32) -> Result<i32> {
        let sys =
            required(unsafe { c::R4Library_system(0, self.session.as_ptr().cast_mut()) })?.ptr;
        Ok(scalar(unsafe {
            c::R4StdAdaptersConfig_writeU32(
                0,
                sys.cast(),
                path.as_ptr().cast(),
                key.as_ptr(),
                key.len() as u64,
                value,
            )
        })? as i32)
    }
}

pub struct Utf8<'s, 'b> {
    native: MaybeUninit<c::R4StdTextUtf8Text>,
    _standard: PhantomData<&'s Standard<'s>>,
    _bytes: PhantomData<&'b [u8]>,
}
impl Utf8<'_, '_> {
    pub fn byte_len(&self) -> Result<usize> {
        Ok(scalar(unsafe { c::R4StdTextUtf8Text_byteLen(0, self.native.as_ptr()) })? as usize)
    }
    pub fn scalar_count(&self) -> Result<usize> {
        Ok(scalar(unsafe { c::R4StdTextUtf8Text_scalarCount(0, self.native.as_ptr()) })? as usize)
    }
}
/// The original shortcut owns fixed byte arrays and retains no input pointer.
/// Native getters return short views into those arrays. A mutable operation
/// cannot run while a previous view is borrowed; opaque padding is never read.
pub struct Shortcut<'s> {
    native: MaybeUninit<c::R4StdShortcutShortcut>,
    _standard: PhantomData<&'s Standard<'s>>,
}
pub struct ResolvedShortcut<'a> {
    pub kind: u32,
    pub policy: u32,
    pub target: &'a [u8],
    pub title: &'a [u8],
    pub args: &'a [u8],
    pub icon: &'a [u8],
    pub workdir: &'a [u8],
}
impl Shortcut<'_> {
    fn field(&self, value: c::R4LibrariesSlot) -> Result<&[u8]> {
        let value = result(value)?;
        if value.flags & 1 == 0 {
            return Err(Error::InvalidProvider);
        }
        if value.length == 0 {
            return Ok(&[]);
        }
        let address = value.ptr as usize;
        let begin = self.native.as_ptr() as usize;
        let end = begin
            .checked_add(core::mem::size_of::<c::R4StdShortcutShortcut>())
            .ok_or(Error::InvalidProvider)?;
        let len = usize::try_from(value.length).map_err(|_| Error::InvalidProvider)?;
        if address < begin || address > end || len > end - address {
            return Err(Error::InvalidProvider);
        }
        // The original native getter identifies initialized owned text, not
        // the entire opaque record which can contain uninitialized padding.
        Ok(unsafe { core::slice::from_raw_parts(value.ptr.cast(), len) })
    }
    pub fn target(&self) -> Result<&[u8]> {
        self.field(unsafe { c::R4StdShortcutShortcut_targetText(0, self.native.as_ptr()) })
    }
    pub fn title(&self) -> Result<&[u8]> {
        self.field(unsafe { c::R4StdShortcutShortcut_titleText(0, self.native.as_ptr()) })
    }
    pub fn args(&self) -> Result<&[u8]> {
        self.field(unsafe { c::R4StdShortcutShortcut_argsText(0, self.native.as_ptr()) })
    }
    pub fn icon(&self) -> Result<&[u8]> {
        self.field(unsafe { c::R4StdShortcutShortcut_iconText(0, self.native.as_ptr()) })
    }
    pub fn set_target(&mut self, value: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4StdShortcutShortcut_setTarget(
                0,
                self.native.as_mut_ptr(),
                value.as_ptr(),
                value.len() as u64,
            )
        })
        .map(|_| ())
    }
    pub fn set_title(&mut self, value: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4StdShortcutShortcut_setTitle(
                0,
                self.native.as_mut_ptr(),
                value.as_ptr(),
                value.len() as u64,
            )
        })
        .map(|_| ())
    }
    pub fn set_args(&mut self, value: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4StdShortcutShortcut_setArgs(
                0,
                self.native.as_mut_ptr(),
                value.as_ptr(),
                value.len() as u64,
            )
        })
        .map(|_| ())
    }
    pub fn set_icon(&mut self, value: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4StdShortcutShortcut_setIcon(
                0,
                self.native.as_mut_ptr(),
                value.as_ptr(),
                value.len() as u64,
            )
        })
        .map(|_| ())
    }
    pub fn set_workdir(&mut self, value: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4StdShortcutShortcut_setWorkdir(
                0,
                self.native.as_mut_ptr(),
                value.as_ptr(),
                value.len() as u64,
            )
        })
        .map(|_| ())
    }
    pub fn set_policy(&mut self, value: crate::abi::LaunchPolicy) -> Result<()> {
        result(unsafe { c::R4StdShortcutShortcut_setPolicy(0, self.native.as_mut_ptr(), value.0) })
            .map(|_| ())
    }
    pub fn write<'out>(&self, out: &'out mut [u8]) -> Result<&'out [u8]> {
        view(
            unsafe {
                c::R4StdShortcutShortcut_writeTo(
                    0,
                    self.native.as_ptr(),
                    out.as_mut_ptr(),
                    out.len() as u64,
                )
            },
            out,
        )
    }
    pub fn resolve(&self) -> Result<ResolvedShortcut<'_>> {
        let mut value = MaybeUninit::uninit();
        required(unsafe {
            c::R4StdShortcutShortcut_resolve(0, self.native.as_ptr(), value.as_mut_ptr())
        })?;
        let value = value.as_ptr();
        Ok(ResolvedShortcut {
            kind: scalar(unsafe { c::R4StdShortcutResolvedTarget_get_kind(value) })? as u32,
            policy: scalar(unsafe { c::R4StdShortcutResolvedTarget_get_policy(value) })? as u32,
            target: self.field(unsafe { c::R4StdShortcutResolvedTarget_get_target(value) })?,
            title: self.field(unsafe { c::R4StdShortcutResolvedTarget_get_title(value) })?,
            args: self.field(unsafe { c::R4StdShortcutResolvedTarget_get_args(value) })?,
            icon: self.field(unsafe { c::R4StdShortcutResolvedTarget_get_icon(value) })?,
            workdir: self.field(unsafe { c::R4StdShortcutResolvedTarget_get_workdir(value) })?,
        })
    }
}
pub struct Document<'s, 'b> {
    native: MaybeUninit<c::R4StdSettingsDocument>,
    bytes: &'b [u8],
    _standard: PhantomData<&'s Standard<'s>>,
}
impl<'b> Document<'_, 'b> {
    pub fn has_supported_format(&self) -> Result<bool> {
        Ok(
            scalar(unsafe {
                c::R4StdSettingsDocument_hasSupportedFormat(0, self.native.as_ptr())
            })? != 0,
        )
    }
    pub fn schema_name(&self) -> Result<Option<&'b [u8]>> {
        let value =
            result(unsafe { c::R4StdSettingsDocument_schemaName(0, self.native.as_ptr()) })?;
        if value.flags & 1 == 0 {
            return Ok(None);
        }
        view(value, self.bytes).map(Some)
    }
    pub fn value(&self, key: &[u8]) -> Result<Option<&'b [u8]>> {
        let answer = result(unsafe {
            c::R4StdSettingsDocument_value(0, self.native.as_ptr(), key.as_ptr(), key.len() as u64)
        })?;
        if answer.flags & 1 == 0 {
            return Ok(None);
        }
        view(answer, self.bytes).map(Some)
    }
    pub fn u32_value(&self, key: &[u8]) -> Result<Option<u32>> {
        let answer = result(unsafe {
            c::R4StdSettingsDocument_u32Value(
                0,
                self.native.as_ptr(),
                key.as_ptr(),
                key.len() as u64,
            )
        })?;
        Ok((answer.flags & 1 != 0).then_some(answer.bits as u32))
    }
    pub fn bool_value(&self, key: &[u8]) -> Result<Option<bool>> {
        let answer = result(unsafe {
            c::R4StdSettingsDocument_boolValue(
                0,
                self.native.as_ptr(),
                key.as_ptr(),
                key.len() as u64,
            )
        })?;
        Ok((answer.flags & 1 != 0).then_some(answer.bits != 0))
    }
}
pub struct Entries<'s, 'b> {
    native: MaybeUninit<c::R4StdSettingsEntryIterator>,
    bytes: &'b [u8],
    ended: bool,
    _standard: PhantomData<&'s Standard<'s>>,
}
impl<'b> Iterator for Entries<'_, 'b> {
    type Item = Result<(&'b [u8], &'b [u8])>;
    fn next(&mut self) -> Option<Self::Item> {
        if self.ended {
            return None;
        }
        let mut entry = MaybeUninit::uninit();
        let answer = match result(unsafe {
            c::R4StdSettingsEntryIterator_next(0, self.native.as_mut_ptr(), entry.as_mut_ptr())
        }) {
            Ok(v) => v,
            Err(e) => {
                self.ended = true;
                return Some(Err(e));
            }
        };
        if answer.flags & 1 == 0 {
            self.ended = true;
            return None;
        }
        Some((|| {
            Ok((
                view(
                    unsafe { c::R4StdSettingsEntry_get_key(entry.as_ptr()) },
                    self.bytes,
                )?,
                view(
                    unsafe { c::R4StdSettingsEntry_get_value(entry.as_ptr()) },
                    self.bytes,
                )?,
            ))
        })())
    }
}
pub struct Writer<'s, 'b> {
    native: MaybeUninit<c::R4StdSettingsWriter>,
    buffer: NonNull<u8>,
    length: usize,
    _standard: PhantomData<&'s Standard<'s>>,
    _buffer: PhantomData<&'b mut [u8]>,
}
impl Writer<'_, '_> {
    pub fn header(&mut self, schema: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4StdSettingsWriter_writeHeader(
                0,
                self.native.as_mut_ptr(),
                schema.as_ptr(),
                schema.len() as u64,
            )
        })
        .map(|_| ())
    }
    pub fn pair(&mut self, key: &[u8], value: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4StdSettingsWriter_writePair(
                0,
                self.native.as_mut_ptr(),
                key.as_ptr(),
                key.len() as u64,
                value.as_ptr(),
                value.len() as u64,
            )
        })
        .map(|_| ())
    }
    pub fn u32_pair(&mut self, key: &[u8], value: u32) -> Result<()> {
        result(unsafe {
            c::R4StdSettingsWriter_writePairU32(
                0,
                self.native.as_mut_ptr(),
                key.as_ptr(),
                key.len() as u64,
                value,
            )
        })
        .map(|_| ())
    }
    pub fn i32_pair(&mut self, key: &[u8], value: i32) -> Result<()> {
        result(unsafe {
            c::R4StdSettingsWriter_writePairI32(
                0,
                self.native.as_mut_ptr(),
                key.as_ptr(),
                key.len() as u64,
                value,
            )
        })
        .map(|_| ())
    }
    pub fn bool_pair(&mut self, key: &[u8], value: bool) -> Result<()> {
        result(unsafe {
            c::R4StdSettingsWriter_writePairBool(
                0,
                self.native.as_mut_ptr(),
                key.as_ptr(),
                key.len() as u64,
                u8::from(value),
            )
        })
        .map(|_| ())
    }
    pub fn rgb24_pair(&mut self, key: &[u8], value: u32) -> Result<()> {
        result(unsafe {
            c::R4StdSettingsWriter_writePairRgb24(
                0,
                self.native.as_mut_ptr(),
                key.as_ptr(),
                key.len() as u64,
                value,
            )
        })
        .map(|_| ())
    }
    pub fn is_ok(&self) -> Result<bool> {
        Ok(scalar(unsafe { c::R4StdSettingsWriter_ok(0, self.native.as_ptr()) })? != 0)
    }
    pub fn bytes(&self) -> Result<&[u8]> {
        view(
            unsafe { c::R4StdSettingsWriter_bytes(0, self.native.as_ptr()) },
            unsafe { core::slice::from_raw_parts(self.buffer.as_ptr(), self.length) },
        )
    }
}
pub struct Graphemes<'b> {
    native: MaybeUninit<c::R4StdGraphemeIterator>,
    bytes: &'b [u8],
    ended: bool,
}
impl<'b> Graphemes<'b> {
    pub fn new(bytes: &'b [u8]) -> Result<Self> {
        let mut native = MaybeUninit::uninit();
        required(unsafe {
            c::R4StdGraphemeIterator_create(native.as_mut_ptr(), bytes.as_ptr(), bytes.len() as u64)
        })?;
        Ok(Self {
            native,
            bytes,
            ended: false,
        })
    }
    pub fn prefix(bytes: &[u8], capacity: usize) -> Result<usize> {
        Ok(scalar(unsafe {
            c::R4StdGrapheme_prefix(0, bytes.as_ptr(), bytes.len() as u64, capacity as u64)
        })? as usize)
    }
}
impl<'b> Iterator for Graphemes<'b> {
    type Item = Result<&'b [u8]>;
    fn next(&mut self) -> Option<Self::Item> {
        if self.ended {
            return None;
        }
        let mut range = MaybeUninit::uninit();
        let answer = match result(unsafe {
            c::R4StdGraphemeIterator_next(0, self.native.as_mut_ptr(), range.as_mut_ptr())
        }) {
            Ok(v) => v,
            Err(e) => {
                self.ended = true;
                return Some(Err(e));
            }
        };
        if answer.flags & 1 == 0 {
            self.ended = true;
            return None;
        }
        Some((|| {
            let a = scalar(unsafe { c::R4StdGraphemeRange_get_start(range.as_ptr()) })? as usize;
            let b = scalar(unsafe { c::R4StdGraphemeRange_get_end(range.as_ptr()) })? as usize;
            self.bytes.get(a..b).ok_or(Error::InvalidProvider)
        })())
    }
}
#[repr(u32)]
#[derive(Clone, Copy)]
pub enum Codepage {
    Cp437 = 437,
    Windows1252 = 1252,
    Cp850 = 850,
}
#[repr(u32)]
#[derive(Clone, Copy)]
pub enum Mode {
    Controls = 0,
    PcGraphics = 1,
}
pub struct Codec<'s> {
    _standard: PhantomData<&'s Standard<'s>>,
}
impl<'s> Codec<'s> {
    pub fn decode_legacy(&self, codepage: Codepage, mode: Mode, byte: u8) -> Result<char> {
        char::from_u32(scalar(unsafe {
            c::R4StdCodec_legacyDecode(0, codepage as u32, mode as u32, byte)
        })? as u32)
        .ok_or(Error::InvalidProvider)
    }
    pub fn legacy_to_utf8<'b>(
        &self,
        codepage: Codepage,
        mode: Mode,
        bytes: &[u8],
        output: &'b mut [u8],
    ) -> Result<&'b str> {
        let answer = unsafe {
            c::R4StdCodec_legacyToUtf8(
                0,
                codepage as u32,
                mode as u32,
                bytes.as_ptr(),
                bytes.len() as u64,
                output.as_mut_ptr(),
                output.len() as u64,
            )
        };
        core::str::from_utf8(view(answer, output)?).map_err(|_| Error::InvalidProvider)
    }
    pub fn utf8_to_legacy<'b>(
        &self,
        codepage: Codepage,
        mode: Mode,
        bytes: &str,
        output: &'b mut [u8],
    ) -> Result<&'b [u8]> {
        view(
            unsafe {
                c::R4StdCodec_utf8ToLegacy(
                    0,
                    codepage as u32,
                    mode as u32,
                    bytes.as_ptr(),
                    bytes.len() as u64,
                    output.as_mut_ptr(),
                    output.len() as u64,
                )
            },
            output,
        )
    }
    pub fn stream(&self) -> Result<Stream<'s>> {
        let mut native = MaybeUninit::uninit();
        required(unsafe { c::R4StdCodecStream_create(native.as_mut_ptr()) })?;
        Ok(Stream {
            native,
            _standard: PhantomData,
        })
    }
}
pub struct Stream<'s> {
    native: MaybeUninit<c::R4StdCodecStream>,
    _standard: PhantomData<&'s Standard<'s>>,
}
impl Stream<'_> {
    pub fn push(&mut self, byte: u8) -> Result<Option<char>> {
        let mut decoded = MaybeUninit::uninit();
        required(unsafe {
            c::R4StdCodecStream_push(0, self.native.as_mut_ptr(), byte, decoded.as_mut_ptr())
        })?;
        if scalar(unsafe { c::R4StdCodecDecoded_inspect(decoded.as_ptr()) })? != 0 {
            return Ok(None);
        }
        let mut value = MaybeUninit::uninit();
        required(unsafe {
            c::R4StdCodecDecoded_get_complete(decoded.as_ptr(), value.as_mut_ptr())
        })?;
        char::from_u32(scalar(unsafe { c::R4StdCodecScalar_get_value(value.as_ptr()) })? as u32)
            .map(Some)
            .ok_or(Error::InvalidProvider)
    }
    pub fn finish(&self) -> Result<bool> {
        Ok(scalar(unsafe { c::R4StdCodecStream_finish(0, self.native.as_ptr()) })? != 0)
    }
    pub fn reset(&mut self) -> Result<()> {
        result(unsafe { c::R4StdCodecStream_reset(0, self.native.as_mut_ptr()) }).map(|_| ())
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct DateTime {
    pub year: u16,
    pub month: u8,
    pub day: u8,
    pub hour: u8,
    pub minute: u8,
    pub second: u8,
}
impl DateTime {
    fn native(self) -> Result<MaybeUninit<c::R4StdDateDateTime>> {
        let mut date = MaybeUninit::uninit();
        let mut time = MaybeUninit::uninit();
        let mut out = MaybeUninit::uninit();
        required(unsafe {
            c::R4StdDateDate_from_fields(date.as_mut_ptr(), self.year, self.month, self.day)
        })?;
        required(unsafe {
            c::R4StdDateTimeOfDay_from_fields(
                time.as_mut_ptr(),
                self.hour,
                self.minute,
                self.second,
            )
        })?;
        required(unsafe {
            c::R4StdDateDateTime_from_fields(out.as_mut_ptr(), date.as_ptr(), time.as_ptr())
        })?;
        Ok(out)
    }
    fn read(native: *const c::R4StdDateDateTime) -> Result<Self> {
        let mut date = MaybeUninit::uninit();
        let mut time = MaybeUninit::uninit();
        required(unsafe { c::R4StdDateDateTime_get_date(native, date.as_mut_ptr()) })?;
        required(unsafe { c::R4StdDateDateTime_get_time(native, time.as_mut_ptr()) })?;
        Ok(Self {
            year: scalar(unsafe { c::R4StdDateDate_get_year(date.as_ptr()) })? as u16,
            month: scalar(unsafe { c::R4StdDateDate_get_month(date.as_ptr()) })? as u8,
            day: scalar(unsafe { c::R4StdDateDate_get_day(date.as_ptr()) })? as u8,
            hour: scalar(unsafe { c::R4StdDateTimeOfDay_get_hour(time.as_ptr()) })? as u8,
            minute: scalar(unsafe { c::R4StdDateTimeOfDay_get_minute(time.as_ptr()) })? as u8,
            second: scalar(unsafe { c::R4StdDateTimeOfDay_get_second(time.as_ptr()) })? as u8,
        })
    }
}
