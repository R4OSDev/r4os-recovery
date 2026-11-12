//! Bounded POST streaming through the original HTTP/TCP/TLS owner.
use super::{Error, Method, Request, Result, Transport, c, options, required, result};
use crate::{
    resources::{StopFlag, Timeout},
    web::Callbacks,
};
use core::{marker::PhantomData, mem::MaybeUninit};

pub struct PostBuffers<'a> {
    pub headers: &'a mut [u8],
    pub io: &'a mut [u8],
    pub upload: &'a mut [u8],
    pub tls: &'a mut [u8],
}

/// Enable callback kind post_stream_write for the sink. Enabling
/// post_stream_read selects a reader instead of request.body. A reader returns
/// a positive byte count, 0 EOF, -1 pause, -2 cancel, or -3 failure.
pub struct PostRequest<'a> {
    pub request: Request<'a, 'a>,
    pub request_length: Option<u64>,
    pub request_body_limit: u64,
    pub response_body_limit: u64,
    pub allow_close_delimited: bool,
    pub stop: Option<&'a StopFlag>,
    pub redirect_error: bool,
}
impl<'a> PostRequest<'a> {
    pub fn new(url: &'a [u8], body: &'a [u8], callbacks: &'a Callbacks<'a, 'a>) -> Self {
        let mut request = Request::get(url);
        request.method = Method::Post;
        request.body = body;
        request.callbacks = Some(callbacks);
        Self {
            request,
            request_length: None,
            request_body_limit: 64 * 1024 * 1024,
            response_body_limit: 64 * 1024 * 1024,
            allow_close_delimited: false,
            stop: None,
            redirect_error: false,
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum StreamState {
    Ready,
    Paused,
    CleanupPending,
    Complete,
    Cancelled,
    Failed,
}
#[derive(Clone, Copy, Debug)]
pub struct StreamReport {
    pub state: StreamState,
    pub failure: Option<u32>,
    pub framing_failure: Option<u32>,
    pub status: Option<u16>,
    pub response_total: Option<u64>,
    pub request_body_confirmed: u64,
    pub application_wire_confirmed: u64,
    pub response_received: u64,
    pub response_delivered: u64,
    pub request_effect_unknown: bool,
    pub http_complete: bool,
    pub tcp_eof: bool,
    pub tls_close_notify: bool,
    pub close_ack: bool,
}

/// Context/buffer/callback loans last through this stream. Pause accepts zero
/// bytes and presents the identical borrowed chunk again on run(). A sink must
/// copy accepted bytes before returning. Transport chunks are not SSE events.
/// Explicitly close and inspect close_ack/can_release; Drop is best effort and
/// does not prove the disposal ACK or undo a possibly effective POST.
#[must_use = "close explicitly and inspect the actual disposal acknowledgement"]
pub struct PostStream<'a> {
    native: *mut c::R4SdkTransportPostStream,
    _loans: PhantomData<&'a mut ()>,
    _local: PhantomData<*mut ()>,
}
impl Transport<'_, '_> {
    pub fn post_stream<'a>(
        &'a mut self,
        storage: &'a mut MaybeUninit<c::R4SdkTransportPostStream>,
        config: PostRequest<'a>,
        buffers: PostBuffers<'a>,
    ) -> Result<PostStream<'a>> {
        let callbacks = config.request.callbacks.ok_or(Error::Unavailable)?;
        let mut fetch = options(&config.request)?;
        let mut stream_options = MaybeUninit::uninit();
        let mut limits = MaybeUninit::uninit();
        let mut native_buffers = MaybeUninit::uninit();
        let mut sink = MaybeUninit::uninit();
        let mut report = MaybeUninit::uninit();
        unsafe {
            result(c::R4SdkTransportFetchOptions_set_redirect(
                fetch.as_mut_ptr(),
                if config.redirect_error {
                    c::R4SdkTransportRedirectMode_error_mode
                } else {
                    c::R4SdkTransportRedirectMode_manual
                },
            ))?;
            if let Some(stop) = config.stop {
                result(c::R4SdkTransportFetchOptions_set_stop(
                    fetch.as_mut_ptr(),
                    c::R4SdkTransportSlot {
                        ptr: (stop as *const StopFlag).cast_mut().cast(),
                        flags: 1,
                        length: 0,
                        bits: 0,
                        status: 0,
                    },
                ))?;
            }
            required(c::R4SdkTransportPostStreamOptions_create(
                stream_options.as_mut_ptr(),
            ))?;
            required(c::R4SdkTransportHttpPayloadStreamLimits_create(
                limits.as_mut_ptr(),
            ))?;
            result(c::R4SdkTransportHttpPayloadStreamLimits_set_body_bytes(
                limits.as_mut_ptr(),
                config.response_body_limit,
            ))?;
            result(
                c::R4SdkTransportHttpPayloadStreamLimits_set_allow_close_delimited(
                    limits.as_mut_ptr(),
                    config.allow_close_delimited as u8,
                ),
            )?;
            result(c::R4SdkTransportPostStreamOptions_set_request(
                stream_options.as_mut_ptr(),
                fetch.as_ptr(),
            ))?;
            result(c::R4SdkTransportPostStreamOptions_set_request_body_limit(
                stream_options.as_mut_ptr(),
                config.request_body_limit,
            ))?;
            result(c::R4SdkTransportPostStreamOptions_set_response_limits(
                stream_options.as_mut_ptr(),
                limits.as_ptr(),
            ))?;
            if let Some(length) = config.request_length {
                result(c::R4SdkTransportPostStreamOptions_set_request_length(
                    stream_options.as_mut_ptr(),
                    c::R4SdkTransportSlot {
                        ptr: core::ptr::null_mut(),
                        length: 0,
                        bits: length,
                        status: 0,
                        flags: 1,
                    },
                ))?;
            }
            result(c::R4SdkTransport_postStreamCallbacks(
                0,
                stream_options.as_mut_ptr(),
                callbacks.native,
            ))?;
            required(c::R4SdkTransport_postStreamSink(
                0,
                callbacks.native,
                sink.as_mut_ptr(),
            ))?;
            required(c::R4SdkTransportPostStreamBuffers_from_fields(
                native_buffers.as_mut_ptr(),
                buffers.headers.as_mut_ptr(),
                buffers.headers.len() as u64,
                buffers.io.as_mut_ptr(),
                buffers.io.len() as u64,
                buffers.upload.as_mut_ptr(),
                buffers.upload.len() as u64,
                buffers.tls.as_mut_ptr(),
                buffers.tls.len() as u64,
            ))?;
            required(c::R4SdkTransport_postStreamInit(
                0,
                storage.as_mut_ptr(),
                self.native,
                config.request.url.as_ptr(),
                config.request.url.len() as u64,
                native_buffers.as_ptr(),
                sink.as_ptr(),
                stream_options.as_ptr(),
                report.as_mut_ptr(),
            ))?;
        }
        Ok(PostStream {
            native: storage.as_mut_ptr(),
            _loans: PhantomData,
            _local: PhantomData,
        })
    }
}

