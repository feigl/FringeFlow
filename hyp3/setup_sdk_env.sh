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

# https://notebooks.gesis.org/binder/jupyter/user/asfhyp3-hyp3-sdk-k3vfdx93/notebooks/docs/sdk_example.ipynb

mamba create -n sdk -y
mamba activate sdk
echo $PYTHONPATH
# https://github.com/scottstanie/sentineleof

cat << EOF > requirements.txt
hyp3_sdk
asf_search
sentineleof
EOF


mamba install --yes --file requirements.txt

 
