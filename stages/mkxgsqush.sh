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

if [ -f "/root/xg64.img" ]; then
	ls -l /root/xg64.img
else
	showFailed "No Xg64.img found."
	exit 1
fi

showinfo "copying ..."
mkdir -p /tmp/squashroot
cp -a /root/xg64.img /tmp/squashroot/
err_check "copy failed."

showinfo "making squash fs.."

cd /tmp
mksquashfs squashroot xiange-sqroot
err_check "make squash fs failed."

showOK "done"

