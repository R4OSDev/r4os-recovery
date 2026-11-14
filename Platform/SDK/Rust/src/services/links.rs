//! Original native own-link activation. Save the canonical request returned
//! by Prepare before Activate. A failed reply is reconciled only with Status.
use super::{Call, Services};
use crate::{
    abi as a,
    resources::Timeout,
    storage::{Error, Result},
};
use core::mem;
pub type LinkToken = a::DesktopLinkToken;
pub type LinkRequest = a::DesktopLinkRequest;
pub type LinkReply = a::DesktopLinkReply;
pub fn link_supported(reply: &LinkReply) -> bool {
    reply.result == 0 && reply.flags & a::desktop_link_capabilities == a::desktop_link_capabilities
}
pub fn prepare_link_binding(
    scope: LinkToken,
    owner: a::ProgramProcessHandle,
    intent: [u64; 3],
    deadline: u64,
    path: &[u8],
    bytes: &[u8],
) -> Result<LinkRequest> {
    if scope.version != 1
        || scope.size as usize != mem::size_of::<LinkToken>()
        || scope.service.instance_id == 0
        || scope.service.generation == 0
        || scope.epoch == [0; 3]
        || owner.instance_id == 0
        || owner.generation == 0
        || owner.reserved != 0
        || intent == [0; 3]
        || path.is_empty()
        || path.len() >= 160
        || bytes.is_empty()
        || bytes.len() > a::desktop_link_max_bytes as usize
        || path.contains(&0)
        || bytes.contains(&0)
    {
        return Err(Error::Raw(a::desktop_link_result_invalid));
    }
    let mut q = LinkRequest {
        token: LinkToken {
            service: scope.service,
            owner,
            epoch: scope.epoch,
            intent,
            ..Default::default()
        },
        deadline,
        link_length: bytes.len() as u32,
        ..Default::default()
    };
    q.link_path[..path.len()].copy_from_slice(path);
    q.link_bytes[..bytes.len()].copy_from_slice(bytes);
    Ok(q)
}
impl Services<'_> {
    fn link_call(&self, op: u16, request: &LinkRequest) -> Result<LinkReply> {
        let mut connection = self.open(c"WINSVC")?;
        // Request is a pointer-free fixed record with every byte occupied by
        // initialized scalar/array fields (including nested explicit padding).
        let bytes = unsafe {
            core::slice::from_raw_parts(
                core::ptr::from_ref(request).cast(),
                mem::size_of::<LinkRequest>(),
            )
        };
        let mut out = [0; mem::size_of::<LinkReply>()];
        let count = match connection.call(op, bytes, &mut out, Timeout::AfterNanos(500_000_000))? {
            Call::Response { bytes, .. } => bytes,
            Call::TimedOut => return Err(Error::Raw(a::service_api_result_timeout)),
            Call::RemoteFailure(code) => return Err(Error::Raw(code)),
        };
        if count != out.len() {
            return Err(Error::InvalidProvider);
        }
        let reply = unsafe { core::ptr::read_unaligned(out.as_ptr().cast::<LinkReply>()) };
        if reply.request.token.version != 1
            || reply.request.token.size as usize != mem::size_of::<LinkToken>()
            || reply.request.link_length > a::desktop_link_max_bytes
            || reply.phase > a::desktop_link_phase_expired
            || reply.result > 0
            || reply.result < a::desktop_link_result_unavailable
        {
            return Err(Error::InvalidProvider);
        }
        if op != a::desktop_link_op_scope {
            let mut expected = *request;
            expected.token.serial = reply.request.token.serial;
            let actual = unsafe {
                core::slice::from_raw_parts(
                    core::ptr::from_ref(&reply.request).cast::<u8>(),
                    mem::size_of::<LinkRequest>(),
                )
            };
            let expected_bytes = unsafe {
                core::slice::from_raw_parts(
                    core::ptr::from_ref(&expected).cast::<u8>(),
                    mem::size_of::<LinkRequest>(),
                )
            };
            if (request.token.serial != 0 && request.token.serial != reply.request.token.serial)
                || actual != expected_bytes
            {
                return Err(Error::InvalidProvider);
            }
        }
        Ok(reply)
    }
    pub fn link_scope(&self) -> Result<LinkReply> {
        self.link_call(a::desktop_link_op_scope, &LinkRequest::default())
    }
    pub fn link_prepare(&self, request: &LinkRequest) -> Result<LinkReply> {
        self.link_call(a::desktop_link_op_prepare, request)
    }
    pub fn link_activate(&self, saved: &LinkRequest) -> Result<LinkReply> {
        self.link_call(a::desktop_link_op_activate, saved)
    }
    pub fn link_status(&self, saved: &LinkRequest) -> Result<LinkReply> {
        self.link_call(a::desktop_link_op_status, saved)
    }
    pub fn link_release(&self, saved: &LinkRequest) -> Result<LinkReply> {
        self.link_call(a::desktop_link_op_release, saved)
    }
}
