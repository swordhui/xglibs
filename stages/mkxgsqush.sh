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

mntroot=/tmp/xgmnt.$$
oldroot=$mntroot/2
newroot=$mntroot/1



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
# $7 will be added to kernel command line 
# $8 is Title
xg_mkgrubcfg_item()
{
	echo -e "menuentry '$8' {" >> $5
	echo -e "\tinsmod gzio" >> $5
	echo -e "\tinsmod part_msdos" >> $5
	echo -e "\tinsmod ext2" >> $5
	echo -e "\tset root='hd0,msdos$3'" >> $5
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
	oldinitname=$(ls $oldroot/boot/initramfs-*.img.gz) 
	for i in $oldinitname
	do
		initnames[$initcnt]="$i"
		initcnt=$(($initcnt+1))
	done
		
	gunzip -c ${initnames[0]} | cpio -i 
	err_check "unzip initramfs ${initnames[0]} failed."

	XGLIST="/lib/libdevmapper.so.1.02 
		/lib/libc.so.6
		/lib/libc-2.19.so 
		/lib/libpthread.so.0 
		/lib/libpthread-2.19.so 
		/lib/ld-2.19.so 
		/lib/ld-linux-x86-64.so.2 
		/sbin/dmsetup
		/lib/modules/$1/kernel/drivers/block/loop.ko
		/lib/modules/$1/kernel/fs/squashfs/squashfs.ko
		/lib/modules/$1/kernel/drivers/md/dm-snapshot.ko
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

	#make depfiles
	mount -t proc none $mntroot/init/proc
	mount -t sysfs none $mntroot/init/sys
	mount --bind /dev $mntroot/init/dev
	chroot $mntroot/init /sbin/depmod $1
	err_check "dempode failed."

	#check dmsetup
	chroot $mntroot/init /sbin/dmsetup --help 
	err_check "dempode failed."

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
			rm -f "/root/xiange-sqroot"
			xg_mksquash
		fi
	else
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
	mount /root/xiange-sqroot $mntroot/0 -o loop 
	err_check "mount xiange-sqroot to $mntroot/0 failed."
	
	showinfo "mount xiange root.."
	losetup -P /dev/loop2 $mntroot/0/xg64.img
	err_check "setup xg64 to /dev/loop2 faled."

	showinfo "mounting new root..."
	mount /dev/loop1p1 $mntroot/1
	err_check "mount loop1p1 failed."
	
	mount /dev/loop2p1 $mntroot/2
	err_check "mount to /mnt/xgmnt/2 faled."
}

imgfile="/root/xg_sqh.img"

xg_mkddimg()
{
	disksize=2000000000
	blocks=$(($disksize/512))
	
	showinfo "create image file $imgfile, size $(($disksize/1000000000)) GB.."
	dd if=/dev/zero of=$imgfile count=$blocks
	err_check "failed."
	
	showinfo "mount to a image.."
	losetup -P /dev/loop1 $imgfile
	err_check "setup $imgfile to /dev/loop1 faled."
	
	showinfo "create partitions..."
	cfdisk /dev/loop1
	err_check "create partition failed."
	
	showinfo "formating..."
	mkfs.ext4 -v /dev/loop1p1
	err_check "format /dev/loop1p1 failed."
	
	
	showinfo "mounting..."
	mount /dev/loop1p1 $mntroot/1
	err_check "mount loop1p1 failed."
	
	showinfo "installing grub2..."
	grub-install --modules=part_msdos --root-directory=$mntroot/1 /dev/loop1
	err_check "install grub failed."

	showinfo "unmount $mntroot/1..."
	umount $mntroot/1
	err_check "unmount grub failed."
}


xg_useoldimg()
{
	showinfo "mount to a image.."
	losetup -P /dev/loop1 $imgfile
	err_check "setup $imgfile to /dev/loop1 faled."

	showinfo "mounting..."
	mount /dev/loop1p1 $mntroot/1
	err_check "mount loop1p1 failed."

	#resize cowfiles
	for i in $mntroot/1/xiange/cow-*; 
	do
		rm -f $i
		err_check "remove $i failed."
		touch $i
		err_check "re-create $i failed."
	done
	
	showinfo "unmount $mntroot/1..."
	umount $mntroot/1
	err_check "unmount grub failed."
}

xg_ckddimg()
{
	if [ -f $imgfile ]; then
		showinfo "$imgfile found, use it directly."
		xg_useoldimg
	else
		xg_mkddimg
	fi
}

#
# init here
#

xg_prepare
xg_ckddimg
xg_cksquash
xg_mount_squash


outputf=$newroot/boot/grub/grub.cfg
mkdir -p /boot/grub

gpkg -info > /tmp/gpkginfo
. /tmp/gpkginfo

devname="/dev/loop1p1"
newid=$(blkid -o value $devname 2>/dev/null | head -n 1)
devindex=1

if [ -z "$newid" ]; then
	showFailed "UUID check failed."
	exit 2
fi

if [ -z "$XGB_ARCH" ]; then
	showFailed "arch check failed."
	exit 4
fi


xg_mkgrubcfg_head $outputf


showinfo "checking kernel ..."
for i in $oldroot/boot/vmlinuz-*; 
do
	i=$(basename $i)
	kernelv=${i#vmlinuz-}
	showinfo "found $i, kerver version: $kernelv"
	xg_do_kernel $kernelv
done

#squshfs.img
showinfo "copy squashfs image.."
mkdir -p $newroot/xiange
cp -a /root/xiange-sqroot $newroot/xiange/xiange-sqroot-$XGB_ARCH
err_check "copy /root/xiange-sqroot to $newroot failed."

#cow.img 
sizeline=$(df -m /dev/loop1p1 | grep "^/dev")
size=$(echo $sizeline | cut -d " " -f 4)
size=$(($size-10))
showinfo "creating cow image size $size MB.."
dd if=/dev/zero of=$newroot/xiange/cow-$XGB_ARCH.out count=$((2*1024*$size))
err_check "create $newroot/cow.out failed."

#unmount newroot
showinfo "unmounting $newroot..."
umount $newroot
err_check "unmount $newroot failed."

showinfo "unmounting $oldroot..."
umount $oldroot
err_check "unmount $oldroot failed."

losetup -d /dev/loop1
err_check "remove /dev/loop1 failed."
losetup -d /dev/loop2
err_check "remove /dev/loop2 failed."

showinfo "unmounting $mntroot/0.."
umount $mntroot/0
err_check "unmount $mntroot/0 failed."

rm -rf $mntroot

showOK "done"

