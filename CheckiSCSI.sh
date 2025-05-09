#!/bin/bash
# check to ensure you are running as SUDO
confini="/etc/tab/conf/default.ini"
passed="yes"

get_settings () {
  echo "Loading settings ..."
  source $confini
}

save_settings () {
  echo "Saving settings ..."
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" scriptver \"$scriptver\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" veeamxfs \"$veeamxfs\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" webmin \"$webmin\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" docker \"$docker\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" vupw \"$vupw\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" devnm \"$devnm\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" nasip \"$nasip\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" host \"$host\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" uuid \"$uuid\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" initiator \"$initiator\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" mountpoint \"$mountpoint\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" tapw \"$tapw\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" lturl \"$lturl\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" serverip \"$serverip\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" iscsifail \"$iscsifail\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" rebooted \"$rebooted\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" setup_cron \"$setup_cron\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" update_os \"$update_os\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" install_webmin \"$install_webmin\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" install_docker \"$install_docker\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" set_ip \"$set_ip\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" tabadmin_pw \"$tabadmin_pw\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" set_nasip \"$set_nasip\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" set_initiator \"$set_initiator\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" iscsi_conf \"$iscsi_conf\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" set_uuid \"$set_uuid\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" veeam_user \"$veeam_user\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" veeam_perms \"$veeam_perms\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" lt_installed \"$lt_installed\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" fstab_updated \"$fstab_updated\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" iscsi_edited \"$iscsi_edited\"
  crudini --ini-options=nospace --set /etc/tab/conf/default.ini "" partitioned \"$partitioned\"  
}

if [[ "$HOSTNAME" == *"veeam"* ]]; then
  echo "Veeam server moving ahead."
else
  exit
fi

get_settings

# check to make sure a block device is found for the iSCSI which matches the one defined in the config file
echo "========================================" >> /etc/tab/logs/checkiscsi.log
echo "$(date)" >> /etc/tab/logs/checkiscsi.log
echo "----------------------------------------" >> /etc/tab/logs/checkiscsi.log
echo "- Testing iSCSI connection at the device level" >> /etc/tab/logs/checkiscsi.log
lsscsi -t | grep $devnm >> /etc/tab/logs/checkiscsi.log
if [ $? != 0 ] ; then
  case "$iscsifail" in
    "yes") echo "- FAIL: 2nd+ failure, checking to see if reboot attempted" >> /etc/tab/logs/checkiscsi.log
           case "$rebooted" in
             "yes") echo "- A reboot has been tried and did not fix the issue, taking no further action" >> /etc/tab/logs/checkiscsi.log
                    passed="no"
                    ;;
             "no") echo "- Reboot has not been attempted, will do so now" >> /etc/tab/logs/checkiscsi.log
                   rebooted="yes"
                   save_settings
                   passed="no"
                   #shutdown -r now
                   ;;
           esac ;;
    "no") echo "- FAIL: 1st failure, will update the config file" >> /etc/tab/logs/checkiscsi.log
          iscsifail="yes"
          passed="no"
          save_settings
          ;;
  esac
else
  # PASSED FIRST CHECK
fi

# check that mount shows the device ID mounted 
echo "- Testing mount to see if there is a mountpoint for this device" >> /etc/tab/logs/checkiscsi.log
if [ $passed == "yes" ] ; then
  mount | grep $devnm
  if [ $? != 0 ] ; then
    case "$iscsifail" in
      "yes") echo "- FAIL: $devnm not found in mount list, 2nd+ failure, checking to see if reboot attempted" >> /etc/tab/logs/checkiscsi.log
             case "$rebooted" in
               "yes") echo "- A reboot has been tried and did not fix the issue, taking no further action" >> /etc/tab/logs/checkiscsi.log
                      passed="no"
                      ;;
               "no") echo "- Reboot has not been attempted, will do so now" >> /etc/tab/logs/checkiscsi.log
                     rebooted="yes"
                     save_settings
                     passed="no"
                     #shutdown -r now
                     ;;
             esac ;;
      "no") echo "- FAIL: $devnm not found in mount list, 1st failure, updating config file" >> /etc/tab/logs/checkiscsi.log
            iscsifail="yes"
            rebooted="no"
            save_settings
            passed="no"
            ;;
    esac
  else
     mount | grep $dmountpoint
    if [ $? != 0 ] ; then
      case "$iscsifail" in
        "yes") echo "- FAIL: $mountpoint not found in mount list, 2nd+ failure, checking to see if reboot attempted" >> /etc/tab/logs/checkiscsi.log
               case "$rebooted" in
                 "yes") echo "- A reboot has been tried and did not fix the issue, taking no further action" >> /etc/tab/logs/checkiscsi.log
                        passed="no"
                        ;;
                 "no") echo "- Reboot has not been attempted, will do so now" >> /etc/tab/logs/checkiscsi.log
                       rebooted="yes"
                       save_settings
                       passed="no"
                       #shutdown -r now
                       ;;
               esac ;;
        "no") echo "- FAIL: $mountpoint not found in mount list, 1st failure, updating config file" >> /etc/tab/logs/checkiscsi.log
              iscsifail="yes"
              save_settings
              passed="no"
              ;;
      esac
    else
      # PASSED SECOND CHECK
    fi
  fi
fi

# check that VBK files exist on the mount point
if [ $iscsifail != "yes" ] ; then
fi


