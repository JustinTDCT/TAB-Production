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
  echo "- Loading settings ..."
  source $confini
}

# --------------------------------------------------[ procedure to save the config file
save_settings () {
  echo "Saving settings ..."
  crudini --ini-options=nospace --set $confini "" scriptver \"$scriptver\"
  crudini --ini-options=nospace --set $confini "" preinstall \"$preinstall\"
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
  crudini --ini-options=nospace --set $confini "" gateway \"$gateway\"
  crudini --ini-options=nospace --set $confini "" dns1 \"$dns1\"
  crudini --ini-options=nospace --set $confini "" dns2 \"$dns2\"
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
  echo "==========[ Creating folders ]=========="
  mkdir /etc/tab
  mkdir /etc/tab/conf
  mkdir /etc/tab/scripts
  mkdir /etc/tab/logs
  mkdir /tab_temp
  # Grab the baseline config file and load it
  echo "==========[ Grabbing baseline config file ]=========="
  wget -O /etc/tab/conf/default.ini https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/default.ini
  echo "==========[ Loading baseline config file ]=========="
  get_settings
}

# --------------------------------------------------[ Procedure to get and check iSCSI device
get_iscsi_device () {
  tempdev=$devnm
  read -p "- Enter the new iSCSI device name (/dev/sdX format): " devnm
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

# --------------------------------------------------[ Procedure to get the iSCSI mount point
get_mountpoint () {
  temppoint=$mountpoint
  read -p "- Enter the new mount point to be used for iSCSI mapping (should be in /mnt folder): " mountpoint
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

# --------------------------------------------------[ Procedure to check the mount point
check_mountpoint () {
  echo "- Verifying the mount point"
  if [ -d $mountpoint ]; then
    echo "- Mountpoint verified as actual folder"
  else
    get_mountpoint
  fi
}

# --------------------------------------------------[ Procedure to get the NAS IP
get_nas_ip () {
  tempip=$nasip
  read -p "- Enter the new NAS IP (EX 192.168.165.123): " nasip
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
  read -p "- Enter the new server IP in CIDR format (EX 192.168.165.123/24): " serverip
  if checkCidrFormat "${serverip}"; then
    echo "- checking to make sure this IP is not in use"
    pingip="${serverip%%"/"*}"
    ping $pingip -c 5 -4
    if [ $? != 0 ]; then
      echo "- $serverip appears open"
      IPOK="yes"
      save_settings
      keystroke
    else
      read -p "- IP responds to pings, use it anyway? [y/N] " -n1 -s yesno
      if [ $yesno == "y" ]; then
        IPOK="yes"
        save_settings
        keystroke
      else serverip=$tempip; IPOK="no"
      fi
    fi
  else
    serverip=$tempip; IPOK="no"
    keystroke
  fi
}

# --------------------------------------------------[ Procedure to get the gateway IP
get_gateway_ip () {
  tempip=$gateway
  read -p "- Enter the new gateway IP (EX 192.168.165.123): " gateway
  if checkIPFormat "${gateway}"; then
    IPOK="yes"
    save_settings
    keystroke
  else
    gateway=$tempip; IPOK="no"
    keystroke;
  fi
}

# --------------------------------------------------[ Procedure to get the DNS1 IP
get_dns1_ip () {
  tempip=$dns1
  read -p "- Enter the new DNS IP (EX 192.168.165.123): " dns1
  if checkIPFormat "${dns1}"; then
    IPOK="yes"
    save_settings
    keystroke
  else
    dns1=$tempip
    IPOK="no"
    keystroke;
  fi
}

# --------------------------------------------------[ Procedure to get the DNS2 IP
get_dns2_ip () {
  tempip=$dns2
  read -p "- Enter the new DNS IP (EX 192.168.165.123): " dns2
  if checkIPFormat "${dns2}"; then
    save_settings
    IPOK="yes"
    keystroke
  else
    dns2=$tempip
    IPOK="no"
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
  echo "==========[ Installing needed applications ]=========="
  apt install htop unzip bmon default-jre crudini ncdu lsscsi -y
  if [ $? != 0 ]; then
    echo "- something failed, halting this process and returning to the main menu"
  else
    echo "- done"
    echo "==========[ Disabling APT sharding for updates ]=========="
    sudo cat > /etc/apt/apt.conf.d/99-disable-phasing <<EOF
    Update-Manager::Always-Include-Phased-Updates true;
    APT::Get::Always-Include-Phased-Updates true;
EOF
    if [ $? != 0 ]; then
      echo "- something failed, halting this process and returning to the main menu"
    else
      echo "- done"
      echo "==========[ Downloading scripts and marking executable ]=========="
      update_scripts
      echo"- done"
      echo "==========[ Adjusting CRONTAB ]=========="
      sed '22,$ d' /etc/crontab > /tab_temp/crontab2
      mv /tab_temp/crontab2 /etc/crontab
      echo "30 20 * * * root /bin/nightlyactions.sh" >> /etc/crontab
      echo "10 * * * * root /etc/tab/scripts/checkiscsi.sh" >> /etc/crontab
      setup_cron="done"
      preinstall="done"
      echo "- done"
      save_settings
    fi
  fi
  keystroke
}

#--------------------------------------------------[ Procedite to update the OS
update_os () {
  echo "==========[ Updating the OS ]=========="
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

#--------------------------------------------------[ Procedure to set the IP
set_ip () {
  if [ $serverip == "none" ]; then
    echo "- Server IP is not set"
    get_server_ip
  fi
  if [ $gateway == "none" ]; then
    echo " - Gateway IP not set"
    get_gateway_ip
  fi
  if [ $dns1 == "none" ]; then
    echo "- DNS1 not set"
    get_dns1_ip
  fi
  if [ $dns2 == "none" ]; then
    echo "- DNS2 not set"
    get_dns2_ip
  fi
  save_settings
  echo "- Creating a backup of the current profile ..."
  # Creates a backup
  find /etc/netplan -type f | xargs -I {} mv {} {}.bk_`date +%Y%m%d%H%M`
  # Changes dhcp from 'yes' to 'no'
  #echo "- Disabling DHCP"
  #sed -i "s/dhcp4: yes/dhcp4: no/g" /etc/netplan/00-installer-config.yaml
  # Retrieves the NIC information
  echo
  echo "- Listing current IPs, take note of the interface for the NIC (should be eth0) ..."
  ip address
  echo
  nic=`ip address | awk 'NR==7{print $2}'`
  echo "- Working with" $nic
  # Ask for input on network configuration
  echo "- Using $serverip as the IP of this server, $gateway as the gateway and $dns1,$dns2 as DNS"
  # creates the new YAML file for the IP
  cat > /etc/netplan/00-installer-config.yaml <<EOF
network:
  ethernets:
    $nic
      addresses:
      - $serverip
      nameservers:
        addresses: [$dns1,$dns2]
      routes:
      - to: default
        via: $gateway
  version: 2
EOF
  # sets permissions on the new file
  chown root:root /etc/netplan/00-installer-config.yaml
  chmod 700 /etc/netplan/00-installer-config.yaml
  # applies the new file
  sudo netplan apply
  echo "- Pausing for 10sec then listing interfaces ..."
  read -t10
  # output the IP
  ip address
  set_ip="done"
  save_settings
}

#--------------------------------------------------[ Procedure to indstall LT
install_automate () {
  echo "==========[ Installing Automate ]=========="
  cd /etc/tab
  if [ $lturl == "none" ]; then
    echo "- no URL has been set"
    read -p "- Enter the URL for the Automate Agent for this client: " lturl
    save_settings
  fi
  wget -O agent.zip $lturl
  # make sure the command worked and bail if it didn't
  if [ $? != 0 ]; then
    echo "- Getting the LT agent failed, gonna quit this step.";
    return
  fi
  # unzip the agent
  unzip agent.zip
  # make sure the command worked and bail if it didn't
  if [ $? != 0 ]; then
    echo "- Unzipping the agent failed, gonna quit.";
    return
  fi
  cd LTechAgent/
  # set the installer script as executable then run it
  chmod +x install.sh
  sudo ./install.sh
  echo
  echo "- Checking service status to see if it is running ..."
  echo
  systemctl status ltechagent | grep active
  if [ $? != 0 ] ; then
    echo "- Possible failure, cannot fin d the service running; leaving this uninstalled pending a manual review "
  else 
    echo "- Install done, you can verify in the thick client if desired."
    keystroke
    lt_installed="done"
    save_settings
  fi  
}

#--------------------------------------------------[ Procedure to adjust the iSCSI config file
adjust_iscsi_conf () {
  echo
  conftemp=$(crudini --get /etc/iscsi/iscsid.conf "" node.startup)
  if [ $conftemp == automatic ] ; then
    echo "- node startup is already automatic, moving on"
    iscsi_edited="done"
    save_settings  
  else 
    echo "- node startup found to be $conftemp, setting to automatic"
    crudini --set /etc/iscsi/iscsid.conf "" node.startup automatic
    conftemp=$(crudini --get /etc/iscsi/iscsid.conf "" node.startup)
    if [ $conftemp == automatic ] ; then
      echo "- new setting confirmed, moving on"
      iscsi_edited="done"
      save_settings
    else
      echo "- the new setting did not take; install will continue but you need to manuallt set \"node.startup\" in the /etc/iscsi/iscsid.conf file to \"automatic\""
    fi
  fi
  echo "- restarting the iSCSI service"
  sudo systemctl restart iscsid open-iscsi
  if [ $? != 0 ]; then
    echo "- The service did not restart normally, since nothing more can be done the script will exit";
    exit
  fi
}

#--------------------------------------------------[ Procedure to make the iSCSI connections
make_iscsi_connection () {
  echo "- Checking for prior saved iSCSI connections"
  ls /etc/iscsi/send_targets/ | grep -v $nasip
  if [ $? == 0 ] ; then
    read -p  "- Found saved sessions, should these be removed (answering \"yes\" will also close any open iSCSI sessions -- \"no\" will exit the script)? [Y/n] " -n1 -s yesno
    if [ $yesno == "n" ]; then
      echo "- exiting"
      exit
    else
      echo "- Logging out connections"
      iscsiadm -m node --logout
      echo" - Removing old connection folders"
      rm -r /etc/iscsi/nodes/
      rm -r /etc/iscsi/send_targets/
    fi
  else
    echo "- Connecting to the iSCSI LUN"
    sudo iscsiadm -m discovery -t sendtargets -p $nasip
    # make sure the command worked and bail if it didn't
    if [ $? != 0 ]; then
      echo "- No LUN targets found, script exiting as nothing can be done";
      exit
    fi
    echo
    echo "- Logging in to iSCSI ..."
    # connect to the LUNs
    sudo iscsiadm -m node --login
    # make sure the command worked and bail if it didn't
    if [ $? != 0 ]; then
      echo "- No LUN targets found, script exiting as nothing can be done";
      exit
    fi
    iscsi_logged_in="yes"
    iscsi_conf="done"
    save_settings
  fi
}

#--------------------------------------------------[ Procedure to check for iSCSI connections
check_iscsi_connections () {
  echo "- Checking for active iSCSI sessions"
  iscsiadm -m session | grep $nasip
  if [ $? != 0 ] ; then
    echo "- no iSCSI connections from this machine to $nasip found to be logged in"
    make_iscsi_connection
  else 
    read -p  "- found an active iSCSI connection to $nasip - do you want to close them (saying \"no\" exits the script? [Y/n] " -n1 -s yesno
    if [ $yesno == "n" ]; then
      echo "- exiting"
      exit
    else
      echo "- Logging out iSCSI connections"
      iscsiadm -m node --logout
      make_iscsi_connection
    fi   
  fi
}

#--------------------------------------------------[ Procedure to setupo the iSCSI initiator
setup_initiator () {
  sudo cat > /etc/iscsi/initiatorname.iscsi <<EOF
InitiatorName=iqn.2004-10.com.$host:veeamxfs01
EOF
  # make sure the command worked and bail if it didn't
  if [ $? != 0 ]; then
    echo "- FAIL: could not set the initiator exiting the script since nothing further can be done till that is fixed";
    exit
  fi
  initiator="InitiatorName=iqn.2004-10.com.$host:veeamxfs01"
  echo "- Pausing the script while you verify that the initiator and LUN are set up in the NAS"
  echo "- Initiator: $initiator"
  keystroke
  set_initiator="done"
  save_settings
  check_iscsi_connections
}

#--------------------------------------------------[ Procedure to capture the UUID
get_UUID () {
  uuid=$(blkid $devnm)
  uuid=`echo "$uuid" | cut -d'"' -f 2`
  echo "- UUID = $uuid for $devnm"
  set_uuid="done"
  save_settings
}

#--------------------------------------------------[ Procedure to check for existing files
check_for_files () {
  echo "- Checking for existing backup images"
  files=$(find $mountpoint -name *.vbk | wc -l)
  if [ $files != "0" ] ; then
    echo "- VBK files found; aborting further actions as this should be manually reviewed!"
    exit
  else 
    echo "- no files found, continuing"
  fi
}

#--------------------------------------------------[ Procedure to check for the UUID
check_for_existing_UUID () {
  blkid | grep $devnm
  if [ $? != 0 ] ; then
    echo "- no UUID has been found which means there is no recognized partition - do you want to make one? Saying no exits the script. [Y/n] "
    read -rsn1 saveme
    if [ $saveme == "y" ] ; then
      echo "- making the new partition"
      sudo parted --script $devnm "mklabel gpt"
      sudo parted --script $devnm "mkpart primary 0% 100%"
      echo "- formatting the partion"
      sudo mkfs.xfs -b size=4096 -m reflink=1,crc=1 $devnm -f -K
      partitioned="done"
      save_settings
    else
      echo "Exiting script"
      exit
    fi
  else
    echo "- UUID exists moving ahead and will try to mount this to see if there are files present"
  fi
}

#--------------------------------------------------[ Procedure to updat fstab
update_fstab () {
  echo "- backing up original file"
  find /etc/fstab -type f | xargs -I {} cp {} {}.bk_`date +%Y%m%d%H%M`
  echo "- removing existing line for $uuid"
  sed -i 'netdev' /etc/fstab
  echo "- adding new line to FSTAB"
  echo "/dev/disk/by-uuid/$uuid /mnt/veeamrepo xfs _netdev 0 0" >> /etc/fstab
  fstab_updated="done"
  save_settings
}

#--------------------------------------------------[ Procedure to do installs
do_install () {
  clear
  echo "=========[ Installing Webmin ]=========="
  if [ $webmin != "yes" ]; then
    echo "- Skipping WebMin install"
  else
    install_webmin
    echo "- Done"
  fi
  echo "==========[ Installing Docker ]=========="
  if [ $docker != "yes" ]; then
    echo "- Skipping Docker install"
  else
    install_docker
    echo "- Done"
  fi
  echo "==========[ Resetting the TABADMIN password ]=========="
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
    echo "- Done"
  fi
  echo "==========[ Setting the server IP ]=========="
  if [ $set_svrip != "yes" ]; then
    echo "- Skipping server IP setup"
  else
    set_ip
    echo "- Done"
  fi
  echo "==========[ Installing the Automate Agent ]=========="
  if [ $inst_lt != "yes" ]; then
    echo "- Skipping installing Automate"
  else
    install_automate
    echo "- Done"
  fi
  echo "==========[ Updating scripts ]=========="
  if [ $ud_scripts != "yes" ]; then
    echo "- Skipping updating script files"
  else
    update_scripts
    echo "- Done"
  fi
  echo "==========[ Updating the iSCSI conf file ]=========="
  if [ $ud_iscsi != "yes" ]; then
    echo "- Skipping updating the iSCSI confgi file"
  else
    adjust_iscsi_conf
    echo "- Done"
  fi
  echo "==========[ Creating the iSCSI Initiator ]=========="
  if [ $cr_initiator != "yes" ]; then
    echo "- Skipping creating the iSCSI inititiator"
  else
    setup_initiator
    echo "- Done"
  fi
  echo "==========[ Updating the UUID and FSTAB ]=========="
  if [ $ud_fstab != "yes" ]; then
    echo "- Skipping UUID / FSTAB updates"
  else
    check_for_existing_UUID
    get_UUID
    check_for_files
    update_fstab
  fi
  keystroke
}

#--------------------------------------------------[ Install Menu
install_menu () {
  done="no"
  rst_tabadmin="no"
  if [ $set_ip == "done" ]; then set_svrip="no"; else set_svrip="yes"; fi; 
  if [ $lt_installed == "done" ]; then inst_lt="no"; else inst_lt="yes"; fi;
  ud_scripts="no"
  if [ $set_initiator == "done" ]; then cr_initiator="no"; else cr_initiator="yes"; fi;
  if [ $iscsi_edited == "done" ]; then ud_iscsi="no"; else ud_iscsi="yes"; fi;
  if [ $iscsi_conf == "done" ]; then cr_iscsi="no"; else cr_iscsi="yes"; fi;
  if [ $fstab_updated == "done" ]; then ud_fstab="no"; else ud_fstab="yes"; fi;
  if [ $veeam_user == "done" ]; then cr_veeamuser="no"; else cr_veeamuser="yes"; fi;
  if [ $veeam_perms == "done" ]; then ud_perms="no"; else ud_perms="yes"; fi;
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

  Settings Configured
  ------------------------------
  iSCSI device ID: $devnm
  NAS IP: $nasip
  Parent hostname: $hostname
  iSCSI mount point: $mountpoint
  Automate Agent URL: $lturl
  Desired IP of this server: $serverip
  Gateway IP to be used: $gateway
  DNS server 1 to be used: $dns1
  DNS server 2 to be used: $dns2

  x. Main Menu
  !. Install the selected items

  NOTE: 
  - If an item shows 'installed' you can still select it to re-install or redo that step; the script will use stored values so be sure they are correct
  - If variables are not set (IE using default values) you will be prompted for the needed values

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
  f. Parent hostname: $host
  g. iSCSI mount point: $mountpoint
  h. Automate Agent URL: $lturl
  i. Desired IP of this server: $serverip
  j. Gateway IP to be used: $gateway
  k. DNS server 1 to be used: $dns1
  l. DNS server 2 to be used: $dns2

  x. Save & back to main menu
  !. Exit without saving

  NOTE
  - Please be sure to be accurate. The script will do its' best to verify the information but cannot account for everything
  
EOF
      read -n1 -s menu
      menu="${menu,,}"
      case "$menu" in
      "a") if [ $webmin == "yes" ]; then webmin="no"; else webmin="yes"; fi ;;
      "b") if [ $docker == "yes" ]; then docker="no"; else docker="yes"; fi ;;
      "c") read -p "- Enter the new TABADMIN password - NOTE: This does not change it for you just makes it easier to cut/paste later: " tapw ;;
      "d") get_iscsi_device ;;
      "e") get_nas_ip ;;
      "f") read -p "- Enter the parent host hostname or the ATN of this machine: " host ;;
      "g") get_mountpoint ;;
      "h") read -p "- Enter the URL for the Automate Agent for this client: " lturl ;;
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
  a. Pre-install requirements -- status: $preinstall
  b. Update OS -- status: $update_os
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
