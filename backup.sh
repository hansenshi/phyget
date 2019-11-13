#!/bin/bash
#
curtime=`date +%Y%m%d_%H%M%S`

for i in phyget_{head,inspur,dell,hp}.sh; do
  cp $i backup/${i}_${curtime} && echo -e " Backup ${i} complete" | awk '{printf " %-8s%-18s%-10s\n",$1,$2,$3}'
done
