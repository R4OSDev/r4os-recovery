param([Parameter(Mandatory)][string]$OwnerRoot,[string[]]$BuildArguments=@())
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$OwnerRoot=[IO.Path]::GetFullPath($OwnerRoot)
$sdkRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'BuildContext.ps1')
$settings=if(Test-Path -LiteralPath (Join-Path $OwnerRoot 'Settings.R4S')){Read-R4BuildSettings $OwnerRoot}else{@{}}
$repositories=[IO.Path]::GetFullPath((Join-Path $sdkRoot '..'))
$workspace=[IO.Path]::GetFullPath((Join-Path $repositories '..'))
if($settings.ContainsKey('WORKSPACE_ROOT')){$workspace=[IO.Path]::GetFullPath($settings.WORKSPACE_ROOT.Replace('\','/'),$OwnerRoot)}
if($settings.ContainsKey('REPOSITORIES_ROOT')){$repositories=[IO.Path]::GetFullPath($settings.REPOSITORIES_ROOT.Replace('\','/'),$OwnerRoot)}
$contract=if($settings.ContainsKey('CONTRACT_ROOT')){[IO.Path]::GetFullPath($settings.CONTRACT_ROOT.Replace('\','/'),$repositories)}else{Join-Path $repositories 'Contract'}
$libraries=Join-Path $repositories 'Libraries'
$install=if($settings.ContainsKey('DEVKIT_ROOT')){[IO.Path]::GetFullPath($settings.DEVKIT_ROOT.Replace('\','/'),$workspace)}else{Join-Path $workspace 'DevKit'}
$zigRoot=if($settings.ContainsKey('ZIG_ROOT')){[IO.Path]::GetFullPath($settings.ZIG_ROOT.Replace('\','/'),$install)}else{Join-Path $install 'Toolchains/Zig'}
$context=Get-R4SdkBuildContext $sdkRoot $contract $libraries $install $zigRoot -Profile 'r4os-host-tools-v1'
Assert-R4SdkBuildArguments $context $BuildArguments
$project=[IO.File]::ReadAllText((Join-Path $OwnerRoot 'build.zig.zon'))
$forks=@()
$hasSdk=$project -cmatch '(?m)(?:^|[{},])\s*\.r4os_sdk\s*='
foreach($binding in @(@('r4os_contract',$contract),@('r4os_libraries',$libraries),@('r4os_sdk',$sdkRoot))){
    # Zig rejects unused forks. A source owner such as Contract has no SDK
    # dependencies. SDK consumers also bind its transitive system package
    # inputs, including compact one-line fixture manifests.
    $declaration=[regex]::Match($project,('(?ms)(?:^|[{},])\s*\.'+$binding[0]+'\s*=\s*\.\{([^}]*)\}'))
    if($declaration.Success){
        $local=[regex]::Match($declaration.Groups[1].Value,'\.path\s*=\s*"([^"]+)"')
        if($local.Success){
            # Local dependencies are already bound and cannot be Zig forks.
            $relative=$local.Groups[1].Value.Replace('\\','/').Replace('\','/')
            $actual=[IO.Path]::GetFullPath($relative,$OwnerRoot)
            $comparison=if($IsWindows){[StringComparison]::OrdinalIgnoreCase}else{[StringComparison]::Ordinal}
            if(!$actual.Equals([IO.Path]::GetFullPath($binding[1]),$comparison)){throw ('SdkLocalComponentPathMismatch: '+$binding[0])}
            continue
        }
    }
    if($declaration.Success -or ($hasSdk -and $binding[0] -cin @('r4os_contract','r4os_libraries'))){$forks+=('--fork='+$binding[1])}
}
$packageName=[regex]::Match($project,'\.name\s*=\s*\.([a-z0-9_]+)').Groups[1].Value
$defaults=$context.data.Build.codegen.host.owner_optimize
if($defaults.Contains($packageName) -and !@($BuildArguments|Where-Object {$_ -cmatch '^-Doptimize='}).Count){
    $BuildArguments=@('-Doptimize='+$defaults[$packageName])+$BuildArguments
}
Push-Location $OwnerRoot
try{& $context.zig build @forks @BuildArguments;$code=$LASTEXITCODE}finally{Pop-Location}
exit $code
