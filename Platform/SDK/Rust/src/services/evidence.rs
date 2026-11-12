//! Persist intent before reserve, serial before offer, and the canonical token
//! before ACK. Resume/status never Retain, Spawn, ACK or consume Desktop reap.
use super::{Call, Services};
use crate::{
    abi,
    resources::Timeout,
    storage::{Error, Result},
};
use core::mem;

pub type EvidenceToken = abi::DesktopEvidenceToken;
pub type EvidenceReply = abi::DesktopEvidenceReply;

fn same_process(a: abi::ProgramProcessHandle, b: abi::ProgramProcessHandle) -> bool {
    a.instance_id == b.instance_id && a.reserved == b.reserved && a.generation == b.generation
}
fn valid_process(p: abi::ProgramProcessHandle) -> bool {
    p.instance_id != 0 && p.reserved == 0 && p.generation != 0
}
pub fn prepare_evidence(
    scope: EvidenceToken,
    request: abi::ProgramProcessHandle,
    intent: [u64; 3],
) -> Result<EvidenceToken> {
    if scope.version != 1
        || scope.size as usize != mem::size_of::<EvidenceToken>()
        || !valid_process(scope.broker)
        || !valid_process(request)
        || scope.epoch == [0; 3]
        || intent == [0; 3]
    {
        return Err(Error::Raw(abi::desktop_evidence_result_invalid));
    }
    Ok(EvidenceToken {
        broker: scope.broker,
        request,
        epoch: scope.epoch,
        intent,
        ..Default::default()
    })
}

