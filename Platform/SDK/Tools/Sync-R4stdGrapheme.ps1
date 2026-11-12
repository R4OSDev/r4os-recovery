# Generated consumer snapshot; the only implementation owner is R4STD.
[CmdletBinding()]
param([string]$LibrariesRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$sdk=Split-Path -Parent $PSScriptRoot
if([string]::IsNullOrWhiteSpace($LibrariesRoot)){$LibrariesRoot=Join-Path $sdk '../Libraries'}
$LibrariesRoot=[IO.Path]::GetFullPath($LibrariesRoot)
$destination=Join-Path $sdk 'Shared/Generated/R4STD_Grapheme'
$manifest=Get-Content -Raw -LiteralPath (Join-Path $destination 'SOURCE.json')|ConvertFrom-Json -AsHashtable
foreach($name in $manifest.files.Keys){
 $entry=$manifest.files[$name];$source=Join-Path $LibrariesRoot $entry.path
 if((Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash.ToLowerInvariant() -cne $entry.sha256){throw "Canonical pinned R4STD input differs: $name"}
 $target=Join-Path $destination $name
 [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
 [IO.File]::WriteAllBytes($target,[IO.File]::ReadAllBytes($source))
}
Write-Output ('R4STD snapshot byte-exact: '+$manifest.files.Count+' files; Libraries '+$manifest.libraries_version+' commit '+$manifest.commit)
