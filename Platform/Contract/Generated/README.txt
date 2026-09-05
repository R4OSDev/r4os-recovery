Generated Contract Artifacts
============================

Except for this overview, every file below this directory is generated
deterministically from API/ApiContract.json and must not be edited manually.

SDK/Zig
  Complete Zig ABI and its export-only package.

SDK/C/include/r4os
  Complete C ABI header.

Kernel/Zig
  Complete kernel ABI with typed provider builders and export package.

Groups
  Query and identity constants for the six platform groups.

Conformance
  Zig and C compile fixtures generated from the same schema.

Docs and Inventory
  Human-readable tables, semantic and parity reports, and machine inventory.

zig build check compares every file byte-for-byte. Use zig build write only
after an intentional schema change.
