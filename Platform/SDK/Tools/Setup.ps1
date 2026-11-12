param(
    [Parameter(Mandatory)][string]$InstallRoot,
    [string[]]$Tools = @('zig','rust','limine','qemu'),
    [string]$ReuseRoot = '',
    [switch]$Check
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$sdkRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'ProfileData.ps1')
$sdkProfiles=Read-R4SdkProfiles $sdkRoot
$installRoot=[IO.Path]::GetFullPath($InstallRoot)
$hostId=if($IsWindows){'Windows'}elseif($IsLinux){'Linux'}else{throw 'Unsupported SDK host.'}
$executableSuffix=if($IsWindows){'.exe'}else{''}
$zigPin=$sdkProfiles.Tools.tools.zig
$zigVersion=$zigPin.version
$limineVersion=$sdkProfiles.Tools.tools.limine.version
$qemuVersionPrefix='QEMU emulator version '+$sdkProfiles.Tools.tools.qemu.hosts[$hostId].version+' '
$zigTarget=Join-Path $installRoot 'Toolchains/Zig'
$limineTarget=Join-Path $installRoot 'Boot/Limine'
$qemuTarget=Join-Path $installRoot 'Emulation/QEMU'
$zigExecutable=Join-Path $zigTarget ('zig'+$executableSuffix)
$limineExecutable=Join-Path $limineTarget $(if($IsWindows){'limine-tool-windows-x86/limine.exe'}else{'limine'})
$qemuExecutable=Join-Path $qemuTarget ('qemu-system-x86_64'+$executableSuffix)
$tempRoot=Join-Path $installRoot ('Temp/Setup-'+[Guid]::NewGuid().ToString('N'))
$curlExecutable=(Get-Command $(if($IsWindows){'curl.exe'}else{'curl'}) -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
foreach($name in $Tools){if($name -cnotin @('zig','rust','limine','qemu')){throw "Unknown SDK installation tool: $name"}}
function Get-RequiredCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Description = $Name
    )
    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) { throw ($Description + ' wurde nicht gefunden: ' + $Name) }
    return $command.Source
}

function Invoke-External {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory = '',
        [string]$FailureMessage = 'Externer Befehl fehlgeschlagen.'
    )
    $previousLocation = $null
    if ($WorkingDirectory -ne '') { $previousLocation = Get-Location; Set-Location -LiteralPath $WorkingDirectory }
    try {
        & $FilePath @Arguments
        if ($LASTEXITCODE -ne 0) { throw ($FailureMessage + ' Exitcode: ' + $LASTEXITCODE) }
    }
    finally {
        if ($null -ne $previousLocation) { Set-Location -LiteralPath $previousLocation }
    }
}

function Get-ExternalOutput {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory = ''
    )
    $previousLocation = $null
    if ($WorkingDirectory -ne '') { $previousLocation = Get-Location; Set-Location -LiteralPath $WorkingDirectory }
    try {
        $previousErrorAction = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try { $output = @(& $FilePath @Arguments 2>&1); $exitCode = $LASTEXITCODE }
        finally { $ErrorActionPreference = $previousErrorAction }
        return [pscustomobject]@{ ExitCode = $exitCode; Output = @($output | ForEach-Object { [string]$_ }) }
    }
    finally {
        if ($null -ne $previousLocation) { Set-Location -LiteralPath $previousLocation }
    }
}

function Test-Version {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Expected,
        [switch]$Exact
    )
    if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) { return $false }
    $result = Get-ExternalOutput $Executable $Arguments
    if ($result.ExitCode -ne 0 -or $result.Output.Count -eq 0) { return $false }
    $line = [string]$result.Output[0]
    if ($Exact) { return $line -ceq $Expected }
    return $line.StartsWith($Expected, [StringComparison]::Ordinal)
}

function Assert-EmptyDirectory {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][string]$Label)
    if (-not (Test-Path -LiteralPath $Path)) { [void](New-Item -ItemType Directory -Path $Path) }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { throw ($Label + '-Ziel ist kein Verzeichnis: ' + $Path) }
    if ($null -ne (Get-ChildItem -LiteralPath $Path -Force | Select-Object -First 1)) {
        throw ($Label + '-Ziel ist nicht leer: ' + $Path)
    }
}

