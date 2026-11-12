param(
    [Parameter(Mandatory)][string]$ToolsRoot,
    [Parameter(Mandatory)][string]$SdkRoot,
    [Parameter(Mandatory)][string]$WorkRoot
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$ToolsRoot=[IO.Path]::GetFullPath($ToolsRoot);$SdkRoot=[IO.Path]::GetFullPath($SdkRoot);$WorkRoot=[IO.Path]::GetFullPath($WorkRoot)
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty test root.'};[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
$toolManifest=Get-Content -Raw -LiteralPath (Join-Path $ToolsRoot 'RustToolsProfile.json')|ConvertFrom-Json -AsHashtable
$hostName=if($IsWindows){'Windows'}else{'Linux'};$catalog=Join-Path $ToolsRoot $toolManifest.hosts[$hostName].catalog
$start=[Diagnostics.ProcessStartInfo]::new();$start.FileName=$catalog;$start.WorkingDirectory=$WorkRoot;$start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
$start.ArgumentList.Add('capabilities');$start.ArgumentList.Add('--json')
# The query must not locate/invoke a compiler, downloader or build script.
$start.Environment['PATH']='';$start.Environment['CARGO_HOME']=Join-Path $WorkRoot 'missing-cargo';$start.Environment['RUSTUP_HOME']=Join-Path $WorkRoot 'missing-rustup'
$process=[Diagnostics.Process]::new();$process.StartInfo=$start
try{
    if(!$process.Start()){throw 'Cannot start catalog'};$out=$process.StandardOutput.ReadToEndAsync();$err=$process.StandardError.ReadToEndAsync();$process.WaitForExit()
    $json=$out.GetAwaiter().GetResult();$diagnostics=$err.GetAwaiter().GetResult()
    if($process.ExitCode -ne 0 -or $diagnostics){throw "Compiler-free catalog failed: $diagnostics"}
}finally{$process.Dispose()}
$data=$json|ConvertFrom-Json -AsHashtable
if($data.schema -ne 3 -or $data.formats.manifest -ne 2 -or $data.formats.semantic_plan -ne 1 -or $data.tools.local_availability_queried){throw 'Capability format/availability mismatch'}
if($data.project_creation.ContainsKey('emitted_metadata_file') -or $data.project_creation.ContainsKey('pin_schema')){throw 'Capability catalog must not define a caller project lock'}
if($data.tools.linker.source_component -cne 'rustc' -or $data.tools.linker.exact_sources -cne 'tools.hosts.*.required[component=rustc]'){throw 'Linker archive ownership differs from the rustc component manifest'}
foreach($hostName in @('Linux','Windows')){
    $provider=@($data.tools.hosts[$hostName].required|Where-Object {$_.component -ceq $data.tools.linker.source_component})
    if($provider.Count -ne 1 -or $provider[0].target -cne $data.tools.hosts[$hostName].triple -or !$provider[0].url -or $provider[0].sha256 -cnotmatch '^[0-9a-f]{64}$'){throw 'Linker provider lacks an exact required host archive'}
}
$hostRows=@($data.support|Where-Object {$_.execution -ceq 'host' -and $_.supported})
if($hostRows.Count -ne 33){throw 'Expected eleven original host role/entry combinations per language.'}
foreach($template in @($data.templates|Where-Object {$_.kind -cne 'R4L'})){
    if($template.platform_generation -ne 2 -or $template.build_profile -cnotmatch '-generation2$' -or !$template.exports.Count){throw 'Executable template lacks actual generation2 plan facts'}
    if(@($template.imports|Where-Object {$_ -cmatch '^R4(SYS|DESK|DRAW|NET|AUDIO|DEV):Query:1'}).Count){throw 'Executable template retained an old platform import'}
}
foreach($template in @($data.templates|Where-Object {$_.kind -ceq 'R4L'})){
    if(@($template.exports|Where-Object {$_ -cmatch '^Query2:[^:]+:2$'}).Count -ne 1 -or @($template.exports|Where-Object {$_ -cmatch '^API_V1:[^:]+:1$'}).Count -ne 1){throw 'Library template lost its generation2 technical descriptor or independent interface revision'}
}
foreach($template in @($data.templates|Where-Object {$_.execution -ceq 'native_r4os' -and $_.language -ceq 'C' -and $_.platform_generation -eq 2})){
    if(!$template.supported -or $template.reason_code -cne 'native-r4cc-subset'){throw 'Qualified native C2 subset is missing'}
}
foreach($row in $hostRows){
    $template=@($data.templates|Where-Object {$_.execution -ceq 'host' -and $_.language -ceq $row.language -and $_.kind -ceq $row.kind -and $_.app_class -ceq $row.app_class -and $_.entry_mode -ceq $row.entry_mode -and $_.role -ceq $row.role})
    if($template.Count -ne 1 -or !$template[0].supported -or $template[0].creator -cne 'Tools/New-Project.ps1' -or $template[0].files.Count -lt 7){throw ('Missing complete host template '+($row|ConvertTo-Json -Compress))}
}
if(!$data.language_parity.availability_is_separate -or !$data.language_parity.capabilities.Count -or !$data.language_parity.module_roles.Count){throw 'Current owner language matrix not projected.'}
foreach($language in @('Zig','C')){
    $row=@($data.support|Where-Object {$_.language -ceq $language -and $_.kind -ceq 'R4X' -and $_.app_class -ceq 'console' -and $_.entry_mode -ceq 'app' -and $null -eq $_.role -and $_.execution -ceq 'host'})
    if($row.Count -ne 1 -or !$row[0].supported){throw 'Existing Zig/C host path disappeared'}
    & $catalog validate --manifest (Join-Path $SdkRoot "Smoke/AppEntry/$language/Console/module.R4MF") 2>&1|Out-Null;if($LASTEXITCODE -ne 0){throw 'Existing Zig/C manifest rejected'}
}
$negative=Join-Path $WorkRoot 'module.R4MF'
[IO.File]::WriteAllText($negative,"R4OS_MODULE_MANIFEST=2`nKIND=R4X`nNAME=BADENTRY`nVERSION=0.1.0`nLANGUAGE=Rust`nSOURCE=src/main.rs`nENTRY_MODE=unknown`nAPP_CLASS=console`nTARGET=/SOFTWARE/BADENTRY.R4X`nIMAGE_SCOPE=none`nIMPORT=R4SYS:Query:1`n",[Text.UTF8Encoding]::new($false))
$rejection=@(& $catalog validate --manifest $negative 2>&1);if($LASTEXITCODE -eq 0 -or ($rejection -join "`n") -notmatch 'RustLowlevelUnsupported'){throw 'Invalid Rust entry did not fail through shared admission'}
$native=@($data.support|Where-Object {$_.language -ceq 'Rust' -and $_.kind -ceq 'R4X' -and $_.app_class -ceq 'console' -and $_.entry_mode -ceq 'app' -and $null -eq $_.role -and $_.execution -ceq 'native_r4os'})
if($native.Count -ne 1 -or $native[0].supported -or $native[0].code -cne 'rust-native-compiler-unavailable'){throw 'Native Rust capability confusion'}
[IO.File]::WriteAllText((Join-Path $WorkRoot 'capabilities.json'),$json,[Text.UTF8Encoding]::new($false))
@{result='PASS';schema=3;compiler_free=$true;support_rows=$data.support.Count;templates=$data.templates.Count;negative='RustLowlevelUnsupported';zig_c_manifests=$true}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $WorkRoot 'result.json') -Encoding utf8NoBOM
Write-Host 'Compiler-free schema3 capabilities,33 true host role templates, current matrix, invalid-entry/native negatives and existing Zig/C PASS.'
