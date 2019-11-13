#!/bin/bash
#

echoUsage_cn () {
  cat << EOF
  =======================================
  ||||||  【惠普】物理机信息查询  |||||||
  =======================================
  
  --------- 
  help info
  
  --物理机初始化设定查询--
  getsp) 查询节电模式
  getprocvt) 查询处理器虚拟化功能
  getprocthread) 查询处理器多线程功能
  getbootmode) 查询bios启动模式
  getbootseq) 查询bios启动顺序
  gettimezone) 查询时区
  getntp) 查询网络时间服务器信息
  getsnmp) 查询snmp设定信息
  getuser) 查询用户设定信息
  getstoragevdisk) 查询存储虚拟磁盘信息
  
  --物理机内部设备状态查询--
  getpwrsw) 是否开机
  getprocessor) 处理器状态
  getmem) 内存状态
  getinventory) 设备列表
  getnicb) 带外网卡状态
  getnics) 系统网卡状态
  getpsu) 电源状态
  getfan) 风扇状态
  getemp) 温度状态
  getvolt) 电压状态
  getstoragestatus) 查询存储汇总状态
  getstoragecontroller) 查询存储控制卡信息
  getstoragebattery) 查询存储电池信息
  getstoragepdisk) 查询存储物理磁盘信息
  
  --外--
  getall) 查询所有项
  quit) 退出
  ------------
EOF
}

# function start
getSavePower () {
  echo -n '  '
  perl locfg.pl -s $1 -u $User -p $Pass -f Get_Host_Power_Saver.xml | grep -A 1 GET_HOST_POWER_SAVER | grep -v 'GET_HOST_POWER_SAVER' | sed s/' '//g
}

getProcVT () {
  echo -n '  '
  echo 'still not found the item'
}

getProcThread () {
  snmpwalk $1 -v 2c -c HrpVe7 CPQSTDEQ-MIB::cpqSeCPUMultiThreadStatus | while read LINE; do
    if [[ $LINE =~ 'enabled' ]]; then
      echo "  CPU `echo $LINE | grep -o cpqSeCPUMultiThreadStatus.[0-9] | grep -o [0-9]` Hyper-Threading is On."
    else
      echo "  CPU `echo $LINE | grep -o cpqSeCPUMultiThreadStatus.[0-9] | grep -o [0-9]` Hyper-Threading is Off."
    fi
  done
}

getBootMode () {
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_CURRENT_BOOT_MODE.xml | sed -n '/<GET_CURRENT_BOOT_MODE>/,/<\/GET_CURRENT_BOOT_MODE>/p' | sed '/GET_CURRENT_BOOT_MODE/d' | sed s/'  <'//g | sed 's/\/>//g'
}

getBootSeq () {
  i=1
  perl locfg.pl -s 10.4.0.62 -u administrator -p 'Ops45!pdt' -f GET_PERSISTENT_BOOT.xml |sed -n '/<PERSISTENT_BOOT>/,/<\/PERSISTENT_BOOT>/p' | sed '/PERSISTENT_BOOT/d' |sed 's@\/>@@g' | sed 's@    <@@g' | while read LINE; do
    if [ $i -le 3 ]; then
      echo '  '$i $LINE
      let i++
    fi
  done
}

getPsu () {
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_EMBEDDED_HEALTH_PSU.xml | sed -n '/<POWER_SUPPLIES>/,/<\/POWER_SUPPLIES>/p' | egrep '<POWER_SYSTEM_REDUNDANCY|<LABEL VALUE|<PRESENT VALUE|<STATUS VALUE' | sed -e 's/<//g' -e 's/\/>//g' -e 's/^[[:space:]]*//g' | head -7 | while read LINE; do
    if [[ $LINE =~ 'POWER_SYSTEM_REDUNDANCY' ]]; then
      echo '  '$LINE
    elif [[ $LINE =~ 'STATUS VALUE' ]]; then
      echo '  '$LINE
    else
      echo -n '  '$LINE
    fi
  done
}

getTimezone () {
  echo -n '  '
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_NETWORK_SETTINGS.xml | grep TIME | sed -e 's/    <//g' -e 's/\/>//g'
}

