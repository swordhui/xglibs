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

isofile=/root/xiange.iso
isodir=/root/xg_iso
sqimg=/root/xg_sqh.img
sqroot=/root/xiange-sqroot
mntdir=/tmp/isomnt

#
# make a Xiange Linux bootable CD/DVD
#

if [ -d $isodir ]; then
	showinfo "remove $isodir/*.."
	rm -rf $isodir
	err_check "remove $isodir failed"
fi

mkdir $isodir
err_check "create $isodir failed"

#check squash image
if [ -f "$sqimg" ]; then
	showinfo "$sqimg found"
else
	showFailed "$sqimg not found"
	exit 1
fi

mkdir -p $mntdir 
err_check "mount $mntdir failed"

sqimgdev=$(losetup -f --show -P $sqimg)
err_check "set loopback dev to $sqimg failed"

mount ${sqimgdev}p3 $mntdir
err_check "mount $sqimgdev dev to $mntdir failed"

showinfo "$sqimgdev mounted to $mntdir, copying boot.."

cp -r $mntdir/boot $isodir
err_check "copy boot failed" 

#patch boot grub
sed -i 's@search.*--no-floppy.*@set root=(cd,3)@g' $isodir/boot/grub/grub.cfg 
err_check "patch grub.cfg failed"

#copy squshfs
mkdir -p $isodir/xiange
touch $isodir/xiange/test

#umount
umount $mntdir
err_check "umount $mntdir failed"

losetup -d $sqimgdev
err_check "remove $sqimg failed"

showinfo "making iso $isofile..."
grub-mkrescueefi -o $isofile --product-name="Xiange-Linux" --product-version="2020.10.29" $isodir
err_check "mkiso failed"

showinfo "$isofile done"

