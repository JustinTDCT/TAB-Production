  #!/bin/bash
# check to ensure you are running as SUDO
confini="/etc/tab/conf/default.ini"
IPOK="no"

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

keystroke () {
  echo
  echo "Press any key to continue ..."
  read -rsn1
}

function checkIPFormat {
  IPOK="no"
  local ipCidr="${1}"
  local validIpCidr
  validIpCidr='(^([1-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5]))$'
  if [[ $ipCidr =~ ^$validIpCidr ]]; then
    echo "Format valid"
    IPOK="yes"
    return 0
  else
    echo "Not a valid IP"
    return 1
  fi
}







get_settings
clear
echo "Performing a quick check of the config file settings; you will be prompted to fix missing or invalid settings ..."
if [ $veeamxfs != "yes" ] ; then
  echo "- Server not flagged as a VeeamXFS server; while this won't stop the install it should be fixed."
  read -p "Fix this? Y/n " -n1 -s chrtmp
    if [ $chrtmp == "y" ] ; then
      veeamxfs="yes"
      save_settings
    fi
fi
if [ $vupw == "none" ] ; then
  echo "- no password has been set for the Veeam user you need to set one now ..."
  read -p "new veeamuser password: " vupw
  save_settings
fi
if [ $nasip == "none" ] ; then
  echo "- no NAS IP defined, please define one now ..."
  echo "Enter the IP in regular format. IE, 192.168.1.123"
  while [[ $IPOK == "no" ]] ;
    do
      read -rp "new IP: " nasip
      if checkIPFormat "${nasip}"; then
        echo "Moving on..."
      fi
      done 
      IPOK="no"
else
  echo "- Data found in NAS IP, verifying it is an IP ..."
  if checkIPFormat "${nasip}"; then  
    echo "- verified format"
  else
    echo "- this does not appear to be a valid IP format, please enter a new one ..."
    while [[ $IPOK == "no" ]] ;
      do
        read -rp "new IP: " nasip
        if checkIPFormat "${nasip}"; then
          echo "Moving on..."
        fi
        done 
      IPOK="no"
  fi
fi





