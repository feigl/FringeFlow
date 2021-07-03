#!/bin/bash -x
 
tar -C $HOME -xzvf bin_htcondor.tgz 
tar -C $HOME -xzvf gmtsar-aux.tgz 

source setup_docker.sh 

run_pair_DAG_gmtsarv60.sh PAIRSmake.txt .12

