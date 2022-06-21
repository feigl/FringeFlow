#!/bin/bash 
if [[ ! $# -eq 3 ]] ; then
    bname=`basename ${0}`
    echo "${bname} copy files from the source to the targe"
    echo "Usage: $bname askja.ssec.wisc.edu /s12/batzli/plot_on_slot2 drhomaskd_utm.grd "
    echo "$bname remote_machine_name remote_directory_name remote_file_name"
    exit -1
 else
    machine=${1}
    dirname=${2}
    filname=${3}

    ssh $machine find $dirname -name $filname > files.lst
    files=`cat files.lst`
    for f in $files; do
        #echo "Processing $f file..."
        # take action on each file. $f store current file name
        dirname1=`ssh $machine dirname $f`
        dirname2=`ssh $machine basename $dirname1`
        #echo "dirname2 is $dirname2"
        mkdir -p $dirname2
        rsync -av $machine:$f $dirname2
    done
    exit 0
fi
