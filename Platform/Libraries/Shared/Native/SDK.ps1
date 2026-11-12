# Locations only. SDK Profiles are the sole build/tool policy.
$nativeLibraryRoot=[IO.Path]::GetFullPath('../..',$PSScriptRoot)
$nativeSettings=@{}
foreach($nativeLine in [IO.File]::ReadAllLines((Join-Path $nativeLibraryRoot 'Settings.R4S'))){if($nativeLine -match '^([A-Z_]+)=(.+)$'){$nativeSettings[$Matches[1]]=$Matches[2]}}
$nativeRepositories=[IO.Path]::GetFullPath($nativeSettings.REPOSITORIES_ROOT.Replace('\','/'),$nativeLibraryRoot)
$nativeSdkRoot=[IO.Path]::GetFullPath($nativeSettings.SDK_ROOT.Replace('\','/'),$nativeRepositories)
. (Join-Path $nativeSdkRoot 'Tools/NativeProfiles.ps1')
$script:R4SdkNative=Get-R4SdkNativeContext $nativeLibraryRoot
Test-R4SdkNativeProjections $script:R4SdkNative
