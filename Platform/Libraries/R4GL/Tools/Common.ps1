# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
function Get-R4GLPaths {
    $libraries = [IO.Path]::GetFullPath('../..', $PSScriptRoot)
    $settings = @{}
    foreach ($line in Get-Content -LiteralPath (Join-Path $libraries 'Settings.R4S')) {
        if ($line -match '^([A-Z_]+)=(.+)$') { $settings[$Matches[1]] = $Matches[2] }
    }
    function Resolve([string]$Base, [string]$Key) {
        [IO.Path]::GetFullPath($settings[$Key].Replace('\', [IO.Path]::DirectorySeparatorChar), $Base)
    }
    $workspace = Resolve $libraries 'WORKSPACE_ROOT'
    $repositories = Resolve $libraries 'REPOSITORIES_ROOT'
    $devkit = Resolve $workspace 'DEVKIT_ROOT'
    $artifacts = Resolve $workspace 'ARTIFACTS_ROOT'
    $unit = [IO.Path]::GetFullPath('..', $PSScriptRoot)
    [pscustomobject]@{
        unit = $unit; libraries = $libraries; workspace = $workspace; devkit = $devkit
        artifacts = $artifacts; zig = (Resolve $devkit 'ZIG_ROOT')
        sdk = (Resolve $repositories 'SDK_ROOT'); contract = (Resolve $repositories 'CONTRACT_ROOT')
        cache = (Join-Path $artifacts ('Native/R4GL/' + $(if ($IsWindows) { 'Windows-x64' } else { 'Linux-x64' })))
        lock = (Join-Path $libraries 'R4NV/Tools/Compiler/Sources.lock.json')
    }
}
function Get-R4GLHash([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Invoke-R4GLScript([string]$Path, [string[]]$Options) {
    & pwsh -NoLogo -NoProfile -File $Path @Options
    if ($LASTEXITCODE) { throw "R4GL dependency failed: $Path ($LASTEXITCODE)" }
}
