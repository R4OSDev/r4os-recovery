# Source identity mechanics; all expected identities come from Components.json.
function Assert-R4SdkRelativePath([string]$Path) {
    if(!$Path -or [IO.Path]::IsPathRooted($Path) -or $Path.Contains('\') -or
        $Path.IndexOfAny([char[]]"`0`r`n") -ge 0 -or $Path.Split('/') -contains '..' -or
        $Path.Split('/') -contains '.' -or $Path.Split('/') -contains ''){throw "SdkSourceInvalidPath: $Path"}
}

function Get-R4SdkBytesDigest([string]$Path,[byte[]]$Bytes) {
    $extension=[IO.Path]::GetExtension($Path).ToLowerInvariant()
    $textExtensions=@('.zig','.zon','.json','.ps1','.psm1','.psd1','.sh','.bat','.toml','.lock','.c','.h','.cc','.cpp','.hpp','.inc','.s','.asm','.ld','.r4mf','.r4s','.py','.rs','.md','.txt','.yml','.yaml','.xml','.cmake')
    if($extension -cin $textExtensions -or [IO.Path]::GetFileName($Path) -cin @('LICENSE','NOTICE','.gitignore','.gitattributes','Makefile')){
        # Only CRLF is normalized. Binary inputs, standalone CR, UTF-8 BOMs and
        # every other byte stay significant. This is not semantic source hashing.
        $bytes=[Text.Encoding]::Latin1.GetBytes([Text.Encoding]::Latin1.GetString($bytes).Replace("`r`n","`n"))
    }
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
}

function Get-R4SdkFileDigest([string]$Path) {
    return Get-R4SdkBytesDigest $Path ([IO.File]::ReadAllBytes($Path))
}

function Get-R4SdkTreeDigest([string]$Root, [string[]]$Files) {
    $ordered=[string[]]@($Files)
    [Array]::Sort($ordered,[StringComparer]::Ordinal)
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $hash=[Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA256)
    try{
        foreach($relative in $ordered){
            Assert-R4SdkRelativePath $relative
            if(!$seen.Add($relative)){throw "SdkSourceDuplicatePath: $relative"}
            $path=[IO.Path]::GetFullPath($relative,$Root)
            if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw "SdkSourceMissingInput: $relative"}
            $row=$relative+"`0"+(Get-R4SdkFileDigest $path)+"`n"
            $hash.AppendData([Text.Encoding]::UTF8.GetBytes($row))
        }
        return [Convert]::ToHexString($hash.GetHashAndReset()).ToLowerInvariant()
    }finally{$hash.Dispose()}
}

function Get-R4SdkSourceState([string]$Root) {
    $Root=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($Root))
    $git=Get-Command git -CommandType Application -ErrorAction SilentlyContinue|Select-Object -First 1
    if($git){
        $top=@(& $git.Source -C $Root rev-parse --show-toplevel 2>$null)
        if($LASTEXITCODE -eq 0 -and $top.Count -eq 1){
            $prefix=(@(& $git.Source -C $Root rev-parse --show-prefix)-join '')
            if($LASTEXITCODE -eq 0 -and !$prefix){
                $Root=[IO.Path]::GetFullPath([string]$top[0])
                $commit=(@(& $git.Source -C $Root rev-parse HEAD)-join '').Trim()
                if($LASTEXITCODE -ne 0){throw 'SdkSourceCannotReadCommit'}
                $dirty=@(& $git.Source -C $Root status --porcelain --untracked-files=normal)
                if($LASTEXITCODE -ne 0){throw 'SdkSourceCannotReadStatus'}
                $files=@(& $git.Source -C $Root -c core.quotepath=false ls-files --cached --others --exclude-standard)
                if($LASTEXITCODE -ne 0){throw 'SdkSourceCannotReadInputs'}
                $files=@($files|Where-Object {Test-Path -LiteralPath (Join-Path $Root $_) -PathType Leaf})
                return [ordered]@{kind='git';root=$Root;commit=$commit;dirty=($dirty.Count -ne 0);files=$files}
            }
        }
    }
    return [ordered]@{kind='snapshot';root=$Root;commit=$null;dirty=$null;files=@()}
}

function Get-R4SdkRepositoryBinding([string]$Id, [string]$Root, $Expected, [bool]$Development) {
    if($Root -and (Test-Path -LiteralPath $Root -PathType Leaf) -and $Expected.Contains('archive_sha256')){
        if($Expected.Contains('tree')){throw "SdkSourceExtractedTreeRequired: $Id"}
        $actual=(Get-FileHash -LiteralPath $Root -Algorithm SHA256).Hash.ToLowerInvariant()
        if($actual -cne $Expected.archive_sha256){throw "SdkSourceArchiveMismatch: $Id"}
        return [ordered]@{id=$Id;root=[IO.Path]::GetFullPath($Root);kind='archive';commit=$Expected.commit;dirty=$false;
            expected_commit=$Expected.commit;tree_sha256=$actual;files=@();matches_sdk=$true}
    }
    if(!$Root -or !(Test-Path -LiteralPath $Root -PathType Container)){throw "SdkSourceRootRequired: $Id"}
    $actual=Get-R4SdkSourceState $Root
    if(!$Expected.Contains('tree') -or $Expected.tree.algorithm -cne 'r4os-files-sha256-lf-v1'){throw "SdkSourceTreeRequired: $Id"}
    $files=if($Development -and $actual.kind -ceq 'git'){$actual.files}else{@($Expected.tree.files)}
    $digest=Get-R4SdkTreeDigest $actual.root $files
    $matches=($digest -ceq $Expected.tree.sha256)
    if($actual.kind -ceq 'git' -and ($actual.commit -cne $Expected.commit -or $actual.dirty)){$matches=$false}
    if(!$Development -and !$matches){throw "SdkSourceIdentityMismatch: $Id"}
    return [ordered]@{id=$Id;root=$actual.root;kind=$actual.kind;commit=$actual.commit;dirty=$actual.dirty;
        expected_commit=$Expected.commit;tree_sha256=$digest;files=@($files);matches_sdk=$matches}
}
