# Shared bounded hardware keyboard/QMP control for guest acceptances.
function Get-RecoveryFirmwareArgs {
    # SeaBIOS 1.17 otherwise moves the NVMe BAR above 4 GB with large RAM,
    # then cannot boot it. Keep this firmware's PCI allocations below 4 GB.
    # OVMF ignores this SeaBIOS-specific fw_cfg key. Same policy on both hosts.
    # Upstream: https://www.mail-archive.com/seabios%40seabios.org/msg13153.html
    return @('-fw_cfg','name=opt/org.seabios/pci64,string=0')
}
function Qmp([object]$Session,[string]$Command,[hashtable]$Arguments=@{}){
    $id=[Guid]::NewGuid().ToString('N')
    $Session.Writer.WriteLine((@{execute=$Command;arguments=$Arguments;id=$id}|ConvertTo-Json -Compress -Depth 10))
    do{
        $line=$Session.Reader.ReadLine()
        if($null -eq $line){throw 'QMP disconnected.'}
        $message=$line|ConvertFrom-Json -AsHashtable
    }while(!$message.ContainsKey('id') -or $message.id -cne $id)
    if($message.ContainsKey('error')){throw "QMP $Command failed: $($message.error|ConvertTo-Json -Compress)"}
    return $message['return']
}
function Open-Qmp([int]$Port){
    $client=[Net.Sockets.TcpClient]::new()
    try{
        $client.Connect('127.0.0.1',$Port)
        $stream=$client.GetStream();$stream.ReadTimeout=5000;$stream.WriteTimeout=5000
        $session=[pscustomobject]@{Client=$client;Reader=[IO.StreamReader]::new($stream,$utf8,$false,4096,$true);Writer=[IO.StreamWriter]::new($stream,$utf8,4096,$true)}
        $session.Writer.AutoFlush=$true
        $greeting=$session.Reader.ReadLine()|ConvertFrom-Json -AsHashtable
        if(!$greeting.ContainsKey('QMP')){throw 'Missing QMP greeting.'}
        $null=Qmp $session 'qmp_capabilities'
        return $session
    }catch{$client.Dispose();throw}
}
function Send-Keys([object]$Session,[string[]]$Sequence){
    foreach($chord in $Sequence){
        $keys=@($chord.Split('+')|ForEach-Object {@{type='qcode';data=$_}})
        $null=Qmp $Session 'send-key' @{keys=$keys;'hold-time'=35}
        Start-Sleep -Milliseconds 70
    }
}

function Get-QmpFreePort {
    $listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0)
    $listener.Start()
    try {return $listener.LocalEndpoint.Port} finally {$listener.Stop()}
}

