#!/bin/bash -
#===============================================================================
#          FILE: home-bak.sh
#         USAGE: ./home-bak.sh
#   DESCRIPTION:
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: NamDuong Nguyen
#  ORGANIZATION: AI Mega Centre
#       CREATED: 09/02/2022 13:30
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

if [ $# -eq 0 ] ; then
   echo "Wrong input parameters"  >> /mnt/beegfs/home-bak/home-bak-daily.log
   exit
fi
if [ "$1" == "daily" ]; then
rsync -ar /home/users/  /mnt/beegfs/home-bak

echo "Backup of home directories $? on `date +%d%b%y-%H:%M` " >> /mnt/beegfs/home-bak/home-bak-daily.log
fi
