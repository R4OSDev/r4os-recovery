# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
$targets = Get-Content -LiteralPath (Join-Path $hostBuild 'meson-info/intro-targets.json') -Raw | ConvertFrom-Json
$names = @('compiler','nir','nak','compiler_bindings','compiler_c_helpers','vtn')
$cPaths = [Collections.Generic.List[string]]::new()
foreach ($target in $targets) {
    if ($target.name -notin $names) { continue }
    foreach ($group in $target.target_sources) {
        if (!$group.PSObject.Properties['language'] -or $group.language -ne 'c') { continue }
        foreach ($file in @($group.sources) + @($group.generated_sources)) {
            if ($file.EndsWith('.c') -and !$file.Replace('\','/').Contains('/nouveau/headers/')) { $cPaths.Add($file) }
        }
    }
}
foreach ($name in @('bitscan','blob','dag','half_float','hash_table','memstream','ralloc','rgtc','set','softfloat','u_debug','u_dynarray','u_math','u_printf','u_string','fast_idiv_by_const','double','float8','range_minimum_query','rb_tree','u_vector','u_worklist','simple_mtx','format/u_format')) {
    $f = Join-Path $source "src/util/$name.c"
    if (Test-Path -LiteralPath $f) { $cPaths.Add($f) }
}
$cPaths.Add((Join-Path $unit 'Port/libc.c'))
$cPaths.Add((Join-Path $unit 'Port/cpu.c'))
$cPaths.Add((Join-Path $unit 'Source/native.c'))
foreach ($name in @('blake3','blake3_dispatch','blake3_portable')) { $cPaths.Add((Join-Path $source "src/util/blake3/$name.c")) }
$cPaths.Add((Join-Path $source 'src/util/mesa-blake3.c'))
$cPaths.Add((Join-Path $hostBuild 'src/util/format/u_format_table.c'))
$cArgs = @($script:R4SdkNative.data.Build.codegen.'native-flags'.nak_c_flags) + @(
    '-isystem',(Join-Path (& $tools.clang -print-resource-dir) 'include'),"-I$(Join-Path $unit 'Port/Include')","-I$hostBuild")
foreach ($p in @('include','src','src/compiler','src/compiler/nir','src/compiler/rust','src/compiler/spirv','src/nouveau/compiler','src/nouveau/headers','src/nouveau/headers/nvidia/classes','src/nouveau/nil','src/util','src/util/format')) {
    $cArgs += "-I$(Join-Path $hostBuild $p)"
    $cArgs += "-I$(Join-Path $source $p)"
}
$cArgs += @('-DR4OS_NAK_STANDALONE=1','-DHAVE_GFX_COMPUTE','-DHAVE_OPENGL=0','-DHAVE_OPENGL_ES_1=0','-DHAVE_OPENGL_ES_2=0',
    '-DMESA_DEBUG=0','-DUSE_GCC_ATOMIC_BUILTINS','-DHAVE_UINT128','-DHAVE_STRUCT_TIMESPEC','-DHAVE_POSIX_MEMALIGN',
    '-DUTIL_ARCH_LITTLE_ENDIAN=1','-DUTIL_ARCH_BIG_ENDIAN=0','-DXXH_FORCE_ALIGN_CHECK=0','-DXXH_FORCE_MEMORY_ACCESS=0',
    '-DHAVE_FMEMOPEN','-DHAVE_REALLOCARRAY','-DPACKAGE_VERSION="26.2.2"',
    '-DBLAKE3_NO_SSE2','-DBLAKE3_NO_SSE41','-DBLAKE3_NO_AVX2','-DBLAKE3_NO_AVX512')
foreach ($a in @('BSWAP32','BSWAP64','CLZ','CLZLL','CTZ','EXPECT','FFS','FFSLL','POPCOUNT','POPCOUNTLL','UNREACHABLE','TYPES_COMPATIBLE_P','ADD_OVERFLOW')) {
    $cArgs += "-DHAVE___BUILTIN_$a"
}
foreach ($a in @('CONST','FLATTEN','MALLOC','PURE','UNUSED','WARN_UNUSED_RESULT','WEAK','FORMAT','PACKED','RETURNS_NONNULL','ALIAS','NORETURN','COLD','VISIBILITY')) {
    $cArgs += "-DHAVE_FUNC_ATTRIBUTE_$a"
}

# Select job-owned overlays and bindings generated for the target ABI.
$cPaths=@(foreach($path in $cPaths) {
    $relative=[IO.Path]::GetRelativePath($source,$path)
    $patched=Join-Path $overlay $relative
    if([IO.Path]::GetFileName($path) -eq 'bindings.c') {Join-Path $buildRoot 'NativeBindings/bindings.c'}
    elseif(!$relative.StartsWith('..') -and (Test-Path -LiteralPath $patched)) {$patched}
    else {$path}
})
