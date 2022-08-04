#!/usr/bin/env bash
# 2022/08/04 Kurt Feigl 

set -v # verbose
set -x # for debugging
#set -e # exit on error
#set -u # error on unset variables

# S1  20 FORGE 20200101  20200130

# NICKB: hardcoding some run_pairs_isce.sh bits for running interactive
# export sat=S1
# export trk=20
# export sit=FORGE
# export t0=20200101
# export t1=20200130

export sat=$1
export trk=$2
export sit=$3
export t0=$4
export t1=$5

WORKDIR=$PWD

# are we running under condor ?
if [[ ! -d /staging/groups/geoscience/isce/ ]]; then
    export ISCONDOR=1
else
    export ISCONDOR=0 
fi
echo ISCONDOR is $ISCONDOR

# NICKB: this comes from run_pairs_isce.sh
# not currently necessary when using /staging/ or /groups/ for orbits and other input/output
#uncompress SSH keys ssh.tgz
#tar -C ${HOME} -xzvf ssh.tgz
#rm -vf ssh.tgz

# uncompress files for shell scripts and add to search path
tar -C ${HOME} -xzvf FringeFlow.tgz

# uncompress siteinfo
tar -C ${HOME} -xzvf siteinfo.tgz

# set up paths and environment

# NICKB: does something in setup_inside_container_isce.sh require domagic.sh?
source $HOME/FringeFlow/docker/setup_inside_container_isce.sh

# NICKB: this does not appear to run in the run_pairs_isce.sh workflow; taken from docker/load_start_docker_container_isce.sh
$HOME/FringeFlow/docker/domagic.sh magic.tgz

# FIXME: domagic.sh cannot write $HOME/magic/model.cfg to the PyAPS install in /home/ops/PyAPS/pyaps3/model.cfg

export timetag=`date +"%Y%m%dT%H%M%S"`
echo timetag is ${timetag}
export runname="${sat}_${trk}_${sit}_${t0}_${t1}"
echo runname is ${runname}

RUNDIR="$WORKDIR/$runname"
mkdir -p $RUNDIR
cd $RUNDIR
pwd

echo "Downloading SLC files"
mkdir -p SLC
pushd SLC
echo PWD is now ${PWD}
which run_ssara.sh
run_ssara.sh $sat $trk $sit $t0 $t1 download | tee -a ../slc.log
# this created dir: /var/lib/condor/execute/slot1/dir_22406/S1_20_FORGE_20200101_20200130/SLC/SLC_20200101_20200130/
# containing files like: S1B_IW_SLC__1SDV_20200103T012610_20200103T012637_019646_02520B_864F.zip

# on askja they were in: /s12/nickb/chtc-prep/T144f_askja3/SLC/
# containing files like: S1A_IW_SLC__1SDV_20181006T135842_20181006T135909_024016_029FBD_1F0D.zip

# NICKB FIXUP - move the SLCs to the SLC/ dir
slcdir="SLC_${t0}_${t1}"
mv $slcdir/*.zip .
# END

ls -ltr | tee -a ../slc.log
popd

# SSARA API query: 3.528266 seconds
# Found 3 scenes
# Downloading data now, 1 at a time.
# ASF Download: S1B_IW_SLC__1SDV_20200127T012610_20200127T012637_019996_025D37_EAFF.zip
# S1B_IW_SLC__1SDV_20200127T012610_20200127T012637_019996_025D37_EAFF.zip download time: 108.41 secs (38.78 MB/sec)
# ASF Download: S1B_IW_SLC__1SDV_20200115T012610_20200115T012637_019821_0257A0_EBC9.zip
# S1B_IW_SLC__1SDV_20200115T012610_20200115T012637_019821_0257A0_EBC9.zip download time: 125.94 secs (33.08 MB/sec)
# ASF Download: S1B_IW_SLC__1SDV_20200103T012610_20200103T012637_019646_02520B_864F.zip
# S1B_IW_SLC__1SDV_20200103T012610_20200103T012637_019646_02520B_864F.zip download time: 146.04 secs (28.55 MB/sec)


echo "Copying input ORBIT files from askja"
# mkdir -p ORBITS
# cd ORBITS
# get_orbits_from_askja.sh | tee -a ../orbits.log
# cd ..
cp /staging/groups/geoscience/isce/input/orbits.tar.xz orbits.tar.xz
tar xf orbits.tar.xz
# [chtc-nickb@bearson-9818685 ORBITS]$ get_orbits_from_askja.sh | tee -a ../orbits.log
# ssh: connect to host askja.ssec.wisc.edu port 22: Connection refused
# NICKB: FIXME: FIX WITH SSH or FIX WITH STAGING?
# above: leaning towards FIX WITH STAGING right now

echo "Making a DEM"
mkdir -p DEM
pushd DEM
# make the DEM
echo "dem.py -a stitch -b $(get_site_dims.sh $sit i) -r -s 1 -c" | tee -a ../dem.log
dem.py -a stitch -b $(get_site_dims.sh $sit i) -r -s 1 -c
popd

echo "Running ISCE"
mkdir -p ISCE
pushd ISCE
run_isce.sh ${sit} | tee -a ../isce.log
ls -ltr | tee -a ../isce.log

# check final output
find  baselines -type f -ls | tee baselines.lst
find  merged    -type f -ls | tee merged.lst
popd


# transfer output back to /staging/
cd $WORKDIR/$runname # I think we should already be there, but just in case
# I don't love using *.log here, as with `set -e` we will bail if there are no such log files
tar czf "$runname.tgz" ISCE/merged ISCE/baselines ISCE/interferograms ISCE/JPGS.tgz ISCE/*.log *.log
mkdir -p "/staging/groups/geoscience/isce/output/"
cp "$runname.tgz" "/staging/groups/geoscience/isce/output/$runname.tgz"

# delete working dir contents to avoid transfering files back to /home/ on submit2
rm -rf $WORKDIR/*

# exit cleanly
exit 0
