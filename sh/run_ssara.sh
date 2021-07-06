#!/bin/bash -vex
## 2021/06/07 Kurt Feigl

## SSARA for downloading data

if [ "$#" -ne 5 ]; then
    bname=`basename $0`
    echo "$bname will calculate an interferometric pair "
    echo "usage:   $bname SAT TRK SITE reference_YYYYMMDD secondary_YYYYMMDD"
    echo "example: $bname S1 144 SANEM 20190110  20190122"

    exit -1
fi

#export YYYYMMDD1="2019-10-02"
#export YYYYMMDD2="2019-11-16"

echo "Starting script named $0"
echo "Arguments are $1 $2 $3 $4 $5"
echo PWD is ${PWD}
echo HOME is ${HOME} 

# export t0=20190110
# export t1=20190122
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


# get working version of ssara client
#cp -rp /home/feigl/SSARA-master $HOME
export PYTHONPATH=$HOME/ssara_client

# export YYYYMMDD1="2018-01-01"
# export YYYYMMDD2="2021-12-31"

export YYYYMMDD1=`echo $t0 |  awk '{ printf("%4d-%02d-%02d\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'`
export YYYYMMDD2=`echo $t1 |  awk '{ printf("%4d-%02d-%02dT23:59:59.999999\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'`

echo YYYYMMDD1 is ${YYYYMMDD1}
echo YYYYMMDD2 is ${YYYYMMDD2}

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

# ls -la password_config.py
# ls -la $HOME/ssara_client/password_config.py

# make list
#ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=${YYYYMMDD1} --end="${YYYYMMDD2} 23:59:59" --print | tee ssara.lst

#  W =      -119.4600000000 
#  E =      -119.3750000000
#  S =        40.3480000000
#  N =        40.4490000000
#https://www.unavco.org/data/sar/sar_api/sar_api.html
#intersectsWith — accepts a list of polygons, line segments ("linestring"), or a point defined in multipoint 2-D Well-Known Text (WKT); 
#currently each polygon must be explicitly closed, i.e. the first vertex and the last vertex of each listed polygon must be identical; 
#coordinate pairs for each vertex are in decimal degrees of longitude followed by decimal degree of latitude:
#https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry
#The OGC standard definition requires a polygon to be topologically closed. It also states that if the exterior linear ring of a polygon is defined in a counterclockwise direction

#--intersectsWith='POLYGON((-119.4600000000 40.3480000000, -119.3750000000 40.3480000000, -119.3750000000 40.4490000000, -119.4600000000 40.4490000000, -119.4600000000 40.3480000000))' \

ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=${trk} \
--start=${YYYYMMDD1} --end=${YYYYMMDD2} \
--intersectsWith="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))" \
--print | tee ssara.lst



# make KML file
#ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=${YYYYMMDD1} --end="${YYYYMMDD2} 23:59:59"  --kml
ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=${trk} \
--start=${YYYYMMDD1} --end=${YYYYMMDD2} \
--intersectsWith="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))" \
--kml | tee ssara.kml


# download data
# end on the 19th, to get the 18th
# python -m ssara_federated_query --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=2018-10-06 --end=2018-10-19 --print
# python -m ssara_federated_query --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=2018-10-06 --end=2018-10-19 --download
#python -m ssara_federated_query --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=2019-10-06 --end=2018-10-19  --s1orbits --download
#python -m ssara_federated_query --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=2018-10-06 --end=2018-11-16 --download
# switch for ICSE --start 2018-10-01 --stop 2018-11-15
#ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=${YYYYMMDD1} --end="${YYYYMMDD2} 23:59:59" --download

ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=${trk} \
--start=${YYYYMMDD1} --end=${YYYYMMDD2} \
--intersectsWith="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))" \
--download | tee -a ssara.log


   