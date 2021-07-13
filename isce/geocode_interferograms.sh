#!/bin/bash -e
# make geocoded images of all interferograms

if [[ ("$#" -ne 1) ]]; then
    bname=`basename $0`
    echo "$bname will create geocoded jpg and kml files for all interferometric pairs"
    echo "usage:   $bname SITE reference_YYYYMMDD secondary_YYYYMMDD"
    echo "example: $bname SANEM 20190110 20190122"
    exit -1
fi

export sit=$1

echo sit is $sit

FILES="./merged/interferograms/*/filt_fine.int"

for f in $FILES
do
  #echo "Processing $f file..."
  pair=`echo $f | awk -F'/' '{print $4}'`
  #echo "pair is $pair"
  t0=`echo $pair | awk -F_ '{print $1}'`
  #echo "first acquisition date t0 is $t0"
  t1=`echo $pair | awk -F_ '{print $2}'`
  #echo "second acquisition date t1 is $t1"

  geocode_interferogram.sh $sit $t0 $t1
done






