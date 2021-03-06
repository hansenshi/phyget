#!/bin/bash
#
trap 'echo "Quit..."; exit 10' SIGINT

echoUsage_cn () {
  cat << EOF
  
  ==================================================================================
  ||||||                     【戴尔】物理机信息查询                          |||||||
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
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn getsensorinfo | dos2unix > $PrePath/phyget_dell_sensorinfo_${1}.pre && echo "  Sensor PreInfo complete"
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn hwinventory | dos2unix > $PrePath/phyget_dell_hwinventory_${1}.pre && echo "  HWinventory PreInfo complete"
}

# init settings query

getSavePower () {
  echo -n '  '
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn get bios.sysprofilesettings.SysProfile | dos2unix | egrep SysProfile
}

getProcVT () {
  echo -n '  '
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn get BIOS.ProcSettings.ProcVirtualization | dos2unix | egrep ProcVirtualization
}

getProcThread () {
  echo -n '  '
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn get BIOS.ProcSettings.LogicalProc | dos2unix | egrep LogicalProc
}

getBootMode () {
  echo -n '  '
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn get BIOS.BiosBootSettings.BootMode | dos2unix | egrep BootMode
}

getBootSeq () {
  echo -n '  '
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn get BIOS.BiosBootSettings.BootSeq | dos2unix | egrep BootSeq
}

getNtp () {
  echo -n '  '`$ExeCmd -r $1 -u $User -p $Pass --nocertwarn get idrac.time.Timezone | dos2unix | egrep 'Timezone'`
  echo ' '`$ExeCmd -r $1 -u $User -p $Pass --nocertwarn get iDRAC.NTPConfigGroup | dos2unix | egrep 'NTPEnable|NTP1'`
}

getSnmp () {
  echo -n '  '
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn get iDRAC.SNMP| dos2unix | egrep 'Agent'| xargs echo
}

getUser () {
  ipmitool -I lanplus -H $1 -U $User -P $Pass user list | sed -e 's/^/  /g'
  #$ExeCmd -r $1 -u $User -p $Pass --nocertwarn get iDRAC.Users.2 | dos2unix | egrep 'Privilege|Enable|IpmiLanPrivilege|IpmiSerialPrivilege|SolEnable|ProtocolEnable|AuthenticationProtocol|PrivacyProtocol|UserName' | xargs echo
}

getStorageVdisk () {
  local a i
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn storage get vdisks -o -p Name,Layout,Size,Status | grep -v 'RAID.Integrated' | while read LINE; do
    LINE=`echo $LINE | xargs`
    if [[ $LINE =~ 'Name' ]]; then
      a=`spaNum "$LINE" 22`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'Layout' ]]; then
      a=`spaNum "$LINE" 15`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'Size' ]]; then
      a=`spaNum "$LINE" 20`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'Status' ]]; then
      echo "$LINE"
    fi
   done
}

# inventory status query

getRollup () {
  if [ -e $PrePath/phyget_dell_sensorinfo_${1}.pre -a -e $PrePath/phyget_dell_hwinventory_${1}.pre ]; then
    echo "  ---------------------------------------"
    grep -A 30 '\[InstanceID: System' $PrePath/phyget_dell_hwinventory_${1}.pre | egrep '^RollupStatus' | awk '{printf "  %-28s%-3s%-7s\n",$1,$2,$3}'
    echo "  ---------------------------------------" 
    grep -A 30 '\[InstanceID: System' $PrePath/phyget_dell_hwinventory_${1}.pre | egrep 'RollupStatus' | sed -n -e '/.\{1,\}RollupStatus/p' | sed -e '1,$s/^/  /g' | awk '{printf "  %-28s%-3s%-7s\n",$1,$2,$3}' | while read Line; do
      echo $Line | awk '{printf "  %-28s%-3s%-7s\n",$1,$2,$3}'
    done
  else
    echo "  No PreInfo File, Please Exec [getpre]"
  fi
}

getPowerStatus () {
  echo -n '  '
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn serveraction powerstatus | dos2unix | xargs echo
}

