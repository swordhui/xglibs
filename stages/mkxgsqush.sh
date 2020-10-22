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

mntroot=/tmp/xgmnt2
oldroot=$mntroot/2
newroot=$mntroot/1
squash_arch=x86_64
declare loopd
declare lpxg



xg_cleanup()
{
	#unmount newroot
	showinfo "unmounting $newroot..."
	umount $newroot

	showinfo "unmounting $oldroot..."
	umount $oldroot

	losetup -d /dev/loop1
	losetup -d /dev/loop2

	showinfo "unmounting $mntroot/0.."
	umount $mntroot/0

	rm -rf $mntroot
}



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
	xg_cleanup
}

#check return code. show $1 if error.
err_check()
{
	if [ $? != 0 ]; then
		showFailed "$1"
		exit 1
	fi
}

# $1 is output file
# $2 is root UUID
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

search --no-floppy --fs-uuid --set=root $2

# Setup video
if [ "\$grub_platform" = "efi" ]
then
    insmod efi_gop
    insmod efi_uga
fi

if [ "\$grub_platform" = "pc" ]
then
    insmod vbe
fi

insmod font
loadfont (\$root)/boot/grub/themes/fallout-grub-theme/fixedsys-regular-32.pf2
insmod gfxterm
set gfxmode=auto
set gfxpayload=keep
terminal_output gfxterm
insmod png
set theme=(\$root)/boot/grub/themes/fallout-grub-theme/theme.txt
export theme



EOF
}

# $1 is arch. $2 is kerver-version. $3 is device index. $4 is UUID
# $5 is output file $6 is initrd-file 
# $7 will be added to kernel command line 
# $8 is Title
xg_mkgrubcfg_item()
{
	echo -e "menuentry '$8' {" >> $5
	echo -e "\tinsmod gzio" >> $5
	echo -e "\tinsmod part_msdos" >> $5
	echo -e "\tinsmod ext2" >> $5
	echo -e "\tinsmod search_fs_uuid" >> $5
	echo -e "\tsearch --fs-uuid --no-floppy --set=root $4" >> $5
	echo -e "\techo 'Loading Xiange Linux $1 $2...'" >> $5
	echo -e "\tlinux /boot/vmlinuz-$1-$2 root=UUID=$4 $7 rw quiet" >> $5
	if [ -n "$6" ]; then
		echo -e "\tinitrd $6" >> $5
	fi
	echo "}" >> $5
}


