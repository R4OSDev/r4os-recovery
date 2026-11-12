# Explicit source rebuild of the existing 39 Recovery variants. This produces
# candidate binaries only; admitting them into Runtime requires a reviewed
# owner revision and a matching inventory/manifest update.
function Build-RecoveryEmbedded {
    param([string]$Root,[string]$Zig,[string[]]$Only=@(),[bool]$ContinueAfterFailure=$false)
    . (Join-Path $PSScriptRoot 'SDKProfile.ps1')
    $context=Get-RecoverySdkContext $Root $Zig
    . (Join-Path $context.sdk_root 'Tools/RecoveryProfiles.ps1')
    $overlay=New-R4SdkRecoveryOverlay $context
    $plan=Get-Content -Raw -LiteralPath (Join-Path $Root 'Provenance/embedded-build-plan.json')|ConvertFrom-Json -AsHashtable
    if($plan.schema -ne 1 -or $plan.modules.Count -ne 39){throw 'Invalid explicit embedded source plan.'}
    $selected=@($plan.modules|Where-Object{!$Only.Count -or $_.name -cin $Only})
    if(!$selected.Count -or ($Only.Count -and $selected.Count -ne $Only.Count)){throw 'Unknown/duplicate embedded selection.'}
    $output=Join-Path $Root 'Artifacts/EmbeddedBuild'
    [IO.Directory]::CreateDirectory($output)|Out-Null
    $results=@()
    $builderHash=Get-RecoveryHash (Join-Path $PSScriptRoot 'Embedded.ps1')
    foreach($item in $selected){
        $source=Get-RecoveryPath $Root $item.source
        $manifest=Join-Path $source 'module.R4MF'
        $fields=Get-RecoveryFields $manifest
        $prefix=Join-Path $output $item.name
        [IO.Directory]::CreateDirectory($prefix)|Out-Null
        $log=Join-Path $prefix 'build.log'
        if($fields.NAME[0] -cne $item.name -or $fields.VERSION[0] -cne $item.version -or
           ('Runtime'+$fields.TARGET[0]) -cne $item.target){throw "Embedded source identity differs: $($item.name)"}
        $sourceFiles=@(Get-ChildItem -LiteralPath $source -File -Recurse -Force|ForEach-Object{
            $relative=[IO.Path]::GetRelativePath($source,$_.FullName).Replace('\','/')
            if($relative -notmatch '(^|/)(\.git|\.zig-cache|zig-out|zig-pkg)/'){$relative}
        })
        $sourceHash=Get-R4SdkTreeDigest $source $sourceFiles
        $watch=[Diagnostics.Stopwatch]::StartNew()
        Push-Location $source
        try{
            $forks=@("--fork=$(Join-Path $Root 'Platform/Contract')","--fork=$(Join-Path $Root 'Platform/Libraries')")
            # A derivative already has a path dependency on the generated SDK.
            # Canonical R4STD retains its original remote bootstrap projection.
            if($item.canonical_reuse){$forks+=,"--fork=$overlay"}
            & $Zig build -j1 --prefix $prefix @forks *> $log
            $code=$LASTEXITCODE
        }finally{Pop-Location}
        if((Get-R4SdkTreeDigest $source $sourceFiles) -cne $sourceHash){throw "Source changed during embedded build: $($item.name)"}
        $result=[ordered]@{source_tree_sha256=$sourceHash;source_files=$sourceFiles;name=$item.name;version=$item.version;source=$item.source;manifestSha256=Get-RecoveryHash $manifest;exit_code=$code;seconds=$watch.Elapsed.TotalSeconds;log=$log;passed=$false}
        if($code -eq 0){
            try{
                $extension=@{1='R4X';2='R4L';3='R4D';4='R4P'}[[int]$item.kind]
                $binary=Join-Path $prefix ($item.name+'.'+$extension)
                $actual=Read-RecoveryContainer $binary
                if($actual.kind -ne $item.kind -or ($actual.imports -join ',') -cne (@($fields['IMPORT']) -join ',')){throw 'Actual imports/kind differ from manifest.'}
                foreach($entry in $actual.imports){
                    $parts=$entry.Split(':')
                    if($parts[0] -cin @('R4SYS','R4DESK','R4DRAW','R4NET','R4AUDIO','R4DEV','R4STD') -and $parts[1] -ceq 'Query'){throw 'Old technical Query import in rebuilt consumer.'}
                }
                $entry=@{1='R4XStart2:2';2='Query2:2';3='DriverInit2:2';4='ProtocolInit2:2'}[[int]$item.kind]
                if($entry -cnotin $actual.exports){throw "Missing actual target entry $entry"}
                if($item.kind -ne 2 -and @($actual.exports|Where-Object{$_ -cmatch '^(R4XStart|DriverInit|ProtocolInit):'}).Count){throw 'Old executable entry retained.'}
                $result.binary=$binary;$result.sha256=Get-RecoveryHash $binary;$result.bytes=$actual.bytes;$result.imports=$actual.imports;$result.exports=$actual.exports;$result.passed=$true
            }catch{$result.validation_error=$_.Exception.Message}
        }
        $results+=,$result
        Write-Host ('Embedded '+$item.name+': exit='+$code+'; target ABI='+$result.passed)
        if(!$result.passed){Get-Content -LiteralPath $log -Tail 45|Out-Host;if(!$ContinueAfterFailure){break}}
    }
    $pass=@($results|Where-Object{!$_.passed}).Count -eq 0 -and $results.Count -eq $selected.Count
    $record=@{schema=1;scope='Actual source builds and binary entry/import inspection; native qualification is separate.';complete=($pass -and $results.Count -eq 39);requestedSucceeded=$pass;controller_sdk=$context.data.sdk_version;frozen_sources=$context.resolved.sources;profile_hashes=$context.data.hashes;builder_sha256=$builderHash;modules=$results}
    Write-RecoveryJson (Join-Path $output 'build-results.json') $record
    if(!$pass){throw 'Embedded source rebuild incomplete; see per-module original build logs.'}
    return $results
}
