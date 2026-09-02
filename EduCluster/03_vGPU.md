# Install vGPU on VM based on KVM
## Dependencies
```bash
sudo apt install unzip
```

## Download driver
- Download package NVIDIA-GRID-Ubuntu-KVM-525.85.07-525.85.05-528.24.zip
- Create token for licensing
- Extract
```bash
mkdir -p ~/vGPU
unzip NVIDIA-GRID-Ubuntu-KVM-525.85.07-525.85.05-528.24.zip -d vGPU
```

- Or access the NFS folder
```bash
/mnt/nfs/vGPU
```

## Remove current NVIDIA driver if existing
```bash
bash /mnt/beegfs/compile_dir/NVIDIA-Linux-x86_64-450.216.04.run --uninstall
dpkg -l | grep -i nvidia
sudo apt-get remove --purge '^nvidia-.*'
```

## Install host driver
### Disable Nouveau and enable nvfio
```bash
echo -e "vfio\nvfio_iommu_type1\nvfio_pci\nvfio_virqfd" >> /etc/modules
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
update-initramfs -u -k all
```

### Disable X server
https://unix.stackexchange.com/questions/25668/how-to-close-x-server-to-avoid-errors-while-updating-nvidia-driver
```bash
sudo init 3
```

### Install driver
- Ref: https://docs.nvidia.com/grid/15.0/grid-vgpu-user-guide/index.html#ubuntu-install-configure-vgpu
- Note: Should remove new kernel header when install vGPU driver, i.e. apt purge linux-headers-5.15.0-134 linux-headers-5.15.0-134-generic & apt reinstall .deb
```bash
cd /mnt/local/vGPU/Host_Drivers
sudo apt install ./nvidia-vgpu-ubuntu-525_525.85.07_amd64.deb
reboot
```

### Configuring vGPU [Deprecated]
- Check domain/bus/slot/function
```bash
aimc@aimc-en1:~$ lsmod | grep vfio
nvidia_vgpu_vfio       65536  272
mdev                   28672  1 nvidia_vgpu_vfio

aimc@aimc-en1:~$ lspci | grep NVIDIA
89:00.0 3D controller: NVIDIA Corporation GV100GL [Tesla V100 SXM2 32GB] (rev a1)
8a:00.0 3D controller: NVIDIA Corporation GV100GL [Tesla V100 SXM2 32GB] (rev a1)
b2:00.0 3D controller: NVIDIA Corporation GV100GL [Tesla V100 SXM2 32GB] (rev a1)
b3:00.0 3D controller: NVIDIA Corporation GV100GL [Tesla V100 SXM2 32GB] (rev a1)

aimc@aimc-en1:~$ virsh nodedev-list --cap pci | grep 89_00_0
pci_0000_89_00_0

aimc@aimc-en1:~$ virsh nodedev-dumpxml pci_0000_89_00_0 | egrep 'domain|bus|slot|function'
    <domain>0</domain>
    <bus>137</bus>
    <slot>0</slot>
    <function>0</function>
```

### Creating vGPU
- Change to root user
```bash
sudo -i
```

- Seach nvidia profile
```bash
cd /sys/bus/pci/devices/0000:89:00.0/mdev_supported_types
grep -l "V100DX-16Q" nvidia-*/name
```
  - The output:
    ```bash
    nvidia-198/name
    ```
  - `8Q` - 8G/vGPU
  - `16Q` - 16G/vGPU

- Check available instances, the result should be greater than 0
```bash
cat nvidia-198/available_instances
```

- Generate uuid for the vGPU
```bash
# uuidgen
b87b1cd3-feb8-4ca6-88af-33b3c9f81425
```

- Write the UUID that you obtained in the previous step to the `create` file in the registration information directory for the vGPU type that you want to create 
```bash
echo "b87b1cd3-feb8-4ca6-88af-33b3c9f81425" > nvidia-198/create
```

- Make the mdev device file that you created to represent the vGPU persistent.
```bash
mdevctl define --auto --uuid b87b1cd3-feb8-4ca6-88af-33b3c9f81425
```

- Confirm that the vGPU was created
```bash
ls -l /sys/bus/mdev/devices/
```
or
```bash
mdevctl list
```

### Create all vGPU
```bash
cd /mnt/nfs/vGPU
sudo ./aimc-create-all-vgpus.sh -r 8
```
- `-r 16`: choose 16GB of vGPU memory

