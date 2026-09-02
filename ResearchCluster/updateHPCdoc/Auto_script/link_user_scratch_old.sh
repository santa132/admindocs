#!/bin/bash
# ------------------------------------------------------------------
# Script: link_user_scratch.sh
# Purpose: Iterate through /home/users/<username> directories,
#          for each user: check if ~/scratch exists — if not,
#          create symlink /scratch/<username> → /home/users/<username>/scratch
#          then chown user:grp-user for the target directory.
# Usage: sudo ./link_user_scratch.sh
# ------------------------------------------------------------------

HOME_ROOT="/home/users"
SCRATCH_ROOT="/scratch"

# Check that roots exist
if [ ! -d "$HOME_ROOT" ]; then
  echo "Error: $HOME_ROOT does not exist."
  exit 1
fi

if [ ! -d "$SCRATCH_ROOT" ]; then
  echo "Error: $SCRATCH_ROOT does not exist."
  exit 1
fi

# Loop through each directory under /home/users
for user_dir in "$HOME_ROOT"/*; do
  [ -d "$user_dir" ] || continue   # skip non-directories
  USER_NAME=$(basename "$user_dir")
  USER_SCRATCH_LINK="$user_dir/scratch"
  TARGET_SCRATCH_DIR="$SCRATCH_ROOT/$USER_NAME"

  # Create target scratch directory if it doesn't exist
  if [ ! -d "$TARGET_SCRATCH_DIR" ]; then
    echo "Creating scratch directory for user: $USER_NAME -> $TARGET_SCRATCH_DIR"
    mkdir -p "$TARGET_SCRATCH_DIR"
  fi

  # Create symlink if link doesn't exist or is incorrect
  if [ ! -L "$USER_SCRATCH_LINK" ] || [ "$(readlink "$USER_SCRATCH_LINK")" != "$TARGET_SCRATCH_DIR" ]; then
    echo "Linking: $USER_SCRATCH_LINK -> $TARGET_SCRATCH_DIR"
    ln -sfn "$TARGET_SCRATCH_DIR" "$USER_SCRATCH_LINK"
  else
    echo "Symlink already exists for user: $USER_NAME"
  fi

  # chown the target scratch directory
  echo "Setting ownership: $TARGET_SCRATCH_DIR -> ${USER_NAME}:grp-${USER_NAME}"
  chown "${USER_NAME}:grp-${USER_NAME}" "$TARGET_SCRATCH_DIR"

done

echo "Done."
