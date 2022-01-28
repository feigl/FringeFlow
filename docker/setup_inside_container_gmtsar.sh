#!/bin/bash -exv
# To set up paths inside container, source this file
# 2021/07/08 Kurt Feigl
# 2021/11/03 Kurt and Sam add some documentation

#
if [[ ! -w "$HOME" ]]; then
    echo "Resetting HOME from $HOME to $PWD because cannot write to $HOME"
    export HOME=$PWD
fi

# configure environment for Reinisch workflow
if [[ -f /home/batzli/setup.sh ]]; then
    # set up on askja
    source /home/batzli/setup.sh
else
    # assume we are on another machine
    if [[ -d ${HOME}/bin_htcondor ]]; then
        export PATH=${HOME}/bin_htcondor:${PATH}
    else
        export PATH=${PWD}/bin_htcondor:${PATH}
    fi
fi

# configure FringeFlow workflow, assuming that 
if [[ -d ${HOME}/FringeFlow ]]; then
    export PATH=${HOME}/FringeFlow/sh:${PATH}
    export PATH=${HOME}/FringeFlow/docker:${PATH}
    export PATH=${HOME}/FringeFlow/gmtsar6:${PATH}
elif [[ -d ${PWD}/FringeFlow ]]; then
    export PATH=${PWD}/FringeFlow/sh:${PATH}
    export PATH=${PWD}/FringeFlow/docker:${PATH}
    export PATH=${PWD}/FringeFlow/gmtsar6:${PATH}
else 
    echo "$0 ERROR: cannot find FringeFlow"
    exit
fi

# SiteInfo is no longer in repo
#export PATH=${HOME}/FringeFlow/siteinfo:${PATH}
# will need to carry this with us
# Current version is on askja.ssec.wisc.edu:/home/feigl/siteinfo
# rsync -rav siteinfo.tgz transfer00.chtc.wisc.edu:/staging/groups/geoscience/insar
if [[ -d ${HOME}/siteinfo ]]; then
    echo "found directory ${HOME}/siteinfo"
    export PATH=${HOME}/siteinfo:${PATH}
    export SITE_TABLE="${HOME}/siteinfo/site_dims.txt"
elif [[ -d ${PWD}/siteinfo ]]; then
    echo "found directory ${PWD}/siteinfo"
    export PATH=${PWD}/siteinfo:${PATH}
    export SITE_TABLE="${PWD}/siteinfo/site_dims.txt"
else
    echo "WARNING the logic in setup_inside_container_gmtsar.sh cannot find directory named siteinfo in ${home} or ${PWD} but maybe we are looking in the wrong place or maybe the paths are exported in the wrong shell?"
fi
echo "If we are in the right place, then SITE_TABLE is $SITE_TABLE or the next attempt is to export that variable in run_pairs_gmtsar.sh?"


# needed for ISCE and MINTPY
#export PATH=${HOME}/FringeFlow/mintpy:${PATH}
#export PATH=${HOME}/FringeFlow/isce:${PATH}

if [[ -d /home/ops/ssara_client ]]; then
    export PATH=${PATH}:/home/ops/ssara_client
    export PYTHONPATH=${PYTHONPATH}:/home/ops/ssara_client
fi

echo "At the very end of $0 PYTHONPATH is now $PYTHONPATH"
echo "At the very end of $0 PATH is now $PATH"
