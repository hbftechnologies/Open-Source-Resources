# Script Name: ghostcms-backup.py
# Author: Harley Frank
# Created: 01/27/2024
# Last Modified: 01/27/2024
# Description: This script will backup a ghost blog to a local directory.

# Notes:
# This script requires the requests module. To install it, run 'pip3 install requests' in the terminal.
# You will need to create a new API key in Ghost CMS and replace the api_key variable below with your new key.

# Import Working Modules
import os
import requests
import json

# General Variables
api_url = 'https://domain.com/ghost/api/v3/content/'
api_key = '1234567890'
output_path = os.path.expanduser("~/Documents/Recovery/client-blogs/ghostcms")

# Function to get posts
def get_posts():
    response = requests.get(f'{api_url}posts/?key={api_key}')
    posts = response.json()
    with open(os.path.join(output_path, 'posts.json'), 'w') as f:
        json.dump(posts, f)

# Function to get settings
def get_settings():
    response = requests.get(f'{api_url}settings/?key={api_key}')
    settings = response.json()
    with open(os.path.join(output_path, 'settings.json'), 'w') as f:
        json.dump(settings, f)

# Call the functions
get_posts()
get_settings()
