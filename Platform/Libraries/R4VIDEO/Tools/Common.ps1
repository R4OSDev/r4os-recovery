# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
function Get-R4VideoPaths {
    $libraries = [IO.Path]::GetFullPath('../..', $PSScriptRoot)
    $settings = @{}
    foreach ($line in Get-Content -LiteralPath (Join-Path $libraries 'Settings.R4S')) {
        if ($line -match '^([A-Z_]+)=(.+)$') { $settings[$Matches[1]] = $Matches[2] }
    }
    function Resolve([string]$Base, [string]$Key) {
        if (!$settings.ContainsKey($Key)) { throw "Missing $Key in Libraries/Settings.R4S" }
        [IO.Path]::GetFullPath($settings[$Key].Replace('\', [IO.Path]::DirectorySeparatorChar), $Base)
    }
    $workspace = Resolve $libraries 'WORKSPACE_ROOT'
    $repositories = Resolve $libraries 'REPOSITORIES_ROOT'
    $devkit = Resolve $workspace 'DEVKIT_ROOT'
    $artifacts = Resolve $workspace 'ARTIFACTS_ROOT'
    [pscustomobject]@{
        unit = [IO.Path]::GetFullPath('..', $PSScriptRoot); libraries = $libraries
        workspace = $workspace; artifacts = $artifacts; zig = (Resolve $devkit 'ZIG_ROOT')
        sdk = (Resolve $repositories 'SDK_ROOT'); contract = (Resolve $repositories 'CONTRACT_ROOT')
        cache = (Join-Path $artifacts ('Native/R4VIDEO/' + $(if ($IsWindows) { 'Windows-x64' } else { 'Linux-x64' })))
    }
}
function Get-R4VideoHash([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
