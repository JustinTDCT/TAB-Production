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
  tempdev=$devnm
  read -p "Enter the new iSCSI device name (/dev/sdX format): " devnm
  if [[ "$devnm" =~ ^/dev/sd ]]; then
    echo "- $devnm meets OK format rules, checking if it's available"
    if test -b $devnm; then
      echo "- FAILED: $devnm is in use, please use another device path"
      devnm=$tempdev
      keystroke
    else
      echo "- verified not in use, saving"
      save_settings
      keystroke
    fi
  else
    echo "- $devnm does no appear to be in \dev\sdX format, please try again"
    devnm=$tempdev
    keystroke
  fi
}

# --------------------------------------------------[ Make sure an entered string is an IP in CIDR format
function checkCidrFormat {
  local ipCidr="${1}"
  local validIpCidr
  validIpCidr='(^([1-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\/([1-9]|[1-2][0-9]|[3][0-2]))$'
  if [[ $ipCidr =~ ^$validIpCidr ]]; then
    echo "- $1 is a valid CIDR IP"
    return 0
  else
    echo "- $1 is not a valid CIDR IP"
    return 1
  fi
}

# --------------------------------------------------[ Make sure an entered string is an IP
function checkIPFormat {
  local ipCidr="${1}"
  local validIpCidr
  validIpCidr='(^([1-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5]))$'
  if [[ $ipCidr =~ ^$validIpCidr ]]; then
    echo "- $1 appears to be a proper IP address"
    return 0
  else
    echo "- $1 is not a valid IP address"
    return 1
  fi
}

# --------------------------------------------------[ Procedure to get the hostname for the intiator
get_hostname () {
  read -p "Enter the parent host hostname or the ATN of this machine: " hostname
}

# --------------------------------------------------[ Procedure to get the iSCSI mount point
get_mountpoint () {
  temppoint=$mountpoint
  read -p "Enter the new mount point to be used for iSCSI mapping (should be in /mnt folder): " mountpoint
  echo "- checking if $mountpoint exists"
  if [ -d $mountpoint ]; then
    echo "- this folder already exists, listing the contents"
    ls $mountpoint
    echo
    read -p "- check the above, do you want to continue using this folder? [y/N] " -n1 -s yesno
    if [ $yesno == "y" ]; then
      save_settings
      keystroke
    else mountpoint=$temppoint
    fi
  else
    echo "- folder does not exist, creating it"
    mkdir -p $mountpoint
    if [ $? != 0 ]; then
      echo "- FAIL: unable to make folder $mountpoint"
      keystroke
    else
      echo "- folder created"
      save_settings
      keystroke
    fi
  fi
}

# --------------------------------------------------[ Procedure to get the NAS IP
get_nas_ip () {
  tempip=$nasip
  read -p "Enter the new NAS IP (EX 192.168.165.123): " nasip
  if checkIPFormat "${nasip}"; then
    echo "- checking to make sure this IP can be pinged"
    ping $nasip -c 5 -4
    if [ $? != 0 ]; then
      echo "- FAIL: IP does not answer pings, be sure it is online"
      nasip=$tempip
      keystroke
    else
      echo "- IP is online, saving"
      set_nasip="done"
      save_settings
      keystroke
    fi
  else
    nasip=$tempip
    keystroke;
  fi
}

# --------------------------------------------------[ Procedure to get the server IP
get_server_ip () {
  tempip=$serverip
  read -p "Enter the new server IP in CIDR format (EX 192.168.165.123/24): " serverip
  if checkCidrFormat "${serverip}"; then
    echo "- checking to make sure this IP is not in use"
    pingip="${serverip%%"/"*}"
    ping $pingip -c 5 -4
    if [ $? != 0 ]; then
      echo "- $serverip appears open"
      save_settings
      keystroke
    else
      read -p "- IP responds to pings, use it anyway? [y/N] " -n1 -s yesno
      if [ $yesno == "y" ]; then
        save_settings
        keystroke
      else serverip=$tempip
      fi
    fi
  else
    serverip=$tempip
    keystroke
  fi
}

# --------------------------------------------------[ Procedure to get the gateway IP
get_gateway_ip () {
  tempip=$gateway
  read -p "Enter the new gateway IP (EX 192.168.165.123): " gateway
  if checkIPFormat "${gateway}"; then
    save_settings
    keystroke
  else
    gateway=$tempip
    keystroke;
  fi
}

