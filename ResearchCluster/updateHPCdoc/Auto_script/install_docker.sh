#!/bin/bash
set -e  # stop script immediately if a command fails

echo "=== 🕐 Docker installation started at $(date) ==="

# ------------------------------------------------------------
# 1️⃣ Remove old Docker versions
# ------------------------------------------------------------
echo "[1/5] Removing old Docker installations..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

# ------------------------------------------------------------
# 2️⃣ Install required dependencies
# ------------------------------------------------------------
echo "[2/5] Installing prerequisite packages..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# ------------------------------------------------------------
# 3️⃣ Add Docker GPG key and repository
# ------------------------------------------------------------
echo "[3/5] Adding Docker GPG key and repository..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# ------------------------------------------------------------
# 4️⃣ Install Docker Engine (28.4.0 or latest)
# ------------------------------------------------------------
echo "[4/5] Installing Docker Engine..."
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# If you want exactly 28.4.0, uncomment below:
# sudo apt-get install -y docker-ce=5:28.4.0-1~ubuntu.24.04~noble \
#   docker-ce-cli=5:28.4.0-1~ubuntu.24.04~noble

# ------------------------------------------------------------
# 5️⃣ Verify Docker installation
# ------------------------------------------------------------
echo "[5/5] Verifying Docker installation..."
docker --version || echo "⚠️  Docker not found in PATH yet!"
echo "---------------------------------------------"
docker version || echo "⚠️  Docker service may not be running."
echo "---------------------------------------------"

echo "✅ Docker Engine installation completed successfully!"
echo "=== 🕓 Finished at $(date) ==="
