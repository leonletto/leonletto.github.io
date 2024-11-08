
function LoadEnvVariables
{
    $current_path = $PSScriptRoot
    if ($null -eq $current_path)
    {
        $current_path = Get-Location
    }

    while (-not (Test-Path "$current_path/.env"))
    {
        $current_path = Split-Path $current_path
        if ($null -eq $current_path)
        {
            Write-Host "No .env file found. Are you setting them elsewhere?"
            break
        }
    }

    # If .env file is found, load it
    if (Test-Path "$current_path/.env")
    {
        get-content $current_path/.env | ForEach-Object {
            $line = $_.Trim()
            if ($line -and -not $line.StartsWith("#"))
            {
                $equals = $line.IndexOf("=")
                if ($equals -gt 0)
                {
                    $name = $line.Substring(0, $equals).Trim()
                    $value = $line.Substring($equals + 1).Trim().Trim("'")

                    Set-Item -Path Env:\"$name" -Value "$value"
                }
            }
        }
    }
}

# Load the environment variables
LoadEnvVariables

# A function to make API requests with proper error handling
function Invoke-ApiRequest
{
    param (
        [string]$Method,
        [string]$Uri,
        [hashtable]$Headers,
        [hashtable]$Body = $null
    )

    try
    {
        if ($Method -eq "Post")
        {
            return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -Body $Body
        }
        else
        {
            return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers
        }
    }
    catch
    {
        Write-Error "Error calling API: $Uri"
        Write-Error $_.Exception.Message
        return $null
    }
}

# Global variables for caching the token
$bearer_token = ""
# set the script run time as a reference
$script_run_time = [DateTime]::Now
$token_expiry = $script_run_time
$expires_in = 0

# Function to get Bearer Token
function Get-BearerToken
{
    $current_time = [DateTime]::Now
    if ($bearer_token -ne "" -and $token_expiry -gt $current_time.AddSeconds($expires_in))
    {
        return $bearer_token
    }

    $url = "https://na.uemauth.vmwservices.com/connect/token"
    $payload = @{
        grant_type = "client_credentials"
        client_id = $env:CLIENT_ID
        client_secret = $env:CLIENT_SECRET
    }
    $headers = @{
        'Content-Type' = 'application/x-www-form-urlencoded'
        'User-Agent' = 'Chrome'
        'Accept' = 'application/json'
    }

    $response = Invoke-ApiRequest -Method "Post" -Uri $url -Headers $headers -Body $payload
    if ($null -eq $response)
    {
        Write-Error "Failed to obtain access token."
        exit 1
    }

    $global:bearer_token = $response.access_token
    $global:token_expiry = $current_time.AddSeconds($response.expires_in - 120) # 2 minute buffer
    $global:expires_in = $response.expires_in
    return $global:bearer_token
}


# Function to get devices list  
function Get-DevicesList
{
    param (
        [hashtable]$headers
    )

    $bearer_token = Get-BearerToken
    $headers.Authorization = "Bearer $bearer_token"
    $url = "https://$( $env:HOST )/api/system/devices/search?searchtext=%"
    $response = Invoke-ApiRequest -Method "Get" -Uri $url -Headers $Headers
    if ($null -eq $response)
    {
        Write-Error "Failed to get devices list."
        exit 1
    }
    
    return $response
}

$headers = @{
    "aw-tenant-code" = $env:API_KEY
    "Accept" = "application/json; version=2"
}
$devices = Get-DevicesList -headers $headers
Write-Output $devices