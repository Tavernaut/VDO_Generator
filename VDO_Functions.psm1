function Read-VDOConfig {
    param(
        [Parameter(Mandatory = $true, Position = 0)][String]$ConfigFile,
        [Parameter()][String]$CreateFromExample
    )
    try {
        if(!(Test-Path $ConfigFile)){
            if($CreateFromExample){
                if(Test-Path $CreateFromExample){
                    Write-Warning "Config file doesn't exist in: $ConfigFile"
                    Write-Warning "Creating config file from example: $CreateFromExample"
                    Copy-Item -Path $CreateFromExample -Destination $ConfigFile
                }
                else{
                    Write-Warning "Config file doesn't exist in: $ConfigFile"
                    Write-Error "Cannot create config file from example as it does not exist: $CreateFromExample"
                    break
                }
            }
            else{
                Write-Warning "Config file doesn't exist in: $ConfigFile"
                Write-Error "Cannot find a config file, and no instruction was given to create one, use the -CreateFromExample flag."
                break
            }
        }
        return Get-Content $ConfigFile | ConvertFrom-JSON
    }
    catch {
        {1:Write-Error "An error occurred that caused the script to terminate."}
    }
}

function New-VDOUri {
    param(
        [Parameter(Mandatory)][string]$BaseUri,
        [Parameter(Mandatory)][string]$Room,
        [Parameter(Mandatory)][string]$Secret,
        [Parameter()][string]$Password,

        [Parameter(Mandatory, ParameterSetName="GuestUri")][string]$Guest,
        [Parameter(ParameterSetName="GuestUri")][string]$Pronouns,
        [Parameter(ParameterSetName="GuestUri")][array]$VDOConfig,
        
        [Parameter(ParameterSetName="DirectorUri")][switch]$Director,

        [Parameter(Mandatory, ParameterSetName="SceneUri")][string]$View,
        [Parameter(ParameterSetName="SceneUri")][switch]$Scene
        
    )
    if($Director){
        $VDOUri = "{0}director={1}_{2}&Password={3}" -f `
                    ($BaseUri -replace '[^\w\?/:\. ]'), 
                    ($Room -replace '[^\w]'),
                    $Secret,
                    $Password
    }
    elseif($Scene){
        $VDOUri = "{0}scn&room={1}_{2}&Password={3}&view={4}" -f `
                    ($BaseUri -replace '[^\w\?/:\. ]'), 
                    ($Room -replace '[^\w]'),
                    $Secret,
                    $Password,
                    ($View -replace '[^\w]')
    }
    else{
        if($Pronouns){$Label = "{0} ({1})" -f $Guest, $Pronouns -replace "/","%2f"}else{$Label = $Guest}
        $VDOUri = "{0}push={1}&label={2}&room={3}_{4}&Password={5}&{6}" -f  `
                    ($BaseUri -replace '[^\w\?/:\. ]'), 
                    ($Guest -replace '[^\w]'), 
                    ($Label -replace '[^\w\s()%]'), 
                    ($Room -replace '[^\w]'),
                    $Secret,
                    $Password,
                    ($VDOConfig -join "&" -replace '[^\w_%\s&=()]') 
    }
    
    
    return $VDOUri -replace '[\s]','%20'
                                                            
}

function New-VDOSecret {
    param(
        [Parameter(Mandatory, Position = 0)][int]$Length
    )
    -join ((0..9) + (65 .. 90) + (97 ..122 ) | Get-Random -Count $Length | %{if($_ -lt 10){$_}else{[char]$_}})
}

function Format-VDOConfig {
    param(
        [Parameter(Mandatory)][psobject]$DefaultParameters,
        [Parameter()][psobject]$OverrideParameters
    )

    $Parameters = $DefaultParameters.PSObject.Copy()

    if($OverrideParameters){
        foreach($Param in $OverrideParameters.PSObject.Properties){
            $Parameters | Add-Member -MemberType NoteProperty -Name $Param.Name -Value $Param.Value -Force
        }
    }

    $output = @()
    
    foreach($Param in $Parameters.PSObject.Properties){
        if($Param.Value){$output += $Param.Name, $Param.Value -join "="}
        else {$output += $Param.Name}
    }

    return $output
}

function Test-OBSCommand {
    param(
        [Parameter(Mandatory)][string]$OBSCommandLocation,
        [Parameter(Mandatory)][securestring]$OBSPassword,
        [Parameter()][string]$Server="127.0.0.1",
        [Parameter()][int]$Port=4455,
        [Parameter()][int]$TimeOut=30
    )

    if(Test-Path $OBSCommandLocation){
        $ScriptBlock = "{0} /server={1}:{2} /password={3} /command=GetVersion" -f`
                            $OBSCommandLocation,
                            $Server,
                            $Port,
                            ($OBSPassword | ConvertFrom-SecureString -AsPlainText)
        $TestJob = Start-Job -Scriptblock ([scriptblock]::Create($ScriptBlock))
        
        $RunTime= 0
        while(($TestJob.State -eq "Running") -and ($RunTime -lt $Timeout)){
            Start-Sleep 1
            $RunTime += 1
        }
        if($TestJob.State -eq "Running"){
            Stop-Job $TestJob
            Write-Error "Timed out while connecting to OBS Websocket, check if the password is correct."
            break
        }
        else{
            if(($TestJob | Receive-Job) -eq "Error: can't connect to OBS websocket plugin!"){
                Write-Error "Error while connecting to OBS Websocket, is the server running and are the -Address and -Port variables set correctly?"
                break
            }
            else{
                return "OBS Websocket Connection Confirmed"
            }
        }
        
    }
    else{
        Write-Error "OBSCommand was called but is not installed at location $OBSCommandLocation"
        Write-Error "Did you install it? You can find it over at: https://github.com/REALDRAGNET/OBSCommand"
        break
    }
}

