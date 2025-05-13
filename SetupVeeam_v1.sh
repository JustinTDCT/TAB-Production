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


check_for_files () {
  echo "Checking for VBK files"
  files=$(find $mountpoint -name *.vbk | wc -l)
  if [ $files != "0" ] ; then
    echo "- VBK files found; aborting further actions as this should be manually reviewed!"
    exit
  else
    

  fi
}

update_fstab () {
  echo "Updating FSTAB"
  echo "- backing up file"
  find /etc/fstab -type f | xargs -I {} cp {} {}.bk_`date +%Y%m%d%H%M`
  echo "- removing existing line for $uuid"
  sed -i '/$uuid/d' /etc/fstab
  echo "- adding new line to FSTAB"
  echo "/dev/disk/by-uuid/$uuid /mnt/veeamrepo xfs _netdev 0 0" >> /etc/fstab
  fstab_updated="done"
  save_settings
}


get_UUID () {
  echo "Retriving UUID"
  uuid=$(blkid $devnm)
  uuid=`echo "$uuid" | cut -d'"' -f 2`
  echo "- UUID = $uuid for $devnm"
  set_uuid="done"
  save_settings
}

check_device () {
devok="false"
while [[ $devok == "false" ]] ; do
  if test -b $devnm; then
    echo "- $devnm exists another device name should be specified"
    read -p "new device id: " devnm
  else
    echo "- $devnm is available moving foreward"
    devok="true"
    save_settings
  fi
done
}

make_iscsi_connection () {
  echo
  echo "Attempting the iSCSI connection"
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
  iscsi_conf="done"
  save_settings
}

check_iscsi_connections () {
  iscsiadm -m session | grep $nasip
  if [ $? != 0 ] ; then
    echo "- no iSCSI connections from this machine to $nasip found to be logged in"
    make_iscsi_connection
  else 
    echo "- found an active iSCSI connection to $nasip - halting the script so nothing gets corrupted - \"sudo iscsiadm -m node --logout \" will close the active sessions"
    exit
fi
}

adjust_iscsi_conf () {
  echo
  conftemp=$(crudini --get /etc/iscsi/iscsid.conf "" node.startup)
  echo "Checking and updating the iSCSI config file"
  if [ $conftemp == automatic ] ; then
    echo "- node startup is already automatic, moving on"
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

setup_initiator () {
  echo
  echo "Setting up the iSCSI initiator ..."
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
}

check_nas_ip () {
  echo "Testing NAS IP"
  ping -c 5 -4 $nasip
  if [ $? != 0 ] ; then
    echo "- NAS IP did not respond to pings, exiting."
    exit
  else
    echo : "- NAS IP responds to pings, moving ahead"
    set_nasip="done"
    save_settings
  fi
}

check_mount_dir () {
  if [ -d $mountpoint ] ; then
    echo "- mountpoint already exists, will try to mount iSCSI"
  else
    echo "- mountpoint is not found, creating it"
    mkdir $mountpoint
  fi
}

do_install () {
  clear
  echo "Beginning install ..."
  if [ $set_nasip != "done" ] ; then
    check_nas_ip
  else
    echo "- NAS IP $nasip already set and verified"
  fi
  if [ $set_initiator != "done" ] ; then
    setup_initiator
  else
    echo "- iSCSI initiator configured already"
  fi
  if [ $iscsi_edited != "done" ] ; then
    adjust_iscsi_conf
  else
    echo "- iSCSI config file has been edit already"
  fi
  if [ $iscsi_conf != "done" ] ; then
    check_device
    check_iscsi_connections
  else
    echo "- device $devnm verified and iSCSI alreayd configured"
  fi
  if [ $set_uuid != "done" ] ; then
    check_for_existing_UUID
    get_UUID
  else
    echo "- UUID $UUID already done and assigned"
  fi
  if [ $fstab_updated != "done" ] ; then
    update_fstab
  else
    echo "- FSTAB has already been updated"
  fi
  check_mount_dir
  #check_for_files
}

if [ "$EUID" -ne 0 ]
  then echo "WARNING: This needs to be run as SUDO!"
  exit
fi

clear
get_settings
echo "Config file: $confini"
echo "Values pulled from the config:"
echo "- VeeamXFS Server: $veeamxfs"
echo "- NAS IP: $nasip"
echo "- Veeam user password: $vupw"
echo "- Host system or ATN: $host"
echo "- Device nanme: $devnm"
echo "- Mountpoint: $mountpoint"
echo
echo "Performing a quick check of the config file settings; you will be prompted to fix missing or invalid settings ..."
if [ $veeamxfs != "yes" ] ; then
  echo "- Server not flagged as a VeeamXFS server; while this won't stop the install it should be fixed."
  read -p "Fix this? Y/n " -n1 -s chrtmp
    if [ $chrtmp == "n" ] ; then
      echo "- Leaving for now, but this should be fixed later"
    else
      veeamxfs="yes"
      save_settings
    fi
fi
if [ $vupw == "none" ] ; then
  echo "- no password has been set for the Veeam user you need to set one now ..."
  read -p "new veeamuser password: " vupw
  save_settings
fi
if [ $vupw == "set" ] ; then
  echo "- the config indicates this user password was setup previously - if you want to change it enter \"passwd veeamuser\" at the CLI to change it manually ..."
fi
if [ $nasip == "none" ] ; then
  echo "- no NAS IP defined, please define one now ..."
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
else
  echo "- Data found in NAS IP, verifying it is an IP ..."
  if checkIPFormat "${nasip}"; then  
    echo "- verified format"
  else
    echo "- this does not appear to be a valid IP format, please enter a new one ..."
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
fi
if [ $host == "none" ] ; then
  echo "- no hostname defined, please do so - this should be the host server or if this is a physical the ATN # ..."
  read -p "hv host name: " host ;
fi
read -p "Change the device namne - currently $devnm? [y/N] " -n1 -s chrtmp
echo 
  if [ $chrtmp == "y" ] ; then
    read -p "new device id: " devnm
    save_settings
  fi
read -p "Change the mountpoint - currently $mountpoint? [y/N] " -n1 -s chrtmp
echo
  if [ $chrtmp == "y" ] ; then
    read -p "new mountpoint: " mountpoint
    save_settings
  fi
echo 
echo "Recap parameters:"
echo "- VeeamXFS Server: $veeamxfs"
echo "- NAS IP: $nasip"
echo "- Veeam user password: $vupw"
echo "- Host system or ATN: $host"
echo "- Device nanme: $devnm"
echo "- Mountpoint: $mountpoint"
echo
read -p "Proceed with install? [Y/n] " -n1 -s chrtmp
echo 
if [ $chrtmp == "n" ] ; then
  echo "NOTICE: Aborting install as requested!"
  exit
fi
do_install
