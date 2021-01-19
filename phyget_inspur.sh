#!/bin/bash
#
trap 'echo "Quit..."; exit 10' SIGINT

echoUsage_cn () {
  cat << EOF
  
  ==================================================================================
  ||||||                     【浪潮】物理机信息查询                          |||||||
  ==================================================================================
  
  ==================================================================================
  help info
  
  --预信息及其它--
  getpre) 抓取预信息                       clearup) 清除临时文件 
  getsysinfo) 系统信息                     quit) 退出
  
  --物理机初始化设定查询--
  getsp) 查询节电模式                       
  getprocvt) 查询处理器虚拟化功能          getntp) 查询NTP信息
  getprocthread) 查询处理器多线程功能      getsnmp) 查询snmp设定信息
  getbootmode) 查询bios启动模式            getuser) 查询用户设定信息
  getbootseq) 查询bios启动顺序             getstoragevdisk) 查询存储虚拟磁盘信息
  
  --物理机内部设备状态查询--
  getrollup) 物理机汇总状态                getfan) 风扇状态
  getpwrsw) 是否开机                       gettemp) 温度状态
  getprocessor) 处理器状态                 getvoltage) 电压状态
  getmemory) 内存状态                      getstoragestatus) 查询存储汇总状态
  getpci) 设备列表                         getstoragecontroller) 查询存储控制卡信息
  getnic) 网卡信息                         getstoragebattery) 查询存储电池信息
  getpsu) 电源状态                         getstoragepdisk) 查询存储物理磁盘信息
  
  --自动查询--
  getallbyip) 按IP查询所有项               getallbyfun) 按具项查询所有项
  
  --常用操作--
  adduser) 添加带外用户                    deluser) 删除带外用户
  collectlog) 日志收集
  ================================================================================== 
  
EOF
}

# function start

getPre () {
  $ExeCmd -H $1 -U $User -P $Pass getBios > $PrePath/phyget_inspur_bios_${1}.pre && echo "  Bios Preinfo complete"
  $ExeCmd -H $1 -U $User -P $Pass getServerStatus | grep -v '-' | sed 's/^/  /g' > $PrePath/phyget_inspur_serverstatus_${1}.pre && echo "  Device Preinfo complete"
}

# init settings query
getSavePower () {
  if [ -s $PrePath/phyget_inspur_bios_${1}.pre ]; then
    grep -E '^Power\/PerformanceProfile' $PrePath/phyget_inspur_bios_${1}.pre | xargs echo | sed 's/^/  /g'
  else
    echo "  NO Bios info , pls exec [getpre]"
  fi
}

getProcVT () {
  if [ -s $PrePath/phyget_inspur_bios_${1}.pre ]; then
    grep -E '^VT-d' $PrePath/phyget_inspur_bios_${1}.pre | xargs echo | sed 's/^/  /g'
  else
    echo "  NO Bios info , pls exec [getpre]"
  fi
}

getProcThread () {
  if [ -s $PrePath/phyget_inspur_bios_${1}.pre ]; then
    grep -E '^HyperThreadingTechnology|Hyper-Threading' $PrePath/phyget_inspur_bios_${1}.pre | xargs echo | sed 's/^/  /g'
  else
    echo "  NO Bios info , pls exec [getpre]"
  fi
}

getBootMode () {
  if [ -s $PrePath/phyget_inspur_bios_${1}.pre ]; then
    grep -E '^(BootMode|Network|Storage|VideoOPROMPolicy|OtherPCIdevices)\>' $PrePath/phyget_inspur_bios_${1}.pre | xargs echo | sed 's/^/  /g'
  else
    echo "  NO Bios info , pls exec [getpre]"
  fi
}

getBootSeq () {
  if [ -s $PrePath/phyget_inspur_bios_${1}.pre ]; then
    grep -E '^(BootOptionsRetry|BootOption1|BootOption2|BootOption3)' $PrePath/phyget_inspur_bios_${1}.pre | xargs echo | sed 's/^/  /g'
  else
    echo "  NO Bios info , pls exec [getpre]"
  fi
}

getNtp () {
  $ExeCmd -H $1 -U $User -P $Pass getNTP | sed 's/^/  /g'
}

