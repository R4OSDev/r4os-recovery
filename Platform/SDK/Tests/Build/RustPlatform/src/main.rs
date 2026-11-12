#![no_std]
use core::{fmt::Write, pin::pin};
use r4os_sdk::{
    App, abi,
    platform::{Platform, PlatformStorage, Resampler, WriteCursor, WriteKind, raw as c},
    resources::Timeout,
};
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
unsafe extern "C" {
    fn sdk58_audio_c(audio: *mut c::R4SdkAudioAudio) -> i32;
}
fn main(app: &mut App<'_>) -> i32 {
    let result = exercise(app);
    if let Err(code) = result {
        let _ = writeln!(&mut Output(app), "FAIL PLATFORM58 step={}", code);
        return code;
    }
    app.write(
        "PASS PLATFORM58 Rust/C silent PCM, device/clock/status, power receipts and stream close\n",
    );
    0
}
fn exercise(app: &App<'_>) -> Result<(), i32> {
    let mut storage = pin!(PlatformStorage::new());
    let platform = Platform::open(storage.as_mut(), app).map_err(|_| 10)?;
    let inventory = platform.devices().inventory().map_err(|_| 11)?;
    if inventory.total != 0 {
        let _record = platform.devices().record(0).map_err(|_| 12)?;
    }
    if platform.devices().memory().map_err(|_| 13)?.is_none() {
        return Err(14);
    }
    let _instrumentation = platform.devices().instrumentation().map_err(|_| 15)?;
    let _cpu_capabilities = platform.devices().cpu_capabilities(0).map_err(|_| 15)?;
    let clock = platform.clock().map_err(|_| 16)?;
    if clock.version != 1 {
        return Err(17);
    }
    let mut power = platform
        .power(Timeout::AfterNanos(2_000_000_000))
        .map_err(|e| {
            let _ = writeln!(&mut Output(app), "Power unavailable: {:?}", e);
            18
        })?;
    let info = power
        .status(Timeout::AfterNanos(2_000_000_000))
        .map_err(|_| 19)?;
    if info.service_generation == 0 || info.configured_cpus != 4 {
        return Err(20);
    }
    let _cpu = power
        .cpu(0, Timeout::AfterNanos(2_000_000_000))
        .map_err(|_| 21)?;
    let audio = platform.audio().map_err(|_| 22)?;
    let before = audio
        .status(Timeout::AfterNanos(2_000_000_000))
        .map_err(|_| 23)?;
    let mut stream = audio
        .open_stream(48000, 2, 0x10000, Timeout::AfterNanos(2_000_000_000))
        .map_err(|_| 24)?;
    let silence = [0u8; 64];
    let mut converter = Resampler::new().map_err(|_| 25)?;
    converter.begin(48000, 2, 1).map_err(|_| 26)?;
    let bytes = converter
        .take_direct(&silence, 48000, 2, 1, silence.len())
        .map_err(|_| 27)?
        .ok_or(28)?;
    let mut cursor = WriteCursor::new(bytes.len(), 4)
        .map_err(|_| 29)?
        .ok_or(30)?;
    let mut offset = 0;
    for _ in 0..8 {
        let progress = stream
            .write(&bytes[offset..], Timeout::AfterNanos(2_000_000_000), true)
            .map_err(|_| 31)?;
        let accepted = cursor.apply(progress).map_err(|_| 32)?;
        if !matches!(accepted.kind, WriteKind::Complete | WriteKind::Retry) {
            return Err(33);
        }
        offset += accepted.accepted;
        if offset == bytes.len() {
            break;
        }
        app.sleep(10);
    }
    if cursor.remaining().map_err(|_| 34)? != 0 {
        return Err(35);
    }
    stream
        .close(Timeout::AfterNanos(2_000_000_000))
        .map_err(|_| 36)?;
    if stream.valid().map_err(|_| 37)? || stream.close(Timeout::Poll).is_ok() {
        return Err(38);
    }
    let after = audio
        .status(Timeout::AfterNanos(2_000_000_000))
        .map_err(|_| 39)?;
    let _ = (before, after);
    let c_result = unsafe { sdk58_audio_c(audio.native()) };
    if c_result != 0 {
        return Err(40 + c_result);
    }
    // A passive global read is not a new CPU measurement or policy change.
    let _perf = platform.devices().performance().map_err(|_| 50)?;
    let _version: Option<abi::KernelVersion> = platform.devices().kernel().map_err(|_| 51)?;
    Ok(())
}
r4os_sdk::app!(main);