function Invoke-OBSCommand {
    param(
        [Parameter(Mandatory)][string]$OBSCommandLocation,
        [Parameter(Mandatory)][securestring]$OBSPassword,
        [Parameter()][string]$Server="127.0.0.1",
        [Parameter()][int]$Port=4455,
        [Parameter()][int]$TimeOut=30,
        [Parameter(Mandatory)][string]$Command,
        [Parameter()][psobject]$JSONPayload
    )

    if(Test-Path $OBSCommandLocation){
        if(!$JSONPayload){
            $ScriptBlock = "{0} /server={1}:{2} /password={3} /command={4}" -f `
                    $OBSCommandLocation,
                    $Server,
                    $Port,
                    ($OBSPassword | ConvertFrom-SecureString -AsPlainText),
                    $Command
        }
        else{
            $ScriptBlock = "{0} /server={1}:{2} /password={3} /sendjson=`"{4}={5}`"" -f`
                $OBSCommandLocation,
                $Server,
                $Port,
                ($OBSPassword | ConvertFrom-SecureString -AsPlainText),
                $Command,
                ($JSONPayload | ConvertTo-Json -Compress).Replace('"',"'")
    
        }
        Write-Verbose -Message "Running: $ScriptBlock"
        $Job = Start-Job -Scriptblock ([scriptblock]::Create($ScriptBlock))
        $RunTime = 0
        while(($Job.State -eq "Running") -and ($RunTime -lt $Timeout)){
            Start-Sleep 1
            $RunTime += 1
        }

        if($Job.State -eq "Running"){
            Stop-Job $Job
            Write-Error "Timed out while connecting to OBS Websocket, check if the password is correct."
            break
        }
        
        else{
            $Result = $Job | Receive-Job
            if($Result -like "Error:*"){
                Write-Error "$Result"
                break
            }
            else{
                return $Result.Trim("Ok") | ConvertFrom-Json 
            }
        }
        
    }
    else{
        Write-Error "OBSCommand was called but is not installed at location $OBSCommandLocation"
        Write-Error "Did you install it? You can find it over at: https://github.com/REALDRAGNET/OBSCommand"
        break
    }
}