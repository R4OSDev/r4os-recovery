# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
function New-R4VKDispatchArchive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Zig,
        [Parameter(Mandatory)][string]$OutputFile,
        [Parameter(Mandatory)][string[]]$Objects
    )
    $ErrorActionPreference = 'Stop'
    if (!$Objects.Count) { throw 'A dispatch archive requires native objects.' }
    foreach ($file in $Objects) {
        if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Native object missing: $file" }
    }
    # Mesa's weak dispatch definitions require link_whole (runtime/meson.build).
    # Merge the explicit C object set into one relocatable archive member so
    # normal SDK archive extraction cannot omit a weak-only implementation.
    # Function/data sections remain separate for final section garbage collection.
    # Rust dependency archives keep their ordinary selective extraction semantics.
    $combined = [IO.Path]::ChangeExtension($OutputFile, '.whole.o')
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($OutputFile))) | Out-Null
    # Hundreds of paths exceed Windows' process command-line limit. LLD's
    # response file keeps the same explicit link_whole set on both hosts.
    $response = [IO.Path]::ChangeExtension($OutputFile, '.objects.rsp')
    [IO.File]::WriteAllLines($response, @($Objects | ForEach-Object {
        '"' + $_.Replace('\', '/').Replace('"', '\"') + '"'
    }), [Text.UTF8Encoding]::new($false))
    # Same-named static helper sections from different translation units must
    # stay distinct; merging them would retain unrelated shader/print globals.
    & $Zig ld.lld -r --unique ('@' + $response) -o $combined
    if ($LASTEXITCODE) { throw 'Native dispatch object link failed.' }
    # ar replaces matching members but retains other old members. A rebuild
    # must produce exactly this combined member, never a stale mixed archive.
    if (Test-Path -LiteralPath $OutputFile) { Remove-Item -LiteralPath $OutputFile -Force }
    & $Zig ar rcsD $OutputFile $combined
    if ($LASTEXITCODE) { throw 'Native dispatch archive creation failed.' }
}
