export PBS_EXEC=/opt/pbs
export PBS_HOME=/var/spool/pbs 
export PBS_DAEMON_SERVICE_USER=root
export PBS_DATA_SERVICE_USER=pbsdata
export PBS_SERVER=SUTD-hpc-hn1

su - pbsdata -s /bin/sh -c "LD_LIBRARY_PATH=$PBS_EXEC/pgsql/lib $PBS_EXEC/pgsql/bin/psql -U pbsdata -p 15007 -d pbs_datastore"

qmgr -c 'print node @default' > nodes.new

qmgr -c 'print sched @default'

qmgr -c 'print server'

```bash
#
# Create and define scheduler default
#
create sched default
set sched sched_host = sutd-hpc-hn1
set sched sched_cycle_length = 00:20:00
set sched sched_port = 15004
set sched sched_priv = /var/spool/pbs/sched_priv
set sched sched_log = /var/spool/pbs/sched_logs
set sched scheduling = True
set sched scheduler_iteration = 600
set sched state = idle
```
 
qmgr -c "set sched default scheduling = false"
qmgr -c "set sched default scheduling = true"

# Hook (657)
qmgr -c "list hook"
qmgr -c 'export hook pbs_cgroups application/x-python default /tmp/pbs_cgroups.old2.7'
qmgr -c 'export hook intcheck application/x-python default /tmp/intcheck.old2.7'

qmgr -c 'export hook pbs_cgroups application/x-config default /tmp/pbs_cgroups.configcheck'
qmgr -c 'export hook intcheck application/x-config default /tmp/intcheck.configcheck'


qmgr -c "s h intcheck enabled=False"
qmgr -c "s h pbs_cgroups enabled=False"

qmgr -c "s h pbs_cgroups debug=true"
qmgr -c "s h pbs_cgroups enabled=true"

# Shutdown 6.5.9
qterm -t immediate -m -s

systemctl stop pbs

# Backup 6.5.10
mkdir /tmp/pbs_backup
cd $PBS_HOME/..
tar -cvf /tmp/pbs_backup/PBS_HOME_tarbackup.tar $PBS_HOME

cd $PBS_EXEC/..
tar -cvf /tmp/pbs_backup/PBS_EXEC_tarbackup.tar $PBS_EXEC

cp /etc/pbs.conf /tmp/pbs_backup/pbs.conf.backup

cp -r $PBS_HOME/sched_priv /tmp/pbs_backup/sched_priv.work

tar -xvsf PBSPro_2022.1.1-CentOS7_x86_64.tar.gz
cd PBSPro_2022.1.1/
rpm -U pbspro-server-2022.1.1.20220926110806-0.el7.x86_64.rpm

# Create/Delete node 1
qmgr -c 'print node @default'
qmgr -c "delete node SUTD-hpc-gn4[0],SUTD-hpc-gn4[1]"
qmgr -c "create node SUTD-hpc-gn4"

# Licensing server
/usr/local/altair/licensing13.3/

qstat -Bf

/etc/pbs_license/altair_lic_sutd_10Feb2020.dat

# Check license stat
cd /usr/local/altair/licensing15.2/
./bin/almutil -licstat

qmgr -c 'set server pbs_license_info=/etc/pbs_license/altair_lic_sutd_10Feb2020.dat'
qmgr -c 'set server pbs_license_info=/usr/local/altair/licensing15.2/altair_lic_sutd_10Feb2020.dat'
qmgr -c 'set server pbs_license_info=6200@SUTD-hpc-hn1'
qmgr -c "s n SUTD-hpc-gn4 resources_available.vnode = SUTD-hpc-gn4"

# Install Python 3.6.8
https://www.liquidweb.com/kb/how-to-install-python-3-on-centos-7/

# Execution node: 6.5.6
ps -ef | grep pbs

$PBS_EXEC/sbin/pbs_mom

# OpenSSL 1.1.1
https://gist.github.com/Bill-tran/5e2ab062a9028bf693c934146249e68c

# Hook
## cgroup
qmgr -c 'export hook pbs_cgroups application/x-config default' > pbs_cgroups.json
qmgr -c 'import hook pbs_cgroups application/x-config default pbs_cgroups.json'