getNtp () {
  echo -n '  '
  echo -n `perl locfg.pl -s $1 -u $User -p $Pass -f GET_NETWORK_SETTINGS.xml | egrep 'DHCP_SNTP|DHCPV6_SNTP' | sed -e 's/    <//g' -e 's/\/>//g'`
  echo 
  echo -n '  '
  echo -n `perl locfg.pl -s $1 -u $User -p $Pass -f GET_NETWORK_SETTINGS.xml | egrep 'SNTP_SERVER' | sed -e 's/    <//g' -e 's/\/>//g' `
  echo 
  echo -n '  '
  echo -n `perl locfg.pl -s $1 -u $User -p $Pass -f GET_GLOBAL_SETTINGS.xml | grep 'PROPAGATE' | sed -e 's/    <//g' -e 's/\/>//g'`
  echo 
}

getSnmp () {
  echo -n '  '
  echo -n `perl locfg.pl -s $1 -u $User -p $Pass -f GET_GLOBAL_SETTINGS.xml | grep SNMP_ACCESS_ENABLED | sed -e 's/    <//g' -e 's/\/>//g'`
  echo 
  echo -n '  '
  echo -n `perl locfg.pl -s $1 -u $User -p $Pass -f GET_SNMP_IM_SETTINGS.xml | egrep 'SNMP_ACCESS\>|1_ROCOMMUNITY\>' | sed -e 's/    <//g' -e 's/\/>//g'`
  echo 
}

getUser () {
  i=7
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_USER.xml | grep -A 7 GET_USER | sed -e 's/    \<//g' -e '/GET_USER/d' | while read LINE; do
    echo '  '$LINE
    let i++
  done
}

getStorageStatus () {
  echo -n '  '
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_EMBEDDED_HEALTH_STORAGE.xml | sed -n '/<STORAGE>/,/<\/STORAGE>/p' | grep -A 2 '<CONTROLLER>' | sed -n '/<STATUS VALUE/p' | sed -e 's/<//g' -e 's/\/>//g' -e s/^[[:space:]]*//g
}

getStorageController () {
  echo -n '  '
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_EMBEDDED_HEALTH_STORAGE.xml | sed -n '/<STORAGE>/,/<\/STORAGE>/p' | grep -A 3 '<CONTROLLER>' | sed -n '/<CONTROLLER_STATUS/p' | sed -e 's/<//g' -e 's/\/>//g' -e s/^[[:space:]]*//g
}

getStorageBattery () {
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_EMBEDDED_HEALTH_PSU.xml | sed -n '/<SMART_STORAGE_BATTERY>/,/<\/SMART_STORAGE_BATTERY>/p' | egrep '<LABEL VALUE|<PRESENT VALUE|<STATUS VALUE' | sed -e 's/<//g' -e 's/\/>//g' -e 's/^[[:space:]]*//g' | head -7 | while read LINE; do
    if [[ $LINE =~ 'STATUS VALUE' ]]; then
      echo '  '$LINE
    else
      echo -n '  '$LINE
    fi
  done
}

getStorageVdisk () {
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_EMBEDDED_HEALTH_STORAGE.xml | grep '<LOGICAL_DRIVE>' -A 5 | sed -e '/--/d' -e '/<LOGICAL_DRIVE>/d' -e 's@/>@@g' | grep '\<.*\>' | awk -F '<' '{print $2}' | while read LINE; do
    echo '  '$LINE
  done
}

getStoragePdisk () {
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_EMBEDDED_HEALTH_STORAGE.xml | grep -A 11 '<PHYSICAL_DRIVE>' | egrep '<LABEL VALUE|<STATUS VALUE|<CAPACITY VALUE|<MEDIA_TYPE' | sed -e 's/<//g' -e 's/\/>//g' -e 's/^[[:space:]]*//g' | while read LINE; do
    if [[ $LINE =~ 'MEDIA_TYPE' ]]; then
      echo '  '$LINE
    else
      echo -n '  '$LINE
    fi
  done
}

getPowerStatus () {
  echo -n '  '
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_HOST_POWER_STATUS.xml | grep -A 1 'GET_HOST_POWER' | grep -v 'GET_HOST_POWER' | grep -o "[^[:space:]]\{1,\}"
}

