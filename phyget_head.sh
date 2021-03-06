#!/bin/bash
#
trap 'echo "Quit..."; exit 10' SIGINT

User='ADMIN'
Pass='PASSWORD'
iplst=`cat phyget_head.ip`
ipfilelst='phyget_dell.ip phyget_inspur.ip phyget_hp.ip'
OutputPath=/opscripts/auto_phymac/phymac_get/phyget_head/output

> phyget_dell.ip
> phyget_inspur.ip
> phyget_hp.ip
> phyget_unknown.ip

concurrent () {
  local tmpfile01=$(mktemp /tmp/file.XXXXXXXX)
  [ -e $tmpfile01 ] && mkfifo $tmpfile01
  exec 3<> $tmpfile01
  rm -f $tmpfile01
  for ((i=1;i<=10;i++))
  do
    echo >&3
  done
}

getPre () {
  PreInfo=`ipmitool -I lanplus -H $1 -U $User -P $Pass -N 5 -R 1 fru | sed -n '/FRU Device Description : Builtin FRU Device (ID 0)/,/Product Serial/p' |egrep 'Product Manufacturer|Product Name|Product Serial' | xargs echo | sed 's/Product//g'`
  Mfr=`echo $PreInfo | awk '{print $3}'`
  Mfr=${Mfr:-UNknown}
  if [ $Mfr == 'DELL' ]; then
    #ExpCode=`racadm -r $1 -u $User -p $Pass --nocertwarn getsysinfo | egrep '^Express Svc Code'`
    #echo $1 $PreInfo 'ExpressCode : '${ExpCode##* } | awk '{printf "  %-15s%-12s%-2s%-8s%-4s%-2s%-10s%-11s%-6s%-2s%-11s%-12s%-2s%-10s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14}'
    echo $1 $PreInfo | awk '{printf "  %-15s%-12s%-2s%-8s%-4s%-2s%-10s%-11s%-6s%-2s%-11s%-12s%-2s%-10s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14}'
    echo $1 >> phyget_dell.ip
  elif [ $Mfr == 'Inspur' ]; then
    echo $1 $PreInfo | awk '{printf "  %-15s%-12s%-2s%-8s%-4s%-2s%-21s%-6s%-2s%-12s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10}'
    echo $1 >> phyget_inspur.ip
  elif [ $Mfr == 'HP' -o $Mfr == 'HPE' ]; then
    echo $1 $PreInfo | awk '{printf "  %-15s%-12s%-2s%-8s%-4s%-2s%-9s%-6s%-6s%-6s%-2s%-12s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12}'
    echo $1 >> phyget_hp.ip
  elif [ $Mfr == 'UNknown' ]; then
    echo $1 $PreInfo | awk '{printf "  %-15s%-12s%-2s%-8s%-4s%-2s%-9s%-6s%-6s%-6s%-2s%-12s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12}'
    echo $1 >> phyget_unknown.ip
  fi
}
start_time=`date +%s`

if [[ -n $iplst ]]; then
  echo -e '\n  =================================================================================='
  echo '  Basic Info'
  curtime=`date +%Y-%m-%d_%H-%M-%S`
  outfile_h=$OutputPath/phyget_head_${curtime}.output
  touch $outfile_h
  for j in $iplst; do
#    read -u3
#    {
    getPre $j | tee -a $outfile_h
#    echo >&3
#    }&
  done
#  wait
#  stop_time=`date +%s`
#  echo "TIME:`expr $stop_time - $start_time`"
#  exec 3<&-
#  exec 3>&-
else
  echo "  ===================="
  echo "  Warning!!!"
  echo "  Pls fill the ip list"
  echo "  ===================="
fi

getSh () {
  echo $1 | sed 's/ip/sh/g'
}

for k in $ipfilelst; do
  if [[ -s $k ]]; then
    ./`getSh $k`
  fi
done
