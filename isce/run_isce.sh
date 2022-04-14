#!/bin/bash -vx
# run ISCE inside container
# 20210809 update SLCdir
# 20211006 fix SLCdir

if [[  ( "$#" -eq 1)  ]]; then
    site=$1
    # launch date of Sentinel 1-A is April 3, 2014
    YYYYMMDD1="2014-04-03"
    YYYYMMDD2="2029-12-31" # T23:59:59.999999"
    echo YYYYMMDD1 is ${YYYYMMDD1}
    echo YYYYMMDD2 is ${YYYYMMDD2}
    slcdir="../SLC"
elif [[  ( "$#" -eq 3)  ]]; then
    site=$1
    t0=$2
    t1=$3
    YYYYMMDD1=`echo $t0 |  awk '{ printf("%4d-%02d-%02d\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'`
    #YYYYMMDD2=`echo $t1 |  awk '{ printf("%4d-%02d-%02dT23:59:59.999999\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'`
    YYYYMMDD2=`echo $t1 |  awk '{ printf("%4d-%02d-%02d\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'`
    echo YYYYMMDD1 is ${YYYYMMDD1}
    echo YYYYMMDD2 is ${YYYYMMDD2}
    slcdir="../SLC_${t0}_${t1}"
else
    bname=`basename $0`
    echo "$bname run ISCE "
    echo "usage:   $bname site5"
    echo "usage:   $bname cosoc"
    exit -1
fi

timetag=`date +"%Y%m%dT%H%M%S"`
echo timetag is ${timetag}
echo slcdir is $slcdir


# get working version of ssara client
#cp -rp /home/feigl/SSARA-master $HOME
#export PYTHONPATH=$HOME/ssara_client



# # configure environment 
# source /opt/isce2/isce_env.sh
# export PATH=/opt/isce2/src/isce2/contrib/stack/topsStack:$PATH

# test
which stackSentinel.py
#stackSentinel.py --help | tee stackSentinel.txt 

# very clean start
#rm -rf orbits ORBITS isce.log baselines configs merged stack run_files interferograms coreg_secondarys secondarys geom_reference reference
# clean start
rm -rf isce.log baselines configs merged stack run_files interferograms coreg_secondarys secondarys geom_reference reference

# count SLC
nSLC=`ls ${slcdir} | wc -l`
echo "number of SLC files nSLC is $nSLC"

# echo "Looking for S1 files that are not zip in SLC folder"
# find .. -name "S1*V_*" | grep -v .zip

# get bounding box
#bbox="$(get_site_dims.sh cosoc S) $(get_site_dims.sh cosoc N) $(get_site_dims.sh cosoc W) $(get_site_dims.sh cosoc E)"
bbox="$(get_site_dims.sh ${site} S) $(get_site_dims.sh ${site} N) $(get_site_dims.sh ${site} W) $(get_site_dims.sh ${site} E)"
echo "Bounding box bbox is $bbox"

# get DEM 
#dem=`grep ${site} $HOME/FringeFlow/siteinfo/site_dems.txt | awk '{print $3}'`
# TODO update this
#dem=`grep ${site} $HOME/siteinfo/site_dems.txt | awk '{print $3}'`
dem=`ls ../DEM/dem*.wgs84 | head -1`
echo "DEM file name dem is $dem"
if [[ ! -f $dem ]]; then
    echo "ERROR: could not find DEM file named $dem"
fi

# TODO: check that -b should not be --box or other
stackSentinel.py -w ./ -s ${slcdir} -a ../AUX/ -o ../ORBITS/ -z 2 -r 6 -c all \
-C geometry -d ${dem} \
-b "${bbox}" \
--start "${YYYYMMDD1}" --stop "${YYYYMMDD2}" \
-W interferogram
# -W slc only first two steps would calculate all baselines


# set up a script to run all the scripts
ls -1 run_files/* | grep -v job | awk '{print "bash",$1}' > run_isce_jobs.sh
chmod a+x run_isce_jobs.sh

# NICKB: encountered this during run_isce_jobs.sh:
# Warning 1: Recode from CP437 to UTF-8 failed with the error: "Invalid argument".
# according to this ticket this should fix it:
# https://github.com/conda-forge/gdal-feedstock/issues/83
export CPL_ZIP_ENCODING=UTF-8

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
npairs=`ls -d merged/interferograms |  wc`
echo number of pairs requested npairs is ${npairs} | tee -a run_isce_jobs.log 
npairs_unw=`ls merged/interferograms/*/filt_fine.unw | wc`
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
# if [ -f merged/interferograms/${t0}_${t1}/filt_fine.int ]; then
#     geocodeIsce.py -f merged/interferograms/${t0}_${t1}/filt_fine.int -d $dem -m ./reference -s ./secondarys/${t1}/ -a 2 -r 6 -b '40.348 40.449 -119.46 -119.375' 
#     mdx.py dem.crop -z -100 -wrap 6.28 -P
#     convert out.ppm merged/interferograms/${t0}_${t1}/filt_fine_geo_crop.jpg
# fi

plot_interferograms.sh





