<#
    Title: Update Cloudflare Domains

    Description:
    Script to update Cloudflare DNS records with the current public IP address.
    This script uses the Cloudflare API to update the DNS records for a list of domains.

    Author: xXsoulshockerXx
    Version: 3.0
    Date Created: 2022-06-09
    Last Updated: 2024-06-09
#>

# Main Variables
$api_url = 'https://api.cloudflare.com/client/v4/zones'
$domains = @('domain1.com', 'domain2.xyz', 'domain3.net', 'domain4.org')

# Dictionary
$domain_zone_map = @{
    'domain1.com' = '7d805226e85109a3eef430d6bcf12b44'
    'domain2.xyz' = '3420deeed99a9e12b255ad1d82bef123'
    'domain3.net' = '420badef1911a69bb8fff37b4f059d1f'
    'domain4.org' = '8c5c69f80085d88780324e5d7ccc1969'
}

# Headers for the API request
$headers = @{
    'Content-Type' = 'application/json'
    'Authorization' = 'Bearer K-blah2304719GeeeT45_33_33_GG'
}

function Get-PublicIP() {
    $url = "https://api.ipify.org?format=json"
    $response = Invoke-WebRequest -Uri $url
    $json = $response.Content | ConvertFrom-Json
    return $json.ip
}

function Read-CloudflarePrimaryRecord {
    param (
        [Parameter(Mandatory=$true)]
        [string]$domain,
        [Parameter(Mandatory=$true)]
        [string]$zoneId
    )

    $api_url = 'https://api.cloudflare.com/client/v4/zones'
    $headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = 'Bearer K-blah2304719GeeeT45_33_33_GG'
    }

    $response = Invoke-WebRequest -Uri "$api_url/$zoneId/dns_records?type=A&name=$domain" -Headers $headers -Method GET
    $response.Content | ConvertFrom-Json
}

function Add-CloudflarePrimaryRecord {
    param (
        [Parameter(Mandatory=$true)]
        [string]$domain,
        [Parameter(Mandatory=$true)]
        [string]$zoneId
    )

    $api_url = 'https://api.cloudflare.com/client/v4/zones'
    $headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = 'Bearer K-blah2304719GeeeT45_33_33_GG'
    }
    $ipAddress = Get-PublicIP

    $body = @{
        "type" = "A"
        "name" = $domain
        "content" = $ipAddress
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri "$api_url/$zoneId/dns_records" -Headers $headers -Method POST -Body $body

        if ($response.StatusCode -eq 200) {
            Write-Output "Primary record for $domain added successfully with ID: $($response.Headers.Location.Split('/')[-1])"
        } else {
            Write-Output "Failed to add primary record for $domain. Status code: $($response.StatusCode)"
        }
    } catch {
        Write-Output "An error occurred while adding primary record for $domain. Error: $_"
    }
}

function Update-CloudflarePrimaryRecord {
    param (
        [Parameter(Mandatory=$true)]
        [string]$domain,
        [Parameter(Mandatory=$true)]
        [string]$zoneId
    )

    $api_url = 'https://api.cloudflare.com/client/v4/zones'
    $headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = 'Bearer K-blah2304719GeeeT45_33_33_GG'
    }

    $public_ip = Get-PublicIP

    $body = @{
        "type" = "A"
        "name" = $domain
        "content" = $public_ip
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri "$api_url/$zoneId/dns_records" -Headers $headers -Method POST -Body $body

        if ($response.StatusCode -eq 200) {
            Write-Output "Primary record for $domain updated successfully with new IP: $public_ip"
        } else {
            Write-Output "Failed to update primary record for $domain. Status code: $($response.StatusCode)"
        }
    } catch {
        Write-Output "An error occurred while updating primary record for $domain. Error: $_"
    }
}

foreach ($domain in $domains) {
    $zoneId = $domain_zone_map.$domain
    $readDNSRecord = Read-CloudflarePrimaryRecord -domain $domain -zoneId $zoneId
    # $readDNSRecord.result.content
    $publicIP = Get-PublicIP

    if ($readDNSRecord.result.content) {
        Write-Output "$domain primary record exists and has an IP of $($readDNSRecord.result.content)."
        # true
        if ($readDNSRecord.result.content -ne $publicIP) {
            # does not match public IP
            # update records
            Write-Output "$domain IP doesn't match the current local public IP: $publicIP."
            Write-Output "Updating $domain DNS Records."
            Update-CloudflarePrimaryRecord -domain $domain -zoneId $zoneId
        } else {
            Write-Output "$domain DNS record is current and no action is needed."
        }
    } else {
        # false
        Write-Output "$domain primary record does not exist."
        Write-Output "Adding $domain DNS Records."
        Add-CloudflarePrimaryRecord -domain $domain -zoneId $zoneId
    }
}
