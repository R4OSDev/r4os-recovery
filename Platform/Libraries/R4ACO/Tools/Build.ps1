# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([string]$OutputRoot,[ValidateRange(1,32)][int]$Jobs=4)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
$sdkCpp23Flags=@($script:R4SdkNative.data.Build.codegen.'native-flags'.cpp23_flags)
$sdkLibcxxVkFlags=@($script:R4SdkNative.data.Build.codegen.'native-flags'.libcxx_vk_flags)
if(!$IsWindows -and !$IsLinux){throw 'Supported hosts: Windows and Linux.'}
$unit=[IO.Path]::GetFullPath('..',$PSScriptRoot)
$libraries=[IO.Path]::GetFullPath('..',$unit)
& (Join-Path $PSScriptRoot 'Shaders.ps1')
$settings=@{}
foreach($line in Get-Content (Join-Path $libraries 'Settings.R4S')){
    if($line -match '^([A-Z_]+)=(.+)$'){$settings[$Matches[1]]=$Matches[2]}
}
function Resolve([string]$Base,[string]$Key){[IO.Path]::GetFullPath($settings[$Key].Replace('\','/'),$Base)}
function Hash([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()}
function Tool([string]$Name){(Get-Command $Name -CommandType Application -ErrorAction Stop|Select-Object -First 1).Source}
$workspace=Resolve $libraries 'WORKSPACE_ROOT'
$repositories=Resolve $libraries 'REPOSITORIES_ROOT'
$artifacts=Resolve $workspace 'ARTIFACTS_ROOT'
$devkit=Resolve $workspace 'DEVKIT_ROOT'
$clang=Tool $(if($IsWindows){'clang.exe'}else{('clang-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0])})
$ar=Tool $(if($IsWindows){'llvm-ar.exe'}else{('llvm-ar-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0])})
$nm=Tool $(if($IsWindows){'llvm-nm.exe'}else{('llvm-nm-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0])})
$git=Tool 'git'
$python=Tool $(if($IsWindows){'python.exe'}else{'python3'})
$version=@(& $clang --version)
$profile=Get-Content -Raw (Join-Path $libraries 'Shared/Native/AMDProfile.json')|ConvertFrom-Json
if($LASTEXITCODE -or $version[0] -notmatch ('(?<![0-9.])'+[regex]::Escape($profile.clang)+'(?![0-9.])')){throw 'Pinned Clang version required.'}
$resource=([string](& $clang -print-resource-dir)).Trim()
if($LASTEXITCODE){throw 'Clang target headers unavailable.'}
$hostName=if($IsWindows){'Windows-x64'}else{'Linux-x64'}
$cache=Join-Path $artifacts "Native/R4ACO/$hostName/Compiler-26.2.2"
[IO.Directory]::CreateDirectory($cache)|Out-Null
$guard=[IO.File]::Open((Join-Path $cache 'build.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try {
    $source=Join-Path $cache 'Source';$generated=Join-Path $cache 'Generated';$objects=Join-Path $cache 'Objects'
    $roots=@{source=$source;generated=$generated;unit=$unit;libraries=$libraries;include=(Join-Path $libraries 'R4GL/Port/Include');
        zig=(Resolve $devkit 'ZIG_ROOT');sdk=(Resolve $repositories 'SDK_ROOT');contract=(Resolve $repositories 'CONTRACT_ROOT');clang_resource=$resource}
    function Expand([string]$Value){
        foreach($key in $roots.Keys){$Value=$Value.Replace(('$'+'{'+$key+'}'),$roots[$key].Replace('\','/'))}
        if($Value.Contains('$'+'{')){throw "Unknown source placeholder: $Value"};return $Value
    }
    $plan=Get-Content -Raw (Join-Path $PSScriptRoot 'Portability.json')|ConvertFrom-Json
    $catalog=Get-Content -Raw (Join-Path $unit 'ThirdParty/Sources.json')|ConvertFrom-Json
    $cpp=Get-Content -Raw (Join-Path $PSScriptRoot 'CppSources.json')|ConvertFrom-Json
    if($plan.schema -ne 1 -or $plan.units.Count -ne 373 -or $catalog.upstream_version -ne '26.2.2'){throw 'Unexpected compiler source plan.'}
    $original=Join-Path $unit $catalog.original_root
    foreach($file in $catalog.files){if((Hash (Join-Path $original $file.path)) -ne $file.sha256){throw "Original source drift: $($file.path)"}}
    foreach($file in @($catalog.patches)+@($catalog.additional_licenses)){if((Hash (Join-Path $unit $file.path)) -ne $file.sha256){throw "Patch/license drift: $($file.path)"}}
    foreach($file in $cpp.files){if((Hash (Join-Path $roots.zig $file.path)) -ne $file.sha256){throw "libc++ source drift: $($file.path)"}}
    $inputs=@($clang,$ar,$nm,(Join-Path $roots.zig $(if($IsWindows){'zig.exe'}else{'zig'})),(Join-Path $unit 'module.R4MF'),(Join-Path $unit 'build.zig'))
    foreach($directory in @('Source','Bindings','Port','Tools','ThirdParty')){
        $inputs+=@(Get-ChildItem (Join-Path $unit $directory) -File -Recurse|ForEach-Object FullName)
    }
    foreach($directory in @((Join-Path $libraries 'Shared/Native'),$roots.include,(Join-Path $libraries 'R4NAK/Port/Include'),
        (Join-Path $libraries 'R4NAK/ThirdParty/stb'),(Join-Path $roots.zig 'lib/libcxx'),(Join-Path $resource 'include'),
        (Join-Path $roots.zig 'lib/compiler_rt'),(Join-Path $roots.zig 'lib/std/math'),
        (Join-Path $roots.sdk 'Shared/C/include'),(Join-Path $roots.contract 'Generated/SDK/C/include'), (Join-Path $roots.contract 'Generated/Generation2/C/include'))){
        $inputs+=@(Get-ChildItem $directory -File -Recurse|ForEach-Object FullName)
    }
    foreach($provider in @('Math','Scan')){
        $manifest=Get-Content -Raw (Join-Path $libraries "Shared/Native/$provider/Sources.json")|ConvertFrom-Json
        $inputs+=@($manifest.files|ForEach-Object {Join-Path $roots.zig $_.path})
    }
    $identities=@(foreach($file in $inputs|Sort-Object -Unique){[ordered]@{path=[IO.Path]::GetRelativePath($workspace,$file).Replace('\','/');sha256=(Hash $file)}})
    $identity=[ordered]@{sdk_profiles=$script:R4SdkNative.data.hashes;schema=1;host=$hostName;compiler=$version[0];profile='Picasso-GFX9-wave64-native-resource-ABI1-2';inputs=$identities}
    $id=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($identity|ConvertTo-Json -Depth 6 -Compress)))).ToLowerInvariant()
    $recordPath=Join-Path $cache 'native.json'
    $valid=$false
    if(Test-Path $recordPath){
        $record=Get-Content -Raw $recordPath|ConvertFrom-Json
        if($record.identity -eq $id -and $record.outputs.Count -eq 3){
            foreach($file in $record.outputs){if((Hash (Join-Path $cache $file.path)) -ne $file.sha256){throw "Compiler cache altered: $($file.path)"}}
            $valid=$true
        }
    }
    if(!$valid){
        [IO.File]::Delete($recordPath)
        foreach($directory in @($source,$generated,$objects)){
            if(Test-Path $directory){Remove-Item -LiteralPath $directory -Recurse -Force}
            [IO.Directory]::CreateDirectory($directory)|Out-Null
        }
        foreach($file in $catalog.files){
            $destination=Join-Path $source $file.path
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))|Out-Null
            Copy-Item -LiteralPath (Join-Path $original $file.path) -Destination $destination
        }
        Push-Location ([IO.Path]::GetPathRoot($source))
        try {
            foreach($patch in $catalog.patches){
                $path=Join-Path $unit $patch.path
                & $git apply --unsafe-paths ('--directory='+$source) --check $path
                if($LASTEXITCODE){throw 'Compiler patch check failed.'}
                & $git apply --unsafe-paths ('--directory='+$source) $path
                if($LASTEXITCODE){throw 'Compiler patch failed.'}
            }
        } finally {Pop-Location}
        foreach($step in $plan.generators){
            foreach($relative in $step.outputs){[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName((Join-Path $generated $relative)))|Out-Null}
            $info=[Diagnostics.ProcessStartInfo]::new()
            $info.FileName=$python;$info.WorkingDirectory=$generated;$info.UseShellExecute=$false
            $info.Environment['PYTHONDONTWRITEBYTECODE']='1';$info.Environment['PYTHONHASHSEED']='0'
            $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
            foreach($argument in $step.arguments){$info.ArgumentList.Add((Expand $argument))}
            $process=[Diagnostics.Process]::Start($info)
            $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
            $process.WaitForExit();$text=$stdout.GetAwaiter().GetResult();$errors=$stderr.GetAwaiter().GetResult()
            if($process.ExitCode){throw "Generator failed: $($step.outputs -join ',') $errors"};$process.Dispose()
            if($step.PSObject.Properties['capture']){[IO.File]::WriteAllText((Join-Path $generated $step.capture),$text,[Text.UTF8Encoding]::new($false))}
            foreach($relative in $step.outputs){if(!(Test-Path (Join-Path $generated $relative))){throw "Missing generated output: $relative"}}
        }
        $flags=@($profile.cpp_flags+$plan.flags|ForEach-Object {Expand $_})
        $flags+=@("-ffile-prefix-map=$workspace=/R4OS","-ffile-prefix-map=$source=/R4ACO/Mesa","-ffile-prefix-map=$generated=/R4ACO/Generated")
        $cFlags=@($flags|Where-Object {$_ -notmatch '^-std=|^-fno-(exceptions|rtti)$|^-nostdinc\+\+$'})+'-std=c11'
        $units=@(foreach($entry in $plan.units){
            $path=Join-Path $(if($entry.generated_source){$generated}else{$source}) $entry.source
            $arguments=if($entry.language -eq 'c'){$cFlags}else{$flags+@('-Werror=global-constructors')}
            if($entry.source -eq 'src/amd/compiler/aco_opcodes.cpp'){
                # std::bitset's C++23 constexpr constructor removes the ELF
                # startup dependency; the warning forbids dynamic fallback.
                $arguments+=@($sdkCpp23Flags)
            }
            [pscustomobject]@{name=$entry.name;source=$path;arguments=$arguments}
        })
        $private=Join-Path $generated 'Cpp'
        [IO.Directory]::CreateDirectory((Join-Path $private 'include'))|Out-Null
        Copy-Item (Join-Path $roots.zig 'lib/libcxx/src/new.cpp') (Join-Path $private 'new.cpp')
        $header=[IO.File]::ReadAllText((Join-Path $roots.zig 'lib/libcxx/src/include/overridable_function.h'))
        $needle='#elif defined(_LIBCPP_OBJECT_FORMAT_ELF) && !defined(__NVPTX__)'
        if(!$header.Contains($needle)){throw 'libc++ override source drift.'}
        [IO.File]::WriteAllText((Join-Path $private 'include/overridable_function.h'),$header.Replace($needle,$needle+' && !defined(R4OS_NATIVE_R4M)'),[Text.UTF8Encoding]::new($false))
        $cppFlags=@($flags|Where-Object {$_ -notmatch '^-std='})+@($script:R4SdkNative.data.Build.codegen.'native-flags'.libcxx_aco_flags)
        foreach($name in $cpp.units){
            $path=if($name -eq 'new'){Join-Path $private 'new.cpp'}else{Join-Path $roots.zig "lib/libcxx/src/$name.cpp"}
            $units+=[pscustomobject]@{name=('libcxx_'+$name);source=$path;arguments=($cppFlags+'-D_LIBCPP_BUILDING_LIBRARY')}
        }
        $units+=[pscustomobject]@{name='cpp_runtime';source=(Join-Path $libraries 'Shared/Native/cpp.cpp');arguments=$cppFlags}
        foreach($name in @('string','numeric','format','sort','errno')){
            $units+=[pscustomobject]@{name=('shared_'+$name);source=(Join-Path $libraries "Shared/Native/$name.c");arguments=$cFlags}
        }
        foreach($name in @('runtime','threading','cpu','stdio')){
            $units+=[pscustomobject]@{name=('port_'+$name);source=(Join-Path $unit "Port/$name.c");arguments=$cFlags}
        }
        $units+=[pscustomobject]@{name='native_bridge';source=(Join-Path $unit 'Source/native.c');arguments=$cFlags}
        $identitySource=Join-Path $generated 'identity.c'
        $bytes=@(for($i=0;$i -lt 64;$i+=2){'0x'+$id.Substring($i,2)})
        [IO.File]::WriteAllText($identitySource,('static const unsigned char identity[32]={'+($bytes -join ',')+'};'+[Environment]::NewLine+'const unsigned char *r4aco_native_identity(void) { return identity; }'+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
        $units+=[pscustomobject]@{name='compiler_identity';source=$identitySource;arguments=$cFlags}
        $results=@($units|ForEach-Object -Parallel {
            $entry=$_;$out=Join-Path $using:objects ($entry.name+'.o');$response=$out+'.rsp'
            $arguments=@($entry.arguments)+@('-MD','-MF',($out+'.d'),'-c',$entry.source,'-o',$out)
            [IO.File]::WriteAllLines($response,@($arguments|ForEach-Object {'"'+$_.Replace('\','\\').Replace('"','\"')+'"'}),[Text.UTF8Encoding]::new($false))
            & $using:clang ('@'+$response) 2>($out+'.log')
            [pscustomobject]@{name=$entry.name;source=$entry.source;object=$out;success=($LASTEXITCODE -eq 0)}
        } -ThrottleLimit $Jobs)
        $failed=@($results|Where-Object {!$_.success})
        if($failed.Count){foreach($failure in $failed){Write-Host $failure.name;Get-Content ($failure.object+'.log')|Write-Host};throw "Compiler build failed: $($failed.Count)/$($units.Count)"}
        $defined=@(& $nm --defined-only @($results.object))
        if($LASTEXITCODE -or ($defined|Where-Object {$_ -match '_GLOBAL__sub_I|__cxx_global_var_init'})){throw 'Unexpected native startup constructor.'}
        $archive=Join-Path $cache 'R4ACO.a';[IO.File]::Delete($archive)
        $response=Join-Path $cache 'archive.rsp'
        $arguments=@('rcsD',$archive)+@($results|Sort-Object name|ForEach-Object object)
        [IO.File]::WriteAllLines($response,@($arguments|ForEach-Object {'"'+$_.Replace('\','\\').Replace('"','\"')+'"'}),[Text.UTF8Encoding]::new($false))
        & $ar ('@'+$response)
        if($LASTEXITCODE){throw 'Compiler archive failed.'}
        foreach($provider in @('Math','Scan')){
            $destination=Join-Path $cache $provider
            & (Join-Path $libraries "Shared/Native/$provider/Build.ps1") -Clang $clang -OutputRoot $destination -IncludeRoot $roots.include -ZigRoot $roots.zig
        }
        $outputs=@(foreach($path in @('R4ACO.a','Math/R4NativeMath.a','Scan/R4NativeScan.a')){[ordered]@{path=$path;sha256=(Hash (Join-Path $cache $path))}})
        $objectRecords=@(foreach($entry in $results|Sort-Object name){[ordered]@{name=$entry.name;source=[IO.Path]::GetRelativePath($workspace,$entry.source).Replace('\','/');object=[IO.Path]::GetRelativePath($cache,$entry.object).Replace('\','/');sha256=(Hash $entry.object)}})
        [ordered]@{schema=1;identity=$id;inputs=$identity;original_files=$catalog.files.Count;compiler_units=$plan.units.Count;objects=$objectRecords;outputs=$outputs;static_initializers=0;scope=$plan.scope}|
            ConvertTo-Json -Depth 8|Set-Content $recordPath -Encoding utf8NoBOM
        Write-Host "R4ACO native compiler: $($units.Count) objects, complete static opcode tables, pinned math/scan."
    } else {Write-Host 'Verified cached R4ACO compiler inputs and archives.'}
    if($OutputRoot){
        $destination=[IO.Path]::GetFullPath($OutputRoot,$workspace);[IO.Directory]::CreateDirectory($destination)|Out-Null
        foreach($file in @('R4ACO.a','Math/R4NativeMath.a','Scan/R4NativeScan.a')){Copy-Item (Join-Path $cache $file) (Join-Path $destination ([IO.Path]::GetFileName($file))) -Force}
        Copy-Item $recordPath (Join-Path $destination 'native.json') -Force
    }
} finally {$guard.Dispose()}
