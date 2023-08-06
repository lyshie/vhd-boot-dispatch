$hostname = "pc-"
$ipv4 = Get-NetIPAddress -AddressFamily IPv4  | Select-Object IPAddress

$ipv4 | foreach {
    if ($_.IPAddress -match "^163\.26\.") {
        $tokens = $_.IPAddress.split(".")
        $hostname += $tokens[2] + "-" + $tokens[3]
        Write-Host $hostname
        Rename-Computer -NewName $hostname -Force
    }
}
