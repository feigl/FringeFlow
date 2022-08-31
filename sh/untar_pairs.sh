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
        #bname=`basename $fname1` 
        # remove extension
        fname0=${fname1%.*}
        echo fname0 is $fname0
        # set target directory     
        if [[ -f $fname1 ]]; then
            if [[ -d $fname0 ]]; then  
                ddir=$fname0
            elif [[ -f $fname0 ]]; then
                echo "WARNING file named $fname0 exists. Renaming it."
                \mv -fv $fname0 ${fname0}.back
                ddir=$fname0
            elif [[ "$fname0" == *"In"* ]];then
                ddir=$PWD
            else
                ddir=$fname0
            fi
            echo ddir is $ddir
            if [[ ! -d ${ddir} ]]; then
                mkdir $ddir
            fi
            tar -C ${ddir} -xzvf ${fname1}
        fi
    done
    exit 0
fi
