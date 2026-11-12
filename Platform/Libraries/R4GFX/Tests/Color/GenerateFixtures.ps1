$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$root=[IO.Path]::GetFullPath('../../../../..',$PSScriptRoot)
$owner=[IO.Path]::GetFullPath('../..',$PSScriptRoot)
$temporary=Join-Path $root 'Temp/gfx-color-fixtures'
$destination=Join-Path $PSScriptRoot 'Fixtures'
New-Item -ItemType Directory -Force -Path $temporary,$destination | Out-Null
$zig=Join-Path $root $(if($IsWindows){'DevKit/Toolchains/Zig/zig.exe'}else{'DevKit/Toolchains/Zig/zig'})
$program=Join-Path $temporary $(if($IsWindows){'MakeFixtures.exe'}else{'MakeFixtures'})
$sources=@(Get-ChildItem -LiteralPath (Join-Path $owner 'ThirdParty/LittleCMS/src') -Filter '*.c' | Sort-Object Name | ForEach-Object FullName)
& $zig cc -std=c11 -O2 -DCMS_NO_PTHREADS=1 -DCMS_NO_REGISTER_KEYWORD=1 -I (Join-Path $owner 'ThirdParty/LittleCMS/include') (Join-Path $PSScriptRoot 'MakeFixtures.c') @sources -lm -o $program
if($LASTEXITCODE){throw 'Fixture generator failed to compile'}
& $program $destination
if($LASTEXITCODE){throw 'Fixture generation failed'}
$files=@(Get-ChildItem -LiteralPath $destination -Filter '*.icc' | Sort-Object Name | ForEach-Object {
    [ordered]@{path=$_.Name;bytes=$_.Length;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}
})
$manifest=[ordered]@{description='Original synthetic fixtures; no real monitor characterization. Stable ICC creation date2026-09-14. LUT XYZ components equal RGB components; VCGT channel peaks3/4,1/2,1. Descending VCGT must be rejected when calibration is requested.';generator='MakeFixtures.c using vendored LittleCMS2.18';files=$files}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'Fixtures.json'),($manifest | ConvertTo-Json -Depth 5)+"`n",[Text.UTF8Encoding]::new($false))
Write-Host "Generated $($files.Count) ICC fixtures."
