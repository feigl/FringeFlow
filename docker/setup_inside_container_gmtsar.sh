#!/bin/bash -e
## 2021/07/08 Kurt Feigl

# set up paths inside container

# configure environment 

export PATH=${HOME}/FringeFlow/sh:${PATH}
export PATH=${HOME}/FringeFlow/docker:${PATH}
export PATH=${HOME}/FringeFlow/gmtsar6:${PATH}
export PATH=${HOME}/gmtsar-aux:${PATH}
export PATH=${HOME}/bin_htcondor:${PATH}

