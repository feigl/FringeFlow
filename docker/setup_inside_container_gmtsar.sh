#!/bin/bash -e
# To set up paths inside container, source this file
# 2021/07/08 Kurt Feigl

#
if [[ ! -w "$HOME" ]]; then
    echo "Resetting HOME from $HOME to $PWD"
    export HOME=$PWD
fi

# configure environment for Reinisch workflow
if [[ -f /home/batzli/setup.sh ]]; then
    source /home/batzli/setup.sh
else
    if [[ -d ${HOME}/bin_htcondor ]]; then
        export PATH=${HOME}/bin_htcondor:${PATH}
    else
        export PATH=${PWD}/bin_htcondor:${PATH}
    fi
fi

if [[ -d ${HOME}/FringeFlow ]]; then
    export PATH=${HOME}/FringeFlow/sh:${PATH}
    export PATH=${HOME}/FringeFlow/docker:${PATH}
    export PATH=${HOME}/FringeFlow/gmtsar6:${PATH}
else
    export PATH=${PWD}/FringeFlow/sh:${PATH}
    export PATH=${PWD}/FringeFlow/docker:${PATH}
    export PATH=${PWD}/FringeFlow/gmtsar6:${PATH}
fi

# SiteInfo is no longer in repo
#export PATH=${HOME}/FringeFlow/siteinfo:${PATH}
# will need to carry this with us
# Current version is on askja.ssec.wisc.edu:/home/feigl/siteinfo
# rsync -rav siteinfo.tgz transfer00.chtc.wisc.edu:/staging/groups/geoscience/insar
if [[ -d ${HOME}/siteinfo ]]; then
    export PATH=${HOME}/siteinfo:${PATH}
else
    export PATH=${PWD}/siteinfo:${PATH}
fi

# needed for ISCE and MINTPY
#export PATH=${HOME}/FringeFlow/mintpy:${PATH}
#export PATH=${HOME}/FringeFlow/isce:${PATH}

if [[ -d /home/ops/ssara_client ]]; then
    export PATH=${PATH}:/home/ops/ssara_client
    export PYTHONPATH=${PYTHONPATH}:/home/ops/ssara_client
fi
