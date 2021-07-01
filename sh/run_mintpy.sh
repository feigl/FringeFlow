#!/bin/bash -vx
## 2021/05/25 Kurt Feigl

# Run epochs for MINTPY

### inside the container 
# prep_isce.py must have permissions to write ../isce

source /opt/isce2/isce_env.sh
export PATH=$PATH:$HOME/MintPy/mintpy/

# need this, too for PyAPS pyaps3
export PYTHONPATH=$PYTHONPATH:$HOME/MintPy/mintpy/:$HOME/PyAPS

# clean start
rm -rf pic isce.log
#rm -rf inputs

# copy keys for ERA PYAPS
# if [ -f ../model.cfg ]; then
#    cp -v ../model.cfg $HOME/PyAPS/pyaps3/model.cfg
# fi
# if [ -f model.cfg ]; then
#    cp -v model.cfg $HOME/PyAPS/pyaps3/model.cfg
# else
#    echo "ERROR: missing key file named model.cfg"
#    exit -1
# fi




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

# run step 1
# smallbaselineApp.py SANEM_T144f_askja.cfg --end load_data
# run all steps:
smallbaselineApp.py SANEM_T144f_askja.cfg | tee smallbaselineApp.log
# run tropo only
#smallbaselineApp.py SANEM_T144f_askja.cfg  --start correct_troposphere