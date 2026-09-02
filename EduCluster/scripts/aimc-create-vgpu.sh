#!/bin/bash

usage="$(basename "$0") [-h] [-g] [-r] -- create a new vGPU

where:
    -h  help
    -g  GPU ID (Use this command to check: lspci | grep NVIDIA)
    -r  RAM of vGPU (4, 8, 16)"

while getopts g:r:h: flag
do
    case "${flag}" in
        g) gpuid=${OPTARG};;
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

if [[ -z "$gpuid" ]] ; then
  echo "No GPU ID provided. Use this command to check: lspci | grep NVIDIA"
  exit 1
fi

if [[ -z "$ram" ]] ; then
  echo "No vRAM provided"
  exit 1
fi
echo "grep -l V100DX-"$ram"Q /sys/bus/pci/devices/0000:"$gpuid"/mdev_supported_types/nvidia-*/name"

nvidia_type=$(grep -l V100DX-"$ram"Q /sys/bus/pci/devices/0000:"$gpuid"/mdev_supported_types/nvidia-*/name)
if [[ $? != 0 ]]; then
   echo "Command failed."
   exit 1
else
   nvidia_type=$(dirname $nvidia_type)
fi

avail=$(cat "$nvidia_type"/available_instances)
if [[ $avail -eq "0" ]] ; then
   echo "No available instances. Exited!"
   exit 0
else
   echo "Available instances: $avail"
fi

uuid=$(uuidgen)
echo "----------"
echo "Creating new instance"
echo $uuid > "$nvidia_type"/create
mdevctl define --auto --uuid $uuid

echo "New instance is created. The UUID is"
echo "$uuid"
