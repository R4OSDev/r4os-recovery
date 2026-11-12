param([Parameter(Mandatory)][string]$KernelRoot,[string]$ContractRoot='',[string]$LibrariesRoot='',[switch]$Write)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'ProfileData.ps1')
$data=Read-R4SdkProfiles ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')))
$KernelRoot=[IO.Path]::GetFullPath($KernelRoot)
$manifest=Join-Path $KernelRoot 'Cargo.toml'
$text=[IO.File]::ReadAllText($manifest).Replace("`r`n","`n")
$original=$text
if(!$ContractRoot -or !$LibrariesRoot){throw 'KernelSdkComponentRootsRequired'}
foreach($binding in @(@('r4os-contract',(Join-Path $ContractRoot 'Generated/SDK/Rust/Cargo.toml')),@('r4os-text-core',(Join-Path $LibrariesRoot 'R4STD/Rust/Cargo.toml')))){
    $bindingSource=[IO.File]::ReadAllText($binding[1])
    $version=[regex]::Match($bindingSource,'(?m)^version\s*=\s*"([^"]+)"').Groups[1].Value
    if(!$version){throw 'KernelSdkCrateVersionMissing'}
    $pattern='(?m)^'+$binding[0]+'\s*=.*$'
    if(![regex]::IsMatch($text,$pattern)){throw 'KernelSdkCrateBindingMissing'}
    $text=[regex]::Replace($text,$pattern,($binding[0]+' = { version = "='+$version+'" }'))
}
$text=[regex]::Replace($text,'(?m)^edition\s*=.*$',('edition = "'+$data.Build.codegen.kernel.edition+'"'))
$minimum=($data.Tools.tools.rust.rust_version.Split('.')[0..1] -join '.')
$text=[regex]::Replace($text,'(?m)^rust-version\s*=.*$',('rust-version = "'+$minimum+'"'))
$release="[profile.release]`n"
foreach($pair in $data.Build.codegen.kernel.cargo_release.GetEnumerator()){
    $key=$pair.Key.ToLowerInvariant().Replace('_','-')
    $value=if($pair.Value -cmatch '^(true|false|[0-9]+)$'){$pair.Value}else{'"'+$pair.Value+'"'}
    $release+=$key+' = '+$value+"`n"
}
$text=[regex]::Replace($text,'(?ms)^\[profile\.release\]\s*.*?(?=^\[|\z)',$release)
$toolchain="[toolchain]`nchannel = `""+$data.Tools.tools.rust.rust_version+"`"`nprofile = `"minimal`"`ntargets = [`""+$data.Build.codegen.kernel.target+"`"]`n"
$toolPath=Join-Path $KernelRoot 'rust-toolchain.toml'
if($Write){
    [IO.File]::WriteAllText($manifest,$text,[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($toolPath,$toolchain,[Text.UTF8Encoding]::new($false))
}elseif($text -cne $original -or [IO.File]::ReadAllText($toolPath).Replace("`r`n","`n") -cne $toolchain){throw 'KernelSdkProjectionMismatch'}
Write-Host 'Kernel SDK projections verified.'
