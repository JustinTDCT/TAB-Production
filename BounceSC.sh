#!/bin/bash
# READY FOR TESTING IN PRODUCTION
echo "Stopping service ..."
service connectwisecontrol-24a22b9fc261d141 stop 2> /dev/null
service connectwisecontrol-24a22b9fc261d141 status
echo "Starting service ..."
service connectwisecontrol-24a22b9fc261d141 start 2> /dev/null
service connectwisecontrol-24a22b9fc261d141 status
