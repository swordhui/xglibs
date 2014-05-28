#!/bin/sh

#
# mount squashfs and unionfs-fuse together.
#
#	Copyright (C) Lihui Zhang <swordhuihui@gmail.com>
#	2014.05.28
#	Licence: GPL V2
#

scriptpath=/var/xiange/xglibs/stages
. $scriptpath/baseio.sh

# $1 is path to squashfs
# $2 is mount point

cd /tmp/sqauni

showinfo "searching..."

allfiles=`find -iname "info" 2>/dev/null`

if [ -z "$allfiles" ]; then
	showFailed "$1 not found."
	exit 2
fi

index=1

for i in $allfiles;
do
	info=$(cat $i)

	docut "$info" ":"

	if [ -z "${docut_a[2]}" ]; then
		showFailed "root not found"
		exit 2
	fi
	sqroot="${docut_a[2]}"

	if [ -z "${docut_a[3]}" ]; then
		showFailed "rw file not found"
	exit 2
	fi
	sqrwfile="${docut_a[3]}"

	printf "%-5d%-40s-->%-40s\n" $index "${docut_a[0]}" "${docut_a[1]}"
done

