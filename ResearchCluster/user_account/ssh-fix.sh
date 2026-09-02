#!/bin/bash
#
# add_user.sh: Add user to LDAP
#

#set -e
USER_NAME=$1

#SCAN ALL HOST IN THE CLUSTER
su - $USER_NAME -c "ssh-keyscan SUTD-hpc-hn1>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn1>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn1>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn2>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn2>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn3>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn3>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn4>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn4>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn5>>/home/users/$USER_NAME/.ssh/known_hosts; \
       ssh-keyscan SUTD-hpc-gn5>>/home/users/$USER_NAME/.ssh/known_hosts" 

#ssh-keygen -t rsa -f /home/users/$USER_NAME/.ssh/id_rsa -q -N ""
#cat /home/users/$USER_NAME/.ssh/id_rsa.pub > /home/users/$USER_NAME/.ssh/authorized_keys
#chmod 600 /home/users/$USER_NAME/.ssh/authorized_keys

echo "Fix ssh for user completed without errors."
