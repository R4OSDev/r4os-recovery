# Technical image copies retain holes through the existing shared host helper.
# A normal File.Copy expands a22-GB sparse fixture on Linux. Keep this change
# outside the guest and compare complete bytes before releasing the host lock.
. (Join-Path $PSScriptRoot '../../Distribution/Tools/Qemu-Media.ps1')
function Copy-RecoveryFixture([string]$Source,[string]$Destination) {
    $sourcePath=[IO.Path]::GetFullPath($Source)
    $destinationPath=[IO.Path]::GetFullPath($Destination)
    $allowed=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../Artifacts'))+[IO.Path]::DirectorySeparatorChar
    if(!$destinationPath.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase) -or
       $sourcePath.Equals($destinationPath,[StringComparison]::OrdinalIgnoreCase)){
        throw 'Fixture copy requires a separate target below Recovery/Artifacts.'
    }
    $inputFile=[IO.File]::Open($sourcePath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    $outputFile=$null;$hash=[Security.Cryptography.SHA256]::Create()
    try{
        $expected=[Convert]::ToHexString($hash.ComputeHash($inputFile))
        $inputFile.Position=0
        $outputFile=[IO.File]::Open($destinationPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        $outputFile.Lock(0,[Math]::Max([long]1,$outputFile.Length))
        $outputFile.SetLength(0)
        [R4OS.Distribution.QemuMediaCopy]::Copy($inputFile,$outputFile)
        $outputFile.Flush($true);$outputFile.Position=0
        if($outputFile.Length -ne $inputFile.Length -or
           [Convert]::ToHexString($hash.ComputeHash($outputFile)) -cne $expected){
            throw 'Technical image copy differs from its complete source.'
        }
    }finally{
        if($null -ne $outputFile){$outputFile.Dispose()}
        $hash.Dispose();$inputFile.Dispose()
    }
}
