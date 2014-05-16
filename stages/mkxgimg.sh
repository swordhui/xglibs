#!/bin/sh

# Warning: when switching from a 8bit to a 9bit font,
# the linux console will reinterpret the bold (1;) to
# the top 256 glyphs of the 9bit font. This does
# not affect framebuffer consoles
NORMAL="\\033[0;39m" # Standard console grey
SUCCESS="\\033[1;32m" # Success is green
WARNING="\\033[1;33m" # Warnings are yellow
FAILURE="\\033[1;31m" # Failures are red
INFO="\\033[1;36m" # Information is light cyan
BRACKET="\\033[1;34m" # Brackets are blue

#show info in cyan color, $1 is information.
showinfo()
{
	echo -e  $INFO"$1"$NORMAL
}

#show OK message in green color, $1 is information.
showOK()
{
	echo -e $SUCCESS"$1"$NORMAL
}

#show OK message in green color, $1 is information.
showFailed()
{
	echo -e $FAILURE"$1"$NORMAL
}

#check return code. show $1 if error.
err_check()
{
	if [ $? != 0 ]; then
		echo -e $FAILURE"$1"
		exit 1
	fi
}

imgfile="/root/xg64.img"

#4G
case "$1" in
8g)
	disksize=8000000000
	;;
8G)
	disksize=8000000000
	;;
*)
	disksize=4000000000
	;;
esac
blocks=$(($disksize/512))

showinfo "create image file $imgfile, size $(($disksize/1000000000)) GB.."
dd if=/dev/zero of=$imgfile count=$blocks
err_check "failed."


showinfo "mount to a image.."
modprobe loop
losetup -d /dev/loop0
losetup -P /dev/loop0 $imgfile
err_check "setup loop device failed."

showinfo "create partitions..."
cfdisk /dev/loop0
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

showinfo "installing grub2..."
grub-install --modules=part_msdos --root-directory=/mnt/image /dev/loop0
err_check "install grub failed."

export XGROOT=/mnt/image

showOK "done. mounted to /mnt/image, ready for stage0"
echo ""
showinfo "Caution: don't forget set XGROOT=/mnt/image when install stage0."


