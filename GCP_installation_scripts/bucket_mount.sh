#!/bin/bash
bucket_name="BUCKET_NAME"
mount_point="data"

# Check if the mount point is already mounted
if mount | grep -q "$mount_point"; then
    fusermount -u "$mount_point"
    # If not mounted, proceed with gcsfuse
    gcsfuse --file-mode 775 "$bucket_name" "$mount_point"
else
    gcsfuse --file-mode 775 "$bucket_name" "$mount_point"
fi