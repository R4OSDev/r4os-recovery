R4OS SDK templates (SDK0.64.89)
===============================

The two native C definitions in this directory remain R4CODE/R4BUILD inputs:
R4OS.R4X_C_Console and R4OS.R4X_C_Desktop_OK. Their compiler is the native
R4CC subset, independent from the host SDK toolchains.

The complete host inventory is compiler-free capability schema3:
  module-catalog capabilities --json --profile /TOOLS/RustToolsProfile.json
There is one file map for each supported combination of Zig/C/Rust with
app/lowlevel console/gui/service, app/lowlevel GUI subsystem, R4L, R4D and R4P.
Existing public IDs for the three Rust app templates, host C/Zig consoles
and local R4L templates remain. Host, R4L, R4X and R4OS folders are SDK-owned
source groupings; consumers use stable IDs and the declared complete file map.

Create a NEW project with explicit matched components:
  ./Tools/New-Project.sh -TemplateId R4OS.Host_C_Console -Directory /project -ContractRoot /CONTRACT -ToolsRoot /TOOLS
  ./Tools/New-RustProject.sh -TemplateId R4OS.R4X_Rust_Console -Directory /rust-project -ContractRoot /CONTRACT -ToolsRoot /TOOLS
ProjectName is optional. SDK resolves from the creator's own location unless
SdkRoot is supplied. Native-only IDs are consumed by R4CODE/R4BUILD instead.
The common creator refuses an existing directory. R4L creation generates only
that new library's own baseline/bindings/conformance/docs with the matched
contract generator; Rust R4L additionally needs the selected installed Cargo
toolset for its locked offline local graph. Later baseline changes are explicit.

Build.sh/.bat are thin starters for the same Build.ps1. Pass SDK/Contract/
ToolsRoot explicitly; C/Zig also select ZigRoot, Rust selects InstallRoot and
CacheRoot as required. The original manifest/role builder and Cargo owner stay
authoritative. Sources remain in their actual project; no injected Zig business
root is produced. Output and caches have explicit owners, and an actual failed
native compile removes its prior artifact/receipt. Default output is build/;
OutputRoot can select out/ when an external/native editor expects that path.

The caller owns component versions and project pins. The SDK does not create,
read, migrate or delete such state. Technical SDK/Contract hashes, Cargo.lock
and required toolchain pins remain enforced. Older wrappers that explicitly
passed ProjectPin should invoke the current driver with selected component
roots; their external metadata remains under its owner's control.

GUI runs through Desktop, services through SERVMAN. A raw entry gets the real
R4XStartContext and initializes optional runtime helpers explicitly. Drivers
and protocols use genuine R4D/R4P entries and their original owner lifetimes.
Subsystem templates are host/launch/window shells, with the shared runtime
API available to the developer's decoder. A template or host build does not
prove a physical device, Windows execution, direct Rust SIMD/FP or performance.
Exact scope: Docs/SDK/LanguageParity.txt and the owner language matrix.
