param(
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$Zig,
    [Parameter(Mandatory)][string]$RustLauncher,
    [Parameter(Mandatory)][string]$FacadeGenerator,
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
    Push-Location $sdk
    try {
        & $Zig build ('--fork='+$ContractRoot) storage-parity-test -j1
        if($LASTEXITCODE -ne 0){throw 'Existing Zig storage/path/registry owner cases failed.'}
        & $Zig build ('--fork='+$ContractRoot) -Dfacade-runtime-only=true -Dfacade-host-test=true --prefix (Join-Path $WorkRoot 'native') -j1
        if($LASTEXITCODE -ne 0){throw 'Native SDK facade objects failed.'}
    }finally{Pop-Location}
    $objects=@()
    foreach($source in @('Tests/Simulation/StorageCallbacks.c','Tests/Conformance/StorageCodecChecks.c')){
        $out=Join-Path $WorkRoot (([IO.Path]::GetFileNameWithoutExtension($source))+'.o')
        & $Zig cc -O1 -UNDEBUG -Werror -I (Join-Path $sdk 'Shared/C/include') -I (Join-Path $ContractRoot 'Generated/SDK/C/include') -I (Join-Path $ContractRoot 'Generated/Generation2/C/include') -c (Join-Path $sdk $source) -o $out
        if($LASTEXITCODE -ne 0){throw ('C fixture failed: '+$source)}
        $objects+=$out
    }
    $source=(Join-Path $sdk 'Tests/Simulation/RustStorage.rs').Replace('\','/')
    $dependency=(Join-Path $sdk 'Rust').Replace('\','/')
    $manifest=@"
[package]
name="r4os-sdk-storage-interop"
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
    foreach($object in @((Join-Path $WorkRoot 'native/lib/r4sdk_facades.o'),(Join-Path $WorkRoot 'native/lib/r4sdk_storage.o'))+$objects){$flags+=@('-C',('link-arg='+$object))}
    $env:CARGO_ENCODED_RUSTFLAGS=$flags -join [char]31
    $patch='patch.crates-io.r4os-contract.path="'+(Join-Path $ContractRoot 'Generated/SDK/Rust').Replace('\','/')+'"'
    $pwsh=(Get-Process -Id $PID).Path
    & $pwsh -NoLogo -NoProfile -File $RustLauncher cargo test --release --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'target') --config $patch --config 'profile.release.opt-level="z"' --config 'profile.release.overflow-checks=true' --config 'profile.release.lto="fat"'
    if($LASTEXITCODE -ne 0){throw 'Rust/C/owner storage interop failed.'}
    $success=$true
    Write-Host 'SDK files, paths, streams, snapshots, batches, hive codecs, text and exact close outcomes PASS.'
}finally{
    $env:CARGO_ENCODED_RUSTFLAGS=$previous
    if($success){Remove-Item -LiteralPath $WorkRoot -Recurse -Force}
}
