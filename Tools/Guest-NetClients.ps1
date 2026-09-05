# Host clients for isolated QEMU acceptances; credentials are the Recovery default.
function Client([string]$Program,[string[]]$Arguments,[string]$InputText=''){
    $start=[Diagnostics.ProcessStartInfo]::new($Program);$start.UseShellExecute=$false
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true;$start.RedirectStandardInput=$true
    $start.Environment['SSH_ASKPASS']=$askpass;$start.Environment['SSH_ASKPASS_REQUIRE']='force';$start.Environment['DISPLAY']='recovery-acceptance'
    foreach($argument in $Arguments){$start.ArgumentList.Add($argument)}
    $client=[Diagnostics.Process]::new();$client.StartInfo=$start
    try{
        if(!$client.Start()){throw "Client did not start: $Program"}
        $stdout=$client.StandardOutput.ReadToEndAsync();$stderr=$client.StandardError.ReadToEndAsync()
        $client.StandardInput.Write($InputText);$client.StandardInput.Close()
        if(!$client.WaitForExit(20000)){$client.Kill($true);$client.WaitForExit();throw "Client timed out: $Program"}
        $text=$stdout.GetAwaiter().GetResult();$errorText=$stderr.GetAwaiter().GetResult()
        [IO.File]::AppendAllText($clientLog,"$([IO.Path]::GetFileName($Program)) $($Arguments -join ' ')`n$text$errorText`n",$utf8)
        if($client.ExitCode -ne 0){throw "Client failed ($($client.ExitCode)): $Program $errorText"}
        return $text
    }finally{$client.Dispose()}
}
function Ssh([string]$Command){return Client $ssh (@('-p',"$sshPort")+$sshOptions+@('r4os@127.0.0.1',$Command))}
function Sftp([string[]]$Commands){return Client $sftp (@('-P',"$sshPort",'-o','BatchMode=no','-b','-')+$sshOptions+@('r4os@127.0.0.1')) (($Commands -join "`n")+"`n")}
function Host-Path([string]$Path){return '"'+$Path.Replace('\','/').Replace('"','\"')+'"'}
function Require-Hash([string]$Actual,[string]$Expected){if((Get-RecoveryHash $Actual) -cne (Get-RecoveryHash $Expected)){throw "File hash mismatch: $Actual"}}
function Ftp-Reply($Ftp,[string]$Expected){
    $line=$Ftp.Reader.ReadLine()
    if($null -eq $line -or $line -cnotmatch "^$Expected "){throw "Unexpected FTP reply: $line (expected $Expected)"}
    return $line
}
function Ftp-Command($Ftp,[string]$Command,[string]$Expected){$Ftp.Writer.WriteLine($Command);return Ftp-Reply $Ftp $Expected}
function Open-Ftp {
    $client=[Net.Sockets.TcpClient]::new();$client.Connect('127.0.0.1',$ftpPort)
    $stream=$client.GetStream();$stream.ReadTimeout=10000;$stream.WriteTimeout=10000
    $ftp=[pscustomobject]@{Client=$client;Reader=[IO.StreamReader]::new($stream,$utf8,$false,4096,$true);Writer=[IO.StreamWriter]::new($stream,$utf8,4096,$true)}
    $ftp.Writer.NewLine="`r`n";$ftp.Writer.AutoFlush=$true
    try{
        $null=Ftp-Reply $ftp '220';$null=Ftp-Command $ftp 'USER r4os' '331';$null=Ftp-Command $ftp 'PASS rosebud' '230'
        $null=Ftp-Command $ftp 'TYPE I' '200';return $ftp
    }catch{$ftp.Writer.Dispose();$ftp.Reader.Dispose();$ftp.Client.Dispose();throw}
}
function Ftp-Transfer($Ftp,[bool]$Active,[bool]$Upload,[string]$Remote,[string]$Local){
    $listener=$null;$data=$null;$file=$null
    try{
        if($Active){
            $listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$listener.Start();$port=$listener.LocalEndpoint.Port
            # QEMU user networking reaches this host listener via its gateway.
            $null=Ftp-Command $Ftp ("PORT 10,0,2,2,{0},{1}" -f [int][Math]::Floor($port/256),($port%256)) '200'
        }else{
            $reply=Ftp-Command $Ftp 'PASV' '227'
            if($reply -notmatch '\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)'){throw 'Invalid FTP PASV response.'}
            $port=[int]$Matches[5]*256+[int]$Matches[6]
            $data=[Net.Sockets.TcpClient]::new();$data.Connect('127.0.0.1',$port)
        }
        $null=Ftp-Command $Ftp ((@('RETR','STOR')[[int]$Upload])+' '+$Remote) '150'
        if($Active){$accept=$listener.AcceptTcpClientAsync();if(!$accept.Wait(10000)){throw 'Active FTP connection timed out.'};$data=$accept.GetAwaiter().GetResult()}
        $stream=$data.GetStream();$stream.ReadTimeout=10000;$stream.WriteTimeout=10000
        if($Upload){$file=[IO.File]::OpenRead($Local);$file.CopyTo($stream);$stream.Flush();$data.Client.Shutdown([Net.Sockets.SocketShutdown]::Send)}
        else{$file=[IO.File]::Create($Local);$stream.CopyTo($file);$file.Flush($true)}
        $file.Dispose();$file=$null;$data.Dispose();$data=$null
        $null=Ftp-Reply $Ftp '226'
    }finally{if($null -ne $file){$file.Dispose()};if($null -ne $data){$data.Dispose()};if($null -ne $listener){$listener.Stop()}}
}
