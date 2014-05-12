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

showinfo "installing firmware..."
gpkg -ub /mnt/oldpacks/linux-firmware-1.0.xgp 
err_check "firmware failed."

showinfo "installing kernel.."
gpkg -ub /mnt/oldpacks/linux-kernel-3.10.37-all.xgp
err_check "install kernel failed."


showinfo "installing initram.."
gpkg -ub /mnt/oldpacks/xiange-initram-1.0.xgp
err_check "install kernel failed."

#change blkid
devname=$(mount | grep "on / " | grep -o "^[^ \t]*")
newid=$(blkid -o value $devname 2>/dev/null | head -n 1)
showinfo "change UUID to $newid (dev $devname)..."
sed -i "s@root=UUID=[^ \t]*@root=UUID=$newid@g" /boot/grub/grub.cfg
err_check "change UUID to $newid failed."

showinfo "enable network manager.."
systemctl enable NetworkManager
err_check "enable network manager failed."

#enable sshd
showinfo "enable sshd manager.."
systemctl enable sshd
err_check "enable sshd failed"

showOK "all done. ready for stage2"

