$QBT_TORRENT_NAME=NULL_NAME
$QBT_INFOHASH=NULL_HASH

# Define qBittorrent API credentials and URL
$qBittorrentURL = "http://localhost:8080"
$qBittorrentUser = "admin"

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

# Set current directory
$currentDIR = $PSScriptRoot

# Check if torrent is already in client
$foundSTRING = Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/torrents/info" -Method Post -WebSession $session -Body @{
    "hashes" = $QBT_INFOHASH
}
# Add torrents to array object
$torrentFiles = (Get-ChildItem -Filter *.torrent).FullName

# Main loop for adding torrent or changing location
if ( $foundSTRING -ne "") {
    Write-Host "$QBT_TORRENT_NAME is already in client"
  	Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/torrents/setLocation" -Method Post  -ContentType "application/x-www-form-urlencoded" -WebSession $session -Body @{
    "hashes" = $QBT_INFOHASH
    "location" = $currentDIR
    }

# Recheck torrent
Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/torrents/recheck" -Method Post  -ContentType "application/x-www-form-urlencoded" -WebSession $session -Body @{
    "hashes" = $QBT_INFOHASH
}

# Resume torrent
Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/torrents/start" -Method Post -WebSession $session -Body @{
    "hashes" = $QBT_INFOHASH
}
}
 else {
        Write-Host "$QBT_TORRENT_NAME is NOT in client"

    foreach ($torrent in $torrentFiles) {
      
# Get just the file name (no path)
$FileName = Split-Path $torrent -leaf
	
# Get a GUID that is used to indicate the start and end of the file in the request
$boundary = "$([System.Guid]::NewGuid().ToString())"

# Read the contents of the file
$FileBytes = [System.IO.File]::ReadAllBytes($torrent)
$FileContent = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($FileBytes)

# Build a Body to submit the request
$bodyLines = @"
--$boundary
Content-Disposition: form-data; name="savepath"

$currentDir
--$boundary
Content-Disposition: form-data; name=`"`"; filename=`"$FileName`"
Content-Type: application/x-bittorrent

$FileContent
$($boundary)--
"@

# Add torrent via .torrent files
        Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/torrents/add" -Method Post -WebSession $session  -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines
                
# Recheck torrent
        Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/torrents/recheck" -Method Post  -ContentType "application/x-www-form-urlencoded" -WebSession $session -Body @{
            "hashes" = $QBT_INFOHASH
        }
# Resume torrent
        Invoke-RestMethod -Uri "$qBittorrentUrl/api/v2/torrents/start" -Method Post -WebSession $session -Body @{
            "hashes" = $QBT_INFOHASH
        }
    }
}


