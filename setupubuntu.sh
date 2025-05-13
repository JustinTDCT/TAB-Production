#!/bin/bash
# this will be a new revision; an all in one as it were
# essential concept - all scripts now in /etc/tab/scrips; logs in /etc/tab/logs; config in /etc/tab/conf

# location of config file
confini="/etc/tab/conf/default.ini"

# variables needed for various parts of the script but we do not need to save their data
IPOK="no"
iscsi_logged_in="no"

# --------------------------------------------------[ procedure to load the config file
get_settings () {
  echo "Loading settings ..."
  source $confini
}

# --------------------------------------------------[ procedure to save the config file
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

# --------------------------------------------------[ procedure to wait for keystroke
keystroke () {
  echo
  echo "Press any key to continue ..."
  read -rsn1
}

# --------------------------------------------------[ procedure for first time runnings
first_run () {
  clear
  echo "THIS IS THE FIRST TIME THIS SCRIPT HAS BEEN RUN - NO INI CONFIG FILE FOUND - DOING CORE INSTALL"
  # Create folder structure
  echo "====[ Creating folders"
  mkdir /etc/tab
  mkdir /etc/tab/conf
  mkdir /etc/tab/scripts
  mkdir /etc/tab/logs
  mkdir /tab_temp
  # Grab the baseline config file and load it
  echo "====[ Grabbing baseline config file"
  wget -O /etc/tab/conf/default.ini https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/default.ini
  echo "====[ Loading baseline config file"
  get_settings
}

# --------------------------------------------------[ Variables Menu
variables_menu () {
  done="no"
  while [ $done == "no" ] 
    do
     clear
     cat<<EOF
  VM Setup Script $scriptver
  =============================
  a. Install Webmin: $webmin
  b. Install Docker $docker
  c. New TABADMIN password $tapw
  d. iSCSI device ID: $devnm
  e. NAS IP: $nasip
  f. Parent hostname: $hostname
  g. iSCSI mount point: $mountpoint
  h. Automate Agent URL: $lturl
  i. Desired IP of this server: $serverip

  x. Save & back to main menu
  
EOF
      read -n1 -s menu
      menu="${menu,,}"
      case "$menu" in
      "a") variables_menu ;;
      "b") install_menu ;;
      "x") done="yes" ;;
      *) echo "Invalid menu option!"
         keystroke ;;
      esac
  done
}



# --------------------------------------------------[ Main program
clear
# check if being run as SUDO
if [ "$EUID" -ne 0 ]
  then echo "WARNING: This needs to be run as SUDO!"
  exit
fi

# check for default ini file
if [ -f "/etc/tab/conf/default.ini" ]; then
  echo "This has been run before ... pulling configuration";
  get_settings
  keystroke
else
  first_run;
  keystroke
  get_Settings
  exit
fi

while :
do
    clear
    cat<<EOF
  VM Setup Script $scriptver
  =============================
  a. Pre-install requirements
  b. Set install variables
  c. Install routine menu

  x. Exit
  
EOF
    read -n1 -s menu
    menu="${menu,,}"
    case "$menu" in
    "b") variables_menu ;;
    "c") install_menu ;;
    "x") clear
         exit ;;
    *) echo "Invalid menu option!"
       keystroke ;;
    esac
done
