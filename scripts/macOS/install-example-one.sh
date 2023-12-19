#!/bin/sh

# Check to see if Application is installed.
DIR="/Library/Application Support/Application"
application="Application"

# See if the check is empty
if [ -d "$DIR" ]
then
    /bin/echo "Directory $DIR found."
    /bin/echo "$application is installed, no action is needed."

    exit 0
else
    /bin/echo "Directory $DIR not found."
    /bin/echo "$application is not installed, run the installer."

    # Install Application

    # Download the required files from Internet
    /bin/echo "Pulling the required files down from Internet."
    mkdir -p /Users/Shared/Application
   	curl -L --silent insertURL -o /Users/Shared/Application/application.zip
    
    # Install
    /bin/echo "unpacking the files"
    unzip /Users/Shared/Application/application.zip -d /Users/Shared/Application/

    /bin/echo "running the install"
    sudo /Users/Shared/Application/install.sh

    # Clean Up
    /bin/echo "cleaning up"
    rm -rf /Users/Shared/Application
    
    exit 0
fi