# Diagnostic inputs for the existing RAM acceptance only. No production image
# or frozen imported module is replaced by these disposable probes.
function Build-RecoveryApi2Fixtures([string]$Root,[string]$Zig) {
    $results=@()
    foreach($project in @('App','Driver','Protocol')) {
        $source=Join-Path $Root "Kernel/Tests/Fixture/RecoveryApi2/$project"
        $fields=Get-RecoveryFields (Join-Path $source 'module.R4MF')
        $output=Join-Path $Root "Artifacts/Api2Fixtures/$project"
        Push-Location $source
        try {
            & $Zig build "--fork=$(Join-Path $Root 'Platform/Contract')" --prefix $output | Out-Host
            if($LASTEXITCODE -ne 0){throw "Recovery API2 diagnostic build failed: $project"}
        } finally {Pop-Location}
        $binary=Join-Path $output "$($fields.NAME[0]).$($fields.KIND[0])"
        $actual=Read-RecoveryContainer $binary
        $expectedImports=@($fields.IMPORT|ForEach-Object{($_.Split(':')[0..2])-join ':'})
        if(($expectedImports -join ',') -cne ($actual.imports -join ',')){throw "Recovery API2 diagnostic imports differ: $project"}
        $results += [ordered]@{name=$fields.NAME[0];version=$fields.VERSION[0];source="Kernel/Tests/Fixture/RecoveryApi2/$project";
            imagePath=$fields.TARGET[0];binary=$binary;bytes=$actual.bytes;sha256=Get-RecoveryHash $binary;imports=$actual.imports;diagnostic=$true}
    }
    Write-RecoveryJson (Join-Path $Root 'Artifacts/Api2Fixtures/modules.json') @{schema=1;modules=$results;production=$false}
    return $results
}
