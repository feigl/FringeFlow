#!/bin/bash -e
# make geocoded images of all interferograms

if [[ ("$#" -ne 2) ]]; then
    bname=`basename $0`
    echo "$bname will create geocoded jpg and kml files for all interferometric pairs matching the template"
    echo "usage:   $bname SITE fname"
    echo "example: $bname SANEM filt_fine.int "
    echo "example: $bname SANEM filt_fine.unw "
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
    geocode_interferogram.sh $sit $fname2
done