impl PostStream<'_> {
    pub fn run(&mut self) -> Result<StreamReport> {
        let mut report = MaybeUninit::uninit();
        required(unsafe { c::R4SdkTransport_postStreamRun(0, self.native, report.as_mut_ptr()) })?;
        decode_report(&report)
    }
    pub fn report(&self) -> Result<StreamReport> {
        let mut report = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkTransport_postStreamReport(0, self.native, report.as_mut_ptr())
        })?;
        decode_report(&report)
    }
    /// Stop intent; completion and disposal are separate acknowledgements.
    pub fn cancel(&mut self) -> Result<()> {
        result(unsafe { c::R4SdkTransport_postStreamCancel(0, self.native) })?;
        Ok(())
    }
    pub fn close(&mut self, timeout: Timeout) -> Result<bool> {
        Ok(
            required(unsafe { c::R4SdkTransport_postStreamClose(0, self.native, &timeout.raw()) })?
                .bits
                != 0,
        )
    }
    pub fn can_release(&self) -> Result<bool> {
        Ok(required(unsafe { c::R4SdkTransport_postStreamCanRelease(0, self.native) })?.bits != 0)
    }
    /// # Safety
    /// Preserve all context, buffer, option and callback loans. Do not reenter
    /// the native owner or release it before its actual Close acknowledgement.
    pub unsafe fn native(&mut self) -> *mut c::R4SdkTransportPostStream {
        self.native
    }
}
impl Drop for PostStream<'_> {
    fn drop(&mut self) {
        let _ = unsafe { c::R4SdkTransport_postStreamClose(0, self.native, &Timeout::Poll.raw()) };
    }
}

fn optional(v: c::R4SdkTransportSlot) -> Result<Option<u64>> {
    let value = result(v)?;
    Ok(if value.flags & 1 == 0 {
        None
    } else {
        Some(value.bits)
    })
}
fn decode_report(value: &MaybeUninit<c::R4SdkTransportPostStreamReport>) -> Result<StreamReport> {
    let p = value.as_ptr();
    unsafe {
        let state = match required(c::R4SdkTransportPostStreamReport_get_state(p))?.bits as u32 {
            c::R4SdkTransportPostStreamState_ready => StreamState::Ready,
            c::R4SdkTransportPostStreamState_paused => StreamState::Paused,
            c::R4SdkTransportPostStreamState_cleanup_pending => StreamState::CleanupPending,
            c::R4SdkTransportPostStreamState_complete => StreamState::Complete,
            c::R4SdkTransportPostStreamState_cancelled => StreamState::Cancelled,
            c::R4SdkTransportPostStreamState_failed => StreamState::Failed,
            _ => return Err(Error::InvalidNative),
        };
        Ok(StreamReport {
            state,
            failure: optional(c::R4SdkTransportPostStreamReport_get_failure(p))?.map(|v| v as u32),
            framing_failure: optional(c::R4SdkTransportPostStreamReport_get_framing_failure(p))?
                .map(|v| v as u32),
            status: optional(c::R4SdkTransportPostStreamReport_get_status(p))?.map(|v| v as u16),
            response_total: optional(c::R4SdkTransportPostStreamReport_get_response_total(p))?,
            request_body_confirmed: required(
                c::R4SdkTransportPostStreamReport_get_request_body_confirmed(p),
            )?
            .bits,
            application_wire_confirmed: required(
                c::R4SdkTransportPostStreamReport_get_application_wire_confirmed(p),
            )?
            .bits,
            response_received: required(c::R4SdkTransportPostStreamReport_get_response_received(
                p,
            ))?
            .bits,
            response_delivered: required(
                c::R4SdkTransportPostStreamReport_get_response_delivered(p),
            )?
            .bits,
            request_effect_unknown: required(
                c::R4SdkTransportPostStreamReport_get_request_effect_unknown(p),
            )?
            .bits
                != 0,
            http_complete: required(c::R4SdkTransportPostStreamReport_get_http_complete(p))?.bits
                != 0,
            tcp_eof: required(c::R4SdkTransportPostStreamReport_get_tcp_eof(p))?.bits != 0,
            tls_close_notify: required(c::R4SdkTransportPostStreamReport_get_tls_close_notify(p))?
                .bits
                != 0,
            close_ack: required(c::R4SdkTransportPostStreamReport_get_close_ack(p))?.bits != 0,
        })
    }
}
