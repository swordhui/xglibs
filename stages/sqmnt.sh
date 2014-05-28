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

if [ -z "$1" ]; then
	showFailed "Usage: squnimnt squashfs.img mount_point"
fi

if [ -z "$2" ]; then
	showFailed "Usage: squnimnt squashfs.img mount_point"
fi


tmpmntroot=/tmp/sqauni/$$
tmpmntdir=$tmpmntroot/ro
tmprwdir=$tmpmntroot/rw
infofile=$tmpmntroot/info
rwfile=${1}.rw.tar.gz
mntpoint=${2%/}

mkdir -p $tmpmntdir
err_check "create $tmpmntdir failed."

mkdir -p $tmprwdir
err_check "create $tmpmntdir failed."

if [ -f $rwfile ]; then
	showinfo "prepare rw data..."
	tar xaf $rwfile -C $tmpmntroot
fi

mount -t squashfs $1 $tmpmntdir -o loop
err_check "mount squashfs $1 to $tmpmntdir failed." 

unionfs -o cow,max_files=32768 \
	-o allow_other,use_ino,suid,dev,nonempty \
    $tmprwdir=RW:$tmpmntdir=RO $mntpoint
err_check "mount unionfs to $mntpoint failed."

echo "$1:$mntpoint:$tmpmntroot:$rwfile" > $infofile

showinfo "$mntpoint is ready to use."