getSnmp () {
  echo -n '  '
  echo "Inspur snmp community is inspur@0531, can't be changed."
}

getUser () {
  ipmitool -I lanplus -H $1 -U $User -P $Pass user list | sed -e 's/^/  /g'
  #$ExeCmd -H $1 -U $User -P $Pass getUser | egrep 'enable' | xargs echo
}

getStorageVdisk () {
  local a i
  $ExeCmd -H $1 -U $User -P $Pass getVirtualDrive | egrep '^Capacity \(GB\)|^index|^Primary RAID Level|^Logical Drive State|^physicaldisks|^status|^Encryption Type' | while read LINE; do
    local LINE=`echo $LINE | xargs`
    if [[ $LINE =~ 'Capacity (GB)' ]]; then
      a=`spaNum "$LINE" 26`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'index' ]]; then
      a=`spaNum "$LINE" 10`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'Primary RAID Level' ]]; then
      a=`spaNum "$LINE" 24`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'Logical Drive State' ]]; then
      a=`spaNum "$LINE" 30`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'physicaldisks' ]]; then
      a=`spaNum "$LINE" 40`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'status' ]]; then
      a=`spaNum "$LINE" 15`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'Encryption Type' ]]; then
      echo
    fi
  done
}

# inventory status query
getRollup () {
  if [ -e $PrePath/phyget_inspur_serverstatus_${1}.pre ]; then
    local j=0
    while read LINE ; do
      [[ $LINE =~ 'OK' ]] && let j++
    done < $PrePath/phyget_inspur_serverstatus_${1}.pre
    echo "  ---------------------------------------"
    if [ $j -lt 10 ]; then
      echo "  ServerRollupStatus : Failure" | awk '{printf "  %-30s%-2s%-10s\n",$1,$2,$3}'
    else
      echo "  ServerRollupStatus : OK" | awk '{printf "  %-30s%-2s%-10s\n",$1,$2,$3}'
    fi
    echo "  ---------------------------------------"
    cat $PrePath/phyget_inspur_serverstatus_${1}.pre
  else
    echo "  No PreInfo File, Please Exec [getpre]"
  fi
}

getPowerStatus () {
  echo -n '  '
  $ExeCmd -H $1 -U $User -P $Pass getPowerStatus | egrep 'P.*S.*' | xargs echo
}

getProcessor () {
  $ExeCmd -H $1 -U $User -P $Pass getCPU | egrep 'CPUCount|ID|Model|CPUStatus|TotalCores' | while read LINE; do
  if [[ $LINE =~ CPUCount ]]; then 
    echo '  '$LINE
  elif [[ $LINE =~ TotalCores ]]; then 
    echo '  '$LINE
  else
    echo -n '  '$LINE
  fi
  done
}

getMemory () {
  local tmpfile01=$(mktemp /tmp/file.XXXXXXXX)
  local tmpfile02=$(mktemp /tmp/file.XXXXXXXX)
  local stra
  local j k
  $ExeCmd -H $1 -U $User -P $Pass getMemory | egrep 'MemCount|MemId|MemVendor|MemPresent|MemSize\(GB\)|MemType|MemStatus|MemFrequency\(MHZ\)' > $tmpfile01
  j=`cat $tmpfile01 | egrep 'MemCount' | grep -o '[0-9]\{1,\}'`
  cat $tmpfile01 | grep 'MemCount' | xargs &> /dev/null && sed -i '1d' $tmpfile01
   
  until [ $j -lt 1 ]; do
    stra=`head -7 $tmpfile01 | xargs echo`
    echo '  '$stra |awk '{printf "  %-6s%-2s%-4s%-10s%-2s%-8s%-11s%-2s%-5s%-11s%-2s%-4s%-8s%-2s%-6s%-10s%-2s%-4s%-18s%-2s%-3s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21}' >> $tmpfile02
    sed -i '1,7d' $tmpfile01
    let j-=1
  done
  echo -e "\n  getMemory_${1}"
  grep 'MemPresent : Yes' $tmpfile02 && grep 'MemPresent : No' $tmpfile02 
  rm -f $tmpfile01 $tmpfile02
}