# --------------------------------------------------[ Procedure to get the DNS1 IP
get_dns1_ip () {
  tempip=$dns1
  read -p "Enter the new DNS IP (EX 192.168.165.123): " dns1
  if checkIPFormat "${dns1}"; then
    save_settings
    keystroke
  else
    dns1=$tempip
    keystroke;
  fi
}

# --------------------------------------------------[ Procedure to get the DNS2 IP
get_dns2_ip () {
  tempip=$dns2
  read -p "Enter the new DNS IP (EX 192.168.165.123): " dns2
  if checkIPFormat "${dns2}"; then
    save_settings
    keystroke
  else
    dns2=$tempip
    keystroke;
  fi
}

# --------------------------------------------------[ Procedure to update script files
update_scripts () {
  downloadok="yes"
  #echo "- /etc/tab_scripts/SetupVeeam.sh"
  #wget -O /etc/tab_scripts/SetupVeeamVM.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/SetupVeeamVM 2> /dev/null
  echo "- /etc/tab/scripts/changeip.sh"
  wget -O /etc/tab/scripts/changeip.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/ChangeIP.sh 2> /dev/null
  if [ $? != 0 ]; then downloadok="no"; fi
  echo "- /bin/bouncelt.sh"
  wget -O /bin/bouncelt.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/BounceLT.sh 2> /dev/null
  if [ $? != 0 ]; then downloadok="no"; fi
  echo "- /bin/bouncesc.sh"
  wget -O /bin/bouncesc.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/BounceSC.sh 2> /dev/null
  if [ $? != 0 ]; then downloadok="no"; fi
  echo "- /bin/nightlyactions.sh"
  wget -O /bin/nightlyactions.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/NightlyActions.sh 2> /dev/null
  if [ $? != 0 ]; then downloadok="no"; fi
  echo "- /etc/tab/scripts/checkiscsi.sh"
  wget -O /etc/tab/scripts/checkiscsi.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/CheckiSCSI.sh 2> /dev/null
  if [ $? != 0 ]; then downloadok="no"; fi
  echo "- /etc/tab/scripts/configedit.sh"
  wget -O /etc/tab/scripts/configedit.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/ConfigEdit.sh 2> /dev/null
  if [ $? != 0 ]; then downloadok="no"; fi
  # make the files executable (8 files)
  #chmod +xX /etc/tab/scripts/SetupVeeamVM.sh
  chmod +xX /etc/tab/scripts/configedit.sh
  if [ $? != 0 ]; then downloadok="no"; fi
  chmod +xX /etc/tab/scripts/changeip.sh
  if [ $? != 0 ]; then downloadok="no"; fi
  chmod +xX /bin/bouncelt.sh
  if [ $? != 0 ]; then downloadok="no"; fi
  chmod +xX /bin/bouncesc.sh
  if [ $? != 0 ]; then downloadok="no"; fi
  chmod +xX /bin/nightlyactions.sh
  if [ $? != 0 ]; then downloadok="no"; fi
  chmod +xX /etc/tab/scripts/checkiscsi.sh    
  if [ $downloadok == "no" ]; then
    echo "- something in either the download or chmod failed, review the above and manually correct the issue when done in this script."
  fi
}

# --------------------------------------------------[ Procedure to run pre-install configuration
run_preinstall () {
  installok="no"
  downloadok="yes"
  echo "====[ Installing needed applications"
  apt install htop unzip bmon default-jre crudini ncdu lsscsi -y
  if [ $? != 0 ]; then
    echo "- something failed, halting this process and returning to the main menu"
  else
    echo "====[ Disabling APT sharding for updates"
    sudo cat > /etc/apt/apt.conf.d/99-disable-phasing <<EOF
    Update-Manager::Always-Include-Phased-Updates true;
    APT::Get::Always-Include-Phased-Updates true;
EOF
    if [ $? != 0 ]; then
      echo "- something failed, halting this process and returning to the main menu"
    else
      echo "====[ Downloading scripts and marking executable"
      update_scripts
      echo "====[ Adjusting CRONTAB"
      if [ $setup_cron != "done" ] ; then  
        sed '22,$ d' /etc/crontab > /tab_temp/crontab2
        mv /tab_temp/crontab2 /etc/crontab
        echo "30 20 * * * root /bin/nightlyactions.sh" >> /etc/crontab
        echo "10 * * * * root /etc/tab/scripts/checkiscsi.sh" >> /etc/crontab
        setup_cron="done"
        save_settings
      fi
    fi
  fi
  keystroke
}