#
# deal with kernel, $1 is version
#
xg_do_kernel()
{
	#copy kernel
	cp -a $oldroot/boot/vmlinuz-$1 $newroot/boot/vmlinuz-$XGB_ARCH-$1
	err_check "copy $oldroot/boot/vmlinuz-$XGB_ARCH-$1 faile.d"

	cp -a $oldroot/boot/config-$1 $newroot/boot/config-$XGB_ARCH-$1
	err_check "copy $oldroot/boot/config-$1 faile.d"

	#get initrams
	rm -rf $mntroot/init
	mkdir $mntroot/init
	cd $mntroot/init
	err_check "enter $mntroot/init failed."

	local -a initnames
	local initcnt=0
	for i in $oldroot/boot/initramfs-*.img.gz
	do
		initnames[$initcnt]="$i"
		initcnt=$(($initcnt+1))
	done
		
	gunzip -c ${initnames[0]} | cpio -i 
	err_check "unzip initramfs ${initnames[0]} failed."

	XGLIST="/lib/libdevmapper.so.*
		/lib/libc.so.*
		/lib/libm.so.*
		/lib/libc-*.so 
		/lib/libm-*.so 
		/lib/libpthread.so.0 
		/lib/libpthread-*.so 
		/lib/ld-*.so 
		/lib/ld-linux-x86-64.so.2 
		/sbin/dmsetup
		/lib/modules/$1/kernel/drivers/block/loop.ko
		/lib/modules/$1/kernel/fs/squashfs/squashfs.ko
		/lib/modules/$1/kernel/lib/lz4/lz4*.ko
		/lib/modules/$1/kernel/drivers/md/dm-snapshot.ko
		/lib/modules/$1/kernel/drivers/md/dm-bufio.ko
		/lib/modules/$1/kernel/drivers/md/dm-mod.ko"
		
	if [ "$XGB_ARCH" == "x86_64" ]; then
		ln -sv lib $mntroot/init/lib64
		err_check "create lib64 failed."
	fi

	mkdir -p $mntroot/init/root
	err_check "create root failed."

	#copy file in list
	for i in $XGLIST;
	do
		basen=$(dirname $i)
		mkdir -p $mntroot/init$basen
		showinfo "copying $oldroot$i..."
		cp -a $oldroot$i $mntroot/init$basen/
		err_check "cp $oldroot$i failed."
	done

	
	#init
	cp /var/xiange/xglibs/stages/init $mntroot/init/init
	err_check "copy init failed."

	#set arch
	sed -i "s/^xgb_arch=.*/xgb_arch=${squash_arch}/g" $mntroot/init/init
	err_check "set new arch failed"

	#make depfiles
	mount -t proc none $mntroot/init/proc
	mount -t sysfs none $mntroot/init/sys
	mount --bind /dev $mntroot/init/dev
	chroot $mntroot/init /sbin/depmod $1
	err_check "dempode failed."

	#check dmsetup
	chroot $mntroot/init /sbin/dmsetup --help 
	err_check "run dmsetup failed."

	#sleep 1
	umount $mntroot/init/dev
	err_check "umount dev failed."
	umount $mntroot/init/sys
	err_check "umount sys failed."
	umount $mntroot/init/proc
	err_check "umount proc failed."

	#generate new initramfs
	initrdf=/boot/initramfs-$XGB_ARCH-$1.img
	find | cpio -o -H newc > $newroot$initrdf
	err_check "generate $newroot$initrdf."
	rm -f $newroot${initrdf}.gz
	gzip $newroot$initrdf
	err_check "compress $newroot$initrdf failed."

	showinfo "$newroot/boot/initramfs-$1.img.gz is ready."

	initrdf=${initrdf}.gz

	#boot.cfg
	xg_mkgrubcfg_item "$XGB_ARCH" "$1" "$devindex" "$newid" "$outputf" \
		"$initrdf" "rootfstype=ext4" "Xiange Linux $XGB_ARCH $1"

	xg_mkgrubcfg_item "$XGB_ARCH" "$1" "$devindex" "$newid" "$outputf" \
		"$initrdf" "safemode"  "Xiange Linux $XGB_ARCH $1 -- Safemode"

}

xg_mksquash()
{
	
	showinfo "copying ..."
	rm -rf /root/squashroot
	mkdir -p /root/squashroot
	ln /root/xg64.img /root/squashroot/
	err_check "copy failed."
	
	showinfo "making squash fs.."
	
	cd /root
	rm -f xiange-sqroot.tmp 2>/dev/null
	mksquashfs squashroot xiange-sqroot.tmp
	err_check "make squash fs failed."
	
	rm -rf squashroot
	err_check "rm temperory file failed."
	mv xiange-sqroot.tmp xiange-sqroot
	err_check "rename xiange-sqroot.tmp failed."
}

xg_cksquash()
{
	if [ -f "/root/xg64.img" ]; then
		ls -l /root/xg64.img
	else
		showFailed "No Xg64.img found."
		exit 1
	fi

	if [ -f "/root/xiange-sqroot" ]; then
		#found, check date
		if [ "/root/xiange-sqroot" -nt "/root/xg64.img" ]; then
			#newer, no need recreate.
			showinfo "xiange-sqroot is newer than xg64.img, pass"
		else
			showinfo "xiange-sqroot is older than xg64.img, recreate it"
			rm -f "/root/xiange-sqroot"
			xg_mksquash
		fi
	else
		showinfo "xiange-sqroot not found, recreate it"
		#not found
		xg_mksquash
	fi
}

