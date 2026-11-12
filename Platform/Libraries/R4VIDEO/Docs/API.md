R4VIDEO Runtime-R4L API
=======================

Independent asynchronous compressed-video decoder ownership. Packet parsing and DPB stay in R4VIDEO; GPU execution and composition keep their existing owners.

VIDEO_V1
--------

Asynchronous, generation-safe compressed-video API. This interface revision is independent of admitted codec profiles.

- ELF-Symbol: `r4video_video_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x313045444f434544:0x314f454449563452`
- Tabellengroesse: 104 Byte

- Slot 0, Offset 32: `open` - Bind actual process/platform providers. Creates bounded runtime ownership; no GPU/decoder admission yet.
  Semantik: may_block, caller_serialized, not_reentrant; Fehlerdomaene `R4VIDEO`; Besitz: Caller serializes operations on each owner; different decoder owners may run concurrently. Keep this R4L and all referenced platform/backend providers loaded through final acknowledgement..
- Slot 1, Offset 40: `query_caps` - Query actual installed codec/backend limits; unsupported never falls back implicitly.
  Semantik: may_block, handle_serialized, not_reentrant; Fehlerdomaene `R4VIDEO`; Besitz: Caller serializes operations on each owner; different decoder owners may run concurrently. Keep this R4L and all referenced platform/backend providers loaded through final acknowledgement..
- Slot 2, Offset 48: `create` - Copy immutable admission and reserve budgets; worker and codec allocation may block. Initial stream generation is 1.
  Semantik: may_block, handle_serialized, not_reentrant; Fehlerdomaene `R4VIDEO`; Besitz: Caller serializes operations on each owner; different decoder owners may run concurrently. Keep this R4L and all referenced platform/backend providers loaded through final acknowledgement..
