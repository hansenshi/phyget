#!/bin/bash
#
trap 'echo "Quit..."; exit 10' SIGINT

echoUsage_cn () {
cat << EOF

  ==================================================================================
  ||||||                     【惠普】物理机信息查询                          |||||||
  ==================================================================================
  
  ==================================================================================
  help info
  
  --预信息及其它--
  getpre) 抓取预信息                       clearup) 清除临时文件 
  getsysinfo) 系统信息                     quit) 退出  
  getlicense) 许可信息
  
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
  ================================================================================== 

EOF
}

# function start

getPre () {
  perl $ExeCmd -s $1 -u $User -p $Pass -f $XPath/Get_EmHealth.xml | sed -e 's@"@@g' -e 's@</@@g' -e 's@/>@@g' -e 's@[<|>]@@g' -e 's@VALUE @@g' | sed -n '/GET_EMBEDDED_HEALTH_DATA/,/GET_EMBEDDED_HEALTH_DATA/p' > $PrePath/phyget_hp_EmHealth_${1}.pre && echo "  EmbeddedHealth Info complete"
}

# init settings query

getSavePower () {
  echo -n '  '
  perl $ExeCmd -s $1 -u $User -p $Pass -f $XPath/GET_HOST_POWER_SAVER.xml | grep -A 1 GET_HOST_POWER_SAVER | grep -v 'GET_HOST_POWER_SAVER' | sed -e 's/\"/ /g' -e 's/^[ \t]*//g'
}

getProcVT () {
  echo -n '  '
  echo 'Not found how to check.'
}

getProcThread () {
  snmpwalk $1 -v 2c -c $ReadCommunity CPQSTDEQ-MIB::cpqSeCPUMultiThreadStatus | while read LINE; do
    if [[ $LINE =~ 'enabled' ]]; then
      echo -n "  CPU `echo $LINE | grep -o cpqSeCPUMultiThreadStatus.[0-9] | grep -o [0-9]` Hyper-Threading is On."
    else
      echo -n "  CPU `echo $LINE | grep -o cpqSeCPUMultiThreadStatus.[0-9] | grep -o [0-9]` Hyper-Threading is Off."
    fi
  done
  echo
}

getBootMode () {
  echo -n '  '
  perl $ExeCmd -s $1 -u $User -p $Pass -f $XPath/GET_CURRENT_BOOT_MODE.xml | sed -n '/<GET_CURRENT_BOOT_MODE>/,/<\/GET_CURRENT_BOOT_MODE>/p' | dos2unix | sed -e '/GET_CURRENT_BOOT_MODE/d' -e 's/VALUE//g' -e 's@[/|<|>]@@g' -e 's/"/ /g' -e 's@^[ ]*@@g'
}

getBootSeq () {
  local i=1
  perl $ExeCmd -s $1 -u $User -p $Pass -f $XPath/GET_PERSISTENT_BOOT.xml |sed -n '/<PERSISTENT_BOOT>/,/<\/PERSISTENT_BOOT>/p' | sed '/PERSISTENT_BOOT/d' |sed -e 's@[<|>|/|]@@g' -e 's/^[[:space:]]*//g' -e 's/"/ /g' | dos2unix | while read LINE; do
    if [ $i -le 3 ]; then
      echo -n "  $i $LINE"
      let i++
    else
      break 1
    fi
  done
  echo
}

getNtp () {
  perl $ExeCmd -s $1 -u $User -p $Pass -f $XPath/GET_NETWORK_SETTINGS.xml | egrep 'PROPAGATE|SNTP_SERVER|DHCP_SNTP|DHCPV6_SNTP|TIME' | sed -e 's@<@@g' -e 's@/>@@g' -e 's/"/ /g' -e 's/VALUE//g' -e s/^[[:space:]]*//g | xargs | sed -e 's/^/  /g' 
}

