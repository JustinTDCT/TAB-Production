#!/bin/bash
# check to ensure you are running as SUDO
if [ "$EUID" -ne 0 ]
  then echo "WARNING: This needs to be run as SUDO!"
  exit
fi
clear
echo This script will configure a basic Ubuntu server to try and fit the role it will play within TAB or a client ...
echo Please use the following menu to set the server parameters. Take a checkpoint before running this. Hit any key to begin ...
read -rsn1
# Create folder structure
echo ========== Creating TAB folder structure ==========
mkdir /etc/tab
mkdir /etc/tab/conf
mkdir /etc/tab/scripts
mkdir /etc/tab/logs
# Grab the baseline config file and load it
echo ========== Get baseline config file ==========
wget -O /etc/tab/conf/default.conf https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/default.conf
echo ========== Loading baseline config file ==========
source /etc/tab/conf/default.conf

disable_sharding () {
  echo ========== Disable APT sharding ==========
  sudo cat > /etc/apt/apt.conf.d/99-disable-phasing <<EOF
  Update-Manager::Always-Include-Phased-Updates true;
  APT::Get::Always-Include-Phased-Updates true;
EOF
}

get_script_files () {
  echo ========== Grabbing script files ==========
  echo "- /etc/tab_scripts/SetupVeeam.sh"
  wget -O /etc/tab_scripts/SetupVeeamVM.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/SetupVeeamVM 2> /dev/null
  echo "- /etc/tab_scripts/SetIP.sh"
  wget -O /etc/tab_scripts/SetIP.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/setip 2> /dev/null 
  echo "- /etc/tab_scripts/loginscript.sh"
  wget -O /etc/tab_scripts/loginscript.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/loginscript 2> /dev/null
  echo "- /etc/tab_scripts/DeployUbuntu.sh"
  wget -O /etc/tab_scripts/DeployUbuntu.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/DeployUbuntu.sh 2> /dev/null
  echo "- /etc/tab_scripts/disable-phased-update.sh"
  wget -O /etc/tabscripts/disable-phased-update.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/disable-phased-update.sh 2> /dev/null
  echo "- /bin/bouncelt.sh"
  wget -O /bin/bouncelt.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/bouncelt.sh 2> /dev/null
  echo "- /bin/bouncesc.sh"
  wget -O /bin/bouncesc.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/bouncesc.sh 2> /dev/null
  echo "- /bin/nightlyactions.sh"
  wget -O /bin/nightlyactions.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/nightlyactions.sh 2> /dev/null
  echo "- /etc/tab_scripts/checkiscsi.sh"
  wget -O /etc/tab_scripts/checkiscsi.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/checkiscsi.sh 2> /dev/null
  # make the files executable (8 files)
  chmod +xX /etc/tab_scripts/SetupVeeamVM.sh
  chmod +xX /etc/tab_scripts/SetIP.sh
  chmod +xX /etc/tab_scripts/loginscript.sh
  chmod +xX /etc/tab_scripts/DeployUbuntu.sh
  chmod +xX /etc/tab_scripts/disable-phased-update.sh
  chmod +xX /bin/bouncelt.sh
  chmod +xX /bin/bouncesc.sh
  chmod +xX /bin/nightlyactions.sh
  chmod +xX /etc/tab_scripts/checkiscsi.sh
}

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
    "a") if [ $veeamxfs == "yes" ]; then
      veeamxfs="no"
      else
      veeamxfs="yes"
      fi ;;
    "b") if [ $webmin == "yes" ]; then
      webmin="no"
      else
      webmin="yes"
      fi ;;
    "d") if [ $docker == "yes" ]; then
      docker="no"
      else
      docker="yes"
      fi ;;
    #"z") if [ $veeamxfs == "yes" ]; then
    #  fi ;;
    "x")  exit                      ;;
     * )  echo "invalid option"     ;;
    esac
    sleep 1
done
