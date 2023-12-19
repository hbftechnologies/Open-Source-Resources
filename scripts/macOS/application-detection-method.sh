#!/bin/sh

/bin/echo "Checking for Application Install"

# Define the bundle identifier to check
bundle_identifier="com.apple.example"

/bin/echo "Checking to see if Application is installed."

# Search for the .app bundle with the specified bundle identifier
app_path=$(mdfind "kMDItemCFBundleIdentifier == '$bundle_identifier' && kMDItemContentType == 'com.apple.application-bundle'" | head -n 1)

if [[ -n $app_path ]]; then
  echo "Application is installed at: $app_path"
else
  echo "Application is not installed."
fi