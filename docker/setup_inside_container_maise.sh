#!/bin/bash
# 2021/07/08 Kurt Feigl
# 2021/12/07 Kurt and Nick
# 2022/08/15 Kurt handle only environment variables here
# 2023/09/16 adapt to smarter docker container which includes environment
# 2023/11/24 adapt to CHTC HPC

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
    conda activate maise
    
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

if [[ -d $CONDA_HOME/envs/maise/bin ]]; then
    export PATH=$PATH:$CONDA_HOME/envs/maise/bin 
fi

if [[ -d $CONDA_HOME/envs/maise/bsin ]]; then
    export PATH=$PATH:$CONDA_HOME/envs/maise/sbin 
fi

# look for isce (not isce2)
# 2023/09/11 with Nick.
# Here are results from a working container
# echo $ISCE_HOME
# /opt/conda/envs/maise/lib/python3.11/site-packages/isce
#export ISCE_HOME=/opt/conda/envs/maise/lib/python3.11/site-packages/isce
path1=`find $CONDA_HOME -name isce`
if [[ -d $path1 ]]; then
    echo path1 is $path1
    path2=`dirname $path1`
    if [[ -d $path2 ]]; then 
        export PATH=$PATH:$path2
        export PYTHONPATH=$PYTHONPATH:$path2
    fi
fi

# look for stack processors for ISCE
path1=`find $CONDA_HOME -name stackSentinel.py`
echo path1 is $path1
path2=`dirname $path1`
if [[ -d $path2 ]]; then 
        export PATH=$PATH:$path2
        export PYTHONPATH=$PYTHONPATH:$path2
        path3=`dirname $path2`
        if [[ -d $path3 ]]; then
            export PATH=$PATH:$path3
            export PYTHONPATH=$PYTHONPATH:$path3
        fi
fi

# (maise) root@63015c028655:/home/nickb/FringeFlow# echo $PYTHONPATH
# :/opt/conda/envs/maise/share/isce2
#export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2

# set PATH 
if [[ -d $CONDA_HOME/envs/maise ]]; then
    # Important Note: There are naming conflicts between topsStack and stripmapStack scripts. 
    # Therefore users MUST have the path of ONLY ONE stack processor in their $PATH at a time, 
    # to avoid the naming conflicts.
    # export PATH=$PATH:/opt/conda/envs/maise/share/isce2/alosStack
    # export PATH=$PATH:/opt/conda/envs/maise/share/isce2/prepStackToStaMPS
    # export PATH=$PATH:/opt/conda/envs/maise/share/isce2/stripmapStack
    # For Sentinel-1 TOPS data
    #export PATH=$PATH:/opt/conda/envs/maise/share/isce2/topsStack
    export PATH=$PATH:$CONDA_HOME/envs/maise/share/isce2/topsStack
fi

# set PYTHONPATH
if [[ -d $CONDA_HOME/envs/maise ]]; then
    export PYTHONPATH=$PYTHONPATH:$CONDA_HOME/envs/maise/share/isce2
     # Important Note: There are naming conflicts between topsStack and stripmapStack scripts. 
    # Therefore users MUST have the path of ONLY ONE stack processor in their $PATH at a time, 
    # to avoid the naming conflicts.
    #export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2/alosStack
    #export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2/prepStackToStaMPS
    #export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2/stripmapStack
    #export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2/alosStack
    # export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2/
    # export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2/topsStack
    export PYTHONPATH=$PYTHONPATH:$CONDA_HOME/envs/maise/share/isce2/
    export PYTHONPATH=$PYTHONPATH:$CONDA_HOME/envs/maise/share/isce2/topsStack
 fi


# look for more for more paths - dem.py
# /opt/conda/envs/maise/lib/python3.11/site-packages/isce/applications/dem.py
# /scratch/feigl/conda/pkgs/isce2-2.6.3-py311h1e919c0_0/lib/python3.11/site-packages/isce/applications/
# path1=`find /opt/conda/envs/maise -name dem.py | head -1`
path1=`find $CONDA_HOME -name dem.py | head -1`
echo path1 is $path1
if [[ -d $path1 ]]; then   
    path2=`dirname $path1`
    if [[ -d $path2 ]]; then
        export PATH=$PATH:$path2
        export PYTHONPATH=$PYTHONPATH:$path2
    fi
fi

# look for ISCE extras - mdx 
# # mdx executable lives here
#export PATH=$PATH:/opt/conda/envs/maise/lib/python3.11/site-packages/isce/bin
#pathfound=`find /opt/conda/envs/maise -name mdx | head -1`
path1=`find $CONDA_HOME -name mdx | head -1`
echo path1 is $path1
path2=`dirname $path1`
if [[ -d $path2 ]]; then
    export PATH=$PATH:$path2
    export PYTHONPATH=$PYTHONPATH:$path2
fi