getPci () {
  local a i
  $ExeCmd -H $1 -U $User -P $Pass getPCIE | egrep 'ID|PresentStatus|DeviceType|DeviceID|VendorID' | while read LINE; do
  local LINE=`echo $LINE | xargs`
  if [[ $LINE =~ 'PresentStatus' ]]; then
    a=`spaNum "$LINE" 16`
    echo -n '  '"$LINE"
    for i in `seq 1 $a`; do echo -n ' '; done
  elif [[ $LINE =~ 'DeviceType' ]]; then
    a=`spaNum "$LINE" 36`
    echo -n '  '"$LINE"
    for i in `seq 1 $a`; do echo -n ' '; done
  elif [[ $LINE =~ 'DeviceID' ]]; then
    a=`spaNum "$LINE" 50`
    echo -n '  '"$LINE"
    for i in `seq 1 $a`; do echo -n ' '; done
  elif [[ $LINE =~ 'VendorID' ]]; then
    a=`spaNum "$LINE" 40`
    echo -n '  '"$LINE"
    for i in `seq 1 $a`; do echo -n ' '; done
    echo
  elif [[ $LINE =~ 'ID' ]]; then
    a=`spaNum "$LINE" 6`
    echo -n '  '"$LINE"
    for i in `seq 1 $a`; do echo -n ' '; done
  fi
  done
}

getNic () {
  $ExeCmd -H $1 -U $User -P $Pass getNetworkAdapter | sed -e 's/^/  /g'
}

getPsu () {
  local a i
  echo -n '  '
  $ExeCmd -H $1 -U $User -P $Pass getPsu | egrep '^PsuCount|^ID|^Present|^Status|^PsuStatus' | while read LINE; do
    local LINE=`echo $LINE | xargs`
    if [[ $LINE =~ 'PsuCount' ]]; then
      a=`spaNum "$LINE" 10`
      echo -n "$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'ID' ]]; then
      a=`spaNum "$LINE" 10`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'Present' ]]; then
      a=`spaNum "$LINE" 10`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'PsuStatus' ]]; then
      echo '  '"$LINE"
    elif [[ $LINE =~ 'Status' ]]; then
      a=`spaNum "$LINE" 18`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    fi
    done
}

getFan () {
  local j
  declare -i j=0
  echo -n '  '
  $ExeCmd -H $1 -U $User -P $Pass getFan | egrep 'FanCount|ID|Present|Status' | while read LINE; do
  if [[ $LINE =~ 'FanCount' ]]; then
    echo $LINE
  fi
  [ $j -eq 1 ] && echo -n '  '$LINE
  [ $j -ge 2 ] && [ $j -le 11 ] && echo -n ' '$LINE
  [ $j -eq 12 ] && echo ' '$LINE
  [ $j -eq 13 ] && echo -n '  '$LINE
  [ $j -ge 14 ] && [ $j -le 23 ] && echo -n ' '$LINE
  [ $j -eq 24 ] && echo ' '$LINE
  let j+=1
  done
}

getTemperature () {
  local j
  declare -i j=1
  $ExeCmd -H $1 -U $User -P $Pass getSensor | egrep 'Temp' | awk '{print $1,$2}' | while read LINE; do
    echo -n '  ' && echo $LINE | awk '{printf "%-19s%-14s\n",$1,$2}' 
    let j+=1
  done
}

getVoltage () {
  $ExeCmd -H $1 -U $User -P $Pass getSensor | egrep -v 'Temp|Hot' | egrep 'V' | while read LINE; do
    echo -n '  ' && echo $LINE | awk '{printf "%-19s%-14s\n",$1,$2}'
  done
}

getStorageStatus () {
  if [ -e $PrePath/phyget_inspur_serverstatus_${1}.pre ]; then
    cat $PrePath/phyget_inspur_serverstatus_${1}.pre | grep 'Storage' | xargs | sed 's/^/  /g'
  else
    echo "  No PreInfo File, Please Exec [getpre]"
  fi
}

getStorageController () {
  echo -n '  '
  $ExeCmd -H $1 -U $User -P $Pass getController | egrep 'Product Name|^Vendor\(ID\)|Firmware Version|^Drive Count|^Virtual Drive Count|abtCCOnErr' | xargs echo
}

getStorageBattery () {
  echo -n '  '
  echo "Not associate for inspur."
}

