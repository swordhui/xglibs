#!/bin/sh

# file system check tool
# check what's inside a directory

if [ -f /tmp/cka ]; then
	echo "checking file extensions.."
else
	echo "/tmp/cka is not found."
	exit 1
fi

#generate file list
unset allfiles
unset allextcnts
unset allexts
declare -a allfiles
declare -A allexts
declare -A allextcnts

mapfile allfiles < /tmp/cka

filecnt=${#allfiles[*]}

echo "$filecnt files found. parsing..."

echo ""
printf "%-10s of %-10s" 0 $filecnt 
j=0


rm /tmp/nullname 2>/dev/null
touch /tmp/nullname

for ((i=0; i<$filecnt; i++))
do
	filesize=${allfiles[i]%%,*}
	filesize=${filesize:=0}
	fname=${allfiles[i]##*/}
	ext=${fname##*.}
#	if [ "$fname" == "$ext" ]; then
#		ext="NULL"
#		echo "$filesize $fname" >> /tmp/nullname
#	else
#		ext=${ext%?}
#	fi
	ext=${ext%?}
	allexts["$ext"]=$((${allexts["$ext"]}+$filesize))
	allextcnts["$ext"]=$((${allextcnts["$ext"]}+1))
	#echo $i  \'$ext\' ${allexts["$ext"]} ${allextcnts["$ext"]}
	j=$((${j}+1))

	if [ "$j" == "1501" ]; then
		printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
		printf "%-10s of %-10s" $i $filecnt 
		j=0
	fi
done


rm /tmp/ckb 2>/dev/null
touch /tmp/ckb

printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
printf "%-10s of %-10s" $i $filecnt 

echo ""
echo "Done. sorting (size in MB,ext,count).."
for k in ${!allexts[*]}
do
	fsize=${allexts["$k"]}
	if [ -n "$fsize" ]; then
		fsize="$(($fsize/1000000)) MB"
	else
		fsize="0 MB"
	fi
	
	printf "%-10s%-10s%s\n" "$fsize" ${allextcnts["$k"]} "$k"  >> /tmp/ckb
done

cat /tmp/ckb | sort -n | nl | tee /tm/result
rm /tmp/ckb

