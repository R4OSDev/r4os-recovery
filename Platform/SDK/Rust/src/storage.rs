//! Borrowed file, console and registry facade. R4SYS owns native identities.
use crate::{
    App, abi, c_facades as c,
    path::{FilePath, RegistryPath},
};
use core::{ffi::CStr, marker::PhantomData, mem::MaybeUninit};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Unavailable,
    Length,
    InvalidProvider,
    Raw(i32),
}
pub type Result<T> = core::result::Result<T, Error>;
pub(crate) fn length(n: usize) -> Result<u32> {
    u32::try_from(n).map_err(|_| Error::Length)
}
pub(crate) fn status(raw: i32) -> Result<()> {
    if raw < 0 {
        Err(Error::Raw(raw))
    } else {
        Ok(())
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Presence {
    Present,
    Missing,
}
fn operation(value: c::R4Operation) -> Result<Presence> {
    match value.state {
        0 => Ok(Presence::Present),
        1 => Ok(Presence::Missing),
        _ => Err(Error::Raw(value.raw_code)),
    }
}
// A stream operation needs its own successful acknowledgement. Missing may
// be useful for idempotent file deletion, but cannot finish/abort a retained
// stream or acknowledge bytes which the provider did not accept.
fn stream_operation(value: c::R4Operation) -> Result<()> {
    match operation(value)? {
        Presence::Present if value.raw_code == 0 => Ok(()),
        _ => Err(Error::Raw(value.raw_code)),
    }
}
fn transfer(value: c::R4Transfer, capacity: usize) -> Result<Option<usize>> {
    match value.state {
        0 if value.bytes as usize <= capacity => Ok(Some(value.bytes as usize)),
        0 => Err(Error::InvalidProvider),
        1 => Ok(None),
        _ => Err(Error::Raw(value.raw_code)),
    }
}

pub struct System<'a> {
    raw: c::R4Sys,
    _loan: PhantomData<&'a ()>,
    _local: PhantomData<*mut ()>,
}
impl<'a> System<'a> {
    pub fn new(app: &'a App<'_>) -> Result<Self> {
        let table = app.system_api().ok_or(Error::Unavailable)?;
        Ok(Self {
            raw: c::R4Sys {
                ctx: app.start_context(),
                table,
                generation2: core::ptr::null(),
                memory2: core::ptr::null(),
            },
            _loan: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn new2(app: &'a crate::app2::App<'_>) -> Result<Self> {
        let raw = c::R4Sys {
            ctx: core::ptr::null(),
            table: core::ptr::null(),
            generation2: app.native_context(),
            memory2: &app.memory,
        };
        Ok(Self {
            raw,
            _loan: PhantomData,
            _local: PhantomData,
        })
    }
    pub(crate) fn raw(&self) -> &c::R4Sys {
        &self.raw
    }
    pub fn files(&self) -> Files<'_> {
        Files { system: self }
    }
    pub fn registry(&self) -> Registry<'_> {
        Registry { system: self }
    }
    pub fn console(&self) -> Console<'_> {
        Console { system: self }
    }
    pub fn physical_storage(&self) -> crate::physical_storage::Storage<'_> {
        crate::physical_storage::Storage::new(self)
    }
    fn pointer(&self) -> *mut c::R4Sys {
        core::ptr::from_ref(&self.raw).cast_mut()
    }
}
#[derive(Clone, Copy)]
pub struct Console<'a> {
    system: &'a System<'a>,
}
impl Console<'_> {
    fn raw(&self) -> c::R4Console {
        c::R4Console {
            system: self.system.pointer(),
        }
    }
    pub fn available(&self) -> bool {
        unsafe { c::r4_console_available(&self.raw()) != 0 }
    }
    /// Bytes retain the console's selected encoding; no implicit conversion.
    pub fn write(&self, bytes: &[u8]) -> Result<()> {
        status(unsafe {
            c::r4_console_write_all(&mut self.raw(), bytes.as_ptr(), bytes.len() as u64)
        })
    }
    pub fn line_z(&self, text: &CStr) -> Result<i32> {
        let raw = unsafe { c::r4_console_line(&mut self.raw(), text.as_ptr().cast()) };
        status(raw)?;
        Ok(raw)
    }
    pub fn line(&self, bytes: &[u8]) -> Result<()> {
        status(unsafe { c::R4SdkConsole(self.system.raw(), bytes.as_ptr(), bytes.len() as u64, 1) })
    }
    pub fn put(&self, byte: u8) -> Result<()> {
        status(unsafe { c::r4_console_put(&mut self.raw(), byte) })
    }
}
#[derive(Clone, Copy)]
pub struct Files<'a> {
    pub(crate) system: &'a System<'a>,
}
impl Files<'_> {
    pub(crate) fn raw(&self) -> c::R4Files {
        c::R4Files {
            system: self.system.pointer(),
        }
    }
    pub fn available(&self) -> bool {
        unsafe { c::r4_files_available(&self.raw()) != 0 }
    }
    pub fn metadata(&self, path: &FilePath) -> Result<Option<abi::FileMetadata2>> {
        let mut value = MaybeUninit::uninit();
        match unsafe { c::r4_files_metadata(&self.raw(), path.as_raw(), value.as_mut_ptr()) } {
            1 => Ok(Some(unsafe { value.assume_init() })),
            0 => Ok(None),
            n => Err(Error::Raw(n)),
        }
    }
    pub fn read(&self, path: &FilePath, out: &mut [u8]) -> Result<Option<usize>> {
        transfer(
            unsafe {
                c::r4_files_read(
                    &mut self.raw(),
                    path.as_raw(),
                    out.as_mut_ptr(),
                    length(out.len())?,
                )
            },
            out.len(),
        )
    }
    pub fn read_at(&self, path: &FilePath, offset: u32, out: &mut [u8]) -> Result<Option<usize>> {
        transfer(
            unsafe {
                c::r4_files_read_at(
                    &mut self.raw(),
                    path.as_raw(),
                    offset,
                    out.as_mut_ptr(),
                    length(out.len())?,
                )
            },
            out.len(),
        )
    }
    pub fn write(&self, path: &FilePath, bytes: &[u8]) -> Result<usize> {
        transfer(
            unsafe {
                c::r4_files_write(
                    &mut self.raw(),
                    path.as_raw(),
                    bytes.as_ptr(),
                    length(bytes.len())?,
                )
            },
            bytes.len(),
        )
        .map(|n| n.unwrap_or(0))
    }
    pub fn append(&self, path: &FilePath, bytes: &[u8]) -> Result<usize> {
        transfer(
            unsafe {
                c::r4_files_append(
                    &mut self.raw(),
                    path.as_raw(),
                    bytes.as_ptr(),
                    length(bytes.len())?,
                )
            },
            bytes.len(),
        )
        .map(|n| n.unwrap_or(0))
    }
    /// Actual resolved mount limits, including hidden boot-volume routing.
    /// This snapshot does not reserve a mount or a filename.
    pub fn name_limits(&self, path: &FilePath) -> Result<abi::FileNameLimits> {
        let mut value = abi::FileNameLimits::default();
        let raw = unsafe { c::r4_files_name_limits(&mut self.raw(), path.as_raw(), &mut value) };
        if raw != 0 {
            return Err(Error::Raw(raw));
        }
        if value.size as usize != core::mem::size_of::<abi::FileNameLimits>()
            || value.flags & abi::file_name_limits_flag_known == 0
        {
            return Err(Error::InvalidProvider);
        }
        Ok(value)
    }
    /// Read-only native recovery scope. Does not reserve the target, inspect
    /// files, or admit software dependencies; final installation revalidates.
    pub fn update_target_supported(&self, path: &crate::path::AbsoluteFilePath) -> Result<bool> {
        match unsafe {
            c::r4_files_system_update_target_supported(&self.raw(), path.as_path().as_raw())
        } {
            0 => Ok(false),
            1 => Ok(true),
            raw if raw < 0 => Err(Error::Raw(raw)),
            _ => Err(Error::InvalidProvider),
        }
    }
    pub fn info(&self, path: &FilePath) -> Result<Option<abi::FileInfo>> {
        let r = unsafe { c::r4_files_info(&mut self.raw(), path.as_raw()) };
        match r.state {
            0 => Ok(Some(r.value)),
            1 => Ok(None),
            _ => Err(Error::Raw(r.raw_code)),
        }
    }
    pub fn delete(&self, path: &FilePath) -> Result<Presence> {
        operation(unsafe { c::r4_files_delete(&mut self.raw(), path.as_raw()) })
    }
    pub fn rename(&self, source: &FilePath, target: &FilePath) -> Result<Presence> {
        operation(unsafe { c::r4_files_rename(&mut self.raw(), source.as_raw(), target.as_raw()) })
    }
    pub fn create_directory(&self, path: &FilePath) -> Result<Presence> {
        operation(unsafe { c::r4_files_create_directory(&mut self.raw(), path.as_raw()) })
    }
    pub fn delete_directory(&self, path: &FilePath) -> Result<Presence> {
        operation(unsafe { c::r4_files_delete_directory(&mut self.raw(), path.as_raw()) })
    }
    /// The returned progress remains available even after a failed copy.
    pub fn copy(
        &self,
        source: &FilePath,
        target: &FilePath,
        scratch: &mut [u8],
    ) -> Result<c::R4FileCopyResult> {
        Ok(unsafe {
            c::r4_files_copy(
                &mut self.raw(),
                source.as_raw(),
                target.as_raw(),
                scratch.as_mut_ptr(),
                length(scratch.len())?,
            )
        })
    }
    pub fn replace_atomic(
        &self,
        target: &FilePath,
        stage: &FilePath,
        backup: &FilePath,
        options: AtomicReplaceOptions,
    ) -> AtomicReplace {
        let raw = unsafe {
            c::r4_files_replace_atomic(
                &mut self.raw(),
                target.as_raw(),
                stage.as_raw(),
                backup.as_raw(),
                options.flags(),
            )
        };
        match raw {
            0 => AtomicReplace::Committed,
            -5 | -6 => AtomicReplace::Conflict,
            -3 => AtomicReplace::Missing,
            -2 | -8 => AtomicReplace::Unsupported,
            -4 => AtomicReplace::BadPath,
            n => AtomicReplace::Failed(n),
        }
    }
    pub fn begin_directory_changes(
        &self,
        path: &FilePath,
        cursor: &mut abi::DirectoryChangeCursor,
    ) -> Result<()> {
        status(unsafe {
            c::r4_files_directory_changes_begin(&mut self.raw(), path.as_raw(), cursor)
        })
    }
    pub fn poll_directory_changes(&self, cursor: &mut abi::DirectoryChangeCursor) -> Result<i32> {
        let r = unsafe { c::r4_files_directory_changes_poll(&mut self.raw(), cursor) };
        status(r)?;
        Ok(r)
    }
    pub fn iterate<'a>(&'a self, path: &'a FilePath) -> DirectoryIterator<'a> {
        DirectoryIterator {
            raw: unsafe { c::r4_files_iterate(self.raw(), path.as_raw()) },
            _loan: PhantomData,
        }
    }
    pub fn stream_reader<'a>(&'a self, path: &'a FilePath) -> StreamReader<'a> {
        StreamReader {
            raw: unsafe { c::r4_files_stream_reader(self.raw(), path.as_raw()) },
            _loan: PhantomData,
        }
    }
    pub fn stream_writer<'a>(
        &'a self,
        path: &'a FilePath,
        flags: u32,
    ) -> core::result::Result<StreamWriter<'a>, StreamOpenError<'a>> {
        let mut raw = c::R4StreamWriter {
            files: self.raw(),
            path: path.as_raw(),
            offset: 0,
            raw_code: 0,
            active: 0,
        };
        let opened =
            unsafe { c::r4_files_stream_writer(self.raw(), path.as_raw(), flags, &mut raw) };
        let writer = StreamWriter {
            raw,
            // These precise native preflights refuse before stream allocation.
            // Other errors keep their existing ambiguous cleanup obligation.
            needs_abort: opened.raw_code != abi::file_stream_error_name_not_supported
                && opened.raw_code != abi::file_stream_error_name_too_long,
            retained: false,
            _loan: PhantomData,
        };
        match operation(opened) {
            Ok(_) if opened.raw_code == 0 => Ok(writer),
            other => Err(StreamOpenError {
                error: other.err().unwrap_or(Error::Raw(opened.raw_code)),
                writer,
            }),
        }
    }
    pub fn owned_create_writer<'a>(
        &'a self,
        path: &'a crate::path::AbsoluteFilePath,
    ) -> core::result::Result<StreamWriter<'a>, StreamOpenError<'a>> {
        self.stream_writer(
            path.as_path(),
            abi::file_stream_open_create | abi::file_stream_open_lease,
        )
    }
    pub fn save(
        &self,
        sequence: &mut u32,
        path: &FilePath,
        bytes: &[u8],
        require_absent: bool,
    ) -> SaveResult {
        match unsafe {
            c::R4SdkDocumentSave(
                self.system.raw(),
                sequence,
                path.as_bytes().as_ptr(),
                path.as_bytes().len() as u64,
                bytes.as_ptr(),
                bytes.len() as u64,
                i32::from(require_absent),
            )
        } {
            0 => SaveResult::Saved,
            1 => SaveResult::BackupRetained,
            3 => SaveResult::CopiesRetained,
            _ => SaveResult::Failed,
        }
    }
    pub fn recent_documents(&self, out: &mut [c::R4RecentEntry]) -> Result<usize> {
        let raw =
            unsafe { c::R4SdkRecentRead(self.system.raw(), out.as_mut_ptr(), out.len() as u64) };
        status(raw)?;
        if raw as usize > out.len() {
            return Err(Error::InvalidProvider);
        }
        Ok(raw as usize)
    }
    pub fn add_recent_document(&self, path: &FilePath, app: &[u8]) -> bool {
        unsafe {
            c::R4SdkRecentAdd(
                self.system.raw(),
                path.as_bytes().as_ptr(),
                path.as_bytes().len() as u64,
                app.as_ptr(),
                app.len() as u64,
            ) != 0
        }
    }
}
#[derive(Clone, Copy)]
pub struct AtomicReplaceOptions {
    pub consume_stage: bool,
    pub require_target_absent: bool,
    pub require_owned_stage: bool,
}
impl Default for AtomicReplaceOptions {
    fn default() -> Self {
        Self {
            consume_stage: true,
            require_target_absent: false,
            require_owned_stage: false,
        }
    }
}
impl AtomicReplaceOptions {
    fn flags(self) -> u32 {
        u32::from(self.consume_stage)
            | (u32::from(self.require_target_absent) << 1)
            | (u32::from(self.require_owned_stage) << 2)
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AtomicReplace {
    Committed,
    Conflict,
    Missing,
    Unsupported,
    BadPath,
    Failed(i32),
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum SaveResult {
    Saved,
    BackupRetained,
    Failed,
    CopiesRetained,
}
impl SaveResult {
    pub fn committed(self) -> bool {
        matches!(self, Self::Saved | Self::BackupRetained)
    }
}
pub struct DirectoryEntry {
    pub path: FilePath,
    pub is_directory: bool,
    pub info: Option<abi::FileInfo>,
    pub metadata: Option<abi::FileMetadata2>,
}
pub struct DirectoryIterator<'a> {
    raw: c::R4DirectoryIterator,
    _loan: PhantomData<&'a Files<'a>>,
}
impl DirectoryIterator<'_> {
    pub fn next_entry(&mut self) -> Result<Option<DirectoryEntry>> {
        let n = unsafe { c::r4_directory_next(&mut self.raw) };
        match n.state {
            1 => Ok(None),
            2 => Err(Error::Raw(n.raw_code)),
            _ => {
                let len = n
                    .path
                    .bytes
                    .iter()
                    .position(|&b| b == 0)
                    .ok_or(Error::InvalidProvider)?;
                let path =
                    FilePath::parse(&n.path.bytes[..len]).map_err(|_| Error::InvalidProvider)?;
                Ok(Some(DirectoryEntry {
                    path,
                    is_directory: n.is_directory != 0,
                    info: if n.has_info != 0 { Some(n.info) } else { None },
                    metadata: if self.raw.last_metadata_valid != 0 {
                        Some(self.raw.last_metadata)
                    } else {
                        None
                    },
                }))
            }
        }
    }
    pub fn revisit_after_removal(&mut self) {
        unsafe { c::r4_directory_revisit_after_removal(&mut self.raw) }
    }
}
pub struct StreamReader<'a> {
    raw: c::R4StreamReader,
    _loan: PhantomData<&'a Files<'a>>,
}
impl StreamReader<'_> {
    pub fn read(&mut self, out: &mut [u8]) -> Result<Option<usize>> {
        transfer(
            unsafe {
                c::r4_stream_reader_read(&mut self.raw, out.as_mut_ptr(), length(out.len())?)
            },
            out.len(),
        )
    }
    pub fn offset(&self) -> u64 {
        self.raw.offset
    }
}
/// No destructor claims a successful close. Keep this value until `finish`
/// or `abort` acknowledges completion, including a failed write/finish.
#[must_use = "finish or abort the actual stream and inspect its result"]
pub struct StreamWriter<'a> {
    raw: c::R4StreamWriter,
    needs_abort: bool,
    retained: bool,
    _loan: PhantomData<&'a Files<'a>>,
}
/// A failed begin can already own a native stream slot. Its exact writer is
/// returned for explicit abort; no path is blindly deleted on that failure.
pub struct StreamOpenError<'a> {
    pub error: Error,
    pub writer: StreamWriter<'a>,
}
impl core::fmt::Debug for StreamOpenError<'_> {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        f.debug_struct("StreamOpenError")
            .field("error", &self.error)
            .finish_non_exhaustive()
    }
}
impl StreamWriter<'_> {
    pub fn write(&mut self, bytes: &[u8]) -> Result<()> {
        stream_operation(unsafe {
            c::r4_stream_writer_write(&mut self.raw, bytes.as_ptr(), length(bytes.len())?)
        })?;
        Ok(())
    }
    pub fn finish(&mut self) -> Result<()> {
        stream_operation(unsafe { c::r4_stream_writer_finish(&mut self.raw) })?;
        self.needs_abort = false;
        Ok(())
    }
    pub fn finish_keep_ownership(&mut self) -> Result<()> {
        stream_operation(unsafe { c::r4_stream_writer_finish_flags(&mut self.raw, 1) })?;
        self.retained = true;
        Ok(())
    }
    pub fn abort(&mut self) -> Result<()> {
        if !self.needs_abort {
            return Ok(());
        }
        let r = unsafe { c::r4_stream_writer_abort(&mut self.raw) };
        stream_operation(r)?;
        self.needs_abort = false;
        self.retained = false;
        Ok(())
    }
    /// Consume this retained create-only stage through its exact path. A
    /// successful acknowledgement closes this writer before another stream
    /// can reuse that path; ambiguous publication keeps its cleanup state.
    pub fn publish_create(&mut self, target: &FilePath, backup: &FilePath) -> AtomicReplace {
        if !self.retained {
            return AtomicReplace::Failed(-1);
        }
        let raw = unsafe {
            c::r4_files_replace_atomic(
                &mut self.raw.files,
                target.as_raw(),
                self.raw.path,
                backup.as_raw(),
                7,
            )
        };
        let result = match raw {
            0 => AtomicReplace::Committed,
            -5 | -6 => AtomicReplace::Conflict,
            -3 => AtomicReplace::Missing,
            -2 | -8 => AtomicReplace::Unsupported,
            -4 => AtomicReplace::BadPath,
            n => AtomicReplace::Failed(n),
        };
        if result == AtomicReplace::Committed {
            self.needs_abort = false;
            self.retained = false
        }
        result
    }
    pub fn offset(&self) -> u64 {
        self.raw.offset
    }
    pub fn needs_abort(&self) -> bool {
        self.needs_abort
    }
    pub fn retained(&self) -> bool {
        self.retained
    }
}