function Remove-EmptyDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    if ($null -ne (Get-ChildItem -LiteralPath $Path -Force | Select-Object -First 1)) {
        throw ('Verzeichnis ist nicht leer und wird nicht entfernt: ' + $Path)
    }
    Remove-Item -LiteralPath $Path
}

function Download-File {
    param([Parameter(Mandatory = $true)][string]$Url, [Parameter(Mandatory = $true)][string]$Destination, [Parameter(Mandatory = $true)][string]$Label)
    Write-Host ('Lade ' + $Label + ' herunter ...')
    Invoke-External $curlExecutable @('--fail', '--location', '--proto', '=https', '--tlsv1.2', '--max-time', '600', '--retry', '3', '--retry-delay', '2', '--connect-timeout', '30', '--progress-bar', '--output', $Destination, $Url) -FailureMessage ('Download fehlgeschlagen: ' + $Label)
}

function Assert-Hash {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][ValidateSet('SHA256', 'SHA512')][string]$Algorithm,
        [Parameter(Mandatory = $true)][string]$Expected,
        [Parameter(Mandatory = $true)][string]$Label
    )
    Write-Host ('Pruefe ' + $Label + ' ...')
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm $Algorithm).Hash
    if (-not $actual.Equals($Expected, [StringComparison]::OrdinalIgnoreCase)) { throw ('Pruefsumme stimmt nicht: ' + $Label) }
}

function Expand-Zip {
    param([Parameter(Mandatory = $true)][string]$Archive, [Parameter(Mandatory = $true)][string]$Destination)
    [void](New-Item -ItemType Directory -Path $Destination)
    Expand-Archive -LiteralPath $Archive -DestinationPath $Destination -Force
}

function Install-Zig {
    if (Test-Version $zigExecutable @('version') $zigVersion -Exact) { Write-Host ('[OK] Zig ' + $zigVersion + ' ist bereits installiert.'); return }
    Assert-EmptyDirectory $zigTarget 'Zig'
    Write-Host ('=== Zig ' + $zigVersion + ' ===')
    if ($IsWindows) {
        $url = $zigPin.hosts.Windows.url
        $hash = $zigPin.hosts.Windows.sha256
        $archive = Join-Path $tempRoot 'zig.zip'; $extract = Join-Path $tempRoot 'Zig'
        Download-File $url $archive 'Zig'; Assert-Hash $archive SHA256 $hash 'Zig'; Expand-Zip $archive $extract
        $source = Join-Path $extract ('zig-x86_64-windows-' + $zigVersion)
    }
    else {
        $url = $zigPin.hosts.Linux.url
        $hash = $zigPin.hosts.Linux.sha256
        $archive = Join-Path $tempRoot 'zig.tar.xz'; $extract = Join-Path $tempRoot 'Zig'
        [void](New-Item -ItemType Directory -Path $extract)
        Download-File $url $archive 'Zig'; Assert-Hash $archive SHA256 $hash 'Zig'
        Invoke-External (Get-RequiredCommand 'tar') @('-xJf', $archive, '-C', $extract) -FailureMessage 'Zig konnte nicht entpackt werden.'
        $source = Join-Path $extract ('zig-x86_64-linux-' + $zigVersion)
    }
    $sourceExecutable = Join-Path $source ('zig' + $executableSuffix)
    if (-not (Test-Version $sourceExecutable @('version') $zigVersion -Exact)) { throw 'Das entpackte Zig-Artefakt besitzt eine unerwartete Version oder Struktur.' }
    Remove-EmptyDirectory $zigTarget; Move-Item -LiteralPath $source -Destination $zigTarget
    Write-Host ('[OK] Zig wurde installiert: ' + $zigTarget)
}

