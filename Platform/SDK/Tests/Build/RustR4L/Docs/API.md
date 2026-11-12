L66R Runtime-R4L API
====================

Own synthetic genuine Rust R4L implementation; uses explicit caller memory/callbacks.

API_V1
------

Same interface in both language implementations; normal exact module identity remains distinct.

- ELF-Symbol: `l66r_api_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x53444b36:0x4c363631`
- Tabellengroesse: 56 Byte

- Slot 0, Offset 32: `open` - Caller serializes work. Callback close returns Busy while work owns the session. Failed release retains the exact active allocation.
  Semantik: may_block, handle_serialized, reentrant; Fehlerdomaene `provider status:0 success,-1 invalid,-2 busy,-3 stale/callback,-4 allocation/release`; Besitz: caller_session.
- Slot 1, Offset 40: `work` - Caller serializes work. Callback close returns Busy while work owns the session. Failed release retains the exact active allocation.
  Semantik: may_block, handle_serialized, reentrant; Fehlerdomaene `provider status:0 success,-1 invalid,-2 busy,-3 stale/callback,-4 allocation/release`; Besitz: caller_session.
- Slot 2, Offset 48: `close` - Caller serializes work. Callback close returns Busy while work owns the session. Failed release retains the exact active allocation.
  Semantik: may_block, handle_serialized, reentrant; Fehlerdomaene `provider status:0 success,-1 invalid,-2 busy,-3 stale/callback,-4 allocation/release`; Besitz: caller_session.

Typen
-----

- `R4L66State`: 72 Byte, Alignment 8. Caller-owned state, exact generation, owned allocation and resident callbacks. No library-global caller state.

Besitzregeln
------------

- caller_session: Caller allocates state and supplies its own allocator/release/notify callbacks and owner context. Exact nonzero generation, callback addresses and state stay resident through real close. Library retains no caller-global state or R4X-global heap; failed release keeps admission/resource ownership. No Rust mutable reference crosses callbacks.
