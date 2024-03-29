#!/bin/bash -ve
# run ISCE inside container
# 20210809 update SLCdir
# 20211006 fix SLCdir
# 20220810 clean up
# 20230829 make it work with MintPy under MAISE
#          try geocoding
bname=`basename $0`

Help()
{
   # Display Help
    echo "$bname runs ISCE"
    echo "usage:   $bname SITE MISSION TRACK YYYYMMDD1 YYYYMMDD2"
    echo "example: $bname SANEM     S1   144  20220331 20220506"
    echo "example: $bname SANEM     S1   144  20220331 20220506 ../SLC "
    echo "example: $bname SANEM     S1   144  20220331 20220506 ../SLC 4"
    exit -1
  }

if [[  ( "$#" -ge 5)  && ( "$#" -le 7) ]]; then
    SITELC=`echo $1 | awk '{ print tolower($1) }'`         
    SITEUC=`echo $1 | awk '{ print toupper($1) }'`
    MISSION=$2
    TRACK=$3
    YYYYMMDD1=$4
    # add one day https://stackoverflow.com/questions/18706823/how-to-increment-a-date-in-a-bash-script
    #YYYYMMDD2=`date +%Y%m%d -d "$5 UTC + 1 day"`
    YYYYMMDD2=$5
   
    #write dates as YYYY-MM-DD
    date_first=`echo $YYYYMMDD1 | awk '{ printf("%4d-%02d-%02d\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'`
    date_last=`echo $YYYYMMDD2 |  awk '{ printf("%4d-%02d-%02d\n",substr($1,1,4),substr($1,5,2),substr($1,7,2)) }'`

   if [[  ( "$#" -ge 6) ]]; then
      SLCDIR=$6
   else
      mkdir -p ../SLC
      SLCDIR=../SLC
   fi
   if [[  ( "$#" -ge 7) ]]; then
      NPROC=$7
   else
      NPROC=$(nproc)
   fi
else
   Help
fi

echo YYYYMMDD1 is ${YYYYMMDD1}  date_first is ${date_first}
echo YYYYMMDD2 is ${YYYYMMDD2}  date_last  is ${date_last}

# set number of connections
if [[ -n ${STACK_SENTINEL_NUM_CONNECTIONS+set} ]]; then
   echo STACK_SENTINEL_NUM_CONNECTIONS  is $STACK_SENTINEL_NUM_CONNECTIONS
else
   export STACK_SENTINEL_NUM_CONNECTIONS=5
fi
echo STACK_SENTINEL_NUM_CONNECTIONS is ${STACK_SENTINEL_NUM_CONNECTIONS}

timetag=`date +"%Y%m%dT%H%M%S"`
echo timetag is ${timetag}

# set folder for SLC zip files
if [[ -n ${SLCDIR+set} ]]; then
   echo inheriting SLCDIR to be $SLCDIR      
else
   export SLCDIR="../SLC"
fi
echo SLCDIR is ${SLCDIR}
if [[ -d ${SLCDIR} ]]; then
   echo SLCDIR named $SLCDIR exists
else
   echo $bname ERROR 
   
fi

# count SLC
nSLC=`ls ${SLCDIR} | wc -l`
echo "number of SLC files nSLC is $nSLC"

if [[ ${nSLC} -lt 3 ]]; then
   echo $bname ERROR need at least 3 SLC files to analyze
   exit -1
fi

# echo "Looking for S1 files that are not zip in SLC folder"
# find .. -name "S1*V_*" | grep -v .zip


# NICKB: encountered this during run_isce_jobs.sh:
# Warning 1: Recode from CP437 to UTF-8 failed with the error: "Invalid argument".
# according to this ticket this should fix it:
# https://github.com/conda-forge/gdal-feedstock/issues/83
export CPL_ZIP_ENCODING=UTF-8


# # test
# ( which stackSentinel.py 2>&1 ) && ( echo "OK"; exit 0 ) || (err=$?; echo "ERROR $err"; (exit $err))

