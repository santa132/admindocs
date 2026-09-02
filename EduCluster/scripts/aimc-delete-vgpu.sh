#!/bin/bash

usage="$(basename "$0") [-h] [-g] -- delete the vGPU

where:
    -h  help
    -g  vGPU ID"

while getopts g:r:h: flag
do
    case "${flag}" in
        g) gpuid=${OPTARG};;
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
  echo "No vGPU ID provided. Use this command to check: mdevctl list"
  exit 1
fi

vgpu=$(mdevctl list | grep "$gpuid")
if [[ $? != 0 ]]; then
   echo "No vGPU with the provided ID"
   exit 1
else
   vgpu=(`echo ${vgpu}`);
fi

echo "1" > /sys/bus/pci/devices/"${vgpu[1]}"/mdev_supported_types/"${vgpu[2]}"/devices/"${vgpu[0]}"/remove

echo "Delete $gpuid successfully"
