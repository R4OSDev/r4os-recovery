R4ENC Runtime-R4L API
=====================

Independent bounded video encoder. Software compression/native encoding, stream rate policy and packet ownership stay in this library; image production, clocks, presentation and network keep their owners.

ENCODE_V1
---------

Independent asynchronous image-to-bitstream API with physical input retirement and immutable output leases.

- ELF-Symbol: `r4enc_encode_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x313045444f434e45:0x313030434e453452`
- Tabellengroesse: 104 Byte

- Slot 0, Offset 32: `open` - Bind real process/platform providers and finite runtime budget; does not activate an encoder.
  Semantik: may_block, handle_serialized, not_reentrant; Fehlerdomaene `R4ENC`; Besitz: Caller serializes each owner; independent streams may progress concurrently. Providers remain loaded through final retirement acknowledgement..
- Slot 1, Offset 40: `query_caps` - Query actual implemented profile and backend. Unsupported never silently selects software.
  Semantik: may_block, handle_serialized, not_reentrant; Fehlerdomaene `R4ENC`; Besitz: Caller serializes each owner; independent streams may progress concurrently. Providers remain loaded through final retirement acknowledgement..
- Slot 2, Offset 48: `create` - Reserve budgets and create one asynchronous stream outside paint or input handling.
  Semantik: may_block, handle_serialized, not_reentrant; Fehlerdomaene `R4ENC`; Besitz: Caller serializes each owner; independent streams may progress concurrently. Providers remain loaded through final retirement acknowledgement..
- Slot 3, Offset 56: `send` - Accept exactly one immutable image loan; AGAIN/error accepts nothing. Never encode or wait for GPU in this call.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4ENC`; Besitz: Caller serializes each owner; independent streams may progress concurrently. Providers remain loaded through final retirement acknowledgement..
- Slot 4, Offset 64: `receive` - Acquire the next completion packet; AGAIN means none ready, EOS follows completed Drain and output exhaustion. Failure leaves output unchanged.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4ENC`; Besitz: Caller serializes each owner; independent streams may progress concurrently. Providers remain loaded through final retirement acknowledgement..
- Slot 5, Offset 72: `release` - Release immutable packet storage after readers finish. Pending release keeps the exact token for retry; acknowledged tokens must not be retried after slot reuse.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4ENC`; Besitz: Caller serializes each owner; independent streams may progress concurrently. Providers remain loaded through final retirement acknowledgement..
- Slot 6, Offset 80: `control` - Queue/query Drain, Abort or Close. Query creates no work; workers retire inputs/resources. Close never revokes leased packets.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4ENC`; Besitz: Caller serializes each owner; independent streams may progress concurrently. Providers remain loaded through final retirement acknowledgement..
- Slot 7, Offset 88: `destroy` - Remove an acknowledged closed owner only after worker and packet retirement. BUSY retains the handle.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4ENC`; Besitz: Caller serializes each owner; independent streams may progress concurrently. Providers remain loaded through final retirement acknowledgement..
- Slot 8, Offset 96: `finish` - After encoder destruction, stop/join runtime workers and release process-local state. Finite timeout preserves an unfinished owner for retry.
  Semantik: may_block, handle_serialized, not_reentrant; Fehlerdomaene `R4ENC`; Besitz: Caller serializes each owner; independent streams may progress concurrently. Providers remain loaded through final retirement acknowledgement..

Typen
-----

- `R4EncRuntime`: 16 Byte, Alignment 8. Process-local owner. The provider remains loaded through acknowledged destruction.
- `R4EncEncoder`: 16 Byte, Alignment 8. Process-local owner. The provider remains loaded through acknowledged destruction.
- `R4EncStartup`: 32 Byte, Alignment 8. Copied runtime policy; opening alone creates no encode work.
- `R4EncCapsQuery`: 32 Byte, Alignment 4. Query an implemented profile and its actual backend admission.
- `R4EncCaps`: 104 Byte, Alignment 8. Capability is implementation admission, never physical encoder qualification.
- `R4EncRate`: 48 Byte, Alignment 8. Copied immutable rate policy. Quality/performance presets are not guessed from vendor SDK names.
- `R4EncBuffer`: 16 Byte, Alignment 8. ABI-compatible view of a common graphics BO/reference handle, not a CPU address.
- `R4EncFence`: 40 Byte, Alignment 8. Canonical common queue fence layout. All-zero means no consumer GPU submission; any nonzero value must be exact.
- `R4EncColor`: 48 Byte, Alignment 4. Immutable stream color metadata. Conversion, scaling and output color policy belong to R4GFX/Desktop.
- `R4EncPlane`: 64 Byte, Alignment 8. Input view validated against the actual BO descriptor. Never infer linear storage from pitch.
- `R4EncConfig`: 192 Byte, Alignment 8. Create reserves all finite budgets. Revision1 uses one encode worker per stream and no B-frame reorder. Reconfigure by closing and opening at a new IDR.
- `R4EncFrame`: 288 Byte, Alignment 8. Send copies metadata and retains deduplicated BO references. Caller keeps all pixels immutable until receive returns the matching completion or control confirms all prior inputs retired.
- `R4EncLease`: 32 Byte, Alignment 8. Immutable process-local output lease. A control request never revokes a delivered packet.
- `R4EncPacket`: 96 Byte, Alignment 8. Receive returns accepted inputs in encode order after physical input retirement. Only compressed output is made CPU-readable in a native path; no full-image readback.
- `R4EncControl`: 24 Byte, Alignment 8. Nonblocking request acceptance is distinct from completion. Abort cancels unstarted inputs, retires active work and starts a new stream generation at an IDR.
- `R4EncState`: 96 Byte, Alignment 8. Read-only progress. Drain preserves outputs and ends in EOS. Abort/Close discard unleased output, but retain externally delivered packets through release.

Besitzregeln
------------

- Immutable input: Send success retains metadata and common BO references. Source pixels and the producer fence remain immutable until the matching receive receipt or completed Abort/Close. Busy/error accepts nothing.
- Physical completion: Logical timeout/cancel never frees active GPU resources. Input receipt follows engine and mapping retirement; packet and provider lifetimes remain reachable on errors.
- Output ownership: Receive supplies one complete access unit or an explicit skipped-input receipt. Data is read-only until release. Delivered leases survive Abort and Close.
- Backpressure: Queues and byte budgets are finite. Consumer chooses frames to omit before Send; no silent replacement of an accepted input. Slow output never blocks local presentation.
- Control identity: Strictly increasing mutation IDs; identical pending retries do not repeat work. Accepted differs from completed. Abort/Close may supersede pending Drain, and Close may supersede Abort. Retrying a superseded ID returns CANCELLED or STALE, never success. Abort advances generation only after old inputs retire; first new input is IDR.
- Errors: A failed control preserves the old stream generation. Close/release/query remain possible. Failed encode never publishes partial bytes as success.
- Media time: PTS/duration belong to the caller timeline. Revision1 has no B-frame reorder. No wall clock, hidden frame scheduler or network transport exists inside the encoder.
- Format and color: Canonical BO descriptors retain placement, modifier and device epoch. Explicit CICP metadata is immutable per stream; unknown or unsupported color/layout is rejected.
- Activation: Opening a runtime or querying capabilities produces no encode work. Only explicit accepted frame input in an admitted encoder may activate the engine.
- Implementation status: This is the 0.79.41 implementation target. Generated contracts do not imply a working codec or physical qualification.
