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
        [Parameter(Mandatory)][string]$Guest,
        [Parameter(Mandatory)][string]$Secret,
        [Parameter()][string]$Pronouns,
        [Parameter()][array]$VDOConfig,
        [Parameter()][string]$Password,
        [Parameter()][switch]$Director
    )
    if($Director){
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
    else{
        $VDOUri = "{0}director={1}_{2}&Password={3}" -f `
                    ($BaseUri -replace '[^\w\?/:\. ]'), 
                    ($Room -replace '[^\w]'),
                    $Secret,
                    $Password
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