#![cfg(test)]
use core::{mem::MaybeUninit, pin::pin};

unsafe extern "C" fn fixture_keep_open(_: *const abi::generation2::R4XStartContext2) -> u32 {
    0
}

#[test]
fn typed_image_clipboard_native_layout_and_generated_calls_without_provider() {
    unsafe extern "C" {
        fn sdk_gui_clipboard_formats_no_provider() -> i32;
    }
    unsafe {
        assert_eq!(sdk_gui_clipboard_formats_no_provider(), 0);
        let mut clipboard = MaybeUninit::<c::R4SdkGuiType0>::uninit();
        assert_eq!(c::R4SdkGuiType0_create(clipboard.as_mut_ptr()).status, 0);
        let image = [
            1u8, 0, 0, 0, 1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0x33, 0x22, 0x11, 0,
        ];
        let copied = c::R4SdkGuiType0_copyFormat(
            0,
            clipboard.as_mut_ptr(),
            abi::clipboard_offer_format_xrgb32,
            image.as_ptr(),
            image.len() as u64,
        );
        assert_eq!(copied.status, 0);
        assert_eq!(copied.bits as i32, abi::clipboard_offer_error_closed);
        let mut scratch = [0xa5; 20];
        let read = c::R4SdkGuiType0_readFormat(
            0,
            clipboard.as_mut_ptr(),
            abi::clipboard_offer_format_xrgb32,
            scratch.as_mut_ptr(),
            scratch.len() as u64,
        );
        assert_eq!(read.status, 0);
        assert_eq!(read.bits as i32, abi::clipboard_offer_error_closed);
        assert_eq!(scratch, [0xa5; 20]);
        let closed = c::R4SdkGuiType0_close(0, clipboard.as_mut_ptr());
        assert_eq!(closed.status, 0);
        assert_eq!(closed.bits as i32, 0);
    }
}
use r4os_sdk::{
    App, ImportSpec, StartupInfo, abi,
    gui::{
        self, InputQueue, Rect, Role, Session, SessionStorage, TextArea, TextField, TextFieldMode,
        raw as c,
    },
    resources::Timeout,
};
unsafe extern "C" {
    fn sdk_gui_modern_hash() -> u64;
    fn sdk_gui_modern_expected() -> u64;
    fn sdk_gui_modern_c_case() -> u64;
    fn sdk_gui_c_case() -> i32;
    fn sdk_gui_control_clipboard_case() -> i32;
    fn sdk_gui_native_tables(
        sys: *mut abi::generation2::R4XStartR4Sys2,
        desk: *mut abi::generation2::R4XStartR4Desk2,
        draw: *mut abi::generation2::R4XStartR4Draw2,
    );
    fn sdk_gui_host_tables(
        sys: *mut abi::generation2::R4XStartR4Sys2,
        desk: *mut abi::generation2::R4XStartR4Desk2,
        draw: *mut abi::generation2::R4XStartR4Draw2,
    );
    fn sdk_gui_oracle_pixels(out: *mut u32, count: usize) -> i32;
    fn sdk_gui_oracle_fail_append(at: u32);
    fn sdk_gui_oracle_cancelled() -> u32;
    fn sdk_gui_host_mode(value: u32);
    fn sdk_gui_host_count(kind: u32) -> u32;
}
#[test]
fn modern_controls_use_the_same_native_frames_from_zig_c_and_rust() {
    let expected = unsafe { sdk_gui_modern_expected() };
    assert_ne!(expected, 0);
    assert_eq!(unsafe { sdk_gui_modern_c_case() }, expected);
    with_app(false, |app| {
        let mut storage = pin!(SessionStorage::new());
        let mut timers = [MaybeUninit::uninit(); 1];
        let mut window = Session::open(storage.as_mut(), app, Role::Window, &mut timers).unwrap();
        let style = gui::Style::light().unwrap();
        let mut commands = [abi::GuiFrameCommand::default(); 16];
        let mut resources = [0; 2048];
        let mut paint = window.begin(&mut commands, &mut resources).unwrap();
        paint.set_style(&style).unwrap();
        let mut scratch = [0; 64];
        paint
            .action_button(
                Rect {
                    x: 10,
                    y: 10,
                    width: 120,
                    height: 32,
                },
                b"Modern",
                gui::ButtonState::Normal,
                true,
                true,
                &mut scratch,
            )
            .unwrap();
        paint
            .progress_bar(
                Rect {
                    x: 10,
                    y: 60,
                    width: 120,
                    height: 12,
                },
                25,
                100,
                0,
                false,
            )
            .unwrap();
        paint.present().unwrap();
        assert_eq!(unsafe { sdk_gui_modern_hash() }, expected);
        // Exercise the generated raw Rust boundary of the shared replacement
        // owner too; the C peer also covers Window's shared entry point.
        let region = abi::DisplayDamageRect {
            x: 10,
            y: 10,
            w: 120,
            h: 32,
        };
        let mut opened = MaybeUninit::<c::R4SdkGuiPaintOpen>::uninit();
        let mut regional = MaybeUninit::<c::R4SdkGuiPaintContext>::uninit();
        unsafe {
            assert_eq!(
                c::R4SdkAppGui_beginPaintReplaceForSize(
                    0,
                    window.native_draw(),
                    320,
                    200,
                    &region,
                    1,
                    opened.as_mut_ptr()
                )
                .status,
                0
            );
            assert_eq!(
                c::R4SdkGuiPaintOpen_get_paint(opened.as_ptr(), regional.as_mut_ptr()).status,
                0
            );
            assert_eq!(
                c::R4SdkGuiPaintContext_discard(0, regional.as_mut_ptr()).status,
                0
            );
        }
    });
}
fn with_app(host: bool, body: impl FnOnce(&App<'_>)) {
    let (mut sys, mut desk, mut draw) = (
        abi::generation2::R4XStartR4Sys2::default(),
        abi::generation2::R4XStartR4Desk2::default(),
        abi::generation2::R4XStartR4Draw2::default(),
    );
    unsafe {
        if host {
            sdk_gui_host_tables(&mut sys, &mut desk, &mut draw)
        } else {
            sdk_gui_native_tables(&mut sys, &mut desk, &mut draw)
        }
    };
    let records = [
        (
            abi::R4LGroup::r4sys.0,
            c"R4SYS",
            (&sys as *const _) as u64,
            sys.magic,
            sys.abi_version,
            sys.size,
        ),
        (
            abi::R4LGroup::r4desk.0,
            c"R4DESK",
            (&desk as *const _) as u64,
            desk.magic,
            desk.abi_version,
            desk.size,
        ),
        (
            abi::R4LGroup::r4draw.0,
            c"R4DRAW",
            (&draw as *const _) as u64,
            draw.magic,
            draw.abi_version,
            draw.size,
        ),
    ];
    let imports = records.map(|(id, name, table, _, _, _)| abi::R4XStartImport {
        group_id: id,
        min_version: 2,
        resolved_version: 2,
        flags: abi::r4xstart_import_flag_group_interface,
        module_name: name.as_ptr() as u64,
        symbol_name: c"Query2".as_ptr() as u64,
        table,
    });
    let specs = records.map(|(id, name, _, _magic, _version, _size)| ImportSpec {
        module_name: name.as_ptr().cast(),
        symbol_name: c"Query2".as_ptr().cast(),
        minimum: 2,
        optional: 0,
        group_id: id,

        reserved: 0,
    });
    let context = abi::generation2::R4XStartContext2 {
        app_class: abi::R4XStartAppClass::gui.0,
        instance_id: 42,
        flags: abi::r4xstart_flag_imports_valid | abi::r4xstart_flag_close_supported,
        should_close: fixture_keep_open as *const () as u64,
        imports: imports.as_ptr() as u64,
        import_count: 3,
        ..Default::default()
    };
    let expected = StartupInfo {
        profile: 1,
        app_class: abi::R4XStartAppClass::gui.0,
        required_groups: 14,
        imports: &specs,
    };
    let app = unsafe { App::from_raw(&context, &expected, c"GuiParity") }.unwrap();
    body(&app);
}
#[test]
fn original_gui_pixels_frames_unicode_input_and_exact_host_session() {
    assert_eq!(unsafe { sdk_gui_c_case() }, 0);
    assert_eq!(unsafe { sdk_gui_control_clipboard_case() }, 0);
    with_app(false, |app| {
        let mut storage = pin!(SessionStorage::new());
        let mut timers = [MaybeUninit::uninit(); 1];
        let mut window = Session::open(storage.as_mut(), app, Role::Window, &mut timers).unwrap();
        // Current font capability absence is an error, never a row-based or
        // invented-revision substitute; caller bitmap storage is untouched.
        let draw = unsafe { window.native_draw() };
        let mut glyph = abi::GuiGlyphBitmap {
            width: 77,
            ..Default::default()
        };
        assert_eq!(
            unsafe { c::R4SdkGuiDrawContext_fontGlyphBitmap(0, draw, 0, 65, &mut glyph) }.status,
            abi::err_no_fn
        );
        assert_eq!(glyph.width, 77);
        assert_eq!(
            unsafe { c::R4SdkGuiDrawContext_fontRevision(0, draw) }.status,
            abi::err_no_fn
        );
        assert_eq!(window.window_info().unwrap().unwrap().client_w, 320);
        window.set_title(c"Test").unwrap();
        window.set_minimum_size(100, 80).unwrap();
        // Typed native transport, including absent/present optional pointers
        // and all upper 32 bits. Runtime ownership is a separate guest proof.
        let identity = window.pointer_identity().unwrap();
        assert_eq!(identity.owner.generation, 0x100000009);
        assert_eq!(identity.epoch, 0x200000008);
        let mut appearance = abi::GuiWindowAppearance {
            reserved: 77,
            ..Default::default()
        };
        let no_appearance = unsafe {
            c::R4SdkGuiDesktopContext_guiWindowAppearance(
                0,
                window.native_desktop(),
                &identity,
                &mut appearance,
            )
        };
        assert_eq!(no_appearance.status, 0);
        assert_eq!(no_appearance.bits as i32, abi::err_no_fn);
        assert_eq!(appearance.reserved, 77);
        assert_eq!(appearance.flags, 0);
        assert_eq!(appearance.window.owner.instance_id, 0);
        let token = window
            .pointer_capture(&identity, r4os_sdk::abi::gui_pointer_mode_relative)
            .unwrap();
        assert_eq!(token.id, 0x300000007);
        assert_eq!(
            window.pointer_info(Some(&token)).unwrap().state,
            r4os_sdk::abi::gui_pointer_state_active
        );
        assert!(matches!(
            window.pointer_release(&token),
            Err(r4os_sdk::storage::Error::Raw(-2))
        ));

        assert_eq!(window.next(Timeout::Poll).unwrap().unwrap().kind, 2);
        let key = window.next(Timeout::Poll).unwrap().unwrap();
        assert_eq!(key.kind(), Some(gui::EventKind::Key));
        assert_eq!((key.kind, key.codepoint, key.modifiers), (3, 0x1f642, 2));
        for kind in [4, 5, 6, 1] {
            assert_eq!(window.next(Timeout::Poll).unwrap().unwrap().kind, kind)
        }
        for (kind, tick) in [
            (gui::EventKind::FocusGained, 0x100000010),
            (gui::EventKind::FocusLost, 0x100000011),
        ] {
            let event = window.next(Timeout::Poll).unwrap().unwrap();
            assert_eq!(event.kind(), Some(kind));
            assert_eq!((event.window_id, event.tick), (4, tick));
        }
        let font = window.next(Timeout::Poll).unwrap().unwrap();
        assert_eq!(font.kind(), Some(gui::EventKind::FontChanged));
        assert_eq!((font.window_id, font.tick), (-1, 0));
        let reset = window.next(Timeout::Poll).unwrap().unwrap();
        assert_eq!(reset.kind(), Some(gui::EventKind::InputReset));
        assert_eq!(
            (reset.window_id, reset.id, reset.tick),
            (4, abi::gui_input_reset_reason_overflow, 0x100000014)
        );
        assert_eq!(reset.raw.kind, abi::GuiEventKind::input_reset.0);
        let unknown = window.next(Timeout::Poll).unwrap().unwrap();
        assert_eq!(unknown.kind(), Some(gui::EventKind::Unknown));
        assert_eq!(
            (
                unknown.raw.kind,
                unknown.raw.window_id,
                unknown.raw.x,
                unknown.raw.y
            ),
            (0xfeed, 4, -7, 13)
        );
        assert_eq!(
            (
                unknown.raw.key,
                unknown.raw.buttons,
                unknown.raw.modifiers,
                unknown.raw.tick
            ),
            (0x1f642, 3, 9, 0x100000012)
        );
        assert!(window.next(Timeout::Poll).unwrap().is_none());
        window.post_command(42).unwrap();
        assert!(window.post_command(43).is_err());
        assert_eq!(window.next(Timeout::Poll).unwrap().unwrap().id, 42);
        window.start_timer(0, 7, 2_000_000, false).unwrap();
        let event = window
            .next(Timeout::AfterNanos(10_000_000))
            .unwrap()
            .unwrap();
        assert_eq!((event.kind, event.id), (9, 7));
        let mut commands = [abi::GuiFrameCommand::default(); 8];
        let mut resources = [0u8; 64];
        let mut paint = window.begin(&mut commands, &mut resources).unwrap();
        paint.clear(0).unwrap();
        paint
            .rect(
                Rect {
                    x: 2,
                    y: 1,
                    width: 2,
                    height: 1,
                },
                0xcc0000,
            )
            .unwrap();
        paint
            .raster(0, 0, 2, 1, 1, &[0xaa112233, 0xff445566])
            .unwrap();
        paint
            .blend_alpha8(0, 1, 2, 2, 3, 0xffffff, &[0, 255, 77, 255, 0])
            .unwrap();
        paint
            .rect(
                Rect {
                    x: 3,
                    y: 2,
                    width: 1,
                    height: 1,
                },
                0x010203,
            )
            .unwrap();
        paint.present().unwrap();
        let mut output = [0u32; 12];
        assert_eq!(unsafe { sdk_gui_oracle_pixels(output.as_mut_ptr(), 12) }, 0);
        assert_eq!(
            output,
            [
                0x112233, 0x445566, 0, 0, 0, 0xffffff, 0xcc0000, 0xcc0000, 0xffffff, 0, 0, 0x010203
            ]
        );
        // Actual partial-flush failure must cancel the opened transaction.
        unsafe { sdk_gui_oracle_fail_append(2) };
        let mut tiny_commands = [abi::GuiFrameCommand::default(); 1];
        let mut paint = window.begin(&mut tiny_commands, &mut resources).unwrap();
        paint.clear(0).unwrap();
        assert!(
            paint
                .rect(
                    Rect {
                        x: 0,
                        y: 0,
                        width: 1,
                        height: 1
                    },
                    1
                )
                .is_err()
        );
        drop(paint);
        assert!(unsafe { sdk_gui_oracle_cancelled() } > 0);
    });
    let mut bytes = [0u8; 24];
    let mut field = TextField::new(&mut bytes).unwrap();
    assert!(field.set_exact("A\u{301}B".as_bytes()).unwrap());
    field.set_selection(0, 1).unwrap();
    assert!(field.paste("🙂".as_bytes()).unwrap());
    assert_eq!(field.value().unwrap(), "🙂B".as_bytes());
    assert!(!field.set_exact(b"\xc0\xaf").unwrap());
    assert_eq!(field.value().unwrap(), "🙂B".as_bytes());
    assert!(field.handle_codepoint(8).unwrap());
    assert_eq!(field.value().unwrap(), b"B");
    assert!(field.set_exact(b"").unwrap());
    field.set_selection(0, 0).unwrap();
    assert!(field.handle_codepoint(u32::from(b'a')).unwrap());
    assert!(field.handle_codepoint(u32::from(b'b')).unwrap());
    assert_eq!(field.value().unwrap(), b"ab");
    let mut secret_bytes = [0u8; 24];
    {
        let mut password = TextField::new_password(&mut secret_bytes).unwrap();
        assert!(password.set_exact("ä🙂".as_bytes()).unwrap());
        assert_eq!(password.value().unwrap(), "ä🙂".as_bytes());
        password.clear().unwrap();
        assert!(password.value().unwrap().is_empty());
        assert!(password.set_exact(b"private").unwrap());
        assert!(password.set_mode(TextFieldMode::Normal).unwrap());
    }
    assert!(secret_bytes.iter().all(|byte| *byte == 0));
    let mut area_bytes = [0u8; 48];
    let mut area = TextArea::new(&mut area_bytes, 5, 3).unwrap();
    area.set("ä\n🙂".as_bytes()).unwrap();
    assert!(area.delete_backward().unwrap());
    assert_eq!(area.value().unwrap(), "ä\n".as_bytes());
    assert!(area.paste("🙂".as_bytes()).unwrap());
    assert_eq!(area.value().unwrap(), "ä\n🙂".as_bytes());
    let mut input = [abi::ConsoleInputEvent::default(); 3];
    let mut queue = InputQueue::new(&mut input).unwrap();
    let text = abi::ConsoleInputEvent {
        kind: abi::console_input_event_text,
        value: 0x1f642,
        ..Default::default()
    };
    assert!(queue.append(&[text, text, text]).unwrap());
    assert!(!queue.append(&[text]).unwrap());
    assert!(queue.consume(2).unwrap());
    assert!(queue.append(&[text, text]).unwrap());
    assert_eq!(queue.peek().unwrap().len(), 1);
    assert!(queue.consume(1).unwrap());
    assert_eq!(queue.peek().unwrap().len(), 2);
    assert!(
        !queue
            .append(&[abi::ConsoleInputEvent {
                value: 0xd800,
                ..text
            }])
            .unwrap()
    );
    // Native float data crosses by pointer. Returned values do not assume the
    // unqualified bare Rust scalar FP calling convention.
    let mut point = MaybeUninit::<c::R4SdkGuiShapePoint>::uninit();
    let x = 1.25f32;
    let y = -2.5f32;
    assert_eq!(
        unsafe { c::R4SdkGuiShapePoint_create(point.as_mut_ptr(), &x, &y) }.status,
        0
    );
    let mut got = 0f32;
    assert_eq!(
        unsafe { c::R4SdkGuiShapePoint_get_y(point.as_ptr(), &mut got) }.status,
        0
    );
    assert_eq!(got, y);
    let (zero, one, width, height) = (0f32, 1f32, 16f32, 12f32);
    let mut begin = MaybeUninit::<c::R4SdkGuiShapePoint>::uninit();
    let mut end = MaybeUninit::<c::R4SdkGuiShapePoint>::uninit();
    let mut stops = MaybeUninit::<[c::R4SdkGuiShapeGradientStop; 2]>::uninit();
    let mut gradient = MaybeUninit::<c::R4SdkGuiShapeGradient>::uninit();
    let mut rounded = MaybeUninit::<c::R4SdkGuiShapeRoundedRect>::uninit();
    let mut payload = [0xa5u8; 256];
    unsafe {
        assert_eq!(
            c::R4SdkGuiShapePoint_create(begin.as_mut_ptr(), &zero, &zero).status,
            0
        );
        assert_eq!(
            c::R4SdkGuiShapePoint_create(end.as_mut_ptr(), &width, &height).status,
            0
        );
        let stop = stops.as_mut_ptr().cast::<c::R4SdkGuiShapeGradientStop>();
        assert_eq!(
            c::R4SdkGuiShapeGradientStop_create(stop, &zero, 0xff112233).status,
            0
        );
        assert_eq!(
            c::R4SdkGuiShapeGradientStop_create(stop.add(1), &one, 0xffaabbcc).status,
            0
        );
        assert_eq!(
            c::R4SdkGuiShapeGradient_create(
                gradient.as_mut_ptr(),
                begin.as_ptr(),
                end.as_ptr(),
                stop,
                2
            )
            .status,
            0
        );
        assert_eq!(
            c::R4SdkGuiShapeRoundedRect_create(rounded.as_mut_ptr(), &zero, &zero, &width, &height)
                .status,
            0
        );
        let built = c::R4SdkGuiShapes_gradientRoundedRect(
            0,
            payload.as_mut_ptr(),
            payload.len() as u64,
            rounded.as_ptr(),
            gradient.as_ptr(),
        );
        assert_eq!(built.status, 0);
        assert_eq!(built.flags & 2, 0);
        assert_eq!(built.length, 208);
        let paint = payload
            .as_ptr()
            .add(160)
            .cast::<abi::GuiGradientPaint>()
            .read_unaligned();
        assert_eq!(
            (paint.version, paint.size, paint.kind, paint.stop_count),
            (1, 32, abi::gui_gradient_kind_linear, 2)
        );
    }
    assert_eq!(
        unsafe { c::R4SdkGuiVerifyAbi(c::R4SdkGui_ABI_FINGERPRINT) },
        0
    );
    assert!(unsafe { c::R4SdkGuiVerifyAbi(c::R4SdkGui_ABI_FINGERPRINT ^ 1) } < 0);
    with_app(true, |app| {
        let mut storage = pin!(SessionStorage::new());
        let mut timers = [];
        let mut host =
            Session::open(storage.as_mut(), app, Role::DesktopHost, &mut timers).unwrap();
        assert!(host.window_info().unwrap().is_none());
        assert_eq!(unsafe { sdk_gui_host_count(3) }, 0);
        let timeout = Timeout::AfterNanos(250_000_000);
        let exchange = host.claim_host(timeout).unwrap();
        assert_eq!(exchange.desktop_epoch, 0x100000007);
        unsafe { sdk_gui_host_mode(1) };
        assert!(
            host.host_exchange(abi::tray_service_op_desktop_sync, &exchange, timeout)
                .is_err()
        );
        assert_eq!(unsafe { sdk_gui_host_count(1) }, 1);
        assert_eq!(unsafe { sdk_gui_host_count(0) }, 1);
        unsafe { sdk_gui_host_mode(0) };
        assert!(
            host.host_exchange(abi::tray_service_op_desktop_sync, &exchange, timeout)
                .is_err()
        );
        assert_eq!(unsafe { sdk_gui_host_count(0) }, 1);
        host.reset_host_connection();
        host.claim_host(timeout).unwrap();
        assert_eq!(unsafe { sdk_gui_host_count(0) }, 2);
        drop(host);
        assert_eq!(unsafe { sdk_gui_host_count(1) }, 2);
        assert_eq!(unsafe { sdk_gui_host_count(3) }, 0);
    });
    let _ = core::mem::size_of::<gui::TimerStorage>();
}
