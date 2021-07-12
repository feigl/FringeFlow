#!/bin/bash -vex
# run one insar pair using gmtsar v6
# 2021/07/08 Kurt Feigl
if [[ "$#" -eq 0 ]]; then
   bname=`basename ${0}`
    echo '	ERROR: $bname requires 2 or 3 arguments.'
    echo '	Usage: $bname SITE in.tgz [out.tgz]'
    echo '	$1=site code e.g., FORGE or SANEM'
    echo '	$2=input compressed tar file made by build_pairs.sh'
    echo '	$3=output compressed tar file (optional)'
    echo '  Both tar files will be staged at transfer.chtc.wisc.edu:/staging/groups/geoscience/insar/TSXh'
    echo '	Example: $bname FORGE In20200415_20210505_in.tgz In20200415_20210505_out.tgz'
elif [[ "$#" -le 3 ]]; then    
 
    site=`echo ${1} | awk '{ print toupper($1) }'`

    # input tar file
    tgz1=${2}

    # output tar file
    if [[ "$#" -eq 3 ]]; then
        tgz2=${3}
    else
        tgz2=`echo ${tgz1} | sed 's/_in/_out/'`
    fi

    # get name of In directory
    dname1=`basename ${tgz1}`
    dname=`echo ${dname1} | awk '{print substr($1,index($1,'_')-11,19)}'`
    echo "dname is ${dname}"

    # get the input file
    echo "Retrieving input tar file named ${tgz1} ..."
    if [[ $(hostname) = "askja.ssec.wisc.edu" ]]; then
        time cp -v  /s12/insar/${site}/TSX/${tgz1} .
    elif [[ -d /staging/groups/geoscience/insar/TSX ]]; then
        time mv -v  /staging/groups/insar/${site}/TSX/${tgz1} .
    else
        echo "Cannot find a input tar file named ${tgz1}"
        exit -1
    fi

    # uncompress tar file
    tar -xzvf $tgz1

    # change directory to pair directory
    cd ${dname}
    echo "Now in directory named $PWD"
    ls -l

    # run the script
    ./run.sh | tee run.log

    if [[ $(wc -c "run.log" | awk '{print $1}') -lt 1000 ]]; then
        echo "ERROR: something went wrong."
    fi

    # make a tar file containing output
    cd ..
    tar -czvf $tgz2 $dname

    # transfer the output file
    if [[ $(hostname) = "askja.ssec.wisc.edu" ]]; then
        mkdir -p /s12/insar/${SITE}/TSX
        cp -v  $tgz2 /s12/insar/${SITE}/TSX
        ssh ${ruser}@transfer.chtc.wisc.edu mkdir -p /staging/groups/geoscience/insar/TSX
        time rsync --progress -rav $tgzfile ${ruser}@transfer.chtc.wisc.edu:/staging/groups/geoscience/insar/TSX
        # clean up after pair is transferred
        # rm -fv In${ref}_${sec}.tgz
    elif [[ -d /staging/groups/geoscience/insar/TSX ]]; then
        mkdir -p /staging/groups/insar/${SITE}/TSX
        time cp -v  $tgz2 /staging/groups/insar/${SITE}/TSX
        # clean up after pair is transferred
        #rm -fv $tgzfile
    else
        echo "Cannot find a place to transfer output tar file named $tgz2"
        # clean up 
        # rm -rf In${ref}_${sec}
    fi

else
    echo "ERROR: wrong number of arguments"
    exit -1
fi