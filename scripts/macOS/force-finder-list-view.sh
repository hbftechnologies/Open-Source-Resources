#!/bin/sh

# Use list view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# This will reset all windows to list view.
sudo find / -name ".DS_Store" -exec rm {} \;