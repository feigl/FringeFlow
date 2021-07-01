#!/bin/bash -vex
## 2021/06/07 Kurt Feigl

## SSARA for downloading data
# get working version of ssara client
#cp -rp /home/feigl/SSARA-master $HOME
export PYTHONPATH=$HOME/ssara_client

export sat=$1
export trk=$2
export sit=$3
export t0=$4
export t1=$5

# export YYYYMMDD1="2018-01-01"
# export YYYYMMDD2="2021-12-31"

export YYYYMMDD1=`echo $t0 |  awk '{ printf("%4d-%02d-%02d\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'
export YYYYMMDD2=`echo $t1 |  awk '{ printf("%4d-%02d-%02d\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'

echo YYYYMMDD1 is {$YYYYMMDD1}
echo YYYYMMDD2 is {$YYYYMMDD2}

ls -la password_config.py
ls -la $HOME/ssara_client/password_config.py

# make list
python -m ssara_federated_query --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=${YYYYMMDD1} --end="${YYYYMMDD2} 23:59:59" --print | tee ssara.lst

# make KML file
python -m ssara_federated_query --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=${YYYYMMDD1} --end="${YYYYMMDD2} 23:59:59"  --kml

# download data
# end on the 19th, to get the 18th
# python -m ssara_federated_query --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=2018-10-06 --end=2018-10-19 --print
# python -m ssara_federated_query --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=2018-10-06 --end=2018-10-19 --download
#python -m ssara_federated_query --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=2019-10-06 --end=2018-10-19  --s1orbits --download
#python -m ssara_federated_query --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=2018-10-06 --end=2018-11-16 --download
# switch for ICSE --start 2018-10-01 --stop 2018-11-15
python -m ssara_federated_query --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=30 --relativeOrbit=144 --intersectsWith='POINT(-119.3987026 40.37426071)' --start=${YYYYMMDD1} --end="${YYYYMMDD2} 23:59:59" --download


   