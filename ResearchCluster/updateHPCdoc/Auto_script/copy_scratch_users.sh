#!/bin/bash
# -------------------------------------------------------------------
# Script: copy_scratch_users.sh
# Purpose: Copy user folders from /mnt/beegfs/Scratch/ to /mnt/beegfs/scratch/
#          except for a specified excluded user list.
# Usage: sudo ./copy_scratch_users.sh
# -------------------------------------------------------------------

SRC_ROOT="/mnt/beegfs/Scratch"
DST_ROOT="/mnt/beegfs/scratch"

# List of users to exclude (exact names)
EXCLUDES=(
  tomomasa_yamasaki
  bo_wang
  bo_wang1
  bo_wang2
  guimeng_liu
  sean_chenjiale
  tianze_yu
  vankhoa_duong
  somayeh_ebrahimkhani
  chuang_zhang
  shengyu_zhang
  xiaofang_chen
  zong_tianqi
  zihan_chen
  ernest_chong
  ernest_chong2
  ernest_chong3
  ernest_chong4
  jingyi_xu
  benjamin_drabkin
  tiansi_li
  reuben_soh
  yining_zhang
  uat
  username
)

# Convert exclude list to associative array for fast lookup
declare -A EXC_MAP
for u in "${EXCLUDES[@]}"; do
  EXC_MAP["$u"]=1
done

# Check source and destination roots
if [ ! -d "$SRC_ROOT" ]; then
  echo "Error: source root does not exist: $SRC_ROOT"
  exit 1
fi
if [ ! -d "$DST_ROOT" ]; then
  echo "Error: destination root does not exist: $DST_ROOT"
  exit 1
fi

# Loop through each directory under source root
for dir in "$SRC_ROOT"/*; do
  [ -d "$dir" ] || continue
  user_name=$(basename "$dir")

  # Skip if in exclude list
  if [[ ${EXC_MAP["$user_name"]+_} ]]; then
    echo "Skipping excluded user: $user_name"
    continue
  fi

  src_dir="$SRC_ROOT/$user_name"
  dst_dir="$DST_ROOT/$user_name"

  echo "Copying user: $user_name"
  echo "  From: $src_dir"
  echo "  To:   $dst_dir"

  # Create destination if not exist
  mkdir -p "$dst_dir"

  # Copy recursively, preserving attributes
  cp -a "$src_dir/." "$dst_dir/"

done

echo "Done."
