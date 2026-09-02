# Apache2
/etc/apache2/sites-available/000-default.conf
--> Home

# Moodle: IP:port
/var/www/html/moodle/config.php

# Moodle --> Hub
- http://192.168.33.15/hub/oauth_callback
  + http://login2.gpucluster.sutd.edu.sg/hub/oauth_callback

# Hub

    GenericOAuthenticator:
      oauth_callback_url: http://login2.gpucluster.sutd.edu.sg/hub/oauth_callback
      authorize_url: http://login2.gpucluster.sutd.edu.sg:8888/moodle/local/oauth/login.php?client_id=jupyterhub&response_type=code
      token_url: http://login2.gpucluster.sutd.edu.sg:8888/moodle/local/oauth/token.php
      userdata_url: http://login2.gpucluster.sutd.edu.sg:8888/moodle/local/oauth/user_info.php
      
      
#####################
# Set up SSH cert
https://thriveread.com/ssl-localhost-certificate-for-https-local-domain/

```bash
mkdir -p /mnt/nfs-ehn1/EduCluster/cert
cd /mnt/nfs-ehn1/EduCluster/cert

openssl genrsa -out CA.key -des3 2048
>> Enter PEM pass phrase: SGPAIp@ssw0rd

openssl req -x509 -new -nodes -key CA.key -sha256 -days 1825 -out CA.pem
>> Enter pass phrase for CA.key:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:SG
State or Province Name (full name) [Some-State]:Singapore
Locality Name (eg, city) []:Singapore
Organization Name (eg, company) [Internet Widgits Pty Ltd]:SUTD
Organizational Unit Name (eg, section) []:AIMC
Common Name (e.g. server FQDN or YOUR name) []:aimc
Email Address []:aimc_support@sutd.edu.sg


openssl genrsa -out local.key -des3 2048

openssl req -new -key local.key -out local.csr

openssl x509 -req -in local.csr -CA ./CA.pem -CAkey ./CA.key -CAcreateserial -days 3650 -sha256 -extfile local.ext -out local.crt

sudo cp /cert/CA.pem /usr/local/share/ca-certificates/CA.crt
sudo update-ca-certificates

/mnt/nfs-ehn1/EduCluster/cert/local.crt  
/mnt/nfs-ehn1/EduCluster/cert/local.csr  
/mnt/nfs-ehn1/EduCluster/cert/local.key

```


# Link: https://cheapsslweb.com/resources/how-to-install-ssl-certificate-on-apache-ubuntu-server

sudo nano /etc/apache2/sites-enabled/000-default.conf
```
SSLEngine on
SSLCertificateFile /mnt/nfs-ehn1/EduCluster/cert/local.crt  
SSLCertificateKeyFile /mnt/nfs-ehn1/EduCluster/cert/local.key
```
sudo a2enmod ssl
sudo systemctl restart apache2

sudo nano /var/www/html/moodle/config.php
$CFG->wwwroot   = 'https://login2.gpucluster.sutd.edu.sg:8888/moodle';

cd /var/www/html

### Jupyter
Link: https://z2jh.jupyter.org/en/latest/administrator/security.html#specify-certificate-through-secret-resource
```
openssl rsa -in local.key -out local.decrypted.key

cd /mnt/nfs-ehn1/EduCluster/cert
kubectl create secret tls enode-tls --key=local.decrypted.key --cert=local.crt

# Verify
kubectl get secret enode-tls jsonpath="{.data}"
```

- Open Jupyterhub config
```
nano config.yaml
helm upgrade --cleanup-on-fail   --install hub jupyterhub/jupyterhub   --namespace hub   --create-namespace   --values current-values.yaml --version 2.0
```

```
hub:
  revisionHistoryLimit:
  config:
    GenericOAuthenticator:
      client_id: JupyterHub
      client_secret: 98e400a9505e553e9274cde8dc4a9680c37a668c11c8f1f2
      oauth_callback_url: https://login2.gpucluster.sutd.edu.sg/hub/oauth_callback
      authorize_url: https://login2.gpucluster.sutd.edu.sg:8888/moodle/local/oauth/login.php?client_id=J>
      token_url: https://login2.gpucluster.sutd.edu.sg:8888/moodle/local/oauth/token.php
      userdata_url: https://login2.gpucluster.sutd.edu.sg:8888/moodle/local/oauth/user_info.php
      #userdata_method: "GET"
      scope:
        - user_info
    Authenticator:
      admin_users:
        - admin
    JupyterHub:
      authenticator_class: generic-oauth
  networkPolicy:
    enabled: false

proxy:
  https:
    enabled: true
    hosts:
      - login2.gpucluster.sutd.edu.sg
    type: secret
    secret:
      name: enode-tls
```

Note: remember to update client key client_secret of JupyterHub if needed?















