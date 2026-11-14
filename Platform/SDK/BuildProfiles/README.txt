R4OS SDK Build Profiles
=======================

These files describe installed native build profiles for R4CODE/R4BUILD.
Profiles/Build.json owns host compiler and component selection; Contract
owns the ABI. The installed SDK and Contract live below C:/R4OS/SDK.

Current native C profiles are R4X_C2, R4X_C2_Console and
R4X_C2_Desktop_OK. They select actual R4XStart2:2, R4XStartContext2 and
explicit Query2:2 imports. The GUI profile requires R4SYS/R4DESK/R4DRAW.
The raw C2 startup expects r4_main2 and generated R4OS2_STARTUP_INFO;
normal App2 startup uses r4_app_main and complete ordered manifest facts.
Native R4CC retains its bounded one-source C console/GUI subset.

R4CP can read historical source metadata for diagnosis/conversion. That
does not admit retired profiles or silently replace historical imports.
Current validation rejects an incompatible manifest before persistence.

Host Zig/C/Rust module profiles select generation2, including lowlevel,
R4L, R4D and R4P. A raw Rust entry borrows platform2::Context;
lowlevel_context2! and initialize_runtime2 opt into App2/runtime helpers.
Console/GUI/service launch rules and independent library APIs remain.
The removed generation1 host/native profiles have no positive build path.

AVX2 remains the native C/Zig module baseline when the required XSTATE is
enabled. Rust uses its pinned target-default integer backend policy from
r4os/rust_module_profile.json. No native Zig/Rust compiler, Windows run or
physical hardware qualification follows from these installed profiles.
