#!/bin/bash
set -euo pipefail

# EBS volume format and mount for Prometheus data persistence
DEVICE="/dev/xvdf"
MOUNT_POINT="/opt/prometheus/data"

# Format only if not already formatted
if ! blkid "$DEVICE"; then
  sudo mkfs.ext4 "$DEVICE"
fi

sudo mkdir -p "$MOUNT_POINT"
sudo mount "$DEVICE" "$MOUNT_POINT"

# Persist across reboots
echo "$DEVICE $MOUNT_POINT ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab

echo "EBS mounted at $MOUNT_POINT"
