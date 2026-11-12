param(
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$Zig,
    [Parameter(Mandatory)][string]$RustLauncher,
    [Parameter(Mandatory)][string]$FacadeGenerator,
    [Parameter(Mandatory)][string]$DataGenerator,
    [Parameter(Mandatory)][string]$WebGenerator,
    [Parameter(Mandatory)][string]$SubsystemGenerator,
    [Parameter(Mandatory)][string]$WorkRoot
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$sdk=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
foreach($name in @('ContractRoot','Zig','RustLauncher','FacadeGenerator','DataGenerator','WebGenerator','SubsystemGenerator','WorkRoot')){Set-Variable $name ([IO.Path]::GetFullPath((Get-Variable $name -ValueOnly)))}
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty test directory.'}
[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
$success=$false;$previous=$env:CARGO_ENCODED_RUSTFLAGS
try{
    & $DataGenerator check (Join-Path $sdk 'Shared/C/include/r4os/data_helpers.h') (Join-Path $sdk 'r4os/generated/data_fingerprint.zig')
    if($LASTEXITCODE -ne 0){throw 'SDK data boundary drift.'}
    & $WebGenerator check (Join-Path $sdk 'Shared/C/include/r4os/web_helpers.h') (Join-Path $sdk 'r4os/generated/web_fingerprint.zig')
    if($LASTEXITCODE -ne 0){throw 'SDK web boundary drift.'}
    & $SubsystemGenerator check (Join-Path $sdk 'Shared/C/include/r4os/subsystem_helpers.h') (Join-Path $sdk 'r4os/generated/subsystem_fingerprint.zig')
    if($LASTEXITCODE -ne 0){throw 'SDK subsystem boundary drift.'}
    & $FacadeGenerator check (Join-Path $sdk 'Rust/src/c_facades.rs')
    if($LASTEXITCODE -ne 0){throw 'C/Rust facade drift.'}
    Push-Location $sdk
    try{
        & $Zig build ('--fork='+$ContractRoot) -Dfacade-runtime-only=true -Dfacade-host-test=true --prefix (Join-Path $WorkRoot 'native') -j1
        if($LASTEXITCODE -ne 0){throw 'Native SDK facade objects failed.'}
    }finally{Pop-Location}
    $object=Join-Path $WorkRoot 'subsystem-c.o'
    & $Zig cc -O1 -UNDEBUG -Werror -fPIC -ffunction-sections -fdata-sections -I (Join-Path $sdk 'Shared/C/include') -I (Join-Path $ContractRoot 'Generated/SDK/C/include') -I (Join-Path $ContractRoot 'Generated/Generation2/C/include') -c (Join-Path $sdk 'Tests/Simulation/SubsystemParity.c') -o $object
    if($LASTEXITCODE -ne 0){throw 'Combined C subsystem consumer failed.'}
    $source=(Join-Path $sdk 'Tests/Simulation/RustSubsystem.rs').Replace('\','/')
    $manifest=@"
[package]
name="r4os-subsystem-helper-interop"
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
        if($LASTEXITCODE -ne 0){throw 'Native SDK C/Rust subsystem cases failed.'}
        $negative=Join-Path $WorkRoot 'negative.rs'
        [IO.File]::WriteAllText((Join-Path $WorkRoot 'Cargo.toml'),$manifest.Replace($source,$negative.Replace('\','/')),[Text.UTF8Encoding]::new($false))
        $cases=@(
            @('E0133','pub fn bad(){let _=r4os_sdk::subsystems::raw::R4SdkSubsystemVerifyAbi(0);}'),
            @('E0499','pub fn bad(){let mut bytes=[0u8;127];let encoded=r4os_sdk::subsystems::encode_launch(b"C:\\TEMP\\G.BIN",&[],&mut bytes).unwrap();let launch=r4os_sdk::subsystems::Launch::parse(encoded).unwrap();bytes.fill(0);let _=launch.guest();}'),
            @('E0502','pub fn bad(s:&mut core::mem::MaybeUninit<r4os_sdk::subsystems::raw::R4SdkSubsystemCatalogCatalog>,w:&mut core::mem::MaybeUninit<r4os_sdk::subsystems::raw::R4SdkUpdateInventoryInventory>,bytes:&mut [u8],v:&r4os_sdk::subsystems::Callbacks<''_,''_>){let catalog=r4os_sdk::subsystems::Catalog::load(s,w,bytes,v).unwrap();bytes.fill(0);let _=catalog.count();}'),
            @('E0502','pub fn bad(s:&mut core::mem::MaybeUninit<r4os_sdk::subsystems::raw::R4SdkSubsystemCatalogCatalog>,w:&mut core::mem::MaybeUninit<r4os_sdk::subsystems::raw::R4SdkUpdateInventoryInventory>,bytes:&[u8],v:&r4os_sdk::subsystems::Callbacks<''_,''_>){let catalog=r4os_sdk::subsystems::Catalog::load(s,w,bytes,v).unwrap();let _=w.as_ptr();let _=catalog.count();}'),
            @('E0277','fn send<T:Send>(){}pub fn bad(){send::<r4os_sdk::subsystems::Runtime<''static>>();}'),
            @('E0502','pub fn bad(b:&mut r4os_sdk::published_frame::Bridge<''_>,p:&mut[u32]){use r4os_sdk::published_frame::*;let s=unsafe{Published::xrgb(p,8,8,Stamp{binding_generation:1,revision:1,palette_revision:0},Damage::Full)}.unwrap();let f=b.sync(s).unwrap();p.fill(0);core::hint::black_box(f.updated());}'),
            @('E0499','pub fn bad(b:&mut r4os_sdk::published_frame::Bridge<''_>,s:r4os_sdk::published_frame::Published<''_>){let f=b.sync(s).unwrap();let _=b.close();core::hint::black_box(f.updated());}'),
            @('E0505','extern crate alloc;pub fn bad(b:&mut r4os_sdk::published_frame::Bridge<''_>,palette:alloc::vec::Vec<u32>){use r4os_sdk::published_frame::*;let pixels=[0u8;64];let s=unsafe{Published::indexed(&pixels,&palette,8,8,Stamp{binding_generation:1,revision:1,palette_revision:1},Damage::Full)};let f=b.sync(s).unwrap();drop(palette);core::hint::black_box(f.updated());}'),
            @('E0277','fn send<T:Send>(){}pub fn bad(){send::<r4os_sdk::published_frame::Bridge<''static>>();}')
        )
        foreach($case in $cases){
            [IO.File]::WriteAllText($negative,$case[1],[Text.UTF8Encoding]::new($false))
            $log=(& $pwsh -NoLogo -NoProfile -File $RustLauncher cargo check --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'negative-target') --config $patch --message-format=json 2>&1|Out-String)
            if($LASTEXITCODE -eq 0 -or $log -notmatch ('"code":"'+$case[0]+'"')){throw ('Missing expected subsystem diagnostic '+$case[0]+': '+$log)}
        }
    }finally{Pop-Location}
    $success=$true;Write-Host ('SDK subsystem helpers: original native C/Rust cores and '+$cases.Count+' actual unsafe/ownership negatives pass; separate guest consumer qualifies the bare ABI.')
}finally{
    $env:CARGO_ENCODED_RUSTFLAGS=$previous
    if($success){Remove-Item -LiteralPath $WorkRoot -Recurse -Force}
}
# The final expected compile rejection must not escape as this helper's result.
$global:LASTEXITCODE=0
