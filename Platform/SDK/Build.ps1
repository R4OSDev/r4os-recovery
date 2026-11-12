# Host launcher; SDK owns compiler and system bindings.
$ErrorActionPreference='Stop'
$sdk=$PSScriptRoot
$forward=@{OwnerRoot=$PSScriptRoot;BuildArguments=@($args)}
& (Join-Path $sdk 'Tools/BuildOwner.ps1') @forward
exit $LASTEXITCODE
