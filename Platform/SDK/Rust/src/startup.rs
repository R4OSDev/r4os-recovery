//! Checked loader views. The SDK's manifest owner generates the expected
//! records, so no Rust-specific import grammar or capacity limit exists.
use crate::abi;
use core::{mem, ptr};

#[derive(Clone, Copy)]
pub struct ImportSpec {
    pub module_name: &'static [u8],
    pub symbol_name: &'static [u8],
    pub minimum: u32,
    pub optional: bool,
    pub group_id: u32,
    pub magic: u32,
    pub version: u32,
    pub size: u32,
}

pub struct StartupInfo<'a> {
    pub app_class: abi::R4XStartAppClass,
    pub required_groups: u32,
    pub imports: &'a [ImportSpec],
}

#[repr(C)]
#[derive(Clone, Copy)]
struct Header {
    magic: u32,
    version: u32,
    size: u32,
    reserved: u32,
}

pub(crate) unsafe fn name_equals(address: u64, expected: &[u8]) -> bool {
    if address == 0 || expected.is_empty() || expected.len() > 31 {
        return false;
    }
    let p = address as *const u8;
    for (index, byte) in expected.iter().enumerate() {
        if !unsafe { *p.add(index) }.eq_ignore_ascii_case(byte) {
            return false;
        }
    }
    unsafe { *p.add(expected.len()) == 0 }
}

pub(crate) unsafe fn entries(context: &abi::R4XStartContext) -> &[abi::R4XStartImport] {
    if context.import_count == 0 {
        &[]
    } else {
        unsafe {
            core::slice::from_raw_parts(
                context.imports as *const abi::R4XStartImport,
                context.import_count as usize,
            )
        }
    }
}

pub(crate) unsafe fn validate<'a>(
    raw: *const abi::R4XStartContext,
    expected: &StartupInfo<'_>,
) -> Result<&'a abi::R4XStartContext, i32> {
    if raw.is_null() || !(raw as usize).is_multiple_of(mem::align_of::<abi::R4XStartContext>()) {
        return Err(-10);
    }
    // Inspect the resident common prefix before forming a full Context loan.
    let magic = unsafe { ptr::read(ptr::addr_of!((*raw).magic)) };
    let major = unsafe { ptr::read(ptr::addr_of!((*raw).abi_major)) };
    let minor = unsafe { ptr::read(ptr::addr_of!((*raw).abi_minor)) };
    let size = unsafe { ptr::read(ptr::addr_of!((*raw).size)) };
    if magic != abi::r4xstart_magic
        || major != abi::r4xstart_abi_major
        || minor < abi::r4xstart_abi_minor
        || size < abi::r4xstart_context_size
    {
        return Err(-12);
    }
    let context = unsafe { &*raw };
    if context.app_class != expected.app_class.0
        || context.flags & abi::r4xstart_flag_imports_valid == 0
    {
        return Err(-12);
    }
    let count = context.import_count as usize;
    if count != expected.imports.len()
        || (count != 0 && context.imports == 0)
        || !(context.imports as usize).is_multiple_of(mem::align_of::<abi::R4XStartImport>())
        || count
            .checked_mul(mem::size_of::<abi::R4XStartImport>())
            .filter(|bytes| *bytes <= isize::MAX as usize)
            .and_then(|bytes| (context.imports as usize).checked_add(bytes))
            .is_none()
        || context.args_len > isize::MAX as u64
        || (context.args_len != 0 && context.args == 0)
        || context.args.checked_add(context.args_len).is_none()
    {
        return Err(-13);
    }
    let mut groups = 0;
    for (entry, spec) in unsafe { entries(context) }.iter().zip(expected.imports) {
        if spec.minimum == 0
            || entry.min_version != spec.minimum
            || entry.group_id != spec.group_id
            || !unsafe { name_equals(entry.module_name, spec.module_name) }
            || !unsafe { name_equals(entry.symbol_name, spec.symbol_name) }
        {
            return Err(-14);
        }
        if entry.table == 0 {
            if !spec.optional
                || spec.group_id != 0
                || entry.resolved_version != 0
                || entry.flags != 0
            {
                return Err(-14);
            }
            continue;
        }
        if entry.resolved_version < spec.minimum {
            return Err(-14);
        }
        if spec.group_id == 0 {
            if entry.flags != 0 {
                return Err(-14);
            }
            continue;
        }
        if spec.optional
            || spec.group_id >= 32
            || entry.flags != abi::r4xstart_import_flag_group_interface
            || !entry.table.is_multiple_of(mem::size_of::<u64>() as u64)
            || spec.size < mem::size_of::<Header>() as u32
        {
            return Err(-14);
        }
        let header = unsafe { ptr::read(entry.table as *const Header) };
        if header.magic != spec.magic || header.version < spec.version || header.size < spec.size {
            return Err(-15);
        }
        groups |= 1 << spec.group_id;
    }
    if groups & expected.required_groups != expected.required_groups {
        return Err(-15);
    }
    Ok(context)
}

