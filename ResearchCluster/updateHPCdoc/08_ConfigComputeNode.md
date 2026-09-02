## `Config SSH passwordless`
- Config in compute node
```
cd /mnt/beegfs/adm/
```

- Edit user allowed to login withou password in: 
```
users_ssh_list.txt
```
- Run file:
```
./setup_ssh_no_pass_multiHN.sh
```

## `Create Symlink`

- No need to create folder scratch, app
```
ln -s /mnt/beegfs/scratch /scratch
ln -s /mnt/beegfs/app /app
```

## `Grant permission to run docker container`
```
ls -l /opt/pbs/sbin | grep pbs_container 
cd /opt/pbs/sbin

chgrp docker pbs_container 
chmod 2755 pbs_container 
sudo systemctl restart pbs
sudo systemctl status pbs
qstat -Bf
```

## `Mount Nas to node` 
- List all disk and mount point
```
df -h
```
```
sudo apt update
sudo apt install -y nfs-common
mkdir -p /home/users
mkdir -p /adm
```

- Edit file 
```
sudo nano /etc/fstab

172.16.0.22:/mnt/tank/hpcc  /home/users  nfs  defaults  0 0
172.16.0.22:/mnt/tank/adm /adm    nfs    defaults      1 2
```

- Apply mount command in file
```
sudo mount -a
systemctl daemon-reload
```