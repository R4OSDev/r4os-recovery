# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
function Initialize-R4VKAMD {
    param([Parameter(Mandatory)]$Mesa, [Parameter(Mandatory)][string]$GeneratedRoot)
    $source = $Mesa.source
    $generated = Join-Path $GeneratedRoot 'AMD'
    [IO.Directory]::CreateDirectory($generated) | Out-Null
    $python = (Get-Command $(if ($IsWindows) {'python.exe'} else {'python3'}) -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    $glslang = (Get-Command $(if ($IsWindows) {'glslangValidator.exe'} else {'glslangValidator'}) -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    $version = @(& $glslang --version)
    $shaderLock = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'ShaderTools.lock.json') | ConvertFrom-Json
    if ($LASTEXITCODE -or $version[0] -ne ('Glslang Version: 11:' + $shaderLock.glslang)) { throw 'Pinned glslangValidator required for RADV helpers.' }
    function InvokeAMD([string[]]$Arguments, [string]$Capture) {
        $start = [Diagnostics.ProcessStartInfo]::new()
        $start.FileName = $python; $start.UseShellExecute = $false
        $start.Environment['PYTHONDONTWRITEBYTECODE'] = '1'; $start.Environment['PYTHONHASHSEED'] = '0'
        $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
        foreach ($item in $Arguments) { $start.ArgumentList.Add($item) }
        $process = [Diagnostics.Process]::Start($start)
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit(); $text = $stdout.GetAwaiter().GetResult(); $errorText = $stderr.GetAwaiter().GetResult()
        $code = $process.ExitCode; $process.Dispose()
        if ($code) { throw "AMD generator failed: $($Arguments[0]): $errorText" }
        if ($Capture) { [IO.File]::WriteAllText((Join-Path $generated $Capture), $text, [Text.UTF8Encoding]::new($false)) }
    }
    $xml = Join-Path $source 'src/vulkan/registry/vk.xml'
    InvokeAMD @((Join-Path $source 'src/vulkan/util/vk_entrypoints_gen.py'), '--xml', $xml, '--proto', '--weak', '--beta', 'false',
        '--out-c', (Join-Path $generated 'radv_entrypoints.c'), '--out-h', (Join-Path $generated 'radv_entrypoints.h'),
        '--prefix', 'radv', '--device-prefix', 'sqtt', '--device-prefix', 'rra', '--device-prefix', 'rmv',
        '--device-prefix', 'ctx_roll', '--device-prefix', 'utrace', '--device-prefix', 'annotate')
    $header = Join-Path $generated 'radv_entrypoints.h'
    $value = [IO.File]::ReadAllText($header).Replace("`r`n", "`n")
    $needle = "#ifndef _WIN32`n#define VK_ENTRY_HIDDEN __attribute__ ((visibility(`"hidden`")))"
    if (!$value.Contains($needle)) { throw 'RADV entrypoint template changed.' }
    $value = $value.Replace($needle, "#if defined(R4OS_VULKAN)`n#define VK_ENTRY_HIDDEN __attribute__ ((visibility(`"default`")))`n#elif !defined(_WIN32)`n#define VK_ENTRY_HIDDEN __attribute__ ((visibility(`"hidden`")))")
    [IO.File]::WriteAllText($header, $value, [Text.UTF8Encoding]::new($false))
    InvokeAMD @((Join-Path $source 'src/amd/vulkan/radv_drirc_gen.py'), '--import-path', (Join-Path $source 'src/util'),
        '--drirc-src', (Join-Path $generated 'radv_drirc.c'), '--drirc-hdr', (Join-Path $generated 'radv_drirc.h'),
        '--validate', (Join-Path $source 'src/amd/vulkan/00-radv-defaults.conf'))
    InvokeAMD @((Join-Path $source 'src/amd/vulkan/radv_tracepoints.py'), '--import-path', (Join-Path $source 'src/util/perf'),
        (Join-Path $source 'src/vulkan/util'), '--src', (Join-Path $generated 'radv_tracepoints.c'),
        '--entrypoints-src', (Join-Path $generated 'radv_entrypoint_tracepoints.c'),
        '--perfetto-hdr', (Join-Path $generated 'radv_tracepoints_perfetto.h'), '--hdr', (Join-Path $generated 'radv_tracepoints.h'), '--xml', $xml)
    foreach ($leaf in @('aco_opcodes_h', 'aco_builder_h', 'aco_opcodes_cpp')) {
        $destination = if ($leaf.EndsWith('_cpp')) { 'aco_opcodes.cpp' } else { $leaf.Substring(0, $leaf.Length - 2) + '.h' }
        InvokeAMD @((Join-Path $source "src/amd/compiler/$leaf.py")) $destination
    }
    $meson = [IO.File]::ReadAllText((Join-Path $source 'src/amd/common/meson.build'))
    $block = [regex]::Match($meson, '(?s)amd_register_files = \[(.*?)\n\]').Groups[1].Value
    $registers = @([regex]::Matches($block, "'([^']+)'") | ForEach-Object { [IO.Path]::GetFullPath($_.Groups[1].Value, (Join-Path $source 'src/amd/common')) })
    InvokeAMD (@((Join-Path $source 'src/amd/registers/makeregheader.py')) + $registers + @('--sort', 'address', '--guard', 'AMDGFXREGS_H')) 'amdgfxregs.h'
    [IO.Directory]::CreateDirectory((Join-Path $generated 'common')) | Out-Null
    Copy-Item (Join-Path $generated 'amdgfxregs.h') (Join-Path $generated 'common/amdgfxregs.h') -Force
    InvokeAMD (@((Join-Path $source 'src/amd/common/sid_tables.py'), (Join-Path $source 'src/amd/common/sid.h')) + $registers) 'sid_tables.h'
    InvokeAMD @((Join-Path $source 'src/amd/common/gfx10_format_table.py'), (Join-Path $source 'src/util/format/u_format.yaml'),
        (Join-Path $source 'src/amd/registers/gfx10-rsrc.json'), (Join-Path $source 'src/amd/registers/gfx11-rsrc.json')) 'gfx10_format_table.c'
    $packets = Join-Path $source 'src/amd/packets'
    $pairs = @(foreach ($gen in @('gfx11', 'gfx12')) { Join-Path $packets "cp_pm4_table_data_$gen.json"; Join-Path $packets "pm4_it_opcodes_$gen.h" })
    foreach ($gen in @('gfx11', 'gfx12')) {
        $script = Join-Path $packets 'parse_cp_pm4_table_data_json.py'
        InvokeAMD (@($script) + $pairs + @($gen, 'packets_h')) "amd_cp_packets_$gen.h"
        $pair = @((Join-Path $packets "cp_pm4_table_data_$gen.json"), (Join-Path $packets "pm4_it_opcodes_$gen.h"))
        InvokeAMD (@($script) + $pair + @($gen, 'print_c')) "amd_cp_print_packet_$gen.c"
        InvokeAMD (@($script) + $pair + @($gen, 'print_h')) "amd_cp_print_packet_$gen.h"
    }
    # The complete upstream RADV closure contains RT helper code. Building its
    # immutable shader data does not admit a ray-tracing feature on Picasso.
    $bvh = Join-Path $generated 'bvh'; [IO.Directory]::CreateDirectory($bvh) | Out-Null
    $text = [IO.File]::ReadAllText((Join-Path $source 'src/vulkan/runtime/bvh/meson.build'))
    $block = [regex]::Match($text, '(?s)vk_glsl_shader_extensions = \[(.*?)\n\]').Groups[1].Value
    $preamble = @([regex]::Matches($block, "'([^']+)'") | ForEach-Object { '-P#extension ' + $_.Groups[1].Value + ' : require' })
    $arguments = @('-V', '--target-env', 'spirv1.5', '-x') + @('src/amd/vulkan/bvh', 'src/vulkan/runtime/bvh', 'src/compiler/spirv' | ForEach-Object { '-I' + (Join-Path $source $_) }) + $preamble
    foreach ($name in @('copy_addrs', 'copy', 'encode', 'encode_gfx12', 'encode_triangles_gfx12', 'header', 'update', 'update_gfx12', 'leaf')) {
        $stem = if ($name -eq 'leaf') { 'radv_leaf' } else { $name }
        & $glslang @arguments -o (Join-Path $bvh "$stem.spv.h") (Join-Path $source "src/amd/vulkan/bvh/$name.comp")
        if ($LASTEXITCODE) { throw "RADV SPIR-V helper failed: $name" }
    }
    foreach ($name in @('lbvh_generate_ir', 'lbvh_main', 'leaf', 'morton', 'ploc_internal', 'hploc_internal')) {
        & $glslang @arguments -o (Join-Path $bvh "$name.spv.h") (Join-Path $source "src/vulkan/runtime/bvh/$name.comp")
        if ($LASTEXITCODE) { throw "Vulkan BVH helper failed: $name" }
    }
    $radix = Join-Path $generated 'radix_sort/shaders'; [IO.Directory]::CreateDirectory($radix) | Out-Null
    $text = [IO.File]::ReadAllText((Join-Path $source 'src/vulkan/runtime/radix_sort/shaders/meson.build'))
    $entries = [regex]::Matches($text, "\[\s*'([^']+\.comp)',\s*'([^']+)',\s*\[([^\]]*)\]")
    if ($entries.Count -ne 17) { throw 'Pinned radix shader inventory changed.' }
    foreach ($entry in $entries) {
        $options = @([regex]::Matches($entry.Groups[3].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
        & $glslang -V --target-env spirv1.5 -x @options -o (Join-Path $radix ($entry.Groups[2].Value + '.spv.h')) (Join-Path $source ('src/vulkan/runtime/radix_sort/shaders/' + $entry.Groups[1].Value))
        if ($LASTEXITCODE) { throw 'Vulkan radix helper failed.' }
    }
    & $glslang -V -S comp -x -o (Join-Path $generated 'astc_spv.h') (Join-Path $source 'src/compiler/glsl/astc_decoder.glsl')
    if ($LASTEXITCODE) { throw 'ASTC helper failed.' }
}
