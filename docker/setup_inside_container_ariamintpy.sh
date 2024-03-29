#!/bin/bash
# 2021/07/08 Kurt Feigl
# 2021/12/07 Kurt and Nick
# 2022/08/15 Kurt handle only environment variables here
# 2023/09/16 adapt to smarter docker container which includes environment
# 2023/11/24 adapt to CHTC HPC
# 2023/1126

# set up paths and environment variables inside container
# source this file

set -v # verbose
set -x # for debugging "eXamine"
#set -e # exit on error "Exit"
#set -u # error on unset variables

# are we running under CONDOR, with the need for staging?
if [[ -d /staging/groups/geoscience/ ]]; then
    export ISCONDOR=1;
    # unset variable that stops running on unbound (undeclared) variable
    set +u
    source /etc/profile.d/conda.sh
    # Next line will deactivate conda environment if necessary
    conda activate ariamintpy
    
    # Matplotlib created a temporary cache directory at /tmp/matplotlib-a8hsjr85
    # because the default path (/.config/matplotlib) is not a writable directory; it
    # is highly recommended to set the MPLCONFIGDIR environment variable to a
    # writable directory, in particular to speed up the import of Matplotlib and to
    # better support multiprocessing.
    export MPLCONFIGDIR=${_CONDOR_SCRATCH_DIR}
else
    export ISCONDOR=0;
fi
echo ISCONDOR is $ISCONDOR

if [[ -d /opt/conda ]]; then
    export CONDA_HOME="/opt/conda"
elif [[ -d $HOME/miniforge3 ]]; then
    export CONDA_HOME="$HOME/miniforge3"
elif [[ -d $HOME/miniforge-pypy3 ]]; then
    export CONDA_HOME="$HOME/miniforge-pypy3"
elif [[ -d /scratch/feigl/conda ]]; then
    export CONDA_HOME="/scratch/feigl/conda" 
else
    echo "ERROR: cannot find a place to define CONDA_HOME"
    exit -1
fi
    

if [[ -d ${CONDA_HOME}/pkgs ]]; then
    export  PYTHONPATH=$PYTHONPATH:${CONDA_HOME}/pkgs
fi

if [[ -d $CONDA_HOME/envs/ariamintpy/bin ]]; then
    export PATH=$PATH:$CONDA_HOME/envs/ariamintpy/bin 
fi

if [[ -d $CONDA_HOME/envs/ariamintpy/bsin ]]; then
    export PATH=$PATH:$CONDA_HOME/envs/ariamintpy/sbin 
fi





# set up for Fringe Flow
if [[ -n  ${_CONDOR_SCRATCH_DIR+set} ]]; then
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/sh
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/docker
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/isce
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/mintpy
    #export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/ssara
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/aria
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/ariamintpy    
elif [[ -d ${HOME}/FringeFlow ]]; then
    export PATH=${PATH}:${HOME}/FringeFlow/sh
    export PATH=${PATH}:${HOME}/FringeFlow/docker
    export PATH=${PATH}:${HOME}/FringeFlow/isce
    export PATH=${PATH}:${HOME}/FringeFlow/mintpy
    #export PATH=${PATH}:${HOME}/FringeFlow/ssara
    export PATH=${PATH}:${HOME}/FringeFlow/aria
    export PATH=${PATH}:${HOME}/FringeFlow/ariamintpy
else
    echo "WARNING cannot find a path to FringeFlow ." Finding ...
    find / -type d -name FringeFlow
fi

if [[ -d ${HOME}/gipht/csh ]]; then
    export PATH=${PATH}:${HOME}/gipht/csh
fi


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



# # set up for MintPy
if [[ -d /tools/MintPy ]]; then
    export MINTPY_HOME=/tools/MintPy
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
else
    echo "WARNING cannot find a path to MintPy ." Finding ...
    find / -type d -name MintPy
fi

# set up for PyAps
if [[ -d /tools/PyAPS ]]; then
    if [[ -n ${PYTHONPATH+set} ]]; then
        export PYTHONPATH=${PYTHONPATH}:/tools/PyAPS
    else
        export PYTHONPATH=/tools/PyAPS
    fi
    export PYTHONPATH=${PYTHONPATH}:/tools/PyAPS/pyaps3
elif [[ -d /opt/conda/lib/python3.8/site-packages/pyaps3 ]]; then
    if [[ -n ${PYTHONPATH+set} ]]; then
        export PYTHONPATH=${PYTHONPATH}:/opt/conda/lib/python3.8/site-packages/pyaps3
    else
        export PYTHONPATH=/tools/PyAPS
    fi
    export PYTHONPATH=${PYTHONPATH}:/opt/conda/lib/python3.8/site-packages/pyaps3
else
    echo "WARNING cannot find a path to PyAps ." Finding ...
    find / -type d -name PyAps
fi

if [[ -d $HOME/ARIA-tools ]]; then
    if [[ -n ${PYTHONPATH+set} ]]; then
        export PYTHONPATH=${PYTHONPATH}:${HOME}/ARIA-tools/tools/ARIAtools
    else
        export PYTHONPATH=${HOME}/ARIA-tools/tools/ARIAtools
    fi
    export PYTHONPATH=${PYTHONPATH}:${HOME}/ARIA-tools
    export PATH=${PATH}:${HOME}/ARIA-tools/tools/bin
elif [[ -d /tools/ARIA-tools ]]; then
    if [[ -n ${PYTHONPATH+set} ]]; then
        export PYTHONPATH=${PYTHONPATH}:/tools/ARIA-tools/tools/ARIAtools
    else
        export PYTHONPATH=/tools/ARIA-tools/tools/ARIAtools
    fi
    export PYTHONPATH=${PYTHONPATH}:/tools/ARIA-tools
    export PATH=${PATH}:/tools/ARIA-tools/tools/bin
else
    echo "WARNING cannot find a path to ARIA-tools ." Finding ...
    find / -type d -name ARIA-tools
fi

# look for asf_search
path1=`find $CONDA_HOME -name asf_search | head -1`
if [[ -d $path1 ]]; then
    echo path1 is $path1
    # export PATH=$PATH:$path1
    # export PYTHONPATH=$PYTHONPATH:$path1
    path2=`dirname $path1`
    if [[ -d $path2 ]]; then 
        export PATH=$PATH:$path2
        export PYTHONPATH=$PYTHONPATH:$path2
    fi
fi

if [[ -d /opt/conda/share/proj ]]; then
    export PROJ_LIB=/opt/conda/share/proj
else
    echo "WARNING cannot find a path to proj ." Finding ...
    find / -type d -name proj
fi




