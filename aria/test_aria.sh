#!/bin/bash -vx

# clean start
rm -rf unwrappedPhase connectedComponents coherence incidenceAngle azimuthAngle stack mask user_bbox.json productBoundingBox amplitude bParallel products

# attempt to download ARIA products and 
# 20220810 Kurt Feigl

# https://nbviewer.org/github/aria-tools/ARIA-tools-docs/blob/master/JupyterDocs/NISAR/L2_interseismic/mintpySF/smallbaselineApp_aria.ipynb
#conda activate ARIA-tools

# example of bounding box
#ariaDownload.py --bbox "36.75 37.225 -76.655 -75.928"

# get small bounding box - study area only
# echo bbox is $bbox
#bbox="40.3480000000 40.4490000000 -119.4600000000 -119.3750000000"

# get bounding box from SSARA covering whole scene
#run_ssara.sh sanem S1 144 20190110  20190122 download
#grep LineString ssara_search_20220828200348.kml
#<LineString><tessellate>1</tessellate><coordinates>-120.004097,40.137749,0 -119.664558,41.756149,0 -116.649643,41.361141,0 -117.064262,39.741959,0 -120.004097,40.137749,0 </coordinates></LineString>
bbox="40.137749 41.756149 -120.004097 -116.649643"


do_download=1
if [[ do_download -eq 1 ]]; then
    #ariaDownload.py --bbox "${bbox}" --output url --start 20210401 --end 20210515 --track 144
    ariaDownload.py -v --bbox "${bbox}" --output url --start 20140101 --end 20160101 --track 144 
    #ariaDownload.py --bbox "${bbox}" --output url --start 20140101 --end 20220601 --track 144 -v
    #ariaDownload.py --bbox "${bbox}" --output url --start 20140101 --end 20220630 --track 137
    pushd products

    urllist=`ls -tr *.txt | tail -1`
    echo urllist is $urllist

    if [[ -f ${urllist} ]]; then
        get_urls.sh $urllist
    fi 

    popd
fi



#ariaPlot.py -v -f "products/*.nc" -plotall  --figwidth=wide -nt 1
#mv -vf figures figures_all

# study area only
#ariaPlot.py -v -f "products/*.nc" --bbox "${bbox}"  -plotall --figwidth=wide -nt 1

# Prepare ARIA products for time series processing.
#ariaTSsetup.py -f "products/*.nc" --bbox "${bbox}" --mask Download --layers all -v 
ariaTSsetup.py -f "products/*.nc"  --mask Download --layers all -v 

echo "conda deactivate "
echo "start container...."
echo "mkdir -p MINTPY"
echo "pushd MINTPY"
echo "load_start_container_aria.sh"
echo "cp $HOME/FringeFlow/mintpy/mintpy_aria.cfg ."
echo "run_mintpy.sh mintpy_aria.cfg " 

