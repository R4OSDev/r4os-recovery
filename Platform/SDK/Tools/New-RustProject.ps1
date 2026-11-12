# Existing public Rust command; the common creator owns all file maps.
param(
    [Parameter(Mandatory)][string]$TemplateId,
    [Parameter(Mandatory)][string]$Directory,
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$ToolsRoot,
    [string]$ProjectName='', [string]$SdkRoot='',
    [string]$InstallRoot='', [string]$CacheRoot='', [switch]$Technical
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
& (Join-Path $PSScriptRoot 'New-Project.ps1') @PSBoundParameters -Language Rust
