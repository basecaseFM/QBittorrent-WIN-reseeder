1. Encrypt and store your qBittorrent password:
#   - Convert your password to a secure string and export it:
#       `$securePassword = ConvertTo-SecureString "YourPassword" -AsPlainText -Force`
#       `$securePassword | ConvertFrom-SecureString | Out-File "$env:LOCALAPPDATA\qBittorrentPassword.txt"`


Qbittorrent Competion Script
powershell -ExecutionPolicy Bypass -NoExit -File "C:\Program Files\qBittorrent\processForSeedingOnLinux.ps1" "%N" "%I" "%D" "%R" "%F"
place script and templates in qbittorent install location.
