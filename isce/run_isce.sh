#!/bin/bash -vx
# run ISCE inside container
# 20210809 update SLCdir
# 20211006 fix SLCdir
# 20220810 clean up


if [[  ( "$#" -eq 1)  ]]; then
    #test case
    # S1  20 FORGE 20200101 20200130
    sat="S1"
    trk=20
    site="FORGE"
    t0=20200101
    t1=20200130
     slcdir="SLC_${sat}_${sit}_${trk}_${t0}_${t1}"
# elif [[  ( "$#" -eq 3)  ]]; then
#     #site=$1
#     site=`echo $1 | awk '{print tolower($1)}'`
#     t0=$2
#     t1=$3
#     slcdir="../SLC_${sit}_${t0}_${t1}"
elif [[  ( "$#" -eq 5)  ]]; then
    export sat=$1
    export trk=$2
    export sit=`echo $3 | awk '{print tolower($1)}'`
    export t0=$4
    export t1=$5
    slcdir="SLC_${sat}_${sit}_${trk}_${t0}_${t1}"
else
    bname=`basename $0`
    echo "$bname will ISCE"
    echo "usage:   $bname SAT TRK SITE reference_YYYYMMDD secondary_YYYYMMDD"
    echo "usage:   $bname S1  20 FORGE 20200101 20200130"
    exit -1
fi

echo slcdir is $slcdir

# make time tags with dashes
# launch date of Sentinel 1-A is April 3, 2014
# YYYYMMDD1="2014-04-03"
# YYYYMMDD2="2029-12-31" # T23:59:59.999999"
YYYYMMDD1=`echo $t0 |  awk '{ printf("%4d-%02d-%02d\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'`
#YYYYMMDD2=`echo $t1 |  awk '{ printf("%4d-%02d-%02dT23:59:59.999999\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'`
YYYYMMDD2=`echo $t1 |  awk '{ printf("%4d-%02d-%02d\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'`
echo YYYYMMDD1 is ${YYYYMMDD1}
echo YYYYMMDD2 is ${YYYYMMDD2}

# set number of connections
STACK_SENTINEL_NUM_CONNECTIONS=${STACK_SENTINEL_NUM_CONNECTIONS:=all}
echo STACK_SENTINEL_NUM_CONNECTIONS is ${STACK_SENTINEL_NUM_CONNECTIONS}

timetag=`date +"%Y%m%dT%H%M%S"`
echo timetag is ${timetag}


# # configure environment 
# source /opt/isce2/isce_env.sh
# export PATH=/opt/isce2/src/isce2/contrib/stack/topsStack:$PATH

# test
which stackSentinel.py
#stackSentinel.py --help | tee stackSentinel.txt 

# very clean start
#rm -rf orbits ORBITS isce.log baselines configs merged stack run_files interferograms coreg_secondarys secondarys geom_reference reference
# clean start
\rm -rfv isce.log baselines configs merged stack run_files interferograms coreg_secondarys secondarys geom_reference reference

# count SLC
nSLC=`ls ${slcdir} | wc -l`
echo "number of SLC files nSLC is $nSLC"

# echo "Looking for S1 files that are not zip in SLC folder"
# find .. -name "S1*V_*" | grep -v .zip

# get bounding box
#bbox="$(get_site_dims.sh cosoc S) $(get_site_dims.sh cosoc N) $(get_site_dims.sh cosoc W) $(get_site_dims.sh cosoc E)"
bbox="$(get_site_dims.sh ${site} S) $(get_site_dims.sh ${site} N) $(get_site_dims.sh ${site} W) $(get_site_dims.sh ${site} E)"
echo "Bounding box bbox is $bbox"

# # get DEM 
# #dem=`grep ${site} $HOME/FringeFlow/siteinfo/site_dems.txt | awk '{print $3}'`
# # TODO update this
# #dem=`grep ${site} $HOME/siteinfo/site_dems.txt | awk '{print $3}'`
dem=`ls ../DEM/dem*.wgs84 | head -1`
echo "DEM file name dem is $dem"
# if [[ ! -f $dem ]]; then
#     echo "ERROR: could not find DEM file named $dem"
# fi

# # TODO: check that -b should not be --box or other
# stackSentinel.py -w ./ -s ${slcdir} -a ../AUX/ -o ../ORBITS/ -z 2 -r 6 -c "$STACK_SENTINEL_NUM_CONNECTIONS" \
# -C geometry -d ${dem} \
# -b "${bbox}" \
# --start "${YYYYMMDD1}" --stop "${YYYYMMDD2}" \
# -W interferogram
# # -W slc only first two steps would calculate all baselines

## https://github.com/yuankailiu/hpc_isce_stack/blob/main/stack_sentinel_cmd.sh
# CPUS_PER_TASK_TOPO=4  # For each python process in the pool, how many CPUs to use
# NUM_PROCESS_4_TOPO=12 # MAX limited by no. of CPUs per node on HPC
# # It looks like this variable gets passed to a python multiprocessing pool, where it's used to process the number of bursts we have in the reference SLC (see topsStack/topo.py). In theory this means we'll get the fastest speeds if we set it equal to the number of bursts
# # But NOTE - the relevant step (run_01_unpack_topo_reference) has to be run on a single node, so we can't use more than 28 (or 32?) CPUs
# # If CPUS_PER_TASK=4, max NUM_PROCESS_4_TOPO=7 or 8
# # This variable gets passed to python multiprocess pool. We should give it the same number of CPUs I think?
# # If we don't set it, it's automatically set to NUM_PROCESS by ISCE
# AZIMUTH_LOOKS=5
# RANGE_LOOKS=20
# # c=No. of pairs per slc in igram network
# # num_connections_ion=no. of pairs in ionospehre igram network
# stackSentinel.py -s $SLC_DIR \
#     -d $DEM \
#     -o $ORBITS_DIR \
#     -a $AUX_DIR \
#     -b '26.5 33.1 33 38' \
#     -c 3 \
#     -x '20150807,20160215' \
#     --filter_strength 0 \
#     --azimuth_looks $AZIMUTH_LOOKS \
#     --range_looks $RANGE_LOOKS \
#     --num_process4topo $NUM_PROCESS_4_TOPO \
#     --stop_date 2022-07-01 \
#     --reference_date 20220102 \
#     --param_ion ./ion_param.txt \
#     --num_connections_ion 3 \
#     --useGPU

if [[ -f $HOME/FringeFlow/isce/ion_param.txt ]]; then
   cp $HOME/FringeFlow/isce/ion_param.txt .
else
   echo error cannot fine ion_param.txt
   exit -1
fi

stackSentinel.py -w ./ \
    -s ${slcdir}   \
    -a ../AUX/     \
    -o ../ORBITS/  \
    -c "$STACK_SENTINEL_NUM_CONNECTIONS" \
    --filter_strength 0 \
    --azimuth_looks 5 \
    --range_looks 20 \
    --num_process4topo 1 \
    -C geometry -d ${dem} \
    -b "${bbox}" \
    --start "${YYYYMMDD1}" \
    --stop  "${YYYYMMDD2}" \
    -W interferogram

# ionospheric correction not available yet
# --param_ion ./ion_param.txt \
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

echo After ISCE disk use is as follows
du -sh *

# check final output
find  ./baselines -type f -ls 
find  ./merged    -type f -ls 






