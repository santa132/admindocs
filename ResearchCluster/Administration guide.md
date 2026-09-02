<!-- TOC ignore:true -->

# Research GPU cluster - Administrator guide

Table of contents

<!-- TOC -->

- [User Management – Research Cluster](#user-management--research-cluster)
- [Adding User in the cluster:](#adding-user-in-the-cluster)
  - [Adding user to a queue:](#adding-user-to-a-queue)
  - [Remove a user from a queue:](#remove-a-user-from-a-queue)
  - [Reset user password](#reset-user-password)
  - [Deleting User in the cluster:](#deleting-user-in-the-cluster)
- [Set walltime of a queue:](#set-walltime-of-a-queue)
  - [Check the walltime in the HPC:](#check-the-walltime-in-the-hpc)
- [Adding storage quota for /scratch:](#adding-storage-quota-for-scratch)
  - [Assign quota of 550GB:](#assign-quota-of-550gb)
  - [Check quota of user:](#check-quota-of-user)
- [Limit number of jobs per user:](#limit-number-of-jobs-per-user)
- [Set maximum 100 number of RUNING jobs in a queue](#set-maximum-100-number-of-runing-jobs-in-a-queue)
- [Set the maximum 50 QUEUED jobs in a queue](#set-the-maximum-50-queued-jobs-in-a-queue)
- [Adding the node to a queue](#adding-the-node-to-a-queue)
- [Removing a node to the queue](#removing-a-node-to-the-queue)
- [Check job with job id:](#check-job-with-job-id)
- [Docker pull the image to HPC GPU nodes:](#docker-pull-the-image-to-hpc-gpu-nodes)
- [Docker build with tag](#docker-build-with-tag)
- [Pull singularity images:](#pull-singularity-images)
- [BEEGFS](#beegfs)

<!-- /TOC -->

## User Management – Research Cluster

The users in the research cluster is using OpenLDAP for creating users in the cluster. Users are created in OpenLDAP using script. The benefit of using OpenLDAP is that users are centrally managed in the OpenLDAP server. There is no need to create users in other servers in the cluster.

The OpenLDAP server is installed in the server SUTD-hpc-hn1. This will require admin privilege when creating /deleting users.

## Adding User in the cluster:

The script is located user `/usr/bin`. It is a shell script.
Syntax:

```bash
user_add.sh -n <username> -c <common/first name> -s <last/surname>
```

- `-n \<username\>`: the user ID to be used by the user to login to the system.
- `-c \<firstname\>`: the first name of the user
- `-s \<lastname\>`: the last name of the user

Example:

```bash
[root@SUTD-hpc-hn1 ~]# user_add.sh -n andy_ng -c Andy -s Ng
 
GROUP ID: 6514
adding new entry "cn=grp-jegant,ou=group,dc=sutd,dc=local"

--------------------
Adding dn: uid=jegant,ou=Users,dc=sutd,dc=local
changetype: add
uid: andy_ng
cn: Andy
sn: Ng
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: {SSHA}A8p2fzq34V02bPo+4cMqwsqTsI7Q4MoZ
shadowLastChange: 18360
shadowMax: 99999
shadowWarning: 7
loginShell: /bin/bash
uidNumber: 5514
gidNumber: 6514
homeDirectory: /home/users/jegant

dn: cn=grp-jegant,ou=group,dc=sutd,dc=local
changetype: modify
add: memberuid
memberuid: jegant
--------------------
adding new entry "uid=jegant,ou=Users,dc=sutd,dc=local"

modifying entry "cn=grp-jegant,ou=group,dc=sutd,dc=local"

# SUTD-hpc-hn1:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-hn1:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-hn1:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-gn1:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-gn1:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-gn1:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-gn1:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-gn1:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-gn1:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-gn2:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-gn2:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-gn2:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-gn2:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-gn2:22 SSH-2.0-OpenSSH_7.4
# SUTD-hpc-gn2:22 SSH-2.0-OpenSSH_7.4
# SUTD-Cloud-cn1:22 SSH-2.0-OpenSSH_7.4
# SUTD-Cloud-cn1:22 SSH-2.0-OpenSSH_7.4
# SUTD-Cloud-cn1:22 SSH-2.0-OpenSSH_7.4
# SUTD-Cloud-cn2:22 SSH-2.0-OpenSSH_7.4
# SUTD-Cloud-cn2:22 SSH-2.0-OpenSSH_7.4
# SUTD-Cloud-cn2:22 SSH-2.0-OpenSSH_7.4
# SUTD-Cloud-cn3:22 SSH-2.0-OpenSSH_7.4
# SUTD-Cloud-cn3:22 SSH-2.0-OpenSSH_7.4
# SUTD-Cloud-cn3:22 SSH-2.0-OpenSSH_7.4
 
Setting user quota...
Using default storage pool (1)
 
Adding of user completed without errors.
```

### Adding user to a queue:

To be able to submit jobs in the cluster, user must be added to a queue.

Syntax:

```bash
qmgr -c "set queue <QUEUE_NAME> acl_users += <USERID>"
```

Example:

```bash
qmgr -c "set queue research acl_users += andy"
qmgr -c "s q gold acl_users += 'somayeh_ebrahimkhani,vankhoa_duong,tianze_yu,guimeng_liu,sean_chenjiale'"
qmgr -c "s q gold acl_users += 'bo_wang,bo_wang1,bo_wang2,tomomasa_yamasaki,nurul_akhira'"
```

### Remove a user from a queue:

Syntax:

```bash
qmgr -c "set queue <QUEUE_NAME> acl_users -= <USERID>"
```

Example:

```bash
qmgr -c "set queue stu acl_users -= andy"
```

### Reset user password

```bash
ldappasswd -H ldap://server_domain_or_IP -x -D "cn=admin,dc=example,dc=com" -W -S "uid=bob,ou=people,dc=example,dc=com"
```

Example:

```bash
ldappasswd -H ldap://192.168.33.10 -x -D "cn=ldapadm,dc=sutd,dc=local" -W -S "uid=summer,ou=Users,dc=sutd,dc=local"
Enter new passwd: default_p@ssw0rd
Provide LDAP manager pass: SUTD_p@ssw0rd
```

### Deleting User in the cluster:

The script is located user /usr/bin. It is a shell script.
Syntax:

```bash
user_delete.sh <username>
```

Example:

```bash
user_delete.sh jegant

Deleting user: jegant
uid=5514(jegant) gid=6514(grp-jegant) groups=6514(grp-jegant)
User delete completed without errors.
```

## Set walltime of a queue:

Syntax:

```bash
qmgr -c "set queue <QUEUE_NAME> resources_max.walltime = 24:00:00"
```

Example: set walltime of “project” queue at a week

```bash
qmgr -c "set queue gold resources_max.walltime = 72:00:00"
```

### Check the walltime in the HPC:

```bash
qstat -q
```

## Adding storage quota for /scratch:

User storage quota is configured by default upon user creation. In case quota needs to be modified, follow the syntax below:
https://www.beegfs.io/wiki/EnableQuota

Syntax:

```bash
beegfs-ctl --setquota --uid <user UID> --sizelimit=550G --inodelimit=unlimited
```

Example:
Get the UID of the user:

```bash
id fcipriano

uid=5001(fcipriano) gid=501(UserGroup) groups=501(UserGroup)
```

### Assign quota of 550GB:

```bash
beegfs-ctl --setquota --uid 5001 --sizelimit=550G --inodelimit=unlimited
```

### Check quota of user:

```bash
beegfs-ctl --getquota --uid 5593
```

## Limit number of jobs per user:

To be able to submit jobs in the cluster, user must be added to a queue:
Syntax:

```bash
qmgr -c "set server max_queued = [u:PBS_GENERIC=<NUM_JOBS>]"
```

Example: Limit to 3 jobs per user

```bash
qmgr -c "set server max_queued = [u:PBS_GENERIC=3]"
```

## Set maximum 100 number of RUNING jobs in a queue

```bash
qmgr -c "s q <queuename> max_run = [o:PBS_ALL=100]"
```

## Set the maximum 50 QUEUED jobs in a queue

```bash
qmgr -c "s q <queuename> max_queued = [o:PBS_ALL=50]"
```

## Adding the node to a queue

1. Determine the Qlist name of the queue
   ```bash
   qmgr -c "p s" |grep <queuename>
   ```

  Locate the parameter `resources_available.Qlist = <Qlistname>`

- The `<Qlistname>` will be the name that we will be assigning to the node.

2. Assign a node to the queue

   ```bash
   qmgr -c "s n <nodename> resources_available.Qlist += <Qlistname>"
   ```
3. Check if the node is assigned to the queue by running:

   ```bash
   pbsnodes <nodename>
   ```

   Check if the parameter: `resources_available.Qlist = <Qlistname>` is assigned to the node.

## Removing a node to the queue

```bash
qmgr -c "s n <nodename> resources_available.Qlist =- <Qlistname>"
```

```bash
qmgr -c "s n SUTD-hpc-gn2 resources_available.Qlist -= research_vn"
```

Check if the parameter: `resources_available.Qlist = <Qlistname>` is removed.

## Check job with job id:

```bash
qstat -f -p 12335
pbsnodes -r sutd-hpc-gn2
```

## Docker pull the image to HPC GPU nodes:

SSH to the GPU nodes (192.168.33.13-SUTD-HPC-GN1, 192.168.33.14-SUTD-HPC-GN2)

```bash
Authentication: 
docker login nvcr.io
Username: $oauthtoken
Password:aHYxMXNrZnM0OWM3dWY3cjNsY2pxNHM1ams6ODdhNGY5NWMtMjM2NS00OTA1LWFjMjUtYjI3ZDNkZjU3MTAx
```

Run the pull command

```bash
docker pull nvcr.io/nvidia/tensorflow:22.06-tf2-py3
```

## Docker build with tag

```bash
docker build -t pytorch-hvd:21.02-py3 .
```

## Pull singularity images:

NGC docker image: `nvcr.io/nvidia/pytorch:22.06-py3`

1. Pull and Convert the docker image to singularity image at headnode
   ```bash
     singularity pull docker://nvcr.io/nvidia/pytorch:20.12-py3
     singularity pull ngc_pytorch_24.06-py3.sif docker://nvcr.io/nvidia/pytorch:20.12-py3
   ```
2. Move the singularity image to `/app/singularity/images/`
   Check singularity cache images:
   ```bash
   singularity cache list -v
   ```

Pip install:

```bash
/usr/local/bin/pip install -r requirements.txt
/opt/conda/bin/pip install -r requirements.txt
/opt/conda/bin/python test.py
```

Docker shared memory
`/etc/docker/daemon.json`

```
    "default-shm-size": "256G",
    "default-ulimits": {
             "memlock": { "name":"memlock", "soft":  -1, "hard": -1 },
             "stack"  : { "name":"stack", "soft": 67108864, "hard": 67108864 }
    } 
```

```bash
systemctl reload docker.service
```

Config new node:

```bash
qmgr -c "active node aimc-gna1"
qmgr -c "create node aimc-gna1"
qmgr -c "set node aimc-gna1 resources_available.ngpus=8"
qmgr -c "set node aimc-gna1 resources_available.ncpus=70"
qmgr -c "s n aimc-gna1 resources_available.Qlist = "a100_vn""
qmgr -c "delete node aimc-gna1"
```

Create new queue:
Create new queue name in PBS control web portal

```bash
qmgr -c "create queue blackout1"
qmgr -c "s q blackout1 queue_type = execution"
qmgr -c "s q blackout1 enabled = True"
qmgr -c "s q blackout1 started = True"
qmgr -c "s q blackout1 priority = 1"
qmgr -c "s q blackout1 default_chunk.Qlist = blackout1_vn"
qmgr -c "s n SUTD-hpc-gn2 resources_available.Qlist -= blackout1_vn"
qmgr -c "s q blackout1 max_queued = [u:PBS_GENERIC=4]"
qmgr -c "s q blackout1 max_queued_res.ngpus = [u:PBS_GENERIC=8]"
qmgr -c "s q blackout1 max_queued_res.ncpus = [u:PBS_GENERIC=40]"
qmgr -c "s q blackout1 max_queued_res.mem = [u:PBS_GENERIC=500gb]"
qmgr -c "s q blackout1 resources_max.walltime = 72:00:00"
qmgr -c "s q blackout1 resources_default.walltime = 24:00:00"
qmgr -c "s q blackout1 acl_user_enable = True"
qmgr -c "s q blackout1 acl_users += andy_ng"
qmgr -c "s q gold max_queued += "[u:andy=5]"
qmgr -c "s q blackout1 max_queued = [g:PBS_GENERIC=4]"
qmgr -c "s q blackout1 max_queued = [g:ernest=4]"
qmgr -c "s q blackout1 max_run = [g:ernest=4]"
qmgr -c "s q blackout1 max_run_res.ngpus = [g:ernest=16]"
```

Clear GPU memory:

```bash
sudo nvidia-smi --gpu-reset -i 7
fuser -k /dev/nvidia[GPUID]
```

Check current output of PBS job at running node:

```bash
/var/spool/pbs/spool/job_id.SUTD-hpc-hn1.OU
/var/spool/pbs/undelivered/job_id.SUTD-hpc-hn1.OU
```

# Home directory backup

```bash
crontab -e 
```

or

Create contab config file at `/var/spool/cron/root`

Run cron job to backup home directore daily at 2am.

```bash
0 2 * * * /mnt/beegfs/adm/home-bak.sh daily
```

# Delete unused file at /raid or /local_data 60 days

```bash
find /local_data/sage-9.2 -ctime +60 -exec rm -rf {} +
```

## BEEGFS

Check uid of a user

```bash
id username
```

Query quota of a user

```bash
beegfs-ctl --getquota --uid username
```
