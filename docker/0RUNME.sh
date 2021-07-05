#!/bin/bash -vx
# 2021/05/25 Kurt Feigl

# Run test case of 2 epochs for ISCE

# On porotomo:
# module purge
# module load Carnegie/isce/base Carnegie/isce/2.2.0 Carnegie/isce/contrib/tops

# On askja:
# ### Outside the container

#dirname="/s12/insar/SANEM/SENTINEL/T144f_askja3"
#dirname="/s12/insar/SANEM/SENTINEL/T144f_askja5"
#dirname="/s12/insar/SANEM/SENTINEL/T144f_askja6"
dirname="/s12/insar/SANEM/SENTINEL/T144h"
#mkdir -p $dirname
cd $dirname
#runname=`basename $dirname`
# test case
# export t0=20190110
# export t1=20190122

# export t0=20190110
# export t1=20190122
# export runname="Pair_${t0}_${t1}"

export runname=ISCE
echo runname is $runname
mkdir -p $runname

# if [ -d $runname ]; then
#     rm -rf $runname
# fi
# mkdir $runname
# cd $runname

## copy keys here
cp -v $HOME/.netrc . 
cp -v $HOME/.model.cfg .
cp /home/feigl/SSARA-master/password_config.py .

# copy input files
cp /s12/insar/SANEM/Maps/SanEmidioWells2/San_Emidio_Wells_2019WithLatLon.csv .
cp -r ../T144g/TEMPLATE/bin .
cp -r ../T144g/TEMPLATE/ISCE/* ISCE
#cp -r ../T144f_askja/isce/aux ISCE

# make a copy of executable scripts
cp -vr /s12/insar/SANEM/SENTINEL/bin .

# # make a tar file
# tar -czvf ../${runname}.tgz .

# cd ..

# pull container from DockerHub
docker pull nbearson/isce_mintpy:latest

# get the short (base) name of the current working directory
#export MYDIR=`basename $PWD`

# arrange permissions
podman unshare chown -R 1000:1000 $runname
cd $runname

# run script in container
#docker run --name $runname -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/.." -w $PWD nbearson/isce_mintpy ./bin/run_pair.sh 20190110  20190122
docker run --name $runname -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/.." -w $PWD nbearson/isce_mintpy ../bin/run_isce.sh

# start interactive shell in container 
#docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/.." -v "$PWD/../..":"$PWD/../.."  -w $PWD nbearson/isce_mintpy 
#docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/.." -w $PWD nbearson/isce_mintpy 
#docker run -it --rm -v "$PWD":"$PWD" -w $PWD nbearson/isce_mintpy 

# change permissions back again
cd ..
sudo chown -R feigl:'domain users' $runname
#podman unshare chown -R feigl:'domain users' $PWD
