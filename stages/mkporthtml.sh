#!/bin/bash
#make a html file for all gentoo softwares

classcnt=0
softcnt=0
curclasscnt=0


#make softwares, $1 is software name, $2 is write file, $3 is index, $4:class
do_make_software()
{
	local cfg
	local classname

	classname=$3

	pushd "$1" > /dev/null

	#get description
	cfg=`ls *.ebuild | tail -n 1`

	if [ "cfg" != "" ]; then
		curclasscnt=$(($curclasscnt+1))
		softcnt=$(($softcnt+1))

		. $cfg 2>/dev/null

		#echo -e "$2\t $1\t\t $DESCRIPTION"

		echo '<tr>' >> $2
		echo "<td>$curclasscnt</td>" >> $2
		echo '<td><img src="icons/cgi.jpeg"></td>' >> $2
		echo "<td><a href=gentoo_read.cgi?@@$classname@@$1@@$cfg>$1</a></td>" >> $2
		#description
		echo "<td><a href=$HOMEPAGE>$DESCRIPTION</a></td>" >> $2
		echo '</tr>' >> $2
	fi
	
	

	popd > /dev/null
}


classd="/srv/www/htdocs/gentoo"
#make all class, $1 is class directory name, $2 is write file name, $3 is index
do_make_class()
{
	local j
	local classf
	local index
	local classname

	classname="$1"

	echo 
	echo "------------------------------------------"
	echo "$classcnt making Class: $1"

	index=$2

	classf=$classd/$1.html
	echo "<table border=1>" > $classf 
	if [ "$?" != "0" ]; then
		echo "No Write Access: $classf"
		return 1
	fi


	echo "<caption>类别 $1</caption>" >> $classf 
	echo "<tr> <td>序号</td> <td>图标</td><td>软件名</td><td>描述</td>  </tr>" >> $classf



	curclasscnt=0
	pushd "$1" > /dev/null
	for j in `ls 2>/dev/null`; 
	do
		if [ -d $j ]; then
			do_make_software $j $classf "$classname"
		fi
	done

	echo
	echo "done, count: $curclasscnt", totalcnt: $softcnt

	if [ "$curclasscnt" != "0" ]; then

		#write to index
		#echo "writing to $index.." 

		classcnt=$(($classcnt+1))

		echo '<tr>' >> $index
		echo "<td>$classcnt</td>" >> $index
		echo '<td><img src="icons/cgi.jpeg"></td>' >> $index
		echo "<td><a href=gentoo_soft.cgi?$1>$1</a></td>" >> $index
		echo "<td>$curclasscnt</td>" >> $index
		echo '</tr>' >> $index


	fi

	popd > /dev/null
}

index="/srv/www/htdocs/gentoo/index.html"


echo "<table border=1>" > $index 
if [ "$?" != "0" ]; then
	echo "No Write Access: $index"
	return 1
fi


echo "<caption>软件类别列表</caption>" >> $index 
echo "<tr> <td>序号</td> <td>图标</td><td>类别</td><td>软件数目</td>  </tr>" >> $index

#do_make_class xfce-base "$index" 1
#echo "</table>" >> $index
#echo "<caption>类别: $classcnt, 软件总数: $softcnt</caption>" >> $index 
#exit 0

allclass=`ls 2>/dev/null`

cnt=0
for i in $allclass ;
do
	if [ -d $i ]; then
		cnt=$(($cnt+1))
	fi
done

echo "*********** Total class $cnt ***************"
echo 


for i in $allclass ;
do
	if [ -d $i ]; then
		do_make_class "$i" "$index" 
	fi
		
done

echo "</table>" >> $index
echo "<caption>类别: $classcnt, 软件总数: $softcnt</caption>" >> $index 
