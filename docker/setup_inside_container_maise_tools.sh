#!/bin/bash -vex
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

# # configure environment for ISCE
# if [[ -f /tools/isce2/src/isce2/docker/isce_env.sh ]]; then
#     source /tools/isce2/src/isce2/docker/isce_env.sh
# elif [[ -f /tools/isce2/isce_env.sh ]]; then
#     #/opt/isce2/isce_env.sh: line 1: PYTHONPATH: unbound variable
#     source /tools/isce2/isce_env.sh 
# else
#     echo "WARNING cannot find file named isce_env.sh . Finding ..."
#     find / -type f -name isce_env.sh 
# fi

# if [[ -d /tools/isce2/src/isce2/contrib/stack/topsStack ]]; then
#     export PATH=/tools/isce2/src/isce2/contrib/stack/topsStack:$PATH
# else
#     echo "WARNING cannot find directory named topsStack . Finding ..."
#     find / -type d -name topsStack
# fi

# if [[ -d /tools/isce2/src/isce2/applications ]]; then
#     export PATH=${PATH}:/tools/isce2/src/isce2/applications
#     if [[ -n ${PYTHONPATH+set} ]]; then
#         export  PYTHONPATH=${PYTHONPATH}:/tools/isce2/src/isce2/applications
#     else
#         export  PYTHONPATH=/tools/isce2/src/isce2/applications
#     fi
# else
#     echo "WARNING cannot find directory named applications . Finding ..."
#     find / -type d -name applications
# fi

# if [[ -f /tools/isce2/installv2.6.1/bin/mdx ]]; then
#     export PATH=${PATH}:/tools/isce2/installv2.6.1/bin
# else
#     echo "WARNING cannot find file named mdx . Finding ..."
#     find / -type f -name mdx
# fi

# set up for Fringe Flow
if [[ -n  ${_CONDOR_SCRATCH_DIR+set} ]]; then
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/sh
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/docker
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/isce
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/mintpy
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/ssara
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/aria
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/maise    
elif [[ -d ${HOME}/FringeFlow ]]; then
    export PATH=${PATH}:${HOME}/FringeFlow/sh
    export PATH=${PATH}:${HOME}/FringeFlow/docker
    export PATH=${PATH}:${HOME}/FringeFlow/isce
    export PATH=${PATH}:${HOME}/FringeFlow/mintpy
    export PATH=${PATH}:${HOME}/FringeFlow/ssara
    export PATH=${PATH}:${HOME}/FringeFlow/aria
    export PATH=${PATH}:${HOME}/FringeFlow/maise
else
    echo "WARNING cannot find a path to FringeFlow ." Finding ...
    find / -type d -name FringeFlow
fi

if [[ -d ${HOME}/gipht/csh ]]; then
    export PATH=${PATH}:${HOME}/gipht/csh
fi

# set up for SSARA
if [[ -d /tools/SSARA ]]; then
    export SSARA_HOME=/tools/SSARA
    export PATH=${PATH}:${SSARA_HOME}
    if [[ -n ${PYTHONPATH+set} ]]; then
        export PYTHONPATH=${PYTHONPATH}:${SSARA_HOME}
    else
        export PYTHONPATH=${SSARA_HOME}
    fi
else
    echo "WARNING cannot find a path to SSARA ." Finding ...
    find / -type d -name SSARA
fi 

# # set up for MintPy
# if [[ -d /tools/MintPy ]]; then
#     export MINTPY_HOME=/tools/MintPy
#     export PATH=${PATH}:${MINTPY_HOME}/mintpy
#     export PATH=${PATH}:${MINTPY_HOME}/sh
#     export PATH=${PATH}:${MINTPY_HOME}/simulation
#     export PATH=${PATH}:${MINTPY_HOME}/utils
#     if [[ -n ${PYTHONPATH+set} ]]; then
#         export PYTHONPATH=${PYTHONPATH}:${MINTPY_HOME}/mintpy
#     else
#         export PYTHONPATH=${MINTPY_HOME}/mintpy
#     fi
#     export PYTHONPATH=${PYTHONPATH}:${MINTPY_HOME}/PyAPS
# else
#     echo "WARNING cannot find a path to MintPy ." Finding ...
#     find / -type d -name MintPy
# fi