qmgr -c 'import hook pbs_cgroups application/x-config default /tmp/pbs_cgroups.configcheck'

## PBS HPC container
qmgr -c "export pbshook PBS_hpc_container application/x-config default" > container_config.json
qmgr -c "import pbshook PBS_hpc_container application/x-config default container_config.json"
qmgr -c 'set hook PBS_hpc_container enabled = true'

qmgr -c "s n SUTD-hpc-gn4 resources_available.Qlist = 'dev_vn'"
qsub -I -l select=1:ncpus=5 -q dev
qsub -I -l select=1:ncpus=5 -q workq -v CONTAINER_IMAGE=nvcr.io/nvidia/pytorch:20.06-py3 -N docker-interactive

qmgr -c "set node SUTD-hpc-gn4 resources_available.allows_container = True"

# Altair license
```bash
[2023-03-17 17:07:12] FAIL: Unable to access lockfile /var/tmp/altair.lock!
[2023-03-17 17:07:12] FAIL: Please check whether other license servers are running and ensure there are sufficient file access permissions.
```
- Check if the lock file is existing or not
- Create if not exist
```bash
[root@SUTD-hpc-hn1 admin]# ls -al /var/tmp/altair.lock
ls: cannot access /var/tmp/altair.lock: No such file or directory
[root@SUTD-hpc-hn1 admin]# touch /var/tmp/altair.lock
[root@SUTD-hpc-hn1 admin]# systemctl restart altairlmxd.service
```


# Docker
docker run -it nvcr.io/nvidia/pytorch:20.06-py3 /bin/bash




chgrp docker $PBS_EXEC/sbin/pbs_container
chmod 2755 $PBS_EXEC/sbin/pbs_container


# Users

## Ernest
ernest_chong,jingyi_xu,zihan_chen,xia_huang,benjamin_drabkin,tiansi_li,reuben_soh,ernest_chong2,ernest_chong3,ernest_chong4,yining_zhang

qmgr -c "s q platinum acl_users += 'ernest_chong,jingyi_xu,zihan_chen,xia_huang,benjamin_drabkin,tiansi_li,reuben_soh,ernest_chong2,ernest_chong3,ernest_chong4,yining_zhang'"

## Roy
zhiqiang_hu,qing_meng,shaun_toh,daniel_chin,mingshan_hee

qmgr -c "s q gold acl_users += 'zhiqiang_hu,qing_meng,shaun_toh,daniel_chin,mingshan_hee'"

## Ngai Man
keshigeyan,viethung_tran,christopher_teo,thibaongoc_nguyen,hosy_tuyen,unhao_koh,kimcuc_nguyen,ngoc_nguyen,siddharth_kumar,milad_abdollahzadeh

qmgr -c "s q gold acl_users += 'keshigeyan,viethung_tran,christopher_teo,thibaongoc_nguyen,hosy_tuyen,unhao_koh,kimcuc_nguyen,ngoc_nguyen,siddharth_kumar,milad_abdollahzadeh'"

## Wang Bo
bo_wang,chenye_yang,tomomasa_yamasaki,nurul_akhira,bo_wang1

qmgr -c "s q gold acl_users += 'bo_wang,chenye_yang,tomomasa_yamasaki,nurul_akhira,bo_wang1'"

## Cai Kui
desmond_loke,shaoxiang_go,xingwei_zhong,peng_kang,panpan_li

qmgr -c "s q gold acl_users += 'desmond_loke,shaoxiang_go,xingwei_zhong,peng_kang,panpan_li'"

## Liu Jun
pengfei_wang,tianjiao_li,he_huang,wenxiao_zhang,li_xu

qmgr -c "s q gold acl_users += 'pengfei_wang,tianjiao_li,he_huang,wenxiao_zhang,li_xu'"

## Tony
chaoqun_you,xingqiu_he

qmgr -c "s q gold acl_users += 'chaoqun_you,xingqiu_he'"

## Dev

chaoqun_you,xingqiu_he,xia_huang

qmgr -c "s q dev acl_users += 'chaoqun_you,xingqiu_he,xia_huang'"

