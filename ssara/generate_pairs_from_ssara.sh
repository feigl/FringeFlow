#!/bin/bash 
## run SSARA for downloading data
# 2021/06/21 Kurt Feigl
# 2022/08/15 Kurt Feigl - make it work everywhere
# 2023/09/26 Kurt Feigl - increase ASF timeout to 5 minutes = 300 seconds
# set -v # verbose
# set -x # for debugging
# set -e # exit on error
# set -u # error on unset variables


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


# Check if a command exists in the $PATH
command_to_check="ssara_federated_query.py"

if command -v "$command_to_check" &> /dev/null ; then
    echo "$command_to_check exists in the PATH."
else
    echo "$command_to_check does not exist in the PATH."
    export PATH=${PATH}:${HOME}/tools/ssara_client
    export PYTHONPATH=${HOME}/tools/ssara_client:${PYTHONPATH}
    export SSARA_HOME=${PWD}
fi


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
# ssara_federated_query.py --platform=SENTINEL-1A,SENTINEL-1B --asfResponseTimeout=300 --relativeOrbit=${TRACK} \
# --start=${date_first} --end=${date_last} \
# --intersectsWith="POLYGON(($LONMIN $LATMIN, $LONMAX $LATMIN, $LONMAX $LATMAX, $LONMIN $LATMAX, $LONMIN $LATMIN))" \
# --print | tee ssara.out

# yyyymmdd=`cat ssara.out | grep zip | head | awk -F, '{print $4}' | awk -F'-' '{print $1$2substr($3,1,2)}' | sort -nu`
# echo $yyymmdd

# #for item in "${my_array[@]}"; do
# for d1 in "${yyyymmdd[@]}"; do
#     for d2 in "${yyyymmdd[@]}"; do
#         echo $d1
#     done
# done

cat ssara.out | grep zip | head | awk -F, '{print $4}' | awk -F'-' '{print $1$2substr($3,1,2)}' | sort -nu > dates.txt
# queue arguments from (
# "-n SANEM -m S1 -t 144 -1 20180101 -2 20181231 -c 5" 
# "-n SANEM -m S1 -t 144 -1 20190101 -2 20191231 -c 5" 

echo 'queue arguments from (' > pairs.sub
while IFS= read -r d1; do
    while JFS= read -r d2; do
        if [ "$d1" -lt "$d2" ]; then
            echo "\"-n $SITEUC -m $MISSION -t $TRACK -1 $d1 -2 $d2 -c 1\"" >> pairs.sub
        fi
    done < dates.txt
done < dates.txt
echo ')' >> pairs.sub

cat pairs.sub

echo consider adding file named pairs.sub to end of a submit file for CHTC

echo "$0 ended normally"
exit 0


