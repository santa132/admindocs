#!/bin/bash
set -e

echo "[1/5] Updating /etc/hosts..."
cat <<'EOF' >> /etc/hosts
172.18.0.5    aimc-ctrl1.sutd.local aimc-ctrl1
172.18.0.6    aimc-ctrl2.sutd.local aimc-ctrl2
172.18.0.7    aimc.sutd.local aimc
EOF

echo "[2/5] Installing SSSD packages..."
apt update -y
apt install -y sssd sssd-ldap libpam-sss libnss-sss

echo "[3/5] Creating /etc/sssd/sssd.conf..."
mkdir -p /etc/sssd
cat <<'EOF' > /etc/sssd/sssd.conf
[sssd]
config_file_version = 2
services = nss, pam
domains = controller

[nss]
filter_users = root
entry_negative_timeout = 5

[pam]
pam_verbosity = 2
pam_account_expired_message = Your account has expired. Please contact a system administrator

[domain/controller]
ldap_schema = rfc2307bis
id_provider = ldap
auth_provider = ldap
access_provider = permit
chpass_provider = ldap

cache_credentials = true
entry_cache_timeout = 600

ldap_uri = ldap://aimc.sutd.local/
ldap_search_base = dc=local
ldap_network_timeout = 30

ldap_access_order = filter,expire
ldap_access_filter = (memberOf=cn=admins,ou=group,dc=local)

ldap_account_expire_policy = shadow
enumerate = true
EOF

chmod 600 /etc/sssd/sssd.conf
chown root:root /etc/sssd/sssd.conf

echo "[4/5] Enabling auto home creation..."
sed -i '/pam_sss.so/a session required        pam_mkhomedir.so skel=/etc/skel/ umask=0022' /etc/pam.d/common-session

echo "[5/5] Restarting SSSD..."
systemctl enable sssd
systemctl restart sssd

echo "✅ Trinity LDAP domain setup complete."
echo "You can test with:  getent passwd <ldap_username>"

