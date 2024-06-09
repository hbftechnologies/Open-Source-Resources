# Script Name: Update Cloudflare IPs
# Created by: xXsoulshockerXx
# Created on: 2022-02-26
# Last Updated: 2024-06-09
# Version: 1.0
# Description:
# Script to update Cloudflare DNS records with the current public IP address.
# This script uses the Cloudflare API to update the DNS records for a list of domains.
# The script checks the current public IP address and compares it to the IP address in the DNS record.
# If the IP address has changed, the script updates the DNS record with the new IP address.
# If the DNS record does not exist, the script creates a new DNS record for the domain.
# The script requires the Cloudflare API key, email, and zone ID. The zone ID can be obtained from the Cloudflare dashboard.

import requests

# Cloudflare API endpoint
api_url = 'https://api.cloudflare.com/client/v4/zones'

# Cloudflare API key and email
api_key = 'blah2304719'
api_email = 'email@example.com'

# List of domains to check
# Add your domains to the list
# The zone ID for each domain can be obtained from the Cloudflare dashboard. In the same order as the domains.
domains = ['domain1.com', 'domain2.xyz', 'domain3.net', 'domain4.org']
zone_id = ['7d805226e85109a3eef430d6bcf12b44', '3420deeed99a9e12b255ad1d82bef123', '420badef1911a69bb8fff37b4f059d1f', '8c5c69f80085d88780324e5d7ccc1969']

# Create a dictionary
# zip function is used to combine two lists into a dictionary
# dict function is used to convert the zipped object into a dictionary
domain_zone_map = dict(zip(domains, zone_id))

# Headers for the API request
headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer blah2304719',
}

# Function to get the public IP
def get_public_ip():
    response = requests.get('https://api.ipify.org')
    return response.text

# Function to get the current IP for a domain
def get_current_ip(domain, zone_id):
    response = requests.get(f'{api_url}/{zone_id}/dns_records?name={domain}', headers=headers)
    data = response.json()
    return data['result'][0]['content']

# Function to update the DNS record for a domain
def update_dns_record(domain, public_ip, zone_id):
    response = requests.get(f'{api_url}/{zone_id}/dns_records?name={domain}', headers=headers)
    data = response.json()
    record_id = data['result'][0]['id']
    data = {
        'type': 'A',
        'name': domain,
        'content': public_ip,
        'proxied': True
    }
    response = requests.put(f'{api_url}/{zone_id}/dns_records/{record_id}', headers=headers, json=data)
    return response.status_code == 200

# Function to create a new DNS record for a domain
def create_dns_record(domain, public_ip, zone_id):
    response = requests.get(f'{api_url}/{zone_id}/dns_records?name={domain}', headers=headers)
    data = response.json()
    if len(data['result']) == 0:
        data = {
            'type': 'A',
            'name': domain,
            'content': public_ip,
            'proxied': True
        }
        response = requests.post(f'{api_url}/{zone_id}/dns_records', headers=headers, json=data)
        return response.status_code == 200
    else:
        return False

# Function to check if a DNS record exists for a domain
def check_dns_record(domain, zone_id):
    response = requests.get(f'{api_url}/{zone_id}/dns_records?name={domain}', headers=headers)
    data = response.json()
    return len(data['result']) > 0

# Get the current public IP
public_ip = get_public_ip()

# Check each domain
for domain in domains:
    # Check if there is a record for the domain
    if check_dns_record(domain, domain_zone_map[domain]):
        current_ip = get_current_ip(domain, domain_zone_map[domain])
        
        if current_ip != public_ip:
            # Update the DNS record if necessary
            if update_dns_record(domain, public_ip, domain_zone_map[domain]):
                print(f'DNS record updated for {domain}. New IP: {public_ip}')
            else:
                print(f'Failed to update DNS record for {domain}.')
        else:
            print(f'No update needed for {domain}.')
    else:
        # Create a new DNS record for the domain
        if create_dns_record(domain, public_ip, domain_zone_map[domain]):
            print(f'DNS record created for {domain}.')
        else:
            print(f'DNS record already exists for {domain}.')
