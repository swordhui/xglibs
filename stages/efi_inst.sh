#!/bin/bash

#
# efi_inst -- install Xiange kernel to EFI partition
# 
# by Zhang Lihui <swordhuihui@gmail.com>, 2018-10-29, 15:58
#

## Set color commands, used via $ECHO
# Please consult `man console_codes for more information
# under the "ECMA-48 Set Graphics Rendition" section
#
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

#show OK message in green color, $1 is information.
showFailed()
{
	echo -e $FAILURE"$1"$NORMAL
}

#show OK message in green color, $1 is information.
showOK()
{
	echo -e $SUCCESS"$1"$NORMAL
}

#
# Error check
#

#check return code. show $1 if error.
err_check()
{
	if [ $? != 0 ]; then
		showFailed "$1" >&2
		exit 1
	fi
}


efi_inst_version=0.1
efi_inst_usage="
efi_inst $SUCCESS$efi_inst_version$NORMAL, usage:\n
	$INFO\t-v            	$NORMAL\t\tshow current version\n
	$INFO\t-a /dev/sdXX kernel_image EFI_part_number\n
			$NORMAL\t\t\tadd kernel image to EFI and install it.\n
			$NORMAL\t\t\t/dev/sdXX is linux root partition, EFI_part_number is EFI partition\n
			$NORMAL\t\t\tsample: efi_inst -a /dev/sdb3 /boot/vmlinux-4.18.16 1\n
	$INFO\t-d bootNum $NORMAL\tdelete boot image from EFI and remove it form boot order.\n
"

gpkg_show_usage()
{
	echo -e $efi_inst_usage
}

gpkg_inst_efi()
{
	efinum=$3

	if [ x"$efinum" == "x" ]; then
		efinum="1"
	fi

	efi_boot=$1
	efi_dev="${1%%[0-9]}"
	efi_dev1="${efi_dev}""${efinum}"
	image="$2"

	partuuid=$(blkid $efi_boot | grep -o PARTUUID=".*")
	echo $partuuid

	if [ x"$partuuid" == "x" ]; then 
		echo -e "${FAILURE}Get PartUUID failed. please make sure your are root or dev name correct.$NORMAL"
		exit 2
	fi

	if [ -f "$image" ]; then
		echo "$image found."
	else
		echo -e "${FAILURE}kernel $image is not a vaild file.$NORMAL"
		exit 2
	fi

	labelname=${2##*/}
	labelname=$(echo $labelname | sed "s/\./-/g")
	destfile_raw="/EFI/Xiange/${labelname}.efi"
	#echo "DestFile=$destfile"

	destfile="\\EFI\\Xiange\\${labelname}.efi"

	echo "DestFile=$destfile"

	mkdir -p /tmp/bootefi
	err_check "create dir /tmp/bootefi failed"

	umount /tmp/bootefi > /dev/null 2>&1

	mount $efi_dev1 /tmp/bootefi
	err_check "mount /tmp/bootefi failed"

	mkdir -p /tmp/bootefi/EFI/Xiange
	err_check "create EFI/Xiange failed"

	cp $image /tmp/bootefi$destfile_raw
	err_check "copy kernel image failed"

	#install
	efibootmgr -c -d ${efi_dev} -p $efinum -L "$labelname" -l "$destfile" -u "root=$partuuid uurw quiet"
	err_check "efibootmgr failed"

	showOK "all done"
}

case "${1}" in
-v)
	#show version.
	echo $efi_inst_version
	;;

-a)
	#show version.
	gpkg_inst_efi "$2" "$3"
	;;


*)
	#show usage 
	gpkg_show_usage
	exit 0
	;;
esac



#efibootmgr -c -d /dev/sdb -p 1 -L "Xiange-4.18.16" -l "\EFI\Xiange\boot-041816.efi" -u "root=PARTUUID=d059e167-d7f1-ef4d-8839-bb0c96d6b0fb rw quiet"

#remove 
#efibootmgr -b  0014 -B
