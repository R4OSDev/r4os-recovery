#![no_std]
use core::fmt::Write;
use core::pin::pin;
use r4os_sdk::{
    App, abi,
    graphics::{Graphics, GraphicsStorage, raw as c},
    resources::{Resources, Timeout},
};
unsafe extern "C" {
    fn sdk57_fill(draw: *mut c::R4SdkGuiDrawContext, reference: *const abi::GfxBufferHandle)
    -> i32;
}
const PIXELS: [u32; 12] = [
    0x112233, 0x445566, 0, 0, 0, 0xffffff, 0xcc0000, 0xcc0000, 0xffffff, 0, 0, 0x010203,
];
struct Output<'a, 'b>(&'a App<'b>);
impl core::fmt::Write for Output<'_, '_> {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        if self.0.write(s) < 0 {
            Err(core::fmt::Error)
        } else {
            Ok(())
        }
    }
}
fn exercise(app: &App<'_>) -> Result<(), i32> {
    let mut storage = pin!(GraphicsStorage::new());
    let gfx = Graphics::open(storage.as_mut(), app).map_err(|_| 10)?;
    let before = gfx.buffers().stats().map_err(|_| 11)?;
    let mut descriptor = abi::GfxBufferDescriptor {
        byte_length: 4096,
        width: 4,
        height: 3,
        format: abi::gfx_buffer_format_xrgb8888,
        plane_count: 1,
        usage: abi::gfx_buffer_usage_cpu_read
            | abi::gfx_buffer_usage_cpu_write
            | abi::gfx_buffer_usage_transfer_source
            | abi::gfx_buffer_usage_transfer_target,
        ..Default::default()
    };
    descriptor.plane_pitches[0] = 16;
    let buffers = gfx.buffers();
    let source = buffers.create(&descriptor).map_err(|_| 12)?;
    let target = buffers.create(&descriptor).map_err(|_| 13)?;
    let actual = buffers.describe(&source.reference).map_err(|_| 14)?;
    if actual.format != descriptor.format
        || actual.width != 4
        || actual.height != 3
        || actual.plane_pitches[0] != 16
    {
        return Err(15);
    }
    let imported = buffers.import(&source.reference).map_err(|_| 16)?;
    if imported.buffer.id != source.buffer.id
        || imported.buffer.generation != source.buffer.generation
    {
        return Err(17);
    }
    let filled = unsafe { sdk57_fill(gfx.native_draw(), &imported.reference) };
    if filled != 0 {
        return Err(20 + filled);
    }
    let queues = gfx.queues();
    let queue = queues
        .open(&abi::GfxQueueConfig::default())
        .map_err(|_| 30)?;
    let request = abi::GfxSubmission {
        source: source.reference,
        target: target.reference,
        byte_length: 48,
        deadline_ns: r4os_sdk::time::Clock::new(app)
            .instant()
            .map_err(|_| 29)?
            .nanoseconds
            .checked_add(5_000_000_000)
            .ok_or(29)?,
        ..Default::default()
    };
    let submitted = unsafe { queues.submit(&queue, &request) }.map_err(|e| {
        let _ = writeln!(&mut Output(app), "GFX57 submit: {:?}", e);
        31
    })?;
    let ticks = Resources::new(app)
        .map_err(|_| 32)?
        .timeout_ticks(Timeout::AfterNanos(5_000_000_000))
        .map_err(|_| 33)?;
    let receipt = queues
        .wait(
            &submitted.fence,
            ticks,
            abi::gfx_queue_wait_resources_released,
        )
        .map_err(|_| 34)?;
    if receipt.phase != abi::gfx_queue_phase_terminal
        || receipt.result != abi::gfx_queue_result_complete
        || receipt.flags & abi::gfx_queue_flag_resources_held != 0
    {
        return Err(35);
    }
    let mapped = buffers
        .map(&target.reference, abi::gfx_buffer_map_read, 0, 4096, false)
        .map_err(|_| 36)?;
    if mapped.cpu_address == 0 || mapped.cpu_address % 4 != 0 || mapped.byte_length < 48 {
        return Err(37);
    }
    let pixels = unsafe { core::slice::from_raw_parts(mapped.cpu_address as *const u32, 12) };
    if pixels != PIXELS {
        return Err(38);
    }
    buffers.unmap(&mapped.lease).map_err(|_| 39)?;
    queues.release(&submitted.fence).map_err(|_| 40)?;
    queues.close(&queue).map_err(|_| 41)?;
    buffers.release(&imported.reference).map_err(|_| 42)?;
    buffers.release(&source.reference).map_err(|_| 43)?;
    buffers.release(&target.reference).map_err(|_| 44)?;
    let after = buffers.stats().map_err(|_| 45)?;
    // A live Desktop may change totals; only our exact handles must be stale.
    if buffers.describe(&source.reference).is_ok() || buffers.describe(&target.reference).is_ok() {
        return Err(46);
    }
    let _ = (before, after);
    let status = gfx.snapshot().map_err(|_| 47)?.ok_or(48)?;
    let mut line = [0u8; 128];
    app.write(status.line(&mut line, 0).map_err(|_| 49)?);
    app.write("\n");
    let _caps = gfx.present_capabilities().map_err(|_| 50)?;
    Ok(())
}
fn main(app: &mut App<'_>) -> i32 {
    match exercise(app) {
        Ok(()) => {
            app.write("PASS GFX57 Rust/C offscreen pixels, buffer imports/maps, CPU queue and exact cleanup\n");
            0
        }
        Err(code) => {
            app.write("FAIL GFX57\n");
            code
        }
    }
}
r4os_sdk::app!(main);
