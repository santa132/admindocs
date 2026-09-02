# Current deployment
en1
- ven0 - for instructor dataset
- ven1 - running
    V100DX-16Q x 8 VMs
    & proxy - donot shutdown
- ven2 - running
    V100DX-16Q x 8 VMs

en2
- ven4 - cordon
    V100DX-8Q x 12 VMs
- ven5 - stop
- ven6 - stop

# Storage
$ kubectl get storageclass
```
NAME                          PROVISIONER                                          RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-client                    cluster.local/nfs-subdir-external-provisioner        Retain          Immediate           false                  138d
second-nfs-client (default)   k8s-sigs.io/second-nfs-subdir-external-provisioner   Delete          Immediate           true                   138d
```
Where is the second class


# Test jupyter image
```
docker run --rm -p 8888:8888 aimc.registry:5000/ai-container:1.0-pytorch
docker run --gpus 1 --rm -p 8888:8888 --user root -e GRANT_SUDO=yes aimc.registry:5000/ai-container:1.0-pytorch
docker run --gpus 1 --rm -d -p 8888:8888 --user root -e GRANT_SUDO=yes --name jupyter aimc.registry:5000/ai-container:1.0-pytorch
```

It will show:
```
http://444cb96d9ca7:8888/lab?token=7e7f883ae72cade95c516c3416fc524a6221ef26f42010c7
http://127.0.0.1:8888/lab?token=7e7f883ae72cade95c516c3416fc524a6221ef26f42010c7
```
- Open web browser at: http://192.168.33.101:8888/lab?token=7e7f883ae72cade95c516c3416fc524a6221ef26f42010c7

- with 192.168.33.101 is the IP of the edu-node running the docker container above.
```
sudo ip route del default via 192.168.33.1 dev br2
sudo ip route add default via 192.168.33.15 dev br2
sudo ip route add default via 172.16.0.15 dev br1
sudo iptables -t nat -A POSTROUTING -o br2 -s 172.16.0.0/24 -j MASQUERADE
```
```
ven1
default via 192.168.33.1 dev enp3s0 proto static
default via 172.16.0.1 dev enp2s0 proto static
default via 172.20.0.1 dev enp1s0 proto static
```

```
sudo ip route del default via 192.168.33.1 dev enp3s0
```
- Test:
```
tcpdump -i br1 -nn host github.com
curl -I https://github.com
```

```
iptables -t nat -A POSTROUTING -o br1 -j MASQUERADE
cat /proc/sys/net/ipv4/ip_forward
iptables -t nat -L -v -n|grep MASQUERADE
iptables -t nat -A POSTROUTING -o br2 -s 172.16.0.0/24 -j MASQUERADE
iptables -t nat -L -v -n|grep MASQUERADE
iptables -L -v -n | grep br1
iptables -t nat -L -v -n
iptables -L -v -n
```
```
cat /etc/iproute2/rt_tables
nano /etc/networkd-dispatcher/routable.d/10-custom-route
```

```
#!/bin/bash
ip rule add from 192.168.33.16 lookup 100
ip route add default via 172.16.0.15 table 100
```

```
/etc/sysctl.conf
```

```
echo "100 customroute" | sudo tee -a /etc/iproute2/rt_tables
cat /etc/iproute2/rt_tables
chmod +x /etc/networkd-dispatcher/routable.d/10-custom-route
ip rule add from 192.168.33.16 lookup 100
ip route add default via 172.16.0.15 table 100
```

```
kubectl get deployment nfs-subdir-external-provisioner -o yaml > nfs-subdir-external-provisioner.yaml
```

```
sudo ip route replace default via 172.16.0.15 dev enp2s0 metric 100
sudo ip route replace default via 172.20.0.1 dev enp1s0 metric 300
sudo ip route replace default via 192.168.33.1 dev enp3s0 metric 200
```