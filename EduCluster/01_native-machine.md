# Install new OS
## Requirement
- Ubuntu Server 22.04
- Name convension: aimc-en[1/2/3/4]
  - en: education node

### Enable virtualization in BIOS
- Choose **"Virtualization - High performace"** mode

## Download and install Ubuntu
- Download and install Ubuntu on the native machine

## Set up networking
### Edit 00-config.yaml
```yaml
network:
  ethernets:
    eno1:
      addresses:
      - 192.168.33.16/24
      nameservers:
        addresses:
        - 192.168.2.100
        - 192.168.2.101
      #routes:
      #- to: default
      #  via: 192.168.33.1
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
#    ens11np0:
#      dhcp4: true
#    ens12np0:
#      dhcp4: true
  version: 2
```
### Create a bridge `br2` (1G network) and a bridge `br1` (100G network)
- Create a new file `/etc/netplan/01-netcfg.yaml`
```yaml
network:
  ethernets:
    ens11np0:
      dhcp4: false
      dhcp6: false
    ens12np0:
      dhcp4: false
      dhcp6: false
    eno1:
      dhcp4: false
      dhcp6: false
  bonds:
    bond0:
      dhcp4: false
      interfaces: [ens11np0, ens12np0]
      parameters:
        mode: balance-tlb
        mii-monitor-interval: 100
  version: 2
  bridges:
    br1:
      dhcp4: false
      dhcp6: false
      interfaces: [ bond0 ]
      addresses: [172.16.0.17/24]
      nameservers:
        addresses: [8.8.8.8, 192.168.2.100,192.168.2.101]
      routes:
        - to: default
          via: 172.16.0.15
      mtu: 1500
      parameters:
        stp: true
        forward-delay: 4
    br2:
      dhcp4: false
      dhcp6: false
      interfaces: [ eno1 ]
      addresses: [192.168.33.17/24]
      nameservers:
        addresses: [192.168.2.100,192.168.2.101]
      mtu: 1500
      parameters:
        stp: true
        forward-delay: 4
```

- Apply change
```bash
sudo netplan generate
sudo netplan apply
```

## Install Kernel and Set GRUB Default Kernel
Install the default kernel:
```bash
apt install linux-image-5.15.0-94-generic linux-headers-5.15.0-94 linux-headers-5.15.0-94-generic linux-modules-5.15.0-94-generic linux-modules-extra-5.15.0-94-generic linux-tools-5.15.0-94-generic
apt install linux-image-5.15.0-92-generic linux-headers-5.15.0-92 linux-headers-5.15.0-92-generic linux-modules-5.15.0-92-generic linux-modules-extra-5.15.0-92-generic linux-tools-5.15.0-92-generic
apt list linux-* |grep 5.15.0-94 # check if 6 packages have state [installed]
dpkg --list | grep linux-image
grep 'menuentry' /boot/grub/grub.cfg | cut -d "'" -f2
```
1.List current kernel
```bash
linux-version list
```

2.Set the GRUB default kernel with timeout at /etc/default/grub
```
GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 5.15.0-92-generic"
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=10
```

3.Update grub
   ```bash
   sudo update-grub
   ```
4.Reboot

## Generate ssh key
```bash
ssh-keygen -t rsa
```

## Mount NFS folder and local folder
- Install NFS client
```bash
sudo apt install nfs-common
```

- Create folders
```bash
sudo mkdir -p /mnt/nfs
sudo mkdir -p /mnt/local
```
- Edit `fstab` file: `sudo vi /etc/fstab`
```bash
/dev/sdb /mnt/local ext4 defaults 0 0
172.16.0.15:/mnt/nfs-ehn1/   /mnt/nfs  nfs  defaults 1 2
172.16.0.22:/mnt/tank/edu   /mnt/nas  nfs  defaults 1 2
172.16.0.22:/mnt/tank/adm   /mnt/adm  nfs  defaults 1 2
```
- Remount
```bash
sudo mount -av
```

## Add local docker registry
- `sudo vi /etc/hosts`
```
192.168.33.30 aimc.registry hub.aimc.local
```

# Set up network card driver
- Guide: https://docs.nvidia.com/networking/display/mlnxofedv543750lts/installing+mlnx_ofed
https://docs.nvidia.com/networking/display/mlnxofedv543681lts
- Download `mlnx_ofed`: https://network.nvidia.com/products/infiniband-drivers/linux/mlnx_ofed/

