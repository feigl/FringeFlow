#!/bin/bash

#cd /software/feigl
#cd /scratch/feigl

cd /home/feigl
mkdir -p ./miniforge

#wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ./miniconda3/miniconda.sh
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O miniforge/miniforge.sh

unset PYTHONPATH

bash miniforge/miniforge.sh -b -u -p ./miniforge

rm -rf miniforge.sh
# https://github#.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh

./miniforge/bin/mamba init bash
source ~/.bashrc
echo $PYTHONPATH

# https://nbviewer.org/github/ASFHyP3/hyp3-docs/blob/main/docs/tutorials/hyp3_insar_stack_for_ts_analysis.ipynb

#mamba create -n hyp3-mintpy python=3.10 asf_search hyp3_sdk "mintpy>=1.5.2" pandas jupyter ipympl ipykernel -y
mamba create -n hyp3-mintpy -y
mamba activate hyp3-mintpy

mamba install python=3.10 asf_search hyp3_sdk "mintpy>=1.5.2" pandas ipympl ipython ipykernel -y



# 2025/06/10  
mamba create --name hyp3kf "python>=3.10" "asf_search>=7.0.0" hyp3_sdk pandas jupyter ipympl jupytext gdal pyproj  --channel conda-forge --yes

# 2025/06/11  
mamba create --name hyp3_sdk  -c conda-forge hyp3_sdk --yes