qmgr -c "s q dev acl_users += 'triphan'"



## Resource
qmgr -c "set queue platinum max_run = [u:PBS_GENERIC=2]"
qmgr -c "set queue gold max_run = [u:PBS_GENERIC=2]"
qmgr -c "set queue dev max_run = [u:PBS_GENERIC=1]"




#############################################################
# Second time
```bash

qmgr -c 'print node @default' > nodes.new

qmgr -c 'print sched @default'

qmgr -c 'print server'
```

## Backup
```bash
qmgr -c "set sched default scheduling = false"
```
```bash
mkdir /tmp/pbs_mom_backup_apr
export PBS_HOME=/var/spool/pbs

cp $PBS_HOME/mom_priv/config /root/admin/pbs_mom_backup_apr/config.backup
```

## Save hook
```bash
qmgr -c "list hook"


qmgr -c 'export hook pbs_cgroups application/x-python default /tmp/pbs_cgroups.old2.7'
qmgr -c 'export hook intcheck application/x-python default /tmp/intcheck.old2.7'

qmgr -c 'export hook pbs_cgroups application/x-config default /tmp/pbs_cgroups.configcheck'
qmgr -c 'export hook intcheck application/x-config default /tmp/intcheck.configcheck'
```
## Shutdown PBS
```bash
qterm -t immediate -m -s -f
systemctl stop pbs
```
### Verify
```bash
ps -ef | grep pbs
```


## Backup
```bash
cd $PBS_HOME/..
tar -cvf /root/admin/upgrade_Apr/PBS_HOME_tarbackup.tar $PBS_HOME

export PBS_EXEC=/opt/pbs
cd $PBS_EXEC/..
tar -cvf /root/admin/upgrade_Apr/PBS_EXEC_tarbackup.tar $PBS_EXEC

cp /etc/pbs.conf /root/admin/upgrade_Apr/pbs.conf.backup
```

## Install
```bash
cd
cd admin/upgrading_Mar/PBSPro_2022.1.1/
rpm -U pbspro-server-2022.1.1.20220926110806-0.el7.x86_64.rpm
```

```bash
Installation of PBS Professional

Terms of use for the software are available online at
http://www.pbspro.com/agreement.html

*** PBS Installation Summary
***
*** Postinstall script called as follows:
*** /opt/pbs/libexec/pbs_postinstall server 2022.1.1.20220926110806 /opt/pbs /var/spool/pbs pbsdata 
***
###########################################################
WARNING: Unable to find OpenSSL version 1.1.1, hence python's ssl module will not work
###########################################################
*** Existing configuration file found: /etc/pbs.conf
***
*** Saving /etc/pbs.conf as /etc/pbs.conf.pre.2022.1.1.20220926110806.20230406100613
*** Replacing /etc/pbs.conf with /etc/pbs.conf.2022.1.1.20220926110806
*** /etc/pbs.conf has been modified.
*** The original contents have been saved to /etc/pbs.conf.pre.2022.1.1.20220926110806.20230406100613
***
*** Registering PBS as a service.
***
*** PBS_HOME is /var/spool/pbs
*** Existing environment file left unmodified: /var/spool/pbs/pbs_environment
***
*** The PBS server has been installed in /opt/pbs/sbin.
*** The PBS scheduler has been installed in /opt/pbs/sbin.
***
*** The PBS communication agent has been installed in /opt/pbs/sbin.
***
*** The PBS MOM has been installed in /opt/pbs/sbin.
***
*** The PBS commands have been installed in /opt/pbs/bin.
***
*** End of /opt/pbs/libexec/pbs_postinstall
```

## Edit scheduler


## Edit pbs.conf
```bash
vi /etc/pbs.conf
```

```bash
PBS_EXEC=/opt/pbs
PBS_SERVER=aimc-hn1
PBS_START_SERVER=1
PBS_START_SCHED=1
PBS_START_COMM=1
PBS_START_MOM=0
PBS_HOME=/var/spool/pbs
PBS_CORE_LIMIT=unlimited
PBS_SCP=/bin/scp
```