```bash
wget https://content.mellanox.com/ofed/MLNX_OFED-5.4-3.6.8.1/MLNX_OFED_LINUX-5.4-3.6.8.1-ubuntu22.04-x86_64.iso

or Copy network driver from local admin folder to node
```bash
aimc@ehn$ scp /mnt/adm/network-driver/MLNX_OFED_LINUX-5.4-3.6.8.1-ubuntu22.04-x86_64.iso aimc@aimc-en2:~/
```

- Install
```bash
sudo -i

$ mount -o ro,loop /mnt/local/network-driver/MLNX_OFED_LINUX-5.4-3.6.8.1-ubuntu22.04-x86_64.iso /mnt
$ cd /mnt
$ ./mlnxofedinstall --force
# $ ./mlnxofedinstall --without-dkms --add-kernel-support --kernel 5.15.0-94-generic --without-fw-update --force

To load the new driver, run:
$ /etc/init.d/openibd restart

$ umount /mnt

Check driver installation:
$ ofed_info -s
MLNX_OFED_LINUX-5.4-3.6.8:
```
- Start driver: no need
```bash
mst start
systemctl enable mst.service

Check driver name at /dev/mst/
mt4115_pciconf0 and mt4115_pciconf1

Change IB interface0 to Ethernet:
mlxconfig -y -d /dev/mst/mt4115_pciconf0 set LINK_TYPE_P1=2
mlxconfig -y -d /dev/mst/mt4115_pciconf1 set LINK_TYPE_P1=2
```

## Setup **bonding**
  - Ref: https://www.server-world.info/en/note?os=Ubuntu_22.04&p=bonding

- Check hardware
```bash
sudo lshw -C network
```
- Install: just run "netplan apply"
```bash
ifconfig ens11f0np0 down
ifconfig ens12f0np0 down

ip link add bond0 type bond mode 802.3ad

ip link set ens11f0np0 master bond0
ip link set ens12f0np0 master bond0
```
- Edit/Create a config file
```bash
nano /etc/netplan/01-netcfg.yaml
```

```yaml
network:
  ethernets:
    ens11f0np0:
      dhcp4: false
      dhcp6: false
    ens12f0np0:
      dhcp4: false
      dhcp6: false
  bonds:
    bond0:
      addresses: [172.16.0.20/24]
      routes:
        - to: default
          via: 172.16.0.1
          metric: 100
      nameservers:
        addresses:
          - "192.168.2.100"
          - "192.168.2.101"
      interfaces:
        - ens11f0np0
        - ens12f0np0
      parameters:
        mode: balance-tlb
        mii-monitor-interval: 100
  version: 2
```
  - Another version
    ```yaml
    network:
    ethernets:
      ens11:
        dhcp4: false
        dhcp6: false
      ens12:
        dhcp4: false
        dhcp6: false
    bonds:
      bond0:
        dhcp4: false
        interfaces:
          - ens11
          - ens12
        parameters:
          mode: balance-tlb
          mii-monitor-interval: 100
    version: 2
    bridges:
      br1:
        dhcp4: false
        dhcp6: false
        interfaces: [ bond0 ]
        addresses: [172.16.0.15/24]
        nameservers:
          addresses: [192.168.2.100,192.168.2.101]
        routes:
          - to: default
            via: 172.16.0.1
        mtu: 1500
        parameters:
          stp: true
          forward-delay: 4
      br2:
        dhcp4: false
        dhcp6: false
        interfaces: [ eno1 ]
        addresses: [192.168.33.15/24]
        nameservers:
          addresses: [192.168.2.100,192.168.2.101]
        routes:
          - to: default
            via: 192.168.33.1
        mtu: 1500
        parameters:
          stp: true
          forward-delay: 4
    ```

- Apply change
```bash
netplan apply
```

- Check
```bash
# after setting bonding, [bonding] is loaded automatically
lsmod | grep bond

ip address show
ethtool bond0
```

## NFS server Setup
- Create a new mount point
```bash
sudo mkdir /mnt/nfs-ehn1
```
- Add line `/dev/sdb /mnt/nfs-ehn1 ext4 defaults 0 0` in `/etc/fstab`

- Install NFS server
```bash
sudo apt install nfs-kernel-server
sudo chown nobody:nogroup /mnt/nfs-ehn1
```

- Edit exports `sudo nano /etc/exports`
```bash
/mnt/nfs-ehn1/      172.16.0.0/24(rw,sync,no_subtree_check,no_root_squash,no_all_squash,insecure)
```

- Restart NFS server
```bash
sudo systemctl restart nfs-kernel-server
```
