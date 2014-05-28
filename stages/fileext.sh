#!/bin/sh

# file system check tool
# check what's inside a directory

#generate file list

if [ -z "$1" ]; then
	echo "No ext specified. filedel.sh exe"
	exit 1
fi
echo "checking *.$1..."
find -type f -iname "*.$1"  -exec stat -c "%s, %W, %Y, %i, %n" '{}' ';' | sort -n  > /tmp/ck$1
echo "done"


declare -a allfiles
mapfile allfiles < /tmp/ck$1
filecnt=${#allfiles[*]}
echo "$filecnt files found. parsing..."


rm /tmp/result$1 2>/dev/null
touch /tmp/result$1

for ((i=0; i<$filecnt; i++))
do
	filesize=${allfiles[i]%%,*}
	filesize=${filesize:=0}
	filesize="$(($filesize/1024)) K"
	fname=${allfiles[i]#*/}
	printf "%-10s%-10s%s\n" "($i)" $filesize "$fname" >> /tmp/result$1 
done

cat /tmp/result$1
rm /tmp/ck$1

