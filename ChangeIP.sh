#!/bin/bash
clear
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
echo "Ready to apply new IP - NOTE: If you are SSH'd in your connection will drop, hit any key to begin ..."
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
echo "."
echo "If you were consoled in (not SSH) and you stayed connected you should run the Veeam VM setup manually: sudo ./SetupVeeamVM.sh"
