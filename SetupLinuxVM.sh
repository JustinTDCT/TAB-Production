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

first_run () {
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
  echo "- /etc/tab_scripts/SetupVeeam.sh"
  wget -O /etc/tab_scripts/SetupVeeamVM.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/SetupVeeamVM 2> /dev/null
  echo "- /etc/tab_scripts/changeip.sh"
  wget -O /etc/tab_scripts/changeip.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/ChangeIP.sh 2> /dev/null 
  echo "- /etc/tab_scripts/loginscript.sh"
  wget -O /etc/tab_scripts/loginscript.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/loginscript 2> /dev/null
  echo "- /etc/tab_scripts/DeployUbuntu.sh"
  wget -O /etc/tab_scripts/DeployUbuntu.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/DeployUbuntu.sh 2> /dev/null
  echo "- /etc/tab_scripts/disable-phased-update.sh"
  wget -O /etc/tabscripts/disable-phased-update.sh https://raw.githubusercontent.com/JustinTDCT/Stuff-for-TAB/refs/heads/main/disable-phased-update.sh 2> /dev/null
  echo "- /bin/bouncelt.sh"
  wget -O /bin/bouncelt.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/BounceLT.sh 2> /dev/null
  echo "- /bin/bouncesc.sh"
  wget -O /bin/bouncesc.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/BounceSC.sh 2> /dev/null
  echo "- /bin/nightlyactions.sh"
  wget -O /bin/nightlyactions.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/NightlyActions.sh 2> /dev/null
  echo "- /etc/tab_scripts/checkiscsi.sh"
  wget -O /etc/tab/scripts/checkiscsi.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/CheckiSCSI.sh 2> /dev/null
  # make the files executable (8 files)
  chmod +xX /etc/tab/scripts/SetupVeeamVM.sh
  chmod +xX /etc/tab/scripts/changeip.sh
  chmod +xX /etc/tab/scripts/loginscript.sh
  chmod +xX /etc/tab/scripts/DeployUbuntu.sh
  chmod +xX /etc/tab/scripts/disable-phased-update.sh
  chmod +xX /bin/bouncelt.sh
  chmod +xX /bin/bouncesc.sh
  chmod +xX /bin/nightlyactions.sh
  chmod +xX /etc/tab/scripts/checkiscsi.sh
}

if [ -f "/etc/tab/conf/default.conf" ]; then
  echo "This has been run before ... pulling configuration data and re-starting the setup ...";
  source /etc/tab/conf/default.conf
else
  echo "This is the first run of this script - setting up ...";
  first_run;
  disable_sharding;
  echo "Baseline setup done, ready to do detailed setup - hit any key to to continue ...";
  read -rsn1
  source /etc/tab/conf/default.conf
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
    "e") read -p "new agent URL : " lturl ;;
    "f") read -p "new tabadmin password : " tapw ;;
    "n") read -p "new veeamuser password : " vupw ;;
    "o") read -p "new NAS IP : " nasip ;;
    "p") read -p "new device id : " devnm ;;
    "q") read -p "hv host name : " host ;;
    "x")  exit ;;
    "z") if [ $veeamxfs == "yes" ] ; then
            if [ $vupw != "none" ] ; then
                if [ $nasip != "none"] ; then
                    if [ $host != "none"] ; then
                        echo "Veeam system lets go!";
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
             echo "Not VEEAM";
          fi ;;
     * )  echo "invalid option"     ;;
    esac
    sleep 1
done
