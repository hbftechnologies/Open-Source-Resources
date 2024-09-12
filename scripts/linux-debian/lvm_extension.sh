#!/bin/bash

# chmod +x lvm_extension.sh
# sudo ./lvm_extension.sh

# Check if LVM is in use
if lvdisplay &> /dev/null; then
    echo "LVM is in use. Checking for available space to extend..."

    # Check for available space in the volume group
    FREE_SPACE=$(vgs --noheadings --units g --nosuffix -o vg_free | awk '{print $1}')
    if [[ $(echo "$FREE_SPACE > 0" | bc -l) -eq 1 ]]; then
        echo "Free space available. Extending logical volume and resizing filesystem..."
        
        # Extend the logical volume with all free space
        sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
        
        # Resize the filesystem
        sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
        
        echo "Logical volume and filesystem have been resized."
    else
        echo "No free space available in LVM to extend the volume."
    fi
else
    echo "LVM is not in use or not found. Skipping LVM resize."
fi
