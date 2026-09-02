# Setup Compute node

## Edit hosts, add hostname and IP of Headnode and Compute node
sudo nano /etc/hosts
```bash
172.18.0.2    aimc-hn2
172.18.0.20   aimc-gn4
```


## Install PBS compute node
```bash
cd PBSPro_2024.1.3
sudo dpkg -i pbspro-execution_2024.1.3.20250423045815-1_amd64.deb
```

## Configure compute node
```bash
sudo nano /etc/pbs.conf
```

On the compute nodes, set these lines:
```bash
PBS_START_SERVER=aimc-hn2
PBS_START_SCHED=0
PBS_START_COMM=0
PBS_START_MOM=1
```

Now we are ready to start up the server. Use the following command:
```bash
sudo systemctl enable pbs
sudo systemctl start pbs
sudo systemctl status pbs
```

Now check that the processes are running:
```bash
ps axf | grep pbs
```

As well as some postgres processes, on the compute nodes, you should only see
```bash
/opt/pbs/sbin/pbs_mom
```

Restart PBS
```bash
sudo /etc/init.d/pbs restart
```