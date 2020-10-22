#!/bin/sh


mntroot=/tmp/xgmnt2

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
		showFailed "$1"
		exit 1
	fi
}

#
# make a Xiange Linux bootable vfat usb disk, $1 is dev, such as /dev/sdc
#

sectors=$(LANG="C" fdisk -l -u /dev/sdc | head -n 1 | grep -o "[0-9]* sectors")
sectors=${sectors%" sectors"}
echo "disk $1, sectors=$sectors, size=$(($sectors*512/1000/1000)) MB"

datasecs=$(($sectors-2048-2048-102400))

#part1: 2048 sectors
#part3: 2048 sectors
#part4: 102400 sectors

showinfo "create GPT partitions.."
printf "o\ny\nn\n\n\n$datasecs\n0700\nn\n\n\n+1M\nEF02\nn\n\n\n\nEF00\nw\ny\n" | gdisk $1
showinfo "create MBR partitions..."
printf "r\nh\n1 2 3\nn\n0700\nn\nEF02\nn\nEF00\ny\nw\ny\n" | gdisk $1

showinfo "formating vfat..."
mkfs.vfat -F 32 -n GRUB2EFI ${1}3
err_check "format ${1}3 failed."

mkfs.vfat -F 32 -n DATA ${1}1
err_check "format ${1}1 failed."

mkdir -p ${mntroot}/1
mkdir -p ${mntroot}/2
showinfo "mounting..."
mount ${1}3 $mntroot/1
err_check "mount ${loopd}p2 failed."

mount ${1}1 $mntroot/2
err_check "mount ${loopd}p3 failed."

showinfo "installing grub2 GPT mode..."
grub-installefi --target=x86_64-efi --efi-directory=$mntroot/1 --boot-directory=$mntroot/2/boot --removable --recheck  $1
err_check "install grub-efi failed."

showinfo "installing grub2 dos mode..."
grub-install --target=i386-pc --boot-directory=$mntroot/2/boot --recheck $1
err_check "install grub failed."

showinfo "copying grub themes.."
cp -r /boot/grub/themes $mntroot/2/boot/grub/
err_check "copying themes failed"


showinfo "unmount $mntroot/1..."
umount $mntroot/1
err_check "unmount efi failed."
umount $mntroot/2
err_check "unmount data failed."


./mkxgsqush.sh "${1}1"