getProcessor () {
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_EMBEDDED_HEALTH_PROCESSORS.xml | sed -n '/<PROCESSORS>/,/<\/PROCESSORS>/p' | sed -e '/PROCESSOR/d' -e 's@<@@g' -e 's/\/>//g' -e 's/^[ ]*//g' | while read LINE; do
    echo '  '$LINE
  done
}

getMemory () {
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_EMBEDDED_HEALTH_MEMORY.xml | sed -n '/<CPU_[0-9]>/,/<\/CPU_[0-9]>/p' | sed -e '/<\/CPU_[0-9]>/d' -e 's/<//g' -e 's/\/>//g' -e 's/>//g' | sed 's/^\([ ]\)\{1,\}//g' | while read LINE; do
    echo '  '$LINE
  done
}

getPCIE () {
  isrest -H $1 -U $User -P $Pass getPCIE | egrep 'ID|PresentStatus|DeviceType|DeviceID|VendorID' | while read LINE; do
  if echo $LINE | grep '^\<ID\>' &> /dev/null; then
    echo -n '  '$LINE
  elif echo $LINE | grep '^\<VendorID\>' &> /dev/null; then
    echo ' '$LINE
  else
    echo -n ' '$LINE
  fi
  done
}

getNetworkAdapterB () {
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_EMBEDDED_HEALTH_NICS.xml | sed -n '/<NIC_INFORMATION>/,/<\/NIC_INFORMATION>/p' | sed -e '/NIC/d' -e 's/<//g' -e 's/\/>//g' -e 's/^[[:space:]]*//g' | head -12 | egrep -v 'PORT_DESCRIPTION|LOCATION' | while read LINE; do
    if [[ $LINE =~ 'STATUS VALUE' ]]; then
      echo '  '$LINE
    else
      echo -n '  '$LINE
    fi
  done
}


getNetworkAdapterS () {
  nic=''
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_EMBEDDED_HEALTH_NICS.xml | sed -n '/<NIC_INFORMATION>/,/<\/NIC_INFORMATION>/p' | sed -e '/NIC/d' -e 's/<//g' -e 's/\/>//g' -e 's/^[[:space:]]*//g' | sed '1,12d' | egrep -v 'LOCATION' | while read LINE; do
    if [[ $LINE =~ 'STATUS VALUE' ]]; then
      echo '  '$LINE
    else
      echo -n '  '$LINE
      #nic=`echo $LINE | grep 'PORT_DESCRIPTION' | sed 's/PORT_DESCRIPTION VALUE = //g'`
      #[[ -n $nic ]] && a=$nic
    fi
  done
}

getFan () {
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_EMBEDDED_HEALTH_FANS.xml | sed -n '/<FANS>/,/<\/FANS>/p' | sed -e '/FAN/d' | sed -e 's/<//g' -e 's/\/>//g' -e 's/^[[:space:]]*//g' | while read LINE; do
    if [[ $LINE =~ 'SPEED VALUE' ]]; then
      echo '  '$LINE
    else
      echo -n '  '$LINE
    fi
  done
}

getTemp () {
  > tmpfile01
  perl locfg.pl -s $1 -u $User -p $Pass -f GET_EMBEDDED_HEALTH_TEMPERATURES.xml | sed -n '/<TEMPERATURE>/,/<\/TEMPERATURE>/p' | sed -e '/TEMP/d' -e '/CAUTION/d' -e '/CRITICAL/d' -e 's/<//g' -e 's/\/>//g' | while read LINE; do
    if [[ $LINE =~ 'CURRENTREADING' ]]; then
      echo '  '$LINE >> tmpfile01
    else
      echo -n '  '$LINE >> tmpfile01
    fi
  done
  cat tmpfile01 | while read LINE; do
    if [[ $LINE =~ 'STATUS VALUE = "OK"' ]]; then
      echo -n '  '
      echo $LINE | awk -F'"' '{printf "%-14s%-17s%-14s%-14s%-14s%-15s%-15s%-6s%-8s%-10s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}'
    fi
  done
  cat tmpfile01 | while read LINE; do
    if [[ $LINE =~ 'STATUS VALUE = "Not Installed"' ]]; then
      echo -n '  '
      echo $LINE | awk -F'"' '{printf "%-14s%-17s%-14s%-14s%-14s%-15s%-15s%-6s%-8s%-10s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}'
    fi
  done
  rm -f tmpfile01
}