#--------------------------------------------------[ Procedite to update the OS
update_os () {
  echo "====[ Updating the OS"
  if [ $update_os == "done" ] ; then
    read -p "- Config shows updates was already done, do it anyway? [y/N] " -n1 -s yesno
      if [ $yesno == "y" ]; then
        apt update
        apt upgrade -y
      fi
  else
    apt update
    apt upgrade -y
    update_os="done"
    save_settings
  fi
}

#--------------------------------------------------[ Procedure to install Docker
install_docker () {
  echo ========== Installing Docker ==========
  apt-get update
  apt-get install ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y
  docker="installed"
  install_docker="done"
  save_settings
}

#--------------------------------------------------[ Procedure to install Webmin
install_webmin () {
  echo "- Beginning install"
  rm -f /usr/share/keyrings/webmin.gpg
  curl -fsSL https://download.webmin.com/jcameron-key.asc | sudo gpg --dearmor -o /usr/share/keyrings/webmin.gpg
  repos=$(tail  /etc/apt/sources.list | grep -m 1 "webmin")
  if [[ "$repos" != "deb [signed-by=/usr/share/keyrings/webmin.gpg] http://download.webmin.com/download/repository sarge contrib" ]]; then
    echo "- Adding WebMin to sources"
    echo "deb [signed-by=/usr/share/keyrings/webmin.gpg] http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
  else
    echo "- Repo already added, skipping"
  fi
  apt update
  apt install webmin -y
  webmin="installed"
  install_webmin="done"
  save_settings
}

#--------------------------------------------------[ Procedure to do installs
do_install () {
  clear
  echo "====[ Installing Webmin"
  if [ $webmin != "yes" ]; then
    echo "- Skipping WebMin install"
  else
    install_webmin
  fi
  echo "====[ Installing Docker"
  if [ $docker != "yes" ]; then
    echo "- Skipping Docker install"
  else
    install_docker
  fi
  echo "====[ Resetting the TABADMIN password"
  if [ $rst_tabadmin != "yes" ]; then
    echo "- Skipping resetting the TABADMIN password"
  else
    if [ $tapw == "none" ]; then
      echo "- No password was defined so nothing to cut and paste"
      passwd tabadmin
      if [ $? != 0 ]; then
        echo "- Password was not saved"
      else
        tapw="set"
        tabadmin_pw="done"
        save_settings
      fi
    fi
  fi
  echo "====[ Setting the server IP"
  if [ $set_svrip != "yes" ]; then
    echo "- Skipping server IP setup"
  else
    set_ip
  fi
  echo "====[ Installing the Automate Agent"
  if [ $inst_lt != "yes" ]; then
    echo "- Skipping installing Automate"
  else
    install_autoomate
  fi
  echo "====[ Updating scripts"
  if [ $ud_scripts != "yes" ]; then
    echo "- Skipping updating script files"
  else
    update_scripts
  fi
  echo "====[ Creating the iSCSI Initiator"
  if [ $cr_initiator != "yes" ]; then
    echo "- Skipping creating the iSCSI inititiator"
  else
    create_inititiator
  fi
  echo "====[ Updating the iSCSI conf file"
  if [ $ud_iscsi != "yes" ]; then
    echo "- Skipping updating the iSCSI confgi file"
  else
    update_iscsi
  fi
  keystroke
}

