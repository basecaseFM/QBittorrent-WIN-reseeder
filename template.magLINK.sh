#!/bin/sh
torrent_name=NULL_NAME
magnetLINK=NULL_MAG
torrent_hash=NULL_HASH

if [[ -z $1 && -z $3 && -z $4 ]] ; then
	alias transmission-remote="transmission-remote"
elif [[ -n $1 && -z $3 && -z $4 ]] ; then
	alias transmission-remote="transmission-remote --auth $1:$2"
elif [[ -z $1 && -n $3 && -z $4 ]] ; then
	alias transmission-remote="transmission-remote $3"
elif [[ -z $1 && -z $3 && -n $4 ]] ; then
	alias transmission-remote="transmission-remote $4"
elif [[ -z $1 && -n $3 && -n $4 ]] ; then
	alias transmission-remote="transmission-remote $3:$4"	
elif [[ -n $1 && -n $3 && -z $4 ]] ; then
	alias transmission-remote="transmission-remote $3 --auth $1:$2"
elif [[ -n $1 && -z $3 && -n $4 ]] ; then
	alias transmission-remote="transmission-remote $4 --auth $1:$2"
elif [[ -n $1 && -n $3 && -n $4 ]] ; then
	alias transmission-remote="transmission-remote $3:$4 --auth $1:$2"
fi	
 
currentDIR="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
foundSTRING="$(transmission-remote -t $torrent_hash -ip)"
declare -a torrentFiles
for file in "$currentDIR"\/*.torrent
do
    torrentFiles=("${torrentFiles[@]}" "$file")
done

if [ -z "$foundSTRING" ]
then
    for torrent in "${torrentFiles[@]}"
    do
        transmission-remote -a "$torrent" -w "$currentDIR" || transmission-remote -a "$magnetLINK" -w "$currentDIR"
        transmission-remote -t $torrent_hash -v
    done
   echo "Torrent is NOT already loaded in Transmission"

else
   transmission-remote -t $torrent_hash --find "$currentDIR"
   transmission-remote -t $torrent_hash -s
   echo "Torrent already in list, moving to current location."
fi
