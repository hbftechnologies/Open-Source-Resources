#!/bin/bash

# Define the content for the krb5.conf file
krb5_conf_content="[libdefaults]
  default_realm = DOMAIN.LAN
 
[realms]
DOMAIN.LAN = {
        kdc = dc01.domain.lan:88
        kdc = dc02.domain.lan:88
        kdc = dc03.domain.lan:88
        admin_server = dc01.domain.lan:749
        default_domain = domain.lan
    }
[domain_realm]
    .domain.lan = DOMAIN.LAN
    domain.lan = DOMAIN.LAN"

# Set the path to the krb5.conf file
krb5_conf_path="/etc/krb5.conf"

# Remove existing krb5.conf file if it exists
if [ -f "$krb5_conf_path" ]; then
    sudo rm "$krb5_conf_path"
fi

# Create a new krb5.conf file and populate it with the desired content
echo "$krb5_conf_content" | sudo tee "$krb5_conf_path" > /dev/null

# Set the correct permissions on the krb5.conf file
sudo chmod 644 "$krb5_conf_path"
sudo chown root:wheel "$krb5_conf_path"