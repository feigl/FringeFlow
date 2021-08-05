#!/bin/bash -vx
## 2021/08/05 Kurt Feigl

# Run epochs for MINTPY
bname=`basename $0`
if [[  ( "$#" -eq 1)  ]]; then
   export CFG=$1
   export STEP="load_data"  
elif [[  ( "$#" -eq 2)  ]]; then
  export CFG=$1
  export STEP=$2
else
    echo "$bname will run mintpy "
    echo "usage:   $bname config.cfg step_name"
    echo "example: $bname FORGE_20210719_ERA5.cfg load_data"
    echo "example: $bname FORGE_20210719_ERA5.cfg quick_overview"
    exit -1
#   ['load_data', 'modify_network', 'reference_point', 'quick_overview', 'correct_unwrap_error']
#   ['invert_network', 'correct_LOD', 'correct_SET', 'correct_troposphere', 'deramp', 'correct_topography']
#   ['residual_RMS', 'reference_date', 'velocity', 'geocode', 'google_earth', 'hdfeos5']
fi

echo "Config file CFG is $CFG"
echo "STEP is ${STEP}"

# clean start
rm -rf pic isce.log

# TODO test on STEP
#rm -rf inputs

# copy keys for ERA PYAPS
if [ -f ../model.cfg ]; then
   cp -v ../model.cfg /home/ops/PyAPS/pyaps3/model.cfg
fi
if [ -f model.cfg ]; then
   cp -v model.cfg /home/ops/PyAPS/pyaps3/model.cfg
fi

export WEATHER_DIR="${PWD}/../ERA5"

# # Add meta data to configuration file
# head SANEM_T144f_askja.cfg 
# ########## 1. load_data
# ##---------add attributes manually
# ## MintPy requires attributes listed at: https://mintpy.readthedocs.io/en/latest/api/attributes/
# ## Missing attributes can be added below manually (uncomment #), e.g.
# # ORBIT_DIRECTION = ascending
# PLATFORM                =    SENTINEL
# PROJECT_NAME            =    SANEM_T144f_askja
# ISCE_VERSION            =    2.4.2

export TTAG=`date +"%Y%m%dT%H%M%S"`
echo TTAG is ${TTAG}

echo "Starting smallbaselineApp.py now "
smallbaselineApp.py  ${CFG} --start ${STEP} | tee smallbaselineApp_${CFG}_${TTAG}.log