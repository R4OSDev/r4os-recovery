#![cfg(test)]
use core::{mem::MaybeUninit, pin::pin};
use r4os_sdk::{
    data::{Arena, ArenaStorage},
    web::transport::{Cache, CacheClock, CacheKey, CacheMode, raw as c},
};
unsafe extern "C" {
    fn sdk_transport_c_case(scratch: *mut u8, capacity: usize) -> i32;
    fn sdk_transport_bootstrap_case() -> i32;
}
fn check(v: c::R4SdkTransportSlot) -> c::R4SdkTransportSlot {
    assert_eq!(v.status, 0);
    assert_eq!(v.flags & 2, 0);
    v
}
#[test]
fn download_metadata_callback_and_retry_defaults_match_the_native_owner() {
    use core::{cell::Cell, ffi::c_void};
    struct State<'a> {
        allow: &'a Cell<bool>,
        calls: &'a Cell<u32>,
    }
    unsafe extern "C" fn observe(
        user: *mut c_void,
        kind: u32,
        args: *const c::R4SdkWebSlot,
        count: u32,
        _: *mut c_void,
    ) -> c::R4SdkWebSlot {
        let reject = || c::R4SdkWebSlot {
            ptr: core::ptr::null_mut(),
            length: 0,
            bits: 0,
            status: 0,
            flags: 1,
        };
        if user.is_null()
            || args.is_null()
            || count != 2
            || kind != c::R4SdkWebCallbackKind_download_head
        {
            return reject();
        }
        let args = unsafe { core::slice::from_raw_parts(args, 2) };
        if args[0].ptr != user || args[1].ptr.is_null() {
            return reject();
        }
        let head = args[1]
            .ptr
            .cast::<c::R4SdkTransportDownloadHeadObservation>();
        let offset = unsafe { c::R4SdkTransportDownloadHeadObservation_get_requested_offset(head) };
        let headers = unsafe { c::R4SdkTransportDownloadHeadObservation_get_headers(head) };
        if offset.status != 0
            || offset.bits != 7
            || headers.status != 0
            || headers.ptr.is_null()
            || headers.length != 18
        {
            return reject();
        }
        if unsafe { core::slice::from_raw_parts(headers.ptr.cast::<u8>(), 18) }
            != b"ETag: \"expected\"\r\n"
        {
            return reject();
        }
        let state = unsafe { &*user.cast::<State<'_>>() };
        state.calls.set(state.calls.get() + 1);
        c::R4SdkWebSlot {
            bits: u64::from(state.allow.get()),
            ..reject()
        }
    }
    let allow = Cell::new(true);
    let calls = Cell::new(0);
    let mut state = State {
        allow: &allow,
        calls: &calls,
    };
    let mut callback_storage = MaybeUninit::uninit();
    let callbacks = unsafe {
        r4os_sdk::web::Callbacks::open(
            &mut callback_storage,
            &mut state,
            1u64 << c::R4SdkWebCallbackKind_download_head,
            observe,
        )
        .unwrap()
    };
    let mut options = MaybeUninit::uninit();
    let mut response = MaybeUninit::uninit();
    let mut head = MaybeUninit::uninit();
    let headers = b"ETag: \"expected\"\r\n";
    unsafe {
        check(c::R4SdkTransportDownloadOptions_create(
            options.as_mut_ptr(),
        ));
        assert_eq!(
            check(c::R4SdkTransportDownloadOptions_get_max_retries(
                options.as_ptr()
            ))
            .bits,
            1
        );
        check(c::R4SdkTransportDownloadOptions_set_max_retries(
            options.as_mut_ptr(),
            0,
        ));
        assert_eq!(
            check(c::R4SdkTransportDownloadOptions_get_max_retries(
                options.as_ptr()
            ))
            .bits,
            0
        );
        let absent = c::R4SdkTransportSlot {
            ptr: core::ptr::null_mut(),
            length: 0,
            bits: 0,
            status: 0,
            flags: 0,
        };
        check(c::R4SdkTransportHttpStreamResponse_from_fields(
            response.as_mut_ptr(),
            200,
            c::R4SdkTransportHttpTransfer_content_length,
            6,
            absent,
            absent,
            absent,
        ));
        check(c::R4SdkTransportDownloadHeadObservation_from_fields(
            head.as_mut_ptr(),
            response.as_ptr(),
            headers.as_ptr(),
            headers.len() as u64,
            7,
        ));
        check(c::R4SdkTransport_downloadCallbacks(
            0,
            options.as_mut_ptr(),
            callbacks.native(),
        ));
        assert_eq!(
            check(c::R4SdkTransportDownloadOptions_observeHead(
                0,
                options.as_ptr(),
                head.as_ptr()
            ))
            .bits,
            1
        );
        allow.set(false);
        assert_eq!(
            check(c::R4SdkTransportDownloadOptions_observeHead(
                0,
                options.as_ptr(),
                head.as_ptr()
            ))
            .bits,
            0
        );
    }
    assert_eq!(calls.get(), 2);
}
#[test]
fn original_c_parser_cache_callbacks_and_ipv4() {
    let mut scratch = vec![0; 32768];
    let code = unsafe { sdk_transport_c_case(scratch.as_mut_ptr(), scratch.len()) };
    assert_eq!(code, 0);
}
#[test]
fn generated_registration_endpoint_preserves_public_ip_and_tls_mode() {
    let mut ip = MaybeUninit::<c::R4SdkTransportNative_app_network_Ipv4Address>::uninit();
    let mut endpoint = MaybeUninit::<c::R4SdkTransportRegistrationEndpoint>::uninit();
    let name = b"138.201.253.143";
    unsafe {
        check(c::R4SdkTransportNative_app_network_Ipv4Address_init(
            0,
            138,
            201,
            253,
            143,
            ip.as_mut_ptr(),
        ));
        check(c::R4SdkTransportRegistrationEndpoint_from_fields(
            endpoint.as_mut_ptr(),
            ip.as_ptr(),
            name.as_ptr(),
            name.len() as u64,
            4021,
            1,
        ));
        let hostname = check(c::R4SdkTransportRegistrationEndpoint_get_hostname(
            endpoint.as_ptr(),
        ));
        assert_eq!(
            core::slice::from_raw_parts(hostname.ptr.cast::<u8>(), hostname.length as usize),
            name
        );
        assert_eq!(
            check(c::R4SdkTransportRegistrationEndpoint_get_port(
                endpoint.as_ptr()
            ))
            .bits,
            4021
        );
        assert_eq!(
            check(c::R4SdkTransportRegistrationEndpoint_get_tls(
                endpoint.as_ptr()
            ))
            .bits,
            1
        );
    }
}
#[test]
fn common_startup_binds_original_entropy_without_optional_host_instructions() {
    assert_eq!(unsafe { sdk_transport_bootstrap_case() }, 0);
}
#[test]
fn cache_invalidation_keeps_exact_pinned_view_until_release() {
    let mut arena_storage = pin!(ArenaStorage::new());
    let mut bytes = vec![0; 65536];
    let mut arena = Arena::open(arena_storage.as_mut(), &mut bytes).unwrap();
    let mut storage = MaybeUninit::uninit();
    let mut cache = Cache::open(&mut storage, &mut arena, 256, 4096).unwrap();
    let key = || CacheKey {
        url: b"http://local/x",
        context: b"partition",
        headers: b"accept:x\r\n",
    };
    let now = CacheClock {
        monotonic_ms: 1000,
        unix_seconds: None,
    };
    assert!(
        cache
            .store(key(), b"Cache-Control: max-age=60\r\n", b"body", now, 1000)
            .unwrap()
            .is_some()
    );
    {
        let lease = cache
            .lookup(key(), CacheMode::Normal, now)
            .unwrap()
            .unwrap();
        let body = lease.body().unwrap();
        cache.invalidate(key()).unwrap();
        assert_eq!(body, b"body");
        assert_eq!(lease.headers().unwrap(), b"Cache-Control: max-age=60\r\n");
    }
    assert!(
        cache
            .lookup(key(), CacheMode::OnlyIfCached, now)
            .unwrap()
            .is_none()
    );
}
#[test]
fn original_response_decoding_rejects_truncation_and_preserves_cancel() {
    let input = b"HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nabc";
    let mut out = [0; 16];
    let mut decoder = MaybeUninit::uninit();
    let mut result = MaybeUninit::uninit();
    unsafe {
        check(c::R4SdkTransportHttpResponseDecoder_init(
            0,
            c::R4SdkWebNative_http_Method_get,
            decoder.as_mut_ptr(),
        ));
        check(c::R4SdkTransportHttpResponseDecoder_decode(
            0,
            decoder.as_mut_ptr(),
            input.as_ptr(),
            input.len() as u64,
            out.as_mut_ptr(),
            16,
            1,
            0,
            result.as_mut_ptr(),
        ));
        assert_eq!(
            check(c::R4SdkTransportHttpDecodeResult_inspectNative(
                result.as_ptr()
            ))
            .bits,
            u64::from(c::R4SdkTransportHttpDecodeResult_TAG_failure)
        );
        check(c::R4SdkTransportHttpResponseDecoder_init(
            0,
            c::R4SdkWebNative_http_Method_get,
            decoder.as_mut_ptr(),
        ));
        check(c::R4SdkTransportHttpResponseDecoder_decode(
            0,
            decoder.as_mut_ptr(),
            input.as_ptr(),
            input.len() as u64,
            out.as_mut_ptr(),
            16,
            0,
            1,
            result.as_mut_ptr(),
        ));
        assert_eq!(
            check(c::R4SdkTransportHttpDecodeResult_inspectNative(
                result.as_ptr()
            ))
            .bits,
            u64::from(c::R4SdkTransportHttpDecodeResult_TAG_aborted)
        );
    }
}
