#!/bin/bash
# ==============================================
# Append new users and groups from getent
# into /etc/passwd and /etc/group
# (no overwrite)
# ==============================================

HOST=$(hostname)
BACKUP_DIR="/adm/hpc/backup_etc/${HOST}"

mkdir -p "$BACKUP_DIR"

echo "[*] Backing up /etc/passwd and /etc/group to $BACKUP_DIR"
cp /etc/passwd "$BACKUP_DIR/passwd.bak"
cp /etc/group "$BACKUP_DIR/group.bak"

# ==============================================
# Append USERS
# ==============================================
echo "[*] Appending new users from getent passwd..."
getent passwd > /tmp/passwd.new

while IFS=: read -r user pw uid gid gecos home shell; do
    if ! grep -q "^${user}:" /etc/passwd; then
        echo "${user}:${pw}:${uid}:${gid}:${gecos}:${home}:${shell}" >> /etc/passwd
        echo " + Added user: ${user}"
    fi
done < /tmp/passwd.new

# ==============================================
# Append GROUPS
# ==============================================
echo "[*] Appending new groups from getent group..."
getent group > /tmp/group.new

while IFS=: read -r group pw gid members; do
    if ! grep -q "^${group}:" /etc/group; then
        echo "${group}:${pw}:${gid}:${members}" >> /etc/group
        echo " + Added group: ${group}"
    fi
done < /tmp/group.new

chmod 644 /etc/passwd /etc/group
chown root:root /etc/passwd /etc/group

echo "[✅] Done on node $HOST"
echo "[ℹ️] Backup saved in $BACKUP_DIR"
