#!/bin/sh

vgas=$(lspci | grep VGA)

echo "Xorg: $vgas" 


#clean all links

#check AMD/ATI
if [ -f /etc/X11/xorg.conf.d/20-ati.conf ]; 
	then rm /etc/X11/xorg.conf.d/20-ati.conf
fi

if [ -f /etc/X11/xorg.conf.d/20-intel.conf ]; 
	then rm /etc/X11/xorg.conf.d/20-intel.conf
fi

if [ -f /etc/X11/xorg.conf.d/20-nvidia.conf ]; 
	then rm /etc/X11/xorg.conf.d/20-nvidia.conf
fi



echo "$vgas" | grep "ATI" > /dev/null  2>&1
if [ "$?" == "0" ]; then
	echo "ATI found." 
	ln -sv samples/20-ati.conf.sample /etc/X11/xorg.conf.d/20-ati.conf
	exit 0
fi

echo "$vgas" | grep "Intel" /dev/null 2>&1
if [ "$?" == "0" ]; then
	echo "Intel found." 
	ln -sv samples/20-intel.conf.sample /etc/X11/xorg.conf.d/20-intel.conf
	exit 0
fi

echo "$vgas" | grep "Nvidia" /dev/null 2>&1
if [ "$?" == "0" ]; then
	echo "Nvidia found." 
	ln -sv samples/20-nvidia.conf.sample /etc/X11/xorg.conf.d/20-nvidia.conf
	exit 0
fi

echo "Done." 








