# edu node:
00-config.yaml
network:
  ethernets:
    eno1:
      addresses:
      - 192.168.33.32/24
      nameservers:
        addresses:
        - 192.168.2.100
        - 192.168.2.101
        search: []
      routes:
      - to: default
        via: 172.16.0.15
#    ens11np0:
#      dhcp4: true
#    ens12np0:
#      dhcp4: true
  version: 2

01-config.yaml
network:
  ethernets:
    ens11np0:
      dhcp4: false
      dhcp6: false
    ens12np0:
      dhcp4: false
      dhcp6: false
    eno1:
      dhcp4: false
      dhcp6: false
  bonds:
    bond0:
      dhcp4: false
      interfaces: [ens11np0, ens12np0]
      parameters:
        mode: balance-tlb
        mii-monitor-interval: 100
  version: 2
  bridges:
    br1:
      dhcp4: false
      dhcp6: false
      interfaces: [ bond0 ]
      addresses: [172.16.0.17/24]
      nameservers:
        addresses: [8.8.8.8, 192.168.2.100,192.168.2.101]
      #gateway4: 172.16.0.15
      routes:
        - to: default
          via: 172.16.0.15
      mtu: 1500
      parameters:
        stp: true
        forward-delay: 4
    br2:
      dhcp4: false
      dhcp6: false
      interfaces: [ eno1 ]
      addresses: [192.168.33.17/24]
      nameservers:
        addresses: [192.168.2.100,192.168.2.101]
      #routes:
      #  - to: default
      #    via: 192.168.33.15
      mtu: 1500
      parameters:
        stp: true
        forward-delay: 4

default via 172.16.0.15 dev br1 proto static
172.16.0.0/24 dev br1 proto kernel scope link src 172.16.0.17
172.20.0.0/24 dev br0 proto kernel scope link src 172.20.0.1
192.168.33.0/24 dev br2 proto kernel scope link src 192.168.33.17
192.168.33.0/24 dev eno1 proto kernel scope link src 192.168.33.17

# Virtual edu node 1-4
Just change default route to 172.16.0.15
```yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    enp1s0:
      addresses:
      - 172.20.0.108/24
      nameservers:
        addresses: []
        search: []
      routes:
      - to: default
        via: 172.20.0.1
        metric: 200
    enp2s0:
      addresses:
      - 172.16.0.108/24
      nameservers:
        addresses:
        - 192.168.2.100
        - 192.168.2.101
        search: []
      routes:
      - to: default
        via: 172.16.0.15
        metric: 100
    enp20s0:
        addresses:
        - 192.168.33.108/24
        nameservers:
          addresses:
          - 192.168.2.100
          - 192.168.2.101
          search: []
        routes:
          - to: default
            via: 192.168.33.1
            metric: 300
  version: 2
```

aimc@aimc-ven1:~$ ip route
default via 172.16.0.15 dev enp2s0 proto static
default via 172.20.0.1 dev enp1s0 proto static
default via 192.168.33.1 dev enp3s0 proto static
10.244.0.0/24 via 10.244.0.0 dev flannel.1 onlink
10.244.1.0/24 via 10.244.1.0 dev flannel.1 onlink
10.244.2.0/24 via 10.244.2.0 dev flannel.1 onlink
10.244.3.0/24 dev cni0 proto kernel scope link src 10.244.3.1
10.244.4.0/24 via 10.244.4.0 dev flannel.1 onlink
10.244.5.0/24 via 10.244.5.0 dev flannel.1 onlink
172.16.0.0/24 dev enp2s0 proto kernel scope link src 172.16.0.102
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
172.20.0.0/24 dev enp1s0 proto kernel scope link src 172.20.0.102
192.168.33.0/24 dev enp3s0 proto kernel scope link src 192.168.33.102


sudo ip route del default via 192.168.33.1 dev br2 
sudo ip route add default via 192.168.33.15 dev br2