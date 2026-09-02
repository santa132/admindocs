#!/bin/bash

# ==============================================
# G-node list inside this file
# ==============================================
GNODES=(
  "aimc-gn1"
  "aimc-gn2"
  "aimc-gn4"
  "aimc-gna1"
  "aimc-gna2"
  "aimc-h100-02"
)

SCRIPT_PATH="/adm/hpc/auto-script/append_passwd_group_gnode.sh"

echo "[*] Executing append_passwd_group_gnode.sh on all G-nodes..."

for node in "${GNODES[@]}"; do
    echo "-----------------------------------------"
    echo "[*] Processing node: $node"
    echo "-----------------------------------------"

    ssh root@$node "bash -s" < $SCRIPT_PATH

    echo "[✔] Completed on $node"
    echo ""
done

echo "[🎉] All G-nodes updated successfully!"
