param([switch]$Write, [string]$SdkRoot='')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if(!$SdkRoot){$SdkRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))}
. (Join-Path $PSScriptRoot 'ProfileData.ps1')
$data=Read-R4SdkProfiles $SdkRoot
$outputs=[ordered]@{'r4os/rust_module_profile.json'=($data.Build.codegen['rust-module']|ConvertTo-Json -Depth 100)+"`n"}
foreach($name in $data.Build.native_c_profiles.Keys){$outputs['BuildProfiles/'+$name+'.ini']=$data.Build.native_c_profiles[$name]}
foreach($relative in $outputs.Keys){
    $path=Join-Path $SdkRoot $relative
    if($Write){[IO.Directory]::CreateDirectory((Split-Path $path -Parent))|Out-Null;[IO.File]::WriteAllText($path,$outputs[$relative],[Text.UTF8Encoding]::new($false))}
    elseif(!(Test-Path -LiteralPath $path -PathType Leaf) -or [IO.File]::ReadAllText($path).Replace("`r`n","`n") -cne $outputs[$relative].Replace("`r`n","`n")){throw "SdkProfileProjectionMismatch: $relative"}
}
Write-Host ('SDK profile projections verified: '+$outputs.Count)
