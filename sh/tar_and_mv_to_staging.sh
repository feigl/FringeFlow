#!/bin/bash
# make a tar file and place it on /staging 
# 2023/10/19 Kurt Feigl

set -v # verbose
set -x # for debugging
set -e # exit on error
set -u # error on unset variables

bname=`basename $0`

Help()
{
   # Display Help
    echo "$bname make a tar file and place it on /staging "
    echo "usage:   $bname source_folder_name target_folder"
    echo "example:"
    echo "         $bname mydir /staging/groups/geoscience/insar"
    echo '         will make a compressed tarfile named mydir.tgz and move it to /staging/groups/geoscience/insar/mydir.tgz'

    exit -1
}

if [[  ( "$#" -eq 2)  ]]; then
    SOURCEDIR=$1
    TARGETDIR=$2 
    echo SOURCEDIR is $SOURCEDIR 
    echo TARGETDIR is $TARGETDIR
else
    Help
fi

if [[ ! -f tarlist.txt ]]; then
    # make a list of files to include in tarball
    touch tarlist.txt
fi

# add items to tarlist
if [[ -d  $SOURCEDIR ]]; then 
    echo "$SOURCEDIR" >> tarlist.txt
fi
if [[ -f _condor_stdout ]]; then 
    echo _condor_stdout >> tarlist.txt
fi
if [[ -f _condor_stdout ]]; 
    then echo _condor_stdout >> tarlist.txt
fi
find . -type f -name "*.log" >> tarlist.txt
find . -type f -name "*.out" >> tarlist.txt
find . -type f -name "*.err" >> tarlist.txt
# cat tarlist.txt | sort -n | unique > tmp.lst
# mv -f tmp.lst tarlist.txt
cat tarlist.txt

# run the tar process to make tar ball
tar -czf "$SOURCEDIR.tgz" `cat tarlist.txt`


if [[ -f ${SOURCEDIR}.tgz ]]; then    
    echo made compressed tar file named ${SOURCEDIR}.tgz 
    ls -lh ${SOURCEDIR}.tgz 
else
    exit -1
fi

if [[  -d /staging/groups/geoscience ]]; then
    if [[  ! -d $TARGETDIR ]]; then
        mkdir -p $TARGETDIR
    fi
    mv -fv $SOURCEDIR.tgz $TARGETDIR
else
    echo keeping everything
fi

echo $bname ended normally
exit 0

