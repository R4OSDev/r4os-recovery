# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
param([Parameter(Mandatory)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$unit=[IO.Path]::GetFullPath('..',$PSScriptRoot)
$libraries=[IO.Path]::GetFullPath('..',$unit)
$settings=@{}
foreach($line in Get-Content (Join-Path $libraries 'Settings.R4S')){
    if($line -match '^([A-Z_]+)=(.+)$'){$settings[$Matches[1]]=$Matches[2]}
}
$workspace=[IO.Path]::GetFullPath($settings.WORKSPACE_ROOT,$libraries)
$devkit=[IO.Path]::GetFullPath($settings.DEVKIT_ROOT,$workspace)
$zig=[IO.Path]::GetFullPath($settings.ZIG_ROOT,$devkit)
$sections=[Collections.Generic.List[string]]::new()
$sections.Add("R4ACO Mesa 26.2.2 SPIR-V/NIR/ACO and bounded runtime notices`nOriginal sources retain their own terms; catalogs pin exact bytes. Build copies carry the documented R4OS patches.`n")
function AddSource([string]$Label,[string]$Path,[string]$Expected,[switch]$Complete){
    $hash=(Get-FileHash -LiteralPath $Path).Hash.ToLowerInvariant()
    if($hash -cne $Expected){throw "Legal source drift: $Label"}
    $source=[IO.File]::ReadAllText($Path).Replace("`r`n","`n")
    if($Complete){$notice=$source}
    else{
        # Keep complete original comment blocks, including license templates
        # emitted by the Mesa generators and notices at the end of stb.
        $blocks=@([regex]::Matches($source,'(?ms)/\*.*?\*/|^(?:(?:[ \t]*//|[ \t]*\#(?!\s*(?:include|define|if|else|endif|error|pragma|undef)\b))[^\n]*\n)+')|
            Where-Object {$_.Value -match '(?i)copyright|SPDX|permission is hereby|public domain|license|redistribution'}|
            ForEach-Object {$_.Value.Trim()}|Select-Object -Unique)
        $notice=if($blocks.Count){$blocks -join "`n`n"}else{'No separate copyright/license comment in this original data/header; original bytes and Mesa license context are retained.'}
    }
    $sections.Add($Label+"`nSHA256 "+$hash+"`n"+$notice+"`n")
}
$catalog=Get-Content -Raw (Join-Path $unit 'ThirdParty/Sources.json')|ConvertFrom-Json
foreach($entry in $catalog.files){
    # GPL license texts are context-only reference files, not linked source.
    if($entry.path -match '^licenses/(GPL-|exceptions/)'){continue}
    AddSource ('Mesa/'+$entry.path) (Join-Path (Join-Path $unit $catalog.original_root) $entry.path) $entry.sha256 -Complete:($entry.path.StartsWith('licenses/'))
}
foreach($entry in $catalog.additional_licenses){AddSource $entry.path (Join-Path $unit $entry.path) $entry.sha256 -Complete}
$cpp=Get-Content -Raw (Join-Path $PSScriptRoot 'CppSources.json')|ConvertFrom-Json
foreach($entry in $cpp.files){AddSource ('Zig/'+$entry.path) (Join-Path $zig $entry.path) $entry.sha256 -Complete:($entry.path.EndsWith('LICENSE.TXT'))}
$stb=Join-Path $libraries 'R4NAK/ThirdParty/stb/stb_sprintf.h'
AddSource 'Shared stb_sprintf.h (MIT or public-domain option)' $stb ((Get-FileHash $stb).Hash.ToLowerInvariant())
foreach($provider in @('Math','Scan')){
    $sections.Add([IO.File]::ReadAllText((Join-Path $libraries "Shared/Native/$provider/NOTICES.txt")).TrimStart([char]0xfeff))
}
[IO.Directory]::CreateDirectory($OutputDirectory)|Out-Null
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'R4ACO-NOTICES.txt'),($sections -join "`n"),[Text.UTF8Encoding]::new($true))
Write-Host 'R4ACO original Mesa, libc++, stb, math and scan notices exported.'
