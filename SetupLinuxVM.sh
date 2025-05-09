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

keystroke () {
  echo
  echo "Press any key to continue ..."
  read -rsn1
}

# ========================================[ Install key programs - mandatory, cannot be skipped ]==================================================
install_key_software () {
    apt install htop unzip bmon default-jre crudini ncdu lsscsi -y
}

# ========================================[ Items to rune the first time the script is run ]==================================================         
first_run () {
  # Create folder structure
  echo ========== Creating TAB folder structure ==========
  mkdir /etc/tab
  mkdir /etc/tab/conf
  mkdir /etc/tab/scripts
  mkdir /etc/tab/logs
  mkdir /tab_temp
  install_key_software
  # Grab the baseline config file and load it
  echo ========== Get baseline config file ==========
  wget -O /etc/tab/conf/default.ini https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/default.ini
  echo ========== Loading baseline config file ==========
  get_settings
}

# ========================================[ Disable APT upgrade sharding ]==================================================         
disable_sharding () {
  echo ========== Disable APT sharding ==========
  sudo cat > /etc/apt/apt.conf.d/99-disable-phasing <<EOF
  Update-Manager::Always-Include-Phased-Updates true;
  APT::Get::Always-Include-Phased-Updates true;
EOF
}

# ========================================[ Retrive script files ]==================================================         
get_script_files () {
  echo ========== Grabbing script files ==========
  #echo "- /etc/tab_scripts/SetupVeeam.sh"
  #wget -O /etc/tab_scripts/SetupVeeamVM.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/SetupVeeamVM 2> /dev/null
  echo "- /etc/tab/scripts/changeip.sh"
  wget -O /etc/tab/scripts/changeip.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/ChangeIP.sh 2> /dev/null 
  echo "- /etc/tab/scripts/setuplinuxvm.sh"
  wget -O /etc/tab/scripts/setuplinuxvm.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/SetupLinuxVM.sh 2> /dev/null
  echo "- /bin/bouncelt.sh"
  wget -O /bin/bouncelt.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/BounceLT.sh 2> /dev/null
  echo "- /bin/bouncesc.sh"
  wget -O /bin/bouncesc.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/BounceSC.sh 2> /dev/null
  echo "- /bin/nightlyactions.sh"
  wget -O /bin/nightlyactions.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/NightlyActions.sh 2> /dev/null
  echo "- /etc/tab/scripts/checkiscsi.sh"
  wget -O /etc/tab/scripts/checkiscsi.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/CheckiSCSI.sh 2> /dev/null
  # make the files executable (8 files)
  #chmod +xX /etc/tab/scripts/SetupVeeamVM.sh
  chmod +xX /etc/tab/scripts/changeip.sh
  chmod +xX /etc/tab/scripts/setuplinuxvm.sh
  chmod +xX /bin/bouncelt.sh
  chmod +xX /bin/bouncesc.sh
  chmod +xX /bin/nightlyactions.sh
  chmod +xX /etc/tab/scripts/checkiscsi.sh
}

# ========================================[ Add key items to CRONTAB ]==================================================         
setup_cron () {
  echo ========== Adjusting CRONTAB ==========
  if [ $setup_cron != "done" ] ; then  
    sed '22,$ d' /etc/crontab > /tab_temp/crontab2
    mv /tab_temp/crontab2 /etc/crontab
    echo "30 20 * * * root /bin/nightlyactions.sh" >> /etc/crontab
    echo "10 * * * * root /etc/tab/scripts/checkiscsi.sh" >> /etc/crontab
    setup_cron="done"
    save_settings
  else
    echo "Config shows cron was already adjusted ..."
  fi
}

# ========================================[ Run OS updates ]==================================================         
update_os () {
  echo ========== Updating Ubuntu OS ==========
  if [ $update_os != "done" ] ; then
    apt update
    apt upgrade -y
    update_os="done"
    save_settings
  else
    echo "Config shows updates already run ..."
  fi
}

# ========================================[ Install Webmin ]==================================================         
install_webmin () {
  echo ========== Installing WebMin ==========
  if [ $install_webmin != "done" ] ; then
    rm -f /usr/share/keyrings/webmin.gpg
    curl -fsSL https://download.webmin.com/jcameron-key.asc | sudo gpg --dearmor -o /usr/share/keyrings/webmin.gpg
    repos=$(tail  /etc/apt/sources.list | grep -m 1 "webmin")
    if [[ "$repos" != "deb [signed-by=/usr/share/keyrings/webmin.gpg] http://download.webmin.com/download/repository sarge contrib" ]]; then
      echo "Adding WebMin to sources"
      echo "deb [signed-by=/usr/share/keyrings/webmin.gpg] http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
    else
      echo "Repo already added, skipping"
    fi
    apt update
    apt install webmin -y
    webmin="installed"
    install_webmin="done"
    save_settings
  else
    echo "Config shows WebMin already installed ..."
  fi
}

