//! Original HTTP/TLS transport and job owners. Pure parsers/policy/cache and
//! advanced resource/document operations remain fully typed in `raw`.
use crate::{App, abi, c_facades as c, resources::Timeout};
use core::{marker::PhantomData, mem::MaybeUninit};
pub mod raw {
    pub use crate::c_facades::*;
}
#[cfg(feature = "alloc")]
mod job;
#[cfg(feature = "alloc")]
pub use job::Job;
mod cache;
pub use cache::{Cache, CacheClock, CacheKey, CacheLease, CacheMode};
mod stream;
pub use stream::{PostBuffers, PostRequest, PostStream, StreamReport, StreamState};
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Native(super::Error),
    Fetch(u32),
    InvalidNative,
    Unavailable,
}
pub type Result<T> = core::result::Result<T, Error>;
impl From<super::Error> for Error {
    fn from(value: super::Error) -> Self {
        Self::Native(value)
    }
}
pub(crate) fn result(v: c::R4SdkTransportSlot) -> Result<c::R4SdkTransportSlot> {
    super::result(c::R4SdkWebSlot {
        ptr: v.ptr,
        length: v.length,
        bits: v.bits,
        status: v.status,
        flags: v.flags,
    })?;
    Ok(v)
}
pub(crate) fn required(v: c::R4SdkTransportSlot) -> Result<c::R4SdkTransportSlot> {
    let v = result(v)?;
    if v.flags & 1 == 0 {
        Err(Error::Unavailable)
    } else {
        Ok(v)
    }
}
fn view(v: c::R4SdkTransportSlot, owner: &[u8]) -> Result<&[u8]> {
    let v = required(v)?;
    Ok(crate::data::view(
        c::R4SdkDataSlot {
            ptr: v.ptr,
            length: v.length,
            bits: v.bits,
            status: v.status,
            flags: v.flags,
        },
        owner,
    )?)
}
#[derive(Clone, Copy, Debug)]
#[repr(u32)]
pub enum Method {
    Get = c::R4SdkWebNative_http_Method_get,
    Post = c::R4SdkWebNative_http_Method_post,
    Head = c::R4SdkWebNative_http_Method_head,
    Put = c::R4SdkWebNative_http_Method_put,
    Delete = c::R4SdkWebNative_http_Method_delete,
    Patch = c::R4SdkWebNative_http_Method_patch,
    Options = c::R4SdkWebNative_http_Method_options,
}
pub struct Request<'a, 'c> {
    pub url: &'a [u8],
    pub method: Method,
    pub timeout: Timeout,
    pub headers: &'a [u8],
    pub body: &'a [u8],
    pub content_type: &'a [u8],
    pub cookie: &'a [u8],
    pub origin: &'a [u8],
    pub partition: &'a [u8],
    pub cors: bool,
    pub credentials: bool,
    pub callbacks: Option<&'c super::Callbacks<'c, 'c>>,
}
impl<'a, 'c> Request<'a, 'c> {
    pub fn get(url: &'a [u8]) -> Self {
        Self {
            url,
            method: Method::Get,
            timeout: Timeout::AfterNanos(10_000_000_000),
            headers: b"",
            body: b"",
            content_type: b"",
            cookie: b"",
            origin: b"",
            partition: b"",
            cors: false,
            credentials: false,
            callbacks: None,
        }
    }
}
pub(crate) fn options(
    request: &Request<'_, '_>,
) -> Result<MaybeUninit<c::R4SdkTransportFetchOptions>> {
    let mut out = MaybeUninit::uninit();
    let timeout = request.timeout.raw();
    unsafe {
        required(c::R4SdkTransportFetchOptions_create(out.as_mut_ptr()))?;
        result(c::R4SdkTransportFetchOptions_set_timeout(
            out.as_mut_ptr(),
            &timeout,
        ))?;
        result(c::R4SdkTransportFetchOptions_set_method(
            out.as_mut_ptr(),
            request.method as u32,
        ))?;
        result(c::R4SdkTransportFetchOptions_set_headers(
            out.as_mut_ptr(),
            request.headers.as_ptr(),
            request.headers.len() as u64,
        ))?;
        result(c::R4SdkTransportFetchOptions_set_body(
            out.as_mut_ptr(),
            request.body.as_ptr(),
            request.body.len() as u64,
        ))?;
        result(c::R4SdkTransportFetchOptions_set_content_type(
            out.as_mut_ptr(),
            request.content_type.as_ptr(),
            request.content_type.len() as u64,
        ))?;
        result(c::R4SdkTransportFetchOptions_set_cookie(
            out.as_mut_ptr(),
            request.cookie.as_ptr(),
            request.cookie.len() as u64,
        ))?;
        result(c::R4SdkTransportFetchOptions_set_origin(
            out.as_mut_ptr(),
            request.origin.as_ptr(),
            request.origin.len() as u64,
        ))?;
        result(c::R4SdkTransportFetchOptions_set_network_partition(
            out.as_mut_ptr(),
            request.partition.as_ptr(),
            request.partition.len() as u64,
        ))?;
        result(c::R4SdkTransportFetchOptions_set_cors(
            out.as_mut_ptr(),
            request.cors as u8,
        ))?;
        result(c::R4SdkTransportFetchOptions_set_credentials_include(
            out.as_mut_ptr(),
            request.credentials as u8,
        ))?;
        if let Some(table) = request.callbacks {
            result(c::R4SdkTransport_fetchCallbacks(
                0,
                out.as_mut_ptr(),
                table.native,
            ))?;
        }
    }
    Ok(out)
}
pub struct Response<'a> {
    pub status: u16,
    pub secure: bool,
    pub redirects: u8,
    pub body: &'a [u8],
    pub headers: &'a [u8],
    final_url: [u8; 1025],
    final_url_len: usize,
}
impl Response<'_> {
    pub fn final_url(&self) -> &[u8] {
        &self.final_url[..self.final_url_len]
    }
}
pub(crate) fn response<'a>(
    value: &MaybeUninit<c::R4SdkTransportFetchResult>,
    raw: &'a [u8],
    body: &'a [u8],
) -> Result<Response<'a>> {
    unsafe {
        let tag = required(c::R4SdkTransportFetchResult_inspectNative(value.as_ptr()))?.bits;
        if tag == u64::from(c::R4SdkTransportFetchResult_TAG_failure) {
            return Err(Error::Fetch(
                required(c::R4SdkTransportFetchResult_get_failure(value.as_ptr()))?.bits as u32,
            ));
        }
        if tag != u64::from(c::R4SdkTransportFetchResult_TAG_response) {
            return Err(Error::InvalidNative);
        }
        let mut native = MaybeUninit::uninit();
        required(c::R4SdkTransportFetchResult_get_response(
            value.as_ptr(),
            native.as_mut_ptr(),
        ))?;
        let mut out = Response {
            status: required(c::R4SdkTransportFetchResponse_get_status(native.as_ptr()))?.bits
                as u16,
            secure: required(c::R4SdkTransportFetchResponse_get_secure(native.as_ptr()))?.bits != 0,
            redirects: required(c::R4SdkTransportFetchResponse_get_redirects(
                native.as_ptr(),
            ))?
            .bits as u8,
            body: view(
                c::R4SdkTransportFetchResponse_get_body(native.as_ptr()),
                body,
            )?,
            headers: view(
                c::R4SdkTransportFetchResponse_get_headers(native.as_ptr()),
                raw,
            )?,
            final_url: [0; 1025],
            final_url_len: 0,
        };
        let mut url = MaybeUninit::uninit();
        required(c::R4SdkTransportFetchResponse_get_final_url(
            native.as_ptr(),
            url.as_mut_ptr(),
        ))?;
        let v = required(c::R4SdkTransportFinalUrl_bytes(0, url.as_ptr()))?;
        if v.length > 1025 || v.ptr.is_null() {
            return Err(Error::InvalidNative);
        }
        out.final_url_len = v.length as usize;
        out.final_url[..out.final_url_len]
            .copy_from_slice(core::slice::from_raw_parts(v.ptr.cast(), out.final_url_len));
        Ok(out)
    }
}
/// Its native bundle is borrowed at its final address. Synchronous responses
/// borrow only caller output; no transport pointer/owner survives the call.
pub struct Transport<'s, 'a> {
    native: *mut c::R4SdkTransportContext,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkTransportContext>>,
    _app: PhantomData<&'a App<'a>>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'a> Transport<'s, 'a> {
    pub fn open(
        storage: &'s mut MaybeUninit<c::R4SdkTransportContext>,
        app: &'a App<'_>,
    ) -> Result<Self> {
        let v = required(unsafe {
            c::R4SdkTransport_open(0, storage.as_mut_ptr(), app.start_context())
        })?;
        if v.bits == 0 {
            return Err(Error::Unavailable);
        }
        Ok(Self {
            native: storage.as_mut_ptr(),
            _storage: PhantomData,
            _app: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn fetch<'b>(
        &mut self,
        request: Request<'_, '_>,
        raw: &'b mut [u8],
        body: &'b mut [u8],
        scratch: &mut [u8],
    ) -> Result<Response<'b>> {
        let options = options(&request)?;
        let mut value = MaybeUninit::uninit();
        let native = required(unsafe { c::R4SdkTransport_transport(0, self.native) })?
            .ptr
            .cast();
        required(unsafe {
            c::R4SdkTransportWebTransport_fetch(
                0,
                native,
                request.url.as_ptr(),
                request.url.len() as u64,
                raw.as_mut_ptr(),
                raw.len() as u64,
                body.as_mut_ptr(),
                body.len() as u64,
                scratch.as_mut_ptr(),
                scratch.len() as u64,
                options.as_ptr(),
                value.as_mut_ptr(),
            )
        })?;
        response(&value, raw, body)
    }
    /// # Safety
    /// Preserve the bundle address and all original socket/session/job loans.
    /// Async operations must own or scope every input through real collect().
    pub unsafe fn native(&mut self) -> *mut c::R4SdkTransportContext {
        self.native
    }
}
pub const SCRATCH_BYTES: usize = c::R4SdkTransport_tls_scratch_bytes as usize;
const _: () = {
    assert!(core::mem::size_of::<abi::R4Timeout>() == 16);
};