## Change hostname
```bash
hostnamectl set-hostname aimc-hn1

qmgr -c 'set server server_host=aimc-hn1'
```


## Edit 

```bash
vi /var/spool/pbs/sched_priv/sched_config
```

```bash
resources: "ncpus, mem, arch, host, vnode, aoe, eoe, ngpus, Qlist, container_engine"
```

## Install license
Path: `/usr/local/altair/licenses/altair_lic.dat`
```bash
cd /usr/local/altair/licensing15.2/
./bin/almutil -licstat
```

### Log file
`cat /usr/local/altair/licensing15.2/logs/aimc-hn1.log`

### Restart
```bash
systemctl restart altairlmxd.service
```


## Set license
```bash
qstat -Bf

qmgr -c 'set server pbs_license_info=6200@aimc-hn1'
qmgr -c 'set server pbs_license_info=6200@192.168.33.10:6200@192.168.33.15:6200@192.168.33.30'
```

### Check exe node license
```bash
pbsnodes aimc-rn3
```

## Change to python3
```bash
ls -al /usr/bin/python*

ln -sf /usr/local/bin/python3 /usr/bin/python
ln -sf /usr/local/bin/python3-config /usr/bin/python-config
```

# Hook
## cgroup
```bash
qmgr -c "list hook"

qmgr -c 'export hook pbs_cgroups application/x-config default' > pbs_cgroups.json
qmgr -c 'import hook pbs_cgroups application/x-config default pbs_cgroups.json'

qmgr -c 'set resource ngpus flag=nh'
```
```bash
        "devices" : {
            "enabled"            : false,
            "exclude_hosts"      : [],
            "exclude_vntypes"    : [],
            "allow"              : [
                "b *:* rwm",
                "c *:* rwm"
                "c 195:* m",
                "c 136:* rwm",
                ["infiniband/rdma_cm","rwm"],
                ["fuse","rwm"],
                ["net/tun","rwm"],
                ["tty","rwm"],
                ["ptmx","rwm"],
                ["console","rwm"],
                ["null","rwm"],
                ["zero","rwm"],
                ["full","rwm"],
                ["random","rwm"],
                ["urandom","rwm"],
                ["cpu/0/cpuid","rwm","*"],
                ["nvidia-modeset", "rwm"],
                ["nvidia-uvm", "rwm"],
                ["nvidia-uvm-tools", "rwm"],
                ["nvidiactl", "rwm"]
            ]
        },

```



## PBS HPC container
```bash
qmgr -c "export pbshook PBS_hpc_container application/x-config default" > container_config.json
qmgr -c "import pbshook PBS_hpc_container application/x-config default container_config.json"
qmgr -c 'set hook pbs_cgroups enabled = true'
```

PBS_hpc_container
```bash
"mount_paths": ["/etc/passwd", "/etc/group", "/raid", "/app", "/Scratch"],
```

### Config `container_engine` on server
```bash
qmgr -c 'create resource container_image type=string,flag=m'
qmgr -c 'create resource container_ports type=string_array,flag=m'
qmgr -c 'create resource container_engine type=string_array,flag=mh'


qmgr -c 's n aimc-gn3 resources_available.container_engine=docker'
qmgr -c 's n aimc-rn3 resources_available.container_engine+= singularity'

qmgr -c 's n aimc-rn3 resources_available.vnode=aimc-rn3'
```

### Config `container_engine` on exec node
```bash
chgrp docker $PBS_EXEC/sbin/pbs_container
chmod 2755 $PBS_EXEC/sbin/pbs_container
```

## Add vnode
```bash
qmgr -c 'print node @default'
qmgr -c "delete node SUTD-hpc-gn4[0],SUTD-hpc-gn4[1]"
qmgr -c "create node SUTD-hpc-gn4"

qmgr -c "delete node aimc-rn3"
qmgr -c "create node aimc-rn3 Mom=aimc-rn3"
qmgr -c "s n aimc-rn3 resources_available.allows_container = true"
qmgr -c "s n aimc-rn3 resources_available.ngpus = 8"
qmgr -c "s n aimc-rn3 resources_available.Qlist = dev_vn"
```

