#!/bin/bash 
# make JPG files from interferogram

if [[ ("$#" -ne 3) ]]; then
    bname=`basename $0`
    echo "$bname will create geocoded jpg and kml files for an interferometric pair"
    echo "usage:   $bname SITE reference_YYYYMMDD secondary_YYYYMMDD"
    echo "example: $bname SANEM 20190110 20190122"
    exit -1
fi

echo "Starting script named $0"
echo PWD is ${PWD}
echo HOME is ${HOME} 

export sit=$1
export t0=$2
export t1=$3

echo sit is $sit
echo t0 is $t0
echo t1 is $t1

# configure environment 
source /opt/isce2/isce_env.sh
export PATH=/opt/isce2/src/isce2/contrib/stack/topsStack:$PATH

get_site_dims.sh $sit -1 | tee tmp.wesn
# export SIT=`echo $sit | tr '[:lower:]' '[:upper:]'`
# echo SIT is $SIT
#get_site_dims.sh $SIT -1 | tee tmp.wesn

export LATMIN=`grep S tmp.wesn | awk '{print $3}'`
export LATMAX=`grep N tmp.wesn | awk '{print $3}'`
export LONMIN=`grep W tmp.wesn | awk '{print $3}'`
export LONMAX=`grep E tmp.wesn | awk '{print $3}'`

# export POLYGON="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))"
# echo POLYGON is $POLYGON

# export BBOX="$LATMIN $LATMAX $LONMIN $LONMAX"
# echo BBOX is $BBOX

export DEM=`ls *.wgs84 | tail -1`

# print wrapped phase in radar coordinates
mdx.py merged/interferograms/${t0}_${t1}/filt_fine.int -z -100 -wrap 6.28 -P 
convert out.ppm merged/interferograms/${t0}_${t1}/filt.fine.pha.jpg

# print amplitude (magnitude) in radar coordinates
export NSAMP=`grep rasterXSize merged/interferograms/20180113_20180125/filt_fine.int.vrt | awk '{print substr($2,13)}' | sed 's/"//g'`
echo "Number of samples NSAMP is $NSAMP"
mdx -P merged/interferograms/${t0}_${t1}/filt_fine.int -c8mag -s $NSAMP
convert out.ppm merged/interferograms/${t0}_${t1}/filt.fine.mag.jpg

## geocode
# fails with following error
# ERROR 1: PROJ: proj_create_from_database: Open of /opt/conda/share/proj failed
#  Using Sinc interpolation
#  threads          12
#  Starting Acquisition time:    5158.8342579999999     
#  Stop Acquisition time:    5164.0348154389994     
#  Azimuth line spacing in secs:    2.0555562999999980E-003
#  Near Range in m:    799303.50597713701     
#  Far  Range in m:    817089.71272298857     
#  Range sample spacing in m:    2.3295621147153232     
#  Input Lines:         2531
#  Input Width:         7636
#  reading interferogram ...
#  Geocoded Lines:           531
#  Geocoded Samples:         835
#  Initializing Sinc Interpolator
#  geocoding on           12  threads...
#  Number of pixels with outside DEM:             0
#  Number of pixels outside the image:       419665
#  Number of pixels with valid data:              0
#  elapsed time =    1.66406250      seconds

#convert out.ppm merged/interferograms/20190110_20190122/filt_fine.dem.crop.jpg
#geocodeIsce.py -f merged/interferograms/${t0}_${t1}/filt_fine.int -d demLat_N40_N41_Lon_W120_W119.dem.wgs84 -m ./reference -s ./secondarys/${t1}/ -a 2 -r 6 -b '40.348 40.449 -119.46 -119.375' 
#geocodeIsce.py -f merged/interferograms/${t0}_${t1}/filt_fine.int -d $DEM -m ./reference -s ./secondarys/${t1}/ -a 2 -r 6 -b "$LATMIN $LATMAX $LONMIN $LONMAX"
#geocodeIsce.py -f merged/interferograms/${t0}_${t1}/filt_fine.int -d $DEM -m ./reference -s ./secondarys/${t1}/ -a 1 -r 1 -b "$LATMIN $LATMAX $LONMIN $LONMAX" 
#geocodeIsce.py -f merged/interferograms/${t0}_${t1}/filt_fine.int -d $DEM -m ./reference -s ./secondarys/${t1}/ -a 1 -r 1 -b "37. 39. -120. -118." 
#geocodeIsce.py -f merged/interferograms/${t0}_${t1}/filt_fine.int -d $DEM -m ./reference -s ./secondarys/${t1}/ -a 1 -r 1 -b "$LATMIN $LATMAX $LONMIN $LONMAX" 

# print wrapped image
# mdx.py merged/interferograms/${t0}_${t1}/filt_fine.int.geo -z -100 -wrap 6.28 -P 
# convert out.ppm merged/interferograms/${t0}_${t1}/filt.fine.geo.pha.jpg

# make kml file
#mdx.py merged/interferograms/${t0}_${t1}/filt_fine.int.geo -wrap 6.28 -kml merged/interferograms/${t0}_${t1}/filt_fine.int.pha.kml

# make an amplitude image 
# export NSAMP=`grep rasterXSize merged/interferograms/20180113_20180125/filt_fine.int.geo.vrt | awk '{print substr($2,13)}' | sed 's/"//g'`
# echo "Number of samples NSAMP is $NSAMP"
# mdx -P merged/interferograms/${t0}_${t1}/filt_fine.int.geo -c8mag -s $NSAMP
# convert out.ppm merged/interferograms/${t0}_${t1}/filt.fine.geo.mag.jpg

ls -ltr merged/interferograms/${t0}_${t1}

