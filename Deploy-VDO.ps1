<# 
.SYNOPSIS 
    .
.DESCRIPTION
    .
.PARAMETER ExecuteOBSCommands
    Tells PowerShell to use OBSCommand to automatically generate browser sources in OBS. OBSCommand needs to be installed seperately for this to work.
#>

[CmdletBinding()]
param(    
    [Parameter()][string]$ConfigFile            = "config.json",
    [Parameter()][switch]$ExecuteOBSCommands    = $false,

    [Parameter(ParameterSetName="FromCommandline", Mandatory)][string]$RoomName,
    [Parameter(ParameterSetName="FromCommandline", Mandatory)][array]$GuestList,
    [Parameter(ParameterSetName="FromCommandline", Mandatory)][array]$VDOConfigs,

    [Parameter(ParameterSetName="FromJSON", Mandatory)][array]$JSONFile
)

Import-Module "$PSScriptRoot\VDO_Functions.psm1" -Force 

$config = Read-VDOConfig "$PSScriptRoot\$ConfigFile" -CreateFromExample "$PSScriptRoot\EXAMPLE_CONFIG.json"

if($JSONFile){
    $Settings = Read-VDOConfig "$PSScriptRoot\$JSONFile" -CreateFromExample "$PSScriptRoot\EXAMPLE_INPUT.json"
}
else{
    $Settings = [PSCustomObject]@{
        RoomName    = $RoomName
        Guests      = $GuestList
        Config      = [PSCustomObject]@{
            _default    = [PSCustomObject]@{
                ConfigList  = $VDOConfigs
            }
        }
    }
}


$Secret = New-VDOSecret ($Config.RoomNameLength - [int]$Settings.RoomName.Length - 1)
$Password = New-VDOSecret $Config.PasswordLength

$DefaultConfig = $Settings.Config.PSObject.Properties["_default"]

foreach($Guest in $Settings.Guests){
    $VDOConfigs = $DefaultConfig
    if($Settings.Config.PSObject.Properties.Name -Contains $Guest){        
        $GuestConfig =  $Settings.Config.PSObject.Properties["$Guest"]
        $VDOConfig = Format-VDOConfig -DefaultParameters $DefaultConfig.Value.ConfigList -OverrideParameters $GuestConfig.Value.ConfigList
    }
    else{
        $GuestConfig = $DefaultConfig
        $VDOConfig = Format-VDOConfig -DefaultParameters $DefaultConfig.Value.ConfigList
    }
    
    New-VDOUri -BaseUri $config.BaseUri -Room $Settings.RoomName -Guest $Guest -Secret $Secret -VDOConfig $VDOConfig -Password $Password -Pronouns $GuestConfig.Value.Pronouns
}