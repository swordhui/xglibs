#!/bin/sh

#
# Xiange installation script : image creater
#
#	Copyright (C) Lihui Zhang <swordhuihui@gmail.com>
#	2014.05.27
#	Licence: GPL V2
#
#	this script can be only called in chroot enviroment after stage0 installed.

scriptpath=/var/xiange/xglibs/stages
. $scriptpath/baseio.sh


xg_do_cleanup()
{
	showinfo "cleaning up..."

	gpkg -unchroot /mnt/image 2>/dev/null
	umount -l /mnt/image/mnt/oldpacks 2>/dev/null
	umount -l /mnt/image 2>/dev/null
	losetup -d /dev/loop0 2>/dev/null
}


imgfile="/root/xg64.img"

#4G
case "$1" in
4g)
	disksize=4000000000
	;;
4G)
	disksize=4000000000
	;;
*)
	disksize=8000000000
	;;
esac
blocks=$(($disksize/512))

showinfo "creating image file $imgfile, size $(($disksize/1000000000)) GB.."
dd if=/dev/zero of=$imgfile count=$blocks
err_check "failed."


showinfo "mounting to a image.."
modprobe loop
losetup -d /dev/loop0
losetup -P /dev/loop0 $imgfile
err_check "setup loop device failed."

showinfo "create partitions..."
printf "o\nn\np\n1\n63\n\na\nw\n" | fdisk -b 512 -c=dos -u=sectors -S 63 /dev/loop0
err_check "create partition failed."

showinfo "formating..."
mkfs.ext4 -v /dev/loop0p1
err_check "format /dev/loop0p1 failed."

showinfo "mounting..."
mkdir -p /mnt/image
mount /dev/loop0p1 /mnt/image
err_check "mount loop0p1 failed."


showinfo "mount xglibs.."
mkdir -p /mnt/image/var/xiange/xglibs
mount --bind /var/xiange/xglibs /mnt/image/var/xiange/xglibs
err_check "mount xglibs failed."


mkdir -p /mnt/image/mnt/oldpacks
mount --bind /var/xiange/packages /mnt/image/mnt/oldpacks
err_check "mount old packs failed."


showinfo "installing grub2..."
grub-install --modules=part_msdos --root-directory=/mnt/image /dev/loop0
err_check "install grub failed."

export XGROOT=/mnt/image

showOK "done. mounted to /mnt/image, ready for stage0"
echo ""
showinfo "Caution: don't forget set XGROOT=/mnt/image when install stage0."

showinfo "installing stage0..."
gpkg inststage 0 /var/xiange/packages
err_check "install failed."

gpkg -chroot /mnt/image /var/xiange/xglibs/stages/dostageall.sh
err_check "chroot 1 failed."

gpkg -unchroot /mnt/image

umount /mnt/image/var/xiange/xglibs
err_check "unmount xglibs failed."

cp /var/xiange/xglibs/stages/stage-gpkg.sh /mnt/image/root
err_check "cp stage-gpkg.sh failed."

gpkg -chroot /mnt/image /root/stage-gpkg.sh
err_check "install gpkg failed."

gpkg -unchroot /mnt/image

mkdir -p /mnt/image/usb{,1,2,3}

showinfo "cleaning up..."
rm /mnt/image/root/stage-gpkg.sh
err_check "rm stage-gpkg.sh failed."
umount -l /mnt/image/mnt/oldpacks
err_check "umount oldpacks failed."
umount -l /mnt/image
err_check "umount /mnt/image failed."
losetup -d /dev/loop0
showinfo "All Done. image ready to use."





