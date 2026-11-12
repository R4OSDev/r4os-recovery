# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
$target = Join-Path $unit 'Port/Rust/r4os-x86_64.json'
$rustSources = Join-Path $foreign ('rust-src-'+$script:R4SdkNative.data.Tools.tools.graphics.rustc+'/rust-src/lib/rustlib/src/rust/library')
$out = Join-Path $buildRoot 'Sysroot/lib/rustlib/r4os-x86_64/lib'
[IO.Directory]::CreateDirectory($out) | Out-Null
$savedBootstrap = [Environment]::GetEnvironmentVariable('RUSTC_BOOTSTRAP')
$env:RUSTC_BOOTSTRAP = $script:R4SdkNative.data.Build.codegen.'native-flags'.nak_bootstrap
try {
    $common = @(Expand-R4SdkNativeFlags $script:R4SdkNative 'nak_sysroot_flags' @{target=$target;out=$out})
    & $tools.rustc @common --crate-name core (Join-Path $rustSources 'core/src/lib.rs') -o (Join-Path $out 'libcore.rlib')
    if ($LASTEXITCODE) { throw 'core failed' }
    & $tools.rustc @common --crate-name compiler_builtins --extern "core=$(Join-Path $out 'libcore.rlib')" `
        --cfg 'feature="compiler-builtins"' --cfg 'feature="mem"' --cfg 'feature="mem-unaligned"' `
        --cfg 'feature="unstable"' --cfg 'feature="force-soft-floats"' `
        (Join-Path $foreign 'compiler_builtins-0.1.140/src/lib.rs') -o (Join-Path $out 'libcompiler_builtins.rlib')
    if ($LASTEXITCODE) { throw 'compiler_builtins failed' }
    & $tools.rustc @common --crate-name alloc --extern "core=$(Join-Path $out 'libcore.rlib')" `
        --extern "compiler_builtins=$(Join-Path $out 'libcompiler_builtins.rlib')" `
        (Join-Path $rustSources 'alloc/src/lib.rs') -o (Join-Path $out 'liballoc.rlib')
    if ($LASTEXITCODE) { throw 'alloc failed' }
    Write-Host 'R4OS core, alloc and compiler_builtins compiled.'
} finally { [Environment]::SetEnvironmentVariable('RUSTC_BOOTSTRAP', $savedBootstrap) }

$rustPort = Join-Path $buildRoot 'Rust'
$out = Join-Path $buildRoot 'RustBuild'
[IO.Directory]::CreateDirectory($out) | Out-Null
function Compile-Rust([string]$name, [string]$path, [string[]]$deps = @(), [string[]]$flags = @()) {
    $crateType = if ($name -eq 'nak_rs') { 'staticlib' } else { 'rlib' }
    $extension = if ($name -eq 'nak_rs') { '.a' } else { '.rlib' }
    $argv = @(Expand-R4SdkNativeFlags $script:R4SdkNative 'nak_crate_flags' @{crate_type=$crateType;name=$name;target=$target;sysroot=(Join-Path $buildRoot 'Sysroot');out=$out})
    foreach ($dep in $deps) { $argv += @('--extern', "$dep=$(Join-Path $out ('lib'+$dep+'.rlib'))") }
    $argv += $flags
    $argv += @($path, '-o', (Join-Path $out ('lib'+$name+$extension)))
    & $tools.rustc @argv 2> (Join-Path $out ($name+'.log'))
    if ($LASTEXITCODE) {
        Get-Content -LiteralPath (Join-Path $out ($name+'.log')) -TotalCount 90
        throw "Rust port: $name failed."
    }
    Write-Host "Compiled $name"
}
Compile-Rust hashbrown (Join-Path $foreign 'hashbrown-0.15.2/src/lib.rs')
Compile-Rust r4os_std (Join-Path $unit 'Port/Rust/std.rs') @('hashbrown')
Compile-Rust rustc_hash (Join-Path $rustPort 'rustc_hash/lib.rs') @('r4os_std') @('--cfg','feature="std"')
foreach ($name in @('compiler','nvidia_headers','nak_latencies','bitview')) {
    Compile-Rust $name (Join-Path $rustPort "$name/lib.rs") @('r4os_std')
}
Compile-Rust nak_bindings (Join-Path $rustPort 'nak_bindings/nak_bindings.rs') @('compiler','r4os_std')
$procedural=@{}
foreach($name in @('nak_ir_proc','paste')) {
    $matches=@($targets | Where-Object name -eq $name)
    if($matches.Count -ne 1 -or @($matches[0].filename).Count -ne 1){throw "Missing native procedural macro $name"}
    $procedural[$name]=[string]$matches[0].filename[0]
}
Compile-Rust nak_rs (Join-Path $rustPort 'nak_rs/lib.rs') @('compiler','nak_bindings','nvidia_headers','nak_latencies','bitview','rustc_hash','r4os_std') @(
    '--extern', ('nak_ir_proc='+$procedural.nak_ir_proc), '--extern', ('paste='+$procedural.paste))
