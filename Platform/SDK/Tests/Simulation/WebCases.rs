//! Reused unchanged by the native test and the real mixed C/Rust R4X probe.
extern crate alloc;
use alloc::{boxed::Box, vec};
use core::{ffi::c_void, mem::MaybeUninit, pin::pin};
use r4os_sdk::{
    data::{Arena, ArenaStorage, Error, Result},
    web::{Callbacks, Canvas, Document, Memory, Reflow, Script, Stylesheet, raw as c},
};
const LAYOUT: &[u8] = include_bytes!("../Fixture/Browser/Layout06228.html");
const FORMS: &[u8] = include_bytes!("../Fixture/Browser/Forms06228.html");
macro_rules! ensure {
    ($ok:expr) => {
        if !$ok {
            return Err(Error::Transport(line!() as i32));
        }
    };
}
fn checked(v: c::R4SdkWebSlot) -> Result<c::R4SdkWebSlot> {
    if v.status != 0 {
        return Err(Error::Transport(v.status));
    }
    if v.flags & 2 != 0 {
        return Err(Error::InvalidNative);
    }
    Ok(v)
}
unsafe fn bytes<'a>(v: c::R4SdkWebSlot) -> Result<&'a [u8]> {
    let v = checked(v)?;
    ensure!(v.flags & 1 != 0 && !v.ptr.is_null() && v.length < 1024 * 1024);
    Ok(unsafe { core::slice::from_raw_parts(v.ptr.cast(), v.length as usize) })
}
unsafe extern "C" {
    fn sdk_web_c_case(
        document: *mut c::R4SdkWebHtmlDocument,
        sheet: *mut c::R4SdkWebCssStylesheet,
        layout: *mut c::R4SdkWebLayoutLayout,
        program: *mut c::R4SdkWebJsProgram,
        runtime: *mut c::R4SdkWebJsRuntime,
        canvas: *mut c::R4SdkWebCanvasManager,
        memory: *mut c::R4SdkWebMemory,
        fixture: *const u8,
        length: usize,
        hash: *mut u64,
    ) -> i32;
}
pub fn c_and_layout() -> Result<u64> {
    let mut arena_storage = pin!(ArenaStorage::new());
    let mut backing = vec![0; 64 * 1024 * 1024];
    let mut arena = Arena::open(arena_storage.as_mut(), &mut backing)?;
    let mut mem_storage = MaybeUninit::uninit();
    let mut memory = Memory::from_arena(&mut mem_storage, &mut arena)?;
    let mut doc = Box::<c::R4SdkWebHtmlDocument>::new_uninit();
    let mut sheet = Box::<c::R4SdkWebCssStylesheet>::new_uninit();
    let mut layout = Box::<c::R4SdkWebLayoutLayout>::new_uninit();
    let mut program = Box::<c::R4SdkWebJsProgram>::new_uninit();
    let mut runtime = Box::<c::R4SdkWebJsRuntime>::new_uninit();
    let mut canvas = Box::<c::R4SdkWebCanvasManager>::new_uninit();
    let mut c_hash = 0;
    let code = unsafe {
        sdk_web_c_case(
            doc.as_mut_ptr(),
            sheet.as_mut_ptr(),
            layout.as_mut_ptr(),
            program.as_mut_ptr(),
            runtime.as_mut_ptr(),
            canvas.as_mut_ptr(),
            memory.native(),
            LAYOUT.as_ptr(),
            LAYOUT.len(),
            &mut c_hash,
        )
    };
    if code != 0 {
        return Err(Error::Transport(code));
    }
    let document = Document::parse(&mut doc, LAYOUT, b"text/html", true)?;
    let mut stylesheet = Stylesheet::parse(&mut sheet, b"")?;
    stylesheet.append_document(&document)?;
    let reflow = Reflow::new(&mut layout, &document, &stylesheet, 480, 240)?;
    ensure!((2..=64).contains(&reflow.operation_count()?));
    ensure!(reflow.structural_hash()? == c_hash);
    Ok(c_hash)
}
pub fn document_forms_fonts_images() -> Result<()> {
    let mut storage = Box::<c::R4SdkWebHtmlDocument>::new_uninit();
    ensure!(Document::parse(&mut storage, b"x", b"image/png", true).is_err());
    let mut doc = Document::parse(
        &mut storage,
        b"<!doctype html><p id=x title='a&amp;b'>Gr\xc3\xbc\xc3\x9fe</p>",
        b"text/html;charset=utf-8",
        true,
    )?;
    let node = doc.find(b"x")?.ok_or(Error::Unavailable)?;
    ensure!(doc.attribute(node, b"title")? == Some(&b"a&b"[..]));
    let mut out = [0; 128];
    ensure!(doc.text(node, &mut out)? == "Grüße".as_bytes());
    doc.set_text(node, b"changed")?;
    ensure!(doc.text(node, &mut out)? == b"changed");
    ensure!(doc.text(node, &mut [0; 2]).is_err());
    let mut doc = Document::parse(&mut storage, FORMS, b"text/html", true)?;
    let submit = doc.first(b"button")?.ok_or(Error::Unavailable)?;
    let mut interaction = Box::<c::R4SdkWebFormsInteraction>::new_uninit();
    let mut base = MaybeUninit::uninit();
    let mut submission = MaybeUninit::uninit();
    let mut body = [0; 128];
    let url = b"https://fixture.example/base";
    unsafe {
        checked(c::R4SdkWebFormsInteraction_create(interaction.as_mut_ptr()))?;
        checked(c::R4SdkWebFormsInteraction_rebuild(
            0,
            interaction.as_mut_ptr(),
            doc.native(),
        ))?;
        checked(c::R4SdkWebNavigation_parse(
            0,
            url.as_ptr(),
            url.len() as u64,
            base.as_mut_ptr(),
        ))?;
        checked(c::R4SdkWebFormsInteraction_submit(
            0,
            interaction.as_mut_ptr(),
            doc.native(),
            submit,
            base.as_ptr(),
            out.as_mut_ptr(),
            out.len() as u64,
            body.as_mut_ptr(),
            body.len() as u64,
            submission.as_mut_ptr(),
        ))?;
        ensure!(
            bytes(c::R4SdkWebFormsSubmission_get_target(submission.as_ptr()))?
                == b"https://fixture.example/search?q=R4OS&safe=on&lang=de&submit=search"
        );
    }
    doc.set_attribute(submit, b"value", b"next")?;
    let encoded = b"data:image/png;base64,SGk=";
    let mut data = MaybeUninit::uninit();
    unsafe {
        checked(c::R4SdkWebImages_decodeDataUrl(
            0,
            encoded.as_ptr(),
            encoded.len() as u64,
            out.as_mut_ptr(),
            out.len() as u64,
            data.as_mut_ptr(),
        ))?;
        ensure!(bytes(c::R4SdkWebImagesDataUrl_get_bytes(data.as_ptr()))? == b"Hi");
    }
    let mut registry = Box::<c::R4SdkWebFontsRegistry>::new_uninit();
    let mut stats = MaybeUninit::uninit();
    let source =
        b"@font-face{font-family:'Demo';src:url('/demo.woff2') format('woff2');font-display:swap;}";
    unsafe {
        checked(c::R4SdkWebFontsRegistry_create(registry.as_mut_ptr()))?;
        checked(c::R4SdkWebFontsRegistry_beginDocument(
            0,
            registry.as_mut_ptr(),
            9,
        ))?;
        checked(c::R4SdkWebFontsRegistry_appendStylesheet(
            0,
            registry.as_mut_ptr(),
            source.as_ptr(),
            source.len() as u64,
            url.as_ptr(),
            url.len() as u64,
            stats.as_mut_ptr(),
        ))?;
        ensure!(c::R4SdkWebFontsRegistry_get_face_count(registry.as_ptr()).bits == 1);
        ensure!(bytes(c::R4SdkWebFontsRegistry_family(0, registry.as_ptr(), 0))? == b"Demo");
    }
    let mut digest = MaybeUninit::uninit();
    let mut hex = [0u8; 64];
    let mut path = MaybeUninit::uninit();
    unsafe {
        checked(c::R4SdkWebFontCache_contentId(
            0,
            b"abc".as_ptr(),
            3,
            digest.as_mut_ptr(),
        ))?;
        checked(c::R4SdkWebFontCache_writeDigestHex(
            0,
            digest.as_ptr(),
            hex.as_mut_ptr().cast(),
        ))?;
        ensure!(&hex == b"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
        checked(c::R4SdkWebFontCache_objectPath(
            0,
            digest.as_ptr(),
            path.as_mut_ptr(),
        ))?;
        ensure!(
            bytes(c::R4SdkWebFontCacheFixed_239__bytes(0, path.as_ptr()))?
                .windows(8)
                .any(|w| w == b"ba7816bf")
        );
    }
    let mut coord = MaybeUninit::uninit();
    let mut demand = MaybeUninit::uninit();
    let mut revision = MaybeUninit::uninit();
    unsafe {
        checked(c::R4SdkWebFontActivationCoordinator_create(
            coord.as_mut_ptr(),
        ))?;
        checked(c::R4SdkWebFontActivationDemand_create(
            demand.as_mut_ptr(),
            0,
            c::R4SdkWebFontsFontDisplay_swap,
        ))?;
        checked(c::R4SdkWebFontActivationCoordinator_begin(
            0,
            coord.as_mut_ptr(),
            9,
            0,
            demand.as_ptr(),
            1,
        ))?;
        ensure!(
            c::R4SdkWebFontActivationCoordinator_complete(
                0,
                coord.as_mut_ptr(),
                8,
                0,
                c::R4SdkWebFontActivationCompletion_ready,
                1
            )
            .bits
                == 0
        );
        ensure!(
            c::R4SdkWebFontActivationCoordinator_complete(
                0,
                coord.as_mut_ptr(),
                9,
                0,
                c::R4SdkWebFontActivationCompletion_ready,
                1
            )
            .bits
                == 1
        );
        ensure!(
            c::R4SdkWebFontActivationCoordinator_takeRevision(
                0,
                coord.as_mut_ptr(),
                revision.as_mut_ptr()
            )
            .flags
                & 1
                != 0
        );
        ensure!(c::R4SdkWebFontActivationRevision_get_epoch(revision.as_ptr()).bits == 9);
        ensure!(
            c::R4SdkWebFontActivationCoordinator_takeRevision(
                0,
                coord.as_mut_ptr(),
                revision.as_mut_ptr()
            )
            .flags
                & 1
                == 0
        );
    }
    Ok(())
}
#[derive(Default)]
struct CallbackState {
    clocks: u32,
    roots: u32,
    weak: u32,
    sweeps: u32,
    scripts: u32,
}
unsafe extern "C" fn callback(
    user: *mut c_void,
    kind: u32,
    _args: *const c::R4SdkWebSlot,
    _count: u32,
    out: *mut c_void,
) -> c::R4SdkWebSlot {
    let state = unsafe { &mut *user.cast::<CallbackState>() };
    match kind {
        c::R4SdkWebCallbackKind_js_clock | c::R4SdkWebCallbackKind_monotonic_clock => {
            state.clocks += 1;
            unsafe { out.cast::<f64>().write(7890.75) };
            return c::R4SdkWebSlot {
                ptr: out,
                length: 0,
                bits: 0,
                status: 0,
                flags: 1,
            };
        }
        c::R4SdkWebCallbackKind_root_mark => state.roots += 1,
        c::R4SdkWebCallbackKind_root_mark_weak => state.weak += 1,
        c::R4SdkWebCallbackKind_root_sweep => state.sweeps += 1,
        c::R4SdkWebCallbackKind_script_report => state.scripts += 1,
        _ => {}
    }
    c::R4SdkWebSlot {
        ptr: core::ptr::null_mut(),
        length: 0,
        bits: 0,
        status: 0,
        flags: 0,
    }
}
pub fn script_callbacks_and_budgets() -> Result<()> {
    let mut arena_storage = pin!(ArenaStorage::new());
    let mut backing = vec![0; 64 * 1024 * 1024];
    let mut arena = Arena::open(arena_storage.as_mut(), &mut backing)?;
    let mut mem_storage = MaybeUninit::uninit();
    let mut memory = Memory::from_arena(&mut mem_storage, &mut arena)?;
    let mut runtime = Box::<c::R4SdkWebJsRuntime>::new_uninit();
    let mut program = Box::<c::R4SdkWebJsProgram>::new_uninit();
    let mut table = MaybeUninit::uninit();
    let mut state = CallbackState::default();
    {
        let mask = (1 << c::R4SdkWebCallbackKind_js_clock)
            | (1 << c::R4SdkWebCallbackKind_root_mark)
            | (1 << c::R4SdkWebCallbackKind_root_mark_weak)
            | (1 << c::R4SdkWebCallbackKind_root_sweep);
        let callbacks = unsafe { Callbacks::open(&mut table, &mut state, mask, callback) }?;
        let mut script = Script::open(&mut runtime, &mut program, &mut memory, Some(&callbacks))?;
        ensure!(script.number(b"6*7;")? == 42.0);
        ensure!(script.number(b"Date.now();")? == 7890.0);
        ensure!(script.boolean(b"const f=(x)=>x+1;try{throw 3;}catch(e){f(e)===4;}")?);
        script.collect()?;
        script.budget(200)?;
        ensure!(script.number(b"while(true){}") == Err(Error::Native("StepLimit")));
        ensure!(script.number(b"function {").is_err());
        script.budget(2000000)?;
        ensure!(script.number(b"1+2;")? == 3.0);
    }
    ensure!(state.clocks > 0 && state.roots > 0 && state.weak > 0 && state.sweeps > 0);
    Ok(())
}
pub fn canvas_and_background() -> Result<()> {
    let mut arena_storage = pin!(ArenaStorage::new());
    let mut backing = vec![0; 65536];
    let mut arena = Arena::open(arena_storage.as_mut(), &mut backing)?;
    let mut mem_storage = MaybeUninit::uninit();
    let mut memory = Memory::from_arena(&mut mem_storage, &mut arena)?;
    let mut canvas_storage = Box::<c::R4SdkWebCanvasManager>::new_uninit();
    {
        let mut canvas = Canvas::open(&mut canvas_storage, &mut memory)?;
        canvas.ensure(1, 4, 3)?;
        canvas.fill(1, 1., 0., 2., 2., 0xff112233)?;
        ensure!(
            canvas.pixels(1)?
                == [
                    0xffffffff, 0xff112233, 0xff112233, 0xffffffff, 0xffffffff, 0xff112233,
                    0xff112233, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
                ]
        );
        ensure!(canvas.ensure(2, 513, 1).is_err());
    }
    let mut area = MaybeUninit::uninit();
    let mut intrinsic = MaybeUninit::uninit();
    let mut input = MaybeUninit::uninit();
    let mut plan = MaybeUninit::uninit();
    let mut tile = MaybeUninit::uninit();
    let mut raster = MaybeUninit::uninit();
    let source = [0xff123456u32];
    let mut target = [0u32; 8];
    unsafe {
        checked(c::R4SdkWebBackgroundSize_from_fields(
            area.as_mut_ptr(),
            4,
            2,
        ))?;
        checked(c::R4SdkWebBackgroundSize_from_fields(
            intrinsic.as_mut_ptr(),
            1,
            1,
        ))?;
        checked(c::R4SdkWebBackgroundPlanInput_create(
            input.as_mut_ptr(),
            area.as_ptr(),
            intrinsic.as_ptr(),
        ))?;
        checked(c::R4SdkWebBackground_buildPlan(
            0,
            input.as_ptr(),
            plan.as_mut_ptr(),
        ))?;
        checked(c::R4SdkWebBackgroundArgbTile_create(
            tile.as_mut_ptr(),
            source.as_ptr(),
            1,
            1,
            1,
            1,
        ))?;
        checked(c::R4SdkWebBackgroundArgbRaster_create(
            raster.as_mut_ptr(),
            target.as_mut_ptr(),
            8,
            4,
            2,
            4,
        ))?;
        ensure!(
            checked(c::R4SdkWebBackground_composite(
                0,
                plan.as_ptr(),
                tile.as_ptr(),
                raster.as_ptr()
            ))?
            .bits
                == 8
        );
        ensure!(target == [0xff123456; 8]);
    }
    Ok(())
}

pub fn runtime_document_lifecycle() -> Result<()> {
    let mut arena_storage = pin!(ArenaStorage::new());
    let mut backing = vec![0; 64 * 1024 * 1024];
    let mut arena = Arena::open(arena_storage.as_mut(), &mut backing)?;
    let mut memory_storage = MaybeUninit::uninit();
    let mut memory = Memory::from_arena(&mut memory_storage, &mut arena)?;
    let mut document_storage = Box::<c::R4SdkWebHtmlDocument>::new_uninit();
    let document = Document::parse(
        &mut document_storage,
        include_bytes!("../Fixture/Browser/Script06228.html"),
        b"text/html",
        true,
    )?;
    let mut storage = Box::<c::R4SdkWebNative_web_security_BrowserStorage>::new_uninit();
    let mut web = Box::<c::R4SdkWebRuntimeWebRuntime>::new_uninit();
    let mut pa = MaybeUninit::uninit();
    let mut table = MaybeUninit::uninit();
    let mut state = CallbackState::default();
    struct Cleanup(*mut c::R4SdkWebRuntimeWebRuntime);
    impl Drop for Cleanup {
        fn drop(&mut self) {
            unsafe {
                let _ = c::R4SdkWebRuntimeWebRuntime_deinit(0, self.0);
            }
        }
    }
    {
        let mask = (1 << c::R4SdkWebCallbackKind_script_report)
            | (1 << c::R4SdkWebCallbackKind_monotonic_clock);
        let callbacks = unsafe { Callbacks::open(&mut table, &mut state, mask, callback) }?;
        let mut observer = MaybeUninit::uninit();
        let mut clock = MaybeUninit::uninit();
        let now = 0.;
        let url = b"https://fixture.example/script";
        unsafe {
            checked(c::R4SdkWeb_memoryPrograms(
                0,
                memory.native(),
                pa.as_mut_ptr(),
            ))?;
            checked(c::R4SdkWebRuntimeWebRuntime_initialize(
                0,
                web.as_mut_ptr(),
                pa.as_ptr(),
            ))?;
        }
        let _cleanup = Cleanup(web.as_mut_ptr());
        unsafe {
            checked(c::R4SdkWebNative_web_security_BrowserStorage_reset(
                0,
                storage.as_mut_ptr(),
            ))?;
            checked(c::R4SdkWeb_scriptObserver(
                0,
                callbacks.native(),
                observer.as_mut_ptr(),
            ))?;
            checked(c::R4SdkWeb_monotonicClock(
                0,
                callbacks.native(),
                clock.as_mut_ptr(),
            ))?;
            checked(c::R4SdkWebRuntimeWebRuntime_setScriptObserver(
                0,
                web.as_mut_ptr(),
                observer.as_ptr(),
            ))?;
            checked(c::R4SdkWebRuntimeWebRuntime_setMonotonicClock(
                0,
                web.as_mut_ptr(),
                clock.as_ptr(),
            ))?;
            checked(c::R4SdkWebRuntimeWebRuntime_beginDocument(
                0,
                web.as_mut_ptr(),
                document.native(),
                storage.as_mut_ptr(),
                url.as_ptr(),
                url.len() as u64,
                b"".as_ptr(),
                0,
                44,
                &now,
            ))?;
            ensure!(c::R4SdkWebRuntimeWebRuntime_javascriptRealmActive(0, web.as_ptr()).bits == 0);
            ensure!(
                checked(c::R4SdkWebRuntimeWebRuntime_executeDocumentScripts(
                    0,
                    web.as_mut_ptr()
                ))?
                .bits
                    == 1
            );
            ensure!(c::R4SdkWebRuntimeWebRuntime_javascriptRealmActive(0, web.as_ptr()).bits == 1);
        }
        let node = document.find(b"result")?.ok_or(Error::Unavailable)?;
        let mut out = [0; 64];
        ensure!(document.text(node, &mut out)? == b"offline-script-ok");
        ensure!(document.attribute(node, b"data-ran")? == Some(&b"yes"[..]));
        unsafe {
            let mut clock_value = MaybeUninit::uninit();
            let mut clock_number = 0.;
            let source = b"performance.now();";
            checked(c::R4SdkWebRuntimeWebRuntime_executeSource(
                0,
                web.as_mut_ptr(),
                source.as_ptr(),
                source.len() as u64,
                clock_value.as_mut_ptr(),
            ))?;
            let realm = checked(c::R4SdkWebRuntimeWebRuntime_get_runtime(web.as_ptr()))?
                .ptr
                .cast();
            checked(c::R4SdkWebJsRuntime_valueNumber(
                0,
                realm,
                clock_value.as_ptr(),
                &mut clock_number,
            ))?;
            ensure!(clock_number == 7890.75);
            checked(c::R4SdkWebRuntimeWebRuntime_abortDocument(
                0,
                web.as_mut_ptr(),
            ))?;
            ensure!(c::R4SdkWebRuntimeWebRuntime_javascriptRealmActive(0, web.as_ptr()).bits == 0);
            ensure!(c::R4SdkWebRuntimeWebRuntime_javascriptRealmBytes(0, web.as_ptr()).bits == 0);
        }
    }
    ensure!(state.scripts == 2 && state.clocks > 0);
    Ok(())
}
