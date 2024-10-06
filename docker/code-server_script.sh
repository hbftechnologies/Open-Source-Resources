#!/bin/bash

# chmod +x code-server_script.sh
# sudo ./code-server_script.sh

# follow the typical instructions to install powershell, but don't do the sudo apt-get install -f
# instead do sudo dpkg --install --ignore-depends=libicu72 powershell_7.4.2-1.deb_amd64.deb
# https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.4#installation-via-direct-download

# Variables
SERVER_HOSTNAME=$(hostname -s)
VSCODE_COMPOSE_FILE="/code/docker-compose.yml"
VSCODE_ENV_FILE="/code/.env"
VSCODE_DOCKERFILE="/code/Dockerfile"
PROXY_DOMAIN="$SERVER_HOSTNAME-code.cloud.harleytechnologies.xyz"
PUID=$(id -u username)
PGID=$(getent group groupname | cut -d: -f3)
SUDO_PASSWORD="sudo123changeme"

# Check if code-server container is running
echo "Checking if code-server container is running..."
if [ "$(docker ps -q -f name=code-server)" ]; then
    echo "code-server container is running. Stopping and removing the container..."
    docker compose -f $VSCODE_COMPOSE_FILE down
else
    echo "code-server container is not running."
fi

# Setting up code-server
echo "Deploying code-server"

# Create /code folder if it doesn't exist
if [ ! -d "/code" ]; then
    echo "Creating /code directory"
    sudo mkdir -p /code
fi

# Create a hostname folder within /code if it doesn't exist
if [ ! -d "/code/$SERVER_HOSTNAME" ]; then
    echo "Creating /code/$SERVER_HOSTNAME directory"
    sudo mkdir -p /code/$SERVER_HOSTNAME
fi

# If the file exists, delete it first
if [ -f "$VSCODE_COMPOSE_FILE" ]; then
    echo "docker-compose.yml already exists. Deleting the existing file."
    sudo rm "$VSCODE_COMPOSE_FILE"
fi

if [ -f "$VSCODE_ENV_FILE" ]; then
    echo ".env already exists. Deleting the existing file."
    sudo rm "$VSCODE_ENV_FILE"
fi

if [ -f "$VSCODE_DOCKERFILE" ]; then
    echo "Dockerfile already exists. Deleting the existing file."
    sudo rm "$VSCODE_DOCKERFILE"
fi

# Create a new .env file
echo "Creating .env file for code-server"
sudo tee $VSCODE_ENV_FILE > /dev/null <<EOF
USER_ID=$PUID
GROUP_ID=$PGID
TIMEZONE=America/New_York
SUDO_PASSD=$SUDO_PASSWORD
PROXY=$PROXY_DOMAIN
WORKSPACE=$SERVER_HOSTNAME
EOF

# Create a new Dockerfile
echo "Creating Dockerfile for code-server"
sudo tee $VSCODE_DOCKERFILE > /dev/null <<'EOF'
FROM lscr.io/linuxserver/code-server:latest

# Update the list of packages
RUN apt-get update

# Install pre-requisite packages
RUN apt-get install -y wget apt-transport-https software-properties-common

# Download the Microsoft repository keys
RUN wget -q https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb

# Register the Microsoft repository keys
RUN dpkg -i packages-microsoft-prod.deb || true

# Delete the Microsoft repository keys file
RUN rm packages-microsoft-prod.deb

# Update the list of packages after we added packages.microsoft.com
RUN apt-get update

# Download the PowerShell package file
RUN wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.5/powershell_7.4.5-1.deb_amd64.deb

# Install the PowerShell package
RUN dpkg --install --ignore-depends=libicu72 powershell_7.4.5-1.deb_amd64.deb || true

# Delete the downloaded PowerShell package file
RUN rm powershell_7.4.5-1.deb_amd64.deb
EOF

# Create a new docker-compose.yml
echo "Creating docker-compose.yml for code-server"
sudo tee $VSCODE_COMPOSE_FILE > /dev/null <<'EOF'
services:
  code-server:
    build: .
    # image: lscr.io/linuxserver/code-server:latest
    container_name: code-server
    restart: unless-stopped
    environment:
      - PUID=$USER_ID
      - PGID=$GROUP_ID
      - TZ=$TIMEZONE
      - SUDO_PASSWORD=$SUDO_PASSD
      - PROXY_DOMAIN=$PROXY #optional
      - DEFAULT_WORKSPACE=/config/$WORKSPACE #optional
    ports:
      - "42843:8443"
    volumes:
      - /code/config:/config
    networks:
      - code-server

networks:
  code-server:
    driver: bridge
EOF

# Add a volume mount for /code/<hostname>
echo "Adding volume for directory: $SERVER_HOSTNAME"
awk '/volumes:/ {print; print "      - /code/'"$SERVER_HOSTNAME"':/config/'"$SERVER_HOSTNAME"'"; next}1' $VSCODE_COMPOSE_FILE > /tmp/docker-compose.yml && sudo mv /tmp/docker-compose.yml $VSCODE_COMPOSE_FILE

# Find all top-level directories in /data except 'code' and mount them as volumes
echo "Adding top-level directories under /data to docker-compose volumes"
for dir in /data/*; do
    if [ -d "$dir" ] && [ "$(basename "$dir")" != "syncthing" ] && [ "$(basename "$dir")" != "code" ] && [ "$(basename "$dir")" != "plex" ]; then
        folder_name=$(basename "$dir")
        # Add a volume mount for each top-level directory inside /code/<hostname>
        echo "Adding volume for directory: $folder_name"
        awk '/volumes:/ {print; print "      - /data/'"$folder_name"':/config/'"$SERVER_HOSTNAME"'/'"$folder_name"'"; next}1' $VSCODE_COMPOSE_FILE > /tmp/docker-compose.yml && sudo mv /tmp/docker-compose.yml $VSCODE_COMPOSE_FILE
    fi
done

# Change ownership of the /code directory and file if necessary
sudo chown -R username:groupname /code
sudo chmod -R 775 /code

# Run docker-compose file
echo "Running 'docker compose -f /code/docker-compose.yml up -d' to start code-server..."
docker compose -f /code/docker-compose.yml up -d

# Remove file to not retain private information
echo "Removing executed code-server script"
sudo rm $0
