#!/bin/sh

# Forked from: https://gist.github.com/timnew/2373475

export LC_ALL="C"

declare ComputerName=$( ipconfig -all 2>&1 | awk -F: '/IPv4/ { print $2 }' | head -n 1 | grep -oP "\d+\.\d+\.\d+\.\d+" | awk -F. '{ printf "PC-%s-%s", $3, $4 }' )

if [ -n "${ComputerName}" ]; then
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Computername\Computername"       -v "Computername"          -t REG_SZ -d "${ComputerName}" -f
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Computername\ActiveComputername" -v "Computername"          -t REG_SZ -d "${ComputerName}" -f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"               -v "Hostname"              -t REG_SZ -d "${ComputerName}" -f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"               -v "NV Hostname"           -t REG_SZ -d "${ComputerName}" -f
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"            -v "AltDefaultDomainName"  -t REG_SZ -d "${ComputerName}" -f
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"            -v "DefaultDomainName"     -t REG_SZ -d "${ComputerName}" -f
fi

#Set-ItemProperty -path "HKU:\.Default\Software\Microsoft\Windows Media\WMSDK\General" -name "Computername" -value $ComputerName