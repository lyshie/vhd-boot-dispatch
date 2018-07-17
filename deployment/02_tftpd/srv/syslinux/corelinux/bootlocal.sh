#!/bin/sh
# put other system startup commands here

sleep 10

su tc -c "tce-load -i /opt/tce/optional/openssh.tcz"
su tc -c "tce-load -i /opt/tce/optional/rsync"
su tc -c "tce-load -i /opt/tce/optional/ntfs-3g"
su tc -c "tce-load -i /opt/tce/optional/ntfsprogs"
/usr/local/etc/init.d/openssh start

next_server=$(cat /proc/cmdline | egrep -o "next-server=\S+" | awk -F= '{print $2}')
tftp -r deploy.sh -l /opt/deploy.sh -g ${next_server}
chmod a+x /opt/deploy.sh
/opt/deploy.sh