getSnmp () {
  perl $ExeCmd -s $1 -u $User -p $Pass -f $XPath/GET_GLOBAL_SETTINGS.xml | grep SNMP_ACCESS_ENABLED | sed -e 's/[<|/|>| ]//g' -e 's@"@ @g' -e 's/^/  /g'
  perl $ExeCmd -s $1 -u $User -p $Pass -f $XPath/GET_SNMP_IM_SETTINGS.xml | egrep 'SNMP_ACCESS\>|1_ROCOMMUNITY\>' | sed -e 's/[<|/|>| ]//g' -e 's@"@ @g'  | xargs | sed -e 's/^/  /g'
}

getUser () {
  ipmitool -I lanplus -H $1 -U $User -P $Pass user list | sed -e 's/^/  /g'
}

getStorageVdisk () {
  local i
  if [ -s $PrePath/phyget_hp_EmHealth_${1}.pre ]; then
  cat $PrePath/phyget_hp_EmHealth_${1}.pre | sed -n '/\<LOGICAL_DRIVE$/,/\<LOGICAL_DRIVE$/p' | sed -n '/\<LOGICAL_DRIVE$/,/\<PHYSICAL_DRIVE$/p' | sed -e '/\<LOGICAL_DRIVE\>/d' -e '/PHYSICAL_DRIVE/d' -e '/ENCRYPTION_STATUS/d' | while read LINE; do
    LINE=${LINE:-Unknown}
    if [[ $LINE =~ 'LOGICAL_DRIVE_TYPE' ]]; then
      echo '  '$LINE
    elif [[ $LINE =~ 'LABEL' ]]; then
      a=`spaNum "$LINE" 8`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'STATUS' ]]; then
      a=`spaNum "$LINE" 8`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'CAPACITY' ]]; then
      a=`spaNum "$LINE" 14`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'FAULT_TOLERANCE' ]]; then
      a=`spaNum "$LINE" 24`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    fi
  done
  else
    echo "  No PreInfo , Pls exec [getpre]"
  fi
}

# inventory status query
getRollup () {
  if [ -s $PrePath/phyget_hp_EmHealth_${1}.pre ]; then
  echo "  ---------------------------------------"
  if ! cat $PrePath/phyget_hp_EmHealth_${1}.pre | sed -n '/HEALTH_AT_A_GLANCE/,/HEALTH_AT_A_GLANCE/p' | sed '/HEALTH_AT_A_GLANCE/d' | egrep -v 'OK|Redundant' &> /dev/null; then
    echo "  ServerRollup Status = OK" | awk -F '=' '{printf "%-30s=%-10s\n",$1,$2}'
  else
    echo "  ServerRollup Status = Failure" | awk -F '=' '{printf "%-30s=%-10s\n",$1,$2}'
  fi
  echo "  ---------------------------------------"
  cat $PrePath/phyget_hp_EmHealth_${1}.pre | sed -n '/HEALTH_AT_A_GLANCE/,/HEALTH_AT_A_GLANCE/p' | sed -e'/HEALTH_AT_A_GLANCE/d' -e 's/^[ \t]*//g' -e 's/^/  /g' | awk -F '=' '{printf "%-30s=%-10s\n",$1,$2}'
  else
    echo "  No PreInfo , Pls exec [getpre]"
  fi
}

getPowerStatus () {
  echo -n '  '
  perl $ExeCmd -s $1 -u $User -p $Pass -f $XPath/GET_HOST_POWER_STATUS.xml | grep -A 1 'GET_HOST_POWER' | grep -v 'GET_HOST_POWER' | grep -o "[^[:space:]]\{1,\}" | sed 's/"/ /g'
}

