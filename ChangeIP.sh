#!/bin/bash

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
read -p "The config file has an IP of $nasip ... do you need to change this? [y/N] " -n1 -s changeip
            if [ $changeip == "y" ] ; then
              echo
              echo "Enter the IP in regular format. IE, 192.168.1.123"
                while [[ $IPOK == "no" ]] ;
                do
                  read -rp "new IP: " nasip
                  if checkIPFormat "${nasip}"; then
                    echo "Moving on..."
                    save_settings
                  fi
                done 
              IPOK="no"    
            fi


echo ========== Setting the Sevrer IP ==========
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
read -p "Enter the IP of your gateway (this will not be verified): " gatewayip
read -p "Enter the IP of preferred nameservers (seperated by a comma if more than one, this will not be verified): " nameserversip
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