# very clean start
#rm -rf orbits ORBITS isce.log baselines configs merged stack run_files interferograms coreg_secondarys secondarys geom_reference reference
# clean start
\rm -rfv isce.log baselines configs merged stack run_files interferograms coreg_secondarys secondarys geom_reference reference

# get bounding box
bbox="$(get_site_dims.sh ${SITELC} S) $(get_site_dims.sh ${SITELC} N) $(get_site_dims.sh ${SITELC} W) $(get_site_dims.sh ${SITELC} E)"
echo "Bounding box bbox is $bbox"

# # get DEM 
# #dem=`grep ${site} $HOME/FringeFlow/siteinfo/site_dems.txt | awk '{print $3}'`
# # TODO update this
# #dem=`grep ${site} $HOME/siteinfo/site_dems.txt | awk '{print $3}'`
# DEM file must be local
\cp -vf ../DEM/dem* .
demfile=`ls dem*.wgs84 | head -1`
echo "DEM file name dem is $demfile"
if [[ ! -f ${demfile} ]]; then
    echo "ERROR: could not find DEM file named $demfile"
    exit -1
fi


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

# # Eventually we will want to do ionospheric corrections
if [[ -f $HOME/FringeFlow/isce/ion_param.txt ]]; then
   cp $HOME/FringeFlow/isce/ion_param.txt .
elif [[ -f /root/FringeFlow/isce/ion_param.txt  ]]; then
   cp /root/FringeFlow/isce/ion_param.txt  .
else
   echo error cannot find ion_param.txt
   exit -1
fi

stackSentinel.py -w ./ \
    -d ${demfile} \
    -s ${SLCDIR}   \
    -a ../AUX/     \
    -o ../ORBITS/  \
    -c "$STACK_SENTINEL_NUM_CONNECTIONS" \
    --filter_strength 0 \
    --azimuth_looks 5 \
    --range_looks 20 \
    --num_proc $NPROC \
    --num_process4topo 1 \
    -C geometry \
    -b "${bbox}" \
    --start "${date_first}" \
    --stop  "${date_last}" \
    --param_ion ./ion_param.txt \
    -W interferogram

# ionospheric correction not available yet
# --param_ion ./ion_param.txt \
# -W slc only first two steps would calculate all baselines


# set up a script to run all the scripts
ls -1 run_files/* | grep -v job | awk '{print "bash",$1, "2>&1 | tee "$1".log"}' > run_isce_jobs.sh
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
npairs=`ls -d merged/interferograms/* |  wc -l`
echo number of pairs requested npairs is ${npairs} | tee -a run_isce_jobs.log 
npairs_unw=`ls merged/interferograms/*/filt_fine.unw | wc -l `
echo number of pairs completed npairs_unw is ${npairs_unw} | tee -a run_isce_jobs.log 

# graphics output
# mdx.py interferograms/20181006_20181018/IW3/fine_01.int -z -100 -wrap 6.28 -P
# convert out.ppm out.pdf
# convert out.ppm out.jpg
# ls -l out.*
#display out.jpg

plot_interferograms.sh

# geocode
#geocodeIsce.py -f merged/interferograms/20190110_20190122/filt_fine.int -d demLat_N40_N41_Lon_W120_W119.dem.wgs84 -m ./reference -s ./secondarys/20190122/ -a 2 -r 6 -b '40.348 40.449 -119.46 -119.375' 
#convert out.ppm merged/interferograms/20190110_20190122/filt_fine.dem.crop.jpg
# if [ -f merged/interferograms/${t0}_${t1}/filt_fine.int ]; then
#     geocodeIsce.py -f merged/interferograms/${t0}_${t1}/filt_fine.int -d $dem -m ./reference -s ./secondarys/${t1}/ -a 2 -r 6 -b '40.348 40.449 -119.46 -119.375' 
#     mdx.py dem.crop -z -100 -wrap 6.28 -P
#     convert out.ppm merged/interferograms/${t0}_${t1}/filt_fine_geo_crop.jpg
# fi







