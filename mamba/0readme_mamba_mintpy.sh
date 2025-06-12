#!/bin/bash



# https://nbviewer.org/github/ASFHyP3/hyp3-docs/blob/main/docs/tutorials/hyp3_insar_stack_for_ts_analysis.ipynb

#mamba create -n mintpykf mintpy pandas jupyter ipympl ipykernel -y
# mamba create -n hyp3-mintpy -y
# mamba activate hyp3-mintpy

# get standard version
#mamba install mintpy -y

cd $HOME

git clone https://github.com/insarlab/MintPy.git
git clone https://github.com/insarlab/PyAPS.gi

mamba create -n mintpykf  -y
mamba activate mintpykf

# overwrite with local version
cd $HOME/MintPy
git pull
mamba install mintpy -y --file $HOME/MintPy/requirements.txt
which smallbaselineApp.py

# add PyAPS
cd $HOME/PyAPS
git pull
mamba install pyaps3 -y --file $HOME/PyAPS/requirements.txt --file $HOME/PyAPS/tests/requirements.txt

# 2025/06/10 above fails

# install standard version with:
mamba create -n mintpy -c conda-forge mintpy -y

#Now the pyaps routines work fine. Indeed, the GRB files now download smoothly. 
And the results are properly geocoded in UTM. 
And the results using pyaps look better than the ones from height_correlation. 
I attribute the previous errors to my clumsy attempts at setting up environments to run using a juypter notebook. Thanks again!

 
