#!/bin/bash -e
## 2021/07/08 Kurt Feigl

# set up paths inside container
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
    export PATH=${PATH}:${HOME}/FringeFlow/siteinfo
fi

if [[ -d ${HOME}/gipht/csh ]]; then
    export PATH=${PATH}:${HOME}/gipht/csh
fi

if [[ -d /home/ops/ssara_client ]]; then
    export PATH=${PATH}:/home/ops/ssara_client
    export PYTHONPATH=${PYTHONPATH}:/home/ops/ssara_client
fi

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

## GDAL for Mac from http://www.kyngchaos.com/software/frameworks/
if [[ -d /Library/Frameworks/GDAL.framework/Programs ]]; then
    export PATH=/Library/Frameworks/GDAL.framework/Programs:$PATH
fi



