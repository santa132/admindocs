#!/bin/bash

HPCGRP_NAME="ernest"
#read -p "LDAP Manager Password: " -s LDAPPASS
LDAPPASS="SUTD_p@ssw0rd"
echo

###Create User's Group ID with same name Start
HIGHEST_GID=$(ldapsearch -x -w "${LDAPPASS}" -b "ou=Group,dc=sutd,dc=local" -D "cn=ldapadm,dc=sutd,dc=local" "(objectclass=posixgroup)" gidnumber | grep -e '^gid' | cut -d':' -f2 | sort | tail -1)

let GROUP_ID=HIGHEST_GID+1

echo "GROUP ID: "$GROUP_ID
GLDIF=$(cat << EOF
dn: cn=grp-${HPCGRP_NAME},ou=group,dc=sutd,dc=local
objectClass: top
objectClass: posixGroup
gidNumber: ${GROUP_ID}

EOF
)
echo "$GLDIF" | ldapadd -x -w $LDAPPASS -D "cn=ldapadm,dc=sutd,dc=local"
###Create Group ID End

## Add existing user to a group
LDIF=$(cat<<EOF
dn: cn=grp-${HPCGRP_NAME},ou=group,dc=sutd,dc=local
changetype: modify
add: memberuid
memberuid: ernest_chong4

EOF
)

ldapmodify -x -W -D "cn=ramesh,dc=tgs,dc=com" -f file1.ldif
Enter LDAP Password:
echo "$GLDIF" | ldapmodify -x -w $LDAPPASS -D "cn=ldapadm,dc=sutd,dc=local"
modifying entry "cn=dbagrp,ou=groups,dc=tgs,dc=com"

ldapsearch -x -LLL -H ldap:/// -b dc=sutd,dc=local