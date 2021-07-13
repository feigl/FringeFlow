#!/bin/bash -vx
# 2021/05/25 Kurt Feigl

# Run MINTPY after big ISCE run


#dirname="/s12/insar/SANEM/SENTINEL/T144f_askja3"
#dirname="/s12/insar/SANEM/SENTINEL/T144f_askja5"
#dirname="/s12/insar/SANEM/SENTINEL/T144f_askja6"
#dirname="/s12/insar/SANEM/SENTINEL/T144g"
#dirname="/s12/insar/SANEM/SENTINEL/COMBINED"
dirname="/s12/insar/SANEM/SENTINEL/T144h"
mkdir -p $dirname
cd $dirname
#runname=`basename $dirname`
# export t0=20190110
# export t1=20190122
# export runname="Pair_${t0}_${t1}"
# export t0=20190101
# export t1=20191230
# export runname="MINTPY_${t0}_${t1}"
export runname="MINTPY_20210605"
#export runname="MINTPY_20210610"

echo runname is $runname
mkdir -p $runname
cd $runname

## copy keys here
cp -v $HOME/.netrc . 
cp -v $HOME/model.cfg .
cp /home/feigl/SSARA-master/password_config.py .

# copy input files
cp /s12/insar/SANEM/Maps/SanEmidioWells2/San_Emidio_Wells_2019WithLatLon.csv .
#cp -r ../TEMPLATE/* .
#cp -r ../TEMPLATE/MINTPY/* .

# make a copy of executable scripts
#cp -vr /s12/insar/SANEM/SENTINEL/sh .

cd ..

# pull container from DockerHub
# export DOCKERIMAGETAG="nbearson/isce_mintpy:latest"
# export DOCKERIMAGETAG="nbearson/isce_mintpy"
export DOCKERIMAGETAG="nbearson/isce_chtc2"
echo DOCKERIMAGETAG is ${DOCKERIMAGETAG}

#docker pull nbearson/isce_mintpy:latest
#docker pull nbearson/isce_chtc2
docker pull ${DOCKERIMAGETAG}

# get the short (base) name of the current working directory
#export MYDIR=`basename $PWD`

# arrange permissions
podman unshare chown -R 1000:1000 $runname
cd $runname

# run script in container
#docker run --name $runname -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/.." -w $PWD nbearson/isce_mintpy ./bin/run_mintpy.sh

# start interactive shell in container 
# mounting sh to allow editing from outside container
docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/../ISCE":"$PWD/../ISCE" -v /s12/insar/SANEM/SENTINEL/sh:/sh -w $PWD ${DOCKERIMAGETAG}

# change permissions back again
cd ..
sudo chown -R feigl:'domain users' $runname
#podman unshare chown -R feigl:'domain users' $PWD
