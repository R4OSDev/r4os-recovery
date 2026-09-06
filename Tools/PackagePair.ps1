# Producer check of the Recovery-owned ELF section, independent of filenames.
function Get-RecoveryElfSection([byte[]]$Elf,[string]$Name) {
 if($Elf.Length -lt 64 -or [Convert]::ToHexString($Elf[0..5]) -cne '7F454C460201' -or [BitConverter]::ToUInt16($Elf,18) -ne 62){throw 'Invalid Recovery ELF64/x86_64.'}
 [long]$start=[BitConverter]::ToUInt64($Elf,40);[int]$stride=[BitConverter]::ToUInt16($Elf,58);[int]$count=[BitConverter]::ToUInt16($Elf,60);[int]$strings=[BitConverter]::ToUInt16($Elf,62)
 if($stride -lt 64 -or $count -lt 1 -or $count -gt 4096 -or $strings -ge $count -or $start -gt $Elf.Length -or $count*$stride -gt $Elf.Length-$start){throw 'Invalid Recovery ELF section table.'}
 [long]$names=[BitConverter]::ToUInt64($Elf,[int]($start+$strings*$stride+24));[long]$size=[BitConverter]::ToUInt64($Elf,[int]($start+$strings*$stride+32))
 if($names -gt $Elf.Length -or $size -gt $Elf.Length-$names){throw 'Invalid Recovery ELF names.'}
 $result=$null
 for($i=0;$i -lt $count;$i++){
  [int]$at=$start+$i*$stride;[long]$index=[BitConverter]::ToUInt32($Elf,$at)
  if($index -ge $size){throw 'Invalid Recovery ELF section name.'}
  [int]$end=[Array]::IndexOf($Elf,[byte]0,[int]($names+$index),[int]($size-$index));if($end -lt 0){throw 'Unterminated Recovery ELF name.'}
  if([Text.Encoding]::ASCII.GetString($Elf,[int]($names+$index),[int]($end-$names-$index)) -cne $Name){continue}
  [long]$offset=[BitConverter]::ToUInt64($Elf,$at+24);[long]$length=[BitConverter]::ToUInt64($Elf,$at+32)
  if($null -ne $result -or [BitConverter]::ToUInt32($Elf,$at+4) -ne 1 -or $offset -gt $Elf.Length -or $length -gt $Elf.Length-$offset -or $length -le 0 -or $length -gt 4096){throw 'Invalid Recovery ELF section.'}
  $result=[byte[]]::new([int]$length);[Array]::Copy($Elf,$offset,$result,0,$length)
 }
 if($null -eq $result){throw "Required Recovery section missing: $Name"}
 return ,$result
}
function Test-RecoveryPackagePair([string]$Kernel,[string]$Runtime,[string]$Version,[string]$KernelVersion) {
 $elf=[IO.File]::ReadAllBytes($Kernel);$pair=Get-RecoveryElfSection $elf '.r4os.recovery.pair'
 $meta=Get-RecoveryElfSection $elf '.r4os.kernel.meta'
 $actualKernel=(@([BitConverter]::ToUInt32($meta,16),[BitConverter]::ToUInt32($meta,20),[BitConverter]::ToUInt32($meta,24)) -join '.')
 if($meta.Length -ne 44 -or [Text.Encoding]::ASCII.GetString($meta,0,8) -cne 'R4OSKRN1' -or $actualKernel -cne $KernelVersion){throw 'Recovery kernel metadata differs from version source.'}
 if($pair.Length -ne 112 -or [Text.Encoding]::ASCII.GetString($pair,0,8) -cne 'R4RECOV1' -or
    [BitConverter]::ToUInt64($pair,8) -ne ([IO.FileInfo]$Runtime).Length -or
    [Convert]::ToHexString($pair[16..47]).ToLowerInvariant() -cne (Get-FileHash -LiteralPath $Runtime -Algorithm SHA256).Hash.ToLowerInvariant() -or
    [Text.Encoding]::ASCII.GetString($pair,48,32).TrimEnd([char]0) -cne $Version -or [Text.Encoding]::ASCII.GetString($pair,80,32).TrimEnd([char]0) -cne $KernelVersion){throw 'Recovery ELF and runtime.img do not form the recorded version/hash pair.'}
}
