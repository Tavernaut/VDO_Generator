<# 
.SYNOPSIS 
    .
.DESCRIPTION
    .
.PARAMETER ExecuteOBSCommands
    Tells PowerShell to use OBSCommand to automatically generate browser sources in OBS. OBSCommand needs to be installed seperately for this to work.
#>

[CmdletBinding(DefaultParameterSetName = "FromCommandline")]
param(    
    [Parameter()][string]$ConfigFile            = "config.json",
    [Parameter()][switch]$ExecuteOBSCommands    = $false
)

Import-Module "$PSScriptRoot\VDO_Functions.psm1" -Force 

Read-VDOConfig "$PSScriptRoot\$ConfigFile" -CreateFromExample "$PSScriptRoot\EXAMPLE_CONFIG.json"