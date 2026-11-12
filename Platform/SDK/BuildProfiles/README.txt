R4OS SDK Build Profiles
=======================

These files describe installable build profiles for R4OS-internal tools such
as R4CODE and R4BUILD.

Profiles are not a second ABI definition. They point to the installed SDK and
Contract under C:/R4OS/SDK; the separate Contract repository remains the API
and ABI source of truth.

Current internal C profiles include:

  R4X_C_Console
  R4X_C_Desktop_OK

R4X_C_Desktop_OK builds a GUI R4X with R4SYS, R4DESK, and R4DRAW imports and
AppClass gui. R4X_C remains readable for external R4CodePad compatibility,
while internal builds use the more precise profiles.

AVX2 is part of the standard SIMD profile for R4X, R4D, and R4P artifacts
when R4OS enables the x87, SSE, and YMM XSAVE state. These profiles do not
provide an SSE-only or soft-float fallback.

Host-only Rust lowlevel R4X uses r4os-rust-r4x-lowlevel-v1, explicitly declared
as ENTRY_MODE=lowlevel when maintaining an existing generation1 project.
New executable templates explicitly select the matching generation2 SDK
profile and real R4XStart2, DriverInit2 or ProtocolInit2 entry. The Rust raw
generation2 entry receives platform2::Context; lowlevel_context2! explicitly
opts into App2 helpers and initialize_runtime2 installs the optional heap.
console/gui/service retain their real launch policies. The Rust backend policy
in r4os/rust_module_profile.json stays target-default integer codegen under the
current pinned compiler; the AVX2 hardware/native C/Zig baseline above remains.
Native R4CC is still its bounded one-source app console/gui subset. There is no
native Zig or Rust compiler/profile implied by host language parity.

R4X_C2, R4X_C2_Console and R4X_C2_Desktop_OK describe the installed raw C2
startup/header/linker contract. Their startup expects r4_main2 and generated
R4OS2_STARTUP_INFO; normal app2 startup uses the complete generated manifest
facts and r4_app_main instead. Native R4BUILD/R4CC consumer qualification is
separate from shipping these assets and remains migration0.90.72. The
capability catalog reports native-generation2-consumer-pending until then.
Legacy profile names remain explicit during the controlled transition.
