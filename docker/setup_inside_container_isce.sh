#!/bin/bash 
# 2021/07/08 Kurt Feigl
# 2021/12/07 Kurt and Nick
# 2022/08/15 Kurt handle only environment variables here

# set up paths and environment variables inside container
# source this file

# configure environment for ISCE
if [[ -f /opt/isce2/isce_env.sh ]]; then
   source /opt/isce2/isce_env.sh
fi

if [[ -d /opt/isce2/src/isce2/contrib/stack/topsStack ]]; then
    export PATH=/opt/isce2/src/isce2/contrib/stack/topsStack:$PATH
fi

if [[ -d /opt/isce2/src/isce2/applications ]]; then
   export PATH=${PATH}:/opt/isce2/src/isce2/applications
   export  PYTHONPATH=${PYTHONPATH}:/opt/isce2/src/isce2/applications
fi

if [[ -d ${HOME}/FringeFlow ]]; then
    export PATH=${PATH}:${HOME}/FringeFlow/sh
    export PATH=${PATH}:${HOME}/FringeFlow/docker
    export PATH=${PATH}:${HOME}/FringeFlow/isce
    export PATH=${PATH}:${HOME}/FringeFlow/mintpy
    export PATH=${PATH}:${HOME}/FringeFlow/ssara
    #export PATH=${PATH}:${HOME}/FringeFlow/siteinfo
    export PATH=${PATH}:${HOME}/FringeFlow/aria
fi


if [[ -d ${HOME}/gipht/csh ]]; then
    export PATH=${PATH}:${HOME}/gipht/csh
fi

# # set up for SSARA
# if [[ -d ${HOME}/ssara_client ]]; then
#     export SSARA_HOME=${HOME}/ssara_client
#     export PATH=${PATH}:${SSARA_HOME}
#     export PYTHONPATH=${PYTHONPATH}:${SSARA_HOME}
# fi 

# set up for MintPy
if [[ -d /home/ops/MintPy ]]; then
    export MINTPY_HOME=/home/ops/MintPy
    export PATH=${PATH}:${MINTPY_HOME}/mintpy
    export PATH=${PATH}:${MINTPY_HOME}/sh
    export PATH=${PATH}:${MINTPY_HOME}/simulation
    export PATH=${PATH}:${MINTPY_HOME}/utils
    export PYTHONPATH=${PYTHONPATH}:${MINTPY_HOME}/mintpy
    export PYTHONPATH=${PYTHONPATH}:${MINTPY_HOME}/PyAPS
fi

if [[ -d /home/ops/PyAPS ]]; then
    export PYTHONPATH=${PYTHONPATH}:/home/ops/PyAPS
    export PYTHONPATH=${PYTHONPATH}:/home/ops/PyAPS/pyaps3
fi

if [[ -d $HOME/ARIA-tools ]]; then
   export PYTHONPATH=${PYTHONPATH}:${HOME}/ARIA-tools/tools/ARIAtools
   export PYTHONPATH=${PYTHONPATH}:${HOME}/ARIA-tools
   export PATH=${PATH}:${HOME}/ARIA-tools/tools/bin
fi

## GDAL for Mac from http://www.kyngchaos.com/software/frameworks/
if [[ -d /Library/Frameworks/GDAL.framework/Programs ]]; then
    export PATH=/Library/Frameworks/GDAL.framework/Programs:$PATH
fi


if [[ -d ${HOME}/siteinfo ]]; then
    #export PATH=${HOME}/siteinfo:${PATH}
    export SITE_DIR=${HOME}/siteinfo  
elif [[ -d ${PWD}/siteinfo ]]; then 
    #export PATH=${PWD}/siteinfo:${PATH}
    export SITE_DIR=${PWD}/siteinfo
else
    echo "WARNING cannot find directory named siteinfo"
    exit -1
fi
echo SITE_DIR is $SITE_DIR
export SITE_TABLE=${SITE_DIR}/site_dims.txt
echo SITE_TABLE is $SITE_TABLE

if [[ -d /staging/groups/geoscience/insar/isce ]]; then
   export ISCONDOR=1;
else
   export ISCONDOR=0;
fi
echo ISCONDOR is $ISCONDOR


