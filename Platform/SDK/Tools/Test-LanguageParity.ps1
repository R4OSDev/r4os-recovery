param(
    [string]$SdkRoot = (Join-Path $PSScriptRoot '..'),
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$LibraryRoot
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$roots = @{
    SDK = [IO.Path]::GetFullPath($SdkRoot)
    Contract = [IO.Path]::GetFullPath($ContractRoot)
    Libraries = [IO.Path]::GetFullPath($LibraryRoot)
}
$matrix = Get-Content -Raw -LiteralPath (Join-Path $roots.SDK 'Inventory/LanguageParity.json') | ConvertFrom-Json -AsHashtable
$guard = $matrix.drift_guard
if ($guard.schema -ne 1 -or $guard.hash_mode -cne 'utf8-bomless-lf') { throw 'Unknown language parity review format.' }

function Resolve-Input([string]$Reference) {
    if ($Reference -cnotmatch '^Repositories/(SDK|Contract|Libraries)/(.+)$') { throw "Invalid parity owner: $Reference" }
    $root = $roots[$Matches[1]]
    $relative = $Matches[2]
    if ($relative.Contains('\') -or @($relative.Split('/') | Where-Object { $_ -in @('', '.', '..') }).Count) { throw "Invalid parity path: $Reference" }
    return Join-Path $root $relative
}
function Text-Hash([string]$Path) {
    $text = [IO.File]::ReadAllText($Path).Replace("`r`n", "`n").Replace("`r", "`n")
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($text))).ToLowerInvariant()
}
function Same-Set($Actual, $Expected, [string]$Label) {
    $a = @($Actual | Sort-Object -Unique -CaseSensitive)
    $b = @($Expected | Sort-Object -Unique -CaseSensitive)
    if (($a -join "`n") -cne ($b -join "`n")) { throw "Language parity drift ($Label); review the changed owner, C/Rust implementations and matching evidence before updating drift_guard." }
}
function Expand-References($References) {
    foreach ($reference in $References) {
        $path = Resolve-Input $reference
        $item = Get-Item -LiteralPath $path
        if ($item.PSIsContainer) {
            foreach ($file in Get-ChildItem -LiteralPath $path -File -Recurse) {
                # Host/package caches contain generated dependency source, not
                # canonical owner files. Keep persistent Generated/ boundaries.
                $relative = [IO.Path]::GetRelativePath($path, $file.FullName).Replace('\', '/')
                if (@($relative.Split('/') | Where-Object { $_ -cin @('.git', '.zig-cache', 'zig-out', 'zig-pkg', 'target') }).Count -ne 0) { continue }
                if ($file.Extension -cin @('.zig', '.rs', '.c', '.h', '.json', '.ps1', '.toml')) {
                    $reference.TrimEnd('/') + '/' + $relative
                }
            }
        } else { $reference }
    }
}
function Language-Sources($Row, [string]$Language) {
    $entry = $Row[$Language]
    if ($entry -isnot [System.Collections.IDictionary]) { return }
    $references = @()
    foreach ($key in @('source', 'sources', 'helper_header', 'helper_boundary')) {
        if ($entry.ContainsKey($key)) { $references += @($entry[$key]) }
    }
    Expand-References $references
}

# These sets include bodies, shared bridges, generated projections and local
# contracts. New functions in an existing file and new files both invalidate
# the reviewed state. Counts/names alone never qualify a changed implementation.
$actualFiles = @(Expand-References $guard.watch)
Same-Set $actualFiles @($guard.files.path) 'owner source set'
foreach ($file in $guard.files) {
    if ((Text-Hash (Resolve-Input $file.path)) -cne $file.sha256) { throw "Language parity source changed: $($file.path); update its C/Rust implementation and qualified evidence, then review drift_guard." }
}

$rootSource = [IO.File]::ReadAllText((Join-Path $roots.SDK 'r4os.zig'))
$rootExports = @([regex]::Matches($rootSource, '(?m)^pub\s+(?:(?:inline|extern|export)\s+)*(?:const|var|fn)\s+([A-Za-z_][A-Za-z_0-9]*)') | ForEach-Object { $_.Groups[1].Value })
Same-Set $rootExports @($matrix.public_exports.name) 'public root mapping'
$capabilities = @{}
foreach ($row in $matrix.capabilities) { $capabilities[$row.id] = $row }
foreach ($export in $matrix.public_exports) {
    if (!$capabilities.ContainsKey($export.capability)) { throw "Unmapped public capability: $($export.name)" }
}

$rows = @($matrix.capabilities) + @($matrix.libraries)
$localLibraries = @(Get-ChildItem -LiteralPath $roots.Libraries -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'Contract/LibraryContract.json') } | ForEach-Object { 'library-' + $_.Name })
Same-Set $localLibraries @($matrix.libraries.id) 'local library owners'
Same-Set @($rows.id) @($guard.coverage.id) 'functional coverage'
foreach ($scope in $guard.coverage) {
    $row = @($rows | Where-Object { $_.id -ceq $scope.id })
    if ($row.Count -ne 1) { throw "Ambiguous parity scope: $($scope.id)" }
    $row = $row[0]
    if (!$scope.zig.Count) { throw "Missing original Zig owner: $($scope.id)" }
    foreach ($source in $scope.zig) {
        if ($source -cnotin $guard.files.path) { throw "Unreviewed original owner: $source" }
    }
    foreach ($language in @('c', 'rust')) {
        $sources = @(Language-Sources $row $language)
        if ($row.ContainsKey($language + '_sources')) { $sources += @(Expand-References $row[$language + '_sources']) }
        if (!$sources.Count) { throw "Missing real $language implementation: $($scope.id)" }
        Same-Set $sources $scope[$language] ($scope.id + '/' + $language)
        foreach ($source in $sources) {
            if ($source -cnotin $guard.files.path) { throw "Unreviewed implementation: $source" }
        }
    }
    if (!$scope.proof.Count) { throw "Missing qualified evidence: $($scope.id)" }
    foreach ($key in $scope.proof) {
        if (!$matrix.evidence.ContainsKey($key) -or $key -ceq 'source_inventory') { throw "Missing functional proof: $($scope.id)/$key" }
        if ($matrix.evidence[$key].ContainsKey('complete') -and !$matrix.evidence[$key].complete) { throw "Incomplete functional proof: $($scope.id)/$key" }
    }
}

Write-Host "Language parity review PASS: $($guard.files.Count) owner files, $($guard.coverage.Count) implementation/evidence scopes, $($rootExports.Count) public exports. This checks review drift; it does not execute or grant new runtime, Windows, hardware or performance qualification."
