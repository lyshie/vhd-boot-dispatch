# msys2-windows-utils
Windows utilities under MSYS2

## 說明
使用 GNU/Linux 環境同時派送 Windows VHD 至多台個人電腦，以 Native VHD Boot 方式開機。
- Server 端以 WOL (Wake-on-LAN) 方式啟動多台個人電腦
- dhcpd 派送網路設定與 next-server 資訊
- in.tfptd 派送 pxelinux.0、pxelinux.cfg/default 與 Tiny Core Linux 作業系統
- 修改 Tiny Core Linux 套件，增加 ntfs-3g、ntfsprogs、openssh、rsync、udpcast 與 uftp 等程式
- 修改 Tiny Core Linux 帳號密碼，如 /etc/passwd、/etc/shadow，並啟動 sshd server
- 於 server 端使用 PSSH 控制遠端的個人電腦
  * 掛載 NTFS 分割區
  * 以 UDP Multicast 或 BitTorrent 方式接收 VHD 檔案、grub4dos、BOOTMGR
  * 安裝 grub4dos 至 MBR 或使用既有的開機程式
  * 重新開機
- 於 Windows 中安裝 MSYS2，以 cygrunsrv 方式啟動 sshd server
- Windows 開機後自動依 IP 設定電腦名稱
   
## Boot
- bootmgr
- BOOTNXT
- Boot\
- grub4dos\

## VHD
```
$ modprobe loop
$ losetup /dev/loop0 disk.vhd
$ partprobe /dev/loop0
$ mount /dev/loop0p1 /mnt/images

$ losetup -d /dev/loop0
```

```
$ VBoxManage clonehd dynamicd_disk.vhd fixed_disk.vhd --format vhd --variant dynamic
```

## PSSH
```
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -h [主機清單] -O "StrictHostKeyChecking no" -- "[指令]"
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -H user@host_or_ip -O "StrictHostKeyChecking no" -- "[指令]"
```

```
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -h [主機清單] -O "StrictHostKeyChecking no" -- "sudo ntfs-3g /dev/sda2 /mnt/sda2"
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -h [主機清單] -O "StrictHostKeyChecking no" -- "tar xvfz /mnt/sda2/vhd.tgz -C /mnt/sda2"
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -h [主機清單] -O "StrictHostKeyChecking no" -- "sudo reboot"
```

```
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -h [主機清單] -O "StrictHostKeyChecking no" -- "shutdown -s -t 30"
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -h [主機清單] -O "StrictHostKeyChecking no" -- "shutdown -r -t 30"
```

