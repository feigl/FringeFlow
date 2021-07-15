#!/bin/bash -e
# To set up paths inside container, source this file
# 2021/07/08 Kurt Feigl

#
if [[ ! -w "$HOME" ]]; then
    echo "Resetting HOME from $HOME to $PWD"
    export HOME=$PWD
fi

# configure environment 
if [[ -f /home/batzli/setup.sh ]]; then
    source /home/batzli/setup.sh
else
    export PATH=${HOME}/bin_htcondor:${PATH}
fi

export PATH=${HOME}/FringeFlow/sh:${PATH}
export PATH=${HOME}/FringeFlow/docker:${PATH}
export PATH=${HOME}/FringeFlow/gmtsar6:${PATH}
export PATH=${HOME}/FringeFlow/siteinfo:${PATH}

if [[ -d /home/ops/ssara_client ]]; then
    export PATH=${PATH}:/home/ops/ssara_client
    export PYTHONPATH=${PYTHONPATH}:/home/ops/ssara_client
fi
