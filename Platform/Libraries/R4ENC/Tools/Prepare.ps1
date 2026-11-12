# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([switch]$Offline)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = Get-R4EncPaths
$lockPath = Join-Path $paths.unit 'ThirdParty/Sources.json'
$lock = Get-Content -Raw -LiteralPath $lockPath | ConvertFrom-Json
if ($lock.schema -ne 1 -or $lock.sources.Count -ne 1 -or $lock.sources[0].name -ne 'OpenH264') { throw 'Invalid OpenH264 source lock.' }
$pin = $lock.sources[0]
$downloads = Join-Path $paths.artifacts 'Native/R4ENC/Downloads'
[IO.Directory]::CreateDirectory($downloads) | Out-Null
$archive = Join-Path $downloads ('openh264-' + $pin.version + '.tar.gz')
if (!(Test-Path -LiteralPath $archive)) {
    if ($Offline) { throw "Missing pinned OpenH264 archive: $archive" }
    $pending = $archive + '.pending'
    Invoke-WebRequest -Uri $pin.url -OutFile $pending
    if ((Get-R4EncHash $pending) -ne $pin.sha256) { throw 'Downloaded OpenH264 archive checksum mismatch.' }
    [IO.File]::Move($pending, $archive, $true)
}
if ((Get-R4EncHash $archive) -ne $pin.sha256) { throw 'Cached OpenH264 archive checksum mismatch.' }
$source = Join-Path $paths.cache 'Source'
$record = Join-Path $paths.cache 'prepare.json'
$patches = @(Get-ChildItem -LiteralPath (Join-Path $paths.unit 'Port') -Filter '*.patch' -File | Sort-Object Name)
$inputs = @($lockPath, $PSCommandPath, (Join-Path $PSScriptRoot 'Common.ps1')) + @($patches | ForEach-Object FullName)
$identity = @($inputs | ForEach-Object { [ordered]@{path=[IO.Path]::GetRelativePath($paths.unit,$_).Replace('\','/'); sha256=(Get-R4EncHash $_)} })
$id = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($identity | ConvertTo-Json -Depth 5 -Compress)))).ToLowerInvariant()
if (Test-Path -LiteralPath $record) {
    $previous = Get-Content -Raw -LiteralPath $record | ConvertFrom-Json
    if ($previous.identity -eq $id) {
        foreach ($entry in $previous.outputs) {
            if ((Get-R4EncHash (Join-Path $source $entry.path)) -ne $entry.sha256) { throw "Prepared OpenH264 source changed: $($entry.path)" }
        }
        Write-Host "Verified OpenH264 preparation: $source"
        return
    }
    [IO.File]::Delete($record)
}
# This path is derived solely from the dedicated R4ENC cache owner.
if (Test-Path -LiteralPath $source) { Remove-Item -LiteralPath $source -Recurse -Force }
[IO.Directory]::CreateDirectory($source) | Out-Null
& tar -xf $archive -C $source --strip-components=1
if ($LASTEXITCODE) { throw 'OpenH264 extraction failed.' }
Push-Location ([IO.Path]::GetPathRoot($source))
try {
    foreach ($patch in $patches) {
        & git apply --unsafe-paths ('--directory=' + $source) --check $patch.FullName
        if ($LASTEXITCODE) { throw "OpenH264 patch check failed: $($patch.Name)" }
        & git apply --unsafe-paths ('--directory=' + $source) $patch.FullName
        if ($LASTEXITCODE) { throw "OpenH264 patch failed: $($patch.Name)" }
    }
} finally { Pop-Location }
$outputs = @(Get-ChildItem -LiteralPath $source -File -Recurse | Sort-Object FullName | ForEach-Object {
    [ordered]@{path=[IO.Path]::GetRelativePath($source,$_.FullName).Replace('\','/'); sha256=(Get-R4EncHash $_.FullName)}
})
[ordered]@{schema=1; identity=$id; inputs=$identity; outputs=$outputs} |
    ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $record -Encoding utf8NoBOM
Write-Host "Prepared pinned OpenH264 $($pin.version): $source"
