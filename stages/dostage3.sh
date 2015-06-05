#!/bin/sh
#
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


showinfo "updating gtk2 modules"
gtk-query-immodules-2.0
err_check "gtk2 query module failed."

showinfo "updating gtk3 modules"
gtk-query-immodules-3.0
err_check "gtk3 query module failed."

showinfo "updating gtk icons.."
gtk-update-icon-cache
err_check "gtk update icon cache  failed."

showinfo "updating mime info..."
update-desktop-database /usr/share/applications
err_check "gtk update icon cache  failed."

showinfo "compile schemas.."
glib-compile-schemas /usr/share/glib-2.0/schemas
err_check "compile schema failed."

showinfo "updating hicolor icons"
xdg-icon-resource forceupdate --theme hicolor
err_check "update hicolor icon failed."

showinfo "updating gnome icons"
xdg-icon-resource forceupdate --theme gnome
err_check "update gnome icon failed."

showinfo "updating pixbuf cache..."
gdk-pixbuf-query-loaders --update-cache
err_check "update pixbuf cache failed."

showinfo "please check OS release information:"
vi /etc/os-release
showinfo "Modify them in need."

showOK "all done. system ready to use"

