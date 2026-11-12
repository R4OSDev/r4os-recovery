param(
 [Parameter(Mandatory)][string]$Compiler,
 [Parameter(Mandatory)][string]$MesaDirectory,
 [Parameter(Mandatory)][string]$NvidiaDirectory,
 [Parameter(Mandatory)][string]$ScratchDirectory
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$unit=[IO.Path]::GetFullPath('../..',$PSScriptRoot)
$mesa=[IO.Path]::GetFullPath($MesaDirectory)
$nvidia=[IO.Path]::GetFullPath($NvidiaDirectory)
$scratch=[IO.Path]::GetFullPath($ScratchDirectory)
foreach($path in @($Compiler,$MesaDirectory,$NvidiaDirectory,$ScratchDirectory)){
 if(![IO.Path]::IsPathFullyQualified($path)){throw 'Generator input paths must be absolute'}
}
$utf8=[Text.UTF8Encoding]::new($false)
$catalog=Get-Content -Raw (Join-Path (Split-Path -Parent $mesa) 'source-files.json')|ConvertFrom-Json
$nvmisc=Join-Path $nvidia 'src/common/sdk/nvidia/inc/nvmisc.h'
if((Get-FileHash $nvmisc).Hash.ToLowerInvariant() -cne '707e5a739d9b8781c05003188d6e64888303c84039e4f2ecc0810b8411669248'){throw 'NVIDIA570.144 nvmisc header mismatch'}
$classes=@('c597','c797','c997','cd97')
$paths=@('src/nouveau/vulkan/nvk_cmd_draw.c','src/nouveau/vulkan/nvk_shader.c')+
 @($classes|ForEach-Object {'src/nouveau/headers/nvidia/classes/cl'+$_+'.h'})
$sources=@(foreach($path in $paths){
 $file=Join-Path $mesa $path
 $expected=@($catalog|Where-Object path -CEQ $path)
 if($expected.Count -ne 1 -or (Get-FileHash $file).Hash.ToLowerInvariant() -cne $expected[0].sha256){throw "Pinned Mesa source changed: $path"}
 [ordered]@{origin='Mesa26.2.2';path=$path;sha256=$expected[0].sha256}
})
$sources+=@{origin='NVIDIA570.144';path='src/common/sdk/nvidia/inc/nvmisc.h';sha256=(Get-FileHash $nvmisc).Hash.ToLowerInvariant()}
$run=Join-Path $scratch ('render-state-'+[Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($run)|Out-Null
$recipe=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Export.c'))
$outputs=@(foreach($class in $classes){
 $source=Join-Path $run ($class+'.c')
 $text=$recipe.Replace('C797',$class.ToUpperInvariant()).Replace('clc797.h',('cl'+$class+'.h'))
 [IO.File]::WriteAllText($source,$text,$utf8)
 $binary=Join-Path $run ($class+$(if($IsWindows){'.exe'}else{''}))
 $log=Join-Path $run ($class+'.log')
 & $Compiler cc -std=c11 -O2 -Wall -Wextra -Werror ('-DR4NV_CLASS=0x'+$class) ('-I'+(Join-Path $nvidia 'src/common/sdk/nvidia/inc')) ('-I'+(Join-Path $mesa 'src/nouveau/headers')) $source -o $binary *> $log
 if($LASTEXITCODE){Get-Content $log -Tail 14|Out-Host;throw "Render class $class failed: $run"}
 $output=Join-Path $run ($class+'.zig')
 & $binary $output
 if($LASTEXITCODE){throw "Render class $class export failed"}
 $notices=''
 foreach($header in @(('cl'+$class+'.h'),'clc597.h')|Select-Object -Unique){
  $original=[IO.File]::ReadAllText((Join-Path $mesa ('src/nouveau/headers/nvidia/classes/'+$header)))
  $notice=$original.Substring(0,$original.IndexOf('*/')+2)
  $notices+=(($notice -split '\r?\n'|ForEach-Object {('// '+$_).TrimEnd()}) -join "`n")+"`n"
 }
 [IO.File]::WriteAllText($output,$notices+[IO.File]::ReadAllText($output),$utf8)
 [ordered]@{class=$class;file=$output;sha256=(Get-FileHash $output).Hash.ToLowerInvariant()}
})
$destination=Join-Path $unit 'Source/Generated/Render'
foreach($output in $outputs){
 Copy-Item -LiteralPath $output.file -Destination (Join-Path $destination ($output.class+'.zig'))
 $name=if($output.class -eq 'c797'){'provenance.json'}else{$output.class+'-provenance.json'}
 [ordered]@{schema=1;generator='Tools/RenderState/Generate.ps1';recipe_sha256=(Get-FileHash (Join-Path $PSScriptRoot 'Export.c')).Hash.ToLowerInvariant();class=$output.class;output_sha256=$output.sha256;sources=$sources}|
  ConvertTo-Json -Depth 7|Set-Content (Join-Path $destination $name) -Encoding utf8NoBOM
}
Write-Output "Four class-specific state tables generated: $run"
