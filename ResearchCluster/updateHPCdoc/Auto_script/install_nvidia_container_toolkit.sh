#!/bin/bash
set -e  # stop script on first error

echo "=== 🕐 Starting NVIDIA Container Toolkit installation at $(date) ==="

# ------------------------------------------------------------
# 1️⃣ Add NVIDIA GPG key and repository
# ------------------------------------------------------------
echo "[1/4] Adding NVIDIA GPG key and repository..."
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

# ------------------------------------------------------------
# 2️⃣ Install NVIDIA Container Toolkit
# ------------------------------------------------------------
echo "[2/4] Installing NVIDIA Container Toolkit..."
sudo apt-get update -y
sudo apt-get install -y nvidia-container-toolkit

# ------------------------------------------------------------
# 3️⃣ Configure Docker runtime for NVIDIA GPU
# ------------------------------------------------------------
echo "[3/4] Configuring Docker runtime..."
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# ------------------------------------------------------------
# 4️⃣ Verify installation
# ------------------------------------------------------------
echo "[4/4] Verifying Docker GPU runtime..."
docker info | grep -A3 Runtimes || echo "⚠️  Docker runtime info not found!"
echo "---------------------------------------------"

echo "✅ NVIDIA Container Toolkit installed successfully!"
echo "You can now test with:"
echo "   sudo docker run -it --rm --gpus all nvcr.io/nvidia/pytorch:24.06-py3 bash"

echo "=== 🕓 Finished at $(date) ==="
