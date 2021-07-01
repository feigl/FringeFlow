#!/bin/bash 

# calculate an interferometric pair
#2021/05/27 Kurt Feigl

if [ "$#" -ne 2 ]; then
    bname=`basename $0`
    echo "$bname will calculate an interferometric pair "
    echo "usage:   $bname reference_YYYYMMDD secondary_YYYYMMDD"
    echo "example: $bname 20190110  20190122"

    exit -1
fi

# 5
#export YYYYMMDD1="2019-10-02"
#export YYYYMMDD2="2019-11-16"

# 2019
#export YYYYMMDD1="2019-01-01"
#export YYYYMMDD2="2019-12-31"

source /opt/isce2/isce_env.sh
export PATH=$PATH:$HOME/MintPy/mintpy/
export PATH=${PWD}/bin:${PATH}

# need this, too for PyAPS pyaps3
export PYTHONPATH=$PYTHONPATH:$HOME/MintPy/mintpy/:$HOME/PyAPS


# export t0=20190110
# export t1=20190122
export t0=$1
export t1=$2
export runname=${t0}_${t1}

#export YYYYMMDD1="2019-01-10"
export YYYYMMDD1=`echo $t0 | awk '{printf("%4d-%02d-%02d",substr($1,1,4),substr($1,5,2),substr($1,7,2))}'`
#export YYYYMMDD2="2019-01-22"
export YYYYMMDD2=`echo $t1 | awk '{printf("%4d-%02d-%02d",substr($1,1,4),substr($1,5,2),substr($1,7,2))}'`

cd SLC
run_ssara.sh
ls -ltr 
cd ..

cd ORBITS
get_orbits.sh
cd ..

cd ISCE
run_isce.sh
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








