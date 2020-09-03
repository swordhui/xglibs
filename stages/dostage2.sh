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




showinfo "updating gtk icons.."
gtk-update-icon-cache
err_check "gtk update icon cache  failed."

#showinfo "updating mime info..."
#update-desktop-database /usr/share/applications
#err_check "gtk update icon cache  failed."


#showinfo "enable slim.."
#systemctl enable slim
#err_check "enable slim failed."

#showinfo "enable fvwm-xiange"
#systemctl enable xiange-welcome
#err_check "enable slim failed."





showinfo "creating user xiang..."
useradd -m -G audio,video,tty,cdrom,camera,gpkg,wheel xiange
err_check "add user xiange failed."

showinfo "setting password for xiange..."
printf "xiange\nxiange\n" | passwd xiange
err_check "change password for xiange failed."


showOK "all done. system ready to use"
showFailed "You can call stage-gpkg.sh to update xglibs now."

