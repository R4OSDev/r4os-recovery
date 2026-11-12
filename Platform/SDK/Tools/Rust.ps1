param()

# Keep native switches, including Cargo's literal -- separator, unbound.
$Arguments = @($args)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$sdkRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$installRoot = Join-Path $sdkRoot '.Installed'
$toolsetSourceRoot = $sdkRoot
$explicitCacheRoot = ''
$profilePath = Join-Path $toolsetSourceRoot 'RustToolsProfile.json'
if(Test-Path -LiteralPath $profilePath -PathType Leaf){$installRoot=$toolsetSourceRoot}
$rustProfile = if (Test-Path -LiteralPath $profilePath -PathType Leaf) { 'sdk' } else { 'kernel' }
$developmentTools = $false
# Parse only the leading toolset options. Native Cargo/rustc switches and
# their literal -- remain unbound, preserving the existing DevKit interface.
while ($Arguments.Count -gt 0) {
    $option = $Arguments[0]
    if ($option -eq '--development-tools') {
        $developmentTools = $true
        $Arguments = @($Arguments | Select-Object -Skip 1)
        continue
    }
    if ($option -notin @('--root', '--cache-root', '--profile')) { break }
    if ($Arguments.Count -lt 2 -or !$Arguments[1]) { throw "Missing value for $option" }
    switch ($option) {
        '--root' { $installRoot = [IO.Path]::GetFullPath($Arguments[1], $toolsetSourceRoot) }
        '--cache-root' { $explicitCacheRoot = [IO.Path]::GetFullPath($Arguments[1], $toolsetSourceRoot) }
        '--profile' { $rustProfile = $Arguments[1] }
    }
    $Arguments = @($Arguments | Select-Object -Skip 2)
}
if ($rustProfile -ceq 'devkit') { $rustProfile = 'development' } # legacy spelling; SDK data still owns it
. (Join-Path $PSScriptRoot 'ProfileData.ps1')
$profileData = Read-R4SdkProfiles $sdkRoot
$pin = $profileData.Tools.tools.rust
if (!$pin.profiles.Contains($rustProfile)) { throw 'Unknown SDK Rust toolset profile.' }
if ($pin.format -ne 1) { throw 'Unbekanntes Rust-Toolchainformat.' }
if ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne [Runtime.InteropServices.Architecture]::X64) {
    throw 'Die Rust-Toolchain unterstuetzt derzeit x86_64-Hosts.'
}
$hostName = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } else { throw 'Rust-Setup unterstuetzt Windows und Linux.' }
$suffix = if ($IsWindows) { '.exe' } else { '' }
$hostTriple = $pin.hosts[$hostName].triple
$toolchainName = $pin.rust_version + '-' + $hostTriple
$rustRoot = Join-Path $installRoot 'Toolchains/Rust'
$cargoHome = Join-Path $rustRoot 'cargo'
$rustupHome = Join-Path $rustRoot 'rustup'
$cargoBin = Join-Path $cargoHome 'bin'
$rustupExe = Join-Path $cargoBin ('rustup' + $suffix)
$toolchainRoot = Join-Path $rustupHome ('toolchains/' + $toolchainName)
$llvmBin = Join-Path $toolchainRoot ('lib/rustlib/' + $hostTriple + '/bin')
$requiredComponents = @($pin.profiles[$rustProfile].required_components)
$wantedComponents = @($requiredComponents)
if ($rustProfile -eq 'sdk' -and $developmentTools) { $wantedComponents += @($pin.profiles.sdk.optional_components) }
$cacheRoot = if ($explicitCacheRoot) { $explicitCacheRoot } else { Join-Path $installRoot '.Cache/Rust' }
$script:RustReadinessReason = ''
$toolsetProfile = if (Test-Path -LiteralPath $profilePath -PathType Leaf) { Get-Content -Raw -LiteralPath $profilePath | ConvertFrom-Json -AsHashtable } else { $null }
$tool = if ($Arguments.Count -eq 0) { 'describe' } else { $Arguments[0] }
$toolArgs = @()
if ($Arguments.Count -gt 1) { $toolArgs = @($Arguments[1..($Arguments.Count - 1)]) }
$exitCode = 0
$environmentNames = @('RUSTUP_HOME', 'CARGO_HOME', 'RUSTUP_TOOLCHAIN', 'RUSTUP_AUTO_INSTALL',
    'RUSTUP_DIST_SERVER', 'RUSTUP_UPDATE_ROOT', 'RUSTUP_INIT_SKIP_PATH_CHECK', 'PATH')