### Create queue list
#### `dev_vn`
```bash
qmgr -c "create queue dev"
qmgr -c "s q dev queue_type = execution"
qmgr -c "s q dev max_queued_res.ngpus = [u:PBS_GENERIC=1]"
qmgr -c "s q dev acl_user_enable = True"
qmgr -c "s q dev acl_users += triphan"
qmgr -c "s q dev resources_default.walltime = 04:00:00"
qmgr -c "s q dev default_chunk.Qlist = dev_vn"
qmgr -c "s q dev max_run = [u:PBS_GENERIC=1]"
qmgr -c "s q dev max_run_res.ngpus = [u:PBS_GENERIC=1]"
qmgr -c "s q dev enabled = True"
qmgr -c "s q dev started = True"

qmgr -c "s q dev priority = 1"
qmgr -c "s q dev max_queued = [u:PBS_GENERIC=1]"
qmgr -c "s q dev max_queued_res.ncpus = [u:PBS_GENERIC=5]"
qmgr -c "s q dev max_queued_res.mem = [u:PBS_GENERIC=500gb]"
qmgr -c "s q dev resources_max.walltime = 1:00:00"
qmgr -c "s q dev max_queued = [u:PBS_GENERIC=1]"
```

#### `gold`
```bash
qmgr -c "create queue gold"
qmgr -c "s q dev queue_type = execution"
qmgr -c "s q dev max_queued_res.ngpus = [u:PBS_GENERIC=1]"
qmgr -c "s q dev acl_user_enable = True"
qmgr -c "s q dev acl_users += triphan"
qmgr -c "s q dev resources_default.walltime = 04:00:00"
qmgr -c "s q dev default_chunk.Qlist = dev_vn"
qmgr -c "s q dev max_run = [u:PBS_GENERIC=1]"
qmgr -c "s q dev max_run_res.ngpus = [u:PBS_GENERIC=1]"
qmgr -c "s q dev enabled = True"
qmgr -c "s q dev started = True"
```

#### `platinum`
```bash

```

### Add queue to node
```bash

```

### Test interactive job
```bash
qmgr -c 'print sched @default'
qmgr -c "set sched default scheduling = true"
```

```bash
pbsnodes aimc-gn3
qmgr -c "s n aimc-gn3 resources_available.Qlist = 'dev_vn'"

qsub -I -l select=1:ncpus=5 -q dev
qsub -I -l select=1:ncpus=5 -q workq -v CONTAINER_IMAGE=nvcr.io/nvidia/pytorch:20.06-py3 -N docker-interactive

qmgr -c "set node SUTD-hpc-gn4 resources_available.allows_container = True"
```
## High Availability
Copy license
```bash
cp altair_lic.dat /usr/local/altair/licenses
```

Edit
```bash

```
### License server
```bash
LICENSE_FILE = /usr/local/altair/licenses/altair_lic.dat

HAL_SERVER1 = 6200@192.168.33.10
HAL_SERVER2 = 6200@192.168.33.15
HAL_SERVER3 = 6200@192.168.33.30
```

Restart
```bash
systemctl restart altairlmxd.service
```

Check log
```bash
cat /usr/local/altair/licensing15.2/logs/aimc-hn3.log
cat /usr/local/altair/licensing15.2/logs/aimc-hn1.log
cat /usr/local/altair/licensing15.2/logs/SUTD-Cloud-cc1.log
```

######################################################
# Execution node
```bash
hostnamectl set-hostname aimc-gn3

ssh-copy-id -i ~/.ssh/id_rsa.pub aimc-hn1
ssh-copy-id -i ~/.ssh/id_rsa.pub aimc-hn2
ssh-copy-id -i ~/.ssh/id_rsa.pub aimc-hn3
```

## Backup
```bash
source /etc/pbs.conf

mkdir /root/upgrade_Apr/pbs_mom_backup_apr -p
cp $PBS_HOME/mom_priv/config /root/upgrade_Apr/pbs_mom_backup_apr/config.backup

cd $PBS_HOME/..
tar -cvf /root/upgrade_Apr/PBS_HOME_tarbackup.tar $PBS_HOME

cd $PBS_EXEC/..
tar -cvf /root/upgrade_Apr/PBS_EXEC_tarbackup.tar $PBS_EXEC

cp /etc/pbs.conf /root/upgrade_Apr/pbs.conf.backup
```

