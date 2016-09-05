#!/bin/sh

#
# Xiange installation script : stage0 things
#
#	Copyright (C) Lihui Zhang <swordhuihui@gmail.com>
#	2014.05.27
#	Licence: GPL V2
#
#	this script can be only called in chroot enviroment after stage0 installed.

scriptpath=/var/xiange/xglibs/stages
. $scriptpath/baseio.sh


showinfo "making locales.." 
mkdir -pv /usr/lib/locale
localedef -i en_US -f ISO-8859-1 en_US
err_check "locale iso-8859-1 failed."

localedef -i en_US -f UTF-8 en_US.UTF-8
err_check "locale en_US.UTF-8 failed."

localedef -i zh_CN -f GB2312 zh_CN.GB2312
err_check "locale gb failed."

localedef -i zh_CN -f UTF-8 zh_CN.UTF-8
err_check "locale gb.utf8 failed."

if [ -f /etc/passwd ]; then
	echo "passwd found, skip."
else
	cp /etc/samples/passwd.sample /etc/passwd
	err_check "copy /etc/samples/passwd.sample failed."
fi

if [ -f /etc/group ]; then
	echo "group found, skip."
else
	cp /etc/samples/group.sample /etc/group
	err_check "copy /etc/samples/group.sample failed."
fi

showinfo "create password..."
pwconv
err_check "pwconv failed."

grpconv
err_check "grpconv failed."

printf "xiange\nxiange\n" | passwd
err_check "crete password for root failed."

showOK "all done. ready for stage1"
exit 0

