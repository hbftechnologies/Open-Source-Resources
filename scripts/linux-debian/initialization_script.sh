#!/bin/bash

# chmod +x initialization_script.sh
# sudo ./initialization_script.sh
# https://webmin.com/faq/#can-i-run-webmin-or-usermin-behind-reverse-proxy

# Variables
TIMEZONE="America/New_York"
# TIMEZONE="America/Chicago"
ROOT_PASSWORD="password" # Set the password for root
ADMIN_PASSWORD="password" # Set the password for admin
USER1_PASSWORD="password" # Set the password for user1
ANSIBLE_PASSWORD="password" # Set the password for ansible
USER2_PASSWORD="password" # Set the password for user2
CHANGE_PASSWORD=false
CHANGE_ROOT_PASSWORD=false
COMPANY_NAME="company.com" # Set your company name
BANNER_FILE="/etc/issue.net"
SSHD_CONFIG_FILE="/etc/ssh/sshd_config"
GENERATE_SSH_KEYS=false
DOCKER_INSTALL=true
DATA_PERMISSIONS=true
INSTALL_NETDATA=false
# NETDATA_REGION="region1" # Set the region for Netdata installation
# NETDATA_REGION="region2" # Set the region for Netdata installation
# NETDATA_REGION="region3" # Set the region for Netdata installation
TAILSCALE_AUTHKEY="authkey" # Set your Tailscale AuthKey
LOCAL_INSTALLATION=false
UBUNTU_PRO=false
UBUNTU_PRO_TOKEN="token" # Set your Ubuntu Pro Token

# Function to check if a package is installed
is_installed() {
    dpkg -l "$1" &> /dev/null
}

# Function to create or update a user account
create_or_update_user() {
    local username=$1
    local password=$2
    if id "$username" &>/dev/null; then
        echo "User $username already exists"
        if [ "$CHANGE_PASSWORD" = true ]; then
            echo "Changing password for user $username"
            echo "$username:$password" | sudo chpasswd
        else
            echo "Skipping password change for user $username"
        fi
    else
        echo "Creating user account for $username"
        sudo useradd -m -s /bin/bash $username
        echo "$username:$password" | sudo chpasswd
    fi
}

# Function to create SSH key pair for a user
generate_ssh_key() {
    local username=$1
    local ssh_dir="/home/$username/.ssh"
    local date=$(date +%Y%m%d)
    local key_file="$ssh_dir/${username}_id_rsa_$date"
    local pub_key_file="$key_file.pub"
    
    if [ ! -d "$ssh_dir" ]; then
        sudo mkdir -p "$ssh_dir"
        sudo chown "$username:$username" "$ssh_dir"
        sudo chmod 700 "$ssh_dir"
    fi
    
    if [ ! -f "$key_file" ]; then
        sudo -u "$username" ssh-keygen -t rsa -b 4096 -f "$key_file" -N ""
        echo "SSH key generated for $username: $key_file"
    else
        echo "SSH key already exists for $username: $key_file"
    fi

    # Add the public key to authorized_keys and set correct permissions
    local auth_keys="$ssh_dir/authorized_keys"
    if ! grep -q "$(cat "$pub_key_file")" "$auth_keys" 2>/dev/null; then
        cat "$pub_key_file" | sudo tee -a "$auth_keys" > /dev/null
        sudo chown "$username:$username" "$auth_keys"
        sudo chmod 600 "$auth_keys"
        echo "Added public key to $auth_keys for $username"
    else
        echo "Public key already present in $auth_keys for $username"
    fi
}

# Function to backup the existing banner if it exists
backup_banner() {
    if [ -f "$BANNER_FILE" ]; then
        local date=$(date +%Y%m%d)
        local backup_file="$BANNER_FILE.bak_$date"
        sudo mv "$BANNER_FILE" "$backup_file"
        echo "Existing banner backed up to $backup_file"
    fi
}

# Function to check if Netdata is running
is_netdata_running() {
    if systemctl is-active --quiet netdata; then
        echo "Netdata is already running"
        return 0
    else
        return 1
    fi
}

# Set Timezone
current_timezone=$(timedatectl show --property=Timezone --value)
if [ "$current_timezone" != "$TIMEZONE" ]; then
    echo "Setting timezone to $TIMEZONE"
    sudo timedatectl set-timezone $TIMEZONE
else
    echo "Timezone is already set to $TIMEZONE"
fi

# Create or update users and set passwords
create_or_update_user "admin" "$ADMIN_PASSWORD"
create_or_update_user "user1" "$USER1_PASSWORD"
create_or_update_user "ansible" "$ANSIBLE_PASSWORD"
create_or_update_user "user2" "$USER2_PASSWORD"

