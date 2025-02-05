$Userpath = Read-Host "Enter Path to seasrch for QBT magnetlink files: "

$magnetlink_list = (Get-ChildItem -Path "$Userpath" -Filter *magnetLINK.ps1 -Recurse).FullName
$magnetlink_list

foreach ($torrent in $magnetlink_list) {
    powershell.exe $magnetlink_list
}

$quit_prompt = Read-Host "Do you want to search a different path: Enter path or hit ENTER to quit "
 
$quit_prompt