getProcessor () {
  if [ -s $PrePath/phyget_hp_EmHealth_${1}.pre ]; then
    cat $PrePath/phyget_hp_EmHealth_${1}.pre | sed -n '/PROCESSORS/,/PROCESSORS/p' | sed -e '/PROCESSOR/d' -e 's/VALUE//g' | egrep 'LABEL|NAME|STATUS|SPEED|EXECUTION_TECHNOLOGY' | while read LINE; do
      if [[ $LINE =~ 'EXECUTION_TECHNOLOGY' ]]; then
        echo '  '$LINE
      else
        echo -n '  '$LINE
      fi
    done
  else
    echo "  No PreInfo , Pls exec [getpre]"
  fi
}

getMemory () {
  local tmpfile01=$(mktemp /tmp/file.XXXXXXXX)
  local tmpfile02=$(mktemp /tmp/file.XXXXXXXX)
  local j
  if [ -s $PrePath/phyget_hp_EmHealth_${1}.pre ]; then
    cat $PrePath/phyget_hp_EmHealth_${1}.pre | sed -n '/\<MEMORY$/,/\<MEMORY$/p' > $tmpfile01
    CPUlst='CPU_1 CPU_2'
    for j in $CPUlst; do
    cat $tmpfile01 | sed -n "/$j/,/$j/p" | sed "s/$j//g" | egrep 'NUMBER_OF_SOCKETS|TOTAL_MEMORY_SIZE|OPERATING_FREQUENCY|OPERATING_VOLTAGE|SOCKET|STATUS|PART NUMBER|TYPE|SIZE|FREQUENCY' | while read LINE; do
      if [[ $LINE =~ 'OPERATING_VOLTAGE' ]]; then
        echo '  '$LINE >> $tmpfile02
      elif [[ $LINE =~ 'OPERATING_FREQUENCY' ]]; then
        echo -n '  '$LINE >> $tmpfile02
      elif [[ $LINE =~ 'FREQUENCY' ]]; then
        echo '  '$LINE >> $tmpfile02
      #-------------------------------------------------------
      elif [[ $LINE =~ 'NUMBER_OF_SOCKETS' ]]; then
        echo -n '  '$j >> $tmpfile02
        echo -n '  '$LINE >> $tmpfile02
      elif [[ $LINE =~ 'TOTAL_MEMORY_SIZE' ]]; then
        echo -n '  '$LINE >> $tmpfile02
      elif [[ $LINE =~ 'SOCKET' ]]; then
        echo -n '  '$j >> $tmpfile02
        a=`spaNum "$LINE" 12`
        echo -n '  '"$LINE" >> $tmpfile02
        for i in `seq 1 $a`; do echo -n ' '; done >> $tmpfile02
      elif [[ $LINE =~ 'STATUS' ]]; then
        a=`spaNum "$LINE" 22`
        echo -n '  '"$LINE" >> $tmpfile02
        for i in `seq 1 $a`; do echo -n ' '; done >> $tmpfile02
      elif [[ $LINE =~ 'PART NUMBER' ]]; then
        a=`spaNum "$LINE" 24`
        echo -n '  '"$LINE" >> $tmpfile02
        for i in `seq 1 $a`; do echo -n ' '; done >> $tmpfile02
      elif [[ $LINE =~ 'TYPE' ]]; then
        a=`spaNum "$LINE" 18`
        echo -n '  '"$LINE" >> $tmpfile02
        for i in `seq 1 $a`; do echo -n ' '; done >> $tmpfile02
      elif [[ $LINE =~ 'SIZE' ]]; then
        a=`spaNum "$LINE" 18`
        echo -n '  '"$LINE" >> $tmpfile02
        for i in `seq 1 $a`; do echo -n ' '; done >> $tmpfile02
      else
        echo -n '  '$LINE  >> $tmpfile02
      fi
      done
    done
    grep 'NUMBER_OF_SOCKETS' $tmpfile02
    sed '/NUMBER_OF_SOCKETS/d' $tmpfile02 | grep -v 'N/A'
    sed '/NUMBER_OF_SOCKETS/d' $tmpfile02 | grep 'N/A'
    rm -f $tmpfile01 $tmpfile02
  else
    echo "  No PreInfo , Pls exec [getpre]"
  fi
}

