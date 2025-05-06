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
      $veeamxfs="no"
      else
      $veeamxfs="yes"
      fi ;;
    "x")  exit                      ;;
     * )  echo "invalid option"     ;;
    esac
    sleep 1
done
