//! Binary/text hive operations use the existing Zig codec. Views pin their
//! immutable bytes, builders use explicit bounded scratch and output slices.
use crate::c_facades as c;
use core::{marker::PhantomData, mem::MaybeUninit};
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Code(i32),
    OutputCapacity { required: usize },
    InvalidResult,
}
type Result<T> = core::result::Result<T, Error>;
fn success(raw: i32) -> Result<()> {
    if raw < 0 {
        Err(Error::Code(raw))
    } else {
        Ok(())
    }
}
pub struct Hive<'a> {
    raw: c::R4HiveView,
    _bytes: PhantomData<&'a [u8]>,
}
impl<'a> Hive<'a> {
    pub fn parse(bytes: &'a [u8]) -> Result<Self> {
        let mut raw = MaybeUninit::uninit();
        success(unsafe {
            c::R4SdkHiveParse(bytes.as_ptr(), bytes.len() as u64, raw.as_mut_ptr())
        })?;
        Ok(Self {
            raw: unsafe { raw.assume_init() },
            _bytes: PhantomData,
        })
    }
    pub fn header(&self) -> c::R4HiveHeader {
        self.raw.header
    }
    fn find(&self, operation: i32, parent: u32, name: &[u8]) -> Result<Option<u32>> {
        let mut index = 0;
        let raw = unsafe {
            c::R4SdkHiveFind(
                &self.raw,
                operation,
                parent,
                name.as_ptr(),
                name.len() as u64,
                &mut index,
            )
        };
        success(raw)?;
        Ok((raw != 0).then_some(index))
    }
    pub fn find_key(&self, path: &[u8]) -> Result<Option<u32>> {
        self.find(0, 0, path)
    }
    pub fn find_child(&self, parent: u32, name: &[u8]) -> Result<Option<u32>> {
        self.find(1, parent, name)
    }
    pub fn find_value(&self, parent: u32, name: &[u8]) -> Result<Option<u32>> {
        self.find(2, parent, name)
    }
    pub fn key(&self, index: u32) -> Result<Option<Key<'a>>> {
        let mut key = MaybeUninit::uninit();
        let raw = unsafe { c::R4SdkHiveKey(&self.raw, index, key.as_mut_ptr()) };
        success(raw)?;
        if raw == 0 {
            return Ok(None);
        }
        let key = unsafe { key.assume_init() };
        Ok(Some(Key {
            parent_index: key.parent_index,
            first_value_index: key.first_value_index,
            value_count: key.value_count,
            first_child_index: key.first_child_index,
            child_count: key.child_count,
            name: unsafe { core::slice::from_raw_parts(key.name, key.name_len as usize) },
        }))
    }
    pub fn value(&self, index: u32) -> Result<Option<Value<'a>>> {
        let mut value = MaybeUninit::uninit();
        let raw = unsafe { c::R4SdkHiveValue(&self.raw, index, value.as_mut_ptr()) };
        success(raw)?;
        if raw == 0 {
            return Ok(None);
        }
        let value = unsafe { value.assume_init() };
        Ok(Some(Value {
            owner_key_index: value.owner_key_index,
            value_type: value.value_type,
            name: unsafe { core::slice::from_raw_parts(value.name, value.name_len as usize) },
            data: unsafe { core::slice::from_raw_parts(value.data, value.data_len as usize) },
        }))
    }
    pub fn get(&self, path: &[u8], name: &[u8]) -> Result<Option<Value<'a>>> {
        let Some(key) = self.find_key(path)? else {
            return Ok(None);
        };
        let Some(value) = self.find_value(key, name)? else {
            return Ok(None);
        };
        self.value(value)
    }
}
pub struct Key<'a> {
    pub parent_index: u32,
    pub first_value_index: u32,
    pub value_count: u32,
    pub first_child_index: u32,
    pub child_count: u32,
    pub name: &'a [u8],
}
pub struct Value<'a> {
    pub owner_key_index: u32,
    pub value_type: u16,
    pub name: &'a [u8],
    pub data: &'a [u8],
}
impl Value<'_> {
    pub fn as_string(&self) -> Option<&[u8]> {
        (self.value_type == 1).then_some(self.data)
    }
    pub fn as_u32(&self) -> Option<u32> {
        if self.value_type != 2 {
            return None;
        }
        Some(u32::from_le_bytes(self.data.try_into().ok()?))
    }
    pub fn as_u64(&self) -> Option<u64> {
        if self.value_type != 3 {
            return None;
        }
        Some(u64::from_le_bytes(self.data.try_into().ok()?))
    }
    pub fn as_bool(&self) -> Option<bool> {
        if self.value_type == 4 && self.data.len() == 1 && self.data[0] < 2 {
            Some(self.data[0] != 0)
        } else {
            None
        }
    }
}
#[repr(C)]
pub struct BuildValue<'a> {
    raw: c::R4HiveBuildValue,
    _bytes: PhantomData<&'a [u8]>,
}
impl<'a> BuildValue<'a> {
    pub fn new(key: &'a [u8], name: &'a [u8], value_type: u16, data: &'a [u8]) -> Self {
        Self {
            raw: c::R4HiveBuildValue {
                key: key.as_ptr(),
                key_len: key.len() as u64,
                name: name.as_ptr(),
                name_len: name.len() as u64,
                value_type,
                data: data.as_ptr(),
                data_len: data.len() as u64,
            },
            _bytes: PhantomData,
        }
    }
}
const _: () = {
    assert!(core::mem::size_of::<BuildValue<'_>>() == core::mem::size_of::<c::R4HiveBuildValue>());
    assert!(
        core::mem::align_of::<BuildValue<'_>>() == core::mem::align_of::<c::R4HiveBuildValue>()
    );
};
fn published(out: &mut [u8], written: u64, raw: i32) -> Result<&[u8]> {
    if raw == -25 {
        return Err(Error::OutputCapacity {
            required: written as usize,
        });
    }
    success(raw)?;
    out.get(..written as usize).ok_or(Error::InvalidResult)
}
pub fn build<'o>(
    kind: u16,
    generation: u64,
    values: &[BuildValue<'_>],
    scratch: &mut [u8],
    out: &'o mut [u8],
) -> Result<&'o [u8]> {
    let mut written = 0;
    let raw = unsafe {
        c::R4SdkHiveBuild(
            kind,
            generation,
            values.as_ptr().cast(),
            values.len() as u64,
            scratch.as_mut_ptr(),
            scratch.len() as u64,
            out.as_mut_ptr(),
            out.len() as u64,
            &mut written,
        )
    };
    published(out, written, raw)
}
pub fn import_text<'o>(
    text: &[u8],
    generation: u64,
    scratch: &mut [u8],
    out: &'o mut [u8],
) -> Result<&'o [u8]> {
    transform(true, text, generation, scratch, out)
}
pub fn export_text<'o>(hive: &Hive<'_>, scratch: &mut [u8], out: &'o mut [u8]) -> Result<&'o [u8]> {
    let bytes = unsafe { core::slice::from_raw_parts(hive.raw.bytes, hive.raw.length as usize) };
    transform(false, bytes, 0, scratch, out)
}
fn transform<'o>(
    import: bool,
    bytes: &[u8],
    generation: u64,
    scratch: &mut [u8],
    out: &'o mut [u8],
) -> Result<&'o [u8]> {
    let mut written = 0;
    let raw = unsafe {
        c::R4SdkHiveText(
            i32::from(import),
            generation,
            bytes.as_ptr(),
            bytes.len() as u64,
            scratch.as_mut_ptr(),
            scratch.len() as u64,
            out.as_mut_ptr(),
            out.len() as u64,
            &mut written,
        )
    };
    published(out, written, raw)
}