#[derive(Clone, Copy)]
pub struct Registry<'a> {
    system: &'a System<'a>,
}
impl Registry<'_> {
    fn raw(&self) -> c::R4Registry {
        c::R4Registry {
            system: self.system.pointer(),
        }
    }
    pub fn available(&self) -> bool {
        unsafe { c::r4_registry_available(&self.raw()) != 0 }
    }
    pub fn snapshot_available(&self) -> bool {
        unsafe { c::r4_registry_snapshot_available(&self.raw()) != 0 }
    }
    pub fn batch_available(&self) -> bool {
        unsafe { c::r4_registry_batch_available(&self.raw()) != 0 }
    }
    pub fn get<'b>(
        &self,
        key: &RegistryPath,
        name: &CStr,
        out: &'b mut [u8],
    ) -> Result<Option<RegistryValue<'b>>> {
        let r = unsafe {
            c::r4_registry_get(
                &mut self.raw(),
                key.as_raw(),
                name.as_ptr().cast(),
                out.as_mut_ptr(),
                length(out.len())?,
            )
        };
        match r.state {
            0 if r.value.length as usize <= out.len() => Ok(Some(RegistryValue {
                info: r.value.info,
                bytes: &out[..r.value.length as usize],
            })),
            0 => Err(Error::InvalidProvider),
            1 => Ok(None),
            _ => Err(Error::Raw(r.raw_code)),
        }
    }
    pub fn set(&self, key: &RegistryPath, name: &CStr, kind: u16, bytes: &[u8]) -> Result<()> {
        operation(unsafe {
            c::r4_registry_set(
                &mut self.raw(),
                key.as_raw(),
                name.as_ptr().cast(),
                kind,
                bytes.as_ptr(),
                length(bytes.len())?,
            )
        })?;
        Ok(())
    }
    pub fn set_string(&self, key: &RegistryPath, name: &CStr, bytes: &[u8]) -> Result<()> {
        self.set(key, name, abi::registry_value_type_string, bytes)
    }
    pub fn set_u32(&self, key: &RegistryPath, name: &CStr, value: u32) -> Result<()> {
        self.set(
            key,
            name,
            abi::registry_value_type_u32,
            &value.to_le_bytes(),
        )
    }
    pub fn set_u64(&self, key: &RegistryPath, name: &CStr, value: u64) -> Result<()> {
        self.set(
            key,
            name,
            abi::registry_value_type_u64,
            &value.to_le_bytes(),
        )
    }
    pub fn set_bool(&self, key: &RegistryPath, name: &CStr, value: bool) -> Result<()> {
        self.set(key, name, abi::registry_value_type_bool, &[u8::from(value)])
    }
    pub fn set_binary(&self, key: &RegistryPath, name: &CStr, bytes: &[u8]) -> Result<()> {
        self.set(key, name, abi::registry_value_type_binary, bytes)
    }
    pub fn delete(&self, key: &RegistryPath, name: &CStr) -> Result<Presence> {
        operation(unsafe {
            c::r4_registry_delete(&mut self.raw(), key.as_raw(), name.as_ptr().cast())
        })
    }
    pub fn begin_snapshot(
        &self,
        key: &RegistryPath,
        kind: SnapshotKind,
    ) -> Result<Option<RegistrySnapshot<'_>>> {
        let mut cursor = abi::RegistrySnapshotCursor::default();
        let r = unsafe {
            c::r4_registry_snapshot_begin(&mut self.raw(), key.as_raw(), kind as u32, &mut cursor)
        };
        if r == abi::registry_api_result_key_not_found
            || r == abi::registry_api_result_hive_not_found
        {
            return Ok(None);
        }
        status(r)?;
        Ok(Some(RegistrySnapshot {
            registry: *self,
            cursor,
        }))
    }
    pub fn apply_batch(&self, builder: &RegistryBatch<'_>) -> c::R4RegistryBatchApply {
        unsafe { c::r4_registry_batch_apply(&mut self.raw(), &builder.raw) }
    }
}
pub struct RegistryValue<'a> {
    pub info: abi::RegistryValueInfo,
    pub bytes: &'a [u8],
}
impl RegistryValue<'_> {
    pub fn as_u32(&self) -> Option<u32> {
        if self.info.value_type != abi::registry_value_type_u32 {
            return None;
        }
        Some(u32::from_le_bytes(self.bytes.try_into().ok()?))
    }
    pub fn as_u64(&self) -> Option<u64> {
        if self.info.value_type != abi::registry_value_type_u64 {
            return None;
        }
        Some(u64::from_le_bytes(self.bytes.try_into().ok()?))
    }
    pub fn as_bool(&self) -> Option<bool> {
        if self.info.value_type == abi::registry_value_type_bool
            && self.bytes.len() == 1
            && self.bytes[0] < 2
        {
            Some(self.bytes[0] != 0)
        } else {
            None
        }
    }
    pub fn as_string(&self) -> Option<&[u8]> {
        (self.info.value_type == abi::registry_value_type_string).then_some(self.bytes)
    }
    pub fn as_binary(&self) -> Option<&[u8]> {
        (self.info.value_type == abi::registry_value_type_binary).then_some(self.bytes)
    }
}
#[repr(u32)]
pub enum SnapshotKind {
    Keys = 1,
    Values = 2,
}
pub struct RegistrySnapshot<'a> {
    registry: Registry<'a>,
    cursor: abi::RegistrySnapshotCursor,
}
impl RegistrySnapshot<'_> {
    pub fn page(
        &mut self,
        entries: &mut [abi::RegistrySnapshotEntry],
        data: &mut [u8],
    ) -> Result<abi::RegistrySnapshotPageInfo> {
        let mut page = abi::RegistrySnapshotPageInfo::default();
        let r = unsafe {
            c::r4_registry_snapshot_page(
                &mut self.registry.raw(),
                &mut self.cursor,
                entries.as_mut_ptr(),
                length(entries.len())?,
                data.as_mut_ptr(),
                length(data.len())?,
                &mut page,
            )
        };
        status(r)?;
        if page.returned as usize > entries.len() || page.data_bytes as usize > data.len() {
            return Err(Error::InvalidProvider);
        }
        Ok(page)
    }
    pub fn cursor(&self) -> &abi::RegistrySnapshotCursor {
        &self.cursor
    }
}
pub struct RegistryBatch<'a> {
    raw: c::R4RegistryBatchBuilder,
    _loan: PhantomData<(&'a mut [abi::RegistryBatchOperation], &'a mut [u8])>,
}
impl<'a> RegistryBatch<'a> {
    pub fn new(
        operations: &'a mut [abi::RegistryBatchOperation],
        blob: &'a mut [u8],
    ) -> Result<Self> {
        let mut raw = MaybeUninit::uninit();
        unsafe {
            c::r4_registry_batch_builder_init(
                raw.as_mut_ptr(),
                operations.as_mut_ptr(),
                length(operations.len())?,
                blob.as_mut_ptr(),
                length(blob.len())?,
            )
        };
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            _loan: PhantomData,
        })
    }
    pub fn reset(&mut self) {
        unsafe { c::r4_registry_batch_builder_reset(&mut self.raw) }
    }
    pub fn set(&mut self, key: &RegistryPath, name: &CStr, kind: u16, bytes: &[u8]) -> Result<()> {
        status(unsafe {
            c::r4_registry_batch_builder_set(
                &mut self.raw,
                key.as_raw(),
                name.as_ptr().cast(),
                kind,
                bytes.as_ptr(),
                length(bytes.len())?,
            )
        })
    }
    pub fn set_u32(&mut self, key: &RegistryPath, name: &CStr, value: u32) -> Result<()> {
        self.set(
            key,
            name,
            abi::registry_value_type_u32,
            &value.to_le_bytes(),
        )
    }
    pub fn set_u64(&mut self, key: &RegistryPath, name: &CStr, value: u64) -> Result<()> {
        self.set(
            key,
            name,
            abi::registry_value_type_u64,
            &value.to_le_bytes(),
        )
    }
    pub fn set_bool(&mut self, key: &RegistryPath, name: &CStr, value: bool) -> Result<()> {
        self.set(key, name, abi::registry_value_type_bool, &[u8::from(value)])
    }
    pub fn set_string(&mut self, key: &RegistryPath, name: &CStr, value: &[u8]) -> Result<()> {
        self.set(key, name, abi::registry_value_type_string, value)
    }
    pub fn set_binary(&mut self, key: &RegistryPath, name: &CStr, value: &[u8]) -> Result<()> {
        self.set(key, name, abi::registry_value_type_binary, value)
    }
    pub fn delete(&mut self, key: &RegistryPath, name: &CStr) -> Result<()> {
        status(unsafe {
            c::r4_registry_batch_builder_delete(&mut self.raw, key.as_raw(), name.as_ptr().cast())
        })
    }
    pub fn operations(&self) -> &[abi::RegistryBatchOperation] {
        unsafe {
            core::slice::from_raw_parts(self.raw.operations, self.raw.operation_count as usize)
        }
    }
    pub fn blob(&self) -> &[u8] {
        unsafe { core::slice::from_raw_parts(self.raw.blob, self.raw.blob_len as usize) }
    }
}
