#!/bin/bash -vx


# attempt to download ARIA products and 
# 20220810 Kurt Feigl

# https://nbviewer.org/github/aria-tools/ARIA-tools-docs/blob/master/JupyterDocs/NISAR/L2_interseismic/mintpySF/smallbaselineApp_aria.ipynb
#conda activate ARIA-tools

site="sanem"
bbox="$(get_site_dims.sh ${site} S) $(get_site_dims.sh ${site} N) $(get_site_dims.sh ${site} W) $(get_site_dims.sh ${site} E)"

echo bbox is $bbox

do_download=1
if [[ do_download -eq 1 ]]; then
    #ariaDownload.py --bbox "${bbox}" --output url --start 20210401 --end 20210515 --track 144
    #ariaDownload.py --bbox "${bbox}" --output url --start 20160101 --end 20220601 --track 144
    ariaDownload.py --bbox "${bbox}" --output url --start 20140101 --end 20220630 --track 137
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

echo "conda deactivate "
echo "mkdir -p MINTPY"
echo "pushd MINTPY"
echo "load_start_container_aria.sh"
echo "cp $HOME/FringeFlow/mintpy/mintpy_aria.cfg"
echo "run_mintpy.sh smallbaselineApp.py mintpy_aria.cfg" 
# Warning 1: Invalid band number. Got 1050, expected 1015. Ignoring provided one, and using 1015 instead
# Warning 1: Invalid band number. Got 1051, expected 1016. Ignoring provided one, and using 1016 instead
# More than 1000 errors or warnings have been reported. No more will be reported from now.
