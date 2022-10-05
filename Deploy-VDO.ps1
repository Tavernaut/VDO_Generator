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

    [Parameter(ParameterSetName="FromJSON", Mandatory)][array]$JSONFile
)

Import-Module "$PSScriptRoot\VDO_Functions.psm1" -Force 

$config = Read-VDOConfig "$PSScriptRoot\$ConfigFile" -CreateFromExample "$PSScriptRoot\EXAMPLE_CONFIG.json"

if($JSONFile){
    $Settings = Read-VDOConfig "$PSScriptRoot\$JSONFile" -CreateFromExample "$PSScriptRoot\EXAMPLE_INPUT.json"
}
else{
    [PSCustomObject]$Settings = @{
        RoomName    = $RoomName
        Guests      = $GuestList
    }
}

$Secret = New-VDOSecret ($Config.RoomNameLength - [int]$Settings.RoomName.Length - 1)



foreach($Guest in $Settings.Guests){
    if($Settings.Config.PSObject.Properties.Name -Contains $Guest){
        $VDOConfig =  $Settings.Config.PSObject.Properties["$Guest"].Value.ConfigList -join "&"
    }
    else{
        $VDOConfig =  $Settings.Config.PSObject.Properties["_default"].Value.ConfigList -join "&"
    }
    
    New-VDOUri -VDOConfig $VDOConfig  -BaseUri $config.BaseUri -Room $Settings.RoomName -Guest $Guest -Secret $Secret 
}