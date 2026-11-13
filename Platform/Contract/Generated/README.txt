Generated Contract Artifacts
============================

Except for this overview, every file below this directory is generated
deterministically from the canonical API/ApiContract.json and
API/Generation2.json. Generated blocks are not edited manually. The shared
technical facade outside its marked block follows the documented owner rule.

Generation2
  Independent current Query2/Start2 roots,533 slots, typed C/Zig/Rust
  signatures and table headers. Current technical records are materialized
  directly into SDK/Zig/technical2_generated.zig from Generation2.json.
  SDK/C and SDK/Rust reflect those same types.

During the provider/SDK cutover only, the base SDK/Kernel bindings retain a
reverse compatibility view derived from the current schema and four inert
LegacyProjection.json holes. Current providers never read that old table.

SDK/Zig
  Complete Zig ABI and its export-only package.

SDK/C/include/r4os
  Complete C ABI header.

Kernel/Zig
  Complete kernel ABI with typed provider builders and export package.

Groups
  Current Query2 and identity constants for the six platform groups.

Conformance
  Zig and C compile fixtures generated from the same schema.

Docs and Inventory
  Human-readable tables, semantic and parity reports, and machine inventory.

zig build check compares every file byte-for-byte. Use zig build write only
after an intentional schema change.
