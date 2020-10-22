#!/bin/sh

#
# Xiange installation script : install all stages
#
#	Copyright (C) Lihui Zhang <swordhuihui@gmail.com>
#	2014.05.27
#	Licence: GPL V2
#
#	this script can be only called in chroot enviroment after stage0 installed.

scriptpath=/var/xiange/xglibs/stages
. $scriptpath/baseio.sh

finalstage="$1"

if [ -n "$finalstage" ]; then
	showinfo "finalstage=$finalstage"
fi

showinfo "do stage0 things..."
$scriptpath/dostage0.sh
err_check "dostage0 failed."


if [ "$finalstage" == "0" ]; then
	showinfo "Stop at stage 0 as requested."
	exit 0
fi

for i in 1 2
do
	showinfo "install stage$i..."
	gpkg inststage $i /mnt/oldpacks
	err_check "install stage $i failed."

	showinfo "do stage$i things..."
	$scriptpath/dostage${i}.sh
	err_check "dostage$i failed."

	if [ "$finalstage" == "$i" ]; then
		break
	fi
done

#clean up
showinfo "please check OS release information:"
cat /etc/os-release
showinfo "Modify them in need."




