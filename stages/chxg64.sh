#!/bin/sh

#
# 
#	chroot to xg64.img
#
#	Copyright (C) Lihui Zhang <swordhuihui@gmail.com>
#	2015.06.08
#	Licence: GPL V2
#
#	

scriptpath=/var/xiange/xglibs/stages
. $scriptpath/baseio.sh

showinfo "mounting xg64.img.."
losetup -P /dev/loop0 /root/xg64.img
err_check "loset failed."

mount /dev/loop0p1 /mnt/image
err_check "mount /ming/image failed."

mount --bind /var/xiange/sources /mnt/image/var/xiange/sources
err_check "mount source failed."

mount --bind /var/xiange/packages-wayland /mnt/image/var/xiange/packages/
err_check "mount packages failed."


gpkg -chroot /mnt/image



