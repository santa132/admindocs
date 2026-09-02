#!/bin/bash
# ========================================================
# 🧠 Auto Cluster Setup Script
# Tasks:
# 1. Config SSH passwordless for users
# 2. Create symbolic links for scratch & app
# 3. Grant PBS permission to use Docker
# ========================================================

set -e   # Stop on any error
LOGFILE="/var/log/auto_cluster_setup.log"

echo "=== 🕐 Starting cluster setup at $(date) ===" | tee -a "$LOGFILE"

# ------------------------------
# 1️⃣ SSH PASSWORDLESS CONFIG
# ------------------------------
echo "[1/3] Configuring SSH passwordless..." | tee -a "$LOGFILE"
cd /adm/hpc/auto-script || { echo "❌ Directory /adm/hpc/auto-script not found."; exit 1; }

if [ -f "./setup_ssh_no_pass_multiHN.sh" ]; then
    echo "✅ Found setup_ssh_no_pass_multiHN.sh" | tee -a "$LOGFILE"
    chmod +x setup_ssh_no_pass_multiHN.sh
    echo "⚙️  Running SSH setup script..." | tee -a "$LOGFILE"
    ./setup_ssh_no_pass_multiHN.sh | tee -a "$LOGFILE"
else
    echo "❌ Missing setup_ssh_no_pass_multiHN.sh in /mnt/beegfs/adm!" | tee -a "$LOGFILE"
    exit 1
fi

# ------------------------------
# 2️⃣ CREATE SYMBOLIC LINKS
# ------------------------------
echo "[2/3] Creating symlinks..." | tee -a "$LOGFILE"

if [ ! -L "/scratch" ]; then
    ln -s /mnt/beegfs/scratch /scratch
    echo "✅ Symlink created: /scratch → /mnt/beegfs/scratch" | tee -a "$LOGFILE"
else
    echo "ℹ️ Symlink /scratch already exists." | tee -a "$LOGFILE"
fi

if [ ! -L "/app" ]; then
    ln -s /mnt/beegfs/app /app
    echo "✅ Symlink created: /app → /mnt/beegfs/app" | tee -a "$LOGFILE"
else
    echo "ℹ️ Symlink /app already exists." | tee -a "$LOGFILE"
fi

# ------------------------------
# 3️⃣ GRANT PBS DOCKER PERMISSION
# ------------------------------
echo "[3/3] Granting PBS permission to run Docker..." | tee -a "$LOGFILE"
cd /opt/pbs/sbin || { echo "❌ Directory /opt/pbs/sbin not found."; exit 1; }

if [ -f "pbs_container" ]; then
    chgrp docker pbs_container
    chmod 2755 pbs_container
    echo "✅ Permissions updated on pbs_container" | tee -a "$LOGFILE"

    echo "🔄 Restarting PBS service..." | tee -a "$LOGFILE"
    systemctl restart pbs
    systemctl status pbs --no-pager | tee -a "$LOGFILE"
else
    echo "❌ File pbs_container not found in /opt/pbs/sbin!" | tee -a "$LOGFILE"
    exit 1
fi

echo "=== ✅ Cluster setup completed successfully at $(date) ===" | tee -a "$LOGFILE"
