# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
# Called within Build.ps1; paths and checked tools belong to that owner.
function Copy-RustPort([string]$Name, [string]$Origin) {
    $dest = Join-Path $buildRoot "Rust/$Name"
    [IO.Directory]::CreateDirectory($dest) | Out-Null
    foreach ($file in Get-ChildItem -LiteralPath $Origin -Filter '*.rs' -File) {
        $s = [IO.File]::ReadAllText($file.FullName).Replace("`r`n", "`n")
        $declarations = [regex]::Matches($s, '(?m)^(?:#!\[.*|//!.*)$')
        $pos = if ($declarations.Count) { $last = $declarations[$declarations.Count-1]; $last.Index + $last.Length } else { 0 }
        $s = $s.Insert($pos,"`nuse std::prelude::*;`n")
        $s = [regex]::Replace($s,'(?m)^(\s*(?:pub )?mod \w+ \{)', ('$1' + "`n    use std::prelude::*;"))
        [IO.File]::WriteAllText((Join-Path $dest $file.Name), $s)
    }
}
Copy-RustPort compiler (Join-Path $hostBuild 'src/compiler/rust/libcompiler.rlib.p/structured')
Copy-RustPort nak_rs (Join-Path $source 'src/nouveau/compiler/nak')
Copy-RustPort nvidia_headers (Join-Path $hostBuild 'src/nouveau/headers')
Copy-RustPort nak_latencies (Join-Path $hostBuild 'src/nouveau/compiler/latencies')
Copy-RustPort bitview (Join-Path $source 'src/nouveau/rust/bitview')
Copy-RustPort nak_bindings (Join-Path $hostBuild 'src/nouveau/compiler')
Copy-Item -LiteralPath (Join-Path $buildRoot 'NativeBindings/compiler.rs') -Destination (Join-Path $buildRoot 'Rust/compiler/bindings.rs')
$binding = [IO.File]::ReadAllText((Join-Path $buildRoot 'NativeBindings/nak_bindings.rs'))
[IO.File]::WriteAllText((Join-Path $buildRoot 'Rust/nak_bindings/nak_bindings.rs'), "use std::prelude::*;`n" + $binding)
$hash = Join-Path $buildRoot 'Rust/rustc_hash'
[IO.Directory]::CreateDirectory($hash) | Out-Null
Get-ChildItem -LiteralPath (Join-Path $source 'subprojects/rustc-hash-2.1.1/src') -File | Copy-Item -Destination $hash
$hashRoot = Join-Path $hash 'lib.rs'
[IO.File]::WriteAllText($hashRoot, [IO.File]::ReadAllText($hashRoot).Replace('extern crate std;', 'extern crate r4os_std as std;'))
foreach ($name in @('compiler','nak_rs','nvidia_headers','nak_latencies','bitview','nak_bindings')) {
    $leaf = if ($name -eq 'nak_bindings') { 'nak_bindings.rs' } else { 'lib.rs' }
    $path = Join-Path $buildRoot "Rust/$name/$leaf"
    $s = [IO.File]::ReadAllText($path)
    $pos = $s.IndexOf('use std::prelude::*;')
    if ($pos -lt 0) { throw "Missing Rust port root: $name" }
    $s = $s.Insert($pos, "#![no_std]`n#[macro_use] extern crate r4os_std as std;`n#[macro_use] extern crate alloc;`n")
    [IO.File]::WriteAllText($path,$s)
}
# Algorithm changes are deliberately excluded. Only runtime facilities which
# are unavailable in the freestanding target are adapted here.
$path = Join-Path $buildRoot 'Rust/nak_rs/api.rs'
$s = [IO.File]::ReadAllText($path).Replace("use std::panic;`n", '')
$before = @'
    if DEBUG.panic() {
        compile()
    } else {
        panic::catch_unwind(compile).unwrap_or(std::ptr::null_mut())
    }
'@
if (!$s.Contains($before)) { throw 'Pinned NAK panic boundary changed.' }
$s = $s.Replace($before, @'
    // R4OS: a failed job terminates its disposable worker without unwinding
    // through C or resuming Rust frames whose allocation failed.
    compile()
'@)
# Debug configuration is explicit and disabled in ABI1. A killed worker must
# never leave a process-global OnceLock stuck in its initializing state.
$s = $s.Replace('self.get_or_init(Debug::new).flags', '0')
[IO.File]::WriteAllText($path,$s)
$path = Join-Path $buildRoot 'Rust/nak_rs/opt_instr_sched_common.rs'
$s = [IO.File]::ReadAllText($path)
$needle = '10_f32.powf((loop_depth + 1.0).log2()) as u64'
if (!$s.Contains($needle)) { throw 'Pinned NAK scheduling math changed.' }
$s = $s.Replace($needle, @'
unsafe {
        unsafe extern "C" { fn powf(x: f32, y: f32) -> f32; fn log2f(x: f32) -> f32; }
        powf(10.0, log2f(loop_depth + 1.0)) as u64
    }
'@)
$end = $s.IndexOf("#[allow(dead_code)]`npub fn save_graphviz(")
if ($end -lt 0) { throw 'Pinned NAK graph exporter changed.' }
[IO.File]::WriteAllText($path,$s.Substring(0,$end))
