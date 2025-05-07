#!/bin/bash
echo "Killing service ..."
pkill -9 ltechagent 2> /dev/null
service ltechagent status
echo "Restarting service ..."
/etc/init.d/ltechagent start 2> /dev/null
service ltechagent start 2> /dev/null
service ltechagent status
