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

showinfo "making locales.." 
mkdir -pv /usr/lib/locale
localedef -i en_US -f ISO-8859-1 en_US
err_check "locale iso-8859-1 failed."

localedef -i en_US -f UTF-8 en_US.UTF-8
err_check "locale en_US.UTF-8 failed."

localedef -i zh_CN -f GB2312 zh_CN.GB2312
err_check "locale gb failed."

localedef -i zh_CN -f UTF-8 zh_CN.UTF-8
err_check "locale gb.utf8 failed."


showinfo "create password..."
pwconv
err_check "pwconv failed."

grpconv
err_check "grpconv failed."

passwd
showOK "all done. ready for stage1"

