use super::{Error, Memory, Result, c, required, result, scalar};
use core::{marker::PhantomData, mem::MaybeUninit};
pub struct Canvas<'s, 'm> {
    native: *mut c::R4SdkWebCanvasManager,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkWebCanvasManager>>,
    _memory: PhantomData<&'m mut ()>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'm> Canvas<'s, 'm> {
    pub fn open(
        storage: &'s mut MaybeUninit<c::R4SdkWebCanvasManager>,
        memory: &'m mut Memory<'_, '_>,
    ) -> Result<Self> {
        let mut allocator = MaybeUninit::uninit();
        required(unsafe { c::R4SdkWeb_memoryCanvas(0, memory.native, allocator.as_mut_ptr()) })?;
        result(unsafe {
            c::R4SdkWebCanvasManager_initialize(0, storage.as_mut_ptr(), allocator.as_ptr())
        })?;
        Ok(Self {
            native: storage.as_mut_ptr(),
            _storage: PhantomData,
            _memory: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn ensure(&mut self, node: u16, width: u32, height: u32) -> Result<()> {
        required(unsafe { c::R4SdkWebCanvasManager_ensure(0, self.native, node, width, height) })?;
        Ok(())
    }
    pub fn fill(
        &mut self,
        node: u16,
        x: f64,
        y: f64,
        width: f64,
        height: f64,
        color: u32,
    ) -> Result<()> {
        let surface = required(unsafe { c::R4SdkWebCanvasManager_find(0, self.native, node) })?
            .ptr
            .cast::<c::R4SdkWebCanvasSurface>();
        result(unsafe {
            c::R4SdkWebCanvasManager_fillRectColor(
                0,
                self.native,
                surface,
                &x,
                &y,
                &width,
                &height,
                color,
            )
        })?;
        Ok(())
    }
    pub fn pixels(&self, node: u16) -> Result<&[u32]> {
        let mut view = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkWebCanvasManager_view(0, self.native, node, view.as_mut_ptr())
        })?;
        let width = scalar(unsafe { c::R4SdkWebCanvasSurfaceView_get_width(view.as_ptr()) })?;
        let height = scalar(unsafe { c::R4SdkWebCanvasSurfaceView_get_height(view.as_ptr()) })?;
        let bytes = required(unsafe { c::R4SdkWebCanvasSurfaceView_get_pixels(view.as_ptr()) })?;
        if width.checked_mul(height) != Some(bytes.length)
            || bytes.length > 262144
            || bytes.ptr.is_null()
            || !(bytes.ptr as usize).is_multiple_of(4)
        {
            return Err(Error::InvalidNative);
        }
        Ok(unsafe { core::slice::from_raw_parts(bytes.ptr.cast(), bytes.length as usize) })
    }
}
impl Drop for Canvas<'_, '_> {
    fn drop(&mut self) {
        let _ = unsafe { c::R4SdkWebCanvasManager_deinit(0, self.native) };
    }
}