xg_prepare()
{
	mkdir -p $mntroot/0
	mkdir -p $mntroot/1
	mkdir -p $mntroot/2
	
	#load modules
	modprobe loop
	err_check "load loop failed."
	modprobe squashfs
	err_check "load squashfs failed."
}

xg_mount_squash()
{
	showinfo "mount sqroot to $mntroot/0.."
	mount /root/xiange-sqroot $mntroot/0 -o loop 
	err_check "mount xiange-sqroot to $mntroot/0 failed."

	if [ -f $mntroot/0/xg64.img ]; then
		showinfo "xg64.img found."
		ls -lh $mntroot/0/xg64.img
	else
		showFailed "xg64.img found."
	fi
	
	showinfo "mount xiange root to $mntroot/0/xg64.img"
	lpxg=$(losetup -f --show -P $mntroot/0/xg64.img)
	echo "result=$?"
	err_check "setup xg64 to ${lpxg} faled."

	showinfo "mounting new root..."
	mount $devname $mntroot/1
	err_check "mount $devname failed."
	
	showinfo "mounting old root..."
	mount -t ext4 ${lpxg}p1 $mntroot/2 -o ro
	err_check "mount to /mnt/xgmnt/2 faled."
}

imgfile="/root/xg_sqh.img"

xg_mkddimg()
{
	disksize=3500000000
	blocks=$(($disksize/512))
	
	showinfo "create image file $imgfile, size $(($disksize/1000000000)) GB.."
	dd if=/dev/zero of=$imgfile count=$blocks
	err_check "failed."
	
	showinfo "mount to a image.."
	loopd=$(losetup -f --show -P $imgfile)
	err_check "setup $imgfile to $loopd faled."

	showinfo "create GPT partitions..."
	printf "o\ny\nn\n\n\n+1M\nEF02\nn\n\n\n+50M\nEF00\nn\n\n\n\n0700\nw\ny\n" | gdisk $loopd 
	showinfo "create MBR partitions..."
	printf "r\nh\n1 2 3\nn\nEF02\nn\nEF00\nn\n0700\ny\nw\ny\n" | gdisk $loopd 

	showinfo "formating vfat..."
	mkfs.vfat -F 32 -n GRUB2EFI ${loopd}p2
	err_check "format ${loopd}p2 failed."

	mkfs.vfat -F 32 -n DATA ${loopd}p3
	err_check "format ${loopd}p3 failed."
	
	
	showinfo "mounting..."
	mount ${loopd}p2 $mntroot/1
	err_check "mount ${loopd}p2 failed."

	mount ${loopd}p3 $mntroot/2
	err_check "mount ${loopd}p3 failed."


	showinfo "installing grub2 GPT mode..."
	grub-installefi --target=x86_64-efi --efi-directory=$mntroot/1 --boot-directory=$mntroot/2/boot --removable --recheck  $loopd 
	err_check "install grub-efi failed."

	showinfo "installing grub2 dos mode..."
	grub-install --target=i386-pc --boot-directory=$mntroot/2/boot --recheck $loopd 
	err_check "install grub failed."

	showinfo "copying grub themes.."
	cp -r /boot/grub/themes $mntroot/2/boot/grub/
	err_check "copying themes failed"

	
	showinfo "unmount $mntroot/1..."
	umount $mntroot/1
	err_check "unmount efi failed."
	umount $mntroot/2
	err_check "unmount data failed."

	losetup -d $loopd
	err_check "release $loopd failed"

	loopd=$(losetup -f --show -P $imgfile)
	err_check "re-setup image failed."
	devname="${loopd}p3"
}

