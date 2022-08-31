#!/bin/bash 

# untar a list of tar balls
#2022/06/09 Kurt Feigl

if [ "$#" -eq 0 ]; then
    bname=`basename $0`
    echo "$bname will extract files from tar files "
    echo "usage:   $bname In20220507_20220518.tgz"
    echo "example: $bname In*.tgz"

    exit -1
else
    for fname1 in "$@"; do
        echo fname1 is $fname1
        bname=`basename $fname` 
        bname=${bname%.*}
        echo bname is $bname
        if [ -f $fname ]; then
            tar -xzvf ${fname1}
        fi
    done
    exit 0
fi
