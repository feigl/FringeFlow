#!/bin/bash -vx
## 2021/05/25 Kurt Feigl

# Run epochs for MINTPY

### inside the container 
# prep_isce.py must have permissions to write ../isce

#source /opt/isce2/isce_env.sh
#export PATH=$PATH:$HOME/MintPy/mintpy/

# need this, too for PyAPS pyaps3
#export PYTHONPATH=$PYTHONPATH:$HOME/MintPy/mintpy/:$HOME/PyAPS
#export PYTHONPATH=$HOME/MintPy/mintpy/:$HOME/PyAPS

# clean start
rm -rf pic isce.log 
#rm -rf inputs

# copy keys for ERA PYAPS
if [ -f ../model.cfg ]; then
   cp -v ../model.cfg /home/ops/PyAPS/pyaps3/model.cfg
fi
if [ -f model.cfg ]; then
   cp -v model.cfg /home/ops/PyAPS/pyaps3/model.cfg
fi
#else
#    echo "ERROR: missing key file named model.cfg"
#    exit -1

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

# steps processing (start/end/dostep):
#   Command line options for steps processing with names are chosen from the following list:
  
#   ['load_data', 'modify_network', 'reference_point', 'quick_overview', 'correct_unwrap_error']
#   ['invert_network', 'correct_LOD', 'correct_SET', 'correct_troposphere', 'deramp', 'correct_topography']
#   ['residual_RMS', 'reference_date', 'velocity', 'geocode', 'google_earth', 'hdfeos5']
  
#   In order to use either --start or --dostep, it is necessary that a
#   previous run was done using one of the steps options to process at least
#   through the step immediately preceding the starting step of the current run.

#   --start STEP          start processing at the named step (default: load_data).
#   --end STEP, --stop STEP
#                         end processing at the named step (default: hdfeos5)
#   --dostep STEP         run processing at the named step only

export CFG=$1
echo "Config file CFG is $CFG"

export TTAG=`date +"%Y%m%dT%H%M%S"`
echo TTAG is ${TTAG}

# run starting at a step
#export STEP="load_data"
#export STEP="quick_overview"
#export STEP="correct_troposphere"
export STEP=$2
echo STEP is ${STEP}

#smallbaselineApp.py  | tee smallbaselineApp_${TTAG}.log
smallbaselineApp.py  ${CFG} --start ${STEP} | tee smallbaselineApp_${CFG}_${TTAG}.log

# run all steps:
# smallbaselineApp.py SANEM_T144f_askja.cfg | tee smallbaselineApp.log
# run tropo only
#smallbaselineApp.py SANEM_T144f_askja.cfg  --start correct_troposphere