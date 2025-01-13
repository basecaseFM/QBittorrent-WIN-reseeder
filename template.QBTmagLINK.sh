#!/bin/sh
name=NULL_NAME
magnetLINK=NULL_MAGNETLINK
TORRENT_HASH=NULL_HASH

QBT_HOST="$1"
QBT_PORT="$2"
QBT_USERNAME="$3"
QBT_PASSWORD="$4" 
currentDIR="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"

cookie_hash=$((curl -i --header "Referer: http://$QBT_HOST:$QBT_PORT" --data-urlencode "username=$QBT_USERNAME" --data-urlencode "password=$QBT_PASSWORD" http://$QBT_HOST:$QBT_PORT/api/v2/auth/login | grep "set-cookie:" | cut -d';' -f1 | cut -d':' -f2) 2>&1)  
cookie_hash=${cookie_hash##* }
	
foundSTRING="$(curl http://$QBT_HOST:$QBT_PORT/api/v2/torrents/info?hashes=$TORRENT_HASH --cookie "$cookie_hash")"
declare -a torrentFiles
for file in "$currentDIR"\/*.torrent
do
    torrentFiles=("${torrentFiles[@]}" "$file")
done

if [ "$foundSTRING" != "[]" ]
then
	curl -X POST --data "cookie='$cookie_hash'" --data "hashes=$TORRENT_HASH" --data-urlencode "location=$currentDIR" http://$QBT_HOST:$QBT_PORT/api/v2/torrents/setLocation
	curl http://$QBT_HOST:$QBT_PORT/api/v2/torrents/recheck?hashes=$TORRENT_HASH --cookie "$cookie_hash"
	curl http://$QBT_HOST:$QBT_PORT/api/v2/torrents/resume?hashes=$TORRENT_HASH --cookie "$cookie_hash"
	echo $name" already in list, moving to current location."
elif ls "$currentDIR"\/*.torrent 1> /dev/null 2>&1;
then	
	for torrent in "${torrentFiles[@]}"
	do
	curl -X POST --form "cookie='$cookie_hash'" --form "savepath=$currentDIR"  --form paused=false --form root_folder=true --form "torrents=@$torrent" http://$QBT_HOST:$QBT_PORT/api/v2/torrents/add   
	curl http://$QBT_HOST:$QBT_PORT/api/v2/torrents/recheck?hashes=$TORRENT_HASH --cookie "$cookie_hash"
	curl http://$QBT_HOST:$QBT_PORT/api/v2/torrents/resume?hashes=$TORRENT_HASH --cookie "$cookie_hash"   
	done
    echo $name" is NOT already loaded in qBittorrent"
else 
	curl -X POST --data-urlencode "cookie='$cookie_hash'" --data-urlencode "savepath=$currentDIR"  --data paused=false --data root_folder=true --data-urlencode "urls=$magnetLINK" http://$QBT_HOST:$QBT_PORT/api/v2/torrents/add
	curl http://$QBT_HOST:$QBT_PORT/api/v2/torrents/recheck?hashes=$TORRENT_HASH --cookie "$cookie_hash"
	curl http://$QBT_HOST:$QBT_PORT/api/v2/torrents/resume?hashes=$TORRENT_HASH --cookie "$cookie_hash"  
fi
