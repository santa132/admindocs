#!/bin/bash

# List all directories in /home/
for USER_NAME in /home/users/*; do
  if [ -d "$USER_NAME" ]; then
    echo "$(Username "$USER_NAME")"

    # Unlink current scratch folder, link to the scratch_old folder
    unlink /home/users/$USER_NAME/scratch
    ln -sf /Scratch/$USER_NAME /home/users/$USER_NAME/scratch_old
    mkdir -p /scratch/$USER_NAME
    chmod 700 /scratch/$USER_NAME
    chown $USER_NAME:grp-$USER_NAME /scratch/$USER_NAME

    # Link new scratch folder with HA
    ln -sf /scratch/$USER_NAME /home/users/$USER_NAME/scratch
    chown $USER_NAME:grp-$USER_NAME /home/users/$USER_NAME/scratch
    USER_ID=$(id -u $USER_NAME 2>/dev/null)
    beegfs-ctl --setquota --uid $USER_ID --sizelimit=500G --inodelimit=unlimited
  fi
done
