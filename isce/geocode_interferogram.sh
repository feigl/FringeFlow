#!/bin/bash -veux
# geocode 1 interferometric pair

if [[ ("$#" -ne 2) ]]; then
    bname=`basename $0`
    echo "$bname will create geocoded jpg and kml files for an interferometric pair"
    echo "usage:   $bname SITE fname"
    echo "example: $bname SANEM ./merged/interferograms/20220331_20220412/filt_fine.int"
    exit -1
fi

echo "Starting script named $0"
echo PWD is ${PWD}
echo HOME is ${HOME} 

export sit=$1
export fname=$2

echo sit is $sit
echo fname is $fname

bname1=`basename $fname`
echo bname1 is $bname1

dname1=`dirname $fname`
echo dname1 is $dname1

pairname=`basename $dname1`
echo pairname is $pairname

t0=`echo $pairname | awk -F_ '{print $1}'`
echo t0 is $t0

t1=`echo $pairname | awk -F_ '{print $2}'`
echo t1 is $t1

if [[ -f $fname ]]; then
    # get coordinates of bounding box
    get_site_dims.sh $sit -1 | tee tmp.wesn

    export LATMIN=`grep S tmp.wesn | awk '{print $3}'`
    export LATMAX=`grep N tmp.wesn | awk '{print $3}'`
    export LONMIN=`grep W tmp.wesn | awk '{print $3}'`
    export LONMAX=`grep E tmp.wesn | awk '{print $3}'`

    # get DEM
    export DEM=`ls *.wgs84 | tail -1`

    #geocodeIsce.py -f merged/interferograms/${t0}_${t1}/filt_fine.int -d $DEM -m ./reference -s ./secondarys/${t1}/ -a 2 -r 6 -b "$LATMIN $LATMAX $LONMIN $LONMAX" 
    geocodeIsce.py -f $fname -d $DEM -m ./reference -s ./secondarys/${t1}/ -a 2 -r 6 -b "$LATMIN $LATMAX $LONMIN $LONMAX" 
    

    # print wrapped image
    mdx.py ${fname}.geo -z -100 -wrap 6.28 -P 
    convert out.ppm ${fname}.geo.pha.jpg

    # make kml file
    mdx.py ${fname}.geo -wrap 6.28 -kml ${fname}.geo.kml

    # # make an amplitude image 
    export NSAMP=`grep rasterXSize $fname.geo.vrt | awk '{print substr($2,13)}' | sed 's/"//g'`
    echo "Number of samples NSAMP is $NSAMP"
    mdx -P ${fname}.geo -c8mag -s $NSAMP
    convert out.ppm ${fname}.geo.mag.jpg

    ls -ltr ${fname}*

fi

