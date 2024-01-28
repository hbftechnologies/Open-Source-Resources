#!/bin/sh

/bin/echo "MacOS Bomgar Install"

# Define the bundle identifier to check
bundle_identifier="com.bomgar.bomgar-scc"

/bin/echo "Checking to see if BeyondTrust Remote Support Tools is installed."

if mdfind "kMDItemCFBundleIdentifier == '$bundle_identifier'" | grep -q "$bundle_identifier"; then
    /bin/echo "Application '$bundle_identifier' found."
    /bin/echo "BeyondTrust Remote Support Agent found, no need to install."

    exit 0
else
    /bin/echo "Application '$bundle_identifier' not found."
    /bin/echo "BeyondTrust Remote Support Agent not found, will need to install."

    # Download Require Files
    /bin/echo "Creating folder to save required installation files."
    directory="/Users/Shared/beyondtrust"
    mkdir -p $directory
    /bin/echo "Downloading the required files down from Beyond Trust."
    curl -L -o /Users/Shared/beyondtrust/install.dmg '[insert download link here]'

    # Install BeyondTrust Remote Agent
    /bin/echo "Mounting DMG from /Users/Shared/beyondtrust directory"

    dmg_file=$(find "$directory" -iname "*.dmg" -print -quit)
    sudo hdiutil attach -noverify -nobrowse "$dmg_file"

    /bin/echo "Locating installation application"
    # Run the .app inside the mounted DMG
    if [[ -d "/Volumes/bomgar-scc/Double-Click To Start Support Session.app" ]]; then
        /bin/echo "Found application, running application"
        # sudo open -a "/Volumes/bomgar-scc/Double-Click To Start Support Session.app/Contents.MacOS/sdcust --silent"
        /Volumes/bomgar-scc/Double-Click\ To\ Start\ Support\ Session.app/Contents/MacOS/sdcust --silent
        sleep 60

        /bin/echo "Checking to see if the DMG is mounted."

        # Check if the DMG is mounted
        if hdiutil info | grep -q "$dmg_file"; then
            /bin/echo "DMG '$dmg_file' is mounted."
            /bin/echo "Unmounting DMG"

            # Unmount the DMG file
            /bin/echo "Unmounting DMG"
            sudo hdiutil detach "/Volumes/bomgar-scc"

        else
            /bin/echo "DMG '$dmg_file' is not mounted."
        fi

        /bin/echo "Checking for Installation files, remove if found."
        if [ -d "$directory" ]
        then
            /bin/echo "Directory $directory found."
            /bin/echo "Cleaning up installation files"

            # Clean Up
            /bin/echo "Cleaning up installation files."
            rm -rf /Users/Shared/beyondtrust
        else
            /bin/echo "Directory $directory not found."
            /bin/echo "Nothing else to do."
        fi
    else
        /bin/echo "Failed to find the .app file inside the mounted DMG."
    fi

    exit 0
fi
