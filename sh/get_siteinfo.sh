#!/usr/bin/env bash
# 2022/08/15 Kurt Feigl 

set -v # verbose
set -x # for debugging
#set -e # exit on error
#set -u # error on unset variables
# S1  20 FORGE 20200101  20200130
# S1 144 SANEM 20190301  20190401 1  
# 

if [[ ( "$#" -ne 1 ) ]]; then
    bname=`basename $0`
    echo "$bname will get site info"
    echo "usage:   $bname $PWD"
    exit -1
fi


# SiteInfo is no longer in repo
#export PATH=${HOME}/FringeFlow/siteinfo:${PATH}
# will need to carry this with us
# Current version is on askja.ssec.wisc.edu:/home/feigl/siteinfo
# rsync -rav siteinfo.tgz transfer00.chtc.wisc.edu:/staging/groups/geoscience/insar
if [[ -f siteinfo.tgz ]]; then
    if [[ -d /home/ops ]]; then
       tar -C /home/ops -xzf siteinfo.tgz
    else
       tar -C $HOME -xzf siteinfo.tgz
    fi
elif [[ -f ${HOME}/siteinfo.tgz ]]; then
    if [[ -d /home/ops ]]; then
       tar -C /home/ops -xzf ${HOME}/siteinfo.tgz
    else
       tar -C $HOME -xzf ${HOME}/siteinfo.tgz
    fi
elif [[ -f ${PWD}/siteinfo.tgz ]]; then 
    if [[ -d /home/ops ]]; then
       tar -C /home/ops -xzf ${PWD}/siteinfo.tgz
    else
        tar -C $HOME -xzf ${PWD}/siteinfo.tgz
    fi
else
    echo "ERROR cannot find tar file named siteinfo.tgz"
    exit -1
fi


