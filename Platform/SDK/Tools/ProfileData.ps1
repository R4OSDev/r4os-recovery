# Interpretation of the three SDK-owned inputs. No compiler or component pins live here.
function Assert-R4ProfileJsonObject($Value, [string]$Label) {
    if ($Value -isnot [Collections.IDictionary]) { throw "SdkProfileObjectRequired: $Label" }
}

function Assert-R4ProfileKeys($Value, [string[]]$Allowed, [string]$Label) {
    Assert-R4ProfileJsonObject $Value $Label
    foreach ($key in $Value.Keys) {
        if ($key -cnotin $Allowed) { throw "SdkProfileUnknownField: $Label.$key" }
    }
}

function Assert-R4ProfileId([string]$Id, [string]$Label) {
    if ($Id -cnotmatch '^[a-z][a-z0-9_-]{0,95}$') { throw "SdkProfileInvalidId: $Label" }
}

function Assert-R4ProfileReference($Map, [string]$Id, [string]$Label) {
    Assert-R4ProfileId $Id $Label
    if (!$Map.Contains($Id)) { throw "SdkProfileUnknownReference: $Label=$Id" }
}

function Assert-R4ProfileJsonNames([System.Text.Json.JsonElement]$Element) {
    if ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Object) {
        $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($property in $Element.EnumerateObject()) {
            if (!$names.Add($property.Name)) { throw ('SdkProfileDuplicateKey: ' + $property.Name) }
            Assert-R4ProfileJsonNames $property.Value
        }
    } elseif ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Array) {
        foreach ($item in $Element.EnumerateArray()) { Assert-R4ProfileJsonNames $item }
    }
}

