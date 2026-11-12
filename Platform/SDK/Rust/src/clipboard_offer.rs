//! Copied CLIPSVC offers. No implicit legacy fallback or automatic mutation retry.
use crate::{abi, platform2::Context};
use core::{marker::PhantomData, mem};
pub type Info = abi::ClipboardOfferInfo;
pub type Lease = abi::ClipboardOfferLease;
pub type Format = abi::ClipboardOfferFormat;
pub type Page = abi::ClipboardOfferPage;
pub type Chunk = abi::ClipboardOfferChunk;
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Error(pub i32);
const INVALID: Error = Error(abi::clipboard_offer_error_invalid);
fn bytes<T>(value: &T) -> &[u8] {
    // Private callers use only the fixed, padding-free, integer wire records.
    unsafe { core::slice::from_raw_parts((value as *const T).cast(), mem::size_of::<T>()) }
}
fn token(value: Lease) -> Lease {
    Lease {
        version: 1,
        size: mem::size_of::<Lease>() as u32,
        provider: value.provider,
        id: value.id,
        revision: 0,
        expires_ns: 0,
        state: 0,
        reserved: 0,
    }
}
fn transfer(
    value: Lease,
    item: u32,
    format: u32,
    offset: u64,
    total_bytes: u64,
) -> abi::ClipboardOfferTransfer {
    abi::ClipboardOfferTransfer {
        version: 1,
        size: mem::size_of::<abi::ClipboardOfferTransfer>() as u32,
        provider: value.provider,
        id: value.id,
        item,
        format,
        offset,
        total_bytes,
    }
}
fn lease_valid(value: Lease, provider: u64, state: u32) -> bool {
    value.provider == provider
        && provider != 0
        && value.id != 0
        && value.expires_ns != 0
        && value.reserved == 0
        && (state == 0 || value.state == state)
}
// Sealed private wire set: every bit pattern is valid, no pointers or padding.
trait Wire: Copy {}
impl Wire for Info {}
impl Wire for Lease {}
impl Wire for Page {}
impl Wire for Chunk {}
fn decode<T: Wire>(data: &[u8]) -> Result<T, Error> {
    if data.len() < mem::size_of::<T>()
        || u32::from_le_bytes(data[0..4].try_into().map_err(|_| INVALID)?) != 1
        || u32::from_le_bytes(data[4..8].try_into().map_err(|_| INVALID)?)
            != mem::size_of::<T>() as u32
    {
        return Err(INVALID);
    }
    Ok(unsafe { data.as_ptr().cast::<T>().read_unaligned() })
}
/// Exclusive synchronous service channel, borrowed from this actual Context.
/// Call Close explicitly. A transport error does not prove a mutation failed.
/// Keep the original token for Status/idempotent Commit until fixed expiry.
#[must_use]
pub struct Client<'a> {
    _context: &'a Context<'a>,
    call: abi::R4SysFns::service_call,
    close: abi::R4SysFns::service_close,
    handle: u32,
    _local: PhantomData<*mut ()>,
}
impl<'a> Client<'a> {
    pub(crate) fn control_native(
        &mut self,
    ) -> Result<crate::c_facades::R4SdkClipboardOffers, Error> {
        if self.handle == 0 {
            return Err(Error(abi::clipboard_offer_error_closed));
        }
        Ok(crate::c_facades::R4SdkClipboardOffers {
            call: Some(self.call),
            close: Some(self.close),
            handle: self.handle,
            timeout_ticks: 500,
            clock: self
                ._context
                .lookup(
                    1,
                    mem::offset_of!(abi::generation2::R4XStartR4Sys2, monotonic_clock) as u32,
                )
                .ok()
                .map(|address| unsafe {
                    mem::transmute::<u64, abi::R4SysFns::monotonic_clock>(address)
                }),
        })
    }
    pub fn connect(context: &'a Context<'a>) -> Result<Self, Error> {
        let open = context
            .lookup(
                1,
                mem::offset_of!(abi::generation2::R4XStartR4Sys2, service_open) as u32,
            )
            .map_err(Error)?;
        let call = context
            .lookup(
                1,
                mem::offset_of!(abi::generation2::R4XStartR4Sys2, service_call) as u32,
            )
            .map_err(Error)?;
        let close = context
            .lookup(
                1,
                mem::offset_of!(abi::generation2::R4XStartR4Sys2, service_close) as u32,
            )
            .map_err(Error)?;
        let open = unsafe { mem::transmute::<u64, abi::R4SysFns::service_open>(open) };
        let mut info = unsafe { mem::zeroed::<abi::ServiceInfo>() };
        let rc = unsafe { open(c"CLIPSVC".as_ptr().cast(), &mut info) };
        if rc != 0 {
            return Err(Error(rc));
        }
        if info.handle == 0 {
            return Err(Error(abi::service_api_result_no_endpoint));
        }
        Ok(Self {
            _context: context,
            call: unsafe { mem::transmute::<u64, abi::R4SysFns::service_call>(call) },
            close: unsafe { mem::transmute::<u64, abi::R4SysFns::service_close>(close) },
            handle: info.handle,
            _local: PhantomData,
        })
    }
    pub fn close(&mut self) -> Result<(), Error> {
        if self.handle == 0 {
            return Err(Error(abi::clipboard_offer_error_closed));
        }
        let rc = unsafe { (self.close)(self.handle) };
        if rc < 0 {
            return Err(Error(rc));
        }
        self.handle = 0;
        Ok(())
    }
    fn rpc(&mut self, op: u16, request: &[u8], out: &mut [u8]) -> Result<usize, Error> {
        if self.handle == 0 {
            return Err(Error(abi::clipboard_offer_error_closed));
        }
        let mut header = unsafe { mem::zeroed::<abi::ServiceMessageHeader>() };
        let rc = unsafe {
            (self.call)(
                self.handle,
                op,
                request.as_ptr(),
                request.len() as u32,
                &mut header,
                out.as_mut_ptr(),
                out.len() as u32,
                500,
            )
        };
        if rc < 0 {
            return Err(Error(rc));
        }
        if header.status == abi::service_api_result_bad_op {
            return Err(Error(abi::clipboard_offer_error_unsupported));
        }
        if header.status != 0 {
            return Err(if header.status < 0 {
                Error(header.status)
            } else {
                INVALID
            });
        }
        if rc as usize > out.len() {
            return Err(INVALID);
        }
        Ok(rc as usize)
    }
    fn fixed<T: Wire>(&mut self, op: u16, request: &[u8]) -> Result<T, Error> {
        let mut payload = [0u8; 80];
        let count = self.rpc(op, request, &mut payload[..mem::size_of::<T>()])?;
        if count != mem::size_of::<T>() {
            return Err(INVALID);
        }
        decode(&payload[..count])
    }
    fn empty(&mut self, op: u16, request: &[u8]) -> Result<(), Error> {
        if self.rpc(op, request, &mut [0u8; 1])? != 0 {
            return Err(INVALID);
        }
        Ok(())
    }
    pub fn info(&mut self) -> Result<Info, Error> {
        let value: Info = self.fixed(abi::clipboard_offer_op_info, &[])?;
        if value.provider == 0
            || value.flags != 0
            || value.put_chunk == 0
            || value.put_chunk > abi::clipboard_offer_put_chunk
            || value.read_chunk == 0
            || value.read_chunk > abi::clipboard_offer_read_chunk
        {
            return Err(INVALID);
        }
        Ok(value)
    }
    pub fn begin(&mut self, current: Info, total_bytes: u64) -> Result<Lease, Error> {
        let request = abi::ClipboardOfferBegin {
            version: 1,
            size: mem::size_of::<abi::ClipboardOfferBegin>() as u32,
            provider: current.provider,
            expected_revision: current.revision,
            total_bytes,
        };
        let value: Lease = self.fixed(abi::clipboard_offer_op_begin, bytes(&request))?;
        if !lease_valid(value, current.provider, 1) || value.revision != current.revision {
            return Err(INVALID);
        }
        Ok(value)
    }
    pub fn declare(
        &mut self,
        stage: Lease,
        item: u32,
        format: u32,
        total: u64,
    ) -> Result<(), Error> {
        self.empty(
            abi::clipboard_offer_op_declare,
            bytes(&transfer(stage, item, format, 0, total)),
        )
    }
    pub fn put(
        &mut self,
        stage: Lease,
        item: u32,
        format: u32,
        offset: u64,
        total: u64,
        data: &[u8],
    ) -> Result<(), Error> {
        if data.len() > abi::clipboard_offer_put_chunk as usize {
            return Err(Error(abi::clipboard_offer_error_too_large));
        }
        let request = transfer(stage, item, format, offset, total);
        let header = bytes(&request);
        let n = header.len();
        let mut payload = [0u8; 4096];
        payload[..n].copy_from_slice(header);
        payload[n..n + data.len()].copy_from_slice(data);
        self.empty(abi::clipboard_offer_op_put, &payload[..n + data.len()])
    }
    fn lease_call(&mut self, op: u16, lease: Lease) -> Result<Lease, Error> {
        let value: Lease = self.fixed(op, bytes(&token(lease)))?;
        if !lease_valid(value, lease.provider, 0)
            || value.id != lease.id
            || value.state != 1 && value.state != 2
            || op == abi::clipboard_offer_op_commit && value.state != 2
        {
            return Err(INVALID);
        }
        Ok(value)
    }
    pub fn commit(&mut self, stage: Lease) -> Result<Lease, Error> {
        self.lease_call(abi::clipboard_offer_op_commit, stage)
    }
    pub fn status(&mut self, stage: Lease) -> Result<Lease, Error> {
        self.lease_call(abi::clipboard_offer_op_status, stage)
    }
    pub fn abort(&mut self, stage: Lease) -> Result<(), Error> {
        self.empty(abi::clipboard_offer_op_abort, bytes(&token(stage)))
    }
    pub fn snapshot(&mut self) -> Result<Lease, Error> {
        let value: Lease = self.fixed(abi::clipboard_offer_op_snapshot, &[])?;
        if !lease_valid(value, value.provider, 3) {
            return Err(INVALID);
        }
        Ok(value)
    }
    pub fn release(&mut self, lease: Lease) -> Result<(), Error> {
        self.empty(abi::clipboard_offer_op_release, bytes(&token(lease)))
    }
    pub fn enumerate(
        &mut self,
        snapshot: Lease,
        cursor: u32,
        formats: &mut [Format],
    ) -> Result<Page, Error> {
        if formats.is_empty() || formats.len() > 16 {
            return Err(INVALID);
        }
        let request = abi::ClipboardOfferEnumerate {
            version: 1,
            size: mem::size_of::<abi::ClipboardOfferEnumerate>() as u32,
            provider: snapshot.provider,
            id: snapshot.id,
            cursor,
            capacity: formats.len() as u32,
        };
        let mut payload = [0u8; 4096];
        let count = self.rpc(
            abi::clipboard_offer_op_enumerate,
            bytes(&request),
            &mut payload,
        )?;
        let page: Page = decode(&payload[..count])?;
        if page.provider != snapshot.provider
            || page.id != snapshot.id
            || page.revision != snapshot.revision
            || page.reserved != 0
            || page.count as usize > formats.len()
            || page.total > 16
            || cursor > page.total
            || page.count > page.total - cursor
            || page.next != cursor + page.count
            || count != mem::size_of::<Page>() + page.count as usize * mem::size_of::<Format>()
        {
            return Err(INVALID);
        }
        for i in 0..page.count as usize {
            let offset = mem::size_of::<Page>() + i * mem::size_of::<Format>();
            let record = unsafe {
                payload
                    .as_ptr()
                    .add(offset)
                    .cast::<Format>()
                    .read_unaligned()
            };
            if record.item >= 8
                || record.format < 1
                || record.format > 5
                || record.total_bytes > abi::clipboard_offer_max_offer_bytes
                || record.flags != 0
                || record.reserved != 0
            {
                return Err(INVALID);
            }
        }
        for (i, out) in formats[..page.count as usize].iter_mut().enumerate() {
            *out = unsafe {
                payload
                    .as_ptr()
                    .add(mem::size_of::<Page>() + i * mem::size_of::<Format>())
                    .cast::<Format>()
                    .read_unaligned()
            };
        }
        Ok(page)
    }
    pub fn read(
        &mut self,
        snapshot: Lease,
        item: u32,
        format: u32,
        offset: u64,
        out: &mut [u8],
    ) -> Result<Chunk, Error> {
        if out.len() > abi::clipboard_offer_read_chunk as usize {
            return Err(Error(abi::clipboard_offer_error_too_large));
        }
        let request = transfer(snapshot, item, format, offset, out.len() as u64);
        let mut payload = [0u8; 4096];
        let count = self.rpc(abi::clipboard_offer_op_read, bytes(&request), &mut payload)?;
        let chunk: Chunk = decode(&payload[..count])?;
        if chunk.provider != snapshot.provider
            || chunk.id != snapshot.id
            || chunk.revision != snapshot.revision
            || chunk.offset != offset
            || chunk.bytes as usize > out.len()
            || chunk.total_bytes > abi::clipboard_offer_max_offer_bytes
            || offset > chunk.total_bytes
            || u64::from(chunk.bytes) > chunk.total_bytes - offset
            || chunk.flags > 1
            || (chunk.flags == 1) != (offset + u64::from(chunk.bytes) == chunk.total_bytes)
            || count != mem::size_of::<Chunk>() + chunk.bytes as usize
        {
            return Err(INVALID);
        }
        out[..chunk.bytes as usize].copy_from_slice(&payload[mem::size_of::<Chunk>()..count]);
        Ok(chunk)
    }
}
