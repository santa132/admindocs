ir# Change the vGPU profile
- Shutdown the current VM
```bash
virsh shutdown ven4
```

- Delete all vGPUs
```
sudo ./aimc-delete-all-vgpus.sh
```

- Create all new vGPUs
```bash
sudo ./aimc-create-all-vgpus.sh -r 16
```

- Get all UUID vGPUs, edit the list 
TODO: combine 3 scripts into one
```bash
mdevctl list
```

- Sort vGPU UUID in order
```bash
python sort_xml.py
```

- Change vGPUs' profile of VM
```bash
virsh edit ven4
```
```xml
    <hostdev mode='subsystem' type='mdev' managed='no' model='vfio-pci' display='off'>
      <source>
        <address uuid=''/>
      </source>
    </hostdev>
```

- Start VM
```bash
virsh start ven4
```

- Console of VM
```bash
virsh console ven4
```

- Check license
```bash
nvidia-smi -q
```
- If error:
```bash
NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running.
Solve:
# get all menuentries
grep 'menuentry \|submenu ' /boot/grub/grub.cfg | cut -f2 -d "'"

# change the grub configuration
vi /etc/default/grub
from: GRUB_DEFAULT=0
to: GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 5.15.0-92-generic"

# update grub
update-grub

# reboot
reboot now

# verify
uname -r
```


- Set clock if this error is shown (`systemctl status nvidia-gridd.service`)
```bash
Failed to acquire license from api.cls.licensing.nvidia.com (Info: NVIDIA RTX Virtual Workstation - Error: Clock windback has been detected)
```
```bash
sudo timedatectl set-time '2023-06-20 03:43:06'
```

- Restart nvidia-gridd
```bash
sudo systemctl restart nvidia-gridd.service
```


- Change helm config:
Change config.yaml at /mnt/nfs/EduCluster

Check current config values:
```bash
helm get values hub --namespace hub -o yaml > current-config.yaml
```

Run
```bash
helm upgrade --cleanup-on-fail   --install hub jupyterhub/jupyterhub   --namespace hub   --create-namespace   --values config.yaml --version 2.0
```