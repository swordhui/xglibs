#!/bin/sh

# file system check tool
# check what's inside a directory

#generate file list

if [ -z "$1" ]; then
	echo "No ext specified. filedo.sh jpg display"
	exit 1
fi

if [ -z "$2" ]; then
	echo "No operation specified. filedo.sh jpg display"
	exit 1
fi



echo "checking *.$1..."
find -type f -iname "*.$1"  -exec stat -c "%s, %W, %Y, %i, %n" '{}' ';' | sort -n -r  > /tmp/ck$1
echo "done"


declare -a allfiles
mapfile allfiles < /tmp/ck$1
filecnt=${#allfiles[*]}
echo "$filecnt files found. parsing..."


rm /tmp/result$1 2>/dev/null
touch /tmp/result$1

for ((i=0; i<$filecnt; i++))
do

	fname=${allfiles[i]#*/}
	fname=${fname%?}
	echo "($i) $2 $fname.."
	$2 "./$fname"
done


