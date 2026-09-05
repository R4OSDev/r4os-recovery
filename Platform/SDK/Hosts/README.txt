R4OS SDK Host Profiles
======================

Shared contains the common SDK core for the R4OS x86_64 target: bindings,
headers, startup stubs, linker profiles, templates, and build profiles.

Hosts contains host-specific wrappers only. A host is the environment that
runs the build, not the R4OS target system.

Profiles:

- Windows: external host for R4CodePad and local Zig builds.
- Linux: external host using the same SDK core.
- R4OS: future native package for an IDE running inside R4OS.

The separate Contract repository remains the API and ABI source of truth.
Host profiles may configure paths and tools but never define a second ABI.
