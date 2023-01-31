#!/bin/bash -vx

# calculate an interferometric pair
#2021/06/10 Kurt Feigl
#2021/10/20 Sam -- modifying for use on Askja
#2021/11/03 Kurt and Sam
#2023/01/31 Kurt and Sam: change tgz to tar

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
# tgz=${1}
# echo "tgz is $tgz"
tarfile=${1}
echo "tarfile is $tarfile"

site=`echo ${tarfile} | awk -F_ '{print $1}'`
sat=`echo ${tarfile} | awk -F_ '{print $2}'`
trk=`echo ${tarfile} | awk -F_ '{print $3}'`
swath=`echo ${tarfile} | awk -F_ '{print $4}'`
ref=`echo ${tarfile} | awk -F_ '{print $5}'`
sec=`echo ${tarfile} | awk -F_ '{print $6}' | sed 's/.tar//'`

echo "site is $site"
echo "sat  is $sat"
echo "trk  is $trk"
echo "swath is $swath"
echo "ref is $ref"
echo "sec is $sec"

runname="${sat}_${trk}_${sit}_${t0}_${t1}_${timetag}"
echo runname is ${runname}

# conditions to account for data availablity for local vs condor slot run
if [[ -f ${tarfile} ]]; then
	echo "using local copy ${tarfile}"
	ls -l ${tarfile}
elif [[ -f /staging/groups/geoscience/insar/${tarfile} ]]; then
  echo "looking for a copy on staging"
  ls -l /staging/groups/geoscience/insar/${tarfile}
  time cp -v /staging/groups/geoscience/insar/${tarfile} .
else
	echo "ERROR: Could not find input file named ${tarfile}"
	ls -l /staging/groups/geoscience/insar ./
	exit -1
fi

# we are in a docker container now for an individual pair. 
# extract tar file
# 2023/01/31 time tar -xzvf ${tarfile}
time tar -xvf ${tarfile}
# intialize environmental vars including PATH
source setup_inside_container_gmtsar.sh 
# set an environmental var for SITE_TABLE
#parent=$(dirname $PWD)
export SITE_TABLE="${PWD}/siteinfo/site_dims.txt"
echo "the site dimensions file is $SITE_TABLE"
cd "In${ref}_${sec}"
# send output to home, in hopes that it will transfer back at the end
time ./run.sh | tee -a ${HOME}/${runname}.log


