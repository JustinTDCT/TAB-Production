#!/bin/bash
confini="/etc/tab/conf/default.ini"
# --------------------------------------------------[ procedure to load the config file
get_settings () {
  echo "- Loading settings ..."
  source $confini
}
echo "=============================================================" >> /etc/tab/log/nightlyactions.log
echo "=============================================================" >> /etc/tab/log/nightlyactions.log
echo "=============================================================" >> /etc/tab/log/nightlyactions.log
echo "$(date)" >> /etc/tab/log/nightlyactions.log
echo "=============================================================" >> /etc/tab/log/nightlyactions.log
# grab new files
echo "Grab new files ..." >> /etc/tab/log/nightlyactions.log
wget -O /etc/tab/scripts/setupubuntu.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/setupubuntu.sh 2> /dev/null
wget -O /etc/tab/scripts/healing.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/Healing.sh 2> /dev/null
wget -O /bin/bouncelt.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/BounceLT.sh 2> /dev/null
wget -O /bin/bouncesc.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/BounceSC.sh 2> /dev/null
wget -O /bin/nightlyactions.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/NightlyActions.sh 2> /dev/null
wget -O /etc/tab/scripts/checkiscsi.sh https://raw.githubusercontent.com/JustinTDCT/TAB-Production/refs/heads/main/CheckiSCSI.sh 2> /dev/null
# make the files executable (8 files)
chmod +xX /bin/bouncelt.sh
chmod +xX /bin/bouncesc.sh
chmod +xX /bin/nightlyactions.sh
chmod +xX /etc/tab/scripts/checkiscsi.sh
chmod +xX /etc/tab/scripts/setupubuntu.sh
chmod +xX /etc/tab/scripts/healing.sh
# update cron
echo "Updating cron ..." >> /etc/tab/log/nightlyactions.log
sed '22,$ d' /etc/crontab > /tab_temp/crontab2
mv /tab_temp/crontab2 /etc/crontab
echo "30 20 * * * root /bin/nightlyactions.sh" >> /etc/crontab
echo "10 * * * * root /etc/tab/scripts/checkiscsi.sh" >> /etc/crontab
# kill LT
echo "Restart LT (Check, kill, re-check) ..." >> /etc/tab/log/nightlyactions.log
service ltechagent status >> /etc/tab/log/nightlyactions.log
pkill -9 ltechagent
service ltechagent status >> /etc/tab/log/nightlyactions.log
# restart LT
/etc/init.d/ltechagent start
service ltechagent start
service ltechagent status >> /etc/tab/log/nightlyactions.log
# get IP of server
ip=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
# make motd
echo "Updating /etc/motd ..."
echo "TAB Computer Systems Ubunu Server - Scripted v1.00.22 - $(date)" > /etc/motd
echo "====================================" >> /etc/motd
echo "- restart LabTech: sudo bouncelt.sh" >> /etc/motd
echo "- restart Screen Connect: sudo bouncesc.sh" >> /etc/motd
echo "- restart the server: sudo shutdown -r now" >> /etc/motd
echo "- access WebMin console: https://$ip:10000" >> /etc/motd
echo "- reset tabadmin password: passwd" >> /etc/motd
echo "-------------- VEEAM XFS SERVERS --------------" >> /etc/motd
echo "- expand LUN (assuming you expanded on NAS and rebooted VM): sudo xfs_growfs /dev/sdb" >> /etc/motd
echo "- check LUN space: df -H | grep /dev/sdb" >> /etc/motd
echo "- reset veeamuser password: sudo passwd veeamuser" >> /etc/motd
echo "- manually trim filesystem: sudo fstrim /mnt/veeamrepo" >> /etc/motd
echo "- fix LUN filesystem errors: sudo umount /dev/sdb; sudo xfs_repair /dev/sdb; sudo mount -a" >> /etc/motd
echo "." >> /etc/motd
echo "You can also run /etc/tab/scripts/healing.sh to perform self healing and LUN expansion" >> /etc/motd
echo "." >> /etc/motd
# update the OS
echo "Update OS ..." >> /etc/tab/log/nightlyactions.log
apt update
apt upgrade -y
apt autoremove -y
# check for reboot pending by file
echo "=============================================================" >> /etc/tab/log/nightlyactions.log
echo "Rebooting if needed ..." >> /etc/tab/log/nightlyactions.log
if [ -e /var/run/reboot-required ]; then 
  echo "- Reboot required!" >> /etc/tab/log/nightlyactions.log
  shutdown -r now
fi
