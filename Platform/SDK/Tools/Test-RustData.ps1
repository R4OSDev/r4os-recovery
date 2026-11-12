param(
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$Zig,
    [Parameter(Mandatory)][string]$RustLauncher,
    [Parameter(Mandatory)][string]$FacadeGenerator,
    [Parameter(Mandatory)][string]$DataGenerator,
    [Parameter(Mandatory)][string]$WorkRoot
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$sdk=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
foreach($name in @('ContractRoot','Zig','RustLauncher','FacadeGenerator','DataGenerator','WorkRoot')){Set-Variable $name ([IO.Path]::GetFullPath((Get-Variable $name -ValueOnly)))}
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty test directory.'}
[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
$success=$false;$previous=$env:CARGO_ENCODED_RUSTFLAGS
try{
    & $DataGenerator check (Join-Path $sdk 'Shared/C/include/r4os/data_helpers.h') (Join-Path $sdk 'r4os/generated/data_fingerprint.zig')
    if($LASTEXITCODE -ne 0){throw 'SDK data boundary drift.'}
    & $FacadeGenerator check (Join-Path $sdk 'Rust/src/c_facades.rs')
    if($LASTEXITCODE -ne 0){throw 'C/Rust facade drift.'}
    Push-Location $sdk
    try{
        & $Zig build ('--fork='+$ContractRoot) -Dfacade-runtime-only=true -Dfacade-host-test=true --prefix (Join-Path $WorkRoot 'native') -j1
        if($LASTEXITCODE -ne 0){throw 'Native SDK facade objects failed.'}
    }finally{Pop-Location}
    $object=Join-Path $WorkRoot 'data-c.o'
    & $Zig cc -O1 -UNDEBUG -Werror -fPIC -ffunction-sections -fdata-sections -I (Join-Path $sdk 'Shared/C/include') -I (Join-Path $ContractRoot 'Generated/SDK/C/include') -I (Join-Path $ContractRoot 'Generated/Generation2/C/include') -c (Join-Path $sdk 'Tests/Simulation/DataParity.c') -o $object
    if($LASTEXITCODE -ne 0){throw 'Combined C data facade consumer failed.'}
    $source=(Join-Path $sdk 'Tests/Simulation/RustData.rs').Replace('\','/')
    $manifest=@"
[package]
name="r4os-data-helper-interop"
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
        if($LASTEXITCODE -ne 0){throw 'Native SDK C/Rust data helper cases failed.'}
        $negative=Join-Path $WorkRoot 'negative.rs'
        [IO.File]::WriteAllText((Join-Path $WorkRoot 'Cargo.toml'),$manifest.Replace($source,$negative.Replace('\','/')),[Text.UTF8Encoding]::new($false))
        $cases=@(
            @('E0133','pub fn bad(){let _=r4os_sdk::data::raw::R4SdkDataVerifyAbi(0);}'),
            @('E0277','fn unpin<T:Unpin>(){} pub fn bad(){unpin::<r4os_sdk::data::DataStorage>();}'),
            @('E0505','pub fn bad(d:&r4os_sdk::data::Data<''_,''_>,b:alloc::vec::Vec<u8>){let mut depth=[0;8];let mut j=d.json(&b,&mut depth).unwrap();drop(b);let _=j.next_token();} extern crate alloc;'),
            @('E0499','pub fn bad(a:&mut r4os_sdk::data::Arena<''_,''_>,b:&[u8]){let m=a.manifest(b"module.R4MF",b).unwrap();let _=a.reset();let _=m.name();}'),
            @('E0502','pub fn bad(p:&mut r4os_sdk::data::SearchParams){let v=p.get(b"a").unwrap();let _=p.set(b"a",b"b");let _=v.map(|b|b.len());}'),
            @('E0133','pub fn bad(b:&r4os_sdk::abi::ProtocolBuffer){let _=r4os_sdk::wire::native::Input::<u64>::new(b,r4os_sdk::wire::native::SizeMode::Exact,r4os_sdk::wire::native::Header::NONE,0);}'),
            @('E0505','pub fn bad(b:alloc::vec::Vec<u8>){let mut c=r4os_sdk::wire::Reader::new(&b).unwrap();let v=c.take(1).unwrap();drop(b);core::hint::black_box(v);} extern crate alloc;'),
            @('E0502','pub fn bad(b:&mut[u8]){let mut w=r4os_sdk::wire::Writer::new(b).unwrap();let v=w.written().unwrap();let _=w.put(b"x");core::hint::black_box(v);}'),
            @('E0505','extern crate alloc; pub fn bad(b:alloc::vec::Vec<u8>){let mut a=r4os_sdk::cli::ArgCursor::new(&b,Default::default()).unwrap();let t=a.next_token().unwrap().unwrap();drop(b);core::hint::black_box(t.bytes());}'),
            @('E0499','pub fn bad(b:&mut[u8]){let q=r4os_sdk::cli::BoundedDiagnosticBuffer::new(b).unwrap();b.fill(1);let _=q.stats();}'),
            @('E0521','pub fn bad(q:&mut r4os_sdk::cli::BoundedDiagnosticBuffer<''_>){let mut saved:Option<&[u8]>=None;let _=q.flush_once(8,|c|{saved=Some(c.bytes);r4os_sdk::cli::Ack::accepted(0)});core::hint::black_box(saved);}'),
            @('E0505','extern crate alloc;pub fn bad(b:alloc::vec::Vec<u8>,s:r4os_sdk::time::checked::ClockSample){let w=r4os_sdk::transfer::WriteAll::new(&b,s,r4os_sdk::resources::Timeout::Forever).unwrap();drop(b);let _=w.progress();}'),
            @('E0499','pub fn bad(b:&mut[u8],s:r4os_sdk::time::checked::ClockSample){let r=r4os_sdk::transfer::ReadExact::new(b,s,r4os_sdk::resources::Timeout::Forever).unwrap();b.fill(0);let _=r.progress();}'),
            @('E0521','pub fn bad(r:&mut r4os_sdk::transfer::ReadExact<''_>,s:r4os_sdk::time::checked::ClockSample){let mut saved:Option<&mut[u8]>=None;let _=r.step(4,false,&mut ||Ok(s),|c|{saved=Some(c.bytes);r4os_sdk::transfer::Ack::bytes(0)});core::hint::black_box(saved);}'),
            @('E0133','pub fn bad(c:&r4os_sdk::platform2::Context<''_>){let _=r4os_sdk::transfer::Tcp::from_borrowed_handles(c,1,2);}'),
            @('E0502','pub fn bad(r:&mut r4os_sdk::inventory::ProgramInventoryReader<''_>){let v=r.view().unwrap();let _=r.restart();core::hint::black_box(v);}'),
            @('E0499','pub fn bad(b:&mut[core::mem::MaybeUninit<r4os_sdk::abi::ProgramLifecycleSnapshot>],p:&r4os_sdk::inventory::NativeProvider,s:r4os_sdk::time::checked::ClockSample){let r=unsafe{r4os_sdk::inventory::LifecycleReader::from_native_provider(b,1,p,s,r4os_sdk::resources::Timeout::Forever)}.unwrap();b.fill(core::mem::MaybeUninit::uninit());let _=r.progress();}'),
            @('E0502','pub fn bad(s:&mut r4os_sdk::device_snapshot::Snapshot<''_>,c:&mut r4os_sdk::device_snapshot::Cursor){let p=s.page(c,1).unwrap();let _=s.capture(false);core::hint::black_box(p.records);}'),
            @('E0499','pub fn bad(b:&mut[core::mem::MaybeUninit<r4os_sdk::abi::DeviceInventoryRecord>],p:&r4os_sdk::device_snapshot::NativeProvider){let s=unsafe{r4os_sdk::device_snapshot::Snapshot::from_native_provider(p,b)}.unwrap();b.fill(core::mem::MaybeUninit::uninit());let _=s.progress();}'),
            @('E0499','pub fn bad<''a>(c:&''a r4os_sdk::platform2::Context<''a>,p:&''a core::ffi::CStr,b:&''a mut[core::mem::MaybeUninit<r4os_sdk::abi::DirectoryMetadataEntry2>]){let mut d=r4os_sdk::metadata2::Directory::new(c,p,b).unwrap();let page=d.next_page().unwrap();d.reset();core::hint::black_box(page);}'),
            @('E0499','pub fn bad<''a>(c:&''a r4os_sdk::platform2::Context<''a>,p:&''a core::ffi::CStr,b:&''a mut[core::mem::MaybeUninit<r4os_sdk::abi::DirectoryMetadataEntry2>]){let mut d=r4os_sdk::metadata2::Directory::new(c,p,b).unwrap();b.fill(core::mem::MaybeUninit::uninit());core::hint::black_box(d.next_page());}'),
            @('E0502','pub fn bad(c:&mut r4os_sdk::text_metrics::Cache<''_>){let rows=c.rows().unwrap();let _=c.prepare(2,0);core::hint::black_box(rows);}'),
            @('E0499','pub fn bad<''a>(c:&''a r4os_sdk::platform2::Context<''a>,s:&''a str,b:&''a mut[core::mem::MaybeUninit<r4os_sdk::abi::FontAdvance2>]){let mut cache=r4os_sdk::text_metrics::Cache::new(c,s,b).unwrap();b.fill(core::mem::MaybeUninit::uninit());core::hint::black_box(cache.prepare(1,0));}'),
            @('E0502','pub fn bad(s:&mut r4os_sdk::file_picker::Session<''_>){let rows=s.rows().unwrap();let _=s.begin(c"C:\\DIR",0);core::hint::black_box(rows);}'),
            @('E0499','pub fn bad<''a>(c:&''a r4os_sdk::platform2::Context<''a>,a:&''a mut[core::mem::MaybeUninit<r4os_sdk::file_picker::Row>],b:&''a mut[core::mem::MaybeUninit<r4os_sdk::file_picker::Row>]){let s=r4os_sdk::file_picker::Session::new(c,a,b,r4os_sdk::file_picker::Mode::Open,b"").unwrap();a.fill(core::mem::MaybeUninit::uninit());core::hint::black_box(s.progress());}'),
            @('E0277','fn send<T:Send>(){} pub fn bad(){send::<r4os_sdk::file_picker::Session<''static>>();}')
        )
        foreach($case in $cases){
            if($case -isnot [array] -or $case.Count -ne 2 -or $case[0] -cnotmatch '^E\d{4}$'){throw 'Malformed compiler-negative case; no diagnostic claim.'}
            [IO.File]::WriteAllText($negative,$case[1],[Text.UTF8Encoding]::new($false))
            $log=(& $pwsh -NoLogo -NoProfile -File $RustLauncher cargo check --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'negative-target') --config $patch --message-format=json 2>&1|Out-String)
            if($LASTEXITCODE -eq 0 -or $log -notmatch ('"code":"'+$case[0]+'"')){throw ('Missing expected data helper diagnostic '+$case[0]+': '+$log)}
        }
    }finally{Pop-Location}
    $success=$true;Write-Host ('SDK data helpers: shared native C/Rust cases and '+$cases.Count+' actual unsafe/ownership negatives pass. Real JSON/ZIP protocol calls require the separate guest consumer.')
}finally{
    $env:CARGO_ENCODED_RUSTFLAGS=$previous
    if($success){Remove-Item -LiteralPath $WorkRoot -Recurse -Force}
}
