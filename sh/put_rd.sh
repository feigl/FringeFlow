#!/bin/bash

# put files on research drive
# 20231013 Kurt Feigl
# https://chtc.cs.wisc.edu/uw-research-computing/transfer-data-researchdrive

# set -v # verbose
# set -x # for debugging
# set -e # exit on error
# set -u # error on unset variables
bname=`basename $0`

Help()
{
   # Display Help
    echo "$bname will transfer from local machine to UW Research Drive"
    echo "usage:   $bname source target"
        exit -1
  }

############################################################
############################################################
# Main program                                             #
############################################################
############################################################
if [[  ( "$#" -eq 2)  ]]; then
    source=$1
    target=$2
else
    echo ERROR: need 2 arguments
    Help
    exit -1
fi


# test existence of variables
#https://unix.stackexchange.com/questions/212183/how-do-i-check-if-a-variable-exists-in-an-if-statement

if [[ -n ${source+set} ]]; then
    echo source is $source
else
    echo "Need name of source directory"
    Help
    exit -1
fi

# test existence of source
if [[ ! -d "$source" ]]; then
    echo "ERROR: source directory does not exist."
    exit -1
fi

if [[ -n ${target+set} ]]; then
    echo target is $target
else
    echo "Need name of target directory on smb://research.drive.wisc.edu/feigl"
    Help
    exit -1
fi

# get architecture of machine
arch=$(uname -a | awk '{print $15}')
echo arch is $arch


if [[ $arch == x86_64* ]]; then
    ## linux box, use smbclient
    # make directory named .cache to avoid error messages like the following
    #   gencache_init: Failed to create directory: /home/feigl/.cache/samba - No such file or directory
    if [[ ! -d .cache ]]; then
        mkdir .cache
    fi

    # start smblient and log results
    smbclient -q -k //research.drive.wisc.edu/feigl << EOF 2>&1 | tee $bname.log
    prompt
    recurse
    mput $source $target
EOF

elif [[ $arch == arm64 ]]; then
    # Mac with M1 chip, use finder
    if [[ -d /Volumes/feigl/$target ]]; then
        cp -vr $source /Volumes/feigl/$target
    else
        echo "ERROR: cannot find Research Drive mounted on mac finder as /Volumes/feigl/$target"
        echo 'consider using Finder with "GO, Connect to server" smb://research.drive.wisc.edu/feigl'
        exit -1
    fi
else
    echo "ERROR: unknown arch $arch"
    exit -1
fi

exit 0


