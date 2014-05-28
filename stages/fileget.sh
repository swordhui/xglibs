#!/bin/sh

# file system check tool
# check what's inside a directory

#generate file list
echo "Generating file list..."
find -type f -exec stat -c "%s, %W, %Y, %i, %n" '{}' ';' | sort -n -r > /tmp/cka
echo "done, parsing file extensions.."
