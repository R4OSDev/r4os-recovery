#![no_std]
use core::ffi::c_void;
use r4os_r4std::{
    ConfigV1Client, DateV1Client, R4StdTextInfo, TextV1Client, text_kind_utf8, text_v1_expectation,
};
use r4os_sdk::{App2, abi, r4l};

struct Arena {
    bytes: [u8; 256 * 1024],
    used: usize,
    live: usize,
    allocations: usize,
    frees: usize,
}
static mut ARENA: Arena = Arena {
    bytes: [0; 256 * 1024],
    used: 0,
    live: 0,
    allocations: 0,
    frees: 0,
};
unsafe extern "C" fn allocate(user: *mut c_void, size: usize, alignment: usize) -> *mut c_void {
    if user.is_null() || size == 0 || !alignment.is_power_of_two() {
        return core::ptr::null_mut();
    }
    let arena = unsafe { &mut *user.cast::<Arena>() };
    let base = arena.bytes.as_mut_ptr() as usize;
    let Some(start) = base
        .checked_add(arena.used)
        .and_then(|v| v.checked_add(alignment - 1))
        .map(|v| v & !(alignment - 1))
    else {
        return core::ptr::null_mut();
    };
    let Some(end) = start.checked_add(size) else {
        return core::ptr::null_mut();
    };
    if end > base + arena.bytes.len() {
        return core::ptr::null_mut();
    }
    arena.used = end - base;
    arena.live += 1;
    arena.allocations += 1;
    start as *mut c_void
}
unsafe extern "C" fn release(user: *mut c_void, block: *mut c_void, _: usize, _: usize) {
    if block.is_null() {
        return;
    }
    let arena = unsafe { &mut *user.cast::<Arena>() };
    assert!(arena.live != 0);
    arena.live -= 1;
    arena.frees += 1;
}
unsafe extern "C" fn reallocate(
    user: *mut c_void,
    block: *mut c_void,
    old: usize,
    size: usize,
    alignment: usize,
) -> *mut c_void {
    if size == 0 {
        unsafe { release(user, block, old, alignment) };
        return core::ptr::null_mut();
    }
    let next = unsafe { allocate(user, size, alignment) };
    if !next.is_null() && !block.is_null() {
        unsafe {
            core::ptr::copy_nonoverlapping(block.cast::<u8>(), next.cast::<u8>(), old.min(size));
            release(user, block, old, alignment);
        }
    }
    next
}
unsafe extern "C" {
    fn r4_library_c_consumer(context: *const abi::generation2::R4XStartContext2) -> i32;
}
fn main(app: &mut App2<'_>) -> i32 {
    let Ok(text) = TextV1Client::init2(app) else {
        return 1;
    };
    let Ok(Some(_)) = TextV1Client::optional2(app) else {
        return 2;
    };
    let Ok(None) = DateV1Client::optional2(app) else {
        return 3;
    };
    let Ok(None) = r4l::Interface::optional2(app, "SDKABSENT", "API_V1", text_v1_expectation)
    else {
        return 4;
    };
    let Ok(query) = r4l::query2(app, "R4STD") else {
        return 5;
    };
    if query.group != 0 || query.reserved != 0 {
        return 6;
    }
    let bytes = "Aä€".as_bytes();
    let mut info = R4StdTextInfo::default();
    if unsafe {
        text.inspect(
            bytes.as_ptr(),
            bytes.len() as u64,
            text_kind_utf8,
            &mut info,
        )
    } != 0
        || info.scalar_count != 3
        || info.content_length != bytes.len() as u64
    {
        return 7;
    }
    if unsafe { r4_library_c_consumer(app.start_context()) } != 0 {
        return 8;
    }
    let Ok(config) = ConfigV1Client::init2(app) else {
        return 9;
    };
    let caller = app.start_context() as *const _ as u64;
    let path = b"C:\\TEMP\\L45R.R4S";
    let document = b"\xef\xbb\xbfR4S_FORMAT=1\r\nSCHEMA=LIB45\r\nNAME=Generation2\r\n";
    if unsafe {
        config.save_document(
            caller,
            path.as_ptr(),
            path.len() as u64,
            document.as_ptr(),
            document.len() as u64,
        )
    } < 0
    {
        return 10;
    }
    let mut value = [0xa5u8; 32];
    let mut scalar = 0;
    if unsafe {
        config.read(
            caller,
            path.as_ptr(),
            path.len() as u64,
            b"NAME".as_ptr(),
            4,
            r4os_r4std::config_kind_string,
            b"fallback".as_ptr(),
            8,
            0,
            value.as_mut_ptr(),
            value.len() as u64,
            &mut scalar,
        )
    } != 0
        || &value[..12] != b"Generation2\0"
    {
        return 11;
    }
    let Ok(fonts) = r4os_r4font::ApiV1Client::init2(app) else {
        return 12;
    };
    let mut format = 0;
    if unsafe { fonts.sniff([0u8, 1, 0, 0].as_ptr(), 4, &mut format) } != 0
        || format != r4os_r4font::format_ttf
    {
        return 13;
    }
    let arena = core::ptr::addr_of_mut!(ARENA);
    let allocator = r4os_r4font::R4FontAllocator {
        r#user: arena as u64,
        r#alloc: allocate as *const () as u64,
        r#realloc: reallocate as *const () as u64,
        r#free: release as *const () as u64,
    };
    let mut decoder = 0;
    if unsafe { fonts.decoder_create(&allocator, 256 * 1024, &mut decoder) } != 0 || decoder == 0 {
        return 14;
    }
    if unsafe { (*arena).live == 0 || (*arena).allocations == 0 } {
        return 15;
    }
    if unsafe { fonts.decoder_destroy(decoder) } != 0 {
        return 16;
    }
    if unsafe { (*arena).live != 0 || (*arena).allocations != (*arena).frees } {
        return 17;
    }
    let Ok(images) = r4os_r4img::ApiV1Client::init2(app) else {
        return 18;
    };
    let mut bmp = [0u8; 58];
    bmp[..2].copy_from_slice(b"BM");
    for (offset, number) in [(2, 58u32), (10, 54), (14, 40), (18, 1), (22, 1), (34, 4)] {
        bmp[offset..offset + 4].copy_from_slice(&number.to_le_bytes());
    }
    bmp[26] = 1;
    bmp[28] = 24;
    bmp[54..57].copy_from_slice(&[0x33, 0x22, 0x11]);
    let mut info = r4os_r4img::R4ImgInfo::default();
    let mut pixels = [0xa5a5a5a5u32];
    let mut required = 0;
    if unsafe {
        images.probe(
            bmp.as_ptr(),
            bmp.len() as u64,
            b"image/bmp".as_ptr(),
            9,
            &mut info,
        )
    } != 0
        || unsafe { images.scratch_bytes(&info, bmp.len() as u64, &mut required) } != 0
        || required == 0
        || required > r4os_r4img::max_scratch_bytes
    {
        return 20;
    }
    let Ok(heap) = app.heap() else {
        return 21;
    };
    let Ok(mut scratch) = heap.allocate(required as usize, 8) else {
        return 22;
    };
    let mut count = 0;
    if unsafe {
        images.decode(
            bmp.as_ptr(),
            bmp.len() as u64,
            b"image/bmp".as_ptr(),
            9,
            pixels.as_mut_ptr(),
            1,
            scratch.as_mut_slice().as_mut_ptr(),
            required,
            &mut info,
            &mut count,
        )
    } != 0
        || count != 1
        || pixels[0] != 0xff112233
    {
        return 19;
    }
    let _=app.write("[RUSTLIB] Query2, independent APIs, optional absence, real STD config, FONT callback balance and IMG exact pixel OK\n");
    0
}
r4os_sdk::app2!(main);
