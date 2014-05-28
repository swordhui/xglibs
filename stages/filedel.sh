#!/bin/sh

# file system check tool
# check what's inside a directory

#generate file list

if [ -z "$1" ]; then
	echo "No ext specified. filedel.sh exe"
	exit 1
fi
echo "deleting *.$1..."
find -type f -iname "*.$1" -exec rm '{}' ';'
echo "done"
