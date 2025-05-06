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

