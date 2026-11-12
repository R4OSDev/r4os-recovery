param(
    [Parameter(Mandatory)][string]$SdkRoot,
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$ToolsRoot,
    [Parameter(Mandatory)][string]$WorkRoot,
    [string]$InstallRoot='', [string]$CacheRoot='', [switch]$Technical
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$SdkRoot=[IO.Path]::GetFullPath($SdkRoot);$ContractRoot=[IO.Path]::GetFullPath($ContractRoot);$ToolsRoot=[IO.Path]::GetFullPath($ToolsRoot);$WorkRoot=[IO.Path]::GetFullPath($WorkRoot)
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty test root.'}
if(!$InstallRoot){$InstallRoot=$ToolsRoot};if(!$CacheRoot){$CacheRoot=Join-Path $InstallRoot '.Cache/Rust'}
$project=Join-Path $WorkRoot 'Project With Spaces';[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
Copy-Item -LiteralPath (Join-Path $SdkRoot 'Tests/Build/RustStartup') -Destination $project -Recurse
$output=Join-Path $WorkRoot 'Output With Spaces';$driver=Join-Path $SdkRoot 'Tools/Build-RustModule.ps1'
$pwsh=(Get-Process -Id $PID).Path
$arguments=@('-NoLogo','-NoProfile','-File',$driver,'-ProjectRoot',$project,'-SdkRoot',$SdkRoot,'-ContractRoot',$ContractRoot,'-ToolsRoot',$ToolsRoot,'-InstallRoot',[IO.Path]::GetFullPath($InstallRoot),'-CacheRoot',[IO.Path]::GetFullPath($CacheRoot),'-OutputRoot',$output)
if($Technical){$arguments+='-Technical'}
function Run([string]$Name,[bool]$Expected,[string[]]$Extra=@()){
    & $pwsh @arguments @Extra > (Join-Path $WorkRoot ($Name+'.log')) 2>&1
    $code=$LASTEXITCODE
    if(($code -eq 0) -ne $Expected){throw "Unexpected $Name exit: $code"}
    if(!$Expected -and (@(Get-ChildItem -LiteralPath $output -Filter '*.R4X' -ErrorAction SilentlyContinue).Count -ne 0 -or (Test-Path -LiteralPath (Join-Path $output 'build.json')) -or (Test-Path -LiteralPath (Join-Path $output 'startup-info.rs')))){throw "Stale success after $Name"}
}
Run baseline $true
$receipt=Get-Content -Raw -LiteralPath (Join-Path $output 'build.json')|ConvertFrom-Json
$generated=@($receipt.compiler_inputs|Where-Object owner -CEQ 'generated')
if($generated.Count -ne 1 -or $generated[0].path -cne 'startup-info.rs' -or $generated[0].sha256 -cne (Get-FileHash -LiteralPath (Join-Path $output 'startup-info.rs') -Algorithm SHA256).Hash.ToLowerInvariant()){throw 'Generated startup input not bound.'}
$artifact=Join-Path $output 'RUSTSTART.R4X';$originalHash=(Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant()
$source=Join-Path $project 'src/main.rs';$original=[IO.File]::ReadAllText($source);$utf8=[Text.UTF8Encoding]::new($false)
if(!$original.Contains("    7`n}")){throw 'Startup fixture return site changed.'}
[IO.File]::WriteAllText($source,$original.Replace("    7`n}","    8`n}"),$utf8)
Run source-change $true
$changedHash=(Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant()
if($originalHash -ceq $changedHash){throw 'Changed Rust source did not change its R4M0 artifact.'}
[IO.File]::WriteAllText($source,$original+"`nintentional syntax error`n",$utf8)
Run compile-error $false
[IO.File]::WriteAllText($source,$original,$utf8)
[IO.File]::WriteAllText((Join-Path $output 'failed-link.elf'),'old owned diagnostic',$utf8)
Run restored $true
if(Test-Path -LiteralPath (Join-Path $output 'failed-link.elf')){throw 'Successful restore retained obsolete failed-link diagnostics.'}
if((Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant() -cne $originalHash){throw 'Restored inputs changed bytes.'}
# Select an empty installation, without changing/removing the real toolchain.
$empty=Join-Path $WorkRoot 'Missing Tools'
$savedArguments=$arguments
try{
    $arguments=@($arguments)
    $position=[Array]::IndexOf($arguments,'-InstallRoot');$arguments[$position+1]=$empty
    Run missing-tools $false
}finally{$arguments=$savedArguments}
$proof=[ordered]@{result='PASS';cases=@('source build','valid source change changes R4M0','compile error removes prior success','restored inputs reproduce R4M0','missing tools removes prior success');baseline_sha256=$originalHash;changed_sha256=$changedHash}
$proof|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $WorkRoot 'result.json') -Encoding utf8NoBOM
Write-Host 'Rust source/error/missing-tool artifact ownership PASS.'
