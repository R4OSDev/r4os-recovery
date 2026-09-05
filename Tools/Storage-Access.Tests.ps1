# Extends the existing real-network acceptance with concurrent storage users.
# All destructive guest commands independently require the technical fixture GUID.
Add-Type -Path (Join-Path $PSScriptRoot 'Guest-SftpHandles.cs')
function Storage-Command([string]$Action){
    $text=Ssh ("C:\R4OS\SOFTWARE\RECOVERY\RECOVERY.R4X /STORAGESMOKE $Action")
    if($text -notmatch '\[STORAGE\] result=OK'){throw "Storage $Action failed: $text"}
    return $text
}
function Storage-Sftp {
    return [RecoverySftpHandles]::new($ssh,(@('-p',"$sshPort")+$sshOptions+@('-s','r4os@127.0.0.1','sftp')),$askpass)
}
function Test-StorageAccess {
    $null=Storage-Command 'BASIC'
    foreach($kind in @('read','write','directory','disconnect')){
        $held=Storage-Sftp
        try{
            $path=if($kind -eq 'write'){'/E/OPEN.TMP'}elseif($kind -eq 'directory'){'/E'}else{'/E/VOLUME.TXT'}
            if($held.Open($path,$kind -eq 'write',$kind -eq 'directory') -ne 0){throw "Could not open SFTP $kind handle."}
            $null=Storage-Command 'BUSY'
            if($kind -ne 'disconnect' -and $held.CloseHandle() -ne 0){throw 'SFTP close failed.'}
        }finally{$held.Dispose()}
        Start-Sleep -Milliseconds 200
        try{$null=Storage-Command $(if($kind -eq 'disconnect'){'WAITFREE'}else{'FREE'})}catch{
            $null=Ssh 'SERVMAN STATUS SSHD'
            $null=Ssh 'IPCONFIG /ALL'
            throw
        }
        if($kind -eq 'write'){$null=Sftp @('rm /E/OPEN.TMP')}
    }
    $ftp=Open-Ftp;$data=$null
    try{
        $reply=Ftp-Command $ftp 'PASV' '227'
        if($reply -notmatch '\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)'){throw 'Invalid PASV.'}
        $data=[Net.Sockets.TcpClient]::new();$data.Connect('127.0.0.1',([int]$Matches[5]*256+[int]$Matches[6]))
        $null=Ftp-Command $ftp 'STOR /E/FTP-HOLD.TMP' '150'
        $null=Storage-Command 'BUSY'
        $data.GetStream().WriteByte(76);$data.Client.Shutdown([Net.Sockets.SocketShutdown]::Send)
        $data.Dispose();$data=$null;$null=Ftp-Reply $ftp '226'
        $null=Storage-Command 'FREE'
        $null=Ftp-Command $ftp 'DELE /E/FTP-HOLD.TMP' '250'
    }finally{if($null -ne $data){$data.Dispose()};$ftp.Writer.Dispose();$ftp.Reader.Dispose();$ftp.Client.Dispose()}

    $start=[Diagnostics.ProcessStartInfo]::new($ssh);$start.UseShellExecute=$false
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true;$start.RedirectStandardInput=$true
    $start.Environment['SSH_ASKPASS']=$askpass;$start.Environment['SSH_ASKPASS_REQUIRE']='force';$start.Environment['DISPLAY']='recovery-storage-acceptance'
    foreach($argument in (@('-p',"$sshPort")+$sshOptions+@('r4os@127.0.0.1','C:\R4OS\SOFTWARE\RECOVERY\RECOVERY.R4X /STORAGESMOKE HOLD'))){$start.ArgumentList.Add($argument)}
    $holder=[Diagnostics.Process]::Start($start)
    try{
        $holder.StandardInput.Close();$holderOut=$holder.StandardOutput.ReadToEndAsync();$holderErr=$holder.StandardError.ReadToEndAsync()
        $ready=$false
        for($i=0;$i -lt 30;$i++){
            Start-Sleep -Milliseconds 100
            $text=Ssh 'DIR C:\TEMP'
            if($text -match 'STORAGE.RDY'){$ready=$true;break}
        }
        if(!$ready){throw 'Exclusive holder did not become ready.'}
        $null=Storage-Command 'FORGED'
        $denied=Storage-Sftp
        try{if($denied.Open('/E/VOLUME.TXT',$false,$false) -eq 0){throw 'SFTP entered exclusively held volume.'}}finally{$denied.Dispose()}
        $ftp=Open-Ftp
        try{$null=Ftp-Command $ftp 'RETR /E/VOLUME.TXT' '450'}finally{$ftp.Writer.Dispose();$ftp.Reader.Dispose();$ftp.Client.Dispose()}
        $null=Sftp @("get /F/VOLUME.TXT $(Host-Path $received)")
        if([IO.File]::ReadAllText($received) -cne '1/DATA'){throw 'Unrelated DATA inaccessible during claim.'}
        $null=Sftp @("put $(Host-Path $replacement) /C/TEMP/STORAGE.REL")
        if(!$holder.WaitForExit(20000)){throw 'Exclusive holder timed out.'}
        $text=$holderOut.GetAwaiter().GetResult();$errors=$holderErr.GetAwaiter().GetResult()
        [IO.File]::AppendAllText($clientLog,"HOLD`n$text$errors`n",$utf8)
        if($holder.ExitCode -ne 0 -or $text -notmatch '\[STORAGE\] HOLD CLOSED' -or $text -notmatch 'result=OK'){throw "Exclusive holder failed: $text $errors"}
    }finally{if(!$holder.HasExited){$holder.Kill($true);$holder.WaitForExit()};$holder.Dispose()}
    $null=Storage-Command 'ABANDON';Start-Sleep -Milliseconds 200
    $null=Storage-Command 'FREE'
    $null=Storage-Command 'CORRUPT'
    $null=Storage-Command 'RESTORE'
    $null=Storage-Command 'FLUSHFAIL'
    Write-Host 'Storage: local/SFTP/FTP uses, exclusive admission, owner retirement, stale references, remount and backend flush faults OK.'
}
