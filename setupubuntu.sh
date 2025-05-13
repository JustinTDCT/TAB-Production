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

# --------------------------------------------------[ Procedure to get and check iSCSI device
get_iscsi_device () {
  formatok="no"
  while [ $formatok != "yes" ]; do
    read -p "Enter the new iSCSI device name: " devnm
    if [[ "$devnm" =~ ^/dev/sd ]]; then
      echo "- $devnm meets OK format rules, checking if it's available"
      if test -b $devnm; then
        echo "- FAILED: $devnm is in use, please use another device path"
      else
        echo "- verified not in use, saving"
        save_settings
        formatok="yes"
      fi
    else
      echo "- $devnm does no appear to be in \dev\sdX format, please try again"
    fi
  done
}

# --------------------------------------------------[ Make sure an entered string is an IP
function checkIPFormat {
  local ipCidr="${1}"
  local validIpCidr
  validIpCidr='(^([1-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5]))$'
  if [[ $ipCidr =~ ^$validIpCidr ]]; then
    echo "- $nasip appears to be a proper IP address"
    return 0
  else
    echo "- $nasip is not a valid IP address"
    return 1
  fi
}

# --------------------------------------------------[ Procedure to get the NAS IP
get_nas_ip () {
  while [ $IPOK == "no" ]; do 
    read -p "Enter the new NAS IP (EX 192.168.165.123): " nasip
    if checkIPFormat "${nasip}"; then
      echo "- checking to make sure this IP can be pinged"
      ping $nasip -c 5 -4
      if [ $? != 0 ]; then
        echo "- FAIL: IP does not answer pings, be sure it is online"
        keystroke
      else
        echo "- IP is online, saving"
        save_settings
        IPOK="yes"
      fi
    fi
  done
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
  c. New TABADMIN password: $tapw
  d. iSCSI device ID: $devnm
  e. NAS IP: $nasip
  f. Parent hostname: $hostname
  g. iSCSI mount point: $mountpoint
  h. Automate Agent URL: $lturl
  i. Desired IP of this server: $serverip

  x. Save & back to main menu
  !. Exit without saving
  
EOF
      read -n1 -s menu
      menu="${menu,,}"
      case "$menu" in
      "a") if [ $webmin == "yes" ]; then webmin="no"; else webmin="yes"; fi ;;
      "b") if [ $docker == "yes" ]; then docker="no"; else docker="yes"; fi ;;
      "c") read -p "enter the new TABADMIN password - NOTE: This does not change it for you just makes it easier to cut/paste later: " tapw ;;
      "d") get_iscsi_device ;;
      "e") get_nas_ip ;;
      "x") done="yes"; save_settings ;;
      "!") done="yes" ;;
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
  get_settings
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
