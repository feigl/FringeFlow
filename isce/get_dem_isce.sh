#!/bin/bash -ex
## 2022/08/09 Kurt Feigl

## get a DEM from somewhere

if [ "$#" -eq 1 ]; then
    export site5=`echo $1 | awk '{print tolower($1)}'`  
else
    bname=`basename $0`
    echo "$bname fetch a DEM "
    echo "usage:   $bname site5"
    echo "example:   $bname sanem"
    exit -1
fi

# set up paths and environment
if [[ -n ${_CONDOR_SCRATCH_DIR+set} ]]; then
    export HOME1=${HOME} 
    export HOME=${_CONDOR_SCRATCH_DIR}
fi
  
# make the DEM
echo "Getting a DEM from NASA"
echo dem.py -a stitch -b $(get_site_dims.sh $site5 i) -r -s 1 -c 
dem.py -a stitch -b $(get_site_dims.sh $site5 i) -r -s 1 -c 
dem=`ls dem*.wgs84 | head -1`

# Try alternative URL
# https://github.com/isce-framework/isce2/discussions/548#discussioncomment-3354637
if [[ -f  $dem ]]; then
    echo dem is $dem
else
    dem.py -a stitch -b $(get_site_dims.sh $site5 i) -r -s 1 -c -u http://step.esa.int/auxdata/dem/SRTMGL1/
    dem=`ls dem*.wgs84 | head -1`
fi

if [[ -f  $dem ]]; then
    echo dem is $dem
else
    if [[ ! -z "$SITE_DIR" ]]; then
        dem=`ls ${SITE_DIR}/${site5}/dem*.wgs84 | head -1`
        if [[ -f $dem ]]; then
            echo "Copying a DEM"
            cp -vf $dem .
        else
            error cannot find dem named $dem
            exit -1
        fi
    else
        echo Error environment variable SITE_DIR is not set
        exit -1
    fi
fi

# reset environment variable
if [[ -n ${_CONDOR_SCRATCH_DIR+set} ]]; then
    export HOME=${HOME1}
fi

