param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
$contract = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$workspace = [IO.Path]::GetFullPath((Join-Path $contract '../..'))
$rustStarter = Join-Path $workspace 'DevKit/Setup/Rust.ps1'
$zig = Join-Path $workspace ('DevKit/Toolchains/Zig/zig' + $(if ($IsWindows) { '.exe' } else { '' }))
$temporary = if (Test-Path -LiteralPath $rustStarter) { Join-Path $workspace 'Temp/ContractRustABI' } else { Join-Path $contract 'Temp/ContractRustABI' }
$targetDirectory = Join-Path $temporary 'target'
$hostTriple = if ($IsWindows) { 'x86_64-pc-windows-msvc' } elseif ($IsLinux) { 'x86_64-unknown-linux-gnu' } else { throw 'Rust ABI tests require an x86_64 Linux or Windows host.' }
$kernelTriple = 'x86_64-unknown-none'
[void][IO.Directory]::CreateDirectory($temporary)

function Invoke-Rust([string[]]$Arguments) {
    if (Test-Path -LiteralPath $rustStarter) {
        & pwsh -NoLogo -NoProfile -File $rustStarter @Arguments
    } else {
        $executable = Get-Command $Arguments[0] -ErrorAction Stop
        & $executable.Source @($Arguments | Select-Object -Skip 1)
    }
    if ($LASTEXITCODE -ne 0) { throw ('Rust ABI command failed: ' + ($Arguments -join ' ')) }
}
if (-not (Test-Path -LiteralPath $zig)) { $zig = (Get-Command zig -ErrorAction Stop).Source }
if (-not (Test-Path -LiteralPath $rustStarter)) {
    $version = (& rustc --version) -join ' '
    if ($LASTEXITCODE -ne 0 -or -not $version.StartsWith('rustc 1.99.0 ')) { throw 'Use pinned Rust 1.99.0 for standalone Contract validation.' }
}
$bindings = Join-Path $contract 'Generated/SDK/Rust/Cargo.toml'
$interop = Join-Path $contract 'Tests/RustInterop/Cargo.toml'
foreach ($target in @($hostTriple,$kernelTriple)) {
    Invoke-Rust @('cargo','check','--locked','--offline','--manifest-path',$bindings,'--target',$target,'--target-dir',$targetDirectory)
}
Invoke-Rust @('cargo','clippy','--locked','--offline','--lib','--manifest-path',$bindings,'--target',$kernelTriple,'--target-dir',$targetDirectory,'--','-D','warnings')
Invoke-Rust @('cargo','build','--locked','--offline','--release','--manifest-path',$interop,'--target',$kernelTriple,'--target-dir',$targetDirectory)
# Linux runs the actual freestanding SysV/soft-float object against Zig/C.
# Windows separately checks the bare target and runs the native host C ABI.
$executionTarget = $kernelTriple
if ($IsWindows) {
    $executionTarget = $hostTriple
    Invoke-Rust @('cargo','build','--locked','--offline','--release','--manifest-path',$interop,'--target',$hostTriple,'--target-dir',$targetDirectory)
}
$libraryName = if ($IsWindows) { 'r4os_contract_interop.lib' } else { 'libr4os_contract_interop.a' }
$library = Join-Path $targetDirectory ($executionTarget + '/release/' + $libraryName)
$include = Join-Path $contract 'Generated/SDK/C/include'
$abi = Join-Path $contract 'Generated/SDK/Zig/abi.zig'
$generation2 = Join-Path $contract 'Generated/Generation2/Zig/abi.zig'
$fixture = Join-Path $contract 'Tests/RustInterop/interop.zig'
$cFixture = Join-Path $contract 'Tests/RustInterop/interop.c'
$arguments = @('test','-O','ReleaseSafe','-lc','-I',$include,'-I',(Join-Path $contract 'Generated/Generation2/C/include'),$cFixture,$library,
    '--dep','r4os_technical_abi','--dep','r4os_generation2',('-Mroot='+$fixture),('-Mr4os_technical_abi='+$abi),
    '--dep','r4os_base_abi=r4os_technical_abi',('-Mr4os_generation2='+$generation2),
    '--cache-dir',(Join-Path $temporary 'zig-cache'))
& $zig @arguments
if ($LASTEXITCODE -ne 0) { throw 'Canonical Rust/Zig/C callback roundtrip failed.' }
Write-Output 'Rust ABI: host and bare layouts, Clippy and native canonical C/Zig callback roundtrips PASS.'
