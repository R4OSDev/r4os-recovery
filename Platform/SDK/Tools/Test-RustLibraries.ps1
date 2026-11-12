param(
    [Parameter(Mandatory)][string]$LibrariesRoot,
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$ToolsRoot,
    [Parameter(Mandatory)][string]$Generator,
    [Parameter(Mandatory)][string]$InstallRoot,
    [Parameter(Mandatory)][string]$CacheRoot,
    [Parameter(Mandatory)][string]$ZigRoot,
    [Parameter(Mandatory)][string]$WorkRoot,
    [switch]$Technical
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$sdk=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
foreach($name in @('LibrariesRoot','ContractRoot','ToolsRoot','Generator','InstallRoot','CacheRoot','ZigRoot','WorkRoot')){
    Set-Variable -Name $name -Value ([IO.Path]::GetFullPath((Get-Variable -Name $name -ValueOnly)))
}
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty test root.'}
[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
$utf8=[Text.UTF8Encoding]::new($false);$pwsh=(Get-Process -Id $PID).Path
$zig=Join-Path $ZigRoot ('zig'+$(if($IsWindows){'.exe'}else{''}))
$pin=Get-Content -Raw -LiteralPath (Join-Path $ToolsRoot 'Profile/ZigToolchain.json')|ConvertFrom-Json
if(((& $zig version)-join '').Trim() -cne $pin.version){throw 'Use the matched C compiler pin.'}
$packages=[Collections.Generic.List[string]]::new();$count=0
foreach($project in Get-ChildItem -LiteralPath $LibrariesRoot -Directory|Sort-Object Name){
    $manifest=Join-Path $project.FullName 'module.R4MF';if(!(Test-Path -LiteralPath $manifest)){continue}
    $fields=@{};$exports=[Collections.Generic.List[string]]::new()
    foreach($line in [IO.File]::ReadLines($manifest)){
        if(!$line.Trim() -or $line.TrimStart().StartsWith('#') -or !$line.Contains('=')){continue}
        $key,$value=$line.Split('=',2)
        if($key -ceq 'EXPORT' -and !$value.StartsWith('Query:') -and !$value.StartsWith('Query2:')){$exports.Add($value)}else{$fields[$key]=$value}
    }
    if($fields.KIND -cne 'R4L'){continue}
    if(!$fields.ContainsKey('BINDING_RUST')){throw 'Current library lacks its Rust projection.'}
    $arguments=@('--check','--module-name',$fields.NAME)
    foreach($export in $exports){$arguments+=@('--export',$export)}
    foreach($entry in @(@('CONTRACT','contract'),@('CONTRACT_BASELINE','baseline'),@('IMPLEMENTATION_ZIG','implementation-zig'),@('BINDING_ZIG','binding-zig'),@('BINDING_C','binding-c'),@('BINDING_RUST','binding-rust'),@('CONFORMANCE_ZIG','fixture-zig'),@('CONFORMANCE_C','fixture-c'),@('API_REFERENCE','docs'))){$arguments+=@(('--'+$entry[1]),(Join-Path $project.FullName $fields[$entry[0]]))}
    & $Generator @arguments
    if($LASTEXITCODE -ne 0){throw 'Local generator/baseline drift.'}
    $binding=Join-Path $project.FullName 'Bindings/Rust'
    $path=$binding.Replace('\','/').Replace('"','\"')
    $packages.Add(('r4os-'+$fields.NAME.ToLowerInvariant()+' = { path = "'+$path+'" }'))
    & $zig cc -target x86_64-freestanding-none -std=c11 -Wall -Wextra -Werror -c -o (Join-Path $WorkRoot ($fields.NAME+'.o')) -I (Join-Path $sdk 'Shared/C/include') -I (Join-Path $ContractRoot 'Generated/SDK/C/include') -I (Join-Path $ContractRoot 'Generated/Generation2/C/include') -I (Join-Path $project.FullName 'Bindings/C') (Join-Path $project.FullName $fields.CONFORMANCE_C)
    if($LASTEXITCODE -ne 0){throw 'Existing C conformance failed.'}
    ++$count
}
if($count -ne 12){throw 'Review the current canonical library set before changing this test.'}
$hostRoot=Join-Path $WorkRoot 'Host';[IO.Directory]::CreateDirectory($hostRoot)|Out-Null
$packages.Add(('r4os-sdk = { path = "'+(Join-Path $sdk 'Rust').Replace('\','/').Replace('"','\"')+'" }'))
$cargo=@"
[package]
name="r4os-library-contract-conformance"
version="0.1.0"
edition="2024"
[lib]
path="lib.rs"
[dependencies]
$($packages -join "`n")
[workspace]
"@
[IO.File]::WriteAllText((Join-Path $hostRoot 'Cargo.toml'),$cargo,$utf8)
[IO.File]::WriteAllText((Join-Path $hostRoot 'lib.rs'),"#![no_std]`npub const LIBRARIES: usize = 12;`n",$utf8)
$patches=@('--config',('patch.crates-io.r4os-contract.path="'+(Join-Path $ContractRoot 'Generated/SDK/Rust').Replace('\','/')+'"'),'--config',('patch.crates-io.r4os-sdk.path="'+(Join-Path $sdk 'Rust').Replace('\','/')+'"'))
$runner=Join-Path $ToolsRoot 'Setup/Rust.ps1'
& $pwsh -NoLogo -NoProfile -File $runner --root $InstallRoot --cache-root $CacheRoot cargo check --offline --manifest-path (Join-Path $hostRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'target') @patches
if($LASTEXITCODE -ne 0){throw 'Rust generated layout/slot conformance failed.'}
$hostSource=Join-Path $hostRoot 'lib.rs';$positive=[IO.File]::ReadAllText($hostSource)
try{
    foreach($generation in @(1,2)){
        $app=if($generation -eq 2){'App2'}else{'App'}
        $init=if($generation -eq 2){'init2'}else{'init'}
        $negative='#![no_std]'+"`n"+('pub fn escape(app: &r4os_sdk::'+$app+'<''_>) -> r4os_r4std::TextV1Client<''static> { r4os_r4std::TextV1Client::'+$init+'(app).unwrap() }')+"`n"
        [IO.File]::WriteAllText($hostSource,$negative,$utf8)
        $failure=Join-Path $WorkRoot ('lifetime'+$generation+'.log')
        & $pwsh -NoLogo -NoProfile -File $runner --root $InstallRoot --cache-root $CacheRoot cargo check --offline --manifest-path (Join-Path $hostRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'target') @patches > $failure 2>&1
        if($LASTEXITCODE -eq 0 -or !([IO.File]::ReadAllText($failure).Contains('lifetime may not live long enough'))){throw 'Library client escaped its exact App/App2 borrow or failed for an unrelated reason.'}
    }
}finally{[IO.File]::WriteAllText($hostSource,$positive,$utf8)}

$guest=Join-Path $WorkRoot 'Guest'
Copy-Item -LiteralPath (Join-Path $sdk 'Tests/Build/RustLibrary') -Destination $guest -Recurse
Move-Item -LiteralPath (Join-Path $guest 'module.R4MF.template') -Destination (Join-Path $guest 'module.R4MF')
$template=[IO.File]::ReadAllText((Join-Path $guest 'Cargo.toml.template'))
$template=$template.Replace('{R4StdRoot}',(Join-Path $LibrariesRoot 'R4STD/Bindings/Rust').Replace('\','/').Replace('"','\"'))
$template=$template.Replace('{R4FontRoot}',(Join-Path $LibrariesRoot 'R4FONT/Bindings/Rust').Replace('\','/').Replace('"','\"'))
$template=$template.Replace('{R4ImgRoot}',(Join-Path $LibrariesRoot 'R4IMG/Bindings/Rust').Replace('\','/').Replace('"','\"'))
[IO.File]::WriteAllText((Join-Path $guest 'Cargo.toml'),$template,$utf8)
$include=Join-Path $guest 'include';[IO.Directory]::CreateDirectory($include)|Out-Null
Copy-Item -LiteralPath (Join-Path $LibrariesRoot 'R4STD/Bindings/C/r4std_abi.h') -Destination $include
& $pwsh -NoLogo -NoProfile -File $runner --root $InstallRoot --cache-root $CacheRoot cargo generate-lockfile --offline --manifest-path (Join-Path $guest 'Cargo.toml') @patches
if($LASTEXITCODE -ne 0){throw 'Explicit fixture lock creation failed.'}
$arguments=@('-NoLogo','-NoProfile','-File',(Join-Path $PSScriptRoot 'Build-RustModule.ps1'),'-ProjectRoot',$guest,'-SdkRoot',$sdk,'-ContractRoot',$ContractRoot,'-ToolsRoot',$ToolsRoot,'-InstallRoot',$InstallRoot,'-CacheRoot',$CacheRoot,'-OutputRoot',(Join-Path $WorkRoot 'GuestOutput'),'-DependencyRoot',$LibrariesRoot,'-ZigRoot',$ZigRoot)
if($Technical){$arguments+='-Technical'}
& $pwsh @arguments > (Join-Path $WorkRoot 'guest-build.log') 2>&1
if($LASTEXITCODE -ne 0){throw 'Rust/C real library consumer build failed; see owned guest-build.log.'}
Write-Host 'All12 Rust/C local contracts/layouts/slots pass; real R4STD Rust/C guest consumer built. Guest execution is a separate explicit qualification.'
