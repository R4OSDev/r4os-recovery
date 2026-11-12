param([Parameter(Mandatory)][string]$LibrariesRoot,[switch]$Write)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'NativeProfiles.ps1')
$data=Read-R4SdkProfiles ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')))
$root=[IO.Path]::GetFullPath($LibrariesRoot)
if($Write){
    function Save-Projection([string]$Relative,$Object){[IO.File]::WriteAllText((Join-Path $root $Relative),($Object|ConvertTo-Json -Depth 100)+"`n",[Text.UTF8Encoding]::new($false))}
    Save-Projection 'Shared/Native/AMDProfile.json' $data.Build.codegen.'native-graphics'
    foreach($relative in $data.Build.codegen.'native-projections'.Keys){
        $expected=$data.Build.codegen.'native-projections'[$relative]
        if($relative.EndsWith('r4os-x86_64.json',[StringComparison]::Ordinal)){$value=$expected}
        else{$value=Get-Content -Raw -LiteralPath (Join-Path $root $relative)|ConvertFrom-Json -AsHashtable;foreach($key in $expected.Keys){$value[$key]=$expected[$key]}}
        Save-Projection $relative $value
    }
    $mesa=Get-Content -Raw -LiteralPath (Join-Path $root 'R4NV/Tools/Compiler/Sources.lock.json')|ConvertFrom-Json -AsHashtable
    $mesa.host_tools=$data.Tools.tools.graphics
    Save-Projection 'R4NV/Tools/Compiler/Sources.lock.json' $mesa
    $nak=Get-Content -Raw -LiteralPath (Join-Path $root 'R4NAK/Tools/Sources.lock.json')|ConvertFrom-Json -AsHashtable
    $nak.rust_version=$data.Tools.tools.graphics.rustc
    Save-Projection 'R4NAK/Tools/Sources.lock.json' $nak
    Save-Projection 'R4VK/Tools/ShaderTools.lock.json' $data.Tools.tools.shader
}
Test-R4SdkNativeProjections @{libraries_root=$root;data=$data}
Write-Host 'SDK native projections verified.'
