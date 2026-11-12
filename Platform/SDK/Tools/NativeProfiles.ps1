. (Join-Path $PSScriptRoot 'BuildContext.ps1')
# Location binding and SDK checks for library-owned native build implementations.
function Get-R4SdkNativeContext([string]$LibrariesRoot) {
    $LibrariesRoot=[IO.Path]::GetFullPath($LibrariesRoot)
    $settings=Read-R4BuildSettings $LibrariesRoot
    $repositories=[IO.Path]::GetFullPath($settings.REPOSITORIES_ROOT.Replace('\','/'),$LibrariesRoot)
    $workspace=[IO.Path]::GetFullPath($settings.WORKSPACE_ROOT.Replace('\','/'),$LibrariesRoot)
    $sdk=[IO.Path]::GetFullPath($settings.SDK_ROOT.Replace('\','/'),$repositories)
    $contract=[IO.Path]::GetFullPath($settings.CONTRACT_ROOT.Replace('\','/'),$repositories)
    $install=[IO.Path]::GetFullPath($settings.DEVKIT_ROOT.Replace('\','/'),$workspace)
    $zig=[IO.Path]::GetFullPath($settings.ZIG_ROOT.Replace('\','/'),$install)
    return Get-R4SdkBuildContext $sdk $contract $LibrariesRoot $install $zig -Profile 'r4os-native-graphics-v1'
}
function Assert-R4SdkNativeProjection($Actual,$Expected,[string]$Label) {
    # Projection order is stable when generated; compare objects recursively so
    # whitespace/property order cannot become a second tool policy.
    if($Actual -is [Collections.IDictionary] -and $Expected -is [Collections.IDictionary]){
        if($Actual.Count -ne $Expected.Count){throw ('SdkNativeProjectionMismatch: '+$Label)}
        foreach($key in $Expected.Keys){if(!$Actual.Contains($key)){throw ('SdkNativeProjectionMismatch: '+$Label)};Assert-R4SdkNativeProjection $Actual[$key] $Expected[$key] ($Label+'/'+$key)}
    }elseif($Actual -is [array] -and $Expected -is [array]){
        if($Actual.Count -ne $Expected.Count){throw ('SdkNativeProjectionMismatch: '+$Label)}
        for($i=0;$i -lt $Actual.Count;$i++){Assert-R4SdkNativeProjection $Actual[$i] $Expected[$i] ($Label+'/'+$i)}
    }elseif(($Actual|ConvertTo-Json -Compress -Depth 100) -cne ($Expected|ConvertTo-Json -Compress -Depth 100)){throw ('SdkNativeProjectionMismatch: '+$Label)}
}
function Test-R4SdkNativeProjections($Context) {
    $root=$Context.libraries_root
    $amd=Get-Content -Raw -LiteralPath (Join-Path $root 'Shared/Native/AMDProfile.json')|ConvertFrom-Json -AsHashtable
    Assert-R4SdkNativeProjection $amd $Context.data.Build.codegen.'native-graphics' 'AMDProfile'
    foreach($relative in $Context.data.Build.codegen.'native-projections'.Keys){
        $actual=Get-Content -Raw -LiteralPath (Join-Path $root $relative)|ConvertFrom-Json -AsHashtable
        $expected=$Context.data.Build.codegen.'native-projections'[$relative]
        if($relative.EndsWith('r4os-x86_64.json',[StringComparison]::Ordinal)){Assert-R4SdkNativeProjection $actual $expected $relative}
        else{foreach($key in $expected.Keys){Assert-R4SdkNativeProjection $actual[$key] $expected[$key] ($relative+'/'+$key)}}
    }
    $mesa=Get-Content -Raw -LiteralPath (Join-Path $root 'R4NV/Tools/Compiler/Sources.lock.json')|ConvertFrom-Json -AsHashtable
    Assert-R4SdkNativeProjection $mesa.host_tools $Context.data.Tools.tools.graphics 'Mesa host tools'
    $nak=Get-Content -Raw -LiteralPath (Join-Path $root 'R4NAK/Tools/Sources.lock.json')|ConvertFrom-Json -AsHashtable
    if($nak.rust_version -cne $Context.data.Tools.tools.graphics.rustc){throw 'SdkNativeProjectionMismatch: NAK Rust'}
    $shader=Get-Content -Raw -LiteralPath (Join-Path $root 'R4VK/Tools/ShaderTools.lock.json')|ConvertFrom-Json -AsHashtable
    Assert-R4SdkNativeProjection $shader $Context.data.Tools.tools.shader 'Shader tools'
}

function Expand-R4SdkNativeFlags($Context,[string]$Name,[hashtable]$Values) {
    foreach($flag in $Context.data.Build.codegen.'native-flags'[$Name]){
        $value=[string]$flag
        foreach($key in $Values.Keys){$value=$value.Replace(('${'+$key+'}'),[string]$Values[$key])}
        if($value.Contains('${')){throw 'SdkNativeFlagPlaceholderUnknown'}
        $value
    }
}
function Assert-R4SdkNativeCompiler($Context,[string]$Compiler) {
    $reported=@(& $Compiler --version)
    $expected=[string]$Context.data.Tools.tools.graphics.clang
    if($LASTEXITCODE -ne 0 -or !$reported.Count -or [string]$reported[0] -cnotmatch ('(?<![0-9.])'+[regex]::Escape($expected)+'(?![0-9.])')){throw 'SdkNativeCompilerMismatch'}
}
