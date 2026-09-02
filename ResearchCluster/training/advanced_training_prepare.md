# Prepare node for training

## Set node state to Offline

```
pbsnodes -o aimc-gn5

# OR

qmgr -c "set node aimc-gn5 state=offline"
```

## Check node belonging to which queue

```
pbsnodes aimc-gn5
```

## Remove unnecessary node or assign new queue

```
qmgr -c "s n aimc-gn2 resources_available.Qlist = blackout1_vn"
```

## Set node state to Online

```
pbsnodes -r aimc-gn5

# OR

qmgr -c "set node aimc-gn5 state=free"
```

## Check user which exists in queue

```
qstat -Qf dev
```

## Set trainer to dev queue

```
qmgr -c "s q dev acl_users += 'junhao_koh,hosy_tuyen,thibaongoc_nguyen,kimcuc_nguyen,benjamin_drabkin,zihan_chen,christopher_teo'"

```

## Remove trainer from dev queue

```
qmgr -c "s q dev acl_users -= 'junhao_koh,hosy_tuyen,thibaongoc_nguyen,kimcuc_nguyen,benjamin_drabkin,zihan_chen,christopher_teo'"
```

## Set node state to Offline

```
pbsnodes -o aimc-gn5

# OR

qmgr -c "set node SUTD-hpc-gn5 state=offline"
```

## Recovery queue of node

```
qmgr -c "s n aimc-gn5 resources_available.Qlist = blackout1_vn,gold_vn,platinum_vn"
qmgr -c "s n aimc-gn2 resources_available.Qlist = gold_vn"
```

## Set node state to Online

```
pbsnodes -r aimc-gn5

# OR

qmgr -c "set node aimc-gn5 state=free"
```