getPci () {
   echo '  not found how to check'
}

getNic () {
  if [ -s $PrePath/phyget_hp_EmHealth_${1}.pre ]; then
  cat $PrePath/phyget_hp_EmHealth_${1}.pre | sed -n '/NIC_INFORMATION/,/NIC_INFORMATION/p' | egrep 'NETWORK_PORT|PORT_DESCRIPTION|LOCATION|MAC_ADDRESS|IP_ADDRESS|STATUS' | while read LINE; do
    LINE=${LINE:-Unknown}
    if [[ $LINE =~ 'STATUS' ]]; then
      echo '  '$LINE
    elif [[ $LINE =~ 'NETWORK_PORT' ]]; then
      a=`spaNum "$LINE" 24`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'PORT_DESCRIPTION' ]]; then
      a=`spaNum "$LINE" 62`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'LOCATION' ]]; then
      a=`spaNum "$LINE" 15`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'MAC_ADDRESS' ]]; then
      a=`spaNum "$LINE" 30`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'IP_ADDRESS' ]]; then
      a=`spaNum "$LINE" 26`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    fi
  done
  else
    echo "  No PreInfo , Pls exec [getpre]"
  fi
}

getPsu () {
  if [ -s $PrePath/phyget_hp_EmHealth_${1}.pre ]; then
  cat $PrePath/phyget_hp_EmHealth_${1}.pre | sed -n '/POWER_SUPPLIES$/,/POWER_SUPPLIES$/p' | sed -n '/SUPPLY/,/SUPPLY/p'  | egrep 'POWER_SYSTEM_REDUNDANCY|LABEL|PRESENT\>|\<STATUS\>' | while read LINE; do
    if [[ $LINE =~ 'POWER_SYSTEM_REDUNDANCY' ]]; then
      echo '  '$LINE
    elif [[ $LINE =~ 'STATUS' ]]; then
      echo '  '$LINE
    else
      echo -n '  '$LINE
    fi
  done
  else
    echo "  No PreInfo , Pls exec [getpre]"
  fi
}

getFan () {
  if [ -s $PrePath/phyget_hp_EmHealth_${1}.pre ]; then
  cat $PrePath/phyget_hp_EmHealth_${1}.pre | sed -n '/FANS$/,/FANS$/p' | egrep 'ZONE|LABEL|STATUS|SPEED' | while read LINE; do
    if [[ $LINE =~ 'SPEED' ]]; then
      echo '  '$LINE
    else
      echo -n '  '$LINE
    fi
  done
  else
    echo "  No PreInfo , Pls exec [getpre]"
  fi
}

getTemperature () {
  local tmpfile01=$(mktemp /tmp/file.XXXXXXXX)
  if [ -s $PrePath/phyget_hp_EmHealth_${1}.pre ]; then
    cat $PrePath/phyget_hp_EmHealth_${1}.pre | sed -n '/\<TEMPERATURE$/,/\<TEMPERATURE$/p' | sed -e '/\<TEMP$/d' -e  '/TEMPERATURE/d' | egrep 'LABEL|LOCATION|STATUS|CURRENTREADING' | while read LINE; do
      if [[ $LINE =~ 'CURRENTREADING' ]]; then
        echo '  '$LINE >> $tmpfile01
      elif [[ $LINE =~ 'LABEL' ]]; then
        a=`spaNum "$LINE" 24`
        echo -n '  '"$LINE" >> $tmpfile01
        for i in `seq 1 $a`; do echo -n ' ' >> $tmpfile01; done
      elif [[ $LINE =~ 'LOCATION' ]]; then
        a=`spaNum "$LINE" 24`
        echo -n '  '"$LINE" >> $tmpfile01
        for i in `seq 1 $a`; do echo -n ' ' >> $tmpfile01; done
      elif [[ $LINE =~ 'STATUS' ]]; then
        a=`spaNum "$LINE" 24`
        echo -n '  '"$LINE" >> $tmpfile01
        for i in `seq 1 $a`; do echo -n ' ' >> $tmpfile01; done
      else
        echo -n '  '$LINE >> $tmpfile01
      fi
    done
    
    cat $tmpfile01 | grep -v 'STATUS = Not Installed' 
    cat $tmpfile01 | grep 'STATUS = Not Installed' 
    rm -f $tmpfile01
  else
    echo "  No PreInfo , Pls exec [getpre]"
  fi
}

