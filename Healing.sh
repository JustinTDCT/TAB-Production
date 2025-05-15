
heal_iscsi_files () {
             umount $mountpoint2 &>> /etc/tab/logs/xfs_repair.log
             if [ $? != 0 ] ; then
               echo "- Dismount did not work, skipping the health test, see /etc/tab/logs/xfs_repair.log for details" >> /etc/tab/logs/checkiscsi.log
             else
               echo "- running xfs_repair on $devnm" >> /etc/tab/logs/xfs_repair.log
               xfs_repair $devnm &>> /etc/tab/logs/xfs_repair.log
               if [ $? != 0 ] ; then
                 echo "- repair was not able to run, skipping, see /etc/tab/logs/xfs_repair.log for details" >> /etc/tab/logs/checkiscsi.log
               else
                 echo "- remounting file system" >> /etc/tab/logs/xfs_repair.log
                 mount -a &>> /etc/tab/logs/xfs_repair.log
                if [ $? != 0 ] ; then
                  echo "- remounting failed! see /etc/tab/logs/xfs_repair.log for details" >> /etc/tab/logs/checkiscsi.log
                else
                  echo "- Repair done, see /etc/tab/logs/xfs_repair.log for details" >> /etc/tab/logs/checkiscsi.log

}
