#!/bin/bash -e
## 2021/06/07 Kurt Feigl

## SSARA for downloading data

if [ "$#" -eq 5 ]; then
    action='print'
elif [ "$#" -eq 6 ]; then
    action=$6
else
    bname=`basename $0`
    echo "$bname will calculate an interferometric pair "
    echo "usage:   $bname SAT TRK SITE reference_YYYYMMDD secondary_YYYYMMDD"
    echo "example: $bname S1 144 SANEM 20190110  20190122"
    exit -1
fi

export SSARA_HOME=$( dirname $(which ssara_federated_query.py ) )
echo "Checking for file named password_config.py in ${SSARA_HOME}"
if [[ -f ${SSARA_HOME}/password_config.py ]]; then
    ls -l ${SSARA_HOME}/password_config.py
else
   echo "ERROR: could not find ile named password_config.py in ${SSARA_HOME}"
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
timetag=`date +"%Y%m%dT%H%M%S"`
echo timetag is ${timetag}

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


echo "Starting query to print."
ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=${trk} \
--start=${YYYYMMDD1} --end=${YYYYMMDD2} \
--intersectsWith="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))" \
--print | tee ssara_${timetag}.csv

if [[ ! ${action} == "print" ]]; then

    # make KML file
    echo "Making KML file"
    #ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=${YYYYMMDD1} --end="${YYYYMMDD2} 23:59:59"  --kml
    ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=${trk} \
    --start=${YYYYMMDD1} --end=${YYYYMMDD2} \
    --intersectsWith="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))" \
    --kml | tee ssara_${timetag}.kml


    # download data
    # switch for ICSE --start 2018-10-01 --stop 2018-11-15
    #ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=${YYYYMMDD1} --end="${YYYYMMDD2} 23:59:59" --download

    echo "Downloading data"
    ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=${trk} \
    --start=${YYYYMMDD1} --end=${YYYYMMDD2} \
    --intersectsWith="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))" \
    --download | tee -a ssara_$timetag}.log

fi
  