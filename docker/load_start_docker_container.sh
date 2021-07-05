#!/bin/bash -vx

# Load a docker container and then start it
# 2021/07/05 Kurt Feigl

#dirname=/s12/insar/SANEM/SENTINEL/
dirname=/System/Volumes/Data/mnt/t31/insar/SANEM/S1
mkdir -p $dirname
cd $dirname
#runname=`basename $dirname`
export sat='S1'
export site='SANEM'
export trk=144
export t0=20190110
export t1=20190122
export runname="${sat}_${trk}_${site}_${t0}_${t1}"
echo runname is $runname

# if [ -d $runname ]; then
#     rm -rf $runname
# fi
mkdir -p $runname
cd $runname

## copy keys here
cp -v $HOME/.netrc . 
cp -v $HOME/.model.cfg .
cp $HOME/SSARA-master/password_config.py .

# copy input files
#cp /s12/insar/SANEM/Maps/SanEmidioWells2/San_Emidio_Wells_2019WithLatLon.csv .
#cp -r ../TEMPLATE/* .
rsync -rav feigl@askja.ssec.wisc.edu:/s12/insar/SANEM/S1/ISCE/"dem*" ISCE
# make a copy of executable scripts
#cp -vr /s12/insar/SANEM/SENTINEL/bin .

# pull scripts
cd $HOME/FringeFlow
git pull 
cd $dirname

cd $runname

tar -C $HOME -czvf FringeFlow.tgz FringeFlow


# make a tar file
#tar -czvf ../${runname}.tgz .

cd ..

# pull container from DockerHub
docker pull docker.io/nbearson/isce_chtc2

# get the short (base) name of the current working directory
#export MYDIR=`basename $PWD`

# arrange permissions
if [[ $HOST == askja.ssec.wisc.edu ]]; then
  podman unshare chown -R 1000:1000 $runname
fi
cd $runname

# run script in container
#docker run --name $runname -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/.." -w $PWD nbearson/isce_mintpy ./bin/run_pair.sh 20190110  20190122

# start interactive shell in container 
#docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/.." -v "$PWD/../..":"$PWD/../.."  -w $PWD nbearson/isce_mintpy 
#docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/../ISCE":"$PWD/../ISCE" -w $PWD nbearson/isce_mintpy 
#docker run -it --rm -v "$PWD":"$PWD" -w $PWD nbearson/isce_mintpy:latest 
#docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/../" -w $PWD isce/isce2:latest
#docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/../" -w $PWD benjym/insar  # does not include icse
 docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/..":"$PWD/../" -w $PWD docker.io/nbearson/isce_chtc2

# change permissions back again
cd ..
if [[ $HOST == askja.ssec.wisc.edu ]]; then
   sudo chown -R ${USER}:'domain users' $runname 
fi


#podman unshare chown -R feigl:'domain users' $PWD
