#!/bin/bash
# READY FOR TESTING IN PRODUCTION
confini="/etc/tab/conf/default.ini"
passed="yes"

get_settings () {
  echo "Loading settings ..."
  source $confini
}

save_settings () {
  echo "Saving settings ..."
  crudini --ini-options=nospace --set $confini "" scriptver \"$scriptver\"
  crudini --ini-options=nospace --set $confini "" veeamxfs \"$veeamxfs\"
  crudini --ini-options=nospace --set $confini "" webmin \"$webmin\"
  crudini --ini-options=nospace --set $confini "" docker \"$docker\"
  crudini --ini-options=nospace --set $confini "" vupw \"$vupw\"
  crudini --ini-options=nospace --set $confini "" devnm \"$devnm\"
  crudini --ini-options=nospace --set $confini "" nasip \"$nasip\"
  crudini --ini-options=nospace --set $confini "" host \"$host\"
  crudini --ini-options=nospace --set $confini "" uuid \"$uuid\"
  crudini --ini-options=nospace --set $confini "" initiator \"$initiator\"
  crudini --ini-options=nospace --set $confini "" mountpoint \"$mountpoint\"
  crudini --ini-options=nospace --set $confini "" tapw \"$tapw\"
  crudini --ini-options=nospace --set $confini "" lturl \"$lturl\"
  crudini --ini-options=nospace --set $confini "" serverip \"$serverip\"
  crudini --ini-options=nospace --set $confini "" iscsifail \"$iscsifail\"
  crudini --ini-options=nospace --set $confini "" rebooted \"$rebooted\"
  crudini --ini-options=nospace --set $confini "" setup_cron \"$setup_cron\"
  crudini --ini-options=nospace --set $confini "" update_os \"$update_os\"
  crudini --ini-options=nospace --set $confini "" install_webmin \"$install_webmin\"
  crudini --ini-options=nospace --set $confini "" install_docker \"$install_docker\"
  crudini --ini-options=nospace --set $confini "" set_ip \"$set_ip\"
  crudini --ini-options=nospace --set $confini "" tabadmin_pw \"$tabadmin_pw\"
  crudini --ini-options=nospace --set $confini "" set_nasip \"$set_nasip\"
  crudini --ini-options=nospace --set $confini "" set_initiator \"$set_initiator\"
  crudini --ini-options=nospace --set $confini "" iscsi_conf \"$iscsi_conf\"
  crudini --ini-options=nospace --set $confini "" set_uuid \"$set_uuid\"
  crudini --ini-options=nospace --set $confini "" veeam_user \"$veeam_user\"
  crudini --ini-options=nospace --set $confini "" veeam_perms \"$veeam_perms\"
  crudini --ini-options=nospace --set $confini "" lt_installed \"$lt_installed\"
  crudini --ini-options=nospace --set $confini "" fstab_updated \"$fstab_updated\"
  crudini --ini-options=nospace --set $confini "" iscsi_edited \"$iscsi_edited\"
  crudini --ini-options=nospace --set $confini "" partitioned \"$partitioned\"  
}

if [[ "$HOSTNAME" == *"veeam"* ]]; then
  echo "Veeam server moving ahead."
else
  exit
fi

get_settings
mountpoint2=${mountpoint::-1}

# check to make sure a block device is found for the iSCSI which matches the one defined in the config file
echo  >> /etc/tab/logs/checkiscsi.log
echo  >> /etc/tab/logs/checkiscsi.log
echo "========================================" >> /etc/tab/logs/checkiscsi.log
echo "$(date)" >> /etc/tab/logs/checkiscsi.log
echo "----------------------------------------" >> /etc/tab/logs/checkiscsi.log
echo "Testing with the following values:" >> /etc/tab/logs/checkiscsi.log
echo "1. Device name: $devnm" >> /etc/tab/logs/checkiscsi.log
echo "2. Mountpoint: $mountpoint" >> /etc/tab/logs/checkiscsi.log
echo "3. Previous failure: $iscsifail" >> /etc/tab/logs/checkiscsi.log
echo "4. Reboot tried: $rebooted" >> /etc/tab/logs/checkiscsi.log
echo  >> /etc/tab/logs/checkiscsi.log
echo "- Testing iSCSI connection at the device level" >> /etc/tab/logs/checkiscsi.log
lsscsi -t | grep $devnm &>> /etc/tab/logs/checkiscsi.log
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
                   shutdown -r now
                   ;;
           esac ;;
    "no") echo "- FAIL: 1st failure, will update the config file" >> /etc/tab/logs/checkiscsi.log
          iscsifail="yes"
          passed="no"
          save_settings
          ;;
  esac