getProcessor () {
  if [ -e $PrePath/phyget_dell_sensorinfo_${1}.pre -a -e $PrePath/phyget_dell_hwinventory_${1}.pre ]; then
    cpucount=`cat $PrePath/phyget_dell_hwinventory_${1}.pre | grep  '\[InstanceID: CPU.Socket.[0-9]\]' | wc -l`
    for i in `seq 1 $cpucount`; do
      cat $PrePath/phyget_dell_hwinventory_${1}.pre | grep -A 58 "\[InstanceID: CPU.Socket.${i}\]" | egrep 'DeviceDescription|Model|CurrentClockSpeed|^PrimaryStatus' | xargs | sed '1,$s/^/  /g' 
    done
    echo
    cat $PrePath/phyget_dell_sensorinfo_${1}.pre | grep -A 3 'Sensor Type : PROCESSOR' | sed '/Sensor Type : PROCESSOR/d' | sed '1,$s/^/  /g'
  else
    echo "  No PreInfo File, Please Exec [getpre]"
  fi
}

getMemory () {
  if [ -e $PrePath/phyget_dell_sensorinfo_${1}.pre -a -e $PrePath/phyget_dell_hwinventory_${1}.pre ]; then
    cat $PrePath/phyget_dell_hwinventory_${1}.pre | grep -A 22 '\[InstanceID: DIMM.Socket.*\]' | egrep 'MemoryType|CurrentOperatingSpeed|^Size|SerialNumber|^InstanceID|PrimaryStatus' | while read LINE; do
      if [[ $LINE =~ 'InstanceID' ]]; then
        echo '  '$LINE
      else
        echo -n '  '$LINE
      fi
    done
    echo
    cat $PrePath/phyget_dell_sensorinfo_${1}.pre | grep -A 25 'Sensor Type : MEMORY' | sed '/Sensor Type : MEMORY/d' | sed '1,$s/^/  /g'
  else
    echo "  No PreInfo File, Please Exec [getpre]"
  fi
}

getPci () {
  if [ -e $PrePath/phyget_dell_sensorinfo_${1}.pre -a -e $PrePath/phyget_dell_hwinventory_${1}.pre ]; then
    cat $PrePath/phyget_dell_hwinventory_${1}.pre | grep -A 25 'Device Type = PCIDevice' | egrep '^Description|^DeviceDescription|Manufacturer' | while read LINE; do
      if [[ $LINE =~ 'DeviceDescription' ]]; then
        echo '  '"$LINE"
      elif [[ $LINE =~ 'Manufacturer' ]]; then
        a=`spaNum "$LINE" 50`
        echo -n '  '"$LINE"
        for i in `seq 1 $a`; do echo -n ' '; done
      elif [[ $LINE =~ 'Description' ]]; then
        a=`spaNum "$LINE" 78`
        echo -n '  '"$LINE"
        for i in `seq 1 $a`; do echo -n ' '; done
      fi
    done
  else
    echo "  No PreInfo File, Please Exec [getpre]"
  fi
}

getNic () {
  local a i
  if [ -e $PrePath/phyget_dell_sensorinfo_${1}.pre -a -e $PrePath/phyget_dell_hwinventory_${1}.pre ]; then
  cat $PrePath/phyget_dell_hwinventory_${1}.pre | egrep -A 17 '\[InstanceID: iDRAC.Embedded' | egrep 'URLString|PermanentMACAddress' | xargs | sed 's/^/  /g'
  cat $PrePath/phyget_dell_hwinventory_${1}.pre | egrep -A 25 '\[InstanceID: NIC.Integrated.*\]' | egrep 'MediaType|LinkSpeed|ProductName|PermanentMACAddress' | while read LINE; do
    if [[ $LINE =~ 'ProductName' ]]; then
      echo '  '"$LINE"
    elif [[ $LINE =~ 'MediaType' ]]; then
      a=`spaNum "$LINE" 20`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'LinkSpeed' ]]; then
      a=`spaNum "$LINE" 19`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'PermanentMACAddress' ]]; then
      a=`spaNum "$LINE" 39`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    fi
    done
  else
    echo "  No PreInfo File, Please Exec [getpre]"
  fi
}

getPsu () {
  if [ -e $PrePath/phyget_dell_sensorinfo_${1}.pre -a -e $PrePath/phyget_dell_hwinventory_${1}.pre ]; then
    cat $PrePath/phyget_dell_hwinventory_${1}.pre | egrep -A 24 '\[InstanceID: PSU.Slot' | egrep 'DeviceDescription|SerialNumber|RedundancyStatus|PrimaryStatus' | while read LINE; do
      if [[ $LINE =~ 'DeviceDescription' ]]; then
        echo '  '$LINE
      else
        echo -n '  '$LINE
      fi
    done 
  else
    echo "  No PreInfo File, Please Exec [getpre]"
  fi
}

