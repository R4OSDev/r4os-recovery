function Get-RecoverySdkContext([string]$Root,[string]$Zig='',[string]$SdkRoot='') {
    if(!$SdkRoot){$SdkRoot=if($env:R4OS_RECOVERY_SDK_ROOT){$env:R4OS_RECOVERY_SDK_ROOT}else{[IO.Path]::GetFullPath('../SDK',$Root)}}
    . (Join-Path $SdkRoot 'Tools/RecoveryProfiles.ps1')
    return Get-R4SdkRecoveryContext -RecoveryRoot $Root -Zig $Zig
}

function Assert-RecoverySdkBootTools($Context,[string]$Qemu,[string]$LimineRoot) {
    . (Join-Path $Context.sdk_root 'Tools/BuildContext.ps1')
    Assert-R4SdkBootTools $Context.sdk_root $Qemu $LimineRoot
}
