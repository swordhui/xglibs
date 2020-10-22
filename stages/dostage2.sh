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


showinfo "updating gtk3 im modules"
gtk-query-immodules-3.0 > /usr/lib/gtk-3.0/3.0.0/immodules.cache
err_check "gtk3 query module failed."

showinfo "updating gtk icons.."
gdk-pixbuf-query-loaders --update-cache
gtk-update-icon-cache /usr/share/icons/Adwaita
gtk-update-icon-cache /usr/share/icons/gnome
gtk-update-icon-cache /usr/share/icons/hicolor
xdg-icon-resource forceupdate --theme hicolor
xdg-icon-resource forceupdate --theme gnome
err_check "gtk update icon cache  failed."

showinfo "updating mime info..."
update-desktop-database /usr/share/applications
glib-compile-schemas /usr/share/glib-2.0/schemas
err_check "gtk update icon cache  failed."

showinfo "enable gtkgreet.."
systemctl enable greetd
err_check "enable greetd failed."


showinfo "creating user xiang..."
useradd -m -G audio,video,tty,usb,cdrom,disk,camera,gpkg,wheel,net,dialout,systemd-journal,dhcpcd,systemd-resolve xiange
err_check "add user xiange failed."

showinfo "setting password for xiange..."
printf "xiange\nxiange\n" | passwd xiange
err_check "change password for xiange failed."


showOK "all done. system ready to use"
showFailed "You can call stage-gpkg.sh to update xglibs now."

