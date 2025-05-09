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
