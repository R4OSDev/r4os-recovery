# R4OS Platform Contract

This repository is the canonical API and ABI definition for the R4OS platform.
It contains the R4M0 container contract, shared layouts and error codes,
platform API groups, generated bindings, conformance fixtures, and the
contract generator.

Optional Runtime-R4L APIs are intentionally not defined here; each independent
library owns its own contract and bindings.

## Build and validation

With the configured Zig toolchain on every supported host:

    zig build test

Generated files are checked during normal builds. Intentional contract changes
must use the repository's explicit generator write workflow and update the
matching baseline.

Detailed German migration notes are preserved in
`DOCUMENTATION.de.txt`.

DriverApi v24 and NetBackend v2 provide append-only network capability
selection. Every packet descriptor retains canonical flat fallback bytes;
the current single-queue implementation admits only validated RX TCP/UDP
checksums and rejects all other optional offloads explicitly.

## License

Original R4OS material is licensed under Apache License 2.0. See `LICENSE`,
`NOTICE`, and `THIRD_PARTY_NOTICES.md`.