- Slot 3, Offset 56: `send` - Copy one complete compressed access unit into a bounded queue. Does not decode or wait for GPU; zero-copy ownership is not implied.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4VIDEO`; Besitz: Caller serializes operations on each owner; different decoder owners may run concurrently. Keep this R4L and all referenced platform/backend providers loaded through final acknowledgement..
- Slot 4, Offset 64: `receive` - Acquire next successfully decoded frame in display order. AGAIN means no ready output; EOS only after Drain and queued output exhaustion. Outputs unchanged on failure.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4VIDEO`; Besitz: Caller serializes operations on each owner; different decoder owners may run concurrently. Keep this R4L and all referenced platform/backend providers loaded through final acknowledgement..
- Slot 5, Offset 72: `release` - Return exact lease after last use. AGAIN retains immutable receipt/fence ownership; retry unchanged until OK. Acknowledged tokens are idempotent until their slot is reused; later retries are STALE and cannot release another frame.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4VIDEO`; Besitz: Caller serializes operations on each owner; different decoder owners may run concurrently. Keep this R4L and all referenced platform/backend providers loaded through final acknowledgement..
- Slot 6, Offset 80: `control` - Query/queue Drain, Flush or Close. Query creates no progress itself. Worker owns retirement. Close does not destroy the decoder handle; destroy follows completed Close.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4VIDEO`; Besitz: Caller serializes operations on each owner; different decoder owners may run concurrently. Keep this R4L and all referenced platform/backend providers loaded through final acknowledgement..
- Slot 7, Offset 88: `destroy` - Remove a closed decoder only after worker quiescence and every frame receipt. BUSY retains owner for retry; successful removal makes the handle stale.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4VIDEO`; Besitz: Caller serializes operations on each owner; different decoder owners may run concurrently. Keep this R4L and all referenced platform/backend providers loaded through final acknowledgement..
- Slot 8, Offset 96: `finish` - After all decoder handles are destroyed, stop/join runtime workers and retire native state. BUSY retains ownership for retry; success closes the runtime permanently.
  Semantik: may_block, handle_serialized, not_reentrant; Fehlerdomaene `R4VIDEO`; Besitz: Caller serializes operations on each owner; different decoder owners may run concurrently. Keep this R4L and all referenced platform/backend providers loaded through final acknowledgement..

Typen
-----

- `R4VideoRuntime`: 16 Byte, Alignment 8. Exact process/provider-local owner. Keep the R4L provider loaded through destruction.
- `R4VideoDecoder`: 16 Byte, Alignment 8. Exact process/provider-local owner. Keep the R4L provider loaded through destruction.
- `R4VideoStartup`: 32 Byte, Alignment 8. Copied startup configuration; application and imported provider generations remain alive through finish.
- `R4VideoCapsQuery`: 32 Byte, Alignment 4. Query an installed implementation and its current backend admission; no decoder allocation.
- `R4VideoCaps`: 104 Byte, Alignment 8. Only an installed, admitted codec profile returns success. Declaration is not a physical hardware qualification.
- `R4VideoConfig`: 72 Byte, Alignment 8. Create an asynchronous decoder. Dimension changes within limits use the same stream; unsupported changes report an error instead of corrupting old leases.
- `R4VideoPacket`: 72 Byte, Alignment 8. Input is never retained as a borrowed pointer. AGAIN accepts nothing; OK accepts the entire unit exactly once. PTS may differ from decode order.
- `R4VideoBuffer`: 16 Byte, Alignment 8. ABI-compatible view of a common graphics BO/reference handle, not a CPU address.
- `R4VideoFence`: 40 Byte, Alignment 8. Canonical common queue fence layout. All-zero means no consumer GPU submission; any nonzero value must be exact.
- `R4VideoPlane`: 64 Byte, Alignment 8. A plane view checked against the real BO descriptor. Multiple planes may share one reference; the enclosing frame owns the deduplicated loan.
- `R4VideoColor`: 48 Byte, Alignment 4. Copied per-frame color metadata. Conversion, scaling and output color policy belong to R4GFX/Desktop.
- `R4VideoLease`: 32 Byte, Alignment 8. Exact consumer acquisition; storage stays owned until release acknowledges it. Not invalidated by seek alone.
- `R4VideoFrame`: 400 Byte, Alignment 8. Receive transfers one output lease in display/reorder order; failed or concealed-corrupt pictures are not reported as successful outputs. No mandatory CPU color conversion.
- `R4VideoReceipt`: 56 Byte, Alignment 8. Call only after ending CPU mappings/readers and submitting the final GPU use. A pending release retains this exact immutable receipt for retries.
- `R4VideoControl`: 24 Byte, Alignment 8. Nonblocking control. Accepted mutation is not completion; query state until completed_request equals request_id. Conflicts while another operation is pending return BUSY.
- `R4VideoState`: 64 Byte, Alignment 8. Copied progress snapshot. Drain preserves reordered outputs; Flush discards unleased old outputs, resets parser/DPB and rejects stale-generation inputs. Close retains storage until all leases/worker resources retire.

Besitzregeln
------------

- Runtime lifetime: All state belongs to the actual caller process and this loaded provider generation. No singleton decoder, global caller budget or ambient desktop dependency.
- Backpressure: Queues and packet sizes are finite. Send success accepts the complete copied unit; AGAIN or error accepts nothing. Receive follows codec display order, never blindly input/DTS order.
- Frame lifetime: DPB references, in-flight GPU work and consumer loans are independent. Flush/Close never revoke a delivered frame. The producer holds BOs and completion metadata until exact release acknowledgement.
- Clock ownership: PTS/DTS are media timeline values, not wall-clock ticks. Decode runs asynchronously; the media host schedules presentation/audio and owns pause/seek clock changes.
- Controls: Monotone request IDs make Drain/Flush/Close retries idempotent. Accepted is not completed. Flush advances stream generation only once after old work ends; Close retains the handle until explicit destroy.
- Graphics ownership: Frame layouts reuse common BO/fence identities. R4GFX/Desktop owns YUV conversion, scaling, colorspace and output; native decode does not require a CPU RGB copy.
- Incomplete implementation: This contract is the 0.79.40 implementation target. Generating bindings or passing ABI checks does not enable any decoder or constitute software/hardware acceptance.
- Canonical storage: Each plane is a view of the queried canonical BO descriptor, including its modifier, extent, placement and device lifetime. Pitch alone never implies linear CPU access. Unknown layouts are unsupported; a renderer must not reinterpret them.
- Failed controls: Flush completes successfully only after prior work retires and stream_generation advances once. A failed Flush leaves the old generation and phase_failed; only query, release, Close and destroy remain legal. Close completion includes all worker and lease retirement. Query is allowed until destroy.
- Acknowledgement retention: Release retries retain the exact immutable receipt until OK. Idempotence is guaranteed while that acknowledged slot has not been reused. After reuse an old token returns STALE and cannot affect a new lease. Never retry a successfully acknowledged token after acquiring another frame.
- Color provenance: CICP primaries, transfer and matrix preserve the signaled stream values. Unknown values remain unspecified; unsupported known values must not silently become sRGB, BT.709 or HDR. Range, chroma siting and coded/crop geometry are independent metadata.