getVoltage () {
   local j=1
   snmpwalk $1 -v 2c -c $ReadCommunity CPQHLTH-MIB::cpqHeFltTolPowerSupplyMainVoltage | while read LINE; do
     echo -n '  '"Power $j Voltage: "
     echo -n $LINE | sed 's/^CPQHLTH.*INTEGER: //g'
     let j++
   done
   echo 
}

getStorageStatus () {
  echo -n '  '
  if [ -s $PrePath/phyget_hp_EmHealth_${1}.pre ]; then
    cat $PrePath/phyget_hp_EmHealth_${1}.pre | egrep '\<STORAGE STATUS\>' | xargs
  else
    echo "  No PreInfo , Pls exec [getpre]"
  fi
}

getStorageController () {
  echo -n '  '
  if [ -s $PrePath/phyget_hp_EmHealth_${1}.pre ]; then
    cat $PrePath/phyget_hp_EmHealth_${1}.pre | sed -n  '/\<STORAGE$/,/\<STORAGE$/p' | sed -e '/STORAGE/d' -e '/CONTROLLER/d' | head -11 | egrep '\<STATUS\>|MODEL|FW_VERSION|CACHE_MODULE_STATUS' | xargs
  else
    echo "  No PreInfo , Pls exec [getpre]"
  fi
}

getStorageBattery () {
  echo -n '  '
  if [ -s $PrePath/phyget_hp_EmHealth_${1}.pre ]; then
    cat $PrePath/phyget_hp_EmHealth_${1}.pre | sed -n '/SMART_STORAGE_BATTERY/,/SMART_STORAGE_BATTERY/p' | sed '/SMART_STORAGE_BATTERY/d' | egrep 'LABEL|PRESENT|STATUS' | xargs
  else
    echo "  No PreInfo , Pls exec [getpre]"
  fi
}

getStoragePdisk () {
  if [ -s $PrePath/phyget_hp_EmHealth_${1}.pre ]; then
    cat $PrePath/phyget_hp_EmHealth_${1}.pre | sed -n '/\<LOGICAL_DRIVE$/,/\<LOGICAL_DRIVE$/p' | sed -n '/\<PHYSICAL_DRIVE$/,/\<PHYSICAL_DRIVE$/p' | sed -e '/PHYSICAL_DRIVE/d' | egrep 'LABEL|\<STATUS\>|SERIAL_NUMBER|\<CAPACITY\>|MEDIA_TYPE' | while read LINE; do
      if [[ $LINE =~ 'MEDIA_TYPE' ]]; then
        echo '  '$LINE
      else
        echo -n '  '$LINE
      fi
    done
  else
    echo "  No PreInfo , Pls exec [getpre]"
  fi
}

# function stop

cycleSingleByIp () {
  local i
  for i in $iplst; do
    outfile=$OutputPath/phyget_hp_${1}_${i}_${curtime}.output
    touch $outfile
  echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
    echo -e "  ${i}_${1}" | tee -a $outfile
    $1 $i | tee -a $outfile
  echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
  done
}

