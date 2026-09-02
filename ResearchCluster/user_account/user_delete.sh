#!/bin/bash

set -e 

LDAPPASS="SUTD_p@ssw0rd"

###DELETE USER AND GROUP
echo "Deleting user: $1"
id $1
ldapdelete -x -D cn=ldapadm,dc=sutd,dc=local -w "$LDAPPASS"  uid=$1,ou=Users,dc=sutd,dc=local
ldapdelete -x -D cn=ldapadm,dc=sutd,dc=local -w "$LDAPPASS"  cn=grp-$1,ou=Group,dc=sutd,dc=local

###DELETE FOLDERS
rm -rf /Scratch/$1
rm -rf /home/users/$1

echo " "
echo "User delete completed without errors."