# QEMU's own GDB remote memory packets inject one real hardware halt. No
# guest completion/status is forged and no external host debugger is needed.
function Invoke-QmpMemoryPacket($Stream,[string]$Command){
    $sum=0;foreach($byte in [Text.Encoding]::ASCII.GetBytes($Command)){$sum=($sum+$byte)-band 255}
    $packet=[Text.Encoding]::ASCII.GetBytes(('$'+$Command+'#'+$sum.ToString('x2')))
    $Stream.Write($packet,0,$packet.Length)
    do{$byte=$Stream.ReadByte();if($byte -lt 0){throw 'QEMU debugger disconnected.'}}while($byte -ne 36)
    $reply=[Collections.Generic.List[byte]]::new();$actual=0
    while(($byte=$Stream.ReadByte()) -ne 35){if($byte -lt 0){throw 'Truncated debugger packet.'};$reply.Add([byte]$byte);$actual=($actual+$byte)-band 255}
    $hex=[char]$Stream.ReadByte()+[string][char]$Stream.ReadByte()
    if([Convert]::ToInt32($hex,16) -ne $actual){throw 'Invalid debugger packet checksum.'}
    $Stream.WriteByte(43)
    return [Text.Encoding]::ASCII.GetString($reply.ToArray())
}
function Set-QmpXhciFault($Session,[switch]$DisableInterrupts,[string]$ControllerId='usb2'){
    $pci=@(Qmp $Session 'query-pci')
    $device=@($pci|ForEach-Object {$_.devices}|Where-Object qdev_id -ceq $ControllerId)
    if($device.Count -ne 1){throw "Fault target is not the exact $ControllerId controller."}
    $bar=@($device[0].regions|Where-Object { $_.bar -eq 0 -and $_.type -eq 'memory' })
    if($bar.Count -ne 1 -or [long]$bar[0].address -le 0){throw 'Fault target MMIO is unavailable.'}
    $port=if($Session.PSObject.Properties['GdbPort']){$Session.GdbPort}else{Get-QmpFreePort}
    $null=Qmp $Session 'stop'
    $tcp=$null
    try {
        if(!$Session.PSObject.Properties['GdbPort']){
            $reply=Qmp $Session 'human-monitor-command' @{'command-line'="gdbserver tcp:127.0.0.1:$port"}
            if($reply -match 'error|failed|already'){throw "QEMU debugger listener failed: $reply"}
            $Session|Add-Member -NotePropertyName GdbPort -NotePropertyValue $port
        }
        $tcp=[Net.Sockets.TcpClient]::new();$tcp.Connect('127.0.0.1',$port)
        $stream=$tcp.GetStream();$stream.ReadTimeout=5000;$stream.WriteTimeout=5000
        if((Invoke-QmpMemoryPacket $stream 'Qqemu.PhyMemMode:1') -cne 'OK'){throw 'Physical debugger mode unavailable.'}
        $base=[uint64]$bar[0].address
        $cap=Invoke-QmpMemoryPacket $stream ('m'+$base.ToString('x')+',4')
        if($cap -cnotmatch '^[0-9a-fA-F]{8}$'){throw 'Invalid xHCI capability read.'}
        $op=$base+[Convert]::ToUInt32($cap.Substring(0,2),16)
        $raw=Invoke-QmpMemoryPacket $stream ('m'+$op.ToString('x')+',4')
        $command=[BitConverter]::ToUInt32([Convert]::FromHexString($raw),0)
        if(($command-band 1) -eq 0){throw 'Fault target was not running.'}
        $mask=if($DisableInterrupts){[uint32]4294967291}else{[uint32]4294967294}
        if($DisableInterrupts -and ($command-band 4) -eq 0){throw 'IRQ target was not interrupt enabled.'}
        $changed=[uint32]($command-band $mask)
        $halt=[Convert]::ToHexString([BitConverter]::GetBytes($changed)).ToLowerInvariant()
        if((Invoke-QmpMemoryPacket $stream ('M'+$op.ToString('x')+',4:'+$halt)) -cne 'OK'){throw 'Hardware halt write failed.'}
        $readback=Invoke-QmpMemoryPacket $stream ('m'+$op.ToString('x')+',4')
        $observed=[BitConverter]::ToUInt32([Convert]::FromHexString($readback),0)
        if($observed -ne $changed){throw 'Controller command readback differs from the requested hardware change.'}
        $raw=Invoke-QmpMemoryPacket $stream ('m'+($op+4).ToString('x')+',4')
        $status=[BitConverter]::ToUInt32([Convert]::FromHexString($raw),0)
        if(!$DisableInterrupts -and ($status-band 1) -eq 0){throw 'QEMU did not acknowledge the real controller halt.'}
        if($DisableInterrupts -and ($status-band 1) -ne 0){throw 'IRQ suppression unexpectedly halted the controller.'}
        $null=Invoke-QmpMemoryPacket $stream 'Qqemu.PhyMemMode:0';$null=Invoke-QmpMemoryPacket $stream 'D'
        return [ordered]@{controller=$ControllerId;bus=$pci[0].bus;slot=$device[0].slot;function=$device[0].function;mmio=$base.ToString('x');commandBefore=$command;commandAfter=$changed;statusAfter=$status;hardwareHalted=(!$DisableInterrupts);interruptsDisabled=[bool]$DisableInterrupts}
    }finally{if($null -ne $tcp){$tcp.Dispose()};$null=Qmp $Session 'cont'}
}
