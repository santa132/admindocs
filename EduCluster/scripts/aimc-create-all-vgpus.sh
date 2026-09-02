#!/bin/bash

usage="$(basename "$0") [-h] [-r] -- create all vGPUs

where:
    -h  help
    -r  RAM of vGPU (4, 8, 16)"

while getopts g:r:h: flag
do
    case "${flag}" in
        r) ram=${OPTARG};;
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

if [[ -z "$ram" ]] ; then
  echo "No vRAM provided!"
  echo "$usage" >&2
  exit 1
fi

cards=$(lspci | grep NVIDIA | awk '{print $1;}')

cards=($cards)

for i in "${cards[@]}";
do
    echo "============================================"
    echo "Card ID: ${i}";

    tries=10

    while [ "$tries" -gt 0 ]; do
        if bash aimc-create-vgpu.sh -g "$i" -r "$ram" | grep -q 'No available instances'
        then
            break
        fi

    tries=$(( tries - 1 ))
    done

    if [ "$tries" -eq 0 ]; then
        echo 'Failed to create new vGPU' >&2
    fi

   #bash aimc-create-vgpu.sh -g "$i" -r "$ram"
done
