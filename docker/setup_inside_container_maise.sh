#!/bin/bash -veux
# 2021/07/08 Kurt Feigl
# 2021/12/07 Kurt and Nick
# 2022/08/15 Kurt handle only environment variables here
# 2023/09/16 adapt to smarter docker container which includes environment

# set up paths and environment variables inside container
# source this file

if [[ -n ${PYTHONPATH+set} ]]; then
    echo inheriting PYTHONPATH as ${PYTHONPATH}   
else
    export  PYTHONPATH="/opt/conda/pkgs"
fi 

if [[ -d /opt/conda/envs/maise/bin ]]; then
    export PATH=$PATH:/opt/conda/envs/maise/bin
fi
if [[ -d /opt/conda/envs/maise/sbin ]]; then
    export PATH=$PATH:/opt/conda/envs/maise/sbin
fi

# 2023/09/11 with Nick.
# Here are results from a working container
# echo $ISCE_HOME
# /opt/conda/envs/maise/lib/python3.11/site-packages/isce
export ISCE_HOME=/opt/conda/envs/maise/lib/python3.11/site-packages/isce

# (maise) root@63015c028655:/home/nickb/FringeFlow# echo $PYTHONPATH
# :/opt/conda/envs/maise/share/isce2
#export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2


# set PATH 
if [[ -d /opt/conda/envs/maise ]]; then
    # Important Note: There are naming conflicts between topsStack and stripmapStack scripts. 
    # Therefore users MUST have the path of ONLY ONE stack processor in their $PATH at a time, 
    # to avoid the naming conflicts.
    # export PATH=$PATH:/opt/conda/envs/maise/share/isce2/alosStack
    # export PATH=$PATH:/opt/conda/envs/maise/share/isce2/prepStackToStaMPS
    # export PATH=$PATH:/opt/conda/envs/maise/share/isce2/stripmapStack
    export PATH=$PATH:/opt/conda/envs/maise/share/isce2/topsStack
fi

# 2.1 Add the following path to your `${PYTHONPATH}` environment vavriable:
# export ISCE_STACK={full_path_to_your_contrib/stack}
# export PYTHONPATH=${PYTHONPATH}:${ISCE_STACK}
# 2.2 Depending on which stack processor you want to use, add the following path to your `${PATH}` environment variable:
# + For Sentinel-1 TOPS data
# export PATH=${PATH}:${ISCE_STACK}/topsStack

# set PYTHONPATH
if [[ -d /opt/conda/envs/maise ]]; then
    export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2
     # Important Note: There are naming conflicts between topsStack and stripmapStack scripts. 
    # Therefore users MUST have the path of ONLY ONE stack processor in their $PATH at a time, 
    # to avoid the naming conflicts.
    #export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2/alosStack
    #export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2/prepStackToStaMPS
    #export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2/stripmapStack
    #export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2/alosStack
    export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2/
    export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/share/isce2/topsStack
    export PYTHONPATH=$PYTHONPATH:/opt/conda/envs/maise/lib/python3.11/site-packages/isce/components/contrib/demUtils/
 fi

# look for more for more paths
# /opt/conda/envs/maise/lib/python3.11/site-packages/isce/applications/dem.py
path1=`find /opt/conda/envs/maise -name dem.py | head -1`
path2=`dirname $path1`
if [[ -d $path2 ]]; then
    export PATH=$PATH:$path2
    export PYTHONPATH=$PYTHONPATH:$path2
fi

# look for ISCE extras
pathfound=`find /opt/conda/envs/maise -name dem.py | head -1`
pathaddon=`dirname $pathfound`
if [[ -d $pathaddon ]]; then
   export PATH=$PATH:$pathaddon
fi

# sed -i 's/import isce/import isce2 as isce/' /opt/conda/envs/maise/lib/python3.11/site-packages/isce/applications/dem.py

# look for MINTPY extras that include "proj" package
# view.py --dpi 150 --noverbose --nodisplay --update geo/geo_temporalCoherence.h5 -c gray
# ERROR 1: PROJ: proj_create_from_database: Open of /opt/conda/envs/maise/share/proj failed
#https://stackoverflow.com/questions/56764046/gdal-ogr2ogr-cannot-find-proj-db-error
if [[ -d /opt/conda/envs/maise/share/proj ]]; then
   export PROJ_LIB='/opt/conda/envs/maise/share/proj'
else
   echo 'WARNING: Cannot find proj library. See https://stackoverflow.com/questions/56764046/gdal-ogr2ogr-cannot-find-proj-db-error'
fi
if [[ -d /opt/conda/envs/maise/lib/cmake/proj ]]; then
   export GDAL_DATA='/opt/conda/envs/maise/lib/cmake/proj'
else
   echo 'WARNING: Cannot find GDAL data library. See https://stackoverflow.com/questions/56764046/gdal-ogr2ogr-cannot-find-proj-db-error'
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


# configure environment for ISCE
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




