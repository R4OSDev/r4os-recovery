//! Bounded pages own their selected paths; labels are presentation only.
use crate::{
    c_facades as c,
    path::FilePath,
    storage::{Error, Files, Result},
};
pub struct DialogPage<const N: usize> {
    rows: [c::R4DialogRow; N],
    directory: Option<FilePath>,
    count: usize,
    number: u32,
}
impl<const N: usize> DialogPage<N> {
    pub fn new() -> Result<Self> {
        if N < 4 || N > u32::MAX as usize {
            return Err(Error::Length);
        }
        Ok(Self {
            rows: unsafe { core::mem::zeroed() },
            directory: None,
            count: 0,
            number: 0,
        })
    }
    /// Scratch is disjoint caller-owned row storage. A failed full scan keeps
    /// the last published page and its exact selected paths unchanged.
    pub fn load(
        &mut self,
        files: &Files<'_>,
        scratch: &mut [c::R4DialogRow],
        directory: &FilePath,
        number: u32,
        extension: &[u8],
    ) -> Result<bool> {
        let mut page = c::R4DialogPage {
            directory: *directory.as_raw(),
            rows: self.rows.as_mut_ptr(),
            capacity: N as u32,
            count: self.count as u32,
            number: self.number,
        };
        let ok = unsafe {
            c::r4_dialog_page_load(
                &mut page,
                scratch.as_mut_ptr(),
                crate::storage::length(scratch.len())?,
                files.raw(),
                directory.as_raw(),
                number,
                extension.as_ptr(),
                extension.len() as u64,
            )
        } != 0;
        if ok {
            self.count = page.count as usize;
            self.number = page.number;
            self.directory = Some(directory.clone())
        }
        Ok(ok)
    }
    pub fn directory(&self) -> Option<&FilePath> {
        self.directory.as_ref()
    }
    pub fn number(&self) -> u32 {
        self.number
    }
    pub fn rows(&self) -> &[c::R4DialogRow] {
        &self.rows[..self.count]
    }
}
/// The Rust adaptation owns `T` values, including their destructors. A rejected
/// or displaced value is returned to the caller instead of copied as bytes.
pub struct OrderedPage<T, const N: usize> {
    entries: [Option<T>; N],
    count: usize,
}
impl<T, const N: usize> OrderedPage<T, N> {
    pub fn new() -> Result<Self> {
        if N == 0 {
            return Err(Error::Length);
        }
        Ok(Self {
            entries: [const { None }; N],
            count: 0,
        })
    }
    pub fn offer(&mut self, value: T, mut less: impl FnMut(&T, &T) -> bool) -> Option<T> {
        if self.count == N && !less(&value, self.entries[N - 1].as_ref().unwrap()) {
            return Some(value);
        }
        let mut at = self.count.min(N - 1);
        let displaced = self.entries[at].take();
        while at > 0 && less(&value, self.entries[at - 1].as_ref().unwrap()) {
            self.entries[at] = self.entries[at - 1].take();
            at -= 1;
        }
        self.entries[at] = Some(value);
        self.count = (self.count + 1).min(N);
        displaced
    }
    pub fn len(&self) -> usize {
        self.count
    }
    pub fn is_empty(&self) -> bool {
        self.count == 0
    }
    pub fn iter(&self) -> impl Iterator<Item = &T> {
        self.entries[..self.count]
            .iter()
            .map(|item| item.as_ref().unwrap())
    }
}
#[cfg(feature = "alloc")]
mod allocated {
    extern crate alloc;
    use super::{Error, Result};
    use alloc::vec::Vec;
    pub struct Snapshot<T> {
        values: Vec<T>,
        limit: usize,
    }
    impl<T> Snapshot<T> {
        pub fn new(max_bytes: usize) -> Result<Self> {
            if core::mem::size_of::<T>() == 0 {
                return Err(Error::Length);
            }
            Ok(Self {
                values: Vec::new(),
                limit: max_bytes / core::mem::size_of::<T>(),
            })
        }
        pub fn append(&mut self, value: T) -> Result<()> {
            if self.values.len() == self.limit {
                return Err(Error::Length);
            }
            if self.values.len() == self.values.capacity() {
                let wanted = self
                    .values
                    .capacity()
                    .saturating_mul(2)
                    .max(64)
                    .min(self.limit);
                self.values
                    .try_reserve_exact(wanted - self.values.len())
                    .map_err(|_| Error::Length)?;
            }
            self.values.push(value);
            Ok(())
        }
        pub fn values(&self) -> &[T] {
            &self.values
        }
        pub fn sort(&mut self, compare: impl FnMut(&T, &T) -> core::cmp::Ordering) {
            self.values.sort_unstable_by(compare)
        }
        pub fn clear(&mut self) {
            self.values.clear()
        }
    }
}
#[cfg(feature = "alloc")]
pub use allocated::Snapshot;