#--------------------------------------------------[ Install Menu
install_menu () {
  done="no"
  rst_tabadmin="no"
  set_svrip="no"
  inst_lt="yes"
  ud_scripts="no"
  cr_initiator="yes"
  ud_iscsi="yes"
  cr_iscsi="yes"
  ud_fstab="yes"
  cr_veeamuser="yes"
  ud_perms="yes"
  while [ $done == "no" ] 
    do
     clear
     cat<<EOF
  VM Setup Script $scriptver
  =============================
  a. Install Webmin: $webmin -- previously done: $install_webmin
  b. Install Docker: $docker -- previously done: $install_docker
  c. Reset the TABADMIN password: $rst_tabadmin -- previously done: $tabadmin_pw
  d. Set the server IP: $set_svrip -- previously done: $set_ip
  e. Install the Automate Agent: $inst_lt -- previously done: $lt_installed
  f. Update scripts: $ud_scripts
  g. Create the iSCSI initiator: $cr_initiator -- previously done: $set_initiator
  h. Edit iSCSI conf file: $ud_iscsi -- previously done: $iscsi_edited
  i. Map iSCSI to $devnm: $cr_iscsi -- previously done: $iscsi_conf
  j. Update FSTAB: $ud_fstab -- previously done: $fstab_updated
  k. Create VEEAMUSER: $cr_veeamuser -- previously done: $veeam_user
  l. Set VEEAMUSER permissions: $ud_perms -- previously done: $veeam_perms

  x. Main Menu
  !. Install the selected items
  
EOF
      read -n1 -s menu
      menu="${menu,,}"
      case "$menu" in
      "a") if [ $webmin == "yes" ]; then webmin="no"; else webmin="yes"; fi ;;
      "b") if [ $docker == "yes" ]; then docker="no"; else docker="yes"; fi ;;
      "c") if [ $rst_tabadmin == "yes" ]; then rst_tabadmin="no"; else rst_tabadmin="yes"; fi ;;
      "d") if [ $set_svrip == "yes" ]; then set_svrip="no"; else set_svrip="yes"; fi ;;
      "e") if [ $inst_lt == "yes" ]; then inst_lt="no"; else inst_lt="yes"; fi ;;
      "f") if [ $ud_scripts == "yes" ]; then ud_scripts="no"; else ud_scripts="yes"; fi ;;
      "g") if [ $cr_initiator == "yes" ]; then cr_initiator="no"; else cr_initiator="yes"; fi ;;
      "h") if [ $ud_iscsi == "yes" ]; then ud_iscsi="no"; else ud_iscsi="yes"; fi ;;
      "i") if [ $cr_iscsi == "yes" ]; then cr_iscsi="no"; else cr_iscsi="yes"; fi ;;
      "j") if [ $ud_fstab == "yes" ]; then ud_fstab="no"; else ud_fstab="yes"; fi ;;
      "k") if [ $cr_veeamuser == "yes" ]; then cr_veeamuser="no"; else cr_veeamuser="yes"; fi ;;
      "l") if [ $ud_perms == "yes" ]; then ud_perms="no"; else ud_perms="yes"; fi ;;
      "x") done="yes" ;;
      "!") do_install; done="yes" ;;
      *) echo "Invalid menu option!"
         keystroke ;;
      esac
  done
}

#--------------------------------------------------[ Variables Menu
variables_menu () {
  done="no"
  while [ $done == "no" ] 
    do
     clear
     cat<<EOF
  VM Setup Script $scriptver
  =============================
  a. Install Webmin: $webmin
  b. Install Docker: $docker
  c. New TABADMIN password: $tapw
  d. iSCSI device ID: $devnm
  e. NAS IP: $nasip
  f. Parent hostname: $hostname
  g. iSCSI mount point: $mountpoint
  h. Automate Agent URL: $lturl
  i. Desired IP of this server: $serverip
  j. Gateway IP to be used: $gateway
  k. DNS server 1 to be used: $dns1
  l. DNS server 2 to be used: $dns2

  x. Save & back to main menu
  !. Exit without saving
  
EOF
      read -n1 -s menu
      menu="${menu,,}"
      case "$menu" in
      "a") if [ $webmin == "yes" ]; then webmin="no"; else webmin="yes"; fi ;;
      "b") if [ $docker == "yes" ]; then docker="no"; else docker="yes"; fi ;;
      "c") read -p "Enter the new TABADMIN password - NOTE: This does not change it for you just makes it easier to cut/paste later: " tapw ;;
      "d") get_iscsi_device ;;
      "e") get_nas_ip ;;
      "f") get_hostname ;;
      "g") get_mountpoint ;;
      "h") read -p "Enter the URL for the Automate Agent for this client: " lturl ;;
      "i") get_server_ip ;;
      "j") get_gateway_ip ;;
      "k") get_dns1_ip ;;
      "l") get_dns2_ip ;;
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
  b. Update OS
  c. Set install variables
  d. Install routine menu

  x. Exit
  
EOF
    read -n1 -s menu
    menu="${menu,,}"
    case "$menu" in
    "a") run_preinstall ;;
    "b") update_os ;;
    "c") variables_menu ;;
    "d") install_menu ;;
    "x") clear
         exit ;;
    *) echo "Invalid menu option!"
       keystroke ;;
    esac
done
