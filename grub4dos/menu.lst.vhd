color blue/green yellow/red white/magenta white/magenta
## menu border color
color border=0xEEFFEE
## set vbe mode
graphicsmode -1 640:800 480:600 24:32 || graphicsmode -1 -1 -1 24:32
font /unifont.hex.gz

timeout 5
default 0

title Windows 10 (Native VHD Boot)
find --set-root --ignore-floppies --ignore-cd /sig_ntfs
chainloader /bootmgr

title reboot (重新開機)
reboot

title halt (關機)
halt