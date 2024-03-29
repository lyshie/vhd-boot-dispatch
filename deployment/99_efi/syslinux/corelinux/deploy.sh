#!/bin/sh

# Tiny Core Linux automation script

# install essential packages
#su tc -c "tce-load -i /cde/optional/Xlibs.tcz"
#for z in $(cat /cde/onboot.lst); do             
#    su tc -c "tce-load -i /cde/optional/${z}"
#done                    

ln -s /lib /lib64

su tc -c "tce-load -wi util-linux"
su tc -c "tce-load -wi parted"
#su tc -c "tce-load -wi grub4dos"
#su tc -c "tce-load -wi transmission"

# ntfs-3g mount and tune
mkdir /mnt/sda1
## drive C:\
ntfs-3g -o noatime,async,big_writes /dev/sda1 /mnt/sda1
## drive D:\
mkdir /mnt/sda2
ntfs-3g -o noatime,async,big_writes /dev/sda2 /mnt/sda2

# D700
mount /dev/nvme0n1p1 /mnt/nvme0n1p1
ntfsfix /dev/nvme0n1p3
ntfs-3g -o noatime,async,big_writes,remove_hiberfile /dev/nvme0n1p3 /mnt/nvme0n1p3

# 還原 D700
restore=$(cat /proc/cmdline | egrep -o "restore=\S+" | awk -F= '{print $2}')
if [[ "$restore" == "true" ]]; then
    cp -f "/mnt/nvme0n1p3/pcroom_r.vhdx" "/mnt/nvme0n1p3/pcroom.vhdx"
    sync
    reboot
fi

# p2p & transmission-cli
mkdir /mnt/sda2/p2p
sysctl -w net.core.rmem_max=4194304
sysctl -w net.core.wmem_max=1048576

#su tc -c "tftp -r pcroom/disk.torrent -l /mnt/sda2/p2p/disk.torrent -g 163.26.68.15"
#su tc -c "mkdir -p ~/.config/transmission"
#su tc -c "tftp -r pcroom/settings.json -l ~/.config/transmission/settings.json -g 163.26.68.15"
##su tc -c "transmission-cli -D -U -w /mnt/sda2/p2p/ /mnt/sda2/p2p/disk.torrent"

# install grub4dos
# /usr/local/share/grub4dos/bootlace.com /dev/sda
# cp /usr/local/share/grub4dos/chinese/grldr /mnt/sda2/
