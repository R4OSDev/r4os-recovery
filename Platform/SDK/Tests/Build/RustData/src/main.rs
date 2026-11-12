#![no_std]
extern crate alloc;
use alloc::vec;
use core::{fmt::Write, mem::MaybeUninit, pin::pin};
use r4os_sdk::{
    App,
    data::{
        Arena, ArenaStorage, Data, DataStorage, Decoder, Encoding, Error, Icon, Raster,
        SearchParams, raw as c,
    },
};
const ZIP: &[u8] = include_bytes!("../../../../../Protocols/R4Zip/Tests/Fixtures/deflate.zip");
const PLAIN: &[u8] = include_bytes!("../../../../../Protocols/R4Zip/Tests/Fixtures/payload.bin");
const MANIFEST: &[u8] = include_bytes!("../../../Fixtures/Data/manifest.r4mf.txt");
const ICON: &[u8] = include_bytes!("../../../Fixtures/Icons/windows32.ico");
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
    fn sdk_data_guest(
        start: *const r4os_sdk::abi::R4XStartContext,
        zip: *const u8,
        length: usize,
        decoded: *mut u8,
        capacity: usize,
        plain: *const u8,
    ) -> i32;
}
fn checked(v: c::R4SdkDataSlot) -> Result<c::R4SdkDataSlot, Error> {
    if v.status != 0 || v.flags & 2 != 0 {
        Err(Error::InvalidNative)
    } else {
        Ok(v)
    }
}
fn stream(data: &Data<'_, '_>) -> Result<(), Error> {
    let mut zip = MaybeUninit::uninit();
    checked(unsafe { c::R4SdkData_zip(0, data.native(), zip.as_mut_ptr()) })?;
    let mut entries = [const { MaybeUninit::<c::R4SdkDataZipEntry>::uninit() }; 4];
    let mut info = MaybeUninit::uninit();
    checked(unsafe {
        c::R4SdkDataZipContext_inspect(
            0,
            zip.as_ptr(),
            ZIP.as_ptr(),
            ZIP.len() as u64,
            entries.as_mut_ptr().cast(),
            4,
            info.as_mut_ptr(),
        )
    })?;
    if checked(unsafe { c::R4SdkDataZipInfo_get_entries(info.as_ptr()) })?.bits != 1 {
        return Err(Error::InvalidNative);
    }
    let mut work = pin!(MaybeUninit::<c::R4SdkDataZipWork>::uninit());
    let native = work.as_mut().get_mut().as_mut_ptr();
    let mut window = vec![0; c::R4SdkDataZip_stream_buffer_bytes as usize];
    let mut progress = MaybeUninit::uninit();
    checked(unsafe {
        c::R4SdkDataZipContext_beginStream(
            0,
            zip.as_ptr(),
            ZIP.as_ptr(),
            ZIP.len() as u64,
            entries[0].as_ptr(),
            window.as_mut_ptr(),
            window.len() as u64,
            native,
            progress.as_mut_ptr(),
        )
    })?;
    let mut decoded = alloc::vec::Vec::new();
    for _ in 0..128 {
        let n = checked(unsafe { c::R4SdkDataZipProgress_get_reserved(progress.as_ptr()) })?.bits
            as usize;
        let start = c::R4SdkDataZip_stream_history_bytes as usize;
        if n > window.len() - start {
            return Err(Error::Bounds);
        }
        decoded.extend_from_slice(&window[start..start + n]);
        if checked(unsafe { c::R4SdkDataZipProgress_get_done(progress.as_ptr()) })?.bits == 1 {
            return if decoded == PLAIN {
                Ok(())
            } else {
                Err(Error::InvalidNative)
            };
        }
        checked(unsafe {
            c::R4SdkDataZipContext_streamStep(0, zip.as_ptr(), native, 4096, progress.as_mut_ptr())
        })?;
    }
    Err(Error::Bounds)
}
fn exercise(app: &App<'_>) -> Result<(), (i32, Error)> {
    let bad = Error::InvalidNative;
    let mut storage = pin!(DataStorage::new());
    let data = Data::open(storage.as_mut(), app).map_err(|e| (1, e))?;
    let mut depth = [0; 16];
    let mut json = data
        .json(
            b"{\"n\":18446744073709551615,\"too\":18446744073709551616,\"a\":[1,2],\"text\":\"A\"}",
            &mut depth,
        )
        .map_err(|e| (2, e))?;
    if json.read_u64(b"n").map_err(|e| (3, e))? != u64::MAX
        || json.read_u64(b"too") != Err(Error::Native("BadDocument"))
    {
        return Err((4, bad));
    }
    let mut out = [0; 256];
    if json.read(b"text", &mut out).map_err(|e| (5, e))? != b"A" {
        return Err((6, bad));
    }
    if !json
        .set(b"text", b"\"B\"", &mut out)
        .map_err(|e| (7, e))?
        .windows(10)
        .any(|b| b == b"\"text\":\"B\"")
    {
        return Err((8, bad));
    }
    json.select(b"a").map_err(|e| (9, e))?;
    json.enter().map_err(|e| (10, e))?;
    if json.token_bytes().map_err(|e| (11, e))? != Some(&b"1"[..]) {
        return Err((12, bad));
    }
    json.next_element().map_err(|e| (13, e))?;
    if json.token_bytes().map_err(|e| (14, e))? != Some(&b"2"[..]) {
        return Err((15, bad));
    }
    let mut hash = data.sha256().map_err(|e| (16, e))?;
    hash.update(b"a").map_err(|e| (17, e))?;
    hash.update(b"bc").map_err(|e| (18, e))?;
    let digest = hash.finish().map_err(|e| (19, e))?;
    if digest[0] != 0xba || digest[31] != 0xad {
        return Err((20, bad));
    }
    let mut expected = [0; 32];
    r4os_sdk::data::digest(b"SHA-256", PLAIN, &mut expected).map_err(|e| (42, e))?;
    let mut full = data.sha256().map_err(|e| (43, e))?;
    full.update(PLAIN).map_err(|e| (44, e))?;
    let (accepted, refused) = full.counters().map_err(|e| (45, e))?;
    if full.finish().map_err(|e| (46, e))? != expected {
        return Err((47, bad));
    }
    let _ = writeln!(
        &mut Output(app),
        "DATA61 SHA batch receipts: accepted={} refused={} (software remains valid)",
        accepted,
        refused
    );
    let mut decoder = Decoder::new(Encoding::Utf8, true, false).map_err(|e| (21, e))?;
    if decoder
        .decode(b"\xc3", &mut out, true)
        .map_err(|e| (22, e))?
        != ""
        || decoder
            .decode(b"\xbc", &mut out, false)
            .map_err(|e| (23, e))?
            != "ü"
    {
        return Err((24, bad));
    }
    let mut arena_storage = pin!(ArenaStorage::new());
    let mut scratch = vec![0; 65536];
    let mut arena = Arena::open(arena_storage.as_mut(), &mut scratch).map_err(|e| (25, e))?;
    {
        let manifest = arena
            .manifest(b"module.R4MF", MANIFEST)
            .map_err(|e| (26, e))?;
        if manifest.name().map_err(|e| (27, e))? != b"DATAUNIT"
            || manifest.version().map_err(|e| (28, e))? != (1, 2, 3)
        {
            return Err((29, bad));
        }
    }
    let mut pixels = [0; 16];
    let mut raster = Raster::new(&mut pixels, 2, 2, 0xffffff).map_err(|e| (30, e))?;
    raster.set(1, 0, 0x010203).map_err(|e| (31, e))?;
    raster.resize(3, 3, 0x090909).map_err(|e| (32, e))?;
    if raster.pixel(1, 0).map_err(|e| (33, e))? != Some(0x010203)
        || Icon::open(ICON)
            .map_err(|e| (34, e))?
            .bitmap(0)
            .map_err(|e| (35, e))?
            .pixel(0, 0)
            .map_err(|e| (36, e))?
            != Some((255, 255))
    {
        return Err((37, bad));
    }
    let params = SearchParams::new(b"a=one+two").map_err(|e| (38, e))?;
    if params.get(b"a").map_err(|e| (39, e))? != Some(&b"one two"[..]) {
        return Err((40, bad));
    }
    let mut decoded = vec![0; PLAIN.len()];
    let rc = unsafe {
        sdk_data_guest(
            app.start_context(),
            ZIP.as_ptr(),
            ZIP.len(),
            decoded.as_mut_ptr(),
            decoded.len(),
            PLAIN.as_ptr(),
        )
    };
    if rc != 0 {
        return Err((100 + rc, bad));
    }
    stream(&data).map_err(|e| (41, e))?;
    Ok(())
}
fn main(app: &mut App<'_>) -> i32 {
    let before = app.heap().unwrap().stats().unwrap();
    if let Err((step, error)) = exercise(app) {
        let _ = writeln!(
            &mut Output(app),
            "FAIL DATA61 step={} error={:?}",
            step,
            error
        );
        return step;
    }
    let after = app.heap().unwrap().stats().unwrap();
    if before.get(c"active_allocations") != after.get(c"active_allocations")
        || before.get(c"active_bytes") != after.get(c"active_bytes")
    {
        app.write("FAIL DATA61 heap balance\n");
        return 90;
    }
    app.write("PASS DATA61 Rust/C real JSON/ZIP protocols, u64 overflow, full/stream CRC bytes, shared SHA/codec/URL/raster/ICO/manifest and exact heap release\n");
    0
}
r4os_sdk::app!(main);
