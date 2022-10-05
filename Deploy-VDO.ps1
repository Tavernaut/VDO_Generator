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

$URIs = @{
    DirectorUri = New-VDOUri -BaseUri $config.BaseUri -Room $Settings.RoomName -Secret $Secret -Password $Password -Director
    Guests      = @{}
}

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
    
    $URIs.Guests += @{
        $Guest = @{
            Link    = New-VDOUri -BaseUri $config.BaseUri -Room $Settings.RoomName -Guest $Guest -Secret $Secret -VDOConfig $VDOConfig -Password $Password -Pronouns $GuestConfig.Value.Pronouns
            Scene   = New-VDOUri -Scene -BaseUri $config.BaseUri -Room $Settings.RoomName -View $Guest -Secret $Secret -Password $Password    
        }
    }    
}

if($ExecuteOBSCommands){
    if($config.OBSCommand.Password){$Password = $config.OBSCommand.Password | ConvertTo-SecureString -AsPlainText -Force}
    else{$Password = Read-Host -AsSecureString -Prompt "OBS Websocket Password"}
    Test-OBSCommand -OBSCommandLocation $config.OBSCommand.Location `
                    -TimeOut $config.OBSCommand.TimeOut `
                    -Server $config.OBSCommand.Server `
                    -Port $config.OBSCommand.Port `
                    -OBSPassword $Password
    
    $CurrentScene = (Invoke-OBSCommand  -OBSCommandLocation $config.OBSCommand.Location `
                                        -TimeOut $config.OBSCommand.TimeOut `
                                        -Server $config.OBSCommand.Server `
                                        -Port $config.OBSCommand.Port `
                                        -OBSPassword $Password `
                                        -Command "GetSceneList").currentProgramSceneName
    
    $CreateInput = [psobject]@{
        sceneName       = $CurrentScene
        inputName       = "test"
        inputKind       = "browser_source"
        inputSettings   = @{
            height  = 1080
            width   = 1920
        }
    }
    foreach($Guest in $URIs.Guests.GetEnumerator()){
        $CreateInput = [psobject]@{
            sceneName       = $CurrentScene
            inputName       = $Guest.Name
            inputKind       = "browser_source"
            inputSettings   = @{
                height          = 1080
                width           = 1920
                url             = $Guest.Value.Scene
                reroute_audio   = $true
                shutdown        = $true
            }
        }

        Invoke-OBSCommand   -OBSCommandLocation $config.OBSCommand.Location `
                            -TimeOut $config.OBSCommand.TimeOut `
                            -Server $config.OBSCommand.Server `
                            -Port $config.OBSCommand.Port `
                            -OBSPassword $Password `
                            -Command "CreateInput" `
                            -JSONPayload $CreateInput | Out-Null

        $SetInputAudioTracks = [psobject]@{
            inputName        = $Guest.Name
            inputAudioTracks = [psobject]@{
                "1"= $true
                "2"= $true
                "3"= $true
                "4"= $false
                "5"= $false
                "6"= $false
            }
        }                   
        Invoke-OBSCommand   -OBSCommandLocation $config.OBSCommand.Location `
                            -TimeOut $config.OBSCommand.TimeOut `
                            -Server $config.OBSCommand.Server `
                            -Port $config.OBSCommand.Port `
                            -OBSPassword $Password `
                            -Command "SetInputAudioTracks" `
                            -JSONPayload $SetInputAudioTracks | Out-Null

        
    }

    # Invoke-OBSCommand   -OBSCommandLocation $config.OBSCommand.Location `
    #                     -TimeOut $config.OBSCommand.TimeOut `
    #                     -Server $config.OBSCommand.Server `
    #                     -Port $config.OBSCommand.Port `
    #                     -OBSPassword $Password `
    #                     -Command "CreateInput" `
    #                     -JSONPayload $CreateInput | Out-Null

}