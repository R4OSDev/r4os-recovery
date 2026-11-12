# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
$out = Join-Path $buildRoot 'NativeBindings'
[IO.Directory]::CreateDirectory($out) | Out-Null
$all = $cArgs
$clangArgs = @($script:R4SdkNative.data.Build.codegen.'native-flags'.binding_c_flags)
for ($i = 0; $i -lt $all.Count; $i++) {
    if ($all[$i] -eq '-isystem') { $clangArgs += @($all[$i],$all[$i+1]); $i++ }
    elseif ($all[$i].StartsWith('-I') -or $all[$i].StartsWith('-D')) { $clangArgs += $all[$i] }
}
$types = @('exec_list','exec_node','float_controls','gc_ctx','gl_access_qualifier','gl_frag_result','gl_interp_mode',
    'gl_subgroup_size','gl_system_value','gl_tess_spacing','gl_varying_slot','gl_vert_attrib','glsl_sampler_dim',
    'glsl_type','glsl_matrix_layout','mesa_scope','mesa_prim','mesa_shader_stage','nir_.*','shader_info',
    'tess_primitive_mode','u_printf_info','util_dynarray')
$common = @('--rust-target',($script:R4SdkNative.data.Tools.tools.graphics.rustc.Split('.')[0..1] -join '.'),'--use-core','--ctypes-prefix','core::ffi','--with-derive-default',
    '--no-prepend-enum-name','--formatter','none','--disable-header-comment')
$argv = @((Join-Path $source 'src/compiler/rust/bindings.h')) + $common
foreach ($pattern in $types + @('u_memstream')) { $argv += @('--allowlist-type',$pattern) }
foreach ($pattern in @('NIR_.*','nir_.*_infos','rust_.*')) { $argv += @('--allowlist-var',$pattern) }
foreach ($pattern in @('glsl_.*','_mesa_shader_stage_to_string','_mesa_.*half.*','_mesa_.*float16.*','nir_.*','compiler_rs.*','u_memstream.*','util_dynarray.*')) { $argv += @('--allowlist-function',$pattern) }
$argv += @('--wrap-static-fns','--wrap-static-fns-suffix','_compiler_rs_extern','--wrap-static-fns-path',
    (Join-Path $out 'bindings'),'-o',(Join-Path $out 'compiler.rs'),'--') + $clangArgs
& $tools.bindgen @argv 2> (Join-Path $out 'compiler.log')
if ($LASTEXITCODE) { Get-Content -LiteralPath (Join-Path $out 'compiler.log') -TotalCount 40; throw 'compiler bindings failed' }
$argv = @((Join-Path $source 'src/nouveau/compiler/nak_bindings.h')) + $common
foreach ($pattern in $types + @('glsl_.*','pipe_format.*')) { $argv += @('--blocklist-type',$pattern) }
foreach ($pattern in @('nak_.*','nv_device_info')) { $argv += @('--allowlist-type',$pattern) }
foreach ($pattern in @('NAK_.*','NVIDIA_VENDOR_ID')) { $argv += @('--allowlist-var',$pattern) }
$argv += @('--allowlist-function','nak_.*','--raw-line','use compiler::bindings::*;',
    '-o',(Join-Path $out 'nak_bindings.rs'),'--') + $clangArgs
& $tools.bindgen @argv 2> (Join-Path $out 'nak.log')
if ($LASTEXITCODE) { Get-Content -LiteralPath (Join-Path $out 'nak.log') -TotalCount 40; throw 'nak bindings failed' }
Write-Host 'Native C/Rust bindings generated for the R4OS ABI.'
