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
        & $Zig build ('--fork='+$ContractRoot) -Dfacade-runtime-only=true -Dfacade-host-test=true --prefix (Join-Path $WorkRoot 'native') -j1
        if($LASTEXITCODE -ne 0){throw 'Native SDK resource objects failed.'}
    }finally{Pop-Location}
    $out=Join-Path $WorkRoot 'callbacks.o'
    & $Zig cc -O1 -UNDEBUG -Werror -I (Join-Path $sdk 'Shared/C/include') -I (Join-Path $ContractRoot 'Generated/SDK/C/include') -I (Join-Path $ContractRoot 'Generated/Generation2/C/include') -c (Join-Path $sdk 'Tests/Simulation/ResourceCallbacks.c') -o $out
    if($LASTEXITCODE -ne 0){throw 'Existing C app-resource fixture/callbacks failed.'}
    $source=(Join-Path $sdk 'Tests/Simulation/RustResources.rs').Replace('\','/')
    $dependency=(Join-Path $sdk 'Rust').Replace('\','/')
    $manifest=@"
[package]
name="r4os-sdk-resource-interop"
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
    if($LASTEXITCODE -ne 0){throw 'Rust/C resource lifecycle interop failed.'}
    # Compile actual misuse with the same bindings; source text inspection is
    # not evidence for unsafe admission or a context's Send restrictions.
    $negative=Join-Path $WorkRoot 'negative.rs'
    $manifest=$manifest.Replace($source,$negative.Replace('\','/'))
    [IO.File]::WriteAllText((Join-Path $WorkRoot 'Cargo.toml'),$manifest,[Text.UTF8Encoding]::new($false))
    $cases=@(
        @('E0133','pub fn bad(r:&r4os_sdk::resources::Resources<''_>,p:&r4os_sdk::path::FilePath,b:&mut[u8]) { let _=r.io(Some(p),r4os_sdk::resources::IoOperation::Read{buffer:b,offset:None},0); }'),
        @('E0277','fn send<T:Send>(){} pub fn bad(){send::<r4os_sdk::resources::Resources<''static>>();}')
    )
    foreach($case in $cases){
        [IO.File]::WriteAllText($negative,$case[1],[Text.UTF8Encoding]::new($false))
        $failure=Join-Path $WorkRoot 'negative.log'
        & $pwsh -NoLogo -NoProfile -File $RustLauncher cargo check --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'target') --config $patch > $failure 2>&1
        if($LASTEXITCODE -eq 0 -or !([IO.File]::ReadAllText($failure).Contains($case[0]))){throw ('Actual negative consumer failed for wrong reason: '+$case[0])}
    }
    $success=$true
    Write-Host 'Rust/C exact resources, partial completion, generation/timeout state and pending owned-buffer retention PASS; unsafe/Send misuse rejected.'
}finally{
    $env:CARGO_ENCODED_RUSTFLAGS=$previous
    if($success){Remove-Item -LiteralPath $WorkRoot -Recurse -Force}
}
