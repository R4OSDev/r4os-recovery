# Inventory projection only. R4MF and full R4M0 validation belong to the
# pinned SDK's ModuleCatalog/R4XBuilder, invoked by the explicit importer.
function Write-RecoveryJson([string]$Path, $Value) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path)) | Out-Null
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 50) + "`n", [Text.UTF8Encoding]::new($false))
}

function Get-RecoveryPath([string]$Root, [string]$Relative) {
    if ([IO.Path]::IsPathRooted($Relative) -or $Relative.Contains('\') -or $Relative.Split('/') -contains '..') {
        throw "Non-canonical inventory path: $Relative"
    }
    $base = [IO.Path]::GetFullPath($Root) + [IO.Path]::DirectorySeparatorChar
    $path = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if (!$path.StartsWith($base, [StringComparison]::Ordinal)) { throw "Path outside Recovery: $Relative" }
    return $path
}

function Get-RecoveryHash([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-RecoveryFields([string]$Path) {
    $fields = @{}
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line.StartsWith('#') -or !$line.Contains('=')) { continue }
        $key, $value = $line.Split('=', 2)
        $key = $key.Trim().ToUpperInvariant()
        if (!$fields.ContainsKey($key)) { $fields[$key] = @() }
        $fields[$key] += $value.Trim()
    }
    return $fields
}

function Read-RecoveryContainer([string]$Path) {
    $data = [IO.File]::ReadAllBytes($Path)
    if ($data.Length -lt 64 -or [Text.Encoding]::ASCII.GetString($data, 0, 4) -cne 'R4M0' -or
        [BitConverter]::ToUInt16($data, 4) -ne 1 -or [BitConverter]::ToUInt16($data, 6) -ne 1 -or
        [BitConverter]::ToUInt16($data, 10) -ne 64) { throw "Invalid R4M0 header: $Path" }
    $kind = [BitConverter]::ToUInt16($data, 8)
    $flags = [BitConverter]::ToUInt32($data, 12)
    if ($kind -lt 1 -or $kind -gt 4 -or ($kind -eq 1 -and ($flags -band 2))) {
        throw "Unsupported/GUI module in Recovery: $Path"
    }
    $metaStart = [long][BitConverter]::ToUInt32($data, 56)
    $metaEnd = $metaStart + [long][BitConverter]::ToUInt32($data, 60)
    if ($metaStart -lt 64 -or $metaEnd -gt $data.LongLength) { throw "Invalid R4M0 strings: $Path" }
    $readName = {
        param([long]$Offset)
        if ($Offset -lt $metaStart -or $Offset -ge $metaEnd) { throw "R4M0 name outside metadata: $Path" }
        $end = $Offset
        while ($end -lt $metaEnd -and $data[$end] -ne 0) { $end++ }
        if ($end -eq $metaEnd -or $end -eq $Offset) { throw "Invalid R4M0 name: $Path" }
        return [Text.Encoding]::UTF8.GetString($data, [int]$Offset, [int]($end - $Offset))
    }
    $imports = @()
    $exports = @()
    foreach ($table in @(@{header=24; size=16; type='import'}, @{header=32; size=16; type='export'})) {
        $start = [long][BitConverter]::ToUInt32($data, $table.header)
        $count = [long][BitConverter]::ToUInt32($data, $table.header+4)
        if ($count -gt 0 -and ($start -lt 64 -or $start + $count*$table.size -gt $data.LongLength)) {
            throw "R4M0 table outside file: $Path"
        }
        for ($i = 0; $i -lt $count; $i++) {
            $off = [int]($start+$i*$table.size)
            $name = & $readName ([BitConverter]::ToUInt32($data, $off))
            if ($table.type -eq 'import') {
                $symbol = & $readName ([BitConverter]::ToUInt32($data, $off+4))
                $revision = [BitConverter]::ToUInt32($data, $off+8)
                $imports += "${name}:${symbol}:${revision}"
            } else {
                $revision = [BitConverter]::ToUInt32($data, $off+12)
                $exports += "${name}:${revision}"
            }
        }
    }
    return [ordered]@{kind=$kind; flags=$flags; imports=$imports; exports=$exports; bytes=$data.LongLength}
}

function Get-RecoveryInputFiles([string]$Root) {
    foreach ($dir in @('Kernel', 'Platform', 'Runtime', 'RecoveryTools', 'Legal')) {
        $base = Join-Path $Root $dir
        if (!(Test-Path -LiteralPath $base)) { continue }
        foreach ($item in Get-ChildItem -LiteralPath $base -File -Recurse -Force) {
            $rel = [IO.Path]::GetRelativePath($Root, $item.FullName).Replace('\', '/')
            if ($rel -match '/(\.git|\.zig-cache|zig-out|zig-pkg)/') { continue }
            $rel
        }
    }
}

function Test-RecoveryInventory([string]$Root) {
    $lock = Get-Content -Raw -LiteralPath (Join-Path $Root 'Provenance/inputs.lock.json') | ConvertFrom-Json -AsHashtable
    if ($lock.schema -ne 1 -or $lock.modules.Count -eq 0 -or $lock.files.Count -eq 0) { throw 'Invalid/empty Recovery lock.' }
    $known = @{}
    foreach ($item in $lock.files) {
        if ($known.ContainsKey($item.path)) { throw "Duplicate pinned path: $($item.path)" }
        $known[$item.path] = $true
        $path = Get-RecoveryPath $Root $item.path
        if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Pinned input missing: $($item.path)" }
        if ((Get-RecoveryHash $path) -cne $item.sha256) { throw "Pinned input changed: $($item.path)" }
    }
    foreach ($path in Get-RecoveryInputFiles $Root) {
        if (!$known.ContainsKey($path)) { throw "Unrecorded Recovery input: $path" }
    }
    $providers = @{}
    $contract = Get-Content -Raw -LiteralPath (Join-Path $Root 'Platform/Contract/API/ApiContract.json') | ConvertFrom-Json -AsHashtable
    foreach ($provider in $lock.platformProviders) {
        if ($provider -cnotin $contract.groups.query_import) { throw "Provider absent from pinned Contract: $provider" }
        $providers[$provider] = $true
    }
    $sources = @{}
    foreach ($source in $lock.sources) {
        if ($sources.ContainsKey($source.id) -or $source.commit -cnotmatch '^[0-9a-f]{40}$' -or
            !$known.ContainsKey($source.archive) -or (Get-RecoveryHash (Get-RecoveryPath $Root $source.archive)) -cne $source.archiveSha256) {
            throw "Invalid source provenance: $($source.id)"
        }
        $sources[$source.id] = $true
    }
    $protocols = @{}
    $moduleNames = @{}
    $importCount = 0
    $runtimeBytes = [long]0
    foreach ($module in $lock.modules) {
        if ($moduleNames.ContainsKey($module.name)) { throw "Duplicate module: $($module.name)" }
        $moduleNames[$module.name] = $true
        if (!$sources.ContainsKey($module.source)) { throw "Module source missing: $($module.name)" }
        if (!$known.ContainsKey($module.path) -or !$known.ContainsKey($module.manifest)) { throw 'Unpinned module/manifest.' }
        $actual = Read-RecoveryContainer (Get-RecoveryPath $Root $module.path)
        if (($actual.imports -join ',') -cne ($module.imports -join ',') -or
            ($actual.exports -join ',') -cne ($module.exports -join ',') -or $actual.kind -ne $module.kind) {
            throw "Binary interface differs from lock: $($module.name)"
        }
        $fields = Get-RecoveryFields (Get-RecoveryPath $Root $module.manifest)
        if ($fields.NAME[0] -cne $module.name -or $fields.VERSION[0] -cne $module.version -or
            ($fields['IMPORT'] -join ',') -cne ($actual.imports -join ',')) { throw "Manifest differs from binary inventory: $($module.name)" }
        foreach ($export in $actual.exports) { $providers["$($module.name):$export"] = $true }
        foreach ($role in $module.protocolRoles) {
            if ($protocols.ContainsKey($role)) { throw "Duplicate protocol role: $role" }
            $protocols[$role] = $true
        }
        $importCount += $actual.imports.Count
        $runtimeBytes += $actual.bytes
    }
    foreach ($module in $lock.modules) {
        foreach ($import in $module.imports) {
            $name, $symbol, $minimum = $import.Split(':')
            $matching = @($providers.Keys | Where-Object {
                $parts = $_.Split(':')
                $parts[0] -ieq $name -and $parts[1] -ieq $symbol -and [uint32]$parts[2] -ge [uint32]$minimum
            })
            if ($matching.Count -eq 0) { throw "Unresolved binary import: $($module.name) -> $import" }
        }
        foreach ($dependency in $module.protocolDependencies) {
            if (!$protocols.ContainsKey($dependency)) { throw "Unresolved protocol dependency: $($module.name) -> $dependency" }
        }
    }
    # Every compiled module under Runtime must participate in dependency validation.
    foreach ($path in $known.Keys) {
        if ($path -match '^Runtime/.*\.(R4X|R4D|R4P|R4L)$' -and $path -cnotin $lock.modules.path) {
            throw "Uncatalogued runtime module: $path"
        }
    }
    return [ordered]@{schema=1; result='ok'; files=$lock.files.Count; modules=$lock.modules.Count;
        imports=$importCount; runtimeModuleBytes=$runtimeBytes; baselineRelease=$lock.baselineRelease;
        scope='Pinned local input integrity and static dependency closure; not a guest runtime acceptance.'}
}