else
  echo "- iSCSI appears valid" >> /etc/tab/logs/checkiscsi.log
fi

# check that mount shows the device ID mounted 
echo "- Testing mount for $devnm and $mountpoint in the same line" >> /etc/tab/logs/checkiscsi.log
if [ $passed == "yes" ] ; then
  mount | grep $devnm | grep $mountpoint2 &>> /etc/tab/logs/checkiscsi.log
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
                     shutdown -r now
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
     echo "- Found mount looks appropriate" >> /etc/tab/logs/checkiscsi.log
  fi
fi

# check that VBK files exist on the mount point
if [ $passed == "yes" ] ; then
  echo "- Testing that backup files exist in mountpoint" >> /etc/tab/logs/checkiscsi.log
  files=$(find $mountpoint -name *.vbk | wc -l)
  if [ $files != "0" ] ; then
    case "$iscsifail" in
      "yes") echo "- Found $files VBK files; previously there had been a failure; resetting config data and performing XFS health check" >> /etc/tab/logs/checkiscsi.log
             iscsifail="no"
             rebooted="no"
             save_settings
             echo  >> /etc/tab/logs/xfs_repair.log
             echo  >> /etc/tab/logs/xfs_repair.log
             echo "========================================" >> /etc/tab/logs/xfs_repair.log
             echo "$(date)" >> /etc/tab/logs/xfs_repair.log
             echo "----------------------------------------" >> /etc/tab/logs/xfs_repair.log
             echo "- unmounting $mountpoint" >> /etc/tab/logs/xfs_repair.log
             umount $mountpoint2 &>> /etc/tab/logs/xfs_repair.log
             if [ $? != 0 ] ; then
               echo "- Dismount did not work, skipping the health test, see /etc/tab/logs/xfs_repair.log for details" >> /etc/tab/logs/checkiscsi.log
             else
               echo "- running xfs_repair on $devnm" >> /etc/tab/logs/xfs_repair.log
               xfs_repair $devnm &>> /etc/tab/logs/xfs_repair.log
               if [ $? != 0 ] ; then
                 echo "- repair was not able to run, skipping, see /etc/tab/logs/xfs_repair.log for details" >> /etc/tab/logs/checkiscsi.log
               else
                 echo "- remounting file system" >> /etc/tab/logs/xfs_repair.log
                 mount -a &>> /etc/tab/logs/xfs_repair.log
                if [ $? != 0 ] ; then
                  echo "- remounting failed! see /etc/tab/logs/xfs_repair.log for details" >> /etc/tab/logs/checkiscsi.log
                else
                  echo "- Repair done, see /etc/tab/logs/xfs_repair.log for details" >> /etc/tab/logs/checkiscsi.log
                fi
              fi
             fi
             ;;
       "no") echo "- Found $files VBK files, no previous failures but resetting config data to be sure" >> /etc/tab/logs/checkiscsi.log
             iscsifail="no"
             rebooted="no"
             save_settings
             ;;
       esac
  else
    case "$iscsifail" in
      "yes") echo "- FAIL: no VBK files found in $mountpoint, 2nd+ failure, checking to see if reboot attempted" >> /etc/tab/logs/checkiscsi.log
             case "$rebooted" in
               "yes") echo "- A reboot has been tried and did not fix the issue, taking no further action" >> /etc/tab/logs/checkiscsi.log
                      passed="no"
                      ;;
               "no") echo "- Reboot has not been attempted, will do so now" >> /etc/tab/logs/checkiscsi.log
                     rebooted="yes"
                     save_settings
                     passed="no"
                     shutdown -r now
                     ;;
             esac ;;
      "no") echo "- FAIL: no VBK files found in $mountpoint, , 1st failure, updating config file" >> /etc/tab/logs/checkiscsi.log
            iscsifail="yes"
            rebooted="no"
            save_settings
            passed="no"
            ;;
    esac
  fi
fi
