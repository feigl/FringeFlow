#!/bin/bash -vx

# get 1 SLC file from askja
#2021/06/10 Kurt Feigl

if [ "$#" -ne 4 ]; then
    bname=`basename $0`
    echo "$bname get an SLC file "
    echo "usage:   $bname SAT TRK SITE YYYYMMDD"
    echo "example: $bname S1 144 SANEM 20190110"

    exit -1
fi

#export YYYYMMDD1="2019-10-02"
#export YYYYMMDD2="2019-11-16"

echo "Starting script named $0"
echo "Arguments are $1 $2 $3 $4"
echo PWD is ${PWD}
echo HOME is ${HOME} 

# export t0=20190110
# export t1=20190122
export sat=$1
export trk=$2
export sit=$3
export t0=$4


echo sat is $sat
echo trk is $trk
echo sit is $sit
echo t0 is $t0

# count number of files already here
shopt -s nullglob
slcfiles=(SLC/*V_${t0}*.zip )
nfiles=${#slcfiles[@]}
#echo ${#slcfiles[@]}
echo "number of existing SLC files already here is $nfiles"

if ( test $nfiles -lt 1 ); then
    sync -rav -e "ssh -l feigl" feigl@askja.ssec.wisc.edu:/s12/insar/${sit}/${sat}/SLC/${sat}'*'V_${t0}'*'.zip SLC
fi

exit 0
