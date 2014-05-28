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

showinfo "do stage0 things..."
$scriptpath/dostage0.sh
err_check "dostage0 failed."

for i in 1 2 3 
do
	showinfo "install stage$i..."
	gpkg inststage $i /mnt/oldpacks
	err_check "install stage $i failed."

	showinfo "do stage$i things..."
	$scriptpath/dostage${i}.sh
	err_check "dostage$i failed."

	if [ "$i" == "1" ]; then
		#remove vim because 
		gpkg -D vim
	fi
done

#clean up
showinfo "please check OS release information:"
vi /etc/os-release
showinfo "Modify them in need."




