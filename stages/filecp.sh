#!/bin/sh

# file system check tool
# check what's inside a directory

#generate file list

if [ -z "$1" ]; then
	echo "No ext specified. filecp.sh png /bak/aaa/"
	exit 1
fi

if [ -z "$2" ]; then
	echo "No desiation specified. filecp.sh png /bak/aaa/"
	exit 2
fi

echo "checking *.$1..."
find -type f -iname "*.$1"  -exec stat -c "%s, %W, %Y, %i, %n" '{}' ';' | sort -n  > /tmp/ck$1
echo "done"


declare -a allfiles
mapfile allfiles < /tmp/ck$1
filecnt=${#allfiles[*]}
echo "$filecnt files found. copying to $2/$1.."


failed=0
succ=0

for ((i=0; i<$filecnt; i++))
do
	fname=${allfiles[i]#*/}
	fname=${fname%?}
	difn=$(dirname $fname)
	mkdir -p "$2/$1/$difn"
	cp -a "./$fname" "$2/$1/$difn"
	if [ "$?" != "0" ]; then
		echo $fname copy failed.
		failed=$(($failed+1))
	else
		succ=$(($succ+1))
	fi
done

echo "Done, $succ successed, $failed failed."


