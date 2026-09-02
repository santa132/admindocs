firewall-cmd --permanent --add-source=172.16.0.0/24
firewall-cmd --permanent --add-source=192.168.33.0/24

firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=5900/tcp
firewall-cmd --permanent --add-port=6000/tcp
firewall-cmd --permanent --add-port=6080/tcp
firewall-cmd --permanent --add-port=6081/tcp
firewall-cmd --permanent --add-port=6082/tcp
firewall-cmd --permanent --add-port=6568/tcp
firewall-cmd --permanent --add-port=7070/tcp
firewall-cmd --permanent --add-port=8888/tcp

