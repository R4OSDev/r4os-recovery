param([Parameter(Mandatory)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$unit=[IO.Path]::GetFullPath('..',$PSScriptRoot)
$catalog=Get-Content -Raw (Join-Path $unit 'ThirdParty/Sources.json')|ConvertFrom-Json
$original=Join-Path $unit $catalog.original_root
$sections=[Collections.Generic.List[string]]::new()
$sections.Add("R4AMD AddrLib, image layout/descriptors and SDMA/PM4/VCN encoder notices`nThe encoders are also compiled into AMDGPU. Mesa $($catalog.upstream_version); original identities in ThirdParty/Sources.json.`n")
$names=@($catalog.files.path|Where-Object {$_ -match '^src/amd/(addrlib/.*\.(cpp|h)|common/.*\.(c|h)|vulkan/.*\.(c|h))$|^src/gallium/(drivers/radeonsi/mm/.*\.(c|h)|include/pipe/p_video_state\.h)$' -or $_ -in @('include/drm-uapi/drm_fourcc.h','src/amd/registers/makeregheader.py','src/amd/registers/regdb.py','src/amd/registers/gfx9.json','licenses/MIT')})
foreach($name in $names){
    $entry=@($catalog.files|Where-Object {$_.path -ceq $name})
    if($entry.Count -ne 1){throw "Missing source $name"}
    $path=Join-Path $original $name
    if((Get-FileHash $path).Hash.ToLowerInvariant() -cne $entry[0].sha256){throw "Source drift $name"}
    $source=[IO.File]::ReadAllText($path)
    if($name -eq 'licenses/MIT'){$notice=$source}
    elseif($name.EndsWith('/gfx9.json')){$notice='GFX9 register data; generated header carries the notice from makeregheader.py below.'}
    elseif($name.EndsWith('/regdb.py')){$notice=[regex]::Match($source,'\A(?:#[^\r\n]*\r?\n)+').Value.Trim();if(!$notice){throw "Missing original notice $name"}}
    elseif($name.EndsWith('/makeregheader.py')){$notice=[regex]::Match($source,'(?s)/\*.*?\*/').Value.Trim();if(!$notice){throw "Missing original notice $name"}}
    else{
        $match=[regex]::Match($source,'(?s)\A\s*(?:(?:/\*.*?\*/|//[^\r\n]*)\s*)+')
        if(!$match.Success){throw "Missing original notice $name"};$notice=$match.Value.Trim()
    }
    $sections.Add($name+"`nSHA256 "+$entry[0].sha256+"`n"+$notice.Replace("`r`n","`n")+"`n")
}
[IO.Directory]::CreateDirectory($OutputDirectory)|Out-Null
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'R4AMD-NOTICES.txt'),($sections -join "`n"),[Text.UTF8Encoding]::new($true))
Write-Host 'R4AMD original AddrLib, image and SDMA/PM4/VCN notices and complete MIT text exported.'
