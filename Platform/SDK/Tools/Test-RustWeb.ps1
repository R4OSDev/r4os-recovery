param(
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$Zig,
    [Parameter(Mandatory)][string]$RustLauncher,
    [Parameter(Mandatory)][string]$FacadeGenerator,
    [Parameter(Mandatory)][string]$DataGenerator,
    [Parameter(Mandatory)][string]$WebGenerator,
    [Parameter(Mandatory)][string]$WorkRoot
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$sdk=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
foreach($name in @('ContractRoot','Zig','RustLauncher','FacadeGenerator','DataGenerator','WebGenerator','WorkRoot')){Set-Variable $name ([IO.Path]::GetFullPath((Get-Variable $name -ValueOnly)))}
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty test directory.'}
[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
$success=$false;$previous=$env:CARGO_ENCODED_RUSTFLAGS
try{
    & $DataGenerator check (Join-Path $sdk 'Shared/C/include/r4os/data_helpers.h') (Join-Path $sdk 'r4os/generated/data_fingerprint.zig')
    if($LASTEXITCODE -ne 0){throw 'SDK data boundary drift.'}
    & $WebGenerator check (Join-Path $sdk 'Shared/C/include/r4os/web_helpers.h') (Join-Path $sdk 'r4os/generated/web_fingerprint.zig')
    if($LASTEXITCODE -ne 0){throw 'SDK web boundary drift.'}
    & $FacadeGenerator check (Join-Path $sdk 'Rust/src/c_facades.rs')
    if($LASTEXITCODE -ne 0){throw 'C/Rust facade drift.'}
    Push-Location $sdk
    try{
        & $Zig build ('--fork='+$ContractRoot) -Dfacade-runtime-only=true -Dfacade-host-test=true --prefix (Join-Path $WorkRoot 'native') -j1
        if($LASTEXITCODE -ne 0){throw 'Native SDK facade objects failed.'}
    }finally{Pop-Location}
    $object=Join-Path $WorkRoot 'web-c.o'
    & $Zig cc -O1 -UNDEBUG -Werror -fPIC -ffunction-sections -fdata-sections -I (Join-Path $sdk 'Shared/C/include') -I (Join-Path $ContractRoot 'Generated/SDK/C/include') -I (Join-Path $ContractRoot 'Generated/Generation2/C/include') -c (Join-Path $sdk 'Tests/Simulation/WebParity.c') -o $object
    if($LASTEXITCODE -ne 0){throw 'Combined C web consumer failed.'}
    $source=(Join-Path $sdk 'Tests/Simulation/RustWeb.rs').Replace('\','/')
    $manifest=@"
[package]
name="r4os-web-helper-interop"
version="0.1.0"
edition="2024"
[lib]
path="$source"
[dependencies]
r4os-sdk={path="$($sdk.Replace('\','/'))/Rust"}
[workspace]
"@
    [IO.File]::WriteAllText((Join-Path $WorkRoot 'Cargo.toml'),$manifest,[Text.UTF8Encoding]::new($false))
    $patch='patch.crates-io.r4os-contract.path="'+(Join-Path $ContractRoot 'Generated/SDK/Rust').Replace('\','/')+'"'
    $flags=@('-D','warnings')
    foreach($file in @((Join-Path $WorkRoot 'native/lib/r4sdk_facades.o'),(Join-Path $WorkRoot 'native/lib/r4sdk_storage.o'),$object)){$flags+=@('-C',('link-arg='+$file))}
    $env:CARGO_ENCODED_RUSTFLAGS=$flags -join [char]31
    $pwsh=(Get-Process -Id $PID).Path
    Push-Location $WorkRoot
    try{
        & $pwsh -NoLogo -NoProfile -File $RustLauncher cargo test --release --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'target') --config $patch --config 'profile.release.opt-level="z"' --config 'profile.release.overflow-checks=true' --config 'profile.release.lto="fat"' -- --test-threads=1
        if($LASTEXITCODE -ne 0){throw 'Native SDK C/Rust web cases failed.'}
        $negative=Join-Path $WorkRoot 'negative.rs'
        [IO.File]::WriteAllText((Join-Path $WorkRoot 'Cargo.toml'),$manifest.Replace($source,$negative.Replace('\','/')),[Text.UTF8Encoding]::new($false))
        $cases=@(
            @('E0133','pub fn bad(){let _=r4os_sdk::web::raw::R4SdkWebVerifyAbi(0);}'),
            @('E0503','pub fn bad(mut s:core::mem::MaybeUninit<r4os_sdk::web::raw::R4SdkWebHtmlDocument>){let d=r4os_sdk::web::Document::parse(&mut s,b"<p>x</p>",b"text/html",true).unwrap();drop(s);let _=d.node_count();}'),
            @('E0502','pub fn bad(c:&mut r4os_sdk::web::Canvas<''_,''_>){let p=c.pixels(1).unwrap();let _=c.ensure(1,2,2);let _=p.len();}'),
            @('E0499','pub fn bad(a:&mut r4os_sdk::data::Arena<''_,''_>){let mut s=core::mem::MaybeUninit::uninit();let mut m=r4os_sdk::web::Memory::from_arena(&mut s,a).unwrap();let _=a.reset();let _=unsafe{m.native()};}'),
            @('E0277','fn send<T:Send>(){} pub fn bad(){send::<r4os_sdk::web::Script<''static,''static,''static>>();}')
        )
        foreach($case in $cases){
            [IO.File]::WriteAllText($negative,$case[1],[Text.UTF8Encoding]::new($false))
            $log=(& $pwsh -NoLogo -NoProfile -File $RustLauncher cargo check --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'negative-target') --config $patch --message-format=json 2>&1|Out-String)
            if($LASTEXITCODE -eq 0 -or $log -notmatch ('"code":"'+$case[0]+'"')){throw ('Missing expected web diagnostic '+$case[0]+': '+$log)}
        }
    }finally{Pop-Location}
    $success=$true;Write-Host ('SDK web helpers: original native C/Rust engines and '+$cases.Count+' actual unsafe/ownership negatives pass; separate guest consumer qualifies the bare ABI.')
}finally{
    $env:CARGO_ENCODED_RUSTFLAGS=$previous
    if($success){Remove-Item -LiteralPath $WorkRoot -Recurse -Force}
}
