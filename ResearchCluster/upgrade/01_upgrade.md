# Upgrade PBS
---
# HEADNODE
## Create a upgrade directory
```bash
mkdir -p admin/upgrade
cd upgrade
```

## Backup
### Node, scheduler, server
```bash
qmgr -c 'print node @default' > nodes.new
qmgr -c 'print sched @default'
qmgr -c 'print server'
```

#### Turn off scheduler
```bash
qmgr -c "set sched default scheduling = false"
```

### Hook
```bash
qmgr -c "list hook"

qmgr -c 'export hook pbs_cgroups application/x-python default /root/admin/upgrade/pbs_cgroups.old2.7'
qmgr -c 'export hook intcheck application/x-python default /root/admin/upgrade/intcheck.old2.7'

qmgr -c 'export hook pbs_cgroups application/x-config default /root/admin/upgrade/pbs_cgroups.configcheck'
qmgr -c 'export hook intcheck application/x-config default /root/admin/upgrade/intcheck.configcheck'
```

### Shutdown PBS
```bash
qterm -t immediate -m -s -f
systemctl stop pbs
```

#### Verify
```bash
ps -ef | grep pbs
```

### HOME and EXEC
```bash
source /etc/pbs.conf

tar -cvf /root/admin/upgrade/PBS_HOME_tarbackup.tar $PBS_HOME
tar -cvf /root/admin/upgrade/PBS_EXEC_tarbackup.tar $PBS_EXEC
cp /etc/pbs.conf /root/admin/upgrade_Apr/pbs.conf.backup
```

## Install licensing
Install licensing on all hosts

### Install licensing
```bash
./altair_licensing_15.2.linux_x64.bin
```

### Create a license folder
```bash
mkdir -p /usr/local/altair/licenses
```

### Copy license to license folder
Path: `/usr/local/altair/licenses/altair_lic.dat`

### Config
```bash
vi altair-serv.cfg
```

Edit following fields
```bash
LICENSE_FILE = /usr/local/altair/licenses/altair_lic.dat

HAL_SERVER1 = 6200@192.168.33.10
HAL_SERVER2 = 6200@192.168.33.15
HAL_SERVER3 = 6200@192.168.33.30
```

**NOTE**: The below config has to be same on license server

### Verify
```bash
cd /usr/local/altair/licensing15.2/
./bin/almutil -licstat
```

### Log file
```bash
cat /usr/local/altair/licensing15.2/logs/aimc-hn3.log
cat /usr/local/altair/licensing15.2/logs/aimc-hn1.log
cat /usr/local/altair/licensing15.2/logs/SUTD-Cloud-cc1.log
```

### Restart
```bash
systemctl restart altairlmxd.service
```

## Install
### Copy and extract installation file
### Install
```bash
cd admin/upgrading/PBSPro_2022.1.1/
rpm -U pbspro-server-2022.1.1.20220926110806-0.el7.x86_64.rpm
```

The result is:
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

### Configuration
#### Scheduler
```bash
vi /var/spool/pbs/sched_priv/sched_config
```

```bash
resources: "ncpus, mem, arch, host, vnode, aoe, eoe, ngpus, Qlist, container_engine"
```

#### License
```bash
qstat -Bf

qmgr -c 'set server pbs_license_info=6200@aimc-hn1'
qmgr -c 'set server pbs_license_info=6200@192.168.33.10:6200@192.168.33.15:6200@192.168.33.30'
```

#### cgroup
```bash
qmgr -c "list hook"

qmgr -c 'export hook pbs_cgroups application/x-config default' > pbs_cgroups.json
qmgr -c 'import hook pbs_cgroups application/x-config default pbs_cgroups.json'
qmgr -c 'set hook pbs_cgroups enabled = true'
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

#### PBS_hpc_container
```bash
qmgr -c "export pbshook PBS_hpc_container application/x-config default" > container_config.json
qmgr -c "import pbshook PBS_hpc_container application/x-config default container_config.json"
qmgr -c 'set pbshook PBS_hpc_container enabled = true'
```

PBS_hpc_container
```bash
"mount_paths": ["/etc/passwd", "/etc/group", "/raid", "/app", "/Scratch"],
```

#### Config `container_engine` on server
```bash
qmgr -c 'create resource container_image type=string,flag=m'
qmgr -c 'create resource container_ports type=string_array,flag=m'
qmgr -c 'create resource container_engine type=string_array,flag=mh'


qmgr -c 's n aimc-gn3 resources_available.container_engine=docker'
qmgr -c 's n aimc-gn3 resources_available.container_engine+= singularity'

qmgr -c 's n aimc-gn3 resources_available.vnode=aimc-gn3'
```

#### Add vnode
```bash
qmgr -c 'print node @default'

