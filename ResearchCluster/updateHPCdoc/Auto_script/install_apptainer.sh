#!/bin/bash
set -e

echo "======  Update repositories & install dependencies ======"

sudo apt-get update

sudo apt-get install -y \
    build-essential \
    libseccomp-dev \
    uidmap \
    fakeroot \
    cryptsetup \
    tzdata \
    dh-apparmor \
    curl wget git

echo "====== [] Create GO source file ======"

sudo bash -c 'cat > /etc/profile.d/go.sh' <<'EOF'
export GOROOT=/mnt/beegfs/app/go/go-1.23.2
export PATH=$GOROOT/bin:$PATH
EOF

source /etc/profile.d/go.sh
echo "[OK] GO environment loaded"

echo "====== Copy Apptainer folder ======"
if [ -d /adm/software/apptainer ]; then
    sudo cp -r /adm/software/apptainer /raid
    echo "[OK] Copied /adm/software/apptainer → /raid"
else
    echo "[ERROR] /adm/software/apptainer not found"
    exit 1
fi

echo "====== Create CACHEDIR and TMPDIR ======"
sudo mkdir -p /raid/apptainer_tmp
sudo chmod 1777 /raid/apptainer_tmp

sudo bash -c 'cat > /etc/profile.d/apptainer.sh' <<'EOF'
export PATH=/raid/apptainer/install/bin:$PATH

# Separate cache for each user
export APPTAINER_CACHEDIR="\$HOME/.apptainer/cache"

# TMPDIR must be located on an ext4 filesystem (e.g., /tmp)
export APPTAINER_TMPDIR="/raid/apptainer_tmp/apptainer_${USER}"

# Auto-create directories
mkdir -p "$APPTAINER_CACHEDIR"
mkdir -p "$APPTAINER_TMPDIR"
chmod -R 700 "$HOME/.apptainer" 2>/dev/null || true
chmod 700 "$APPTAINER_TMPDIR" 2>/dev/null || true
EOF

source /etc/profile.d/apptainer.sh
echo "[OK] Apptainer environment loaded"

echo "====== Disable user namespace restrictions ======"

sudo bash -c 'echo kernel.apparmor_restrict_unprivileged_userns=0 \
  > /etc/sysctl.d/90-disable-userns-restrictions.conf'

sudo sysctl -p /etc/sysctl.d/90-disable-userns-restrictions.conf

echo "[OK] User namespace restrictions disabled"

echo "======  Verify kernel setting ======"

sudo sysctl kernel.apparmor_restrict_unprivileged_userns

echo ""
echo "============================================="
echo "     ✔ APPTAINER INSTALLATION COMPLETED"
echo "     Please logout/login to reload env"
echo "============================================="