# # set up for PyAps
# if [[ -d /tools/PyAPS ]]; then
#     if [[ -n ${PYTHONPATH+set} ]]; then
#         export PYTHONPATH=${PYTHONPATH}:/tools/PyAPS
#     else
#         export PYTHONPATH=/tools/PyAPS
#     fi
#     export PYTHONPATH=${PYTHONPATH}:/tools/PyAPS/pyaps3
# elif [[ -d /opt/conda/lib/python3.8/site-packages/pyaps3 ]]; then
#     if [[ -n ${PYTHONPATH+set} ]]; then
#         export PYTHONPATH=${PYTHONPATH}:/opt/conda/lib/python3.8/site-packages/pyaps3
#     else
#         export PYTHONPATH=/tools/PyAPS
#     fi
#     export PYTHONPATH=${PYTHONPATH}:/opt/conda/lib/python3.8/site-packages/pyaps3
# else
#     echo "WARNING cannot find a path to PyAps ." Finding ...
#     find / -type d -name PyAps
# fi

# if [[ -d $HOME/ARIA-tools ]]; then
#     if [[ -n ${PYTHONPATH+set} ]]; then
#         export PYTHONPATH=${PYTHONPATH}:${HOME}/ARIA-tools/tools/ARIAtools
#     else
#         export PYTHONPATH=${HOME}/ARIA-tools/tools/ARIAtools
#     fi
#     export PYTHONPATH=${PYTHONPATH}:${HOME}/ARIA-tools
#     export PATH=${PATH}:${HOME}/ARIA-tools/tools/bin
# elif [[ -d /tools/ARIA-tools ]]; then
#     if [[ -n ${PYTHONPATH+set} ]]; then
#         export PYTHONPATH=${PYTHONPATH}:/tools/ARIA-tools/tools/ARIAtools
#     else
#         export PYTHONPATH=/tools/ARIA-tools/tools/ARIAtools
#     fi
#     export PYTHONPATH=${PYTHONPATH}:/tools/ARIA-tools
#     export PATH=${PATH}:/tools/ARIA-tools/tools/bin
# else
#     echo "WARNING cannot find a path to ARIA-tools ." Finding ...
#     find / -type d -name ARIA-tools
# fi

# if [[ -d /opt/conda/share/proj ]]; then
#     export PROJ_LIB=/opt/conda/share/proj
# else
#     echo "WARNING cannot find a path to proj ." Finding ...
#     find / -type d -name proj
# fi

# ## GDAL for Mac from http://www.kyngchaos.com/software/frameworks/
# if [[ -d /Library/Frameworks/GDAL.framework/Programs ]]; then
#     export PATH=/Library/Frameworks/GDAL.framework/Programs:$PATH
# else
#     echo "WARNING cannot find a path to gdal . Consider following command:"
#     echo 'find / -type d -name gdal'
# fi

# set up for siteinfo
if [[ -n  ${_CONDOR_SCRATCH_DIR+set} ]]; then
    export SITE_DIR=${_CONDOR_SCRATCH_DIR}/siteinfo  
elif [[ -d ${HOME}/siteinfo ]]; then
    export SITE_DIR=${HOME}/siteinfo  
elif [[ -d ${PWD}/siteinfo ]]; then     
    export SITE_DIR=${PWD}/siteinfo
else
    echo "WARNING cannot find directory named siteinfo"
fi
echo SITE_DIR is $SITE_DIR
export SITE_TABLE=${SITE_DIR}/site_dims.txt
echo SITE_TABLE is $SITE_TABLE

# are we running under CONDOR, with the need for staging?
if [[ -d /staging/groups/geoscience/ ]]; then
    export ISCONDOR=1;
else
    export ISCONDOR=0;
fi
echo ISCONDOR is $ISCONDOR


