# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$UnitRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ([IO.Path]::GetFullPath('SDK.ps1',$PSScriptRoot))
if (!$IsWindows -and !$IsLinux) { throw 'Supported hosts: Windows and Linux.' }
$unit = [IO.Path]::GetFullPath($UnitRoot)
$libraries = [IO.Path]::GetFullPath('../..', $PSScriptRoot)
$settings = @{}
foreach ($line in Get-Content -LiteralPath (Join-Path $libraries 'Settings.R4S')) {
    if ($line -match '^([A-Z_]+)=(.+)$') { $settings[$Matches[1]] = $Matches[2] }
}
function Resolve([string]$Base, [string]$Key) {
    if (!$settings.ContainsKey($Key)) { throw "Missing Libraries setting: $Key" }
    [IO.Path]::GetFullPath($settings[$Key].Replace('\', [IO.Path]::DirectorySeparatorChar), $Base)
}
function Hash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Tool([string]$Name) { (Get-Command $Name -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source }
$workspace = Resolve $libraries 'WORKSPACE_ROOT'
$repositories = Resolve $libraries 'REPOSITORIES_ROOT'
$artifacts = Resolve $workspace 'ARTIFACTS_ROOT'
$devkit = Resolve $workspace 'DEVKIT_ROOT'
$planPath = Join-Path $unit 'Tools/Portability.json'
$sourcesPath = Join-Path $unit 'ThirdParty/Sources.json'
$profilePath = Join-Path $PSScriptRoot 'AMDProfile.json'
$plan = Get-Content -Raw -LiteralPath $planPath | ConvertFrom-Json
$sources = Get-Content -Raw -LiteralPath $sourcesPath | ConvertFrom-Json
$profile = Get-Content -Raw -LiteralPath $profilePath | ConvertFrom-Json
if ($plan.schema -ne 1 -or $sources.schema -ne 1 -or $profile.schema -ne 1 -or
    $plan.module -notin @('AMDGPU','R4AMD','R4ACO')) { throw 'Unsupported portability plan.' }
if ($plan.profile -eq 'mesa' -and $sources.upstream_version -ne $profile.mesa) { throw 'Mesa profile/source mismatch.' }
$clang = Tool $(if ($IsWindows) { 'clang.exe' } else { ('clang-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]) })
$nm = Tool $(if ($IsWindows) { 'llvm-nm.exe' } else { ('llvm-nm-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]) })
$git = Tool 'git'
$version = @(& $clang --version)
if ($LASTEXITCODE -or !$version.Count -or $version[0] -notmatch ('(?<![0-9.])' + [regex]::Escape($profile.clang) + '(?![0-9.])')) { throw "Clang $($profile.clang) required." }
$resource = [string](& $clang -print-resource-dir)
if ($LASTEXITCODE -or !$resource) { throw 'Clang resource headers unavailable.' }
$hostName = if ($IsWindows) { 'Windows-x64' } else { 'Linux-x64' }
$stage = if ($plan.PSObject.Properties['output_stage']) { [string]$plan.output_stage } else { 'Portability' }
if ($stage -notmatch '^[A-Za-z0-9_-]+$') { throw 'Invalid native output stage.' }
$output = Join-Path $artifacts ("Native/$($plan.module)/$hostName/$stage-$($sources.upstream_version)")
[IO.Directory]::CreateDirectory($output) | Out-Null
# No cache reuse: every build verifies original inputs and regenerates/recompiles.
# Namespaces are per owner, host and upstream version, separate from NAK/NVK/GL.
$guard = [IO.File]::Open((Join-Path $output 'build.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
try {
    $recordPath = Join-Path $output 'portability.json'
    [IO.File]::Delete($recordPath)
    $source = Join-Path $output 'Source'
    $generated = Join-Path $output 'Generated'
    $objects = Join-Path $output 'Objects'
    foreach ($directory in @($source, $generated, $objects)) {
        if (Test-Path -LiteralPath $directory) { Remove-Item -LiteralPath $directory -Recurse -Force }
        [IO.Directory]::CreateDirectory($directory) | Out-Null
    }
    $original = Join-Path $unit $sources.original_root
    foreach ($file in $sources.files) {
        $input = Join-Path $original $file.path
        if ((Hash $input) -ne $file.sha256) { throw "Upstream source drift: $($file.path)" }
        $destination = Join-Path $source $file.path
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
        Copy-Item -LiteralPath $input -Destination $destination
    }
    if ($sources.PSObject.Properties['additional_licenses']) {
        foreach ($license in $sources.additional_licenses) {
            if ((Hash (Join-Path $unit $license.path)) -ne $license.sha256) { throw "License drift: $($license.path)" }
        }
    }
    Push-Location ([IO.Path]::GetPathRoot($source))
    try {
        foreach ($patch in $sources.patches) {
            $path = Join-Path $unit $patch.path
            if ((Hash $path) -ne $patch.sha256) { throw "Patch drift: $($patch.path)" }
            & $git apply --unsafe-paths ('--directory=' + $source) --check $path
            if ($LASTEXITCODE) { throw "Patch check failed: $($patch.path)" }
            & $git apply --unsafe-paths ('--directory=' + $source) $path
            if ($LASTEXITCODE) { throw "Patch failed: $($patch.path)" }
        }
    } finally { Pop-Location }
    $roots = @{
        source = $source; generated = $generated; unit = $unit
        include = (Join-Path $libraries 'R4GL/Port/Include'); libraries = $libraries
        sdk = (Resolve $repositories 'SDK_ROOT'); contract = (Resolve $repositories 'CONTRACT_ROOT')
        zig = (Resolve $devkit 'ZIG_ROOT'); clang_resource = $resource.Trim()
    }
    function Expand([string]$Value) {
        foreach ($key in $roots.Keys) { $Value = $Value.Replace(('$' + '{' + $key + '}'), $roots[$key].Replace('\','/')) }
        if ($Value.Contains('$' + '{')) { throw "Unknown native path variable: $Value" }
        return $Value
    }
    $pythonVersion = $null
    if ($plan.generators.Count) {
        $python = Tool $(if ($IsWindows) { 'python.exe' } else { 'python3' })
        $pythonVersion = [string](& $python --version)
        if ($LASTEXITCODE) { throw 'Python version unavailable.' }
        foreach ($step in $plan.generators) {
            foreach ($relative in $step.outputs) { [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName((Join-Path $generated $relative))) | Out-Null }
            $info = [Diagnostics.ProcessStartInfo]::new()
            $info.FileName = $python; $info.WorkingDirectory = $generated; $info.UseShellExecute = $false
            $info.Environment['PYTHONDONTWRITEBYTECODE'] = '1'
            $info.Environment['PYTHONHASHSEED'] = '0'
            $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
            foreach ($argument in $step.arguments) { $info.ArgumentList.Add((Expand $argument)) }
            $process = [Diagnostics.Process]::Start($info)
            $stdout = $process.StandardOutput.ReadToEndAsync()
            $stderr = $process.StandardError.ReadToEndAsync()
            $process.WaitForExit()
            $text = $stdout.GetAwaiter().GetResult(); $errors = $stderr.GetAwaiter().GetResult()
            if ($process.ExitCode) { throw "Generator failed ($($step.outputs -join ', ')): $errors" }
            $process.Dispose()
            if ($step.PSObject.Properties['capture']) { [IO.File]::WriteAllText((Join-Path $generated $step.capture), $text, [Text.UTF8Encoding]::new($false)) }
            foreach ($relative in $step.outputs) { if (!(Test-Path -LiteralPath (Join-Path $generated $relative))) { throw "Generator output missing: $relative" } }
        }
    }
    $results = @(foreach ($entry in $plan.units) {
        if ($entry.name -notmatch '^[a-z0-9_]+$') { throw 'Invalid object name.' }
        $flags = if ($plan.profile -eq 'mesa') { @($profile.cpp_flags) } else {
            @($script:R4SdkNative.data.Build.codegen.'native-flags'.portability_c_flags) + @(($resource.Trim() + '/include'))
        }
        if ($entry.language -eq 'c') { $flags = @($flags | Where-Object { $_ -notmatch '^-std=|^-fno-(exceptions|rtti)$|^-nostdinc\+\+$' }) + '-std=c11' }
        $object = Join-Path $objects ($entry.name + '.o')
        $sourceRoot = if ($entry.PSObject.Properties['owner_source'] -and $entry.owner_source) { $unit } else { $source }
        $arguments = @($flags + $plan.flags | ForEach-Object { Expand $_ }) + @('-MD','-MF',($object + '.d'),'-c',(Join-Path $sourceRoot $entry.source),'-o',$object)
        $response = $object + '.rsp'
        [IO.File]::WriteAllLines($response, @($arguments | ForEach-Object { '"' + $_.Replace('\','\\').Replace('"','\"') + '"' }), [Text.UTF8Encoding]::new($false))
        & $clang ('@' + $response)
        if ($LASTEXITCODE) { throw "Freestanding compilation failed: $($entry.name)" }
        $bytes = [IO.File]::ReadAllBytes($object)
        if ($bytes.Length -lt 64 -or $bytes[0] -ne 127 -or [Text.Encoding]::ASCII.GetString($bytes,1,3) -ne 'ELF' -or
            $bytes[4] -ne 2 -or $bytes[5] -ne 1 -or [BitConverter]::ToUInt16($bytes,16) -ne 1 -or [BitConverter]::ToUInt16($bytes,18) -ne 62) { throw "Expected x86_64 ELF relocatable object: $object" }
        $undefined = @(& $nm --undefined-only --demangle $object)
        if ($LASTEXITCODE) { throw 'Cannot audit unresolved symbols.' }
        $symbols = @($undefined | ForEach-Object { $_.Trim() -replace '^U\s+', '' } | Where-Object { $_ } | Sort-Object -Unique)
        [ordered]@{name=$entry.name; source=$entry.source; object=('Objects/'+$entry.name+'.o'); sha256=(Hash $object); bytes=$bytes.Length; target='ELF64 x86_64 ET_REL'; undefined_symbols=$symbols; compiler_arguments=$arguments; required_followup=$plan.followup}
    })
    # Record all shared/toolchain header inputs as well as the original/patch plan.
    $inputs = @($PSCommandPath,$planPath,$sourcesPath,$profilePath,$clang,$nm)
    foreach ($directory in @((Join-Path $unit 'Port'), (Join-Path $libraries 'R4GL/Port/Include'), (Join-Path $libraries 'R4NAK/Port/Include'),
            (Join-Path $libraries 'Shared/Native'), (Join-Path $libraries 'R4VK/Bindings/C'), (Join-Path $roots.sdk 'Shared/C/include'),
            (Join-Path $roots.contract 'Generated/SDK/C/include'), (Join-Path $roots.contract 'Generated/Generation2/C/include'), (Join-Path $roots.zig 'lib/libcxx/include'), (Join-Path $resource.Trim() 'include'))) {
        if (Test-Path -LiteralPath $directory) { $inputs += @(Get-ChildItem -LiteralPath $directory -File -Recurse | ForEach-Object FullName) }
    }
    $identities = @(foreach ($path in $inputs | Sort-Object -Unique) { [ordered]@{path=[IO.Path]::GetRelativePath($workspace,$path).Replace('\','/'); sha256=(Hash $path)} })
    $report = [ordered]@{schema=1; module=$plan.module; upstream=$sources.upstream_version; host=$hostName; compiler=$version[0]; python=$pythonVersion; scope=$plan.scope; cache_reused=$false; inputs=$identities; objects=$results}
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $recordPath -Encoding utf8NoBOM
    Write-Host "Verified $($plan.module): $($results.Count) genuine freestanding source units; unresolved link dependencies -> $($plan.followup)."
} finally { $guard.Dispose() }
