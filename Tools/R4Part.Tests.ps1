# One grouped product acceptance on a newly created, disposable 128-MB NVMe.
# Interactive commands use the real R4PART.R4X through the regular SSH shell.
Add-Type -Path (Join-Path $PSScriptRoot 'Guest-Console.cs')
. (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1')
$script:partScriptSequence=0
function New-R4PartFixture([string]$Path,[switch]$DamageBackup){
    # Only this disposable image is passed by the two guest runners.
    $file=[IO.File]::Create($Path)
    try{
        $file.SetLength(128MB);[uint64]$sectors=128MB/512
        $entries=[byte[]]::new(16384)
        ([Guid]::Parse('ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')).ToByteArray().CopyTo($entries,0)
        ([Guid]::Parse('07613000-2222-4333-8444-000000000001')).ToByteArray().CopyTo($entries,16)
        U64 $entries 32 2048;U64 $entries 40 6143
        [Text.Encoding]::Unicode.GetBytes('GPT WITNESS').CopyTo($entries,56)
        $guid='07613000-2222-4333-8444-000000000000'
        $primary=Header $entries $guid 1 ($sectors-1) 2 $sectors
        $backup=Header $entries $guid ($sectors-1) 1 ($sectors-33) $sectors
        $mbr=[byte[]]::new(512);$mbr[42]=0x76;$mbr[450]=238;$mbr[510]=85;$mbr[511]=170
        U32 $mbr 454 1;U32 $mbr 458 ([uint32]($sectors-1))
        Write-At $file 0 $mbr;Write-At $file 1024 $entries
        if($DamageBackup){$entries[56]=$entries[56] -bxor 1}else{$primary[16]=$primary[16] -bxor 1}
        Write-At $file 512 $primary;Write-At $file (($sectors-33)*512) $entries
        Write-At $file (($sectors-1)*512) $backup;$file.Flush($true)
    }finally{$file.Dispose()}
}
function Part-Script([string[]]$Lines,[string[]]$Expected=@(),[bool]$Fail=$false,[string[]]$Forbidden=@()){
    $script:partScriptSequence++;$name='RP{0:d3}.R4S' -f $script:partScriptSequence
    $local=Join-Path $output $name
    [IO.File]::WriteAllText($local,(($Lines -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))
    $null=Sftp @("put $(Host-Path $local) /C/TEMP/$name")
    $text=Ssh ("R4PART /S `"C:\TEMP\$name`"") -ExpectedExitCode ([int]$Fail)
    foreach($pattern in $Expected){if($text -notmatch $pattern){throw "Missing script output $pattern : $text"}}
    foreach($pattern in $Forbidden){if($text -match $pattern){throw "Script continued past error: $text"}}
    $null=Sftp @("rm /C/TEMP/$name")
    return $text
}
function Part-Run([string[]]$Commands,[string[]]$Expected=@(),[int]$Errors=0){
    $console=[RecoveryConsole]::new($ssh,(@('-tt','-p',"$sshPort")+$sshOptions+@('r4os@127.0.0.1','R4PART')),$askpass)
    try{
        $null=$console.Wait('R4PART> ',0,10000)
        $console.Send((($Commands+@('EXIT') -join "`n")+"`n"))
        if($console.Finish(20000) -ne 0){throw 'R4PART console returned failure.'}
        $text=$console.Output
    }catch{
        $null=Ssh 'SERVMAN STATUS SSHD'
        $null=Ssh 'R4DIAG TASKS'
        throw
    }finally{
        [IO.File]::AppendAllText($clientLog,"R4PART console`n$($console.Output)`n",$utf8)
        $console.Dispose()
    }
    if([regex]::Matches($text,'R4PART: ERROR ').Count -ne $Errors){throw "Unexpected R4PART error count: $text"}
    foreach($pattern in $Expected){if($text -notmatch $pattern){throw "Missing R4PART output $pattern : $text"}}
    return $text
}
function Part-File([string]$Letter){
    $null=Sftp @("put $(Host-Path $replacement) /$Letter/WITNESS.BIN","get /$Letter/WITNESS.BIN $(Host-Path $received)")
    Require-Hash $received $replacement
}
function Part-Read([string]$Letter){
    $null=Sftp @("get /$Letter/WITNESS.BIN $(Host-Path $received)");Require-Hash $received $replacement
}
function Test-R4Part([bool]$Recovery=$true) {
    $listing=Ssh 'R4PART LIST DISK'
    $found=[regex]::Matches($listing,'(?m)^\s*(\d+)\s+128\s+(?:\d+|\?)\s+GPT\s+[^\r\n]+\[NVMe\]')
    if($found.Count -ne 1){throw "No unique 128-MB scratch NVMe: $listing"}
    $disk=[int]$found[0].Groups[1].Value
    $select="SELECT DISK $disk";$yes="YES DISK $disk";$p1="$yes PARTITION 1";$p2="$yes PARTITION 2"
    # The damaged primary header is deliberately not an accepted inventory ID.
    # Selection is the unique 128-MB GPT NVMe fixture; require its real GUID
    # after repair has made both table copies authoritative again.
    $null=Part-Run @($select,'DETAIL DISK','CHECK GPT') @('GPT status: (primary|backup)_damaged','ERROR GptRepairRequired') 1
    $null=Part-Script @('REM explicit repair from one intact counterpart',$select,'REPAIR GPT',$yes,'CHECK GPT','DETAIL DISK','EXIT') @('GPT repair verified','GPT status: healthy','GUID: 07613000-2222-4333-8444-000000000000')
    $null=Part-Script @($select,'CLEAN') @('ERROR MissingConfirmation','Script stopped at line 2') $true
    $null=Part-Script @($select,'CLEAN','YES DISK 999','CHECK GPT') @('ERROR Cancelled') $true @('GPT status:')
    $null=Part-Script @($select,'SELECT DISK 999','CLEAN',$yes) @('Script stopped at line 2','R4PART: ERROR') $true @('Existing data')
    $null=Part-Script @($select,'UNKNOWN','CLEAN',$yes) @('ERROR UnknownCommand') $true @('Existing data')
    $null=Part-Script @($select,'CHECK GPT','REPAIR GPT','EXIT','CLEAN',$yes) @('GPT status: healthy') $false @('Existing data')
    $null=Part-Run @($select,'CHECK GPT','CLEAN',$yes)
    $null=Part-Run @($select,'CONVERT MBR ID=07610010','NO','LIST PARTITION') @('ERROR Cancelled') 1
    $null=Part-Run @($select,'CONVERT MBR ID=07610010',$yes,'CREATE PARTITION PRIMARY SIZE=16 OFFSET=1024',$yes,
        'ACTIVE',$p1,'DETAIL PARTITION','INACTIVE',$p1,'SET ID=0B',$p1,'UNIQUEID DISK','CONVERT GPT','DELETE PARTITION',$p1,
        'CONVERT GPT ID=07610010-2222-4333-8444-000000000000',$yes,
        'CREATE PARTITION PRIMARY SIZE=64 OFFSET=1024 NAME="Scratch FAT"',$yes,
        'CREATE PARTITION PRIMARY SIZE=32 OFFSET=66560 NAME="Scratch NTFS"',$yes,
        'CREATE PARTITION PRIMARY SIZE=8 OFFSET=1024','LIST PARTITION','DETAIL DISK','RESCAN') @('Disk ID: 07610010','ERROR NotEmpty','ERROR NoSpace','Scratch FAT','Scratch NTFS','GUID: 07610010-2222-4333-8444-000000000000') 2
    $null=Part-Run @($select,'SELECT PARTITION 1','FORMAT FS=FAT32 QUICK LABEL="PART FAT"',$p1,'ASSIGN LETTER=X',
        'SELECT PARTITION 2','FORMAT FS=NTFS FULL LABEL="PART NTFS"',$p2,'ASSIGN LETTER=Y','LIST VOLUME') @('FAT32','NTFS','Assigned X:','Assigned Y:')
    Part-File 'X';Part-File 'Y'
    # NTFS growth preserves IDs/start and the unrelated FAT volume. No-space,
    # unsupported FS and a live SFTP handle must all reject before mutation.
    $null=Part-Run @($select,'SELECT PARTITION 1','EXTEND SIZE=1',
        'CREATE PARTITION PRIMARY SIZE=4 OFFSET=99328',$yes,'SELECT PARTITION 2','EXTEND SIZE=16',
        'SELECT PARTITION 3','DELETE PARTITION',"$yes PARTITION 3") @('ERROR UnsupportedNtfs','ERROR NoSpace') 2
    $held=Storage-Sftp
    try{
        if($held.Open('/Y/WITNESS.BIN',$false,$false) -ne 0){throw 'Could not hold NTFS file.'}
        $null=Part-Run @($select,'SELECT PARTITION 2','EXTEND SIZE=16',$p2,'DETAIL PARTITION') @('ERROR Storage \(-3: in use','sectors 65536') 1
        if($held.CloseHandle() -ne 0){throw 'Held NTFS close failed.'}
    }finally{$held.Dispose()}
    $null=Part-Run @($select,'SELECT PARTITION 2','EXTEND SIZE=16',$p2,'DETAIL PARTITION','LIST VOLUME') @('32 MB -> 48 MB','first LBA 133120, sectors 98304','Assigned Y:')
    Part-Read 'X';Part-Read 'Y'
    # The payload is larger than the entire old filesystem, so successful
    # write+read proves allocation in the newly added area, not only old space.
    $growth=Join-Path $output 'growth.bin';$growthRead=Join-Path $output 'growth-read.bin'
    $block=[byte[]]::new(65536);for($i=0;$i -lt $block.Length;$i++){$block[$i]=[byte](($i*17+39)%256)}
    $file=[IO.File]::Create($growth);try{for($i=0;$i -lt 640;$i++){$file.Write($block)}}finally{$file.Dispose()}
    $parallel=$null;$parallelWrite=$null
    try{
        if(!$Recovery){
            $parallel=Storage-Sftp
            $parallelWrite=$parallel.WriteFileAsync('/C/TEMP/NTFSPAR.BIN',$block[0..32767],512)
        }
        $null=Sftp @("put $(Host-Path $growth) /Y/GROWTH.BIN","get /Y/GROWTH.BIN $(Host-Path $growthRead)") -TimeoutMilliseconds 60000
        if($null -ne $parallelWrite){
            if(!$parallelWrite.Wait(60000)){throw 'Concurrent NTFS write timed out.'}
            $parallelWrite.GetAwaiter().GetResult()
            $parallelExpected=Join-Path $output 'ntfs-parallel.bin';$parallelRead=Join-Path $output 'ntfs-parallel-read.bin'
            $file=[IO.File]::Create($parallelExpected);try{for($i=0;$i -lt 256;$i++){$file.Write($block)}}finally{$file.Dispose()}
            $null=Sftp @("get /C/TEMP/NTFSPAR.BIN $(Host-Path $parallelRead)",'rm /C/TEMP/NTFSPAR.BIN')
            Require-Hash $parallelRead $parallelExpected
            Write-Host 'Concurrent NTFS volumes: 16-MB C: write and 40-MB Y: transfer, both readback hashes OK.'
        }
    }catch{
        $null=Ssh 'SERVMAN STATUS SSHD'
        $null=Ssh 'SERVMAN DIAG'
        throw
    }finally{if($null -ne $parallel){$parallel.Dispose()}}
    Require-Hash $growthRead $growth
    Part-Read 'Y'
    $query=Part-Run @($select,'SELECT PARTITION 2','SHRINK QUERYMAX','SHRINK DESIRED=32') @('Maximum shrink:','ERROR ShrinkLimit') 1
    if($query -notmatch 'Maximum shrink: (\d+) MB' -or [int]$Matches[1] -ge 32){throw 'Live 40-MB file did not constrain QUERYMAX.'}
    $null=Sftp @('rm /Y/GROWTH.BIN')
    $query=Part-Run @($select,'SELECT PARTITION 2','SHRINK QUERYMAX') @('Maximum shrink: 32 MB; minimum volume: 16 MB')
    $held=Storage-Sftp
    try{
        if($held.Open('/Y/WITNESS.BIN',$false,$false) -ne 0){throw 'Could not hold NTFS shrink witness.'}
        $null=Part-Run @($select,'SELECT PARTITION 2','SHRINK DESIRED=32',$p2,'DETAIL PARTITION') @('ERROR Storage \(-3: in use','sectors 98304') 1
        if($held.CloseHandle() -ne 0){throw 'Held shrink witness close failed.'}
    }finally{$held.Dispose()}
    $null=Part-Run @($select,'SELECT PARTITION 2','SHRINK DESIRED=32',$p2,'DETAIL PARTITION','SHRINK QUERYMAX') @('SHRINK NTFS: 48 MB -> 16 MB','first LBA 133120, sectors 32768','Assigned Y:','Maximum shrink: 0 MB')
    Part-Read 'X';Part-Read 'Y'
    # SFTP intentionally creates only new targets. Exercise post-shrink
    # allocation with a fresh file, then native COPY overwrite/truncation.
    $null=Sftp @("put $(Host-Path $payload) /Y/AFTERSHRINK.BIN","get /Y/AFTERSHRINK.BIN $(Host-Path $received)")
    Require-Hash $received $payload
    $copy=Ssh 'COPY Y:\WITNESS.BIN Y:\AFTERSHRINK.BIN'
    if($copy -notmatch '1 file\(s\) copied'){throw 'Native overwrite after shrink failed.'}
    $null=Sftp @("get /Y/AFTERSHRINK.BIN $(Host-Path $received)",'rm /Y/AFTERSHRINK.BIN')
    Require-Hash $received $replacement

    $null=Part-Run @($select,'SELECT PARTITION 1','OFFLINE PARTITION','LIST VOLUME') @('Offline: affected volumes flushed and unmounted')
    $text=Ssh 'R4PART LIST VOLUME';if($text -match '(?m)^\s*23\s+X\s'){throw 'OFFLINE did not survive EXIT.'}
    Part-Read 'Y'
    $null=Part-Run @($select,'SELECT PARTITION 1','ONLINE PARTITION LETTER=X','REMOVE','ASSIGN LETTER=W','SELECT VOLUME W','DETAIL VOLUME','REMOVE','ASSIGN LETTER=X') @('Assigned W:','Assigned X:')
    Part-Read 'X'
    $null=Part-Run @($select,'SELECT PARTITION 1','ATTRIBUTES GPT SET=0x1000000000000000',$p1,'ATTRIBUTES GPT','ATTRIBUTES GPT CLEAR=0x1000000000000000',$p1,
        'UNIQUEID PARTITION ID=07610011-2222-4333-8444-000000000000',$p1,'LIST VOLUME') @('GPT attributes: 0x1000000000000000','Identifiers/types changed')
    $text=Ssh 'R4PART LIST VOLUME';if($text -match '(?m)^\s*23\s+X\s'){throw 'Changed partition GUID retained the old letter.'}
    Part-Read 'Y'
    $null=Part-Run @($select,'SELECT PARTITION 1','ASSIGN LETTER=X','DELETE PARTITION',$p1,'LIST PARTITION')
    Part-Read 'Y'
    $null=Part-Run @($select,'UNIQUEID DISK ID=07610012-2222-4333-8444-000000000000',$yes,'LIST VOLUME')
    $text=Ssh 'R4PART LIST VOLUME';if($text -match '(?m)^\s*24\s+Y\s'){throw 'Changed disk GUID retained the old letter.'}
    $null=Part-Run @($select,'SELECT PARTITION 2','ASSIGN LETTER=Y','OFFLINE DISK','ONLINE DISK','LIST VOLUME') @('Partition 2 online as')
    $null=Part-Run @($select,'SELECT PARTITION 2','DELETE PARTITION',$p2,'CONVERT MBR ID=07610013',$yes,'CONVERT GPT ID=07610014-2222-4333-8444-000000000000',$yes,'CLEAN ALL',$yes,'LIST PARTITION')
    # Reserved live RAM and Recovery aliases are never assignable/removable.
    if($Recovery){$null=Part-Run @('SELECT VOLUME R','REMOVE') @('ERROR Protected') 1}
    $safe=Join-Path $output 'PARTSAFE.R4S'
    [IO.File]::WriteAllText($safe,"REM caller return witness`nLIST DISK`nLIST VOLUME`nHELP`nEXIT`n",[Text.UTF8Encoding]::new($true))
    $null=Sftp @("put $(Host-Path $safe) /C/TEMP/PARTSAFE.R4S")
    Write-Host 'R4PART: GPT repair, script stop/exit codes, real formatting/resize, identity and mount operations OK.'
}
function Part-Type([string]$Command){
    $keys=@(foreach($ch in $Command.ToLowerInvariant().ToCharArray()){if($ch -eq ' '){'spc'}elseif($ch -match '[a-z0-9]'){[string]$ch}elseif($ch -eq ':'){'shift+semicolon'}elseif($ch -eq '\'){'backslash'}elseif($ch -eq '/'){'slash'}elseif($ch -eq '.'){'dot'}else{throw "Unsupported R4PART UI test key: $ch"}})
    Send-Keys $session ($keys+@('ret'))
}
function Test-R4PartMenu {
    Send-Keys $session @('down','down','down','ret')
    Wait-Marker 'R4PART - R4OS partition tool'
    Part-Type 'HELP';Wait-Marker 'R4PART uses the current Terminal/SSH console'
    Part-Type 'SELECT DISK 0';Part-Type 'CHECK GPT';Wait-Marker 'GPT status: healthy'
    Part-Type 'EXIT';Start-Sleep -Milliseconds 300
    $menu=Capture 'r4part-return';if([RecoveryFrame]::new($menu).RedRow() -le 0){throw 'R4PART did not return to its menu.'}
    Send-Keys $session @('down','ret');Start-Sleep -Milliseconds 300
    Part-Type 'R4PART /S C:\TEMP\PARTSAFE.R4S';Start-Sleep -Milliseconds 500
    Part-Type 'ECHO TERMINALRETURNED';Wait-Marker 'TERMINALRETURNED'
    Part-Type 'EXIT';Start-Sleep -Milliseconds 300
    # Restore main selection 0 so the shared network runner restarts normally.
    Send-Keys $session @('down','down')
}