if [ "$CHANGE_ROOT_PASSWORD" = true ]; then
    echo "Changing root password"
    echo "root:$ROOT_PASSWORD" | sudo chpasswd
else
    echo "Skipping root password change"
fi

# Conditionally generate SSH keys
if [ "$GENERATE_SSH_KEYS" = true ]; then
    echo "Generating SSH keys for users"
    generate_ssh_key "admin"
    generate_ssh_key "user1"
    generate_ssh_key "ansible"
    generate_ssh_key "user2"
else
    echo "Skipping SSH key generation"
fi

# Install Docker and Docker Compose
if [ "$DOCKER_INSTALL" = true ]; then
    if ! is_installed "docker-ce"; then
        echo "Installing Docker and Docker Compose"
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        echo "Docker is already installed"
    fi
fi

# Add Users to Docker Group
add_to_group() {
    local username=$1
    local groupname=$2
    if groups $username | grep &>/dev/null "\b$groupname\b"; then
        echo "User $username is already in the $groupname group"
    else
        echo "Adding $username to the $groupname group"
        sudo usermod -aG $groupname $username
    fi
}

add_to_group "admin" "docker"
add_to_group "user1" "docker"
add_to_group "ansible" "docker"
add_to_group "admin" "sudo"
add_to_group "ansible" "sudo"

sudo addgroup sshaccess
add_to_group "admin" "sshaccess"
add_to_group "user1" "sshaccess"
add_to_group "ansible" "sshaccess"
add_to_group "user2" "sshaccess"

# set the default editor to nano
if ! grep -q "export EDITOR=nano" /etc/profile; then
    echo "Setting default editor to nano"
    echo "export EDITOR=nano" | sudo tee -a /etc/profile > /dev/null
else
    echo "nano is already set as the default editor in /etc/profile"
fi

# Install AppArmor and PAM modules
for pkg in apparmor apparmor-profiles apparmor-utils apparmor-easyprof libpam-tmpdir libpam-apparmor libpam-cracklib; do
    if is_installed $pkg; then
        echo "$pkg is already installed"
    else
        echo "Installing $pkg"
        sudo apt-get install -y $pkg
    fi
done

# Configure PAM for AppArmor
if ! grep -q 'pam_apparmor.so' /etc/pam.d/apparmor; then
    echo "Configuring PAM for AppArmor"
    echo 'session optional pam_apparmor.so order=user,group,default' | sudo tee /etc/pam.d/apparmor > /dev/null
else
    echo "PAM for AppArmor is already configured"
fi

# Start and enable AppArmor service
if sudo systemctl is-enabled apparmor.service &> /dev/null; then
    echo "AppArmor service is already enabled"
else
    echo "Starting and enabling AppArmor service"
    sudo systemctl start apparmor.service
    sudo systemctl enable apparmor.service
fi

# Install vsftpd
if is_installed "vsftpd"; then
    echo "vsftpd is already installed"
else
    echo "Installing vsftpd"
    sudo apt-get install -y vsftpd
fi

# Install ACL
if is_installed "acl"; then
    echo "ACL is already installed"
else
    echo "Installing ACL"
    sudo apt-get install -y acl
fi

# Create /data folder
if [ -d "/data" ]; then
    echo "/data folder already exists"
else
    echo "Creating /data folder"
    sudo mkdir /data
fi

# Create group for data and add users to it
if getent group data >/dev/null; then
    echo "Group 'data' already exists"
else
    echo "Creating 'data' group"
    sudo groupadd data
fi

add_to_group "admin" "data"
add_to_group "user1" "data"
add_to_group "ansible" "data"
add_to_group "user2" "data"

# Set permissions for /data folder
if [ "$DATA_PERMISSIONS" = true ]; then
    echo "Setting permissions for /data folder"
    sudo chown admin:data /data
    sudo chmod -R 775 /data
    sudo chmod g+s /data
    sudo setfacl -R -m u:admin:rwx /data
    sudo setfacl -R -m g:data:rwx /data
    sudo setfacl -dR -m u:admin:rwx /data
    sudo setfacl -dR -m g:data:rwx /data
fi

# Backup the existing banner and create a new one
backup_banner

# Set custom banner in /etc/issue.net
HOSTNAME=$(hostname)
BANNER="WARNING! Authorized Users Only!

Property of $COMPANY_NAME
Logging is enabled and malicious acts will be taken seriously to the
fullest extent of the law.

$HOSTNAME"

echo "$BANNER" | sudo tee /etc/issue.net > /dev/null
echo "Banner /etc/issue.net" | sudo tee -a /etc/ssh/sshd_config > /dev/null

