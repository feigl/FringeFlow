#!/bin/bash -vx
# run ISCE inside container

export sat=$1
export trk=$2
export sit=$3
export t0=$4
export t1=$5

echo sat is $sat
echo trk is $trk
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

export POLYGON="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))"
echo POLYGON is $POLYGON

export BBOX="$LATMIN $LATMAX $LONMIN $LONMAX"
echo BBOX is $BBOX

export DEM=`ls *.wgs84 | tail -1`

#convert out.ppm merged/interferograms/20190110_20190122/filt_fine.dem.crop.jpg
#geocodeIsce.py -f merged/interferograms/${t0}_${t1}/filt_fine.int -d demLat_N40_N41_Lon_W120_W119.dem.wgs84 -m ./reference -s ./secondarys/${t1}/ -a 2 -r 6 -b '40.348 40.449 -119.46 -119.375' 
ls merged/SLC/${t1}/${t1}.slc.full > files.lst
geocodeIsce.py -f files.lst -d $DEM -m ./merged/geom_reference -s merged/SLC/${t1}/${t1}.slc.full -a 2 -r 6 -b "$LATMIN $LATMAX $LONMIN $LONMAX"

exit

mdx.py merged/SLC/${t1}/${t1}.slc.full.geo -z -100 -wrap 6.28 -P
convert out.ppm merged/SLC/${t1}/${t1}.slc.geo.jpg




