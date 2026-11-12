param(
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$Zig,
    [Parameter(Mandatory)][string]$RustLauncher,
    [Parameter(Mandatory)][string]$FacadeGenerator,
    [Parameter(Mandatory)][string]$DataGenerator,
    [Parameter(Mandatory)][string]$WebGenerator,
    [Parameter(Mandatory)][string]$UpdateGenerator,
    [Parameter(Mandatory)][string]$WorkRoot
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$sdk=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
foreach($name in @('ContractRoot','Zig','RustLauncher','FacadeGenerator','DataGenerator','WebGenerator','UpdateGenerator','WorkRoot')){Set-Variable $name ([IO.Path]::GetFullPath((Get-Variable $name -ValueOnly)))}
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty test directory.'}
[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
$success=$false;$previous=$env:CARGO_ENCODED_RUSTFLAGS
try{
    & $DataGenerator check (Join-Path $sdk 'Shared/C/include/r4os/data_helpers.h') (Join-Path $sdk 'r4os/generated/data_fingerprint.zig')
    if($LASTEXITCODE -ne 0){throw 'SDK data boundary drift.'}
    & $WebGenerator check (Join-Path $sdk 'Shared/C/include/r4os/web_helpers.h') (Join-Path $sdk 'r4os/generated/web_fingerprint.zig')
    if($LASTEXITCODE -ne 0){throw 'SDK web boundary drift.'}
    & $UpdateGenerator check (Join-Path $sdk 'Shared/C/include/r4os/update_helpers.h') (Join-Path $sdk 'r4os/generated/update_fingerprint.zig')
    if($LASTEXITCODE -ne 0){throw 'SDK update boundary drift.'}
    & $FacadeGenerator check (Join-Path $sdk 'Rust/src/c_facades.rs')
    if($LASTEXITCODE -ne 0){throw 'C/Rust facade drift.'}
    Push-Location $sdk
    try{
        & $Zig build ('--fork='+$ContractRoot) -Dfacade-runtime-only=true -Dfacade-host-test=true --prefix (Join-Path $WorkRoot 'native') -j1
        if($LASTEXITCODE -ne 0){throw 'Native SDK facade objects failed.'}
    }finally{Pop-Location}
    $object=Join-Path $WorkRoot 'update-c.o'
    & $Zig cc -O1 -UNDEBUG -Werror -fPIC -ffunction-sections -fdata-sections -I (Join-Path $sdk 'Shared/C/include') -I (Join-Path $ContractRoot 'Generated/SDK/C/include') -I (Join-Path $ContractRoot 'Generated/Generation2/C/include') -c (Join-Path $sdk 'Tests/Simulation/UpdateParity.c') -o $object
    if($LASTEXITCODE -ne 0){throw 'Combined C update consumer failed.'}
    $source=(Join-Path $sdk 'Tests/Simulation/RustUpdate.rs').Replace('\','/')
    $manifest=@"
[package]
name="r4os-update-helper-interop"
version="0.1.0"
edition="2024"
[lib]
path="$source"
[dependencies]
r4os-sdk={path="$($sdk.Replace('\','/'))/Rust",features=["alloc"]}
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
        if($LASTEXITCODE -ne 0){throw 'Native SDK C/Rust update cases failed.'}
        $negative=Join-Path $WorkRoot 'negative.rs'
        [IO.File]::WriteAllText((Join-Path $WorkRoot 'Cargo.toml'),$manifest.Replace($source,$negative.Replace('\','/')),[Text.UTF8Encoding]::new($false))
        $cases=@(
            @('E0133','pub fn bad(){let _=r4os_sdk::update::raw::R4SdkUpdateVerifyAbi(0);}'),
            @('E0502','pub fn bad(j:&mut r4os_sdk::update::Journal<''_>,c:&r4os_sdk::update::Callbacks<''_,''_>){let source=j.source().unwrap();let _=j.rollback(c);let _=source.len();}'),
            @('E0502','pub fn bad(mut bytes:alloc::vec::Vec<u8>){let mut storage=core::mem::MaybeUninit::uninit();let i=r4os_sdk::update::Inventory::parse(&mut storage,&bytes).unwrap();bytes.clear();let _=i.count();}extern crate alloc;'),
            @('E0499','pub fn bad(h:&mut r4os_sdk::update::HostFile<''_>){let mut d=h.device().unwrap();let _=h.release();let _=d.flush();}'),
            @('E0277','fn send<T:Send>(){}pub fn bad(){send::<r4os_sdk::update::Journal<''static>>();}')
        )
        foreach($case in $cases){
            [IO.File]::WriteAllText($negative,$case[1],[Text.UTF8Encoding]::new($false))
            $log=(& $pwsh -NoLogo -NoProfile -File $RustLauncher cargo check --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'negative-target') --config $patch --message-format=json 2>&1|Out-String)
            if($LASTEXITCODE -eq 0 -or $log -notmatch ('"code":"'+$case[0]+'"')){throw ('Missing expected update diagnostic '+$case[0]+': '+$log)}
        }
    }finally{Pop-Location}
    $success=$true;Write-Host ('SDK update helpers: original native C/Rust cores and '+$cases.Count+' actual unsafe/ownership negatives pass; separate guest consumer qualifies the bare ABI.')
}finally{
    $env:CARGO_ENCODED_RUSTFLAGS=$previous
    if($success){Remove-Item -LiteralPath $WorkRoot -Recurse -Force}
}
