#!/bin/bash
HEADNODE="aimc-hn1"
USERLIST="/mnt/beegfs/adm/users_ssh_list.txt"

# Thêm fingerprint của headnode vào known_hosts (tránh prompt yes/no)
ssh-keyscan -H $HEADNODE >> /etc/ssh/ssh_known_hosts 2>/dev/null

while read -r user; do
    home="/home/users/$user"
    ssh_dir="$home/.ssh"
    key="$ssh_dir/id_rsa"

    if id "$user" &>/dev/null; then
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        primary_group=$(id -gn "$user")
        chown -R "$user:$primary_group" "$ssh_dir"

        if [ ! -f "$key" ]; then
            sudo -u "$user" ssh-keygen -t rsa -b 4096 -f "$key" -N "" -q
        fi

        sudo -u "$user" ssh-copy-id -o StrictHostKeyChecking=no -i "$key.pub" "$user@$HEADNODE"

        echo "✅ SSH no-password setup done for $user → $HEADNODE"
    else
        echo "⚠️ User $user not found on compute node, skipping..."
    fi
done < "$USERLIST"

