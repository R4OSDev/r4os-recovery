extern crate alloc;
use alloc::vec;
use core::{ffi::c_void, mem::MaybeUninit};
use r4os_sdk::subsystems::{
    self as s, Callbacks, Clock, Command, Config, Cycle, Error, Launch, LaunchOption, Pacer,
    Result, Runtime, raw as c,
};
unsafe extern "C" {
    fn sdk65_fixture_init(p: *mut c_void);
    fn sdk65_fixture_mask() -> u64;
    fn sdk65_fixture_summary(p: *const c_void, out: *mut u64);
    fn sdk65_fixture_dispatch(
        p: *mut c_void,
        kind: u32,
        args: *const c::R4SdkSubsystemSlot,
        count: u32,
        output: *mut c_void,
    ) -> c::R4SdkSubsystemSlot;
    fn sdk65_c_runtime(out: *mut u64) -> i32;
    fn sdk65_c_video(out: *mut u64) -> i32;
}
#[repr(C, align(16))]
struct Fixture([MaybeUninit<u8>; 8192]);
fn check(v: c::R4SdkSubsystemSlot) -> Result<()> {
    if v.status != 0 {
        return Err(Error::Transport(v.status));
    }
    if v.flags & 2 != 0 {
        return Err(Error::InvalidNative);
    }
    Ok(())
}
fn matches(test: bool) -> Result<()> {
    if test {
        Ok(())
    } else {
        Err(Error::InvalidNative)
    }
}
pub fn clock_launch() -> Result<()> {
    let mut clock = Clock::new(1000, 0)?;
    matches(clock.sync(10)? == 10_000_000)?;
    clock.pause(10)?;
    matches(clock.sync(100)? == 10_000_000)?;
    clock.resume(100)?;
    matches(clock.sync(110)? == 20_000_000)?;
    matches(clock.ticks_until(23_000_000)? == 3)?;
    let mut pacer = Pacer::new(60)?;
    matches(pacer.take(0)?)?;
    matches(!pacer.take(1)?)?;
    let mut out = [0u8; 127];
    let options = [LaunchOption::new(b"C", b"synthetic")?];
    let guest = b"C:\\TEMP\\SYNTH65.BIN";
    let encoded = s::encode_launch(guest, &options, &mut out)?;
    let launch = Launch::parse(encoded)?;
    matches(launch.guest()? == guest)?;
    matches(launch.option(b"C")? == Some(b"synthetic".as_slice()))?;
    matches(launch.option(b"missing")?.is_none())
}
pub fn runtime_summary() -> Result<[u64; 7]> {
    let mut reference = [0u64; 7];
    matches(unsafe { sdk65_c_runtime(reference.as_mut_ptr()) } == 0)?;
    let mut model = Fixture([MaybeUninit::uninit(); 8192]);
    unsafe {
        sdk65_fixture_init((&mut model as *mut Fixture).cast());
    }
    let mut storage = MaybeUninit::uninit();
    {
        let callbacks = unsafe {
            Callbacks::open(
                &mut storage,
                &mut model,
                sdk65_fixture_mask(),
                sdk65_fixture_dispatch,
            )
        }?;
        let mut rt = Runtime::new(
            Config {
                slice_budget: 4,
                max_input_events: 4,
                max_wait_ticks: 8,
                idle_retry_ticks: 1,
            },
            1000,
            0,
            &callbacks,
            &callbacks,
        )?;
        rt.cycle(10)?;
        rt.request(Command::Pause, 10)?;
        rt.cycle(40)?;
        matches(rt.state()? == 2)?;
        rt.request(Command::Resume, 40)?;
        rt.cycle(50)?;
        rt.request(Command::Reset, 50)?;
        rt.cycle(60)?;
        rt.request(Command::Close, 70)?;
        matches(
            rt.cycle(70)?
                == Cycle::Finished {
                    state: 5,
                    exit_code: 0,
                },
        )?;
    }
    let mut actual = [0u64; 7];
    unsafe {
        sdk65_fixture_summary((&model as *const Fixture).cast(), actual.as_mut_ptr());
    }
    matches(actual == reference)?;
    matches(actual[0..4] == [3, 12, 1, 3] && actual[5] == 10_000_000 && actual[6] == 0)?;
    Ok(actual)
}
pub fn runtime() -> Result<()> {
    runtime_summary().map(|_| ())
}

