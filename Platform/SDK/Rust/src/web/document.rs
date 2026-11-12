use super::{Result, c, object_view, output_view, required, result, scalar};
use core::{marker::PhantomData, mem::MaybeUninit};

pub struct Document<'s> {
    native: *mut c::R4SdkWebHtmlDocument,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkWebHtmlDocument>>,
    _local: PhantomData<*mut ()>,
}
impl<'s> Document<'s> {
    pub fn parse(
        storage: &'s mut MaybeUninit<c::R4SdkWebHtmlDocument>,
        input: &[u8],
        content_type: &[u8],
        require_html: bool,
    ) -> Result<Self> {
        let mut options = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkWebHtmlParseOptions_from_fields(
                options.as_mut_ptr(),
                content_type.as_ptr(),
                content_type.len() as u64,
                require_html as u8,
            )
        })?;
        let mut stats = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkWebHtmlDocument_parse(
                0,
                storage.as_mut_ptr(),
                input.as_ptr(),
                input.len() as u64,
                options.as_ptr(),
                stats.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            native: storage.as_mut_ptr(),
            _storage: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn find(&self, id: &[u8]) -> Result<Option<u16>> {
        let v = result(unsafe {
            c::R4SdkWebHtmlDocument_findElementById(0, self.native, id.as_ptr(), id.len() as u64)
        })?;
        Ok(if v.flags & 1 == 0 {
            None
        } else {
            Some(v.bits as u16)
        })
    }
    pub fn first(&self, tag: &[u8]) -> Result<Option<u16>> {
        let v = result(unsafe {
            c::R4SdkWebHtmlDocument_findFirstElement(0, self.native, tag.as_ptr(), tag.len() as u64)
        })?;
        Ok(if v.flags & 1 == 0 {
            None
        } else {
            Some(v.bits as u16)
        })
    }
    pub fn attribute(&self, node: u16, name: &[u8]) -> Result<Option<&[u8]>> {
        let v = result(unsafe {
            c::R4SdkWebHtmlDocument_attribute(
                0,
                self.native,
                node,
                name.as_ptr(),
                name.len() as u64,
            )
        })?;
        if v.flags & 1 == 0 {
            return Ok(None);
        }
        // Native views are bounds checked against this exact document's storage.
        Ok(Some(object_view(v, unsafe {
            &*self.native.cast::<MaybeUninit<c::R4SdkWebHtmlDocument>>()
        })?))
    }
    pub fn text<'o>(&self, node: u16, out: &'o mut [u8]) -> Result<&'o [u8]> {
        let v = unsafe {
            c::R4SdkWebHtmlDocument_textContent(
                0,
                self.native,
                node,
                out.as_mut_ptr(),
                out.len() as u64,
            )
        };
        output_view(v, out)
    }
    pub fn set_text(&mut self, node: u16, value: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4SdkWebHtmlDocument_setTextContent(
                0,
                self.native,
                node,
                value.as_ptr(),
                value.len() as u64,
            )
        })?;
        Ok(())
    }
    pub fn set_attribute(&mut self, node: u16, name: &[u8], value: &[u8]) -> Result<()> {
        result(unsafe {
            c::R4SdkWebHtmlDocument_setAttribute(
                0,
                self.native,
                node,
                name.as_ptr(),
                name.len() as u64,
                value.as_ptr(),
                value.len() as u64,
            )
        })?;
        Ok(())
    }
    pub fn node_count(&self) -> Result<usize> {
        Ok(scalar(unsafe { c::R4SdkWebHtmlDocument_get_node_count(self.native) })? as usize)
    }
    /// # Safety
    /// Do not invalidate existing document/stylesheet/layout/runtime loans.
    pub unsafe fn native(&self) -> *mut c::R4SdkWebHtmlDocument {
        self.native
    }
}
pub struct Stylesheet<'s> {
    native: *mut c::R4SdkWebCssStylesheet,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkWebCssStylesheet>>,
    _local: PhantomData<*mut ()>,
}
impl<'s> Stylesheet<'s> {
    pub fn parse(
        storage: &'s mut MaybeUninit<c::R4SdkWebCssStylesheet>,
        source: &[u8],
    ) -> Result<Self> {
        let mut stats = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkWebCssStylesheet_parse(
                0,
                storage.as_mut_ptr(),
                source.as_ptr(),
                source.len() as u64,
                stats.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            native: storage.as_mut_ptr(),
            _storage: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn append_document(&mut self, document: &Document<'_>) -> Result<()> {
        result(unsafe {
            c::R4SdkWebCssStylesheet_appendDocumentStyles(0, self.native, document.native)
        })?;
        Ok(())
    }
}
pub struct Reflow<'s, 'd> {
    native: *mut c::R4SdkWebLayoutLayout,
    _storage: PhantomData<&'s mut MaybeUninit<c::R4SdkWebLayoutLayout>>,
    _inputs: PhantomData<&'d ()>,
    _local: PhantomData<*mut ()>,
}
impl<'s, 'd> Reflow<'s, 'd> {
    pub fn new(
        storage: &'s mut MaybeUninit<c::R4SdkWebLayoutLayout>,
        document: &'d Document<'_>,
        sheet: &'d Stylesheet<'_>,
        width: i32,
        height: i32,
    ) -> Result<Self> {
        required(unsafe { c::R4SdkWebLayoutLayout_create(storage.as_mut_ptr()) })?;
        let mut viewport = MaybeUninit::uninit();
        let mut stats = MaybeUninit::uninit();
        required(unsafe {
            c::R4SdkWebLayoutViewport_create(viewport.as_mut_ptr(), width, height)
        })?;
        required(unsafe {
            c::R4SdkWebLayoutLayout_reflow(
                0,
                storage.as_mut_ptr(),
                document.native,
                sheet.native,
                viewport.as_ptr(),
                stats.as_mut_ptr(),
            )
        })?;
        Ok(Self {
            native: storage.as_mut_ptr(),
            _storage: PhantomData,
            _inputs: PhantomData,
            _local: PhantomData,
        })
    }
    pub fn operation_count(&self) -> Result<usize> {
        let mut stats = MaybeUninit::uninit();
        required(unsafe { c::R4SdkWebLayoutLayout_stats(0, self.native, stats.as_mut_ptr()) })?;
        Ok(
            scalar(unsafe { c::R4SdkWebLayoutLayoutStats_get_render_ops(stats.as_ptr()) })?
                as usize,
        )
    }
    pub fn structural_hash(&self) -> Result<u64> {
        scalar(unsafe { c::R4SdkWebLayoutLayout_structuralHash(0, self.native) })
    }
}
