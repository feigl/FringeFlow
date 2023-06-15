#!/bin/bash -x 

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

# 2021/11/03 Kurt and Sam add siteinfo to tarball
# 2021/11/16 Kurt and Sam designed (but not implemented auto-submit in four places in if statements at end of this file)
# 2021/12/09 Sam attempted to implement auto-submit
# 2022/03/02 Sam added ${15} and ${16} to bring dt and bperp forward from build_pairs.sh and beyond to plot_pair7.sh and write_run_script.sh
# 2022/02/03 Kurt and Sam, update to make plots
# 2022/06/15 Sam commented out line 156
# 2023/01/10 Kurt and Sam - reduce number of remote commands requiring MFA
# 2023/06/15 Kurt add user name to /staging folder


if [[ ! $# -eq 16 ]] ; then
    echo '	ERROR: $0 requires 16 arguments.'
    echo "  Number of arguments actually received ${#}"
    echo '	Usage: $0 sat trk ref sec user satparam demf filter_wv xmin xmax ymin ymax site unwrap dt bperp'
    echo '	$1=sat'
    echo '	$2=trk'
    echo '	$3=ref (reference image date in YYYYMMDD) formerly mast' 
    echo '	$4=sec (secondary image date in YYYYMMDD) formerly slav'
    echo '	$5=user'
    echo '	$6=satparam (for TSX this is swath number)'
    echo '	$7=demf (DEM filename)'
    echo '	$8=filter_wv (filter wavelength)'
    echo '	$9,${10},${11},${12} are xmin xmax ymin ymax'
    echo '	${13}=site'
    echo '	${14}=unwrap (value or empty) default empty will not unwrap)'
    echo '      ${15}=dt (days between ref and sec)'
    echo '      ${16}=bperp (baseline in meters)'
    echo '	Example: $0 TSX T144 20180724 20181203 feigl strip_007R tusca_dem_3dep_10m.grd 80 -116.1900101030447 -116.0749982018097 41.41245177646995 41.49864121097495 tusca 0.12 132 -6.0'
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
dt=${15}
bperp=${16}

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
# touch ${pairdir}.tar
# date > ${pairdir}.sub

if [[ ! -f ${pairdir}.tar ]]; then
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
    write_run_script.sh ${sat} ${ref} ${sec} ${satparam} dem/${demf} ${filter_wv} ${site} ${xmin} ${xmax} ${ymin} ${ymax} ${unwrap} ${trk} ${dt} ${bperp} ${user}
    # TODO - add track to this command line 
    # 6/15/2022 commented out the line below
    #write_run_script.sh ${sat} ${ref} ${sec} ${satparam} dem/${demf} ${filter_wv} ${site} ${xmin} ${xmax} ${ymin} ${ymax} ${unwrap}

    # copy the FringeFlow scripts, excluding source code control stuff in .git folder
    rsync --exclude=".git" -ra ${HOME}/FringeFlow .

    # copy the bin_htcondor scripts, excluding source code control stuff in .git folder
    if [[ -d /home/batzli/bin_htcondor ]]; then
        rsync --exclude=".git" -ra /home/batzli/bin_htcondor .
    else
        echo ERROR could not find /home/batzli/bin_htcondor
        exit -1
    fi

    # copy the siteinfo directory
    # rsync -ra /home/batzli/siteinfo .
    # 2023/01/31 copy the user's siteinfo directory
    # rsync -ra ${HOME}/siteinfo .
    # 2023/06/13 assume a copy is already there

    # copy makefile for plotting routines
    # cd In${ref}_${sec}
    # cp /home/batzli/bin_htcondor/plotting.make .
    # cd ..

    # copy setup file - TODO this is already inside of FringeFlow
    cp  ${HOME}/FringeFlow/docker/setup_inside_container_gmtsar.sh .

    # make a file listing files to send to submit-2
    if [[ ! -f send2.lst ]]; then 
        touch send2.lst   
    fi
    # make a file listing files to send to transfer00
    if [[ ! -f send0.lst ]]; then 
        touch send0.lst
    fi

    # make a tar file
    tarfile=${pairdir}.tar
    echo "Making tar file named ${tarfile}"
    tar -cf ../$tarfile ./
    cd ..

    # transfer the tar file
    if [[ $(hostname) = "askja.ssec.wisc.edu" ]]; then
        mkdir -p /s12/insar/
        cp -vf  $tarfile /s12/insar/
        #ssh ${ruser}@transfer.chtc.wisc.edu mkdir -p /staging/groups/geoscience/insar
        #rsync --progress -av $tarfile ${ruser}@transfer.chtc.wisc.edu:/staging/groups/geoscience/insar
        rsync --progress -av $tarfile ${ruser}@transfer.chtc.wisc.edu:/staging/groups/geoscience/insar/${ruser}
        # clean up after pair is transferred
        #rm -f $tarfile
        # TODO
        # echo "$tarfile"  >> send0.lst

    else
        echo "Cannot find a place to transfer tar file named $tarfile"
    fi

    # send the executable to CHTC
    #echo "Now consider the following command"
    #echo "Now running the following command"
    # remove echo and quotes for auto submit
    #echo "rsync -ra /home/feigl/FringeFlow/gmtsar6/run_pair_gmtsar.sh ${ruser}@submit-2.chtc.wisc.edu:"
    #rsync -ra /home/feigl/FringeFlow/gmtsar6/run_pair_gmtsar.sh ${ruser}@submit-2.chtc.wisc.edu:

    # make a submit file 
    cat ${HOME}/FringeFlow/gmtsar6/run_pair_gmtsar_TEMPLATE.sub | sed "s/pairdir/${pairdir}/" > ${pairdir}.sub

    # send submit file to CHTC
    #echo "Now consider the following command"
    #echo "Now running the following command"
    # remove echo and quotes for auto submit
    #echo "rsync -ra ${pairdir}.sub ${ruser}@submit-2.chtc.wisc.edu:"
    #rsync -ra ${pairdir}.sub ${ruser}@submit-2.chtc.wisc.edu:

    # transfer two files
    # rsync -rav ${pairdir}.sub ${HOME}/FringeFlow/gmtsar6/run_pair_gmtsar.sh ${ruser}@submit-2.chtc.wisc.edu:
    # 2023/06/13 FringeFlow folder now transfered via transfer_input_file command in .sub file
    rsync -rav ${pairdir}.sub ${ruser}@submit-2.chtc.wisc.edu:
    # TODO
    # echo "${pairdir}.sub"  >> send2.lst
fi

#echo "Current working directory is now ${PWD}"
# submit the job
# The next line of code fails to return
#ssh -T submit-2.chtc.wisc.edu "condor_submit ${pairdir}.sub" 
# use try "-t" switch this instead
if [[ -f ${pairdir}.sub ]]; then
    #ls -l ${pairdir}.sub
    #ssh -v ${ruser}@submit-2.chtc.wisc.edu 'ls -l *.sub'
    #uncomment the next two lines for auto submit
    #echo "ls -l ${pairdir}.sub" | ssh -t ${ruser}@submit-2.chtc.wisc.edu  
    #echo "condor_submit ${pairdir}.sub" | ssh -t ${ruser}@submit-2.chtc.wisc.edu 
    #comment the following line for auto submit
    echo "condor_submit ${pairdir}.sub" >> submit_all.sh
fi
# check on status of jobs
# ssh submit-2.chtc.wisc.edu "condor_q"
