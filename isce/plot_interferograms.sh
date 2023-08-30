#!/bin/bash -vx
# plot interferograms

if [[ ("$#" -ne 2) ]]; then
    bname=`basename $0`
    echo "$bname will create jpg and kml files for an interferometric pair"
    echo "usage:   $bname SITE fname"
    echo "example: $bname SANEM filt_fine.int "
    echo "example: $bname SANEM filt_fine.unw "
    echo "example: $bname SANEM filt_fine.int.geo"
    exit -1
fi

echo "Starting script named $0"
echo PWD is ${PWD}
echo HOME is ${HOME} 

export sit=$1
export fname1=$2

echo sit is $sit
echo fname1 is $fname1
for fname2 in `ls -1 merged/interferograms/*/${fname1}` ; do
    plot_interferogram.sh $sit $fname2
done


#find . -name "*.jpg" -ls
# tar -czvf JPGS.tgz `find . -name "*.jpg"`
