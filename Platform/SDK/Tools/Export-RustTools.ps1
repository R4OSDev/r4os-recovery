param(
    [Parameter(Mandatory)][string]$Destination,
    [Parameter(Mandatory)][string]$PackagerLinux,
    [Parameter(Mandatory)][string]$PackagerWindows,
    [Parameter(Mandatory)][string]$CatalogLinux,
    [Parameter(Mandatory)][string]$CatalogWindows,
    [Parameter(Mandatory)][string]$HeapRuntime,
    [Parameter(Mandatory)][string]$FacadeRuntime,
    [Parameter(Mandatory)][string]$StorageRuntime,
    [string]$SdkRoot='', [string]$ContractRoot='', [string]$ReleaseManifest='',
    [string]$LibraryContractLinux='', [string]$LibraryContractWindows='', [string]$CacheRoot='',
    [switch]$Technical
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
if (!$SdkRoot) { $SdkRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')) }
$workspace=$SdkRoot
if (!$ContractRoot) { throw 'Select the SDK-matched ContractRoot location explicitly.' }
$Destination=[IO.Path]::GetFullPath($Destination,$workspace)
$SdkRoot=[IO.Path]::GetFullPath($SdkRoot,$workspace);$ContractRoot=[IO.Path]::GetFullPath($ContractRoot,$workspace)
$PackagerLinux=[IO.Path]::GetFullPath($PackagerLinux,$workspace);$PackagerWindows=[IO.Path]::GetFullPath($PackagerWindows,$workspace)
$CatalogLinux=[IO.Path]::GetFullPath($CatalogLinux,$workspace);$CatalogWindows=[IO.Path]::GetFullPath($CatalogWindows,$workspace)
$HeapRuntime=[IO.Path]::GetFullPath($HeapRuntime,$workspace)
$FacadeRuntime=[IO.Path]::GetFullPath($FacadeRuntime,$workspace)
$StorageRuntime=[IO.Path]::GetFullPath($StorageRuntime,$workspace)
. (Join-Path $PSScriptRoot 'ProfileData.ps1')
. (Join-Path $PSScriptRoot 'ProfileSources.ps1')
$sdkProfiles=Read-R4SdkProfiles $SdkRoot
$pin=$sdkProfiles.Tools.tools.rust
if(!$CacheRoot){$CacheRoot=Join-Path $SdkRoot '.Installed/.Cache/Rust'}
if(!$ReleaseManifest){$ReleaseManifest=Join-Path $CacheRoot ('channel-rust-'+$pin.rust_version+'.toml')}
$ReleaseManifest=[IO.Path]::GetFullPath($ReleaseManifest,$workspace)
$utf8=[Text.UTF8Encoding]::new($false)
$canonicalCommits=@{}
function Hash([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()}
function Source-Bytes([string]$Root,[string]$Relative){
    if($Technical){return ,([IO.File]::ReadAllBytes((Join-Path $Root $Relative)))}
    # Match git archive, including the repository's declared EOL filters.
    # Edited checkout files can still use different, Git-equivalent newlines.
    $info=[Diagnostics.ProcessStartInfo]::new();$info.FileName='git';$info.UseShellExecute=$false
    $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    if(!$canonicalCommits.ContainsKey($Root)){throw 'Source revision was not pinned.'}
    foreach($arg in @('-C',$Root,'cat-file','--filters',($canonicalCommits[$Root]+':'+$Relative))){$info.ArgumentList.Add($arg)}
    $process=[Diagnostics.Process]::new();$process.StartInfo=$info;$bytes=[IO.MemoryStream]::new()
    try{
        if(!$process.Start()){throw 'Cannot read canonical source input.'}
        $errors=$process.StandardError.ReadToEndAsync();$process.StandardOutput.BaseStream.CopyTo($bytes);$process.WaitForExit()
        if($process.ExitCode -ne 0){throw ('Cannot read canonical source '+$Relative+': '+$errors.GetAwaiter().GetResult())}
        return ,($bytes.ToArray())
    }finally{$bytes.Dispose();$process.Dispose()}
}
function Source-Hash([string]$Root,[string]$Relative){
    return Get-R4SdkBytesDigest $Relative ([byte[]](Source-Bytes $Root $Relative))
}
function Source-Files([string]$Root,[string]$Directory){
    if($Technical){
        # Development inputs include new source files, never ignored compiler
        # caches below a tool project. Deleted files cannot be exported.
        $state=Get-R4SdkSourceState $Root
        return @($state.files|Where-Object { $_.StartsWith($Directory+'/',[StringComparison]::Ordinal) -and (Test-Path -LiteralPath (Join-Path $Root $_) -PathType Leaf) })
    }
    $files=@(& git -C $Root -c core.quotepath=false ls-files -- $Directory);if($LASTEXITCODE -ne 0){throw 'Cannot enumerate canonical source inputs.'}
    return $files
}
function Source([string]$Root){
    $commit=(& git -C $Root rev-parse HEAD)-join '';if($LASTEXITCODE -ne 0){throw 'Missing source repository.'}
    $dirty=@(& git -C $Root status --porcelain --untracked-files=normal);if($LASTEXITCODE -ne 0){throw 'Cannot inspect source repository.'}
    if(!$Technical -and $dirty.Count){throw "Clean source required: $Root"}
    return @{commit=$commit;dirty=($dirty.Count -ne 0)}
}
function Version([string]$Root){
    $text=[IO.File]::ReadAllText((Join-Path $Root 'build.zig.zon'))
    if($text -notmatch '\.version\s*=\s*"(\d+\.\d+\.\d+)"'){throw 'Missing package version.'}
    return $Matches[1]
}
function Crate([string]$Root,[string]$Relative){
    $text=[IO.File]::ReadAllText((Join-Path $Root $Relative))
    $package=[regex]::Match($text,'(?ms)^\[package\]\s*(.*?)(?=^\[|\z)').Groups[1].Value
    $name=[regex]::Match($package,'(?m)^name\s*=\s*"([^"]+)"').Groups[1].Value
    $version=[regex]::Match($package,'(?m)^version\s*=\s*"(\d+\.\d+\.\d+)"').Groups[1].Value
    if(!$name -or !$version){throw 'Missing Rust crate identity.'};return @{name=$name;version=$version}
}
function Copy-Input([string]$Source,[string]$Relative){
    $target=Join-Path $Destination $Relative
    [IO.Directory]::CreateDirectory((Split-Path $target -Parent))|Out-Null
    Copy-Item -LiteralPath $Source -Destination $target -Force
}
function Copy-Source([string]$Root,[string]$SourceRelative,[string]$ExportRelative){
    $target=Join-Path $Destination $ExportRelative
    [IO.Directory]::CreateDirectory((Split-Path $target -Parent))|Out-Null
    [IO.File]::WriteAllBytes($target,[byte[]](Source-Bytes $Root $SourceRelative))
}
function Check-Packager([string]$Path,[bool]$Windows){
    $bytes=[IO.File]::ReadAllBytes($Path)
    if($Windows){
        if($bytes.Length -lt 256 -or $bytes[0] -ne 77 -or $bytes[1] -ne 90){throw 'Packager is not a Windows PE executable.'}
        $pe=[BitConverter]::ToInt32($bytes,60)
        if($pe -lt 64 -or $pe+26 -gt $bytes.Length -or [BitConverter]::ToUInt32($bytes,$pe) -ne 17744 -or [BitConverter]::ToUInt16($bytes,$pe+4) -ne 34404 -or [BitConverter]::ToUInt16($bytes,$pe+24) -ne 523){throw 'Packager is not PE32+ x86_64.'}
    }else{
        if($bytes.Length -lt 64 -or [BitConverter]::ToUInt32($bytes,0) -ne 1179403647 -or $bytes[4] -ne 2 -or $bytes[5] -ne 1 -or [BitConverter]::ToUInt16($bytes,18) -ne 62){throw 'Packager is not ELF64 little-endian x86_64.'}
    }
}
function Component([string]$Name,[string]$Target){
    $header='[pkg.'+$Name+'.target.'+$Target+']'
    $match=[regex]::Match($manifestText,'(?ms)^'+[regex]::Escape($header)+'\r?\n(?<body>.*?)(?=^\[|\z)')
    if(!$match.Success){throw "Missing pinned Rust component $Name/$Target"}
    $body=$match.Groups['body'].Value
    if($body -notmatch '(?m)^available = true$'){throw "Unavailable pinned Rust component $Name/$Target"}
    $url=[regex]::Match($body,'(?m)^xz_url = "([^"]+)"$').Groups[1].Value
    $sha=[regex]::Match($body,'(?m)^xz_hash = "([0-9a-f]{64})"$').Groups[1].Value
    if(!$url.StartsWith('https://static.rust-lang.org/') -or !$sha){throw 'Invalid pinned Rust component identity.'}
    return @{component=$Name;target=$Target;url=$url;sha256=$sha}
}
if((Hash $ReleaseManifest) -cne $pin.manifest_sha256){throw 'Pinned Rust release manifest differs.'}
$manifestText=[IO.File]::ReadAllText($ReleaseManifest)
Check-Packager $PackagerLinux $false
Check-Packager $PackagerWindows $true
Check-Packager $CatalogLinux $false
Check-Packager $CatalogWindows $true
foreach($runtimeObject in @($HeapRuntime,$FacadeRuntime,$StorageRuntime)){
    Check-Packager $runtimeObject $false
    if([BitConverter]::ToUInt16([IO.File]::ReadAllBytes($runtimeObject),16) -ne 1){throw 'SDK runtime must be an ELF64 relocatable module object.'}
}
$sdkSource=Source $SdkRoot;$contractSource=Source $ContractRoot
$canonicalCommits[$SdkRoot]=$sdkSource.commit;$canonicalCommits[$ContractRoot]=$contractSource.commit
[IO.Directory]::CreateDirectory($Destination)|Out-Null
foreach($file in @('Rust.ps1','Rust.sh','Rust.bat','ProfileData.ps1','Setup.ps1','Setup.sh','Setup.bat')){Copy-Source $SdkRoot ('Tools/'+$file) ('Setup/'+$file)}
Copy-Source $SdkRoot 'build.zig.zon' 'build.zig.zon'
foreach($file in @('Build.json','Tools.json','Components.json')){Copy-Source $SdkRoot ('Profiles/'+$file) ('Profiles/'+$file)}
Copy-Source $SdkRoot 'Tools/Sync-ProfilePolicy.ps1' 'Tools/Sync-ProfilePolicy.ps1'
Copy-Source $SdkRoot 'r4os/generated/profile_policy.zig' 'r4os/generated/profile_policy.zig'
[IO.File]::WriteAllText((Join-Path $Destination 'Setup/RustToolchain.json'),($pin|ConvertTo-Json -Depth 100)+"`n",$utf8) # generated compatibility projection
Copy-Input $ReleaseManifest 'Profile/rust-release.toml'
Copy-Source $ContractRoot 'Module/CpuBaseline.json' 'Profile/CpuBaseline.json'
[IO.File]::WriteAllText((Join-Path $Destination 'Profile/ZigToolchain.json'),($sdkProfiles.Tools.tools.zig|ConvertTo-Json -Depth 100)+"`n",$utf8)
Copy-Source $SdkRoot 'r4os/rust_qualification.json' 'Profile/RustQualification.json'
Copy-Source $SdkRoot 'Inventory/LanguageParity.json' 'Profile/LanguageParity.json'
[IO.File]::WriteAllText((Join-Path $Destination 'Profile/RustModuleProfile.json'),($sdkProfiles.Build.codegen['rust-module']|ConvertTo-Json -Depth 100)+"`n",$utf8)
$templateSource=Join-Path $SdkRoot 'Templates';$templateDestination=Join-Path $Destination 'Profile/Templates'
if(Test-Path -LiteralPath $templateDestination){Remove-Item -LiteralPath $templateDestination -Recurse -Force}
foreach($relative in Source-Files $SdkRoot 'Templates'){Copy-Source $SdkRoot $relative ('Profile/'+$relative)}
Copy-Input $PackagerLinux 'bin/x86_64-unknown-linux-gnu/r4xbuilder'
Copy-Input $PackagerWindows 'bin/x86_64-pc-windows-msvc/r4xbuilder.exe'
Copy-Input $CatalogLinux 'bin/x86_64-unknown-linux-gnu/module-catalog'
Copy-Input $CatalogWindows 'bin/x86_64-pc-windows-msvc/module-catalog.exe'
Copy-Input $HeapRuntime 'Runtime/r4sdk_heap.o'
Copy-Input $FacadeRuntime 'Runtime/r4sdk_facades.o'
Copy-Input $StorageRuntime 'Runtime/r4sdk_storage.o'
if([bool]$LibraryContractLinux -ne [bool]$LibraryContractWindows){throw 'Both library-contract host tools must be supplied together.'}
if($LibraryContractLinux){
    $LibraryContractLinux=[IO.Path]::GetFullPath($LibraryContractLinux,$workspace)
    $LibraryContractWindows=[IO.Path]::GetFullPath($LibraryContractWindows,$workspace)
    Copy-Input $LibraryContractLinux 'bin/x86_64-unknown-linux-gnu/r4l-contract-gen'
    Copy-Input $LibraryContractWindows 'bin/x86_64-pc-windows-msvc/r4l-contract-gen.exe'
}
if($IsLinux){
    $linuxExecutables=@('Setup/Rust.sh','Setup/Setup.sh','bin/x86_64-unknown-linux-gnu/r4xbuilder','bin/x86_64-unknown-linux-gnu/module-catalog')
    if($LibraryContractLinux){$linuxExecutables+='bin/x86_64-unknown-linux-gnu/r4l-contract-gen'}
    $linuxPaths=@($linuxExecutables|ForEach-Object {Join-Path $Destination $_})
    & chmod 755 @linuxPaths
    if($LASTEXITCODE -ne 0){throw 'Cannot prepare executable toolset files.'}
}
$hosts=[ordered]@{}
foreach($name in @('Linux','Windows')){
    $hostTriple=$pin.hosts[$name].triple
    $required=@(foreach($component in @('rustc','cargo','rust-std')+@($pin.profiles.sdk.required_components)){Component $component $hostTriple};Component 'rust-std' $pin.kernel_target)
    $optional=@(foreach($component in $pin.profiles.sdk.optional_components){Component $(if($component -cin @('rustfmt','clippy')){$component+'-preview'}else{$component}) $hostTriple})
    $suffix=if($name -eq 'Windows'){'.exe'}else{''}
    $hosts[$name]=[ordered]@{triple=$hostTriple;bootstrap=@{url="https://static.rust-lang.org/rustup/archive/$($pin.rustup_version)/$hostTriple/rustup-init$suffix";sha256=$pin.hosts[$name].rustup_sha256};required=$required;optional=$optional;packager="bin/$hostTriple/r4xbuilder$suffix";catalog="bin/$hostTriple/module-catalog$suffix";packager_build_target=$(if($name -eq 'Windows'){'x86_64-windows-gnu'}else{'x86_64-linux-gnu'})}
    if($LibraryContractLinux){$hosts[$name]['r4l_contract_generator']="bin/$hostTriple/r4l-contract-gen$suffix"}
}
$sdkInputs=@(foreach($relative in @('Profiles/Build.json','Profiles/Tools.json','Profiles/Components.json','Tools/ProfileData.ps1','build.zig.zon','r4os/module_manifest.zig','r4os/import_spec.zig','r4os/startup_metadata.zig','r4os/module_capabilities.zig','r4os/rust_project.zig','r4os/rust_module_profile.json','r4os/rust_qualification.json','r4os/linker/r4os_module.ld','r4os/heap_runtime.zig','r4os/vm_allocator.zig','r4os/allocator_wait.zig','r4os/build.zig','Tools/ModuleCatalog/src/main.zig','Tools/ModuleCatalog/src/capabilities.zig','Tools/R4XBuilder/src/main.zig','Tools/Build-RustModule.ps1','Tools/RustBuildInputs.ps1','Tools/New-RustProject.ps1','Tools/New-Project.ps1','Tools/Build-Project.ps1','Tools/MatchedComponents.ps1','Inventory/LanguageParity.json','Rust/Cargo.toml')){@{path=$relative;sha256=Source-Hash $SdkRoot $relative}}
    foreach($directory in @('Rust/src','Templates','Shared/C','Shared/Generated/R4STD_Grapheme','r4os','Tools')){foreach($relative in Source-Files $SdkRoot $directory){@{path=$relative;sha256=Source-Hash $SdkRoot $relative}}})
$sdkInputs=@($sdkInputs|Sort-Object -Property path -Unique)
$contractInputs=@(foreach($relative in @('build.zig.zon','API/Generation2.json','Module/CpuBaseline.json','Generated/SDK/Rust/Cargo.toml','Generated/SDK/Rust/src/lib.rs')){@{path=$relative;sha256=Source-Hash $ContractRoot $relative}}
    foreach($directory in @('Generated/SDK/C','Generated/SDK/Zig','Generated/Generation2')){foreach($relative in Source-Files $ContractRoot $directory){@{path=$relative;sha256=Source-Hash $ContractRoot $relative}}})
$files=@(foreach($dir in @('Setup','Profile','Profiles','bin','Runtime')){Get-ChildItem -LiteralPath (Join-Path $Destination $dir) -File -Recurse|Sort-Object FullName|ForEach-Object {@{path=[IO.Path]::GetRelativePath($Destination,$_.FullName).Replace('\','/');bytes=$_.Length;sha256=Hash $_.FullName}}})
$files+=@{path='build.zig.zon';bytes=([IO.FileInfo](Join-Path $Destination 'build.zig.zon')).Length;sha256=Hash (Join-Path $Destination 'build.zig.zon')}
$exportedRustProfile=[ordered]@{schema=1;id=$pin.profiles.sdk.id;scope='pinned tools, not a Rust module build capability';technical=[bool]$Technical;
    source_hash_mode='r4os-files-sha256-lf-v1';sdk=@{version=Version $SdkRoot;source=$sdkSource;inputs=$sdkInputs;rust_crate=Crate $SdkRoot 'Rust/Cargo.toml';packager_source_sha256=Source-Hash $SdkRoot 'Tools/R4XBuilder/src/main.zig'};
    contract=@{version=Version $ContractRoot;source=$contractSource;inputs=$contractInputs;binding_crate=Crate $ContractRoot 'Generated/SDK/Rust/Cargo.toml';cpu_baseline='Profile/CpuBaseline.json'};
    profile_sources=$sdkProfiles.hashes;build_profiles=$sdkProfiles.Build.profiles;component_sets=$sdkProfiles.Components.sets;rust_version=$pin.rust_version;cargo_version=$pin.cargo_version;rustup_version=$pin.rustup_version;
    release_manifest=@{path='Profile/rust-release.toml';url="https://static.rust-lang.org/dist/channel-rust-$($pin.rust_version).toml";sha256=$pin.manifest_sha256};
    bare_target=$pin.kernel_target;hosts=$hosts;runtime=@{
        heap=@{path='Runtime/r4sdk_heap.o';sha256=Hash $HeapRuntime;cpu_baseline_sha256=Source-Hash $ContractRoot 'Module/CpuBaseline.json'};
        facades=@{path='Runtime/r4sdk_facades.o';sha256=Hash $FacadeRuntime;cpu_baseline_sha256=Source-Hash $ContractRoot 'Module/CpuBaseline.json'};
        storage=@{path='Runtime/r4sdk_storage.o';sha256=Hash $StorageRuntime;cpu_baseline_sha256=Source-Hash $ContractRoot 'Module/CpuBaseline.json'}
    };template_root='Profile/Templates';required_components=$pin.profiles.sdk.required_components;optional_components=$pin.profiles.sdk.optional_components;rust_src_required=$false;files=$files}
[IO.File]::WriteAllText((Join-Path $Destination 'RustToolsProfile.json'),($exportedRustProfile|ConvertTo-Json -Depth 20)+"`n",$utf8)
$readme=@'
R4OS pinned Rust tools
======================
This directory is an independent toolset, not a complete DevKit/workspace.
Read RustToolsProfile.json for exact SDK/Contract/source, host, component,
bootstrap, CPU-profile and packager hashes. Profiles/Build.json, Tools.json
and Components.json are the only maintained inputs. RustToolchain.json is
a generated compatibility projection. This toolset alone does not advertise Rust module
build support; that belongs to the matched SDK capability catalog.

PowerShell7 and HTTPS-capable curl are host prerequisites. Linux requires
an x86_64 host. Windows uses the same PS7 code with pinned x86_64 MSVC-host
Rust tools; Windows execution is not implied by this prepared package.

Linux:   ./Setup/Rust.sh setup
Windows: Setup\Rust.bat setup
Inspect: ./Setup/Rust.sh describe
Check:   ./Setup/Rust.sh check
Invoke:  ./Setup/Rust.sh cargo --version
Use --root ABSOLUTE_PATH and --cache-root ABSOLUTE_PATH before the command
to select other installation/cache roots. Otherwise both live below this
directory. Homes and exact toolchain selection are private to each call;
no global Rust installation, shell-profile edit or complete workspace is used.
--development-tools additionally requests optional rustfmt/Clippy. rust-src
is not required by the SDK baretarget profile. No toolchain update occurs.

Cargo.lock and matched source dependencies belong to the SDK project contract.
Official SDK build admission owns target/CPU/link flags and rejects conflicting
project/global overrides. Calling raw Cargo here is not that module builder.
'@
[IO.File]::WriteAllText((Join-Path $Destination 'README.txt'),$readme+"`n",[Text.UTF8Encoding]::new($true))
Write-Host "Standalone Rust toolset prepared: $Destination"
