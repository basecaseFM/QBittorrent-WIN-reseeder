# Set variables to args provided from Qbittorrent client
param(
  [string]$QBT_TORRENT_NAME,
  [string]$QBT_INFOHASH,
  [string]$QBT_SAVE_PATH,
  [string]$QBT_ROOT_PATH,
  [string]$QBT_CONTENT_PATH
)

# Define qBittorrent API credentials and URL
$qBittorrentURL = "http://localhost:8080"
$qBittorrentUser = "admin"

# Set location for stored torrents
$TORRENT_STORE = "S:\Torrents"

##Save Old directory and Create Placeholder for New directory
  $OLD_DIR = "$QBT_SAVE_PATH"
  $NEW_DIR = "$QBT_SAVE_PATH\$QBT_TORRENT_NAME-DIR\"

##Check if Current Directory has been Modified by Script
if ($OLD_DIR.EndsWith("-DIR")){
	" Directory already processed"
	$NEW_DIR = $OLD_DIR
} else {
 	"Proceeed, not processed yet"

    ## Create New Directory
       	mkdir "$NEW_DIR"
	
    ## Move File/Folder from Old Directory to New Directory
  		 Move-Item -Path "$QBT_CONTENT_PATH" -Destination "$NEW_DIR"
}
#  Copy torrent from designated .torrent storage directory to download directory
#  ** If unknown, the option must be selected in the qbittorrent/PREFERENCES/Copy .torrent files to:  [PATH to .torrents]
#	or 	qbittorrent/PREFERENCES/Copy .torrent files for completed torrents to:  [PATH to .torrents]
Copy-Item $TORRENT_STORE\"$QBT_TORRENT_NAME"*.torrent "$NEW_DIR.$QBT_TORRENT_NAME.torrent"

# Create torrent-name.QBTmagnetLINK from the template file 
#       QBittorrent-reseeder Linux file
$content = [System.IO.File]::ReadAllText(".\template.QBTmagLINK.sh").Replace("NULL_NAME","""$QBT_TORRENT_NAME""").Replace("NULL_HASH","$QBT_INFOHASH")
[System.IO.File]::WriteAllText("$NEW_DIR.$QBT_TORRENT_NAME.QBTmagnetLINK", $content)

# Create torrent-name.magnetLINK from the template file 
#       TRANSMISSION-reseeder linux file
$TRANSMISSION = [System.IO.File]::ReadAllText(".\template.magLINK.sh").Replace("NULL_NAME","""$QBT_TORRENT_NAME""").Replace("NULL_HASH","$QBT_INFOHASH")
[System.IO.File]::WriteAllText("$NEW_DIR.$QBT_TORRENT_NAME.magnetLINK", $TRANSMISSION)

# Create torrent-name.QBTmagnetLINKwindows from the template file 
#       QBittorrentWin-reseeder Windows file
$QBT_WIN = [System.IO.File]::ReadAllText(".\qbtMagnetlinktemplate.ps1").Replace("NULL_NAME","""$QBT_TORRENT_NAME""").Replace("NULL_HASH","$QBT_INFOHASH")
[System.IO.File]::WriteAllText("$NEW_DIR.$QBT_TORRENT_NAME.QBTmagnetLINK.ps1", $QBT_WIN)


# Get secure-password that was saved on disk
function Get-SecurePassword {
    # Path to the encrypted password file
    $passwordFilePath = "$env:LOCALAPPDATA\qBittorrentPassword.txt"

    # Check if the password file exists
    if (Test-Path $passwordFilePath) {
        # Read the encrypted password and convert it to a SecureString
        $encryptedPassword = Get-Content -Path $passwordFilePath
        $securePassword = $encryptedPassword | ConvertTo-SecureString
        return $securePassword
    }
    else {
        Write-Error "Password file not found at $passwordFilePath"
        return $null
    }
}
$qBittorrentPassword = Get-SecurePassword

function Get-qBittorrentSession {
    param (
        [String]$qBittorrentUrl,
        [String]$username,
        [SecureString]$password
    )

    $passwordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    )

    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    try {
        Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/auth/login" -Method Post -WebSession $session -Body @{
            username = $username
            password = $passwordPlain
        } | Out-Null
        return $session
    }
    catch {
        Write-Error "Failed to authenticate to qBittorrent. Please check your credentials and URL."
        return $null
    }
}
$session = Get-qBittorrentSession -qBittorrentUrl $qBittorrentUrl -username $qBittorrentUser -password $qBittorrentPassword
if (-not $session) { return }

## Change torrent Location
Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/torrents/setLocation" -Method Post  -ContentType "application/x-www-form-urlencoded" -WebSession $session -Body @{
        "hashes" = $QBT_INFOHASH
        "location" = $NEW_DIR
    }

# Recheck torrent
Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/torrents/recheck" -Method Post  -ContentType "application/x-www-form-urlencoded" -WebSession $session -Body @{
    "hashes" = $QBT_INFOHASH
}
# Resume torrent
Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/torrents/start" -Method Post -WebSession $session -Body @{
    "hashes" = $QBT_INFOHASH
}

# Debug line if needed 
# Read-Host -Prompt "Press Enter to exit"