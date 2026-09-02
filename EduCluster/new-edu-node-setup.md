#Install ubuntu server

# Ubuntu: Install Kernel and Set GRUB Default Kernel

## Install Kernel

Install the default kernel:

```bash
sudo apt install linux-image-generic-5.15.0-94-generic
```

1.List current kernel

```bash
linux-version list
```

2.Set the default kernel

GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 5.15.0-94-generic"
GRUB_TIMEOUT_STYLE=menu

3.Update grub

```bash
   sudo update-grub
```

4. Reboot the machine

## Fix default boot by boot-repair:

```bash
1.Open the Ubuntu ISO File.
2.Go for the Try Ubuntu & open Terminal.
3.Execute the command sudo add-apt-repository ppa:yannubuntu/boot-repair.
4.Run the command sudo apt install boot-repair
```

# Setup network

At /etc/netplan/00-config.ymal
```bash
00-config.yaml
network:
  ethernets:
    eno1:
      addresses:
      - 192.168.33.16/24
      nameservers:
        addresses: [192.168.2.100,192.168.2.101]
        search: []
      routes:
      - to: default
        via: 192.168.33.1
    eno2:
      dhcp4: true
    eno3:
      dhcp4: true
    eno4:
      dhcp4: true
    eno5:
      dhcp4: true
    eno6:
      dhcp4: true

# ens11np0:

# dhcp4: true

# ens12np0:

# dhcp4: true

  version: 2
```

# Copy network driver from admin folder to node
```bash
aimc@ehn$ scp /mnt/adm/network-driver/MLNX_OFED_LINUX-5.4-3.6.8.1-ubuntu22.04-x86_64.iso aimc-en2:~/

mount -o ro,loop /home/aimc-en2/MLNX_OFED_LINUX-5.8-2.0.3.0-ubuntu22.04-x86_64.iso /mnt
mount: /mnt: WARNING: source write-protected, mounted read-only.
```
# Clone image or bring up
```bash
virsh edit
delete vgpu
update vgpu

Fix dpkg issue
apt --fix-broken install
apt-get install -f
dpkg --configure -a
dpkg --force-all --configure -a
```