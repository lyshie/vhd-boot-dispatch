SCHTASKS /CREATE /SC DAILY /TN "五分鐘後自動關機" /TR "shutdown -s -t 300" /ST 18:00

