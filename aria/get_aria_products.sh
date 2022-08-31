#!/bin/bash -vx


# attempt to download ARIA products and 
# 20220810 Kurt Feigl

# https://nbviewer.org/github/aria-tools/ARIA-tools-docs/blob/master/JupyterDocs/NISAR/L2_interseismic/mintpySF/smallbaselineApp_aria.ipynb
#conda activate ARIA-tools

# example of bounding box
#ariaDownload.py --bbox "36.75 37.225 -76.655 -75.928"

# get small bounding box - study area only
# site="sanem"
# bbox="$(get_site_dims.sh ${site} S) $(get_site_dims.sh ${site} N) $(get_site_dims.sh ${site} W) $(get_site_dims.sh ${site} E)"
# echo bbox is $bbox
#bbox is 40.3480000000 40.4490000000 -119.4600000000 -119.3750000000

# get bounding box from SSARA covering whole scene
#run_ssara.sh sanem S1 144 20190110  20190122 download
#grep LineString ssara_search_20220828200348.kml
#<LineString><tessellate>1</tessellate><coordinates>-120.004097,40.137749,0 -119.664558,41.756149,0 -116.649643,41.361141,0 -117.064262,39.741959,0 -120.004097,40.137749,0 </coordinates></LineString>
#bbox="40.137749 41.756149 -120.004097 -116.649643"

# medium size 
bbox="40.2 40.6 -119.7 -119.3"
do_download=1
if [[ do_download -eq 1 ]]; then
    #ariaDownload.py --bbox "${bbox}" --output url --start 20210401 --end 20210515 --track 144
    ariaDownload.py --bbox "${bbox}" --output url --start 20140101 --end 20220601 --track 144
    #ariaDownload.py --bbox "${bbox}" --output url --start 20140101 --end 20220630 --track 137
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
ariaTSsetup.py -f "products/*.nc" --bbox "${bbox}" --mask Download --layers all 




# I have downloaded 773 ARIA products with ariaDownload.py. But when I use smallbaselineApp
# ariaDownload.py --bbox "40.2 40.6 -119.7 -119.3" --output url --start 20140101 --end 20220601 --track 144

# (base) mambauser@25443de73af5:/System/Volumes/Data/mnt/t31/insar/SANEM/ARIA/T144/MINTPY$ ls ../products/*.nc | wc
#     773     773   69570

# But I only 99 interferograms load.

# WARNING: 672 out of 773 GUNW products rejected for not meeting users bbox spatial criteria

echo "conda deactivate "
echo "mkdir -p MINTPY"
echo "pushd MINTPY"
echo "load_start_container_aria.sh"
echo "cp $HOME/FringeFlow/mintpy/mintpy_aria.cfg ."
echo "run_mintpy.sh mintpy_aria.cfg " 
# Warning 1: Invalid band number. Got 1050, expected 1015. Ignoring provided one, and using 1015 instead
# Warning 1: Invalid band number. Got 1051, expected 1016. Ignoring provided one, and using 1016 instead
# More than 1000 errors or warnings have been reported. No more will be reported from now.