# 1029  export PYTHONPATH=$PYTHONPATH:/scratch/feigl/conda/pkgs/isce2-2.6.3-py311h1e919c0_0/share/isce2
#  1056  export PYTHONPATH=$PYTHONPATH:/scratch/feigl/conda/pkgs/isce2-2.6.3-py311h1e919c0_0/lib/python3.11/site-packages/isce
#  1058  export PYTHONPATH=$PYTHONPATH:/scratch/feigl/conda/pkgs/isce2-2.6.3-py311h1e919c0_0/lib/python3.11/site-packages
#  1060  export PYTHONPATH=$PYTHONPATH:/scratch/feigl/conda/pkgs/isce2-2.6.3-py311h1e919c0_0/lib/python3.11/site-packages/isce/components
#  1062  export PYTHONPATH=$PYTHONPATH:/scratch/feigl/conda/pkgs/isce2-2.6.3-py311h1e919c0_0/lib/python3.11/site-packages/isce/components/iscesys/
#  1063  export PYTHONPATH=$PYTHONPATH:/scratch/feigl/conda/pkgs/isce2-2.6.3-py311h1e919c0_0/lib/python3.11/site-packages/isce/components/iscesobj
#  1067  export PYTHONPATH=$PYTHONPATH:/scratch/feigl/conda/pkgs/isce2-2.6.3-py311h1e919c0_0/lib/python3.11/site-packages/isce/components/iscesys/ImageApi

# sed -i 's/import isce/import isce2 as isce/' /opt/conda/envs/maise/lib/python3.11/site-packages/isce/applications/dem.py

# look for MINTPY extras that include "proj" package
# view.py --dpi 150 --noverbose --nodisplay --update geo/geo_temporalCoherence.h5 -c gray
# ERROR 1: PROJ: proj_create_from_database: Open of /opt/conda/envs/maise/share/proj failed
#https://stackoverflow.com/questions/56764046/gdal-ogr2ogr-cannot-find-proj-db-error
# if [[ -d /opt/conda/envs/maise/share/proj ]]; then
#    export PROJ_LIB='/opt/conda/envs/maise/share/proj'
if [[ -d $CONDA_HOME/maise/share/proj ]]; then
   export PROJ_LIB=$CONDA_HOME/maise/share/proj
else
   echo 'WARNING: Cannot find proj library. See https://stackoverflow.com/questions/56764046/gdal-ogr2ogr-cannot-find-proj-db-error'
fi

# if [[ -d /opt/conda/envs/maise/lib/cmake/proj ]]; then
#    export GDAL_DATA='/opt/conda/envs/maise/lib/cmake/proj'
if [[ -d $CONDA_HOME/envs/maise/lib/cmake/proj ]]; then
   export GDAL_DATA=$CONDA_HOME/envs/maise/lib/cmake/proj
else
   echo 'WARNING: Cannot find GDAL data library. See https://stackoverflow.com/questions/56764046/gdal-ogr2ogr-cannot-find-proj-db-error'
fi

## GDAL for Mac from http://www.kyngchaos.com/software/frameworks/
if [[ -d /Library/Frameworks/GDAL.framework/Programs ]]; then
    export PATH=/Library/Frameworks/GDAL.framework/Programs:$PATH
else
    echo "WARNING cannot find a path to gdal . Consider following command:"
    echo 'find / -type d -name gdal'
fi

# set up for Fringe Flow
if [[ -n  ${_CONDOR_SCRATCH_DIR+set} ]]; then
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/sh
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/docker
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/isce
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/mintpy
    #export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/ssara
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/aria
    export PATH=${PATH}:${_CONDOR_SCRATCH_DIR}/FringeFlow/maise    
elif [[ -d ${HOME}/FringeFlow ]]; then
    export PATH=${PATH}:${HOME}/FringeFlow/sh
    export PATH=${PATH}:${HOME}/FringeFlow/docker
    export PATH=${PATH}:${HOME}/FringeFlow/isce
    export PATH=${PATH}:${HOME}/FringeFlow/mintpy
    #export PATH=${PATH}:${HOME}/FringeFlow/ssara
    export PATH=${PATH}:${HOME}/FringeFlow/aria
    export PATH=${PATH}:${HOME}/FringeFlow/maise
else
    echo "WARNING cannot find a path to FringeFlow ." Finding ...
    find / -type d -name FringeFlow
fi

if [[ -d ${HOME}/gipht/csh ]]; then
    export PATH=${PATH}:${HOME}/gipht/csh
fi

# # set up for SSARA
# if [[ -d /tools/SSARA ]]; then
#     export SSARA_HOME=/tools/SSARA
# elif [[ -d $HOME/tools/SSARA ]]; then
#     export SSARA_HOME=$HOME/tools/SSARA
# elif [[ -d $HOME/FringeFlow/ssara ]]; then
#     export SSARA_HOME=$HOME/Fringeflow/ssara
#  else
#     echo "WARNING cannot find a path to SSARA ." Finding ...
#     #find / -type d -name SSARA
# fi 
# export PATH=${PATH}:${SSARA_HOME}
# if [[ -n ${PYTHONPATH+set} ]]; then
#     export PYTHONPATH=${PYTHONPATH}:${SSARA_HOME}
# else
#     export PYTHONPATH=${SSARA_HOME}
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




