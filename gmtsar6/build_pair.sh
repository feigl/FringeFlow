#!/bin/bash 

# for debugging, add "-vx" switch after "bash" in the shebang line above.
# switches in line above:
#      -e exit on error
#      -v verbose
#      -x examine

# based on /home/batzli/bin_htcondor/run_pair_gmtsarv60.sh
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

### 2021/07/08 ***
# change name of script to build_pair.sh 
# clean out anything not related to TSX
# This script builds a directory for a run
# This script does not actually run GMTSAR

if [[ ! $# -eq 14 ]] ; then
    echo '	ERROR: $0 requires 14 arguments.'
    echo "  Number of arguments actually received ${#}"
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
itrk=`echo $trk | sed 's/T//'` 
# set reference and secondary variables
ref=${3}
sec=${4}
orb1a=`expr $ref - 1`  
orb2a=`expr $sec - 1`
user=${5}
satparam=${6} # extra parameter for satellite specific parameters (e.g., for S1A satparam = subswath number)
# remove underscore
swath=`echo $satparam | sed 's/_//'`
#echo "swath is $swath"

demf=${7}
# set filter wavelength
filter_wv=${8}
# set region variables
xmin=${9}
xmax=${10}
ymin=${11}
ymax=${12}
site=${13}
SITE=`echo ${site} | awk '{ print toupper($1) }'`
unwrap=${14}

# set remote user on chtc
if [[ ${USER} = "batzli" ]]; then
   ruser="sabatzli"
else
   ruser=${USER}
fi

# set data directory
if [[ $(hostname) = "askja.ssec.wisc.edu" ]]; then
    export DATADIR=/s12
else
    export DATADIR=${HOME}
fi
#echo "DATADIR is $DATADIR"

# make a directory for this pair
pairdir=${SITE}_${sat}_${trk}_${swath}_${ref}_${sec}
echo "pairdir is $pairdir"

# do this for debugging
# touch ${pairdir}.tgz
# date > ${pairdir}.sub

if [[ ! -f ${pairdir}.tgz ]]; then
    mkdir -p ${pairdir}
    cd ${pairdir}

    # copy PAIRSmake.txt
    cp -v ../PAIRSmake.txt .

    # copy cut grid file
    mkdir -p dem 
    cd dem
    cp ${DATADIR}/insar/dem/cut_$demf ./$demf
    cd ..

    ## get data from askja
    mkdir -p RAW
    cd RAW
    longfilename1=`grep -i ${site} ${DATADIR}/insar/TSX/TSX_OrderList.txt | grep ${ref} | awk '{print $12}'`
    #echo "longfilename1 is $longfilename1"
    if [[ ! -d $longfilename1 ]]; then
        echo "ERROR $0 Cannot find $longfilename1"
        exit -1
    fi
    cp -r $longfilename1 .

    ## get secondary data to working directory
    longfilename2=`grep -i ${site} ${DATADIR}/insar/TSX/TSX_OrderList.txt | grep ${sec} | awk '{print $12}'`
    #echo "longfilename2 is $longfilename2"
    if [[ ! -d $longfilename2 ]]; then
        echo "ERROR $0 Cannot find $longfilename2"
        exit -1
    fi
    cp -r $longfilename1 .

    cp -r $longfilename2 .
    cd ../

    # run a script to write a script (run.sh)
    write_run_script.sh ${sat} ${ref} ${sec} ${satparam} dem/${demf} ${filter_wv} ${site} ${xmin} ${xmax} ${ymin} ${ymax} ${unwrap}

    # copy the FringeFlow scripts, excluding source code control stuff in .git folder
    rsync --exclude=".git" -ra ${HOME}/FringeFlow .

    # copy the bin_htcondor scripts, excluding source code control stuff in .git folder
    rsync --exclude=".git" -ra /home/batzli/bin_htcondor .

    # copy makefile for plotting routines
    # cd In${ref}_${sec}
    # cp /home/batzli/bin_htcondor/plotting.make .
    # cd ..

    # copy setup file
    cp  ${HOME}/FringeFlow/docker/setup_inside_container_gmtsar.sh .

    # make a tar file
    tgzfile=${pairdir}.tgz
    echo "Making tar file named ${tgzfile}"
    tar -czf ../$tgzfile ./
    cd ..

    # transfer the tar file
    if [[ $(hostname) = "askja.ssec.wisc.edu" ]]; then
        mkdir -p /s12/insar/
        cp -f  $tgzfile /s12/insar/
        #ssh ${ruser}@transfer.chtc.wisc.edu mkdir -p /staging/groups/geoscience/insar
        rsync --progress -av $tgzfile ${ruser}@transfer.chtc.wisc.edu:/staging/groups/geoscience/insar
        # clean up after pair is transferred
        #rm -f $tgzfile
    else
        echo "Cannot find a place to transfer tar file named $tgzfile"
    fi

    # send the executable to CHTC
    #rsync -ra /home/feigl/FringeFlow/gmtsar6/run_pair_gmtsar.sh ${ruser}@submit-2.chtc.wisc.edu:

    # make a submit file 
    cat ${HOME}/FringeFlow/gmtsar6/run_pair_gmtsar_TEMPLATE.sub | sed "s/pairdir/${pairdir}/" > ${pairdir}.sub
    # send submit file to CHTC
    # rsync -ra ${pairdir}.sub ${ruser}@submit-2.chtc.wisc.edu:
fi

#echo "Current working directory is now ${PWD}"
# submit the job
# The next line of code fails to return
#ssh -T submit-2.chtc.wisc.edu "condor_submit ${pairdir}.sub" 
# use try "-t" swicth this instead
if [[ -f ${pairdir}.sub ]]; then
    #ls -l ${pairdir}.sub
    #ssh -v ${ruser}@submit-2.chtc.wisc.edu 'ls -l *.sub'
    #echo "ls -l ${pairdir}.sub" | ssh -t ${ruser}@submit-2.chtc.wisc.edu  
    #echo "condor_submit ${pairdir}.sub" | ssh -t ${ruser}@submit-2.chtc.wisc.edu 
    echo "condor_submit ${pairdir}.sub" >> submit_all.sh
fi
# check on status of jobs
# ssh submit-2.chtc.wisc.edu "condor_q"
