#!/bin/sh

#
# Xiange installation script : basic io with color
#
#	Copyright (C) Lihui Zhang <swordhuihui@gmail.com>
#	2014.05.27
#	Licence: GPL V2
#


# CLWarning: when switching from a 8bit to a 9bit font,
# the linux console will reinterpret the bold (1;) to
# the top 256 glyphs of the 9bit font. This does
# not affect framebuffer consoles
CLNORMAL="\\033[0;39m" # Standard console grey
CLSUCCESS="\\033[1;32m" # CLSuccess is green
CLWARNING="\\033[1;33m" # CLWarnings are yellow
CLFAILURE="\\033[1;31m" # CLFailures are red
CLINFO="\\033[1;36m" # CLInformation is light cyan

#show CLinfo in cyan color, $1 is CLinformation.
showinfo()
{
	echo -e  $CLINFO"$1"$CLNORMAL
}

#show OK message in green color, $1 is CLinformation.
showOK()
{
	echo -e $CLSUCCESS"$1"$CLNORMAL
}

#show OK message in green color, $1 is CLinformation.
showFailed()
{
	echo -e $CLFAILURE"$1"$CLNORMAL
}

xg_do_cleanup()
{
	showinfo "cleaning up..."
}

#check return code. show $1 if error.
err_check()
{
	local retcode="$?"
	if [ "$retcode" != "0" ]; then
		showFailed "$1"
		xg_do_cleanup
		exit $retcode 
	fi
}

show_clearcolor()
{
	CLNORMAL="" # Standard console grey
	CLSUCCESS="" # CLSuccess is green
	CLWARNING="" # CLWarnings are yellow
	CLFAILURE="" # CLFailures are red
	CLINFO="" # CLInformation is light cyan
}

#
# string cut
#	$1 is string
#	$2 is delimiter
#	$3 is index, default is 0
#	result is put to array docut_a, and count docut_c
#
declare -a docut_a
docut()
{
	local left="$1"
	local item=""
	docut_c=0
	unset docut_a

	while [ "$left" != "$item" ];
	do
		item="${left%%${2}*}"
		left="${left#*$2}"
		docut_a[$docut_c]=$item
		echo "$docut_c = ${docut_a[$docut_c]}"
		docut_c=$(($docut_c+1))
	done
}

