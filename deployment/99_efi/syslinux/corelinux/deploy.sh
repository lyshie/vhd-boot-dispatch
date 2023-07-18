#!/bin/sh

# Tiny Core Linux automation script

# install essential packages
#su tc -c "tce-load -i /cde/optional/Xlibs.tcz"
#for z in $(cat /cde/onboot.lst); do             
#    su tc -c "tce-load -i /cde/optional/${z}"
#done                    

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
