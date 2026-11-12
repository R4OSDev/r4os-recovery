# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = Get-R4VideoPaths
$source = Join-Path $paths.cache 'Source'
$output = Join-Path $paths.cache 'Generated'
$hostBuild = Join-Path $output 'TableHost'
$record = Join-Path $output 'tables.json'
$tables = @(
    @{name='cavlc'; generator='CavlcTables'; sources=@('libavcodec/vlc.c','libavutil/reverse.c')},
    @{name='h274'; generator='H274Tables'; sources=@()},
    @{name='mpeg12'; generator='Mpeg12Tables'; sources=@('libavcodec/vlc.c','libavutil/reverse.c','libavcodec/mpeg12data.c')},
    @{name='msmp4'; generator='Msmp4Tables'; sources=@('libavcodec/vlc.c','libavutil/reverse.c')},
    @{name='intrax8'; generator='Intrax8Tables'; sources=@('libavcodec/vlc.c','libavutil/reverse.c')},
    @{name='vc1'; generator='Vc1Tables'; sources=@('libavcodec/vlc.c','libavutil/reverse.c','libavcodec/vc1data.c','libavcodec/msmpeg4_vc1_data.c')}
)
$provider = (Get-Content -Raw -LiteralPath (Join-Path $paths.unit 'ThirdParty/Sources.json') | ConvertFrom-Json).sources[0]
$zig = Join-Path $paths.zig $(if ($IsWindows) { 'zig.exe' } else { 'zig' })
$inputs = @($PSCommandPath, (Join-Path $PSScriptRoot 'Common.ps1'),
    (Join-Path $paths.cache 'prepare.json'), (Join-Path $paths.unit 'Port/Config/config.h'), (Join-Path $PSScriptRoot 'VlcTableHost.h'), $zig)
foreach ($table in $tables) {
    $pinPath = Join-Path $PSScriptRoot ($table.generator+'.json')
    $table.pin = Get-Content -Raw -LiteralPath $pinPath | ConvertFrom-Json
    if ($table.pin.schema -ne 1 -or $table.pin.ffmpeg -ne $provider.version) { throw 'Tables differ from the FFmpeg source version.' }
    $table.header = Join-Path $output ('r4video_'+$table.name+'_tables.h')
    $inputs += @($pinPath, (Join-Path $PSScriptRoot ($table.generator+'.c')))
}
$identities = @($inputs | ForEach-Object { [ordered]@{path=[IO.Path]::GetRelativePath($paths.workspace,$_).Replace('\','/'); sha256=(Get-R4VideoHash $_)} })
$identity = [ordered]@{sdk_profiles=$script:R4SdkNative.data.hashes;schema=1; host=$(if($IsWindows){'Windows-x64'}else{'Linux-x64'}); inputs=$identities}
$id = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($identity | ConvertTo-Json -Depth 6 -Compress)))).ToLowerInvariant()
if (Test-Path -LiteralPath $record) {
    $previous = Get-Content -Raw -LiteralPath $record | ConvertFrom-Json
    if ($previous.identity -eq $id) {
        foreach ($table in $tables) {
            if ((Get-R4VideoHash $table.header) -ne $table.pin.sha256 -or (Get-Item -LiteralPath $table.header).Length -ne $table.pin.bytes) { throw "Generated $($table.name) tables changed." }
        }
        Write-Host 'Verified immutable H.264/H.274/MPEG2/VC1 tables.'
        return
    }
    [IO.File]::Delete($record)
}
[IO.Directory]::CreateDirectory($hostBuild) | Out-Null
# These host tools invoke only the upstream table initializers. Neither creates
# decoder workers nor chooses target capabilities. Host libc provides its I/O.
$config = [IO.File]::ReadAllText((Join-Path $paths.unit 'Port/Config/config.h'))
foreach ($name in @('HAVE_PTHREADS','HAVE_THREADS','HAVE_INLINE_ASM','HAVE_X86ASM','HAVE_POSIX_MEMALIGN')) {
    $config = [regex]::Replace($config, ('(?m)^#define '+$name+' [01]$'), ('#define '+$name+' 0'))
}
foreach ($name in @('HAVE_ERF','HAVE_HYPOT')) {
    $config = [regex]::Replace($config, ('(?m)^#define '+$name+' [01]$'), ('#define '+$name+' 1'))
}
[IO.File]::WriteAllText((Join-Path $hostBuild 'config.h'), $config, [Text.UTF8Encoding]::new($false))
$outputs = @()
foreach ($table in $tables) {
    $exe = Join-Path $hostBuild ($table.name+'-tables'+$(if($IsWindows){'.exe'}else{''}))
    $arguments = @($script:R4SdkNative.data.Build.codegen.'native-flags'.video_table_host_flags)+@(
    ('-I'+$hostBuild), ('-I'+(Join-Path $paths.unit 'Port/Config')), ('-I'+$source),
    (Join-Path $PSScriptRoot ($table.generator+'.c')))
    $arguments += @($table.sources | ForEach-Object { Join-Path $source $_ })
    $arguments += @($script:R4SdkNative.data.Build.codegen.'native-flags'.video_table_link_flags)+@('-o',$exe)
    $buildLog = Join-Path $hostBuild ($table.name+'-build.log')
    & $zig @arguments 2> $buildLog
    if ($LASTEXITCODE) { throw "Table generator build failed; see $buildLog." }
    $lines = @(& $exe 2> (Join-Path $hostBuild ($table.name+'-generate.log')))
    if ($LASTEXITCODE) { throw "Upstream $($table.name) table initialization failed." }
    # Canonical LF regardless of the host C runtime's stdout text mode.
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($lines -join "`n")+"`n")
    $hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    if ($bytes.Length -ne $table.pin.bytes -or $hash -ne $table.pin.sha256) { throw "$($table.name) output differs from the reviewed upstream table data." }
    [IO.File]::WriteAllBytes($table.header,$bytes)
    $outputs += [ordered]@{name=$table.name; sha256=$hash; bytes=$bytes.Length}
}
[ordered]@{schema=1; identity=$id; inputs=$identity; outputs=$outputs} |
    ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $record -Encoding utf8NoBOM
Write-Host 'Generated immutable H.264/H.274/MPEG2/VC1 tables.'
