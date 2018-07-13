﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Path = ".\Bin\CryptoNight-AMD\xmrig-amd.exe"
$Uri = "https://github.com/xmrig/xmrig-amd/releases/download/v2.7.1-beta/xmrig-amd-2.7.1-beta-win64.zip"
$Port = "304{0:d2}"

$Devices = $Devices.AMD
if (-not $Devices -or $Config.InfoOnly) {return} # No AMD present in system

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{MainAlgorithm = "cryptonight/1"; Params = ""}
    [PSCustomObject]@{MainAlgorithm = "cryptonight/msr"; Params = ""}
    [PSCustomObject]@{MainAlgorithm = "cryptonight/rto"; Params = ""}
    [PSCustomObject]@{MainAlgorithm = "cryptonight/xao"; Params = ""}
    [PSCustomObject]@{MainAlgorithm = "cryptonight/xtl"; Params = ""}
    [PSCustomObject]@{MainAlgorithm = "cryptonight-lite"; Params = ""}
    [PSCustomObject]@{MainAlgorithm = "cryptonight-lite/0"; Params = ""}
    [PSCustomObject]@{MainAlgorithm = "cryptonight-lite/1"; Params = ""}
    [PSCustomObject]@{MainAlgorithm = "cryptonight-lite/ipbc"; Params = ""}
    [PSCustomObject]@{MainAlgorithm = "cryptonight-heavy"; Params = ""}
    [PSCustomObject]@{MainAlgorithm = "cryptonight-heavy/tube"; Params = ""}
    [PSCustomObject]@{MainAlgorithm = "cryptonight-heavy/xhv"; Params = ""}
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Devices | Select-Object Vendor, Model -Unique | ForEach-Object {
    $Miner_Device = $Devices | Where-Object Vendor -EQ $_.Vendor | Where-Object Model -EQ $_.Model
    $Miner_Port = $Port -f ($Miner_Device | Select-Object -First 1 -ExpandProperty Index)
    $Miner_Model = $_.Model
    $Miner_Name = (@($Name) + @($Miner_Device.Name | Sort-Object) | Select-Object) -join '-'

    $DeviceIDsAll = Get-GPUIDs $Miner_Device -join ','
    $Miner_PlatformId = $Miner_Device | Select -Property Platformid -Unique -ExpandProperty PlatformId

    $Commands | Where-Object {$Pools.(Get-Algorithm $_.MainAlgorithm).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

        $Algorithm_Norm = Get-Algorithm $_.MainAlgorithm

        [PSCustomObject]@{
            Name = $Miner_Name
            DeviceName = $Miner_Device.Name
            DeviceModel = $Miner_Model
            Path      = $Path
            Arguments = "-R 1 --opencl-devices=$($DeviceIDsAll) --opencl-platform=$($Miner_PlatformId) --api-port $($Miner_Port) -a $($_.MainAlgorithm) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass) --keepalive --nicehash --donate-level=1 $($_.Params)"
            HashRates = [PSCustomObject]@{$Algorithm_Norm = $Stats."$($Miner_Name)_$($Algorithm_Norm)_HashRate".Week}
            API       = "XMRig"
            Port      = $Miner_Port
            URI       = $Uri
            DevFee    = 1.0
        }
    }
}