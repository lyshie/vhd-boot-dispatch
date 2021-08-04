# vhd-boot-dispatch
Windows Native VHD Boot and Dispatch

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

## [Transfer time](https://techinternets.com/copy_calc)
- 40 GiB

|設備|速度|估計傳輸時間|
|---|---|---|
|Fast Ethernet|100 mbps|1:00:04|
|Gigabit Ethernet|1000 mbps|0:06:00|
|USB 2.0|480 mbps|0:12:30|
|USB 3.0|3.2 gbps|0:01:50|
|SATA-I|1.5 gbps|0:03:54|
|SATA-II|3 gbps|0:01:57|

## Disk layouts
|檔案名稱|用途|類型|狀態|大小|
|---|---|---|---|---|
|pcroom_base.vhdx|母碟|基礎磁碟|靜態|約 30 GB|
|pcroom.vhdx|子碟|差異化磁碟|動態|隨差異增加|
|pcroom_r.vhdx|還原檔|差異化磁碟|靜態|約 173 KB|

## 開機選項
```
base.vhdx => pcroom_base.vhdx => pcroom.vhdx (pcroom_r.vhdx)
          => office_base.vhdx => office.vhdx (office_r.vhdx)
```
|名稱|標題|BCD|VHD|
|---|---|---|---|
|pcroom_r|電腦教室還原|BCD.pcroom_vhdx|pcroom_r.vhdx > pcroom.vhdx|
|pcroom|電腦教室|BCD.pcroom_vhdx|pcroom.vhdx|
|office_r|辦公室還原|BCD.office_vhdx|office_r.vhdx > office.vhdx|
|office|辦公室|BCD.office_vhdx|office.vhdx|

## VHD 建立順序
```
base.vhdx(0) => test.vhdx(1)   == pcroom_base.vhdx(1) => pcroom.vhdx(2)
                test_r.vhdx(1)                           pcroom_r.vhdx(2)
                               == office_base.vhdx(1) => office.vhdx(2)
                                                         office_r.vhdx(2)
```

