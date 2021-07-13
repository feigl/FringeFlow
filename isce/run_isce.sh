#!/bin/bash -vx
# run ISCE inside container

echo "Starting script named $0"
echo "PWD is  $PWD"
echo "Echo results of ls -l follow"
ls -l
du -sh *

# configure environment 
source /opt/isce2/isce_env.sh
export PATH=/opt/isce2/src/isce2/contrib/stack/topsStack:$PATH

# test
which stackSentinel.py
#stackSentinel.py --help | tee stackSentinel.txt 

# very clean start
#rm -rf orbits ORBITS isce.log baselines configs merged stack run_files interferograms coreg_secondarys secondarys geom_reference reference
# clean start
rm -rf isce.log baselines configs merged stack run_files interferograms coreg_secondarys secondarys geom_reference reference

# count SLC
export nSLC=`ls SLC | wc -l`
echo "number of SLC files nSLC is $nSLC"

echo "looking for files that are not zip in SLC folder"
find SLC -ls | grep -v .zip

# Carry only a small subset of orbits
# this is still hard-wired for SANEM with these switches: 
# -n 3 (swath) 
# -b (bounding box)
# -d dem
stackSentinel.py -w ./ -s ../SLC/ -a aux/ -o ../ORBITS \
-n 3 -z 2 -r 6 -c 1 -C geometry  -b '40.348 40.449 -119.46 -119.375' \
-d demLat_N40_N41_Lon_W120_W119.dem.wgs84   

#--start ${YYYYMMDD1} --stop ${YYYYMMDD2}

# set up a script to run all the scripts
ls -1 run_files/* | grep -v job | awk '{print "bash",$1}' > run_isce_jobs.sh
chmod a+x run_isce_jobs.sh

#run the script
echo "starting script named ./run_isce_jobs.sh" | tee run_isce_jobs.log 
date | tee -a run_isce_jobs.log 
./run_isce_jobs.sh | tee -a run_isce_jobs.log 

# quality control
echo "script named ./run_isce_jobs.sh has completed" | tee -a run_isce_jobs.log 
date | tee -a run_isce_jobs.log 


grep -i error isce.log   | tee -a run_isce_jobs.log 
grep -i warning isce.log | tee -a run_isce_jobs.log 
# timing
head -1 isce.log | tee -a run_isce_jobs.log 
tail -1 isce.log | tee -a run_isce_jobs.log 


# count number of interferograms
export npairs=`ls -d merged/interferograms |  wc`
echo number of pairs requested npairs is ${npairs} | tee -a run_isce_jobs.log 
export npairs_unw=`ls merged/interferograms/*/filt_fine.unw | wc`
echo number of pairs completed npairs_unw is ${npairs_unw} | tee -a run_isce_jobs.log 

# graphics output
# mdx.py interferograms/20181006_20181018/IW3/fine_01.int -z -100 -wrap 6.28 -P
# convert out.ppm out.pdf
# convert out.ppm out.jpg
# ls -l out.*
#display out.jpg

# geocode
#geocodeIsce.py -f merged/interferograms/20190110_20190122/filt_fine.int -d demLat_N40_N41_Lon_W120_W119.dem.wgs84 -m ./reference -s ./secondarys/20190122/ -a 2 -r 6 -b '40.348 40.449 -119.46 -119.375' 
#convert out.ppm merged/interferograms/20190110_20190122/filt_fine.dem.crop.jpg
if [ -f merged/interferograms/${t0}_${t1}/filt_fine.int ]; then
    geocodeIsce.py -f merged/interferograms/${t0}_${t1}/filt_fine.int -d demLat_N40_N41_Lon_W120_W119.dem.wgs84 -m ./reference -s ./secondarys/${t1}/ -a 2 -r 6 -b '40.348 40.449 -119.46 -119.375' 
    mdx.py dem.crop -z -100 -wrap 6.28 -P
    convert out.ppm merged/interferograms/${t0}_${t1}/filt_fine_geo_crop.jpg
fi

#2021-03-13 00:53:09,018 - isce.zerodop.topozero - WARNING - Default Peg heading set to: -2.90493584856863
#2021-03-13 02:24:23,944 - isce.mroipac.correlation - INFO - Calculating Correlation
# less than 2 hours for 7 aquisitions
#2021-03-18 18:06:31,974 - isce.zerodop.topozero - WARNING - Default Peg heading set to: -2.90493584856863
#2021-03-18 18:17:52,645 - isce.mroipac.correlation - INFO - Calculating Correlation
# less than 7 minutes for 2 SLCs