getVolt () {
   j=1
   snmpwalk $1 -v 2c -c $ReadCommunity1 CPQHLTH-MIB::cpqHeFltTolPowerSupplyMainVoltage | while read LINE; do
     echo -n '  '"Power $j Voltage: "
     echo $LINE | sed 's/^CPQHLTH.*INTEGER: //g'
     let j++
   done
   
   #echo -n '  ' && echo $LINE | awk '{printf "%-19s%-14s\n",$1,$2}'
}

# function stop

User='admin'
Pass='Ops68!ppd'
ReadCommunity='One1Dream2'
ReadCommunity1='HrpVe7'

cycle () {
  isrest=/opt/ISREST/ISREST-Linux-V1R1/bin/isrest
  iplst=`cat phyget_hp.ip`
  for i in $iplst; do
    echo "  $i"
    $1 $i
    echo
  done
}

cycleAll () {
  scrp=`basename $0`
  funlst=`sed -n '/^# function start.*/,/^# function stop.*/p' $scrp | grep 'get[A-Z].*()' | egrep -o '^get[A-Z].*[a-z]|^get[A-Z].*[A-Z]'`
  for i in $funlst; do
    echo '  '$i'----'
    cycle $i
  done 
}


echoUsage_cn
read -p "  快点，你的选择: " CHOICE
echo "     "

until [[ $CHOICE == 'quit' ]]; do
case $CHOICE in
  getsp)
    echo "  1.节电模式"
    cycle getSavePower
    ;;
  getprocvt)
    echo "  2.虚拟化"
    cycle getProcVT
    ;;
  getprocthread)
    echo "  3.多线程"
    cycle getProcThread 
    ;;
  getbootmode)
    echo "  4.启动模式"
    cycle getBootMode 
    ;;
  getbootseq)
    echo "  5.启动顺序"
    cycle getBootSeq 
    ;;
  getpsu)
    echo "  6.电源信息"
    cycle getPsu
    ;;
  gettimezone)
    echo "  7.时区"
    cycle getTimezone 
    ;;
  getntp)
    echo "  8.NTP"
    cycle getNtp 
    ;;
  getsnmp)
    echo "  9.SNMP"
    cycle getSnmp 
    ;;
  getuser)
    echo "  10.带外用户"
    cycle getUser 
    ;;
  getstoragestatus)
    echo "  11.存储汇总状态"
    cycle getStorageStatus 
    ;;
  getstoragecontroller)
    echo "  12.存储控制器"
    cycle getStorageController 
    ;;
  getstoragebattery)
    echo "  13.阵列卡电池"
    cycle getStorageBattery 
    ;;
  getstoragevdisk)
    echo "  14.虚拟磁盘"
    cycle getStorageVdisk 
    ;;
  getstoragepdisk)
    echo "  15.物理磁盘"
    cycle getStoragePdisk 
    ;;
  getpwrsw)
    echo "  16.是否开机"
    cycle getPowerStatus 
    ;;
  getprocessor)
    echo "  17.处理器"
    cycle getProcessor
    ;;
  getmem)
    echo "  18.物理内存"
    cycle getMemory 
    ;;
  getinventory)
    echo "  19.设备列表"
    cycle getPCIE 
    ;;
  getnicb)
    echo "  20.带外网卡状态"
    cycle getNetworkAdapterB 
    ;;
  getnics)
    echo "  21.系统网卡状态"
    cycle getNetworkAdapterS 
    ;;
  getfan)
    echo "  22.风扇状态"
    cycle getFan 
    ;;
  getemp)
    echo "  23.温度状态"
    cycle getTemp 
    ;;
  getvolt)
    echo "  24.电压状态"
    cycle getVolt 
    ;;
  getall)
    echo "  25.查询所有项"
    cycleAll
    ;;
  *)
    echo "  未知选项"
    echo ""
    ;;
  esac
  echo "     "
  echoUsage_cn
  read -p "  快点，你的选择.: " CHOICE
  echo "     "
done
