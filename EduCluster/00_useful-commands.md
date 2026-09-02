# Version compatible
- Ubuntu 22.04, kernel `5.15.0-94-generic` (kernel version should be `92` or `94`)
- vGPU NVIDIA version: `NVIDIA-GRID-Ubuntu-KVM-525.85.07-525.85.05-528.24`
- Network driver: `MLNX_OFED_LINUX-5.4-3.6.8.1-ubuntu22.04-x86_64.iso`
- Moodle version: `4.2.8+ (Build: 20240726)`, branch: `402`
- Kubenetes: Client/Server - `v1.30.3`

# Default instructor account
- instructor@192.168.33.183 / Default_p@ssw0rd

# Usefull commands
## KVM
- List all VMs
```bash
virsh list --all
```

- Start VM
```bash
virsh start vUbuntu2204
```

- Set autostart after boot:
```bash
virsh autostart aimc-ven4
```

- Shutdown VM
```bash
virsh shutdown vUbuntu2204
```

- Force to shutdown
```bash
virsh destroy vUbuntu2204
```

- List all IP address
```bash
virsh net-dhcp-leases br0
```

- Access serial terminal
  - To exit: Ctrl + ]
```bash
virsh console vUbuntu2204
```

- Remove VM and delete its storage
```bash
virsh undefine ven7 --remove-all-storage
```

- Change VM name
```bash
virsh domrename ven1 ven2
```

- Check state
```bash
virsh domstate ven1
```

- Export config
```bash
virsh dumpxml aimc-ven5 > aimc-template.xml
```

- Check virtual disk
```bash
virsh domblklist aimc-ven5
```

- Define new VM
```bash
virsh define aimc-template.xml
```
NOTE: If it reports the error that the CPU is not compatible with host CPU, then the CPU of the VM needs to be modified. Replace CPU configuration with `<cpu mode='host-passthrough' check='none'/>`
  ```bash
  virsh edit guest_name
  ```

- Clone VM:
```bash
virt-clone --original ven7 --name ven8  --file /mnt/local/kvm/images/ven8.qcow2
```

- Update vGPU device xml list
```xml
    <hostdev mode='subsystem' type='mdev' managed='no' model='vfio-pci' display='off'>
      <source>
        <address uuid='26216876-d01a-4eed-b06d-341abcf4da00'/>
      </source>
    </hostdev>
```

## Change hostname
```bash
sudo nano /etc/hostname

sudo nano /etc/hosts

sudo hostname aimc-ven5

sudo nano /etc/netplan/00-installer-config.yaml

reboot
```

## To prevent a node from scheduling new pods use:
```bash
kubectl cordon <node-name>

# check node status -> SchedulingDisabled
kubectl get nodes aimc-ven1

# Back
kubectl uncordon <node-name>
```

## Resize VM disk
### On host
```bash
ls -al /mnt/nfs-en2/kvm/images/ven1.qcow2 
sudo qemu-img info  /mnt/local/kvm/images/aimc-ven5.qcow2
sudo qemu-img resize  /mnt/local/kvm/images/ven1.qcow2 +50G
sudo qemu-img info  /mnt/local/kvm/images/ven1.qcow2
sudo fdisk -l /mnt/local/kvm/images/ven1.qcow2
```

### On VM
```bash
lsblk
sudo pvs
sudo apt install cloud-guest-utils
sudo growpart /dev/vda 3
sudo lsblk 
sudo pvresize /dev/vda3
sudo vgs
sudo lvextend -r -l +100%FREE  /dev/mapper/ubuntu--vg-ubuntu--lv
sudo resize2fs  /dev/mapper/ubuntu--vg-ubuntu--lv
df -hT | grep mapper
```

## Generate ssh key
```bash
ssh-keygen -t rsa
```

# NFS
- if you cannot mount the nfs, try to add `ip route`
```bash
ip route add 172.0.0.0/8 via 172.20.0.1 dev enp1s0
showmount -e  172.16.0.15
mount 172.16.0.15:/mnt/nfs-en2/ /mnt/nfs
ls /mnt/nfs/
```

# Kube debug
```bash
# Nodes
kubectl get nodes --all-namespaces -o wide

# Pods
kubectl get pods -n hub -o wide

# Services
kubectl get services --all-namespaces

# Describe
kubectl describe pod <pod_name> -n hub

# Log
kubectl logs <pod_name> -n hub

# Create a new token
kubeadm token create --print-join-command

# Restart a namespaces
kubectl -n kube-system rollout restart deploy
```

# Check port
```bash
sudo lsof -i tcp
sudo netstat -ntlp
nc -z -v 172.16.0.15 8081
```

# NOTE
- If the pod is failed to pull new images, there may be have an issues of full disk --> Resize VM disk

# Helm
```bash
helm show values jupyterhub/jupyterhub > values.yaml
```

# Install K9S
- Check newer version at [https://github.com/derailed/k9s/releases](https://github.com/derailed/k9s/releases)
```bash
wget https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.deb
sudo dpkg -i k9s_linux_amd64.deb
```