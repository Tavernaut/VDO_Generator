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
        [Parameter()][string]$Password
    )
    if($Pronouns){$Label = "{0} ({1})" -f $Guest, $Pronouns}else{$Label = $Guest}
    $VDOUri = "{0}push={1}&label={2}&room={3}_{4}&Password={5}&{6}" -f  `
                ($BaseUri -replace '[^\w\?/:\. ]'), 
                ($Guest -replace '[^\w]'), 
                ($Label -replace '[^\w\s()%]'), 
                ($Room -replace '[^\w]'),
                $Secret,
                $Password,
                ($VDOConfig -join "&" -replace '[^\w_%\s&=]') 
    
    return $VDOUri -replace '[\s]','%20'
                                                            
}

function New-VDOSecret {
    param(
        [Parameter(Mandatory, Position = 0)][int]$Length
    )
    -join ((0..9) + (65 .. 90) + (97 ..122 ) | Get-Random -Count $Length | %{if($_ -lt 10){$_}else{[char]$_}})
}

