#!/bin/bash
confini="/etc/tab/conf/default.ini"

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
  n. STAGE: iSCSI Configuration Done: $iscsi_conf
  o. STAGE: UUID Set: $set_uuid
  p. STAGE: Veeam User Created: $veeam_user
  q. STAGE: iSCSI Permissions Set: $veeam_perms
  q. STAGE: Automate Instakked: $lt_installed
  r. STAGE: FStab Updated: $fstab_updated
  s. STAGE: iSCSI Partitioned: $partitioned
  t. STAGE: iSCSI Config File Edited: $iscsi_edited

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
  0. XFS Mount Point: $mountpoint

  !. Save and exit
  ^. Exit, no save
  $. Script version

EOF
    read -n1 -s menu
    menu="${menu,,}"
    case "$menu" in
    "a") if [ $veeamxfs == "yes" ] ; then veeamxfs="no"
         else veeamxfs="yes"
         fi ;; 
    "b") if [ $webmin == "yes" ] ; then webmin="no"
         else webmin="yes"
         fi ;;     
    "c") if [ $docker == "yes" ] ; then docker="no"
         else docker="yes"
         fi ;;     
    "d") if [ $iscsifail == "yes" ] ; then iscsifail="no"
         else iscsifail="yes"
         fi ;;     
    "e") if [ $rebooted == "yes" ] ; then rebooted="no"
         else rebooted="yes"
         fi ;;     
    "f") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "g") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "h") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "i") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "j") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "k") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "l") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "m") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "n") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "o") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "p") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "q") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "r") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "s") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    "t") if [ $setup_cron == "yes" ] ; then setup_cron="done"
         else setup_cron="yes"
         fi ;;     
    
    "e") read -p "new agent URL: " lturl ;;
    "!") save_settings
         clear
         exit ;;
    "^") clear
         exit ;;
    * ) echo "Invalid option"
        keystroke ;;
    esac
#    sleep 1
done