$previousEnvironment = @{}
foreach ($name in $environmentNames) { $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }

function Invoke-RustNative([string]$Executable, [string[]]$NativeArguments) {
    & $Executable @NativeArguments
    if ($LASTEXITCODE -ne 0) { throw ('Rust-Werkzeug fehlgeschlagen: ' + [IO.Path]::GetFileName($Executable) + ', Exitcode ' + $LASTEXITCODE) }
}

function Get-RustOutput([string]$Executable, [string[]]$NativeArguments) {
    $result = @(& $Executable @NativeArguments)
    if ($LASTEXITCODE -ne 0) { throw ('Rust-Pruefung fehlgeschlagen: ' + [IO.Path]::GetFileName($Executable)) }
    return $result
}

function Get-RustProfilePath([string]$Relative) {
    if ([IO.Path]::IsPathRooted($Relative) -or $Relative.Contains('\') -or $Relative.Split('/') -contains '..') { throw 'Noncanonical toolset file path.' }
    return Join-Path $toolsetSourceRoot $Relative
}

function Test-RustProfileInputs {
    if ($null -eq $toolsetProfile) { return $true }
    if ($toolsetProfile.schema -ne 1 -or $toolsetProfile.id -cne $pin.profiles.sdk.id) {
        $script:RustReadinessReason = 'unsupported standalone toolset metadata'; return $false
    }
    foreach ($file in $toolsetProfile.files) {
        $path = Get-RustProfilePath $file.path
        if (!(Test-Path -LiteralPath $path -PathType Leaf)) { $script:RustReadinessReason = 'missing toolset input: ' + $file.path; return $false }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine $file.sha256) {
            $script:RustReadinessReason = 'toolset input hash mismatch: ' + $file.path; return $false
        }
    }
    return $true
}

function Test-RustReady {
    $script:RustReadinessReason = ''
    if (!(Test-RustProfileInputs)) { return $false }
    if (-not (Test-Path -LiteralPath $rustupExe -PathType Leaf)) { $script:RustReadinessReason = 'missing rustup'; return $false }
    $rustcExe = Join-Path $toolchainRoot ('bin/rustc' + $suffix)
    if (-not (Test-Path -LiteralPath $rustcExe -PathType Leaf)) { $script:RustReadinessReason = 'missing rustc'; return $false }
    $rustupVersion = (Get-RustOutput $rustupExe @('--version')) -join ' '
    $rustcVersion = (Get-RustOutput $rustcExe @('--version')) -join ' '
    if (-not $rustupVersion.StartsWith('rustup ' + $pin.rustup_version + ' ') -or
        -not $rustcVersion.StartsWith('rustc ' + $pin.rust_version + ' ')) { $script:RustReadinessReason = 'rustup/rustc version mismatch'; return $false }
    $cargoExe = Join-Path $toolchainRoot ('bin/cargo' + $suffix)
    if (!(Test-Path -LiteralPath $cargoExe -PathType Leaf)) { $script:RustReadinessReason = 'missing cargo'; return $false }
    $cargoVersion = (Get-RustOutput $cargoExe @('--version')) -join ' '
    if (!$cargoVersion.StartsWith('cargo ' + $pin.cargo_version + ' ')) { $script:RustReadinessReason = 'cargo version mismatch'; return $false }
    $components = @(Get-RustOutput $rustupExe @('component', 'list', '--toolchain', $toolchainName, '--installed'))
    foreach ($component in $wantedComponents) {
        $installedName = if ($component -eq 'rust-src') { 'rust-src' } else { $component.Replace('-preview', '') + '-' + $hostTriple }
        if ($installedName -notin $components) { $script:RustReadinessReason = 'missing component: ' + $installedName; return $false }
    }
    if (('rust-std-' + $pin.kernel_target) -notin $components) { $script:RustReadinessReason = 'missing bare target: ' + $pin.kernel_target; return $false }
    foreach ($name in @('rust-lld', 'llvm-readobj', 'llvm-objdump', 'llvm-objcopy', 'llvm-nm', 'llvm-size')) {
        if (-not (Test-Path -LiteralPath (Join-Path $llvmBin ($name + $suffix)) -PathType Leaf)) { $script:RustReadinessReason = 'missing LLVM tool: ' + $name; return $false }
    }
    return $true
}

function Get-RustDownload([string]$Url, [string]$Destination, [string]$ExpectedHash) {
    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        if ((Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash -ieq $ExpectedHash) { return }
    }
    $curl = Get-Command $(if ($IsWindows) { 'curl.exe' } else { 'curl' }) -CommandType Application -ErrorAction Stop | Select-Object -First 1
    Write-Host ('Lade ' + [IO.Path]::GetFileName($Destination) + ' ...')
    Invoke-RustNative $curl.Source @('--fail', '--location', '--proto', '=https', '--tlsv1.2', '--retry', '3',
        '--connect-timeout', '30', '--max-time', '300', '--silent', '--show-error', '--output', $Destination, $Url)
    if ((Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash -ine $ExpectedHash) {
        throw ('Rust-Pruefsumme stimmt nicht: ' + [IO.Path]::GetFileName($Destination))
    }
}

function Install-Rust {
    if (!(Test-RustProfileInputs)) { throw $script:RustReadinessReason }
    if (Test-RustReady) { Write-Host ('[OK] Rust ' + $pin.rust_version + ', Komponenten und Kerneltarget sind bereits installiert.'); return }
    [void](New-Item -ItemType Directory -Path $cacheRoot -Force)
    $manifest = Join-Path $cacheRoot ('channel-rust-' + $pin.rust_version + '.toml')
    Get-RustDownload ('https://static.rust-lang.org/dist/channel-rust-' + $pin.rust_version + '.toml') $manifest $pin.manifest_sha256
    $bootstrap = Join-Path $cacheRoot ('rustup-init-' + $pin.rustup_version + '-' + $hostTriple + $suffix)
    Get-RustDownload ('https://static.rust-lang.org/rustup/archive/' + $pin.rustup_version + '/' + $hostTriple + '/rustup-init' + $suffix) `
        $bootstrap $pin.hosts[$hostName].rustup_sha256
    if ($IsLinux) { Invoke-RustNative (Get-Command 'chmod' -ErrorAction Stop).Source @('755', $bootstrap) }
    Invoke-RustNative $bootstrap @('-y', '--no-modify-path', '--profile', 'minimal', '--default-host', $hostTriple, '--default-toolchain', 'none')
    Invoke-RustNative $rustupExe @('set', 'auto-self-update', 'disable')
    $installArgs = @('toolchain', 'install', $toolchainName, '--profile', 'minimal', '--target', $pin.kernel_target)
    foreach ($component in $wantedComponents) { $installArgs += @('--component', $component) }
    Invoke-RustNative $rustupExe $installArgs
    Invoke-RustNative $rustupExe @('default', $toolchainName)
    if ($IsLinux -and $null -ne $toolsetProfile) {
        Invoke-RustNative (Get-Command chmod -CommandType Application | Select-Object -First 1).Source @('755', (Get-RustProfilePath $toolsetProfile.hosts.Linux.packager))
    }
    if (-not (Test-RustReady)) { throw 'Rust-Installation ist nicht vollstaendig oder hat eine unerwartete Version.' }
    [ordered]@{
        format = 1; host = $hostTriple; rust_version = $pin.rust_version; rustup_version = $pin.rustup_version
        cargo_version = $pin.cargo_version; profile = $rustProfile
        kernel_target = $pin.kernel_target; components = $wantedComponents; manifest_sha256 = $pin.manifest_sha256
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $rustRoot 'installation.json') -Encoding utf8NoBOM
    Write-Host ('[OK] Rust ' + $pin.rust_version + ' installiert: ' + $rustRoot)
}

try {
    $env:RUSTUP_HOME = $rustupHome
    $env:CARGO_HOME = $cargoHome
    $env:RUSTUP_TOOLCHAIN = $toolchainName
    $env:RUSTUP_AUTO_INSTALL = '0'
    $env:RUSTUP_DIST_SERVER = 'https://static.rust-lang.org'
    $env:RUSTUP_UPDATE_ROOT = 'https://static.rust-lang.org/rustup'
    $env:RUSTUP_INIT_SKIP_PATH_CHECK = 'yes'
    $env:PATH = $cargoBin + [IO.Path]::PathSeparator + $previousEnvironment['PATH']
    if ($tool -eq 'setup') {
        if ($toolArgs.Count -ne 0) { throw 'Rust setup akzeptiert keine weiteren Argumente.' }
        Install-Rust
    }
    elseif ($tool -in @('describe', 'check')) {
        $ready = Test-RustReady
        [ordered]@{
            rust_version = $pin.rust_version; cargo_version = $pin.cargo_version; rustup_version = $pin.rustup_version; host = $hostTriple
            kernel_target = $pin.kernel_target; root = $rustRoot; cargo_home = $cargoHome; rustup_home = $rustupHome
            toolchain = $toolchainRoot; llvm_bin = $llvmBin; installed = $ready; reason = $script:RustReadinessReason
            profile = $rustProfile; cache_root = $cacheRoot; required_components = @($requiredComponents)
            optional_components = @(if ($rustProfile -eq 'sdk') { $pin.profiles.sdk.optional_components })
            wanted_components = @($wantedComponents); rust_src_required = ('rust-src' -in $requiredComponents)
            pin_sha256 = $profileData.hashes.Tools
            complete_toolset = ($ready -and $null -ne $toolsetProfile)
            toolset_metadata_present = ($null -ne $toolsetProfile)
            toolset_manifest_sha256 = $(if ($null -ne $toolsetProfile) { (Get-FileHash $profilePath -Algorithm SHA256).Hash.ToLowerInvariant() } else { $null })
            sdk = $(if ($null -ne $toolsetProfile) { $toolsetProfile.sdk } else { $null })
            contract = $(if ($null -ne $toolsetProfile) { $toolsetProfile.contract } else { $null })
            packager = $(if ($null -ne $toolsetProfile) { Get-RustProfilePath $toolsetProfile.hosts[$hostName].packager } else { $null })
            linker = Join-Path $llvmBin ('rust-lld' + $suffix)
            linker_sha256 = $(if ($ready) { (Get-FileHash (Join-Path $llvmBin ('rust-lld' + $suffix)) -Algorithm SHA256).Hash.ToLowerInvariant() } else { $null })
            installed_components = @(if ($ready) { Get-RustOutput $rustupExe @('component','list','--toolchain',$toolchainName,'--installed') })
        } | ConvertTo-Json -Depth 8
        if ($tool -eq 'check' -and !$ready) { $exitCode = 1 }
    }
    else {
        if ($tool -in @('rustc', 'cargo', 'rustup', 'rustfmt', 'cargo-clippy', 'clippy-driver')) {
            $executable = Join-Path $cargoBin ($tool + $suffix)
        }
        elseif ($tool -in @('rust-lld', 'llvm-readobj', 'llvm-objdump', 'llvm-objcopy', 'llvm-nm', 'llvm-size')) {
            $executable = Join-Path $llvmBin ($tool + $suffix)
        }
        else { throw ('Unbekanntes Rust-Werkzeug: ' + $tool) }
        if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw 'Rust-Werkzeug fehlt. Zuerst Rust.sh setup beziehungsweise Rust.bat setup ausfuehren.' }
        & $executable @toolArgs
        $exitCode = $LASTEXITCODE
    }
}
catch {
    Write-Error $_ -ErrorAction Continue
    $exitCode = 1
}
finally {
    foreach ($name in $environmentNames) {
        if ($null -eq $previousEnvironment[$name]) {
            Remove-Item -LiteralPath ('Env:' + $name) -ErrorAction SilentlyContinue
        }
        else {
            Set-Item -LiteralPath ('Env:' + $name) -Value $previousEnvironment[$name]
        }
    }
}
exit $exitCode
