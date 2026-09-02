# Install KVM (Kernel-based Virtual Machine) on Ubuntu Server 22.04
## Requirement of VM
- Ubuntu Server 22.04
- Name convension: aimc-ven[1/2/3/4]
  - ven: virtual education node

## Update and install dependencies
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install bridge-utils qemu-kvm virtinst libvirt-daemon virt-manager -y
```
- Check KVM
```bash
aimc@aimc-en1:~$ kvm-ok
INFO: /dev/kvm exists
KVM acceleration can be used
```

- Check `libvirtd.service`
```bash
aimc@aimc-en1:~$ sudo systemctl status libvirtd.service 
[sudo] password for aimc: 
● libvirtd.service - Virtualization daemon
     Loaded: loaded (/lib/systemd/system/libvirtd.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2023-06-13 03:40:55 UTC; 1 day 23h ago
TriggeredBy: ● libvirtd-admin.socket
             ● libvirtd-ro.socket
             ● libvirtd.socket
       Docs: man:libvirtd(8)
             https://libvirt.org
   Main PID: 2806 (libvirtd)
      Tasks: 23 (limit: 32768)
     Memory: 56.8M
        CPU: 13.964s
     CGroup: /system.slice/libvirtd.service
             ├─2806 /usr/sbin/libvirtd
             ├─3157 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/br0.conf --leasefile-ro --dhc>
             └─3158 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/br0.conf --leasefile-ro --dhc>

Jun 13 03:40:56 aimc-en1 dnsmasq[3157]: reading /etc/resolv.conf
Jun 13 03:40:56 aimc-en1 dnsmasq[3157]: using nameserver 127.0.0.53#53
Jun 13 03:40:56 aimc-en1 dnsmasq[3157]: read /etc/hosts - 7 addresses
Jun 13 03:40:56 aimc-en1 dnsmasq[3157]: read /var/lib/libvirt/dnsmasq/br0.addnhosts - 0 addresses
Jun 13 03:40:56 aimc-en1 dnsmasq-dhcp[3157]: read /var/lib/libvirt/dnsmasq/br0.hostsfile
Jun 13 03:40:56 aimc-en1 libvirtd[2806]: libvirt version: 8.0.0, package: 1ubuntu7.5 (Marc Deslauriers <>
Jun 13 03:40:56 aimc-en1 libvirtd[2806]: hostname: aimc-en1
Jun 13 03:40:56 aimc-en1 libvirtd[2806]: Tried to update an unsupported keyword YA: skipping.
Jun 13 03:40:56 aimc-en1 libvirtd[2806]: Tried to update an unsupported keyword YA: skipping.
```

## Config KVM network in the native machine
- Create a kvm folder
```bash
mkdir /mnt/local/kvm -p
cd /mnt/local/kvm
```
- Copy some necessary files
```bash
cd /mnt/adm/kvm
cp br0.xml create_vm.sh ubuntu-22.04.2-live-server-amd64.iso /mnt/local/kvm
```

- `br0.xml` file
```xml
<network>
  <name>br0</name>
  <uuid>427c954b-4993-4554-bb1d-79d99882a9a6</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='br0' stp='on' delay='0'/>
  <mac address='52:54:00:0d:ff:76'/>
  <ip address='172.20.0.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='172.20.0.2' end='172.20.0.254'/>
    </dhcp>
  </ip>
</network>
```

- Create network
```bash
virsh net-define br0.xml
virsh net-start br0
virsh net-autostart br0
```

- Check network
```bash
aimc-hpc-gn4@aimc-hpc-gn4:~/kvm$ virsh net-list
 Name   State    Autostart   Persistent
-----------------------------------------
 br0    active   yes         yes
```

- These next commands will delete the default private network, this is not required but you can if you prefer to delete it.
```bash
virsh net-destroy default
virsh net-undefine default
```

- Restart  libvirt daemon
```bash
sudo systemctl restart libvirtd.service
```

## Create VMs
### Download image (Skip this step if you have copied from NFS)
- Download OS image
- Copy downloaded image to `/mnt/local/kvm`

### Create script to create VM
- Create an `images` folder
```bash
sudo mkdir -p /mnt/local/kvm/images
sudo chown libvirt-qemu:kvm /mnt/local/kvm/images
```
- Script to import VM from existing images, i.e. import_ven4.sh, -> not work
```bash
sudo virt-install --name ven5 \
--os-variant ubuntu22.04 \
--vcpus 35 \
--memory 215040 \
--disk /mnt/local/kvm/images/aimc-ven5.qcow2,format=qcow2,bus=virtio,size=250 \
--network bridge=br0,model=virtio \
--network bridge=br1,model=virtio \
--network bridge=br2,model=virtio \
--graphics vnc \
--extra-args='console=ttyS0,115200n8 --- console=ttyS0,115200n8' \
--debug \
--import
```

- Script to create new VM
```bash
sudo virt-install \
--name ven1 \
--os-variant ubuntu22.04 \
--vcpus 35 \
--memory 215040 \
--location /mnt/local/kvm/ubuntu-22.04.2-live-server-amd64.iso,kernel=casper/vmlinuz,initrd=casper/initrd \
--disk /mnt/local/kvm/images/ven1.qcow2,size=250 \
--network bridge=br0,model=virtio \
--network bridge=br1,model=virtio \
--network bridge=br2,model=virtio \
--graphics vnc \
--extra-args='console=ttyS0,115200n8 --- console=ttyS0,115200n8' \
--debug
```

- Please change the appropriate name in the script (arguments: `--name` and `--disk`)
- This will waiting for finishing installtion from GUI
- Note for resource: en1&2: 80cpu, 512 memory, 
  + 16 GB profile x 8pcs: 35 vCPU, memory 215040, disk 250GB -> 36 vCPU
  + 8 GB profile x 12pcs: 28 vCPU, memory 215040, disk 250GB
  + 8 GB profile x 12pcs: 18 vCPU, memory 174080, disk 250GB ???
  How to check? 
  virsh dominfo aimc-ven2 | grep CPU

- Set autostart after boot:
```bash
virsh autostart aimc-ven5
```

### Open VNC to setup
- Create an SSH tunnel
```bash
ssh aimc-en1@192.168.33.16 -NfL 5900:127.0.0.1:5900
```

- Download VNC from https://www.realvnc.com/en/connect/download/viewer/
- Install
- Open VM using this URL: 127.0.0.1:5900
- Install as normal installation


### Finish create a new VM
- After choosing `Reboot`, open another terminal and SSH to the native machine (`aimc-en1` in this case)
  - Go in the console: `virsh console ven1`
  - Press `Enter` to reboot the VM
  - Press `Ctrl` + `]` to exit

## Setup network for VM
- Create and edit the config file
```bash
vi /etc/netplan/00-installer-config.yaml
```

- Choose the IP address from `x.x.x.[100 + VM ID]`
```yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    enp1s0:
      addresses:
      - 172.20.0.101/24
      nameservers:
        addresses: []
        search: []
      routes:
      - to: default
        via: 172.20.0.1
    enp2s0:
      addresses:
      - 172.16.0.101/24
      nameservers:
        addresses:
        - 192.168.2.100
        - 192.168.2.101
        search: []
      routes:
      - to: default
        via: 172.16.0.15
    enp20s0:
        addresses:
        - 192.168.33.101/24
        nameservers:
          addresses:
          - 192.168.2.100
          - 192.168.2.101
          search: []
        routes:
          - to: default
            via: 192.168.33.1
  version: 2
```

- Apply change
```bash
sudo netplan generate
sudo netplan apply
```
### Create mouting point


## References
- https://www.wpdiaries.com/kvm-on-ubuntu/
- https://www.wpdiaries.com/ubuntu-on-kvm/
- https://deploy.equinix.com/developers/guides/kvm-and-libvirt
