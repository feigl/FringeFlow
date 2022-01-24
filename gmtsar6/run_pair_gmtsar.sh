#!/bin/bash -vx

# calculate an interferometric pair
#2021/06/10 Kurt Feigl
#2021/10/20 Sam -- modifying for use on Askja
#2021/11/03 Kurt and Sam

if [ "$#" -ne 1 ]; then
    bname=`basename $0`
    echo "$bname will calculate an interferometric using gmtsar "
    echo "usage:   "
    echo "   $bname filename.tgz"
    echo "   $bname site_sat_trk_swath_ref_sec.tgz"
    echo "example:"
    echo "   $bname FORGE_TSX_T30_strip004_20200415_20210505.tgz"
    echo "Tarfile named filename.tgz is assumed to exist on transfer.chtc.wisc.edu:/staging/groups/geoscience/insar"
    exit -1
fi

#export YYYYMMDD1="2019-10-02"
#export YYYYMMDD2="2019-11-16"

echo "Starting script named $0"
echo "Argument is $1"
echo PWD is ${PWD}
echo HOME is ${HOME} 

timetag=`date +"%Y%m%dT%H%M%S"`
echo "timetag is $timetag"

#pairdir=${site}_${sat}_${trk}_${swath}_${ref}_${sec}
#tgz="FORGE_TSX_T30_strip004_20200415_20210505.tgz"
tgz=${1}
echo "tgz is $tgz"

site=`echo ${tgz} | awk -F_ '{print $1}'`
sat=`echo ${tgz} | awk -F_ '{print $2}'`
trk=`echo ${tgz} | awk -F_ '{print $3}'`
swath=`echo ${tgz} | awk -F_ '{print $4}'`
ref=`echo ${tgz} | awk -F_ '{print $5}'`
sec=`echo ${tgz} | awk -F_ '{print $6}' | sed 's/.tgz//'`

echo "site is $site"
echo "sat  is $sat"
echo "trk  is $trk"
echo "swath is $swath"
echo "ref is $ref"
echo "sec is $sec"

runname="${sat}_${trk}_${sit}_${t0}_${t1}_${timetag}"
echo runname is ${runname}

# conditions to account for data availablity for local vs condor slot run
if [[ -f ${tgz} ]]; then
	echo "using local copy ${tgz}"
	ls -l ${tgz}
elif [[ -f /staging/groups/geoscience/insar/${tgz} ]]; then
  echo "looking for a copy on staging"
  ls -l /staging/groups/geoscience/insar/${tgz}
  time cp -v /staging/groups/geoscience/insar/${tgz} .
else
	echo "ERROR: Could not find input file named ${tgz}"
	ls -l /staging/groups/geoscience/insar ./
	exit -1
fi

# we are in a docker container now for an individual pair, right?
# extract tar file
time tar -xzvf ${tgz}
# intialize environmental vars including PATH
source setup_inside_container_gmtsar.sh 
# set an environmental var for SITE_TABLE
#parent=$(dirname $PWD)
export SITE_TABLE="${PWD}/siteinfo/site_dims.txt"
echo "the site dimensions file is $SITE_TABLE"
cd "In${ref}_${sec}"
# send output to home, in hopes that it will transfer back at the end
time ./run.sh | tee ${HOME}/${runname}.log


