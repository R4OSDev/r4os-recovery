# Technical QEMU fixtures only. Caller supplies verified local tools and paths.
# Never accepts a physical destination; all images live under Artifacts.
function U32([byte[]]$Bytes,[int]$Offset,[uint32]$Value){[BitConverter]::GetBytes($Value).CopyTo($Bytes,$Offset)}
function U64([byte[]]$Bytes,[int]$Offset,[uint64]$Value){[BitConverter]::GetBytes($Value).CopyTo($Bytes,$Offset)}
function Id([int]$Disk,[int]$Part){return ('{0:x8}-2222-4333-8444-{1:x12}' -f $Disk,$Part)}
function Crc([byte[]]$Bytes,[int]$Length){
    # Fixture-only reference implementation; production GPT uses the SDK owner.
    [uint32]$value=[uint32]::MaxValue
    for($i=0;$i -lt $Length;$i++){
        $value=$value -bxor $Bytes[$i]
        for($bit=0;$bit -lt 8;$bit++){
            if($value -band 1){$value=($value -shr 1) -bxor [uint32]3988292384}else{$value=$value -shr 1}
        }
    }
    return $value -bxor [uint32]::MaxValue
}
function Write-At([IO.Stream]$Stream,[long]$Offset,[byte[]]$Bytes){$Stream.Position=$Offset;$Stream.Write($Bytes)}
function Copy-Volume([IO.Stream]$Disk,[long]$Offset,[string]$Path){
    $volumeInput=[IO.File]::OpenRead($Path)
    try{$Disk.Position=$Offset;$volumeInput.CopyTo($Disk,4MB)}finally{$volumeInput.Dispose()}
}
function Header([byte[]]$Entries,[string]$DiskGuid,[uint64]$Current,[uint64]$Backup,[uint64]$ArrayLba){
    $h=[byte[]]::new(512)
    [Text.Encoding]::ASCII.GetBytes('EFI PART').CopyTo($h,0)
    U32 $h 8 65536; U32 $h 12 92
    U64 $h 24 $Current; U64 $h 32 $Backup; U64 $h 40 34; U64 $h 48 (4194304-34)
    ([Guid]::Parse($DiskGuid)).ToByteArray().CopyTo($h,56)
    U64 $h 72 $ArrayLba; U32 $h 80 128; U32 $h 84 128; U32 $h 88 (Crc $Entries $Entries.Length)
    U32 $h 16 (Crc $h 92)
    return ,$h
}
function New-Installation([int]$Number,[bool]$BadManifest=$false){
    $name=if($BadManifest){'damaged'}else{"disk-$Number"}
    $dir=Join-Path $output $name
    [IO.Directory]::CreateDirectory($dir)|Out-Null
    $roles=@('BIOSBOOT','BOOT','SYSTEM','RECOVERY','DATA')
    [uint64[]]$starts=@(2048,4096,266240,2363392,3411968)
    [uint64[]]$lengths=@(2048,262144,2097152,1048576,(4194304-34-3411968+1))
    $types=@('21686148-6449-6e6f-744e-656564454649','c12a7328-f81f-11d2-ba4b-00a0c93ec93b',
        'ebd0a0a2-b9e5-4433-87c0-68b6b72699c7','ebd0a0a2-b9e5-4433-87c0-68b6b72699c7','ebd0a0a2-b9e5-4433-87c0-68b6b72699c7')
    $parts=[ordered]@{}
    $entries=[byte[]]::new(16384)
    for($i=0;$i -lt 5;$i++){
        $id=Id $Number ($i+1)
        $parts[$roles[$i]]=[ordered]@{partitionGuid=$id;typeGuid=$types[$i];firstLba=$starts[$i];sectorCount=$lengths[$i]}
        ([Guid]::Parse($types[$i])).ToByteArray().CopyTo($entries,$i*128)
        ([Guid]::Parse($id)).ToByteArray().CopyTo($entries,$i*128+16)
        U64 $entries ($i*128+32) $starts[$i];U64 $entries ($i*128+40) ($starts[$i]+$lengths[$i]-1)
        [Text.Encoding]::Unicode.GetBytes($roles[$i]).CopyTo($entries,$i*128+56)
    }
    $manifest=[ordered]@{schema=1;installationId=Id $Number 100;diskGuid=$(if($BadManifest){Id 99 0}else{Id $Number 0});
        logicalSectorBytes=512;partitions=$parts;bootFiles=@('boot/kernel.elf');releaseVersion='0.76.4';kernelVersion='0.1.87'}
    $manifestPath=Join-Path $dir 'installation.json'
    [IO.File]::WriteAllText($manifestPath,($manifest|ConvertTo-Json -Depth 10),$utf8)
    $slot=if($Number -eq 3){'PREVIOUS'}else{'CURRENT'}
    $config=Join-Path $dir 'limine.conf'
    $recoveryGuid=$parts.RECOVERY.partitionGuid
    [IO.File]::WriteAllText($config,"timeout: 0`n`n/Recovery storage probe`n    protocol: limine`n    path: guid($recoveryGuid):/$slot/recovery.elf`n    resolution: 1024x768x32`n    module_path: guid($recoveryGuid):/$slot/runtime.img`n    module_string: recovery.runtime=1`n",$utf8)
    $diskPath=Join-Path $output "$name.img"
    $disk=[IO.File]::Open($diskPath,[IO.FileMode]::Create,[IO.FileAccess]::ReadWrite)
    try{
        $disk.SetLength(2048MB)
        $mbr=[byte[]]::new(512);$mbr[450]=238;$mbr[510]=85;$mbr[511]=170
        U32 $mbr 440 $Number;U32 $mbr 454 1;U32 $mbr 458 (4194304-1)
        Write-At $disk 0 $mbr
        Write-At $disk 512 (Header $entries (Id $Number 0) 1 (4194304-1) 2)
        Write-At $disk 1024 $entries
        Write-At $disk ((4194304-33)*512) $entries
        Write-At $disk ((4194304-1)*512) (Header $entries (Id $Number 0) (4194304-1) 1 (4194304-33))
        for($i=1;$i -lt 5;$i++){
            $role=$roles[$i]
            $witness=Join-Path $dir "$role.txt"
            [IO.File]::WriteAllText($witness,"$Number/$role",$utf8)
            $list=Join-Path $dir "$role.list"
            $files=@("$witness|/VOLUME.TXT")
            if($role -eq 'BOOT'){
                $files+=@("$manifestPath|/boot/r4os-installation.json","$config|/boot/limine.conf", "$(Join-Path $LimineRoot 'limine-bios.sys')|/boot/limine-bios.sys", "$(Join-Path $LimineRoot 'BOOTX64.EFI')|/EFI/BOOT/BOOTX64.EFI")
            }
            if($role -eq 'RECOVERY'){$files+=@("$kernel|/$slot/recovery.elf","$runtime|/$slot/runtime.img")}
            [IO.File]::WriteAllText($list,($files -join "`n")+"`n",$utf8)
            $volume=Join-Path $dir "$role.img"
            $size=[int][Math]::Floor($lengths[$i]*512/1MB)
            if($role -in @('SYSTEM','DATA')){
                Checked $imageCreator @('format-ntfs','--output',$volume,'--meta',(Join-Path $root 'Platform/SDK/Tests/Fixture/Ntfs/Meta0605'),'--size',"$size",'--label',"R4TEST$Number$role",'--serial',('{0:x16}' -f ($Number*16+$i)),'--add-list',$list)
            }else{Checked $imageCreator @('--output',$volume,'--size',"$size",'--volume-only','--add-list',$list)}
            # BPB hidden sectors must describe this actual partition location.
            $fs=[IO.File]::Open($volume,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite)
            try{
                $bpb=[byte[]]::new(512);$fs.ReadExactly($bpb);U32 $bpb 28 ([uint32]$starts[$i]);Write-At $fs 0 $bpb
                if($role -in @('SYSTEM','DATA')){Write-At $fs ($fs.Length-512) $bpb}else{Write-At $fs (6*512) $bpb}
            }finally{$fs.Dispose()}
            Copy-Volume $disk ([long]$starts[$i]*512) $volume
            Remove-Item -LiteralPath $volume -Force
        }
        $disk.Flush($true)
    }finally{$disk.Dispose()}
    Checked $limine @('bios-install',$diskPath)
    return $diskPath
}

