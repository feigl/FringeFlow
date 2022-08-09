#!/usr/bin/env bash

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
export STACK_SENTINEL_NUM_CONNECTIONS=${6:=all} # passed to stackSentinel as number of interferograms between each date and subsequent dates

WORKDIR=$PWD

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
export runname="${sat}_${trk}_${sit}_${t0}_${t1}_c${STACK_SENTINEL_NUM_CONNECTIONS}"
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


# echo "Copying input ORBIT files from askja"
# mkdir -p ORBITS
# cd ORBITS
# get_orbits_from_askja.sh | tee -a ../orbits.log
# cd ..
# cp /staging/groups/geoscience/isce/input/orbits.tar.xz orbits.tar.xz
# tar xf orbits.tar.xz
# [chtc-nickb@bearson-9818685 ORBITS]$ get_orbits_from_askja.sh | tee -a ../orbits.log
# ssh: connect to host askja.ssec.wisc.edu port 22: Connection refused
# NICKB: FIXME: FIX WITH SSH or FIX WITH STAGING?
# above: leaning towards FIX WITH STAGING right now
# 20220613 above requires all orbits - instead try getting only orbits for which we have an SLC
mkdir -p ORBITS
pushd ORBITS
get_orbits.sh tee -a ../orbits.log
popd

echo "Setting the DEM"
mkdir -p DEM
pushd DEM
dem=`ls ${SITE_DIR}/${SIT}/dem* | head -1`
if [[ -f  $dem ]]; then
    echo "Copying a DEM"
    cp -vf $dem .
else
# make the DEM
    echo "Getting a DEM from NASA"
    echo dem.py -a stitch -b $(get_site_dims.sh $sit i) -r -s 1 -c 
    dem.py -a stitch -b $(get_site_dims.sh $sit i) -r -s 1 -c | tee -a ../dem.log
    echo "cannot find DEM $dem"
    exit -1
fi
popd

echo "Running ISCE"
mkdir -p ISCE
pushd ISCE
run_isce.sh ${sit} | tee -a ../isce.log
ls -ltr | tee -a ../isce.log

# check final output
find  baselines -type f -ls | tee ../baselines.lst
find  merged    -type f -ls | tee ../merged.lst
popd


# transfer output back to /staging/
cd $WORKDIR/$runname # I think we should already be there, but just in case
# I don't love using *.log here, as with `set -e` we will bail if there are no such log files
# 2022/06/14 Kurt - keep the DEM and the ORBITS too
#tar czf "$runname.tgz" DEM ORBITS ISCE/merged ISCE/baselines ISCE/interferograms ISCE/JPGS.tgz ISCE/*.log *.log
# 2022/08/01 Kurt - add more folders
#tar czf "$runname.tgz" DEM ORBITS ISCE/merged ISCE/baselines ISCE/interferograms ISCE/JPGS.tgz ISCE/reference ISCE/secondarys ISCE/stacks ISCE/aux ISCE/dem* ISCE/*.log *.log 
tar -czf "$runname.tgz" DEM ORBITS ISCE 
# ./ISCE/aux
# ../ISCE/baselines
# ../ISCE/baselines.txt
# ../ISCE/bperp.csv
# ../ISCE/configs
# ../ISCE/coreg_secondarys
# ../ISCE/demLat_N40_N41_Lon_W120_W119.dem
# ../ISCE/demLat_N40_N41_Lon_W120_W119.dem.vrt
# ../ISCE/demLat_N40_N41_Lon_W120_W119.dem.wgs84
# ../ISCE/demLat_N40_N41_Lon_W120_W119.dem.wgs84.vrt
# ../ISCE/demLat_N40_N41_Lon_W120_W119.dem.wgs84.xml
# ../ISCE/demLat_N40_N41_Lon_W120_W119.dem.xml
# ../ISCE/geom_reference
# ../ISCE/interferograms
# ../ISCE/isce.log
# ../ISCE/merged
# ../ISCE/prepareStack.log
# ../ISCE/reference
# ../ISCE/run_files
# ../ISCE/run_isce_jobs.log
# ../ISCE/run_isce_jobs.sh
# ../ISCE/SAFE_files.txt
# ../ISCE/secondarys
# ../ISCE/stack

mkdir -p "/staging/groups/geoscience/isce/output/"
cp "$runname.tgz" "/staging/groups/geoscience/isce/output/$runname.tgz"

# delete working dir contents to avoid transfering files back to /home/ on submit2
rm -rf $WORKDIR/*

# exit cleanly
exit 0
