#!/bin/bash
#
# add_user.sh: Add user to LDAP
#

set -e

# Defaults
LDAP_BASE="dc=sutd,dc=local"
LDAP_ACCOUNTS_DN="ou=Users,${LDAP_BASE}"
LDAP_USER_GROUP="cn=UserGroup,ou=Group,${LDAP_BASE}"
LDAP_ADMIN_GROUP="cn=Admins,ou=group,${LDAP_BASE}"
LDAP_BIND_DN="cn=ldapadm,${LDAP_BASE}"
USER_NAME=
USER_CN=
USER_SN=
USER_ID=
GROUP_ID=
IS_ADMIN=
LDAP_OPTIONS=

usage()
{
cat << EOF
usage $0 options

This script creates a user in LDAP

OPTIONS
  -h         Show this message
  -n <name>  Username
  -c <cn>    User CN
  -s <sn>    User SN
  -i <uid>   User ID Number (default: next available number)
  -g <gid>   Primary group ID Number (default: $GROUP_ID)
  -a         Add user to administrator group
  -D         LDAP Bind DN (default: $LDAP_BIND_DN)
  -b         LDAP Base (default: $LDAP_BASE)
  -P         LDAP Accounts DN (default: $LDAP_ACCOUNTS_DN)
  -U         LDAP User Group DN (default: $LDAP_USER_GROUP)
  -A         LDAP Admin Group DN (default: $LDAP_ADMIN_GROUP)
  -t         Test. Show what would be done, but don’t actually modify LDAP.
EOF
}

error_ldap() {
  echo "Error: Error connecting to LDAP or uninitialized user tree"
}

while getopts "hn:c:s:i:g:aD:b:P:U:A:t" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    n)
      USER_NAME=$OPTARG
      ;;
    c)
      USER_CN=$OPTARG
      ;;
    s)
      USER_SN=$OPTARG
      ;;
    i)
      USER_ID=$OPTARG
      ;;
    a)
      IS_ADMIN=0
      ;;
    D)
     LDAP_BIND_DN=$OPTARG
     ;;
    b)
     LDAP_BASE=$OPTARG
     ;;
    P)
     LDAP_ACCOUNTS_DN=$OPTARG
     ;;
    A)
      LDAP_ADMIN_GROUP=$OPTARG
      ;;
    t)
      LDAP_OPTIONS+=" -n "
      ;;
    ?)
      usage
      exit
      ;;
  esac
done

if [ -z $USER_NAME        ] ||
   [ -z $USER_CN          ] ||
   [ -z $USER_SN          ] ||
   [ -z $LDAP_BIND_DN     ] ||
   [ -z $LDAP_ACCOUNTS_DN ] ||
   [ -z $LDAP_ADMIN_GROUP ]
then
  usage
  exit 1
fi

#read -p "LDAP Manager Password: " -s LDAPPASS
LDAPPASS="SUTD_p@ssw0rd"
echo

###Create User's Group ID with same name Start
HIGHEST_GID=$(ldapsearch -x -w "${LDAPPASS}" -b "ou=Group,dc=sutd,dc=local" -D "${LDAP_BIND_DN}" "(objectclass=posixgroup)" gidnumber | grep -e '^gid' | cut -d':' -f2 | sort | tail -1)

let GROUP_ID=HIGHEST_GID+1
LDAP_USER_GROUP=cn="grp-$USER_NAME,ou=group,dc=sutd,dc=local"
echo "GROUP ID: "$GROUP_ID
GLDIF=$(cat << EOF
dn: cn=grp-${USER_NAME},ou=group,dc=sutd,dc=local
objectClass: top
objectClass: posixGroup
gidNumber: ${GROUP_ID}

EOF
)
echo "$GLDIF" | ldapadd -x -w $LDAPPASS -D $LDAP_BIND_DN 
###Create Group ID End


# If USER_ID not supplied, find next using ldap query
if [ -z $USER_ID ]
then
  HIGHEST_UID=$(ldapsearch -x -w "$LDAPPASS" -b "${LDAP_ACCOUNTS_DN}" -D "cn=ldapadm,dc=sutd,dc=local" "(objectclass=posixaccount)" uidnumber | grep -e '^uid' | cut -d':' -f2 | sort | tail -1)
  if [ -z $HIGHEST_UID ]
  then
    error_ldap
    exit 1
  fi
  let USER_ID=HIGHEST_UID+1
fi

#read -p "${USER_NAME} Initial Password: " -s USER_CLEARTEXT_PASS
#DEFAULT USER PASSWORD
USER_CLEARTEXT_PASS="default_p@ssw0rd"
echo

USER_PASS=$(slappasswd -h {SSHA} -s $USER_CLEARTEXT_PASS)

unset USER_CLEARTEXT_PASS

CHANGE_DATE=$(echo "$(date +%s) / ( 60 * 60 * 24 )" | bc)

LDIF=$(cat<<EOF
dn: uid=${USER_NAME},${LDAP_ACCOUNTS_DN}
changetype: add
uid: ${USER_NAME}
cn: ${USER_CN}
sn: ${USER_SN}
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: ${USER_PASS}
shadowLastChange: ${CHANGE_DATE}
shadowMax: 99999
shadowWarning: 7
loginShell: /bin/bash
uidNumber: ${USER_ID}
gidNumber: ${GROUP_ID}
homeDirectory: /home/users/${USER_NAME}

dn: ${LDAP_USER_GROUP}
changetype: modify
add: memberuid
memberuid: ${USER_NAME}

EOF
)

if [ $IS_ADMIN ]
then
  LDIF+=$(cat<<EOF


dn: ${LDAP_ADMIN_GROUP}
changetype: modify
add: memberuid
memberuid: ${USER_NAME}

EOF
)
fi

echo "--------------------"
echo "Adding ${LDIF}"
echo "--------------------"
echo "$LDIF" | ldapmodify -x -w "$LDAPPASS" -D "${LDAP_BIND_DN}" $LDAP_OPTIONS

unset LDAPPASS

#SCAN ALL HOST IN THE CLUSTER
su - $USER_NAME -c "mkdir .ssh;ssh-keyscan SUTD-hpc-hn1>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn1>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn1>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn2>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn2>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-Cloud-cn1>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-Cloud-cn2>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-Cloud-cn3>>/home/users/$USER_NAME/.ssh/known_hosts"

ssh-keygen -t rsa -f /home/users/$USER_NAME/.ssh/id_rsa -q -N ""
cat /home/users/$USER_NAME/.ssh/id_rsa.pub > /home/users/$USER_NAME/.ssh/authorized_keys
chmod 600 /home/users/$USER_NAME/.ssh/authorized_keys
chown -R $USER_NAME:grp-$USER_NAME /home/users/$USER_NAME/.ssh
mkdir -p /Scratch/$USER_NAME
chmod 700 /Scratch/$USER_NAME
chown $USER_NAME:grp-$USER_NAME /Scratch/$USER_NAME
ln -sf /Scratch/$USER_NAME /home/users/$USER_NAME/scratch
chown $USER_NAME:grp-$USER_NAME /home/users/$USER_NAME/scratch

##QUOTA
echo " "
echo "Setting user quota..."
beegfs-ctl --setquota --uid $USER_ID --sizelimit=550G --inodelimit=unlimited

echo " "
echo "Adding of user completed without errors."
