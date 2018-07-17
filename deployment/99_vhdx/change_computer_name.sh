#!/bin/sh

# Forked from: https://gist.github.com/timnew/2373475

declare ComputerName=$( ipconfig -all 2>&1 | awk -F: '/IPv4/ { print $2 }' | grep -oP "\d+\.\d+\.\d+\.\d+" | awk -F. '{ printf "PC-%s-%s", $3, $4 }' )

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Computername\Computername"       -v "Computername"          -t REG_SZ -d "${ComputerName}" -f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Computername\ActiveComputername" -v "Computername"          -t REG_SZ -d "${ComputerName}" -f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"               -v "Hostname"              -t REG_SZ -d "${ComputerName}" -f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"               -v "NV Hostname"           -t REG_SZ -d "${ComputerName}" -f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"            -v "AltDefaultDomainName"  -t REG_SZ -d "${ComputerName}" -f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"            -v "DefaultDomainName"     -t REG_SZ -d "${ComputerName}" -f

#Set-ItemProperty -path "HKU:\.Default\Software\Microsoft\Windows Media\WMSDK\General" -name "Computername" -value $ComputerName
