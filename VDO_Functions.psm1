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