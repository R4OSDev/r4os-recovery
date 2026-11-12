# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
function Get-R4VKFileHash([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Get-R4VKMesaSource {
    $unit = [IO.Path]::GetFullPath('..', $PSScriptRoot)
    $libraries = [IO.Path]::GetFullPath('../..', $PSScriptRoot)
    $settings = @{}
    foreach ($line in Get-Content -LiteralPath (Join-Path $libraries 'Settings.R4S')) {
        if ($line -match '^([A-Z_]+)=(.+)$') { $settings[$Matches[1]] = $Matches[2] }
    }
    $workspace = [IO.Path]::GetFullPath($settings.WORKSPACE_ROOT.Replace('\', [IO.Path]::DirectorySeparatorChar), $libraries)
    $devkit = [IO.Path]::GetFullPath($settings.DEVKIT_ROOT.Replace('\', [IO.Path]::DirectorySeparatorChar), $workspace)
    $mesaTools = Join-Path $libraries 'R4NV/Tools/Compiler'
    $lockPath = Join-Path $mesaTools 'Sources.lock.json'
    $lock = Get-Content -Raw -LiteralPath $lockPath | ConvertFrom-Json
    $basePatch = Get-R4VKFileHash (Join-Path $mesaTools 'MesaStandalone.patch')
    $prepared = Join-Path $devkit ('Toolchains/MesaNAK/' + $lock.mesa.version + '-' + $basePatch.Substring(0, 16))
    $source = Join-Path $prepared 'Source'
    $stamp = Get-Content -Raw -LiteralPath (Join-Path $prepared 'prepared.json') | ConvertFrom-Json
    if ($stamp.mesa -ne $lock.mesa.sha512 -or $stamp.patch -ne $basePatch) {
        throw 'Mesa source preparation does not match the shared source lock.'
    }
    $manifestPath = Join-Path $prepared 'source-files.json'
    $sourceFiles = @(Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json)
    foreach ($file in $sourceFiles) {
        if ((Get-R4VKFileHash (Join-Path $source $file.path)) -ne $file.sha256) {
            throw "Prepared Mesa source changed: $($file.path)"
        }
    }
    [pscustomobject]@{
        unit = $unit; libraries = $libraries; workspace = $workspace; devkit = $devkit
        lock_path = $lockPath; lock = $lock; source = $source
        manifest_path = $manifestPath; files = $sourceFiles
    }
}
