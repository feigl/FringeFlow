#!/bin/bash -vx

# calculate an interferometric pair
#2021/05/27 Kurt Feigl

if [ "$#" -ne 5 ]; then
    bname=`basename $0`
    echo "$bname will calculate an interferometric pair "
    echo "usage:   $bname SAT TRK SITE reference_YYYYMMDD secondary_YYYYMMDD"
    echo "example: $bname S1 T53 SANEM 20190110  20190122"

    exit -1
fi

#export YYYYMMDD1="2019-10-02"
#export YYYYMMDD2="2019-11-16"

echo "Hello world from $0"
echo "arguments are $1 $2 $3 $4 $5"

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

export timetag=`date +"%Y%m%dT%H%M%S"`
echo timetag is ${timetag}
export runname="${sat}_${trk}_${sit}_${t0}_${t1}_${timetag}"
echo runname is ${runname}

echo PWD is ${PWD}
echo HOME is ${HOME} 

# set path
echo looking for isce_env.sh
ls /opt
find /opt -name isce_env.sh -ls
echo looking for stackSentinel.py
find /opt -name stackSentinel.py -ls
source /opt/isce2/isce_env.sh
export PATH=$PATH:$HOME/MintPy/mintpy/

# 20210605 needed for stackSentinel.py
export PATH=$PATH:/opt/isce2/src/isce2/contrib/stack/topsStack

# need this, too for PyAPS pyaps3
export PYTHONPATH=$PYTHONPATH:$HOME/MintPy/mintpy/:$HOME/PyAPS

# uncompress files for shell scripts and add to search path
tar -xzvf sh.tgz
export PATH=${PWD}/sh:${PATH}
echo ${PATH}

# uncompress ssh.tgz
tar -C ${HOME} -xzvf ${PWD}/ssh.tgz
rm -vf ssh.tgz

## Copy Keys
# extract keys from tar file
tar -xzvf magic.tgz

# for SSARA
ls -l password_config.py
cp -v password_config.py $HOME/ssara_client

# for orbits via wget
ls -la .netrc

# key for MintPy and PyAPS
ls -la model.cfg
find $HOME . -name model.cfg -ls 
#cp -vf model.cfg $HOME/PyAPS/pyaps3/model.cfg
cp -vf model.cfg `find $HOME -name model.cfg` 

mkdir $runname
cd $runname
echo PWD is now ${PWD}
tar -xzvf ../pair1.tgz


cd SLC
echo PWD is now ${PWD}
which run_ssara.sh
run_ssara.sh $sat $trk $sit $t0 $t1
ls -ltr | tee SLC.txt
cd ..

cd ORBITS
get_orbits.sh
ls -ltr | tee ORBITS.txt
cd ..

cd ISCE
run_isce.sh
ls -ltr | tee ISCE.txt
cd ..


# MINTPY will fail with only one pair
# cd MINTPY
# run_mintpy.sh
# plot_interferograms.sh
# cd ..

# cd MINTPY/geo
# plot_maps.sh
# plot_time_series.sh
# cd ../..

# remove keys
rm -vf model.cfg .netrc password_config.py

# make a tar file and send it to askja
cd ..
tar -czvf ${runname}_${timetag}.tgz $runname
rsync -rav ${runname}_${timetag}.tgz feigl@askja.ssec.wisc.edu:/s12/insar 