## External Reference
- [Grub4dos Guide](http://diddy.boot-land.net/grub4dos/Grub4dos.htm)
- [Tiny Core Linux](http://distro.ibiblio.org/tinycorelinux/)
  * ntfs-3g
  * ntfsprogs
  * rsync
  * grub4dos
  
  ```
  $ tce-load -wi ntfs-3g
  ```
  
- [Tiny Core Linux Customizations for Remastering](http://www.canbike.org/off-topic/aggregate/tiny-core-linux-customizations-for-remastering.html)

  ```
  $ zcat core.gz | sudo cpio -i -H newc -d
  $ sudo find | sudo cpio -o -H newc | gzip -2 > core.gz
  ```
- [Transmission](https://transmissionbt.com/)

  ```
  $ vi settings.json
  "dht-enabled": true
  "lpd-enabled": true
  ```

  ```
  $ transmission-create -o disk.torrent -c "Win7 VHD Boot" disk.vhd
  $ tftp -r pcroom/disk.torrent -l /mnt/sda2/p2p/disk.torrent -g [伺服器位址]
  $ transmission-cli -v -w /mnt/sda2/p2p/ /mnt/sda2/p2p/disk.torrent
  ```

- [Udpcast](https://www.udpcast.linux.lu/) / [uftp](http://uftp-multicast.sourceforge.net/) / [mrsync](https://sourceforge.net/projects/mrsync/)

  ```
  $ udp-sender --full-duplex -f source.vhd
  $ udp-receiver -f saved.vhd
  ```
  
  ```
  $ mkdir /mnt/sda2/t                       # Temp
  $ uftpd -D /mnt/sda2/ -T /mnt/sda2/t/     # Dest, Temp (Client)
  $ uftp -R -1 /srv/pcroom/pieces/          # Source directory (Server)
  
  $ split -b 1G /src/pcroom/disk.vhd /src/pcroom/pieces  # Split, unknown file size limit (2147483647)
  $ cat * > disk.vhd                                     # Join
  ```
  * [How can I get gcc to write a file larger than 2.0 GB?](https://askubuntu.com/questions/21474/how-can-i-get-gcc-to-write-a-file-larger-than-2-0-gb)
  
  ```
  $ tce-load -wi compiletc
  $ cd uftp-4.9.3/
  $ vim makefile                            # Add -D_GNU_SOURCE (-D_FILE_OFFSET_BITS=64)
  ifeq ("Linux", "$(UNAME_S)")
  ...
  ...
  bad-function-cast -DHAS_GETIFADDRS -D_GNU_SOURCE $(ENC_OPTS) 
  
  $ make NO_ENCRYPTION=1
  ```

- [Parallel SSH](https://pypi.python.org/pypi/pssh)
- [MSYS2](http://www.msys2.org/)
- [ConEmu](https://conemu.github.io/)
- [Booting Windows to a Differencing Virtual Hard Disk](https://blogs.msdn.microsoft.com/heaths/2009/10/13/booting-windows-to-a-differencing-virtual-hard-disk/)
- [Native VHD Boot on unsupported versions of Windows 7](http://agnipulse.com/2016/12/native-vhd-boot-unsupported-versions-windows-7/)
- [WakeMeOnLan](http://www.nirsoft.net/utils/wake_on_lan.html)
  * [HowTo: Wake Up Computers Using Linux Command [ Wake-on-LAN ( WOL ) ]](https://www.cyberciti.biz/tips/linux-send-wake-on-lan-wol-magic-packets.html)
  
  ```
  $ ethtool -s net0 wol g
  ```
  
- [UEFI support for PXE booting](http://projects.theforeman.org/projects/foreman/wiki/PXE_Booting_UEFI/8)
- [PXELINUX](http://www.syslinux.org/wiki/index.php?title=PXELINUX)

  ```
  LABEL tiny-core-linux
  TITLE Tiny Core Linux
  LINUX /corelinux/vmlinuz
  INITRD /corelinux/core.gz,/corelinux/tce.gz,/corelinux/cde.gz
  APPEND loglevel=3,next-server=163.26.68.15
  ```

- [chntpw](https://en.wikipedia.org/wiki/Chntpw)
  * [Reset Windows 7 Admin Password with Ubuntu Live CD/USB](http://www.chntpw.com/reset-windows-7-admin-password-with-ubuntu/)
  * [How to Hack a Windows 7/8/2008/10 Admin Account Password with Windows Magnifier](https://cx2h.wordpress.com/2015/04/02/how-to-hack-a-windows-782008-admin-account-password-with-windows-magnifier/)
- [憶傑科技 - VHD 無硬碟系統](https://sites.google.com/a/vhdsoft.com/web/)
- [[網路工具] 如何使用透過網路(LAN)喚醒功能(Wake on LAN)](https://www.asus.com/tw/support/FAQ/1009775)
- [ATA over Ethernet](https://en.wikipedia.org/wiki/ATA_over_Ethernet)
  * [WinAoE - AoE Windows Driver](https://winaoe.org/)
- [Visual BCD Editor](https://www.boyans.net/)
- [ProductPolicy viewer](http://reboot.pro/topic/20585-productpolicy-viewer/?p=196418)
- [PsTools](https://docs.microsoft.com/en-us/sysinternals/downloads/pstools) / 遠端執行桌面程式

  ```
  $ ./PsExec -accepteula
  $ ./PsExec -i 1 -s notepad.exe
  ```

## About
HSIEH, Li-Yi @進學國小資訊組
