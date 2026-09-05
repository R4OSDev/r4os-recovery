R4OS ABI
========

Scope
-----

The files in this directory define the binary boundaries between R4M0
modules, programs, Runtime-R4Ls, and the kernel. The target is little-endian
x86_64 with 8-byte pointers and the C calling convention.

Contracts
---------

R4M0.txt
  Shared container format for R4X, R4L, R4D, and R4P.

R4XStart.txt
  R4X program entry point, startup context, and imported platform tables.

SubsystemLaunch.txt
  Versioned length-coded guest path and option payload layered on R4X args.

R4LQuery.txt
  Generic query export of an R4L module.

R4LInterface.txt
  Versioned table header for independent named Runtime-R4Ls.

R4DDriver.txt
  Owner-bound segment-DMA and asynchronous storage request lifetimes.

Platform tables
---------------

R4SYS, R4DESK, R4DRAW, R4NET, R4AUDIO, and R4DEV begin with magic, ABI
version, size, and flags. Function pointers and reserved slots follow in a
fixed order. Current values and fields are generated from API/ApiContract.json
into Generated/Docs/API.

A named Runtime-R4L has no central kernel table. It returns its
library-owned, versioned function table through the shared query and interface
mechanism.

Compatibility rules
-------------------

- Existing tables grow only at the end.
- Reserved or tombstoned slots are never silently repurposed.
- Fixed-layout types are never extended in place.
- Extensible types follow their version and size contract.
- Zig and C projections remain binary-identical.

Validation
----------

    zig build check
    zig build test

Generated package sources, layout assertions, and conformance fixtures are
versioned under Generated.
