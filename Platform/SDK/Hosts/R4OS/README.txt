R4OS SDK Native Host Profile
============================

This profile is the minimal future SDK package for an IDE running inside
R4OS. It is limited to the material R4OS needs to edit, build, and install
modules:

- Contract snapshots;
- headers and Zig bindings;
- startup stubs;
- linker profiles;
- R4M0 packaging rules;
- templates and small examples.

Windows or Linux scripts, QEMU configuration, push helpers, and local build
caches do not belong in this profile.
