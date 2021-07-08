#!/bin/bash -vex
#!/usr/bin/env -S bash -x
# for debugging, add "-vx" switch after "bash" in the shebang line above.
# switches in line above:
#      -e exit on error
#      -v verbose
#      -x examine
# run_pair_gmtsarv60.sh (this script)
# how to run a pair of insar images 20160804 Kurt Feigl
#
# edit 20170218 Elena C Reinisch, change S1A setup for preprocessing per pair; save PRM and LED files to output
# edit 20170710 copy data from maule during job, send email when job has finished; transfer pair directly to maule 
# edit 20170801 ECR update to copy maule ALOS data with frame in the name
# edit 20171114 ECR comment out renaming of p2p_TSX script for airbus and instead add $site to pair2e.sh call
# edit 20180406 ECR update to pull from new bin_htcondor repo
# edit 20200124 KF/SAB update to share geoscience group directory
# edit 20201227 Kurt fix bug that stops run before geocoding
# edit 20200406 Kurt and Sam try to fix bug about disk usage exceedes request
# edit 20201106 Sam changed shebang from #!/bin/bash to #!/usr/bin/env bash as recommended by TC -- updated maule to askja and s21 to s12
# edit 20201130 Sam and Kurt set name of GMTSAR package to GMTSAR_v60

# edit 20201201 set up environment variables with path names for GMT and GMTSAR
# note 20201201 this is where software is unbundled for submit-2 (yes) bundled in the DAG version of this script - batzli
# edit 20201202 batzli added usage
# edit 20201228 batzli added some breaks for troublshooting
# edit 20210305 batzli ran successful pair, removed exit before result file cutting, moving, and cleanup, moved a >cd and actual >./run.sh to pair2e.sh
# edit 20210308 batzli added ${unwrap} variable ("value" [.12] or empthy) to pass through from run_pair_DAG_gmtsarv60.sh to here (run_pair_gmtsarv60.sh) then to pair2e.sh

if [[ ! $# -eq 14 ]] ; then
    echo '	ERROR: $0 requires 14 arguments.'
    echo '	Usage: $0 sat trk ref sec user satparam demf filter_wv xmin xmax ymin ymax site'
    echo '	$1=sat'
    echo '	$2=trk'
    echo '	$3=ref (reference image date in YYYYMMDD) formerly mast' 
    echo '	$4=sec (secondary image date in YYYYMMDD) formerly slav'
    echo '	$5=user'
    echo '	$6=satparam (for TSX this is strip number)'
    echo '	$7=demf (DEM filename)'
    echo '	$8=filter_wv (filter wavelength)'
    echo '	$9,${10},${11},${12} are xmin xmax ymin ymax'
    echo '	${13}=site'
    echo '	${14}=unwrap (value or empty) default empty will not unwrap)'
    echo '	Example: $0 TSX T144 20180724 20181203 feigl strip_007R tusca_dem_3dep_10m.grd 80 -116.1900101030447 -116.0749982018097 41.41245177646995 41.49864121097495 tusca y'
    exit 0
fi

# set satellite and track
sat=${1}
trk=${2}
# set reference and secondary variables
ref=${3}
sec=${4}
orb1a=`expr $ref - 1`
orb2a=`expr $sec - 1`
user=${5}
satparam=${6} # extra parameter for satellite specific parameters (e.g., for S1A satparam = subswath number)
demf=${7}
# set filter wavelength
filter_wv=${8}
# set region variables
xmin=${9}
xmax=${10}
ymin=${11}
ymax=${12}
site=${13}
unwrap=${14}
SITE=`echo $site | awk '{ print toupper($1) }'`

# set data directory
if [[ $(hostname) = "askja.ssec.wisc.edu" ]]; then
    export DATADIR=/s12
else
    export DATADIR=${HOME}
fi
echo "DATADIR is $DATADIR"


# set up ssh transfer (for HTCONDOR only, [missing destination dir?] move up to conditional)


# make local directories for local copies of data and dem
#if [ ! -d "/s12/${user}/RAW" ] ; then
if [ ! -d "./RAW" ] ; then
	mkdir RAW
fi
#if [ ! -d "/s12/${user}/dem" ] ; then
if [ ! -d "./dem" ] ; then
	mkdir dem
fi

# transfer cut grid file to job server (for moving to submit-2)
# scp $askja:${HOME}/insar/condor/feigl/insar/dem/cut_$demf dem/$demf
# copy cut grid for current use
cp ${DATADIR}/insar/dem/cut_$demf dem/$demf

# get data from askja
cd RAW
## get reference data to working directory
swath=`echo $satparam | awk '{print substr($1,7,3)}'`
echo "swath is $swath"
#longfilename1=`grep ${site} ${DATADIR}/insar/TSX/TSX_OrderList.txt | grep ${ref} | sed 's%/s12/%/root/%' | awk '{print $12}'`
longfilename1=`grep ${site} ${DATADIR}/insar/TSX/TSX_OrderList.txt | grep ${ref} | awk '{print $12}'`
echo "longfilename1 is $longfilename1"
cp -r $longfilename1 .

## get secondary data to working directory
swath=`echo $satparam | awk '{print substr($1,7,3)}'`
echo "swath is $swath"
#longfilename2=`grep ${site} ${DATADIR}/insar/TSX/TSX_OrderList.txt | grep ${sec} | sed 's%/s12/%/root/%' | awk '{print $12}'`
longfilename2=`grep ${site} ${DATADIR}/insar/TSX/TSX_OrderList.txt | grep ${sec} | awk '{print $12}'`
echo "longfilename2 is $longfilename2"
cp -r $longfilename2 .

echo "leaving RAW"
cd ../
echo "in $0 working directory is now $PWD"
pwd

# run a script to write a script (run.sh)
write_run_script.sh ${sat} ${ref} ${sec} ${satparam} dem/${demf} ${filter_wv} ${site} ${xmin} ${xmax} ${ymin} ${ymax} ${unwrap}

# make the run script e
chmod a+x In${ref}_${sec}/run.sh

# make a tar file
tgzfile=In${ref}_${sec}_in.tgz
tar -czvf $tgzfile In${ref}_${sec}

# transfer the tar file
if [[ $(hostname) = "askja.ssec.wisc.edu" ]]; then
    mkdir -p /s12/insar/${SITE}/TSX
    cp -v  $tgzfile /s12/insar/${SITE}/TSX
    ssh transfer.chtc.wisc.edu mkdir -p /staging/groups/geoscience/insar/TSX
    time rsync --progress -rav $tgzfile transfer.chtc.wisc.edu:/staging/groups/geoscience/insar/TSX
    # clean up after pair is transferred
    # rm -fv In${ref}_${sec}.tgz
elif [[ -d /staging/groups/geoscience/insar/TSX ]]; then
    mkdir -p /staging/groups/insar/${SITE}/TSX
    cp -v  $tgzfile /staging/groups/insar/${SITE}/TSX
    # clean up after pair is transferred
    #rm -fv $tgzfile
else
    echo "Cannot find a place to transfer tar file named $tgzfile"
    # clean up 
    # rm -rf In${ref}_${sec}
fi
exit 0
