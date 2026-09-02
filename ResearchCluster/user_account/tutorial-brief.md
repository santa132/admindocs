```
user_add.sh -n andy_ng -c Andy -s Ng
```
```
user_delete.sh andy
```
```
ldappasswd -H ldap://192.168.33.10 -x -D "cn=ldapadm,dc=sutd,dc=local" -W -S "uid=summer,ou=Users,dc=sutd,dc=local"
```
-> newpasswd -> LDAP passwd

Create new queue:
Create new queue name in PBS control web portal
```
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
<<<<<<< HEAD
qmgr -c "s q blackout1 acl_users += 'timothy,triphan'"

id andy
```
-> uid of user
```
beegfs-ctl --setquota --uid 5593 --sizelimit=550G --inodelimit=unlimited
```
Check quota
```
beegfs-ctl --getquota --uid 5593
```
