#![no_std]
extern crate alloc;
use alloc::{boxed::Box, vec};
use core::{ffi::c_void, fmt::Write, mem::MaybeUninit, pin::pin};
use r4os_sdk::{
    App,
    data::{Arena, ArenaStorage},
    resources::Timeout,
    web::{
        Callbacks, Document, Memory,
        transport::{self, Job, Request, Transport, raw as c},
    },
};
struct Output<'a, 'b>(&'a App<'b>);
impl Write for Output<'_, '_> {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        if self.0.write(s) < 0 {
            Err(core::fmt::Error)
        } else {
            Ok(())
        }
    }
}
enum Error {
    Code(u32),
    Transport(transport::Error),
    Data(r4os_sdk::data::Error),
}
impl core::fmt::Debug for Error {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Code(v) => write!(f, "line={v}"),
            Self::Transport(v) => write!(f, "{v:?}"),
            Self::Data(v) => write!(f, "{v:?}"),
        }
    }
}
impl From<transport::Error> for Error {
    fn from(e: transport::Error) -> Self {
        Self::Transport(e)
    }
}
impl From<r4os_sdk::data::Error> for Error {
    fn from(e: r4os_sdk::data::Error) -> Self {
        Self::Data(e)
    }
}
type Result<T> = core::result::Result<T, Error>;
macro_rules! ensure {
    ($ok:expr) => {
        if !$ok {
            return Err(Error::Code(line!()));
        }
    };
}
unsafe extern "C" {
    fn sdk_transport_c_case(scratch: *mut u8, capacity: usize) -> i32;
    fn sdk_transport_network_case(
        start: *const r4os_sdk::abi::R4XStartContext,
        scratch: *mut u8,
        capacity: usize,
        download: *mut u8,
        download_capacity: usize,
        tls_error: *mut u32,
    ) -> i32;
    fn sdk_transport_runtime_job_case(
        start: *const r4os_sdk::abi::R4XStartContext,
        allocator: *mut c::R4SdkDataAllocator,
        programs: *mut c::R4SdkWebJsProgramAllocator,
        document: *mut c::R4SdkWebHtmlDocument,
        storage: *mut c::R4SdkWebNative_web_security_BrowserStorage,
        runtime: *mut c::R4SdkWebRuntimeWebRuntime,
        job: *mut c::R4SdkTransportRuntimeJobsRequestJob,
    ) -> i32;
}
fn web(v: c::R4SdkWebSlot) -> Result<()> {
    ensure!(v.status == 0 && v.flags & 2 == 0);
    Ok(())
}
unsafe extern "C" fn cancel(
    _: *mut c_void,
    kind: u32,
    _: *const c::R4SdkWebSlot,
    _: u32,
    _: *mut c_void,
) -> c::R4SdkWebSlot {
    c::R4SdkWebSlot {
        ptr: core::ptr::null_mut(),
        length: 0,
        bits: 0,
        status: if kind == c::R4SdkWebCallbackKind_network_progress {
            0
        } else {
            -63
        },
        flags: 1,
    }
}
fn sync(app: &App<'_>) -> Result<()> {
    let mut storage = MaybeUninit::uninit();
    let mut t = Transport::open(&mut storage, app)?;
    let mut raw = vec![0; 32768];
    let mut body = vec![0; 8192];
    let mut scratch = vec![0; transport::SCRATCH_BYTES];
    let response = t.fetch(
        Request::get(b"http://10.0.2.2:18163/redirect"),
        &mut raw,
        &mut body,
        &mut scratch,
    )?;
    ensure!(
        response.status == 200
            && response.body == b"abcDEF"
            && response.redirects == 1
            && response.final_url() == b"http://10.0.2.2:18163/chunk"
    );
    let e = t
        .fetch(
            Request::get(b"http://10.0.2.2:18163/truncated"),
            &mut raw,
            &mut body,
            &mut scratch,
        )
        .err();
    ensure!(
        e == Some(transport::Error::Fetch(
            c::R4SdkTransportError_read_peer_closed
        ))
    );
    let mut request = Request::get(b"http://10.0.2.2:18163/stall?timeout");
    request.timeout = Timeout::AfterNanos(100_000_000);
    let e = t.fetch(request, &mut raw, &mut body, &mut scratch).err();
    ensure!(e == Some(transport::Error::Fetch(c::R4SdkTransportError_read_timeout)));
    let mut table = MaybeUninit::uninit();
    let mut state = ();
    let callbacks = unsafe {
        Callbacks::open(
            &mut table,
            &mut state,
            1 << c::R4SdkWebCallbackKind_network_progress,
            cancel,
        )
    }?;
    let mut request = Request::get(b"http://10.0.2.2:18163/never-cancelled");
    request.callbacks = Some(&callbacks);
    let e = t.fetch(request, &mut raw, &mut body, &mut scratch).err();
    ensure!(e == Some(transport::Error::Fetch(c::R4SdkTransportError_cancelled)));
    Ok(())
}
fn jobs(app: &App<'_>) -> Result<()> {
    let mut job = Job::get(
        app,
        b"http://10.0.2.2:18163/plain?rust-job",
        32768,
        8192,
        Timeout::AfterNanos(2_000_000_000),
    )?;
    let mut joined = false;
    for _ in 0..1200 {
        if job.collect()? {
            joined = true;
            break;
        }
        app.sleep(1);
    }
    ensure!(joined);
    ensure!(job.response()?.body == b"transport-body");
    drop(job);
    let mut job = Job::get(
        app,
        b"http://10.0.2.2:18163/stall?rust-cancel",
        32768,
        8192,
        Timeout::AfterNanos(2_000_000_000),
    )?;
    job.cancel()?;
    let mut joined = false;
    for _ in 0..1200 {
        if job.collect()? {
            joined = true;
            break;
        }
        app.sleep(1);
    }
    ensure!(
        joined
            && job.response().err()
                == Some(transport::Error::Fetch(c::R4SdkTransportError_cancelled))
    );
    drop(job);
    // Drop itself must cancel/service/join before freeing any owned backing.
    let job = Job::get(
        app,
        b"http://10.0.2.2:18163/stall?rust-drop",
        32768,
        8192,
        Timeout::AfterNanos(2_000_000_000),
    )?;
    drop(job);
    Ok(())
}
fn runtime_job(app: &App<'_>) -> Result<()> {
    let mut arena_storage = pin!(ArenaStorage::new());
    let mut backing = vec![0; 64 * 1024 * 1024];
    let mut arena = Arena::open(arena_storage.as_mut(), &mut backing)?;
    let mut mem_storage = MaybeUninit::uninit();
    let mut memory = Memory::from_arena(&mut mem_storage, &mut arena)?;
    let mut allocator = MaybeUninit::uninit();
    let mut programs = MaybeUninit::uninit();
    let mut doc = Box::<c::R4SdkWebHtmlDocument>::new_uninit();
    let document = Document::parse(
        &mut doc,
        b"<!doctype html><p>transport</p>",
        b"text/html",
        true,
    )?;
    let mut storage = Box::<c::R4SdkWebNative_web_security_BrowserStorage>::new_uninit();
    let mut runtime = Box::<c::R4SdkWebRuntimeWebRuntime>::new_uninit();
    let mut job = Box::<c::R4SdkTransportRuntimeJobsRequestJob>::new_uninit();
    let code = unsafe {
        web(c::R4SdkWebMemory_get_allocator(
            memory.native(),
            allocator.as_mut_ptr(),
        ))?;
        web(c::R4SdkWeb_memoryPrograms(
            0,
            memory.native(),
            programs.as_mut_ptr(),
        ))?;
        sdk_transport_runtime_job_case(
            app.start_context(),
            allocator.as_mut_ptr(),
            programs.as_mut_ptr(),
            document.native(),
            storage.as_mut_ptr(),
            runtime.as_mut_ptr(),
            job.as_mut_ptr(),
        )
    };
    ensure!(code == 0);
    Ok(())
}
fn main(app: &mut App<'_>) -> i32 {
    let before = app.heap().unwrap().stats().unwrap();
    {
        let mut scratch = vec![0; transport::SCRATCH_BYTES];
        let mut download = vec![0; 200000];
        let code = unsafe { sdk_transport_c_case(scratch.as_mut_ptr(), scratch.len()) };
        if code != 0 {
            let _ = writeln!(&mut Output(app), "FAIL TRANSPORT63 C base line={}", code);
            return 1;
        }
        app.write("PASS TRANSPORT63 C parser/cache/callback/IPv4\n");
        let mut tls = 0;
        let code = unsafe {
            sdk_transport_network_case(
                app.start_context(),
                scratch.as_mut_ptr(),
                scratch.len(),
                download.as_mut_ptr(),
                download.len(),
                &mut tls,
            )
        };
        if code != 0 {
            let _ = writeln!(
                &mut Output(app),
                "FAIL TRANSPORT63 C network line={} tls={}",
                code,
                tls
            );
            return 2;
        }
        app.write("PASS TRANSPORT63 C cookies/target policy/owner-thread callbacks/TLS alert/200000-byte resume\n");
    }
    for (i, case) in [sync as fn(&App<'_>) -> Result<()>, jobs, runtime_job]
        .into_iter()
        .enumerate()
    {
        if let Err(e) = case(app) {
            let _ = writeln!(&mut Output(app), "FAIL TRANSPORT63 Rust case={} {:?}", i, e);
            return 3 + i as i32;
        }
        let _ = writeln!(&mut Output(app), "PASS TRANSPORT63 Rust case={}", i);
    }
    let after = app.heap().unwrap().stats().unwrap();
    if before.get(c"active_allocations") != after.get(c"active_allocations")
        || before.get(c"active_bytes") != after.get(c"active_bytes")
    {
        app.write("FAIL TRANSPORT63 heap balance\n");
        return 90;
    }
    app.write(
        "PASS TRANSPORT63 Rust/C exact worker join, generation cancellation and heap release\n",
    );
    0
}
r4os_sdk::app!(main);