cycleSingleByFunction () {
  local i
  outfile=$OutputPath/phyget_hp_${1}_${curtime}.output
  touch $outfile
  echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
  echo -e "  查询单项_${1}" | tee -a $outfile
  for i in $iplst; do
    echo -e "\n  ${1}_${i}" | tee -a $outfile
    $1 $i | tee -a $outfile
  done
  echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
}

cycleAllByIp () {
  local i j
  local scrp=`basename $0`
  funlst=`sed -n '/^# function start.*/,/^# function stop.*/p' $scrp | grep 'get[A-Z].*()' | egrep -o '^get[A-Z].*[a-z]|^get[A-Z].*[A-Z]'`
  for i in $iplst; do
    outfile=$OutputPath/phyget_hp_all_${i}_${curtime}.output
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
  scrp=`basename $0`
  funlst=`sed -n '/^# function start.*/,/^# function stop.*/p' $scrp | grep 'get[A-Z].*()' | egrep -o '^get[A-Z].*[a-z]|^get[A-Z].*[A-Z]'`
  for f in $funlst; do
    outfile=$OutputPath/phyget_hp_all_${f}_${curtime}.output
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

addUser () {
#  read -p "  用户名: " UserN
#  read -sp "    密码: " PassN ; echo
  UserN='TESTADMIN'
  PassN='PASSWORD'
  echo
  perl $ExeCmd -s $1 -u $User -p $Pass -f $XPath/ADD_USER.xml -t UserNew=$UserN,PassNew=$PassN | grep '^\.\.\..*\.\.\.' | sed -e 's/^/  /g'
  #perl $ExeCmd -s $1 -u $User -p $Pass -f $XPath/ADD_USER.xml -t UserNew=$UserN,PassNew=$PassN
}

delUser () {
  read -p "  用户名: " UserO
  echo
  perl $ExeCmd -s $1 -u $User -p $Pass -f $XPath/Delete_User.xml -t UserOld=$UserO | grep '^\.\.\..*\.\.\.' | sed -e 's/^/  /g'
}

getLicense () {
  perl $ExeCmd -s $1 -u $User -p $Pass -f $XPath/Get_All_Licenses.xml | sed -n '/<LICENSE>/,/<\/LICENSE>/p' | sed -e '/LICENSE>/d' -e 's/[<|>|/]//g' -e 's/VALUE//g' | egrep 'LICENSE_TYPE|LICENSE_KEY|LICENSE_STATE' | xargs | sed -e 's/^/  /g'
}

getSysInfo () {
  echo -n '  Product Name: '`snmpwalk -v 2c -c One1Dream2 ${1} CPQSINFO-MIB::cpqSiProductName | sed -e s/\"//g -e 's/^CPQ.*\: //g'` 
  echo '  Serial Number: '`snmpwalk -v 2c -c One1Dream2 ${1} CPQSINFO-MIB::cpqSiSysSerialNum | sed -e s/\"//g -e 's/^CPQ.*\: //g'` 
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

mkdir -p ./phyget_hp/{output,pre} &> /dev/null
FilePath=./phyget_hp
XPath=$FilePath/hp_xml
OutputPath=$FilePath/output
PrePath=$FilePath/pre
ExeCmd=$FilePath/hp_xml/locfg.pl

User='ADMIN'
Pass='PASSWORD'
ReadCommunity='COMMUNITY'
iplst=`cat phyget_hp.ip`
curtime=`date +%Y-%m-%d_%H-%M-%S`

echoUsage_cn
read -p "  你的选择: " CHOICE
CHOICE=${CHOICE:-UNknown}

until [ $CHOICE == quit ]; do
case $CHOICE in
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
  gettimezone)
    cycleSingleByFunction getTimezone
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
  getpre)
    cycleSingleByFunction getPre
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
  getsysinfo)
    cycleSingleByFunction getSysInfo
    ;;
  getlicense)
    cycleSingleByFunction getLicense
    ;;
  adduser)
    cycleSingleByFunction addUser
    ;;
  deluser)
    cycleSingleByFunction delUser
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
