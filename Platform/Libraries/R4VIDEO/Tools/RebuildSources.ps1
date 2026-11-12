# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
# Run inside the extracted R4VIDEO source package, on Windows or Linux.
param([Parameter(Mandatory)][string]$DevKitDirectory)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$workspace=[IO.Path]::GetFullPath('../../../..',$PSScriptRoot)
$devkit=[IO.Path]::GetFullPath($DevKitDirectory)
$zig=Join-Path $devkit ('Toolchains/Zig/'+$(if($IsWindows){'zig.exe'}else{'zig'}))
if(!(Test-Path -LiteralPath $zig)){throw 'DevKitDirectory must contain Toolchains/Zig and its complete lib directory.'}
$version=[string](& $zig version)
if($LASTEXITCODE -or $version.Trim() -ne '0.16.0'){throw 'The source profile requires Zig0.16.0.'}
$libraries=[IO.Path]::GetFullPath('../..',$PSScriptRoot)
$settings=Join-Path $libraries 'Settings.R4S'
$previous=[IO.File]::ReadAllBytes($settings)
try {
    $relative=[IO.Path]::GetRelativePath($workspace,$devkit).Replace('\','/')
    $text=[IO.File]::ReadAllText($settings)
    $text=[regex]::Replace($text,'(?m)^DEVKIT_ROOT=.*$',('DEVKIT_ROOT='+$relative))
    [IO.File]::WriteAllText($settings,$text,[Text.UTF8Encoding]::new($true))
    & pwsh -NoProfile -File (Join-Path $libraries 'Build.ps1') R4VIDEO -Doffline=true
    if($LASTEXITCODE){throw 'Source rebuild failed.'}
} finally { [IO.File]::WriteAllBytes($settings,$previous) }
Write-Host 'Rebuilt replaceable module: Repositories/Libraries/R4VIDEO/zig-out/R4VIDEO.R4L'