getStoragePdisk () {
  local a i
  $ExeCmd -H $1 -U $User -P $Pass getPhysicalDrive | egrep 'Product ID|Device ID|Coerced size \(GB\)|Firmware State|Vendor Specific Info' | while read LINE; do
    local LINE=`echo $LINE | xargs`
    if [[ $LINE =~ 'Product ID' ]]; then
      echo '  '$LINE
    elif [[ $LINE =~ 'Device ID' ]]; then
      a=`spaNum "$LINE" 14`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'Coerced size (GB)' ]]; then
      a=`spaNum "$LINE" 30`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'Firmware State' ]]; then
      a=`spaNum "$LINE" 26`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'Vendor Specific Info' ]]; then
      a=`spaNum "$LINE" 35`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    fi
   done
}

# function stop


cycleSingleByIp () {
  local i
  for i in $iplst; do
    local outfile=$OutputPath/phyget_inspur_${1}_${i}_${curtime}.output
    touch $outfile
    echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
    echo -e "  ${i}_${1}" | tee -a $outfile
    $1 $i | tee -a $outfile
  echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
  done
}

cycleSingleByFunction () {
  #start_time=`date +%s`
  local i
  local outfile=$OutputPath/phyget_inspur_${1}_${curtime}.output
  touch $outfile
  echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
  echo -e "  查询单项_${1}" | tee -a $outfile
  for i in $iplst; do
    #read -u3
    #{
    echo -e "\n  ${1}_${i}" | tee -a $outfile
    $1 $i | tee -a $outfile
    #echo >&3
    #}&
  done
  wait
  
  #stop_time=`date +%s`
  #echo "TIME:`expr $stop_time - $start_time`"
  #exec 3<&-
  #exec 3>&-
  echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
}

cycleAllByIp () {
  local i j
  local scrp=`basename $0`
  local funlst=`sed -n '/^# function start.*/,/^# function stop.*/p' $scrp | grep 'get[A-Z].*()' | egrep -o '^get[A-Z].*[a-z]|^get[A-Z].*[A-Z]'`
  for i in $iplst; do
    local outfile=$OutputPath/phyget_inspur_all_${i}_${curtime}.output
    touch $outfile
    echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
    echo -e "  查询所有项_${i}" | tee -a $outfile
    echo | tee -a $outfile
    for f in $funlst; do
      echo -e '\n  '${i}_${f} | tee -a $outfile
      $f $i | tee -a $outfile
    done
  echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
  done
}

cycleAllByFunction () {
  local i j
  local scrp=`basename $0`
  local funlst=`sed -n '/^# function start.*/,/^# function stop.*/p' $scrp | grep 'get[A-Z].*()' | egrep -o '^get[A-Z].*[a-z]|^get[A-Z].*[A-Z]'`
  for f in $funlst; do
    local outfile=$OutputPath/phyget_inspur_all_${f}_${curtime}.output
    touch $outfile
    echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
    echo -e "  查询所有项_${f}\n" | tee -a $outfile
    for i in $iplst; do
      echo -e '\n  '${f}_${i} | tee -a $outfile
      $f $i | tee -a $outfile
    done
  echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
  done
}

collectLog () {
  echo
  echo "  Start time: "`date +%Y-%m-%d_%H:%M:%S`; echo
  echo "  Running..."
  $ExeCmd -H $1 -U $User -P $Pass getLog &> /dev/null && echo -e "  Log Collection Completed \n  View the logfiles on ${LogPath}${1} "
  echo
  echo "  End time: "`date +%Y-%m-%d_%H:%M:%S`
}

addUser () {
#  local UserN PassN
#  read -p "  用户名: " UserN
#  read -sp "    密码: " PassN ; echo
#  UserN='adminxxx'
#  PassN='passwordxxx'
  echo
  $ExeCmd -H $1 -U $User -P $Pass addUser -N $UserN -PWD $PassN -G Administrator -ACCESS enable &> /dev/null && echo "  User $UserN add success"
  #$ExeCmd -H $1 -U $User -P $Pass addUser -N $UserN -PWD $PassN -G administrator -ACCESS enable && echo "  User $UserN add success"
}