function Read-R4SdkProfiles([string]$SdkRoot) {
    $SdkRoot = [IO.Path]::GetFullPath($SdkRoot)
    & (Join-Path $SdkRoot 'Tools/Sync-ProfilePolicy.ps1') -SdkRoot $SdkRoot -Check | Out-Null
    $documents = [ordered]@{}
    $hashes = [ordered]@{}
    foreach ($name in @('Build', 'Tools', 'Components')) {
        $path = Join-Path $SdkRoot ('Profiles/' + $name + '.json')
        $text = [IO.File]::ReadAllText($path)
        $json = [System.Text.Json.JsonDocument]::Parse($text)
        try { Assert-R4ProfileJsonNames $json.RootElement } finally { $json.Dispose() }
        $document = ConvertFrom-Json -InputObject $text -AsHashtable -Depth 100
        Assert-R4ProfileJsonObject $document $name
        if (($document.schema -isnot [long] -and $document.schema -isnot [int]) -or $document.schema -ne 1) {
            throw "SdkProfileSchemaMismatch: $name"
        }
        $documents[$name] = $document
        $hashes[$name] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $build, $tools, $components = $documents.Build, $documents.Tools, $documents.Components
    Assert-R4ProfileKeys $build @('schema', 'profiles', 'cpu_baselines', 'codegen', 'native_c_profiles', 'platforms', 'module_defaults') 'Build'
    Assert-R4ProfileJsonObject $build.platforms 'platforms'
    foreach($id in $build.platforms.Keys){
        Assert-R4ProfileId $id 'platform'
        $platform=$build.platforms[$id]
        Assert-R4ProfileKeys $platform @('generation','contract_module','sdk_module','query_symbol','query_version','entry_symbol','entry_version') "platforms.$id"
        if($platform.generation -notin @(1,2)){throw "SdkPlatformGenerationUnsupported: $id"}
        $next=$platform.generation -eq 2
        if($platform.contract_module -cne $(if($next){'r4os_contract2'}else{'r4os_contract'}) -or
           $platform.sdk_module -cne $(if($next){'r4os_platform2'}else{'r4os'}) -or
           $platform.query_symbol -cne $(if($next){'Query2'}else{'Query'}) -or
           $platform.entry_symbol -cne $(if($next){'R4XStart2'}else{'R4XStart'}) -or
           $platform.query_version -ne $platform.generation -or $platform.entry_version -ne $platform.generation){throw "SdkPlatformIdentityMismatch: $id"}
    }
    if(!$build.platforms.Contains('platform1') -or $build.platforms.platform1.generation -ne 1){throw 'SdkPlatformDefaultMissing'}
    Assert-R4ProfileKeys $tools @('schema', 'toolsets', 'tools') 'Tools'
    Assert-R4ProfileKeys $components @('schema', 'policy', 'repositories', 'libraries', 'sets') 'Components'
    foreach ($entry in @(@($build.profiles, 'profiles'), @($build.codegen, 'codegen'),
                        @($build.cpu_baselines, 'cpu_baselines'), @($tools.toolsets, 'toolsets'),
                        @($tools.tools, 'tools'), @($components.repositories, 'repositories'),
                        @($components.libraries, 'libraries'), @($components.sets, 'sets'))) {
        Assert-R4ProfileJsonObject $entry[0] $entry[1]
        foreach ($id in $entry[0].Keys) { Assert-R4ProfileId $id $entry[1] }
    }
    if (!$build.profiles.Count -or !$tools.toolsets.Count -or !$components.sets.Count) {
        throw 'SdkProfileEmptyCatalogue'
    }
    foreach ($id in $build.profiles.Keys) {
        $profile = $build.profiles[$id]
        Assert-R4ProfileKeys $profile @('language', 'role', 'toolset', 'components', 'codegen', 'cpu', 'kind', 'platform') "profiles.$id"
        if($profile.Contains('platform')){Assert-R4ProfileReference $build.platforms $profile.platform "$id.platform"}
        if ($profile.language -cnotin @('Zig', 'C', 'C++', 'Rust') -or
            $profile.role -cnotin @('module', 'kernel', 'recovery', 'native', 'host')) {
            throw "SdkProfileUnsupportedRole: $id"
        }
        if($profile.Contains('kind') -and $profile.kind -cnotin @('R4X','R4L','R4D','R4P')){throw "SdkProfileUnsupportedKind: $id"}
        Assert-R4ProfileReference $tools.toolsets $profile.toolset "$id.toolset"
        Assert-R4ProfileReference $components.sets $profile.components "$id.components"
        Assert-R4ProfileReference $build.codegen $profile.codegen "$id.codegen"
        if ($profile.Contains('cpu')) { Assert-R4ProfileReference $build.cpu_baselines $profile.cpu "$id.cpu" }
    }
    if($build.module_defaults -isnot [array] -or !$build.module_defaults.Count){throw 'SdkModuleDefaultsRequired'}
    $defaultGroups=@{}
    foreach($item in $build.module_defaults){
        Assert-R4ProfileKeys $item @('language','kind','entry','profile','profile_role') 'module_defaults'
        if($item.language -cnotin @('Zig','C','Rust') -or $item.kind -cnotin @('R4X','R4L','R4D','R4P') -or
           $item.entry -cnotin @('','app','lowlevel') -or ($item.kind -cne 'R4X' -and $item.entry)){throw 'SdkModuleDefaultInvalid'}
        if($item.Contains('profile') -eq $item.Contains('profile_role')){throw 'SdkModuleDefaultReferenceRequired'}
        $defaultProfileId=if($item.Contains('profile')){$item.profile}else{
            if($item.language -cne 'Rust' -or !$build.codegen.'rust-module'.profile_ids.Contains($item.profile_role)){throw 'SdkModuleDefaultRoleInvalid'}
            $build.codegen.'rust-module'.profile_ids[$item.profile_role]
        }
        Assert-R4ProfileReference $build.profiles $defaultProfileId 'module_defaults.profile'
        $defaultProfile=$build.profiles[$defaultProfileId]
        if($defaultProfile.language -cne $item.language -or $defaultProfile.role -cne 'module' -or
           ($defaultProfile.Contains('kind') -and $defaultProfile.kind -cne $item.kind)){throw 'SdkModuleDefaultRoleMismatch'}
        $group=$item.language+'/'+$item.kind
        if(!$defaultGroups.ContainsKey($group)){$defaultGroups[$group]=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)}
        $entries=$defaultGroups[$group]
        if($entries.Contains('') -or (!$item.entry -and $entries.Count) -or !$entries.Add($item.entry)){throw 'SdkModuleDefaultAmbiguous'}
    }
    foreach ($id in $tools.toolsets.Keys) {
        $ids = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $set = $tools.toolsets[$id]
        Assert-R4ProfileKeys $set @('tools') "toolsets.$id"
        if (!$set.tools.Count) { throw "SdkProfileEmptyToolset: $id" }
        foreach ($tool in $set.tools) {
            Assert-R4ProfileReference $tools.tools $tool "$id.tools"
            if (!$ids.Add($tool)) { throw "SdkProfileDuplicateTool: $tool" }
        }
    }
    foreach ($id in $components.repositories.Keys) {
        $source = $components.repositories[$id]
        Assert-R4ProfileKeys $source @('repository', 'commit', 'version', 'files', 'archive_sha256', 'archive_url', 'zig_archive_url', 'archive_format', 'zig_hash', 'tree', 'source_subdir', 'provenance') "repositories.$id"
        if ($source.repository -cnotmatch '^https://[^\s]+$' -or
            $source.commit -cnotmatch '^[0-9a-f]{40}$' -or
            $source.version -cnotmatch '^\d+\.\d+\.\d+$') { throw "SdkProfileInvalidSource: $id" }
        if($source.Contains('source_subdir')){
            $relative=$source.source_subdir
            if(!$relative -or [IO.Path]::IsPathRooted($relative) -or $relative.Contains('\') -or
               $relative.Split('/') -contains '..' -or $relative.Split('/') -contains '.' -or $relative.Split('/') -contains ''){throw "SdkProfileInvalidSourceSubdir: $id"}
        }
        if($source.Contains('provenance')){
            Assert-R4ProfileKeys $source.provenance @('repository','commit','version','archive_sha256') "$id.provenance"
            if($source.provenance.repository -cnotmatch '^https://[^\s]+$' -or $source.provenance.commit -cnotmatch '^[0-9a-f]{40}$' -or
               $source.provenance.version -cnotmatch '^\d+\.\d+\.\d+$' -or $source.provenance.archive_sha256 -cnotmatch '^[0-9a-f]{64}$'){throw "SdkProfileInvalidProvenance: $id"}
        }
        Assert-R4ProfileJsonObject $source.files "$id.files"
        foreach ($path in $source.files.Keys) {
            if ([IO.Path]::IsPathRooted($path) -or $path.Contains('\') -or
                $path.Split('/') -contains '..' -or $path.Split('/') -contains '.' -or
                $source.files[$path] -cnotmatch '^[0-9a-f]{64}$') { throw "SdkProfileInvalidInput: $id/$path" }
        }
        if ($source.Contains('archive_sha256') -and $source.archive_sha256 -cnotmatch '^[0-9a-f]{64}$') {
            throw "SdkProfileInvalidArchiveHash: $id"
        }
        if($source.Contains('tree')){
            Assert-R4ProfileKeys $source.tree @('algorithm','sha256','files') "$id.tree"
            if($source.tree.algorithm -cne 'r4os-files-sha256-lf-v1' -or
               $source.tree.sha256 -cnotmatch '^[0-9a-f]{64}$' -or !$source.tree.files.Count){throw "SdkProfileInvalidSourceTree: $id"}
            $treePaths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            foreach($path in $source.tree.files){
                if([IO.Path]::IsPathRooted($path) -or $path.Contains('\') -or $path.Split('/') -contains '..' -or
                   $path.Split('/') -contains '.' -or !$treePaths.Add($path)){throw "SdkProfileInvalidSourceTreePath: $id/$path"}
            }
        }
    }
    $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($id in $components.libraries.Keys) {
        $library = $components.libraries[$id]
        Assert-R4ProfileKeys $library @('name', 'repository', 'path', 'version', 'target', 'manifest_sha256') "libraries.$id"
        Assert-R4ProfileReference $components.repositories $library.repository "$id.repository"
        if (!$names.Add($library.name)) { throw "SdkProfileDuplicateSystemLibrary: $($library.name)" }
        if ($library.path -cnotmatch '^[A-Za-z0-9_/-]+$' -or $library.path.Split('/') -contains '..' -or
            $library.version -cnotmatch '^\d+\.\d+\.\d+$' -or
            $library.manifest_sha256 -cnotmatch '^[0-9a-f]{64}$') { throw "SdkProfileInvalidLibrary: $id" }
    }
    foreach ($id in $components.sets.Keys) {
        $set = $components.sets[$id]
        Assert-R4ProfileKeys $set @('contract', 'system_libraries', 'source_sdk', 'source_libraries') "sets.$id"
        Assert-R4ProfileReference $components.repositories $set.contract "$id.contract"
        foreach ($field in @('source_sdk', 'source_libraries')) {
            if ($set.Contains($field)) { Assert-R4ProfileReference $components.repositories $set[$field] "$id.$field" }
        }
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($library in $set.system_libraries) {
            Assert-R4ProfileReference $components.libraries $library "$id.system_libraries"
            if (!$seen.Add($library)) { throw "SdkProfileDuplicateSystemReference: $library" }
        }
    }
    if ($components.policy.system_selection -cne 'sdk-only' -or
        $components.policy.additional_libraries -cne 'caller-pinned-no-system-shadowing' -or
        $components.policy.development -cne 'explicit-sdk-snapshot') { throw 'SdkProfilePolicyMismatch' }
    $sdkManifest = [IO.File]::ReadAllText((Join-Path $SdkRoot 'build.zig.zon'))
    if ($sdkManifest -cnotmatch '\.version\s*=\s*"(\d+\.\d+\.\d+)"') { throw 'SdkProfileMissingSdkVersion' }
    return [ordered]@{schema=1; sdk_version=$Matches[1]; hashes=$hashes; Build=$build; Tools=$tools; Components=$components}
}

function Get-R4SdkBuildProfile([string]$SdkRoot, [string]$Id) {
    $data = Read-R4SdkProfiles $SdkRoot
    Assert-R4ProfileReference $data.Build.profiles $Id 'profile'
    $profile = $data.Build.profiles[$Id]
    $platformId=if($profile.Contains('platform')){$profile.platform}else{'platform1'}
    return [ordered]@{
        schema=1; sdk_version=$data.sdk_version; id=$Id; hashes=$data.hashes
        build=$profile; platform=$data.Build.platforms[$platformId]; codegen=$data.Build.codegen[$profile.codegen]
        toolset=$data.Tools.toolsets[$profile.toolset]
        components=$data.Components.sets[$profile.components]
    }
}

function Assert-R4SdkProjectCFlags($Data, [string]$Kind, [string]$Name, $Flags) {
    $policy=$Data.Build.codegen.module.project_c_flags
    $specific=@()
    $key=$Kind+':'+$Name
    if($policy.modules.Contains($key)){$specific=@($policy.modules[$key])}
    foreach($flag in $Flags){
        $admitted=($flag -cin $policy.allowed_exact -or $flag -cin $specific)
        foreach($prefix in $policy.allowed_prefixes){if($flag.StartsWith($prefix,[StringComparison]::Ordinal)){$admitted=$true}}
        if(!$admitted){throw "SdkProfileCFlagOverride: $key $flag"}
    }
}
