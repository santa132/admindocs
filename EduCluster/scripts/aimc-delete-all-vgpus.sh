#!/bin/bash

usage="$(basename "$0") [-h] -- delete all vGPUs

where:
    -h  help"

while getopts g:r:h: flag
do
    case "${flag}" in
        h) echo "$usage" >&2 
           exit 1
           ;;
        :) echo "$usage" >&2 
           exit 1  
           ;;
       \?) printf "illegal option: -%s\n" "$OPTARG" >&2
           echo "$usage" >&2 
           exit 1  
           ;; 
    esac
done

cards=$(mdevctl list | awk '{print $1;}')

cards=($cards)

for i in "${cards[@]}";
do
    echo "============================================"
    echo "Card ID: ${i}";

    tries=10

    while [ "$tries" -gt 0 ]; do
        if bash aimc-delete-vgpu.sh -g "$i"
        then
            break
        fi
    tries=$(( tries - 1 ))
    done

    if [ "$tries" -eq 0 ]; then
        echo 'Failed to delete vGPU' >&2
    fi
done
