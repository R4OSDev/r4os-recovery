#![no_std]
use core::{mem::MaybeUninit, pin::pin};
use r4os_sdk::{
    App, abi,
    gui::{Rect, Role, Session, SessionStorage, raw as c},
    path::FilePath,
    resources::{Resources, Timeout},
    storage::System,
};
unsafe extern "C" {
    fn sdk56_gui_c(canvas: *mut c::R4SdkGuiCanvas) -> i32;
}
fn draw(window: &mut Session<'_, '_>) -> Result<(), i32> {
    let mut commands = [abi::GuiFrameCommand::default(); 64];
    let mut resources = [0u8; 4096];
    let mut paint = window
        .begin(&mut commands, &mut resources)
        .map_err(|_| 20)?;
    paint.clear(0x24384c).map_err(|_| 21)?;
    paint
        .text(16, 20, c"Rust/C GUI parity", 0xffffff, 0x24384c)
        .map_err(|_| 22)?;
    paint
        .rect(
            Rect {
                x: 16,
                y: 48,
                width: 80,
                height: 12,
            },
            0x33aa66,
        )
        .map_err(|_| 23)?;
    let result = unsafe { sdk56_gui_c(paint.native_canvas()) };
    if result != 0 {
        return Err(30 + result);
    }
    paint.present().map_err(|_| 24)?;
    Ok(())
}
fn wait_mode(window: &mut Session<'_, '_>, fullscreen: bool) -> Result<(), i32> {
    window.request_fullscreen(fullscreen).map_err(|_| 40)?;
    for _ in 0..200 {
        let state = window.poll_mode().map_err(|_| 41)?;
        if state.phase == 2 && state.mode == u32::from(fullscreen) {
            return Ok(());
        }
        window
            .next(Timeout::AfterNanos(20_000_000))
            .map_err(|_| 42)?;
    }
    Err(43)
}
fn exercise(app: &App<'_>) -> Result<(), i32> {
    let mut storage = pin!(SessionStorage::new());
    let mut timers = [MaybeUninit::uninit(); 1];
    let mut window =
        Session::open(storage.as_mut(), app, Role::Window, &mut timers).map_err(|_| 10)?;
    window.set_title(c"SDK56 Rust/C GUI").map_err(|_| 11)?;
    window.set_minimum_size(240, 160).map_err(|_| 12)?;
    let before = window.window_info().map_err(|_| 13)?.ok_or(14)?;
    draw(&mut window)?;
    // Inject through the real native input queue, preserving the full scalar.
    let raw = abi::GuiEvent {
        kind: abi::GuiEventKind::key_down.0,
        window_id: before.window_id,
        key: 0x1f642,
        modifiers: 2,
        ..Default::default()
    };
    let pushed = unsafe {
        c::R4SdkGuiDesktopContext_guiPushEvent(
            0,
            window.native_desktop(),
            app.instance_id() as u32,
            &raw,
        )
    };
    if pushed.status != 0 || (pushed.bits as i32) < 0 {
        return Err(15);
    }
    let mut received = false;
    for _ in 0..50 {
        if let Some(e) = window
            .next(Timeout::AfterNanos(20_000_000))
            .map_err(|_| 16)?
            && e.kind == 3
            && e.codepoint == 0x1f642
            && e.modifiers == 2
        {
            received = true;
            break;
        }
    }
    if !received {
        return Err(17);
    }
    // Broker admission/publication may complete just after app entry.
    let mut bound = false;
    for _ in 0..100 {
        if window.poll_mode().is_ok() {
            bound = true;
            break;
        }
        app.sleep(1)
    }
    if !bound {
        return Err(44);
    }
    wait_mode(&mut window, true)?;
    let maximized = window.window_info().map_err(|_| 45)?.ok_or(46)?;
    if maximized.client_w <= before.client_w && maximized.client_h <= before.client_h {
        return Err(47);
    }
    draw(&mut window)?;
    wait_mode(&mut window, false)?;
    let restored = window.window_info().map_err(|_| 48)?.ok_or(49)?;
    if (restored.client_w, restored.client_h) != (before.client_w, before.client_h) {
        return Err(50);
    }
    window.post_command(56).map_err(|_| 51)?;
    let mut command = false;
    for _ in 0..50 {
        if let Some(e) = window
            .next(Timeout::AfterNanos(20_000_000))
            .map_err(|_| 52)?
            && e.kind == 7
            && e.id == 56
        {
            command = true;
            break;
        }
    }
    if !command {
        return Err(53);
    }
    let owner = Resources::new(app).map_err(|_| 54)?;
    let mut process = owner
        .open_process(app.instance_id() as u32)
        .map_err(|_| 55)?;
    process.request_close().map_err(|_| 56)?;
    for _ in 0..50 {
        if let Some(e) = window
            .next(Timeout::AfterNanos(20_000_000))
            .map_err(|_| 57)?
            && e.kind == 1
        {
            return Ok(());
        }
    }
    Err(58)
}
fn main(app: &mut App<'_>) -> i32 {
    let result = exercise(app);
    let code = result.err().unwrap_or(0);
    let Ok(system) = System::new(app) else {
        return 90;
    };
    let Ok(path) = FilePath::parse(b"C:\\TEMP\\GUI56.TXT") else {
        return 91;
    };
    let bytes = if code == 0 {
        &b"PASS GUI56 Rust/C frames, UTF32 input, fullscreen/restore and normal close\r\n"[..]
    } else {
        &b"FAIL GUI56\r\n"[..]
    };
    if system.files().write(&path, bytes).is_err() {
        return 92;
    }
    if code != 0 {
        let digits = [
            b'0' + (code / 10) as u8,
            b'0' + (code % 10) as u8,
            b'\r',
            b'\n',
        ];
        let _ = system.files().append(&path, &digits);
    }
    code
}
r4os_sdk::app!(main);
