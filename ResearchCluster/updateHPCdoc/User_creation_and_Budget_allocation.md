# `User Creation and Budget Allocation Procedure`

## `1. Create New User`

### Step 1: Edit User List
Edit file `list_add_user.txt` and add the new username.

### Step 2: Run Script to Create User on aimc-ctrl1
```bash
cd /adm/hpc/auto-script
./create_obol_user.sh
```

### Step 3: Add User to Cluster (Run on Headnode 1 as root)
```bash
./add_new_user_to_cluster.sh
```
- You can create manually with command:
```bash
obol group add --gid <GID> grp-<User_name>
obol user add -g grp-<User_name> -p <Password> <User_name>
```

### Step 4: Append passwd and group to All G Nodes (Run on aimc-ctrl1)
```bash
./run_append_to_gnodes.sh
```

### Step 5: Add to queue (Run on aimc-hn2 as root)
```bash
qmgr -c "set queue <queue name> acl_users += <user name>"
Ex: qmgr -c "set queue aimcq acl_users += shaoyang"
```

## `2. Procedure: Scripts to Add Budgets`
### Step 1: Login as amadmin
```bash
su - amadmin
amgr login
```
### Step 2: Edit Input Files

- Edit user_list.txt to add new user.

- Edit script add_users_to_personal_project.sh:

- Change:
```bash
GROUP="g_zhang_wenxuan"
USER_LIST="user_list_wenxuan.txt"
```

- Edit start and end date if required.

### Step 3: Run Script to Create Group and Personal Project
```bash
./add_users_to_personal_project.sh
```

## `3. Deposit Budgets`
### Step 1: Deposit to Group (as Investor)
- Example:
```bash
amgr deposit group -n g_roy_lee -s cpu_hrs 10000000000 -s gpu_hrs 10000000000 -s SU_A100 10000000000 -s SU_V100 10000000000 -s SU_H100 10000000000 -s SU_TOTAL 10000000000 -C "Deposit 10000000000 to all SUs for the group g_roy_lee"
```

### Step 2: Deposit to Project (as Manager)
- Example:
```bash
amgr deposit project -n personal-yihan_du -s cpu_hrs 100000 -s gpu_hrs 100000 -s SU_A100 100000 -s SU_V100 1000
```