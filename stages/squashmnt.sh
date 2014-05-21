#!/bin/bash

#
# mount sqush fs in RW mode
#	by Lihui Zhang <swordhuihui@gmail.com>
#	2014.05.20
#
#	$1 is squasfs image file, with xiang-root(xg64.img)
#	$2 is cow.out file, for squashfs writing.
#	$3 is final mount point. [optional]
#

NORMAL="\\033[0;39m" # Standard console grey
SUCCESS="\\033[1;32m" # Success is green
WARNING="\\033[1;33m" # Warnings are yellow
FAILURE="\\033[1;31m" # Failures are red
INFO="\\033[1;36m" # Information is light cyan
BRACKET="\\033[1;34m" # Brackets are blue

#show info in cyan color, $1 is information.
showinfo()
{
	echo -e  $INFO"$1"$NORMAL
}

#show OK message in green color, $1 is information.
showOK()
{
	echo -e $SUCCESS"$1"$NORMAL
}

#show OK message in green color, $1 is information.
showFailed()
{
	echo -e $FAILURE"$1"$NORMAL
}

#check return code. show $1 if error.
err_check()
{
	if [ $? != 0 ]; then
		showFailed "$1"
		exit 1
	fi
}

if [ "$UID" != "0" ]; then
	showFailed "Need root priviledge"
	exit 2
fi



if [ -z "$1" ]; then
	showFailed "No squash image file specified."
	showinfo "Usage: squashmnt.sh imagefile cowfile"
	exit 2
fi

if [ -z "$2" ]; then
	showFailed "No cowfile specified."
	showinfo "Usage: squashmnt.sh imagefile cowfile"
	exit 2
fi

#modules
modprobe squashfs
err_check "load squshfs failed."
modprobe loop
err_check "load loop failed."
modprobe dm-snapshot
err_check "load dm-snapshot failed."

mkdir -p /mnt/squash/0
err_check "create /mnt/squash/0 failed."

if [ -z "$3" ]; then
	finalmnt=/mnt/squash
else
	finalmnt="$3"
fi

#mount squshfs
mount "$1" /mnt/squash/0 -o loop
err_check "mount $1 to /mnt/squash/0 failed."

losetup -P /dev/loop1 /mnt/squash/0/xg64.img
err_check "setup /mnt/squash/0/xg64.img to /dev/loop1 failed."

mkdir -p /dev/cow 
err_check "create /dev/cow failed."
if [ -b /dev/cow/ctl ]; then
	showinfo "/dev/cow/ctl ok"
else
	mknod /dev/cow/ctl b 241 255 
	err_check "create /dev/cow/ctl failed."
fi

if [ -b /dev/cow/0 ]; then
	showinfo "/dev/cow/0 OK"
else
	mknod /dev/cow/0 b 241 0 
	err_check "create /dev/cow/0 failed."
fi

#mount cow
losetup /dev/loop2 "$2"
err_check "setup cow file $2 to /dev/loop2 faile.d"

echo "0 $(blockdev --getsize /dev/loop1p1) snapshot /dev/loop1p1 /dev/loop2 p 64" | dmsetup create root_fs
err_check "create root_fs failed."

mount /dev/mapper/root_fs "$finalmnt"
err_check "mount failed."

showOK "mounted to $finalmnt in RW mode."