function Install-Limine {
    if (Test-Version $limineExecutable @('--version') ('Limine ' + $limineVersion)) { Write-Host ('[OK] Limine ' + $limineVersion + ' ist bereits installiert.'); return }
    Assert-EmptyDirectory $limineTarget 'Limine'
    Write-Host ('=== Limine ' + $limineVersion + ' ===')
    $url = $sdkProfiles.Tools.tools.limine.url
    $hash = $sdkProfiles.Tools.tools.limine.sha256
    $archive = Join-Path $tempRoot 'limine.zip'; $extract = Join-Path $tempRoot 'Limine'
    Download-File $url $archive 'Limine'; Assert-Hash $archive SHA256 $hash 'Limine'; Expand-Zip $archive $extract
    $source = Join-Path $extract ('limine-binary-' + $limineVersion)
    if ($IsLinux) { Invoke-External (Get-RequiredCommand 'make') @('-C', $source) -FailureMessage 'Das Limine-Hostwerkzeug konnte nicht gebaut werden.' }
    $sourceExecutable = if ($IsWindows) { Join-Path $source 'limine-tool-windows-x86/limine.exe' } else { Join-Path $source 'limine' }
    if (-not (Test-Version $sourceExecutable @('--version') ('Limine ' + $limineVersion))) { throw 'Das Limine-Artefakt besitzt eine unerwartete Version oder Struktur.' }
    Remove-EmptyDirectory $limineTarget; Move-Item -LiteralPath $source -Destination $limineTarget
    Write-Host ('[OK] Limine wurde installiert: ' + $limineTarget)
}

function Install-QemuWindows {
    $qemuArchive = Join-Path $tempRoot 'qemu.exe'; $sevenZipBootstrap = Join-Path $tempRoot '7zr.exe'
    $sevenZipArchive = Join-Path $tempRoot '7z-x64.exe'; $sevenZipExtract = Join-Path $tempRoot 'SevenZip'; $qemuExtract = Join-Path $tempRoot 'QEMU'
    Download-File $sdkProfiles.Tools.tools.qemu.hosts.Windows.url $qemuArchive 'QEMU'
    Assert-Hash $qemuArchive SHA512 $sdkProfiles.Tools.tools.qemu.hosts.Windows.sha512 'QEMU'
    Download-File $sdkProfiles.Tools.tools.sevenzip.bootstrap_url $sevenZipBootstrap '7-Zip-Bootstrap'
    Assert-Hash $sevenZipBootstrap SHA256 $sdkProfiles.Tools.tools.sevenzip.bootstrap_sha256 '7-Zip-Bootstrap'
    Download-File $sdkProfiles.Tools.tools.sevenzip.url $sevenZipArchive '7-Zip'
    Assert-Hash $sevenZipArchive SHA256 $sdkProfiles.Tools.tools.sevenzip.sha256 '7-Zip'
    [void](New-Item -ItemType Directory -Path $sevenZipExtract)
    Invoke-External $sevenZipBootstrap @('x', $sevenZipArchive, ('-o' + $sevenZipExtract), '-y') -FailureMessage '7-Zip konnte nicht vorbereitet werden.'
    $sevenZip = Join-Path $sevenZipExtract '7z.exe'
    if (-not (Test-Path -LiteralPath $sevenZip -PathType Leaf)) { throw 'Das 7-Zip-Paket besitzt eine unerwartete Struktur.' }
    [void](New-Item -ItemType Directory -Path $qemuExtract)
    Invoke-External $sevenZip @('x', $qemuArchive, ('-o' + $qemuExtract), '-y') -FailureMessage 'QEMU konnte nicht entpackt werden.'
    $pluginDirectory = Join-Path $qemuExtract '$PLUGINSDIR'; if (Test-Path -LiteralPath $pluginDirectory) { Remove-Item -LiteralPath $pluginDirectory -Recurse -Force }
    $uninstaller = Join-Path $qemuExtract 'qemu-uninstall.exe'; if (Test-Path -LiteralPath $uninstaller) { Remove-Item -LiteralPath $uninstaller -Force }
    if (-not (Test-Version (Join-Path $qemuExtract 'qemu-system-x86_64.exe') @('--version') $qemuVersionPrefix)) { throw 'Das QEMU-Artefakt besitzt eine unerwartete Version oder Struktur.' }
    Remove-EmptyDirectory $qemuTarget; Move-Item -LiteralPath $qemuExtract -Destination $qemuTarget
}

