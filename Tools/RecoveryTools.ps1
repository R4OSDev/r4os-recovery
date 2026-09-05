# Recovery-owned applications build against the pinned SDK and Contract.
# Frozen imported modules under Runtime are never rebuilt by this path.
function Build-RecoveryTools([string]$Root, [string]$Zig) {
    $lock = Get-Content -Raw -LiteralPath (Join-Path $Root 'Provenance/inputs.lock.json') | ConvertFrom-Json -AsHashtable
    $providers = @($lock.platformProviders)
    foreach ($module in $lock.modules) {
        foreach ($export in $module.exports) { $providers += "$($module.name):$export" }
    }
    $results = @()
    foreach ($project in @('Menu')) {
        $source = Join-Path $Root "RecoveryTools/$project"
        $fields = Get-RecoveryFields (Join-Path $source 'module.R4MF')
        $output = Join-Path $Root "Artifacts/RecoveryTools/$project"
        Push-Location $source
        try {
            & $Zig build "--fork=$(Join-Path $Root 'Platform/Contract')" --prefix $output | Out-Host
            if ($LASTEXITCODE -ne 0) { throw "Recovery application build failed: $project" }
        } finally { Pop-Location }
        $binary = Join-Path $output "$($fields.NAME[0]).R4X"
        $actual = Read-RecoveryContainer $binary
        if ($actual.kind -ne 1 -or $actual.flags -ne 1 -or
            ($fields.IMPORT -join ',') -cne ($actual.imports -join ',')) {
            throw "Recovery console artifact does not match its manifest: $project"
        }
        foreach ($import in $actual.imports) {
            $name, $symbol, $minimum = $import.Split(':')
            $matching = @($providers | Where-Object {
                $parts = $_.Split(':')
                $parts[0] -ieq $name -and $parts[1] -ieq $symbol -and [uint32]$parts[2] -ge [uint32]$minimum
            })
            if ($matching.Count -eq 0) { throw "Unresolved Recovery application import: $project -> $import" }
        }
        $target = $fields.TARGET[0]
        if ($target -cnotmatch '^/R4OS/SOFTWARE/[A-Z0-9]+/[A-Z0-9]+\.R4X$') { throw "Invalid application target: $target" }
        $results += [ordered]@{name=$fields.NAME[0]; version=$fields.VERSION[0]; source="RecoveryTools/$project";
            imagePath=$target; binary=$binary; bytes=$actual.bytes; sha256=Get-RecoveryHash $binary; imports=$actual.imports}
    }
    Write-RecoveryJson (Join-Path $Root 'Artifacts/RecoveryTools/modules.json') @{schema=1; modules=$results}
    return $results
}
