#!/bin/bash -e
## 2021/07/08 Kurt Feigl

# set up paths inside container

export MINTPY_HOME=/home/ops/MintPy
export PATH=${PATH}:${MINTPY_HOME}/mintpy
export PATH=${PATH}:${HOME}/FringeFlow/sh
export PATH=${PATH}:${HOME}/FringeFlow/docker
export PATH=${PATH}:${HOME}/FringeFlow/gmtsar6
export PATH=${PATH}:${HOME}/gipht/csh
export PATH=${PATH}:/home/ops/ssara_client


export PYTHONPATH=${PYTHONPATH}:${MINTPY_HOME}:$HOME/PyAPS

export PYTHONPATH=${PYTHONPATH}:/home/ops/ssara_client