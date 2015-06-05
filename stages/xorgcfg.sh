#!/bin/sh

vgas=$(lspci | grep VGA)

echo "$vgas" > /tmp/xorgcfg.log

#check AMD/ATI

echo "$vgas" | grep "ATI" > /dev/null  2>&1
if [ "$?" == "0" ]; then
	echo "ATI found." >> /tmp/xorgcfg.log
	exit 1
fi

echo "$vgas" | grep "Intel" /dev/null 2>&1
if [ "$?" == "0" ]; then
	echo "Intel found." >> /tmp/xorgcfg.log
	exit 1
fi

echo "$vgas" | grep "Nvidia" /dev/null 2>&1
if [ "$?" == "0" ]; then
	echo "Nvidia found." >> /tmp/xorgcfg.log
	exit 1
fi

echo "Done." >> /tmp/xorgcfg.log








