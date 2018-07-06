timeout 5
default 0

title Windows 10 (Native VHD Boot)
find --set-root --ignore-floppies --ignore-cd /sig_intel_ssd
dd if=()/disk_r.vhd of=()/disk.vhd
find --set-root --ignore-floppies --ignore-cd /sig_intel_ssd
chainloader /bootmgr
