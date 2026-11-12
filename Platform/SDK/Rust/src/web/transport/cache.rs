use super::{Error, MaybeUninit, PhantomData, Result, c, required, result};
use crate::data::Arena;
#[derive(Clone, Copy)]
#[repr(u32)]
pub enum CacheMode {
    Normal = c::R4SdkWebNative_web_response_cache_Mode_normal,
    NoStore = c::R4SdkWebNative_web_response_cache_Mode_no_store,
    Reload = c::R4SdkWebNative_web_response_cache_Mode_reload,
    NoCache = c::R4SdkWebNative_web_response_cache_Mode_no_cache,
    ForceCache = c::R4SdkWebNative_web_response_cache_Mode_force_cache,
    OnlyIfCached = c::R4SdkWebNative_web_response_cache_Mode_only_if_cached,
}
pub struct CacheKey<'a> {
    pub url: &'a [u8],
    pub context: &'a [u8],
    pub headers: &'a [u8],
}
#[derive(Clone, Copy)]
pub struct CacheClock {
    pub monotonic_ms: u64,
    pub unix_seconds: Option<u64>,
}
fn key(value: CacheKey<'_>) -> Result<MaybeUninit<c::R4SdkTransportCacheKey>> {
    let mut out = MaybeUninit::uninit();
    required(unsafe {
        c::R4SdkTransportCacheKey_create(
            out.as_mut_ptr(),
            value.url.as_ptr(),
            value.url.len() as u64,
            value.context.as_ptr(),
            value.context.len() as u64,
            value.headers.as_ptr(),
            value.headers.len() as u64,
        )
    })?;
    Ok(out)
}
fn clock(value: CacheClock) -> Result<MaybeUninit<c::R4SdkTransportCacheClock>> {
    let mut out = MaybeUninit::uninit();
    let seconds = c::R4SdkTransportSlot {
        ptr: core::ptr::null_mut(),
        length: 0,
        bits: value.unix_seconds.unwrap_or(0),
        status: 0,
        flags: u32::from(value.unix_seconds.is_some()),
    };
    required(unsafe {
        c::R4SdkTransportCacheClock_from_fields(out.as_mut_ptr(), value.monotonic_ms, seconds)
    })?;
    Ok(out)
}
/// Original cache owner, bound to its storage/arena. Lease pins preserve
/// immutable entry bytes while invalidate retires them. !Send/!Sync.
pub struct Cache<'s, 'a> {
    native: *mut c::R4SdkTransportCacheCache,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkTransportCacheCache>>,
    _arena: PhantomData<&'a mut ()>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'a> Cache<'s, 'a> {
    pub fn open(
        storage: &'s mut MaybeUninit<c::R4SdkTransportCacheCache>,
        arena: &'a mut Arena<'_, '_>,
        object_bytes: usize,
        total_bytes: usize,
    ) -> Result<Self> {
        let allocator = arena.allocator()?;
        let mut limits = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkTransportCacheLimits_from_fields(
                limits.as_mut_ptr(),
                object_bytes as u64,
                total_bytes as u64,
            )
        })?;
        required(unsafe {
            c::R4SdkTransportCacheCache_init(
                0,
                allocator.as_ptr(),
                limits.as_ptr(),
                storage.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            native: storage.as_mut_ptr(),
            _storage: PhantomData,
            _arena: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn store(
        &mut self,
        k: CacheKey<'_>,
        headers: &[u8],
        body: &[u8],
        now: CacheClock,
        request_started_ms: u64,
    ) -> Result<Option<u64>> {
        let k = key(k)?;
        let now = clock(now)?;
        let v = result(unsafe {
            c::R4SdkTransportCacheCache_store(
                0,
                self.native,
                k.as_ptr(),
                headers.as_ptr(),
                headers.len() as u64,
                body.as_ptr(),
                body.len() as u64,
                now.as_ptr(),
                request_started_ms,
                c::R4SdkTransportSlot {
                    ptr: core::ptr::null_mut(),
                    length: 0,
                    bits: 0,
                    status: 0,
                    flags: 0,
                },
            )
        })?;
        Ok(if v.flags & 1 == 0 { None } else { Some(v.bits) })
    }
    pub fn invalidate(&self, k: CacheKey<'_>) -> Result<()> {
        let k = key(k)?;
        result(unsafe { c::R4SdkTransportCacheCache_invalidate(0, self.native, k.as_ptr()) })?;
        Ok(())
    }
    pub fn lookup<'c>(
        &'c self,
        k: CacheKey<'_>,
        mode: CacheMode,
        now: CacheClock,
    ) -> Result<Option<CacheLease<'c, 's, 'a>>> {
        let k = key(k)?;
        let now_native = clock(now)?;
        let mut lookup = MaybeUninit::uninit();
        let mut handle = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkTransportCacheCache_lookup(
                0,
                self.native,
                k.as_ptr(),
                mode as u32,
                now_native.as_ptr(),
                lookup.as_mut_ptr(),
            )
        })?;
        let action = required(unsafe { c::R4SdkTransportCacheLookup_get_action(lookup.as_ptr()) })?
            .bits as u32;
        let v = result(unsafe {
            c::R4SdkTransportCacheLookup_get_handle(lookup.as_ptr(), handle.as_mut_ptr())
        })?;
        Ok(if v.flags & 1 == 0 {
            None
        } else {
            Some(CacheLease {
                owner: self,
                handle,
                action,
                now,
            })
        })
    }
}
impl Drop for Cache<'_, '_> {
    fn drop(&mut self) {
        let _ = unsafe { c::R4SdkTransportCacheCache_deinit(0, self.native) };
    }
}
pub struct CacheLease<'c, 's, 'a> {
    owner: &'c Cache<'s, 'a>,
    handle: MaybeUninit<c::R4SdkTransportCacheHandle>,
    pub action: u32,
    now: CacheClock,
}
impl CacheLease<'_, '_, '_> {
    fn part(&self, body: bool) -> Result<&[u8]> {
        let now = clock(self.now)?;
        let mut view = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkTransportCacheCache_view(
                0,
                self.owner.native,
                self.handle.as_ptr(),
                now.as_ptr(),
                view.as_mut_ptr(),
            )
        })?;
        let v = required(unsafe {
            if body {
                c::R4SdkTransportCacheView_get_body(view.as_ptr())
            } else {
                c::R4SdkTransportCacheView_get_headers(view.as_ptr())
            }
        })?;
        if v.length == 0 {
            return Ok(&[]);
        }
        if v.ptr.is_null() || v.length > isize::MAX as u64 {
            return Err(Error::InvalidNative);
        }
        Ok(unsafe { core::slice::from_raw_parts(v.ptr.cast(), v.length as usize) })
    }
    pub fn body(&self) -> Result<&[u8]> {
        self.part(true)
    }
    pub fn headers(&self) -> Result<&[u8]> {
        self.part(false)
    }
}
impl Drop for CacheLease<'_, '_, '_> {
    fn drop(&mut self) {
        let _ = unsafe {
            c::R4SdkTransportCacheCache_release(0, self.owner.native, self.handle.as_ptr())
        };
    }
}