function Install-QemuLinux {
    $systemQemu = Get-RequiredCommand 'qemu-system-x86_64'
    if (-not (Test-Version $systemQemu @('--version') $qemuVersionPrefix)) { throw ('SdkToolIdentityMismatch: expected QEMU '+$sdkProfiles.Tools.tools.qemu.hosts.Linux.version) }
    $systemQemuImg = Get-RequiredCommand 'qemu-img'
    [void](New-Item -ItemType SymbolicLink -Path (Join-Path $qemuTarget 'qemu-system-x86_64') -Target $systemQemu)
    [void](New-Item -ItemType SymbolicLink -Path (Join-Path $qemuTarget 'qemu-img') -Target $systemQemuImg)
}

function Install-Qemu {
    if (Test-Version $qemuExecutable @('--version') $qemuVersionPrefix) { Write-Host ('[OK] QEMU '+$sdkProfiles.Tools.tools.qemu.hosts[$hostId].version+' ist bereits installiert.'); return }
    Assert-EmptyDirectory $qemuTarget 'QEMU'; Write-Host ('=== QEMU '+$sdkProfiles.Tools.tools.qemu.hosts[$hostId].version+' ===')
    if ($IsWindows) { Install-QemuWindows } else { Install-QemuLinux }
    if (-not (Test-Version $qemuExecutable @('--version') $qemuVersionPrefix)) { throw 'Die installierte QEMU-Version konnte nicht bestaetigt werden.' }
    Write-Host ('[OK] QEMU wurde eingerichtet: ' + $qemuTarget)
}


try {
    if(!$Check){[IO.Directory]::CreateDirectory($tempRoot)|Out-Null}
    $locations=@{zig='Toolchains/Zig';rust='Toolchains/Rust';limine='Boot/Limine';qemu='Emulation/QEMU'}
    if($ReuseRoot -and !$Check){
        $ReuseRoot=[IO.Path]::GetFullPath($ReuseRoot)
        foreach($name in $Tools){
            $target=Join-Path $installRoot $locations[$name]
            $source=Join-Path $ReuseRoot $locations[$name]
            if(!(Test-Path -LiteralPath $target) -and (Test-Path -LiteralPath $source -PathType Container)){
                [IO.Directory]::CreateDirectory((Split-Path $target -Parent))|Out-Null
                New-Item -ItemType $(if($IsWindows){'Junction'}else{'SymbolicLink'}) -Path $target -Target $source|Out-Null
            }
        }
    }
    $checks=[ordered]@{}
    foreach($name in $Tools){
        if(!$Check){
            switch -CaseSensitive ($name){
                'zig' {Install-Zig}
                'limine' {Install-Limine}
                'qemu' {Install-Qemu}
                'rust' {& pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Rust.ps1') --root $installRoot --profile kernel setup;if($LASTEXITCODE -ne 0){throw 'SDK Rust setup failed.'}}
            }
        }
        $ready=switch -CaseSensitive ($name){
            'zig' {Test-Version $zigExecutable @('version') $zigVersion -Exact}
            'limine' {Test-Version $limineExecutable @('--version') ('Limine '+$limineVersion) -Exact}
            'qemu' {Test-Version $qemuExecutable @('--version') $qemuVersionPrefix}
            'rust' {
                $description=@(& pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Rust.ps1') --root $installRoot --profile kernel check)
                if($LASTEXITCODE -ne 0){$false}else{(($description -join "`n")|ConvertFrom-Json).installed}
            }
        }
        if(!$ready){throw "SdkToolIdentityMismatch: $name"}
        $checks[$name]=@{ready=$true;location=(Join-Path $installRoot $locations[$name])}
    }
    $receipt=[ordered]@{schema=1;sdk_version=$sdkProfiles.sdk_version;host=$hostId;profiles=$sdkProfiles.hashes;tools=$checks}
    if(!$Check){[IO.File]::WriteAllText((Join-Path $installRoot '.SDK-Tools.json'),($receipt|ConvertTo-Json -Depth 10)+"`n")}
    $receipt|ConvertTo-Json -Depth 10
} finally {
    if(Test-Path -LiteralPath $tempRoot){Remove-Item -LiteralPath $tempRoot -Recurse -Force}
}
