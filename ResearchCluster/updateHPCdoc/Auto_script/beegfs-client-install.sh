#!/bin/bash
# BeeGFS 7.4.6 Client Installation Script for Ubuntu 24.04
# ---------------------------------------------------------

BEEGFS_VER="7.4.6"
BEEGFS_HOST="172.16.0.8"      # <-- Change sysMgmtdHost as needed
#OFED_PATH="/usr/src/ofa_kernel/default/include/"  # <-- Change if needed
OFED_PATH="/usr/src/linux-nvidia-headers-5.15.0-1091/include"
set -e
echo ">>> Installing BeeGFS client version ${BEEGFS_VER} ..."

# --- Add BeeGFS repo and key ---
wget -q https://www.beegfs.io/release/beegfs_${BEEGFS_VER}/gpg/GPG-KEY-beegfs -O /etc/apt/trusted.gpg.d/beegfs.asc
wget -q https://www.beegfs.io/release/beegfs_${BEEGFS_VER}/dists/beegfs-noble.list -O /etc/apt/sources.list.d/beegfs.list

# --- Install packages ---
apt update -y
apt install -y apt-transport-https beegfs-client beegfs-utils beegfs-helperd

# --- Configure beegfs-helperd.conf ---
HELPERD_CONF="/etc/beegfs/beegfs-helperd.conf"
sed -i '/^connDisableAuthentication/d' "$HELPERD_CONF"
echo "connDisableAuthentication = true" >> "$HELPERD_CONF"

# --- Configure beegfs-client.conf ---
CLIENT_CONF="/etc/beegfs/beegfs-client.conf"

# Replace or append required values
sed -i "/^sysMgmtdHost/d" "$CLIENT_CONF"
sed -i "/^connDisableAuthentication/d" "$CLIENT_CONF"
sed -i "/^sysMountSanityCheckMS/d" "$CLIENT_CONF"

# Append clean entries at the end
echo "sysMgmtdHost = ${BEEGFS_HOST}" >> "$CLIENT_CONF"
echo "connDisableAuthentication = true" >> "$CLIENT_CONF"
echo "sysMountSanityCheckMS = 0" >> "$CLIENT_CONF"

# --- Configure beegfs-client-autobuild.conf ---
AUTO_BUILD_CONF="/etc/beegfs/beegfs-client-autobuild.conf"
sed -i '/^buildArgs/d' "$AUTO_BUILD_CONF" 2>/dev/null || true
echo "buildArgs=-j8 BEEGFS_OPENTK_IBVERBS=1 OFED_INCLUDE_PATH=${OFED_PATH}" >> "$AUTO_BUILD_CONF"

# --- Restart services ---
systemctl restart beegfs-helperd
systemctl restart beegfs-client

echo ">>> BeeGFS client installation and configuration completed successfully."
