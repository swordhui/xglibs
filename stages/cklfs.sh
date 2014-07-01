#!/bin/sh

#
# Xiange script : check wich package can be update
#
#	Copyright (C) Lihui Zhang <swordhuihui@gmail.com>
#	2014.06.16
#	Licence: GPL V2
#
#	

scriptpath=/var/xiange/xglibs/stages
. $scriptpath/baseio.sh


ntmpdir=/tmp/xglfs.$$

mkdir -p $ntmpdir
err_check "make dir $ntmpdir failed."

cd $ntmpdir
err_check "enter dir $ntmpdir failed."


xg_get_list()
{
	showinfo "getting the newest lfs install file.."
	wget http://www.linuxfromscratch.org/lfs/downloads/development/wget-list
	err_check "get lfs file list failed."
}


xg_get_list

rm $ntmpdir/wget-list
err_check "remove file list failed."

rm -d $ntmpdir
err_check "remove $ntmpdir failed."