# ========================================[ Install Docker ]==================================================         
install_docker () {
  echo ========== Installing Docker ==========
  if [ $install_docker != "done" ] ; then
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
    apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
    docker="installed"
    install_docker="done"
    save_settings
  else
    echo "Config shows Docker already installed ..."
  fi
}

# ========================================[ Install Automate ]==================================================         
install_automate () {
  echo ========== Installing Automate ==========
  if [ $lt_installed != "done" ] ; then
    # download the LT agent
    cd /etc/tab
    wget -O agent.zip $lturl
    # make sure the command worked and bail if it didn't
    if [ $? != 0 ]; then
      echo "Getting the LT agent failed, gonna quit.";
      return
    fi
    # unzip the agent
    unzip agent.zip
    # make sure the command worked and bail if it didn't
    if [ $? != 0 ]; then
      echo "Unzipping the agent failed, gonna quit.";
      return
    fi
    cd LTechAgent/
    # set the installer script as executable then run it
    chmod +x install.sh
    sudo ./install.sh
    echo
    echo "Checking service status to see if it is running ..."
    echo
    systemctl status ltechagent | grep active
    if [ $? != 0 ] ; then
      echo "Possible failure, cannot fin d the service running; leaving this uninstalled pending a manual review ..."
    else 
      echo "Install done, you can verify in the thick client then press any key to continue ..."
      read -s
      lt_installed="done"
      save_settings
    fi  
  else
    echo "Config file shows Automate has already been installed ..."
  fi
}

# ========================================[ Set the Server IP ]==================================================         
set_ip () {
  echo ========== Setting the Sevrer IP ==========
  if [ $set_ip == "yes" ] ; then
    echo
    echo "Creating a backup of the current profile ..."
    # Creates a backup
    find /etc/netplan -type f | xargs -I {} mv {} {}.bk_`date +%Y%m%d%H%M`
    # Changes dhcp from 'yes' to 'no'
    echo "Disabling DHCP"
    sed -i "s/dhcp4: yes/dhcp4: no/g" /etc/netplan/00-installer-config.yaml
    # Retrieves the NIC information
    echo
    echo "Listing current IPs, take note of the interface for the NIC (should be eth0) ..."
    ip address
    echo
    nic=`ip address | awk 'NR==7{print $2}'`
    echo "Working with" $nic
    # Ask for input on network configuration
    echo "Using $serverip as the IP of this server ..."
    read -p "Enter the IP of your gateway: " gatewayip
    read -p "Enter the IP of preferred nameservers (seperated by a comma if more than one): " nameserversip
    echo
    echo "Ready to apply new IP - NOTE: If you are SSH'd in your connection will drop and you will need to run the script again (wait about 2m) ..."
    keystroke
    # creates the new YAML file for the IP
    cat > /etc/netplan/00-installer-config.yaml <<EOF
network:
  ethernets:
    $nic
      addresses:
      - $serverip
      nameservers:
        addresses: [$nameserversip]
      routes:
      - to: default
        via: $gatewayip
  version: 2
EOF
    # sets permissions on the new file
    chown root:root /etc/netplan/00-installer-config.yaml
    chmod 700 /etc/netplan/00-installer-config.yaml
    # applies the new file
    sudo netplan apply
    echo "Pausing for 10sec then listing interfaces ..."
    read -t10
    # output the IP
    ip address
    set_ip="done"
    save_settings
  else 
    echo "Config shows the IP was already set ..."
  fi
}

# ========================================[ Reset the Tabadmin password ]==================================================         
reset_tabadmin_pw () {
  echo ========== Resetting the Tabadmin password ==========
  if [ $tabadmin_pw != "done" ] ; then
    echo "PW provided (so you can cut/paste): $tapw   --- note: once saved it will be purged from the config file"
    passwd tabadmin
    if [ $? != 0 ]; then
      echo "Password change ended in error; not saving this stage as done";
    else
      echo "Password changed"
      tapw="set"
      tabadmin_pw="done"    
      save_settings  
    fi
  else
    echo "Config file indicates this was already set using the script, please edit the config file or use \"passwd tabadmin\" to manually change it from CLI."
  fi
}

check_health () {
  clear
  echo "Reloading config data to analyze it ..."
  get_settings
  echo "====[ CONFIG FILE CHECK ]===="
  echo "looking for errant settings"
  if 
}

