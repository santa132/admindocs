#!/bin/bash

START=100000        # start UID range
RANGE=65536         # each user gets a unique 65536 space
FILE_SUBUID="/etc/subuid"
FILE_SUBGID="/etc/subgid"

echo "[*] Backup old subuid/subgid..."
cp $FILE_SUBUID ${FILE_SUBUID}.bak
cp $FILE_SUBGID ${FILE_SUBGID}.bak

echo "[*] Processing all HPC users..."

# list all valid HPC users (from /etc/passwd and home under /home/users)
users=$(awk -F: '$3>=500 && $3<60000 && $7=="/bin/bash" {print $1}' /etc/passwd)

for user in $users; do
    # skip if user already has subuid
    if grep -q "^$user:" $FILE_SUBUID; then
        echo "[SKIP] $user đã có subuid"
        continue
    fi

    echo "$user:$START:$RANGE" | tee -a $FILE_SUBUID
    echo "$user:$START:$RANGE" | tee -a $FILE_SUBGID

    echo "[ADD] $user: $START:$RANGE"

    START=$((START + RANGE))
done

echo "[DONE] Subuid/subgid updated!"
