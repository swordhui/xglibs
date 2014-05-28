#!/bin/sh

#
# CAUTION: DO NOT INCLUDE ANY OTHER FILES!!!!
# THIS SCRIPT IS STAND ALONG ONLY!!!
#

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
		showFailed "$1"
		exit 1
	fi
}

showinfo "checking /var/xiange/xglib.."
mountpoint /var/xiange/xglibs
if [ "$?" == "0" ]; then
	showFailed "please un-mount /var/xiange/xglbis."
	exit 1
fi

showinfo "updating xglibs.."
gpkg --sync
err_check "sync xglibs failed."


showinfo "set owner to gpkg.."
chown -R gpkg:gpkg /var/xiange/xglibs
err_check "set owner failed."

showinfo "set permission..."
chmod -R g+w /var/xiange/xglibs/.git
err_check "set permission failed."

showOK "all done. gpkg ready to use"

