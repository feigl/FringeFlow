#!/bin/bash

#cd /software/feigl
#cd /scratch/feigl

cd /home/feigl
mkdir -p ./miniforge3

#wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ./miniconda3/miniconda.sh
#wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O miniforge/miniforge.sh
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh 

unset PYTHONPATH

#bash miniforge/miniforge.sh -b -u -p ./miniforge
bash Miniforge3-Linux-x86_64.sh -b -u -p ./miniforge3

#rm -rf miniforge.sh
# https://github#.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh

# ./miniforge3/bin/mamba init bash
# source ~/.bashrc
# echo $PYTHONPATH

# https://notebooks.gesis.org/binder/jupyter/user/asfhyp3-hyp3-sdk-k3vfdx93/notebooks/docs/sdk_example.ipynb

echo $PYTHONPATH
# https://github.com/scottstanie/sentineleof


# add items for SDK
cat << EOF > requirements.txt
hyp3_sdk
asf_search
gdal
matplotlib
pyproj
ipykernel
pandas
EOF
#sentineleof

mamba deactivate
mamba create -n sdk -y
mamba activate sdk
mamba install --yes --file requirements.txt


#which smallbaselineApp.py  

# try to install mintpy - fails
#mamba install -n sdk -y  --file $HOME/MintPy/requirements.txt

mamba create -n hyp3-mintpy python=3.10 "asf_search>=7.0.0" hyp3_sdk "mintpy>=1.5.2" pandas jupyter ipympl