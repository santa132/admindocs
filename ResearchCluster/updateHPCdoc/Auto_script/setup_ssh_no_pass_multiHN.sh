#!/bin/bash
# List of headnodes
HEADNODES=("aimc-hn1" "aimc-hn2")
#USERLIST="/adm/hpc/auto-script/users_ssh_list.txt"
USERLIST=( $(getent passwd | awk -F: '$3 >= 1000 && $2 == "*" {print $1}') )

# Add fingerprints of all headnodes to known_hosts (avoid yes/no prompt)
for hn in "${HEADNODES[@]}"; do
    ssh-keyscan -H "$hn" >> /etc/ssh/ssh_known_hosts 2>/dev/null
done

# Loop through each user in the list
for user in "${USERLIST[@]}"; do
    home="/home/users/$user"
    ssh_dir="$home/.ssh"
    key="$ssh_dir/id_rsa"

    if id "$user" &>/dev/null; then
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        primary_group=$(id -gn "$user")
        chown -R "$user:$primary_group" "$ssh_dir"

        # Generate key if not exists
        if [ ! -f "$key" ]; then
            sudo -u "$user" ssh-keygen -t rsa -b 4096 -f "$key" -N "" -q
        fi

        # Copy key to all headnodes
        for hn in "${HEADNODES[@]}"; do
            sudo -u "$user" ssh-copy-id -o StrictHostKeyChecking=no -i "$key.pub" "$user@$hn"
            echo "✅ SSH no-password setup done for $user → $hn"
        done
    else
        echo "⚠️ User $user not found on compute node, skipping..."
    fi
done