## 如何準備 VHD 檔案
- 透過 VirtualBox 安裝新系統
- [取消 `VirtualDiskExpandOnMount`](https://superuser.com/questions/1149941/how-to-by-pass-vhd-boot-host-volume-not-enough-space-when-native-booting)
  ```
  HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\FsDepends\Parameters
  VirtualDiskExpandOnMount = 4
  ```
- [SDelete 清理磁碟](https://docs.microsoft.com/en-us/sysinternals/downloads/sdelete)
```
> sdelete64 -c -z C:
```
- 緊湊 VHD 磁碟空間
  * [Windows](https://social.technet.microsoft.com/wiki/contents/articles/8043.how-to-compact-a-dynamic-vhd-with-diskpart.aspx)
  ```
  diskpart
  > select vdisk file="f:\base.vhdx"
  > compact vdisk
  ```
  * [Linux](https://serverfault.com/questions/888986/compact-a-vhd-on-a-linux-host)
  ```
  $ vboxmanage clonemedium INPUT.VHD OUTPUT.VHD --format VHD --variant Standard
  ```
- [建立差異化磁碟 (Differencing Disks)](https://blogs.msdn.microsoft.com/7/2009/10/07/diskpart-exe-and-managing-virtual-hard-disks-vhds-in-windows-7/)
```
diskpart
> create vdisk file="f:\pcroom_base.vhdx" parent="f:\base.vhdx"
```
- [合併差異化磁碟](https://blogs.msdn.microsoft.com/7/2009/10/07/diskpart-exe-and-managing-virtual-hard-disks-vhds-in-windows-7/)
```
diskpart
> select vdisk file="f:\pcroom_base.vhdx"
> merge vdisk depth=1
> compact vdisk
> create vdisk file="f:\pcroom.vhdx" parent="f:\pcroom_base.vhdx"
```

## [UTC in Windows](https://wiki.archlinux.org/index.php/time#UTC_in_Windows)
```
> reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /d 1 /t REG_DWORD /f
```

## 開機流程
- grub2 (無 grub2 可略過)
```
menuentry 'GRUB4DOS (NTFS)' --class windows {
    savedefault
    insmod part_msdos
    insmod ntfs
    insmod ntldr
    search --set=root --no-floppy --file /sig_ntfs    # 特徵檔案，識別磁碟區位置
    ntldr /grldr                                      # 控制權交給 grub4dos
}
```
- grub4dos
```
timeout 5
default 0

title Windows 10 (Native VHD Boot)

find --set-root --ignore-floppies --ignore-cd /sig_ntfs
dd if=()/Boot/BCD.pcroom_vhdx of=()/Boot/BCD               # 設定 pcroom.vhdx 為開機裝置 (可切換不同用途的 VHD 檔案)

find --set-root --ignore-floppies --ignore-cd /sig_ntfs    # 還原 pcroom_r.vhdx 至 pcroom.vhdx
dd if=()/pcroom_r.vhdx of=()/pcroom.vhdx

find --set-root --ignore-floppies --ignore-cd /sig_ntfs
chainloader /bootmgr                                       # 控制權交給 bootmgr (Boot\BCD)
```

## Boot
- 1st stage files
  - grldr (開機程式)
  - menu.lst (開機選單)
  - unifont.hex.gz (中文字形)
  - sig_* (選用，特徵檔案，識別磁碟區位置)
- 2nd stage files
  - bootmgr
  - BOOTNXT
  - Boot
  - Boot\BCD (紀錄作業系統開機的裝置)
  - Boot\BCD.*
- disk files
  - base.vhdx (基礎檔)
  - pcroom.vhdx (差異檔)
  - pcroom_r.vhdx (差異檔，還原用)

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
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -h [主機清單] -t 0 -O "StrictHostKeyChecking no" -- "[指令]"
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -H user@host_or_ip -t 0 -O "StrictHostKeyChecking no" -- "[指令]"
```

```
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -h [主機清單] -t 0 -O "StrictHostKeyChecking no" -- "sudo ntfs-3g /dev/sda2 /mnt/sda2"
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -h [主機清單] -t 0 -O "StrictHostKeyChecking no" -- "tar xvfz /mnt/sda2/vhd.tgz -C /mnt/sda2"
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -h [主機清單] -t 0 -O "StrictHostKeyChecking no" -- "sudo reboot"
```

```
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -h [主機清單] -t 0 -O "StrictHostKeyChecking no" -- "shutdown -s -t 30"
$ rm /root/.ssh/known_hosts; sshpass -p [密碼] pssh -i -A -h [主機清單] -t 0 -O "StrictHostKeyChecking no" -- "shutdown -r -t 30"
```

```
$ rm /root/.ssh/known_hosts; sshpass -f [密碼] pssh -i -A -h [主機清單] -t 0 -O "StrictHostKeyChecking no" -- "/opt/bin/udp-receiver --receive-timeout 10 --n okbd -f /mnt/sda2/pcroom.vhdx \&"
```

```
$ /opt/bin/udp-sender -f /mnt/sda2/pcroom.vhdx
```

## grub4dos
```
$ /usr/local/share/grub4dos/bootlace.com /dev/sda
$ cp /usr/local/share/grub4dos/{chinese/}grldr /mnt/sda2
```
中文字型顯示須符合 unifont.hex 格式，自行下載 [`GNU Unifont`](http://unifoundry.com/)，可內嵌或外部載入。[直接下載字型](http://unifoundry.com/pub/unifont-11.0.01/font-builds/unifont-11.0.01.hex.gz)。
```
color blue/green yellow/red white/magenta white/magenta
## menu border color
color border=0xEEFFEE
## set vbe mode
graphicsmode -1 640:800 480:600 24:32 || graphicsmode -1 -1 -1 24:32
font /unifont.hex.gz
```

## External Reference
- [Disable driver signature enforcement [Windows Guide]](https://windowsreport.com/driver-signature-enforcement-windows-10/)

  ```
  $ bcdedit.exe -set loadoptions DISABLE_INTEGRITY_CHECKS
  $ bcdedit.exe -set TESTSIGNING ON
  
  $ gpedit.msc
  User Configuration > Administrative Templates > System > Driver Installation > Code signing for device drivers entry [Ignore]
  ```
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
  $ udp-sender --full-duplex -f source.vhdx
  $ udp-receiver -f saved.vhdx
  $ rm /root/.ssh/known_hosts; sshpass -f passwd pssh -t 0 -i -A -h hosts_pcroom_30 -O "StrictHostKeyChecking no" -- "sudo /opt/bin/udp-receiver --nokbd -f /mnt/sda2/pcroom.vhdx \&"
  ```
  
  ```
  $ mkdir /mnt/sda2/t                       # Temp
  $ uftpd -D /mnt/sda2/ -T /mnt/sda2/t/     # Dest, Temp (Client)
  $ uftp -R -1 /srv/pcroom/pieces/          # Source directory (Server)
  
  $ split -b 1G /src/pcroom/disk.vhdx /src/pcroom/pieces  # Split, unknown file size limit (2147483647)
  $ cat * > disk.vhdx                                     # Join
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
  $ etherwake -i [介面] -b [MAC Address / 11:22:33:44:55:66]
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
- [Disk2vhd：未安裝 Hyper-V 套件時，直接以 p2v 的方式轉成 VHDX](https://docs.microsoft.com/en-us/sysinternals/downloads/disk2vhd)
- [chntpw](https://en.wikipedia.org/wiki/Chntpw)
  * [Reset Windows 7 Admin Password with Ubuntu Live CD/USB](http://www.chntpw.com/reset-windows-7-admin-password-with-ubuntu/)
  * [How to Hack a Windows 7/8/2008/10 Admin Account Password with Windows Magnifier](https://cx2h.wordpress.com/2015/04/02/how-to-hack-a-windows-782008-admin-account-password-with-windows-magnifier/)
- [憶傑科技 - VHD 無硬碟系統](https://sites.google.com/a/vhdsoft.com/web/)
- [[網路工具] 如何使用透過網路(LAN)喚醒功能(Wake on LAN)](https://www.asus.com/tw/support/FAQ/1009775)
- [ATA over Ethernet](https://en.wikipedia.org/wiki/ATA_over_Ethernet)
  * [WinAoE - AoE Windows Driver](https://winaoe.org/)
- [Visual BCD Editor](https://www.boyans.net/)
  * [編輯 BCD 紀錄，使用 VHD 開機](https://www.boyans.net/VBCD_HowTo.html)
  ```
  ApplicationDevice => LocateExDevice = \pcroom.vhdx
  OSDevice => LocateExDevice = \pcroom.vhdx
  ```
  * [Mounting the BCD Store as a Registry Hive](http://www.mistyprojects.co.uk/documents/BCDEdit/files/bcd_as_registry_hive.htm)
  * [Devices - Locate](http://www.mistyprojects.co.uk/documents/BCDEdit/files/device_locate.htm)
- [ProductPolicy viewer](http://reboot.pro/topic/20585-productpolicy-viewer/?p=196418)
- [PsTools](https://docs.microsoft.com/en-us/sysinternals/downloads/pstools) / 遠端執行桌面程式

  ```
  $ ./PsExec -accepteula
  $ ./PsExec -i 1 -s notepad.exe

  以 start 指令同步執行，類似 fork 功能
  $ start /b C:\Users\student\Desktop\PSTools\PsExec.exe \\主機1 -u 帳號 -p 密碼 -i -f -c " 指令.cmd"
  $ start /b C:\Users\student\Desktop\PSTools\PsExec.exe \\主機2 -u 帳號 -p 密碼 -i -f -c " 指令.cmd"
  ```
- [AIO Boot](https://github.com/nguyentumine/AIO-Boot)

## UEFI
- [PC: Illustrated Guide to GRUB and Linux Boot Process on BIOS and UEFI](http://iam.tj/prototype/guides/boot/)
- [The rEFInd Boot Manager](http://www.rodsbooks.com/refind/)
- [MBR2GPT.EXE](https://docs.microsoft.com/zh-tw/windows/deployment/mbr-to-gpt)
- GPT + UEFI
  ```
   GPT
  +-----------------------+
  | EFI partition / FAT32 | boot manager: bootmgfw.efi, grubx64.efi 
  +-----------------------+
  | Ext4 partition        | kernel, rootfs: Fedora Linux (/boot, /, /home)
  +-----------------------+
  | NTFS partition        | kernel: Windows 10 (winload.efi)
  +-----------------------+
  | NTFS partition        | VHD, VHDX files (winload.efi)
  +-----------------------+
  ```
- GPT + UEFI (VHDX)
  ```
   GPT
  +----------------+
  | EFI partition  | /EFI/Microsoft/Boot/bootmgfw.efi
  | FAT32          |                   ./BCD.pcroom_vhdx_efi  (pcroom.vhdx)
  |                |                   ./BCD.win10_vhd.efi    (win10.vhd)
  |                |                   ./BCD                  (目前)
  +----------------+
  | NTFS partition | /pcroom.vhdx
  |                | /win10.vhd
  +----------------+
  ```
- MBR + BIOS (VHDX)
  ```
   MBR
  +----------------+
  | NTFS partition | /bootmgr
  |                | /Boot/BCD.pcroom_vhdx
  |                | /pcroom.vhdx
  +----------------+
  ```
- GPT + UEFI/BIOS coexist
  ```
   GPT
  +---------------------+
  | EFI partition       | bootmgfw.efi
  | FAT32               | grubx64.efi
  +---------------------+
  | BIOS boot partition | core.img (Grub2)
  +---------------------+
  | Ext4                | /boot/grub2, /boot, vmlinuz, initramfs
  +---------------------+
  | Ext4 / LVM          | /, /home
  +---------------------+
  | NTFS partition      | bootmgr, grldr, pcroom.vhdx
  +---------------------+
  ```
- EFI partition (/boot/efi)
  ```
  .
  ├── EFI
  │   ├── BOOT
  │   │   ├── BOOTX64.EFI
  │   │   ├── fallback.efi
  │   │   └── fbx64.efi
  │   ├── fedora
  │   │   ├── BOOT.CSV
  │   │   ├── BOOTX64.CSV
  │   │   ├── grub.cfg
  │   │   ├── grubx64.efi
  │   │   ├── shim.efi
  │   │   ├── shimx64.efi
  │   │   ├── shimx64-fedora.efi
  │   │   └── x86_64-efi/
  │   ├── Insyde
  │   └── Microsoft
  │       ├── Boot
  │       │   ├── BCD
  │       │   ├── BCD.pcroom_vhdx_efi
  │       │   ├── BCD.win10_vhd_efi
  │       │   ├── bootmgfw.efi
  │       │   └── bootmgr.efi
  │       ├── Boot_pcroom_vhdx
  │       │   ├── BCD
  │       │   ├── bootmgfw.efi
  │       │   └── bootmgr.efi
  │       ├── Boot_win10_vhd
  │       │   ├── BCD
  │       │   ├── bootmgfw.efi
  │       │   └── bootmgr.efi
  │       └── Recovery
  │           └── BCD
  └── sig_swift
  ```
## About
HSIEH, Li-Yi @進學國小資訊組
