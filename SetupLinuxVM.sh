#!/bin/bash
# check to ensure you are running as SUDO
confini="/etc/tab/conf/default.ini"

save_settings () {
  crudini --set default.ini var veeamxfs \"$veeamxfs\"
  crudini --set default.ini var iscsifail\ \"$iscsifail\"
  crudini --set default.ini var rebooted \"$rebooted\"
  crudini --set default.ini var scriptver \"$scriptver\"
  crudini --set default.ini var webmin \"$webmin\"
  crudini --set default.ini var vupw \"$vupw\"
  crudini --set default.ini var tapw \"$tapw\"
  crudini --set default.ini var nasip \"$nasip\"
  crudini --set default.ini var lturl \"$lturl\"
  crudini --set default.ini var host \"$host\"
  crudini --set default.ini var docker \"$docker\"
  crudini --set default.ini var serverip \"$serverip\"
  crudini --set default.ini stage update_os \"$update_os\"
  crudini --set default.ini stage setup_cron\ \"$setup_cron\"
  crudini --set default.ini stage install_webmin \"$install_webmin\"
  crudini --set default.ini stage install_docker \"$install_docker\"
  crudini --set default.ini stage set_ip \"set_ip\"
}

install_key_software () {
    apt install htop unzip bmon default-jre crudini -y
}

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
  source /etc/tab/conf/default.ini
}

disable_sharding () {
  echo ========== Disable APT sharding ==========
  sudo cat > /etc/apt/apt.conf.d/99-disable-phasing <<EOF
  Update-Manager::Always-Include-Phased-Updates true;
  APT::Get::Always-Include-Phased-Updates true;
EOF
}

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

setup_cron () {
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

update_os () {
  if [ $update_os != "done" ] ; then
    echo ========== Updating Ubuntu ==========
    apt update
    apt upgrade -y
    update_os="done"
    save_settings
  else
    echo "Config shows updates already run ..."
  fi
}


install_webmin () {
  if [ $install_webmin != "done" ] ; then
    echo ========== Installing WebMin ==========
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

install_docker () {
  if [ $install_docker != "done" ] ; then
    echo ========== Installing WebMin ==========
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

set_ip () {
  echo "Creating a backup of the current profile ..."
  # Creates a backup
  cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bk_`date +%Y%m%d%H%M`
  rm /etc/netplan/00-installer-config.yaml
  # Changes dhcp from 'yes' to 'no'
  echo "Disabling DHCP"
  sed -i "s/dhcp4: yes/dhcp4: no/g" /etc/netplan/00-installer-config.yaml
  # Retrieves the NIC information
  echo "."
  echo "Listing current IPs, take note of the interface for the NIC (should be eth0) ..."
  ip address
  echo "."
  nic=`ip address | awk 'NR==7{print $2}'`
  echo "Working with" $nic
  # Ask for input on network configuration
  echo "Intentional delay here for 20 seconds ... the login likes to blank the line you're on ... if this still happens you should be entering 3 things:"
  echo "VM IP in CIDR form (IE 192.168.1.100/24), the gateway, then a comma seperated DNS IP list"
  read -p "Enter the static IP of the server in CIDR notation: " staticip 
  read -p "Enter the IP of your gateway: " gatewayip
  read -p "Enter the IP of preferred nameservers (seperated by a coma if more than one): " nameserversip
  echo
  echo "Ready to apply new IP - NOTE: If you are SSH'd in your connection will drop and you will need to run the script again (wait about 2m), hit any key to begin ..."
  read -s
  # creates the new YAML file for the IP
  cat > /etc/netplan/00-installer-config.yaml <<EOF
network:
  ethernets:
    $nic
      addresses:
      - $staticip
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
}

do_install () {
  echo ========== Running selected installs ==========
  update_os
  setup_cron
  state="updated"
  save_settings
  if [ $webmin == "yes" ] ; then
    install_webmin
  fi
  if [ $docker == "yes" ] ; then
    install_docker
  fi  
  if [ $serverip != "none" ] ; then
    set_ip
  fi
  echo "Hit any key to continue back to the menu ... "
  read -rsn1
}

if [ "$EUID" -ne 0 ]
  then echo "WARNING: This needs to be run as SUDO!"
  exit
fi
clear
echo This script will configure a basic Ubuntu server to try and fit the role it will play within TAB or a client ...
echo Please use the following menu to set the server parameters. Take a checkpoint before running this. Hit any key to begin ...
read -rsn1

if [ -f "/etc/tab/conf/default.conf" ]; then
  echo "This has been run before ... pulling configuration, hit any key to restart setup ...";
  source /etc/tab/conf/default.conf
  read -rsn1
else
  echo "This is the first run of this script - setting up ...";
  first_run;
  disable_sharding;
  get_script_files;
  echo "Baseline setup done, ready to do detailed setup - you should now re-run this script from /etc/tab/scripts (I'll exit there for you)! Hit any key to exit ...";
  read -rsn1
  cd /etc/tab/scripts
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

  x. Abort and quit
  z. Start setup 
  
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
    "d") if [ $docker != "installed" ] ; then
           if [ $docker == "yes" ]; then
             docker="no"
           else
             docker="yes"
           fi
      fi ;;
    "e") read -p "new agent URL : " lturl ;;
    "f") read -p "new tabadmin password : " tapw ;;
    "n") read -p "new veeamuser password : " vupw ;;
    "o") read -p "new NAS IP : " nasip ;;
    "p") read -p "new device id : " devnm ;;
    "q") read -p "hv host name : " host ;;
    "x")  exit ;;
    "z") if [ $veeamxfs == "yes" ] ; then
            if [ $vupw != "none" ] ; then
                if [ $nasip != "none" ] ; then
                    if [ $host != "none" ] ; then
                        echo "Veeam system lets go!";
                        save_settings
                        do_install
                    else
                        echo "ERROR: Host name of parent system not set!";
                    fi
                else
                    echo "ERROR: NAS IP not set!";
                fi
            else
                echo "ERROR: Veeam user password not set!";
            fi
         else
             echo "Not a Veeam system!";
             save_settings
             do_install
          fi ;;
     * )  echo "invalid option"     ;;
    esac
    sleep 1
done
