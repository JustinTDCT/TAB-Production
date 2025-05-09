confini="/etc/tab/conf/default.ini"

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

get_settings
while :
do
    clear
    cat<<EOF
  VM Config File Editor $scriptver
  =============================
  [TOGGLE VALLUES - Letter changes value to its other options]
  a. VeeamXFS Server: $veeamxfs
  b. Install WebMin: $webmin
  c. Install Docker: $docker
  d. iSCSI Test Failed: $iscsifail
  e. iSCSI Test Fail Reboot: $rebooted
  f. STAGE: CRON Adjusted: $setup_cron
  g. STAGE: OS Updated: $update_os
  h. STAGE: WebMin Installed: $install_webmin
  i. STAGE: Docker Installed: $install_docker
  j. STAGE: Server IP Set: $set_ip
  k. STAGE: Tabadmin Password Change: $tabadmin_pw
  l. STAGE: NAS IP Set: $set_nasip
  m. STAGE: Intiator Set: $set_initiator
  n. STAGE: iSCSI Conf Updated: $iscsi_conf
  o. STAGE: UUID Set: $set_uuid
  p. STAGE: Veeam User Created: $veeam_user
  q. STAGE: iSCSI Permissions Set: $veeam_perms
  q. STAGE: Automate Instakked: $lt_installed
  r. STAGE: FStab Updated: $fstab_updated
  s. STAGE: iSCSI Partitioned: $partitioned

  [MANUAL SETTINGS]
  1. Veeam User Passsword: $vupw
  2. iSCSI Device: $devnm
  3. NAS IP: $nasip
  4. Parent Hostname: $host
  5. Volume UUID: $uuid
  6. iSCSI Initiator: $initiator
  7. Tabadmin Password: $tapw
  8. Automate Agent URL: $lturl
  9. Server IP: $serverip

  !. Save and exit
  ^. Exit, no save

EOF
    read -n1 -s menu
    menu="${menu,,}"
    case "$menu" in
    "e") read -p "new agent URL: " lturl ;;
    "!") save_settings
         clear
         exit ;;
    "^") clear
         exit ;;
    * ) echo "Invalid option"
        keystroke ;;
    esac
    sleep 1
done