xg_usedisk()
{

	showinfo "use $1 directly.."
	devname="$1"
	devp=${devname%%[0-9]}
	
	showinfo "mounting..."
	mount $devname $mntroot/1
	err_check "mount #devname failed."
	
	showinfo "installing grub2..."
	grub-install --modules=part_msdos --root-directory=$mntroot/1 --target=i386-pc $devp
	err_check "install grub failed."

	showinfo "unmount $mntroot/1..."
	umount $mntroot/1
	err_check "unmount grub failed."
}



xg_useoldimg()
{
	showinfo "mount to a image.."
	loopd=$(losetup -f --show -P $imgfile)
	err_check "setup $imgfile to ${loopd} faled."

	showinfo "mounting..."
	mount ${loopd}p3 $mntroot/1
	err_check "mount ${loopd}p3 failed."

	#remove cowfiles
	rm $mntroot/1/xiange/cow-*
	
	showinfo "unmount $mntroot/1..."
	umount $mntroot/1
	err_check "unmount grub failed."
	devname="${loopd}p3"
}

xg_ckddimg()
{
	if [ -n "$1" ]; then
		#$1 can be a vfat device, such as /dev/sdc1
		xg_usedisk "$1"
	elif [ -f $imgfile ]; then
		showinfo "$imgfile found, use it directly."
		xg_useoldimg
	else
		xg_mkddimg
	fi
}

#
# init here, $1 can be device name
#

devname="/dev/loop1p3"

xg_prepare
xg_ckddimg "$1"
xg_cksquash
xg_mount_squash

eval squash_arch=$(cat $oldroot/etc/os-release | grep -o "VERSION=[^ ]*" | sed "s/VERSION=//g")

if [ -z "$squash_arch" ]; then
	showFailed "os-release parse failed in old root"
fi

showinfo "squasf_filename=$squash_arch"


outputf=$newroot/boot/grub/grub.cfg
mkdir -p /boot/grub

gpkg -info > /tmp/gpkginfo
. /tmp/gpkginfo

newid=$(blkid -s UUID -o value $devname 2>/dev/null)
devindex=1

if [ -z "$newid" ]; then
	showFailed "UUID check failed."
	exit 2
fi

if [ -z "$XGB_ARCH" ]; then
	showFailed "arch check failed."
	exit 4
fi


xg_mkgrubcfg_head $outputf $newid


showinfo "checking kernel ..."
for i in $oldroot/boot/vmlinuz-*; 
do
	i=$(basename $i)
	kernelv=${i#vmlinuz-}
	showinfo "found $i, kerver version: $kernelv"
	xg_do_kernel $kernelv
	err_check "do kernel failed"
done

#squshfs.img
showinfo "copy squashfs image.."
mkdir -p $newroot/xiange
cp -a /root/xiange-sqroot $newroot/xiange/xiange-sqroot-${squash_arch}
err_check "copy /root/xiange-sqroot to $newroot failed."

#cow.img 
showinfo "calculating cow size..."
sizeline=$(df -m $devname | grep "/dev")
echo "$sizeline"
size=$(echo $sizeline | cut -d " " -f 4)
showinfo "Total: $size MB"

if [ $size -lt 15 ]; then
	showFailed "size is too small: $size"
elif [ $size -gt 1000 ]; then
	size=1000
else
	size=$(($size-10))
fi

showinfo "creating cow image size $size MB.."
dd if=/dev/zero of=$newroot/xiange/cow-${squash_arch}.out count=$((2*1024*$size))
err_check "create $newroot/cow.out failed."

#unmount newroot
showinfo "unmounting $newroot..."
umount $newroot
err_check "unmount $newroot failed."

showinfo "unmounting $oldroot..."
umount $oldroot
err_check "unmount $oldroot failed."

losetup -d ${loopd}
losetup -d ${lpxg}
err_check "remove /dev/loop2 failed."

showinfo "unmounting $mntroot/0.."
umount $mntroot/0
err_check "unmount $mntroot/0 failed."

rm -rf $mntroot

showOK "done"

