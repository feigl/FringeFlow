#!/bin/bash 
# 2021/07/08 Kurt Feigl
# 2021/12/07 Kurt and Nick
# 2022/08/15 Kurt handle only environment variables here

# set up paths and environment variables inside container
# source this file

if [[ -n ${PYTHONPATH+set} ]]; then
    echo inheriting PYTHONPATH as ${PYTHONPATH}   
else
    export  PYTHONPATH=":"
fi 
# configure environment for ISCE
#/opt/isce2/isce_env.sh: line 1: PYTHONPATH: unbound variable
# nickb note: isce2 environment is now set in the conda environment
if [[ -f /tools/isce2/isce_env.sh ]]; then
   source /tools/isce2/isce_env.sh
fi

if [[ -d /opt/conda/envs/maise/share/isce2/topsStack/ ]]; then
    export PATH=/opt/conda/envs/maise/share/isce2/topsStack/:$PATH
fi

if [[ -d /opt/conda/envs/maise/lib/python3.11/site-packages/isce/applications ]]; then
    export PATH=${PATH}:/opt/conda/envs/maise/lib/python3.11/site-packages/isce/applications
    if [[ -n ${PYTHONPATH+set} ]]; then
        export  PYTHONPATH=${PYTHONPATH}:/opt/conda/envs/maise/lib/python3.11/site-packages/isce/applications
    else
        export  PYTHONPATH=/opt/conda/envs/maise/lib/python3.11/site-packages/isce/applications
    fi
fi

if [[ -d ${HOME}/FringeFlow ]]; then
    export PATH=${PATH}:${HOME}/FringeFlow/sh
    export PATH=${PATH}:${HOME}/FringeFlow/docker
    export PATH=${PATH}:${HOME}/FringeFlow/isce
    export PATH=${PATH}:${HOME}/FringeFlow/mintpy
    export PATH=${PATH}:${HOME}/FringeFlow/ssara
    #export PATH=${PATH}:${HOME}/FringeFlow/siteinfo
    export PATH=${PATH}:${HOME}/FringeFlow/aria
    export PATH=${PATH}:${HOME}/FringeFlow/maise
fi


if [[ -d ${HOME}/gipht/csh ]]; then
    export PATH=${PATH}:${HOME}/gipht/csh
fi

# # set up for SSARA
if [[ -d /tools/SSARA ]]; then
    export SSARA_HOME=/tools/SSARA
    export PATH=${PATH}:${SSARA_HOME}
    if [[ -n ${PYTHONPATH+set} ]]; then
        export PYTHONPATH=${PYTHONPATH}:${SSARA_HOME}
    else
        export PYTHONPATH=${SSARA_HOME}
    fi
fi 

# set up for MintPy
if [[ -d /tools/MintPy ]]; then
    export MINTPY_HOME=/opt/conda/envs/maise/lib/python3.11/site-packages/mintpy
    export PATH=${PATH}:${MINTPY_HOME}/mintpy
    export PATH=${PATH}:${MINTPY_HOME}/sh
    export PATH=${PATH}:${MINTPY_HOME}/simulation
    export PATH=${PATH}:${MINTPY_HOME}/utils
    if [[ -n ${PYTHONPATH+set} ]]; then
        export PYTHONPATH=${PYTHONPATH}:${MINTPY_HOME}/mintpy
    else
        export PYTHONPATH=${MINTPY_HOME}/mintpy
    fi
    export PYTHONPATH=${PYTHONPATH}:${MINTPY_HOME}/PyAPS
fi

if [[ -d /tools/PyAPS ]]; then
    if [[ -n ${PYTHONPATH+set} ]]; then
        export PYTHONPATH=${PYTHONPATH}:/opt/conda/envs/maise/lib/python3.11/site-packages/pyaps3
    else
        export PYTHONPATH=/opt/conda/envs/maise/lib/python3.11/site-packages/pyaps3
    fi
    export PYTHONPATH=${PYTHONPATH}:/opt/conda/envs/maise/lib/python3.11/site-packages/pyaps3
fi

if [[ -d /tools/ARIA-tools ]]; then
    if [[ -n ${PYTHONPATH+set} ]]; then
        export PYTHONPATH=${PYTHONPATH}:/tools/ARIA-tools/tools/ARIAtools
    else
        export PYTHONPATH=/tools/ARIA-tools/tools/ARIAtools
    fi
    export PYTHONPATH=${PYTHONPATH}:/tools/ARIA-tools/tools/ARIAtools
    export PATH=${PATH}:/tools/ARIA-tools/tools/bin
fi

if [[ -d /opt/conda/envs/maise/share/proj/ ]]; then
    export PROJ_LIB=/opt/conda/envs/maise/share/proj/
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


