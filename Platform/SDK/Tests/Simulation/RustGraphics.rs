#![cfg(test)]
// The native catalogue changed; keep the existing GUI/host consumers bound to
// these exact bytes as part of the same small serialized native invocation.
#[path = "RustGui.rs"]
mod gui_regression;
use core::{mem::MaybeUninit, pin::pin};
use r4os_sdk::{
    App, ImportSpec, StartupInfo, abi,
    graphics::{Graphics, GraphicsStorage, raw as c},
};
unsafe extern "C" {
    fn sdk_gfx_oracle_tables(
        sys: *mut abi::R4XStartR4Sys,
        desk: *mut abi::R4XStartR4Desk,
        draw: *mut abi::R4XStartR4Draw,
    );
}
#[test]
fn current_offscreen_graphics_reuses_original_descriptors_and_receipts() {
    let (mut sys, mut desk, mut draw) = (
        abi::R4XStartR4Sys::default(),
        abi::R4XStartR4Desk::default(),
        abi::R4XStartR4Draw::default(),
    );
    unsafe { sdk_gfx_oracle_tables(&mut sys, &mut desk, &mut draw) };
    // No R4DESK import or hosted window is needed for graphics.
    let records = [
        (
            abi::R4LGroup::r4sys,
            c"R4SYS",
            &sys as *const _ as u64,
            sys.magic,
            sys.abi_version,
            sys.size,
        ),
        (
            abi::R4LGroup::r4draw,
            c"R4DRAW",
            &draw as *const _ as u64,
            draw.magic,
            draw.abi_version,
            draw.size,
        ),
    ];
    let imports = records.map(|(group, name, table, _, _, _)| abi::R4XStartImport {
        group_id: group.0,
        module_name: name.as_ptr() as u64,
        symbol_name: c"Query".as_ptr() as u64,
        flags: abi::r4xstart_import_flag_group_interface,
        min_version: 1,
        resolved_version: 1,
        table,
    });
    let specs = records.map(|(group, name, _, magic, version, size)| ImportSpec {
        module_name: name.to_bytes(),
        symbol_name: b"Query",
        minimum: 1,
        optional: false,
        group_id: group.0,
        magic,
        version,
        size,
    });
    let start = abi::R4XStartContext {
        app_class: abi::R4XStartAppClass::console.0,
        instance_id: 42,
        flags: abi::r4xstart_flag_imports_valid,
        imports: imports.as_ptr() as u64,
        import_count: 2,
        ..Default::default()
    };
    let expected = StartupInfo {
        app_class: abi::R4XStartAppClass::console,
        required_groups: records.iter().fold(0, |m, r| m | (1 << r.0.0)),
        imports: &specs,
    };
    let app = unsafe { App::from_raw(&start, &expected, c"GfxParity") }.unwrap();
    let mut storage = pin!(GraphicsStorage::new());
    let gfx = Graphics::open(storage.as_mut(), &app).unwrap();
    assert!(gfx.snapshot().unwrap().is_none());
    let handle = abi::GfxBufferHandle {
        id: 7,
        generation: 99,
        ..Default::default()
    };
    let mapped = gfx
        .buffers()
        .map(&handle, 1, 0x100000003, 0x200000000, true)
        .unwrap();
    assert_eq!(mapped.byte_length, 0x200000000);
    assert!(gfx.buffers().map(&handle, 1, u64::MAX, 2, false).is_err());
    let fence = abi::GfxFence {
        slot: 7,
        timeline: 23,
        point: 0x100000007,
        reset_generation: 0x200000001,
        ..Default::default()
    };
    let receipt = gfx.queues().wait(&fence, 0x300000003, 1).unwrap();
    assert_eq!(receipt.fence.point, fence.point);
    assert_eq!(receipt.fence.reset_generation, fence.reset_generation);
    // Successful wait transport is not automatically a terminal/success fence.
    assert_eq!(receipt.phase, abi::gfx_queue_phase_queued);
    assert_eq!(receipt.result, abi::gfx_queue_result_pending);
    let backend = gfx.queues().backend_info(16).unwrap();
    assert_eq!(backend.memory_generation, 0x500000018);
    assert_eq!(backend.binding.device_generation, 0x100000017);
    assert_eq!(
        gfx.outputs().cursor_info().unwrap().display_generation,
        0x100000079
    );
    assert_eq!(
        gfx.outputs().cursor_status().unwrap().completed,
        0x200000079
    );
    let mut line = [0u8; 128];
    let telemetry = gfx
        .telemetry(&abi::GfxTelemetryRequest {
            adapter_id: 3,
            memory_generation: 0x200000007,
            ..Default::default()
        })
        .unwrap();
    assert_eq!(
        r4os_sdk::graphics::telemetry_line(&mut line, &telemetry, 5).unwrap(),
        "GPU temp: -12.5 C"
    );
    assert_eq!(
        r4os_sdk::graphics::telemetry_line(&mut line, &telemetry, 99).unwrap(),
        "unknown metric"
    );
    assert_eq!(
        r4os_sdk::graphics::telemetry_line(&mut [0u8; 1], &telemetry, 5).unwrap(),
        "unknown"
    );
    let raw = unsafe { gfx.native_draw() };
    let queue = abi::GfxQueueHandle {
        timeline: 0x100000003,
        ..Default::default()
    };
    let submission = abi::GfxSubmission {
        operation: abi::gfx_queue_operation_native,
        ..Default::default()
    };
    let mut native = abi::GfxNativeSubmission {
        commands: 0x200000009,
        revision: 1,
        ..Default::default()
    };
    let mut result = abi::GfxFenceStatus::default();
    let good = unsafe {
        c::R4SdkGuiDrawContext_gfxQueueSubmitNative(
            0,
            raw,
            &queue,
            &submission,
            &native,
            &mut result,
        )
    };
    assert_eq!(good.bits as i32, 1);
    assert_eq!(result.fence.point, 0x300000007);
    native.revision = 2;
    result.deadline_ns = 79;
    let bad = unsafe {
        c::R4SdkGuiDrawContext_gfxQueueSubmitNative(
            0,
            raw,
            &queue,
            &submission,
            &native,
            &mut result,
        )
    };
    assert_eq!(bad.bits as i32, -3);
    assert_eq!(result.deadline_ns, 79);
    let mut output = MaybeUninit::uninit();
    assert_eq!(
        unsafe {
            c::R4SdkGfxOpenNative(c::R4SdkGui_ABI_FINGERPRINT ^ 1, output.as_mut_ptr(), &start)
        },
        abi::io_error_invalid
    );
    let sys2 = abi::generation2::R4XStartR4Sys2::default();
    let draw2 = abi::generation2::R4XStartR4Draw2 {
        gfx_buffer_map: draw.gfx_buffer_map as u64,
        gfx_buffer_map_persistent: draw.gfx_buffer_map_persistent as u64,
        gfx_fence_wait: draw.gfx_fence_wait as u64,
        gfx_queue_backend_info: draw.gfx_queue_backend_info as u64,
        display_cursor_info: draw.display_cursor_info as u64,
        display_cursor_submit: draw.display_cursor_submit as u64,
        display_cursor_status: draw.display_cursor_status as u64,
        ..Default::default()
    };
    let imports2 = [
        abi::R4XStartImport {
            group_id: 1,
            min_version: 2,
            resolved_version: 2,
            table: core::ptr::from_ref(&sys2) as u64,
            ..Default::default()
        },
        abi::R4XStartImport {
            group_id: 3,
            min_version: 2,
            resolved_version: 2,
            table: core::ptr::from_ref(&draw2) as u64,
            ..Default::default()
        },
    ];
    let start2 = abi::generation2::R4XStartContext2 {
        app_class: abi::R4XStartAppClass::console.0,
        instance_id: 42,
        flags: abi::r4xstart_flag_imports_valid,
        imports: imports2.as_ptr() as u64,
        import_count: imports2.len() as u32,
        ..Default::default()
    };
    let context2 = unsafe { r4os_sdk::platform2::Context::new(&start2) }.unwrap();
    let app2 = r4os_sdk::App2::from_context(&context2, c"GfxParity2").unwrap();
    let mut storage2 = pin!(GraphicsStorage::new());
    let gfx2 = Graphics::open2(storage2.as_mut(), &app2).unwrap();
    assert_eq!(
        gfx2.buffers()
            .map(&handle, 1, 0x100000003, 0x200000000, true)
            .unwrap()
            .byte_length,
        mapped.byte_length
    );
    let receipt2 = gfx2.queues().wait(&fence, 0x300000003, 1).unwrap();
    assert_eq!(receipt2.fence.point, receipt.fence.point);
    assert_eq!(receipt2.phase, abi::gfx_queue_phase_queued);
    assert_eq!(receipt2.result, abi::gfx_queue_result_pending);
    assert_eq!(
        gfx2.queues().backend_info(16).unwrap().memory_generation,
        backend.memory_generation
    );
    assert_eq!(
        gfx2.outputs().cursor_info().unwrap().display_generation,
        0x100000079
    );
    assert_eq!(
        unsafe {
            c::R4SdkGfxOpenNative2(
                c::R4SdkGui_ABI_FINGERPRINT ^ 1,
                output.as_mut_ptr(),
                &start2,
            )
        },
        abi::io_error_invalid
    );
}
