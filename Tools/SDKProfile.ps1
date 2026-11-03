function Get-RecoverySdkContext([string]$Root,[string]$Zig='',[string]$SdkRoot='') {
    if(!$SdkRoot){$SdkRoot=if($env:R4OS_RECOVERY_SDK_ROOT){$env:R4OS_RECOVERY_SDK_ROOT}else{[IO.Path]::GetFullPath('../SDK',$Root)}}
    . (Join-Path $SdkRoot 'Tools/RecoveryProfiles.ps1')
    return Get-R4SdkRecoveryContext -RecoveryRoot $Root -Zig $Zig
}

function Assert-RecoverySdkBootTools($Context,[string]$Qemu,[string]$LimineRoot) {
    $hostName=if($IsWindows){'Windows'}else{'Linux'}
    $qemuVersion=[string]$Context.data.Tools.tools.qemu.hosts[$hostName].version
    $reported=(@(& $Qemu --version 2>&1) -join "`n")
    if($LASTEXITCODE -ne 0 -or !$reported.StartsWith(('QEMU emulator version '+$qemuVersion+' '),[StringComparison]::Ordinal)){throw 'RecoverySdkQemuMismatch'}
    $limine=Join-Path $LimineRoot $(if($IsWindows){'limine-tool-windows-x86/limine.exe'}else{'limine'})
    $lines=@(& $limine --version 2>&1)
    $reported=if($lines.Count){[string]$lines[0]}else{''}
    if($LASTEXITCODE -ne 0 -or $reported -cne ('Limine '+$Context.data.Tools.tools.limine.version)){throw 'RecoverySdkLimineMismatch'}
}
