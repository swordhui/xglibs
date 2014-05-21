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




#
# deal with kernel, $1 is version
#
xg_do_kernel()
{
	#copy kernel
	cp -a $oldroot/boot/vmlinuz-$1 $newroot/boot
	err_check "copy $oldroot/boot/vmlinuz-$1 faile.d"

	cp -a $oldroot/boot/config-$1 $newroot/boot
	err_check "copy $oldroot/boot/config-$1 faile.d"

	#get initrams
	rm -rf /tmp/xgmnt/init
	mkdir /tmp/xgmnt/init
	cd /tmp/xgmnt/init
	err_check "enter /tmp/xgmnt/init failed."

	gunzip -c $oldroot/boot/initramfs-1.0.img.gz | cpio -i 
	err_check "unzip $oldroot/boot/initramfs-1.0.img.gz failed."

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
		
	#copy file in list
	for i in $XGLIST;
	do
		basen=$(dirname $i)
		mkdir -p $newroot$basen
		showinfo "copying $oldroot$i..."
		cp -a $oldroot$i /tmp/xgmnt/init$basen/
		err_check "cp $oldroot$i failed."
	done
}

#if [ -f "/root/xg64.img" ]; then
#	ls -l /root/xg64.img
#else
#	showFailed "No Xg64.img found."
#	exit 1
#fi
#
#showinfo "copying ..."
#mkdir -p /tmp/squashroot
#cp -a /root/xg64.img /tmp/squashroot/
#err_check "copy failed."
#
#showinfo "making squash fs.."
#
#cd /tmp
#mksquashfs squashroot xiange-sqroot
#err_check "make squash fs failed."
#
#rm -rf squashroot
#err_check "rm temperory file failed."

##mount it
#modprobe loop
#err_check "load loop failed."
#modprobe squashfs
#err_check "load squashfs failed."
#
#mkdir -p /tmp/xgmnt/0
#mkdir -p /tmp/xgmnt/1
#mkdir -p /tmp/xgmnt/2
#
#mount xiange-sqroot /tmp/xgmnt/0 -o loop 
#err_check "mount xiange-sqroot to /tmp/xgmnt/0 failed."
#
#imgfile="/root/xg_sqh.img"
#disksize=4000000000
#blocks=$(($disksize/512))
#
#showinfo "create image file $imgfile, size $(($disksize/1000000000)) GB.."
#dd if=/dev/zero of=$imgfile count=$blocks
#err_check "failed."
#
#showinfo "mount to a image.."
#losetup -P /dev/loop1 $imgfile
#err_check "setup $imgfile to /dev/loop1 faled."
#
#showinfo "create partitions..."
#cfdisk /dev/loop1
#err_check "create partition failed."

#showinfo "formating..."
#mkfs.ext4 -v /dev/loop1p1
#err_check "format /dev/loop0p1 failed."
#
#
#showinfo "mounting..."
#mount /dev/loop1p1 /tmp/xgmnt/1
#err_check "mount loop0p1 failed."
#
#showinfo "installing grub2..."
#grub-install --modules=part_msdos --root-directory=/tmp/xgmnt/1 /dev/loop1
#err_check "install grub failed."

##setup root
#showinfo "mount xiange root.."
#losetup -P /dev/loop2 /tmp/xgmnt/0/xg64.img
#err_check "setup xg64 to /dev/loop2 faled."
#
#mount /dev/loop2p1 /tmp/xgmnt/2
#err_check "mount to /mnt/xgmnt/2 faled."

#kernel

oldroot=/tmp/xgmnt/2
newroot=/tmp/xgmnt/1

showinfo "checking kernel ..."
for i in $oldroot/boot/vmlinuz-*; 
do
	i=$(basename $i)
	kernelv=${i#vmlinuz-}
	showinfo found $i, kerver version: $kernelv
	xg_do_kernel $kernelv
done



#initramfs

#grub.cfg

#squshfs.img

#cow

#unmount

showOK "done"