qmgr -c "delete node aimc-gn3"
qmgr -c "create node aimc-gn3 Mom=aimc-gn3"
qmgr -c "s n aimc-gn3 resources_available.allows_container = true"
qmgr -c "s n aimc-gn3 resources_available.ngpus = 8"
qmgr -c "s n aimc-gn3 resources_available.Qlist = dev_vn"
```
#### Create `dev_vn` for testing
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
```

#### Setup interactive job limitation
```bash
cd admin
qmgr -c "c h intcheck event=queuejob"
qmgr -c "i h intcheck application/x-python default interactive_reject.py"

qmgr -c "s h intcheck enabled=true"
```

#### Enable scheduling
```bash
qmgr -c 'print sched @default'
qmgr -c "set sched default scheduling = true"
```

#### Test job
```bash
pbsnodes aimc-gn3
qmgr -c "s n aimc-gn3 resources_available.Qlist = 'dev_vn'"

qsub -I -l select=1:ncpus=5 -q dev
qsub -I -l select=1:ncpus=5 -q dev -v CONTAINER_IMAGE=nvcr.io/nvidia/pytorch:20.06-py3 -N docker-interactive

qmgr -c "set node aimc-gn3 resources_available.allows_container = True"
```

## Debug cgroup hook
```bash
export PBS_HOOK_CONFIG_FILE=/var/spool/pbs/server_priv/hooks/PBS_hpc_container.CF
pbs_python --hook -r $PBS_HOME/server_priv/resourcedef -i /var/spool/pbs/server_priv/hooks/tmp/hook_queuejob_PBS_hpc_container_1680857095.in /var/spool/pbs/server_priv/hooks/PBS_hpc_container.PY


export PBS_HOOK_CONFIG_FILE=/root/admin/upgrade_Apr/debug/PBS_hpc_container.CF
pbs_python --hook -r $PBS_HOME/server_priv/resourcedef -i /var/spool/pbs/server_priv/hooks/tmp/hook_queuejob_PBS_hpc_container_1680857095.in /root/admin/upgrade_Apr/debug/PBS_hpc_container.PY

source /etc/pbs.conf
export PBS_HOOK_CONFIG_FILE=/root/upgrade_Apr/debug/PBS_hpc_container.CF
pbs_python --hook -r $PBS_HOME/server_priv/resourcedef -i /var/spool/pbs/server_priv/hooks/tmp/hook_queuejob_PBS_hpc_container_1680857095.in /root/upgrade_Apr/debug/PBS_hpc_container.PY
```
### Fix bug: Not start container with GPU
- The issue
```bash
[triphan@aimc-hn1 ~]$ qsub -I -l select=1:ncpus=5:ngpus=1 -q dev -N Test -v CONTAINER_IMAGE=nvcr.io/nvidia/pytorch:23.04-py3
qsub: Enable pbs_cgroups hook to run GPU containers using dock
```
  - Change the line code 2067 located at `/var/spool/pbs/server_priv/hooks/PBS_hpc_container.PY` from `mom_priv` to `server_priv`
    ```py
    job_file = os.path.join(hdir, "server_priv", "hooks", "pbs_cgroups.HK")
    ```

- Create a missing folder `mkdir -p /sys/fs/cgroup/memory/pbs_jobs.service/jobid/`

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

---
# EXECUTION NODE
## Create a upgrade directory
```bash
mkdir -p upgrade
cd upgrade
```

## Backup
```bash
source /etc/pbs.conf

mkdir /root/upgrade/pbs_mom_backup_apr -p
cp $PBS_HOME/mom_priv/config /root/upgrade_Apr/pbs_mom_backup_apr/config.backup

tar -cvf /root/upgrade/PBS_HOME_tarbackup.tar $PBS_HOME

tar -cvf /root/upgrade/PBS_EXEC_tarbackup.tar $PBS_EXEC

cp /etc/pbs.conf /root/upgrade/pbs.conf.backup
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
scp /root/admin/upgrade/PBSPro_2022.1.1/pbspro-execution-2022.1.1.20220926110806-0.el7.x86_64.rpm aimc-gn1:/root/upgrade
```

### Install
```bash
source /etc/pbs.conf

rpm -e pbspro-execution
rm -rf $PBS_HOME
rm -rf $PBS_EXEC
rm -f /etc/pbs.conf

cd upgrade/
cd PBSPro_2022.1.1/

rpm -U pbspro-execution-2022.1.1.20220926110806-0.el7.x86_64.rpm
```

## Configuration
### `mom_priv` config
```bash
vi $PBS_HOME/mom_priv/config
```
```bash
$clienthost aimc-hn1 
$restrict_user_maxsysid 999 
$restrict_user True 
$restrict_user_exceptions localadmin
```

### `pbs.conf` config
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

## Config `container_engine` on exec node
```bash
source /etc/pbs.conf
chgrp docker $PBS_EXEC/sbin/pbs_container
chmod 2755 $PBS_EXEC/sbin/pbs_container
```

# Create node on HEADNODE
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