## Change to python3
```bash
ls -al /usr/bin/python*

ln -sf /usr/bin/python3 /usr/bin/python
ln -sf /usr/bin/python3-config /usr/bin/python-config
```

## Shutdown PBS
```bash
systemctl stop pbs
```
### Verify
```bash
ps -ef | grep pbs
```

## Install
### Copy exec if not exist
From hn1
```bash
scp /root/admin/upgrading_Mar/PBSPro_2022.1.1/pbspro-execution-2022.1.1.20220926110806-0.el7.x86_64.rpm aimc-gn1:/root/upgrade_Apr
```

Install
```bash
source /etc/pbs.conf

rpm -e pbspro-execution
rm -rf $PBS_HOME
rm -rf $PBS_EXEC
rm -f /etc/pbs.conf

cd upgrade_Mar/
cd PBSPro_2022.1.1/
cd upgrade_Apr


rpm -U pbspro-execution-2022.1.1.20220926110806-0.el7.x86_64.rpm
```

## Edit
```bash
vi $PBS_HOME/mom_priv/config
```

```bash
$clienthost aimc-hn1 
$restrict_user_maxsysid 999 
$restrict_user True 
$restrict_user_exceptions localadmin
```

```bash
vi /etc/pbs.conf
```

```bash
PBS_EXEC=/opt/pbs
PBS_SERVER=aimc-hn1
PBS_START_SERVER=0
PBS_START_SCHED=0
PBS_START_COMM=0
PBS_START_MOM=1
PBS_HOME=/var/spool/pbs
PBS_CORE_LIMIT=unlimited
PBS_SCP=/bin/scp
```


## Start pbs
```bash
systemctl restart pbs.service
```

### Config `container_engine` on exec node
```bash
source /etc/pbs.conf
chgrp docker $PBS_EXEC/sbin/pbs_container
chmod 2755 $PBS_EXEC/sbin/pbs_container
```

## Create node
```bash
qmgr -c "create node aimc-gn1 Mom=aimc-gn1"
qmgr -c "create node aimc-gn2 Mom=aimc-gn2"
qmgr -c "create node aimc-gn3 Mom=aimc-gn3"
qmgr -c "create node aimc-gn4 Mom=aimc-gn4"
qmgr -c "create node aimc-gn5 Mom=aimc-gn5"
qmgr -c "delete node aimc-gn3"
```

### Check node
```bash
qmgr -c "print node @default"
```





export PBS_HOOK_CONFIG_FILE=/var/spool/pbs/server_priv/hooks/PBS_hpc_container.CF
pbs_python --hook -r $PBS_HOME/server_priv/resourcedef -i /var/spool/pbs/server_priv/hooks/tmp/hook_queuejob_PBS_hpc_container_1680857095.in /var/spool/pbs/server_priv/hooks/PBS_hpc_container.PY



export PBS_HOOK_CONFIG_FILE=/root/admin/upgrade_Apr/debug/PBS_hpc_container.CF
pbs_python --hook -r $PBS_HOME/server_priv/resourcedef -i /var/spool/pbs/server_priv/hooks/tmp/hook_queuejob_PBS_hpc_container_1680857095.in /root/admin/upgrade_Apr/debug/PBS_hpc_container.PY

source /etc/pbs.conf
export PBS_HOOK_CONFIG_FILE=/root/upgrade_Apr/debug/PBS_hpc_container.CF
pbs_python --hook -r $PBS_HOME/server_priv/resourcedef -i /var/spool/pbs/server_priv/hooks/tmp/hook_queuejob_PBS_hpc_container_1680857095.in /root/upgrade_Apr/debug/PBS_hpc_container.PY




