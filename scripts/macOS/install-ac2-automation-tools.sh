#!/bin/sh

# Check to see if AC2 Automation Tools is installed
DIR="/usr/local/bin/cfgutil"

# See if the check is empty
if [[ -L "$DIR" ]]; then
    /bin/echo "Apple Configurator Automation Tools installed, no action needed."
    exit 0
else
    /bin/echo "Did not find Apple Configurator Automation Tools."
    /bin/echo "Running the install."

    # Install AC2 Automation Tools
    sudo ln -s "/Applications/Apple Configurator.app/Contents/MacOS/cfgutil" /usr/local/bin

    exit 0
fi