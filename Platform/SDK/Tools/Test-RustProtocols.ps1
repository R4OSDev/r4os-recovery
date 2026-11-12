param(
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$Zig,
    [Parameter(Mandatory)][string]$RustLauncher,
    [Parameter(Mandatory)][string]$WorkRoot
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$sdk=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
foreach($name in @('ContractRoot','Zig','RustLauncher','WorkRoot')){Set-Variable $name ([IO.Path]::GetFullPath((Get-Variable $name -ValueOnly)))}
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty test directory.'}
[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
$success=$false;$previous=$env:CARGO_ENCODED_RUSTFLAGS
try{
    & $Zig test -OReleaseSafe --dep protocol --dep r4os_contract ('-Mroot='+ (Join-Path $sdk 'Tests/Simulation/ProtocolOwners.zig')) --dep r4os_contract ('-Mprotocol='+ (Join-Path $sdk 'r4os/protocol.zig')) ('-Mr4os_contract='+ (Join-Path $ContractRoot 'Generated/SDK/Zig/package.zig')) ('-femit-bin='+ (Join-Path $WorkRoot 'original-owner'))
    if($LASTEXITCODE -ne 0){throw 'Original Zig protocol owner case failed.'}
    $object=Join-Path $WorkRoot 'protocol-c.o'
    & $Zig cc -O1 -UNDEBUG -Werror -fPIC -ffunction-sections -fdata-sections -I (Join-Path $sdk 'Shared/C/include') -I (Join-Path $ContractRoot 'Generated/SDK/C/include') -I (Join-Path $ContractRoot 'Generated/Generation2/C/include') -c (Join-Path $sdk 'Tests/Simulation/ProtocolParity.c') -o $object
    if($LASTEXITCODE -ne 0){throw 'Combined C protocol consumer failed.'}
    $source=(Join-Path $sdk 'Tests/Simulation/RustProtocol.rs').Replace('\','/')
    $manifest=@"
[package]
name="r4os-protocol-helper-interop"
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
    foreach($file in @($object)){$flags+=@('-C',('link-arg='+$file))}
    $env:CARGO_ENCODED_RUSTFLAGS=$flags -join [char]31
    $pwsh=(Get-Process -Id $PID).Path
    Push-Location $WorkRoot
    try{
        & $pwsh -NoLogo -NoProfile -File $RustLauncher cargo test --release --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'target') --config $patch --config 'profile.release.opt-level="z"' --config 'profile.release.overflow-checks=true' --config 'profile.release.lto="fat"' -- --test-threads=1
        if($LASTEXITCODE -ne 0){throw 'Native SDK C/Rust protocol cases failed.'}
        $negative=Join-Path $WorkRoot 'negative.rs'
        [IO.File]::WriteAllText((Join-Path $WorkRoot 'Cargo.toml'),$manifest.Replace($source,$negative.Replace('\','/')),[Text.UTF8Encoding]::new($false))
        $cases=@(
            @('E0133','pub fn bad(){let _=r4os_sdk::protocol::Protocol::from_raw(core::ptr::null());}'),
            @('E0133','pub fn bad(a:&mut r4os_sdk::protocol::Allocation<''_>){a.release();}'),
            @('E0277','fn send<T:Send>(){}pub fn bad(){send::<r4os_sdk::protocol::Gate>();}'),
            @('E0308','unsafe extern "C" fn init()->i32{0}unsafe extern "C" fn shutdown()->i32{0}unsafe extern "C" fn query(_: *mut r4os_sdk::abi::ProtocolStatus)->i32{0}unsafe extern "C" fn dispatch(_:u32,_:*const r4os_sdk::abi::ProtocolBuffer,_:*mut r4os_sdk::abi::ProtocolBuffer)->i32{0}r4os_sdk::protocol_entry!(init,shutdown,query,dispatch);')
        )
        foreach($case in $cases){
            [IO.File]::WriteAllText($negative,$case[1],[Text.UTF8Encoding]::new($false))
            $log=(& $pwsh -NoLogo -NoProfile -File $RustLauncher cargo check --offline --manifest-path (Join-Path $WorkRoot 'Cargo.toml') --target-dir (Join-Path $WorkRoot 'negative-target') --config $patch --message-format=json 2>&1|Out-String)
            if($LASTEXITCODE -eq 0 -or $log -notmatch ('"code":"'+$case[0]+'"')){throw ('Missing expected protocol diagnostic '+$case[0]+': '+$log)}
        }
    }finally{Pop-Location}
    $success=$true;Write-Host ('SDK protocol helpers: original Zig and native C/Rust cores and '+$cases.Count+' actual unsafe/ownership negatives pass; separate guest consumer qualifies the bare ABI.')
}finally{
    $env:CARGO_ENCODED_RUSTFLAGS=$previous
    if($success){Remove-Item -LiteralPath $WorkRoot -Recurse -Force}
}
