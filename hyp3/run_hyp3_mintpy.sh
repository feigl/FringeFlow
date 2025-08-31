#!/bin/bash 

# run SANEM
# /data/insar/SANEM/SDK/DESCENDING/mintpy55
# start with clean environment
#mamba deactivate

# generate InSAR pairs with HYP3
# 
# run notebook interactively
# code hyp3_insar_stack_for_ts_analysis_55.ipynb

# warp the TIF files
mamba run -n hyp3 python warp.py

runname=mintpy55
# perform time-series analysis with MintPy

# ValueError: Invalid NaN value found in the following kept pairs for Bperp or coherence! 
#         They likely have issues, check them and maybe exclude them in your network.
#         ['20170613_20180220', '20171116_20181030', '20190603_20230302', '20200329_20240904', '20210523_20211213', '20230513_20231227']
# mkdir drop
# ls -d data/*20170613_20180220*
# ls -d data/*20171116_20181030*
# ls -d data/*20190603_20230302*
# ls -d data/*20200329_20240904*
# ls -d data/*20210523_20211213*
# ls -d data/*20230513_20231227*
# mv data/S1_307989_IW3_20170613_20180220_VV_INT40_6CE4 drop
# mv data/S1_307989_IW3_20171116_20181030_VV_INT40_2697 drop
# mv data/S1_307989_IW3_20190603_20230302_VV_INT40_12D4 drop
# mv data/S1_307989_IW3_20200329_20240904_VV_INT40_19DF drop
# mv data/S1_307989_IW3_20210523_20211213_VV_INT40_03DF drop
# mv data/S1_307989_IW3_20230513_20231227_VV_INT40_60D0 drop

#rm -rf inputs *.h5

# use standard version installed with 
#mamba create -n mintpy -c conda-forge mintpy -y

mamba run -n mintpy smallbaselineApp.py ${runname}.cfg > ${runname}.out 2> ${runname}.err 

cd ..
mkdir -p ${runname}hcorr
cd ${runname}hcorr/
ln -s ../${runname}/data .

cat ../${runname}/${runname}.cfg | sed 's/mintpy.troposphericDelay.method = no/mintpy.troposphericDelay.method = height_correlation/' > ${runname}hcorr.cfg
mamba run -n mintpy smallbaselineApp.py ${runname}hcorr.cfg > ${runname}hcorr.out 2> ${runname}hcorr.err 

cd ..
mkdir -p ${runname}era
cd ${runname}era/
ln -s ../${runname}/data .

cat ../${runname}/${runname}.cfg | sed 's/mintpy.troposphericDelay.method = no/mintpy.troposphericDelay.method = pyaps/' > ${runname}era.cfg
mamba run -n mintpy smallbaselineApp.py ${runname}era.cfg > ${runname}era.out 2> ${runname}era.err &
