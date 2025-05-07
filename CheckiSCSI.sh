#!/bin/bash  
if [[ "$HOSTNAME" == *"veeam"* ]]; then
  echo "Veeam server moving ahead."
else
  exit
fi
if [ -d /mnt/veeamrepo/backups/ ]; then
  echo "iSCSI OK"
  if [ -f /etc/tab/scripts/iscsi.fail ]; then
    echo "Removing old fail file..."
    echo "$(date)" >> /etc/tab/logs/checkiscsi.log
    echo "- iSCSI reconnected" >> /etc/tab/logs/checkiscsi.log
    rm -f /etc/tab/scripts/iscsi.fail
  fi
else
  if [ -f /etc/tab/scripts/iscsi.fail ]; then
    echo "2nd fail, rebooting..."
    echo "Removing old fail file..."
    rm -f /etc/tab/scripts/iscsi.fail
    echo "$(date)" >> /etc/tab/logs/checkiscsi.log
    echo "- 2nd fail, rebooting" >> /etc/tab/logs/checkiscsi.log
    shutdown -r now
  else  
    echo "iSCSI fail - dropping file..."
    touch /etc/tab/scripts/iscsi.fail
    echo "$(date)" >> /etc/tab/logs/checkiscsi.log
    echo "- 1st fail, dropping file" >> /etc/tab/logs/checkiscsi.log
  fi
fi
