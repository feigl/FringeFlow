#!/bin/bash 
# 2021/06/21 Kurt Feigl
# 2022/08/15 Kurt Feigl - make it work everywhere


## SSARA for downloading data

if [ "$#" -eq 5 ]; then
    action='print'
elif [ "$#" -eq 6 ]; then
    action=$6
else
    bname=`basename $0`
    echo "$bname will find SLC data using SSARA "
    echo "usage:   $bname SITELCELC  MISSION TRACK date_first date_last"
    echo "example: $bname SANEM S1        144  20190110  20190122"
    echo "example: $bname FORGE S1         20  20190101  20191231"
    exit -1
fi

## make a copy of the ssara client so that we can have permissions to set the password file
# 20220915 moved to setup_inside_container_maise.sh
# # required to download
# echo "Setting up local copy of SSARA client with credentials"
# \rm -rf ssara_client
# if [[ -d $HOME/ssara_client ]]; then
#     \cp -rf $HOME/ssara_client .
# elif [[ -d /home/ops/ssara_client/ ]]; then
#     \cp -rf /home/ops/ssara_client/ .
# fi
# if [[ -f $HOME/magic/password_config.py ]]; then
#     \cp -f $HOME/magic/password_config.py ssara_client/
# elif [[ -f /home/ops/magic/password_config.py ]]; then
#     \cp -f /home/ops/magic/password_config.py ssara_client/
# elif [[ -f ../magic/password_config.py ]]; then
#     \cp -f ../magic/password_config.py ssara_client/
# else
#     echo ERROR: cannot find password_config.py 
#     exit -1
# fi

# export PATH=${PATH}:${PWD}/ssara_client
# export PYTHONPATH=${PWD}/ssara_client:${PYTHONPATH}
# export SSARA_HOME=${PWD}

echo SSARA_HOME is $SSARA_HOME

echo "Starting script named $0"
echo "Arguments are $1 $2 $3 $4 $5"
echo PWD is ${PWD}
echo HOME is ${HOME} 

# export YYYYMMDD1=20190110
# export YYYYMMDD2=20190122
export SITELC=`echo $1 | awk '{print tolower($1)}'`
export SITEUC=`echo $1 | awk '{print toupper($1)}'`
export MISSION=$2
export TRACK=$3
export YYYYMMDD1=$4
export YYYYMMDD2=$5

echo MISSION is $MISSION
echo TRACK is $TRACK
echo SITELC is $SITELC
echo YYYYMMDD1 is $YYYYMMDD1
echo YYYYMMDD2 is $YYYYMMDD2
timetag=`date +"%Y%m%dT%H%M%S"`
echo timetag is ${timetag}

# make dates with hyphens
export date_first=`echo $YYYYMMDD1 |  awk '{ printf("%4d-%02d-%02d\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'`
export date_last=` echo $YYYYMMDD2 |  awk '{ printf("%4d-%02d-%02dT23:59:59.999999\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'`

echo date_first is ${date_first}
echo date_last is ${date_last}

# 2022/08/15 finally repair above to read as below
export LATMIN=$(get_site_dims.sh ${SITELC} S)
export LATMAX=$(get_site_dims.sh ${SITELC} N)
export LONMIN=$(get_site_dims.sh ${SITELC} W)
export LONMAX=$(get_site_dims.sh ${SITELC} E)


export POLYGON="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))"
echo POLYGON is $POLYGON

echo "Starting query to print."
ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=${TRACK} \
--start=${date_first} --end=${date_last} \
--intersectsWith="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))" \
--print | tee ssara_${timetag}.log

if [[ ! ${action} == "print" ]]; then

    # make KML file
    echo "Making KML file"
    #ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=${date_first} --end="${date_last} 23:59:59"  --kml
    ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=${TRACK} \
    --start=${date_first} --end=${date_last} \
    --intersectsWith="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))" \
    --kml | tee -a ssara_${timetag}.log


    # download data  # requires keys
    # switch for ICSE --start 2018-10-01 --stop 2018-11-15
    #ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=${date_first} --end="${date_last} 23:59:59" --download

    echo "Downloading data"
    ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=${TRACK} \
    --start=${date_first} --end=${date_last} \
    --intersectsWith="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))" \
    --parallel=4 \
    --download | tee -a ssara_${timetag}.log

fi
echo "$0 ended normally"
exit 0


