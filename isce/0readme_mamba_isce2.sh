#!/bin/bash

#cd /software/feigl
#cd /scratch/feigl
cd $HOME
mkdir -p ./miniconda3

#wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ./miniconda3/miniconda.sh
#wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O miniforge/miniforge.sh

curl https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -o ~/miniconda3/miniconda.sh

unset PYTHONPATH

bash miniconda3/miniforge.sh -b -u -p ./miniforge

rm -rf miniforge.sh
# https://github#.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh

./miniforge/bin/mamba init bash
source ~/.bashrc
echo $PYTHONPATH

mamba create -n isce2kf -y
mamba activate isce2kf
echo $PYTHONPATH

# https://github.com/scottstanie/sentineleof

# add pandas for asf_search

cat << EOF > requirements.txt
isce2
cython
gdal
git
h5py
libgdal
pytest
numpy
fftw
scipy
basemap
scons
opencv
shapely
asf_search
sentineleof
ipykernel
EOF


mamba install --yes --file requirements.txt

 

# with isce2 installed from conda it sets $ISCE_STACK for me, but we need to pick our stack still

# ref: https://github.com/isce-framework/isce2/blob/main/contrib/stack/README.md

# (isce2t2) [bearson@spark-a006 ~]$ env | grep STACK

#ISCE_STACK=/home/bearson/miniforge-pypy3/envs/isce2t2/share/isce2

 
#ISCE_STACK=/scratch/feigl/miniforge/envs/isce2kf/share/isce2/
#ISCE_STACK=/software/feigl/miniforge/envs/isce2kf/share/isce2
ISCE_STACK=/home/feigl/miniforge/envs/isce2kf/share/isce2
#export PYTHONPATH=${PYTHONPATH}:${ISCE_STACK}
export PYTHONPATH=${PYTHONPATH}:${ISCE_STACK}

export PATH=${PATH}:${ISCE_STACK}/topsStack

 

stackSentinel.py

# should print usage text as expected

get_quotas /home/feigl /scratch/feigl /software/feigl/

eof --search-path ./SLC --save-dir ./orbits/

# dem file must be in local directory because .xml file contains full path name!

stackSentinel.py -w ./ \
    -d demLat_N38_N39_Lon_W112_W111.dem.wgs84 \
    -s SLC \
    -a aux \
    -o orbits \
    -c 1 \
    --filter_strength 0 \
    --azimuth_looks 5 \
    --range_looks 20 \
    --num_proc 16\
    --num_process4topo 16 \
    -C geometry \
    --param_ion ./ion_param.txt \
    -W interferogram 

# set up a script to run all the scripts
ls -1 run_files/* | grep -v job | awk '{print "bash",$1}' > run_isce_jobs.sh
chmod a+x run_isce_jobs.sh