getFan () {
  if [ -e $PrePath/phyget_dell_sensorinfo_${1}.pre -a -e $PrePath/phyget_dell_hwinventory_${1}.pre ]; then
    cat $PrePath/phyget_dell_hwinventory_${1}.pre | egrep -A 24 '\[InstanceID: Fan.' | egrep 'DeviceDescription|PrimaryStatus|RedundancyStatus|CurrentReading' | while read LINE; do
      if [[ $LINE =~ 'DeviceDescription' ]]; then
        echo '  '$LINE
      else
        echo -n '  '$LINE
      fi
    done 
    cat $PrePath/phyget_dell_sensorinfo_${1}.pre | grep -A 7 'Sensor Type : FAN' | sed '1,$s/^/  /g'
  else
    echo "  No PreInfo File, Please Exec [getpre]"
  fi
}

getTemperature () {
  if [ -e $PrePath/phyget_dell_sensorinfo_${1}.pre -a -e $PrePath/phyget_dell_hwinventory_${1}.pre ]; then
     cat $PrePath/phyget_dell_hwinventory_${1}.pre | egrep -A 26 '\[InstanceID: System' | egrep 'EstimatedExhaustTemperature|TempStatisticsRollupStatus|TempRollupStatus' | xargs | sed '1,$s/^/  /g'
     echo 
     cat $PrePath/phyget_dell_sensorinfo_${1}.pre | grep -A 12 'Sensor Type : TEMPERATURE' | sed -e '/^\[Key/d' -e '/^$/d' | sed '1,$s/^/  /g' 
  else
    echo "  No PreInfo File, Please Exec [getpre]"
  fi
}

getVoltage () {
  if [ -e $PrePath/phyget_dell_sensorinfo_${1}.pre -a -e $PrePath/phyget_dell_hwinventory_${1}.pre ]; then
     cat $PrePath/phyget_dell_sensorinfo_${1}.pre | grep -A 38 'Sensor Type : VOLTAGE' | sed -e '/^\[Key/d' -e '/^$/d' | sed '1,$s/^/  /g' 
  else
    echo "  No PreInfo File, Please Exec [getpre]"
  fi
}

getStorageStatus () {
  echo -n '  '
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn storage get status | dos2unix | xargs echo
}

getStorageController () {
  echo -n '  '
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn storage get controllers -o -p RollupStatus,DeviceDescription,Name | head -4 | tail -3 | xargs echo
}

getStorageBattery () {
  echo -n '  '
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn storage get batteries -o -p DeviceDescription,Status | grep -v 'Battery.Integrated' | awk -F= '{print $2}' | xargs echo
}


getStoragePdisk () {
  local a i
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn storage get pdisks -o -p Name,Size,Status,SerialNumber | dos2unix | grep -v 'RAID.Integrated' | while read LINE; do
    LINE=`echo $LINE | xargs`
    if [[ $LINE =~ 'Name' ]]; then
      a=`spaNum "$LINE" 27`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'Status' ]]; then
      a=`spaNum "$LINE" 13`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'Size' ]]; then
      a=`spaNum "$LINE" 18`
      echo -n '  '"$LINE"
      for i in `seq 1 $a`; do echo -n ' '; done
    elif [[ $LINE =~ 'SerialNumber' ]]; then
      echo "$LINE"
    fi
  done
}


# function stop



cycleSingleByIp () {
  local i
  for i in $iplst; do
    local outfile=$OutputPath/phyget_dell_${1}_${i}_${curtime}.output
    touch $outfile
  echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
    echo -e "  ${i}_${1}" | tee -a $outfile
    $1 $i | tee -a $outfile
  echo -e '\n  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' | tee -a $outfile
  done
}

