param(
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$Zig,
    [Parameter(Mandatory)][string]$RustLauncher,
    [Parameter(Mandatory)][string]$FacadeGenerator,
    [Parameter(Mandatory)][string]$NetBridgeGenerator,
    [Parameter(Mandatory)][string]$WorkRoot
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$sdk=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$ContractRoot=[IO.Path]::GetFullPath($ContractRoot);$Zig=[IO.Path]::GetFullPath($Zig)
$RustLauncher=[IO.Path]::GetFullPath($RustLauncher);$WorkRoot=[IO.Path]::GetFullPath($WorkRoot)
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty test directory.'}
[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
$success=$false;$previous=$env:CARGO_ENCODED_RUSTFLAGS
try {
    & $FacadeGenerator check (Join-Path $sdk 'Rust/src/c_facades.rs')
    if($LASTEXITCODE -ne 0){throw 'C/Rust facade projection drift.'}
    & $NetBridgeGenerator check (Join-Path $sdk 'Shared/C/include/r4os/net_bridge.h') (Join-Path $sdk 'r4os/generated/net_facade.zig') (Join-Path $sdk 'Rust/src/generated/network.rs')
    if($LASTEXITCODE -ne 0){throw 'Compiler-typed network bridge drift.'}
    Push-Location $sdk
    try {
        & $Zig build ('--fork='+$ContractRoot) service-parity-test -j1
        if($LASTEXITCODE -ne 0){throw 'Existing service/network/deadline owner cases failed.'}
        & $Zig build ('--fork='+$ContractRoot) -Dfacade-runtime-only=true -Dfacade-host-test=true --prefix (Join-Path $WorkRoot 'native') -j1
        if($LASTEXITCODE -ne 0){throw 'Native SDK service objects failed.'}
    }finally{Pop-Location}
    $out=Join-Path $WorkRoot 'callbacks.o'
    & $Zig cc -O1 -UNDEBUG -Werror -I (Join-Path $sdk 'Shared/C/include') -I (Join-Path $ContractRoot 'Generated/SDK/C/include') -I (Join-Path $ContractRoot 'Generated/Generation2/C/include') -c (Join-Path $sdk 'Tests/Simulation/ServiceNetworkCallbacks.c') -o $out
    if($LASTEXITCODE -ne 0){throw 'Existing C app-service fixture/callbacks failed.'}
    $source=(Join-Path $sdk 'Tests/Simulation/RustServices.rs').Replace('\','/')
    $dependency=(Join-Path $sdk 'Rust').Replace('\','/')
    $manifest=@"
[package]
name="r4os-sdk-service-interop"
version="0.1.0"
edition="2024"
[lib]
path="$source"
[dependencies]
r4os-sdk={path="$dependency",features=["alloc"]}
[workspace]
"@
    [IO.File]::WriteAllText((Join-Path $WorkRoot 'Cargo.toml'),$manifest,[Text.UTF8Encoding]::new($false))
    $flags=@('-D','warnings')
    foreach($object in @((Join-Path $WorkRoot 'native/lib/r4sdk_facades.o'),(Join-Path $WorkRoot 'native/lib/r4sdk_storage.o'),$out)){$flags+=@('-C',('link-arg='+$object))}
    $env:CARGO_ENCODED_RUSTFLAGS=$flags -join [char]31
    $patch='patch.crates-io.r4os-contract.path="'+(Join-Path $ContractRoot 'Generated/SDK/Rust').Replace('\','/')+'"'
    $pwsh=(Get-Process -Id $PID).Path
    & $pwsh -NoLogo -NoProfile -File $RustLauncher cargo test --release --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'target') --config $patch --config 'profile.release.opt-level="z"' --config 'profile.release.overflow-checks=true' --config 'profile.release.lto="fat"'
    if($LASTEXITCODE -ne 0){throw 'Rust/C service lifecycle interop failed.'}
    # Compile actual misuse with the same bindings; source text inspection is
    # not evidence for unsafe admission or a context's Send restrictions.
    $negative=Join-Path $WorkRoot 'negative.rs'
    $manifest=$manifest.Replace($source,$negative.Replace('\','/'))
    [IO.File]::WriteAllText((Join-Path $WorkRoot 'Cargo.toml'),$manifest,[Text.UTF8Encoding]::new($false))
    $cases=@(
        @('E0133','pub fn bad(n:&r4os_sdk::network::Network<''_>,r:&mut r4os_sdk::network::RawRequest) { let _=n.net_socket_status(r); }'),
        @('E0277','fn send<T:Send>(){} pub fn bad(){send::<r4os_sdk::network::Network<''static>>();}')
    )
    foreach($case in $cases){
        [IO.File]::WriteAllText($negative,$case[1],[Text.UTF8Encoding]::new($false))
        $failure=Join-Path $WorkRoot 'negative.log'
        & $pwsh -NoLogo -NoProfile -File $RustLauncher cargo check --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'target') --config $patch > $failure 2>&1
        if($LASTEXITCODE -eq 0 -or !([IO.File]::ReadAllText($failure).Contains($case[0]))){throw ('Actual negative consumer failed for wrong reason: '+$case[0])}
    }
    $success=$true
    Write-Host 'Rust/C services, bounded drain, absolute deadlines, TCP/UDP, serial partial progress and retained async requests PASS; unsafe/Send misuse rejected.'
}finally{
    $env:CARGO_ENCODED_RUSTFLAGS=$previous
    if($success){Remove-Item -LiteralPath $WorkRoot -Recurse -Force}
}