# ========================================[ Install ]==================================================         
do_install () {
  echo ========== Running selected installs ==========
  update_os
  save_settings
  setup_cron
  if [ $webmin == "yes" ] ; then
    install_webmin
  else
    if [ $webmin == "installed" ] ; then
      echo "WebMin already installed ..."
    else
      echo "Skipping WebMin install as defined in config ..."
    fi
  fi
  save_settings
  if [ $docker == "yes" ] ; then
    install_docker
  else
    if [ $docker == "installed" ] ; then
      echo "Docker already installed ..."
    else
      echo "Skipping Docker install as defined in config ..."
    fi
  fi  
  save_settings
  if [ $serverip != "none" ] ; then
    set_ip
  else
    echo "Skipping IP setup as defined in config ..."
  fi
  save_settings
  if [ $tapw == "none" ] ; then
      echo "Skipping tabadmin password as none defined in config ..."
  else
    if [ $tapw == "set" ] ; then
      echo "Config file indicates this was already set using the script, please edit the config file or use \"passwd tabadmin\" to manually change it from CLI."
    else
      reset_tabadmin_pw
    fi
  fi
  save_settings
  if [ $lturl != "none" ] ; then
    install_automate
  else
    echo "Skipping Automate install as no URL was defined ..."
  fi
  keystroke
}

function checkCidrFormat {
  IPOK="no"
  local ipCidr="${1}"
  local validIpCidr
  validIpCidr='(^([1-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\.([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-5])\/([1-9]|[1-2][0-9]|[3][0-2]))$'
  if [[ $ipCidr =~ ^$validIpCidr ]]; then
    echo "Format valid"
    IPOK="yes"
    return 0
  else
    echo "Not a CIDR format"
    return 1
  fi
}

if [ "$EUID" -ne 0 ]
  then echo "WARNING: This needs to be run as SUDO!"
  exit
fi
clear
echo This script will configure a basic Ubuntu server to try and fit the role it will play within TAB or a client ...
echo Please use the following menu to set the server parameters. Take a checkpoint before running this ...
keystroke

if [ -f "/etc/tab/conf/default.ini" ]; then
  echo "This has been run before ... pulling configuration";
  get_settings
  keystroke
else
  echo "This is the first run of this script - setting up ...";
  first_run;
  disable_sharding;
  get_script_files;
  echo "Baseline setup done, ready to do detailed setup - we will now re-run this script from /etc/tab/scripts ...";
  keystroke
  /etc/tab/scripts/./setuplinuxvm.sh
  exit
fi


# this is the main menu where you adjust how this machine will be setup
while :
do
    clear
    cat<<EOF
  VM Setup Script $scriptver
  =============================
  a. VeeamXFS Server: $veeamxfs
  b. Install WebMin: $webmin
  c. Script set IP of this server: $serverip
  d. Install Docker-CE and Compose: $docker
  e. Automate agent download URL: $lturl
  f. TABADMIN password change: $tapw
  
  The below are only needed if this is a VeeamXFS VM
  n. Veeam user password: $vupw
  o. NAS IP: $nasip
  p. iSCSI dev name: $devnm
  q. Host server name: $host

  y. Perform TAB script health check
  x. Abort and quit
  z. Start setup 

  NOTE - Any user input value besides a default value will cause the script to attempt that portion!
  
EOF
    read -n1 -s menu
    menu="${menu,,}"
    case "$menu" in
    "a") if [ $veeamxfs != "installed" ] ; then
           if [ $veeamxfs == "yes" ]; then
             veeamxfs="no"
           else
             veeamxfs="yes"
           fi
      fi ;;
    "b") if [ $webmin != "installed" ] ; then
           if [ $webmin == "yes" ]; then
             webmin="no"
           else
             webmin="yes"
           fi
      fi ;;
    "c") echo "Enter the IP in CIDR format. IE, 192.168.1.123/24"
            while [[ $IPOK == "no" ]] ;
              do
              read -rp "new IP: " serverip
              if checkCidrFormat "${serverip}"; then
              echo "Moving on..."
              fi
            done 
            IPOK="no" ;;
    "d") if [ $docker != "installed" ] ; then
           if [ $docker == "yes" ]; then
             docker="no"
           else
             docker="yes"
           fi
      fi ;;
    "e") read -p "new agent URL: " lturl ;;
    "f") read -p "new tabadmin password: " tapw ;;
    "n") read -p "new veeamuser password: " vupw ;;
    "o") read -p "new NAS IP: " nasip ;;
    "p") read -p "new device id: " devnm ;;
    "q") read -p "hv host name: " host ;;
    "y") check_health ;;
    "x") read -p "Save your config? Y/n " -n1 -s saveme
            if [ $saveme == "y" ] ; then
                echo "Saving settings ..."
                save_settings
            fi
            exit ;;
    "z") if [ $veeamxfs == "yes" ] ; then
            if [ $vupw != "none" ] ; then
                if [ $nasip != "none" ] ; then
                    if [ $host != "none" ] ; then
                        echo "Veeam system lets go!";
                        save_settings
                        do_install
                    else
                        echo "ERROR: Host name of parent system not set! ...";
                        keystroke
                    fi
                else
                    echo "ERROR: NAS IP not set! ...";
                    keystroke
                fi
            else
                echo "ERROR: Veeam user password not set! ...";
                keystroke
            fi
         else
             echo "Not a Veeam system!";
             save_settings
             do_install
          fi ;;
     * )  echo "invalid option"
                keystroke  ;;
    esac
    sleep 1
done
