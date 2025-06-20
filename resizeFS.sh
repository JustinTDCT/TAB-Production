#!/bin/bash
clear
set -e

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root."
    exit 1
fi

echo "Detecting physical volume..."
pv_device=$(pvs --noheadings -o pv_name | awk '{print $1}' | head -n 1)
if [[ -z "$pv_device" || ! -b "$pv_device" ]]; then
    echo "Physical volume not found or not a block device: $pv_device"
    exit 1
fi
echo "Physical volume: $pv_device"


# Get base disk and partition number
partition_number=$(basename "$pv_device" | grep -o '[0-9]*$')
base_disk="/dev/$(basename "$pv_device" | sed 's/[0-9]*$//')"

if [[ ! -b "$base_disk" ]]; then
    echo "Base disk not found: $base_disk"
    exit 1
fi

echo "Base disk: $base_disk"
echo "Partition number: $partition_number"

echo "Fixing GPT to use full disk size..."
gdisk "$base_disk" <<EOF
w
y
y
EOF

# Resize the partition using parted
echo "Resizing partition..."
parted -s "$base_disk" resizepart "$partition_number" 100%

# Inform the kernel of partition table changes
echo "Updating kernel partition table..."
partprobe "$base_disk"

# Resize the physical volume
echo "Resizing physical volume..."
pvresize "$pv_device"

echo "Partition and PV resized successfully."


# Get the volume group name
vg_name=$(pvs --noheadings -o vg_name "$pv_device" | awk '{print $1}')

# Get logical volumes in that volume group
lv_paths=$(lvs --noheadings -o lv_path "$vg_name" | awk '{print $1}')

echo "Volume Group: $vg_name"
echo "Logical Volumes on $pv_device:"
echo "Device name: $lv_paths"

# Get the device-mapper name
DM_NAME=$(dmsetup info -c --noheadings -o name "$lv_paths" 2>/dev/null)
DM_NAME="/dev/mapper/$DM_NAME"
echo "Mapping name: $DM_NAME"

# Reszie the volume group
set +e
lvextend -l +100%FREE $lv_paths
set -e

# Resize the file system
resize2fs $DM_NAME
df -h
