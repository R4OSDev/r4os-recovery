# Shared input accounting for the SDK Rust builder. Dot-sourced after its
# canonical path/hash helpers; no Cargo/TOML grammar or source-file guessing.
function Read-CompilerDependencies([string]$Path) {
    $text=[IO.File]::ReadAllText($Path)
    $text=[regex]::Replace($text,'\\\r?\n',' ')
    $line=@($text.Split("`n")|Where-Object {$_ -match ': '})|Select-Object -First 1
    if(!$line){throw 'CompilerDepInfoMissingRule'}
    $rhs=$line.Substring($line.IndexOf(': ')+2)
    $paths=[Collections.Generic.List[string]]::new();$token=[Text.StringBuilder]::new()
    for($i=0;$i -lt $rhs.Length;++$i){
        $c=$rhs[$i]
        if($c -eq '$' -and $i+1 -lt $rhs.Length -and $rhs[$i+1] -eq '$'){
            [void]$token.Append('$');++$i;continue
        }
        # Make escapes a space/hash/backslash. Preserve ordinary Windows
        # path separators; they are not arbitrary character escapes.
        if($c -eq '\' -and $i+1 -lt $rhs.Length -and
           ([char]::IsWhiteSpace($rhs[$i+1]) -or $rhs[$i+1] -in @('#','\',':'))){
            [void]$token.Append($rhs[++$i]);continue
        }
        if([char]::IsWhiteSpace($c)){
            if($token.Length){$paths.Add($token.ToString());[void]$token.Clear()}
        }else{[void]$token.Append($c)}
    }
    if($token.Length){$paths.Add($token.ToString())}
    return $paths.ToArray()
}
function Find-InputOwner([string]$Path,$Roots) {
    foreach($root in $Roots|Sort-Object {$_.path.Length} -Descending){
        if((SamePath $Path $root.path) -or (Below $Path $root.path)){return $root}
    }
    throw 'CompilerDependencyOutsideSelectedRoots'
}
function Observe-Input([string]$Path,$Roots) {
    $path=[IO.Path]::GetFullPath($Path)
    $root=Find-InputOwner $path $Roots
    return Input $path $root.path $root.owner
}
function Build-RustCCompanions($Rust,$Cpu,[string]$Optimization,[string]$Work,$Roots) {
    if(!$Rust.c_sources.Count){return @{objects=@();inputs=@();compiler=$null}}
    if(!$ZigRoot){throw 'RustCCompanionsRequireExplicitZigRoot'}
    $zig=Join-Path ([IO.Path]::GetFullPath($ZigRoot)) ('zig'+$(if($IsWindows){'.exe'}else{''}))
    $pin=$sdkProfiles.Tools.tools.zig
    if((Invoke-Tool $zig @('version') $Work).Trim() -cne $pin.version){throw 'RustCCompilerVersionMismatch'}
    $objects=@();$inputs=@();$commands=@()
    $arguments=@('cc')+@($Rust.c_flags)+@($codegen.native_c.flags)+@($codegen.native_c.optimization[$Optimization])
    foreach($requirement in $Cpu.requirements){if($requirement.ContainsKey('c_flag')){$arguments+=$requirement.c_flag}}
    $arguments+=@('-I',(Join-Path $SdkRoot 'Shared/C/include'),'-I',(Join-Path $ContractRoot 'Generated/SDK/C/include'),'-I',(Join-Path $ContractRoot 'Generated/Generation2/C/include'))
    foreach($include in $Rust.c_includes){
        $path=[IO.Path]::GetFullPath($include,$ProjectRoot)
        $null=Find-InputOwner $path $Roots
        $arguments+=@('-I',$path)
    }
    foreach($define in $Rust.c_defines){$arguments+=('-D'+$define.name+'='+$define.value)}
    foreach($root in $Roots|Sort-Object {$_.path.Length}){$arguments+=('-ffile-prefix-map='+$root.path+'=/r4os/'+$root.owner)}
    foreach($source in $Rust.c_sources){
        $file=Canonical $ProjectRoot $source
        $object=Join-Path $Work ('companion'+$objects.Count+'.o');$depfile=$object+'.d'
        $args=$arguments+@('-MD','-MF',$depfile,'-c',$file,'-o',$object)
        Invoke-Tool $zig $args $Work|Out-Null
        $objects+=$object
        foreach($path in Read-CompilerDependencies $depfile){
            $full=[IO.Path]::GetFullPath($path,$Work)
            if(Below $full ([IO.Path]::GetFullPath($ZigRoot))){
                $inputs+=Input $full ([IO.Path]::GetFullPath($ZigRoot)) 'c-compiler'
            }else{$inputs+=Observe-Input $full $Roots}
        }
        $commands+=@{source=$source;arguments=$args;sha256=Hash $object}
    }
    return @{objects=$objects;inputs=$inputs;compiler=@{kind='zig-cc';version=$pin.version;sha256=Hash $zig;pin_sha256=Hash (Join-Path $ToolsRoot 'Profile/ZigToolchain.json');commands=$commands}}
}

# Optional library-owned native helpers are an explicit compiler input. They
# are never inferred from Studio projects, installed hardware or ambient paths.
function Build-RustLibraryHelpers([string]$Work,$Roots) {
    if(!$LibraryHelpersRoot){return @{objects=@();inputs=@();receipt=$null}}
    if(!$ZigRoot){throw 'LibraryHelpersRequireExplicitZigRoot'}
    $zig=Join-Path ([IO.Path]::GetFullPath($ZigRoot)) ('zig'+$(if($IsWindows){'.exe'}else{''}))
    $pin=$sdkProfiles.Tools.tools.zig
    if((Invoke-Tool $zig @('version') $Work).Trim() -cne $pin.version){throw 'LibraryHelperCompilerVersionMismatch'}
    $files=@()
    foreach($relative in @('build.zig.zon','consumer_helpers.zig','consumer_adapters.zig','consumer_media.zig','consumer_media_adapters.zig','R4STD/Source/codec_tables.zig')){
        $files+=Canonical $LibraryHelpersRoot $relative
    }
    $files+=Canonical $SdkRoot 'build.zig'
    foreach($relative in @('Shared/Language','Shared/C','R4STD/Bindings/Zig','R4IMG/Bindings/Zig','R4FONT/Bindings/Zig','R4GFX/Bindings/Zig','R4GFX/Display','R4VIDEO/Bindings/Zig','R4ENC/Bindings/Zig','R4ACO/Bindings/Zig','R4NAK/Bindings/Zig')){
        $files+=@(Get-ChildItem -LiteralPath (Canonical $LibraryHelpersRoot $relative) -Recurse -File|ForEach-Object FullName)
    }
    $inputs=@($files|Sort-Object -Unique|ForEach-Object {Observe-Input $_ $Roots})
    $prefix=Join-Path $Work 'library-helpers'
    $arguments=@('build',('--fork='+$ContractRoot),('-Dlibrary-helpers-root='+$LibraryHelpersRoot),'--prefix',$prefix,'-j1')
    Invoke-Tool $zig $arguments $SdkRoot|Out-Null
    # Bind the receipt to precisely the source snapshot compiled in this build.
    foreach($item in $inputs){
        $owner=@($Roots|Where-Object owner -CEQ $item.owner)[0]
        if((Hash (Canonical $owner.path $item.path)) -cne $item.sha256){throw 'LibraryHelperInputChangedDuringBuild'}
    }
    $objects=@();$built=@()
    foreach($name in @('r4libraries_helpers.o','r4libraries_facades.o')){
        $path=Join-Path $prefix ('lib/'+$name)
        $objects+=$path;$built+=@{name=$name;sha256=Hash $path}
    }
    return @{objects=$objects;inputs=$inputs;receipt=@{owner='Libraries';compiler='zig';version=$pin.version;objects=$built;stack_probes=$true}}
}