### List all UUID, i.e. en2
```bash
mdevctl list
45bcff4f-1773-4bec-a238-98df2589cca5 0000:3a:00.0 nvidia-198 (defined)
2eb08099-9437-4571-b101-2d9717648458 0000:3a:00.0 nvidia-198 (defined)
3ad93036-167d-4afd-9761-4cae31bdacbb 0000:3b:00.0 nvidia-198 (defined)
9b4f28fb-83b0-4abe-b6b1-df3172290bd8 0000:3b:00.0 nvidia-198 (defined)
866a8856-050e-4370-ab1c-77a6f3ba2e01 0000:8a:00.0 nvidia-198 (defined)
b087a78c-3023-458b-922c-3f4e9161cef6 0000:8a:00.0 nvidia-198 (defined)
b3af98c8-13f8-4d16-a840-7ab7d5576d53 0000:89:00.0 nvidia-198 (defined)
50cf5949-da29-4d63-a2c4-0f7981c171fe 0000:89:00.0 nvidia-198 (defined)
0e54a858-c280-432f-b310-ad4e64c8331c 0000:15:00.0 nvidia-198 (defined)
0325e643-6d4b-432f-9541-c1fd31ef98fa 0000:16:00.0 nvidia-198 (defined)
1b7e069c-4bdb-47f5-951c-96a819ab2978 0000:16:00.0 nvidia-198 (defined)
f37c908c-8e49-445c-94a2-6227651a6719 0000:15:00.0 nvidia-198 (defined)
d8a20d40-eb74-4081-8710-015c0b34027a 0000:b2:00.0 nvidia-198 (defined)
78df747f-8b11-4f33-8c9b-8b7222d1867d 0000:b2:00.0 nvidia-198 (defined)
c321c0fc-3450-4adb-8097-51e014ea8e2a 0000:b3:00.0 nvidia-198 (defined)
8c7a8344-ffb1-4a5e-9a20-87b4402e222e 0000:b3:00.0 nvidia-198 (defined)
```
### Generate vGPU xml file
```bash
./mnt/local/vGPU/vGPU_generate_xml.sh
```

## Adding One or More vGPUs to a Linux with KVM Hypervisor VM by Using virsh
Note: keep same vGPU under a GPU to avoid performance reduction
```bash
virsh edit ven1
```

- Add device entries
```xml
<device>
...
    <hostdev mode='subsystem' type='mdev' model='vfio-pci'>
      <source>
        <address uuid=''/>
      </source>
    </hostdev>
    <hostdev mode='subsystem' type='mdev' model='vfio-pci'>
      <source>
        <address uuid=''/>
      </source>
    </hostdev>
</device>
```

- Start/Restart the VM
```bash
virsh start ven1
```

## Install Guest driver in VM
### Check the ip of VM
```bash
aimc@aimc-en1:/mnt/nfs/vGPU$ virsh list --all
 Id   Name   State
----------------------
 2    ven1   running

aimc@aimc-en1:/mnt/nfs/vGPU$ virsh console ven1
Connected to domain 'ven1'
Escape character is ^] (Ctrl + ])

aimc@aimc-ven1:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:05:41:79 brd ff:ff:ff:ff:ff:ff
    inet 172.20.0.101/24 brd 172.20.0.255 scope global enp1s0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe05:4179/64 scope link 
       valid_lft forever preferred_lft forever
3: enp2s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:89:d9:16 brd ff:ff:ff:ff:ff:ff
    inet 172.16.0.41/24 brd 172.16.0.255 scope global enp2s0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe89:d916/64 scope link 
       valid_lft forever preferred_lft forever
4: enp20s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:51:d3:51 brd ff:ff:ff:ff:ff:ff
    inet 192.168.33.101/24 brd 192.168.33.255 scope global enp20s0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe51:d351/64 scope link 
       valid_lft forever preferred_lft forever
```

- Install SSH server
```bash
sudo apt install openssh-server
```

- Exit console: `Ctrl + ]`

- Copy ssh key
```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub aimc@172.16.0.101
```

- SSH to the VM
```bash
ssh aimc@172.16.0.101
```

- Copy NVIDIA Guest drive and token
```bash
scp /mnt/local/vGPU/Guest_Drivers/nvidia-linux-grid-525_525.85.05_amd64.deb aimc@172.16.0.108:/home/aimc
scp /mnt/local/vGPU/client_configuration_token_03-23-2023-09-07-06.tok aimc@172.16.0.108:/home/aimc
```

- Install NVIDIA driver
```bash
sudo apt install ./nvidia-linux-grid-525_525.85.05_amd64.deb
```

- Change FeatureType from 0 to 2
```bash
sudo nano /etc/nvidia/gridd.conf
```
```
# Description: Set Feature to be enabled
# Data type: integer
# Possible values:
#    0 => for unlicensed state
#    1 => for NVIDIA vGPU (Optional, autodetected as per vGPU type)
#    2 => for NVIDIA RTX Virtual Workstation
#    4 => for NVIDIA Virtual Compute Server
# All other values reserved
FeatureType=2
```

- Restart VM
```bash
sudo reboot
```

- SSH to VM
- Copy token
```bash
sudo cp client_configuration_token_03-23-2023-09-07-06.tok /etc/nvidia/ClientConfigToken/
```

- Change mode
```bash
chmod 744 /etc/nvidia/ClientConfigToken/client_configuration_token_03-23-2023-09-07-06.tok
```

- Restart nvidia-gridd deamon
```bash
sudo systemctl restart nvidia-gridd.service
```

- Test
```bash
nvidia-smi -q
```

- Rebooting the VM may save your time when the vGPU does not recognize the license
```bash
sudo reboot
```

# Issues
## vGPU Unlicensed
- If all vGPU are attached and `nvidia-smi -q` shows "Unlicensed", please check the 
permission of the `.tok` file (correct permission is `744`).

- If `nvidia-gridd.service` have an issue related to clock, please set a realtime clock
```bash
timedatectl set-ntp off
timedatectl set-time '2023-06-20 16:14:50'
systemctl restart nvidia-gridd
```
And check the status.