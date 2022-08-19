#!/bin/bash -vx
if [[  "$#" -ne 5 ]]; then
    bname=`basename $0`
    echo "$bname will retrieve ARIA products prepare them for mintpy"
    echo "usage:   $bname SAT TRK SITE start_YYYYMMDD stop_YYYYMMDD "
    echo "example: $bname S1 144 SANEM 20160101 --end 20220601"
    echo " need to do this first"
    echo "conda activate ARIA-tools"
    exit -1
fi


export sat=$1
export trk=$2
export site=$3
echo site is $site
export SITE=`echo $site | awk '{print tolower($1)}'`
echo SITE is $SITE
export t0=$4
export t1=$5

if [[ ! -d /System/Volumes/Data/mnt/t31/insar/${SITE}/S1/T${trk} ]]; then 
   mkdir -p /System/Volumes/Data/mnt/t31/insar/${SITE}/S1/T${trk}
fi
pushd /System/Volumes/Data/mnt/t31/insar/${SITE}/S1/T${trk}

# attempt to download ARIA products and 
# 20220810 Kurt Feigl

# https://nbviewer.org/github/aria-tools/ARIA-tools-docs/blob/master/JupyterDocs/NISAR/L2_interseismic/mintpySF/smallbaselineApp_aria.ipynb
#conda activate ARIA-tools

#site="sanem"
bbox="$(get_site_dims.sh ${site} S) $(get_site_dims.sh ${site} N) $(get_site_dims.sh ${site} W) $(get_site_dims.sh ${site} E)"
echo bbox is $bbox

do_download=1
if [[ do_download -eq 1 ]]; then
    #ariaDownload.py --bbox "${bbox}" --output url --start 20210401 --end 20210515 --track 144
    #ariaDownload.py --bbox "${bbox}" --output url --start 20160101 --end 20220601 --track 144 -l 400 -m 36
    #ariaDownload.py --bbox "${bbox}" --output url --start 20220101 --end 20220601 --track 137
    ariaDownload.py --bbox "${bbox}" --output url --start $t0 --end $t1 --track $trk
    pushd products

    urllist=`ls -tr *.txt | tail -1`
    echo urllist is $urllist

    if [[ -f ${urllist} ]]; then
        get_urls.sh $urllist
    fi 
    popd
fi


# Prepare ARIA products for time series processing.
#rm -rf unwrappedPhase connectedComponents coherence incidenceAngle azimuthAngle stack
ariaTSsetup.py -f 'products/*.nc' --bbox "${bbox}" --mask Download --layers all 


# mkdir -p mintpy
# pushd mintpy
# cp $HOME/FringeFlow/mintpy_aria.cfg
# smallbaselineApp.py mintpy_aria.cfg 

popd
