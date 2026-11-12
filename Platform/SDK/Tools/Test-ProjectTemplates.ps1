param(
 [Parameter(Mandatory)][string]$SdkRoot,[Parameter(Mandatory)][string]$ContractRoot,[Parameter(Mandatory)][string]$ToolsRoot,
 [Parameter(Mandatory)][string]$ZigRoot,[Parameter(Mandatory)][string]$InstallRoot,[Parameter(Mandatory)][string]$CacheRoot,
 [Parameter(Mandatory)][string]$NativeCacheRoot,[Parameter(Mandatory)][string]$WorkRoot,[switch]$Technical,[switch]$KeepProjects
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
foreach($key in @('SdkRoot','ContractRoot','ToolsRoot','ZigRoot','InstallRoot','CacheRoot','NativeCacheRoot','WorkRoot')){Set-Variable $key ([IO.Path]::GetFullPath((Get-Variable $key -ValueOnly)))}
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty work root.'}
$resultPath=$WorkRoot+'.result.json';if(Test-Path -LiteralPath $resultPath){throw 'Use a new compact result path.'}
[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
$success=$false;$pwsh=(Get-Process -Id $PID).Path;$utf8=[Text.UTF8Encoding]::new($false)
$proof=[ordered]@{schema=1;result='pending';scope='Actual canonical host template creation and build; no new guest/hardware/runtime claim';projects=@();negative=@()}
function Run([string]$Log,[string[]]$Arguments,[bool]$Expected=$true){
 & $pwsh -NoLogo -NoProfile -File @Arguments > (Join-Path $WorkRoot $Log) 2>&1
 $code=$LASTEXITCODE
 if(($code -eq 0) -ne $Expected){throw ('Unexpected '+$Log+' result '+$code+'; '+[IO.File]::ReadAllText((Join-Path $WorkRoot $Log)))}
}
try{
 . (Join-Path $PSScriptRoot 'MatchedComponents.ps1')
 $profile=Read-SdkMatchedComponents $SdkRoot $ContractRoot $ToolsRoot $Technical.IsPresent
 $packager=Get-SdkMatchedTool $ToolsRoot $profile $profile.hosts[$(if($IsWindows){'Windows'}else{'Linux'})].packager
 $hostName=if($IsWindows){'Windows'}else{'Linux'};$catalog=Get-SdkMatchedTool $ToolsRoot $profile $profile.hosts[$hostName].catalog
 $json=@(& $catalog capabilities --json);if($LASTEXITCODE -ne 0){throw 'Current capability query failed.'};$data=($json -join "`n")|ConvertFrom-Json -AsHashtable
 $items=@($data.templates|Where-Object execution -CEQ 'host');if($items.Count -ne 33){throw 'Host-role template set incomplete.'}
 $common=@('-SdkRoot',$SdkRoot,'-ContractRoot',$ContractRoot,'-ToolsRoot',$ToolsRoot)
 if($Technical){$common+='-Technical'}
 $firstC=$null;$firstRust=$null;$index=0
 foreach($template in $items){
  $index++;$name='TP'+$index.ToString('00')+$template.language.Substring(0,1);$directory=Join-Path $WorkRoot ('Projects With Spaces/'+$name);$output=Join-Path $WorkRoot ('Outputs With Spaces/'+$name)
  Write-Host ('Template '+$index+'/'+$items.Count+': '+$template.id)
  $create=@((Join-Path $SdkRoot 'Tools/New-Project.ps1'),'-TemplateId',$template.id,'-Directory',$directory,'-ProjectName',$name,'-InstallRoot',$InstallRoot,'-CacheRoot',$CacheRoot)+$common
  Run ($name+'-create.log') $create
  $build=@((Join-Path $directory 'Build.ps1'),'-ZigRoot',$ZigRoot,'-InstallRoot',$InstallRoot,'-CacheRoot',$(if($template.language -ceq 'Rust'){$CacheRoot}else{$NativeCacheRoot}),'-OutputRoot',$output)+$common
  Run ($name+'-build.log') $build
  $receipt=Get-Content -Raw -LiteralPath (Join-Path $output 'build.json')|ConvertFrom-Json -AsHashtable
  if($receipt.status -cne 'success'){throw 'Template did not produce a current success receipt.'}
  $json=@(& $catalog plan --manifest (Join-Path $directory 'module.R4MF'))
  if($LASTEXITCODE -ne 0){throw 'Current created template semantic plan failed'}
  $facts=(($json -join "`n")|ConvertFrom-Json -AsHashtable).plan
  $file=Join-Path $output $receipt.artifact.file;$bytes=[IO.File]::ReadAllBytes($file)
  $kind=@{R4X=1;R4L=2;R4D=3;R4P=4}[$template.kind]
  if([BitConverter]::ToUInt32($bytes,0) -ne 0x304d3452 -or [BitConverter]::ToUInt16($bytes,8) -ne $kind){throw 'Template did not build its genuine declared R4M0 role.'}
  $sha=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
  if($sha -cne $receipt.artifact.sha256){throw 'Built artifact differs from current receipt.'}
  & $packager --inspect $file > (Join-Path $WorkRoot ($name+'-inspect.log')) 2>&1
  if($LASTEXITCODE -ne 0){throw 'Canonical container inspector rejected the actual template artifact.'}
  $exports=@();$table=[BitConverter]::ToUInt32($bytes,32);$count=[BitConverter]::ToUInt32($bytes,36)
  for($i=0;$i -lt $count;$i++){
   $offset=$table+16*$i;$address=[BitConverter]::ToUInt32($bytes,$offset);$end=$address
   while($end -lt $bytes.Length -and $bytes[$end] -ne 0){$end++};if($end -eq $bytes.Length){throw 'Unterminated actual export name'}
   $exports+=@{name=[Text.Encoding]::UTF8.GetString($bytes,$address,$end-$address);section=[BitConverter]::ToUInt32($bytes,$offset+4);offset=[BitConverter]::ToUInt32($bytes,$offset+8);version=[BitConverter]::ToUInt32($bytes,$offset+12)}
  }
  if($exports.Count -ne $facts.exports.Count){throw 'Actual export count differs from canonical semantic plan'}
  for($i=0;$i -lt $exports.Count;$i++){
   $expected=$facts.exports[$i].Split(':');if($exports[$i].name -cne $expected[0] -or $exports[$i].version -ne [uint32]$expected[-1]){throw 'Actual export name/version differs from semantic plan'}
  }
  if($template.kind -cne 'R4L' -and ($facts.platform_generation -ne 2 -or $receipt.sdk_profile.id -cne $facts.sdk_profile)){throw 'Executable template used a hidden old build profile'}
  if($template.kind -ceq 'R4X'){
   $entry=[BitConverter]::ToUInt32($bytes,48)
   if([BitConverter]::ToUInt32($bytes,52) -ne 1 -or $exports[0].name -cne 'R4XStart2' -or $exports[0].version -ne 2 -or [BitConverter]::ToUInt32($bytes,$entry+4) -ne $exports[0].section -or [BitConverter]::ToUInt32($bytes,$entry+8) -ne $exports[0].offset){throw 'Actual R4X entry differs from generation2 export'}
  }
  $proof.projects+=@{id=$template.id;language=$template.language;kind=$template.kind;entry=$template.entry_mode;role=$template.role;app_class=$template.app_class;artifact_bytes=$bytes.Length;sha256=$sha;true_container_kind=$kind;created=$true;built=$true;project=$directory;output=$output;artifact=$file;exports=$exports;platform_generation=$facts.platform_generation;build_profile=$receipt.sdk_profile.id;canonical_inspect=$true}
  if(!$firstC -and $template.language -ceq 'C' -and $template.kind -ceq 'R4X' -and $template.entry_mode -ceq 'app' -and $template.app_class -ceq 'console'){$firstC=@{directory=$directory;output=$output;build=$build;artifact=$file}}
  if(!$firstRust -and $template.language -ceq 'Rust' -and $template.kind -ceq 'R4X' -and $template.entry_mode -ceq 'app' -and $template.app_class -ceq 'console'){$firstRust=@{directory=$directory;output=$output;build=$build;artifact=$file}}
 }
 # Exercise the newly shared native output owner against a real compiler error.
 if(!$firstC){throw 'Native output refusal fixture missing.'}
 $manifest=[IO.File]::ReadAllText((Join-Path $firstC.directory 'module.R4MF'))
 $relative=[regex]::Match($manifest,'(?m)^SOURCE=(.+)$').Groups[1].Value.Trim();$source=Join-Path $firstC.directory $relative;$original=[IO.File]::ReadAllText($source)
 try{
  [IO.File]::WriteAllText($source,$original+"`nintentional invalid C source`n",$utf8)
  Run 'native-compile-refusal.log' $firstC.build $false
  if((Test-Path -LiteralPath $firstC.artifact) -or (Test-Path -LiteralPath (Join-Path $firstC.output 'build.json'))){throw 'Native compiler failure retained a stale success.'}
 }finally{[IO.File]::WriteAllText($source,$original,$utf8)}
 if($KeepProjects){Run 'native-compile-recovery.log' $firstC.build}
 $proof.negative+=@('real native compiler failure removes exact previous artifact/receipt')
 # A script wrapper must preserve the Rust compiler's nonzero process result.
 if(!$firstRust){throw 'Rust output refusal fixture missing.'}
 $source=Join-Path $firstRust.directory 'src/main.rs';$original=[IO.File]::ReadAllText($source)
 try{
  [IO.File]::WriteAllText($source,$original+"`n"+'compile_error!("intentional template compiler refusal");'+"`n",$utf8)
  Run 'rust-compile-refusal.log' $firstRust.build $false
  if((Test-Path -LiteralPath $firstRust.artifact) -or (Test-Path -LiteralPath (Join-Path $firstRust.output 'build.json'))){throw 'Rust compiler failure retained a stale success.'}
 }finally{[IO.File]::WriteAllText($source,$original,$utf8)}
 if($KeepProjects){Run 'rust-compile-recovery.log' $firstRust.build}
 $proof.negative+=@('real Rust compiler failure exits nonzero and removes exact previous artifact/receipt')
 # Existing public Rust command must reject a C file map and clean its own stage.
 $bad=Join-Path $WorkRoot 'Rejected Language'
 Run 'rust-creator-language-refusal.log' (@((Join-Path $SdkRoot 'Tools/New-RustProject.ps1'),'-TemplateId','R4OS.Host_C_Console','-Directory',$bad)+$common) $false
 if((Test-Path -LiteralPath $bad) -or @(Get-ChildItem -LiteralPath $WorkRoot -Directory -Filter 'Rejected Language.new-*').Count){throw 'Rejected creator retained source/stage copies.'}
 $proof.negative+=@('Rust creator rejects C file map without partial destination')
 $proof.result='PASS';[IO.File]::WriteAllText($resultPath,($proof|ConvertTo-Json -Depth 12)+"`n",$utf8)
 $success=$true;Write-Host ('PASS33 actual host projects, genuine role containers and three output/creator negatives. Compact result: '+$resultPath)
}finally{if($success -and !$KeepProjects){Remove-Item -LiteralPath $WorkRoot -Recurse -Force}}