# Backup existing sshd_config and replace with new configuration
if [ -f "$SSHD_CONFIG_FILE" ]; then
    echo "Backing up existing $SSHD_CONFIG_FILE"
    sudo cp $SSHD_CONFIG_FILE $SSHD_CONFIG_FILE.bak
fi

echo "Updating $SSHD_CONFIG_FILE with the new configuration"
sudo tee $SSHD_CONFIG_FILE > /dev/null <<EOF
# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

Include /etc/ssh/sshd_config.d/*.conf

Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

# AllowGroups sshaccess

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
LogLevel VERBOSE

# Authentication:

LoginGraceTime 2m
PermitRootLogin no
#StrictModes yes
MaxAuthTries 3
MaxSessions 10

PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
#AuthorizedKeysFile     .ssh/authorized_keys .ssh/authorized_keys2

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication yes
PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
KbdInteractiveAuthentication yes

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the KbdInteractiveAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via KbdInteractiveAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and KbdInteractiveAuthentication to 'no'.
UsePAM yes

#AllowAgentForwarding yes
AllowTcpForwarding yes
GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
PrintMotd no
PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
Compression no
ClientAliveInterval 60
ClientAliveCountMax 3
#UseDNS no
#PidFile /run/sshd.pid
MaxStartups 10:30:60
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

ChallengeResponseAuthentication no

# no default banner path
Banner /etc/issue.net

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# override default of no subsystems
Subsystem       sftp    /usr/lib/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#       X11Forwarding no
#       AllowTcpForwarding no
#       PermitTTY no

Match User user2
        ForceCommand internal-sftp
EOF

# Restart SSH service to apply changes
echo "Restarting SSH service to apply changes"
sudo systemctl restart ssh

# Add Symlinks for Data Folder to each user's home directory
for user in admin user1 ansible user2; do
    if [ -L "/home/$user/data" ]; then
        echo "/home/$user/data symlink already exists"
    else
        echo "Creating /home/$user/data symlink"
        sudo ln -s /data /home/$user/data
    fi
done

# Install Webmin
if is_installed "webmin"; then
    echo "Webmin is already installed"
else
    echo "Installing Webmin"
    curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
    sudo sh setup-repos.sh
    sudo apt-get update
    sudo apt-get install -y webmin --install-recommends
fi

# Install Tailscale
if is_installed "tailscale"; then
    echo "Tailscale is already installed"
else
    echo "Installing Tailscale"
    curl -fsSL https://tailscale.com/install.sh | sudo sh
    sudo tailscale set --auto-update
    sudo tailscale up --authkey $TAILSCALE_AUTHKEY

fi

# Install UFW
if is_installed "ufw"; then
    echo "UFW is already installed"
else
    echo "Installing UFW"
    sudo apt-get install -y ufw
fi

# configure UFW
sudo ufw default deny
sudo ufw allow 41641/udp
sudo ufw allow in on tailscale0
sudo ufw allow out on tailscale0

if [ "$LOCAL_INSTALLATION" = true ]; then
    sudo ufw allow 22
    sudo ufw allow 80
    sudo ufw allow 443
    sudo ufw allow 10000 # webmin
    sudo ufw allow 1514 # wazzuh
    sudo ufw allow 1515 # wazzuh
    sudo ufw allow 55000 # wazzuh
    sudo ufw allow in from 192.168.1.0/24
    sudo ufw allow in from 192.168.2.0/24
fi

# Conditionally install Netdata based on the region
if [ "$INSTALL_NETDATA" = true ]; then
    if is_netdata_running; then
        echo "Skipping Netdata installation"
    else
        if [ -z "$NETDATA_REGION" ]; then
            echo "Region is not specified, cannot install Netdata"
            exit 1
        else
            echo "Installing Netdata for region: $NETDATA_REGION"
            # Example installation steps for Netdata
            case $NETDATA_REGION in
                "region1")
                    # grab from the console
                    ;;
                "region2")
                    # grab from the console
                    ;;
                "region3")
                    # grab from the console
                    ;;
                *)
                    echo "Unknown region specified: $NETDATA_REGION"
                    exit 1
                    ;;
            esac
        fi
    fi
else
    echo "Skipping Netdata installation"
fi

# Setup Ubuntu Pro Subscription
if [ "$UBUNTU_PRO" = true ]; then
    echo "Installing Ubuntu Pro for $UBUNTU_PRO_TOKEN"
    sudo pro attach $UBUNTU_PRO_TOKEN
fi

# Update and upgrade system
echo "Updating and upgrading the system"
sudo apt-get update && sudo apt-get upgrade -y

# Deleting Script Before Reboot
echo "Deleting the script before reboot"
echo "$(date): Initialization script self-deleted after execution." >> /var/log/system_init.log
sudo rm $0

# Restart system
echo "Restarting the system"
sudo reboot