impl Services<'_> {
    fn evidence_call(
        &self,
        op: u16,
        request: abi::DesktopEvidenceRequest,
        out: &mut [u8],
    ) -> Result<EvidenceReply> {
        let name = c"WINSVC";
        let mut connection = self.open(name)?;
        let mut buffer = [0u8; abi::service_api_max_payload];
        let request_bytes = unsafe {
            core::slice::from_raw_parts(
                core::ptr::from_ref(&request).cast(),
                mem::size_of_val(&request),
            )
        };
        let bytes = match connection.call(
            op,
            request_bytes,
            &mut buffer,
            Timeout::AfterNanos(500_000_000),
        )? {
            Call::Response { bytes, .. } => bytes,
            Call::TimedOut => return Err(Error::Raw(abi::service_api_result_timeout)),
            Call::RemoteFailure(code) => return Err(Error::Raw(code)),
        };
        if bytes < mem::size_of::<EvidenceReply>() {
            return Err(Error::InvalidProvider);
        }
        let reply = unsafe { core::ptr::read_unaligned(buffer.as_ptr().cast::<EvidenceReply>()) };
        if reply.token.version != 1
            || reply.token.size as usize != mem::size_of::<EvidenceToken>()
            || reply.phase > abi::desktop_evidence_phase_unavailable
            || reply.result > 0
            || reply.result < abi::desktop_evidence_result_released
            || reply.data_bytes as usize > out.len()
            || bytes != mem::size_of::<EvidenceReply>() + reply.data_bytes as usize
        {
            return Err(Error::InvalidProvider);
        }
        if op != abi::desktop_evidence_op_scope
            && (!same_process(reply.token.broker, request.token.broker)
                || !same_process(reply.token.request, request.token.request)
                || reply.token.epoch != request.token.epoch
                || reply.token.intent != request.token.intent
                || (request.token.serial != 0 && reply.token.serial != request.token.serial)
                || (valid_process(request.token.process)
                    && !same_process(reply.token.process, request.token.process))
                || (valid_process(request.token.desktop)
                    && !same_process(reply.token.desktop, request.token.desktop)))
        {
            return Err(Error::InvalidProvider);
        }
        out[..reply.data_bytes as usize]
            .copy_from_slice(&buffer[mem::size_of::<EvidenceReply>()..bytes]);
        Ok(reply)
    }
    pub fn evidence_scope(&self) -> Result<EvidenceReply> {
        self.evidence_call(abi::desktop_evidence_op_scope, Default::default(), &mut [])
    }
    pub fn evidence_reserve(&self, intent: EvidenceToken) -> Result<EvidenceReply> {
        if intent.serial != 0 {
            return Err(Error::Raw(abi::desktop_evidence_result_invalid));
        }
        self.evidence_call(
            abi::desktop_evidence_op_reserve,
            abi::DesktopEvidenceRequest {
                token: intent,
                ..Default::default()
            },
            &mut [],
        )
    }
    fn evidence_mutate(&self, op: u16, token: EvidenceToken) -> Result<EvidenceReply> {
        if token.serial == 0 {
            return Err(Error::Raw(abi::desktop_evidence_result_invalid));
        }
        self.evidence_call(
            op,
            abi::DesktopEvidenceRequest {
                token,
                ..Default::default()
            },
            &mut [],
        )
    }
    pub fn evidence_offer(&self, token: EvidenceToken) -> Result<EvidenceReply> {
        self.evidence_mutate(abi::desktop_evidence_op_offer, token)
    }
    pub fn evidence_acknowledge(&self, token: EvidenceToken) -> Result<EvidenceReply> {
        self.evidence_mutate(abi::desktop_evidence_op_ack, token)
    }
    pub fn evidence_status(&self, token: EvidenceToken) -> Result<EvidenceReply> {
        self.evidence_call(
            abi::desktop_evidence_op_status,
            abi::DesktopEvidenceRequest {
                token,
                ..Default::default()
            },
            &mut [],
        )
    }
    pub fn evidence_read(
        &self,
        token: EvidenceToken,
        offset: u32,
        out: &mut [u8],
    ) -> Result<EvidenceReply> {
        if out.is_empty() || out.len() > abi::desktop_evidence_max_output_chunk as usize {
            return Err(Error::Raw(abi::desktop_evidence_result_invalid));
        }
        self.evidence_call(
            abi::desktop_evidence_op_read,
            abi::DesktopEvidenceRequest {
                token,
                offset,
                capacity: out.len() as u32,
            },
            out,
        )
    }
    pub fn evidence_release(&self, token: EvidenceToken) -> Result<EvidenceReply> {
        self.evidence_mutate(abi::desktop_evidence_op_release, token)
    }
    /// Adoption creates no kernel reference. The broker validates the saved
    /// epoch on every use, including after numeric process IDs repeat at boot.
    pub fn adopt_evidence(&self, token: EvidenceToken) -> EvidenceLease<'_> {
        EvidenceLease {
            owner: self,
            token,
            owned: true,
        }
    }
}

#[must_use = "release the evidence lease or export its persisted token"]
pub struct EvidenceLease<'a> {
    owner: &'a Services<'a>,
    token: EvidenceToken,
    owned: bool,
}
impl EvidenceLease<'_> {
    pub fn token(&self) -> EvidenceToken {
        self.token
    }
    pub fn status(&self) -> Result<EvidenceReply> {
        self.owner.evidence_status(self.token)
    }
    pub fn read(&self, offset: u32, out: &mut [u8]) -> Result<EvidenceReply> {
        self.owner.evidence_read(self.token, offset, out)
    }
    pub fn export(mut self) -> EvidenceToken {
        self.owned = false;
        self.token
    }
    pub fn close(&mut self) -> Result<EvidenceReply> {
        if !self.owned {
            return Err(Error::Raw(abi::err_not_owned));
        }
        let reply = self.owner.evidence_release(self.token)?;
        if matches!(
            reply.result,
            abi::desktop_evidence_result_released
                | abi::desktop_evidence_result_expired
                | abi::desktop_evidence_result_unknown
                | abi::desktop_evidence_result_stale
        ) {
            self.owned = false;
        }
        Ok(reply)
    }
}
impl Drop for EvidenceLease<'_> {
    fn drop(&mut self) {
        if self.owned {
            let _ = self.close();
        }
    }
}
