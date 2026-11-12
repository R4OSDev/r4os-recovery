param([Parameter(Mandatory)][string]$ProjectRoot,[string]$SdkRoot='',
      [switch]$IncludeLibraries,[switch]$Write)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if(!$SdkRoot){$SdkRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))}
. (Join-Path $PSScriptRoot 'ProfileData.ps1')
$data=Read-R4SdkProfiles $SdkRoot
$path=Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) 'build.zig.zon'
$original=[IO.File]::ReadAllText($path)
$text=$original
foreach($pair in @(@('contract','r4os_contract'),@('libraries','r4os_libraries'))){
    $source=$data.Components.repositories[$pair[0]]
    if(!$source.Contains('zig_hash') -or !$source.Contains('archive_url')){throw ('SdkZigPinMissing: '+$pair[0])}
    $pattern='(?s)\.'+$pair[1]+'\s*=\s*\.\{[^{}]*\}\s*,?'
    $match=[regex]::Match($text,$pattern)
    $body='.'+$pair[1]+" = .{`n            .url = `""+$source.archive_url+"`",`n            .hash = `""+$source.zig_hash+"`","
    if($pair[0] -ceq 'libraries' -and (!$match.Success -or $match.Value -match '\.lazy\s*=\s*true')){$body+="`n            .lazy = true,"}
    $body+="`n        },"
    if($match.Success){$text=$text.Substring(0,$match.Index)+$body+$text.Substring($match.Index+$match.Length)}
    elseif([regex]::IsMatch($text,('\.'+$pair[1]+'\s*='))){throw ('SdkZigPinSyntaxUnsupported: '+$pair[1])}
    elseif($IncludeLibraries -and $pair[0] -ceq 'libraries'){
        $marker='.dependencies = .{'
        $index=$text.IndexOf($marker,[StringComparison]::Ordinal)
        if($index -lt 0){throw 'SdkZigDependenciesMissing'}
        $index+=$marker.Length
        $text=$text.Insert($index,"`n        "+$body)
    }
}
$text=[regex]::Replace($text,'(\.minimum_zig_version\s*=\s*")[^"]+("\s*,)',('${1}'+$data.Tools.tools.zig.version+'${2}'))
if($Write){[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false))}
elseif($text.Replace("`r`n","`n") -cne $original.Replace("`r`n","`n")){throw 'SdkZigComponentPinsDiffer'}
Write-Host 'SDK-controlled Zig component pins verified.'
