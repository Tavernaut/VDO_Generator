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
        [Parameter()][array]$VDOConfig,
        [Parameter()][string]$Password
    ) 
    $VDOUri = "{0}push={1}&room={2}_{3}&Password={4}&{5}" -f    ($BaseUri -replace '[^a-zA-Z0-9\?/:\. ]'), 
                                                                ($Guest -replace '[^a-zA-Z0-9 ]'), 
                                                                ($Room -replace '[^a-zA-Z0-9 ]'),
                                                                $Secret,
                                                                $Password,
                                                                ($VDOConfig -join "&" -replace '[^a-zA-Z0-9_% ]') 
    
    return $VDOUri -replace ' ','%20'
                                                            
}

function New-VDOSecret {
    param(
        [Parameter(Mandatory, Position = 0)][int]$Length
    )
    -join ((0..9) + (65 .. 90) + (97 ..122 ) | Get-Random -Count $Length | %{if($_ -lt 10){$_}else{[char]$_}})
}

