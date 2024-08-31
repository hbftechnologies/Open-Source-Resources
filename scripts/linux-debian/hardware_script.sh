#!/bin/bash

# chmod +x hardware_script.sh
# sudo ./hardware_script.sh

echo "Gathering hardware specifications..."

# Check if the required commands are available
for cmd in lshw dmidecode lscpu lsblk free; do
    if ! command -v $cmd &> /dev/null; then
        echo "$cmd is required but not installed. Please install it to proceed."
        exit 1
    fi
done

echo "============================================="
echo "System Information"
echo "============================================="

# Get system brand, model, and serial number using dmidecode
brand=$(sudo dmidecode -s system-manufacturer)
model=$(sudo dmidecode -s system-product-name)
serial_number=$(sudo dmidecode -s system-serial-number)

echo "Brand: $brand"
echo "Model: $model"
echo "Serial Number: $serial_number"

echo "---------------------------------------------"

# Get CPU information
echo "CPU Information:"
lscpu | grep -E '^Model name:|^Architecture:|^CPU(s):|^Thread(s) per core:|^Core(s) per socket:|^Socket(s):|^Vendor ID:|^CPU MHz:|^L1d cache:|^L1i cache:|^L2 cache:|^L3 cache:'

echo "---------------------------------------------"

# Get memory information
echo "Memory Information:"
free -h

echo "---------------------------------------------"

# Get storage information
echo "Storage Information:"
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT

echo "---------------------------------------------"

# Get network information
echo "Network Interfaces:"
lshw -class network | grep -E 'description:|product:|vendor:|physical id:|bus info:|logical name:|serial:|size:|capacity:|capabilities:|configuration:'

echo "---------------------------------------------"

# Get GPU information (if available)
echo "GPU Information:"
lshw -class display | grep -E 'description:|product:|vendor:|physical id:|bus info:|logical name:|version:|serial:|width:|clock:|capabilities:|configuration:'

echo "---------------------------------------------"

# Get motherboard information
echo "Motherboard Information:"
sudo dmidecode -t baseboard | grep -E 'Manufacturer:|Product Name:|Version:|Serial Number:'

echo "---------------------------------------------"

# Get BIOS information
echo "BIOS Information:"
sudo dmidecode -t bios | grep -E 'Vendor:|Version:|Release Date:'

echo "============================================="
echo "Hardware specifications gathering complete."