pub(crate) unsafe fn table<T>(
    context: &abi::R4XStartContext,
    group: abi::R4LGroup,
    magic: u32,
    version: u32,
) -> Option<&T> {
    let entry = unsafe { entries(context) }
        .iter()
        .find(|e| e.group_id == group.0)?;
    if entry.table == 0
        || entry.flags != abi::r4xstart_import_flag_group_interface
        || !(entry.table as usize).is_multiple_of(mem::align_of::<T>())
    {
        return None;
    }
    let header = unsafe { ptr::read(entry.table as *const Header) };
    if header.magic != magic
        || header.version < version
        || (header.size as usize) < mem::size_of::<T>()
    {
        return None;
    }
    Some(unsafe { &*(entry.table as *const T) })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::App;

    unsafe extern "C" fn close(context: *const abi::R4XStartContext) -> u32 {
        u32::from(unsafe { (*context).instance_id } == 42)
    }

    #[test]
    fn hosted_context_optional_named_imports_and_six_checked_groups() {
        // Platform start tables contain integer slots, so zero slots are valid
        // table contents. Startup does not call a window/console operation.
        macro_rules! platform {
            ($ty:ident, $magic:ident, $version:ident) => {
                abi::$ty::default()
            };
        }
        let sys = platform!(R4XStartR4Sys, r4xstart_r4sys_magic, r4xstart_r4sys_version);
        let desk = platform!(
            R4XStartR4Desk,
            r4xstart_r4desk_magic,
            r4xstart_r4desk_version
        );
        let draw = platform!(
            R4XStartR4Draw,
            r4xstart_r4draw_magic,
            r4xstart_r4draw_version
        );
        let net = platform!(R4XStartR4Net, r4xstart_r4net_magic, r4xstart_r4net_version);
        let audio = platform!(
            R4XStartR4Audio,
            r4xstart_r4audio_magic,
            r4xstart_r4audio_version
        );
        let mut dev = platform!(R4XStartR4Dev, r4xstart_r4dev_magic, r4xstart_r4dev_version);
        let mut entries: [abi::R4XStartImport; 16] = unsafe { mem::zeroed() };
        let mut specs = [ImportSpec {
            module_name: b"LIB",
            symbol_name: b"API_V1",
            minimum: 1,
            optional: true,
            group_id: 0,
            magic: 0,
            version: 0,
            size: 0,
        }; 16];
        macro_rules! bind {
            ($index:expr, $table:ident, $name:literal, $group:ident) => {{
                let table = &$table;
                entries[$index].group_id = abi::R4LGroup::$group.0;
                entries[$index].flags = abi::r4xstart_import_flag_group_interface;
                entries[$index].resolved_version = 1;
                entries[$index].table = ptr::from_ref(table) as u64;
                entries[$index].module_name = concat!($name, "\0").as_ptr() as u64;
                entries[$index].symbol_name = c"Query".as_ptr() as u64;
                specs[$index] = ImportSpec {
                    module_name: $name.as_bytes(),
                    symbol_name: b"Query",
                    minimum: 1,
                    optional: false,
                    group_id: abi::R4LGroup::$group.0,
                    magic: table.magic,
                    version: table.abi_version,
                    size: table.size,
                };
            }};
        }
        bind!(0, sys, "R4SYS", r4sys);
        bind!(1, desk, "R4DESK", r4desk);
        bind!(2, draw, "R4DRAW", r4draw);
        bind!(3, net, "R4NET", r4net);
        bind!(4, audio, "R4AUDIO", r4audio);
        bind!(5, dev, "R4DEV", r4dev);
        for item in &mut entries {
            item.min_version = 1;
            if item.group_id == 0 {
                item.module_name = c"LIB".as_ptr() as u64;
                item.symbol_name = c"API_V1".as_ptr() as u64;
            }
        }
        // A named export need not be a platform table or aligned data pointer.
        entries[6].table = 1;
        entries[6].resolved_version = 1;
        specs[6].optional = false;
        let expected = StartupInfo {
            app_class: abi::R4XStartAppClass::gui,
            required_groups: (1 << abi::R4LGroup::r4sys.0)
                | (1 << abi::R4LGroup::r4desk.0)
                | (1 << abi::R4LGroup::r4draw.0),
            imports: &specs,
        };
        let mut ctx: abi::R4XStartContext = unsafe { mem::zeroed() };
        ctx.magic = abi::r4xstart_magic;
        ctx.abi_major = abi::r4xstart_abi_major;
        ctx.abi_minor = abi::r4xstart_abi_minor;
        ctx.size = abi::r4xstart_context_size;
        ctx.app_class = abi::R4XStartAppClass::gui.0;
        ctx.flags = abi::r4xstart_flag_imports_valid | abi::r4xstart_flag_close_supported;
        ctx.instance_id = 42;
        ctx.should_close = close as *const () as u64;
        ctx.imports = entries.as_ptr() as u64;
        ctx.import_count = entries.len() as u32;
        ctx.args = b"/HOST".as_ptr() as u64;
        ctx.args_len = 5;
        {
            let app = unsafe { App::from_raw(&ctx, &expected, c"HOST") }.unwrap();
            assert_eq!(app.instance_id(), 42);
            assert_eq!(app.args(), b"/HOST");
            assert!(app.should_close());
            assert_eq!(app.import("lib", "api_v1").unwrap().table, 1);
            assert!(app.system_api().is_some() && app.desktop_api().is_some());
            assert!(app.drawing_api().is_some() && app.network_api().is_some());
            assert!(app.audio_api().is_some() && app.device_api().is_some());
            assert!(app.import("missing", "API").is_none());
        }
        let check = |ctx: &abi::R4XStartContext| unsafe { validate(ctx, &expected).map(|_| ()) };
        entries[7].resolved_version = 1; // Missing optional must be entirely unresolved.
        assert_eq!(check(&ctx), Err(-14));
        entries[7].resolved_version = 0;
        entries[6].table = 0; // Missing mandatory named export.
        assert_eq!(check(&ctx), Err(-14));
        entries[6].table = 1;
        entries[0].resolved_version = 0;
        assert_eq!(check(&ctx), Err(-14));
        entries[0].resolved_version = 1;
        entries[0].table += 1;
        assert_eq!(check(&ctx), Err(-14));
        entries[0].table -= 1;
        core::hint::black_box(&entries);
        dev.size -= 8;
        core::hint::black_box(&dev);
        assert_eq!(check(&ctx), Err(-15));
        dev.size += 8;
        core::hint::black_box(&dev);
        dev.abi_version -= 1;
        core::hint::black_box(&dev);
        assert_eq!(check(&ctx), Err(-15));
        dev.abi_version += 1;
        core::hint::black_box(&dev);
        ctx.import_count -= 1;
        assert_eq!(check(&ctx), Err(-13));
        ctx.import_count += 1;
        ctx.app_class = abi::R4XStartAppClass::console.0;
        assert_eq!(check(&ctx), Err(-12));
        ctx.app_class = abi::R4XStartAppClass::gui.0;
        ctx.args = u64::MAX;
        assert_eq!(check(&ctx), Err(-13));
        ctx.args = 0;
        assert_eq!(check(&ctx), Err(-13));
        ctx.args_len = 0;
        assert_eq!(check(&ctx), Ok(()));
        ctx.size -= 8;
        assert_eq!(check(&ctx), Err(-12));
        assert_eq!(
            unsafe { validate(ptr::null(), &expected).map(|_| ()) },
            Err(-10)
        );
    }
}
