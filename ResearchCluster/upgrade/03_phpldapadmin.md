# Install phpldapadmin
> Successful installation in Jan 5 24

Ref: https://hostadvice.com/how-to/web-hosting/centos/how-to-install-phpldapadmin-on-centos-7/

- Install Apache and PHP
```
sudo yum -y install httpd php
```

- Enable and Start Apache service
```
sudo systemctl enable httpd && sudo systemctl start httpd
```
  - If getting an error `httpd configuration error no mpm loaded.`, Open file `/etc/httpd/conf.modules.d/00-mpm.conf` and uncomment `LoadModule mpm_worker_module modules/mod_mpm_worker.so`

- Install extra PHP packages
```
sudo yum install php-ldap php-mbstring php-pear php-xml -y
sudo yum install epel-release -y
```

- Install the phpLDAPadmin
```
sudo yum -y install phpldapadmin
```

- Configure the phpLDAPadmin Virtual Host
Modify your configuration file located at `/etc/httpd/conf.d/phpldapadmin.conf` to look like the one below:
```
Alias /phpldapadmin /usr/share/phpldapadmin/htdocs
Alias /ldapadmin /usr/share/phpldapadmin/htdocs
<Directory /usr/share/phpldapadmin/htdocs>
  <IfModule mod_authz_core.c>
    # Apache 2.4
    Require all granted
  </IfModule>
  <IfModule !mod_authz_core.c>
    # Apache 2.2
    Order Deny,Allow
    Deny from all
    Allow from 127.0.0.1
    Allow from ::1
  </IfModule>
</Directory>
```

- Configure the phpLDAPadmin
```
sudo vi /etc/phpldapadmin/config.php
```

```
$servers->setValue('server','name','LDAP Server');
$servers->setValue('server','host','192.168.33.10');
$servers->setValue('login','bind_id','cn=ldapadm,dc=sutd,dc=local');
$servers->setValue('appearance','password_hash','ssha');
$servers->setValue('login','attr','dn');
//$servers->setValue('login','attr','uid');
```

- Save your changes and exit the editor.
- Access http://192.168.33.10/phpldapadmin
  - Username: cn=ldapadm,dc=sutd,dc=local
  - Password: **ldapadm** password

# phpLDAPadmin
> Note: Old guide

Reference: https://www.centlinux.com/2018/06/install-phpldapadmin-centos-7-lamp-server.html

- Add the EPEL yum Repository
```bash
rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum makecache
```

- Install phpLDAPAdmin, Apache and PHP
```bash
yum -y install phpldapadmin httpd php
yum install php-ldap -y
```
- Enable and Start Apache service
```bash
systemctl enable httpd && systemctl start httpd
```

- Allow Apache service port thru firewall
```bash
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
```

- Edit the phpMyadmin web server configurations
```html
#
#  Web-based tool for managing LDAP servers
#

Alias /phpldapadmin /usr/share/phpldapadmin/htdocs
Alias /ldapadmin /usr/share/phpldapadmin/htdocs

<Directory /usr/share/phpldapadmin/htdocs>
   <IfModule mod_authz_core.c>
     # Apache 2.4     Require all granted
   </IfModule>
   <IfModule !mod_authz_core.c>
     # Apache 2.2
     Order Deny,Allow
     Deny from all
     Allow from 127.0.0.1
     Allow from ::1
   </IfModule>
</Directory>
```

  - Restart
  ```bash
  systemctl restart httpd
  ```

- Open URL http://192.168.33.10/ldapadmin in web browser.