delUser () {
  echo
  $ExeCmd -H $1 -U $User -P $Pass delUser -N $UserO &> /dev/null && echo "  User $UserO delete success"
}

getSysInfo () {
  $ExeCmd -H $1 -U $User -P $Pass getFru | egrep 'Product Manufacturer|Product Name|Product Serial' | xargs | sed 's/^/  /g'
}

spaNum () {
  local chvar=$1
  local hopenum=$2
  local chnum=${#chvar}
  local addnum=$[$hopenum-$chnum]
  echo $addnum
}

clearUp () {
  rm -f $OutputPath/* && rm -f $PrePath/* && echo "  Clearup tmpfile finished"
}

quit () {
  exit 0
}

mkdir -p ./phyget_inspur/{output,pre} &> /dev/null
FilePath=./phyget_inspur
OutputPath=$FilePath/output
PrePath=$FilePath/pre
LogPath=/opt/ISREST/ISREST-Linux-V1R1/logs/
ExeCmd=/opt/ISREST/ISREST-Linux-V1R1/bin/isrest

User='ADMIN'
Pass='PASSWROD'
ReadCommunity='COMMUNITY'
iplst=`cat phyget_inspur.ip`
curtime=`date +%Y-%m-%d_%H-%M-%S`

[ -e /tmp/fd1 ] || mkfifo /tmp/fd1
exec 3<> /tmp/fd1
rm -f /tmp/fd1
for ((i=1;i<=1;i++))
do
  echo >&3
done

echoUsage_cn
read -p "  你的选择: " CHOICE
CHOICE=${CHOICE:-UNknown}

until [ $CHOICE == quit ]; do
case $CHOICE in
  getpre)
    cycleSingleByFunction getPre
    ;;
  getsysinfo)
    cycleSingleByFunction getSysInfo
    ;;
  getsp)
    cycleSingleByFunction getSavePower
    ;;
  getprocvt)
    cycleSingleByFunction  getProcVT
    ;;
  getprocthread)
    cycleSingleByFunction getProcThread
    ;;
  getbootmode)
    cycleSingleByFunction getBootMode
    ;;
  getbootseq)
    cycleSingleByFunction  getBootSeq
    ;;
  getntp)
    cycleSingleByFunction getNtp
    ;;
  getsnmp)
    cycleSingleByFunction getSnmp
    ;;
  getuser)
    cycleSingleByFunction getUser
    ;;
  getstoragevdisk)
    cycleSingleByFunction getStorageVdisk
    ;;
  getrollup)
    cycleSingleByFunction getRollup
    ;;
  getpwrsw)
    cycleSingleByFunction getPowerStatus
    ;;
  getprocessor)
    cycleSingleByFunction getProcessor
    ;;
  getmemory)
    cycleSingleByFunction getMemory
    ;;
  getpci)
    cycleSingleByFunction getPci
    ;;
  getnic)
    cycleSingleByFunction getNic
    ;;
  getpsu)
    cycleSingleByFunction getPsu
    ;;
  getfan)
    cycleSingleByFunction getFan
    ;;
  gettemp)
    cycleSingleByFunction getTemperature
    ;;
  getvoltage)
    cycleSingleByFunction getVoltage
    ;;
  getstoragestatus)
    cycleSingleByFunction getStorageStatus
    ;;
  getstoragecontroller)
    cycleSingleByFunction getStorageController
    ;;
  getstoragebattery)
    cycleSingleByFunction getStorageBattery
    ;;
  getstoragepdisk)
    cycleSingleByFunction getStoragePdisk
    ;;
  adduser)
    read -p "  用户名: " UserN
    read -sp "    密码: " PassN ; echo
    cycleSingleByFunction addUser
    ;;
  deluser)
    read -p "  用户名: " UserO
    cycleSingleByFunction delUser
    ;;
  collectlog)
    cycleSingleByFunction collectLog
    ;;
  getallbyfun)
    cycleAllByFunction
    ;;
  getallbyip)
    cycleAllByIp
    ;;
  clearup)
    clearUp
    ;;
  *)
    echo -e "  未知选项\n"
    ;;
  esac
  echoUsage_cn
  read -p "  你的选择: " CHOICE
  CHOICE=${CHOICE:-UNknown}
done
