#!/bin/sh

#this script can be only called in chroot enviroment after stage0 installed.

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

# $1 is output file
xg_mkgrubcfg_head()
{
	cat > $1 << EOF
#
# DO NOT EDIT THIS FILE
#
# It is automatically generated by Xiange install script 
# Lihui Zhang <swordhuihui@gmail.com>
# 2014.05.14

set timeout=5


EOF
}


# $1 is arch. $2 is kerver-version. $3 is device index. $4 is UUID
# $5 is output file $6 is initrd-file
xg_mkgrubcfg_item()
{
	echo -e "menuentry 'Xiange Linux $1 $2' {" >> $5
	echo -e "\tinsmod gzio" >> $5
	echo -e "\tinsmod part_msdos" >> $5
	echo -e "\tinsmod ext2" >> $5
	echo -e "\tset root='hd0,msdos$3'" >> $5
	echo -e "\techo 'Loading Xiange Linux $1 $2...'" >> $5
	echo -e "\tlinux /boot/vmlinuz-$2 root=UUID=$4 rw quiet" >> $5
	if [ -n "$6" ]; then
		echo -e "\tinitrd $6" >> $5
	fi
	echo "}" >> $5
}

#change blkid
devname=$(mount | grep "on / " | grep -o "^[^ \t]*")
newid=$(blkid -o value $devname 2>/dev/null | head -n 1)
devnameraw=$(basename $devname)
devnameraw2=${devnameraw%[0-9]}
devindex=${devnameraw#$devnameraw2}

outputf=/boot/grub/boot.cfg
mkdir -p /boot/grub

gpkg -info > /tmp/gpkginfo
. /tmp/gpkginfo

initrdf=$(ls /boot/initramfs*)

echo "devname: $devname, UUID: $newid, Index: $devindex"
echo "Arch: $XGB_ARCH"
echo "initramfs: $initrdf"

if [ -z "$newid" ]; then
	showFailed "UUID check failed."
	exit 2
fi

if [ -z "$devindex" ]; then
	showFailed "devindex check failed."
	exit 3
fi

if [ -z "$XGB_ARCH" ]; then
	showFailed "arch check failed."
	exit 4
fi


xg_mkgrubcfg_head $outputf



echo "checking kernels.."


for i in /boot/vmlinuz-*; 
do
	i=$(basename $i)
	kernelv=${i#vmlinuz-}
	echo found $i, kerver version: $kernelv
	xg_mkgrubcfg_item "$XGB_ARCH" "$kernelv" "$devindex" "$newid" "$outputf" "$initrdf"
done

#showinfo "change UUID to $newid (dev $devname)..."
#sed -i "s@root=UUID=[^ \t]*@root=UUID=$newid@g" /boot/grub/grub.cfg
#err_check "change UUID to $newid failed."

showinfo "enable network manager.."
systemctl enable NetworkManager
err_check "enable network manager failed."

#enable sshd
showinfo "enable sshd manager.."
systemctl enable sshd
err_check "enable sshd failed"

showOK "all done. ready for stage2"
showinfo "If you want install stage2, please remove vim with gpkg -D vim."

