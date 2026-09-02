#!/bin/bash

USERLIST_FILE="list_add_user.txt"

# Node list for ssh-keyscan
NODES=(
    "aimc-gn1"
    "aimc-gn2"
    "aimc-gn3"
    "aimc-gn4"
    "aimc-gna1"
    "aimc-gna2"
    "aimc-h100-02"
)

### CHECK USERLIST FILE
if [[ ! -f "$USERLIST_FILE" ]]; then
    echo "ERROR: File $USERLIST_FILE does not exist!"
    exit 1
fi

echo "----- START ADD USER AUTOMATION -----"

### READ USERS FROM FILE
while IFS= read -r USER_NAME; do
    
    [[ -z "$USER_NAME" ]] && continue   # skip empty lines

    echo ">>> Processing user: $USER_NAME"

    USER_HOME="/home/users/$USER_NAME"
    USER_SSH="$USER_HOME/.ssh"

    # Get UID of the user
    USER_ID=$(id -u "$USER_NAME" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "User $USER_NAME does not exist! Skipping."
        continue
    fi

    ### CREATE ~/.ssh
    su - "$USER_NAME" -c "mkdir -p $USER_SSH"
    su - "$USER_NAME" -c "chmod 700 $USER_SSH"

    ### SSH-KEYSCAN for all nodes
    echo "  - Scanning SSH fingerprints..."
    for node in "${NODES[@]}"; do
        su - "$USER_NAME" -c "ssh-keyscan $node >> $USER_SSH/known_hosts 2>/dev/null"
    done

    ### GENERATE SSH KEYPAIR
    echo "  - Generating SSH keypair"
    su - "$USER_NAME" -c "ssh-keygen -t rsa -f $USER_SSH/id_rsa -q -N ''"

    ### authorized_keys
    su - "$USER_NAME" -c "cat $USER_SSH/id_rsa.pub > $USER_SSH/authorized_keys"
    chmod 600 "$USER_SSH/authorized_keys"
    chown -R "$USER_NAME:grp-$USER_NAME" "$USER_SSH"

    ### CREATE SCRATCH DIRECTORY
    echo "  - Creating /scratch/$USER_NAME"
    mkdir -p "/scratch/$USER_NAME"
    chmod 700 "/scratch/$USER_NAME"
    chown "$USER_NAME:grp-$USER_NAME" "/scratch/$USER_NAME"

    ### LINK SCRATCH
    su - "$USER_NAME" -c "ln -sf /scratch/$USER_NAME $USER_HOME/scratch"
    chown "$USER_NAME:grp-$USER_NAME" "$USER_HOME/scratch"

    ### SET QUOTA
    echo "  - Setting quota to 550G"
    beegfs-ctl --setquota --uid "$USER_ID" --sizelimit=550G --inodelimit=unlimited

    echo ">>> User $USER_NAME completed."
    echo ""

done < "$USERLIST_FILE"

echo "----- ALL USERS COMPLETED -----"
