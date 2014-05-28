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
mntpoint=${1%/}

# $1 is path to squashfs
# $2 is mount point

if [ -z "$1" ]; then
	showFailed "unmount squashfs+unionfs"
	showFailed "Usage: squmnt mount_point"
	exit 1
fi

cd /tmp/sqauni

showinfo "searching $mntpoint..."

allfiles=`find -iname "info" 2>/dev/null`

if [ -z "$allfiles" ]; then
	showFailed "$mntpoint not found."
	exit 2
fi

info=$(grep "$mntpoint:" $allfiles  2>/dev/null)

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

showinfo "unmounting.."
umount "${docut_a[1]}"
err_check "umount ${docut_a[1]} failed."

umount "$sqroot/ro"
err_check "umount $sqroot/ro failed."

showinfo "writing rw file.."
cd $sqroot
err_check "cd $sqroot failed."

tar czf "$sqrwfile" rw/
err_check "write $sqrwfile failed."

cd /tmp

rm -rf "$sqroot/rw"
err_check "delete $sqroot/rw failed."

rm -f "$sqroot/info"
err_check "delete $sqroot/info failed."

rm -fd "$sqroot/ro"
err_check "delete $sqroot/ro failed."

rm -fd "$sqroot"
err_check "delete $sqroot failed."

showinfo "umounted."


