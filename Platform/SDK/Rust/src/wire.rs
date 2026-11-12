//! Shared freestanding SDK wire/checksum/geometry helpers. Storage is borrowed;
//! native dispatch intake is separate and requires explicit unsafe guarantees.
use crate::{abi, c_facades as c};
use core::{marker::PhantomData, mem::MaybeUninit};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Error {
    Truncated,
    Capacity,
    LengthOverflow,
    InvalidBuffer,
    InvalidState,
    InvalidMark,
    InvalidOrder,
    InvalidWidth,
    ValueOverflow,
}
fn exact(code: i32) -> Result<(), Error> {
    match code {
        0 => Ok(()),
        -1 => Err(Error::Truncated),
        -2 => Err(Error::Capacity),
        -3 => Err(Error::LengthOverflow),
        -4 => Err(Error::InvalidBuffer),
        -6 => Err(Error::InvalidMark),
        -7 => Err(Error::InvalidOrder),
        -8 => Err(Error::InvalidWidth),
        -9 => Err(Error::ValueOverflow),
        _ => Err(Error::InvalidState),
    }
}
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Order {
    Little = 0,
    Big = 1,
}
#[derive(Clone, Copy)]
pub struct ReaderMark<'a> {
    raw: c::R4SdkWireMark,
    _loan: PhantomData<&'a [u8]>,
}
#[derive(Clone, Copy)]
pub struct WriterMark<'a> {
    raw: c::R4SdkWireMark,
    _loan: PhantomData<&'a [u8]>,
}
pub struct Reader<'a> {
    raw: c::R4SdkWireReader,
    bytes: &'a [u8],
}
impl<'a> Reader<'a> {
    pub fn new(bytes: &'a [u8]) -> Result<Self, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkWireReaderInit(bytes.as_ptr(), bytes.len() as u64, raw.as_mut_ptr())
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            bytes,
        })
    }
    pub fn position(&self) -> usize {
        self.raw.position as usize
    }
    pub fn remaining(&self) -> usize {
        self.bytes.len().saturating_sub(self.position())
    }
    pub fn take(&mut self, count: usize) -> Result<&'a [u8], Error> {
        let start = self.position();
        let mut raw = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkWireTake(&mut self.raw, count as u64, raw.as_mut_ptr()) })?;
        let end = start.checked_add(count).ok_or(Error::InvalidState)?;
        let result = self.bytes.get(start..end).ok_or(Error::InvalidState)?;
        let span = unsafe { raw.assume_init() };
        if span.address != result.as_ptr() as u64 || span.length != count as u64 {
            return Err(Error::InvalidState);
        }
        Ok(result)
    }
    fn integer(&mut self, width: u32, order: Order) -> Result<u64, Error> {
        let mut value = 0;
        exact(unsafe { c::R4SdkWireReadInteger(&mut self.raw, width, order as u32, &mut value) })?;
        Ok(value)
    }
    pub fn read_u8(&mut self) -> Result<u8, Error> {
        u8::try_from(self.integer(1, Order::Big)?).map_err(|_| Error::InvalidState)
    }
    pub fn read_u16(&mut self, order: Order) -> Result<u16, Error> {
        u16::try_from(self.integer(2, order)?).map_err(|_| Error::InvalidState)
    }
    pub fn read_u32(&mut self, order: Order) -> Result<u32, Error> {
        u32::try_from(self.integer(4, order)?).map_err(|_| Error::InvalidState)
    }
    pub fn read_u64(&mut self, order: Order) -> Result<u64, Error> {
        self.integer(8, order)
    }
    pub fn checkpoint(&self) -> Result<ReaderMark<'a>, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkWireReaderMark(&self.raw, raw.as_mut_ptr()) })?;
        Ok(ReaderMark {
            raw: unsafe { raw.assume_init() },
            _loan: PhantomData,
        })
    }
    pub fn restore(&mut self, mark: &ReaderMark<'a>) -> Result<(), Error> {
        exact(unsafe { c::R4SdkWireReaderRestore(&mut self.raw, mark.raw) })
    }
}
pub struct Writer<'a> {
    raw: c::R4SdkWireWriter,
    bytes: &'a mut [u8],
}
impl<'a> Writer<'a> {
    pub fn new(bytes: &'a mut [u8]) -> Result<Self, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe {
            c::R4SdkWireWriterInit(bytes.as_mut_ptr(), bytes.len() as u64, raw.as_mut_ptr())
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            bytes,
        })
    }
    pub fn position(&self) -> usize {
        self.raw.position as usize
    }
    pub fn remaining(&self) -> usize {
        self.bytes.len().saturating_sub(self.position())
    }
    pub fn written(&self) -> Result<&[u8], Error> {
        self.bytes.get(..self.position()).ok_or(Error::InvalidState)
    }
    pub fn put(&mut self, bytes: &[u8]) -> Result<(), Error> {
        exact(unsafe { c::R4SdkWirePut(&mut self.raw, bytes.as_ptr(), bytes.len() as u64) })
    }
    fn integer(&mut self, width: u32, value: u64, order: Order) -> Result<(), Error> {
        exact(unsafe { c::R4SdkWireWriteInteger(&mut self.raw, width, order as u32, value) })
    }
    pub fn write_u8(&mut self, value: u8) -> Result<(), Error> {
        self.integer(1, value.into(), Order::Big)
    }
    pub fn write_u16(&mut self, value: u16, order: Order) -> Result<(), Error> {
        self.integer(2, value.into(), order)
    }
    pub fn write_u32(&mut self, value: u32, order: Order) -> Result<(), Error> {
        self.integer(4, value.into(), order)
    }
    pub fn write_u64(&mut self, value: u64, order: Order) -> Result<(), Error> {
        self.integer(8, value, order)
    }
    pub fn checkpoint(&self) -> Result<WriterMark<'a>, Error> {
        let mut raw = MaybeUninit::uninit();
        exact(unsafe { c::R4SdkWireWriterMark(&self.raw, raw.as_mut_ptr()) })?;
        Ok(WriterMark {
            raw: unsafe { raw.assume_init() },
            _loan: PhantomData,
        })
    }
    /// Position only; previously written bytes are not rolled back.
    pub fn restore(&mut self, mark: &WriterMark<'a>) -> Result<(), Error> {
        exact(unsafe { c::R4SdkWireWriterRestore(&mut self.raw, mark.raw) })
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChecksumError {
    LengthOverflow,
    InvalidState,
    InvalidBuffer,
}
fn checksum_code(code: i32) -> Result<(), ChecksumError> {
    match code {
        0 => Ok(()),
        -1 => Err(ChecksumError::LengthOverflow),
        -3 => Err(ChecksumError::InvalidBuffer),
        _ => Err(ChecksumError::InvalidState),
    }
}
#[derive(Clone, Copy)]
pub struct InternetChecksum16 {
    raw: c::R4SdkChecksum16,
}
impl InternetChecksum16 {
    pub fn new() -> Result<Self, ChecksumError> {
        let mut raw = MaybeUninit::uninit();
        checksum_code(unsafe { c::R4SdkChecksumInit(raw.as_mut_ptr()) })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
        })
    }
    pub fn add(&mut self, bytes: &[u8]) -> Result<(), ChecksumError> {
        checksum_code(unsafe {
            c::R4SdkChecksumAdd(&mut self.raw, bytes.as_ptr(), bytes.len() as u64)
        })
    }
    /// Non-mutating snapshot. Protocol owns pseudoheader bytes, UDP zero
    /// mapping and offload admission. Later add is still allowed.
    pub fn finish(&self) -> Result<u16, ChecksumError> {
        let mut value = 0;
        checksum_code(unsafe { c::R4SdkChecksumFinish(&self.raw, &mut value) })?;
        Ok(value)
    }
    pub fn bytes_processed(&self) -> u64 {
        self.raw.bytes
    }
}
#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BufferMode {
    Exact = 0,
    AtLeast = 1,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct BlockLimits {
    pub capacity_blocks: u64,
    pub max_blocks: u64,
    pub max_bytes: u64,
    pub lba_bits: u32,
    pub buffer_mode: BufferMode,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct BlockShape {
    pub byte_count: u64,
    pub last_lba: u64,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BlockError {
    ZeroCount,
    UnknownGeometry,
    UnsupportedShape,
    OutOfRange,
    LengthMismatch,
    Overflow,
    InvalidBuffer,
}
pub fn block_transfer(
    lba: u64,
    count: u64,
    block_bytes: u64,
    buffer_bytes: u64,
    limits: BlockLimits,
) -> Result<BlockShape, BlockError> {
    let raw_limits = c::R4SdkBlockLimits {
        capacity_blocks: limits.capacity_blocks,
        max_blocks: limits.max_blocks,
        max_bytes: limits.max_bytes,
        lba_bits: limits.lba_bits,
        buffer_mode: limits.buffer_mode as u32,
    };
    let mut result = MaybeUninit::uninit();
    let code = unsafe {
        c::R4SdkBlockTransfer(
            lba,
            count,
            block_bytes,
            buffer_bytes,
            raw_limits,
            result.as_mut_ptr(),
        )
    };
    match code {
        0 => {}
        -1 => return Err(BlockError::ZeroCount),
        -2 => return Err(BlockError::UnknownGeometry),
        -3 => return Err(BlockError::UnsupportedShape),
        -4 => return Err(BlockError::OutOfRange),
        -5 => return Err(BlockError::LengthMismatch),
        -6 => return Err(BlockError::Overflow),
        _ => return Err(BlockError::InvalidBuffer),
    }
    let result = unsafe { result.assume_init() };
    Ok(BlockShape {
        byte_count: result.byte_count,
        last_lba: result.last_lba,
    })
}

pub mod native {
    use super::{PhantomData, abi, c};
    use core::{mem, ptr};
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub enum Error {
        NullBuffer,
        TooShort,
        LengthMismatch,
        Misaligned,
        UnsupportedVersion,
        InvalidHeaderSize,
        InvalidDirection,
        InvalidFlags,
        InvalidPolicy,
        LengthOverflow,
    }
    fn exact(code: i32) -> Result<(), Error> {
        match code {
            0 => Ok(()),
            -1 => Err(Error::NullBuffer),
            -2 => Err(Error::TooShort),
            -3 => Err(Error::LengthMismatch),
            -4 => Err(Error::Misaligned),
            -5 => Err(Error::UnsupportedVersion),
            -6 => Err(Error::InvalidHeaderSize),
            -7 => Err(Error::InvalidDirection),
            -8 => Err(Error::InvalidFlags),
            -10 => Err(Error::LengthOverflow),
            _ => Err(Error::InvalidPolicy),
        }
    }
    #[repr(u32)]
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub enum SizeMode {
        Exact = 0,
        Prefix = 1,
    }
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub struct Header {
        pub version_offset: Option<u32>,
        pub expected_version: u32,
        pub size_offset: Option<u32>,
    }
    impl Header {
        pub const NONE: Self = Self {
            version_offset: None,
            expected_version: 0,
            size_offset: None,
        };
    }
    fn policy<T>(
        direction: u32,
        mode: SizeMode,
        header: Header,
        flags: u32,
    ) -> Result<c::R4SdkNativePolicy, Error> {
        if mem::size_of::<T>() == 0 || mem::size_of::<T>() > u32::MAX as usize {
            return Err(Error::InvalidPolicy);
        }
        Ok(c::R4SdkNativePolicy {
            required_bytes: mem::size_of::<T>() as u64,
            alignment: mem::align_of::<T>() as u64,
            version_offset: header.version_offset.unwrap_or(u32::MAX),
            size_offset: header.size_offset.unwrap_or(u32::MAX),
            expected_version: header.expected_version,
            size_mode: mode as u32,
            direction,
            allowed_flags: flags,
        })
    }
    fn admit(
        buffer: &abi::ProtocolBuffer,
        policy: c::R4SdkNativePolicy,
        access: u32,
    ) -> Result<usize, Error> {
        let mut address = 0;
        exact(unsafe { c::R4SdkNativeAdmit(buffer, policy, access, &mut address) })?;
        Ok(address as usize)
    }
    pub struct Input<'a, T: Copy> {
        data: *const T,
        _loan: PhantomData<(&'a abi::ProtocolBuffer, &'a T)>,
    }
    impl<'a, T: Copy> Input<'a, T> {
        /// # Safety
        /// T is a native POD record with correct declared layout, no Rust
        /// references/ownership, and a valid initialized representation at data.
        /// Header offsets name actual initialized native u32 fields of T.
        /// Metadata and immutable mapped data remain live for 'a within dispatch.
        /// The helper does not establish mapping, authority or bit validity.
        pub unsafe fn new(
            buffer: &'a abi::ProtocolBuffer,
            mode: SizeMode,
            header: Header,
            flags: u32,
        ) -> Result<Self, Error> {
            Ok(Self {
                data: admit(buffer, policy::<T>(0, mode, header, flags)?, 0)? as *const T,
                _loan: PhantomData,
            })
        }
        pub fn get(&self) -> &T {
            unsafe { &*self.data }
        }
    }
    pub struct InOut<'a, T: Copy> {
        data: *mut T,
        _loan: PhantomData<(&'a mut abi::ProtocolBuffer, &'a mut T)>,
    }
    impl<'a, T: Copy> InOut<'a, T> {
        /// # Safety
        /// T is native POD with no Rust ownership/references, initialized and
        /// bit-valid. Metadata and separate mapped payload stay exclusive,
        /// stable and live for 'a within the original dispatch loan.
        /// Header offsets name actual initialized native u32 fields of T.
        pub unsafe fn new(
            buffer: &'a mut abi::ProtocolBuffer,
            mode: SizeMode,
            header: Header,
            flags: u32,
        ) -> Result<Self, Error> {
            Ok(Self {
                data: admit(buffer, policy::<T>(2, mode, header, flags)?, 2)? as *mut T,
                _loan: PhantomData,
            })
        }
        pub fn get_mut(&mut self) -> &mut T {
            unsafe { &mut *self.data }
        }
    }
    pub struct Output<'a, T: Copy> {
        buffer: &'a mut abi::ProtocolBuffer,
        policy: c::R4SdkNativePolicy,
        _type: PhantomData<mem::MaybeUninit<T>>,
    }
    impl<'a, T: Copy> Output<'a, T> {
        /// # Safety
        /// T is native POD with no Rust references/ownership. Header offsets
        /// name actual initialized native u32 fields of T. Metadata and
        /// separate mapped payload capacity stay exclusive/stable/live for 'a
        /// through dispatch. Payload may be uninitialized. No pin or device
        /// quiescence is implied, and the view cannot extend that storage loan.
        pub unsafe fn new(
            buffer: &'a mut abi::ProtocolBuffer,
            mode: SizeMode,
            header: Header,
            flags: u32,
        ) -> Result<Self, Error> {
            let policy = policy::<T>(1, mode, header, flags)?;
            let _ = admit(buffer, policy, 1)?;
            Ok(Self {
                buffer,
                policy,
                _type: PhantomData,
            })
        }
        pub fn write(&mut self, value: T) -> Result<(), Error> {
            let size = mem::size_of::<T>() as u32;
            let candidate = abi::ProtocolBuffer {
                data: (&value as *const T).cast_mut().cast(),
                len: size,
                capacity: size,
                flags: 0,
                reserved: 0,
            };
            let mut checked = self.policy;
            checked.direction = 0;
            checked.size_mode = 0;
            checked.alignment = mem::align_of::<T>() as u64;
            checked.allowed_flags = 0;
            let _ = admit(&candidate, checked, 0)?;
            let target = admit(self.buffer, self.policy, 1)? as *mut T;
            unsafe { ptr::write(target, value) };
            self.buffer.len = size;
            Ok(())
        }
    }
}
