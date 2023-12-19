#!/bin/bash

currentUser=$(stat -f%Su /dev/console)

currentAdminPriv=$(dseditgroup -o checkmember -m "$currentUser" admin | awk '{ print $1 }')

if [[ "$currentAdminPriv" == "yes" ]]; then
	echo "The user, $currentUser, is already an admin."
elif [[ "$currentAdminPriv" == "no" ]]; then
	echo "The user, $currentUser, is not an admin."
	echo "Granting admin privileges..."
	/usr/sbin/dseditgroup -o edit -a "$currentUser" -t user admin && echo "Done."
fi