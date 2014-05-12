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

if [ -z "$1" ]; then
	showFailed "Please specify device name,such as /dev/sda2."
	exit 1
fi

showinfo "mounting..."
mkdir -p /mnt/image

#check mount point
mountpoint /mnt/image
if [ "$?" == "0" ];
	showFailed "/mnt image have already mounted, please unmount first."
	exit 2
fi

mount $1 /mnt/image
err_check "mount $1 to /mnt/image  failed."


showinfo "mount xglibs.."
mkdir -p /mnt/image/var/xiange/xglibs
mount --bind /var/xiange/xglibs /mnt/image/var/xiange/xglibs
err_check "mount xglibs failed."

export XGROOT=/mnt/image

showOK "done. mounted to /mnt/image, ready for stage0"
echo ""
showinfo "Caution: don't forget set XGROOT=/mnt/image when install stage0."


