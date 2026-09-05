param([string]$WorkspaceRoot = '', [string]$Plan = '')

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Inventory.ps1')
$recoveryRoot = Split-Path $PSScriptRoot -Parent
if (!$WorkspaceRoot) { $WorkspaceRoot = [IO.Path]::GetFullPath((Join-Path $recoveryRoot '../..')) }
if (!$Plan) { $Plan = Join-Path $recoveryRoot 'Provenance/import-plan.json' }
$selection = Get-Content -Raw -LiteralPath $Plan | ConvertFrom-Json -AsHashtable
$work = Join-Path $WorkspaceRoot 'Temp/RecoveryImport'
[IO.Directory]::CreateDirectory($work) | Out-Null
$sourceMap = @{}
$fileOrigins = @{}

function Invoke-OwnerBuild([string]$Repository, [string[]]$BuildArguments = @()) {
    $starter = Join-Path $Repository $(if ($IsWindows) {'Build.bat'} else {'Build.sh'})
    & $starter @BuildArguments
    if ($LASTEXITCODE -ne 0) { throw "Owner build failed: $Repository" }
}

try {
    if ($selection.schema -ne 1) { throw 'Unsupported explicit import plan.' }
    # Validate all revisions and build inputs before importing any payload.
    foreach ($source in $selection.sources) {
        $repo = Get-RecoveryPath $WorkspaceRoot $source.repository
        $commit = & git -C $repo rev-parse HEAD
        if ($LASTEXITCODE -ne 0 -or $commit -cne $source.commit) { throw "Source revision changed: $($source.id)" }
        $remote = & git -C $repo remote get-url origin
        if ($LASTEXITCODE -ne 0 -or $remote -cne $source.remote) { throw "Source remote changed: $($source.id)" }
        $changed = @(& git -C $repo diff HEAD --name-only)
        if ($LASTEXITCODE -ne 0) { throw 'Cannot read source changes.' }
        # Documentation corrections do not alter compilation. Archives always
        # contain exact committed bytes, including their original documentation.
        $codeChanges = @($changed | Where-Object { $_ -notmatch '(?i)(\.md|\.txt)$' })
        if ($codeChanges.Count) { throw "Uncommitted build inputs in $($source.id): $($codeChanges -join ', ')" }
        $untracked = @(& git -C $repo ls-files --others --exclude-standard)
        if ($LASTEXITCODE -ne 0 -or $untracked.Count) { throw "Untracked inputs in $($source.id)." }
        $sourceMap[$source.id] = @{definition=$source; repository=$repo}
    }
    $zig = Join-Path $WorkspaceRoot $(if ($IsWindows) {'DevKit/Toolchains/Zig/zig.exe'} else {'DevKit/Toolchains/Zig/zig'})
    $zigVersion = & $zig version
    if ($LASTEXITCODE -ne 0 -or $zigVersion -cne $selection.toolchain.version) { throw 'Zig version differs from explicit import plan.' }
    $log = Join-Path $work 'owner-builds.log'
    Start-Transcript -LiteralPath $log -Force | Out-Null
    try {
        Invoke-OwnerBuild $sourceMap.SDK.repository
        Invoke-OwnerBuild $sourceMap.Libraries.repository @('R4STD')
        foreach ($module in $selection.modules) {
            if ($module.source -ne 'Libraries') { Invoke-OwnerBuild $sourceMap[$module.source].repository }
        }
    } finally { Stop-Transcript | Out-Null }
    $inspector = Join-Path $sourceMap.SDK.repository $(if ($IsWindows) {'zig-out/bin/r4xbuilder.exe'} else {'zig-out/bin/r4xbuilder'})
    foreach ($source in $selection.sources) {
        $repo = $sourceMap[$source.id].repository
        $archiveRelative = "Legal/Sources/$($source.id).zip"
        $archive = Get-RecoveryPath $recoveryRoot $archiveRelative
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($archive)) | Out-Null
        & git -C $repo archive --format=zip "--output=$archive" $source.commit
        if ($LASTEXITCODE -ne 0) { throw "Source archive failed: $($source.id)" }
        $sourceMap[$source.id].archive = $archiveRelative
        $sourceMap[$source.id].archiveSha256 = Get-RecoveryHash $archive
        $extract = Join-Path $work $source.id
        if (Test-Path -LiteralPath $extract) { Remove-Item -LiteralPath $extract -Recurse -Force }
        [IO.Compression.ZipFile]::ExtractToDirectory($archive, $extract)
        $sourceMap[$source.id].extracted = $extract
        if ($source.copyTo) {
            $target = Get-RecoveryPath $recoveryRoot $source.copyTo
            if (Test-Path -LiteralPath $target) {
                # A failed initial import can resume, but never erase edits.
                $originalFiles = @(Get-ChildItem -LiteralPath $extract -File -Recurse -Force)
                $existingFiles = @(Get-ChildItem -LiteralPath $target -File -Recurse -Force)
                if ($originalFiles.Count -ne $existingFiles.Count) { throw "Source copy has changed: $($source.copyTo)" }
                foreach ($file in $originalFiles) {
                    $existing = Join-Path $target ([IO.Path]::GetRelativePath($extract, $file.FullName))
                    if (!(Test-Path -LiteralPath $existing) -or (Get-RecoveryHash $existing) -cne (Get-RecoveryHash $file.FullName)) {
                        throw "Explicit import refuses to overwrite an edited source copy: $existing"
                    }
                }
            } else {
                [IO.Directory]::CreateDirectory($target) | Out-Null
                Get-ChildItem -LiteralPath $extract -Force | Copy-Item -Destination $target -Recurse -Force
            }
            foreach ($file in Get-ChildItem -LiteralPath $target -File -Recurse -Force) {
                $rel = [IO.Path]::GetRelativePath($recoveryRoot, $file.FullName).Replace('\','/')
                $fileOrigins[$rel] = @{source=$source.id; path=[IO.Path]::GetRelativePath($target,$file.FullName).Replace('\','/')}
            }
        }
        foreach ($file in Get-ChildItem -LiteralPath $extract -File -Force | Where-Object {$_.Name -match '^(LICENSE|NOTICE|THIRD_PARTY_NOTICES)'}) {
            $target = Get-RecoveryPath $recoveryRoot "Legal/Notices/$($source.id)/$($file.Name)"
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
            Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        }
    }
    $modules = @()
    foreach ($module in $selection.modules) {
        $source = $sourceMap[$module.source]
        $manifest = Join-Path $source.extracted $module.manifest
        $fields = Get-RecoveryFields $manifest
        $artifact = Get-RecoveryPath $WorkspaceRoot $module.artifact
        & $inspector --inspect $artifact
        if ($LASTEXITCODE -ne 0) { throw "Canonical container validation failed: $artifact" }
        $container = Read-RecoveryContainer $artifact
        $targetRelative = 'Runtime' + $fields.TARGET[0]
        $target = Get-RecoveryPath $recoveryRoot $targetRelative
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
        Copy-Item -LiteralPath $artifact -Destination $target -Force
        $manifestRelative = "Legal/Manifests/$($fields.NAME[0])/module.R4MF"
        $targetManifest = Get-RecoveryPath $recoveryRoot $manifestRelative
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($targetManifest)) | Out-Null
        Copy-Item -LiteralPath $manifest -Destination $targetManifest -Force
        $fileOrigins[$targetRelative] = @{source=$module.source; path=$module.artifact}
        $fileOrigins[$manifestRelative] = @{source=$module.source; path=$module.manifest}
        $modules += [ordered]@{name=$fields.NAME[0]; version=$fields.VERSION[0]; source=$module.source;
            path=$targetRelative; manifest=$manifestRelative; kind=$container.kind; bytes=$container.bytes;
            imports=$container.imports; exports=$container.exports;
            protocolRoles=@($fields['META'] | Where-Object {$_ -like 'r4p.role=*'} | ForEach-Object {$_.Substring(9)});
            protocolDependencies=@($fields['META'] | Where-Object {$_ -like 'r4p.dep=*'} | ForEach-Object {$_.Substring(8)});
            resources=@($fields['ICON']) + @($fields['HELP']) + @($fields['RESOURCE']) | Where-Object {$_}}
    }
    foreach ($resource in $selection.resources) {
        $target = Get-RecoveryPath $recoveryRoot $resource.target
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
        Copy-Item -LiteralPath (Join-Path $sourceMap[$resource.source].extracted $resource.path) -Destination $target -Force
        $fileOrigins[$resource.target] = @{source=$resource.source; path=$resource.path}
    }
    $files = @(foreach ($relative in Get-RecoveryInputFiles $recoveryRoot | Sort-Object -CaseSensitive) {
        $path = Get-RecoveryPath $recoveryRoot $relative
        $origin = $fileOrigins[$relative]
        $hash = Get-RecoveryHash $path
        [ordered]@{path=$relative; bytes=([IO.FileInfo]::new($path)).Length; sha256=$hash; originalSha256=$hash; origin=$origin}
    })
    $lock = [ordered]@{schema=1; baselineRelease=$selection.baselineRelease; toolchain=@{version=$zigVersion; importerBinarySha256=Get-RecoveryHash $zig};
        sources=@(foreach($source in $selection.sources) { @{id=$source.id; commit=$source.commit; remote=$source.remote;
            archive=$sourceMap[$source.id].archive; archiveSha256=$sourceMap[$source.id].archiveSha256} });
        platformProviders=$selection.platformProviders; modules=$modules; files=$files; validation=$selection.validation}
    Write-RecoveryJson (Join-Path $recoveryRoot 'Provenance/inputs.lock.json') $lock
    Test-RecoveryInventory $recoveryRoot | ConvertTo-Json
    Write-Host "Explicit Recovery import completed. Build log: $log"
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
