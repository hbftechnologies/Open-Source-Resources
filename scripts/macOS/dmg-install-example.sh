#!/bin/sh

/bin/echo "Application Install"

application="Name"

# Define the bundle identifier to check
bundle_identifier="com.apple.example"

# Search for the .app bundle with the specified bundle identifier
app_path=$(mdfind "kMDItemCFBundleIdentifier == '$bundle_identifier' && kMDItemContentType == 'com.apple.application-bundle'" | head -n 1)

/bin/echo "Checking to see if '$application' is installed."


if [[ -n $app_path ]]; then
    /bin/echo "Application '$application' is installed at: '$app_path'"

    exit 0
else
    /bin/echo "Application '$application' is not installed."

    # Download Require Files
    /bin/echo "Creating folder to save required installation files."
    directory="/Users/Shared/Application"
    mkdir -p $directory
    /bin/echo "Downloading the required files down from internet location."
    curl -L -o /Users/Shared/Application/zip.zip insertURL

    # Unzip Files
    unzip /Users/Shared/Application/zip.zip -d /Users/Shared/Application/

    # Install Application
    /bin/echo "Mounting DMG from /Users/Shared/Application directory"

    dmg_file=$(find "$directory" -iname "*.dmg" -print -quit)
    sudo hdiutil attach -noverify -nobrowse "$dmg_file"

    /bin/echo "Locating installation application"
    # Run the .app inside the mounted DMG
    if [[ -f "/Volumes/Application/application.pkg" ]]; then
        /bin/echo "Found application, running application"
        sudo installer -pkg /Volumes/Application/application.pkg -target /

        # Check if the DMG is mounted
        /bin/echo "Checking to see if the DMG is mounted."
        if hdiutil info | grep -q "$dmg_file"; then
            /bin/echo "DMG '$dmg_file' is mounted."

            # Unmount the DMG file
            /bin/echo "Unmounting DMG"
            sudo hdiutil detach "/Volumes/Application"

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
            rm -rf /Users/Shared/Delinea
        else
            /bin/echo "Directory $directory not found."
            /bin/echo "Nothing else to do."
        fi
    else
        /bin/echo "Failed to find the .pkg file inside the mounted DMG."
    fi

    exit 0
fi
