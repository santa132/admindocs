# Kubernetes installation
This setup is applied for both a master node and worker node

## Installation
- Install SSH
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install openssh-server ca-certificates curl gnupg lsb-release apt-transport-https -y

sudo service ssh start
```

- Disable swap and comment out the swap partition in `/etc/fstab`
```bash
sudo swapoff -a
```

- Docker installation
```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
```

- Container runtime for Kubernetes
  - Reference: https://github.com/Mirantis/cri-dockerd
```bash
cd
git clone https://github.com/Mirantis/cri-dockerd.git
#wget https://storage.googleapis.com/golang/getgo/installer_linux
#chmod +x ./installer_linux
#./installer_linux

# New Sept 2024
wget https://go.dev/dl/go1.23.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.1.linux-amd64.tar.gz

Add `export PATH=$PATH:/usr/local/go/bin` to ~/.bash_profile

source ~/.bash_profile
cd cri-dockerd
mkdir bin
go build -o bin/cri-dockerd
mkdir -p /usr/local/bin

sudo install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
sudo cp -a packaging/systemd/* /etc/systemd/system

sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service

sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
```

- Deploy GPU plugin on GPU node
  - Reference: https://github.com/NVIDIA/k8s-device-plugin#preparing-your-gpu-nodes
  - Install the `nvidia-container-toolkit`
    ```bash
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/libnvidia-container.list

    sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
    ```
  - Configure `docker`: `sudo vi /etc/docker/daemon.json`
    ```json
    {
        "default-runtime": "nvidia",
        "runtimes": {
            "nvidia": {
                "path": "/usr/bin/nvidia-container-runtime",
                "runtimeArgs": []
            }
        },
        "insecure-registries" : ["hub.aimc.local:5000","aimc.registry:5000"]
    }
    ```
  - Restart `docker`:
    ```bash
    sudo systemctl restart docker
    ```
  - Configure `containerd`: `sudo vi /etc/containerd/config.toml`
    - Comment out `disabled_plugins = ["cri"]`, and insert:
    ```
    version = 2
    [plugins]
      [plugins."io.containerd.grpc.v1.cri"]
        [plugins."io.containerd.grpc.v1.cri".containerd]
          default_runtime_name = "nvidia"

          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
            [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
              privileged_without_host_devices = false
              runtime_engine = ""
              runtime_root = ""
              runtime_type = "io.containerd.runc.v2"
              [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
                BinaryName = "/usr/bin/nvidia-container-runtime"
    ```
  - Restart `containerd`:
    ```bash
    sudo systemctl restart containerd
    ```

  - On MASTER only
    - Link: https://github.com/NVIDIA/k8s-device-plugin
    ```bash
    # OLD
    kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.0/nvidia-device-plugin.yml

    # NEW - Jul 2024
    helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
    helm repo update

    helm upgrade -i nvdp nvdp/nvidia-device-plugin \
    --namespace nvidia-device-plugin \
    --create-namespace \
    --version 0.16.1 \
    --set gfd.enabled=true
    ```
    - Configure `docker`: `sudo vi /etc/docker/daemon.json`
    ```json
    {
        "insecure-registries" : ["hub.aimc.local:5000","aimc.registry:5000"]
    }
    ```
      - Restart `docker`:
      ```bash
      sudo systemctl restart docker
      ```

- Kubernetes:
  - Reference: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
  ```bash
  # OLD
  # ONE LINE
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
  # ONE LINE
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

  # NEW - Aug 2024
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

  sudo apt-get update --allow-unauthenticated
  sudo apt-get install -y kubelet kubeadm kubectl --allow-unauthenticated
  sudo apt-mark hold kubelet kubeadm kubectl
  ```

- NFS
```bash
sudo apt install nfs-common
```

- Reboot

# Setup kube master node
These steps is set up in the master node ONLY.

- `kube` init
```bash
sudo kubeadm init --cri-socket=unix:///var/run/cri-dockerd.sock --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=172.16.0.15
```

- To check config?
```bash
sudo cat /etc/kubernetes/kubelet.conf
```
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
- Flannel network plugin:
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

- Allow pods to schedule on master:
```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## Helm installation
- Reference: https://helm.sh/docs/intro/install/
```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

# Setup new worker nodes
- Prerequisite:
  - Need internet for setup. Just be on Kube network should be ok
  - Install Ubuntu 22.04 + NVIDIA GPU driver (included with Ubuntu)
  - Install Kubernetes

- Run command on **Master**
```bash
kubeadm token create --print-join-command
```

- Reset Kube on new nodes:
```bash
sudo kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock
```
- Clear old configurations
```bash
sudo -i
kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
ip link set cni0 down
ip link delete cni0 type bridge
systemctl stop kubelet
systemctl stop docker.sock
systemctl stop docker
# iptables --flush
# iptables -tnat --flush
systemctl start kubelet
systemctl start docker
exit
```

- Run the generated command on new nodes:
  - NOTE: Note the need to add `--cri-socket=unix:///var/run/cri-dockerd.sock` to the command
```bash
sudo XXXX --cri-socket=unix:///var/run/cri-dockerd.sock
XXXX is the output of "kubeadm token create" in master node
```

- Checking
  - Run `kubectl get nodes -o wide` to get the status of all nodes
  - GPU functionality check & count:
    ```bash
    kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPUs:.status.capacity.'nvidia\.com/gpu'

    kubectl get nodes -L  nvidia.com/gpu.product -L nvidia.com/gpu.count
    ```

# Setup new VM import from clone image
- Prerequisite:
  - Need internet for setup. Just be on Kube network should be ok
  - Install Ubuntu 22.04 + NVIDIA GPU driver (included with Ubuntu)
  - Install Kubernetes

- In master node: create token:
```bash
kubectl drain aimc-ven5 --ignore-daemonsets --delete-emptydir-data
kubectl delete node aimc-ven5
```

- Worker node:
```bash
kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
ip link set cni0 down
ip link delete cni0 type bridge
ip link set flannel.1 down
ip link delete flannel.1
systemctl stop kubelet
systemctl stop docker.sock
systemctl stop docker
systemctl start kubelet
systemctl start docker

OR:
kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock
rm -rf /etc/kubernetes/ /var/lib/kubelet /var/lib/cni/ /var/lib/kubeadm/
systemctl restart containerd
```
- In Master node
```bash
kubeadm token create --print-join-command
```

- In new worker node: join
```bash
sudo kubeadm join 172.16.0.15:6443 --token xxxx 	--discovery-token-ca-cert-hash sha256:yyyy \
--cri-socket=unix:///var/run/cri-dockerd.sock
```

- Check node showed in master node: kubectl get nodes
```bash
kubectl get nodes aimc-ven5 --show-labels
kubectl describe node aimc-ven8
```

f35f824e-1f54-411d-87c6-5a8a9c776cb8 0000:8a:00.0 nvidia-198 (defined)
098c529d-d379-4ff3-b90c-1c8e85123ef9 0000:8a:00.0 nvidia-198 (defined)
2892dcab-b33d-4dbf-b6aa-e225e6691cfa 0000:15:00.0 nvidia-198 (defined)
64cc3fd5-b32c-4372-b6e1-a7df0e9a833c 0000:3a:00.0 nvidia-198 (defined)
a4380e63-27ba-47cd-aa12-6b0df1ec5f9d 0000:3a:00.0 nvidia-198 (defined)
8069a10a-a9dc-4661-93a7-36e3d20c4c5c 0000:b2:00.0 nvidia-198 (defined)
9b09167f-bb20-4e82-965e-259eb8449d50 0000:16:00.0 nvidia-198 (defined)
299961a4-dbc3-40fb-93ff-97de0ae2f6d4 0000:89:00.0 nvidia-198 (defined)
77b99ae3-6ae9-483b-9433-0b57261ce8bc 0000:89:00.0 nvidia-198 (defined)
bb2fa8d8-f916-4ef9-80bd-c30976426503 0000:b3:00.0 nvidia-198 (defined)
4949e96e-fb87-4dc5-9606-287690194d6e 0000:b2:00.0 nvidia-198 (defined)
3a0c585d-f1ad-4ff3-a666-6e906bde6646 0000:b3:00.0 nvidia-198 (defined)
72cd0326-e61b-4d82-8cf7-79823840b0c8 0000:16:00.0 nvidia-198 (defined)
801c2d39-0515-41fc-ae16-66b7246cb428 0000:3b:00.0 nvidia-198 (defined)
f395b690-722b-4159-8135-3a16569811a6 0000:3b:00.0 nvidia-198 (defined)
ebcfd1b4-83f4-4dc5-835e-09dc47049083 0000:15:00.0 nvidia-198 (defined)