pub fn refused_driver() -> Result<()> {
    let mut model = Fixture([MaybeUninit::uninit(); 8192]);
    let mut storage = MaybeUninit::uninit();
    unsafe {
        sdk65_fixture_init((&mut model as *mut Fixture).cast());
    }
    let callbacks =
        unsafe { Callbacks::open(&mut storage, &mut model, 0, sdk65_fixture_dispatch) }?;
    // Rejected construction must never run a guard on uninitialized native state.
    matches(matches!(
        Runtime::new(Config::default(), 1000, 0, &callbacks, &callbacks),
        Err(Error::Native("MissingCallback"))
    ))
}
pub fn video() -> Result<()> {
    let mut reference = [0u64; 2];
    matches(unsafe { sdk65_c_video(reference.as_mut_ptr()) } == 0)?;
    let mut model = Fixture([MaybeUninit::uninit(); 8192]);
    unsafe {
        sdk65_fixture_init((&mut model as *mut Fixture).cast());
    }
    let mut table = MaybeUninit::uninit();
    let mut scratch = vec![0u32; 128 * 128];
    let mut pixels = [1u32, 2, 3, 4, 5, 6];
    {
        let cb = unsafe {
            Callbacks::open(
                &mut table,
                &mut model,
                sdk65_fixture_mask(),
                sdk65_fixture_dispatch,
            )
        }?;
        let mut backend = MaybeUninit::uninit();
        let mut surface = MaybeUninit::uninit();
        let mut presenter = MaybeUninit::uninit();
        let mut result = MaybeUninit::uninit();
        unsafe {
            check(c::R4SdkSubsystem_videoBackend(
                0,
                cb.native(),
                0,
                0,
                0,
                backend.as_mut_ptr(),
            ))?;
            check(c::R4SdkSubsystemVideoSurface_initXrgb32(
                0,
                pixels.as_mut_ptr(),
                6,
                3,
                2,
                surface.as_mut_ptr(),
            ))?;
            check(c::R4SdkSubsystemVideoPresenter_init(
                0,
                surface.as_ptr(),
                scratch.as_mut_ptr(),
                scratch.len() as u64,
                presenter.as_mut_ptr(),
            ))?;
            check(c::R4SdkSubsystemVideoPresenter_presentTo(
                0,
                presenter.as_mut_ptr(),
                backend.as_ptr(),
                6,
                4,
                result.as_mut_ptr(),
            ))?;
            matches(c::R4SdkSubsystemVideoPresentResult_inspectNative(result.as_ptr()).bits == 2)?;
            check(c::R4SdkSubsystemVideoPresenter_presentTo(
                0,
                presenter.as_mut_ptr(),
                backend.as_ptr(),
                6,
                4,
                result.as_mut_ptr(),
            ))?;
            matches(c::R4SdkSubsystemVideoPresentResult_inspectNative(result.as_ptr()).bits == 0)?;
            pixels[1] = 17;
            let mut rect = MaybeUninit::uninit();
            check(c::R4SdkSubsystemVideoRect_create(
                rect.as_mut_ptr(),
                1,
                0,
                1,
                1,
            ))?;
            check(c::R4SdkSubsystemVideoPresenter_invalidate(
                0,
                presenter.as_mut_ptr(),
                rect.as_ptr(),
            ))?;
            check(c::R4SdkSubsystemVideoPresenter_presentTo(
                0,
                presenter.as_mut_ptr(),
                backend.as_ptr(),
                6,
                4,
                result.as_mut_ptr(),
            ))?;
            check(c::R4SdkSubsystemVideoPresenter_presentTo(
                0,
                presenter.as_mut_ptr(),
                backend.as_ptr(),
                8,
                8,
                result.as_mut_ptr(),
            ))?;
            check(c::R4SdkSubsystemVideoPresenter_deinit(
                0,
                presenter.as_mut_ptr(),
                backend.as_ptr(),
            ))?;
        }
    }
    let mut summary = [0u64; 7];
    unsafe {
        sdk65_fixture_summary((&model as *const Fixture).cast(), summary.as_mut_ptr());
    }
    // Exact backing image is private to the common recording backend.
    unsafe extern "C" {
        fn sdk65_fixture_pixels_hash(p: *const c_void) -> u64;
    }
    let image_hash = unsafe { sdk65_fixture_pixels_hash((&model as *const Fixture).cast()) };
    matches(pixels == [1, 17, 3, 4, 5, 6])?;
    matches(reference == [image_hash, summary[6]])
}
pub fn catalogue() -> Result<()> {
    use alloc::boxed::Box;
    use s::Catalog;
    unsafe extern "C" {
        fn sdk65_fixture_host_state(p: *mut c_void, state: u64);
    }
    let bytes = include_bytes!("../Fixtures/Subsystems/Modules.json");
    let mut workspace = Box::<c::R4SdkUpdateInventoryInventory>::new_uninit();
    let mut storage = Box::<c::R4SdkSubsystemCatalogCatalog>::new_uninit();
    let mut model = Fixture([MaybeUninit::uninit(); 8192]);
    unsafe {
        sdk65_fixture_init((&mut model as *mut Fixture).cast());
    }
    let mut table = MaybeUninit::uninit();
    {
        let cb = unsafe {
            Callbacks::open(
                &mut table,
                &mut model,
                sdk65_fixture_mask(),
                sdk65_fixture_dispatch,
            )
        }?;
        let catalog = Catalog::load(&mut storage, &mut workspace, bytes, &cb)?;
        matches(catalog.count()? == 1)?;
        let resolution = catalog.resolve(b"C:\\TEMP\\S65.BAS", b"PRINT 1", 7, true)?;
        matches(resolution.state()? == 1 && resolution.count()? == 1)?;
        let selected = resolution.selected()?.ok_or(Error::Unavailable)?;
        matches(
            selected.subsystem_id()? == b"r4os.basic"
                && selected.format()? == b"basic.qbasic-source",
        )?;
        let mut out = vec![0u8; 4096];
        let rendered = catalog.render(&mut out)?;
        matches(
            rendered
                .windows(b"MODULES.JSON".len())
                .any(|w| w == b"MODULES.JSON"),
        )?;
    }
    unsafe {
        sdk65_fixture_host_state((&mut model as *mut Fixture).cast(), 1);
    }
    let cb = unsafe {
        Callbacks::open(
            &mut table,
            &mut model,
            sdk65_fixture_mask(),
            sdk65_fixture_dispatch,
        )
    }?;
    matches(matches!(
        Catalog::load(&mut storage, &mut workspace, bytes, &cb),
        Err(Error::Native("MissingHost"))
    ))
}
pub fn audio_failure() -> Result<()> {
    unsafe extern "C" {
        fn sdk65_c_audio(out: *mut u64) -> i32;
    }
    let mut out = [0u64; 5];
    let code = unsafe { sdk65_c_audio(out.as_mut_ptr()) };
    if code != 0 {
        return Err(Error::Transport(code));
    }
    matches(out == [3, 20_000_000, 1, 1, 1])
}
