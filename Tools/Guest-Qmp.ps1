# Shared bounded hardware keyboard/QMP control for guest acceptances.
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