```bash
04/07/2023 17:43:06;0086;Server@aimc-hn1;Svr;Server@aimc-hn1;Compiling script file: </var/spool/pbs/server_priv/hooks/PBS_hpc_container.PY>
04/07/2023 17:43:06;0080;Server@aimc-hn1;Hook;Server@aimc-hn1;Tri ahihi {'systemd': '/sys/fs/cgroup/systemd/pbs_jobs.service/jobid/', 'freezer': '/sys/fs/cgroup/freezer/pbs_jobs.service/jobid/', 'perf_event': '/sys/fs/cgroup/perf_event/pbs_jobs.service/jobid/', 'memory': '/sys/fs/cgroup/memory/pbs_jobs.service/jobid/', 'net_cls': '/sys/fs/cgroup/net_cls,net_prio/pbs_jobs.service/jobid/', 'cpuacct': '/sys/fs/cgroup/cpu,cpuacct/pbs_jobs.service/jobid/', 'blkio': '/sys/fs/cgroup/blkio/pbs_jobs.service/jobid/'}
04/07/2023 17:43:06;0100;Server@aimc-hn1;Req;;Type 1 request processed from triphan@aimc-hn1, sock=19
[root@aimc-hn1 hooks]# ls /sys/fs/cgroup/memory/pbs_jobs.service/jobid/
ls: cannot access /sys/fs/cgroup/memory/pbs_jobs.service/jobid/: No such file or directory
[root@aimc-hn1 hooks]# ls /sys/fs/cgroup/memory/
cgroup.clone_children           memory.kmem.tcp.limit_in_bytes      memory.oom_control
cgroup.event_control            memory.kmem.tcp.max_usage_in_bytes  memory.pressure_level
cgroup.procs                    memory.kmem.tcp.usage_in_bytes      memory.soft_limit_in_bytes
cgroup.sane_behavior            memory.kmem.usage_in_bytes          memory.stat
machine.slice                   memory.limit_in_bytes               memory.swappiness
memory.failcnt                  memory.max_usage_in_bytes           memory.usage_in_bytes
memory.force_empty              memory.memsw.failcnt                memory.use_hierarchy
memory.kmem.failcnt             memory.memsw.limit_in_bytes         notify_on_release
memory.kmem.limit_in_bytes      memory.memsw.max_usage_in_bytes     release_agent
memory.kmem.max_usage_in_bytes  memory.memsw.usage_in_bytes         system.slice
memory.kmem.slabinfo            memory.move_charge_at_immigrate     tasks
memory.kmem.tcp.failcnt         memory.numa_stat                    user.slice
[root@aimc-hn1 hooks]# ls /sys/fs/cgroup/memory/pbs_jobs.service/
ls: cannot access /sys/fs/cgroup/memory/pbs_jobs.service/: No such file or directory
[root@aimc-hn1 hooks]# ls /sys/fs/cgroup/memory/^C
[root@aimc-hn1 hooks]# mkdir -p /sys/fs/cgroup/memory/pbs_jobs.service/jobid/
[root@aimc-hn1 hooks]# 

```

```bash
[root@aimc-hn1 ~]# cat /etc/issue.net 
##########################################################################
#                      Welcome to SUTD-GPU cluster                       #
#                                  ***                                   #
#                                                                        #
# This GPU cluster is a property of SUTD. It is for official use only.   #
# - To list the available environment modules, do "module avail"         #
# - To purge the loaded modules, do "module purge"                       #
# - To see list of all jobs in the queues, run "qstat"                   #
# - Examples: user can find examples of docker, singularity, environment #
#   module at /app/public/example                                        #
#                                                                        #
##########################################################################
```




# Upgrade NVIDIA driver
## Uninstall
Check current nvidia-driver
```bash
nvidia-smi

# 440.33.01

bash /mnt/beegfs/compile_dir/NVIDIA-Linux-x86_64-440.33.01.run --uninstall
```
> Yes


## Edit yum script
If the `/usr/bin/python` has version 3, force `yum` run with version 2
```bash
vi /usr/bin/yum
vi /usr/libexec/urlgrabber-ext-down

#!/usr/bin/python2
```

## Install
```
yum install libglvnd-devel
systemctl isolate multi-user.target
bash /mnt/beegfs/compile_dir/NVIDIA-Linux-x86_64-450.216.04.run

reboot
```

> Yes
> Yes





















