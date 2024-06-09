<#
    Title: Update Cloudflare Domains

    Description:
    Script to update Cloudflare DNS records with the current public IP address.
    This script uses the Cloudflare API to update the DNS records for a list of domains.

    Author: xXsoulshockerXx
    Version: 1.2
    Date Created: 2022-06-09
    Last Updated: 2024-06-09
#>

# Main Variables
$api_url = 'https://api.cloudflare.com/client/v4/zones'
$api_key = 'blah2304719'
$api_email = 'email@example.com'
$domains = 'domain1.com', 'domain2.xyz', 'domain3.net', 'domain4.org'
$zone_id = '7d805226e85109a3eef430d6bcf12b44', '3420deeed99a9e12b255ad1d82bef123', '420badef1911a69bb8fff37b4f059d1f', '8c5c69f80085d88780324e5d7ccc1969'

# Create a dictionary
# ForEach-Object is used to iterate through the domains and zone_id arrays
# Select-Object is used to combine the two arrays into a dictionary
$domain_zone_map = @{}
0..($domains.Length-1) | ForEach-Object {
    $domain_zone_map.Add($domains[$_], $zone_id[$_])
}

# Define the headers for the API request
$headers = @{
    'Content-Type' = 'application/json'
    'Authorization' = 'Bearer L-KDIAqOEPO1Ge86Cc4FBuOuMMkoicMB78_2_l4G'
}

function Get-PublicIP() {
    # This function retrieves the public IP address of the machine running the script.
    # It does this by making a GET request to the 'api.ipify.org' API endpoint.
    # The response is then returned as a string.
    Invoke-RestMethod -Uri 'https://api.ipify.org'
}

function Get-CurrentIP($domain, $zone_id) {
    # This function retrieves the current IP address associated with a given domain and zone ID.
    # It does this by making a GET request to the Cloudflare API endpoint for the specified zone ID,
    # and then searching for the 'content' field of the first DNS record with the given domain name.
    # The returned value is a string representing the current IP address.
    $response = Invoke-RestMethod -Uri "$api_url/$zone_id/dns_records?name=$domain" -Headers $headers
    $response.result[0].content
}

function Update-DNSRecord($domain, $public_ip, $zone_id) {
    # This function updates the DNS record for a given domain and zone ID with the specified public IP address.
    # It does this by making a GET request to the Cloudflare API endpoint for the specified zone ID,
    # and then searching for the DNS record with the given domain name.
    # If a record is found, it is updated with the new public IP address.
    # The function returns a boolean value indicating whether the update was successful.
    $response = Invoke-RestMethod -Uri "$api_url/$zone_id/dns_records?name=$domain" -Headers $headers
    $record_id = $response.result[0].id
    $data = @{
        'type' = 'A'
        'name' = $domain
        'content' = $public_ip
        'proxied' = $true
    }
    $response = Invoke-RestMethod -Uri "$api_url/$zone_id/dns_records/$record_id" -Headers $headers -Method Put -Body $data | Select-Object -ExpandProperty StatusCode
    $response -eq 200
}

function Add-DNSRecord($domain, $public_ip, $zone_id) {
    # This function creates a new DNS record for a given domain and zone ID with the specified public IP address.
    # It does this by making a GET request to the Cloudflare API endpoint for the specified zone ID,
    # and then searching for any existing DNS records with the given domain name.
    # If no records are found, a new record is created with the specified public IP address.
    # The function returns a boolean value indicating whether the record creation was successful.
    $response = Invoke-RestMethod -Uri "$api_url/$zone_id/dns_records?name=$domain" -Headers $headers
    $data = @{
        'type' = 'A'
        'name' = $domain
        'content' = $public_ip
        'proxied' = $true
    }
    $response = Invoke-RestMethod -Uri "$api_url/$zone_id/dns_records" -Headers $headers -Method Post -Body $data | Select-Object -ExpandProperty StatusCode
    $response -eq 200
}

function Get-DNSRecord($domain, $zone_id) {
    # This function checks whether a DNS record exists for a given domain and zone ID.
    # It does this by making a GET request to the Cloudflare API endpoint for the specified zone ID,
    # and then searching for any existing DNS records with the given domain name.
    # The function returns a boolean value indicating whether a record was found.
    $response = Invoke-RestMethod -Uri "$api_url/$zone_id/dns_records?name=$domain" -Headers $headers
    $response.result.Count -gt 0
}

# Get the current public IP
$public_ip = Get-PublicIP

# Check each domain
foreach ($domain in $domains) {
    # Check if there is a record for the domain
    if (Get-DNSRecord $domain $domain_zone_map[$domain]) {
        $current_ip = Get-CurrentIP $domain $domain_zone_map[$domain]
        
        if ($current_ip -ne $public_ip) {
            # Update the DNS record if necessary
            if (Update-DNSRecord $domain $public_ip $domain_zone_map[$domain]) {
                Write-Host "DNS record updated for $domain. New IP: $public_ip"
            } else {
                Write-Host "Failed to update DNS record for $domain."
            }
        } else {
            Write-Host "No update needed for $domain."
        }
    } else {
        # Create a new DNS record for the domain
        if (Add-DNSRecord $domain $public_ip $domain_zone_map[$domain]) {
            Write-Host "DNS record created for $domain."
        } else {
            Write-Host "DNS record already exists for $domain."
        }
    }
}
