# One grouped product acceptance on a newly created, disposable 128-MB NVMe.
# Interactive commands use the real R4PART.R4X through the regular SSH shell.
Add-Type -Path (Join-Path $PSScriptRoot 'Guest-Console.cs')
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
    $found=[regex]::Matches($listing,'(?m)^\s*(\d+)\s+128\s+\d+\s+none/\?\s+[^\r\n]+\[NVMe\]')
    if($found.Count -ne 1){throw "No unique blank 128-MB scratch NVMe: $listing"}
    $disk=[int]$found[0].Groups[1].Value
    $select="SELECT DISK $disk";$yes="YES DISK $disk";$p1="$yes PARTITION 1";$p2="$yes PARTITION 2"
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
    Write-Host 'R4PART: actual MBR/GPT, formatting, identity, mount and confirmation operations OK.'
}
function Part-Type([string]$Command){
    $keys=@(foreach($ch in $Command.ToLowerInvariant().ToCharArray()){if($ch -eq ' '){'spc'}elseif($ch -match '[a-z0-9]'){[string]$ch}else{throw "Unsupported R4PART UI test key: $ch"}})
    Send-Keys $session ($keys+@('ret'))
}
function Test-R4PartMenu {
    Send-Keys $session @('down','down','down','ret')
    Wait-Marker 'R4PART - R4OS partition tool'
    Part-Type 'HELP';Wait-Marker 'R4PART uses the current Terminal/SSH console'
    Part-Type 'EXIT';Start-Sleep -Milliseconds 300
    $menu=Capture 'r4part-return';if([RecoveryFrame]::new($menu).RedRow() -le 0){throw 'R4PART did not return to its menu.'}
    Send-Keys $session @('down','ret');Start-Sleep -Milliseconds 300
    Part-Type 'R4PART';Start-Sleep -Milliseconds 300
    Part-Type 'LIST DISK';Start-Sleep -Milliseconds 300
    Part-Type 'EXIT';Start-Sleep -Milliseconds 300
    Part-Type 'ECHO TERMINALRETURNED';Wait-Marker 'TERMINALRETURNED'
    Part-Type 'EXIT';Start-Sleep -Milliseconds 300
    # Restore main selection 0 so the shared network runner restarts normally.
    Send-Keys $session @('down','down')
}