cycleSingleByFunction () {
  local i
  local outfile=$OutputPath/phyget_dell_${1}_${curtime}.output
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
  local f i
  local scrp=`basename $0`
  local funlst=`sed -n '/^# function start.*/,/^# function stop.*/p' $scrp | grep 'get[A-Z].*()' | egrep -o '^get[A-Z].*[a-z]|^get[A-Z].*[A-Z]'`
  for i in $iplst; do
    local outfile=$OutputPath/phyget_dell_all_${i}_${curtime}.output
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
  local f i
  local scrp=`basename $0`
  local funlst=`sed -n '/^# function start.*/,/^# function stop.*/p' $scrp | grep 'get[A-Z].*()' | egrep -o '^get[A-Z].*[a-z]|^get[A-Z].*[A-Z]'`
  for f in $funlst; do
    local outfile=$OutputPath/phyget_dell_all_${f}_${curtime}.output
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
  local JosStatus
  local tmpfile01=$(mktemp /tmp/file.XXXXXXXX)
  local curtime=`date +%Y-%m-%d_%H-%M-%S`
  echo
  echo "  Start time: "`date +%Y-%m-%d_%H:%M:%S`
  echo
  if $ExeCmd -r $1 -u $User -p $Pass --nocertwarn techsupreport collect &>> $tmpfile01; then
    echo "  Log Collection in progress..." 
    JID=`cat $tmpfile01 | egrep -o 'JID_[0-9]{1,}'`
    JobStatus=${JobStatus:-UNknown}
    until [[ $JobStatus == "Completed" ]]; do
      sleep 3
      JobStatus=`$ExeCmd -r $1 -u $User -p $Pass --nocertwarn jobqueue view -i $JID | grep 'Status' | sed 's/Status=//g' | dos2unix`
      echo "  $JobStatus"
    done
      echo "  Log Collection Completed; Export logfile in progress..."
      $ExeCmd -r $1 -u $User -p $Pass --nocertwarn techsupreport export -f /tmp/log_${1}_${curtime}.zip && echo "  Logfile is /tmp/log_${1}_${curtime}.zip"
      echo 
      echo "  End time: "`date +%Y-%m-%d_%H:%M:%S`
  else
    echo "  Log Collection in Error."
  fi
}


addUser () {
  local UserN PassN UserIdN
  #read -p "  用户ID: " UserIdN
  #read -p "  用户名: " UserN
  #read -sp "    密码: " PassN ; echo
  UserIdN=4
  UserN='TESTADMIN'
  PassN='PASSWORD'
  echo
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdN}.UserName $UserN &> /dev/null && echo "  setting username success"
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdN}.Password $PassN &> /dev/null && echo "  setting password success"
  
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdN}.Privilege 0x1ff &> /dev/null && echo "  setting privilege success"
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdN}.Enable Enabled &> /dev/null && echo "  setting user enabled"
  	   
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdN}.IpmiLanPrivilege 4 &> /dev/null && echo "  setting IpmiLanPrivilege success"
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdN}.IpmiSerialPrivilege 4 &> /dev/null && echo "  setting IpmiSerialPrivilege success"
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdN}.SolEnable Enabled &> /dev/null && echo "  setting SolEnable enable"
  	   
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdN}.ProtocolEnable Disabled &> /dev/null && echo "  setting snmpv3 disable"
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdN}.AuthenticationProtocol SHA &> /dev/null && echo "  setting AuthenticationProtocol success"
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdN}.PrivacyProtocol AES &> /dev/null && echo "  setting PrivacyProtocol success"
}

delUser () {
  local UserIdO
  read -p "  用户ID: " UserIdO
  echo
  #$ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdO}.Enable Disabled &> /dev/null && echo "  User $UserIdO is disabled"
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdO}.Privilege 0x0 &> /dev/null && echo "  User $UserIdO is set to NO access "
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn set idrac.users.${UserIdO}.Enable Disabled &> /dev/null && echo "  User $UserIdO is disabled"
  ipmitool -I lanplus -H $1 -U $User -P $Pass user set name $UserIdO '' &> /dev/null && echo "  User $UserIdO is set to null"
}

getSysInfo () {
  $ExeCmd -r $1 -u $User -p $Pass --nocertwarn getsysinfo | egrep '^Express Svc Code|^Service Tag|^System Model' | xargs echo | sed 's/^/  /g'
}

clearUp () {
  rm -f $OutputPath/* && rm -f $PrePath/* && echo "  Clearup tmpfile finished"
}

spaNum () {
  local chvar=$1
  local hopenum=$2
  local chnum=${#chvar}
  local addnum=$[$hopenum-$chnum]
  echo $addnum
}

quit () {
  exit 0
}


mkdir -p ./phyget_dell/{output,pre} &> /dev/null
FilePath=./phyget_dell
OutputPath=$FilePath/output
PrePath=$FilePath/pre
ExeCmd=/usr/sbin/racadm

User='ADMIN'
Pass='PASSWORD'
ReadCommunity='COMMUNITY'
iplst=`cat phyget_dell.ip`
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
  adduser)
    cycleSingleByFunction addUser
    ;;
  deluser)
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
