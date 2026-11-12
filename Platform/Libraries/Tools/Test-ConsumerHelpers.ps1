param(
    [Parameter(Mandatory)][string]$SdkRoot,
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$Zig,
    [Parameter(Mandatory)][string]$RustLauncher,
    [Parameter(Mandatory)][string]$Generator,
    [Parameter(Mandatory)][string]$RustGenerator,
    [Parameter(Mandatory)][string]$WorkRoot,
    [switch]$Media
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$libraries=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
foreach($name in @('SdkRoot','ContractRoot','Zig','RustLauncher','Generator','RustGenerator','WorkRoot')){Set-Variable $name ([IO.Path]::GetFullPath((Get-Variable $name -ValueOnly)))}
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty test directory.'}
[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
$success=$false;$previous=$env:CARGO_ENCODED_RUSTFLAGS
try{
    & $Generator check (Join-Path $libraries 'Shared/C/include/r4libraries/helpers.h') (Join-Path $libraries 'Shared/Language/fingerprint.zig')
    if($LASTEXITCODE -ne 0){throw 'Library native boundary drift.'}
    & $RustGenerator check (Join-Path $libraries 'Shared/Rust/src/raw.rs')
    if($LASTEXITCODE -ne 0){throw 'Library Rust projection drift.'}
    Push-Location $SdkRoot
    try{
        & $Zig build ('--fork='+$ContractRoot) ('-Dlibrary-helpers-root='+$libraries) -Dlibrary-helpers-host-test=true --prefix (Join-Path $WorkRoot 'native') -j1
        if($LASTEXITCODE -ne 0){throw 'Native library helper objects failed.'}
    }finally{Pop-Location}
    $extra=@()
    if($Media){
        Push-Location $SdkRoot
        try{
            & $Zig build ('--fork='+$ContractRoot) ('-Dlibrary-helpers-root='+$libraries) -Dlibrary-helpers-oracle-only=true --prefix (Join-Path $WorkRoot 'oracle') -j1
            if($LASTEXITCODE -ne 0){throw 'Existing media/recording oracle build failed.'}
        }finally{Pop-Location}
        $extra+=Join-Path $WorkRoot 'oracle/lib/r4libraries_media_oracle.o'
        $object=Join-Path $WorkRoot 'media.o'
        $includes=@()
        foreach($lib in @('R4GFX','R4ENC','R4VIDEO','R4ACO','R4NAK')){$includes+=@('-I',(Join-Path $libraries ($lib+'/Bindings/C')))}
        & $Zig cc -O1 -UNDEBUG -Werror -fPIC -ffunction-sections -fdata-sections @includes -I (Join-Path $libraries 'Shared/C/include') -I (Join-Path $SdkRoot 'Shared/C/include') -I (Join-Path $ContractRoot 'Generated/SDK/C/include') -I (Join-Path $ContractRoot 'Generated/Generation2/C/include') -c (Join-Path $libraries 'Shared/Tests/media.c') -o $object
        if($LASTEXITCODE -ne 0){throw 'Combined media/graphics C headers and transport cases failed.'}
        $extra+=$object
    }
    $pure=Join-Path $WorkRoot 'pure.o'
    & $Zig cc -O1 -UNDEBUG -Werror -fPIC -ffunction-sections -fdata-sections -I (Join-Path $libraries 'R4STD/Bindings/C') -I (Join-Path $libraries 'R4IMG/Bindings/C') -I (Join-Path $libraries 'R4FONT/Bindings/C') -I (Join-Path $libraries 'Shared/C/include') -I (Join-Path $SdkRoot 'Shared/C/include') -I (Join-Path $ContractRoot 'Generated/SDK/C/include') -I (Join-Path $ContractRoot 'Generated/Generation2/C/include') -c (Join-Path $libraries 'Shared/Tests/pure.c') -o $pure
    if($LASTEXITCODE -ne 0){throw 'C library helper consumer failed.'}
    $source=(Join-Path $libraries $(if($Media){'Shared/Tests/media_native.rs'}else{'Shared/Tests/native.rs'})).Replace('\','/')
    $crate=(Join-Path $libraries 'Shared/Rust').Replace('\','/')
    $manifest=@"
[package]
name="r4os-library-helper-interop"
version="0.1.0"
edition="2024"
[lib]
path="$source"
[dependencies]
r4os-library-helpers={path="$crate"}
r4os-sdk={path="$($SdkRoot.Replace('\','/'))/Rust",features=["alloc"]}
[workspace]
"@
    [IO.File]::WriteAllText((Join-Path $WorkRoot 'Cargo.toml'),$manifest,[Text.UTF8Encoding]::new($false))
    $patches=@('--config',('patch.crates-io.r4os-contract.path="'+(Join-Path $ContractRoot 'Generated/SDK/Rust').Replace('\','/')+'"'),'--config',('patch.crates-io.r4os-sdk.path="'+(Join-Path $SdkRoot 'Rust').Replace('\','/')+'"'))
    $flags=@('-D','warnings')
    foreach($object in (@((Join-Path $WorkRoot 'native/lib/r4libraries_helpers.o'),(Join-Path $WorkRoot 'native/lib/r4libraries_facades.o'),$pure)+$extra)){$flags+=@('-C',('link-arg='+$object))}
    $env:CARGO_ENCODED_RUSTFLAGS=$flags -join [char]31
    $pwsh=(Get-Process -Id $PID).Path
    Push-Location $WorkRoot
    try{
        & $pwsh -NoLogo -NoProfile -File $RustLauncher cargo test --release --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'target') @patches --config 'profile.release.opt-level="z"' --config 'profile.release.overflow-checks=true' --config 'profile.release.lto="fat"' -- --test-threads=1
        if($LASTEXITCODE -ne 0){throw 'Native C/Rust library helper interop failed.'}
        $negative=Join-Path $WorkRoot 'negative.rs'
        [IO.File]::WriteAllText((Join-Path $WorkRoot 'Cargo.toml'),$manifest.Replace($source,$negative.Replace('\','/')),[Text.UTF8Encoding]::new($false))
        $cases=@(
            @('E0133','pub fn bad(){let _=r4os_library_helpers::raw::R4LibrariesVerifyAbi(0);}'),
            @('E0505','pub fn bad(heap:r4os_library_helpers::Heap,fonts:&r4os_library_helpers::font::Fonts<''_>){let d=fonts.decoder(&heap,100000).unwrap();drop(heap);drop(d);}'),
            @('E0505','pub fn bad(d:&mut r4os_library_helpers::font::Decoder<''_,''_>,b:alloc::vec::Vec<u8>){let f=d.open_face(&b,0).unwrap();drop(b);drop(f);}'),
            @('E0502','pub fn bad(s:&r4os_library_helpers::standard::Standard<''_>,o:&mut[u8]){let w=s.writer(o).unwrap();let _=o.len();drop(w);}'),
            @('E0277','fn send<T:Send>(){} pub fn bad(){send::<r4os_library_helpers::font::Decoder<''static,''static>>();}')
        )
        if($Media){$cases+=,@('E0521','pub fn bad(m:&mut r4os_library_helpers::media::Mux,packet:&[u8]){let mut saved=alloc::vec::Vec::new();let _=m.packet(packet,true,0,1,|b|{saved.push(b);true});drop(saved);}')}
        if($Media){$cases+=,@('E0505','pub fn bad(app:&r4os_sdk::App<''_>,heap:r4os_library_helpers::Heap,b:&[u8]){let p=r4os_library_helpers::graphics::ColorProfile::open(app,&heap,b,1,0).unwrap();drop(heap);drop(p);}')}
        foreach($case in $cases){
            [IO.File]::WriteAllText($negative,"extern crate alloc;`n"+$case[1]+"`n",[Text.UTF8Encoding]::new($false))
            $log=(& $pwsh -NoLogo -NoProfile -File $RustLauncher cargo check --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'negative-target') @patches --message-format=json 2>&1|Out-String)
            if($LASTEXITCODE -eq 0 -or $log -notmatch ('"code":"'+$case[0]+'"')){throw ('Missing expected lifetime/unsafe diagnostic '+$case[0]+': '+$log)}
        }
    }finally{Pop-Location}
    $success=$true;Write-Host ('Library helpers: shared native C/Rust cases and '+$cases.Count+' ownership/unsafe negatives pass. Real tables require the separate guest consumer.')
}finally{
    $env:CARGO_ENCODED_RUSTFLAGS=$previous
    if($success){Remove-Item -LiteralPath $WorkRoot -Recurse -Force}
}
