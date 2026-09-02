#!/bin/bash

USERLIST="list_add_user.txt"
PASSWORD="P@ssw0rd"

while read user; do
    # Skip empty lines
    [ -z "$user" ] && continue

    GROUP="grp-$user"

    echo "-----------------------------------------"
    echo "Processing user: $user (group: $GROUP)"
    echo "-----------------------------------------"

    # Create group (ignore if it already exists)
    obol group add "$GROUP"
    if [ $? -ne 0 ]; then
        echo "Group $GROUP already exists or error occurred → skipping."
    else
        echo "Group $GROUP created."
    fi

    # Create user with password
    obol user add -g "$GROUP" -p "$PASSWORD" "$user"
    if [ $? -ne 0 ]; then
        echo "User $user already exists or error occurred → skipping."
    else
        echo "User $user created with group $GROUP."
    fi

    echo ""

done < "$USERLIST"

