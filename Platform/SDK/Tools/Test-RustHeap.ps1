param(
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$Zig,
    [Parameter(Mandatory)][string]$RustLauncher,
    [Parameter(Mandatory)][string]$WorkRoot,
    [switch]$Generation2
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$sdk=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$ContractRoot=[IO.Path]::GetFullPath($ContractRoot);$Zig=[IO.Path]::GetFullPath($Zig)
$RustLauncher=[IO.Path]::GetFullPath($RustLauncher);$WorkRoot=[IO.Path]::GetFullPath($WorkRoot)
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty test directory.'}
[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
$success=$false;$previousFlags=$env:CARGO_ENCODED_RUSTFLAGS
try {
    Push-Location $sdk
    try {
        & (Join-Path $sdk 'Build.ps1') -Dheap-host-test-only=true --prefix (Join-Path $WorkRoot 'native') -j2
        if($LASTEXITCODE -ne 0){throw 'Native shared heap build failed.'}
    }finally{Pop-Location}
    $source=(Join-Path $sdk 'Tests/Simulation/RustHeap.rs').Replace('\','/')
    $dependency=(Join-Path $sdk 'Rust').Replace('\','/')
    $manifest=@"
[package]
name="r4os-sdk-heap-interop"
version="0.1.0"
edition="2024"
[lib]
path="$source"
[dependencies]
r4os-sdk={path="$dependency",features=["alloc"]}
[features]
generation2=[]
[workspace]
"@
    # TOML is file data, never interpolated into a shell command.
    [IO.File]::WriteAllText((Join-Path $WorkRoot 'Cargo.toml'),$manifest,[Text.UTF8Encoding]::new($false))
    $object=Join-Path $WorkRoot 'native/lib/r4sdk_heap_host.o'
    $env:CARGO_ENCODED_RUSTFLAGS=('-D'+[char]31+'warnings'+[char]31+'-C'+[char]31+'link-arg='+$object)
    $featureArguments=@()
    if($Generation2){
        $startupObject=Join-Path $WorkRoot 'native/lib/r4sdk_startup2_host.o'
        $env:CARGO_ENCODED_RUSTFLAGS+=([char]31+'-C'+[char]31+'link-arg='+$startupObject)
        $featureArguments=@('--features','generation2')
        $startupProbe=Join-Path $WorkRoot $(if($IsWindows){'app2-startup.exe'}else{'app2-startup'})
        & $Zig cc -std=c11 -O2 -UNDEBUG -Wall -Wextra -Werror -I (Join-Path $sdk 'Shared/C/include') -I (Join-Path $ContractRoot 'Generated/SDK/C/include') -I (Join-Path $ContractRoot 'Generated/Generation2/C/include') (Join-Path $sdk 'Tests/Simulation/App2Startup.c') $object $startupObject -o $startupProbe
        if($LASTEXITCODE -ne 0){throw 'C normal App2 calling-convention probe build failed.'}
        & $startupProbe
        if($LASTEXITCODE -ne 0){throw 'C normal App2 admission and shared heap owner probe failed.'}
    }
    $patch='patch.crates-io.r4os-contract.path="'+(Join-Path $ContractRoot 'Generated/SDK/Rust').Replace('\','/')+'"'
    $pwsh=(Get-Process -Id $PID).Path
    & $pwsh -NoLogo -NoProfile -File $RustLauncher cargo test --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'target') --config $patch @featureArguments
    if($LASTEXITCODE -ne 0){throw 'Rust/shared heap interop failed.'}
    $success=$true
    Write-Host 'SDK shared heap Rust/C ABI, owner/generation, layout/failure and release ACKs PASS.'
}finally{
    $env:CARGO_ENCODED_RUSTFLAGS=$previousFlags
    if($success){Remove-Item -LiteralPath $WorkRoot -Recurse -Force}
}
